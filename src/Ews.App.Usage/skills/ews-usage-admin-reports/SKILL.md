---
name: ews-usage-admin-reports
description: "Open the EWS Weekly Usage reports in the Microsoft 365 Admin Center. Launches the browser to the EWS usage reports page where tenant admins can view weekly EWS usage by application directly from Microsoft. No local data collection required. Use this skill for a quick view of EWS usage or when working with worldwide cloud tenants."
license: MIT
compatibility: "Requires a web browser and Microsoft 365 tenant admin credentials. Only available for worldwide (commercial) cloud tenants."
metadata:
  stage: "03c"
  category: "ews-app-usage"
  prerequisites: "none"
---

# Skill: Open M365 Admin Center EWS Reports

## Purpose

You are an AI assistant that helps Microsoft 365 tenant administrators access the built-in EWS Weekly Usage reports in the Microsoft 365 Admin Center. This provides a quick, no-setup view of EWS usage patterns directly from Microsoft's reporting infrastructure.

## Context

This is Step 03c of the EWS App Usage workflow, but it can also be used independently — it does NOT require prior data collection steps. The M365 Admin Center reports are maintained by Microsoft and show EWS usage data without any local setup. However, they are only available for **worldwide (commercial) cloud tenants** — government and sovereign cloud tenants should use the local data collection tools instead.

## What You Do

### Step 1: Open the Admin Center Reports

```powershell
Start-Process "https://admin.cloud.microsoft/?source=applauncher#/reportsUsage/EWSWeeklyUsage"
```

This opens the default web browser to the EWS Weekly Usage reports page.

### Step 2: Explain What the Reports Show

The M365 Admin Center EWS Usage Reports provide:

- **Weekly EWS usage by application** — which apps are making EWS calls
- **Usage trends over time** — whether EWS usage is increasing or decreasing
- **Application identification** — app names and IDs making EWS calls
- **Call volume** — relative usage levels per application

### Step 3: Cloud Availability Check

**Before opening**, confirm the tenant's cloud environment:

> **"Which Microsoft 365 cloud environment is your tenant in?"**
> - [🌍 Worldwide / Commercial] → Reports are available, proceed
> - [🇺🇸 US Government (GCC / GCC High / DoD)] → Reports NOT available, use local tools
> - [🇨🇳 China (21Vianet)] → Reports NOT available, use local tools
> - [❓ Not sure] → Try the link; if it doesn't work, use local tools

**If the tenant is NOT in the worldwide cloud:**
- Inform the admin that these reports are only available for worldwide cloud tenants
- Redirect to the local data collection workflow:
  1. `ews-usage-setup` → set up app registration
  2. `ews-usage-collect` → collect data via Graph API
  3. `ews-usage-report` → generate local reports
- The local tools support all cloud environments (Global, USGovernmentL4, USGovernmentL5, ChinaCloud)

### Step 4: Post-Launch Guidance

After opening the Admin Center, advise the admin:

1. **Sign in** — Use tenant admin credentials if prompted
2. **Review the report** — Note which applications show EWS activity
3. **Export data** — The Admin Center allows exporting report data for further analysis
4. **Compare with local data** — If you've also run the local collection tools, compare results for completeness
5. **Bookmark the page** — For ongoing monitoring as you plan migrations

### Relationship to Local Reports

| Feature | Admin Center Reports | Local Tools |
|---------|---------------------|-------------|
| Setup required | None | App registration + credentials |
| Cloud support | Worldwide only | All clouds |
| Data granularity | Weekly summaries | Detailed per-app data |
| EWS permission detection | Based on call activity | Based on Entra permissions + activity |
| Customization | Limited | Full — raw CSV data |
| Offline access | No | Yes — local CSV/Excel/Power BI |
| Historical data | Limited retention | You control retention |

**Recommendation**: Use Admin Center reports for a quick overview, and local tools for detailed migration planning.

## Error Handling

| Issue | Solution |
|-------|----------|
| Page not loading | Check internet connectivity and admin credentials |
| Access denied | Verify the user has M365 admin or reports reader role |
| Reports not available | Tenant may be in a government/sovereign cloud — use local tools |
| Browser not opening | Manually navigate to the URL in any browser |
| Data looks incomplete | Admin Center reports may have different coverage than local tools — run both for completeness |

## Acceptance Criteria

- [ ] Browser opens to the EWS Weekly Usage reports page
- [ ] Admin can sign in and view the reports
- [ ] Report shows EWS usage data (or confirms no EWS usage)

## Admin Center URL

```
https://admin.cloud.microsoft/?source=applauncher#/reportsUsage/EWSWeeklyUsage
```
