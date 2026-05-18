# Requirements — Access profiles (spec/004 — RETROSPECTIVE)

Source: `architecture/13_ACCESS_PROFILES.md` + roadmap §2 ("Access Profiles Phase 1-3 complete, schema v21→v23"). CGC-verified shipped paths against api/ + dashboard/ 2026-05-18.

> Retrospective. ID convention: 400-block.

REQ-400: The system shall provide exactly three access profiles: `standard`, `advanced`, `all_in_one`.
REQ-401: The system shall set `standard` as the default profile on first-boot wizard completion.
REQ-402: While the operator is in `standard` profile, the system shall expose only consumer-grade features.
REQ-403: While the operator is in `advanced` profile, the system shall additionally expose engineer-grade surfaces (Swarm GUI, FlowEngine inspector, compose editor).
REQ-404: While the operator is in `all_in_one` profile, the system shall additionally enable managed-interface DHCP (per Article VI).
REQ-405: The system shall expose `POST /api/v1/access-profile/switch` taking `{profile: "<name>"}`.
REQ-406: When the operator switches profile, the system shall trigger the `access_profile_switch` FlowEngine workflow at `api/internal/flowengine/workflows/access_profile_switch.go`.
REQ-407: When the workflow runs, the system shall compose activities from `api/internal/flowengine/activities/access_profile.go` to: stop coreapps disabled by the new profile, start coreapps enabled by the new profile, and update firewall rules.
REQ-408: If the workflow fails at any step, then the system shall run compensating actions to restore the prior profile state.
REQ-409: The system shall persist the active profile in the SQLite `access_profiles` table (schema v21+).
REQ-410: When the system boots, the system shall read the persisted profile before deciding which coreapps to start.
REQ-411: The system shall hide UI surfaces disabled by the current profile from the dashboard navigation menu (component `dashboard/src/components/settings/AccessProfileSettings.vue` controls visibility).
REQ-412: While the operator is in `standard` profile, the system shall hide the Swarm GUI components (`dashboard/src/components/swarm/SwarmOverview.vue` + `StackList.vue`).
REQ-413: When the operator opens the profile-switcher (`dashboard/src/components/settings/ProfilesTab.vue`), the system shall display a clear summary of what each profile enables.
REQ-414: The system shall NOT enable Pi-hole DHCP under any profile other than `all_in_one`.
REQ-415: If the operator attempts to enable DHCP via API while profile != `all_in_one`, then the system shall reject the request with HTTP 409.
REQ-416: When the operator switches AWAY from `all_in_one`, the system shall stop Pi-hole DHCP cleanly without disrupting active leases (Pi-hole continues serving existing leases until renewal timeout).
REQ-417: The system shall NOT allow operator-defined custom profiles in v1.0 (`PRF-05` deferred).
REQ-418: When the API receives `POST /api/v1/access-profile/switch` with a profile name outside the canonical set, the system shall reject with HTTP 400.
REQ-419: The system shall write a structured audit event to `/cubeos/data/audit.log` on every profile switch including: from-profile, to-profile, operator, timestamp.
REQ-420: The system shall expose `GET /api/v1/access-profile/history` returning the last 100 profile changes.
REQ-421: When the system upgrades from schema v20 to v21, the system shall create the `access_profiles` table and seed the existing device's profile as `standard`.
REQ-422: When the system upgrades from schema v22 to v23, the system shall add the `dhcp_managed_interface` column to `network_modes`.
REQ-423: The system shall NOT allow downgrading a profile-aware device back to a pre-v21 schema (Article XIII append-only).
REQ-424: While the workflow runs, the system shall surface per-step progress to the dashboard via `dashboard/src/components/settings/ProfileSwitchProgressModal.vue` (CGC-verified shipped).
