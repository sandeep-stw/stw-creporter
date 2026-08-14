# UX Specification

**Version:** 0.1.0  
**Feel:** premium, minimal, trustworthy, executive, calm, data-driven. Desktop-first; usable on tablet.

Avoid ERP-dense screens, rainbow palettes, and technical jargon (no “G/L 6110”, “OData”, “API v2”).

**Progressive disclosure:** summary first; details on demand.

---

## Visual direction

- Neutral surface, one accent (trust blue/ink)
- Typography: clear hierarchy; numbers tabular
- Status: semantic — healthy / watch / critical — not traffic-light overload
- Charts: few; used to support a sentence, not replace it
- Currency and period always visible in the header

---

## Global chrome

**Header:** company selector · period selector · comparison · “Data updated X ago” · profile

If sync is stale or failed, a calm banner: business language + “Retry sync” for admins. No stack traces.

---

## Screens

### 1. Login

Microsoft work account. Short value prop: “C-level answers from your Business Central data.” No feature grid.

### 2. Onboarding (wizard)

1. Create / join tenant  
2. Connect Microsoft account for Business Central  
3. Select environment (sandbox vs production — labelled clearly)  
4. Select company  
5. Validate API access (human list: customers, invoices, bank, etc. — pass/fail)  
6. Run synchronization (progress by entity, not raw URLs)  
7. Validate completeness (periods covered, missing ledgers)  
8. Generate first executive briefing  

Errors: “We could not read posted sales invoices. Your administrator may need to grant API access or install our Business Central extension.” + code for support, not a Node stack.

### 3. Business Central connection (settings)

List connections, environments, companies, last sync, next sync, capability matrix (standard vs extension). Disconnect. Never show tokens.

### 4. Company selection

If multiple companies: switcher. Cross-company consolidation is **out of MVP** unless explicitly scoped later.

### 5. Executive dashboard

**Hero:** “Ask your business anything” — large input.

Suggested questions: contextual from data (e.g. if overdue high, show collections question).

**Cards (6):** Revenue · Gross Margin · Profit · Cash · Receivables · Inventory  

Each: current value, change vs comparison, comparison label, status.

**What needs your attention** — max 5 issues (Phase 6; Phase 5 may be empty with “Connect and sync to see priorities”).

**Recommended actions** — max 5.

**Business trends** — 1–2 sparse charts (revenue and cash).

Tone: CEO briefing, not KPI wall.

### 6. Chat

Thread. Streaming status: “Checking receivables…” (tool names translated).

Answer blocks with optional buttons: Show receivables · Show inventory · Show calculation · Compare with last month.

Follow-ups as chips.

Scope chips: company, period, currency.

### 7. Answer evidence drawer

Claim → metric, period, current, previous, delta, sources, calculation notes, confidence.

Link to top contributing customers/items when present. Not a full BC page replica.

### 8. Alerts (Phase 6)

List in-app: threshold, current value, since when. Configure in settings. Extension points for Email / Teams / Slack / WhatsApp — disabled in MVP UI except “coming later”.

### 9. Settings

Profile, locale (en-IN default for INR display), timezone, briefing time.

### 10. Users & permissions

Invite, role, company access, sensitive G/L tags. Owner-only for connections.

---

## Empty / loading / error

| State | UX |
| --- | --- |
| No BC | CTA to onboarding |
| Syncing | Skeleton cards + “Preparing your books…” |
| Insufficient metric | Honest sentence, not 0 |
| Demo mode | Badge: Demonstration company |

---

## Accessibility

Visible focus, contrast, don’t rely on colour alone for status, chat input labelled.
