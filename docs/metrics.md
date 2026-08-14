# Metric Catalogue (MVP and near-MVP)

**Version:** 0.1.0  
**Engine rules:** decimal arithmetic only; one primary date field; one reporting currency (default LCY); never silently substitute.

Each metric has: `metric_id`, name, description, formula, required_data, dimensions, periods, interpretation, warnings, source fields, edge cases, tests.

---

## Shared conventions

**Period types:** `day`, `week`, `month`, `quarter`, `year`, `custom`, `as_of` (stock metrics).

**Stock vs flow**

- Flow (Revenue): sum over posting dates in range.
- Stock (Cash, AR): as-of period end, not summed across days.

**Comparison:** previous period of equal length; previous year same dates — specified in `PeriodSpec`.

**Confidence labels on results:** `confirmed_erp` | `calculated_erp` | `inferred` | `scenario` | `insufficient`.

---

## MVP metrics

### M01 — Revenue

| Field | Definition |
| --- | --- |
| metric_id | `revenue` |
| name | Revenue |
| description | Sales recognized in the period, in reporting currency |
| formula | Sum of posted sales invoice line amounts (excluding pure tax if identifiable) + mapped G/L sales accounts if invoice lines incomplete. Credit memos reduce revenue. |
| required_data | SalesInvoice + Lines **or** GLEntry with revenue account map |
| dimensions | customer, item, salesperson, period |
| date | `postingDate` |
| currency | Sum `amountLcy` |
| interpretation | Top-line demand that hit the books — not orders, not collections |
| warnings | Prepayments, unposted invoices, and job WIP may be excluded |
| edge cases | Credit memos; multi-currency; cancelled invoices; sales of FA if mixed in sales docs |
| tests | Two invoices + one credit memo in month; prior month comparison; FX invoice uses LCY |

**Limitation:** If only G/L is available, revenue follows mapped accounts. If neither complete, `insufficient`.

---

### M02 — Gross Profit

| Field | Definition |
| --- | --- |
| metric_id | `gross_profit` |
| formula | Revenue − COGS |
| COGS preferred | Sum of value entries (cost amounts) for sales in period |
| COGS fallback | Σ line (qty × unitCost) labelled medium confidence |
| required_data | Revenue sources + ValueEntry or item costs |
| date | posting date of related sales / value entries |
| interpretation | Money left after product/service delivery cost |
| edge cases | Negative stock; average vs FIFO cost; services with no cost |
| tests | Known COGS fixture; fallback vs preferred divergence flagged |

---

### M03 — Gross Margin

| Field | Definition |
| --- | --- |
| metric_id | `gross_margin` |
| formula | GrossProfit / Revenue × 100 (percentage, still decimal) |
| required_data | M01, M02 |
| warnings | Undefined if Revenue = 0 — return `unavailable`, do not show 0% |
| tests | Zero revenue; 25% fixture |

---

### M04 — Operating Profit

| Field | Definition |
| --- | --- |
| metric_id | `operating_profit` |
| formula | Mapped income statement: GrossProfit − operating expenses (ex-financing/tax if map says so) |
| required_data | GLAccount map (`AccountMap` per company) + GLEntry |
| interpretation | Operating result **only if** the company has a validated map |
| warnings | Without map, metric is unavailable. Never infer from account numbers. |
| tests | Mapped P&L fixture; unmapped company returns insufficient |

---

### M05 — Cash Balance

| Field | Definition |
| --- | --- |
| metric_id | `cash_balance` |
| formula | Sum of bank account balances in LCY as of date (plus cash accounts if mapped) |
| required_data | BankAccount balances and/or G/L cash & bank map |
| date | `as_of` |
| interpretation | Liquidity in bank/cash accounts — not undrawn facilities |
| edge cases | Uncleared cheques; bank rec lag; multiple banks / currencies |
| tests | Two banks; FX bank uses LCY |

---

### M06 — Accounts Receivable

| Field | Definition |
| --- | --- |
| metric_id | `accounts_receivable` |
| formula | Sum of open customer ledger remaining amounts (positive = owed to us) as of date |
| required_data | CustomerLedgerEntry remaining |
| fallback | Unpaid posted sales invoices − applications if applications exist |
| date | `as_of` using remaining open at that date (not invoice date sum) |
| interpretation | Customer credit outstanding |
| tests | Invoice + payment application; credit memo; overdue subset |

---

### M07 — Accounts Payable

| Field | Definition |
| --- | --- |
| metric_id | `accounts_payable` |
| formula | Sum of open vendor ledger remaining as of date |
| required_data | VendorLedgerEntry |
| date | `as_of` |
| tests | Invoice + payment; debit memo |

---

### M08 — Inventory Value

| Field | Definition |
| --- | --- |
| metric_id | `inventory_value` |
| formula | On-hand value as of date from item/value entries or item inventory × cost |
| required_data | ItemLedger + ValueEntry preferred; else items inventory fields |
| date | `as_of` |
| interpretation | Cash tied in stock at costing value — not retail |
| warnings | Drop-ship, wip, and non-inventory items excluded when identifiable |
| tests | Receipt + shipment; zero stock |

---

### M09 — Working Capital

| Field | Definition |
| --- | --- |
| metric_id | `working_capital` |
| formula | AccountsReceivable + InventoryValue − AccountsPayable |
| required_data | M06, M07, M08 |
| date | `as_of` |
| interpretation | Operating capital tied in the cycle (simplified; excludes other current items) |
| warnings | Not a full balance-sheet current assets − current liabilities |
| tests | Identity of components |

---

### M10 — DSO

| Field | Definition |
| --- | --- |
| metric_id | `dso` |
| name | Days Sales Outstanding |
| formula | AccountsReceivable / CreditSales × NumberOfDays |
| CreditSales | Revenue in the lookback window (default 90 days), credit sales if flag exists else all posted sales |
| NumberOfDays | Length of lookback window |
| required_data | M06 + M01 |
| interpretation | Average days to collect **if** sales mix is comparable |
| limitations | Cash sales inflate/deflate; large one-off invoices distort; not customer-level without breakdown |
| tests | Steady AR and sales; zero sales → unavailable |

---

### M11 — DPO

| Field | Definition |
| --- | --- |
| metric_id | `dpo` |
| formula | AccountsPayable / CreditPurchases × NumberOfDays |
| CreditPurchases | Posted purchase invoice totals in lookback (mapped COGS/purchases if needed) |
| limitations | Services vs goods mix; unposted receipts |
| tests | Analogous to DSO |

---

## Near-MVP metrics (Phase 6–7; define now, implement when data exists)

| metric_id | Formula (short) | Notes |
| --- | --- | --- |
| `ebitda` | Operating profit + mapped depreciation/amortization | Needs account map |
| `net_profit` | Mapped net income | Needs account map |
| `current_ratio` | Current assets / current liabilities | Needs BS map |
| `quick_ratio` | (Current assets − inventory) / current liabilities | Needs BS map |
| `inventory_days` | Inventory / COGS × days | Stock / flow mix |
| `cash_conversion_cycle` | DSO + InventoryDays − DPO | Compound limitations |
| `customer_concentration` | Top N customers revenue / total revenue | Ranking |
| `customer_growth` | Period revenue vs prior for customer | Needs two periods |
| `customer_profitability` | Revenue − COGS − attributed discounts (not full ABC) | Value entries |
| `product_profitability` | Same by item | Value entries |
| `inventory_turnover` | COGS / average inventory | |
| `slow_moving_inventory` | No issue in N days and qty/value remaining | Needs ILE |
| `overdue_receivables` | Remaining where dueDate < as_of and open | Ledger |
| `average_collection_period` | Customer-level payment delay | Needs applications |
| `expense_growth` | OpEx period vs prior | Needs map or G/L categories |
| `budget_variance` | Actual − budget | Needs budgets |
| `revenue_growth` | Period vs compare | Derived from M01 |

---

## Driver analysis (Phase 6)

For Δ Gross Profit, decompose where data allows:

- volume, price, mix, discount, cost (and optionally FX)

Present top contributors by dimension (item, customer, salesperson). Contribution must add (within rounding of 0.01 in LCY) or show an **unexplained residual**.

---

## Test cases (engine-wide)

1. Do not add INR and USD amounts.
2. Credit memo reverses revenue.
3. As-of AR ignores invoices posted after as-of.
4. Overdue uses dueDate, not postingDate.
5. Margin with 0 revenue is unavailable.
6. Unmapped operating profit is unavailable.
7. Demo seed reproduces golden values in `tests/metrics/golden-demo.json` (to be added with seed).
