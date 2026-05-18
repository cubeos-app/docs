# 5. Offline-first architecture

Date: 2026-05-18 (codifying decision originally made 2026-01-31)

## Status

Accepted

## Context

CubeOS targets field deployments, privacy-conscious self-hosters, intermittent-internet regions, air-gapped lab setups. Many alternatives (CasaOS, Umbrel) assume internet uplink for installs / pulls / OS updates / license checks. CubeOS rejects that assumption.

## Decision

Every feature MUST be usable without internet. Internet enhances; never a prerequisite.

Mechanisms:
1. **Local Docker registry** (`localhost:5000`) — coreapps + curated images mirrored at image-build time.
2. **First-boot wizard works offline** — no account creation, no telemetry.
3. **App store offline mode** — CasaOS metadata cached locally.
4. **`offline_hotspot` network mode** ships as a first-class operating mode (not a degraded fallback).
5. **No OTA license validation** — Apache 2.0; nothing to validate.

## Consequences

**Positive:** Resilience to outages, ISP issues, geofencing. Privacy — no telemetry leakage. Sensitive-environment ready.

**Negative:** Local registry adds ~3 GB per image. Online-only features (CasaOS app store *discovery*) are degraded — operator sees only cached apps.

**Enforced by:** Article III + Article XIV (local registry only for coreapps).
