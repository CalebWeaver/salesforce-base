Orchestrate the story implementation pipeline for: $ARGUMENTS

If no story file path was provided, list the `.md` files in `docs/user-stories/` (excluding README.md) and ask the user to pick one before proceeding.

---

## Pipeline

Work through each stage below in order. Do not skip stages. After agent stages, always surface a summary to the user before moving to the next gate.

---

### Stage 1 — Dev Agent: Implement Story

Use the **Agent tool** to spawn a dev agent with the following task:

> Read the story file at `<story_file>` carefully. Implement all required Apex classes, triggers, LWC components, and configuration metadata needed to satisfy the acceptance criteria. Follow all guidelines in CLAUDE.md — patterns, naming conventions, security (CRUD/FLS), governor limits, and meta.xml requirements. When done, respond with a summary listing every file created or modified.

Wait for the agent to complete and capture its summary.

---

### Stage 2 — Lint (Post-Implementation)

Run the project lint command via Bash:
- If `package.json` contains a `"lint"` script → `npm run lint`
- Else if `sf` CLI is available → `sf scanner run --target force-app/ --format table`
- Else → note that no lint command was found and continue

Report any violations found.

---

### Stage 3 — Human Review Gate: Implementation

Run `git diff --stat` and show the output to the user.

Ask the user:
> "**Stage 3 — Human Review: Implementation**
>
> The dev agent has finished and lint has run. Here's what changed:
> `<git diff --stat output>`
>
> **Lint result:** `<pass / issues found>`
>
> Do you approve this implementation, or do you have feedback for the dev agent?"

- If **approved** → continue to Stage 4.
- If **feedback provided** → return to Stage 1 with the user's feedback appended to the dev agent task. Repeat until approved.

---

### Stage 4 — Test Agent: Write Tests

Get the list of changed Apex files: `git diff --name-only HEAD -- "*.cls" "*.trigger"`

Use the **Agent tool** to spawn a test agent with the following task:

> Read the story file at `<story_file>`. The following Apex files were added or modified: `<changed files list>`. Write comprehensive Apex unit tests for all of them. Follow the test data framework patterns in CLAUDE.md. Requirements: 90%+ code coverage target, test positive paths, negative/error paths, and bulk scenarios (200+ records). Use `@TestSetup` where appropriate. Do not rely on existing org data. When done, respond with a summary of test classes written and the coverage you expect.

Wait for the agent to complete and capture its summary.

---

### Stage 5 — Lint (Post-Tests)

Run the same lint command as Stage 2 and report any violations.

---

### Stage 6 — Human Review Gate: Tests

Run `git diff --stat HEAD` and show new test files.

Ask the user:
> "**Stage 6 — Human Review: Tests**
>
> The test agent has finished and lint has run. Here's what was added:
> `<git diff --stat output>`
>
> **Test agent summary:** `<agent summary from Stage 4>`
> **Lint result:** `<pass / issues found>`
>
> Do you approve these tests, or do you have feedback for the test agent?"

- If **approved** → continue to Stage 7.
- If **feedback provided** → return to Stage 4 with the user's feedback appended to the test agent task. Repeat until approved.

---

### Stage 7 — Code Review Agent: Final Feedback

Use the **Agent tool** to spawn a code review agent with the following task:

> You are a senior Salesforce code reviewer. Review all changes made for the story at `<story_file>`. Run `git diff HEAD` to see every changed file. Provide a structured code review covering:
>
> 1. **Security** — CRUD/FLS enforcement on all DML and SOQL, no exposed sensitive data, no hardcoded IDs
> 2. **Governor limits** — SOQL in loops, DML in loops, CPU time risks, heap size risks
> 3. **Pattern compliance** — Does the implementation follow the architecture patterns defined in CLAUDE.md?
> 4. **Test quality** — Coverage breadth, data isolation, bulk testing, meaningful assertions (not just `System.assertNotEquals(null, result)`)
> 5. **Overall verdict** — `APPROVE` or `REQUEST CHANGES`, with a one-sentence summary
>
> Cite specific file names and line numbers for every issue raised.

Present the full code review output to the user.

---

## Completion

After Stage 7, tell the user the pipeline is complete and remind them to:
1. Commit the changes: `git add -A && git commit -m "feat: <story name>"`
2. Push to their feature branch
3. Address any `REQUEST CHANGES` items from the code review before opening a PR
