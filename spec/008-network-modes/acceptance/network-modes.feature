Feature: Network modes (spec/008 — retrospective)

  Background:
    Given the system supports the six modes
    And the current mode is "offline_hotspot"

  # REQ-800 + REQ-801
  Scenario: Catalog endpoint lists six modes
    When the operator GETs /api/v1/network/modes
    Then the response lists exactly the six canonical modes
    And each entry includes hardware requirements

  # REQ-802 — hide modes the hardware can't support
  Scenario: x86 LXC hides WiFi-only modes
    Given the system runs on x86 LXC with no WiFi hardware
    When the operator opens the mode picker
    Then offline_hotspot, wifi_router, wifi_bridge, android_tether, wifi_client are hidden
    And only eth_client is shown

  # REQ-803 + REQ-804 + REQ-806
  Scenario: Mode switch surfaces progress via WebSocket
    When the operator switches mode from offline_hotspot to wifi_router
    Then dashboard receives WebSocket progress events for each saga step
    And the switch completes within 15 seconds

  # REQ-805 — saga compensation
  Scenario: Failed switch rolls back cleanly
    Given switching to wifi_router will fail at step 7 (firewall apply)
    When the operator attempts the switch
    Then compensating actions restore the previous mode (offline_hotspot)
    And the audit log records the failed switch

  # REQ-808 + REQ-809
  Scenario: offline_hotspot blocks outbound internet at firewall
    Given the current mode is offline_hotspot
    When any container attempts outbound to the internet
    Then the firewall drops the packet
    And nftables logs the drop with prefix "cubeos-block-outbound"

  # REQ-815 + REQ-816 — credential security
  Scenario: WiFi credentials never appear in logs or DB
    Given the operator submitted WiFi credentials via dashboard
    When credentials are stored
    Then /cubeos/config/secrets.env contains them (mode 0600)
    And no row in cubeos.db contains the credential text
    And no entry in /cubeos/data/audit.log contains the credential text

  # REQ-812 — v3 → v4 migration
  Scenario: Upgrade from v3 OFFLINE maps to v4 offline_hotspot
    Given the device is on CubeOS v3 with mode "OFFLINE"
    When the operator upgrades to v4
    Then on first v4 boot the mode is "offline_hotspot"

  # REQ-811 — boot-time hardware verification
  Scenario: Mode rolls back to offline_hotspot if required hardware missing on boot
    Given persisted mode is "wifi_router"
    And the Ethernet adapter has been removed since last boot
    When the system boots
    Then the saga detects missing hardware and reverts to offline_hotspot
    And the operator is notified via dashboard
