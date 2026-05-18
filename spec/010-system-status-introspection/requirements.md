# Requirements — System status introspection (spec/010)

Source: `01_REQUIREMENTS.md` §1.2 + roadmap §2 (HAL row "Testing 65/100").

> Future-work. ID convention: 1000-block.

REQ-1000: The system shall expose `GET /api/v1/system/status` returning CPU usage %, RAM used/total, disk used/total per mount, system temperature C, uptime seconds.
REQ-1001: The system shall sample metrics every 5 seconds in-process and serve cached values to minimize per-request overhead.
REQ-1002: The system shall include hardware-specific metrics from HAL: GPS lock, Iridium signal bars, Meshtastic neighbor count, ZigBee coordinator state.
REQ-1003: The system shall expose `GET /api/v1/system/health` returning JSON of per-coreapp health + per-subsystem health.
REQ-1004: When any subsystem reports `unhealthy`, the system shall include a `remediation` field with actionable next steps.
REQ-1005: The system shall expose `GET /api/v1/system/health?expanded=true` returning per-check detail.
REQ-1006: The system shall expose `GET /api/v1/system/stacks/{stack}/resources` returning CPU + memory + network IO per service replica.
REQ-1007: While the operator is on the Swarm GUI view, the dashboard shall poll `/system/stacks/*/resources` every 5 seconds.
REQ-1008: The system shall expose `GET /api/v1/system/audit` paginated with `from`, `to`, `event_type`, `actor` filters.
REQ-1009: While the audit log file is rotated, the system shall include the previous N rotated files in the search corpus (default 30 days).
REQ-1010: The system shall expose `GET /api/v1/system/boot/history` returning the last 50 boot summaries.
REQ-1011: The system shall expose `GET /api/v1/system/hardware` returning detected hardware: SoC, CPU, RAM, disks, WiFi adapters, USB devices, GPIO availability, serial ports.
REQ-1012: When a hardware change is detected at runtime, the system shall push a WebSocket event to subscribed dashboards.
REQ-1013: The system shall provide `cubeos-cli system status`, `system health`, `system hardware` commands.
REQ-1014: The system shall provide `cubeos-cli system health` that exits non-zero if any subsystem is unhealthy.
REQ-1015: The system shall optionally expose Prometheus-format metrics at `GET /metrics` when the operator enables the `prometheus_exporter` feature flag.
REQ-1016: The system shall scrape its own metrics every 5 seconds when the flag is enabled.
REQ-1017: The system shall NEVER include user data (file paths, container env vars with secrets, network credentials) in any status / health / metrics response.
REQ-1018: The system shall redact secret-bearing env vars from any process listing (keys matching `*_SECRET`, `*_KEY`, `*_TOKEN`, `*_PASSWORD` → `[REDACTED]`).
