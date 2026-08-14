# Product Specification — Executive Intelligence Agent

**Version:** 0.1.0  
**Owner:** Product Architecture  
**Related:** [architecture.md](./architecture.md), [mvp-backlog.md](./mvp-backlog.md), [executive-questions.md](./executive-questions.md)

---

## 1. Problem

SME owners and senior managers run their companies on Microsoft Dynamics 365 Business Central, but they do not manage the business from ERP screens.

They need answers to questions such as:

- Why did profit fall this month?
- Why is cash falling while sales grow?
- Who should we call for collections today?
- Can we afford to hire?

Business Central stores the facts. Reports and dashboards show *what* happened. Owners still do the *why*, *so what*, and *what next* work themselves — or they wait for a controller, accountant, or consultant.

Existing tools fail them in four ways:

1. **ERP-native language.** G/L accounts, dimensions, posting groups, and report IDs are not executive language.
2. **What without why.** Dashboards report revenue; they do not explain mix, cost, or working-capital traps.
3. **No evidence trail.** Spreadsheet commentary and generic ChatGPT answers cannot be traced to posted transactions.
4. **Wrong user.** Power BI and BC report packs assume an analyst. This product assumes a CEO with ten minutes.

## 2. Product

**Executive Intelligence Agent** is a multi-tenant SaaS C-level advisor connected primarily to Business Central.

It converts authorized ERP data into:

- business-language answers
- explanations with drivers
- prioritized alerts
- recommended actions
- forecasts and scenarios (later phases)
- inspectable evidence

It is **not** another ERP dashboard, **not** a generic chatbot over OData, and **not** an LLM writing SQL against production.

## 3. Target customer

### Primary

Indian and international SMEs (roughly 20–500 employees) already live on Business Central, typically:

- manufacturing, distribution, trading, professional services
- owner-managed or professional CEO + small finance team
- one or more legal companies in one BC tenant
- INR or mixed-currency books; GST/VAT as applicable

### Secondary

- CFOs / finance heads who want a daily pulse without building reports
- Multi-company groups that need a consistent executive layer across companies
- Implementation partners who want a value-add on top of BC

### Not primary (MVP)

- Enterprises that already run a full FP&A stack (Anaplan, Pigment, etc.)
- Companies whose system of record is SAP ECC/S4, Oracle, Tally-only, or Excel-only
- Users who need transactional posting into BC (this product is read/analyze first)

## 4. User personas

| ID | Persona | Goals | Frustrations | Success look |
| --- | --- | --- | --- | --- |
| P1 | **Owner / MD** | Know if the business is healthy; decide cash, hiring, pricing | Does not speak ERP; waits on accountant | Morning briefing + 3 actions |
| P2 | **CEO** | Board-ready narrative; risks before they explode | Dashboards without causality | Diagnostic answers with evidence |
| P3 | **CFO / Finance Head** | P&L, BS, WC, variance, collections priority | Manual Excel bridges | Traceable metrics + driver trees |
| P4 | **COO** | Inventory cash lock-up, service levels | Stock reports without working-capital view | Slow movers, coverage, purchase drag |
| P5 | **CRO / Sales Head** | Who is growing, declining, profitable | Sales value ≠ cash or margin | Customer/product profitability |
| P6 | **Collections lead** | Who to call first today | Ageing dump, no priority | Ranked call list with reasons |
| P7 | **Read-only board observer** | Monthly pack | Too much operational detail | Board summary only |

**Permission principle:** a Sales Manager must not automatically see payroll, confidential G/L, or other companies.

## 5. Jobs to be done

1. When I start my day, I want a 3-minute pulse so I know what needs me.
2. When a number looks wrong, I want to know *why* in business language.
3. When cash is tight, I want the next controllable actions ranked.
4. When I ask a follow-up, I want the agent to keep period, company, and currency context.
5. When I present to the board, I want claims I can defend from ERP evidence.
6. When data is incomplete, I want the system to say so — never invent.

## 6. Core use cases (MVP Phase 1–3)

| UC | Use case | Phase |
| --- | --- | --- |
| UC-01 | Connect BC (Entra ID), pick environment and company, sync | 1–2 |
| UC-02 | Ask natural-language questions about sales, profit, cash, AR, AP, inventory | 4–5 |
| UC-03 | Compare current period vs prior period / prior year | 3–4 |
| UC-04 | See ranked overdue customers and call-first list | 3–6 |
| UC-05 | Inspect evidence for any material claim | 3–5 |
| UC-06 | Morning CEO briefing | 6 |
| UC-07 | Prioritized “what needs attention” + recommendations | 6 |
| UC-08 | Diagnostic “why did X change?” with driver decomposition | 6 |
| UC-09 | Alerts on threshold breaches | 6 |
| UC-10 | Business Health Score with transparent rules | 7 |

Later: forecasts, scenarios, CRM/bank/Fabric, document RAG.

## 7. User stories (representative)

- As an **owner**, I can ask “how are we doing this month?” and receive a pulse in my company’s currency without knowing G/L numbers.
- As a **CFO**, I can ask “why did gross margin fall?” and see contribution by product, customer, price, cost, and mix — with evidence.
- As a **CEO**, I can open the morning briefing and see at most five issues ranked by impact × urgency × confidence × controllability.
- As a **collections lead**, I can get “call these 10 customers first” with overdue amount, days, and customer value.
- As a **tenant admin**, I can restrict a sales manager from payroll and management accounts.
- As an **auditor of AI**, I can open an analysis run and see metrics, periods, sources, and confidence labels.

## 8. Functional requirements

### Must (MVP)

- Multi-tenant SaaS with company-scoped data
- Microsoft Entra ID OAuth for Business Central
- Multi-environment (sandbox/production) and multi-company
- Incremental sync of core entities (see [data-model.md](./data-model.md))
- Deterministic metric engine (see [metrics.md](./metrics.md))
- Executive chat with intent → tools → calculation → interpretation
- Evidence records for material claims
- Conversation context (period, company, last metrics)
- Demo company seed (no live BC required for development)
- Audit log of AI requests (no raw OAuth tokens; minimize raw ERP payloads)
- RBAC as specified in [security.md](./security.md)

### Should (Phase 6–7)

- Driver analysis, briefing, alerts, health score, recommendations

### Could (Phase 7+)

- Statistical forecasts, scenario simulator, anomalies, extra integrations

## 9. Non-functional requirements

| Area | Requirement |
| --- | --- |
| Accuracy | Financial math uses decimal types only; golden tests for every MVP metric |
| Latency | Simple lookup/metric answers p95 < 8s with warm cache; briefing generation may be async |
| Freshness | UI shows last successful sync time per company |
| Availability | Design for Azure; single-region MVP OK |
| Scale | Architecture supports later split of sync/analytics workers |
| i18n | Locale-aware number/date; INR crore/lakh formatting as display layer, not storage |
| Accessibility | Keyboard-usable chat and dashboard; sufficient contrast |
| Observability | Structured logs, error tracking, AI tracing (prompts redacted) |

## 10. Security requirements (summary)

Full detail: [security.md](./security.md).

- Tenant isolation in every query
- Company-level authorization
- Encrypted tokens at rest
- Prompt-injection defence; no tool that executes free SQL
- Least-privilege BC API consent
- Role-based metric and G/L visibility

## 11. MVP scope

### In — Phase 1 product MVP (Phases 0–5 of build)

Authentication, tenant, BC connection, core sync, semantic metrics, executive chat, evidence, dashboard cards, demo data.

**Metrics:** Revenue, Gross Profit, Gross Margin, Operating Profit (if mappable), Cash, AR, AP, Inventory, Working Capital, DSO, DPO.

**Question classes:** descriptive, comparative, lookup, ranking (overdue / top debtors).

### In — Phase 2–3 product MVP (build Phase 6)

Diagnostics, briefing, alerts, recommendations, collections ranking.

### Out of MVP

- Posting or writing back to Business Central
- Full statutory reporting / GST returns
- Payroll deep analysis unless G/L mapping exists and user is authorized
- Autonomous multi-agent swarms
- Document RAG as a required path
- Fabric / Synapse / Snowflake as the system of record
- WhatsApp / Slack / Teams delivery (extension points only)

## 12. Success metrics

| Metric | Target (directional) |
| --- | --- |
| Time-to-first-insight after connect | First briefing or chat answer after successful sync |
| Answer faithfulness | Zero fabricated ERP numbers in eval set |
| Question coverage | ≥ 80% of Phase-1 golden questions answered with correct metrics |
| Executive usefulness | Owner can act from briefing without opening BC |
| Trust | Every material number has View evidence |

**Definition of MVP success (product):**

A business owner can connect Business Central and ask:

- How are we doing this month?
- Why did profit decline?
- Why is cash lower?
- Who owes us money?
- Which customers should we call?
- Which products make us the most money?
- Where is inventory getting stuck?
- What should I focus on this week?

and receive an accurate, traceable, business-language answer from that company’s ERP data (or an explicit insufficiency statement).

## 13. Product principles (operating)

1. **Business language first** — never require G/L numbers, table IDs, or API names.
2. **Answer WHY, not only WHAT.**
3. **Evidence before opinion.**
4. **Executive prioritization** — impact × urgency × confidence × controllability.
5. **LLM explains; engine calculates.**
