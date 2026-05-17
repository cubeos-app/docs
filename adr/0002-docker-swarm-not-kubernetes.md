# 2. Docker Swarm single-node, not Kubernetes

Date: 2026-05-17 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

CubeOS targets edge hardware (Raspberry Pi 4/5, ARM64 SBCs, x86_64 LXC). Each device runs **multiple containerised services** that need:

- A single source of truth for runtime state (the "Three-Headed Hydra" problem — see `00_PROJECT_OVERVIEW.md`)
- Self-healing (restart failed containers)
- Declarative deployment (`docker compose`-style config)
- Zero-downtime updates
- A future path to multi-node clustering

The candidate orchestrators considered:

| Option                  | Pros                                                            | Cons                                                                                              |
|-------------------------|------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| Docker Swarm single-node | Built into Docker engine, reads compose format, zero overhead   | Limited multi-node feature set, smaller community                                                  |
| Kubernetes (k3s)        | Rich ecosystem, future-proof                                     | Compose format requires conversion; ~600 MB RAM overhead on Pi; YAML+CRD complexity for ~12 services |
| Custom orchestrator     | Tailored to CubeOS                                               | Reinventing the wheel; significant maintenance load for one developer                              |
| Nomad                   | Compose-friendly, less overhead than k8s                          | Smaller community than Swarm; another tool to learn                                                |

## Decision

**Docker Swarm in single-node mode** is the runtime orchestrator. We:

- Keep the docker-compose YAML format as the developer interface; deploy via `docker stack deploy` (NEVER `docker run`).
- Run with `--task-history-limit 1` to bound `tasks.db` memory.
- Build our own Swarm GUI inside `dashboard/` (no Portainer / Swarmpit dependency — keeps consistency with the rest of the dashboard UX).
- Accept that multi-node Swarm clustering is architecturally supported but not implemented in v1.0.
- Explicitly reject Kubernetes (k3s/k0s/microk8s) for the edge use case.

## Consequences

**Positive:**
- Zero RAM overhead vs Docker baseline.
- Compose files work as-is (with a transformation layer for CasaOS app-store apps — `api/internal/managers/compose.go`).
- Operator-familiar mental model (Docker is the on-ramp; Swarm is "Docker with more").
- Built-in service reconciliation = self-healing for free.

**Negative:**
- Swarm has a smaller ecosystem than Kubernetes; some advanced patterns (e.g. Operator Pattern, CRDs) are not available.
- Migration to k8s in future would be non-trivial (we don't expect to do this).
- ARM64-specific quirk: must pass `--resolve-image never` to avoid manifest-list confusion. Documented in `00_PROJECT_OVERVIEW.md` risk table.

**Enforced by Constitution:** Article IV (Docker Swarm is truth) + Article V (port discipline) + the `docker run` ban in `/home/claude-runner/gitlab/products/cubeos/CLAUDE.md` rule 8.
