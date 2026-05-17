Feature: CubeOS access profiles (spec/004 — retrospective)

  Background:
    Given the system has the three-profile catalog (standard, advanced, all_in_one)
    And the first-boot wizard has been completed
    And the current profile is "standard"

  # REQ-400 + REQ-401
  Scenario: Default profile after first-boot is standard
    Then the access_profiles table shows profile="standard" for this device

  # REQ-402 + REQ-411 + REQ-412
  Scenario: Standard profile hides engineer surfaces
    When the operator opens the dashboard
    Then the navigation menu does NOT show "Swarm GUI"
    And the navigation menu does NOT show "FlowEngine inspector"
    And /swarm-gui returns 403 if accessed directly

  # REQ-405 + REQ-406 + REQ-407
  Scenario: Switching to advanced profile activates engineer surfaces
    When the operator POSTs /api/v1/access-profile/switch with {profile:"advanced"}
    Then the access_profile_switch FlowEngine saga runs
    And the navigation menu now shows "Swarm GUI"
    And the navigation menu now shows "FlowEngine inspector"

  # REQ-404 + REQ-414 — Article VI gate
  Scenario: Switching to all_in_one enables DHCP only with managed interface
    Given the operator has designated wlan0 as the managed interface
    When the operator switches to all_in_one profile
    Then Pi-hole DHCP starts serving on wlan0
    And the audit log records the DHCP-enable event

  # REQ-415 — REJECT DHCP without all_in_one
  Scenario: DHCP enable request rejected when profile != all_in_one
    Given the current profile is "standard"
    When the operator POSTs /api/v1/network/dhcp with {enabled:true}
    Then the response is HTTP 409
    And the response body explains "DHCP requires all_in_one profile + managed interface"

  # REQ-408 — saga rollback
  Scenario: Failed profile switch rolls back cleanly
    Given switching to all_in_one will fail because no managed interface is designated
    When the operator attempts the switch
    Then the saga aborts at step 4 (firewall update)
    And compensating actions restore the previous profile state
    And the audit log records the failed switch with reason

  # REQ-416 — clean DHCP shutdown on switch-away
  Scenario: Switching away from all_in_one shuts DHCP cleanly
    Given current profile is "all_in_one" with DHCP serving 5 active leases
    When the operator switches to "advanced"
    Then Pi-hole DHCP stops accepting new leases
    And existing leases continue serving until their normal renewal timeout

  # REQ-417 + REQ-418 — no custom profiles
  Scenario: Custom profile name rejected
    When the operator POSTs /api/v1/access-profile/switch with {profile:"my-custom"}
    Then the response is HTTP 400 with body explaining the three valid profiles

  # REQ-420 — history endpoint
  Scenario: Profile change history is retrievable
    Given the operator has switched profiles 3 times today
    When the operator GETs /api/v1/access-profile/history
    Then the response contains the 3 most recent switches
    And each entry has from-profile, to-profile, operator, timestamp
