# Design — Boot sequence (spec/001)

Implementation spans `releases/` (image), `hal/` (privileged systemd unit), `api/` (boot-state endpoint), `dashboard/` (boot-progress UI). This spec lives in `docs/` because it's a project-level concern.

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
| cubeos-init   | (systemd unit, owned by releases/ + hal/)
| service       | - mount /cubeos data partition
+---------------+ - check .setup_complete
   │              - decide first-boot vs recovery
   ▼              - swarm init --task-history-limit 1 (first-boot only)
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
| cubeos-api     | (bridge mode)
+----------------+
   │
   ▼
+----------------+
| cubeos-hal     | (privileged)
+----------------+
   │
   ▼  +------------------+
   ├─► cubeos-dashboard  (bridge)
   ├─► dozzle            (bridge)
   ├─► (network layer)   wireguard/openvpn/tor
   └─► (AI/ML layer)     ollama/chromadb/docs-indexer
            │
            ▼
        operator-installed apps (per stored desired-state)
            │
            ▼
        write /cubeos/data/audit.log boot-complete event
```

## Component ownership (CGC-verified)

| Function | Repo | Real path / CGC location |
|---|---|---|
| `cubeos-init.service` systemd unit | `releases/` + `hal/` | (boot script in image) |
| Swarm init | shell-out during cubeos-init | per Article IV |
| Coreapp stack deploy ordering | `coreapps/` | per-coreapp compose files |
| Boot-state API | `api/` | new endpoint `GET /api/v1/system/boot` (this spec adds) |
| Boot-progress UI | `dashboard/` | new component (this spec adds; pattern: `dashboard/src/components/wizard/`) |
| First-boot wizard | `dashboard/` | existing at `dashboard/src/components/wizard/FirstBootWizard.vue` (CGC-verified) |
| Audit log write | `api/` | via `audit_log` table + the AuditLogger middleware (verify in api/) |

## Out of scope

- Image-level OTA boot — `adr/0007-ota-strategy.md` (deferred).
- A/B partition switching — same.
- Encrypted root partition — operator-overridable post-boot.
