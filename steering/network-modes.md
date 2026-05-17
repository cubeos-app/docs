# Steering — Network modes

CubeOS supports six operating modes for the network stack. Condensed from `docs/network-modes.md` + `CUBEOS_PROJECT_ROADMAP_v4.md` §2.

## The six modes

| Mode               | AP   | DHCP on managed | Internet uplink         | Use case                                       |
|--------------------|:----:|:---------------:|-------------------------|------------------------------------------------|
| `offline_hotspot`  | yes  | yes (only profile=all_in_one) | none                    | Field deployment, air-gapped, secure environments |
| `wifi_router`      | yes  | yes (only profile=all_in_one) | Ethernet uplink         | Home/office with wired uplink, Pi acts as router |
| `wifi_bridge`      | yes  | no              | Ethernet uplink, transparent bridge | Pi extends an existing LAN without becoming the DHCP authority |
| `android_tether`   | yes  | yes (only profile=all_in_one) | USB tether to Android phone | Mobile deployment via phone's data plan |
| `wifi_client`      | no   | no              | Upstream WiFi network   | Pi joins an existing WiFi network as a client (no AP) |
| `eth_client`       | no   | no              | Ethernet only           | Pi as a wired-only client (no AP, no WiFi)     |

## v3 → v4 mode-name evolution

The 3-mode predecessor (`OFFLINE`, `ONLINE_ETH`, `ONLINE_WIFI`) was superseded by the v4 6-mode set above. Migration: existing devices on v3 are auto-mapped at first boot post-upgrade:
- `OFFLINE` → `offline_hotspot`
- `ONLINE_ETH` → `wifi_router`
- `ONLINE_WIFI` → `android_tether` (if USB-tether selected) OR `wifi_client` (if direct WiFi)

## Constitutional gates

- **Article VI:** DHCP is enabled ONLY when (a) `mode` puts a managed interface in play AND (b) `access_profile == all_in_one`. Otherwise Pi-hole's DHCP service stays off even if the mode would otherwise allow it.
- **Article VII:** Hardware detection decides which modes are *offered* in the UI. A Pi without WiFi hardware never sees `wifi_router`, `wifi_bridge`, `wifi_client`, `android_tether`, or `offline_hotspot` in the mode picker — only `eth_client`.
- **Article VIII:** Code references `ap_interface` + `uplink_interface`, never `wlan0` / `eth0`. Mode switches re-resolve these roles via HAL.

## Mode switch flow

1. Operator picks new mode in dashboard.
2. Dashboard → `POST /api/v1/network/mode` → API → Orchestrator.
3. Orchestrator schedules a FlowEngine saga: (a) stop dependent coreapps; (b) HAL `POST /network/mode` with new mode + chosen interfaces; (c) HAL applies new firewall + hostapd + wpa_supplicant config; (d) HAL restarts affected systemd services; (e) Orchestrator restarts coreapps in new order.
4. On any step failure: FlowEngine runs compensating actions (revert config, restart prior systemd state, restart coreapps in prior order).
5. Operator gets success/failure feedback in UI within ~15s typical.

## Per-mode firewall topology

| Mode               | Inbound on AP iface                   | Inbound on uplink iface          | NAT?               | Forwarding?       |
|--------------------|---------------------------------------|----------------------------------|--------------------|-------------------|
| `offline_hotspot`  | 53,67,80,443,6000-6999                | (none — no uplink iface)         | no                 | no                |
| `wifi_router`      | 53,67,80,443,6000-6999                | 22,80,443 (admin only)           | yes (uplink ← AP)  | yes (AP → uplink) |
| `wifi_bridge`      | (transparent — bridge mode)           | (transparent)                    | no                 | yes (bridged)     |
| `android_tether`   | 53,67,80,443,6000-6999                | (USB iface, no inbound)          | yes                | yes               |
| `wifi_client`      | n/a                                   | 22,80,443                        | no                 | no                |
| `eth_client`       | n/a                                   | 22,80,443                        | no                 | no                |

The HAL `network` endpoint owns the nftables ruleset; the table name is `inet cubeos`.

## What's still planned (Phase 10)

Per `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "NEW Phase 10: USB WiFi AP Selection":

- External USB WiFi adapter as the default AP interface (rather than the onboard Pi WiFi). Reason: onboard WiFi power output is limited; external high-power USB adapters extend AP range significantly — needed for MeshSat field deployment.
- Spec: `spec/005-usb-wifi-ap/`.

## What's still planned (Phase 12)

Per `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "Phase 12: AP Expansion (AIO Interface Selector + TLS)":

- All-in-One profile gets a UI-driven AP interface selector (currently the AP iface is auto-detected; explicit selection unblocks dual-WiFi setups).
- AP gets TLS certificates auto-provisioned via the local CA so dashboard at `cubeos.cube` no longer triggers browser TLS warnings.
- Spec: `spec/007-ap-expansion-aio/`.
