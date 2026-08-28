# Architecture

## Local-first write path

Every user write is committed to SQLite before any network request is attempted. The repository then creates an outbox operation in `sync_queue` with a stable idempotency key.

```text
Form submit
  → records table
  → sync_queue
  → UI immediately reflects pending state
```

## Synchronization

`SyncEngine` checks connectivity, loads due outbox operations and sends them through a provider-neutral `RemoteApi` adapter.

A successful operation is removed from the outbox and its record becomes `synced`. Temporary failure increments `attempts` and schedules the next attempt using exponential backoff. After the capped retry count, the record becomes `failed` and remains visible to the user.

## Idempotency

Every remote mutation carries an idempotency key generated when the local operation is queued. Retrying the same operation must not create a duplicate remote effect. `MockRemoteApi` demonstrates this behavior with an in-memory processed-key set.

## Attachments

Attachment operations are queued separately from record mutations. The local path remains available while offline; the real remote adapter can upload it later and store a remote URL after success.

## Connectivity recovery

The controller subscribes to `connectivity_plus`. When connectivity returns it triggers the same sync engine used by the manual **Sync now** action. Business logic therefore does not depend on the UI or connectivity listener.

## Production extensions

A production application would normally add conflict-resolution/version columns, encrypted local storage where required, background execution, server timestamps, dead-letter/retry management, telemetry, and a real HTTP/Supabase/Firebase adapter.
