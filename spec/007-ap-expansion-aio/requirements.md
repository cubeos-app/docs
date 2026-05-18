# Requirements — AP expansion (AIO interface selector + TLS) (spec/007)

Source: `CUBEOS_PROJECT_ROADMAP_v4.md` §2 "Phase 12".

> ID convention: 700-block.

REQ-700: While the active profile is `all_in_one`, the system shall display the managed-interface selector in Settings → Network.
REQ-701: The system shall list every AP-capable interface (from spec/005) PLUS every wired Ethernet interface in the selector.
REQ-702: When the operator picks a managed interface, the system shall persist it to the `network_modes.dhcp_managed_interface` column (schema v23+) and trigger the network-mode-switch workflow.
REQ-703: While no managed interface is selected, the system shall NOT enable Pi-hole DHCP (Article VI gate stays armed).
REQ-704: When two WiFi adapters are present, the system shall allow operator to designate one as AP-managed and the other as uplink-client.
REQ-705: The system shall NOT allow the same interface to be both AP-managed AND uplink-client (mutual exclusion in API + UI).
REQ-706: When the operator violates the mutual exclusion via API, the system shall reject with HTTP 409.
REQ-707: The system shall generate a local Certificate Authority on first boot, persist private key + cert at `/cubeos/data/ca/`.
REQ-708: The system shall issue a TLS certificate for `cubeos.cube` + every coreapp FQDN signed by the local CA.
REQ-709: The system shall configure NPM (the reverse proxy) to serve the local-CA-signed cert for `cubeos.cube`.
REQ-710: The system shall expose `GET /api/v1/security/ca-cert` returning the CA's public cert in PEM format.
REQ-711: When the operator first connects to `https://cubeos.cube`, the system shall present a "Trust this CA" landing page with download + per-OS install instructions.
REQ-712: While the operator has not trusted the CA, the system shall NOT block dashboard access (graceful TLS warning).
REQ-713: The system shall renew the cubeos.cube cert 30 days before expiry.
REQ-714: The system shall expose `POST /api/v1/security/ca-cert/rotate` for operator-triggered CA rotation.
REQ-715: When the CA is rotated, the system shall re-issue all dependent certs + restart NPM atomically.
REQ-716: When the CA is rotated, the system shall log the rotation event to `/cubeos/data/audit.log`.
REQ-717: The system shall provide a one-page guide at `https://cubeos.cube/trust-ca` covering: download the CA cert, install on macOS / Windows / Linux / iOS / Android.
REQ-718: When the operator imports the CA + restarts the browser, the system shall serve `https://cubeos.cube` with no TLS warning.
REQ-719: The system shall publish the local CA cert via mDNS as `_cubeos-ca._tcp` for auto-discovery.
REQ-720: While the device is in `offline_hotspot` mode, the system shall continue serving mDNS announcements on the AP-managed interface.
