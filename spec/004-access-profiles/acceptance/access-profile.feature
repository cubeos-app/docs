Feature: CubeOS access profiles (spec/004 — RETROSPECTIVE)

  # Covers: REQ-400, REQ-401, REQ-402, REQ-403, REQ-404, REQ-405, REQ-407, REQ-408, REQ-411, REQ-412, REQ-414, REQ-415, REQ-416, REQ-417, REQ-418, REQ-419, REQ-420, REQ-424

  Background:
    Given first-boot wizard completed
    And the current profile is "standard"

  Scenario: Default profile after first-boot is standard
    Then the access_profiles table shows profile="standard"

  Scenario: Standard profile hides Swarm-GUI components
    When the operator opens the dashboard
    Then components/swarm/SwarmOverview.vue is NOT rendered
    And components/swarm/StackList.vue is NOT rendered

  Scenario: Switching to advanced activates Swarm GUI
    When the operator POSTs /api/v1/access-profile/switch with {profile:"advanced"}
    Then the access_profile_switch FlowEngine workflow runs (api/internal/flowengine/workflows/access_profile_switch.go)
    And on completion components/swarm/SwarmOverview.vue is rendered

  Scenario: Switching to all_in_one enables DHCP with managed interface
    Given the operator has designated wlan0 as managed interface
    When the operator switches to all_in_one
    Then Pi-hole DHCP starts serving on wlan0
    And audit log records the DHCP-enable event

  Scenario: DHCP enable rejected when profile != all_in_one
    Given the current profile is "standard"
    When the operator POSTs /api/v1/network/dhcp with {enabled:true}
    Then HTTP 409 is returned with body explaining the profile requirement

  Scenario: Failed switch rolls back cleanly
    Given switching to all_in_one will fail because no managed interface designated
    When the operator attempts the switch
    Then the workflow aborts at the firewall-update step
    And compensating actions restore the previous profile state

  Scenario: Switch progress surfaces in the modal
    When the operator switches profiles
    Then ProfileSwitchProgressModal.vue shows per-step progress

  Scenario: Custom profile name rejected
    When the operator POSTs /api/v1/access-profile/switch with {profile:"my-custom"}
    Then HTTP 400 is returned

  Scenario: History endpoint returns recent switches
    Given the operator has switched profiles 3 times today
    When the operator GETs /api/v1/access-profile/history
    Then the response contains the 3 most recent switches
