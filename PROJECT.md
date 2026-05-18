# Project Charter — CubeOS

> Operator-facing charter. Vision, mission, scope, deliverables, success metrics. CGC-grounded 2026-05-18 (audit: `claude-gateway/docs/sdd-audits/docs-cgc-2026-05-18.md`). Machine-readable companion: `PROJECT.json`. Hard rules: `constitution.md`.

## Vision

A self-hosted operating system anyone can install on a Raspberry Pi, ARM64 SBC, or x86/amd64 box and get a complete personal cloud — offline-first, with no subscription, no telemetry, and no dependency on any commercial cloud provider.

The user picks CubeOS in `rpi-imager`, flashes an SD card, boots the Pi, and 90 seconds later has a dashboard, a DNS sinkhole (Pi-hole), a reverse proxy (NPM), a local container registry, an app store, and one-click installable apps — all unified under one API and one Vue dashboard, all reachable on the local network without any cloud round-trip.

Source: `docs/architecture/00_PROJECT_OVERVIEW.md` §Executive Summary + `CUBEOS_PROJECT_ROADMAP_v4.md` §1.

## Mission

Be the operating-system layer for self-hosted infrastructure that:

1. **Works completely offline** — every feature usable without internet uplink.
2. **Treats Docker Swarm as the single source of truth** for container runtime state (per roadmap principle 4).
3. **Owns the host entirely through HAL** — API containers NEVER touch host services directly (per roadmap principle 1).
4. **Ships official Raspberry Pi Imager listings** — not just `.img.gz` downloads.
5. **Supports the multi-track product family** — Track A (Platform), Track B (MeshSat Bridge running on CubeOS), Track C (Hardware integrations), Track D (MeshSat Hub running on CubeOS).

## Scope (CGC-verified shipping facts, 2026-05-18)

**In scope:**

1. **Boot sequence** — `cubeos-init.service` first-boot vs recovery-boot decision, Swarm init with `--task-history-limit 1`, full coreapp stack start. Spec: `spec/001-boot-sequence`.
2. **Service management** — every coreapp + user-app deployed as Docker Swarm stack; PortManager (api/internal/managers/ports_new.go, CGC-verified) allocates user-app ports in 6100-6999.
3. **App installation** — Orchestrator (api/internal/managers/orchestrator.go:27) routes lifecycle through 12 FlowEngine workflows (api/internal/flowengine/workflows/) composed from 14 activities (api/internal/flowengine/activities/).
4. **Network modes** — 6 modes (offline_hotspot, wifi_router, wifi_bridge, android_tether, wifi_client, eth_client). FlowEngine workflow at api/internal/flowengine/workflows/network_mode_switch.go. HAL applier at hal/internal/handlers/network.go + wifi_ap.go + firewall.go.
5. **Access profiles** — 3 profiles (standard, advanced, all_in_one). Workflow at api/internal/flowengine/workflows/access_profile_switch.go. Handler at api/internal/handlers/profiles.go. UI at dashboard/src/components/settings/AccessProfileSettings.vue + ProfileSwitchProgressModal.vue + ProfilesTab.vue.
6. **VPN + privacy** — WireGuard, OpenVPN, Tor exposed via hal/internal/handlers/vpn.go.
7. **HAL** — 47-file handler subsystem covering: system, power, RTC, watchdog, network, firewall, VPN, storage, GPS, cellular, Meshtastic, Iridium, camera, sensors, audio, GPIO, I2C, bluetooth, USB, mounts, hardware, logs.
8. **Distribution** — `get.cubeos.app` curl installer + official Pi Imager JSON manifest. Spec: `spec/003-rpi-imager`.
9. **Multi-platform** — Pi 5 (primary), Pi 4, x86_64 LXC, x86_64 bare-metal.
10. **OTA updates** — per-component CI auto-deploy on push to main; image-level OTA deferred. ADR: `adr/0007-ota-strategy.md`.

**Out of scope (per roadmap §Non-Goals):**

1. Multi-node Swarm clustering (architecture supports it, post-v1).
2. Kubernetes migration (explicitly rejected).
3. Custom orchestrator (use Swarm).
4. Third-party Swarm GUI (build our own — `dashboard/src/components/swarm/`).
5. Cloud telemetry.

## Deliverables (CGC-verified state, 2026-05-18)

| Dimension | Score (roadmap v4) | CGC-verified fact |
|---|---:|---|
| Frontend / Dashboard | 95/100 | 144+ Vue components incl. `components/swarm/{SwarmOverview,StackList}.vue`, `components/settings/{AccessProfileSettings,ProfileSwitchProgressModal,ProfilesTab}.vue`, `components/wizard/FirstBootWizard.vue` |
| Backend API | 92/100 | 35+ handler files; 28+ managers; 12 FlowEngine workflows + 14 activities; **schema v27** (roadmap dated v24, has advanced) |
| HAL | 90/100 | 47 handler files across 22 functional domains; 4 internal/ packages |
| Infrastructure | 88/100 | Swarm running, CI/CD via SSH |
| Security | 82/100 | SSH hardening + fail2ban + watchdog + HAL 3-layer ACL (core/meshsat/readonly) |
| **Overall** | **90/100** | Production-ready |

## Success metrics

1. `pi-imager-cubeos-listing-shipped == true` — last item of Phase 5.
2. `time-from-flash-to-dashboard < 5 min` — operator boots fresh CubeOS Pi → dashboard wizard in <5 min.
3. `offline-uptime == 100%` — every coreapp continues operating when internet uplink drops.
4. `hal-boundary-violations == 0` — every code review surfaces zero attempts to call host services from API containers.

## Tracks (per roadmap §4)

- **Track A — CubeOS Platform** (Phases 1-12, 7 marked DONE, 1 mostly-done, 4 planned)
- **Track B — MeshSat Bridge + Android** (spec home in `meshsat/` + `meshsat-android/`)
- **Track C — Hardware** (GPS/NTP/Smart Power/Kiosk Display/SDR/Radio/Yggdrasil mesh)
- **Track D — MeshSat Hub** (spec home in `meshsat-hub/`)

This `docs/` repo owns Track A spec coverage. Sister repos own B/C/D.

## Source trace

Every requirement, principle, ADR cites at least one of:

1. `claude-context/roadmap/CUBEOS_PROJECT_ROADMAP_v4.md` (canonical roadmap, dated 2026-02-28)
2. `claude-context/roadmap/CUBEOS_FULL_EXECUTION_PLAN_v4.md`
3. `docs/architecture/00_PROJECT_OVERVIEW.md` through `13_ACCESS_PROFILES.md` (14 docs)
4. `docs/decisions/adr-ota-updates.md`
5. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md`
6. **CGC index** of api/, hal/, dashboard/, meshsat/, meshsat-hub/, meshsat-android/ (CGC audit: `claude-gateway/docs/sdd-audits/docs-cgc-2026-05-18.md`)
