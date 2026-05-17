# Constitution — CubeOS

The hard rules. Every contributor — human or agent — is bound by these. The merge-coordinator + `validate-project-spec.py` + per-repo CI gate enforce them. Vision/mission/scope live in [`PROJECT.md`](PROJECT.md). Decisions live in `adr/`. Source-of-truth roadmap in `claude-context/roadmap/CUBEOS_PROJECT_ROADMAP_v4.md`.

> **Scope note:** This is the **project-level constitution**. CubeOS spans multiple component repos (api project 13, dashboard project 14, hal project 22, coreapps project 19, releases project 20, …). Each component repo may add its own thinner component-scoped `constitution.md` that asserts repo-local rules, but **MUST NOT contradict** any Article here.

---

## Article I — HAL owns the host (NON-NEGOTIABLE)

The API container shall NEVER touch host services directly. ALL host operations go through HAL at `HAL_URL`. This includes (non-exhaustive): Pi-hole DHCP/DNS, hostapd WiFi AP, network mode switching, serial port allocation, GPIO, fail2ban, watchdog, systemd service management, sysctl, fstab. The X-HAL-Key header gates the HAL API; the HAL 3-layer security model (transport + identity + ACL) protects against rogue API instances.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 1. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 1. `docs/architecture/02_ARCHITECTURE.md` §Service Layers.

---

## Article II — FQDN-only communication

The system shall use `*.cubeos.cube` for inter-service addressing. Raw IP addresses are forbidden in code, compose files, and configs. The single explicit exception is `localhost:5000` for the local Docker registry, which is intentionally non-FQDN to avoid DNS dependencies during the early-boot registry-pull window.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 2.

---

## Article III — Offline-first

The system shall make every feature operate fully without internet uplink. Online connectivity may *enhance* a feature (CasaOS app store discovery, OTA updates, NTP) but it shall never be a *prerequisite* for any feature. Validation: the `offline_hotspot` network mode regression suite covers every coreapp.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 3, `01_REQUIREMENTS.md` §1.8 (Local Registry), `01_REQUIREMENTS.md` §1.6 (Network Modes).

---

## Article IV — Docker Swarm is truth

The system shall treat Docker Swarm as the single source of truth for container runtime state. The database stores *desired* state; Swarm enforces *actual* running state. ALL container operations route through one `Orchestrator` that delegates to one `SwarmManager`. Direct `docker run` is forbidden everywhere — use `docker stack deploy`. The `--task-history-limit 1` invariant must be re-asserted on every Swarm init to bound `tasks.db` memory.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 4. `00_PROJECT_OVERVIEW.md` §The Solution (the Three-Headed Hydra fix). `01_REQUIREMENTS.md` §1.2 SVC-01, SVC-04, SVC-09. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 8.

---

## Article V — Port discipline (6xxx scheme)

The system shall allocate all CubeOS-managed service ports inside the `6000-6999` range. No exceptions. Hardcoded ports outside this range in compose files or Go handlers are a constitutional violation regardless of how convenient the alternative seems. The full allocation map:

```
22, 53, 67, 80, 443   System (SSH, DNS, DHCP, HTTP)  — host-mode services
5000                   Local Docker Registry          — exception per Article II
6000-6009              Infrastructure                  (NPM:6000, Pi-hole:6001, HAL:6005)
6010-6019              Platform                        (API:6010, Dashboard:6011)
6020-6029              Network/VPN                     (WireGuard:6020, OpenVPN:6021, Tor:6022)
6030-6039              AI/ML                           (Ollama:6030, ChromaDB:6031)
6050-6059              Communication                   (MeshSat Bridge:6050)
6070-6079              MeshSat Hub                     (Hub:6070, MQTT:6071/6072)
6100-6999              User apps                       (dynamically allocated)
```

`PORT-05` explicitly requires Ollama (default `11434`) to be remapped to the 6030 range.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 5. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Port Allocation Scheme". `01_REQUIREMENTS.md` §1.4.

---

## Article VI — Managed interface = DHCP ON (rare exception)

The system shall enable Pi-hole DHCP if and only if the operator selects the `all_in_one` access profile AND designates a managed interface (WiFi AP or wired LAN). CubeOS NEVER runs DHCP on a network it doesn't explicitly own. Running DHCP on a borrowed network (e.g. operator's home LAN with an existing router) creates IP conflicts and triggers ISP complaints — both are unrecoverable from a remote-deployed Pi.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 6. `docs/architecture/13_ACCESS_PROFILES.md` §10.

---

## Article VII — Hardware detection drives capabilities

The system shall detect WiFi adapters, Ethernet interfaces, GPIO availability, USB peripherals, and serial ports at boot via HAL. Features enable/disable themselves based on detected hardware, not based on the installation method or profile selection. Example: the WiFi AP capability appears in the UI only when HAL reports a hostapd-capable interface present.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 7.

---

## Article VIII — Role-based interface assignment

The system shall reference network interfaces by ROLE (`ap_interface`, `uplink_interface`) and never by Linux device name (`wlan0`, `eth0`) in code. The roles are resolved to device names at runtime by HAL based on hardware detection (Article VII). This makes the same code work on Pi 5 (`wlan0` is the onboard radio) and external USB AP setups (`wlan1` may be the AP role, `wlan0` may be the client role).

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 8.

---

## Article IX — Serial port ownership

The system shall allow ONLY one HAL subsystem (GPS, Iridium, Meshtastic, Cellular, ZigBee, AX.25) to claim any given serial port (`/dev/tty*`). A serial port registry in HAL enforces ownership at runtime. The AT-probe protocol distinguishes modems from GPS receivers on the same physical port type. Violation = the wrong subsystem reads bytes intended for another, producing silent corruption or device lockup.

**Source:** `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principle 9.

---

## Article X — Subnet discipline (`10.42.24.0/24`)

The system shall use the `10.42.24.0/24` subnet for internal Docker bridge networking. Hardcoded subnet values are forbidden — code references the subnet via the `CUBEOS_SUBNET` env var (default `10.42.24.0/24`). The `10.42.24.x` choice deliberately avoids the common `192.168.0.0/24` and `192.168.1.0/24` ranges that collide with most consumer routers.

**Source:** `01_REQUIREMENTS.md` §1.6 `NET-07`. `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 6. `00_PROJECT_OVERVIEW.md` §Key Design Decisions.

---

## Article XI — Pure Go (`CGO_ENABLED=0`)

The system's Go components (api, hal) shall compile with `CGO_ENABLED=0`. SQLite access uses `modernc.org/sqlite` (the pure-Go driver), NEVER `mattn/go-sqlite3` (CGO-bound). This invariant unblocks cross-compilation (Pi ARM64 + x86_64 from one build host) and is the prerequisite for any future FIPS-validated build target.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 4.

---

## Article XII — Swagger annotations mandatory

Every Go HTTP handler in `api/` shall include complete Swagger annotations (`@Summary`, `@Description`, `@Tags`, `@Accept`, `@Produce`, `@Param`, `@Success`, `@Failure`, `@Router`). The `make verify-routes` target validates that the registered router routes match the Swagger documentation route set — drift on either side fails the target. The Swagger spec is the API contract; the contract IS code, not commentary.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 2. `docs/architecture/07_API_CONTRACTS.md`.

---

## Article XIII — Append-only migrations

The system's schema migrations file (`api/internal/database/migrations.go`) shall be append-only. Existing entries are NEVER edited. A schema fix that breaks an already-shipped migration is a new migration that fixes the broken one — the broken one stays in place because deployed Pi devices already ran it. Violation = data loss on upgrade.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 9. `docs/architecture/03_DATABASE_SCHEMA.md`.

---

## Article XIV — Local registry only for coreapps

The system shall pull all coreapp container images from `localhost:5000` (the local Docker registry), NEVER from Docker Hub or any other public registry at runtime. The local registry mirrors verified images and is populated at image-build time. Pulling from Docker Hub on a deployed Pi violates Article III (offline-first) and exposes the device to upstream supply-chain attacks.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 10. `01_REQUIREMENTS.md` §1.8.

---

## Article XV — Auto-deploy on push to main

The system's CI/CD pipelines deploy to Pi on every push to `main`. The contributor shall consequently treat `git push origin main` as an act of deployment. Feature work happens on feature branches; the main-branch merge is the deploy. Direct push to main is allowed for documentation-only changes that need no build but is otherwise discouraged — feature branches and MRs are the norm. Manual Pi pull/restart is FORBIDDEN — the pipeline owns the deploy.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 11. `00_PROJECT_OVERVIEW.md` §Distribution.

---

## Article XVI — Packer triggers are deliberate

The system's image-build pipeline runs ONLY on commits matching `chore: bump version to vX.Y.Z` OR explicit web-trigger. A normal feature commit shall NEVER trigger Packer. Accidental Packer runs waste 30+ minutes of build time, populate releases with unintended images, and pollute the Pi Imager manifest JSON.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 12. `docs/architecture/12_INSTALL_PUBLISH_PIPELINE.md`.

---

## Article XVII — Claude Code files are local-only

The system shall keep `CLAUDE.md`, `.claude/`, and operator memory files outside git history. Each repo's `.gitignore` MUST contain these entries. Before any commit, contributors verify that no Claude-Code-authored file has been added accidentally. Spec-kit artefacts (`PROJECT.json`, `PROJECT.md`, `constitution.md`, `spec/`, `steering/`, `adr/`, `.agentic/`) ARE meant to be committed — they are project documentation. **Only** Claude-Code-tooling files stay local.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Critical Rules" rule 13. Pattern matches the meshsat / meshsat-hub / meshsat-android `.gitignore` files post-Path-A.

---

## Article XVIII — Parallel-dev gates

The system shall enforce that no two parallelizable tasks share `files_owned` entries within the same dependency wave — validated by `validate-project-spec.py` at the Phase F gate BEFORE any worker launches. CubeOS spans multiple component repos, so a `docs/spec/<feature>/` that lists work in api+dashboard+hal MUST be decomposed by the planner into per-component child specs before dispatch. The repo's default workflow ("push directly to main") is overridden for parallel-dev waves: ONE short-lived `merge/<feature_id>` branch, ONE MR per feature, auto-delete on merge.

**Source:** `claude-gateway/scripts/validate-project-spec.py` Phase F gate. `claude-gateway/docs/runbooks/parallel-dev-feature.md`. `adr/0008-parallel-dev-workflow-override.md`.

---

## Article XIX — Operator identity on every commit

The system shall record commits across all CubeOS repos with the canonical operator identity:

- `user.name`: `Kyriakos Papadopoulos`
- `user.email`: `ncpjfuzl@mxmx.email`

Applied per-command via `git -c user.name=... -c user.email=... commit ...`. NEVER via `git config` (that violates the per-command convention and persists state that future contributors must remember to unset). `Co-Authored-By: Claude <noreply@anthropic.com>` trailer goes in the commit body as before for AI-assisted commits.

**Source:** `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` §"Commit Author Identity — ALL REPOS".
