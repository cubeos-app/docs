# 4. Port discipline: 6000-6999 only for CubeOS services

Date: 2026-05-18 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

Container port collisions are a perennial Docker pain point. CubeOS ships ~12 coreapps + unbounded user apps, each needing a unique host port. Common ranges (8xxx, 9xxx) collide unpredictably with user-installed services.

## Decision

Allocate the full `6000-6999` range. Sub-ranges defined in Article V. PortManager (CGC-verified at `api/internal/managers/ports_new.go`) auto-allocates user-app ports inside `6100-6999` with triple-source validation (DB + Swarm + HAL).

Upstream container ports outside 6xxx MUST be remapped (e.g. Ollama 11434 → 6030 per `PORT-05`).

## Consequences

**Positive:** one range to remember; firewall rules collapse (open `6000-6999` on AP iface unconditionally); zero collision with common conflicting ports; ~900 user-app slots before exhaustion.

**Negative:** operators familiar with default upstream ports must re-learn. Documented in `01_REQUIREMENTS.md` §1.4.

**Enforced by:** Article V + PortManager validation.
