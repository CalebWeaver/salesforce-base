---
name: use-project-docs
description: How to use and maintain project documentation in docs/ — when to read architecture.md, modules/, and user-stories/ before working, and when to update docs after changes.
---

## Project Documentation

Project-specific context lives in `docs/` — always check these before making architectural decisions or working in an unfamiliar area.

- **`docs/project-reference.md`** — Always read at the start of every task. Contains org-specific conventions, lessons learned, and context that supplements the baseline rules.
- **`docs/architecture.md`** — Project-level architecture: org topology, data model, integrations, and key architectural decisions. Read before making cross-cutting changes.
- **`docs/modules/`** — One file per major module or domain area (e.g., `case-routing.md`, `billing.md`). Read the relevant module doc before modifying code in that area.
- **`docs/user-stories/`** — One file per user story (e.g., `US-101-case-auto-routing.md`). Read the relevant story file before starting implementation work.

**Keeping docs current**: When you make a significant change — new module, new integration, architectural decision — update the relevant doc. If a module doc doesn't exist yet for the area you're working in, create one.

## Project Resources

- **Templates**: `templates/salesforce/classes/` — base classes and utilities to copy from before creating new ones
- **References**: `references/` — cloned repo structures (see `repos.json`, run `scripts/sync-references.sh`)

Check references for established patterns before creating new structures from scratch.
