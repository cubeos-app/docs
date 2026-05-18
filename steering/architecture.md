# Steering — Architecture

CubeOS's system architecture, CGC-grounded 2026-05-18.

## The Three-Headed Hydra problem (motivating the architecture)

Pre-Swarm CubeOS had three independent components — Services handler, AppManager, AppStore — each calling Docker directly. This produced state fragmentation, status desynchronisation, and concurrency hazards.

The Swarm migration (Phases 1-4 per roadmap) fixed this by routing every container operation through:

- One **Orchestrator** (CGC-verified: `api/internal/managers/orchestrator.go:27`)
- delegating to one **SwarmManager** (`api/internal/managers/swarm.go`)
- via the **FlowEngine** (`api/internal/flowengine/engine.go`)
- composing 12 **workflows** (`api/internal/flowengine/workflows/`) from 14 **activities** (`api/internal/flowengine/activities/`).

## High-level shape

```
+------------------------------------------------------------------+
|                        CUBEOS SYSTEM                              |
+------------------------------------------------------------------+
|                                                                    |
|  +------------------------+     +---------------------------+     |
|  |     HOST SERVICES      |     |    DOCKER SWARM           |     |
|  |  (systemd managed)     |     |    (container runtime)    |     |
|  |  - hostapd (WiFi AP)   |     |  INFRASTRUCTURE LAYER     |     |
|  |  - wpa_supplicant      |     |  +---------------------+  |     |
|  |  - systemd-resolved    |     |  | pihole (host mode)  |  |     |
|  |  - cubeos-init.service |     |  | npm (host mode)     |  |     |
|  |  - watchdog            |     |  | registry            |  |     |
|  |  - fail2ban            |     |  +---------------------+  |     |
|  |  - HAL (privileged)    |     |  PLATFORM LAYER           |     |
|  +------------------------+     |  +---------------------+  |     |
|                                 |  | cubeos-api          |  |     |
|                                 |  | cubeos-dashboard    |  |     |
|                                 |  | dozzle (logging)    |  |     |
|                                 |  +---------------------+  |     |
|                                 |  NETWORK LAYER            |     |
|                                 |  +---------------------+  |     |
|                                 |  | wireguard           |  |     |
|                                 |  | openvpn / tor       |  |     |
|                                 |  +---------------------+  |     |
|                                 |  AI/ML + APPLICATION      |     |
|                                 |  +---------------------+  |     |
|                                 |  | ollama, chromadb    |  |     |
|                                 |  | user-installed apps |  |     |
|                                 |  +---------------------+  |     |
|                                 +---------------------------+     |
+------------------------------------------------------------------+
```

## Component-repo map (CGC-verified)

| Component | GitLab proj | Real entry point | What it owns |
|---|---:|---|---|
| api | 13 | `cmd/cubeos-api/main.go` | REST API + Orchestrator + 12 FlowEngine workflows + 14 activities + 28 managers + 35 handlers |
| dashboard | 14 | `src/main.js` | Vue 3 SPA + 144+ components organised by feature (settings/, swarm/, services/, wizard/, ...) |
| hal | 22 | `cmd/cubeos-hal/main.go` | 47 handler files across 22 domains; X-HAL-Key + 3-role ACL + tier gating |
| coreapps | 19 | `*/docker-compose.yml` | Docker Swarm stack definitions for ~12 coreapps |
| releases | 20 | Packer + scripts/ | Image builder + Pi Imager manifest |
| docs | 16 | this repo | Architecture docs + spec home (CubeOS project-level) |

## Cross-component contracts

| Contract | Source of truth |
|---|---|
| REST API (api → dashboard, api → user apps) | `architecture/07_API_CONTRACTS.md` + Swagger (Article XII) — generated from godoc + verified by `make verify-routes` |
| HAL API (api → hal) | `hal/OPENAPI_DOCS.md` + `hal/internal/handlers/docs.go ServeOpenAPISpec` |
| Compose-to-Swarm transformation | `api/internal/flowengine/activities/appstore.go` + `app_install.go` (NOT a managers/compose.go file) |
| App-store handoff (AppStore → Orchestrator) | unified `apps` table; CGC-verified |
| Pi-hole / NPM as host-mode services | `coreapps/pihole/`, `coreapps/npm/` + HAL endpoints |

## Where to extend

- **New coreapp:** add `coreapps/<name>/docker-compose.yml`, allocate 6xxx port per Article V.
- **New HAL handler:** add `hal/internal/handlers/<feature>.go` + register in `hal/internal/handlers/routes.go` + update OpenAPI per hal/ADR-0006.
- **New API handler:** add `api/internal/handlers/<domain>.go`, register route in `api/cmd/cubeos-api/main.go`, full Swagger annotations per Article XII, run `make verify-routes`.
- **New FlowEngine workflow:** add `api/internal/flowengine/workflows/<workflow>.go` composing existing activities from `api/internal/flowengine/activities/`. Add new activity files only when the operation is genuinely new (not just a different ordering).
- **New dashboard feature:** add `dashboard/src/components/<feature-group>/<Component>.vue` (NOT in `views/` — that directory does not exist).

## Where NOT to extend (constitutional boundaries)

Per the 19 Articles in `constitution.md`. See that file.
