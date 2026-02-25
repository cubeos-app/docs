# CubeOS OTA Update Assessment — RAUC Evaluation

**Document:** 11_OTA_ASSESSMENT.md
**Version:** 1.0
**Last Updated:** February 25, 2026

---

## 1. Overview

This document evaluates RAUC and competing A/B partition update systems for CubeOS. CubeOS already has a working in-place system updater (Phase 4) that handles API, dashboard, and coreapp updates via Docker image pulls. This assessment focuses on whether an atomic OS-level update mechanism should be added for the root filesystem, kernel, and boot firmware — the layers *below* Docker.

### 1.1 Why Consider A/B Updates?

The current updater can update CubeOS containers but cannot safely update:
- The Linux kernel and device tree
- System packages (Docker, systemd, networking stack)
- Boot firmware (config.txt, U-Boot, UEFI)
- Base OS configuration (systemd units, sysctl, security hardening)

A failed OS-level update today requires reflashing the SD card. For deployed devices (especially headless/remote), this is unacceptable.

---

## 2. How RAUC Works

[RAUC](https://rauc.io/) (Robust Auto-Update Controller) is an open-source framework for safe, atomic over-the-air updates on embedded Linux.

### 2.1 Core Concepts

```
┌──────────────────────────────────────────────────┐
│                   SD Card / eMMC                  │
├──────────┬──────────┬──────────┬─────────────────┤
│   boot   │ rootfs_a │ rootfs_b │      data       │
│ (FAT32)  │  (ext4)  │  (ext4)  │     (ext4)      │
│  512 MB  │   4 GB   │   4 GB   │   remaining     │
│          │ ACTIVE   │ INACTIVE │  /cubeos/        │
└──────────┴──────────┴──────────┴─────────────────┘
```

**A/B Partition Scheme:**
- Two root filesystem partitions (A and B), only one active at a time
- Updates are written to the *inactive* partition while the system runs from the *active* one
- On reboot, the bootloader switches to the updated partition
- If boot fails (watchdog, health check), automatic rollback to the previous partition

**Update Flow:**
1. Device downloads a RAUC bundle (.raucb) — a signed archive containing the new rootfs image
2. RAUC writes the bundle contents to the inactive slot
3. RAUC marks the inactive slot as "pending boot"
4. Device reboots; bootloader (U-Boot / tryboot for Pi) selects the updated slot
5. RAUC marks the slot as "good" after a successful health check
6. If boot fails, the bootloader falls back to the previous slot automatically

### 2.2 Key Features

| Feature | Description |
|---------|-------------|
| Atomic updates | Full partition write — no partial updates possible |
| Cryptographic signing | Bundles are signed with X.509 certificates |
| Rollback | Automatic via bootloader (tryboot on Pi 4/5) |
| Status tracking | D-Bus API reports slot status, boot attempts, versions |
| Streaming | Can install from HTTP(S) without downloading the full bundle first |
| Adaptive updates | Delta updates (binary diff) to reduce bandwidth |
| Hooks | Pre/post-install scripts for migration, data backup |

---

## 3. CubeOS Requirements

### 3.1 Hardware Targets

| Target | Boot Method | Watchdog | Storage |
|--------|-------------|----------|---------|
| Raspberry Pi 5 | tryboot (bootloader) | bcm2835_wdt (15s max) | SD / USB / NVMe |
| Raspberry Pi 4 | tryboot (bootloader) | bcm2835_wdt (15s max) | SD / USB |
| Generic ARM64 SBC | U-Boot | Board-specific | SD / eMMC |

### 3.2 Must-Preserve Across Updates

| Data | Location | Strategy |
|------|----------|----------|
| SQLite database | /cubeos/data/cubeos.db | Separate data partition — never touched |
| Docker volumes | /cubeos/data/ | Separate data partition |
| User apps | /cubeos/apps/ | Separate data partition |
| Secrets | /cubeos/config/secrets.env | Separate data partition |
| WiFi/AP config | /cubeos/config/ | Separate data partition |
| Docker images | /var/lib/docker/ | On data partition (bind mount) or re-pulled |
| Swarm state | /var/lib/docker/swarm/ | On data partition (bind mount) |
| Network state | /cubeos/data/cubeos.db | In database on data partition |

The key insight: CubeOS already isolates all mutable state under `/cubeos/` (on the data partition). The rootfs is effectively immutable after first boot — this is ideal for A/B updates.

### 3.3 Docker Considerations

Docker's `/var/lib/docker/` (overlay2 layers, container state) is large (1-3GB) and must survive updates. Two approaches:

1. **Bind mount from data partition**: `/var/lib/docker` → `/cubeos/docker/` on the data partition. Docker state survives rootfs replacement. This is the recommended approach.
2. **Re-pull after update**: Fresh rootfs has no Docker images; first boot after update pulls everything from the local registry. Slower but cleaner.

Option 1 is preferred since CubeOS already pre-loads Docker images into the image at build time.

---

## 4. Comparison with Alternatives

### 4.1 Evaluation Matrix

| Criteria | RAUC | SWUpdate | Mender | balenaOS | rsync-based |
|----------|------|----------|--------|----------|-------------|
| **Complexity** | Medium | Medium | High (server) | Very High | Low |
| **Pi 4/5 support** | Yes (tryboot) | Yes (U-Boot) | Yes | Yes (proprietary) | N/A |
| **Rollback** | Automatic | Automatic | Automatic | Automatic | Manual |
| **Signing** | X.509 | X.509, GPG | X.509 | Proprietary | None |
| **Delta updates** | Yes (adaptive) | Yes (SWU) | Yes | Yes | Yes (rsync) |
| **Server required** | No (pull-based) | No | Yes (hosted/self) | Yes (balenaCloud) | No |
| **License** | LGPL-2.1 | GPL-2.0 | Apache-2.0 (client) | Proprietary | N/A |
| **SD card wear** | Low (full partition write) | Low | Low | Low | Medium (many small writes) |
| **Bundle size** | Full rootfs (~1GB compressed) | Full or delta | Full or delta | Full | Delta only |
| **Community** | Active, embedded focus | Active, industrial | Commercial focus | Commercial | DIY |
| **Integration effort** | 2-3 weeks | 2-3 weeks | 3-4 weeks + server | Rewrite boot flow | 1 week |

### 4.2 RAUC vs SWUpdate

Both are strong choices for embedded Linux. Key differences:

- **RAUC** uses a dedicated bundle format (.raucb) and integrates with systemd. Its D-Bus API makes it easy to expose update status in CubeOS's REST API.
- **SWUpdate** uses .swu archives and has a built-in web UI. More flexible for complex update scenarios (e.g., updating multiple components independently) but more configuration overhead.

For CubeOS, RAUC is simpler because we only need to update one slot (rootfs) and CubeOS already has its own web UI.

### 4.3 Mender

Mender requires a server component (Mender Server) for device management, update distribution, and fleet monitoring. The open-source client is Apache-2.0, but the server is commercial for production use. This adds operational complexity that doesn't align with CubeOS's self-hosted philosophy.

### 4.4 balenaOS Approach

balenaOS uses a custom immutable OS with A/B updates managed by the balena platform. It's tightly coupled to balenaCloud and not suitable for self-hosted deployments. However, its architecture validates the A/B approach for Docker-centric single-board computer operating systems.

### 4.5 rsync-based (Current CubeOS Approach Extended)

The simplest approach: `rsync` the new rootfs over the current one. No A/B partitions needed. However:
- **Not atomic**: Power loss during rsync = bricked device
- **No rollback**: Once overwritten, the old rootfs is gone
- **Risky for kernel updates**: Mismatched kernel + modules = unbootable

This is acceptable for container updates (current Phase 4 updater) but not for OS-level changes.

---

## 5. Proposed Partition Layout (If RAUC Adopted)

### 5.1 SD Card Layout

```
Partition  Type    Size     Mount Point        Purpose
─────────  ─────   ─────    ──────────────     ───────────────────────────
p1         FAT32   512 MB   /boot/firmware     Boot firmware, kernel, DTBs
p2         ext4    4 GB     / (slot A)         Root filesystem A
p3         ext4    4 GB     (slot B)           Root filesystem B
p4         ext4    rest     /cubeos            Persistent data
```

**Total overhead**: 4 GB for the second rootfs slot. On a 32GB SD card, this leaves ~23 GB for data. On 16GB, ~7 GB — tight but workable.

### 5.2 Boot Flow (Raspberry Pi)

```
Power On
  │
  ▼
Pi Firmware (start4.elf)
  │
  ├── Reads autoboot.txt → tryboot flag set?
  │   ├── Yes → Boot from tryboot partition (slot B)
  │   └── No  → Boot from default partition (slot A)
  │
  ▼
Linux Kernel
  │
  ▼
systemd → cubeos-init.service
  │
  ├── RAUC mark-good (if boot succeeds + health check passes)
  └── Or: watchdog timeout → reboot → fallback to previous slot
```

The Raspberry Pi 4/5 `tryboot` mechanism is well-documented and RAUC has native support for it via the `tryboot` boot selection backend.

### 5.3 Data Partition Bind Mounts

The rootfs would contain symlinks or bind mounts for all mutable paths:

```
/cubeos/config    → /mnt/data/cubeos/config    (on p4)
/cubeos/data      → /mnt/data/cubeos/data      (on p4)
/cubeos/apps      → /mnt/data/cubeos/apps      (on p4)
/cubeos/coreapps  → /mnt/data/cubeos/coreapps  (on p4)
/var/lib/docker   → /mnt/data/docker           (on p4)
```

This means the rootfs is truly immutable in normal operation — all writes go to the data partition.

---

## 6. Integration Effort Estimate

### 6.1 Phase Breakdown

| Phase | Work | Effort |
|-------|------|--------|
| **1. Partition layout** | Update Packer templates to create 4-partition layout | 2-3 days |
| **2. RAUC integration** | Install RAUC, configure slots, create system.conf | 2-3 days |
| **3. Boot selection** | Configure Pi tryboot, test rollback | 2-3 days |
| **4. Bundle generation** | CI pipeline to build .raucb bundles from rootfs | 2-3 days |
| **5. API endpoint** | Add `/api/v1/system/update` endpoint to trigger RAUC | 1-2 days |
| **6. Dashboard UI** | Update system page with OTA update controls | 1-2 days |
| **7. Testing** | End-to-end update + rollback testing on Pi 4/5 | 3-5 days |
| **8. Migration** | Existing users: provide one-time reflash or migration script | 2-3 days |
| **Total** | | **15-24 days** |

### 6.2 Dependencies

- Pi firmware must support tryboot (Pi 4 with Sep 2022+ firmware, all Pi 5)
- RAUC package available for Ubuntu 24.04 ARM64 (yes, via apt)
- Bundle signing requires a PKI setup (self-signed CA is fine for CubeOS)

---

## 7. Impact Assessment

### 7.1 Benefits

- **Brick-proof updates**: Power loss during update does not corrupt the device
- **Automatic rollback**: Failed kernel or system update reverts on next boot
- **Immutable rootfs**: Improved security — root filesystem is read-only in normal operation
- **Confidence for remote devices**: Users can update headless/remote Pis without physical access risk
- **Compliance**: A/B updates are an industry standard for IoT/embedded devices

### 7.2 Risks

- **SD card space**: 4 GB overhead for the second rootfs slot; problematic on 16 GB cards
- **Image build complexity**: CI must produce both flashable images and RAUC bundles
- **Migration**: Existing users must reflash (cannot add a partition to a running system)
- **Docker layer invalidation**: If /var/lib/docker is on rootfs (not data partition), all images are lost on update
- **First-boot changes**: The boot sequence must be adapted for the 4-partition layout and RAUC slot management

### 7.3 SD Card Wear

RAUC writes the entire rootfs partition (~4 GB) on each update. For SD cards with ~10,000 P/E cycles:
- 4 GB write per update / 32 GB card = ~12.5% of cells written per update
- At one update per week: ~520 updates/year × 12.5% = ~6,500% total writes/year
- Well within SD card endurance limits (most modern cards handle 10,000+ P/E cycles)
- CubeOS already uses `Storage=volatile` for journald to minimize write wear

---

## 8. Recommendation

### 8.1 Should CubeOS Adopt RAUC?

**Yes, but not yet.**

RAUC is the right technical choice for CubeOS's A/B update needs. It is well-maintained, has native Pi tryboot support, doesn't require a server component, and aligns with CubeOS's self-hosted philosophy.

However, the integration effort (15-24 days) is significant, and CubeOS has higher-priority work:
- The current Docker-based updater handles the most common update scenario (new API/dashboard/HAL versions)
- Most CubeOS users are currently flashing fresh images for major updates anyway (beta phase)
- The partition layout change is a breaking change that requires a reflash for existing users

### 8.2 Recommended Timeline

| Phase | When | What |
|-------|------|------|
| **Now (Beta)** | Current | Continue using Docker-based updater for container updates |
| **Pre-1.0** | Before stable release | Implement RAUC with 4-partition layout as part of the "stable image format" |
| **1.0 Release** | Stable | Ship with A/B partitions from day one — no migration needed |
| **Post-1.0** | Ongoing | RAUC bundles published alongside Docker image updates |

### 8.3 Action Items (When Ready)

1. Create a `feature/rauc` branch in the releases repo
2. Update Packer template to produce 4-partition images
3. Add RAUC to the base image (golden base build)
4. Create RAUC system.conf with Pi tryboot backend
5. Add bundle generation to CI pipeline
6. Add `/api/v1/system/update/os` endpoint
7. Add update UI to dashboard system page
8. Test on Pi 4 and Pi 5 with both SD card and USB boot
9. Document the update flow in `12_OTA_UPDATES.md`

### 8.4 Alternative: Incremental Approach

If full RAUC is too heavy for the pre-1.0 timeline, a lighter alternative:

1. **Add the 4-partition layout now** (in the Packer template) — this is the hardest part to retrofit later
2. **Use simple dd-based rootfs replacement** as an interim — write new rootfs to inactive slot, update tryboot config
3. **Migrate to RAUC later** — the partition layout is already in place

This "partition-first, RAUC-later" approach reduces risk by making the breaking change (partition layout) early while deferring the RAUC complexity.

---

## 9. References

- [RAUC Documentation](https://rauc.readthedocs.io/)
- [RAUC on Raspberry Pi](https://rauc.readthedocs.io/en/latest/integration.html#raspberry-pi)
- [Pi tryboot mechanism](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot)
- [SWUpdate](https://sbabic.github.io/swupdate/)
- [Mender](https://mender.io/)
- [CubeOS System Updater (Phase 4)](./09_PRODUCTION_HARDENING.md)

---

*Document: 11_OTA_ASSESSMENT.md | Version: 1.0 | February 25, 2026*
