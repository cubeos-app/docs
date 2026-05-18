# Design — Swarm Orchestrator + FlowEngine (spec/009 — RETROSPECTIVE)

The architectural foundation that fixed the Three-Headed Hydra. All paths CGC-verified 2026-05-18.

## Wire diagram

```
                     +-----------------------+
                     |       Dashboard       |
                     |  components/swarm/    |
                     |  SwarmOverview.vue    |
                     |  StackList.vue        |
                     +-----------+-----------+
                                 │
                                 ▼
+-----------------------------------------------------------+
|  Unified API  (api/cmd/cubeos-api/main.go)                |
|  chi v5 router → handlers/ → Orchestrator                 |
+----------------------------+------------------------------+
                             │
                             ▼
        +-------------------+-------------------+
        |                   |                   |
        ▼                   ▼                   ▼
  +-----------+      +-------------+      +-----------+
  |Orchestrator|     |WorkflowEng. |      |SwarmManag.|
  |  (sole     |◄───►| (registry + |◄───►|+ DockerMgr|
  |   entry)   |     |  workflows/ |      | (Swarm +  |
  |            |     |  activities/)      |  Docker   |
  +-----+------+     +-------------+      |  client)  |
        │                                  +-----+-----+
        ▼                                        │
  +-----------+                            +-----------+
  |  apps     |                            |  Docker   |
  |  (SQLite, |                            |  Swarm    |
  |   v27)    |                            +-----------+
  +-----------+
```

## CGC-verified component map

| Function | Real path |
|---|---|
| Orchestrator | `api/internal/managers/orchestrator.go:27` |
| SwarmManager | `api/internal/managers/swarm.go` |
| DockerManager | `api/internal/managers/docker.go` |
| PortManager (triple-source: DB + Swarm + HAL) | `api/internal/managers/ports_new.go` |
| FlowEngine core | `api/internal/flowengine/engine.go` (+ saga.go, step.go, store.go, registry.go, definition.go, progress.go, errors.go) |
| 12 Workflows | `api/internal/flowengine/workflows/*.go` |
| 14 Activities | `api/internal/flowengine/activities/*.go` |
| Compose transformation | inside `activities/appstore.go` + `activities/app_install.go` (NOT a separate `managers/compose.go`) |
| Workflow handler | `api/internal/handlers/workflows.go` |
| App handler | `api/internal/handlers/apps.go` |
| Swarm GUI components | `dashboard/src/components/swarm/SwarmOverview.vue` + `StackList.vue` + `index.js` |
| Stack handler (likely) | `api/internal/handlers/apps.go` or `api/internal/handlers/handlers.go` (verify route registration in cmd/cubeos-api/main.go) |
| Schema versioning | `api/internal/database/schema.go:13 CurrentSchemaVersion = 27` |

## The 12 canonical FlowEngine workflows

| Workflow | File | Purpose |
|---|---|---|
| appstore_install | `workflows/appstore_install.go` | Install from app store with compose transform |
| appstore_remove | `workflows/appstore_remove.go` | Uninstall app-store app |
| app_install | `workflows/app_install.go` | Generic app install |
| app_remove | `workflows/app_remove.go` | Generic app remove |
| network_mode_switch | `workflows/network_mode_switch.go` | 6-mode switching (spec/008) |
| wifi_client_switch | `workflows/wifi_client_switch.go` | WiFi client network change |
| access_profile_switch | `workflows/access_profile_switch.go` | Profile switching (spec/004) |
| first_boot_setup | `workflows/first_boot_setup.go` | First-boot wizard saga |
| backup | `workflows/backup.go` | Backup orchestration |
| restore | `workflows/restore.go` | Restore from backup |
| registry_cache | `workflows/registry_cache.go` | Registry GC + sync |
| system_update | `workflows/system_update.go` | OS package update |

## 14 activities (granular building blocks)

`activities/`: access_profile, app_install, app_remove, appstore, backup, database, docker, hal, infra, network, registry, setup, update, wifi_client.

## Why this design

Pre-Hydra-fix: Services + AppManager + AppStore each called Docker directly → race conditions + state drift. Post-fix: ONE Orchestrator + ONE Swarm/Docker manager + composable activities = coherent state, parallel-safe.

## Out of scope

- Multi-node Swarm (post-v1; architecture supports).
- Tasks-db monitoring (`managers/tasks_db_monitor.go` does NOT exist; covered by `--task-history-limit 1` per REQ-915).
- Long-term saga archival beyond the `flowengine_runs` table.
