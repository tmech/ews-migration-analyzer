# EWS App Usage Orchestrator Reference

## Workflow Overview

```
Step 00: Setup          → App registration + env vars
Step 01: Collect        → CSV data from Graph API
Step 02: Report         → Merged EWSUsage.csv + charts
Step 03: View Results   → Excel / Power BI / Admin Center
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `EWS_USAGE_TENANT_ID` | Azure AD / Entra tenant ID |
| `EWS_USAGE_AUDIT_APP_ID` | App registration client ID |
| `EWS_USAGE_AUDIT_APP_SECRET` | App registration client secret |

## Required Graph API Permissions (Application)

| Permission | Purpose |
|------------|---------|
| `Application.Read.All` | Read all Entra app registrations |
| `AuditLog.Read.All` | Read sign-in activity logs |

## Key Files

| File | Purpose |
|------|---------|
| `appSettings.json` | Non-secret configuration (OutputPath) |
| `Scripts/New-EwsUsageAuditApp.ps1` | Automated app registration setup |
| `Scripts/Find-EwsUsage.ps1` | Main data collection script |
| `Collect-EWS-App-Usage.ipynb` | Data collection notebook |
| `Report-EWS-App-Usage.ipynb` | Report generation notebook |
| `Usage-Data/*.csv` | Raw collected data |
| `Usage-Data/EWSUsage.csv` | Merged report output |
| `EWS-Usage.xlsx` | Excel workbook for analysis |
| `EWS-Usage.pbix` | Power BI report |

## Azure Cloud Variants

The tools support these cloud environments:

| Cloud | Value |
|-------|-------|
| Worldwide (Commercial) | `Global` |
| US Government L4 (GCC High) | `USGovernmentL4` |
| US Government L5 (DoD) | `USGovernmentL5` |
| China (21Vianet) | `ChinaCloud` |

## Microsoft Documentation

- [Deprecation of EWS in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online)
- [Identify EWS-using applications](https://aka.ms/ewsIdentifyApps)
- [EWS Usage Reports in M365 Admin Center](https://aka.ms/ewsAdminUsage)
- [EWS Migration Tools](https://aka.ms/ewsTools)
- [Midnight Blizzard Security Incident](https://aka.ms/mblizz)
