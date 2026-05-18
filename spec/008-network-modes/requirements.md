# Requirements — Network modes (spec/008 — RETROSPECTIVE)

Source: `docs/network-modes.md` + roadmap §2 ("Phase 6 Network Modes DONE"). CGC-verified paths 2026-05-18.

> Retrospective. ID convention: 800-block.

REQ-800: The system shall provide exactly six network modes: `offline_hotspot`, `wifi_router`, `wifi_bridge`, `android_tether`, `wifi_client`, `eth_client`.
REQ-801: The system shall expose the catalog at `GET /api/v1/network/modes` (handler: `api/internal/handlers/network.go`) returning name + description + capabilities + hardware requirements per mode.
REQ-802: While hardware required by a mode is absent, the system shall hide that mode from the operator's selectable set (Article VII).
REQ-803: The system shall expose `POST /api/v1/network/mode` triggering the `network_mode_switch` FlowEngine workflow at `api/internal/flowengine/workflows/network_mode_switch.go`.
REQ-804: When the mode-switch workflow runs, the system shall stop dependent coreapps, apply new firewall config via HAL, apply new hostapd and wpa_supplicant config via HAL, restart affected systemd services, and restart coreapps in the new boot order.
REQ-805: If any workflow step fails, then the system shall run compensating actions to restore the previous mode.
REQ-806: The system shall surface mode-switch progress in the dashboard via WebSocket push within 15 seconds typical.
REQ-807: The system shall apply mode-specific iptables rules via the HAL `hal/internal/handlers/firewall.go` endpoints (NO per-mode .nft template files — rules are constructed in code).
REQ-808: The system shall reset CubeOS-managed firewall rules when entering a new mode (no cross-mode leakage).
REQ-809: While in `offline_hotspot`, the system shall block all outbound internet traffic at the firewall level (defense-in-depth for Article III).
REQ-810: The system shall persist the active mode in SQLite `network_modes` table and restore it on boot.
REQ-811: When the mode is restored on boot, the system shall verify all required hardware is present and roll back to `offline_hotspot` if anything is missing.
REQ-812: When upgrading from CubeOS pre-Phase-6, the system shall map v3 modes to v4 modes: `OFFLINE` → `offline_hotspot`, `ONLINE_ETH` → `wifi_router`, `ONLINE_WIFI` → `android_tether` (USB-tether) OR `wifi_client` (direct WiFi).
REQ-813: When the migration cannot unambiguously map a v3 mode, the system shall prompt the operator via dashboard to choose explicitly.
REQ-814: When the operator selects `wifi_client` or `wifi_bridge`, the system shall provide a UI to scan for nearby SSIDs + connect with credentials.
REQ-815: The system shall store WiFi credentials in `/cubeos/config/secrets.env` with mode `0600`, NEVER in any database.
REQ-816: The system shall NEVER log WiFi credentials to any log file.
REQ-817: The system shall maintain a regression suite exercising every mode transition.
REQ-818: When the regression suite runs, the system shall verify each end-state matches expected firewall rules + active services + Pi-hole DHCP state.
REQ-819: The system shall display a mode-picker in the dashboard with each mode's icon, name, description, and hardware-requirement check status.
REQ-820: While the current mode is in transition, the system shall display a progress indicator with per-step status.
REQ-821: If a mode-switch fails, then the system shall display the failure step + log link + retry / revert buttons.
