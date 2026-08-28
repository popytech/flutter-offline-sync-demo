# Flutter Offline Sync Demo

A production-minded Flutter reference for **offline-first forms, attachments and deferred synchronization**.

> Local-first UX · SQLite outbox · retries · idempotency · connectivity recovery · attachment queue

## Why this exists

Mobile apps often operate with unstable or unavailable connectivity. This demo shows how a Flutter application can remain usable offline, persist work locally, and safely synchronize later without duplicating server-side operations.

## Architecture

```text
UI
 ↓
RecordRepository
 ↓
SQLite local database
 ├─ records
 ├─ attachments
 └─ sync_queue (outbox)
        ↓
SyncEngine
 ├─ connectivity gate
 ├─ exponential backoff
 ├─ idempotency keys
 └─ remote API adapter
```

## Demo capabilities

- Create/edit records while fully offline
- Persist records with SQLite
- Queue create/update/upload operations in an outbox
- Attach files and defer upload
- Resume synchronization when connectivity returns
- Exponential retry with capped attempts
- Stable idempotency keys per operation
- Visible sync state: local, pending, syncing, synced, failed
- Manual “Sync now” control
- Deterministic mock API for development and tests

## Run

```bash
flutter pub get
flutter run
```

## Quality

```bash
flutter analyze
flutter test
```

The same checks run on GitHub Actions.

## Scope

This repository is provider-neutral. The remote adapter is mocked so the offline synchronization pattern can be reused with Supabase, REST, GraphQL, Firebase or a custom backend.

## License

MIT

---

Built by **Popy Traoré** · Guinea → Africa
