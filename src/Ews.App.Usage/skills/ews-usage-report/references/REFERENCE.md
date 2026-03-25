# EWS Usage Report Reference

## EWS Status Classifications

| Status | Meaning | Action Required |
|--------|---------|----------------|
| `No EWS` | App does not have EWS permissions | None — already clean |
| `Active EWS` | App has EWS permissions AND recent sign-in activity | **High priority** — needs migration plan |
| `Inactive EWS` | App has EWS permissions but no recent sign-in activity | Consider removing EWS permissions |

## EWS Permission Detection

Apps are classified as EWS-using if they have either:

| Permission | Type | Identifier |
|------------|------|------------|
| `EWS.AccessAsUser.All` | Delegated | User-context EWS access |
| `full_access_as_app` | Application | App-only full mailbox access via EWS |

## Python Dependencies

| Package | Purpose |
|---------|---------|
| `pandas` | Data loading, merging, and analysis |
| `matplotlib` | Chart generation (donut chart) |
| `numpy` | Numerical support |

## Report Data Flow

```
EntraAppRegistrations.csv  ─┐
                             ├──► Merge ──► EWSUsage.csv
EWSEntraAppRegistrations.csv ┤
                             │
AppSignInActivity.csv  ──────┘
```

### Merge Logic

1. Load all Entra app registrations
2. Load apps identified as having EWS permissions
3. Load latest sign-in activity per app
4. Join on `AppId`
5. Compute:
   - `UsesEws` = app appears in EWS app registrations list
   - `LastSignIn` = most recent sign-in from activity data
   - `EwsStatus` = classification based on `UsesEws` and `LastSignIn` recency
   - `EntraLink` = URL to view the app in Entra portal

## EWSUsage.csv Schema

| Column | Type | Description |
|--------|------|-------------|
| `DisplayName` | string | App display name from Entra |
| `AppId` | GUID | Application (client) ID |
| `UsesEws` | boolean | Whether the app has EWS permissions |
| `LastSignIn` | datetime | Most recent sign-in timestamp |
| `EwsStatus` | string | `No EWS`, `Active EWS`, or `Inactive EWS` |
| `EntraLink` | URL | Direct link to app in Entra portal |

## Microsoft Documentation

- [Deprecation of EWS in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online)
- [Identify EWS-using applications](https://aka.ms/ewsIdentifyApps)
- [EWS Usage Reports](https://aka.ms/ewsAdminUsage)
