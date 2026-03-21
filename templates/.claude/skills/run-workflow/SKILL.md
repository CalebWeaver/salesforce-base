---
name: run-workflow
description: Orchestrates a story implementation pipeline for Salesforce development. Use when the user wants to implement a user story end-to-end with dev agent → lint → human review → test agent → lint → human review → code review agent.
---

# Story Implementation Pipeline

Orchestrate the 7-stage agent workflow for: $ARGUMENTS

If no story file path was provided, list `.md` files in `docs/user-stories/` (excluding README.md) and ask the user to pick one before starting.

Make a todo list covering all 7 stages and work through them in order.

---

## Stage 1 — Dev Agent: Implement Story

Use the **Agent tool** to spawn a dev agent with this task:

> Read the story file at `<story_file>`. Implement all required Apex classes, triggers, LWC components, and configuration metadata needed to satisfy the acceptance criteria. Follow all guidelines in CLAUDE.md — patterns, naming conventions, CRUD/FLS security, governor limits, and meta.xml requirements. When done, respond with a summary listing every file created or modified.

Wait for the agent to finish. Capture its file summary.

---

## Stage 2 — Lint (Post-Implementation)

Run the project lint command via Bash:
- If `package.json` has a `"lint"` script → `npm run lint`
- Else if `sf` is available → `sf scanner run --target force-app/ --format table`
- Else → note no lint command found and continue

Report any violations.

---

## Stage 3 — Human Review Gate: Implementation

Run `git diff --stat` and show the output.

Ask the user:

> **Stage 3 — Human Review: Implementation**
>
> The dev agent finished and lint ran. Here's what changed:
> `<git diff --stat output>`
>
> **Lint:** `<pass / N violations>`
>
> Approve to continue to test writing, or provide feedback to revise.

- **Approved** → continue to Stage 4.
- **Feedback given** → return to Stage 1 with the feedback appended to the dev agent task. Repeat until approved.

---

## Stage 4 — Test Agent: Write Tests

Run `git diff --name-only HEAD -- "*.cls" "*.trigger"` to get the list of changed Apex files.

Use the **Agent tool** to spawn a test agent with this task:

> Read the story file at `<story_file>`. The following Apex files were added or modified: `<changed files>`. Write comprehensive Apex unit tests for all of them. Follow the test data framework patterns in CLAUDE.md. Requirements: target 90%+ code coverage; test positive paths, negative/error paths, and bulk scenarios (200+ records); use `@TestSetup` where appropriate; never rely on existing org data. When done, respond with a summary of test classes written and expected coverage.

Wait for the agent to finish. Capture its summary.

---

## Stage 5 — Lint (Post-Tests)

Run the same lint command as Stage 2. Report any violations.

---

## Stage 6 — Human Review Gate: Tests

Run `git diff --stat HEAD` to show what test files were added.

Ask the user:

> **Stage 6 — Human Review: Tests**
>
> The test agent finished and lint ran. Here's what was added:
> `<git diff --stat output>`
>
> **Test agent summary:** `<agent summary from Stage 4>`
> **Lint:** `<pass / N violations>`
>
> Approve to continue to code review, or provide feedback to revise.

- **Approved** → continue to Stage 7.
- **Feedback given** → return to Stage 4 with the feedback. Repeat until approved.

---

## Stage 7 — Code Review Agent: Final Feedback

Use the **Agent tool** to spawn a code review agent with this task:

> You are a senior Salesforce code reviewer. Review all changes for the story at `<story_file>`. Run `git diff HEAD` to see every changed file. Provide a structured code review covering:
>
> 1. **Security** — CRUD/FLS on all DML/SOQL, no hardcoded IDs, no exposed sensitive data
> 2. **Governor limits** — SOQL in loops, DML in loops, CPU/heap risks
> 3. **Pattern compliance** — Does the implementation follow the architecture defined in CLAUDE.md?
> 4. **Test quality** — Coverage breadth, data isolation, bulk testing, meaningful assertions
> 5. **Verdict** — `APPROVE` or `REQUEST CHANGES` with a one-sentence summary
>
> Cite file names and line numbers for every issue raised.

Present the full code review to the user.

---

## Wrap Up

After Stage 7, tell the user the pipeline is complete and remind them to:
1. Commit: `git add -A && git commit -m "feat: <story name>"`
2. Push to their feature branch
3. Address any `REQUEST CHANGES` items before opening a PR
