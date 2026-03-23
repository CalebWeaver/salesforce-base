# Frontmatter Fields Reference

Complete reference for all supported fields in Claude Code agent `.md` files.
Source: https://code.claude.com/docs/en/sub-agents

## Required Fields

### `name`
Unique identifier. Lowercase letters and hyphens only. Must match the filename (without `.md`).

```yaml
name: code-reviewer
```

### `description`
Tells Claude when to delegate to this agent. Written from Claude's perspective as a delegation trigger. This is the most important field — write it carefully.

```yaml
description: Expert code review specialist. Proactively reviews code for quality,
  security, and maintainability. Use immediately after writing or modifying code.
```

## Tool Configuration Fields

### `tools`
Allowlist of tools the agent can use. Omit to inherit all tools from the parent conversation, including MCP tools.

```yaml
tools: Read, Glob, Grep, Bash
```

Available internal tools: `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `Agent`, `WebFetch`, `WebSearch`, `TodoRead`, `TodoWrite`

### `disallowedTools`
Denylist of tools to block. Applied before `tools` when both are set. Useful when you want to inherit most tools but block a few.

```yaml
disallowedTools: Write, Edit
```

**Interaction with `tools`**: If both are set, `disallowedTools` filters the inherited set first, then `tools` restricts to the specified allowlist. A tool in both lists is removed.

### `Agent(agent-name)` syntax
When an agent runs as a main thread (`claude --agent`), restrict which sub-agents it can spawn:

```yaml
tools: Agent(worker, researcher), Read, Bash
```

This is an allowlist — only `worker` and `researcher` can be spawned. Omit parentheses (`Agent`) to allow spawning any sub-agent.

## Model Field

### `model`
Controls which AI model the agent uses.

| Value | Behavior |
|-------|----------|
| `inherit` | Same model as the parent conversation (default when omitted) |
| `haiku` | Fast, low-latency, low-cost. Good for exploration and search. |
| `sonnet` | Balanced capability and speed. Good for analysis and implementation. |
| `opus` | Maximum capability. Good for complex reasoning. Higher cost. |
| Full model ID | e.g., `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` |

```yaml
model: sonnet
```

## Context and Knowledge Fields

### `skills`
Skills to preload into the agent's context at startup. Full skill content is injected — not just made available for invocation. Agents do NOT inherit skills from the parent conversation.

```yaml
skills:
  - implement-feature
  - project-architecture
  - logging-patterns
```

Only list skills the agent actively needs for its role.

### `memory`
Enables persistent cross-session memory. The agent reads and writes to a dedicated directory.

| Scope | Location | Use When |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge applies across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via git |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not in version control |

```yaml
memory: project
```

When enabled, Read, Write, and Edit are automatically granted for the memory directory. The first 200 lines of `MEMORY.md` in the memory directory are injected into the system prompt.

**Recommended default**: `project` — shareable via version control without being user-global.

## Execution Control Fields

### `permissionMode`
Controls how the agent handles permission prompts.

| Mode | Behavior |
|------|----------|
| `default` | Standard prompts (default) |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts (explicitly allowed tools still work) |
| `bypassPermissions` | Skip all permission prompts — use with caution |
| `plan` | Read-only plan mode |

```yaml
permissionMode: acceptEdits
```

If the parent uses `bypassPermissions`, it takes precedence and cannot be overridden.

### `maxTurns`
Maximum number of agentic turns before the agent stops automatically. Useful to prevent runaway agents.

```yaml
maxTurns: 20
```

### `background`
Set to `true` to always run this agent as a background task (non-blocking).

```yaml
background: true
```

Default is `false` (foreground, blocking). Claude decides foreground vs background for agents without this set.

### `isolation`
Set to `worktree` to run the agent in a temporary git worktree — an isolated copy of the repo. The worktree is automatically cleaned up if the agent makes no changes.

```yaml
isolation: worktree
```

Useful for parallel experiments or risky refactors where you want isolation.

### `effort`
Overrides the session effort level for this agent.

```yaml
effort: high
```

Options: `low`, `medium`, `high`, `max` (max only on Opus 4.6).

## Hooks Field

Defines lifecycle hooks scoped to this agent only. Hooks are cleaned up when the agent finishes.

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
  Stop:
    - hooks:
        - type: command
          command: "./scripts/cleanup.sh"
```

`Stop` hooks in frontmatter are automatically converted to `SubagentStop` events.

Hook events available in frontmatter: `PreToolUse`, `PostToolUse`, `Stop`.

Hook input arrives as JSON via stdin. Exit code 2 blocks the operation.

## MCP Servers Field

Scope MCP servers to this agent only. Servers are connected on agent start, disconnected when it finishes.

```yaml
mcpServers:
  # Inline definition — only this agent gets access
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  # Reference by name — reuses an already-configured server
  - github
```

Inline definitions use the same schema as `.mcp.json` entries. String references reuse the parent session's connection.

**Use case**: Keep noisy or domain-specific MCP servers out of the main conversation's context — define them here so only the agent sees their tool descriptions.
