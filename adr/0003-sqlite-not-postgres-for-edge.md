# 3. SQLite as the CubeOS API database

Date: 2026-05-18 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

CubeOS API needs a database for apps catalog, installed-apps state, sessions, audit log, network config, FlowEngine saga state. CGC-verified: current schema is at version **27** (`api/internal/database/schema.go:13 CurrentSchemaVersion = 27`), ~30 tables. Access pattern: single-writer (the API container).

## Decision

**SQLite via `modernc.org/sqlite`** (pure-Go driver, Article XI). DB file at `/cubeos/data/cubeos.db`. WAL mode. Backup via file copy.

## Consequences

**Positive:** ~50 MB RAM saved vs Postgres on Pi; zero ops overhead; pure Go = single static binary cross-compiles cleanly for ARM64.

**Negative:** No native replication. Multi-node Swarm clustering (post-v1) would need an external sync mechanism (Litestream, rqlite) — non-goal for now.

**Contrast with meshsat-hub:** Hub is internet-exposed multi-tenant — SQLite for Tier 1, MariaDB Galera for Tier 2/3. CubeOS itself is single-tenant edge — SQLite is unambiguously the right choice.

**Enforced by:** Article XI + Article XIII (append-only migrations).
