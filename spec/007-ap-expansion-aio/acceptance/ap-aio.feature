Feature: AP expansion — AIO interface + TLS (spec/007)

  # Covers: REQ-700, REQ-701, REQ-702, REQ-703, REQ-704, REQ-705, REQ-706, REQ-707, REQ-708, REQ-709, REQ-710, REQ-711, REQ-712, REQ-713, REQ-714, REQ-715, REQ-716, REQ-718, REQ-719

  Background:
    Given the active profile is all_in_one
    And the Pi has onboard wlan0 + USB wlan1 + Ethernet eth0

  Scenario: Selector lists all candidates
    When the operator opens Settings → Network
    Then the managed-interface dropdown lists wlan0, wlan1, eth0

  Scenario: Picking managed interface enables DHCP on it
    When the operator picks wlan1 as managed interface
    Then network_modes.dhcp_managed_interface is set to wlan1
    And Pi-hole DHCP starts serving on wlan1

  Scenario: Cannot set same interface as both managed and uplink
    When the operator POSTs {managed:"wlan1", uplink:"wlan1"}
    Then HTTP 409 is returned with mutual-exclusion explanation

  Scenario: Local CA issues cubeos.cube cert at first boot
    Given the Pi has just completed first-boot wizard
    When the operator inspects /cubeos/data/ca/
    Then ca.key and ca.crt exist
    And /cubeos/data/certs/cubeos.cube.crt exists
    And NPM serves cubeos.cube with that cert

  Scenario: Operator downloads CA cert
    When the operator GETs /api/v1/security/ca-cert
    Then the response is application/x-pem-file

  Scenario: Operator clicks through TLS warning to /trust-ca
    Given the operator's browser does NOT yet trust the local CA
    When the operator visits https://cubeos.cube and clicks through the warning
    Then they land on /trust-ca
    And they can download the CA cert via a one-click button
    And per-OS install instructions are shown

  Scenario: Dashboard remains accessible pre-trust
    Given the operator has NOT imported the CA
    When the operator clicks through the TLS warning
    Then the dashboard loads (no HSTS hard-fail)

  Scenario: Cert auto-renews 30 days before expiry
    Given /cubeos/data/certs/cubeos.cube.crt expires in 29 days
    When the cert-renewal workflow runs
    Then a new cert is issued with fresh 1-year validity
    And NPM reloads

  Scenario: CA rotation re-issues all dependent certs
    When the operator POSTs /api/v1/security/ca-cert/rotate
    Then a new CA key+cert is generated
    And every dependent cert is re-issued from the new CA
    And NPM restarts atomically
    And audit.log records the rotation

  Scenario: cubeos-cli auto-discovers CA via mDNS
    Given a laptop is on the same network as the Pi's AP interface
    When cubeos-cli runs `cubeos-cli ca discover`
    Then the CA cert SHA-256 is retrieved via mDNS _cubeos-ca._tcp
