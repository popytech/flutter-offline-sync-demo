enum SyncState { local, pending, syncing, synced, failed }

enum SyncOperationType { createRecord, updateRecord, uploadAttachment }

class AppRecord {
  const AppRecord({
    required this.id,
    required this.title,
    required this.notes,
    required this.updatedAt,
    required this.syncState,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime updatedAt;
  final SyncState syncState;

  AppRecord copyWith({
    String? title,
    String? notes,
    DateTime? updatedAt,
    SyncState? syncState,
  }) {
    return AppRecord(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
    );
  }
}

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.recordId,
    required this.idempotencyKey,
    required this.attempts,
    required this.nextAttemptAt,
    this.attachmentPath,
  });

  final String id;
  final SyncOperationType type;
  final String recordId;
  final String idempotencyKey;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? attachmentPath;
}
