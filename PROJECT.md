# Project Charter — CubeOS

> Operator-facing charter. Vision, mission, scope, deliverables, success metrics. Authored 2026-05-17 by curating the strategic documents listed in **Source Trace** at the foot of this file. Machine-readable companion: `PROJECT.json`. Hard rules: `constitution.md`. Decisions: `adr/`.

---

## Vision

**A self-hosted operating system that anyone can install on a Raspberry Pi, ARM64 SBC, or x86/amd64 box and get a complete personal cloud — offline-first, with no subscription, no telemetry, and no dependency on any commercial cloud provider.**

CubeOS is what happens when you take the "homelab Docker Compose stack" pattern that ~100,000 self-hosters maintain by hand, productise it into an opinionated immutable image, and ship it via the official Raspberry Pi Imager catalog. The user picks CubeOS in `rpi-imager`, flashes an SD card, boots the Pi, and 90 seconds later has a dashboard, a DNS sinkhole (Pi-hole), a reverse proxy (NPM), a local container registry, an app store, and one-click installable apps — all unified under one API and one Vue dashboard, all reachable on the local network without any cloud round-trip.

Source: `docs/architecture/00_PROJECT_OVERVIEW.md` §Executive Summary + `CUBEOS_PROJECT_ROADMAP_v4.md` §1.

## Mission

Be the **operating system layer** for self-hosted infrastructure that:

1. **Works completely offline.** Every feature must be usable without internet. Internet enhances; it is never a prerequisite. (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 3.)
2. **Treats Docker Swarm as the single source of truth** for container runtime state. The Three-Headed Hydra problem (Services + AppManager + AppStore independently calling Docker) is fixed by routing every container operation through one Orchestrator that delegates to one SwarmManager. (Source: `docs/architecture/00_PROJECT_OVERVIEW.md` §The Solution.)
3. **Owns the host entirely through HAL.** API containers NEVER touch host services directly. Pi-hole DHCP, hostapd WiFi AP, network mode switching, serial port allocation, GPIO — all go through HAL at `HAL_URL`. (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 1.)
4. **Ships official Raspberry Pi Imager listings**, not just `.img.gz` downloads. The user experience target is: "Pick CubeOS in the official Pi Imager → flash → boot → done." (Source: `docs/architecture/10_RASPBERRY_PI_IMAGER.md`.)
5. **Supports the multi-track product family** — Track A (Platform), Track B (MeshSat Bridge running on CubeOS), Track C (Hardware integrations), Track D (MeshSat Hub running on CubeOS). All tracks share the same OS substrate, port discipline, and HAL boundary. (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §4.)

## Scope (in / out)

**In scope — what CubeOS itself does:**

1. **Boot sequence** — `cubeos-init.service` runs first-boot setup wizard; recovery boot restores last-known state; hardware watchdog enabled at boot; 90s boot budget on Pi 5. (Source: `docs/architecture/04_BOOT_SEQUENCE.md`, `docs/architecture/01_REQUIREMENTS.md` §1.1.)
2. **Service management** — every coreapp + user-app deployed as a Docker Swarm stack; Swarm reconciliation handles failure recovery; built-in Swarm GUI in dashboard; `--task-history-limit 1` to bound memory. (Source: `01_REQUIREMENTS.md` §1.2.)
3. **App installation** — CasaOS-compatible app store + local-registry offline path; automatic port allocation (6100-6999) + FQDN assignment (`*.cubeos.cube`) + NPM proxy + Pi-hole DNS entries on install; full cleanup on uninstall. (Source: `01_REQUIREMENTS.md` §1.3, `docs/architecture/08_LOCAL_REGISTRY.md`.)
4. **Network modes** — six modes shipped: `offline_hotspot`, `wifi_router`, `wifi_bridge`, `android_tether`, `wifi_client`, `eth_client` (the canonical v4 mode names; earlier v3 names like `OFFLINE` / `ONLINE_ETH` / `ONLINE_WIFI` were the three-mode predecessor, now superseded). Mode switchable via dashboard; firewall rules auto-applied per mode. (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2, `docs/network-modes.md`.)
5. **Access profiles** — three profiles (`standard`, `advanced`, `all_in_one`) gating capability surface; `all_in_one` is the only profile that enables managed-interface DHCP (Pi-hole runs DHCP only when explicitly selected). (Source: `docs/architecture/13_ACCESS_PROFILES.md`, `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 6.)
6. **VPN + privacy stack** — WireGuard, OpenVPN, Tor as coreapps; per-app Tor routing toggle. (Source: `01_REQUIREMENTS.md` §1.7.)
7. **Hardware abstraction (HAL)** — 14 hardware categories, 80+ endpoints, X-HAL-Key ACL, serial-port ownership registry (no two HAL subsystems claim the same `/dev/tty*`). (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 9.)
8. **Distribution** — `get.cubeos.app` curl installer + official Raspberry Pi Imager JSON manifest + GitHub + GitLab releases. (Source: `01_REQUIREMENTS.md` §1.10, `docs/architecture/10_RASPBERRY_PI_IMAGER.md`, `docs/architecture/12_INSTALL_PUBLISH_PIPELINE.md`.)
9. **Multi-platform** — Pi 5 (primary), Pi 4 (community), x86_64 LXC (Proxmox), x86_64 bare-metal. BananaPi deferred by choice. (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2.)
10. **OTA updates** — assessed in `docs/architecture/11_OTA_ASSESSMENT.md`; current decision: per-component CI auto-deploy on push to main, image-level OTA deferred (see `adr/0007-ota-strategy.md`). (Source: `adr/0007-ota-strategy.md` extending existing `decisions/adr-ota-updates.md`.)

**Out of scope (explicitly non-goals for v1.0):**

1. **Multi-node Swarm clustering** — architecture supports it, implementation deferred to post-v1. (Source: `00_PROJECT_OVERVIEW.md` §Non-Goals.)
2. **Kubernetes migration** — explicitly rejected; complexity-to-value ratio wrong for single-node edge. (Source: ibid.)
3. **Custom orchestrator** — use Swarm; do not write a CubeOS-specific orchestrator. (Source: ibid.)
4. **Third-party Swarm GUI** — build our own in dashboard, no Portainer/Swarmpit dependency. (Source: ibid.)
5. **Cloud telemetry** — no phone-home; CubeOS is offline-first, period.

## Deliverables (current state, per roadmap §2)

| Dimension              | Score    | Verified fact                                                                                                  |
|------------------------|---------:|----------------------------------------------------------------------------------------------------------------|
| Frontend / Dashboard   | 95/100   | 144+ Vue components, 9 pages, 29 Pinia stores, dual mode, responsive, Access Profiles UI                        |
| Backend API            | 92/100   | 79+ Go files, 375+ Swagger endpoints, schema v24, FlowEngine operational, Access Profiles                       |
| HAL                    | 90/100   | 40+ Go files, 80+ endpoints, 14 hardware categories, serial port registry, Iridium support                      |
| Infrastructure         | 88/100   | Swarm running, CI/CD via SSH, Packer pipeline, parallel Full+Lite, x86 Packer templates                         |
| Security               | 82/100   | SSH hardening, fail2ban, sysctl, watchdog, HAL 3-layer security, X-HAL-Key ACL                                  |
| Testing                | 65/100   | Integration tests in CI, 26 alpha QA + 3 x86 QA rounds, Pi regression suite                                     |
| Distribution           | 75/100   | beta.03 released, curl installer, get.cubeos.app live, GitHub + GitLab releases                                 |
| **Overall**            | **90/100** | Production-ready platform, multi-platform verified on Pi 5 + x86 LXC                                          |

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "Current State Snapshot" (dated 2026-02-28).

## Success metrics

1. **`pi-imager-cubeos-listing-shipped == true`** — official Raspberry Pi Foundation Imager catalog includes CubeOS. Pending submission (last remaining item of Phase 5).
2. **`time-from-flash-to-dashboard < 5 min`** — operator boots a fresh CubeOS Pi and reaches the dashboard's first-boot wizard in under 5 minutes. (Sub-metric: boot sequence completes in <90s per `BOOT-09`.)
3. **`offline-uptime == 100%`** — every coreapp continues operating when internet uplink drops. Validated by `network-modes.md` `offline_hotspot` regression suite.
4. **`zero-cross-tenant-leak`** — CubeOS itself is single-tenant; this metric matters for MeshSat Hub (Track D) running ON CubeOS. Tracked separately in `meshsat-hub/PROJECT.md`.
5. **`hal-boundary-violations == 0`** — every code review surfaces zero attempts to call host services from inside API containers. Enforced by `scripts/pre-commit-check.sh`.
6. **`pi5-boot-to-90s`** — `BOOT-09` is currently a `Medium` priority requirement; ship verification gated on Phase 8 polish.
7. **`schema-v24-stable`** — no schema rollbacks; v24→v25 only happens via append-only migration. (`docs/architecture/03_DATABASE_SCHEMA.md` defines invariants.)

## Constraints

1. **Hardware floor:** Raspberry Pi 4 / 4GB minimum. Pi 5 / 8GB is the development target.
2. **Network floor:** boot must succeed without DHCP server present; CubeOS provides its own DHCP via Pi-hole in `all_in_one` profile.
3. **Storage floor:** 16 GB SD card minimum; recommended 64 GB+ for app store usage.
4. **Single developer + AI-assisted, 50+ hrs/week** — sequencing matters more than speed. (Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §1.)
5. **No hard deadline** — optimize for correct sequencing over speed. (Source: ibid.)

## Risks (top 5 from `00_PROJECT_OVERVIEW.md` §Risk Assessment)

| Risk                                              | Impact   | Mitigation                                              |
|---------------------------------------------------|----------|---------------------------------------------------------|
| Swarm instability on Pi                           | High     | Test thoroughly, use `--task-history-limit 1`           |
| Pi-hole DHCP breaks                               | Critical | Keep `network_mode: host`, test first                   |
| Memory exhaustion via `tasks.db`                  | Medium   | Set `task-history-limit 1`, monitor                     |
| ARM64 architecture mismatch on app installs       | Medium   | Use `--resolve-image never` workaround                  |
| Extended downtime during major migrations         | Medium   | Prepare rollback SD card; freeze-and-reflash supported  |

## Tracks (per roadmap §4)

CubeOS is the substrate for four parallel tracks:

- **Track A — CubeOS Platform** (Phases 1-12, 7 marked DONE, 1 mostly-done, 4 planned)
- **Track B — MeshSat Bridge** (runs on CubeOS; spec home in `meshsat/`)
- **Track C — Hardware** (GPS/NTP/Smart Power/Kiosk Display/SDR/Radio/Yggdrasil mesh)
- **Track D — MeshSat Hub** (runs on CubeOS Tier 2 cluster; spec home in `meshsat-hub/`)

This `docs/` repo owns **Track A** spec coverage; sister repos own B/D. Hardware (Track C) spans HAL component repo + per-device coreapp definitions in `coreapps/`.

## Relationship to other repos

| Repo                  | Role                                                                        |
|-----------------------|-----------------------------------------------------------------------------|
| `docs/` (this repo)   | **Spec home + user docs + architecture reference**                          |
| `api/`                | Implementation of the backend API + Orchestrator + FlowEngine               |
| `dashboard/`          | Implementation of the Vue 3 frontend + Swarm GUI                            |
| `hal/`                | Implementation of the Hardware Abstraction Layer                            |
| `coreapps/`           | Docker Swarm stack definitions for every coreapp                            |
| `releases/`           | Packer image builder + Pi Imager manifest                                   |
| `docsindex/`          | Local docs search index (consumes content from `docs/`)                     |
| `website/`            | `cubeos.app` marketing site (consumes content from `docs/`)                 |
| `meshsat/`            | MeshSat Bridge — Track B product running on CubeOS                          |
| `meshsat-hub/`        | MeshSat Hub — Track D product running on CubeOS Tier 2 cluster              |
| `meshsat-android/`    | Companion mobile app for MeshSat Bridge                                     |

## Source trace

Every requirement in `spec/`, every principle in `constitution.md`, every decision in `adr/` cites at least one of:

1. `claude-context/roadmap/CUBEOS_PROJECT_ROADMAP_v4.md` (canonical roadmap, dated 2026-02-28, ~499 lines, 4 tracks × 12 phases × 9 principles)
2. `claude-context/roadmap/CUBEOS_FULL_EXECUTION_PLAN_v4.md` (task-level companion, ~584 lines)
3. `docs/architecture/00_PROJECT_OVERVIEW.md` through `13_ACCESS_PROFILES.md` (14 docs, ~6,000 lines)
4. `docs/decisions/adr-ota-updates.md` (existing ADR, extended in `adr/0007-*`)
5. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` (cross-cutting rules — HAL boundary, no CGO, 6xxx port scheme, etc.)
6. `docs/network-modes.md` (6 network modes, validated by regression suite)
7. `docs/backup-restore.md` (backup architecture)
8. `docs/developer-guide.md` (developer onboarding)

Operators may grep any REQ-NNN or constitution Article against this source set to verify lineage.
