# 3. SQLite as the CubeOS API database

Date: 2026-05-17 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

The CubeOS API (`api/` project 13) needs a database for: apps catalog, installed-apps state, users, sessions, audit log, network mode config, FlowEngine saga state. Schema is small (currently v24, ~30 tables) and access pattern is single-writer single-reader (the API container).

Candidate databases:

| Option                       | RAM      | Ops complexity | Pros                                              | Cons                                                |
|------------------------------|----------|----------------|---------------------------------------------------|-----------------------------------------------------|
| SQLite (pure-Go `modernc.org/sqlite`) | <50 MB   | nil            | Single file, zero-config, fast for single-writer  | No native replication; single-node only             |
| PostgreSQL                   | ~200 MB  | medium         | Rich types, replication, multi-writer             | Overhead massive for Pi; needs `postgres` user, init scripts |
| MariaDB                      | ~150 MB  | medium         | Mature, replication                               | Same overhead concerns                              |
| MariaDB Galera (3-node)      | n/a on edge | high       | Multi-master                                      | Requires 3 nodes; not edge-shaped                   |

## Decision

**SQLite via `modernc.org/sqlite`** (the pure-Go driver, NOT `mattn/go-sqlite3` which is CGO-bound and breaks Article XI). DB file at `/cubeos/data/cubeos.db`. WAL mode enabled. Backup via `sqlite3 cubeos.db ".backup ..."` to `/cubeos/data/backups/`.

## Consequences

**Positive:**
- ~50 MB RAM saved vs Postgres → matters on Pi 4 / 4GB.
- Zero ops overhead. Backup = file copy. Restore = file replace.
- Pure Go = single static binary, no CGO, cross-compiles cleanly for ARM64.
- WAL mode handles the API's single-writer pattern at ~5,000 writes/sec on Pi 5 SSD — well above our actual load.

**Negative:**
- No native replication. Multi-node Swarm clustering would require an external sync mechanism (Litestream, rqlite) — explicit non-goal for v1.0.
- Some Postgres-only features unavailable: JSON ops, full-text search via tsvector. We use SQLite's JSON1 + FTS5 extensions where needed.

**Contrast with `meshsat-hub`:** meshsat-hub is internet-exposed multi-tenant SaaS — it ships SQLite for Tier 1 single-tenant deploys but MariaDB Galera for Tier 2 cluster + k8s deploys. CubeOS itself is single-tenant edge — SQLite is unambiguously the right choice.

**Enforced by Constitution:** Article XI (CGO_ENABLED=0) requires the pure-Go SQLite driver.
