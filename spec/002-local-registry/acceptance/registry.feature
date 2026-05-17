Feature: CubeOS local registry (spec/002)

  Background:
    Given the local registry stack is deployed at localhost:5000
    And the registry data dir /cubeos/data/registry/ is persistent

  # REQ-200 + REQ-201
  Scenario: Registry binds loopback only
    When the operator runs `ss -tnlp | grep :5000`
    Then the listener is on 127.0.0.1:5000
    And no remote-reachable listener is bound

  # REQ-203 + REQ-211
  Scenario: Coreapp deploy fails when image missing from local registry
    Given a coreapp compose file references `localhost:5000/missing-app:v1.0.0`
    And `missing-app:v1.0.0` is NOT in the local registry
    When the operator triggers deploy
    Then the deploy fails with error "image not present in local registry: missing-app:v1.0.0"
    And the dashboard surfaces the actionable error

  # REQ-207 + REQ-208
  Scenario: Operator imports a tar-archived image
    Given the operator has a Docker image saved as `/tmp/myapp.tar`
    When the operator imports via Settings → Registry → Import image
    Then the image is loaded into the local registry
    And /cubeos/data/registry/imports.log records the import event

  # REQ-210 — offline mode guard
  Scenario: Pull from public registry blocked in offline_hotspot mode
    Given active mode is `offline_hotspot`
    When any code path attempts to pull from `docker.io` or `ghcr.io`
    Then the pull is blocked with error "offline_hotspot mode forbids remote pulls"

  # REQ-212 + REQ-213 + REQ-214 — GC
  Scenario: Garbage collection dry-run shows reclaim estimate
    Given the registry has untagged layers older than 30 days
    When the operator invokes GC dry-run
    Then the dashboard shows the bytes-to-reclaim estimate
    And no layer referenced by an active stack is in the reclaim set

  Scenario: Garbage collection applies after confirmation
    Given the operator confirmed the GC dry-run estimate
    When GC apply runs
    Then untagged unreferenced layers older than 30 days are deleted
    And /cubeos/data/registry/gc.log records the bytes-reclaimed count

  # REQ-215
  Scenario: Registry status endpoint reports key metrics
    When the operator queries GET /api/v1/registry/status
    Then the response contains storage_used_bytes, image_count, last_import_at, last_gc_at

  # REQ-216
  Scenario: Registry unreachable blocks app-install actions
    Given the registry stack is stopped
    When the operator opens the App Store
    Then a critical-severity health banner is shown
    And the "Install" buttons are disabled
