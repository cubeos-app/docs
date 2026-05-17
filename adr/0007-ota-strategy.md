# 7. OTA strategy — per-component CI auto-deploy; image-level OTA deferred

Date: 2026-05-17 (extends and consolidates `decisions/adr-ota-updates.md` from March 2026)

## Status

Accepted (supersedes `decisions/adr-ota-updates.md` directionally, kept for git-history continuity)

## Context

The legacy March-2026 ADR (`decisions/adr-ota-updates.md`) analysed several Over-The-Air update mechanisms for shipped CubeOS Pi devices and reached a tentative position. Since then (per `CUBEOS_PROJECT_ROADMAP_v4.md` §2 + `architecture/11_OTA_ASSESSMENT.md`) the project has shipped the per-component CI auto-deploy mechanism and accumulated enough operational data to make the OTA decision durable.

OTA options on the table:

| Option                       | Granularity     | Downtime  | Rollback | Operator visibility |
|------------------------------|-----------------|-----------|----------|---------------------|
| **Per-component CI auto-deploy** | One coreapp at a time | seconds | Per-component `git revert` | High (push triggers deploy) |
| RAUC / Mender (image-level OTA) | Full image      | full reboot | A/B partitions | Low (silent updates)  |
| Manual reflash               | Full image      | full SD swap | Keep prior SD | Highest (operator physically swaps) |
| Self-built OTA service       | Component       | seconds | Custom    | Per design          |

## Decision

**Adopt per-component CI auto-deploy as the canonical update mechanism.**

- Push to `main` on `api`, `dashboard`, `hal`, `coreapps`, etc. triggers GitLab CI that builds the image, pushes to each Pi's local registry, runs `docker stack deploy --resolve-image never`, restarts the stack.
- Rollback = `git revert` + push (CI redeploys the revert automatically).
- OS-level package updates (kernel, systemd, base utilities) are operator-driven via `cubeos-cli system update && cubeos-cli system upgrade` — NOT auto-applied (per `steering/security-baseline.md` Layer 10).
- Image-level OTA (RAUC / Mender) is **deferred to post-v1.0**. Major image updates require operator SD-card reflash; data on `/cubeos/` partition survives reflash.

## Why not image-level OTA in v1.0

1. **Single developer constraint.** RAUC + A/B partitioning + boot bootloader integration + OTA channel server is months of work for one developer.
2. **Per-component already covers 90%+ of update needs.** Most updates are coreapp image refreshes, not kernel changes.
3. **Operator culture.** CubeOS operators expect deliberate, explicit deploys (Article XV). Silent OTA contradicts that posture.
4. **Reflash-survives-data.** `/cubeos/` data partition is on a separate partition that survives an `.img.xz` reflash, so the "operator reflash" path isn't as scary as on traditional embedded systems.

## Consequences

**Positive:**
- Per-component deploy is fast (seconds), low-risk (one coreapp at a time), easy to rollback.
- Operator always knows what's being deployed (push log + GitLab CI pipeline).
- Zero OTA-related attack surface (no OTA server to compromise).
- Article XV (auto-deploy on push to main) is the operational reality.

**Negative:**
- Kernel + OS-base updates require operator action (`cubeos-cli system upgrade`). Operators who don't run updates regularly fall behind on security patches.
- Major architecture changes (e.g. PVE 8 → 9 equivalent) require image reflash → operator pain.
- No "fleet update from console" capability — each Pi auto-deploys independently from its registered repo.

## Re-evaluate when

- More than ~100 deployed Pi devices need centralised fleet management.
- A regulatory requirement appears that mandates centralised audit + control over what's deployed.
- A second developer joins and has bandwidth to build RAUC integration.

## Supersedes

`decisions/adr-ota-updates.md` (March 2026) — that file remains for git-history continuity. This ADR is the canonical statement going forward.
