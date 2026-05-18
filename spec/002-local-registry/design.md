# Design — Local registry (spec/002)

Operationalises Article III + Article XIV.

## Wire diagram

```
+---------------------+
|  Packer image build |  populates registry with coreapp images
+----------+----------+
           │
           ▼
+------------------------------------+
|  /cubeos/data/registry/            |  persistent volume
+------------------------------------+
           │
           ▼
+------------------------------------+
|  registry:2 (Swarm stack)          |  listens 127.0.0.1:5000
+------------------------------------+
        │                  ▲
        │ pull             │ push (CI auto-deploy)
        ▼                  │
+------------------+   +-------------------+
| coreapp pulls    |   | GitLab CI runners |
| at start/restart |   | tag + push images |
+------------------+   +-------------------+
```

CGC-verified: there is already a `api/internal/handlers/registry.go` + `api/internal/managers/` (no specific registry-manager file, but `internal/flowengine/workflows/registry_cache.go` workflow exists for registry sync operations).

## File-level layout (CGC-grounded paths for future work)

| Function | Real path |
|---|---|
| Registry stack compose | `coreapps/registry/docker-compose.yml` (new) |
| Registry status endpoint | `api/internal/handlers/registry.go` (CGC-verified exists) |
| Garbage-collection workflow | `api/internal/flowengine/workflows/registry_cache.go` (CGC-verified — extend for GC) |
| Image-import workflow | new `api/internal/flowengine/activities/registry.go` (CGC-verified) |
| Dashboard registry UI | new `dashboard/src/components/registry/` (alongside `swarm/`, `services/`, `settings/`, `wizard/`) |

## Why localhost:5000 not FQDN

Per Article II — registry must work during early boot before Pi-hole's DNS is up. Using `localhost:5000` removes the DNS dependency.

## Out of scope

- Multi-tier registries (origin + edge).
- Image signing (cosign / notation) — deferred.
- Cross-Pi registry sync — multi-node Swarm (post-v1).
