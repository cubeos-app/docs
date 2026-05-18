# 1. Record architecture decisions

Date: 2026-05-18

## Status

Accepted

## Context

We need to record the architectural decisions made on this project. The legacy `decisions/adr-ota-updates.md` (March 2026) was a one-off ADR. We are now adopting Spec-Driven Development across the CubeOS family. This `adr/` directory subsumes `decisions/` going forward; the original file is preserved and explicitly extended by `adr/0007-ota-strategy.md`.

## Decision

Use Markdown ADRs per Nygard. `adr/NNNN-<kebab>.md` from `0001`.

## Consequences

- Architecture decisions become discoverable + greppable.
- The legacy `decisions/adr-ota-updates.md` stays in place for git-history continuity, with `adr/0007-ota-strategy.md` consolidating + extending it.
