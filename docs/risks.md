# Risks and Mitigations

**Version:** 0.1.0

| ID | Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- | --- |
| R01 | Standard BC APIs lack customer/vendor/item ledger remaining amounts | AR/AP/DSO/overdue wrong or empty | High | Capability probe; AL extension pack; labelled invoice fallback; never silent zero |
| R02 | LLM invents amounts or causes | Loss of CFO trust; legal risk | High | Facts JSON + validator; templated fallback; eval harness; no SQL tool |
| R03 | JavaScript number / SQL float in money path | Silent rupee errors | Medium | Decimal everywhere; CI tests; lint policy |
| R04 | Cross-tenant leak | Severe | Medium | tenantId on rows; query guard; automated tests |
| R05 | Sales role sees payroll | Compliance / HR | Medium | G/L tags + metric grants; denied ≠ 0 |
| R06 | OAuth token leakage | Tenant BC takeover | Medium | Encrypt at rest; never log; Key Vault; no tokens to browser |
| R07 | API throttling / incomplete sync | Stale or partial answers | High | Cursors, backoff, completeness, freshness UI, insufficient when coverage gaps |
| R08 | Custom fields / schema drift per customer | Brittle core | High | Adapter maps; extras JSON; never hard-code one chart of accounts |
| R09 | G/L sign and credit memo conventions misunderstood | Inverted P&L/AR | High | Fixture tests from real BC samples; mapper unit tests |
| R10 | Mixing postingDate and dueDate | False overdue / wrong revenue | High | Metric date field mandatory; tests |
| R11 | Mixing currencies | Nonsense totals | Medium | LCY-only aggregates; refuse mixed add |
| R12 | Operating profit guessed from account numbers | Wrong P&L | High | Require AccountMap; else unavailable |
| R13 | Correlation stated as causation | Bad decisions | High | Driver residual; inference labels; eval forbidden phrases |
| R14 | Demo numbers used in live tenant | Catastrophic trust | Low | `source` flag; UI badge; environment checks |
| R15 | Prompt injection exfiltrates tools | Data leak | Medium | Allow list; ignore instructions in data; session-bound ids |
| R16 | Sync too slow for “this morning” | Product feel broken | Medium | Incremental; snapshots; async briefing |
| R17 | Scope creep (Fabric, WhatsApp, write-back) | MVP never ships | High | Phased backlog; this risk log |
| R18 | Multi-agent complexity | Unreliable answers | Medium | Single orchestrator + specialist prompts |
| R19 | Fiscal calendar ≠ calendar month | Wrong “this month” | Medium | FiscalPeriod when available; disclose assumption |
| R20 | Cost of LLM on long ledgers | Margin | Medium | Tools return aggregates not raw dumps; cache |
| R21 | Entra/BC admin consent blocked at customer | Cannot onboard | Medium | Clear wizard errors; partner-led consent runbook |
| R22 | Inventory value without value entries | Bad stock cash | Medium | Degrade + label; prefer value entries via extension |
| R23 | India display (lakh/crore) vs storage | Rounding confusion | Low | Display layer only; store major units decimal |
| R24 | Alert noise | Users ignore system | Medium | Materiality floors; max 5 issues |
| R25 | Forecast treated as fact | Bad hiring/cash decisions | Medium | Labels; separate scenario objects |

---

## Architecture decisions that reduce risk

1. **Semantic layer** so the model never sees raw BC as the source of truth.
2. **Connector capability matrix** instead of pretending every tenant has every API.
3. **Evidence validation** as a hard gate before the user sees creative prose with numbers.
4. **Demo seed** so development and eval do not depend on a live tenant.
5. **Phase gates** so chat UI is not built on untested money math.
