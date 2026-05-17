# 1. Record architecture decisions

Date: 2026-05-17

## Status

Accepted

## Context

We need to record the architectural decisions made on this project.

The legacy `decisions/adr-ota-updates.md` (March 2026) was a one-off ADR not embedded in any methodology. We are now adopting Spec-Driven Development (Path A / IFRNLLEI01PRD-929) across the CubeOS family, which expects `adr/` as a peer to `spec/`, `steering/`, `constitution.md`. This new `adr/` directory subsumes `decisions/` going forward; the original file is preserved in `decisions/` and explicitly extended by `adr/0007-ota-strategy.md`.

## Decision

We will use Markdown Architecture Decision Records as described by Michael Nygard ([https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)).

Numbering: `adr/NNNN-<kebab-slug>.md` starting at `0001`. Order is creation order. ADRs are immutable once Accepted; superseded ADRs link to their replacement.

## Consequences

- Architecture decisions become discoverable + greppable.
- New decisions go through a small lightweight write-up rather than being lost to commit messages or operator memory.
- The legacy `decisions/adr-ota-updates.md` stays in place for git-history continuity, with the new `adr/0007-ota-strategy.md` consolidating its content + adding the 2026-05 decisions.
