import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/sync_models.dart';

class LocalStore {
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final root = await getDatabasesPath();
    final db = await openDatabase(
      p.join(root, 'offline_sync_demo.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE records(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_state TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE attachments(
            id TEXT PRIMARY KEY,
            record_id TEXT NOT NULL,
            local_path TEXT NOT NULL,
            remote_url TEXT,
            sync_state TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue(
            id TEXT PRIMARY KEY,
            operation_type TEXT NOT NULL,
            record_id TEXT NOT NULL,
            idempotency_key TEXT NOT NULL UNIQUE,
            attachment_path TEXT,
            attempts INTEGER NOT NULL DEFAULT 0,
            next_attempt_at TEXT NOT NULL
          )
        ''');
      },
    );
    _database = db;
    return db;
  }

  Future<List<AppRecord>> listRecords() async {
    final db = await database;
    final rows = await db.query('records', orderBy: 'updated_at DESC');
    return rows.map((row) {
      return AppRecord(
        id: row['id']! as String,
        title: row['title']! as String,
        notes: row['notes']! as String,
        updatedAt: DateTime.parse(row['updated_at']! as String),
        syncState: SyncState.values.byName(row['sync_state']! as String),
      );
    }).toList();
  }

  Future<void> saveRecord(AppRecord record) async {
    final db = await database;
    await db.insert(
      'records',
      {
        'id': record.id,
        'title': record.title,
        'notes': record.notes,
        'updated_at': record.updatedAt.toUtc().toIso8601String(),
        'sync_state': record.syncState.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRecordState(String recordId, SyncState state) async {
    final db = await database;
    await db.update(
      'records',
      {'sync_state': state.name},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<void> enqueue(SyncOperation operation) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': operation.id,
        'operation_type': operation.type.name,
        'record_id': operation.recordId,
        'idempotency_key': operation.idempotencyKey,
        'attachment_path': operation.attachmentPath,
        'attempts': operation.attempts,
        'next_attempt_at': operation.nextAttemptAt.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<SyncOperation>> dueOperations(DateTime now) async {
    final db = await database;
    final rows = await db.query(
      'sync_queue',
      where: 'next_attempt_at <= ?',
      whereArgs: [now.toUtc().toIso8601String()],
      orderBy: 'next_attempt_at ASC',
    );
    return rows.map((row) {
      return SyncOperation(
        id: row['id']! as String,
        type: SyncOperationType.values.byName(row['operation_type']! as String),
        recordId: row['record_id']! as String,
        idempotencyKey: row['idempotency_key']! as String,
        attachmentPath: row['attachment_path'] as String?,
        attempts: row['attempts']! as int,
        nextAttemptAt: DateTime.parse(row['next_attempt_at']! as String),
      );
    }).toList();
  }

  Future<void> completeOperation(String operationId) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [operationId]);
  }

  Future<void> rescheduleOperation(
    String operationId, {
    required int attempts,
    required DateTime nextAttemptAt,
  }) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {
        'attempts': attempts,
        'next_attempt_at': nextAttemptAt.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }
}
