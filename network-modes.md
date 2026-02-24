# Network Modes

CubeOS supports three network operating modes, letting you deploy your server in any environment -- from a fully air-gapped field station to a home office with wired internet.

## Table of Contents

- [Overview](#overview)
- [OFFLINE Mode](#offline-mode)
- [ONLINE_ETH Mode (Ethernet Uplink)](#online_eth-mode-ethernet-uplink)
- [ONLINE_WIFI Mode (WiFi Dongle Uplink)](#online_wifi-mode-wifi-dongle-uplink)
- [Switching Modes](#switching-modes)
- [Technical Details](#technical-details)
- [Troubleshooting](#troubleshooting)

---

## Overview

All three modes share one thing in common: CubeOS always runs a WiFi access point. Client devices (phones, laptops, tablets) connect to this access point to reach the dashboard and all installed apps. The difference between modes is where internet comes from -- or whether it's available at all.

| Mode | Internet Source | WiFi AP | Use Case |
|------|----------------|---------|----------|
| **OFFLINE** | None | Active | Field, air-gapped, secure |
| **ONLINE_ETH** | Ethernet cable | Active | Home, office, wired network |
| **ONLINE_WIFI** | USB WiFi adapter | Active | Mobile, no Ethernet available |

You choose a mode during the setup wizard, and you can switch modes at any time from the dashboard without reinstalling anything.

## OFFLINE Mode

```
                    WiFi AP (wlan0)
                   /
[Raspberry Pi] ----  Client Phone
                   \
                    Client Laptop
```

### What It Does

CubeOS creates a WiFi access point with no internet connectivity. The Pi operates as a fully self-contained server. All services -- dashboard, apps, DNS, file sharing -- work locally without any external connection.

### When to Use It

- **Field deployments**: Expeditions, remote sites, outdoor events
- **Emergency response**: Disaster relief communication hubs
- **Secure environments**: Air-gapped networks, classified facilities
- **Classrooms**: Isolated lab environments for teaching
- **Off-grid**: Locations with no internet infrastructure

### How It Works

1. `hostapd` creates a WiFi access point on the Pi's built-in WiFi radio (`wlan0`).
2. Pi-hole serves as DNS and DHCP server for all connected clients.
3. Clients receive an IP address in the `10.42.24.10 - 10.42.24.250` range.
4. All `*.cubeos.cube` domains resolve to `10.42.24.1` (the Pi).
5. No NAT rules, no upstream routing.

### What Works Offline

- Web dashboard and all management functions
- All installed apps
- DNS resolution for `.cubeos.cube` domains
- App installation from the local Docker registry (pre-loaded images)
- Backups to USB drives

### What Requires Internet

- Installing apps from remote registries
- System updates
- NTP time synchronization (system uses local clock)
- Accessing external websites from connected clients

## ONLINE_ETH Mode (Ethernet Uplink)

```
[Internet] <-- Ethernet --> [Raspberry Pi] <-- WiFi AP --> Clients
                (eth0)                         (wlan0)
```

### What It Does

CubeOS connects to the internet via an Ethernet cable while continuing to broadcast a WiFi access point. Internet access is shared with all WiFi clients through Network Address Translation (NAT).

### When to Use It

- **Home server**: Plug into your router for reliable internet
- **Office deployment**: Connect to the wired network
- **Any location with Ethernet**: Hotels, co-working spaces, server rooms

### How It Works

1. `eth0` receives an IP address from the upstream router via DHCP.
2. `hostapd` creates the WiFi access point on `wlan0`.
3. Pi-hole serves DNS and DHCP to WiFi clients.
4. `iptables` NAT rules forward traffic from `wlan0` clients to `eth0`.
5. Clients get internet access through the Pi's Ethernet connection.

### Benefits

- Most reliable internet connection method
- Full-speed internet for all clients
- Pi-hole filters ads and trackers for all connected devices
- App installation from both internet and local registry
- System updates available

## ONLINE_WIFI Mode (WiFi Dongle Uplink)

```
[Internet] <-- WiFi (wlan1) --> [Raspberry Pi] <-- WiFi AP (wlan0) --> Clients
              USB adapter                          built-in WiFi
```

### What It Does

CubeOS uses a USB WiFi adapter to connect to an existing WiFi network for internet access. The Pi's built-in WiFi radio continues to serve as the access point for clients.

### When to Use It

- **Mobile deployment**: No Ethernet port available at the location
- **Temporary setups**: Events, pop-up offices, demonstrations
- **Travel**: Hotel WiFi shared securely to your devices

### Requirements

- A compatible USB WiFi adapter. Recommended chipsets:
  - RTL8812AU (best compatibility)
  - Other chipsets may work but are not guaranteed

### How It Works

1. `hostapd` creates the access point on the built-in WiFi radio (`wlan0`).
2. The USB WiFi adapter (`wlan1`) connects as a client to the upstream WiFi network.
3. Pi-hole serves DNS and DHCP to access point clients.
4. `iptables` NAT rules forward traffic from `wlan0` clients through `wlan1`.
5. Clients get internet access through the upstream WiFi network.

### Connecting to an Upstream Network

1. Go to Dashboard > Network.
2. Select ONLINE_WIFI mode.
3. The system scans for available WiFi networks.
4. Select your network from the list and enter the password.
5. CubeOS connects and begins sharing internet with AP clients.

### Notes

- WiFi speeds depend on the upstream network and USB adapter capabilities.
- The built-in WiFi radio is dedicated to the access point. It cannot be used for both AP and client simultaneously.
- USB 3.0 adapters in USB 3.0 ports provide the best throughput.

## Switching Modes

You can switch between network modes at any time:

1. Open the dashboard at [http://cubeos.cube](http://cubeos.cube).
2. Navigate to **Network** in the sidebar.
3. Select the desired mode from the mode selector.
4. If switching to ONLINE_WIFI, select and authenticate to the upstream WiFi network.
5. Confirm the switch.

### What Happens During a Switch

- The mode change is orchestrated as a FlowEngine workflow with automatic rollback protection.
- There will be a brief WiFi disconnection (approximately 10 seconds) while the access point reconfigures.
- If the switch fails for any reason, CubeOS automatically reverts to the previous working mode.
- All running apps continue to operate. Only network routing changes.

### Switching Tips

- **OFFLINE to ONLINE_ETH**: Plug in the Ethernet cable before switching.
- **OFFLINE to ONLINE_WIFI**: Make sure your USB WiFi adapter is plugged in.
- **Any mode to OFFLINE**: Works immediately, just removes internet routing.
- **ONLINE_ETH to ONLINE_WIFI**: You can switch directly. Ethernet will be deactivated.

## Technical Details

### Network Configuration

| Setting | Value |
|---------|-------|
| Subnet | `10.42.24.0/24` |
| Gateway IP | `10.42.24.1` |
| DHCP Range | `10.42.24.10` - `10.42.24.250` |
| DNS Server | `10.42.24.1` (Pi-hole) |
| Domain | `cubeos.cube` |

The `10.42.24.0/24` subnet was chosen specifically to avoid conflicts with common home and office networks, which typically use `192.168.0.0/24`, `192.168.1.0/24`, or `10.0.0.0/24`.

### DNS and Domain Resolution

- **Pi-hole** handles all DNS for connected clients.
- Every CubeOS service gets a subdomain: `service.cubeos.cube` (e.g., `pihole.cubeos.cube`, `logs.cubeos.cube`).
- In ONLINE modes, Pi-hole forwards external DNS queries to upstream resolvers while filtering ads and trackers.
- In OFFLINE mode, only `.cubeos.cube` domains resolve. External domains return NXDOMAIN.

### DHCP

- Pi-hole's built-in DHCP server assigns addresses to WiFi clients.
- Lease range: `10.42.24.10` through `10.42.24.250` (241 addresses).
- The gateway (`10.42.24.1`) and DNS (`10.42.24.1`) are pushed to all clients automatically.

### Reverse Proxy

- Nginx Proxy Manager (NPM) listens on ports 80 and 443.
- Each app's subdomain is routed to the correct internal port.
- In ONLINE modes with a public IP, NPM can provision SSL certificates via Let's Encrypt.

### Firewall and NAT

- In ONLINE modes, `iptables` rules enable IP masquerading (NAT) from the WiFi subnet to the internet-facing interface.
- Forwarding is enabled only for established connections and new outbound connections from the WiFi subnet.
- The Pi itself is accessible only from the WiFi subnet by default.

### Access Point Configuration

The access point is managed by `hostapd` and configured through the HAL (Hardware Abstraction Layer). Configuration changes made through the dashboard are applied via the HAL REST API. Direct editing of `/etc/hostapd/hostapd.conf` is not recommended.

## Troubleshooting

### "I can't connect to the CubeOS WiFi network"

1. Make sure the Pi has been running for at least 90 seconds after power-on.
2. Check that the WiFi LED on the Pi is active.
3. Try moving closer to the Pi -- WiFi range depends on your environment.
4. If you recently changed the WiFi name or password, make sure you're using the new credentials.
5. Some devices cache old WiFi credentials. Forget the "CubeOS" network and reconnect.
6. Check for WiFi channel conflicts. If many networks are on the same channel, the AP may struggle. This can be changed in Dashboard > Network > WiFi AP settings.

### "I connected to CubeOS WiFi but cubeos.cube doesn't load"

1. Wait 10-15 seconds after connecting for DNS to initialize.
2. Try the direct IP address: [http://10.42.24.1](http://10.42.24.1)
3. Check that your device received an IP in the `10.42.24.x` range (check WiFi connection details).
4. Clear your browser cache or try an incognito/private window.
5. Make sure you're using `http://` not `https://`.

### "No internet in ONLINE_ETH mode"

1. Verify the Ethernet cable is plugged in securely at both ends.
2. Check that the upstream router/switch is providing DHCP.
3. Look at Dashboard > Network to confirm `eth0` received an IP address.
4. Try unplugging and re-plugging the Ethernet cable.
5. Restart the network mode: switch to OFFLINE, then back to ONLINE_ETH.

### "WiFi scan shows no networks in ONLINE_WIFI mode"

1. Confirm your USB WiFi adapter is plugged in and recognized.
2. Check Dashboard > Network for adapter status.
3. Make sure the adapter uses a supported chipset (RTL8812AU recommended).
4. Try unplugging and re-plugging the USB adapter.
5. Some 5 GHz networks may not be visible depending on adapter capabilities.

### "Network mode switch failed"

1. The system automatically rolled back to the previous working mode.
2. Check Dashboard > Network for the current active mode.
3. Review logs in Dozzle ([http://logs.cubeos.cube](http://logs.cubeos.cube)) for error details.
4. Make sure the required hardware is connected (Ethernet cable for ONLINE_ETH, USB adapter for ONLINE_WIFI).
5. Try the switch again. Transient failures can occur if hardware is still initializing.

### "Clients can't reach the internet but CubeOS works fine"

1. This usually indicates a NAT or forwarding issue.
2. Try switching to OFFLINE mode and back to your desired ONLINE mode.
3. Reboot the Pi if the issue persists: Dashboard > Settings > Reboot.
4. Check that Pi-hole is running: Dashboard > Apps > Pi-hole should show "Running".
