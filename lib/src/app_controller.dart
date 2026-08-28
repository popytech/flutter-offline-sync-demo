import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'data/record_repository.dart';
import 'models/sync_models.dart';
import 'sync/sync_engine.dart';

class AppController extends ChangeNotifier {
  AppController({
    required RecordRepository repository,
    required SyncEngine syncEngine,
    Connectivity? connectivity,
  })  : _repository = repository,
        _syncEngine = syncEngine,
        _connectivity = connectivity ?? Connectivity();

  final RecordRepository _repository;
  final SyncEngine _syncEngine;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  List<AppRecord> records = const [];
  bool loading = true;
  bool syncing = false;
  String statusMessage = 'Loading local data…';

  Future<void> initialize() async {
    records = await _repository.list();
    loading = false;
    statusMessage = records.isEmpty ? 'Ready — create a record even without internet.' : 'Local data loaded.';
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        unawaited(syncNow(automatic: true));
      }
    });
  }

  Future<void> createRecord(String title, String notes) async {
    if (title.trim().isEmpty) return;
    await _repository.create(title: title.trim(), notes: notes.trim());
    await refresh();
    statusMessage = 'Saved locally and queued for sync.';
    notifyListeners();
  }

  Future<void> attachFile(AppRecord record) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = result?.files.single.path;
    if (path == null) return;
    await _repository.queueAttachment(recordId: record.id, localPath: path);
    await refresh();
    statusMessage = 'Attachment queued. It will upload when sync succeeds.';
    notifyListeners();
  }

  Future<void> syncNow({bool automatic = false}) async {
    if (syncing) return;
    syncing = true;
    statusMessage = automatic ? 'Connection restored — syncing…' : 'Syncing queued changes…';
    notifyListeners();

    final summary = await _syncEngine.run();
    await refresh(notify: false);
    syncing = false;
    if (summary.offline) {
      statusMessage = 'Offline — changes remain safely queued.';
    } else if (summary.failed > 0) {
      statusMessage = '${summary.succeeded} synced · ${summary.failed} scheduled for retry.';
    } else if (summary.processed == 0) {
      statusMessage = 'Everything is already synchronized.';
    } else {
      statusMessage = '${summary.succeeded} operation(s) synchronized.';
    }
    notifyListeners();
  }

  Future<void> refresh({bool notify = true}) async {
    records = await _repository.list();
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
