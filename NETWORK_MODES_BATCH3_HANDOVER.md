# Network Modes Batch 3 — Handover

**Date:** 2026-02-19  
**Tasks:** T11, T12, T13, T14, T15, T16  
**Theme:** Static IP Support (DB Schema + API + Boot-lib)  
**Repos:** api, releases

---

## Summary

Batch 3 adds static IP override support across the full stack. Users can now specify a static IP, netmask, gateway, and DNS servers for the upstream interface instead of using DHCP. The static IP configuration persists in SQLite and survives reboots via netplan templates.

1. **T11** — DB migration 14: adds 6 new columns to `network_config` table
2. **T12** — `StaticIPConfig` struct + extended `SetNetworkModeRequest` model
3. **T13** — API `SetMode()` flow extended: handler → manager → set*Mode → netplan → HAL
4. **T14** — `write_netplan_for_mode()` in boot-lib now generates DHCP or static netplan per mode
5. **T15** — `read_persisted_network_config()` reads static IP fields from SQLite
6. **T16** — `apply_network_mode()` passes static IP globals to netplan writer

---

## Files Changed

### API Repo (`api/`)

| File | Tasks | Changes |
|------|-------|---------|
| `internal/database/schema.go` | T11 | Added 6 columns to `network_config` CREATE TABLE; bumped `CurrentSchemaVersion` to 14 |
| `internal/database/migrations.go` | T11 | Added migration 14: ALTER TABLE adds `use_static_ip`, `static_ip_address`, `static_ip_netmask`, `static_ip_gateway`, `static_dns_primary`, `static_dns_secondary` |
| `internal/models/network.go` | T12 | Added `StaticIPConfig` struct with `IsConfigured()` and `NetmaskToCIDR()` helpers; embedded in `NetworkConfig`; extended `SetNetworkModeRequest` with 6 static IP fields + `ToStaticIPConfig()` |
| `internal/handlers/network.go` | T13 | `SetNetworkMode` handler parses static IP fields from request, validates them, passes `StaticIPConfig` to `SetMode()` |
| `internal/managers/network.go` | T13 | `SetMode()` signature extended with `staticIP models.StaticIPConfig`; `saveConfigToDB()` persists 6 new columns; all 5 `set*Mode()` functions accept and use static IP; `generateNetplanYAML()` produces DHCP or static variants; added `buildDNSBlock()` helper |

### Releases Repo (`releases/`)

| File | Tasks | Changes |
|------|-------|---------|
| `firstboot/cubeos-boot-lib.sh` | T14, T15, T16 | `read_persisted_network_config()` reads 6 static IP columns from SQLite; `write_netplan_for_mode()` generates static IP netplan variants when `NET_USE_STATIC_IP=1`; `apply_network_mode()` logs static IP config |

---

## API Request Format

`POST /api/v1/network/mode` now accepts optional static IP fields:

```json
{
  "mode": "online_eth",
  "use_static_ip": true,
  "static_ip": "192.168.1.100",
  "static_netmask": "255.255.255.0",
  "static_gateway": "192.168.1.1",
  "static_dns_primary": "1.1.1.1",
  "static_dns_secondary": "8.8.8.8"
}
```

When `use_static_ip` is false or omitted, DHCP is used (unchanged behavior).

Validation rules:
- `static_ip` and `static_gateway` are required when `use_static_ip` is true
- `static_netmask` defaults to `255.255.255.0` if omitted
- `static_dns_*` are optional (falls back to Pi-hole for AP modes, 1.1.1.1/8.8.8.8 for server modes)
- Static IP is rejected for OFFLINE mode (no upstream interface)

---

## Static IP per Mode Matrix

| Mode | Interface | Static IP applies to | DNS fallback |
|------|-----------|---------------------|--------------|
| OFFLINE | N/A | Not applicable | N/A |
| ONLINE_ETH | eth0 | eth0 upstream | 10.42.24.1 (Pi-hole) |
| ONLINE_WIFI | wlan1 | wlan1 upstream | 10.42.24.1 (Pi-hole) |
| SERVER_ETH | eth0 | eth0 | 1.1.1.1, 8.8.8.8 |
| SERVER_WIFI | wlan0 | wlan0 | 1.1.1.1, 8.8.8.8 |

---

## Acceptance Criteria Verification

| Criteria | Status |
|----------|--------|
| DB migration 14 adds 6 new columns to network_config | PASS |
| `POST /network/mode` accepts `use_static_ip`, `static_ip`, `static_netmask`, `static_gateway`, `static_dns_primary`, `static_dns_secondary` | PASS |
| When static IP is set for ONLINE_ETH, eth0 netplan uses `addresses:` + `routes:` instead of `dhcp4: true` | PASS |
| Static IP config survives reboot (read from SQLite at boot, applied via netplan) | PASS (via T15 read + T14 write) |
| DHCP remains default when static IP fields are empty | PASS |
| Static IP rejected for OFFLINE mode | PASS (handler validation) |

---

## Netplan Examples

### ONLINE_ETH with static IP:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
      optional: true
    wlan0:
      addresses:
        - 10.42.24.1/24
      link-local: []
      optional: true
```

### ONLINE_ETH with DHCP (unchanged):
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
      dhcp-identifier: mac
      optional: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses:
          - 10.42.24.1
    wlan0:
      addresses:
        - 10.42.24.1/24
      link-local: []
      optional: true
```

---

## Git Commit Messages

```bash
# api repo
git add internal/database/schema.go internal/database/migrations.go \
        internal/models/network.go internal/managers/network.go \
        internal/handlers/network.go
git commit -m "T11-T13: static IP support — schema, models, API, netplan generation

- Migration 14: add 6 static IP columns to network_config
- StaticIPConfig struct with IsConfigured(), NetmaskToCIDR()
- SetMode() extended with StaticIPConfig parameter
- All set*Mode() functions support static IP on upstream interface
- generateNetplanYAML() produces DHCP or static variants per mode
- buildDNSBlock() helper for user/fallback DNS in netplan
- Handler validates static IP fields, rejects for OFFLINE mode
- saveConfigToDB() persists all 6 static IP columns"

# releases repo
git add firstboot/cubeos-boot-lib.sh
git commit -m "T14-T16: static IP support in boot-lib

- read_persisted_network_config() reads 6 static IP columns from SQLite
- write_netplan_for_mode() generates static IP netplan when NET_USE_STATIC_IP=1
- Each of 4 upstream modes (online_eth/wifi, server_eth/wifi) has DHCP + static variant
- apply_network_mode() logs static IP configuration
- Netmask-to-CIDR conversion for /8 through /25"
```

---

## External Actions Required Before Batch 4

1. **Push api repo** → CI auto-deploys to Pi
2. **Push releases repo** (no Packer rebuild needed yet — boot-lib changes only take effect in next image)
3. **Test on Pi via SSH:**
   ```bash
   # Set ONLINE_ETH with static IP
   curl -X POST http://localhost:6010/api/v1/network/mode \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"mode":"online_eth","use_static_ip":true,"static_ip":"192.168.1.100","static_gateway":"192.168.1.1","static_dns_primary":"1.1.1.1"}'

   # Verify DB persistence
   sqlite3 /cubeos/data/cubeos.db "SELECT mode, use_static_ip, static_ip_address, static_ip_gateway FROM network_config WHERE id=1"

   # Verify netplan was written
   cat /etc/netplan/01-cubeos.yaml
   # Should show addresses: [192.168.1.100/24] and routes: via 192.168.1.1

   # Switch back to DHCP
   curl -X POST http://localhost:6010/api/v1/network/mode \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"mode":"online_eth"}'
   
   # Verify DHCP netplan restored
   cat /etc/netplan/01-cubeos.yaml
   # Should show dhcp4: true
   ```
4. **Reboot test:** After setting static IP via API, reboot Pi and verify netplan applies correctly

---

## Next: Batch 4

**Tasks:** T17, T18, T19, T20  
**Theme:** Dashboard — Network Config Dialog  
**Key files:** `dashboard/src/components/network/NetworkConfigDialog.vue` (new), `IPConfigStep.vue` (new), `NetworkModeSelector.vue` (modified)  
**Prerequisites:** This batch (Batch 3) + API deployed with static IP support
