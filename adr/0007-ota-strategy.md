# 7. OTA strategy — per-component CI auto-deploy; image-level OTA deferred

Date: 2026-05-18 (extends + consolidates `decisions/adr-ota-updates.md` from March 2026)

## Status

Accepted (supersedes `decisions/adr-ota-updates.md` directionally, kept for git-history continuity)

## Context

OTA options considered:

| Option | Granularity | Downtime | Rollback | Operator visibility |
|---|---|---|---|---|
| **Per-component CI auto-deploy** | One coreapp at a time | seconds | Per-component `git revert` | High |
| RAUC / Mender (image-level OTA) | Full image | full reboot | A/B partitions | Low |
| Manual reflash | Full image | full SD swap | Keep prior SD | Highest |
| Self-built OTA service | Component | seconds | Custom | Per design |

## Decision

**Per-component CI auto-deploy is the canonical update mechanism** (Article XV operationalises this).

Image-level OTA (RAUC / Mender) **deferred to post-v1.0**. Major image updates require operator SD reflash; `/cubeos/` partition survives reflash.

OS-level package updates (kernel, systemd, base utilities) are operator-driven via `cubeos-cli system update && cubeos-cli system upgrade` — NOT auto-applied.

## Why not image-level OTA in v1.0

1. Single-developer constraint.
2. Per-component covers 90%+ of update needs.
3. Operator culture prefers deliberate, explicit deploys.
4. Reflash-survives-data — operator reflash isn't as scary as on traditional embedded.

## Consequences

**Positive:** Per-component deploy is fast (seconds), low-risk, easy to rollback. Zero OTA-related attack surface.

**Negative:** Kernel + OS-base updates require operator action. Major architecture changes need reflash → operator pain.

## Re-evaluate when

- More than ~100 deployed Pis need centralised fleet management.
- Regulatory mandate for centralised audit + control.
- Second developer with bandwidth to build RAUC integration.

## Supersedes

`decisions/adr-ota-updates.md` (March 2026) — preserved for git-history continuity. This ADR is canonical going forward.
