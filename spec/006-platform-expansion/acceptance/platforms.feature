Feature: Platform expansion (spec/006)

  # Covers: REQ-600, REQ-601, REQ-602, REQ-603, REQ-604, REQ-605, REQ-606, REQ-607, REQ-608, REQ-609, REQ-610, REQ-611, REQ-612, REQ-613, REQ-614, REQ-615

  Scenario: Proxmox helper script creates LXC
    Given a PVE 9 host with shell access
    When the operator runs `bash <(curl -s https://get.cubeos.app/platforms/proxmox/install-cubeos-lxc.sh)`
    Then a CubeOS LXC container is created
    And the container boots and reaches the first-boot wizard

  Scenario: Physical x86 USB installer wizard installs CubeOS
    Given a physical x86 box booted from the CubeOS USB image (UEFI)
    When the installer wizard completes
    Then CubeOS is installed to the chosen disk
    And Secure Boot remained enabled throughout

  Scenario: Regression suite blocks release if a platform fails
    Given the release candidate v0.3.0 is staged
    When platform-regression-pi5.sh fails on a critical test
    Then the release tag pipeline halts

  Scenario: Platform-support matrix lists current status
    When the operator visits cubeos.app/platforms
    Then a matrix lists Pi 5 (Supported), Pi 4 (Supported), x86 LXC (Supported), x86 physical (Community), BananaPi (Deferred)

  Scenario: BananaPi placeholder welcomes community contributions
    When a community contributor opens releases/platforms/bananapi/
    Then a PLACEHOLDER.md explains the deferral
    And describes the path to upgrading the platform to Community status

  Scenario: GPIO UI hidden on x86 (no GPIO hardware)
    Given the system runs on x86 hardware with no GPIO
    When the operator opens the dashboard
    Then the GPIO settings page is hidden from navigation

  Scenario: New-platform PR requires regression artifacts
    When a contributor opens a PR adding `releases/platforms/rock5b/`
    Then the PR template requires regression test output attached
    And CI fails the PR if regression artifacts are missing
