# Requirements — Swarm Orchestrator + FlowEngine (spec/009 — RETROSPECTIVE)

Source: `architecture/00_PROJECT_OVERVIEW.md` §"The Solution" + `architecture/02_ARCHITECTURE.md` + roadmap §2. CGC-verified paths 2026-05-18 (api/internal/managers/orchestrator.go:27 + 12 workflows + 14 activities + 28 managers + 35 handlers).

> Retrospective. ID convention: 900-block.

REQ-900: The system shall route every container lifecycle operation through the single Orchestrator at `api/internal/managers/orchestrator.go:27`.
REQ-901: The system shall NOT permit any other code path to call Docker directly except via Orchestrator → DockerManager (`api/internal/managers/docker.go`) or SwarmManager (`api/internal/managers/swarm.go`).
REQ-902: The system shall delegate all Docker Swarm API calls to a single SwarmManager.
REQ-903: The system shall use a single `apps` table as the source of truth for installed apps.
REQ-904: The system shall start every coreapp + user app as a Docker Swarm service, NEVER as `docker run`.
REQ-905: The system shall configure each service with `restart_policy: condition: any` so Swarm restarts on container failure.
REQ-906: The system shall implement multi-step lifecycle operations as FlowEngine workflows in `api/internal/flowengine/workflows/` composed from activities in `api/internal/flowengine/activities/`.
REQ-907: When any workflow step fails, the system shall execute compensating actions in reverse order from the failure point.
REQ-908: The system shall provide at minimum these workflows (CGC-verified shipping): `appstore_install`, `appstore_remove`, `app_install`, `app_remove`, `network_mode_switch`, `access_profile_switch`, `first_boot_setup`, `backup`, `restore`, `registry_cache`, `system_update`, `wifi_client_switch`.
REQ-909: The system shall allocate user-app ports via the PortManager at `api/internal/managers/ports_new.go` with triple-source validation (DB + Swarm + HAL).
REQ-910: When a user app is uninstalled, the system shall release its port back to the available pool.
REQ-911: The system shall fail an install with HTTP 409 if no port is available in the 6100-6999 range.
REQ-912: The system shall transform CasaOS-compatible docker-compose.yml files into Swarm-compatible compose at install time via the activities at `api/internal/flowengine/activities/appstore.go` and `app_install.go` (NOT a single managers/compose.go file).
REQ-913: When the transformation encounters a feature unsupported in Swarm, the system shall reject the install with an actionable error.
REQ-914: The system shall expose `GET /api/v1/system/stacks` (handler at `api/internal/handlers/handlers.go` or similar) returning all deployed Swarm stacks + per-service replica counts + per-task status.
REQ-915: The system shall apply `--task-history-limit 1` to Swarm to bound `tasks.db` memory (Article IV).
REQ-916: The system shall expose a built-in Swarm GUI in dashboard at `dashboard/src/components/swarm/SwarmOverview.vue` + `StackList.vue` (NOT `views/SwarmGUIView.vue`).
REQ-917: The system shall NOT depend on any third-party Swarm GUI (no Portainer / Swarmpit).
REQ-918: The system shall persist saga-run history to the `flowengine_runs` table (schema v22+).
REQ-919: While a workflow is running, the system shall emit per-step progress events that the dashboard subscribes to via WebSocket.
REQ-920: The system shall handle context cancellation by propagating through to the workflow step that observes it.
