---
name: skill-builder
description: How to create and structure Claude Code skills — SKILL.md format, frontmatter fields, progressive disclosure with reference files, and what belongs where.
---

## Naming
Prefer gerund names or noun phrases

## Description
Especially consise. Fewer than 1000 characters. Include key terms.

## The Filter

Before adding anything to a skill, ask: **Would Claude get this right without being told?** If yes, omit it.

## What Belongs in a Skill

- Project-specific field names, paths, or syntax Claude can't infer
- Known failure modes: things Claude consistently gets wrong in this domain
- Non-obvious constraints or counterintuitive decisions
- Edge cases that contradict Claude's defaults

## Workflow Guidance

- Match instruction specificity to task fragility: give exact steps when consistency is critical and errors are hard to recover from, give general direction when multiple approaches are valid.
- Use workflows for complex tasks. For highly complex tasks, use a markdown reference file.
- For complex tasks: Break into numbered steps and give Claude a copy-paste checklist it tracks as it works — this prevents skipping steps and makes progress visible.
- For quality-critical tasks: Build in a validate → fix → repeat loop. The "validator" can be a script or a reference doc Claude checks against. Only proceed when it passes.

## Skill Structure

```
my-skill/
├── SKILL.md          ← Loaded when skill is invoked
├── references/       ← Loaded only when Claude explicitly reads them
├── scripts/
└── assets/
```

**Progressive disclosure**: Claude only sees `name` and `description` at startup. `SKILL.md` loads on invocation. Files in `references/`, `scripts/`, `assets/` load only when Claude reads them — zero context cost otherwise.
- Keep all reference file links directly in SKILL.md — never chain references file-to-file, as Claude may only partially read chained files.
- When a reference file is more than 100 lines, use a table of contents at the top.

## Frontmatter Fields

```yaml
---
name: skill-name                    # kebab-case, matches folder name
description: One sentence — specific and actionable; this is what Claude matches against user intent
user-invocable: false               # false = only Claude invokes (background knowledge); omit if user-invocable
disable-model-invocation: true      # true = only user can invoke (side-effect workflows like deploy, commit)
---
```

Omit optional fields unless needed. Most skills only need `name` and `description`.

## Where Skills Live

```
profiles/base/skills/{name}/       ← Shared across all profiles
profiles/{profile}/skills/{name}/  ← Profile-specific
.claude/skills/{name}/             ← This baseline repo itself
```

## Wiring a Skill

1. Create folder and write `SKILL.md`
2. Add invocation hint to the relevant rules file:
   ```
   Invoke /skill-name for X.
   ```
3. Add to agent `skills:` frontmatter if it should preload for a specific agent role

Use `Invoke /skill-name` syntax — not file paths.

## References
[Extend Claude with Skills](https://code.claude.com/docs/en/skills)
[Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
