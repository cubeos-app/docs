# Requirements — AP expansion (AIO interface selector + TLS) (spec/007)

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "Phase 12: AP Expansion (AIO Interface Selector + TLS)".

> ID convention: 700-block (`700..799`).

## Functional requirements

### AIO interface selector (UI)

REQ-700: While the active profile is `all_in_one`, the system shall display the managed-interface selector in Settings → Network.
REQ-701: The system shall list every AP-capable interface (from spec/005 REQ-503) PLUS every wired Ethernet interface in the selector.
REQ-702: When the operator picks a managed interface, the system shall persist it to the `network_modes.dhcp_managed_interface` column (schema v23+) and trigger the network-mode-switch saga.
REQ-703: While no managed interface is selected, the system shall NOT enable Pi-hole DHCP (Article VI gate stays armed).

### Dual-WiFi setup

REQ-704: When two WiFi adapters are present (e.g. onboard wlan0 + USB wlan1), the system shall allow operator to designate one as AP-managed and the other as uplink-client.
REQ-705: The system shall NOT allow the same interface to be both AP-managed AND uplink-client (mutual exclusion enforced in API + UI).
REQ-706: When the operator violates the mutual exclusion via API, the system shall reject with HTTP 409 + explanatory body.

### Local CA + TLS provisioning

REQ-707: The system shall generate a local Certificate Authority on first boot, persist private key + cert at `/cubeos/data/ca/`.
REQ-708: The system shall issue a TLS certificate for `cubeos.cube` + every coreapp FQDN (`*.cubeos.cube` wildcard) signed by the local CA.
REQ-709: The system shall configure NPM (the reverse proxy) to serve the local-CA-signed cert for `cubeos.cube`.
REQ-710: The system shall expose `GET /api/v1/security/ca-cert` returning the CA's public cert in PEM format for operator browser-import.

### Browser trust UX

REQ-711: When the operator first connects to `https://cubeos.cube`, the system shall present a "Trust this CA" landing page that downloads the CA cert + provides per-OS install instructions.
REQ-712: While the operator has not trusted the CA, the system shall NOT block dashboard access (graceful TLS warning rather than HSTS hard-fail).
REQ-713: The system shall renew the cubeos.cube cert 30 days before expiry (cert lifetime: 1 year).

### Cert rotation

REQ-714: The system shall expose `POST /api/v1/security/ca-cert/rotate` for operator-triggered CA rotation.
REQ-715: When the CA is rotated, the system shall re-issue all dependent certs + restart NPM atomically.
REQ-716: When the CA is rotated, the system shall log the rotation event to `/cubeos/data/audit.log`.

### Operator-import flow

REQ-717: The system shall provide a one-page guide at `https://cubeos.cube/trust-ca` covering: download the CA cert, install on macOS / Windows / Linux / iOS / Android.
REQ-718: When the operator imports the CA + restarts the browser, the system shall serve `https://cubeos.cube` with no TLS warning.

### Discovery

REQ-719: The system shall publish the local CA cert via mDNS as `_cubeos-ca._tcp` so well-known CubeOS client tools can auto-discover it.
REQ-720: While the device is in `offline_hotspot` mode, the system shall continue to serve mDNS announcements on the AP-managed interface.
