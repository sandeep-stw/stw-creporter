# MVP Backlog

Each item is implementable in sequence with the [roadmap task list](./roadmap.md). Do not start an item until its dependencies are done.

**Priority:** P0 must for Phase 1 product MVP (chat on core metrics) · P1 Phase 6 · P2 Phase 7.

---

## Platform

### MVP-001 — Repository and app foundation
- **Epic:** Foundation / Platform
- **User story:** As a developer, I have a typed Next.js app with lint, test, and env standards so later work is consistent.
- **Business value:** Enables all delivery without re-platforming.
- **Technical approach:** Next.js App Router, TypeScript strict, ESLint, Vitest, Tailwind, shadcn, folder structure from architecture.md.
- **Dependencies:** Architecture pack accepted.
- **Acceptance criteria:** `pnpm test` and `pnpm lint` run; no business logic in random files; README explains env vars without secrets.
- **Priority:** P0

### MVP-002 — PostgreSQL and Prisma
- **Epic:** Platform
- **User story:** As the platform, I persist tenants and canonical data with decimal money types.
- **Technical approach:** Apply `prisma/schema.prisma`; migrations; no Float for money.
- **Dependencies:** MVP-001
- **Acceptance criteria:** Migrate on empty DB; Decimal columns for amounts; tenantId indexes exist.
- **Priority:** P0

### MVP-003 — Authentication (Entra ID)
- **Epic:** Platform
- **User story:** As a user, I sign in with my Microsoft work account.
- **Technical approach:** Auth.js + Microsoft Entra ID; session expiry; protected routes.
- **Dependencies:** MVP-001
- **Acceptance criteria:** Unauthenticated users cannot hit API; session expires; no tokens in logs.
- **Priority:** P0

### MVP-004 — Tenant and membership
- **Epic:** Platform
- **User story:** As an owner, I have a tenant and can exist as the first member with Owner role.
- **Technical approach:** Tenant create on first login or invite; Membership; unique email per tenant strategy documented.
- **Dependencies:** MVP-002, MVP-003
- **Acceptance criteria:** User cannot see another tenant’s rows in API tests.
- **Priority:** P0

### MVP-005 — RBAC
- **Epic:** Security
- **User story:** As an owner, I assign CEO/CFO/Sales/Ops/Read Only roles that constrain metrics and companies.
- **Technical approach:** Role + Permission grants; AccessControl service on every tool/API.
- **Dependencies:** MVP-004
- **Acceptance criteria:** Sales Manager denied payroll G/L and `getExpenseBreakdown` if not granted; denied ≠ zero.
- **Priority:** P0

### MVP-006 — Audit infrastructure
- **Epic:** Security
- **User story:** As an owner, I can rely on an audit trail of AI and admin actions.
- **Technical approach:** AuditLog + AnalysisRun writers; redaction helpers.
- **Dependencies:** MVP-004
- **Acceptance criteria:** Sample chat writes AnalysisRun without tokens or full BC payloads.
- **Priority:** P0

---

## Business Central

### MVP-007 — BC connector interface and mocks
- **Epic:** Business Central
- **User story:** As a developer, I can run the product without a live BC tenant.
- **Technical approach:** `BusinessCentralConnector` interface; `MockConnector` + HTTP connector; no fake Microsoft URLs in HTTP adapter.
- **Dependencies:** MVP-001
- **Acceptance criteria:** Mock implements companies, customers, invoices, banks; HTTP adapter only documented v2 paths.
- **Priority:** P0

### MVP-008 — OAuth for Business Central
- **Epic:** Business Central
- **User story:** As an owner, I connect BC via Microsoft OAuth without pasting tokens.
- **Technical approach:** Confidential client; encrypted token storage; refresh; environment discovery.
- **Dependencies:** MVP-003, MVP-004
- **Acceptance criteria:** Tokens never returned to client; refresh on 401; disconnect revokes locally.
- **Priority:** P0

### MVP-009 — Company discovery and selection
- **Epic:** Business Central
- **User story:** As an owner, I pick environment and company.
- **Technical approach:** `getCompanies()`; Company rows; capability probe.
- **Dependencies:** MVP-007, MVP-008
- **Acceptance criteria:** Sandbox vs production labelled; probe records unavailable entities.
- **Priority:** P0

### MVP-010 — Sync engine
- **Epic:** Business Central
- **User story:** As an owner, my company’s data syncs incrementally and I see freshness.
- **Technical approach:** BullMQ jobs; SyncCursor; pagination; retry/throttle; upsert.
- **Dependencies:** MVP-002, MVP-009
- **Acceptance criteria:** Full then incremental; `dataUpdatedAt` set; 429 respected in tests; one lock per company.
- **Priority:** P0

### MVP-011 — Core entity sync
- **Epic:** Business Central
- **User story:** As the metric engine, I have customers, vendors, items, G/L accounts/entries, sales/purchase invoices and lines, bank accounts.
- **Technical approach:** One mapper per resource; sign normalization tests.
- **Dependencies:** MVP-010
- **Acceptance criteria:** Idempotent upsert; credit memo signs correct; custom fields in JSON extras.
- **Priority:** P0

### MVP-012 — Ledger extension seam
- **Epic:** Business Central
- **User story:** As a CFO, AR remaining and overdue still work when standard APIs lack ledger entries.
- **Technical approach:** `sourceMode` per entity; AL extension spec in docs; invoice-open fallback labelled.
- **Dependencies:** MVP-011
- **Acceptance criteria:** If ledgers unavailable, AR either degraded+labelled or insufficient — never silent zeros.
- **Priority:** P0

### MVP-013 — Sync monitoring UI
- **Epic:** Business Central
- **User story:** As an owner, I see sync progress and business-language errors.
- **Technical approach:** SyncJob status API + settings page.
- **Dependencies:** MVP-010
- **Acceptance criteria:** No stack traces; retry for admins.
- **Priority:** P0

---

## Analytics

### MVP-014 — Period and currency services
- **Epic:** Analytics
- **User story:** As the engine, I never mix currencies or date types.
- **Technical approach:** PeriodSpec, FiscalPeriod, Money (decimal.js), LCY aggregation only.
- **Dependencies:** MVP-002
- **Acceptance criteria:** Unit tests for FY vs calendar, posting vs due, FX refuse-add.
- **Priority:** P0

### MVP-015 — Metric engine (MVP set)
- **Epic:** Analytics
- **User story:** As a CEO, core metrics are calculated deterministically.
- **Technical approach:** One module per metric M01–M11; SQL NUMERIC aggregations.
- **Dependencies:** MVP-011, MVP-014
- **Acceptance criteria:** Golden tests on demo data; zero revenue margin unavailable; unmapped OpProfit unavailable.
- **Priority:** P0

### MVP-016 — Compare and breakdown
- **Epic:** Analytics
- **User story:** As a CEO, I can compare last month and see top customers.
- **Technical approach:** `compareMetric`, `breakdownMetric` tools.
- **Dependencies:** MVP-015
- **Acceptance criteria:** Residual shown if breakdown does not foot; top-N stable sort.
- **Priority:** P0

### MVP-017 — Evidence model
- **Epic:** Analytics
- **User story:** As a CEO, I can inspect how a number was produced.
- **Technical approach:** Evidence records linked to AnalysisRun.
- **Dependencies:** MVP-015, MVP-006
- **Acceptance criteria:** Drawer fields match spec (metric, period, current, previous, delta, sources).
- **Priority:** P0

### MVP-018 — Financial test suite
- **Epic:** Analytics
- **User story:** As a CFO, I trust numbers because tests encode BC fixtures.
- **Technical approach:** Invoice, credit memo, payment, overdue, multi-currency tests.
- **Dependencies:** MVP-015
- **Acceptance criteria:** CI fails if float used in metric path (lint/custom check optional); all fixtures green.
- **Priority:** P0

---

## Demo data

### MVP-019 — Synthetic demo company
- **Epic:** Demo
- **User story:** As a developer or prospect, I can demo growth, margin pressure, late payers, dead stock, expense spike, cash pressure.
- **Technical approach:** Seed script into canonical tables; `source=demo`.
- **Dependencies:** MVP-002
- **Acceptance criteria:** Seed is deterministic; documents expected storyline; enough history (≥ 12 months).
- **Priority:** P0

---

## AI

### MVP-020 — LLM provider abstraction
- **Epic:** AI
- **User story:** As the platform, I can swap Azure OpenAI / other providers.
- **Technical approach:** `LLMProvider` interface; env-selected impl.
- **Dependencies:** MVP-001
- **Acceptance criteria:** No provider SDKs imported in orchestrator core.
- **Priority:** P0

### MVP-021 — Intent + planner
- **Epic:** AI
- **User story:** As a user, my question is mapped to metrics without free SQL.
- **Technical approach:** JSON-schema classifier + planner; heuristic backup.
- **Dependencies:** MVP-020, MVP-015
- **Acceptance criteria:** Golden questions Q02, Q10, Q15 select correct metrics; injection does not add tools.
- **Priority:** P0

### MVP-022 — Tool gateway
- **Epic:** AI
- **User story:** As security, the model can only call allow-listed tools with session tenant/company.
- **Technical approach:** Gateway ignores model-supplied tenantId.
- **Dependencies:** MVP-005, MVP-016
- **Acceptance criteria:** Tests: model cannot change company; invalid args 400.
- **Priority:** P0

### MVP-023 — Executive response + validation
- **Epic:** AI
- **User story:** As a CEO, I get business language that only uses engine numbers.
- **Technical approach:** Prompt v1; facts JSON; validator; repair once; templated fallback.
- **Dependencies:** MVP-021, MVP-022, MVP-017
- **Acceptance criteria:** Hallucinated number stripped; confidence labels present; ERP jargon avoided in eval snapshot.
- **Priority:** P0

### MVP-024 — Conversation memory
- **Epic:** AI
- **User story:** As a user, “what about profit?” keeps last month’s period.
- **Technical approach:** ConversationState on Conversation; planner pre-resolve.
- **Dependencies:** MVP-023
- **Acceptance criteria:** Follow-up test; UI shows inherited period.
- **Priority:** P0

### MVP-025 — Contextual follow-ups
- **Epic:** AI
- **User story:** As a CEO, I see relevant next questions.
- **Technical approach:** Derive from unused breakdowns and intent.
- **Dependencies:** MVP-023
- **Acceptance criteria:** After cash-down, follow-ups mention receivables/inventory, not generic “tell me more”.
- **Priority:** P0

---

## UI

### MVP-026 — Onboarding wizard
- **Epic:** UX
- **User story:** As an owner, I connect BC and reach first briefing/chat without ERP jargon.
- **Technical approach:** Steps in ux.md; demo skip path.
- **Dependencies:** MVP-009, MVP-010, MVP-019
- **Acceptance criteria:** Demo path completes without Entra BC; live path shows capability fail clearly.
- **Priority:** P0

### MVP-027 — Executive dashboard
- **Epic:** UX
- **User story:** As a CEO, I see pulse cards and a large ask box.
- **Technical approach:** Cards from metric engine; freshness; suggestions.
- **Dependencies:** MVP-015, MVP-026
- **Acceptance criteria:** Six cards; change vs comparison; empty/insufficient states honest.
- **Priority:** P0

### MVP-028 — Chat UI
- **Epic:** UX
- **User story:** As a CEO, I converse and drill into evidence.
- **Technical approach:** Streaming; action buttons; evidence drawer.
- **Dependencies:** MVP-023, MVP-017, MVP-027
- **Acceptance criteria:** Quality bar example for cash can be produced on demo data (numbers from seed, not the spec’s sample rupees unless seed matches).
- **Priority:** P0

### MVP-029 — Users and settings UI
- **Epic:** UX
- **User story:** As an owner, I manage roles, locale, and connections.
- **Dependencies:** MVP-005, MVP-008
- **Acceptance criteria:** Invite + role change audited.
- **Priority:** P0

---

## Intelligence (Phase 6)

### MVP-030 — Driver analysis
- **Epic:** Diagnostics
- **User story:** As a CEO, “why did margin fall?” names top contributors that foot to residual.
- **Technical approach:** Decomposition service; unexplained residual.
- **Dependencies:** MVP-016
- **Acceptance criteria:** Industrial-pumps-style fixture; no causation beyond drivers.
- **Priority:** P1

### MVP-031 — Collections ranking
- **Epic:** Collections
- **User story:** As a collections lead, I get “call these 10 first” with reasons.
- **Technical approach:** Score = overdue amount × days × value × utilization (documented).
- **Dependencies:** MVP-015
- **Acceptance criteria:** Ranking explanation visible; no “they won’t pay” inference.
- **Priority:** P1

### MVP-032 — Morning CEO briefing
- **Epic:** Briefing
- **User story:** As an owner, I receive pulse, what changed, ≤5 issues, ≤5 actions, questions to ask.
- **Technical approach:** Job + BriefingService; Executive module.
- **Dependencies:** MVP-023, MVP-030, MVP-031
- **Acceptance criteria:** Sections as product spec; generated after sync or on demand.
- **Priority:** P1

### MVP-033 — Prioritization and recommendations
- **Epic:** Recommendations
- **User story:** As an owner, I see issues ranked impact × urgency × confidence × controllability.
- **Technical approach:** Rule engine on metrics/alerts; recs tied to evidence; no fake ₹ impact unless calculated.
- **Dependencies:** MVP-032
- **Acceptance criteria:** Each rec has title, reason, expected impact (qualitative or calculated), urgency, confidence, function.
- **Priority:** P1

### MVP-034 — Alerts
- **Epic:** Alerts
- **User story:** As a CFO, I set thresholds (cash, overdue, margin, inventory, revenue decline, expenses, concentration).
- **Technical approach:** Alert definitions; evaluate after sync; in-app notifications; channel ports unused.
- **Dependencies:** MVP-015
- **Acceptance criteria:** Fire/clear logged; RBAC on alert metrics.
- **Priority:** P1

---

## Advanced (Phase 7)

### MVP-035 — Forecasts
- **Epic:** Forecast
- **User story:** As a CFO, I see a 60-day cash outlook from statistics + open invoices, not from the LLM.
- **Technical approach:** Simple trend/seasonality; assumptions listed.
- **Dependencies:** MVP-015
- **Acceptance criteria:** LLM cannot change forecast numbers; labelled forecast.
- **Priority:** P2

### MVP-036 — Scenario simulator
- **Epic:** Scenario
- **User story:** As a CEO, I ask “revenue -10%” and see actual vs assumption vs scenario.
- **Technical approach:** `runScenario` tool; UI separation.
- **Dependencies:** MVP-015
- **Acceptance criteria:** Actuals unchanged; hiring scenario uses stated cost assumption.
- **Priority:** P2

### MVP-037 — Business Health Score
- **Epic:** Health
- **User story:** As an owner, I see 0–100 with inspectable category weights.
- **Technical approach:** Documented rules; no hidden ML.
- **Dependencies:** MVP-015
- **Acceptance criteria:** Methodology screen matches calculation.
- **Priority:** P2

### MVP-038 — Anomaly detection
- **Epic:** Anomaly
- **User story:** As a CEO, I ask “what looks unusual?” and get threshold/statistical moves.
- **Technical approach:** Period-over-period z-score or % + min absolute materiality.
- **Dependencies:** MVP-015
- **Acceptance criteria:** Materiality floor avoids noise; journals flagged only with amounts + accounts (authorized).
- **Priority:** P2

### MVP-039 — Golden eval harness
- **Epic:** Quality
- **User story:** As the team, we run 50 executive questions continuously.
- **Technical approach:** JSON dataset + graders for metrics and forbidden claims.
- **Dependencies:** MVP-023, MVP-019
- **Acceptance criteria:** CI job on demo; report coverage.
- **Priority:** P0 (harness can start with subset; 50 by end of Phase 5)

---

## Explicitly not in MVP backlog

Write-back to BC, Teams/WhatsApp delivery, Fabric warehouse, document RAG as required path, multi-agent autonomous runtime, consolidation across companies.
