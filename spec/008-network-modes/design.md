# Design — Network modes (spec/008 — RETROSPECTIVE)

Phase 6 shipped. All file paths CGC-verified 2026-05-18.

## Six-mode catalog summary

Full per-mode firewall topology in `steering/network-modes.md`.

| Mode | AP | DHCP | Internet uplink | Hardware required |
|---|:---:|:---:|---|---|
| `offline_hotspot` | yes | aio | none | hostapd-capable WiFi |
| `wifi_router` | yes | aio | Ethernet | WiFi + Ethernet |
| `wifi_bridge` | yes | no | Ethernet (bridged) | WiFi + Ethernet |
| `android_tether` | yes | aio | USB tether | WiFi + USB OTG |
| `wifi_client` | no | no | upstream WiFi | WiFi |
| `eth_client` | no | no | Ethernet only | Ethernet only |

"aio" = DHCP runs only when profile=all_in_one (Article VI).

## CGC-verified component map

| Function | Real path |
|---|---|
| api workflow | `api/internal/flowengine/workflows/network_mode_switch.go` |
| api network activity | `api/internal/flowengine/activities/network.go` |
| api wifi-client activity | `api/internal/flowengine/activities/wifi_client.go` (+ workflow `workflows/wifi_client_switch.go`) |
| api REST handler | `api/internal/handlers/network.go` |
| HAL applier — network | `hal/internal/handlers/network.go` |
| HAL applier — wifi AP | `hal/internal/handlers/wifi_ap.go` |
| HAL applier — firewall (iptables shell-outs, NOT nftables config files) | `hal/internal/handlers/firewall.go` |
| Dashboard mode picker | new `dashboard/src/components/settings/NetworkModePanel.vue` (next to existing `WiFiInterfacesPanel.vue`) |
| Schema migration | `api/internal/database/migrations.go` v6 added `network_modes` table; v23 added `dhcp_managed_interface` column |

## network-mode-switch workflow

```
saga steps (CGC-verified at api/internal/flowengine/workflows/network_mode_switch.go):
  1. validate target mode + hardware availability
  2. compute diff (which coreapps depend on the current vs new mode)
  3. stop diff.to_stop coreapps in reverse-boot-order
  4. HAL: apply new firewall rules (via /firewall/* endpoints — iptables shell-out)
  5. HAL: apply new hostapd / wpa_supplicant config (via /network/* + /wifi_ap.go)
  6. HAL: restart systemd networking units
  7. HAL: update Pi-hole DHCP state (enable iff profile=all_in_one AND mode permits)
  8. start diff.to_start coreapps in boot-order
  9. persist new mode to network_modes table
  10. write audit event
  11. websocket-push to dashboard

Compensation: reverse-from-failed-step.
```

## WiFi credentials storage

`/cubeos/config/secrets.env` with mode `0600`. Loaded into wpa_supplicant via HAL at mode-switch. NEVER persisted to SQLite.

## Out of scope

- 802.1X enterprise WiFi (PEAP, EAP-TLS) — separate future spec.
- Bonding (LACP) — separate future spec.
- VLAN tagging — operator configures via netplan.
