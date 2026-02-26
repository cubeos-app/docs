# QA Plan — Raspberry Pi (ARM64)

Target hardware: Raspberry Pi 4 (2GB+) or Raspberry Pi 5
Image variants: Full and Lite

## Boot Verification

### First Boot
- [ ] Flash image to SD card using Raspberry Pi Imager
- [ ] Pi Imager custom settings applied (hostname, user, WiFi, SSH key)
- [ ] First boot completes within 5 minutes
- [ ] `.setup_complete` flag created at `/cubeos/data/.setup_complete`
- [ ] Console shows SSID and password for hotspot AP
- [ ] Dashboard accessible at `http://cubeos.cube` from a connected device
- [ ] Setup wizard loads on first visit

### Normal Boot (Reboot)
- [ ] Reboot completes within 3 minutes
- [ ] All services start automatically (check `docker service ls`)
- [ ] Dashboard accessible without re-running setup
- [ ] Previously installed apps resume running

## Network Modes

### offline_hotspot (default)
- [ ] AP broadcasts SSID
- [ ] Client connects and gets DHCP lease from Pi-hole
- [ ] Dashboard and all apps accessible via `.cubeos.cube` subdomains
- [ ] No internet access (expected)

### wifi_router (AP + Ethernet uplink)
- [ ] Ethernet cable connected to router
- [ ] AP still broadcasts SSID
- [ ] Clients have internet access via NAT
- [ ] Dashboard and apps accessible via subdomains

### wifi_bridge (AP + WiFi station)
- [ ] Second WiFi adapter connected (USB)
- [ ] Station connects to upstream WiFi
- [ ] AP still broadcasts SSID
- [ ] Clients have internet via WiFi bridge
- [ ] Dashboard accessible

### android_tether (AP + USB tether)
- [ ] Android phone connected via USB with tethering enabled
- [ ] `usb0` or `rndis0` interface detected
- [ ] AP broadcasts SSID
- [ ] Clients have internet via phone
- [ ] Dashboard accessible

### wifi_client (station only, no AP)
- [ ] Mode switch from AP mode: AP shuts down, station connects
- [ ] Device accessible via mDNS (`hostname.local`) or IP
- [ ] Dashboard accessible on LAN
- [ ] 30-second fallback: if station fails to connect, reverts to `offline_hotspot`

### eth_client (Ethernet only, no AP)
- [ ] Mode switch: AP shuts down, Ethernet gets DHCP from upstream
- [ ] Device accessible via mDNS or IP
- [ ] Dashboard accessible on LAN

## App Store

### Install
- [ ] Browse store catalog — apps load with icons and descriptions
- [ ] Install an app (e.g. Uptime Kuma) — all progress steps complete
- [ ] App accessible at `appname.cubeos.cube`
- [ ] App appears in My Apps with green status dot

### Remove
- [ ] Uninstall app via detail sheet Danger Zone
- [ ] With "Delete app data" checked: data directory removed
- [ ] Without "Delete app data": data directory preserved
- [ ] DNS entry removed (nslookup returns nothing)
- [ ] Port released (not shown in Ports tab)

### Offline Install
- [ ] Cache an app offline via "Cache Offline" button
- [ ] Switch to `offline_hotspot` mode (no internet)
- [ ] Install the cached app — succeeds from local registry
- [ ] App accessible via subdomain

## HAL Hardware Detection

### GPIO
- [ ] `GET /api/v1/hal/gpio` returns pin list (not 501)
- [ ] GPIO toggle via dashboard works (if wired)

### I2C
- [ ] `GET /api/v1/hal/i2c/scan` returns detected devices
- [ ] UPS HAT detected if present (X728 or PiJuice)

### Temperature
- [ ] `GET /api/v1/hal/temperature` returns CPU temperature
- [ ] Dashboard system overview shows temperature reading

### UPS Detection (X728)
- [ ] If X728 connected: battery percentage shown in dashboard
- [ ] If no UPS: endpoint returns empty/not-detected (not error)

### Interface Detection
- [ ] HAL detects WiFi and Ethernet interfaces
- [ ] Roles assigned correctly (ap_interface, uplink_interface)
- [ ] Mode availability API returns correct available modes for detected hardware

## Registry Sync

- [ ] Local registry running at `localhost:5000`
- [ ] After app install, image cached in local registry
- [ ] `docker images | grep localhost:5000` shows cached images
- [ ] 6-hour sync timer active (check systemd timer or cron)

## Update Flow

- [ ] `cubeos update` pulls latest container images
- [ ] API and dashboard restart with new versions
- [ ] No data loss after update
- [ ] Version number in dashboard matches updated version

## Backup and Restore

- [ ] `cubeos backup` creates `.tar.gz` at `/cubeos/backups/`
- [ ] Backup includes database, app configs, and user data
- [ ] `cubeos restore <file>` restores from backup
- [ ] All apps and settings intact after restore

## Security

- [ ] HAL accessible only via `hal-internal` network (not from client devices)
- [ ] `iptables -L CUBEOS_HAL` shows port 6005 blocked from external
- [ ] X-HAL-Key header required for HAL requests
- [ ] SSH key auth works; password auth disabled (if configured via Imager)
- [ ] JWT required for all API endpoints except `/health` and `/api/v1/auth/login`

## Performance

- [ ] Idle CPU usage < 10% (no runaway containers)
- [ ] Idle RAM usage < 1GB on 2GB Pi (Lite), < 1.5GB (Full)
- [ ] SD card I/O: no excessive writes (check `iotop` briefly)
- [ ] Docker task history limit = 1 (no memory bloat from old tasks)
