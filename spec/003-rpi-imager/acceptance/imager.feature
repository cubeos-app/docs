Feature: CubeOS Pi Imager listing (spec/003)

  Background:
    Given the CubeOS release pipeline produces 5 image variants
    And the GitLab release key is available in the CI variable vault

  # REQ-300 + REQ-301
  Scenario: Manifest generated on tagged release
    Given a commit `chore: bump version to v0.2.0` triggers Packer
    When Packer + CI complete successfully
    Then pi-imager-manifest.json contains 5 subitems
    And each subitem has name, description, url, sha256, size, release_notes_url

  # REQ-303 — pre-publication verification
  Scenario: Manifest verifier rejects mismatched hash
    Given a manifest entry has the wrong sha256 for the published image
    When verify-manifest.sh runs
    Then the script exits non-zero
    And the CI pipeline halts before uploading the manifest

  # REQ-314 + REQ-315 — signature
  Scenario: Manifest is signed and signature published
    When the release pipeline completes
    Then pi-imager-manifest.json.sig is present alongside pi-imager-manifest.json
    And the signature verifies against the published CubeOS release pubkey

  # REQ-304 + REQ-305
  Scenario: Operator sees friendly variant names in Pi Imager
    When the operator opens Raspberry Pi Imager and navigates to CubeOS
    Then the variant names "CubeOS Pi 5 (full)", "CubeOS Pi 5 (lite — no AI/ML)" are shown
    And the operator can pick any variant for flashing

  # REQ-306 — Pi Imager integrity check
  Scenario: Download corruption triggers Pi Imager abort
    Given the operator selects "CubeOS Pi 5 (full)"
    And the downloaded file is corrupted in transit
    When Pi Imager computes the sha256 after download
    Then the sha256 does not match the manifest entry
    And Pi Imager aborts the flash with a clear error message

  # REQ-318 + REQ-319 — historical retention
  Scenario: Old versions remain in manifest with eol flag
    Given a version v0.1.0 is older than 12 months but within retention
    When the manifest is generated
    Then v0.1.0 is still present
    And v0.1.0 has eol=true if marked end-of-life
    And no version newer than 12 months is removed

  # REQ-308 — URL stability
  Scenario: Canonical manifest URL never changes
    Given the URL https://get.cubeos.app/pi-imager-manifest.json was submitted to Pi Foundation
    When a release pipeline runs
    Then the manifest is served at the same canonical URL
    And the url-stability-check.sh validation passes
