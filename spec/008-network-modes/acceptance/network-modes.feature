Feature: Network modes (spec/008 — RETROSPECTIVE)

  # Covers: REQ-800, REQ-801, REQ-802, REQ-803, REQ-804, REQ-805, REQ-806, REQ-807, REQ-808, REQ-809, REQ-810, REQ-811, REQ-812, REQ-813, REQ-814, REQ-815, REQ-816, REQ-817, REQ-818, REQ-819, REQ-820, REQ-821

  Background:
    Given the system supports the six modes
    And the current mode is offline_hotspot

  Scenario: Catalog endpoint lists six modes
    When the operator GETs /api/v1/network/modes
    Then the response lists exactly the six canonical modes
    And each entry includes hardware requirements

  Scenario: x86 LXC hides WiFi-only modes
    Given the system runs on x86 LXC with no WiFi hardware
    When the operator opens the mode picker
    Then offline_hotspot, wifi_router, wifi_bridge, android_tether, wifi_client are hidden
    And only eth_client is shown

  Scenario: Mode switch surfaces progress via WebSocket
    When the operator switches from offline_hotspot to wifi_router
    Then dashboard receives WebSocket progress events per workflow step
    And the switch completes within 15 seconds

  Scenario: Failed switch rolls back cleanly
    Given switching to wifi_router will fail at the HAL firewall-apply step
    When the operator attempts the switch
    Then compensating actions restore offline_hotspot
    And audit log records the failed switch

  Scenario: offline_hotspot blocks outbound internet at firewall
    Given the current mode is offline_hotspot
    When any container attempts outbound to the internet
    Then the firewall drops the packet

  Scenario: WiFi credentials never appear in logs or DB
    Given the operator submitted WiFi credentials via dashboard
    When credentials are stored
    Then /cubeos/config/secrets.env contains them (mode 0600)
    And no row in cubeos.db contains the credential text
    And no entry in /cubeos/data/audit.log contains the credential text

  Scenario: Upgrade from v3 OFFLINE maps to v4 offline_hotspot
    Given the device is on CubeOS v3 with mode "OFFLINE"
    When the operator upgrades to v4
    Then on first v4 boot the mode is "offline_hotspot"

  Scenario: HAL uses iptables shell-outs (not nftables config files)
    When the operator inspects hal/internal/handlers/firewall.go
    Then iptables shell-out calls are present
    And no per-mode .nft template files are loaded
