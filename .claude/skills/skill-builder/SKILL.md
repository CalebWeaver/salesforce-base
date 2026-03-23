---
name: skill-builder
description: How to create and structure Claude Code skills in this project — SKILL.md format, frontmatter fields, progressive disclosure with reference files, and what belongs where.
---

## Skill Structure

Every skill is a folder containing a `SKILL.md` plus optional subdirectories for reference material:

```
my-skill/
├── SKILL.md          ← Core instructions (concise — under ~500 lines)
├── references/       ← Detailed docs loaded only when needed
│   └── patterns.md
├── scripts/          ← Executable shell/Python scripts
└── assets/           ← Templates and static files
```

**Progressive disclosure**: At startup, Claude only sees each skill's `name` and `description`. `SKILL.md` is read when the skill is invoked. Files in `references/`, `scripts/`, and `assets/` are read only when Claude explicitly needs them — zero context cost otherwise. This means detailed content belongs in separate files, not embedded in `SKILL.md`.

## SKILL.md Frontmatter

```yaml
---
name: skill-name                    # kebab-case, matches folder name
description: One sentence describing what this skill does and when Claude should use it.
user-invocable: false               # Optional. false = only Claude can invoke (background knowledge)
disable-model-invocation: true      # Optional. true = only the user can invoke (side-effect workflows)
---
```

- `name` and `description` are always loaded — make `description` specific and actionable
- Omit optional fields unless needed; most skills only need `name` and `description`
- Use `disable-model-invocation: true` for skills with side effects (deploy, commit, send messages)
- Use `user-invocable: false` for background reference skills Claude uses autonomously

## What Goes Where

| Content | Location |
|---------|----------|
| Decision flows, rules, when-to-use tables | `SKILL.md` |
| Short code snippets (< 20 lines, core pattern) | `SKILL.md` |
| Long code examples, comprehensive patterns | `references/` file |
| Bash/Python scripts the skill runs | `scripts/` file |
| Templates copied into the project | `assets/` file |

Keep `SKILL.md` under ~500 lines. If it's getting long, move code examples to `references/`. Split `references/` into multiple files when patterns are independent — Claude loads each file separately, so finer granularity means less unused context per invocation.

## Where Skills Live in This Repo

```
profiles/base/skills/{name}/     ← Shared across composed profiles
profiles/{profile}/skills/{name}/
.claude/skills/{name}/           ← For this baseline repo itself
```

## Adding a Skill

1. Create the folder: `profiles/{base|profile}/skills/{skill-name}/`
2. Write `SKILL.md` — frontmatter + concise instructions + core patterns
3. If you have long code examples, put them in `references/patterns.md` and point to them from `SKILL.md`:
   ```
   For full implementation examples, read `references/patterns.md` in this skill.
   ```
4. Update the relevant rules file with `Invoke /skill-name for X.`
5. Update agent `.md` files if the skill should be preloaded for a specific agent role

## Skill Invocation in Rules Files

Point agents to skills from rules files — don't embed the detail in always-loaded rules:

```markdown
✅ Invoke `/build-async` for detailed patterns and examples.
❌ See references/patterns/base/async-patterns.md for examples.  ← Old pattern, avoid
```

## Writing Good Descriptions

The description is what Claude matches against user intent. Be specific:

```yaml
# Too vague
description: Async processing patterns.

# Good — Claude knows exactly when to use this
description: How to implement async processing — when to use job queues vs background workers vs scheduled tasks, and the rules for each.
```

## Skills vs Agents

- **Skill**: A focused body of knowledge or capability invoked on demand
- **Agent**: A role that preloads a set of skills and operates with a defined scope

Agent files live in `profiles/{profile}/agents/{name}.md` or `.claude/agents/{name}.md`. The `skills` frontmatter field lists skill names to inject at startup. Keep agent body content minimal — skills carry the detail.
