# Design — Platform expansion (spec/006)

Phase 11 broadens supported hardware. Three tracks: Proxmox community script, physical x86 USB installer, BananaPi deferral with community-contributable skeleton.

## File-level paths (future-work)

| Track | Path |
|---|---|
| Proxmox helper | `releases/platforms/proxmox/install-cubeos-lxc.sh` (new) |
| x86 USB installer | `releases/platforms/x86-installer/packer.json` + Calamares config dir (new) |
| BananaPi skeleton | `releases/platforms/bananapi/PLACEHOLDER.md` (new) |
| Matrix page | `website/content/platforms.md` (consume content via website repo) |
| Contributing guide | `releases/CONTRIBUTING-platforms.md` (new) |
| Regression scripts | `scripts/platform-regression-{x86,pi5,lxc}.sh` (new) |

## Platform matrix (current target state)

| Platform | Status | Tested | Known issues |
|---|---|---|---|
| Raspberry Pi 5 | Supported | 4 GB, 8 GB | none |
| Raspberry Pi 4 | Supported | 4 GB, 8 GB | slower boot (~110s vs 90s budget) |
| x86_64 LXC (Proxmox) | Supported | PVE 8, PVE 9 | no GPIO, no serial |
| x86_64 physical | Community | 2 builds | no GPIO; serial depends on hardware |
| BananaPi M4 Zero | Deferred | community-validated only | maintainer bandwidth |
| Rock 5B | Community | community PRs welcome | non-trivial Packer template |

## Out of scope

- Cluster install (Pi swarm farm) — post-v1.
- ARM macOS / Windows ARM — not Linux-friendly enough.
- Specialised cloud-VM images (AWS AMI, GCP image) — operators use the x86 install path on a cloud VM.
