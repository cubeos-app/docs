# ADR: OTA Update Strategy

**Status:** Accepted
**Date:** 2026-02-26
**Phase:** 8.3 (OTA Assessment)

## Context

CubeOS ships as a single SD card image for Raspberry Pi (ARM64) and x86_64 machines. The system runs all services as Docker containers orchestrated by Docker Swarm (single-node). The typical user is a self-hoster with one device, flashing a new SD card image for major upgrades. The installed base is small (<50 devices) and expected to grow gradually.

Updates today already work at the container level: the `cubeos update` CLI command pulls new images from the local registry (synced from GitLab CI) and performs rolling restarts via Swarm. The question is whether we need full OS-level A/B partition updates (RAUC, Mender) now, or whether container-level updates are sufficient.

## Options Evaluated

### 1. RAUC (A/B Partition Updates)

- Dual root partitions with atomic switchover via bootloader
- Proven in embedded Linux (automotive, industrial)
- Requires repartitioning the SD card (A/B root + shared data), custom bootloader integration, and a RAUC update server
- Adds ~2 GB to image size (duplicate root partition)
- Complex recovery: if both slots corrupt, full reflash required anyway

### 2. Mender (Managed OTA Platform)

- Commercial OTA platform with open-source client
- Provides fleet management dashboard, delta updates, rollback
- Requires Mender server infrastructure (self-hosted or SaaS)
- Client needs integration into the image build pipeline
- Designed for fleets of hundreds/thousands of devices — overkill for current scale

### 3. `cubeos update` (Container Image Pull + Rolling Restart)

- Already implemented: pulls latest container images, Swarm performs rolling restarts
- Zero downtime for individual services (Swarm `update_config` with `order: start-first`)
- Host OS unchanged — kernel/firmware updates require a new SD card flash
- No additional infrastructure, no repartitioning, no bootloader changes
- Users already understand "flash SD card" for major upgrades

## Decision

**Phase 1 (now through pre-1.0): Use `cubeos update` for all routine updates.**

Container-level updates via Docker Swarm cover the primary update surface (API, dashboard, HAL, coreapps, user apps). Host OS changes (kernel, firmware, system packages) are rare and handled by reflashing.

**Deferred: RAUC A/B partitions, to be revisited when multi-device deployments become common (Phase 7c+ or >100 active devices).**

Mender is ruled out entirely for the foreseeable future — the fleet management overhead is unjustified for CubeOS's self-hosted single-device model.

## Rationale

1. **Attack surface matches the solution.** >95% of CubeOS changes are container images. Swarm rolling updates handle these with zero downtime and automatic rollback on health check failure.

2. **SD card reality.** Most users run on SD cards. A/B partitioning doubles root partition wear and halves available space. SD card corruption — the primary failure mode — requires a full reflash regardless of partition scheme.

3. **Complexity vs. benefit.** RAUC adds bootloader integration, partition management, an update server, and image signing infrastructure. For a single-device self-hosted OS with a small user base, this complexity is not justified by the marginal benefit of atomic OS-level rollback.

4. **Swarm already provides rollback.** `docker service rollback <service>` reverts any service to its previous image. This covers the most common failure case (bad container image) without any OS-level machinery.

5. **User expectations.** Self-hosters expect to flash SD cards for major upgrades. This is the norm for Raspberry Pi projects (Home Assistant, LibreELEC, DietPi). Automated OS-level OTA is a nice-to-have, not a requirement.

## Consequences

### What We Gain

- No additional infrastructure to build or maintain
- No SD card repartitioning or bootloader changes
- Simpler image build pipeline (single root partition)
- Container updates are already tested and working in production

### What We Defer

- Atomic OS-level rollback (kernel, firmware, system packages)
- Unattended host OS upgrades (users must reflash for kernel updates)
- Fleet-wide update orchestration (not needed at current scale)

### Review Trigger

Revisit this decision when ANY of:
- Active device count exceeds 100
- Host OS changes become frequent (>2 per quarter)
- A kernel/firmware bug causes widespread issues that container rollback cannot address
- Multi-device fleet management becomes a supported use case (Phase 7c+)
