---
name: agent-creator
description: How to design and create Claude Code subagents in this baseline repo — file structure, frontmatter fields, placement, manifest wiring, and prompt-writing best practices.
---

## When to Create an Agent

Create a subagent when a role has a **recurring, scoped task** with predictable tool needs. Use the main conversation when work requires constant back-and-forth or shared context across phases.

| Signal | Use |
|--------|-----|
| Repeated role invocations (reviewer, deployer, tester) | Agent |
| Task produces verbose output (test runs, log analysis) | Agent |
| You want to enforce tool restrictions per role | Agent |
| Work spans multiple dependent phases sharing context | Main conversation |
| Quick one-off task already in context | Main conversation |

## Where Agents Live in This Repo

```
profiles/base/          ← No agents here (base is composed, not standalone)
profiles/lightweight/agents/{name}.md
profiles/enterprise/agents/{name}.md
profiles/poc/agents/{name}.md
.claude/agents/         ← For this baseline repo itself
```

Agents in `profiles/{profile}/agents/` are copied into target projects by the init script. Each profile's `manifest.json` declares the agents directory:

```json
"agents": {
  "profile": "profiles/enterprise/agents"
}
```

The init script copies the entire agents directory to `.claude/agents/` in the target project.

## Agent File Structure

```
profiles/{profile}/agents/
├── developer.md         ← Implementation role
├── reviewer.md          ← Read-only review role
└── test-developer.md    ← Test writing role
```

Every agent is a single `.md` file — no subdirectories needed. Agent content is minimal; complexity lives in skills.

## Anatomy of an Agent File

```markdown
---
name: agent-name
description: What this agent does and when to use it. Be specific — this is how Claude decides to delegate.
tools: Read, Write, Edit, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet
skills:
  - skill-name-one
  - skill-name-two
---

One or two sentences defining the agent's role and highest-priority instruction.
Read `docs/project-reference.md` before starting work.
```

**This repo's convention**: Keep the body to 1-3 sentences. Skills carry all the implementation detail. The body is the role definition, not the how-to.

## Frontmatter Fields

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | kebab-case, matches filename |
| `description` | Yes | How Claude decides when to delegate. Make it specific and action-oriented. |
| `tools` | No | Allowlist. Omit to inherit all tools from parent. |
| `disallowedTools` | No | Denylist. Applied before `tools`. |
| `model` | No | `sonnet`, `haiku`, `opus`, full ID, or `inherit` (default) |
| `skills` | No | Skills preloaded into context at startup. List by name. |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | Cap on agentic turns before the agent stops |
| `memory` | No | `user`, `project`, or `local` — enables cross-session learning |
| `background` | No | `true` to always run as a background task |
| `isolation` | No | `worktree` to run in a temp git worktree (auto-cleaned up) |
| `hooks` | No | Lifecycle hooks scoped to this agent only |
| `mcpServers` | No | MCP servers scoped to this agent only |

For full field details and hook patterns, read `references/frontmatter-fields.md` in this skill.

## Tool Configuration Patterns

**Read-only roles** (reviewer, auditor, analyzer):
```yaml
tools: Read, Glob, Grep
disallowedTools: Write, Edit, Bash
```

**Standard developer roles**:
```yaml
tools: Read, Write, Edit, Glob, Grep, Bash
```

**Rules**:
- Use `tools` (allowlist) when you want to strictly limit capabilities
- Use `disallowedTools` (denylist) when you want to inherit most tools but block a few
- If both are set, `disallowedTools` applies first, then `tools` filters the remainder
- Subagents cannot spawn other subagents — don't add `Agent` to the tools list

## Skills in Agents

Skills listed in `skills:` frontmatter are **fully injected** into the agent's context at startup — not just available for invocation. The agent doesn't inherit skills from the parent conversation; list them explicitly.

```yaml
skills:
  - implement-feature   # Full SKILL.md content injected at startup
  - project-architecture
```

Only list skills the agent actively needs. Every skill adds context cost.

## Writing Effective Descriptions

The description is the delegation trigger. Claude reads it to decide when to route a task to this agent.

```yaml
# Too vague — Claude won't know when to use it
description: Helps with code.

# Too narrow — Claude misses valid use cases
description: Reviews AuthService.ts for security issues only.

# Good — specific about role, domain, and trigger conditions
description: Review code for standards violations, security issues, and architectural
  pattern adherence. Read-only — does not modify files.
```

Tips:
- Name the domain or technology (backend API, frontend, database layer)
- State what the agent does (reviews, implements, deploys)
- Call out key constraints ("read-only", "does not modify files")
- Add "Use proactively after X" to encourage automatic delegation

## Writing the System Prompt (Agent Body)

Keep it short. This repo uses 1-3 sentences because skills carry the detail.

**What to include in the body:**
- Role declaration ("You are a backend API developer.")
- The single most important behavioral constraint
- A pointer to project docs: `Read docs/project-reference.md before starting work.`

**What NOT to include:**
- Code examples (put in skills/references)
- Exhaustive checklists (put in skills)
- Anything that belongs in always-loaded rules

For advanced prompt patterns (HITL gates, definition-of-done checklists, pipeline handoffs), read `references/prompt-patterns.md` in this skill.

## Common Agent Patterns

| Agent | Tools | Notes |
|-------|-------|-------|
| `developer` | Read, Write, Edit, Glob, Grep, Bash | Main implementation role |
| `reviewer` | Read, Glob, Grep | Explicitly disallows Write, Edit, Bash |
| `test-developer` | Read, Write, Edit, Glob, Grep, Bash | Focused on test-only work |

## Adding an Agent to a Profile

1. Create `profiles/{profile}/agents/{name}.md`
2. Set `name`, `description`, `tools`, and `skills` in frontmatter
3. Write a 1-3 sentence body (role + priority constraint)
4. Verify the manifest has `"agents": { "profile": "profiles/{profile}/agents" }` — existing profiles already have this
5. Test: run the init script and confirm the agent appears in the target project's `.claude/agents/` directory

## Model Selection

| Role | Model | Reason |
|------|-------|--------|
| Developer, reviewer, complex reasoning | `inherit` (default) | Uses whatever the user selected for the session |
| Fast codebase search, exploration | `haiku` | Low latency, low cost |
| Deep analysis, security review | `sonnet` | Balanced capability and speed |
| Highly complex multi-step tasks | `opus` | Max capability, higher cost |

`inherit` is correct for most agents — let the user choose the model for their session.
