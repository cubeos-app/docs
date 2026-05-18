Feature: CubeOS boot sequence (spec/001)

  # Covers: REQ-100, REQ-101, REQ-102, REQ-103, REQ-104, REQ-105, REQ-106, REQ-107, REQ-108, REQ-109, REQ-110, REQ-111, REQ-112, REQ-113, REQ-114, REQ-115, REQ-116, REQ-117, REQ-118, REQ-119, REQ-120

  Background:
    Given a Raspberry Pi 5 with a freshly-flashed CubeOS image
    And /cubeos data partition has no .setup_complete file

  Scenario: First boot launches setup wizard
    When the Pi boots for the first time
    Then cubeos-init.service detects first-boot
    And only pihole, npm, cubeos-api, cubeos-dashboard, cubeos-hal coreapps start
    And the operator at https://cubeos.cube sees the setup wizard
    And no user-app coreapps are started

  Scenario: Subsequent boot is recovery-boot
    Given /cubeos/data/.setup_complete exists
    When the Pi boots
    Then cubeos-init.service classifies the boot as recovery-boot
    And all coreapps from the desired-state are started

  Scenario: Slow boot logs per-step timings
    Given the boot takes longer than 90 seconds
    When boot completes
    Then /cubeos/data/boot.log records per-coreapp start + completion timings
    And the dashboard shows a slow-boot warning banner on next operator visit

  Scenario: Corrupted SQLite triggers restoration
    Given /cubeos/data/cubeos.db is corrupted
    When the Pi boots
    Then cubeos-init.service detects corruption via PRAGMA integrity_check
    And restores from /cubeos/data/backups/cubeos.db.last-known-good
    And logs the restoration to audit.log

  Scenario: Boot-state API + UI
    Given the boot is in progress
    When the operator opens https://cubeos.cube
    Then BootProgressView.vue polls GET /api/v1/system/boot every 2 seconds
    And renders a per-coreapp status list

  Scenario: hostapd does not start when profile != all_in_one
    Given the active access profile is "standard"
    When the Pi boots
    Then hostapd is NOT started
    And Pi-hole DHCP is NOT enabled
