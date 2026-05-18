Feature: CubeOS local registry (spec/002)

  # Covers: REQ-200, REQ-201, REQ-203, REQ-207, REQ-208, REQ-210, REQ-211, REQ-212, REQ-213, REQ-214, REQ-215, REQ-216

  Background:
    Given the local registry stack is deployed at localhost:5000

  Scenario: Registry binds loopback only
    When the operator runs `ss -tnlp | grep :5000`
    Then the listener is on 127.0.0.1:5000

  Scenario: Coreapp deploy fails when image missing from local registry
    Given a coreapp compose references `localhost:5000/missing-app:v1.0.0` not in the registry
    When the operator triggers deploy
    Then the deploy fails with HTTP 422 and body listing the missing image

  Scenario: Operator imports a tar-archived image
    Given the operator has a Docker image saved as /tmp/myapp.tar
    When the operator imports via Settings → Registry → Import image
    Then the image is loaded into the local registry
    And /cubeos/data/registry/imports.log records the event

  Scenario: Pull from public registry blocked in offline_hotspot mode
    Given active mode is offline_hotspot
    When any code path attempts to pull from docker.io
    Then the pull is blocked with error "offline_hotspot mode forbids remote pulls"

  Scenario: GC dry-run shows reclaim estimate
    Given untagged layers older than 30 days exist
    When the operator invokes GC dry-run
    Then the dashboard shows the bytes-to-reclaim estimate
    And no layer referenced by an active stack is in the reclaim set

  Scenario: Registry status endpoint reports key metrics
    When the operator queries GET /api/v1/registry/status
    Then the response contains storage_used_bytes, image_count, last_import_at, last_gc_at

  Scenario: Registry unreachable blocks app-install
    Given the registry stack is stopped
    When the operator opens the App Store
    Then a critical-severity health banner is shown
    And Install buttons are disabled
