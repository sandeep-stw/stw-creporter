# BCM-010 — Configure Microsoft Entra application

This is the Entra registration for the Executive Intelligence Agent: **user sign-in** (Auth.js) and **Business Central API access** (confidential client). Declarative settings: [`config/entra-app.json`](../config/entra-app.json).

Do not put client secrets in git. Copy values into the local gitignored `.env`.

## 1. Create app registration

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com).
2. Go to **App registrations** → **New registration**.
3. Name: `Executive Intelligence Agent` (or `displayName` in `entra-app.json`).
4. Supported account types: **Accounts in any organizational directory** (multitenant work accounts). Personal Microsoft accounts are not in scope.
5. Redirect URI (Web):
   - `http://localhost:3000/api/auth/callback/microsoft-entra-id` (local Auth.js)
   - Production: `https://<your-host>/api/auth/callback/microsoft-entra-id`
   - Optional for BC consent from the web client: `https://businesscentral.dynamics.com/OAuthLanding.htm`
6. Register and copy:
   - **Application (client) ID** → `AUTH_MICROSOFT_ENTRA_ID_ID` and `BC_CLIENT_ID`
   - **Directory (tenant) ID** → `ENTRA_TENANT_ID` (home tenant of the app)

Set **implicit grant** off. Use the **Web** platform (authorization code + client secret), not SPA.

## 2. Configure Business Central access

1. Open the app → **API permissions** → **Add a permission**.
2. **Microsoft APIs** → **Dynamics 365 Business Central**.
3. **Application permissions** (service / sync workers):
   - `API.ReadWrite.All` — APIs and web services
   - `Automation.ReadWrite.All` — automation APIs
4. **Delegated permissions** (owner connects their BC tenant):
   - `Financials.ReadWrite.All` — access as the signed-in user
5. Add **Microsoft Graph** delegated permissions used by Auth.js:
   - `openid`, `profile`, `email`, `offline_access`, `User.Read`
6. **Grant admin consent** in the home tenant for application permissions. Customer tenants still consent on first connect.

Resource app ID (Dynamics 365 Business Central): `996def3d-b36c-4153-8607-a6fd3c01b89f`.

## 3. Create client credential

1. **Certificates & secrets** → **New client secret**.
2. Description: `executive-intelligence-agent`.
3. Expiry: 24 months (or `clientSecret.defaultValidityMonths`).
4. Copy the secret **Value** immediately → `AUTH_MICROSOFT_ENTRA_ID_SECRET` and `BC_CLIENT_SECRET`.
5. Store only in `.env` or a secret vault. Never log it.

## 4. Assign required Business Central permissions

Entra API permissions are not enough for S2S. In each Business Central environment:

1. Search **Microsoft Entra Applications**.
2. **New** → **Client ID** = Application (client) ID.
3. Description: `Executive Intelligence Agent`.
4. **State** = **Enabled**.
5. Assign permission sets (**not** `SUPER`):
   - `D365 AUTOMATION`
   - `D365 BUS FULL ACCESS` (read financials for metrics; tighten per customer later)
6. If admin consent was not granted in Entra, use **Grant Consent** on the card (needs the BC redirect URI above).

For delegated onboarding, the owner signs in and consents `Financials.ReadWrite.All`; tokens stay on the server (MVP-008).

## 5. Wire local environment

```bash
cp .env.example .env
```

| Variable | Source |
| --- | --- |
| `AUTH_SECRET` | Generated locally |
| `AUTH_URL` | App origin |
| `AUTH_MICROSOFT_ENTRA_ID_ID` | Application (client) ID |
| `AUTH_MICROSOFT_ENTRA_ID_SECRET` | Client secret value |
| `AUTH_MICROSOFT_ENTRA_ID_ISSUER` | `https://login.microsoftonline.com/organizations/v2.0` for multi-tenant |
| `BC_CLIENT_ID` | Same client ID |
| `BC_CLIENT_SECRET` | Same secret |
| `BC_TOKEN_SCOPE` | `https://api.businesscentral.dynamics.com/.default` |

## Automation

Validate config without Azure:

```powershell
pwsh -File scripts/Register-EntraApp.ps1 -ValidateOnly
python3 tests/entra_app_config_test.py
```

Create or update the app registration (Azure CLI):

```powershell
az login --allow-no-subscriptions
pwsh -File scripts/Register-EntraApp.ps1 -GrantAdminConsent
```

Re-runs update permissions and do not rotate the secret unless you pass `-RotateSecret`.

## References

- [Register an Entra app](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
- [BC S2S authentication](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/automation-apis-using-s2s-authentication)
- [Auth.js Microsoft Entra ID](https://authjs.dev/getting-started/providers/microsoft-entra-id)
