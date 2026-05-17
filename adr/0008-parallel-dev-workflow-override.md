# 8. Parallel-dev workflow override for CubeOS family

Date: 2026-05-17

## Status

Accepted

## Context

CubeOS's default per-component repo workflow per Article XV is "push directly to main; CI auto-deploys." This works for human-driven feature development at a one-MR-at-a-time pace.

Adopting Spec-Driven Development (Path A / IFRNLLEI01PRD-929) + the `claude-gateway` parallel-dev infrastructure (epic IFRNLLEI01PRD-922) introduces a different shape:

- Multiple workers (Claude Code sessions) operate in parallel on different `spec/<feature>/tasks.json` items.
- Each worker needs an isolated git worktree to avoid stepping on others.
- Worker output must NOT auto-deploy to Pi devices the moment it lands — at parallel-dev scale, the validation gate becomes the bottleneck, not the deploy.

A "push directly to main, CI auto-deploys" rule applied to parallel-dev workers would either (a) deploy partially-validated work in seconds, or (b) require disabling CI auto-deploy entirely. Neither is acceptable.

## Decision

**Parallel-dev waves get a workflow override** scoped to those waves only:

1. The planner allocates each `tasks.json` task to a short-lived branch named `merge/<feature_id>`.
2. The worker commits + pushes to `merge/<feature_id>`.
3. The merge-coordinator opens ONE merge request per feature against `main` once all tasks in the feature pass acceptance.
4. CI runs the full test suite against the MR.
5. Operator approves the MR → squash-merge → CI auto-deploys (regular Article XV path resumes from that point).
6. The `merge/<feature_id>` branch is auto-deleted on merge.

Human work outside parallel-dev waves continues unchanged: push to main, CI auto-deploys.

## Consequences

**Positive:**
- Parallel-dev workers can't accidentally deploy unvalidated code.
- Operator retains MR-gate approval for parallel-dev output.
- Branch namespace stays clean (auto-delete on merge).
- The override is scoped — human contributors don't have to learn a new workflow for normal work.

**Negative:**
- Two workflows now coexist per repo. Confusion risk: a contributor might think they MUST open an MR for everything.
- Mitigated by: clear documentation in `steering/release-pipeline.md` + this ADR.

**Enforced by:** `claude-gateway/docs/runbooks/parallel-dev-feature.md` + `validate-project-spec.py` Phase F gate (rejects `files_owned` overlap within a wave). The override is operationalised in `gateway-state/bin/merge-coordinator.sh`.

**Mirrors:** meshsat / meshsat-hub / meshsat-android ADR-0003 (each repo's local parallel-dev override). This is the CubeOS-family-wide version.
