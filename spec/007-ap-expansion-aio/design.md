# Design — AP expansion (AIO + TLS) (spec/007)

Phase 12 polishes `all_in_one`. Two strands: AIO interface selector + local-CA TLS.

## File-level paths (future-work)

| Function | Real path |
|---|---|
| AIO interface API | new `api/internal/handlers/network_aio.go` |
| Dashboard selector UI | extend `dashboard/src/components/settings/WiFiInterfacesPanel.vue` (CGC-verified exists) |
| Local CA generation | new `hal/internal/handlers/security_ca.go` |
| NPM cert wiring | `coreapps/npm/cubeos-cube-vhost.conf` (new) |
| CA cert API | new `api/internal/handlers/security_cacert.go` |
| Auto-renewal workflow | new `api/internal/flowengine/workflows/cert_renewal.go` |
| Trust-CA landing | new `dashboard/src/components/wizard/TrustCAWizard.vue` (alongside existing FirstBootWizard.vue) |
| mDNS announcer | new `hal/internal/handlers/mdns_announce.go` |

## Local CA generation

```
First boot:
  openssl ecparam -genkey -name prime256v1 -out /cubeos/data/ca/ca.key
  openssl req -new -x509 -key /cubeos/data/ca/ca.key -days 3650 \
      -subj "/CN=CubeOS Local CA/O=CubeOS Device $DEVICE_ID" \
      -out /cubeos/data/ca/ca.crt
  chmod 600 /cubeos/data/ca/ca.key
```

Per-cert issuance via openssl x509 signing.

## Browser trust UX

1. NPM serves `cubeos.cube` with local-CA-signed cert.
2. Browser shows TLS warning.
3. Operator clicks Advanced → Continue anyway.
4. Lands on `/trust-ca` page (`TrustCAWizard.vue`).
5. One-click CA-cert download + per-OS guide.
6. After import, browser restart → cubeos.cube is trusted.

## Out of scope

- Public-CA-issued cert (Let's Encrypt for private domains doesn't work).
- HSM-backed CA key — operator-overridable.
- Cert pinning enforcement (would break trust-import path).
