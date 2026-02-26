# QA Plan — x86_64 (amd64)

Target hardware: any x86_64 machine or VM (2GB+ RAM)
Image format: qcow2 (QEMU/KVM, Proxmox, VirtualBox via conversion)
Note: QEMU boot test in CI covers basic boot — this plan is for full hardware QA.

## Boot Verification

### First Boot
- [ ] Boot from qcow2 image (UEFI or BIOS/GRUB)
- [ ] GRUB menu appears (or auto-boots within timeout)
- [ ] Kernel loads without panic
- [ ] systemd reaches `multi-user.target`
- [ ] Docker and Swarm initialize
- [ ] `.setup_complete` flag created at `/cubeos/data/.setup_complete`
- [ ] Dashboard accessible at device IP on port 6011

### Normal Boot (Reboot)
- [ ] Reboot completes within 2 minutes
- [ ] All services start automatically
- [ ] Dashboard accessible without re-running setup
- [ ] Previously installed apps resume running

### VM-Specific
- [ ] Proxmox VM: boots with virtio disk and NIC
- [ ] VirtualBox: boots after `qemu-img convert -f qcow2 -O vdi`
- [ ] Nested virtualization: Docker works inside VM (Proxmox: enable nesting)

## Network Modes

x86 machines typically have no WiFi hardware. Only `eth_client` is available unless a WiFi adapter is present.

### eth_client (default for x86)
- [ ] Ethernet interface detected by HAL
- [ ] DHCP lease obtained from upstream router
- [ ] Dashboard accessible via IP
- [ ] mDNS/avahi broadcasts hostname
- [ ] All apps accessible via `.cubeos.cube` subdomains (requires DNS pointing to device)

### With WiFi adapter (optional)
- [ ] USB WiFi adapter detected by HAL
- [ ] AP modes become available (offline_hotspot, wifi_router, etc.)
- [ ] Same behavior as Raspberry Pi for WiFi modes

### Without WiFi
- [ ] Mode availability API returns only `eth_client`
- [ ] Dashboard network settings show no WiFi options
- [ ] No hostapd errors in logs

## App Store

### Install
- [ ] Browse store catalog — apps load
- [ ] Install an app — all progress steps complete
- [ ] App accessible at `appname.cubeos.cube` (if DNS configured) or via direct port
- [ ] App appears in My Apps with green status dot

### Remove
- [ ] Uninstall via Danger Zone
- [ ] DNS entry, proxy, port, and database record cleaned up
- [ ] Data directory removed (or preserved based on checkbox)

## HAL (tier=container or tier=full)

x86 HAL runs without GPIO/I2C hardware. Hardware-specific endpoints return 501 Not Supported.

### Expected 501 Responses
- [ ] `GET /api/v1/hal/gpio` — returns 501 (no GPIO on x86)
- [ ] `POST /api/v1/hal/gpio` — returns 501
- [ ] `GET /api/v1/hal/i2c/scan` — returns 501 (no I2C bus)

### Expected Working Endpoints
- [ ] `GET /api/v1/hal/health` — returns 200
- [ ] `GET /api/v1/hal/temperature` — returns CPU temp (via `/sys/class/thermal/` or lm-sensors)
- [ ] `GET /api/v1/hal/storage` — returns disk info
- [ ] `GET /api/v1/hal/network/interfaces` — returns detected NICs

### Interface Detection
- [ ] HAL detects Ethernet interfaces
- [ ] No false WiFi detection on machines without WiFi
- [ ] Roles assigned: `uplink_interface` set to Ethernet

## Registry Sync

- [ ] Local registry running at `localhost:5000`
- [ ] After app install, image cached in registry
- [ ] Offline install from cache works

## Update Flow

- [ ] `cubeos update` pulls latest container images
- [ ] API and dashboard restart with new versions
- [ ] No data loss after update

## Backup and Restore

- [ ] `cubeos backup` creates backup archive
- [ ] `cubeos restore <file>` restores successfully
- [ ] All apps and settings intact after restore

## Security

- [ ] HAL accessible only via `hal-internal` network
- [ ] `iptables -L CUBEOS_HAL` shows port 6005 blocked externally
- [ ] X-HAL-Key header required for HAL requests
- [ ] JWT required for API endpoints

## Performance

- [ ] Idle CPU usage < 5% (x86 is faster than Pi)
- [ ] Idle RAM usage < 1.5GB (Full variant)
- [ ] Docker task history limit = 1
- [ ] No excessive disk writes
