import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/local_store.dart';
import '../data/remote_api.dart';
import '../models/sync_models.dart';

class SyncEngine {
  SyncEngine({
    required LocalStore localStore,
    required RemoteApi remoteApi,
    Connectivity? connectivity,
    DateTime Function()? now,
  })  : _localStore = localStore,
        _remoteApi = remoteApi,
        _connectivity = connectivity ?? Connectivity(),
        _now = now ?? DateTime.now;

  final LocalStore _localStore;
  final RemoteApi _remoteApi;
  final Connectivity _connectivity;
  final DateTime Function() _now;

  static const maxAttempts = 5;

  Future<SyncSummary> run() async {
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.every((result) => result == ConnectivityResult.none)) {
      return const SyncSummary(processed: 0, succeeded: 0, failed: 0, offline: true);
    }

    final due = await _localStore.dueOperations(_now());
    var succeeded = 0;
    var failed = 0;

    for (final operation in due) {
      final records = await _localStore.listRecords();
      final matches = records.where((record) => record.id == operation.recordId);
      if (matches.isEmpty) {
        await _localStore.completeOperation(operation.id);
        continue;
      }

      final record = matches.first;
      await _localStore.updateRecordState(record.id, SyncState.syncing);

      try {
        await _remoteApi.apply(operation, record: record);
        await _localStore.completeOperation(operation.id);
        await _localStore.updateRecordState(record.id, SyncState.synced);
        succeeded += 1;
      } catch (_) {
        final attempts = operation.attempts + 1;
        failed += 1;
        if (attempts >= maxAttempts) {
          await _localStore.completeOperation(operation.id);
          await _localStore.updateRecordState(record.id, SyncState.failed);
        } else {
          final delaySeconds = math.min(60, math.pow(2, attempts).toInt());
          await _localStore.rescheduleOperation(
            operation.id,
            attempts: attempts,
            nextAttemptAt: _now().add(Duration(seconds: delaySeconds)),
          );
          await _localStore.updateRecordState(record.id, SyncState.pending);
        }
      }
    }

    return SyncSummary(
      processed: due.length,
      succeeded: succeeded,
      failed: failed,
      offline: false,
    );
  }
}

class SyncSummary {
  const SyncSummary({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.offline,
  });

  final int processed;
  final int succeeded;
  final int failed;
  final bool offline;
}
