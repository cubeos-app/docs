# Steering — Security baseline

Hardened defaults shipped by CubeOS at the OS layer, condensed from `architecture/09_PRODUCTION_HARDENING.md`.

## Layer 1 — SSH

- Password authentication: **disabled**. SSH key auth only.
- Root login: **disabled**.
- Port: default `22`; configurable but documented as the most-attacked port.
- Default seeded operator user: `cubeos`; first-boot wizard collects the SSH pubkey before exposing any other surface.
- `fail2ban` watches `sshd` logs and bans source IPs after 5 failed attempts in 10 minutes (1-hour ban; persistent bans escalate).

## Layer 2 — fail2ban filters

- `sshd` (above)
- `npm` (Nginx Proxy Manager admin login)
- `cubeos-api` (failed JWT auth)
- `pihole-web` (admin login attempts)

All filters share the same 5-in-10-min → 1-hour ban policy by default. Operator can extend via `/etc/fail2ban/jail.d/`.

## Layer 3 — Watchdog

- Hardware watchdog enabled in `/boot/firmware/config.txt`: `dtparam=watchdog=on`.
- `systemd` configured: `RuntimeWatchdogSec=15s`, `RebootWatchdogSec=30s`.
- If the kernel hangs for >15 seconds without petting the watchdog, the hardware resets the board. Required for unattended Pi deployments per `BOOT-10`.

## Layer 4 — sysctl hardening

`/etc/sysctl.d/99-cubeos.conf` ships with:
- `kernel.dmesg_restrict = 1`
- `kernel.kptr_restrict = 2`
- `net.ipv4.tcp_syncookies = 1`
- `net.ipv4.conf.all.rp_filter = 1`
- `net.ipv4.conf.all.accept_redirects = 0`
- `net.ipv4.conf.all.accept_source_route = 0`
- `net.ipv4.conf.all.log_martians = 1`

## Layer 5 — Read-only root filesystem (opt-in)

- `09_PRODUCTION_HARDENING.md` describes the read-only root scheme (tmpfs `/var/log`, `/tmp`, `/var/cache`; persistent `/cubeos/`).
- Default: writeable rootfs (development-friendly).
- Production: enable read-only via `cubeos-cli system harden --readonly-root` after first-boot wizard completes.

## Layer 6 — Firewall

- `nftables` table `inet cubeos` ships with default-deny inbound on all interfaces except:
  - Loopback (allowed)
  - SSH (port 22) on uplink
  - HTTP/HTTPS (80/443) on uplink (for NPM)
  - DHCP/DNS on the **managed** interface only (per Article VI)
  - WireGuard (51820) on uplink if WireGuard coreapp enabled
- Per-network-mode rule additions / removals are managed by HAL's network endpoint.

## Layer 7 — HAL 3-layer ACL

Per Article I, HAL is the only path to host operations. HAL enforces:

1. **Transport:** HAL binds on `127.0.0.1:6005` only — never on a public interface. API container reaches HAL via `host.docker.internal` mapping.
2. **Identity:** `X-HAL-Key` header carried in every API → HAL request. Key is generated at first boot, stored in `/cubeos/config/secrets.env`, mounted into API container as `HAL_KEY` env. Rotated on operator command.
3. **ACL:** per-endpoint allowlist of which API roles may invoke. `pihole-dhcp-enable` requires `superadmin`; `network-info` allows `viewer`.

## Layer 8 — JWT auth (API)

- `JWT_SECRET` generated at first boot, stored in `secrets.env`.
- Default token lifetime: 24h. Refresh tokens: 7 days.
- All API routes except `/health` and `/api/v1/auth/login` require `Authorization: Bearer <jwt>` per the `JWTAuth` middleware.
- Failed auth attempts go to `fail2ban` (Layer 2).

## Layer 9 — Audit log

- Every state-changing API call writes to `/cubeos/data/audit.log` (JSONL) via the `AuditMiddleware`.
- Retention: 90 days; configurable. Older entries gzipped and archived.
- The audit log is append-only at the application layer (`O_APPEND | O_WRONLY`). Tamper resistance is NOT cryptographic at this layer — operators who need cryptographic tamper-evidence ship logs to an external syslog-ng host (see `meshsat-hub/constitution.md` Article VIII for a SHA-256 hash-chain reference implementation).

## Layer 10 — Update channel

- `apt-get` repositories: Debian + Raspberry Pi + `get.cubeos.app/apt` (CubeOS-curated).
- Updates are NOT auto-applied. Operator runs `cubeos-cli system update` to pull, then `cubeos-cli system upgrade` to apply. This matches Article XV — the deploy is explicit and operator-driven for OS-level changes (CI auto-deploy applies only to coreapp image rebuilds).

## What CubeOS does NOT do (deliberately)

- **No telemetry.** No metrics, no error reports, no "anonymous usage statistics" leave the device.
- **No cloud config.** All config lives on-device. No mandatory cloud account.
- **No mandatory account.** First-boot wizard works fully offline.
- **No phone-home for license validation.** CubeOS is Apache-2.0; there is no license to validate.

## Operator overrides

Every layer above is operator-overridable. The defaults are tuned for "Pi 5 in a vehicle dashboard with no admin access for months." A developer running CubeOS on a desktop for app testing may relax SSH password auth, disable fail2ban, etc. — but each relaxation lives in `/etc/cubeos/security.override` so it survives upgrades and is auditable.
