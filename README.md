# Flutter Offline Sync Demo

[![CI](https://github.com/popytech/flutter-offline-sync-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/popytech/flutter-offline-sync-demo/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-offline--first-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-111111)](./LICENSE)

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

See [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) for the detailed flow.

## Demo capabilities

- Create records while fully offline
- Persist records with SQLite
- Queue create/update/upload operations in an outbox
- Attach files and defer upload
- Resume synchronization when connectivity returns
- Exponential retry with capped attempts
- Stable idempotency keys per operation
- Visible sync state: local, pending, syncing, synced, failed
- Manual **Sync now** control
- Deterministic mock API for development and tests

## Quick start

This repository focuses on the reusable application/synchronization layer. If platform host folders are not present after cloning, generate them once with Flutter:

```bash
git clone https://github.com/popytech/flutter-offline-sync-demo.git
cd flutter-offline-sync-demo
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

## Quality

```bash
flutter analyze
flutter test
```

The same checks run on GitHub Actions and the main branch is validated by CI.

## Project structure

```text
lib/
├─ main.dart
└─ src/
   ├─ app_controller.dart
   ├─ home_page.dart
   ├─ data/
   │  ├─ local_store.dart
   │  ├─ record_repository.dart
   │  └─ remote_api.dart
   ├─ models/
   │  └─ sync_models.dart
   └─ sync/
      └─ sync_engine.dart
```

## Reusing the pattern

The remote adapter is intentionally provider-neutral. Replace `MockRemoteApi` with a Supabase, REST, GraphQL, Firebase or custom backend adapter while keeping the local write/outbox/retry flow unchanged.

## Production extensions

For a production application, add conflict resolution/versioning, encrypted local storage where required, background execution, server timestamps, telemetry and a dead-letter/retry management screen.

## License

MIT.

---

Built by **Popy Traoré** · Guinea → Africa
