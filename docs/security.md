# Security and Multi-Tenancy

**Version:** 0.1.0

---

## 1. Threat model (MVP)

| Threat | Mitigation |
| --- | --- |
| Cross-tenant data read | Composite keys + mandatory tenant in queries + tests |
| Privilege escalation (sales → payroll) | RBAC + G/L sensitivity tags + metric permissions |
| Stolen BC refresh token | Encryption at rest, Key Vault, rotation, short-lived access tokens |
| Prompt injection → data exfil | Allow-listed tools; session-bound tenant; no SQL tool |
| LLM leakage of other companies | Company in server context; model never receives other companies’ facts |
| CSRF / session theft | Standard session cookies, expiry, HTTPS |
| Over-broad Entra consent | Least-privilege BC application permissions; document required scopes |
| Log leakage | Redact tokens, IBAN, full prompts with PII |

---

## 2. Isolation hierarchy

```text
Tenant
  Membership (User ↔ Role)
  BusinessCentralConnection
    Environment
      Company
        ERP facts, conversations, alerts
```

**Rules**

- Every table with business data has `tenantId`.
- Company-scoped tables have `companyId` and FK to Company in the same tenant.
- Authorization is server-side only.
- Front-end filters are UX, not security.

Prisma extension pattern (implementation): reject queries on tenant models without `tenantId` in `where` (allow-list of system jobs still pass tenant from job payload).

---

## 3. Roles (default)

| Role | Typical access |
| --- | --- |
| Owner | All companies, billing, connections, users |
| CEO | All operational metrics of assigned companies; not IdP/secret settings |
| CFO | Full financial metrics + G/L (except tagged secret accounts if any) |
| Finance Manager | P&L, AR, AP, cash; configurable G/L |
| Sales Manager | Sales, customers, AR for *their* customers if salesperson filter set; no payroll G/L |
| Operations Manager | Inventory, purchases, orders |
| Read Only | Assigned metrics, no settings, no export of full ledgers (configurable) |

Permissions are **additive grants** on: companies, metrics, G/L account tags (`payroll`, `management`, `standard`), tools (`getExpenseBreakdown`).

Denied data is an authorization error, not a zero.

---

## 4. Authentication

- Application: Microsoft Entra ID (work accounts) first; session expiry configurable (default 8 hours idle / 24 hours absolute for MVP).
- BC: OAuth 2.0 confidential client; tokens in encrypted columns or secret store; never in browser.
- Future: other OIDC providers without changing tenant model.

Entra registration (BCM-010) is documented in [entra-app.md](./entra-app.md). Required least-privilege scopes:

| API | Type | Permission |
| --- | --- | --- |
| Microsoft Graph | Delegated | `openid`, `profile`, `email`, `offline_access`, `User.Read` |
| Dynamics 365 Business Central | Delegated | `Financials.ReadWrite.All` |
| Dynamics 365 Business Central | Application | `API.ReadWrite.All`, `Automation.ReadWrite.All` |

Do not assign the Business Central `SUPER` permission set to the Entra application. Use `D365 AUTOMATION` plus a financial read set such as `D365 BUS FULL ACCESS`, then tighten per customer.

---

## 5. Encryption

- In transit: TLS 1.2+
- At rest: PostgreSQL disk encryption + application encryption for OAuth secrets (`ENCRYPTION_KEY` in Key Vault)
- No secrets in git, client bundles, or prompts

---

## 6. API validation

- Authn required
- CSRF for cookie sessions
- Rate limit per user and per tenant
- Zod validation on all tool and HTTP inputs
- Maximum question length; content-type checks

---

## 7. Audit logs

Admin: user invite, role change, connection create/delete, company access change.

AI: see [ai-system.md](./ai-system.md) AnalysisRun.

Retention: configurable; default 1 year for AI audit in MVP design.

---

## 8. Data leakage protection

- Facts JSON includes only authorized metrics
- Demo vs production labelled in UI
- Export of evidence respects same RBAC
- Prompt traces stored redacted

---

## 9. Secure development

- Dependency scanning in CI (later milestone)
- No eval of model-generated code
- Sync workers use least DB role (DML on canonical tables only)
