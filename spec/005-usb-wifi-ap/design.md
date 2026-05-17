# Design — USB WiFi AP (spec/005)

Phase 10 enables external high-power USB WiFi adapters to serve as the AP interface. Driven by MeshSat field deployment needing >100 m AP range; onboard Pi 5 WiFi tops out at 20-30 m practical.

## Topology before / after

```
BEFORE (onboard Pi WiFi as AP):
   client devices ────► wlan0 (Pi onboard, ~20-30 m range)
                        │
                        ▼
                       Pi-hole DHCP + hostapd
                        │
                        ▼
                       Pi (router or bridge to uplink)

AFTER (USB adapter as AP):
   client devices ────► wlan1 (USB high-power, ~100-200 m range)
                        │
                        ▼
                       Pi-hole DHCP + hostapd
                        │
                        ▼
                       Pi
                        │
                        ▼ (optional)
                       wlan0 (onboard) as client to uplink WiFi
```

## Compatible adapters (recommended)

The roadmap doesn't pre-pick adapters; HAL's detection logic surfaces compatibility. Known-good chipsets per CubeOS community testing (will populate over time):

- **mt7612u** (Alfa AWUS036ACH, Comfast CF-916AC) — 5 GHz, AP-capable, ~150 m practical
- **rtl8812au** (Alfa AWUS036AC) — 5 GHz, AP-capable, well-supported in current kernels
- **rt2870** (older Alfa AWUS036H) — 2.4 GHz only, AP-capable

Chipsets WITHOUT AP-mode support are NOT marked AP-capable in HAL registry (REQ-501), even if the adapter is functional as a client.

## Operator UX

1. Operator plugs USB WiFi adapter into Pi.
2. HAL detects via udev; reports new device to API.
3. Dashboard widget "Network → AP interface" lists adapters with metadata.
4. Operator picks the high-power USB adapter.
5. API runs the network-mode-switch saga: stop hostapd on old iface, start on new, update firewall rules, update Pi-hole binding.
6. Operator sees the AP relocate; clients reconnect to the same SSID (which moved between physical radios transparently).

## Fallback semantics

If the operator-selected AP adapter is unplugged at runtime (REQ-506):
1. Kernel reports device removal via netlink.
2. HAL detects, picks next-best AP-capable adapter (priority: highest TX power, then most-recent insertion).
3. API runs the fallback saga; hostapd relaunches on the fallback.
4. Matrix alert posted to `#infra-nllei01-prod` or operator's configured alert room.
5. Once original adapter is replugged, operator is prompted via dashboard banner to optionally switch back (no auto-revert per REQ-514).

## Out of scope

- Auto-selection of best AP adapter (operator must confirm — REQ-514).
- Multi-AP simultaneous operation (one AP iface at a time in v1.0).
- 6E / WiFi 7 support (adapter chipset must support; HAL surfaces what hardware reports).
