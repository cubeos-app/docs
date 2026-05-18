# Steering — Network modes

CubeOS supports six operating modes. Condensed from `docs/network-modes.md` + `CUBEOS_PROJECT_ROADMAP_v4.md` §2.

## The six modes

| Mode | AP | DHCP on managed | Internet uplink | Use case |
|---|:---:|:---:|---|---|
| `offline_hotspot` | yes | yes (only profile=all_in_one) | none | Field deployment, air-gapped |
| `wifi_router` | yes | yes (only profile=all_in_one) | Ethernet | Home/office with wired uplink |
| `wifi_bridge` | yes | no | Ethernet (bridged) | Pi extends LAN, NOT DHCP authority |
| `android_tether` | yes | yes (only profile=all_in_one) | USB tether to Android | Mobile, via phone's data |
| `wifi_client` | no | no | Upstream WiFi | Pi joins existing WiFi |
| `eth_client` | no | no | Ethernet only | Pi as wired-only client |

## v3 → v4 mode-name evolution

The 3-mode predecessor (`OFFLINE`, `ONLINE_ETH`, `ONLINE_WIFI`) was superseded by the v4 6-mode set. Migration: existing v3 devices auto-map at first boot post-upgrade.

## Constitutional gates

- **Article VI:** DHCP enabled ONLY when (a) mode puts a managed interface in play AND (b) profile=`all_in_one`.
- **Article VII:** Hardware detection decides which modes appear in the UI.
- **Article VIII:** Code references `ap_interface` / `uplink_interface`, never `wlan0` / `eth0`.

## Mode switch flow (CGC-verified)

1. Operator picks new mode in dashboard.
2. Dashboard → `POST /api/v1/network/mode` (api/internal/handlers/network.go)
3. api/ → FlowEngine workflow `api/internal/flowengine/workflows/network_mode_switch.go`
4. Workflow composes activities from `api/internal/flowengine/activities/network.go`
5. Activities call HAL endpoints (`hal/internal/handlers/network.go` + `wifi_ap.go` + `firewall.go`):
   - Tear down current hostapd/wpa_supplicant
   - Apply new firewall rules (iptables shell-out via `hal/internal/handlers/firewall.go`)
   - Restart affected systemd units
   - Update Pi-hole DHCP state if Article VI applies
6. Workflow restarts coreapps in new order.
7. Operator gets success/failure within ~15s typical.

## Per-mode firewall topology

| Mode | Inbound on AP iface | Inbound on uplink iface | NAT? | Forwarding? |
|---|---|---|:---:|:---:|
| `offline_hotspot` | 53,67,80,443,6000-6999 | (no uplink) | no | no |
| `wifi_router` | 53,67,80,443,6000-6999 | 22,80,443 admin | yes | yes |
| `wifi_bridge` | (transparent) | (transparent) | no | yes (bridged) |
| `android_tether` | 53,67,80,443,6000-6999 | (USB) | yes | yes |
| `wifi_client` | n/a | 22,80,443 | no | no |
| `eth_client` | n/a | 22,80,443 | no | no |

CGC-verified: `hal/internal/handlers/firewall.go` shells out to iptables to apply mode-specific rules. **No nftables `<mode>.nft` template files exist** in HAL — rules are constructed in code per mode.

## Pending (Phase 10)

- USB WiFi AP selection (external high-power adapter as default AP iface). Spec: `spec/005-usb-wifi-ap`.

## Pending (Phase 12)

- AIO interface selector UI in `dashboard/src/components/settings/WiFiInterfacesPanel.vue` (CGC-verified exists).
- Local-CA TLS for `cubeos.cube` removing browser warnings. Spec: `spec/007-ap-expansion-aio`.
