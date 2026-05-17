# Design — AP expansion (AIO interface selector + TLS) (spec/007)

Phase 12 polishes the `all_in_one` profile. Two strands:

1. **AIO interface selector** — explicit operator choice of which physical interface is "the AP-managed one" (current behavior: auto-detected with no UI override).
2. **Local-CA TLS** — eliminate the "this site is not secure" browser warning on `cubeos.cube`.

## Interface selector UI

Lives in Settings → Network → "Managed interface" dropdown. Visible only when profile = `all_in_one` (REQ-700). Lists:

- Every AP-capable WiFi interface (from spec/005 REQ-503)
- Every wired Ethernet interface

Operator picks one; the network-mode-switch saga (per spec/008) reconfigures:

- hostapd (if WiFi chosen) OR `network/ethernet` static-IP config (if Ethernet chosen)
- Pi-hole DHCP binds to the chosen interface
- nftables rules update for the chosen interface
- Firewall rules for the OTHER interfaces become uplink-only (no DHCP responses)

## Mutual exclusion: AP-managed vs uplink-client

When the operator has TWO WiFi adapters and both could plausibly be AP OR client, the UI offers two pickers:

- "Managed interface" (AP-managed) → one of the WiFi adapters or an Ethernet iface
- "Uplink interface" (client) → can be the OTHER WiFi adapter, an Ethernet iface, or USB tether

Validation: managed_interface != uplink_interface (REQ-705). Violations return HTTP 409 (REQ-706).

## Local CA generation

```
first boot:
  openssl ecparam -genkey -name prime256v1 -out /cubeos/data/ca/ca.key
  openssl req -new -x509 -key /cubeos/data/ca/ca.key -days 3650 \
      -subj "/CN=CubeOS Local CA/O=CubeOS Device $DEVICE_ID" \
      -out /cubeos/data/ca/ca.crt
  chmod 600 /cubeos/data/ca/ca.key
```

Per-cert issuance:
```
openssl req -new -newkey ec:/cubeos/data/ca/ca.key -nodes \
    -keyout /cubeos/data/certs/cubeos.cube.key \
    -subj "/CN=cubeos.cube" -out /tmp/csr.pem
openssl x509 -req -in /tmp/csr.pem -CA /cubeos/data/ca/ca.crt -CAkey /cubeos/data/ca/ca.key \
    -CAcreateserial -days 365 -out /cubeos/data/certs/cubeos.cube.crt \
    -extfile <(printf "subjectAltName=DNS:cubeos.cube,DNS:*.cubeos.cube")
```

NPM consumes `/cubeos/data/certs/cubeos.cube.{crt,key}` via a bind-mount.

## Browser trust UX

The first time an operator visits `https://cubeos.cube`, the browser shows a TLS warning (the local CA is untrusted). CubeOS handles this gracefully:

1. NPM serves `cubeos.cube` with the local-CA-signed cert.
2. Browser shows warning; operator can choose "Advanced → Continue anyway."
3. Once they click through, they land on `/trust-ca` (a special public-route page).
4. The page offers a one-click CA-cert download + per-OS install guides.
5. After installing the CA, browser restart → `cubeos.cube` is now trusted.

Alternative: operator can scan a QR code shown on the page (mobile devices) that downloads the CA cert into the Keychain (iOS) / Credential Storage (Android).

## mDNS discovery

`_cubeos-ca._tcp` SRV record + TXT record carrying CA cert SHA-256. Allows CubeOS CLI tools (`cubeos-cli`) running on operator laptops to auto-discover + trust the CA without manual cert installation. Active on the AP-managed interface even in `offline_hotspot` mode.

## Out of scope

- Public-CA-issued cert (Let's Encrypt). CubeOS may be on a private domain (`cubeos.cube`) which Let's Encrypt won't issue for. Operators with public domains can layer LE on top via NPM's existing LE integration.
- Hardware Security Module integration for CA key. Operator-overridable.
- Cert pinning enforcement (would break operator trust-import path).
