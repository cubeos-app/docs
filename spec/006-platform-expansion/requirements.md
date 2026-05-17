# Requirements — Platform expansion (spec/006)

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "NEW Phase 11: Platform Expansion — BananaPi, Proxmox community scripts, physical x86".

> ID convention: 600-block (`600..699`).

## Functional requirements

### Proxmox helper-script publication

REQ-600: The system shall publish a Proxmox community helper script at the canonical Proxmox-helper-scripts URL pattern that creates a CubeOS LXC from the x86_64 image.
REQ-601: When the operator runs the helper script, the system shall install CubeOS as a Proxmox LXC with default storage / network parameters chosen by the script.
REQ-602: The system shall maintain compatibility with the Proxmox community-script signing convention (Proxmox VE 9+).

### Physical x86 install path

REQ-603: The system shall publish a bootable USB image variant for physical x86 hardware (alongside the existing Proxmox LXC variant).
REQ-604: When the operator boots from the x86 USB image, the system shall present an installation wizard that partitions, installs CubeOS, and reboots.
REQ-605: The system shall NOT require UEFI Secure Boot disable for physical x86 installs (works under default UEFI settings).

### BananaPi deferral documentation

REQ-606: The system shall document the BananaPi deferral decision in the platform-support matrix on `cubeos.app` with rationale (limited maintainer bandwidth, community PRs welcome).
REQ-607: While BananaPi is deferred, the system shall keep the Packer template skeleton in `releases/platforms/bananapi/` so a community contributor can pick it up.

### Multi-platform regression

REQ-608: The system shall run platform regression suites on each release: Pi 5, Pi 4 (cross-build), x86_64 LXC, x86_64 physical via QEMU.
REQ-609: If any platform regression fails, then the system shall block the release tag until investigated.

### Documentation matrix

REQ-610: The system shall publish a platform-support matrix at `cubeos.app/platforms` listing for each platform: status (Supported / Community / Deferred), tested versions, known issues, install path.
REQ-611: When a platform is upgraded from Community to Supported, the system shall add it to the official Pi-Imager-manifest variant set (spec/003).

### Hardware feature parity guidance

REQ-612: The system shall document per-platform hardware-feature parity (GPIO, serial ports, hardware watchdog, hardware RNG) at `cubeos.app/platforms/<name>/hardware-features`.
REQ-613: When a hardware feature is unavailable on a platform, the system shall hide the related dashboard UI (Article VII compliance — features driven by detected hardware).

### Community-contribution onboarding

REQ-614: The system shall maintain a `CONTRIBUTING-platforms.md` in `releases/` describing how to add a new platform.
REQ-615: When a community PR adds a new platform, the system shall require the contributor to provide passing platform-regression artifacts before review acceptance.
