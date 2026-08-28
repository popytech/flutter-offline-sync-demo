import 'package:uuid/uuid.dart';

import '../models/sync_models.dart';
import 'local_store.dart';

class RecordRepository {
  RecordRepository({required LocalStore localStore, Uuid? uuid})
      : _localStore = localStore,
        _uuid = uuid ?? const Uuid();

  final LocalStore _localStore;
  final Uuid _uuid;

  Future<List<AppRecord>> list() => _localStore.listRecords();

  Future<AppRecord> create({required String title, required String notes}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final record = AppRecord(
      id: id,
      title: title,
      notes: notes,
      updatedAt: now,
      syncState: SyncState.pending,
    );
    await _localStore.saveRecord(record);
    await _localStore.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        type: SyncOperationType.createRecord,
        recordId: id,
        idempotencyKey: 'record-create-$id',
        attempts: 0,
        nextAttemptAt: now,
      ),
    );
    return record;
  }

  Future<AppRecord> update(AppRecord current, {required String title, required String notes}) async {
    final now = DateTime.now();
    final next = current.copyWith(
      title: title,
      notes: notes,
      updatedAt: now,
      syncState: SyncState.pending,
    );
    await _localStore.saveRecord(next);
    await _localStore.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        type: SyncOperationType.updateRecord,
        recordId: current.id,
        idempotencyKey: 'record-update-${current.id}-${now.microsecondsSinceEpoch}',
        attempts: 0,
        nextAttemptAt: now,
      ),
    );
    return next;
  }

  Future<void> queueAttachment({required String recordId, required String localPath}) async {
    final now = DateTime.now();
    await _localStore.enqueue(
      SyncOperation(
        id: _uuid.v4(),
        type: SyncOperationType.uploadAttachment,
        recordId: recordId,
        idempotencyKey: 'attachment-$recordId-${localPath.hashCode}',
        attachmentPath: localPath,
        attempts: 0,
        nextAttemptAt: now,
      ),
    );
    await _localStore.updateRecordState(recordId, SyncState.pending);
  }
}
