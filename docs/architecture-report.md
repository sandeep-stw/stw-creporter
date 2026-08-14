# Architecture Report — Fifteen Planning Deliverables

**Product:** Executive Intelligence Agent  
**Date:** 14 August 2026  
**Phase:** 0 complete (planning). Next: Phase 1 Task ENG-001.

This report answers the first architecture task. Detail lives in the linked documents. The **sequential build list** is in [roadmap.md](./roadmap.md).

---

## 1. Product architecture

A read-analyze-advise SaaS layer on Business Central. Executives ask business questions. An orchestrator classifies intent, selects metrics, runs **allow-listed** analytical tools, then an LLM writes executive language over a **facts JSON**. Sync workers load official BC APIs (or a mock/demo seed) into a canonical PostgreSQL model. Specialist “agents” are prompt + tool profiles, not a multi-agent swarm.

See [architecture.md](./architecture.md).

---

## 2. User personas

Owner/MD, CEO, CFO/Finance Head, COO, CRO/Sales Head, Collections lead, Read-only board observer. RBAC prevents Sales from seeing payroll/management accounts by default.

See [product-spec.md](./product-spec.md).

---

## 3. Top 50 C-level questions

Catalogue Q01–Q50 with intent, phase, metrics, and specialists: [executive-questions.md](./executive-questions.md). Sample eval JSON: [eval/golden-questions.sample.json](./eval/golden-questions.sample.json).

---

## 4. MVP feature list

**P0 (Phases 1–5):** Auth, tenant, RBAC, BC OAuth, sync, demo company, metrics M01–M11, executive chat, evidence, dashboard cards, onboarding.

**P1 (Phase 6):** Drivers, collections ranking, briefing, recommendations, alerts.

**P2 (Phase 7):** Forecast, scenarios, health score, anomalies.

Out: BC write-back, Teams/WhatsApp delivery, Fabric as SoR, required document RAG.

See [mvp-backlog.md](./mvp-backlog.md).

---

## 5. Business Central data requirements

Standard API v2.0: companies, customers, vendors, items, accounts, generalLedgerEntries, sales/purchase invoices and lines, orders, bankAccounts, dimensions.

Often **custom AL APIs**: customer/vendor/item ledger, value entries, budgets, payment applications.

Capability probe records `standard_api | custom_api | unavailable`. Metrics degrade with labels or `insufficient` — never invented endpoints or silent zeros.

See [data-model.md](./data-model.md).

---

## 6. Canonical data model

Tenant → Connection → Environment → Company → customers, vendors, items, G/L, invoices, ledgers, banks, periods, currencies. Platform: sync, metrics, conversations, analysis runs, evidence, alerts, audit.

Prisma: [../prisma/schema.prisma](../prisma/schema.prisma). Money is `Decimal`. Isolation keys: `tenantId` (+ `companyId`).

---

## 7. Metric catalogue

MVP: Revenue, Gross Profit, Gross Margin, Operating Profit (mapped only), Cash, AR, AP, Inventory, Working Capital, DSO, DPO.

Each has formula, date field, currency rule, edge cases, tests: [metrics.md](./metrics.md).

---

## 8. AI orchestration design

Question → guards → intent → planner → tools → authz → engine → drivers → facts JSON → LLM (prompt v1) → evidence validation → persist.

Tools: `getMetric`, `compareMetric`, `breakdownMetric`, `getTopCustomers`, `getTopVendors`, `getOverdueReceivables`, later ageing, expenses, cash bridge, scenario, health.

See [ai-system.md](./ai-system.md), [prompts/executive-advisor.v1.md](../prompts/executive-advisor.v1.md).

---

## 9. Security architecture

Entra ID app auth; confidential client for BC; encrypted tokens; TLS; RBAC; prompt-injection isolation; rate limits; redacted audit. Denied data is an error, not zero.

See [security.md](./security.md).

---

## 10. Multi-tenant architecture

Every business query filters `tenantId` server-side. Company grants on memberships. Prisma/query guard + automated cross-tenant tests. Front-end filters are not security.

---

## 11. Recommended technical stack

Next.js, React, TypeScript, Tailwind, shadcn/ui, PostgreSQL, Prisma, Redis, BullMQ, Auth.js + Entra ID, LLM provider interface (Azure OpenAI-capable), Recharts, Azure-portable containers, Pino + OpenTelemetry. `decimal.js` for money. Later: Fabric/ClickHouse behind `AnalyticsStore`.

---

## 12. Folder structure

`app`, `components`, `features`, `domain`, `analytics`, `agents`, `ai`, `connectors/business-central`, `auth`, `security`, `db`, `jobs`, `lib`, `types`, `tests`, `docs`, `prompts`, `prisma` — as in [architecture.md](./architecture.md) §14.

---

## 13. Development phases

Phase 0 Foundation → 1 Platform → 2 BC → 3 Analytics → 4 AI → 5 Executive UI → 6 Intelligence → 7 Advanced.

---

## 14. Detailed MVP backlog

Items **MVP-001 … MVP-039** with ID, epic, story, value, approach, dependencies, acceptance criteria, priority: [mvp-backlog.md](./mvp-backlog.md).

Sequential engineering tasks **DOC-01 … ENG-070**: [roadmap.md](./roadmap.md).

---

## 15. Major risks and mitigations

Highest: missing ledger APIs, LLM hallucination, float math, tenant leaks, G/L sign errors, date-field confusion, guessed operating profit, scope creep.

See [risks.md](./risks.md).

---

## Sequential path to a complete product (compressed)

1. Accept this pack.  
2. Scaffold app + Postgres/Redis + Prisma migrate.  
3. Entra login + tenant + RBAC + audit.  
4. BC connector (mock + OAuth HTTP) + sync.  
5. Demo seed + metric engine + tests.  
6. Orchestrator + validated chat API.  
7. Onboarding + dashboard + chat + evidence UI.  
8. Drivers, briefing, collections, alerts, recs.  
9. Forecast, scenarios, health, anomalies.  
10. Keep the 50-question eval green as the quality bar.

Do not implement Phase 1 until this report and linked specs remain consistent.
