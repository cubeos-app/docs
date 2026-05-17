Feature: CubeOS boot sequence (spec/001)

  Background:
    Given a Raspberry Pi 5 with a freshly-flashed CubeOS image
    And the /cubeos data partition has no .setup_complete file

  # REQ-105 + REQ-106
  Scenario: First boot launches setup wizard, not full stack
    When the Pi boots for the first time
    Then cubeos-init.service detects first-boot
    And only pihole, npm, cubeos-api, cubeos-dashboard coreapps start
    And the operator browser at https://cubeos.cube shows the setup wizard
    And no user-app coreapps are started

  # REQ-107
  Scenario: Operator completes first-boot wizard
    Given the operator is on the first-boot wizard
    When the operator submits the wizard (SSH pubkey + network mode + profile)
    Then /cubeos/data/.setup_complete is written atomically
    And the full coreapp stack starts in declared order

  # REQ-108 — recovery boot
  Scenario: Subsequent boot is recovery-boot
    Given /cubeos/data/.setup_complete exists
    When the Pi boots
    Then cubeos-init.service classifies the boot as recovery-boot
    And all coreapps from the desired-state are started
    And no setup-wizard is shown

  # REQ-100 — swarm init only on first boot
  Scenario: Swarm init does not re-run on recovery boot
    Given Docker Swarm is already initialized
    When the Pi boots (recovery-boot)
    Then docker swarm init is NOT called
    And the existing Swarm state is preserved

  # REQ-110 + REQ-111 — watchdog
  Scenario: Watchdog resets the board on kernel hang
    Given watchdog is enabled with 15-second timeout
    When the kernel becomes unresponsive for >15 seconds
    Then the hardware watchdog resets the board
    And the next boot starts cleanly

  # REQ-112 + REQ-113 — boot budget
  Scenario: Slow boot logs per-step timings
    Given the boot takes longer than 90 seconds
    When boot completes
    Then /cubeos/data/boot.log records per-coreapp start + completion timings
    And the dashboard shows a slow-boot warning banner on next operator visit

  # REQ-114 + REQ-115 — boot-state API + UI
  Scenario: Dashboard polls boot state during incomplete boot
    Given the boot is in progress
    When the operator opens https://cubeos.cube
    Then BootProgressView.vue polls GET /api/v1/system/boot every 2 seconds
    And the UI renders a per-coreapp status list

  # REQ-117 — DB corruption recovery
  Scenario: Corrupted SQLite triggers restoration from last-known-good
    Given /cubeos/data/cubeos.db is corrupted
    When the Pi boots
    Then cubeos-init.service detects the corruption via PRAGMA integrity_check
    And restores cubeos.db from /cubeos/data/backups/cubeos.db.last-known-good
    And logs the restoration to audit.log
    And boots normally

  # REQ-117 — unrecoverable DB triggers recovery wizard
  Scenario: Both DB and backup corrupted enters recovery-wizard mode
    Given /cubeos/data/cubeos.db is corrupted
    And /cubeos/data/backups/cubeos.db.last-known-good is also corrupted
    When the Pi boots
    Then cubeos-init.service enters RECOVERY_WIZARD_MODE
    And the dashboard shows the recovery-wizard UI
    And no user-app coreapps are started

  # REQ-104 — Article VI gate on hostapd
  Scenario: hostapd does not start when profile != all_in_one
    Given the active access profile is "standard"
    When the Pi boots
    Then hostapd is NOT started
    And Pi-hole DHCP is NOT enabled
