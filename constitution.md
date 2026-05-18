# Constitution — CubeOS

The hard rules. Every contributor — human or agent — is bound by these. Vision/mission/scope live in [`PROJECT.md`](PROJECT.md). Decisions live in `adr/`. Source-of-truth roadmap in `claude-context/roadmap/CUBEOS_PROJECT_ROADMAP_v4.md`. CGC-grounded 2026-05-18.

> **Scope note:** This is the project-level constitution. CubeOS spans multiple component repos. Each component repo may add its own thinner component-scoped `constitution.md` but **MUST NOT contradict** any Article here.

## Article I — HAL owns the host (NON-NEGOTIABLE)

The API container shall NEVER touch host services directly. ALL host operations go through HAL at `HAL_URL`. CGC-verified: hal/ has 47 handler files covering Pi-hole DHCP-host-shim, hostapd via wifi_ap.go, firewall via firewall.go, systemd service control via system.go, etc. No `api/` code path shells out to `systemctl` or writes to `/etc/`.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 1. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 1.

## Article II — FQDN-only communication

The system shall use `*.cubeos.cube` for inter-service addressing. Raw IP addresses are forbidden in code, compose files, and configs. The single explicit exception: `localhost:5000` for the local Docker registry.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 2.

## Article III — Offline-first

The system shall make every feature operate fully without internet uplink. Online connectivity may enhance; it shall never be a prerequisite. Validation: the `offline_hotspot` network mode regression suite covers every coreapp.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 3.

## Article IV — Docker Swarm is truth

The system shall treat Docker Swarm as the single source of truth for container runtime state. The database stores *desired* state; Swarm enforces *actual*. ALL container operations route through the single Orchestrator (CGC-verified at api/internal/managers/orchestrator.go:27) that delegates to one SwarmManager (api/internal/managers/swarm.go). Direct `docker run` is forbidden everywhere — use `docker stack deploy`. `--task-history-limit 1` must be re-asserted on every Swarm init.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 4. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 8.

## Article V — Port discipline (6xxx scheme)

The system shall allocate all CubeOS-managed service ports inside the `6000-6999` range. CGC-verified: PortManager at api/internal/managers/ports_new.go enforces the 6100-6999 user-app subrange.

Allocation map:

```
22, 53, 67, 80, 443   System (SSH, DNS, DHCP, HTTP) — host-mode services
5000                   Local Docker Registry — exception per Article II
6000-6009              Infrastructure                  (NPM:6000, Pi-hole:6001, HAL:6005)
6010-6019              Platform                        (API:6010, Dashboard:6011)
6020-6029              Network/VPN                     (WireGuard:6020, OpenVPN:6021, Tor:6022)
6030-6039              AI/ML                           (Ollama:6030, ChromaDB:6031)
6050-6059              Communication                   (MeshSat Bridge:6050)
6070-6079              MeshSat Hub                     (Hub:6070, MQTT:6071/6072)
6100-6999              User apps (dynamically allocated by PortManager)
```

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 5.

## Article VI — Managed interface = DHCP ON (rare exception)

The system shall enable Pi-hole DHCP if and only if the operator selects the `all_in_one` access profile AND designates a managed interface. CubeOS NEVER runs DHCP on a network it doesn't explicitly own.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 6.

## Article VII — Hardware detection drives capabilities

The system shall detect WiFi adapters, Ethernet interfaces, GPIO availability, USB peripherals, and serial ports at boot via HAL. Features enable/disable themselves based on detected hardware, not based on installation method or profile selection.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 7.

## Article VIII — Role-based interface assignment

The system shall reference network interfaces by ROLE (`ap_interface`, `uplink_interface`) and never by Linux device name (`wlan0`, `eth0`) in code. Roles are resolved to device names at runtime by HAL based on hardware detection.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 8.

## Article IX — Serial port ownership

The system shall allow ONLY one HAL subsystem (GPS, Iridium, Meshtastic, Cellular, ZigBee, AX.25) to claim any given serial port (`/dev/tty*`). Violation = silent corruption.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 9.

## Article X — Subnet discipline (`10.42.24.0/24`)

The system shall use the `10.42.24.0/24` subnet for internal Docker bridge networking. Hardcoded subnet values are forbidden — code references the subnet via the `CUBEOS_SUBNET` env var (default `10.42.24.0/24`).

**Source:** `01_REQUIREMENTS.md` §1.6 `NET-07`.

## Article XI — Pure Go (`CGO_ENABLED=0`)

The system's Go components (api, hal) shall compile with `CGO_ENABLED=0`. SQLite access uses `modernc.org/sqlite` (the pure-Go driver), NEVER `mattn/go-sqlite3`.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 4.

## Article XII — Swagger annotations mandatory

Every Go HTTP handler in `api/` shall include complete Swagger annotations. The `make verify-routes` target validates that registered router routes match the Swagger documentation route set. CGC-verified: `api/scripts/verify-routes.sh` exists.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 2.

## Article XIII — Append-only migrations

The system's schema migrations file (`api/internal/database/migrations.go`) shall be append-only. Existing entries are NEVER edited. CGC-verified: `CurrentSchemaVersion = 27` at `api/internal/database/schema.go:13`. The roadmap dated 2026-02-28 cited v24; live code is v27, so 3 migrations have been added since the roadmap was written without breaking append-only.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 9.

## Article XIV — Local registry only for coreapps

The system shall pull all coreapp container images from `localhost:5000`, NEVER from Docker Hub or any other public registry at runtime.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 10.

## Article XV — Auto-deploy on push to main

The system's CI/CD pipelines deploy to Pi on every push to `main`. Treat `git push origin main` as an act of deployment. Manual Pi pull/restart is FORBIDDEN.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 11.

## Article XVI — Packer triggers are deliberate

The system's image-build pipeline runs ONLY on commits matching `chore: bump version to vX.Y.Z` OR explicit web-trigger. Normal feature commits NEVER trigger Packer.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 12.

## Article XVII — Claude Code files are local-only

The system shall keep `CLAUDE.md`, `.claude/`, and operator memory files outside git history. Spec-kit artefacts (`PROJECT.json`, `PROJECT.md`, `constitution.md`, `spec/`, `steering/`, `adr/`, `.agentic/`) ARE meant to be committed — they are project documentation.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 13.

## Article XVIII — Parallel-dev gates

The system shall enforce that no two parallelizable tasks share `files_owned` entries within the same dependency wave — validated by `validate-project-spec.py` at the Phase F gate BEFORE any worker launches. CubeOS spans multiple component repos, so a `docs/spec/<feature>/` that lists work in api+dashboard+hal MUST be decomposed by the planner into per-component child specs before dispatch. The repo's default workflow is overridden for parallel-dev waves: ONE short-lived `merge/<feature_id>` branch, ONE MR per feature, auto-delete on merge.

**Source:** `claude-gateway/scripts/validate-project-spec.py` Phase F gate. `claude-gateway/docs/runbooks/parallel-dev-feature.md`.

## Article XIX — Operator identity on every commit

The system shall record commits across all CubeOS repos with the canonical operator identity:

- `user.name`: `Kyriakos Papadopoulos`
- `user.email`: `ncpjfuzl@mxmx.email`

Applied per-command via `git -c user.name=... -c user.email=... commit ...`. NEVER via `git config`.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Commit Author Identity — ALL REPOS".
