# Steering — Security baseline

Hardened defaults shipped by CubeOS at the OS layer + per-repo. Condensed from `architecture/09_PRODUCTION_HARDENING.md` + per-component constitutions.

## OS layer

- **SSH** — password auth disabled, root login disabled, key auth only, default user `cubeos`.
- **fail2ban** — sshd, npm, cubeos-api, pihole-web filters. 5-in-10min → 1h ban default.
- **Hardware watchdog** — enabled via `dtparam=watchdog=on`; `RuntimeWatchdogSec=15s`. Wrapped by `hal/internal/handlers/system.go` `/watchdog/*` endpoints.
- **sysctl hardening** — `kernel.dmesg_restrict=1`, `kernel.kptr_restrict=2`, `net.ipv4.tcp_syncookies=1`, source-route/redirect rejection.
- **nftables** firewall — default-deny inbound except SSH, HTTP/HTTPS via NPM, DHCP on managed interface (per Article VI).
- **Read-only root** opt-in via `cubeos-cli system harden --readonly-root`.

## HAL ACL (per hal/PROJECT.md + constitution C-I/II/III)

3-role ACL via `X-HAL-Key` header. Roles: `core` (full), `meshsat` (comms HW + read system), `readonly` (GET system+sensors). `CUBEOS_TIER` full/container gating for destructive endpoints (netplan write, NAT enable, compose recreate, AP revert).

## JWT auth (per api/)

- HS256, `JWT_SECRET` from `/cubeos/config/secrets.env`.
- Default token TTL 24h, refresh 7d.
- All API routes except `/health` and `/api/v1/auth/login` gated by JWT middleware (per api/ constitution C-III).
- Failed auth → fail2ban.

## Audit log

- Every state-changing API call writes to `/cubeos/data/audit.log` (JSONL).
- 90-day default retention.
- Append-only at application layer.
- Tamper resistance NOT cryptographic; operators wanting hash-chain ship to external syslog-ng.

## Update channel

- `apt-get` from Debian + Pi + `get.cubeos.app/apt`.
- NOT auto-applied; operator runs `cubeos-cli system update` then `cubeos-cli system upgrade`.

## What CubeOS does NOT do (deliberately)

- No telemetry / cloud metrics / phone-home for license validation.
- No mandatory cloud account.
- No first-boot internet requirement.
