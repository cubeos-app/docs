# Requirements — System status introspection (spec/010)

Source: `01_REQUIREMENTS.md` §1.2 SVC-08 + `CUBEOS_PROJECT_ROADMAP_v4.md` §2 (HAL row "Testing 65/100" + need for better in-product diagnostics).

> ID convention: 1000-block (`1000..1099`).

## Functional requirements

### System metrics endpoint

REQ-1000: The system shall expose `GET /api/v1/system/status` returning CPU usage %, RAM used/total, disk used/total per mount, system temperature C, uptime seconds.
REQ-1001: The system shall sample metrics every 5 seconds in-process and serve cached values to minimize per-request overhead.
REQ-1002: The system shall include hardware-specific metrics from HAL: GPS lock status, Iridium signal bars, Meshtastic neighbor count, ZigBee coordinator state.

### Health probes

REQ-1003: The system shall expose `GET /api/v1/system/health` returning JSON of per-coreapp health (`healthy` / `degraded` / `unhealthy`) + per-subsystem health (HAL, Swarm, Pi-hole DNS, NPM, registry).
REQ-1004: When any subsystem reports `unhealthy`, the system shall include a `remediation` field with actionable next steps.
REQ-1005: The system shall expose `GET /api/v1/system/health?expanded=true` returning the full per-check result set (one JSON object per probe).

### Per-coreapp resource visibility

REQ-1006: The system shall expose `GET /api/v1/system/stacks/{stack}/resources` returning CPU + memory + network IO per service replica.
REQ-1007: While the operator is on the Swarm GUI view, the dashboard shall poll `/system/stacks/*/resources` every 5 seconds and render sparklines.

### Audit log access

REQ-1008: The system shall expose `GET /api/v1/system/audit` paginated with `from`, `to`, `event_type`, `actor` filters returning audit events from `/cubeos/data/audit.log`.
REQ-1009: While the audit log file is rotated, the system shall include the previous N rotated files in the search corpus (configurable; default 30 days).

### Boot summary access

REQ-1010: The system shall expose `GET /api/v1/system/boot/history` returning the last 50 boot summaries from spec/001 REQ-120 audit events.

### Hardware enumeration

REQ-1011: The system shall expose `GET /api/v1/system/hardware` returning detected hardware: SoC model, CPU model+cores, RAM total, disk model+size, WiFi adapters with chipsets, USB devices, GPIO availability, serial ports.
REQ-1012: When a hardware change is detected at runtime (USB hotplug), the system shall push a WebSocket event to subscribed dashboards.

### CLI mirror

REQ-1013: The system shall provide a `cubeos-cli system status` command that prints a terse text summary of `/system/status` + `/system/health`.
REQ-1014: The system shall provide a `cubeos-cli system health` command that exits non-zero if any subsystem is unhealthy (suitable for cron-based monitoring).
REQ-1015: The system shall provide a `cubeos-cli system hardware` command that prints the hardware enumeration as a table.

### Prometheus exposition (optional)

REQ-1016: The system shall optionally expose Prometheus-format metrics at `GET /metrics` when the operator enables the `prometheus_exporter` feature flag.
REQ-1017: The system shall scrape its own metrics every 5 seconds when the flag is enabled and include the standard `go_*` + `process_*` collectors.

### Privacy

REQ-1018: The system shall NEVER include user data (file paths, container env vars containing secrets, network credentials) in any status / health / metrics response.
REQ-1019: The system shall redact secret-bearing env vars from any process listing returned by status endpoints (env var keys matching `*_SECRET`, `*_KEY`, `*_TOKEN`, `*_PASSWORD` redacted to `[REDACTED]`).
