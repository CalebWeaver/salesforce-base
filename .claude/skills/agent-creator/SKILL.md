---
name: agent-creator
description: How to design and create Claude Code subagents — frontmatter fields, description writing, prompt patterns, and placement in this baseline repo.
---

## Agent vs Skill

Use an **agent** when the task needs isolated context, specific tool restrictions, or a separate model.
Use a **skill** when you want reusable instructions that run in the main conversation.

## Frontmatter Reference

```yaml
---
name: code-reviewer          # required; kebab-case; unique per scope
description: ...             # required; Claude's routing signal — see Description section
tools: Read, Grep, Glob, Bash  # allowlist; omit to inherit all tools from parent
disallowedTools: Write, Edit   # denylist; inherit everything except these
model: inherit               # sonnet | opus | haiku | <full-model-id> | inherit (default)
permissionMode: default      # default | acceptEdits | dontAsk | bypassPermissions | plan
maxTurns: 20                 # stop after N agentic turns; prevents runaway costs
skills:                      # inject full skill content at startup; not inherited from parent
  - write-apex
memory: project              # user | project | local — enables persistent memory dir
background: false            # true = always run as background task
effort: medium               # low | medium | high | max (max = Opus 4.6 only)
isolation: worktree          # run in temp git worktree; auto-cleaned up if no changes made
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
---
```

Only `name` and `description` are required. Omit everything else unless it adds specific value.

The agent receives **only** the body as its system prompt — no Claude Code system prompt, no parent skills.

## Description — Routing Signal

Claude matches user requests to agents via the description. Write it to match the task, not the agent's identity.

- Include role + trigger + proactivity hint: `Expert code reviewer. Use proactively after writing or modifying code.`
- Include domain + action: `Debugging specialist for errors and test failures.`
- "Use proactively" or "Use immediately after X" enables automatic delegation without @-mention.
- Avoid vague nouns: ~~`Code quality agent`~~

## Prompt Quality: ok → good

**ok** (prose, conditional, category-organized):
```
Examine the provided code or diff. If no files specified, run `git diff main`.
1. Correctness — Logic errors, edge cases...
2. Security — Injection risks...
Distinguish blockers from suggestions. Be direct. Skip praise.
```

**good** (directive, checklist, priority-organized):
```
When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is clear and readable
- No exposed secrets or API keys
- ...

Provide feedback by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

Rules:
- Open with `When invoked:` numbered steps — bake in defaults, eliminate conditional prose
- Use bullet checklists for "what to check", not prose categories
- Prescribe output structure explicitly (priority tiers, not topic categories)
- Ask for fix examples, not just identification
- Drop negative instructions ("Be direct", "Skip praise") — just model the behavior you want

## Tool Selection

- Read-only agent: `tools: Read, Grep, Glob, Bash` (excludes Edit/Write implicitly)
- Use `disallowedTools` to block specific tools while inheriting the rest
- Use `hooks.PreToolUse` for conditional logic (e.g., allow `bash` but block SQL write statements)

## Model Selection

- `haiku` — fast search/exploration; low cost
- `sonnet` — default for most tasks
- `opus` — complex reasoning; architecture decisions
- `inherit` — same model as parent session (actual default when field is omitted)

## Memory

- `memory: project` is the recommended default — stores in `.claude/agent-memory/<name>/`; commit to share with team
- `memory: user` — cross-project knowledge in `~/.claude/agent-memory/<name>/`
- Add to the agent prompt: "Update your agent memory as you discover patterns, conventions, and architectural decisions."

## Skills Preloading

- List skills under `skills:` to inject their full content into the agent at startup
- The agent won't discover or invoke skills on its own — preloading is the only way to give it skill knowledge
- Prefer preloading over telling the agent to "read the X skill" — more reliable

## Placement in This Repo

```
profiles/base/agents/                    ← Shared across enterprise + lightweight
profiles/{enterprise|lightweight}/agents/  ← Profile-specific
profiles/poc/agents/                     ← POC-only
.claude/agents/                          ← This baseline repo's own agents (not templated)
```

After adding an agent:
1. Place the `.md` file in the appropriate `profiles/*/agents/` directory
2. Verify `manifest.json` has `agents.profile` pointing to the right directory
3. Add an invocation hint to the relevant rules file: `Use the @code-reviewer agent after making changes.`

## Reference

[Sub-agents documentation](https://code.claude.com/docs/en/sub-agents)
