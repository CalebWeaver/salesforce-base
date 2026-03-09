# User Stories

This directory contains one file per user story. Each file gives an AI agent enough context to implement the story without needing access to an external project management tool.

## How to Use

Create a new markdown file for each user story, named with the story identifier (e.g., `US-101-case-auto-routing.md`, `US-102-routing-admin-screen.md`). Group related stories under the same epic prefix so they sort together.

**Status lifecycle**: `Draft` → `Ready` → `In Progress` → `In Review` → `Complete`. Agents should update a story's status to `In Progress` when starting work and `In Review` when implementation is done. Only a human moves a story to `Complete`.

## What to Include

Each user story file should cover:

- **Status**: Current lifecycle stage — `Draft`, `Ready`, `In Progress`, `In Review`, or `Complete`
- **Story**: The user story statement (As a ___, I want ___, so that ___)
- **Epic**: Which epic this belongs to (if applicable)
- **Acceptance criteria**: Specific, testable conditions that must be met
- **Technical notes**: Implementation guidance — relevant objects, classes, patterns, or constraints the agent should know about
- **Dependencies**: Other stories or modules this depends on
- **Out of scope**: What this story explicitly does NOT cover (helps agents avoid scope creep)

## Example

```markdown
# US-101: Auto-Route Incoming Cases

**Status**: Ready
**Epic**: Case Routing

## Story
As a support manager, I want incoming Cases to be automatically assigned to the correct queue based on configurable rules, so that Cases reach the right team without manual triage.

## Acceptance Criteria
- Cases are evaluated against Routing_Rule__c records on insert
- Rules are evaluated in Priority__c order; first match wins
- If no rule matches, Case is assigned to the Default_Queue__c from Routing_Config__mdt
- Routing works in bulk (200+ Cases in a single insert)

## Technical Notes
- Use the TriggerHandler pattern from templates
- Routing_Rule__c and Routing_Group__c already exist (see docs/modules/case-routing.md)
- The RoutingEngine class should be stateless and testable without DML

## Dependencies
- Routing_Rule__c and Routing_Group__c objects must be deployed first
- Depends on SecurityEnforcer for CRUD/FLS checks

## Out of Scope
- Round-robin assignment within a queue (that's US-103)
- Re-routing on Case field updates (that's US-105)
```
