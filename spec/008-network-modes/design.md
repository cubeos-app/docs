# Design — Network modes (spec/008 — retrospective)

Phase 6 shipped per roadmap §2. This spec captures the design as-built.

## Six-mode catalog summary

(Full per-mode firewall topology in `steering/network-modes.md`.)

| Mode               | AP   | DHCP | Internet uplink         | Hardware required       |
|--------------------|:----:|:----:|-------------------------|-------------------------|
| `offline_hotspot`  | yes  | aio  | none                    | hostapd-capable WiFi    |
| `wifi_router`      | yes  | aio  | Ethernet                | WiFi + Ethernet         |
| `wifi_bridge`      | yes  | no   | Ethernet (bridged)      | WiFi + Ethernet         |
| `android_tether`   | yes  | aio  | USB tether              | WiFi + USB OTG          |
| `wifi_client`      | no   | no   | upstream WiFi network   | WiFi (any chipset)      |
| `eth_client`       | no   | no   | Ethernet only           | Ethernet only           |

"aio" = DHCP runs only when profile=all_in_one (Article VI).

## network-mode-switch saga (the canonical example)

```
saga steps:
  1. validate target mode + hardware availability
  2. compute diff (which coreapps depend on the current vs new mode)
  3. stop diff.to_stop coreapps in reverse-boot-order
  4. HAL: tear down current firewall ruleset (`inet cubeos` table flush)
  5. HAL: tear down current hostapd / wpa_supplicant config
  6. HAL: write new mode config to /cubeos/config/network-mode.json
  7. HAL: apply new firewall ruleset
  8. HAL: apply new hostapd / wpa_supplicant config
  9. HAL: restart systemd networking units
  10. HAL: update Pi-hole DHCP state (enable iff profile=all_in_one AND mode permits)
  11. start diff.to_start coreapps in boot-order
  12. persist new mode to network_modes table
  13. write audit event
  14. websocket-push mode-change to dashboard

compensating actions on failure (run in reverse from failure point):
  reverse of every step that succeeded, restoring prior state
```

## Firewall topology storage

Per-mode firewall rules live in `hal/internal/network/firewalls/<mode>.nft` as raw nftables config files. HAL's mode-switch loads the appropriate file + applies atomically (`nft -f`).

Anti-leak guarantee (REQ-808): every mode-switch starts with `nft flush table inet cubeos` BEFORE loading the new file. The `inet cubeos` table is dedicated to CubeOS rules — operator-added rules in other tables survive.

## WiFi credential storage

Stored in `/cubeos/config/secrets.env` with mode `0600`. Loaded into `wpa_supplicant` at mode-switch time via HAL. Never persisted to SQLite (would risk exposure via DB backup that gets emailed somewhere).

## Out of scope

- 802.1X enterprise WiFi (PEAP, EAP-TLS). Deferred to spec for future enterprise-mode work.
- Bonding (LACP, active-backup) across multiple uplinks. Deferred.
- VLAN tagging. Operator can configure via `cubeos-cli` shell-out to HAL.
