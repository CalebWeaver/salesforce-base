# Module Documentation

This directory contains one file per major module or domain area in the project. Each file describes the module's purpose, key classes, objects, and patterns so AI agents can quickly understand scope and conventions before making changes.

## How to Use

Create a new markdown file for each distinct functional area of the project. Name it after the module (e.g., `case-routing.md`, `billing.md`, `user-provisioning.md`).

## What to Include in Each Module Doc

Each module file should cover:

- **Purpose**: What business problem this module solves
- **Key classes**: The main Apex classes and their roles (triggers, handlers, services, selectors, controllers)
- **Custom objects**: Objects this module owns or heavily depends on
- **Automation**: Flows, Process Builders, or triggers and the events they respond to
- **LWC components**: Any Lightning Web Components in this module
- **External touchpoints**: Integrations, Platform Events, or callouts this module uses
- **Testing notes**: Anything unusual about testing this module (required data setup, mock services, etc.)

## Example

See the template below for a starting point:

```markdown
# Case Routing

## Purpose
Automatically assigns incoming Cases to the correct queue based on configurable routing rules. Supports round-robin and skills-based assignment.

## Key Classes
- **CaseRoutingTriggerHandler**: Trigger handler for Case before insert
- **RoutingEngine**: Evaluates Routing_Rule__c records against Case fields
- **RoutingEngineTest**: Tests for bulk routing, rule priority, fallback behavior

## Custom Objects
- **Routing_Rule__c**: Defines field-match criteria and target queue
- **Routing_Group__c**: Named groups of users for round-robin assignment

## Automation
- Case before insert trigger evaluates routing rules
- Scheduled job (RoutingRebalancer) runs nightly to redistribute open Cases

## Testing Notes
- RoutingEngine tests depend on Routing_Rule__c and Queue records created in @TestSetup
- Use CustomerFixture.withRoutingRules() for standard test scenarios
```
