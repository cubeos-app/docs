# Design — Local registry (spec/002)

Operationalises Article III + Article XIV. The registry is the seam that lets CubeOS work fully offline.

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

## Why localhost:5000 not FQDN

Article II requires FQDN for inter-service comms, but the registry is the exception (called out in Article II itself). The reason: registry must work during early boot, BEFORE Pi-hole's DNS is necessarily up. Using `localhost:5000` removes the DNS dependency for this specific path.

## Operator UX

- **Storage usage:** `GET /api/v1/registry/status` surfaces disk usage; dashboard widget shows GB used / GB free.
- **Image import:** Settings → Registry → "Import image from file" → upload `.tar` (output of `docker save`) → backend untars + `docker push localhost:5000/<image>:<tag>`.
- **GC:** Settings → Registry → "Garbage collect untagged layers" → confirmation modal → backend runs `registry garbage-collect` with `--dry-run` first, presents reclaim estimate, applies on confirm.

## Out of scope

- Multi-tier registries (origin + edge) — not relevant for single-Pi deployments.
- Image signing (cosign / notation) — deferred; SHA-256 digest pinning covers most threats.
- Cross-Pi registry sync — implemented as part of multi-node Swarm (post-v1.0).
