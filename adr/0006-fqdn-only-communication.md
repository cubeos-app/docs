# 6. FQDN-only internal communication

Date: 2026-05-18 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

Inter-service communication can address peers by container name, Docker bridge IP, host IP, or FQDN. Choosing one mechanism + enforcing it is more important than which mechanism we pick. Mixed usage causes IP-change breakage, cross-stack name collisions, and bridge-driver coupling.

## Decision

Use **FQDN** of the form `<service>.cubeos.cube`. Pi-hole serves `cubeos.cube` as the local DNS zone, resolving each service name to its current Swarm-assigned IP.

Single explicit exception: `localhost:5000` for the local Docker registry (pulled during early boot before Pi-hole's DNS is necessarily up).

## Consequences

**Positive:** Service migrations transparently re-resolve via DNS. Code is portable across deploys. Operator-readable URLs.

**Negative:** DNS dependency. Pi-hole down kills inter-service comms. Mitigation: Pi-hole runs as host-mode coreapp, starts before any service that depends on it.

**Enforced by:** Article II.
