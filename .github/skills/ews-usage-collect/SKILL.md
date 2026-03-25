---
name: ews-usage-collect
description: "Collect EWS application usage data from a Microsoft 365 tenant. Queries Microsoft Graph for app registrations, EWS permissions, and sign-in activity. Produces timestamped CSV files for analysis. Use this skill after app registration setup is complete and credentials are configured."
license: MIT
compatibility: "Requires PowerShell 7+, configured environment variables (EWS_USAGE_TENANT_ID, EWS_USAGE_AUDIT_APP_ID, EWS_USAGE_AUDIT_APP_SECRET)."
metadata:
  stage: "01"
  category: "ews-app-usage"
  prerequisites: "ews-usage-setup"
---

# Skill: Collect EWS Usage Data

## Purpose

You are an AI assistant that helps Microsoft 365 tenant administrators collect EWS application usage data from their tenant. You guide them through running the data collection process, which queries Microsoft Graph to identify all app registrations with EWS permissions and their recent sign-in activity.

## Context

This is Step 01 of the EWS App Usage workflow. The app registration and credentials must already be configured (Step 00). This step produces the raw CSV data that the reporting step (Step 02) will merge and analyze.

## What You Do

### Pre-Flight Checks

Before starting data collection, verify:

1. **Environment variables are set:**
   ```powershell
   if (-not $env:EWS_USAGE_TENANT_ID) { Write-Warning "EWS_USAGE_TENANT_ID not set" }
   if (-not $env:EWS_USAGE_AUDIT_APP_ID) { Write-Warning "EWS_USAGE_AUDIT_APP_ID not set" }
   if (-not $env:EWS_USAGE_AUDIT_APP_SECRET) { Write-Warning "EWS_USAGE_AUDIT_APP_SECRET not set" }
   ```
   If any are missing → redirect to `ews-usage-setup` skill.

2. **Output directory exists:**
   Check `appSettings.json` for `OutputPath` (default: `.\Usage-Data`). Create it if needed.

3. **Working directory:**
   The scripts expect to be run from `src/Ews.App.Usage/`.

### Option A: Run via Notebook (Recommended for VS Code)

Guide the admin through running the `Collect-EWS-App-Usage.ipynb` notebook:

1. Open `Collect-EWS-App-Usage.ipynb` in VS Code
2. Run all cells in order
3. The notebook will:
   - Import the `EwsUtilities` module
   - Load configuration from `appSettings.json`
   - Call `Find-EwsUsage.ps1 -Operation GetEwsActivity`
   - Save output CSVs to the configured output path

### Option B: Run via PowerShell Directly

For command-line execution:

```powershell
# Navigate to the Ews.App.Usage directory
cd src/Ews.App.Usage

# Import the utilities module
Import-Module ./Modules/EwsUtilities.psm1

# Load configuration
$config = Get-Config
$outputPath = if ($config.OutputPath) { $config.OutputPath } else { ".\Usage-Data" }

# Create output directory if needed
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath }

# Run the data collection
./Scripts/Find-EwsUsage.ps1 `
    -OutputPath $outputPath `
    -OAuthClientId $env:EWS_USAGE_AUDIT_APP_ID `
    -OAuthTenantId $env:EWS_USAGE_TENANT_ID `
    -OAuthClientSecret $env:EWS_USAGE_AUDIT_APP_SECRET `
    -Operation GetEwsActivity
```

### What the Script Collects

The `Find-EwsUsage.ps1` script with `-Operation GetEwsActivity` performs these queries:

1. **Entra App Registrations** — All registered applications in the tenant
   - Output: `EntraAppRegistrations-<timestamp>.csv`

2. **Entra Service Principals** — Service principals for each application
   - Output: `EntraServicePrincipals-<timestamp>.csv`

3. **EWS App Registrations** — Apps with EWS permissions (`EWS.AccessAsUser.All` delegated or `full_access_as_app` application)
   - Output: `EWSEntraAppRegistrations-<timestamp>.csv`

4. **Sign-In Activity** — Recent sign-in events for EWS-enabled apps
   - Output: `AppSignInActivity-<timestamp>.csv`

### Post-Collection Validation

After the script completes, verify the output:

```powershell
$outputPath = ".\Usage-Data"
$files = Get-ChildItem -Path $outputPath -Filter "*.csv" | Sort-Object LastWriteTime -Descending
$files | Select-Object Name, Length, LastWriteTime | Format-Table
```

Expected: At least 3-4 new timestamped CSV files. If the tenant has no EWS apps, the `EWSEntraAppRegistrations` file may be empty or contain only headers.

### Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid credentials | Verify env vars, check secret hasn't expired |
| 403 Forbidden | Missing permissions | Verify admin consent was granted for both permissions |
| Empty results | No apps in tenant | Normal for new/small tenants — the report will show "No EWS" for all apps |
| Timeout errors | Large tenant | The script handles pagination; retry on transient failures |
| Certificate errors | Proxy/firewall | Check network connectivity to `login.microsoftonline.com` and `graph.microsoft.com` |

## Acceptance Criteria

- [ ] Data collection script ran without errors
- [ ] `EntraAppRegistrations-<timestamp>.csv` exists in output folder
- [ ] `EWSEntraAppRegistrations-<timestamp>.csv` exists in output folder
- [ ] `AppSignInActivity-<timestamp>.csv` exists in output folder
- [ ] CSV files contain data (not just headers)

## Human Checkpoint

Before proceeding to report generation, confirm:

1. **"Did the data collection complete without errors?"**
   - If no: review error messages and troubleshoot
2. **"Do the CSV files contain the expected data?"**
   - If empty: verify permissions, check if there are actually EWS apps in the tenant
3. **"Ready to generate the usage report?"**
   - Options: [✅ Proceed to reporting] [🔄 Re-run collection] [⏸️ Pause]

Do NOT proceed to the next skill without explicit human approval.

## Next Skill

Upon approval → **Step 02: Generate Reports** (`ews-usage-report`)
