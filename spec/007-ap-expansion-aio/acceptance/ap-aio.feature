Feature: AP expansion — AIO interface selector + TLS (spec/007)

  Background:
    Given the active profile is "all_in_one"
    And the Pi has onboard wlan0 + USB wlan1 + Ethernet eth0

  # REQ-700 + REQ-701
  Scenario: Managed-interface selector lists all candidates
    When the operator opens Settings → Network
    Then the managed-interface dropdown lists wlan0, wlan1, eth0

  # REQ-702 + REQ-703
  Scenario: Picking a managed interface enables DHCP on it
    When the operator picks wlan1 as managed interface
    Then network_modes.dhcp_managed_interface is set to wlan1
    And Pi-hole DHCP starts serving on wlan1
    And Pi-hole DHCP is NOT serving on any other interface

  # REQ-704 + REQ-705 + REQ-706 — mutual exclusion
  Scenario: Cannot set same interface as both managed and uplink
    When the operator POSTs {managed:"wlan1", uplink:"wlan1"}
    Then the response is HTTP 409
    And the body explains the mutual-exclusion rule

  # REQ-707 + REQ-708 + REQ-709
  Scenario: Local CA issues cubeos.cube cert at first boot
    Given the Pi has just completed first-boot wizard
    When the operator inspects /cubeos/data/ca/
    Then ca.key and ca.crt exist
    And /cubeos/data/certs/cubeos.cube.crt exists
    And NPM serves cubeos.cube with that cert (`openssl s_client` matches)

  # REQ-710 — CA cert exposure
  Scenario: Operator downloads the CA cert
    When the operator GETs /api/v1/security/ca-cert
    Then the response is application/x-pem-file
    And the response body is the CA's public cert

  # REQ-711 + REQ-718 — trust landing
  Scenario: Operator clicks through TLS warning to /trust-ca
    Given the operator's browser does NOT yet trust the local CA
    When the operator visits https://cubeos.cube and clicks through the warning
    Then they land on /trust-ca
    And they can download the CA cert via a one-click button
    And per-OS install instructions are shown

  # REQ-712 — no HSTS hard-fail
  Scenario: Dashboard remains accessible pre-trust
    Given the operator has NOT yet imported the CA
    When the operator clicks through the TLS warning
    Then the dashboard loads (no HSTS hard-fail blocks it)

  # REQ-713 — auto-renewal
  Scenario: Cert auto-renews 30 days before expiry
    Given /cubeos/data/certs/cubeos.cube.crt expires in 29 days
    When the cert-renewal FlowEngine workflow runs
    Then a new cert is issued with a fresh 1-year validity
    And NPM reloads to pick up the new cert

  # REQ-714 + REQ-715 + REQ-716 — CA rotation
  Scenario: Operator-triggered CA rotation re-issues all dependent certs
    When the operator POSTs /api/v1/security/ca-cert/rotate
    Then a new CA key+cert is generated
    And every dependent cert is re-issued from the new CA
    And NPM restarts atomically
    And the audit log records the rotation

  # REQ-719 — mDNS discovery
  Scenario: cubeos-cli auto-discovers the CA via mDNS
    Given a laptop is on the same network as the Pi's AP interface
    When cubeos-cli runs `cubeos-cli ca discover`
    Then the CA cert SHA-256 is retrieved via mDNS _cubeos-ca._tcp
    And the operator is prompted to trust it
