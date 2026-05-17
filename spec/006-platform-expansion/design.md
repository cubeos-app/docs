# Design — Platform expansion (spec/006)

Phase 11 broadens the supported hardware floor. Three tracks:

1. **Proxmox community script** — `pvesh create` recipe published in the canonical Proxmox community-scripts repo (helper-scripts.com or successor).
2. **Physical x86 USB image** — bootable installer that partitions, installs CubeOS, reboots.
3. **BananaPi deferral** — kept on the roadmap as community-contributable but not maintainer-supported.

## Proxmox community script shape

The script targets PVE 8+ + 9+ and creates an LXC container with:
- Debian 12 / 13 base
- Unprivileged container
- `network_mode: bridge` to `vmbr0`
- Auto-start on host boot
- 4 GB RAM, 2 vCPU, 16 GB disk defaults (operator-overridable via env vars)
- CubeOS auto-installed via `curl get.cubeos.app | bash` inside the container post-create

## Physical x86 USB image

Built from the same Packer template as the x86_64 LXC image with one delta: includes a Calamares-derived installer that runs on first boot, partitions the target disk, installs the OS, reboots.

Defaults:
- ext4 root
- swap = min(RAM, 4 GB)
- `/cubeos/` on the same disk
- GRUB UEFI; BIOS-mode supported as a wizard checkbox

## Platform support matrix

```
| Platform              | Status     | Tested versions | Known issues                       |
|-----------------------|------------|-----------------|------------------------------------|
| Raspberry Pi 5        | Supported  | 4 GB, 8 GB     | none                               |
| Raspberry Pi 4        | Supported  | 4 GB, 8 GB     | slower boot (~110s, exceeds 90s budget per spec/001 REQ-112) |
| x86_64 LXC (Proxmox)  | Supported  | PVE 8, PVE 9   | no GPIO, no serial ports           |
| x86_64 physical       | Community  | tested on 2 builds | no GPIO; serial ports depend on hardware |
| BananaPi M4 Zero      | Deferred   | community-validated only | maintenance bandwidth     |
| Rock 5B               | Community  | community PRs welcome | non-trivial Packer template needed |
```

## Out of scope

- Cluster install (Pi swarm farm) — multi-node Swarm clustering is a separate post-v1.0 effort.
- ARM macOS / Windows ARM — not Linux-friendly enough to be in scope.
- Specific cloud-VM images (AWS AMI, GCP image) — operators can install on a cloud VM via the x86 install path; specialized cloud images are not maintained.
