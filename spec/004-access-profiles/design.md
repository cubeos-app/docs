# Design — Access profiles (spec/004 — RETROSPECTIVE)

Phase 1-3 shipped. All file paths CGC-verified 2026-05-18.

## Three-profile model

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   standard   │     │   advanced   │     │  all_in_one  │
│ (consumer)   │ ──► │ (homelab)    │ ──► │ (field/AIO)  │
│              │     │              │     │              │
│ • app store  │     │ + Swarm GUI  │     │ + DHCP       │
│ • dashboard  │     │ + FE inspector│     │ + AP managed │
│ • basic net  │     │ + compose ed │     │   interface  │
└──────────────┘     └──────────────┘     └──────────────┘
```

Profiles are ordered for additive capability.

## CGC-verified component map

| Function | Real path |
|---|---|
| FlowEngine workflow | `api/internal/flowengine/workflows/access_profile_switch.go` |
| Per-step activity | `api/internal/flowengine/activities/access_profile.go` |
| REST handler | `api/internal/handlers/profiles.go` |
| Test helpers (shipped) | `api/internal/handlers/access_profile_test_helpers.go` |
| Profile settings UI | `dashboard/src/components/settings/AccessProfileSettings.vue` |
| Profile-switch progress modal | `dashboard/src/components/settings/ProfileSwitchProgressModal.vue` |
| Profile-tab UI | `dashboard/src/components/settings/ProfilesTab.vue` |
| Profile-aware Swarm GUI gating | `dashboard/src/components/swarm/SwarmOverview.vue` + `StackList.vue` (hidden in `standard`) |
| Profile-aware Apps store gating | `dashboard/src/components/services/` (verify hide-condition wiring) |
| Schema migrations | `api/internal/database/migrations.go` v20→v21 + v22→v23 |

## FlowEngine workflow

The `access_profile_switch` saga (CGC-verified). Steps (composed from `activities/access_profile.go`):

1. validate target profile is in {standard, advanced, all_in_one}
2. compute diff: which coreapps to stop, which to start
3. stop diff.to_stop coreapps (reverse boot-order)
4. update firewall rules via HAL `POST /firewall/...` (hal/internal/handlers/firewall.go)
5. update Pi-hole DHCP state if target=all_in_one AND managed_interface designated
6. start diff.to_start coreapps (boot-order)
7. persist new profile to access_profiles table
8. write audit event

Compensation: reverse-from-failed-step per FlowEngine convention.

## Schema deltas

```sql
-- v21
CREATE TABLE IF NOT EXISTS access_profiles (
  device_id TEXT PRIMARY KEY,
  profile TEXT NOT NULL CHECK (profile IN ('standard','advanced','all_in_one')),
  set_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  set_by TEXT
);

-- v23
ALTER TABLE network_modes ADD COLUMN dhcp_managed_interface TEXT DEFAULT NULL;
```

Append-only per Article XIII. Current schema is v27, so 4 additional migrations have shipped since these.

## Operator UX

- Profile switcher: Settings → Profile (`AccessProfileSettings.vue`).
- Confirmation dialog summarises what changes.
- Switch progress in `ProfileSwitchProgressModal.vue`.
- Switch history via `GET /api/v1/access-profile/history`.

## Out of scope (deferred per roadmap)

- Operator-defined custom profiles (`PRF-05`).
- Per-coreapp profile overrides.
- Time-based profile schedules.
