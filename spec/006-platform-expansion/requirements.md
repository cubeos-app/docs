# Requirements — Platform expansion (spec/006)

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "Phase 11: Platform Expansion".

> ID convention: 600-block.

REQ-600: The system shall publish a Proxmox community helper script at the canonical Proxmox-helper-scripts URL pattern that creates a CubeOS LXC from the x86_64 image.
REQ-601: When the operator runs the helper script, the system shall install CubeOS as a Proxmox LXC with default storage / network parameters chosen by the script.
REQ-602: The system shall maintain compatibility with the Proxmox community-script signing convention (PVE 9+).
REQ-603: The system shall publish a bootable USB image variant for physical x86 hardware.
REQ-604: When the operator boots from the x86 USB image, the system shall present an installation wizard that partitions, installs CubeOS, and reboots.
REQ-605: The system shall NOT require UEFI Secure Boot disable for physical x86 installs.
REQ-606: The system shall document the BananaPi deferral decision in the platform-support matrix.
REQ-607: While BananaPi is deferred, the system shall keep the Packer template skeleton in `releases/platforms/bananapi/` for community contributors.
REQ-608: The system shall run platform regression suites on each release: Pi 5, Pi 4 (cross-build), x86_64 LXC, x86_64 physical via QEMU.
REQ-609: If any platform regression fails, then the system shall block the release tag until investigated.
REQ-610: The system shall publish a platform-support matrix at `cubeos.app/platforms` listing for each platform: status, tested versions, known issues, install path.
REQ-611: When a platform is upgraded from Community to Supported, the system shall add it to the Pi-Imager-manifest variant set.
REQ-612: The system shall document per-platform hardware-feature parity at `cubeos.app/platforms/<name>/hardware-features`.
REQ-613: When a hardware feature is unavailable on a platform, the system shall hide the related dashboard UI (Article VII).
REQ-614: The system shall maintain `releases/CONTRIBUTING-platforms.md` describing how to add a new platform.
REQ-615: When a community PR adds a new platform, the system shall require passing platform-regression artifacts before review acceptance.
