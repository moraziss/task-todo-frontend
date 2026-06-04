# task_todo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Server (Go) and PostgreSQL

- Configure DSN via env var:
  - Windows (PowerShell): setx POSTGRES_DSN "postgres://postgres:password@localhost:5432/todo_db?sslmode=disable"
  - macOS/Linux (bash): export POSTGRES_DSN="postgres://postgres:password@localhost:5432/todo_db?sslmode=disable"
- Run server: go run ./server/cmd/server
- On startup the server runs migrations automatically.

### If you see: relation "tasks" does not exist during migration
This happens when the database is empty and an ALTER TABLE tries to modify a non‑existing table. Fixed in code by bootstrapping base tables first. If you still hit it (e.g., old binary or lack of privileges), run the bootstrap SQL once, then start the server:

1) Open psql connected to your database (todo_db), then execute:

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  color VARCHAR(16) NOT NULL DEFAULT '#9e9e9e',
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY,
  parent_id UUID NULL REFERENCES tasks(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  priority VARCHAR(20) DEFAULT 'medium',
  category VARCHAR(50),
  category_id UUID NULL REFERENCES categories(id) ON DELETE SET NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deadline TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS attachments (
  id UUID PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON tasks(parent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_updated_at ON tasks(updated_at);
CREATE INDEX IF NOT EXISTS idx_tasks_is_deleted ON tasks(is_deleted);
CREATE INDEX IF NOT EXISTS idx_tasks_is_pinned ON tasks(is_pinned);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline);
CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
CREATE INDEX IF NOT EXISTS idx_attachments_task_id ON attachments(task_id);

INSERT INTO categories (id, name, color, is_default)
VALUES (gen_random_uuid(), 'Uncategorized', '#9e9e9e', TRUE)
ON CONFLICT (name) DO NOTHING;

2) Alternatively, run the included script:
- psql -d todo_db -f server/sql/bootstrap.sql

After that, start the server again. Migrations will continue to be applied safely with IF NOT EXISTS clauses.
