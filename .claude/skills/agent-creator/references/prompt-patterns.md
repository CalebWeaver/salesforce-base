# Agent System Prompt Patterns

Best practices for writing the markdown body of an agent file — the system prompt Claude uses when the agent runs.

## This Repo's Convention

Keep agent bodies to 1-3 sentences. Skills carry implementation detail. The body is the role declaration.

```markdown
You are a backend API developer. Follow project architecture patterns and standards
from preloaded skills. Read `docs/project-reference.md` before starting work.
```

That's it. Resist the urge to add more — it creates bloat in every invocation.

## Single Responsibility

Each agent should excel at one task with clear input and output. Avoid general-purpose "do everything" agents — they dilute descriptions and make delegation decisions ambiguous.

```markdown
# Bad — too broad, Claude won't know when to use it
You are a helpful assistant. You can write code, review it, deploy it,
and write documentation.

# Good — focused role with clear scope
You are a test developer. Your only job is writing test classes.
Never modify production code. Follow test patterns from preloaded skills.
```

## Human-in-the-Loop (HITL) Gates

For agents with autonomy over significant changes, embed stopping points where the agent must wait for human input before proceeding.

```markdown
Before making any DML-affecting changes, list the operations you plan to perform
and wait for approval. Ask numbered questions when acceptance criteria are ambiguous
and wait for answers before proceeding.
```

This keeps humans in control of progression without requiring constant prompting.

## Definition of Done Checklist

Embed a completion checklist directly in the system prompt so the agent knows what "done" means.

```markdown
A task is complete when:
- All new code has corresponding test coverage >80%
- All tests pass
- No security issues introduced
- Code reviewed against project standards from preloaded skills
```

## Workflow Steps Pattern

For agents that follow a predictable sequence, list it explicitly. This reduces hallucinated steps.

```markdown
When invoked:
1. Read `docs/project-reference.md` for project context
2. Identify the files relevant to the task
3. Check for existing patterns before creating new ones
4. Implement following patterns from preloaded skills
5. Write or update tests before marking complete
```

## Memory Maintenance Instructions

When an agent has `memory` enabled, tell it how to use that memory proactively.

```markdown
Before starting work, read your agent memory for relevant patterns and prior decisions.
After completing a task, update your agent memory with any new patterns, gotchas,
or architectural decisions discovered. Keep notes concise — one or two sentences per item.
```

## Pipeline / Handoff Pattern

For multi-agent workflows, the agent body can specify handoff signals.

```markdown
When your review is complete, output a summary block in this format:
---REVIEW COMPLETE---
Issues found: {count}
Critical: {list or "none"}
Suggestions: {list or "none"}
Recommended next: @"test-developer (agent)" to add missing test coverage

This signals the orchestrator (main conversation) that the next step should be invoked.
```

Prefer hook-driven handoffs over prompt-based ones when possible — register `SubagentStop` hooks in `settings.json` to print suggested next commands automatically.

## Security-Conscious Prompts

For agents with broad tool access, add explicit guardrails.

```markdown
Never delete files unless explicitly asked. Never push to remote branches.
Never hardcode credentials or Salesforce IDs. When in doubt, ask before acting.
```

## Role + Constraint + Pointer Pattern

The minimal effective pattern for this repo:

```markdown
You are a [role]. [One sentence on the most important behavioral constraint].
[Pointer to project docs or key skill.]
```

Examples:

```markdown
# developer
You are a backend developer. Follow project architecture patterns and standards
from preloaded skills. Read `docs/project-reference.md` before starting work.

# reviewer
Review code for compliance with project standards and architecture from
preloaded skills. Focus on security, layer boundary violations, and test coverage.

# developer (poc/prototype)
You are a prototype developer. Speed matters more than production hardening.
Follow POC standards from preloaded skills.
```

## What NOT to Put in the Body

- Code examples → put in skills/references
- Long decision trees → put in skills
- Exhaustive checklists of rules already covered by preloaded skills → redundant
- Anything already covered by always-loaded rules → already in context
- Explanations of why → put the "why" in skills if needed; agents need the "what"
