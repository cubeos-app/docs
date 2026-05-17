# Requirements — USB WiFi AP (spec/005)

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "NEW Phase 10: USB WiFi AP Selection — external USB as default AP interface (March 8)". Driven by MeshSat field-deployment range requirement (Track B).

> ID convention: 500-block (`500..599`).

## Functional requirements

### Hardware detection

REQ-500: The system shall detect USB WiFi adapters at boot via HAL (per Article VII) and report each adapter's chipset, supported modes (AP / client / both), and max TX power.
REQ-501: When a USB WiFi adapter advertises AP-mode support, the system shall mark it AP-capable in the HAL device registry.
REQ-502: While no AP-capable USB adapter is present, the system shall fall back to the onboard Pi WiFi for AP duty if hardware-AP-capable.

### Operator selection

REQ-503: The system shall expose `GET /api/v1/network/ap-interfaces` returning the ordered list of AP-capable interfaces with detected metadata.
REQ-504: The system shall expose `POST /api/v1/network/ap-interface` taking `{interface: "wlan1"}` to set the active AP interface.
REQ-505: When the operator picks a new AP interface, the system shall trigger a network-mode-switch saga (per spec/008) that re-deploys hostapd against the new interface.
REQ-506: While the operator-selected AP interface is unplugged at runtime, the system shall fall back to the next AP-capable adapter and emit a Matrix alert.

### Persistence

REQ-507: The system shall persist the operator-selected AP interface in SQLite (schema v25 — new column on `network_modes` table).
REQ-508: When the system boots, the system shall read the persisted AP interface preference before launching hostapd.

### Higher-power adapter advantages

REQ-509: The system shall surface the configured TX power per AP adapter in the dashboard so the operator can choose the highest-range hardware.
REQ-510: When the configured TX power exceeds the regulatory ceiling for the operator's region, the system shall clamp to the regional max and log the clamp.

### Article VIII compliance

REQ-511: The system shall reference the chosen AP interface as `ap_interface` (role-based, per Article VIII), never `wlan0` / `wlan1` in code outside HAL.
REQ-512: When the AP interface role is reassigned, the system shall update all dependent firewall rules + hostapd config + Pi-hole DHCP binding atomically.

### Backward compatibility

REQ-513: When upgrading from a CubeOS version pre-Phase-10, the system shall default `ap_interface` to the onboard Pi WiFi and prompt the operator to choose otherwise.
REQ-514: The system shall NOT alter the AP interface selection without operator confirmation, even if a higher-spec USB adapter appears post-upgrade.

### Diagnostics

REQ-515: The system shall expose `GET /api/v1/network/ap-status` returning the active AP interface, mode (AP / hostapd state), connected client count, current TX power.
REQ-516: While `ap-status` reports hostapd as failed, the dashboard shall display a critical-severity banner with diagnostic action links.
