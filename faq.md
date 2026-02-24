# Frequently Asked Questions

## Table of Contents

- [General](#general)
- [Hardware](#hardware)
- [Network](#network)
- [Apps](#apps)
- [System Management](#system-management)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

---

## General

### What is CubeOS?

CubeOS is a self-hosted operating system for Raspberry Pi and ARM64 single-board computers. It turns your Pi into a managed server with a web dashboard, one-click app store, built-in DNS filtering, and three network modes -- all controllable from your phone or computer without needing a terminal.

Think of it as what Synology DSM is for NAS devices, but for Raspberry Pi.

### How is CubeOS different from DietPi, Home Assistant, or Umbrel?

| | CubeOS | DietPi | Home Assistant | Umbrel |
|---|--------|--------|----------------|--------|
| **Primary focus** | General-purpose server, field deployment | Lightweight Debian | Home automation | Personal server |
| **Offline operation** | Full offline mode, air-gapped | Needs internet for setup | Needs internet for setup | Needs internet for setup |
| **Network modes** | 3 modes (OFFLINE, ETH, WiFi) | Standard networking | Standard networking | Standard networking |
| **Container engine** | Docker Swarm (self-healing) | Docker | Docker / add-ons | Docker |
| **WiFi access point** | Built-in, always-on | Manual configuration | Not included | Not included |
| **Target audience** | Self-hosters, field teams, makers | Power users | Smart home users | Bitcoin/self-hosting |

CubeOS stands out with its offline-first design, built-in WiFi access point, and three network modes -- making it uniquely suited for field deployments, expeditions, classrooms, and environments without reliable internet.

### Is CubeOS open source?

Yes. CubeOS is licensed under the Apache License 2.0. The source code is available on GitHub at [github.com/cubeos-app](https://github.com/cubeos-app).

### Where can I get help?

- **Documentation**: You're reading it. Start with the [Getting Started](getting-started.md) guide.
- **GitHub Issues**: Report bugs or request features on the relevant repository at [github.com/cubeos-app](https://github.com/cubeos-app).
- **Troubleshooting**: See the [Troubleshooting Guide](guides/troubleshooting.md) for common issues.

## Hardware

### What Raspberry Pi models are supported?

CubeOS supports:
- **Raspberry Pi 5** (recommended) -- 4 GB or 8 GB
- **Raspberry Pi 4** (64-bit) -- 2 GB, 4 GB, or 8 GB

CubeOS requires a 64-bit (ARM64) processor. Older models (Pi 3, Pi Zero, Pi Zero 2 W) are not supported.

### Can I use CubeOS on non-Raspberry Pi ARM64 boards?

CubeOS is designed and tested for Raspberry Pi, but it should run on other ARM64 single-board computers with compatible hardware (WiFi, Ethernet, USB). Community testing on other boards is welcome -- please report your experience on GitHub.

### Does CubeOS work with a USB SSD instead of an SD card?

Yes. Flash the CubeOS image to a USB SSD instead of a microSD card. Raspberry Pi 5 boots from USB by default. For Pi 4, you may need to update the bootloader to enable USB boot first (see the Raspberry Pi documentation).

USB SSDs are faster and more reliable than microSD cards. They are recommended for production deployments.

### How much RAM do I need?

- **2 GB**: CubeOS runs, but you're limited to a few lightweight apps. Use the Lite image.
- **4 GB**: Recommended. Runs the full platform plus several apps comfortably.
- **8 GB**: Best for AI/ML workloads (Ollama, ChromaDB) or running many apps simultaneously.

CubeOS core services (API, dashboard, DNS, proxy) use approximately 800 MB of RAM at idle.

### Does CubeOS have a hardware watchdog?

Yes. CubeOS enables the Raspberry Pi's hardware watchdog with a 15-second timeout. If the system hangs and the watchdog is not pinged within 15 seconds, the Pi reboots automatically.

## Network

### Does CubeOS work without internet?

Yes. OFFLINE mode is a core feature. CubeOS creates a WiFi access point and runs all services locally. You can manage the server, run apps, share files, and use DNS -- all without any internet connection.

The only things that require internet are: installing apps from remote registries, system updates, and NTP time sync.

### What's the default WiFi password?

The default WiFi password during first boot is **cubeos1234**. You set a new WiFi password during the setup wizard.

### What subnet does CubeOS use?

CubeOS uses `10.42.24.0/24`:
- Gateway: `10.42.24.1`
- DHCP range: `10.42.24.10` -- `10.42.24.250`
- DNS: `10.42.24.1` (Pi-hole)

This subnet was chosen to avoid conflicts with common home networks that use `192.168.x.x` or `10.0.0.x`.

### Can I change the WiFi channel or SSID?

Yes. Go to Dashboard > Network > WiFi AP settings to change the network name, password, and channel.

### What domain does CubeOS use internally?

CubeOS uses `cubeos.cube` as the internal domain. All services are accessible via subdomains:
- Dashboard: `cubeos.cube`
- Pi-hole: `pihole.cubeos.cube`
- Log Viewer: `logs.cubeos.cube`
- Installed apps: `appname.cubeos.cube`

These domains work only when connected to the CubeOS WiFi network.

## Apps

### How do I install apps?

Open the dashboard at [http://cubeos.cube](http://cubeos.cube), navigate to the App Store, find an app, and click Install. The app is deployed as a Docker Swarm service with automatic port allocation, DNS entry, and reverse proxy configuration.

### Can I install Docker apps that aren't in the App Store?

Yes. You can install any Docker image via the API:

```bash
curl -X POST http://api.cubeos.cube/api/v1/apps \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "image": "docker-image:tag",
    "description": "My custom app"
  }'
```

See the [Developer Guide](developer-guide.md#creating-custom-apps) for more details on custom app installation.

### Can I install apps when offline?

Yes, if the Docker images are available in the local registry. The Full CubeOS image comes with popular apps pre-loaded in the local registry at `localhost:5000`. In ONLINE modes, pulled images are also cached locally for future offline use.

### How do I access an installed app?

Each app gets a subdomain under `cubeos.cube`. For example, if you install an app called "files", access it at `http://files.cubeos.cube`. The exact URL is shown on the app's card in the dashboard.

### How do I uninstall an app?

Go to Dashboard > Apps, find the app, and click Uninstall. This removes the Swarm stack, DNS entry, reverse proxy rule, and releases the allocated port.

## System Management

### How do I update CubeOS?

Go to Dashboard > Settings > Updates. If an update is available, click Update. CubeOS downloads and applies the update, then restarts affected services.

Updates require internet access (ONLINE_ETH or ONLINE_WIFI mode).

### How do I reset CubeOS to factory settings?

CubeOS provides a factory reset option:

1. Go to Dashboard > Settings > Factory Reset.
2. Confirm the reset.
3. CubeOS wipes the database, configuration, and user data.
4. On the next boot, the setup wizard runs again as if it were a fresh installation.

Alternatively, flash a fresh CubeOS image to the SD card.

### Can I SSH into CubeOS?

Yes. SSH is available if enabled during image flashing (via Raspberry Pi Imager settings) or if you enable it later from the dashboard.

```bash
ssh cubeos@cubeos.cube
```

The SSH user is `cubeos`. If you configured an SSH key during flashing, key authentication is used. Otherwise, use the admin password.

### How do I view container logs?

Use Dozzle, the built-in log viewer:
- Dashboard: click the logs icon on any app
- Direct URL: [http://logs.cubeos.cube](http://logs.cubeos.cube)

Dozzle shows real-time logs from all Docker containers.

### How do I back up my CubeOS system?

Go to Dashboard > Settings > Backups > Create Backup. Choose a backup scope (Tier 1 for config only, Tier 2 for app configs, Tier 3 for everything including data) and a destination (local, USB, or network share). See [Backup and Restore](backup-restore.md) for full details.

### Can I schedule automatic backups?

Yes. Go to Dashboard > Settings > Backups > Schedule. Configure the frequency, scope, destination, and retention policy. See [Backup and Restore](backup-restore.md#scheduled-backups) for details.

## Security

### Is the default admin password secure?

No. The setup wizard requires you to set your own admin password on first boot. There is no default admin password in production -- you create one during setup.

### Are backups encrypted?

They can be. CubeOS supports two encryption modes:
- **Device mode**: Encrypted with a key tied to the Pi's hardware. Automatic, but only restorable on the same Pi.
- **Portable mode**: Encrypted with a passphrase you provide. Restorable on any Pi.

See [Backup and Restore - Encryption](backup-restore.md#encryption) for details.

### Does CubeOS have a firewall?

CubeOS uses `iptables` for NAT and basic firewall rules. In ONLINE modes, only the WiFi subnet can access the Pi's services. External access from the upstream network is blocked by default.

### Can I use a VPN with CubeOS?

Yes. CubeOS includes built-in WireGuard and OpenVPN clients. Upload your VPN configuration in Dashboard > Network > VPN, then connect. You can also enable Tor routing for specific apps.

## Troubleshooting

### CubeOS won't boot / I can't find the WiFi network

1. Make sure the SD card was flashed correctly. Try reflashing.
2. Use the official power supply. Undervoltage causes boot failures.
3. Wait at least 90 seconds. First boot takes longer than subsequent boots.
4. Connect an HDMI monitor to see boot messages.
5. If the green LED blinks in a pattern, the Pi cannot read the SD card. Try a different card.

### I forgot my admin password

There is no password recovery. You have two options:
1. Factory reset from the dashboard (if you can still access it).
2. Flash a fresh CubeOS image and restore from a backup.

### The dashboard is slow or unresponsive

1. Check CPU and memory usage in the dashboard. If maxed out, stop some apps.
2. On a 2 GB Pi, the system may struggle with many apps running. Consider upgrading to 4 GB.
3. A slow SD card degrades performance significantly. Use a Class 10 or better card, or switch to a USB SSD.
4. Reboot the Pi: Dashboard > Settings > Reboot.

### An app is stuck in "Installing" or "Pending"

1. Check if the system is online. Image pulls require internet access (unless cached locally).
2. View the workflow status in Dashboard > Apps.
3. Check logs in Dozzle for error messages.
4. If the workflow is stuck, stop the app and try reinstalling.

### The Pi reboots unexpectedly

1. This is usually the hardware watchdog doing its job. It reboots the system if it detects a hang.
2. Check the power supply. Undervoltage causes instability and watchdog reboots.
3. Check temperature. The Pi throttles and may become unstable above 80 degrees C. Ensure adequate cooling.
4. Check storage. A full SD card can cause system instability. Free up space or use a larger card.
