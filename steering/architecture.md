# Steering — Architecture

CubeOS's system architecture, condensed from `architecture/02_ARCHITECTURE.md` and `CUBEOS_PROJECT_ROADMAP_v4.md` §4.

## The Three-Headed Hydra problem (motivating the architecture)

Pre-Swarm CubeOS had three independent components — Services handler, AppManager, AppStore — each calling Docker directly. This produced:

- **State fragmentation:** `apps` table (Services) vs. `installed_apps` table (AppManager) vs. AppStore registry — three sources of truth, frequent drift.
- **Status desynchronisation:** Dashboard polled Services for status; AppManager polled Docker independently; AppStore showed cached state.
- **Concurrency hazards:** Two install requests overlapped because there was no central coordinator.

The Swarm migration (completed Phase 1-4 per roadmap) fixed this by routing every container operation through a single **Orchestrator** that delegates to a single **SwarmManager**.

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

## Service layers

| Layer            | Services                                | Network mode | Port range            | Startup order |
|------------------|-----------------------------------------|--------------|-----------------------|---------------|
| Infrastructure   | pihole, npm, registry                   | host         | 53,67,80,443,5000,6000,6001 | 1, 2, 3       |
| Platform         | api, dashboard, dozzle, watchdog        | bridge       | 6010-6019             | 4, 5, 6, 7    |
| Network          | wireguard, openvpn, tor                 | bridge       | 6020-6029             | 8, 9, 10      |
| AI/ML            | ollama, chromadb, docs-indexer          | bridge       | 6030-6039             | 11, 12, 13    |
| Application      | user apps                               | bridge       | 6100-6999             | 14+           |

Source: `architecture/02_ARCHITECTURE.md` §1.2.

## Component structure (api/)

```
api/cmd/cubeos/main.go
api/internal/
├── config/        env loading, defaults
├── database/      sqlite + schema + migrations (append-only per Article XIII)
├── managers/      swarm, orchestrator, registry, compose, npm, pihole, ports, network, vpn, backup, system
├── handlers/      one file per domain (apps, auth, system, network, docker, access_profile, ...)
├── flowengine/    Saga-based workflow engine
├── clients/       External service clients (npm_external, pihole_external, hal_external)
└── middleware/    Logger → Recovery → RealIP → RequestID → CORS → Timeout(60s) → MaxBodySize(10MB) → SetupRequired → JWTAuth
```

The Orchestrator pattern (`api/internal/managers/orchestrator.go`) is the central coordinator. FlowEngine workflows (7 sagas as of v0.2.0-beta.03) handle multi-step operations with rollback semantics.

## Component structure (hal/)

40+ Go files across 14 hardware categories: GPIO, Serial, Network (hostapd, wpa_supplicant, iwconfig), Pi-hole-DHCP-as-host, NPM-as-host, sysctl, fail2ban, watchdog, Iridium (RockBLOCK 9603N + 9704), GPS (UART + USB GNSS), Cellular, Meshtastic, ZigBee (CC2652P), GPIO buttons + LEDs. 80+ endpoints. X-HAL-Key ACL across the entire HAL API per Article I.

## Component structure (dashboard/)

144+ Vue 3 components, 9 pages, 29 Pinia stores. Composition API exclusively. Tailwind CSS exclusively. Responsive across mobile / tablet / desktop. Dual mode (operator / advanced). Access Profile UI gates capability surface per Article VI / `13_ACCESS_PROFILES.md`.

## Cross-component contracts

| Contract                                                          | Source of truth                                           |
|-------------------------------------------------------------------|-----------------------------------------------------------|
| REST API (api → dashboard, api → user apps)                       | `architecture/07_API_CONTRACTS.md` + Swagger (Article XII) |
| HAL API (api → hal)                                               | `hal/openapi.yaml` (component-repo level)                  |
| Compose-to-Swarm transformation                                   | `api/internal/managers/compose.go`                         |
| App store handoff (AppStore → Orchestrator)                       | unified `apps` table; legacy `installed_apps` deprecated  |
| Pi-hole / NPM as host-mode services                               | `coreapps/pihole/`, `coreapps/npm/` + HAL endpoints       |

## Where to extend

- **New coreapp:** add `coreapps/<name>/docker-compose.yml`, allocate 6xxx port per Article V, define `host` vs `bridge` mode per service-layer table.
- **New HAL category:** add `hal/internal/<category>/`, register routes in `hal/cmd/hal/main.go`, claim any serial port via the registry per Article IX.
- **New API handler:** add `api/internal/handlers/<domain>.go`, register route in `api/cmd/cubeos/main.go`, add full Swagger annotations per Article XII, run `make verify-routes`.
- **New saga workflow:** add `api/internal/flowengine/<workflow>.go`, register in `api/internal/managers/orchestrator.go`, write compensating-action functions per saga semantics.

## Where NOT to extend (constitutional boundaries)

- API containers MUST NOT touch host services directly (Article I).
- Raw IPs MUST NOT appear in code (Article II).
- Ports MUST NOT escape `6000-6999` (Article V).
- DHCP MUST NOT run on non-managed interfaces (Article VI).
- Serial ports MUST NOT be claimed by more than one HAL subsystem (Article IX).
- Subnet MUST NOT diverge from `10.42.24.0/24` (Article X).
- Go code MUST NOT enable CGO (Article XI).
- HTTP handlers MUST NOT lack Swagger annotations (Article XII).
- Migrations MUST NOT be edited in place (Article XIII).
- Coreapp pulls MUST NOT hit Docker Hub at runtime (Article XIV).
