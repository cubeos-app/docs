Feature: CubeOS Pi Imager listing (spec/003)

  # Covers: REQ-300, REQ-301, REQ-303, REQ-304, REQ-305, REQ-306, REQ-308, REQ-311, REQ-312, REQ-314, REQ-315

  Background:
    Given the CubeOS release pipeline produces 5 image variants

  Scenario: Manifest generated on tagged release
    Given a commit `chore: bump version to v0.2.0` triggers Packer
    When Packer + CI complete
    Then pi-imager-manifest.json contains 5 subitems
    And each subitem has name, description, url, sha256, size, release_notes_url

  Scenario: Manifest verifier rejects mismatched hash
    Given a manifest entry has the wrong sha256 for the published image
    When verify-manifest.sh runs
    Then the script exits non-zero
    And CI halts before uploading

  Scenario: Manifest is signed
    When the release pipeline completes
    Then pi-imager-manifest.json.sig is present
    And the signature verifies against the published CubeOS release pubkey

  Scenario: Operator sees friendly variant names in Pi Imager
    When the operator opens Pi Imager and navigates to CubeOS
    Then variant names "CubeOS Pi 5 (full)", "CubeOS Pi 5 (lite — no AI/ML)" are shown

  Scenario: Download corruption triggers Pi Imager abort
    Given the operator selects "CubeOS Pi 5 (full)"
    And the downloaded file is corrupted in transit
    When Pi Imager computes the sha256
    Then sha256 does not match the manifest entry
    And Pi Imager aborts with a clear error

  Scenario: Old versions remain in manifest with eol flag
    Given a version v0.1.0 is older than 12 months but within retention
    When the manifest is generated
    Then v0.1.0 is still present
    And v0.1.0 has eol=true if marked end-of-life

  Scenario: Canonical manifest URL never changes
    Given the URL was submitted to Pi Foundation
    When a release pipeline runs
    Then the manifest is served at the same canonical URL
