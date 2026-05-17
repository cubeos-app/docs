# 5. Offline-first architecture

Date: 2026-05-17 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

CubeOS targets users who can't or won't rely on internet uplink at runtime:
- Field deployments (vehicles, boats, MeshSat-style edge gateways).
- Privacy-conscious self-hosters who don't want their Pi reaching out to third-party services.
- Operators in regions with intermittent / slow / metered internet.
- Air-gapped enterprise lab setups.

Many alternatives (CasaOS, Umbrel, RasPlex, etc.) assume internet uplink for app installs, container image pulls, OS updates, and license checks. CubeOS rejects that assumption.

## Decision

Every CubeOS feature MUST be usable without internet uplink. Internet may *enhance* a feature; it must NEVER be a prerequisite.

Concrete mechanisms:

1. **Local Docker registry** (`localhost:5000`) — every coreapp + curated user-app image is mirrored to the device's local registry at image-build time. Runtime container pulls go to `localhost:5000`, never to Docker Hub. (See `08_LOCAL_REGISTRY.md`.)
2. **Bundled curl installer** — `install.sh` works against `get.cubeos.app` (the curl-installer) OR against a USB stick / SD card containing the same script + assets, for fully offline initial install.
3. **Pi-hole-as-DHCP** in `all_in_one` profile + `offline_hotspot` mode — Pi is its own AP + DHCP + DNS authority. No upstream resolver needed.
4. **First-boot wizard works offline** — no account creation, no telemetry, no "verify your installation."
5. **App store offline mode** — CasaOS app store metadata cached locally; user can install pre-cached apps offline. Online discovery is optional.
6. **No OTA license validation** — Apache 2.0; nothing to validate.
7. **Network mode `offline_hotspot`** ships as a fully-validated first-class operating mode (not a degraded fallback).

## Consequences

**Positive:**
- Resilience against internet outages, ISP issues, undersea-cable cuts, geofencing.
- Privacy: no inadvertent telemetry leakage.
- Suitable for sensitive environments (security labs, military field kit, journalists in hostile networks).
- Reduces failure modes — fewer external dependencies = fewer ways to break.

**Negative:**
- Local registry must be populated at image-build time (~3 GB additional storage per image).
- Image size on download: a CubeOS image is larger than a bare Raspberry Pi OS image because of the bundled coreapp images.
- Some inherently online features (CasaOS app store *discovery*) are degraded — operator sees only what's already cached.

**Enforced by Constitution:** Article III (Offline-first) + Article XIV (Local registry only for coreapps).
