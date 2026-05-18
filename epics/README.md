# Epic registry — CubeOS family

YAML files in this directory list cross-spec epics. Each epic spans 2+ specs
across the cubeos-family repos (api, hal, docs, meshsat, meshsat-android,
meshsat-hub) and declares the dispatch dependencies between them.

Consumed by:
- `scripts/sdd-epic-readiness.py` — walks every epic, computes ready / blocked specs
- `validate-project-spec.py` C30 (`epic_dag_no_orphans_no_cycles`)

Format (per file):

```yaml
id: <kebab-case slug>
title: <human-readable>
youtrack_epic: IFR<prefix>-NNNN
description: <one paragraph>
specs:
  - repo: <slug>            # one of api|hal|docs|meshsat|meshsat-android|meshsat-hub
    spec_slug: <NNN-name>   # the spec/ subdirectory
    blocked_by: []          # list of {repo, spec_slug} that must reach status=completed first
                            # empty = ready as soon as the epic starts
status: pending | in-progress | completed
```

The validator (C30) checks:
- Every (repo, spec_slug) referenced exists on disk
- The graph (specs as nodes, blocked_by edges) has NO cycles
- Every spec in an epic exists in the repo's tasks.json
- `status: completed` epics have all their specs status=completed in their respective tasks.json files
