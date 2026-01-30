# Network Guide

CubeOS creates its own WiFi network and manages DHCP/DNS for connected devices.

## Network Architecture

```
Internet ─── Router ─── Ethernet ─── CubeOS Pi
                                        │
                                   WiFi AP
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                 Phone              Laptop              Tablet
```

## Default Network Settings

| Setting | Value |
|---------|-------|
| WiFi SSID | CubeOS-XXXX |
| WiFi Password | (on device label) |
| IP Range | 192.168.42.1 - 192.168.42.254 |
| Gateway | 192.168.42.1 |
| DNS Server | 192.168.42.1 (Pi-hole) |

## WiFi Configuration

### Changing WiFi Name & Password

1. Go to Dashboard → Network → WiFi
2. Enter new SSID and password
3. Click Save
4. Reconnect with new credentials

**Or via command line:**

```bash
# Edit hostapd config
nano /etc/hostapd/hostapd.conf

# Change ssid= and wpa_passphrase=
# Then restart:
systemctl restart hostapd
```

### WiFi Channel

The default channel is auto-selected. To change:

1. Go to Network → WiFi → Advanced
2. Select channel (1, 6, or 11 recommended for 2.4GHz)
3. Save and reconnect

## DHCP & IP Addresses

CubeOS runs Pi-hole which provides DHCP. Devices connecting to the WiFi automatically receive:

- IP address (192.168.42.x)
- Gateway (192.168.42.1)
- DNS server (192.168.42.1)

### Viewing Connected Devices

1. Dashboard → Network → Clients
2. Or Pi-hole admin → Network

### Setting Static IPs

1. Go to http://pihole.cubeos.cube/admin
2. Navigate to Local DNS → DHCP
3. Add static lease with MAC address and desired IP

## DNS & Ad Blocking

Pi-hole handles all DNS queries and blocks ads/trackers.

### Accessing Pi-hole Admin

- **URL**: http://pihole.cubeos.cube/admin
- **Password**: cubeos

### Common Pi-hole Tasks

**Whitelist a domain:**
1. Go to Domains
2. Add domain with "Add to Whitelist"

**View blocked queries:**
1. Go to Query Log
2. Filter by "Blocked"

**Add custom DNS record:**
1. Go to Local DNS → DNS Records
2. Add domain and IP

## Internet Connection

### Via Ethernet (Recommended)

1. Connect Pi to your router with Ethernet cable
2. Internet is shared with WiFi clients automatically
3. Most reliable method

### Via USB Tethering

1. Connect phone via USB
2. Enable USB tethering on phone
3. CubeOS will detect and use the connection

### Checking Internet Status

Dashboard shows internet connectivity status. Or:

```bash
ping -c 3 8.8.8.8
curl -I https://google.com
```

## Firewall

CubeOS uses iptables for firewall. Default rules:

- Allow all outbound traffic
- Allow established connections
- Allow local network traffic
- NAT for WiFi clients

### Managing Firewall

Via Dashboard → Settings → Firewall, or:

```bash
# View current rules
iptables -L -n -v

# Allow a port
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# Save rules
netfilter-persistent save
```

## Troubleshooting Network

### No Internet on WiFi Clients

1. Check Pi has internet: `ping 8.8.8.8`
2. Check NAT is enabled: `cat /proc/sys/net/ipv4/ip_forward`
3. Restart networking: `systemctl restart networking`

### DNS Not Resolving

1. Check Pi-hole is running: `docker ps | grep pihole`
2. Test DNS: `nslookup google.com 192.168.42.1`
3. Restart Pi-hole: `docker restart cubeos-pihole`

### Can't Connect to WiFi

1. Check hostapd status: `systemctl status hostapd`
2. Check WiFi interface: `ip link show wlan0`
3. View logs: `journalctl -u hostapd`

### Slow Network

1. Check for interference (change WiFi channel)
2. Limit bandwidth-heavy services
3. Check CPU usage (may throttle under load)
