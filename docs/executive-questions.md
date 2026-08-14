# Top 50 C-Level Questions

These questions are the product contract for language, metrics, and evaluation. They are also the seed of the golden evaluation dataset (`tests/eval/golden-questions.json` in later implementation).

**Legend**

- **Intent:** classification used by the router
- **Phase:** earliest build phase that must answer it well
- **Primary metrics / tools:** deterministic layer, not LLM invention
- **Specialists:** conceptual contributors (orchestration may be a workflow, not separate processes)

---

## Question catalogue

| # | Question | Intent | Phase | Primary metrics / tools | Specialists |
| --- | --- | --- | --- | --- | --- |
| Q01 | How are we doing this month? | EXECUTIVE_SUMMARY | 5–6 | Pulse set | Executive |
| Q02 | What were sales last month? | DESCRIPTIVE | 5 | Revenue | Sales, CFO |
| Q03 | How do sales compare with last year? | COMPARATIVE | 5 | Revenue | Sales |
| Q04 | How is profit? | DESCRIPTIVE | 5 | GrossProfit, GrossMargin, OperatingProfit | CFO |
| Q05 | Why did profit fall this month? | DIAGNOSTIC | 6 | GrossProfit + drivers | CFO, Sales |
| Q06 | Why is gross margin lower than last quarter? | DIAGNOSTIC | 6 | GrossMargin + mix/price/cost | CFO, Sales |
| Q07 | Where are margins deteriorating? | RANKING / DIAGNOSTIC | 6 | Product/customer margin | CFO, Sales |
| Q08 | What are my biggest expenses? | RANKING | 6 | ExpenseBreakdown | CFO |
| Q09 | Why did expenses spike? | DIAGNOSTIC / ANOMALY | 6–7 | ExpenseGrowth + G/L | CFO |
| Q10 | How much cash do we have? | LOOKUP | 5 | CashBalance | CFO |
| Q11 | Why is my cash balance decreasing even though sales are growing? | DIAGNOSTIC | 6 | Cash, Revenue, AR, Inventory, AP | CFO, Inventory, Sales |
| Q12 | Why is cash lower? | DIAGNOSTIC | 6 | Cash bridge | CFO, Inventory |
| Q13 | Where can we improve cash flow? | PRESCRIPTIVE | 6 | WC, overdue, slow stock | CFO, Collections, Inventory |
| Q14 | Which three actions will have the biggest impact on cash this month? | PRESCRIPTIVE | 6 | Recommendations | Executive |
| Q15 | How much do customers owe us? | LOOKUP | 5 | AccountsReceivable | Collections |
| Q16 | Who owes us the most? | RANKING | 5 | Top customers by AR | Collections |
| Q17 | Which invoices are overdue? | RANKING / LOOKUP | 5 | OverdueReceivables | Collections |
| Q18 | Which overdue customers should my team call first? | PRESCRIPTIVE / RANKING | 6 | Collections score | Collections |
| Q19 | Which customers are affecting my cash flow? | DIAGNOSTIC | 6 | AR movement by customer | Collections, Sales |
| Q20 | Are receivables getting worse? | COMPARATIVE | 5–6 | AR, DSO, overdue | CFO, Collections |
| Q21 | How much do we owe vendors? | LOOKUP | 5 | AccountsPayable | CFO |
| Q22 | Which vendors are becoming more expensive? | DIAGNOSTIC | 6 | Purchase price vs prior | Inventory, CFO |
| Q23 | How much inventory do we have? | LOOKUP | 5 | InventoryValue | Inventory |
| Q24 | Is inventory too high? | DIAGNOSTIC | 6 | InventoryDays, policy/thresholds | Inventory |
| Q25 | Which inventory is not moving? | RANKING | 6 | SlowMovingInventory | Inventory |
| Q26 | Where is inventory getting stuck? | DIAGNOSTIC | 6 | Ageing, turns, coverage | Inventory |
| Q27 | Which products are making money but locking up too much working capital? | RANKING | 6 | ProductProfitability + inventory | Sales, Inventory |
| Q28 | Who are my most profitable customers? | RANKING | 6 | CustomerProfitability | Sales, CFO |
| Q29 | Which customers are growing? | RANKING | 6 | CustomerGrowth | Sales |
| Q30 | Which customers are declining? | RANKING | 6 | CustomerGrowth | Sales |
| Q31 | Which products make us the most money? | RANKING | 6 | ProductProfitability | Sales |
| Q32 | What should I focus on today? | PRESCRIPTIVE / EXECUTIVE_SUMMARY | 6 | Priority engine | Executive |
| Q33 | What should I focus on this week? | EXECUTIVE_SUMMARY | 6 | Briefing | Executive |
| Q34 | What is the biggest financial risk in my business right now? | PRESCRIPTIVE / ANOMALY | 6–7 | Risk ranking | Risk, CFO |
| Q35 | What should I be worried about? | ANOMALY / EXECUTIVE_SUMMARY | 6–7 | Alerts + concentration | Executive |
| Q36 | Give me a CEO summary for this week. | EXECUTIVE_SUMMARY | 6 | Briefing | Executive |
| Q37 | Give me a board-level summary for this month. | EXECUTIVE_SUMMARY | 6 | Briefing (board tone) | Executive |
| Q38 | What happened in the business yesterday? | DESCRIPTIVE / EXECUTIVE_SUMMARY | 6 | Daily movements | Executive |
| Q39 | Can we afford to hire five more people? | SCENARIO | 7 | Cash, OpEx, scenario | CFO, Forecast |
| Q40 | What would happen if revenue drops 10%? | SCENARIO | 7 | Scenario engine | CFO |
| Q41 | What would happen if customers pay 15 days later? | SCENARIO | 7 | DSO / cash scenario | CFO |
| Q42 | What if gross margin improves by 2 percentage points? | SCENARIO | 7 | Scenario | CFO |
| Q43 | What if DSO improves by 10 days? | SCENARIO | 7 | Cash conversion | CFO |
| Q44 | What if inventory decreases 15%? | SCENARIO | 7 | Inventory / cash | Inventory, CFO |
| Q45 | What will cash look like in 60 days? | PREDICTIVE | 7 | Cash forecast | Forecast, CFO |
| Q46 | What looks unusual? | ANOMALY | 7 | Anomaly service | Risk |
| Q47 | How do these compare with last month? | COMPARATIVE | 5 | Context metrics | Executive |
| Q48 | Why did Customer ABC’s average payment period increase? | DIAGNOSTIC / LOOKUP | 6 | Payment behaviour | Collections |
| Q49 | What is our working capital position? | DESCRIPTIVE | 5 | WorkingCapital, CCC | CFO |
| Q50 | Show me the business health score and why it moved. | DESCRIPTIVE / DIAGNOSTIC | 7 | Health score | Executive |

---

## Intent taxonomy

| Intent | Typical verbs | Engine behaviour |
| --- | --- | --- |
| DESCRIPTIVE | what, how much, how is | `getMetric` / pulse |
| COMPARATIVE | vs last month/year, better/worse | `compareMetric` |
| DIAGNOSTIC | why, caused, driven | `compareMetric` + `breakdownMetric` + drivers |
| PREDICTIVE | will, outlook, 60 days | forecast service (not LLM math) |
| PRESCRIPTIVE | should, focus, call first | recommendation engine on observed data |
| SCENARIO | what if, happen if | scenario engine; label assumptions |
| LOOKUP | how much does X owe | entity-filtered metric or ledger query |
| RANKING | which, top, most | top-N breakdowns |
| ANOMALY | unusual, worried | anomaly + thresholds |
| EXECUTIVE_SUMMARY | summary, briefing, how are we doing | briefing composer |

Follow-ups such as “what about profit?” inherit **company, period, comparison, and currency** from conversation state. The UI must still show that scope.

---

## Evaluation rules (all 50)

1. Numbers come only from the metric/query engine or are labelled insufficient.
2. Causal language requires driver evidence; otherwise use “associated with” or “insufficient evidence.”
3. Scenario answers must separate actuals vs assumptions vs calculated scenario.
4. Unauthorized G/L or payroll must be refused, not omitted silently as zero.
