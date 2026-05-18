# 2. Docker Swarm single-node, not Kubernetes

Date: 2026-05-18 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

CubeOS runs ~12 coreapps + unbounded user apps on edge hardware (Pi 4/5, ARM64 SBC, x86_64 LXC). Each device needs a single source of truth for runtime state. Options:

| Option | Pros | Cons |
|---|---|---|
| Docker Swarm single-node | Built-in, reads compose, ~0 RAM overhead | Smaller ecosystem |
| Kubernetes (k3s) | Rich ecosystem | ~600 MB RAM overhead on Pi; YAML+CRD complexity |
| Custom orchestrator | Tailored | Reinvention |

## Decision

**Docker Swarm in single-node mode.** Compose format as developer interface; `docker stack deploy`. `--task-history-limit 1` (Article IV). Build our own Swarm GUI in `dashboard/src/components/swarm/`.

CGC-verified shipped surface: `api/internal/managers/swarm.go` (SwarmManager), 12 FlowEngine workflows under `api/internal/flowengine/workflows/`, `dashboard/src/components/swarm/SwarmOverview.vue` + `StackList.vue`.

## Consequences

**Positive:** zero RAM overhead; compose-native developer experience; built-in service reconciliation = self-healing.

**Negative:** smaller ecosystem vs k8s; ARM64 manifest quirks require `--resolve-image never`. Migration to k8s in future would be non-trivial (we don't expect to).

**Enforced by:** Article IV + Article V + the `docker run` ban in parent CLAUDE.md rule 8.
