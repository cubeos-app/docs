# Design — USB WiFi AP (spec/005)

Phase 10 enables external high-power USB WiFi adapters as the AP interface. Driven by MeshSat field range needs.

## File-level paths (future-work, paths follow existing conventions)

| Function | Real path |
|---|---|
| HAL adapter detection | `hal/internal/handlers/wifi_ap.go` (CGC-verified exists) + extend `hardware.go` for AP capability metadata |
| HAL AP whitelist/blacklist | `/cubeos/config/wifi-ap-{whitelist,blacklist}.json` (CGC-verified shipping) |
| api AP-interface API | new `api/internal/handlers/network_ap.go` (paths follow handlers/ convention) |
| api workflow integration | extend `api/internal/flowengine/workflows/network_mode_switch.go` to handle AP iface change |
| Schema migration | extend `api/internal/database/migrations.go` v27→v28 (current is v27 per CGC) |
| Dashboard UI | new `dashboard/src/components/settings/APInterfacePanel.vue` (alongside existing `WiFiInterfacesPanel.vue`) |
| Fallback alert | extend existing Matrix alert path (per `meshsat-hub/spec/...` alerting model) |

## Topology

```
BEFORE: onboard Pi WiFi as AP (range ~20-30m)
        client devices ──► wlan0 onboard ──► Pi (router or bridge)

AFTER: USB adapter as AP (range ~100-200m)
        client devices ──► wlan1 USB ──► Pi
                                          │
                                          ▼ (optional)
                                         wlan0 onboard as client to uplink
```

## Compatible adapters (community-validated)

- mt7612u (Alfa AWUS036ACH) — 5GHz, AP-capable
- rtl8812au (Alfa AWUS036AC) — 5GHz, AP-capable
- rt2870 (Alfa AWUS036H) — 2.4GHz, AP-capable

The hal/wifi_ap.go two-stage test (iw phy + brief hostapd) is the gate per hal/ADR-0004.

## Out of scope

- Auto-selection of best AP adapter (operator must confirm — REQ-514).
- Multi-AP simultaneous operation (one AP iface at a time).
- 6E / WiFi 7 (adapter chipset must support).
