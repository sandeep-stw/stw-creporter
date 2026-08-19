# Executive Intelligence Agent — Architecture Pack

**Product:** Executive Intelligence Agent  
**Primary ERP:** Microsoft Dynamics 365 Business Central  
**Audience:** SME owners and C-level / senior management  
**Status:** Phase 0 — architecture and planning (no application runtime yet)  
**Version:** 0.1.0  
**Date:** 14 August 2026

This pack is the source of truth for design before implementation. Application code must not start until these documents stay internally consistent.

## Read in this order

| Order | Document | Purpose |
| --- | --- | --- |
| 0 | [architecture-report.md](./architecture-report.md) | Fifteen planning deliverables in one place |
| 1 | [product-spec.md](./product-spec.md) | Problem, personas, jobs, MVP, success |
| 2 | [executive-questions.md](./executive-questions.md) | Top 50 C-level questions and intent map |
| 3 | [architecture.md](./architecture.md) | System, stack, folders, tenancy, BC, AI |
| 4 | [data-model.md](./data-model.md) | Canonical model, sync, Prisma |
| 5 | [metrics.md](./metrics.md) | MVP metric catalogue |
| 6 | [ai-system.md](./ai-system.md) | Orchestration, tools, anti-hallucination |
| 7 | [security.md](./security.md) | Security, RBAC, audit, isolation |
| 7b | [entra-app.md](./entra-app.md) | Entra app registration (BCM-010) |
| 8 | [ux.md](./ux.md) | Screens, briefing-first UI |
| 9 | [mvp-backlog.md](./mvp-backlog.md) | Backlog items with acceptance criteria |
| 10 | [roadmap.md](./roadmap.md) | Phases, epics, sequential task list |
| 11 | [risks.md](./risks.md) | Risks and mitigations |
| 12 | [prompts/executive-advisor.v1.md](../prompts/executive-advisor.v1.md) | Versioned production system prompt |

## Non-negotiable engineering rules

1. Never use JavaScript floating point for financial calculations.
2. Never trust client-side authorization.
3. Never allow cross-tenant data access.
4. Never allow an LLM to generate unrestricted executable SQL.
5. Never fabricate Business Central API endpoints.
6. Never hide analytical assumptions.
7. Never expose raw secrets or OAuth tokens.
8. Never use fake values in production responses.
9. Never silently substitute missing data.
10. Never confuse invoice date, posting date, and due date.
11. Never combine currencies without explicit conversion.
12. Never interpret accounting signs without validating Business Central conventions.
13. Never label correlation as causation.
14. Never deploy financial calculations without tests.
15. Always keep deterministic analytics separate from LLM interpretation.

## Implementation gate

Implementation of Phase 1 (platform) starts only after this pack is accepted. The first code milestone is repository scaffolding, not chat UI.
