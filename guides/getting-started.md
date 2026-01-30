# Getting Started with CubeOS

This guide walks you through your first boot and basic setup of CubeOS.

## First Boot

1. **Insert the CubeOS SD card** into your Raspberry Pi
2. **Connect power** - the device will boot automatically
3. **Wait 2-3 minutes** for initial setup to complete

## Connecting to CubeOS

### Option 1: WiFi (Recommended)

1. On your phone or laptop, look for a WiFi network named `CubeOS-XXXX`
2. The password is printed on the device label (or `cubeos` by default)
3. Once connected, open a browser and go to http://cubeos.cube

### Option 2: Ethernet

1. Connect the Pi to your router via Ethernet cable
2. Find the Pi's IP address in your router's DHCP leases
3. Open a browser and go to `http://<IP_ADDRESS>`

## First Login

1. Go to http://cubeos.cube (or the IP address)
2. Login with:
   - Username: `admin`
   - Password: `cubeos`
3. **Change your password immediately** in Settings → Security

## Dashboard Overview

After login, you'll see the main dashboard with:

- **System Stats** - CPU, memory, disk usage, temperature
- **Services** - Status of running applications
- **Network** - Connected clients and traffic
- **Quick Actions** - Common tasks

## Next Steps

- [Configure your network](network.md)
- [Install applications](services.md)
- [Set up backups](backups.md)

## Default URLs

All services are accessible via `.cubeos.cube` domains when connected to the CubeOS WiFi:

| Service | URL |
|---------|-----|
| Dashboard | http://cubeos.cube |
| Pi-hole DNS | http://pihole.cubeos.cube/admin |
| Proxy Manager | http://npm.cubeos.cube |
| Container Manager | http://dockge.cubeos.cube |
| System Logs | http://logs.cubeos.cube |
| Terminal | http://terminal.cubeos.cube |
| API Docs | http://api.cubeos.cube/api/v1/docs |

## Troubleshooting First Boot

### Can't find CubeOS WiFi network

- Wait 3-5 minutes after powering on
- Ensure the green LED on the Pi is blinking (indicates activity)
- Try moving closer to the device

### Can't access http://cubeos.cube

- Make sure you're connected to the CubeOS WiFi, not your home WiFi
- Try http://192.168.42.1 instead
- Clear your browser cache

### Login not working

- Default credentials are `admin` / `cubeos`
- If changed and forgotten, see [Password Reset](troubleshooting.md#password-reset)
