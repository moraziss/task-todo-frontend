# task-todo-frontend

An offline-first to-do app built with Flutter. Tasks live in a local SQLite database, so the app works without a connection, and are synchronised with a Go + PostgreSQL backend when one is available.

> Backend: [moraziss/task-todo-backend](https://github.com/moraziss/task-todo-backend)

## Features

- **Offline-first storage** — everything is read from and written to SQLite (`sqflite`; `sqflite_common_ffi` on Windows, macOS and Linux).
- **Categories** — tasks belong to a category with its own colour; deleting a category does not delete its tasks.
- **Subtasks with progress** — open a task to add subtasks and see a completion bar.
- **Smart ordering** — active tasks first, pinned on top, overdue deadlines raised, then by priority (high → low). Completed tasks sink to the bottom.
- **Deadlines** — set when creating a task; overdue tasks are highlighted.
- **Swipe gestures** — swipe right to pin / unpin, swipe left to delete.
- **Soft delete** — deleted tasks are only flagged, so the deletion can be synchronised to the server before the row is removed.
- **Sync** — `POST /sync` sends local tasks and categories and merges the server's response back.

File attachments are not implemented yet: the button on the task screen is a placeholder.

## Tech stack

| Area | Choice |
| --- | --- |
| UI | Flutter (Material 3) |
| State management | `provider` (`ChangeNotifier`) |
| Local storage | `sqflite` / `sqflite_common_ffi` |
| Networking | `http` |
| Backend | Go + PostgreSQL (separate repository) |

## Project layout

```
Frontend/
├── lib/
│   ├── main.dart                 # app entry point, database bootstrap
│   ├── models/                   # Task, Category (Map <-> object)
│   ├── screens/                  # main list, task details
│   └── services/
│       ├── database_helper.dart  # SQLite access
│       ├── sync_service.dart     # HTTP sync with the backend
│       └── task_provider.dart    # state, sorting, progress
├── test/                         # model unit tests
└── analysis_options.yaml         # flutter_lints
docs/
└── product-spec.ru.md            # product specification (Russian)
```

## Getting started

Requirements: Flutter (stable channel) with Dart 3.

```bash
cd Frontend
flutter pub get
flutter run
```

The app expects the sync server at `http://localhost:8080` by default. Point it somewhere else with `--dart-define`; for example, the Android emulator reaches the host machine at `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Without a running server the app still works; sync simply logs an error and local data is untouched.

## Checks

```bash
cd Frontend
flutter analyze
flutter test
```

Both run in CI on every push and pull request (`.github/workflows/ci.yml`).

## Documentation

The product specification — data model, soft delete, category lifecycle, subtask progress formula, sorting rules and UX ideas — is in [docs/product-spec.ru.md](docs/product-spec.ru.md) (in Russian).
