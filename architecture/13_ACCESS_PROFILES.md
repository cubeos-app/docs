# CubeOS Access Profiles — Implementation Plan

**Date:** 2026-02-27  
**Status:** Design Complete — Ready for Implementation  
**Scope:** API, Dashboard, FlowEngine, Database, Installer, Wizard  

---

## 1. Problem Statement

CubeOS was designed as an all-in-one network stack (AP + Pi-hole DNS/DHCP + NPM reverse proxy). This works perfectly for expedition/field deployments but breaks for the majority of real-world users who:

- Already have a router with DHCP
- Already run Pi-hole or AdGuard
- Already have NPM, Traefik, or Caddy
- Run CubeOS in an LXC/VM where network management is inappropriate
- Are CasaOS orphans who just want apps, not infrastructure

The result: `appstore_install` workflow fails at "Setting up access" step on any non-Pi environment because NPM can't create proxy rules for `appname.cubeos.cube` — a domain that doesn't exist without Pi-hole.

---

## 2. Solution: Access Profiles

A single user-facing setting that controls how CubeOS interacts with the network for DNS, DHCP, and reverse proxy. Orthogonal to network modes — they are independent axes.

### The Three Profiles

| Profile | Name | What it does | Target user |
|---------|------|-------------|-------------|
| A | **Standard** | Apps accessible via `host_ip:port`. CubeOS does not manage DNS, DHCP, or proxy entries. Pi-hole and NPM run but are not auto-configured per app. | CasaOS orphans, LXC/VM users, home users on existing LAN |
| B | **Advanced** | Apps accessible via `host_ip:port` + via user's existing NPM and Pi-hole. CubeOS calls external APIs to create proxy and DNS entries automatically. | Homelab power users with existing infrastructure |
| C | **All-in-One** | Full stack — CubeOS manages DNS (Pi-hole), DHCP, reverse proxy (NPM), and AP. Apps get `appname.cubeos.cube` FQDNs. | Expedition, field deploy, fresh Pi with no existing network |

### Default

**Always Standard.** No exceptions. No hardware-based auto-selection. User explicitly opts into All-in-One or Advanced.

---

## 3. Database Schema Changes

Add to `system_config` table (or new `access_profile` table):

```sql
-- New columns in system_config
access_profile          TEXT NOT NULL DEFAULT 'standard',
  -- values: standard | advanced | all_in_one

-- Advanced profile credentials
ext_npm_url             TEXT,
ext_npm_token           TEXT,
ext_pihole_url          TEXT,
ext_pihole_password     TEXT,

-- All-in-One profile state
aio_dhcp_enabled        INTEGER NOT NULL DEFAULT 0,
aio_dns_enabled         INTEGER NOT NULL DEFAULT 0,
aio_proxy_enabled       INTEGER NOT NULL DEFAULT 0,
```

Schema version bump required.

---

## 4. API Changes

### New endpoints

```
GET  /api/v1/access-profile
     Returns current profile + config

POST /api/v1/access-profile
     Body: { profile, ext_npm_url, ext_npm_token, ext_pihole_url, ext_pihole_password }
     Triggers access_profile_switch FlowEngine workflow

POST /api/v1/access-profile/test-external
     Body: { ext_npm_url, ext_npm_token, ext_pihole_url, ext_pihole_password }
     Tests external API connectivity before saving
     Returns: { npm_ok, pihole_ok, npm_version, pihole_version }
```

### Modified behavior

`GET /api/v1/system/config` — include `access_profile` in response  
`POST /api/v1/setup/complete` — save chosen profile from wizard  

---

## 5. FlowEngine Workflow Changes

### 5a. appstore_install — "Setting up access" step

Current behavior (always):
```
create_npm_proxy_rule(app.fqdn → container)
create_pihole_dns_entry(app.fqdn → 10.42.24.1)
```

New behavior (profile-aware):
```
switch access_profile:

  case "standard":
    → skip both steps entirely
    → app_url = "http://{host_ip}:{port}"

  case "advanced":
    → call external NPM API to create proxy rule
    → call external Pi-hole API to create DNS entry
    → app_url = "http://{app.fqdn}" via external proxy
    → compensate: delete external entries on failure

  case "all_in_one":
    → current behavior (local NPM + local Pi-hole)
    → app_url = "http://{app.fqdn}.cubeos.cube"
    → compensate: delete local entries on failure
```

### 5b. appstore_remove — "Removing access" step

Same switch logic — remove entries from the right system.

### 5c. New workflow: access_profile_switch

```
Workflow: access_profile_switch
Input: { from_profile, to_profile, credentials? }

Steps:
  1. validate_transition
     - If to Advanced: test external API credentials (fail fast)
     - If to All-in-One: verify Pi-hole + NPM running locally
     - Compensate: nothing (read-only validation)

  2. pause_app_access
     - Mark all installed apps as "access_updating" in DB
     - Compensate: restore previous status

  3. teardown_old_access
     - Remove all existing proxy rules + DNS entries from OLD system
     - (standard: nothing to remove)
     - Compensate: recreate them in old system

  4. update_profile_db
     - Write new profile + credentials to system_config
     - Compensate: restore old profile

  5. configure_new_services
     - Standard: disable Pi-hole DHCP (if was All-in-One)
     - Advanced: save + activate external credentials
     - All-in-One: enable Pi-hole DHCP, verify NPM ready
     - Compensate: reverse service changes

  6. migrate_app_entries  (bulk step — most important)
     - For each installed app:
       → create proxy rule in NEW system
       → create DNS entry in NEW system
       → update app.access_url in DB
     - Compensate: remove all newly created entries

  7. verify_access
     - Spot-check 3 random apps are reachable
     - Compensate: nothing (informational)

  8. restore_app_status
     - Mark all apps back to "running"
     - Update access_urls in DB
```

Progress visible in dashboard — same modal as app install, showing per-app progress on step 6.

---

## 6. Wizard Changes

### Step restructure

Current wizard (Pi-centric):
1. Welcome + hardware detection
2. Admin password
3. Network mode
4. WiFi AP config  ← shown always, even without WiFi
5. Timezone
6. Finish

New wizard (platform-aware):
1. Welcome + hardware detection
2. Admin password
3. **Access Profile** ← NEW, always shown
4. Network mode  ← only shown if All-in-One selected
5. WiFi AP config ← only shown if All-in-One + WiFi detected
6. Timezone
7. Finish

### Step 3: Access Profile UI

```
┌─────────────────────────────────────────────────────────────────┐
│  How should CubeOS work on your network?                        │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  ● Standard      │  │  ○ Advanced      │  │ ○ All-in-One │  │
│  │                  │  │                  │  │              │  │
│  │  Apps via        │  │  Use your own    │  │  CubeOS runs │  │
│  │  IP:port         │  │  NPM + Pi-hole   │  │  everything  │  │
│  │                  │  │                  │  │              │  │
│  │  Works           │  │  API             │  │  AP + DNS    │  │
│  │  everywhere      │  │  integration     │  │  + DHCP      │  │
│  │                  │  │                  │  │              │  │
│  │  Recommended ✓   │  │                  │  │              │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                 │
│  [Advanced credentials expand inline when selected]            │
│  [All-in-One shows network mode + AP steps after this]         │
└─────────────────────────────────────────────────────────────────┘
```

When **Advanced** selected, expand inline:
```
  NPM URL:      [https://npm.yourdomain.com    ]
  NPM Token:    [●●●●●●●●●●●●●●●●●●●●●●●●●●●● ]
  Pi-hole URL:  [http://192.168.1.2            ]
  Pi-hole Pass: [●●●●●●●●●●●●●●●●●●●●●●●●●●●● ]
  [ Test Connection ]  ✓ NPM reachable  ✓ Pi-hole reachable
```

### Conditional steps

```
if profile == "standard" or "advanced":
    skip network_mode step
    skip wifi_ap step
    wizard = 5 steps total

if profile == "all_in_one":
    show network_mode step
    if wifi_detected: show wifi_ap step
    wizard = 6-7 steps total
```

---

## 7. Dashboard Settings Changes

### Settings → Network → Access Profile

Same three cards as wizard. Current profile highlighted. "Change" button triggers profile switch modal.

Switch modal shows:
1. Profile selection (pre-selected to current)
2. If Advanced: credential fields + Test Connection
3. If All-in-One: warning about DHCP takeover
4. Confirm → triggers `access_profile_switch` workflow
5. Progress modal (same component as app install) showing per-app migration

### App cards

Each installed app shows its access URL:
- Standard: `http://192.168.181.191:6100`
- Advanced: `https://appname.yourdomain.com`
- All-in-One: `http://appname.cubeos.cube`

---

## 8. Installer Changes (curl/install.sh)

Add to generated `defaults.env`:
```bash
CUBEOS_ACCESS_PROFILE=standard
```

Always `standard` on x86/container installs — no prompting needed.

The wizard handles the actual selection on first boot.

---

## 9. HAL Changes

HAL needs two new capability checks used during wizard + profile switch:

```
GET /api/v1/hal/capabilities/dhcp
    Returns whether Pi-hole DHCP can be safely enabled
    (checks for existing DHCP servers on network)

GET /api/v1/hal/capabilities/proxy
    Returns whether local NPM is reachable and healthy
```

Used by `validate_transition` step in `access_profile_switch` workflow.

---

## 10. Implementation Phases

### Phase 1 — Unblock x86 (1 session, ~2 hours)

**Goal:** Stop the circuit breaker crash on non-Pi installs.

Changes:
- Add `access_profile=standard` to DB schema + defaults.env
- FlowEngine `appstore_install`: skip NPM + DNS steps when `access_profile=standard`
- FlowEngine `appstore_remove`: skip NPM + DNS steps when `access_profile=standard`
- Wizard: skip AP step when no WiFi detected OR `CUBEOS_TIER=container`

Result: x86 app install works end-to-end. Apps accessible via IP:port.

### Phase 2 — Full Profile System (2-3 sessions)

**Goal:** Complete profile selection in wizard + settings.

Changes:
- Full wizard Access Profile step (Standard/Advanced/All-in-One)
- Settings → Network → Access Profile card
- `access_profile_switch` FlowEngine workflow
- All-in-One profile = current behavior preserved
- Advanced profile credentials storage + test endpoint

### Phase 3 — External Integration (2-3 sessions)

**Goal:** Advanced profile actually works with real external NPM + Pi-hole.

Changes:
- External NPM API client (NPM uses JWT auth)
- External Pi-hole v6 API client
- Migration step in `access_profile_switch` for installed apps
- Per-app `access_url` stored in DB + shown in dashboard

---

## 11. Affected Repositories

| Repo | Changes | Phase |
|------|---------|-------|
| `api` | New endpoints, profile-aware FlowEngine steps, new workflow | 1, 2, 3 |
| `dashboard` | Wizard step, Settings card, progress modal reuse | 1, 2 |
| `hal` | Two new capability endpoints | 2 |
| `releases` | defaults.env + install.sh | 1 |
| `docs` | Access profiles user guide | 2 |

---

## 12. Key Principles

1. **Standard is always the default** — no exceptions, no hardware-based auto-selection
2. **All-in-One is opt-in** — user must consciously choose it
3. **Profile switches never break running apps** — always accessible via IP:port regardless of profile
4. **Pi-hole and NPM always installed** — profile only controls whether they're auto-configured per app
5. **FlowEngine handles all transitions** — atomic, compensatable, observable
6. **External credentials stored encrypted** — never logged, masked in API responses

---

*Document Version: 1.0*  
*Authors: CubeOS Development Team*  
*Next: Implement Phase 1 to unblock x86 installs*
