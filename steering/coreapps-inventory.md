# Steering — Coreapps inventory

The set of services CubeOS ships and runs as Docker Swarm stacks on every device. Curated from `architecture/05_COREAPPS_INVENTORY.md`.

## What is a coreapp?

A *coreapp* is a service whose docker-compose definition ships in the `coreapps/` repo (project 19) and is deployed automatically on first boot. User-installed apps come from the CasaOS-compatible app store + local registry but are not coreapps.

Coreapps are versioned alongside the CubeOS release: `v0.2.0-beta.03` pins specific image tags in `coreapps/*/docker-compose.yml`. Updating a coreapp = bumping its compose file = trigger CI = re-deploy to all running Pis on push to main per Article XV.

## Infrastructure layer (host-mode services)

| Coreapp        | Image                              | Port(s)              | Purpose                                                          |
|----------------|------------------------------------|----------------------|------------------------------------------------------------------|
| `pihole`       | `pihole/pihole:2025.x`             | 53, 67, 80 (managed) | DNS + DHCP (DHCP only when Article VI condition holds)           |
| `npm`          | `jc21/nginx-proxy-manager:2.x`     | 80, 443, 81          | Reverse proxy + cert termination + admin UI                       |
| `registry`     | `registry:2`                       | 5000                 | Local Docker registry per Article XIV                            |

## Platform layer

| Coreapp              | Image                                | Port    | Purpose                                       |
|----------------------|--------------------------------------|--------:|-----------------------------------------------|
| `cubeos-api`         | `localhost:5000/cubeos-api:v0.2.0`   | 6010    | Backend REST API + Orchestrator + FlowEngine  |
| `cubeos-dashboard`   | `localhost:5000/cubeos-dashboard:v0.2.0` | 6011 | Vue 3 frontend + Swarm GUI                    |
| `cubeos-hal`         | `localhost:5000/cubeos-hal:v0.2.0`   | 6005    | Hardware abstraction (privileged)             |
| `dozzle`             | `amir20/dozzle:latest`               | 6012    | Real-time container log viewer                |

## Network / VPN layer

| Coreapp        | Image                                  | Port  | Purpose                                            |
|----------------|----------------------------------------|------:|----------------------------------------------------|
| `wireguard`    | `linuxserver/wireguard:1.x`            | 51820 | WireGuard server + per-app VPN routing             |
| `openvpn`      | `linuxserver/openvpn-as:latest`        | 6021  | OpenVPN client + admin UI                          |
| `tor`          | `dperson/torproxy:latest`              | 6022  | SOCKS5 proxy for Tor routing                       |

## AI/ML layer

| Coreapp        | Image                                  | Port    | Purpose                                            |
|----------------|----------------------------------------|--------:|----------------------------------------------------|
| `ollama`       | `ollama/ollama:0.x`                    | 6030    | LLM inference (`PORT-05` required relocation from 11434) |
| `chromadb`     | `chromadb/chroma:0.x`                  | 6031    | Vector database for RAG                            |
| `docs-indexer` | `localhost:5000/cubeos-docs-indexer:v0.2.0` | 6032 | Local docs RAG indexer (consumes `docsindex/`)     |

## What was removed (Sprint 0 cleanup)

Per `06_SPRINT_PLAN.md` Sprint 0 task `S0-02`:
- `dockge` — removed; replaced by built-in Swarm GUI in dashboard per `00_PROJECT_OVERVIEW.md` Non-Goals (no third-party Swarm GUI).
- `gpio` — removed; GPIO operations moved into HAL (Article I).
- `nettools` — removed; network introspection moved into HAL.
- `usb-monitor` — removed; udev rules in HAL handle USB device events.

## What was added (Sprint 1 + Sprint 2)

Per `06_SPRINT_PLAN.md`:
- `registry` (Sprint 1 — `S1-11`) — required for Article III (offline-first).
- `cubeos-api` stack separation (Sprint 1 — `S1-12`) — independent release cycle from dashboard.
- `cubeos-dashboard` stack separation (Sprint 1 — `S1-13`).
- `wireguard` / `openvpn` / `tor` (Sprint 0 — `S0-06` / `S0-07` / `S0-08`).

## Adding a new coreapp

1. Create `coreapps/<name>/docker-compose.yml` with:
   - Port allocation inside `6000-6999` per Article V.
   - Image tag pinned to a SHA-256 digest OR a versioned tag (NOT `latest` for ARM64 compat per `00_PROJECT_OVERVIEW.md` risk `--resolve-image never`).
   - `network_mode: host` ONLY if absolutely required (justify in commit message).
   - Image MUST be present in local registry at install time (Article XIV).
2. If host-mode network: add HAL endpoint(s) for any host-config requirement.
3. Add coreapp to the access-profile gating in `api/internal/handlers/access_profile.go` if it should not appear in `standard` profile.
4. Update this file (`steering/coreapps-inventory.md`) with the new row.
5. CI on `coreapps/` repo will deploy on push to main per Article XV.

## Removing a coreapp

1. Stop the stack on every running Pi BEFORE the commit lands: `docker stack rm <name>` via dashboard or `cubeos-cli stack rm`.
2. Delete `coreapps/<name>/`.
3. Remove from this inventory file.
4. Add a migration to `api/internal/database/migrations.go` (append-only per Article XIII) that drops any orphan rows in `apps` table for the removed coreapp.
