# Project Architecture

<!--
  This file documents project-specific architecture decisions, integrations,
  and org-level conventions. AI agents reference this when they need context
  about how this project is structured and why.

  Keep this file updated as the project evolves. When you make a significant
  architectural decision, document it here so future developers (and agents)
  understand the reasoning.
-->

## Overview

<!--
  High-level description of the project: what it does, who it serves,
  and what Salesforce features it relies on.
-->

## Org Topology

<!--
  Describe the Salesforce org(s) this project targets:
  - Org type (production, sandbox, scratch)
  - Namespace (if any)
  - Key installed packages and their versions
  - Connected external systems
-->

## Data Model

<!--
  Describe the core custom objects and their relationships. Focus on
  objects this project owns — don't re-document standard Salesforce objects
  unless the project extends them significantly.

  Example:
  - **Routing_Rule__c**: Defines criteria for auto-routing Cases.
    Master-detail to Routing_Group__c. Evaluated in priority order.
  - **Routing_Group__c**: Groups of users who receive routed Cases.
    Junction to User via Routing_Member__c.
-->

## Integrations

<!--
  Document external system integrations:
  - System name and purpose
  - Authentication method (Named Credential name, OAuth flow, etc.)
  - Direction (inbound, outbound, bidirectional)
  - Key endpoints or Platform Events used
  - Error handling and retry strategy
-->

## Key Architectural Decisions

<!--
  Record significant decisions and their rationale. This helps agents
  and developers understand *why* things are the way they are, not just
  *what* they are.

  Example:
  ### Use Platform Events instead of Outbound Messages for ERP sync
  **Decision**: Platform Events with a retry subscriber
  **Rationale**: Outbound Messages don't support custom payloads and
  require configuring delivery endpoints per environment. Platform Events
  give us structured payloads and built-in replay for missed events.
  **Date**: 2025-03-15
-->
