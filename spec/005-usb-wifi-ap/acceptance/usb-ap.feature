Feature: USB WiFi AP selection (spec/005)

  # Covers: REQ-500, REQ-501, REQ-502, REQ-503, REQ-504, REQ-505, REQ-506, REQ-507, REQ-508, REQ-510, REQ-514, REQ-516

  Background:
    Given the Pi has onboard wlan0 AP-capable
    And a USB WiFi adapter (mt7612u) is plugged in as wlan1

  Scenario: HAL detects and marks both adapters AP-capable
    When the operator GETs /hal/network/wifi-adapters
    Then the response includes wlan0 with ap_capable=true
    And the response includes wlan1 with ap_capable=true and higher max_tx_power

  Scenario: Falls back to onboard wlan0 when no USB adapter
    Given the USB adapter is unplugged
    When the operator GETs /api/v1/network/ap-interfaces
    Then only wlan0 is listed

  Scenario: Operator picks USB adapter as AP
    When the operator POSTs /api/v1/network/ap-interface with {interface:"wlan1"}
    Then the network-mode-switch workflow runs
    And hostapd stops on wlan0 + starts on wlan1
    And Pi-hole DHCP rebinds to wlan1

  Scenario: Active USB adapter unplug triggers fallback
    Given wlan1 is the active AP interface
    When the USB adapter is unplugged
    Then hostapd relaunches on wlan0
    And a Matrix alert is posted

  Scenario: AP interface choice survives reboot
    Given wlan1 was the active AP
    When the Pi reboots
    Then on next boot hostapd starts on wlan1

  Scenario: TX power clamped to regional ceiling
    Given the adapter reports 30 dBm
    And the regional ceiling is 23 dBm
    When the operator queries /api/v1/network/ap-status
    Then current_tx_power_dbm shows 23
    And audit.log shows the clamp event

  Scenario: New USB adapter does NOT auto-replace current AP
    Given wlan0 is the active AP
    When the operator plugs in a higher-power USB adapter
    Then wlan0 remains the active AP
    And the dashboard shows a banner offering to switch

  Scenario: hostapd failure shows critical banner
    Given hostapd has crashed on the active AP interface
    When the operator opens the dashboard
    Then a critical-severity banner is shown with diagnostic links
