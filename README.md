# Executive Intelligence Agent

SaaS C-level advisor for companies running **Microsoft Dynamics 365 Business Central**.

This repository is in **Phase 0 — architecture and planning**. Application runtime is not implemented yet.

## Read first

Start at [docs/README.md](./docs/README.md).

| Document | Contents |
| --- | --- |
| [docs/architecture-report.md](./docs/architecture-report.md) | Fifteen planning deliverables |
| [docs/product-spec.md](./docs/product-spec.md) | Problem, personas, MVP, success |
| [docs/executive-questions.md](./docs/executive-questions.md) | Top 50 C-level questions |
| [docs/architecture.md](./docs/architecture.md) | Stack, folders, BC, AI, tenancy |
| [docs/data-model.md](./docs/data-model.md) | Canonical model and sync |
| [docs/metrics.md](./docs/metrics.md) | Metric catalogue |
| [docs/ai-system.md](./docs/ai-system.md) | Orchestration and anti-hallucination |
| [docs/security.md](./docs/security.md) | RBAC and isolation |
| [docs/ux.md](./docs/ux.md) | Screens and UX |
| [docs/mvp-backlog.md](./docs/mvp-backlog.md) | Backlog with acceptance criteria |
| [docs/roadmap.md](./docs/roadmap.md) | **Sequential task list** to complete the project |
| [docs/risks.md](./docs/risks.md) | Risks and mitigations |
| [prompts/executive-advisor.v1.md](./prompts/executive-advisor.v1.md) | Versioned system prompt |
| [prisma/schema.prisma](./prisma/schema.prisma) | Initial data model |

## Next implementation step

Follow **Phase 1, Task 1.1** in [docs/roadmap.md](./docs/roadmap.md): scaffold Next.js, TypeScript, and the domain folder structure. Do not skip metric tests when analytics work begins.

## Product rule

The language model explains. The calculation engine calculates. No unrestricted SQL from the LLM.
