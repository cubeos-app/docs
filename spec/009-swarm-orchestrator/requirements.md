# Requirements — Swarm Orchestrator + FlowEngine (spec/009 — retrospective, shipped)

Source: `architecture/00_PROJECT_OVERVIEW.md` §"The Solution" + `architecture/02_ARCHITECTURE.md` §2.1 + `CUBEOS_PROJECT_ROADMAP_v4.md` §2 ("FlowEngine: 7 workflows").

> Retrospective spec for the post-Three-Headed-Hydra unified architecture (Phases 1-4 shipped). New orchestrator features go in their own specs.
> ID convention: 900-block (`900..999`).

## Functional requirements

### Single coordinator

REQ-900: The system shall route every container lifecycle operation (install / uninstall / start / stop / restart) through one Orchestrator (`api/internal/managers/orchestrator.go`).
REQ-901: The system shall NOT permit any other code path to call Docker directly except the Orchestrator (and its SwarmManager delegate).
REQ-902: The system shall delegate all Docker Swarm API calls to a single SwarmManager (`api/internal/managers/swarm.go`).

### Unified app table

REQ-903: The system shall use a single `apps` table as the source of truth for installed apps.
REQ-904: The system shall deprecate the legacy `installed_apps` table (kept for one release for migration safety, then dropped per the append-only migration rules).
REQ-905: While the deprecation is in effect, the system shall NOT write to `installed_apps`.

### Self-healing via Swarm reconciliation

REQ-906: The system shall start every coreapp + user app as a Docker Swarm service, NEVER as `docker run`.
REQ-907: The system shall configure each service with `restart_policy: condition: any` so Swarm restarts on container failure.
REQ-908: When a container fails, the system shall record the failure to the audit log via SwarmManager event subscription.

### Saga workflows

REQ-909: The system shall implement multi-step lifecycle operations as FlowEngine sagas with explicit compensating actions.
REQ-910: When any saga step fails, the system shall execute the compensating actions in reverse order from the failure point.
REQ-911: The system shall provide at minimum the following sagas: install_app, uninstall_app, start_app, stop_app, network_mode_switch, access_profile_switch, backup.

### Port allocation

REQ-912: The system shall allocate user-app ports via a PortManager that maintains an in-memory allocation map synced with SQLite.
REQ-913: When a user app is uninstalled, the system shall release its port back to the available pool.
REQ-914: The system shall fail an install with HTTP 409 if no port is available in the 6100-6999 range (per Article V).

### Compose transformation

REQ-915: The system shall transform CasaOS-compatible docker-compose.yml files into Swarm-compatible compose at install time via `api/internal/managers/compose.go`.
REQ-916: When the transformation encounters a feature unsupported in Swarm (e.g. `depends_on: condition: service_healthy`), the system shall apply a documented fallback or reject the install with an actionable error.

### Resource visibility

REQ-917: The system shall expose `GET /api/v1/system/stacks` returning all deployed Swarm stacks + per-service replica counts + per-task status.
REQ-918: The system shall expose `GET /api/v1/system/stacks/{stack}/logs` streaming logs from all service replicas.

### Memory safety

REQ-919: The system shall apply `--task-history-limit 1` to Swarm to bound `tasks.db` memory (per Article IV + `01_REQUIREMENTS.md` SVC-09).
REQ-920: When `tasks.db` exceeds operator-configurable thresholds (default 100 MB), the system shall emit a warning to the audit log + dashboard banner.

### Swarm GUI parity

REQ-921: The system shall expose a built-in Swarm GUI in dashboard at /swarm-gui showing stacks + services + tasks + secrets + configs (gated to advanced+aio profiles per spec/004 REQ-412).
REQ-922: The system shall NOT depend on any third-party Swarm GUI (no Portainer / Swarmpit).
