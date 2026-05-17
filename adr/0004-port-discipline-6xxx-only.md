# 4. Port discipline: 6000-6999 only for CubeOS services

Date: 2026-05-17 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

Container port collisions are a perennial Docker pain point. CubeOS ships ~15 coreapps + supports unbounded user-installed apps, each needing a unique host port. Common port ranges (`8000-8999`, `9000-9999`) overlap with random user services. Default container ports (e.g. Ollama's 11434, ChromaDB's 8000, Pi-hole's 80/443/8080) collide unpredictably.

## Decision

Allocate the full `6000-6999` port range to CubeOS services. Sub-ranges:

```
6000-6009  Infrastructure  (NPM 6000, Pi-hole 6001, HAL 6005)
6010-6019  Platform        (API 6010, Dashboard 6011)
6020-6029  Network/VPN     (WireGuard 6020, OpenVPN 6021, Tor 6022)
6030-6039  AI/ML           (Ollama 6030, ChromaDB 6031)
6050-6059  Communication   (MeshSat Bridge 6050)
6070-6079  MeshSat Hub     (Hub 6070, MQTT 6071/6072)
6100-6999  User apps       (dynamically allocated)
```

System ports (`22`, `53`, `67`, `80`, `443`) stay where the OS expects them and are handled by `network_mode: host` services. The local Docker registry uses `5000` (Docker's documented default; changing it would surprise every operator).

Default container ports for upstream images that fall outside this range MUST be remapped. Example: `PORT-05` requires Ollama (default `11434`) → `6030`.

Port allocation for user apps inside `6100-6999` is automatic: `api/internal/managers/ports.go` finds the next free port in range and writes it into the generated compose file.

## Consequences

**Positive:**
- One port range to remember. Operator sees `:6xxx` and knows "that's CubeOS."
- Firewall rules collapse: `nftables` opens `6000-6999` on the AP interface unconditionally; per-service rules live alongside service code, not in the firewall.
- Zero collision with the most-common conflicting ports (8000s, 9000s).
- The 900-port user-app range supports ~900 user apps before exhaustion — well above any realistic single-Pi load.

**Negative:**
- Operators familiar with default upstream ports must re-learn (Ollama isn't on 11434 anymore — it's on 6030).
- Documentation has to call this out explicitly (which it does — `01_REQUIREMENTS.md` §1.4).

**Enforced by Constitution:** Article V (Port discipline) — no exceptions.
