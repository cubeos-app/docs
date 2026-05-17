# 6. FQDN-only internal communication

Date: 2026-05-17 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

Inter-service communication between coreapps + user-apps can address peers by:

- Container name (e.g. `pihole`)
- Docker bridge IP (e.g. `172.18.0.3`)
- Host IP on the docker0 bridge (`10.42.24.1`)
- FQDN (e.g. `pihole.cubeos.cube`)

Choosing one mechanism + enforcing it is more important than which mechanism we pick. Mixed usage causes:
- IP changes (Swarm reschedules services) break references that used IPs.
- Container names work inside a stack but not across stacks.
- Host-IP usage couples code to the specific bridge driver.

## Decision

Use **FQDN** of the form `<service>.cubeos.cube` for all inter-service references. Pi-hole serves `cubeos.cube` as the local DNS zone, resolving each service name to its current Swarm-assigned IP.

The one explicit exception: `localhost:5000` for the local Docker registry. The registry is pulled during the early-boot window before Pi-hole is necessarily up; using FQDN here would create a chicken-and-egg dependency.

## Consequences

**Positive:**
- Service migrations (Swarm reschedules) transparently re-resolve via DNS.
- Code is portable across deploys (dev, x86 LXC, production Pi) — no IP literals.
- Operator-readable URLs: `https://api.cubeos.cube` instead of `https://172.18.0.5`.

**Negative:**
- DNS dependency. Pi-hole going down kills inter-service comms. Mitigated by: Pi-hole runs as a host-mode coreapp (not a Swarm overlay service), starts before any service that depends on it, and is the first service to come back if it crashes.
- The exception (`localhost:5000`) must be documented every time someone reads the registry code.

**Enforced by Constitution:** Article II (FQDN-only communication). The registry-as-exception is called out explicitly in Article II so it doesn't drift into "we make exceptions when convenient."
