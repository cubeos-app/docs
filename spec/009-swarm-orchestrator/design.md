# Design — Swarm Orchestrator + FlowEngine (spec/009 — retrospective)

The architectural foundation that fixed the Three-Headed Hydra (per `00_PROJECT_OVERVIEW.md` §The Solution).

## Wire diagram

```
                     +-----------------------+
                     |       Dashboard       |
                     +-----------+-----------+
                                 │
                                 ▼
+-----------------------------------------------------------+
|              Unified API  (api/cmd/cubeos)                |
|   chi v5 router → handlers/ → Orchestrator                |
+----------------------------+------------------------------+
                             │
                             ▼
         +-------------------+-------------------+
         |                   |                   |
         ▼                   ▼                   ▼
   +------------+      +------------+      +-----------+
   |Orchestrator|      |FlowEngine  |      |SwarmManag.|
   | (saga      |◄────►| (workflow  |◄────►| (Docker   |
   |  callsite) |      |  runner +  |      |  Swarm    |
   |            |      |  compensate)      |  client)  |
   +-----+------+      +------------+      +-----+-----+
         │                                       │
         ▼                                       ▼
   +-----------+                           +-----------+
   |  apps     |                           |  Docker   |
   |  (SQLite) |                           |  Swarm    |
   +-----------+                           +-----------+
```

## The 7 FlowEngine sagas

| Workflow                  | Owns                                                                             | Compensating actions                                                              |
|---------------------------|----------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| `install_app`             | allocate port → write compose → stack deploy → DNS → proxy → DB insert            | reverse each step                                                                 |
| `uninstall_app`           | stack remove → DNS remove → proxy remove → cleanup files → DB delete              | (no-op on success; failure mid-way logs partial state)                            |
| `start_app`               | service scale to N                                                                | scale back to 0                                                                   |
| `stop_app`                | service scale to 0                                                                | scale to previous N                                                               |
| `network_mode_switch`     | (see spec/008)                                                                    | (see spec/008)                                                                    |
| `access_profile_switch`   | (see spec/004)                                                                    | (see spec/004)                                                                    |
| `backup`                  | snapshot SQLite → tar /cubeos/data → upload to SMB/NFS                            | delete partial tar                                                                |

## Why one Orchestrator + one SwarmManager

Pre-Hydra-fix: Services handler + AppManager + AppStore each maintained Docker calls. Race conditions: two install requests overlapping; status drift between cached state and Swarm; cleanup gaps on uninstall.

Post-fix: ONE Orchestrator processes lifecycle requests serially through the saga model. ONE SwarmManager is the only thing that talks to Docker. Concurrency safety: Orchestrator's saga runs are mutually exclusive per stack.

## Port allocation algorithm

`api/internal/managers/ports.go`:

```
PortManager.Allocate() -> (port int, err error)
  1. acquire mu
  2. for port := 6100; port < 7000; port++ {
       if !in_use[port] { in_use[port] = true; persist to apps.port column; return port, nil }
     }
  3. return 0, ErrPortPoolExhausted (HTTP 409)
```

In-memory map `in_use` initialised at boot from `SELECT port FROM apps WHERE port IS NOT NULL`.

## Compose transformation

`api/internal/managers/compose.go` reads CasaOS-format compose, transforms to Swarm-compatible:

- `restart: always` → `deploy.restart_policy.condition: any`
- `depends_on` (long form) → drop (Swarm doesn't honor; replaced by service startup-order logic in deploy)
- `network_mode: host` preserved for infrastructure-layer services
- `ports: ["6010:6010"]` preserved
- `volumes: [...]` preserved
- `environment: [...]` preserved + merged with operator overrides

Unsupported features (REQ-916): logged + install rejected with actionable error.

## Swarm GUI

Built into dashboard at /swarm-gui (gated per spec/004 REQ-412). Lists:

- Stacks (with task-history limit warning if exceeded per REQ-919/920)
- Services (per stack)
- Tasks (per service replica)
- Secrets + Configs

Operator can stop/start/restart services from the GUI. Per-service log streaming via WebSocket consuming GET /api/v1/system/stacks/{stack}/logs (REQ-918).
