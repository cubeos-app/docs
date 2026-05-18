# Steering — Coreapps inventory

The set of services CubeOS ships and runs as Docker Swarm stacks. Curated from `architecture/05_COREAPPS_INVENTORY.md` (CGC-grounded against `coreapps/` filesystem 2026-05-18).

## What is a coreapp?

A *coreapp* is a service whose docker-compose definition ships in the `coreapps/` repo (project 19) and is deployed automatically on first boot. User-installed apps come from the CasaOS-compatible app store but are NOT coreapps.

Coreapps are versioned alongside the CubeOS release. Updating a coreapp = bumping its compose file = triggers per-component CI = re-deploys to all running Pis on push to main per Article XV.

## Infrastructure layer (host-mode)

| Coreapp | Port(s) | Purpose |
|---|---|---|
| `pihole` | 53, 67, 80 (managed) | DNS + DHCP (DHCP only when Article VI condition holds) |
| `npm` | 80, 443, 81 | Reverse proxy + cert termination + admin UI |
| `registry` | 5000 | Local Docker registry per Article XIV |

## Platform layer (bridge mode)

| Coreapp | Port | Purpose |
|---|---:|---|
| `cubeos-api` | 6010 | Backend REST API + Orchestrator + FlowEngine |
| `cubeos-dashboard` | 6011 | Vue 3 frontend + Swarm GUI (`components/swarm/`) |
| `cubeos-hal` | 6005 | Privileged HAL (per hal/PROJECT.md) |
| `dozzle` | 6012 | Real-time container log viewer |

## Network / VPN layer

| Coreapp | Port | Purpose |
|---|---:|---|
| `wireguard` | 51820 | Per-app VPN routing |
| `openvpn` | 6021 | OpenVPN client + admin UI |
| `tor` | 6022 | SOCKS5 proxy for Tor routing |

## AI/ML layer

| Coreapp | Port | Purpose |
|---|---:|---|
| `ollama` | 6030 | LLM inference (PORT-05 required remap from 11434) |
| `chromadb` | 6031 | Vector database for RAG |
| `docs-indexer` | 6032 | Local docs RAG indexer (consumes `docsindex/`) |

## Removed in Sprint 0 cleanup

- `dockge` — replaced by built-in Swarm GUI in dashboard (`components/swarm/`)
- `gpio`, `nettools`, `usb-monitor` — moved into HAL (handlers/gpio.go, handlers/network*, handlers/usb.go)

## Adding a new coreapp

1. Create `coreapps/<name>/docker-compose.yml` with:
   - Port allocation inside `6000-6999` per Article V
   - Image tag pinned (NEVER `latest` for ARM64 compat)
   - `network_mode: host` ONLY if absolutely required
   - Image MUST be in local registry at install time (Article XIV)
2. If host-mode: add HAL endpoint(s) for host-config.
3. Add to access-profile gating in `api/internal/handlers/profiles.go` if not in `standard`.
4. Update this file.
5. Push to main → CI auto-deploys.
