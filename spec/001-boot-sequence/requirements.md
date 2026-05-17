# Requirements — Boot sequence (spec/001)

Source: `architecture/04_BOOT_SEQUENCE.md` + `01_REQUIREMENTS.md` §1.1 (`BOOT-01..10`) + `CUBEOS_PROJECT_ROADMAP_v4.md` §3 principles 4, 7.

> ID convention: this feature uses the 100-block (`100..199`) per the repo-wide REQ-uniqueness rule.

## Functional requirements

### Boot orchestration

REQ-100: The system shall initialize Docker Swarm via `swarm init --task-history-limit 1` on first boot if no Swarm state exists.
REQ-101: The system shall start coreapps in the order pihole, npm, cubeos-api, cubeos-dashboard, cubeos-hal, dozzle, network-layer, ai-layer, user apps.
REQ-102: The system shall not start any user-facing coreapp before pihole is healthy.
REQ-103: The system shall not start cubeos-api before the SQLite database initializes.
REQ-104: When the active profile is `all_in_one`, the system shall start hostapd only after Pi-hole DHCP is ready.

### First-boot detection

REQ-105: When `/cubeos/data/.setup_complete` is absent, the system shall mark the boot as first-boot.
REQ-106: While the boot is marked first-boot, the system shall present the setup wizard at `https://cubeos.cube` and not start the full service stack.
REQ-107: When the operator completes the wizard, the system shall write `/cubeos/data/.setup_complete` atomically and then start the full coreapp stack.

### Recovery boot

REQ-108: When `/cubeos/data/.setup_complete` is present, the system shall classify the boot as recovery-boot and restore all coreapps to their last-known state.
REQ-109: If a coreapp fails to start during recovery, then the system shall record the failure to `/cubeos/data/boot.log` and continue with the remaining coreapps.

### Hardware watchdog

REQ-110: While the system is running, the watchdog daemon shall pet `/dev/watchdog` every 5 seconds with a hardware timeout of 15 seconds.
REQ-111: If the kernel hangs for more than 15 seconds without watchdog pet, then the hardware shall reset the board.

### Boot budget

REQ-112: The system shall complete the boot sequence within 90 seconds on Raspberry Pi 5.
REQ-113: If the boot budget is exceeded, then the system shall log the slow-boot event with per-step timings to `/cubeos/data/boot.log`.

### Boot-state introspection API

REQ-114: The system shall expose `GET /api/v1/system/boot` returning the current boot phase, completion timestamps for each coreapp, and any failures.
REQ-115: While boot is incomplete, the dashboard shall display a boot-progress UI driven by `GET /api/v1/system/boot`.

### Resilience

REQ-116: If the boot sequence is interrupted by power loss, then the next boot shall resume from the last-known coreapp state with no data corruption.
REQ-117: If the SQLite database is corrupted on boot, then the system shall attempt restoration from `/cubeos/data/backups/cubeos.db.last-known-good` and log the restoration event.

### Profile + mode persistence

REQ-118: The system shall persist the active access profile and network mode across boots in SQLite and read both before deciding which coreapps to start.
REQ-119: While the active mode is `offline_hotspot`, the system shall not start any coreapp that requires internet uplink.

### Audit

REQ-120: The system shall write a structured boot summary to `/cubeos/data/audit.log` on every successful boot completion.
