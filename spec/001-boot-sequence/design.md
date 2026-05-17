# Design — Boot sequence (spec/001)

Implementation of the boot sequence (REQ-100..120) is split across `releases/` (image), `hal/` (privileged systemd unit), `api/` (boot-state API), `dashboard/` (boot-progress UI). This spec lives in `docs/` because the boot sequence is a project-level concern that spans those component repos.

## Wire diagram

```
power-on
   │
   ▼
+---------------+
| Pi firmware   |
| → kernel       |
| → systemd     |
+---------------+
   │
   ▼
+---------------+
| cubeos-init   | (systemd unit, owned by hal repo)
| service       | - mount /cubeos data partition
+---------------+ - check .setup_complete
   │              - decide first-boot vs recovery
   │              - swarm init --task-history-limit 1 (first-boot only)
   ▼
+----------------+
| pihole stack   | (host mode)
+----------------+
   │ (healthy)
   ▼
+----------------+
| npm stack      | (host mode)
+----------------+
   │
   ▼
+----------------+
| cubeos-api     | (bridge mode, schema init → migrations → server bind)
+----------------+
   │
   ▼
+----------------+
| cubeos-hal     | (privileged, X-HAL-Key gate active)
+----------------+
   │
   ▼  +------------------+
   ├─► cubeos-dashboard  (bridge mode)
   ├─► dozzle            (bridge mode)
   ├─► (network layer)   wireguard/openvpn/tor
   └─► (AI/ML layer)     ollama/chromadb/docs-indexer
            │
            ▼
        operator-installed apps (per stored desired-state)
            │
            ▼
        write /cubeos/data/audit.log boot-complete event
```

## Component ownership

| Function                          | Repo         | Notes                                                                    |
|-----------------------------------|--------------|--------------------------------------------------------------------------|
| `cubeos-init.service` systemd unit | `hal/`       | Privileged; mounts data partition, detects boot type                     |
| Swarm init                        | `hal/`       | First-boot only; `--task-history-limit 1` per Article IV                 |
| Coreapp stack deploy ordering     | `coreapps/`  | Compose files + healthcheck definitions                                  |
| Boot-state API                    | `api/`       | `GET /api/v1/system/boot` per REQ-114                                    |
| Boot-progress UI                  | `dashboard/` | Polls `/api/v1/system/boot` every 2s during boot per REQ-115             |
| First-boot wizard                 | `dashboard/` | Different route; shown when `.setup_complete` absent                     |
| Audit log write                   | `api/`       | On boot-complete signal from `cubeos-init`                               |

## Boot decision tree

```
cubeos-init.service starts
   │
   ├─ /cubeos partition mounted? ─── no ──► fsck → mount → continue
   ├─ /cubeos/data/.setup_complete exists?
   │       │
   │       ├─ no  ──► FIRST_BOOT
   │       │           swarm init
   │       │           start ONLY: pihole, npm, api, dashboard
   │       │           dashboard renders setup-wizard route
   │       │           wait for /api/v1/setup/complete POST
   │       │           write .setup_complete atomically
   │       │           continue to full-stack start
   │       │
   │       └─ yes ──► RECOVERY_BOOT
   │                   verify SQLite integrity
   │                   start all coreapps in declared order
   │                   restore user-installed apps from `apps` table
   │
   └─ on full-stack complete: write audit.log + GET /api/v1/system/boot
```

## SQLite integrity recovery (REQ-117)

```
boot path:
   sqlite3 /cubeos/data/cubeos.db "PRAGMA integrity_check"
   if ok ──► proceed
   if not ─►
     mv /cubeos/data/cubeos.db /cubeos/data/cubeos.db.corrupted-$(date +%s)
     cp /cubeos/data/backups/cubeos.db.last-known-good /cubeos/data/cubeos.db
     verify integrity again
       if ok ──► proceed + log restoration to audit.log
       if not ─► RECOVERY_WIZARD_MODE
                 (dashboard renders "Database unrecoverable; reset or restore from external backup" UI)
```

## Out of scope (here)

- Image-level OTA boot — see `adr/0007-ota-strategy.md` (deferred to post-v1.0).
- A/B partition switching — same.
- Bootloader signing — deferred.
- Encrypted root partition — operator-overridable post-boot via `cubeos-cli system harden`.
