# Design — Access profiles (spec/004 — retrospective)

Phase 1-3 shipped per roadmap §2. This spec captures the design as-built for future contributors.

## Three-profile model

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   standard   │     │   advanced   │     │  all_in_one  │
│              │     │              │     │              │
│ • app store  │ ──► │ + Swarm GUI  │ ──► │ + DHCP       │
│ • dashboard  │     │ + FlowEngine │     │ + AP-managed │
│ • basic net  │     │ + compose ed │     │   interface  │
└──────────────┘     └──────────────┘     └──────────────┘
   DEFAULT             ENGINEER             FIELD/AIO
   (consumer)          (homelab admin)      (off-grid kit)
```

Profiles are ordered (`standard < advanced < all_in_one`) for additive capability. Switching DOWN stops the additional coreapps + UIs; switching UP starts them.

## FlowEngine workflow

The `access_profile_switch` saga (per roadmap §2 "FlowEngine: 7 workflows (6 original + access_profile_switch)"):

```
saga steps:
  1. validate target profile is in {standard, advanced, all_in_one}
  2. compute diff: which coreapps to stop, which to start
  3. stop diff.to_stop coreapps (in reverse boot-order)
  4. update firewall rules (HAL POST /network/firewall)
  5. update Pi-hole DHCP state (HAL POST /pihole/dhcp/enabled iff target=all_in_one)
  6. start diff.to_start coreapps (in boot-order)
  7. persist new profile to access_profiles table
  8. write audit event
  9. invalidate dashboard-cached profile state (websocket push)
compensating actions (run on any step failure, in reverse):
  9'. (no-op — websocket cache rebuilds on next poll)
  8'. (n/a — no audit yet)
  7'. restore previous access_profiles row
  6'. stop coreapps we started in step 6
  5'. revert Pi-hole DHCP state
  4'. revert firewall rules
  3'. start coreapps we stopped in step 3
```

## Schema v21 + v23 deltas

```sql
-- v21: add access_profiles table
CREATE TABLE IF NOT EXISTS access_profiles (
  device_id TEXT PRIMARY KEY,
  profile TEXT NOT NULL CHECK (profile IN ('standard','advanced','all_in_one')),
  set_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  set_by TEXT
);

-- v23: extend network_modes with managed-interface field
ALTER TABLE network_modes ADD COLUMN dhcp_managed_interface TEXT DEFAULT NULL;
```

Append-only per Article XIII. Pre-v21 devices auto-create the table on upgrade with seed row `(device_id, 'standard', NOW(), 'system')`.

## Operator UX

- **Profile switcher** lives in Settings → Profile.
- Switching prompts a confirmation dialog summarising what's changing (coreapps to stop/start, DHCP transition).
- Switch-history surfaced under Settings → Profile → History.

## Out of scope (deferred)

- Custom operator-defined profiles (`PRF-05` — declined for v1.0 to keep the matrix small).
- Per-coreapp profile overrides (e.g. "enable ollama in standard profile" — would defeat the simplification value).
- Time-based profile schedules (e.g. "switch to advanced 9-5 weekdays") — operator can script via cubeos-cli if needed.
