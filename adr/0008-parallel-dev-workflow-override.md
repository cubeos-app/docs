# 8. Parallel-dev workflow override for CubeOS family

Date: 2026-05-18

## Status

Accepted

## Context

CubeOS's default per-component repo workflow per Article XV is "push directly to main; CI auto-deploys." Parallel-dev waves need different semantics: multiple workers operate in parallel; output must NOT auto-deploy the moment it lands.

## Decision

**Parallel-dev waves get a workflow override** scoped to those waves only:

1. Planner allocates each `tasks.json` task to `merge/<feature_id>` short-lived branch.
2. Worker commits + pushes to `merge/<feature_id>`.
3. Merge-coordinator opens ONE MR per feature against `main` once all tasks pass acceptance.
4. CI runs full test suite against the MR.
5. Operator approves → squash-merge → CI auto-deploys (Article XV resumes).
6. `merge/<feature_id>` branch auto-deleted on merge.

Human work outside parallel-dev waves unchanged.

## Consequences

**Positive:** Parallel-dev workers can't accidentally deploy unvalidated code. Operator retains MR-gate approval. Branch namespace clean.

**Negative:** Two workflows coexist per repo. Mitigated by clear documentation.

**Enforced by:** `claude-gateway/docs/runbooks/parallel-dev-feature.md` + `validate-project-spec.py` Phase F gate + `gateway-state/bin/merge-coordinator.sh`.

Mirrored in every component repo's ADR for symmetry.
