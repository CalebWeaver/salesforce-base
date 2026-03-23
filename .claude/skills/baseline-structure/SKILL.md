---
name: baseline-structure
description: Layout, profile system, manifests, skills/agents organization, and gotchas for the aimpoint-base-claude baseline repo itself.
---

## What This Repo Does

`scripts/init-project.sh` creates new Salesforce SFDX projects by:
1. Assembling `.claude/CLAUDE.md` from `profiles/{profile}/claude.md` (preamble) + rules files (standards body)
2. Copying skills from `profiles/base/skills/` + `profiles/{profile}/skills/` → `.claude/skills/`
3. Copying agents from `profiles/{profile}/agents/` → `.claude/agents/`
4. Copying Apex templates per the profile manifest
5. Scaffolding `docs/` from `templates/docs/`
6. Filtering `references/repos.json` to profile-relevant repos

## Project Structure

```
profiles/           Profile manifests, CLAUDE.md templates, skills, agents
  base/             Shared content composed into lightweight + enterprise
    skills/         Skills copied into all composed-profile projects
    agents/         Agent definitions for all composed-profile projects (overridden by profile)
  enterprise/       FFLib-specific skills and agents
    skills/         fflib-architecture, fflib-testing, nebula-logger
    agents/         developer, reviewer, experience-cloud-developer
    claude.md       Thin CLAUDE.md template for generated projects
  lightweight/      Trigger-handler-specific skills and agents
  poc/              Standalone POC profile (not composed from base)
templates/          Apex classes and docs copied into target projects
  docs/             project-reference.md, architecture.md, modules/, user-stories/
  salesforce/classes/
    enterprise/     Enterprise-only templates (Application.cls, etc.)
    testsupport/    Test data framework (builders, fixtures, TestDataGraph)
references/         Reference repos config
  repos.json        External repo definitions (NebulaLogger, FFLib, etc.)
scripts/            init-project.sh, sync-references.sh
```

## Profile System

Three profiles: `poc`, `lightweight`, `enterprise`.

**Composed profiles** (lightweight, enterprise): CLAUDE.md is assembled from `claude.md` preamble + `rules-base.md` + `rules-overlay.md`. Base skills + profile skills are both copied.

**Standalone profile** (poc): Only `profiles/poc/skills/` is copied — no base. Manifest has `"standalone": true`.

## Manifests

Each profile has `manifest.json`. Key fields:
- `templates.copy` — Apex class files/dirs to copy
- `references.required/optional` — which repos from repos.json to include
- `claude.template` — path to thin CLAUDE.md template
- `skills.base` — base skills dir (composed profiles only)
- `skills.profile` — profile-specific skills dir
- `agents.profile` — profile-specific agents dir
- `"standalone": true` — present only on poc

## Skills and Agents by Profile

**Base skills** (enterprise + lightweight): `write-apex`, `write-tests`, `deploy`, `configure-values`, `build-async`, `build-lwc`, `build-for-experience-cloud`

**Enterprise skills**: `fflib-architecture`, `fflib-testing`, `nebula-logger`

**Lightweight skills**: `trigger-handler`

**POC skills**: `poc-approach`, `poc-promotion`

**Enterprise agents**: `developer` (all enterprise skills), `reviewer` (read-only), `experience-cloud-developer`

**Lightweight agents**: `developer`, `reviewer` (read-only), `experience-cloud-developer`

**POC agents**: `developer` (poc-approach), `promoter` (poc-promotion)

## Pattern Files Live in Skills

Implementation patterns (Apex code examples, detailed how-tos) live directly in skill SKILL.md files. Rules files point to skills with `Invoke /skill-name` rather than to separate reference files.

Adding a pattern:
1. Add it to the relevant skill's SKILL.md
2. Add a pointer in the rules file: `Invoke /skill-name for examples.`
3. Base-level patterns go in `profiles/base/skills/`

## Gotchas

- `references/.gitignore` ignores `*/` with explicit exceptions for tracked files (README.md, repos.json). Add negation rules for any new tracked subdirectories.
- The init script is copied into target projects so teams can re-run it.
- The `.claude/CLAUDE.md` at the repo root is for *this* baseline project, not a template. Templates live under `profiles/*/claude.md`.
