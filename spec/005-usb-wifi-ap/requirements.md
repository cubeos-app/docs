# Requirements — USB WiFi AP (spec/005)

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "NEW Phase 10: USB WiFi AP Selection". Driven by MeshSat range needs.

> Future-work. ID convention: 500-block.

REQ-500: The system shall detect USB WiFi adapters at boot via HAL (Article VII) and report chipset, supported modes, and max TX power.
REQ-501: When a USB WiFi adapter advertises AP-mode support, the system shall mark it AP-capable in HAL device registry.
REQ-502: While no AP-capable USB adapter is present, the system shall fall back to the onboard Pi WiFi for AP if hardware-AP-capable.
REQ-503: The system shall expose `GET /api/v1/network/ap-interfaces` returning the ordered list of AP-capable interfaces with metadata.
REQ-504: The system shall expose `POST /api/v1/network/ap-interface` to set the active AP interface.
REQ-505: When the operator picks a new AP interface, the system shall trigger a network-mode-switch workflow that re-deploys hostapd against the new interface.
REQ-506: While the operator-selected AP interface is unplugged at runtime, the system shall fall back to the next AP-capable adapter and emit a Matrix alert.
REQ-507: The system shall persist the operator-selected AP interface in SQLite (schema v28+).
REQ-508: When the system boots, the system shall read the persisted AP interface before launching hostapd.
REQ-509: The system shall surface configured TX power per AP adapter in the dashboard.
REQ-510: When the configured TX power exceeds the regulatory ceiling, the system shall clamp + log the clamp.
REQ-511: The system shall reference the chosen AP interface as `ap_interface` (role-based per Article VIII).
REQ-512: When the AP interface role is reassigned, the system shall update firewall rules + hostapd config + Pi-hole DHCP binding atomically.
REQ-513: When upgrading from a pre-Phase-10 CubeOS, the system shall default `ap_interface` to the onboard Pi WiFi and prompt the operator to choose otherwise.
REQ-514: The system shall NOT alter the AP interface selection without operator confirmation, even if a higher-spec USB adapter appears post-upgrade.
REQ-515: The system shall expose `GET /api/v1/network/ap-status` returning active AP interface, mode, connected-client count, current TX power.
REQ-516: While `ap-status` reports hostapd as failed, the dashboard shall display a critical-severity banner with diagnostic links.
