Feature: Swarm Orchestrator + FlowEngine (spec/009 — RETROSPECTIVE)

  # Covers: REQ-900, REQ-901, REQ-903, REQ-904, REQ-905, REQ-907, REQ-908, REQ-911, REQ-912, REQ-913, REQ-915, REQ-916, REQ-917

  Scenario: Direct Docker calls outside Orchestrator are forbidden
    When a developer adds a code path that calls `docker.NewClient()` outside managers/
    Then code review rejects it
    And pre-commit-check.sh flags the violation

  Scenario: Only apps table receives writes
    Given an operator installs a new app
    When the install completes via appstore_install workflow
    Then a row is inserted into `apps`
    And the legacy `installed_apps` is NOT written to

  Scenario: Swarm reconciliation restarts a killed container
    Given app "uptime-kuma" is running as a Swarm service
    When the operator kills the container manually
    Then within 30 seconds Swarm restarts the container

  Scenario: Install workflow compensation rolls back cleanly
    Given the appstore_install workflow fails at the proxy-create step
    When the failure occurs
    Then compensating actions run in reverse from that step
    And DNS entry is removed
    And stack is removed
    And port is released
    And no `apps` row was inserted

  Scenario: Port pool exhaustion returns HTTP 409
    Given all 900 user-app ports (6100-6999) are in use
    When the operator tries to install another app
    Then HTTP 409 is returned

  Scenario: CasaOS compose transformed inside activity
    Given the operator installs a CasaOS-format app with `restart: always`
    When the activities/appstore.go transformation runs
    Then the output has `deploy.restart_policy.condition: any`

  Scenario: Swarm initialised with --task-history-limit 1
    When the system initializes Swarm
    Then `docker info` reports task-history-limit=1

  Scenario: Swarm GUI hidden in standard profile
    Given the current profile is standard
    When the operator opens the dashboard
    Then components/swarm/SwarmOverview.vue is NOT rendered

  Scenario: No third-party Swarm GUI
    When the operator inspects deployed Swarm stacks
    Then no stack uses portainer/portainer
    And no stack uses swarmpit/swarmpit

  Scenario: 12 workflows are present
    When inspecting api/internal/flowengine/workflows/
    Then 12 *.go workflow files are present (excluding tests)
    And they include appstore_install, appstore_remove, app_install, app_remove, network_mode_switch, wifi_client_switch, access_profile_switch, first_boot_setup, backup, restore, registry_cache, system_update

  Scenario: 14 activities are present
    When inspecting api/internal/flowengine/activities/
    Then 14 *.go activity files are present (excluding tests)

  Scenario: No managers/compose.go file
    When inspecting api/internal/managers/
    Then there is NO compose.go file (compose transformation lives in activities)
