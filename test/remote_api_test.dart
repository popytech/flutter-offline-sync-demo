import 'package:flutter_offline_sync_demo/src/data/remote_api.dart';
import 'package:flutter_offline_sync_demo/src/models/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final record = AppRecord(
    id: 'record-1',
    title: 'Offline record',
    notes: 'Stored locally first',
    updatedAt: DateTime(2026),
    syncState: SyncState.pending,
  );

  SyncOperation operation(String idempotencyKey) => SyncOperation(
        id: idempotencyKey,
        type: SyncOperationType.createRecord,
        recordId: record.id,
        idempotencyKey: idempotencyKey,
        attempts: 0,
        nextAttemptAt: DateTime(2026),
      );

  test('duplicate idempotency key is accepted without a second remote effect', () async {
    final api = MockRemoteApi(failureEvery: 2, latency: Duration.zero);

    await api.apply(operation('same-key'), record: record);
    await api.apply(operation('same-key'), record: record);

    expect(
      () => api.apply(operation('new-key'), record: record),
      throwsA(isA<RemoteSyncException>()),
    );
  });

  test('copyWith keeps immutable record identity', () {
    final next = record.copyWith(title: 'Updated', syncState: SyncState.synced);
    expect(next.id, record.id);
    expect(next.title, 'Updated');
    expect(next.syncState, SyncState.synced);
  });
}
