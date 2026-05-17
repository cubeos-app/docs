Feature: Swarm Orchestrator + FlowEngine (spec/009 — retrospective)

  # REQ-900 + REQ-901
  Scenario: Direct Docker calls outside Orchestrator are forbidden
    When a developer adds a code path that calls `docker.NewClient()` outside managers/
    Then code review rejects it
    And pre-commit-check.sh flags the violation

  # REQ-903 + REQ-905
  Scenario: Only apps table receives writes after migration
    Given an operator installs a new app
    When the install completes
    Then a row is inserted into `apps`
    And NO row is inserted into the deprecated `installed_apps`

  # REQ-906 + REQ-907 — self-healing
  Scenario: Swarm reconciliation restarts a killed container
    Given app "uptime-kuma" is running as a Swarm service
    When the operator kills the container manually (`docker kill ...`)
    Then within 30 seconds Swarm restarts the container
    And the audit log records the unexpected restart event

  # REQ-909 + REQ-910 — saga compensation
  Scenario: Install saga failure compensates cleanly
    Given the install_app saga fails at step 5 (proxy create) for app X
    When the failure occurs
    Then compensating actions run in reverse from step 5
    And DNS entry created in step 4 is removed
    And stack deployed in step 3 is removed
    And port allocated in step 1 is released
    And no `apps` row was inserted

  # REQ-912 + REQ-913 + REQ-914 — port allocation
  Scenario: Port allocator releases on uninstall
    Given app Y owns port 6150
    When the operator uninstalls app Y
    Then port 6150 is released
    And a subsequent install can allocate 6150

  Scenario: Port pool exhaustion returns HTTP 409
    Given all 900 user-app ports (6100-6999) are in use
    When the operator tries to install another app
    Then the response is HTTP 409 with body explaining port pool exhaustion

  # REQ-915 + REQ-916 — compose transform
  Scenario: CasaOS compose transformed to Swarm-compatible
    Given the operator installs a CasaOS-format app with `restart: always`
    When compose.go transforms it
    Then the output has `deploy.restart_policy.condition: any`
    And `depends_on: condition: service_healthy` is dropped with documented fallback

  # REQ-919 — task-history-limit
  Scenario: Swarm initialized with --task-history-limit 1
    When the system initializes Swarm
    Then `docker info` reports task-history-limit=1

  # REQ-921 + REQ-412 (cross-spec) — Swarm GUI gated
  Scenario: Swarm GUI hidden in standard profile
    Given the current profile is standard
    When the operator opens the dashboard
    Then the navigation menu does not show "Swarm GUI"
    And /swarm-gui returns 403 if accessed directly

  # REQ-922 — no third-party Swarm GUI
  Scenario: Docker images list contains no Portainer / Swarmpit
    When the operator inspects deployed Swarm stacks
    Then no stack uses portainer/portainer
    And no stack uses swarmpit/swarmpit
