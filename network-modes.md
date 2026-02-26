# Network Modes

CubeOS supports six network modes that control how your device connects to the internet and how clients reach the dashboard. You choose a mode during the setup wizard and can switch at any time from the dashboard without reinstalling.

Modes fall into two categories:

- **AP modes** -- CubeOS broadcasts its own WiFi access point and owns the `10.42.24.0/24` subnet. Clients connect to the CubeOS WiFi network. Pi-hole provides DHCP.
- **Client modes** -- CubeOS joins an existing network as a regular device. No access point, no DHCP. Dashboard is accessed via the device's assigned IP or `cubeos.local`.

---

## Overview

| Code | Display Name | AP? | Internet Via | Pi-hole DHCP | Dashboard Access |
|------|-------------|:---:|-------------|:------------:|-----------------|
| `offline_hotspot` | Offline Hotspot | Yes | None | ON | `cubeos.cube` / `10.42.24.1` |
| `wifi_router` | WiFi Router | Yes | Ethernet cable | ON | `cubeos.cube` / `10.42.24.1` |
| `wifi_bridge` | WiFi Bridge | Yes | 2nd WiFi adapter | ON | `cubeos.cube` / `10.42.24.1` |
| `android_tether` | Android Tether | Yes | USB-tethered phone | ON | `cubeos.cube` / `10.42.24.1` |
| `wifi_client` | WiFi Client | No | WiFi (same card) | OFF | `cubeos.local` / DHCP IP |
| `eth_client` | Ethernet Client | No | Ethernet cable | OFF | `cubeos.local` / DHCP IP |

---

## Mode Descriptions

### offline_hotspot -- Offline Hotspot

```
                    WiFi AP (wlan0)
                   /
[Raspberry Pi] ----  Client Phone
                   \
                    Client Laptop

No internet connection.
```

**What it does:** CubeOS creates a WiFi access point with no internet connectivity. The device operates as a fully self-contained server. All services -- dashboard, apps, DNS, file sharing -- work locally.

**When to use it:**
- Field deployments, expeditions, outdoor events
- Air-gapped or secure environments
- Classrooms and isolated lab setups
- Off-grid locations with no internet

**Requirements:** Built-in WiFi radio (standard on all Raspberry Pi models).

**Pi-hole DHCP:** ON. Clients receive addresses in `10.42.24.10` - `10.42.24.250`.

**How to switch:** Dashboard > Network > select Offline Hotspot > Confirm. Takes effect immediately.

**Caveats:**
- No app installation from remote registries (local registry images only).
- No system updates or NTP time sync (uses local clock).
- External domains return NXDOMAIN -- only `*.cubeos.cube` resolves.
- This is the default mode on first boot and the safe fallback if any other mode fails.

---

### wifi_router -- WiFi Router

```
[Internet] <-- Ethernet (eth0) --> [Raspberry Pi] <-- WiFi AP (wlan0) --> Clients
               cable uplink                           built-in WiFi
```

**What it does:** CubeOS connects to the internet via an Ethernet cable and broadcasts a WiFi access point. Internet is shared with all WiFi clients through NAT.

**When to use it:**
- Home server plugged into a router
- Office or co-working space with wired Ethernet
- Any location with an Ethernet port

**Requirements:** Ethernet cable connected to a router or switch that provides DHCP.

**Pi-hole DHCP:** ON. Serves addresses to WiFi clients only; Ethernet interface is excluded from DHCP scope.

**How to switch:** Plug in the Ethernet cable, then Dashboard > Network > select WiFi Router > configure (optional static IP) > Confirm.

**Caveats:**
- Most reliable internet mode -- wired connection, no WiFi interference.
- Pi-hole filters ads and trackers for all connected WiFi clients.
- NAT rules forward traffic from the WiFi subnet (`10.42.24.0/24`) to `eth0`.

---

### wifi_bridge -- WiFi Bridge

```
[Internet] <-- WiFi (wlan1) --> [Raspberry Pi] <-- WiFi AP (wlan0) --> Clients
              USB WiFi adapter                     built-in WiFi
```

**What it does:** CubeOS uses a USB WiFi adapter as a client to connect to an existing WiFi network for internet, while the built-in WiFi radio broadcasts the CubeOS access point. Internet is shared with AP clients through NAT.

**When to use it:**
- No Ethernet port available at the location
- Temporary setups, events, demonstrations
- Travel -- share hotel WiFi securely to your devices

**Requirements:**
- A USB WiFi adapter (RTL8812AU chipset recommended).
- The upstream WiFi network's SSID and password.

**Pi-hole DHCP:** ON. Serves addresses to WiFi AP clients only; the USB adapter interface is excluded from DHCP scope.

**How to switch:** Plug in the USB WiFi adapter, then Dashboard > Network > select WiFi Bridge > enter the upstream WiFi SSID and password > Confirm.

**Caveats:**
- The built-in WiFi radio is dedicated to the access point. A second radio is required for the uplink.
- USB 3.0 adapters in USB 3.0 ports provide the best throughput.
- If no SSID is configured, the mode will not activate and falls back to `offline_hotspot`.
- At boot, the system waits up to 5 seconds for the USB adapter to obtain an IP. If it fails, a warning is logged but the AP remains operational (clients can still reach local services).

---

### android_tether -- Android Tether

```
[Internet] <-- USB tether (usb0) --> [Raspberry Pi] <-- WiFi AP (wlan0) --> Clients
               Android phone                            built-in WiFi
```

**What it does:** CubeOS uses a USB-tethered Android phone as the internet uplink while broadcasting a WiFi access point. Internet from the phone's mobile data is shared with all WiFi clients through NAT.

**When to use it:**
- Mobile deployment where only cellular internet is available
- Temporary connectivity via a phone's data plan
- Locations with no WiFi or Ethernet infrastructure

**Requirements:**
- An Android phone with USB tethering enabled (Settings > Network > Hotspot & tethering > USB tethering).
- A USB cable connecting the phone to the Pi.

**Pi-hole DHCP:** ON. Serves addresses to WiFi AP clients.

**How to switch:** Connect the Android phone via USB and enable USB tethering, then Dashboard > Network > select Android Tether > Confirm.

**Caveats:**
- The USB tethering interface typically appears as `usb0` or `rndis0`.
- Phone must remain connected and tethering must stay enabled for internet to work.
- Battery drain on the phone can be significant -- keep it plugged into a charger.
- Boot script support for this mode is still being implemented. If the mode is set and the boot script does not recognise it, the system falls back to `offline_hotspot`.

---

### wifi_client -- WiFi Client

```
                                       Home WiFi Network
                                      /
[Internet] <-- WiFi Router --> [Raspberry Pi]
                                      \
                                       Other home devices

No CubeOS access point. Pi joins the existing network as a regular WiFi device.
```

**What it does:** CubeOS connects directly to an existing WiFi network using its built-in radio. No access point is created. The device behaves like any other WiFi client on the network.

**When to use it:**
- Home server that should join the existing home WiFi
- Headless server where you access the dashboard from your regular network
- Situations where broadcasting a separate access point is not desired

**Requirements:**
- A WiFi network to join (SSID and password).
- Clients must be on the same network as the Pi to reach the dashboard.

**Pi-hole DHCP:** OFF. CubeOS does not run DHCP on networks it does not own. Pi-hole provides DNS-only resolution for internal `*.cubeos.cube` domains.

**How to switch:** Dashboard > Network > select WiFi Client > enter the WiFi SSID and password > acknowledge the warning that all current WiFi clients will be disconnected > Confirm.

**Caveats:** See the detailed section below.

---

### eth_client -- Ethernet Client

```
[Internet] <-- Ethernet --> [Router] <-- Ethernet --> [Raspberry Pi]
                                                        (eth0)

No CubeOS access point. Pi joins the existing network via Ethernet.
```

**What it does:** CubeOS connects directly to an existing network via Ethernet. No access point is created. The device behaves like any other wired client on the network.

**When to use it:**
- Dedicated server room or rack with wired connectivity
- VM or LXC container deployments
- Environments where WiFi is unavailable or unnecessary

**Requirements:** Ethernet cable connected to a router or switch that provides DHCP (or static IP configured).

**Pi-hole DHCP:** OFF. CubeOS does not run DHCP on networks it does not own.

**How to switch:** Plug in the Ethernet cable, then Dashboard > Network > select Ethernet Client > configure (optional static IP) > acknowledge the warning > Confirm.

**Caveats:**
- If the Pi has WiFi hardware, the WiFi radio is disabled (hostapd stopped, interface flushed).
- Dashboard accessible at `cubeos.local` (via mDNS/Avahi) or the DHCP-assigned IP.
- Avahi is started automatically so the device is discoverable via `.local`.

---

## wifi_client Mode -- Special Notes

Switching to `wifi_client` is the most complex mode transition because it tears down the access point that the user may be connected to. Several safety mechanisms ensure the user is never locked out.

### AP Teardown Process

When switching to `wifi_client`, the system executes this sequence:

1. Stop hostapd (tears down the access point).
2. Disable Pi-hole DHCP.
3. Flush the AP interface IP (`ip addr flush wlan0`).
4. Write a station-mode netplan (WiFi client configuration).
5. Apply netplan -- starts `wpa_supplicant` for WiFi association.
6. Wait for a DHCP lease from the upstream network.
7. Verify connectivity.
8. If successful: save mode to database, start Avahi for `.local` discovery.
9. If failed: revert to `offline_hotspot` (see below).

### 30-Second Auto-Revert

After applying the station-mode netplan, the system polls for a DHCP-assigned IP every 2 seconds for up to 30 seconds. If no IP is obtained within the timeout:

- Netplan is rewritten to `offline_hotspot` configuration.
- `netplan apply` restores the AP interface.
- hostapd is restarted.
- Pi-hole DHCP is re-enabled.
- The database is updated back to `offline_hotspot`.

The user can reconnect to the CubeOS WiFi network and try again.

### WiFi Watchdog

After a successful switch to `wifi_client`, a watchdog monitors the station connection:

- Checks connectivity every 60 seconds.
- After 5 consecutive failures, automatically reverts to `offline_hotspot`.
- This prevents the device from becoming unreachable if the upstream WiFi network goes down or moves out of range.

### mDNS Discovery After Switch

Once in `wifi_client` mode, the dashboard is no longer at `cubeos.cube` (there is no AP or DNS server serving that domain to external clients). Instead:

| Platform | How to reach the dashboard |
|----------|---------------------------|
| macOS, iOS | `http://cubeos.local` (mDNS native) |
| Windows 10/11 | `http://cubeos.local` (mDNS native) |
| Linux | `http://cubeos.local` (requires avahi-daemon) |
| Android | mDNS is unreliable -- check your router's DHCP client list for the Pi's IP |

The setup wizard's final screen shows this information before initiating the switch.

### Pi Imager WiFi Credential Pre-Fill

If WiFi credentials were entered in the Raspberry Pi Imager customization screen at flash time, CubeOS extracts them at first boot and pre-fills the setup wizard. The user can then choose `wifi_client` to join that network without re-entering credentials. Cloud-init is configured to never apply these credentials directly -- CubeOS controls when and how they are used.

---

## Switching Modes

### How to Switch via Dashboard

1. Open the dashboard at `http://cubeos.cube` (AP modes) or `http://cubeos.local` (client modes).
2. Navigate to **Network** in the sidebar.
3. Select the desired mode from the mode selector grid.
4. For modes that require configuration (all except `offline_hotspot`), a dialog opens to collect upstream credentials, optional static IP settings, and any required acknowledgements.
5. For switches to client modes (`wifi_client`, `eth_client`), you must acknowledge that the access point will be torn down and WiFi clients will be disconnected.
6. Confirm the switch.

Modes may be greyed out and unavailable if the required hardware is not detected (e.g., `wifi_bridge` without a USB WiFi adapter).

### What Happens During a Mode Switch

The mode change is orchestrated as a FlowEngine workflow with automatic rollback:

1. Validate hardware requirements for the target mode.
2. Update netplan configuration for the new mode.
3. Reconfigure interfaces (stop/start hostapd, flush IPs, apply NAT rules).
4. Toggle Pi-hole DHCP (ON for AP modes, OFF for client modes).
5. Verify connectivity (for internet-connected modes).
6. If any step fails, the workflow rolls back to the previous working mode.

There is a brief network interruption (approximately 10 seconds) during the switch. All running apps continue to operate -- only network routing changes.

### Pi-hole DHCP Safety

Pi-hole DHCP is enforced at three points to prevent rogue DHCP servers on networks CubeOS does not own:

1. **Every mode switch** -- the FlowEngine saga toggles DHCP as part of the transition.
2. **Every boot** -- the boot script reads the current mode from the database and enforces the correct DHCP state.
3. **Watchdog fallback** -- reverting to `offline_hotspot` re-enables DHCP.

If the mode in the database is unknown or corrupt, the system defaults to `offline_hotspot` (AP + DHCP -- safe because CubeOS owns the subnet).

---

## Network Diagrams

### offline_hotspot

```
+------------------+         WiFi AP (wlan0)         +----------------+
|                  |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~>  |  Client Phone  |
|  Raspberry Pi    |  <~~~~~~~~~~~~~~~~~~~~~~~~~~~~  +----------------+
|  10.42.24.1      |
|                  |         WiFi AP (wlan0)         +----------------+
|  [Pi-hole DHCP]  |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~>  | Client Laptop  |
|  [hostapd]       |  <~~~~~~~~~~~~~~~~~~~~~~~~~~~~  +----------------+
+------------------+

No internet. All services are local.
Pi-hole serves DNS + DHCP on 10.42.24.0/24.
```

### wifi_router

```
+-----------+    Ethernet (eth0)    +------------------+    WiFi AP (wlan0)    +----------------+
|  Internet |  ==================>  |                  |  ~~~~~~~~~~~~~~~~~~>  |  Client Phone  |
|  Router   |  <==================  |  Raspberry Pi    |  <~~~~~~~~~~~~~~~~~~  +----------------+
+-----------+                       |  10.42.24.1      |
                                    |                  |    WiFi AP (wlan0)    +----------------+
                                    |  [NAT: wlan0→eth0] ~~~~~~~~~~~~~~~~~~>  | Client Laptop  |
                                    |  [Pi-hole DHCP]  |  <~~~~~~~~~~~~~~~~~~  +----------------+
                                    |  [hostapd]       |
                                    +------------------+

Internet via Ethernet. NAT forwards WiFi client traffic to eth0.
Pi-hole serves DNS + DHCP on 10.42.24.0/24.
```

### wifi_client

```
+-----------+    WiFi    +------------------+
|  Home     |  ~~~~~~~~  |                  |
|  WiFi     |  ~~~~~~~~  |  Raspberry Pi    |
|  Router   |            |  (DHCP IP from   |
+-----------+            |   home router)   |
     |                   |                  |
     |  WiFi             |  [Avahi/mDNS]    |
     |                   +------------------+
+----------------+
| Client Laptop  |-----> Reaches Pi at cubeos.local or DHCP IP
+----------------+

No AP. No CubeOS DHCP. Pi is a regular device on the home network.
Pi-hole runs DNS-only for internal *.cubeos.cube resolution.
```

---

## Technical Details

### Network Configuration

| Setting | Value |
|---------|-------|
| Subnet | `10.42.24.0/24` |
| Gateway IP | `10.42.24.1` |
| DHCP Range | `10.42.24.10` - `10.42.24.250` |
| DNS Server | `10.42.24.1` (Pi-hole) |
| Domain | `cubeos.cube` |
| Default AP SSID | `CubeOS` |
| Default AP Channel | `7` |

The `10.42.24.0/24` subnet was chosen to avoid conflicts with common home and office networks (`192.168.0.0/24`, `192.168.1.0/24`, `10.0.0.0/24`).

### Interface Role Assignment

CubeOS uses role-based interface assignment rather than hardcoded interface names. HAL detects hardware at boot and assigns roles:

| Role | Purpose |
|------|---------|
| **ap** | Runs the CubeOS access point (hostapd) |
| **uplink** | Provides internet connectivity |
| **unused** | Detected but not assigned |

Detection priority for the AP role: SDIO WiFi (Pi built-in) > PCI WiFi > USB WiFi.

When multiple interfaces exist for a role, the setup wizard asks the user to choose.

### Static IP Support

Any mode with an upstream interface supports optional static IP configuration instead of DHCP. When static IP is configured:

- AP modes use Pi-hole (`10.42.24.1`) as the DNS fallback.
- Client modes use public DNS (`1.1.1.1`, `8.8.8.8`) as the DNS fallback.

### DNS and Domain Resolution

- **Pi-hole** handles all DNS for connected clients (AP modes) or internal resolution (client modes).
- Every CubeOS service gets a subdomain: `service.cubeos.cube` (e.g., `pihole.cubeos.cube`, `logs.cubeos.cube`).
- In internet-connected modes, Pi-hole forwards external DNS queries to upstream resolvers while filtering ads and trackers.
- In `offline_hotspot`, only `*.cubeos.cube` domains resolve. External domains return NXDOMAIN.

### Reverse Proxy

- Nginx Proxy Manager (NPM) listens on ports 80 and 443.
- Each app's subdomain is routed to the correct internal port.
- In internet-connected modes with a public IP, NPM can provision SSL certificates via Let's Encrypt.

### Firewall and NAT

- In AP modes with internet (`wifi_router`, `wifi_bridge`, `android_tether`), iptables rules enable IP masquerading from the WiFi subnet to the uplink interface.
- Forwarding is enabled only for established connections and new outbound connections from the WiFi subnet.
- In client modes and `offline_hotspot`, NAT is disabled.

---

## Troubleshooting

### "I can't connect to the CubeOS WiFi network"

1. Make sure the Pi has been running for at least 90 seconds after power-on.
2. Confirm the current mode is an AP mode (not `wifi_client` or `eth_client`).
3. Check that the WiFi LED on the Pi is active.
4. Move closer to the Pi -- range depends on the environment.
5. If you recently changed the WiFi name or password, use the new credentials.
6. Forget the "CubeOS" network on your device and reconnect.

### "cubeos.cube doesn't load after connecting"

1. Wait 10-15 seconds after connecting for DNS to propagate.
2. Try the direct IP: `http://10.42.24.1`.
3. Check that your device received an IP in the `10.42.24.x` range.
4. Clear your browser cache or try incognito mode.
5. Use `http://` not `https://`.

### "No internet in wifi_router mode"

1. Verify the Ethernet cable is plugged in at both ends.
2. Check that the upstream router provides DHCP.
3. Look at Dashboard > Network to confirm `eth0` received an IP.
4. Try switching to `offline_hotspot` and back to `wifi_router`.

### "WiFi scan shows no networks (wifi_bridge mode)"

1. Confirm the USB WiFi adapter is plugged in and recognised.
2. Check Dashboard > Network for adapter status.
3. Ensure the adapter uses a supported chipset (RTL8812AU recommended).
4. Try unplugging and re-plugging the adapter.

### "Can't reach the dashboard after switching to wifi_client"

1. Connect to the same WiFi network the Pi joined.
2. Try `http://cubeos.local` (works on macOS, iOS, Windows, Linux with Avahi).
3. Check your router's DHCP client list for the Pi's IP address.
4. If the switch failed, the Pi auto-reverted to `offline_hotspot` -- look for the CubeOS WiFi network.

### "Mode switch failed"

1. The system automatically rolled back to the previous working mode.
2. Check Dashboard > Network for the current active mode.
3. Review logs in Dozzle (`http://logs.cubeos.cube`) for error details.
4. Ensure the required hardware is connected for the target mode.
5. Try the switch again -- transient failures can occur if hardware is still initialising.
