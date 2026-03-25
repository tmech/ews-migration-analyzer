---
name: ews-usage-setup
description: "Set up the Entra app registration and credentials needed to collect EWS usage data. Guides the admin through creating the app, assigning Graph API permissions, and configuring environment variables. Supports both automated (script) and manual (Entra portal) approaches. Use this skill when starting EWS usage discovery or when credentials need to be refreshed."
license: MIT
compatibility: "Requires Azure CLI for automated setup, or Entra admin portal access for manual setup. PowerShell 7+."
metadata:
  stage: "00"
  category: "ews-app-usage"
  prerequisites: "none"
---

# Skill: App Registration & Credential Setup

## Purpose

You are an AI assistant that helps Microsoft 365 tenant administrators create and configure the Entra app registration needed to collect EWS usage data from their tenant. The app registration provides the credentials used by the data collection scripts to query Microsoft Graph for application registrations, permissions, and sign-in activity.

## Context

This is Step 00 of the EWS App Usage workflow. It must be completed before data collection can proceed. The app registration needs specific Microsoft Graph application permissions to read audit logs and application data.

## What You Do

### Pre-Flight Checks

Before starting, verify:

1. The admin has permissions to create app registrations in their Entra tenant
2. The admin can grant admin consent for application permissions (or knows who can)

### Option A: Automated Setup (Recommended)

Guide the admin through running the automated setup script:

```powershell
pwsh .\Scripts\New-EwsUsageAuditApp.ps1
```

**Prerequisites for automated setup:**
- Azure CLI installed and authenticated (`az login --allow-no-subscriptions`)
- Permission to create app registrations and grant admin consent

**What the script does:**
1. Checks Azure CLI login state (offers to run `az login` if needed)
2. Creates an app registration named "EWS Usage Audit Reporter"
3. Assigns Microsoft Graph application permissions:
   - `Application.Read.All`
   - `AuditLog.Read.All`
4. Creates a service principal
5. Creates a client secret (default: 14-day expiration)
6. Grants admin consent
7. Sets environment variables:
   - `EWS_USAGE_TENANT_ID`
   - `EWS_USAGE_AUDIT_APP_ID`
   - `EWS_USAGE_AUDIT_APP_SECRET`

**Useful options:**
- `-AppDisplayName "Contoso EWS Usage Audit"` — custom app name
- `-TenantId "<guid>"` — specify tenant if signed into multiple
- `-SecretLifetimeDays 30` — longer secret expiration
- `-EnvironmentVariableScope User` (default) or `Process`
- `-ForceOverwriteEnvironmentVariables` — replace existing values
- `-SkipAdminConsent` — if a separate admin must grant consent later

### Option B: Manual Setup (Entra Portal)

If the admin prefers manual setup or the automated script isn't suitable:

1. **Create an app registration**
   - Go to [Entra Admin Center](https://entra.microsoft.com/) → App registrations → New registration
   - Name: "EWS Usage Audit Reporter" (or similar)
   - Supported account types: Single tenant
   - No redirect URI needed

2. **Add API permissions**
   - Go to API permissions → Add a permission → Microsoft Graph → Application permissions
   - Add: `Application.Read.All`
   - Add: `AuditLog.Read.All`
   - Click "Grant admin consent for [tenant]"

3. **Create a client secret**
   - Go to Certificates & secrets → New client secret
   - Description: "EWS Usage Audit"
   - Expiration: Choose a short duration (14-30 days recommended)
   - **Copy the secret value immediately** — it won't be shown again

4. **Set environment variables**
   - Find the Application (client) ID and Directory (tenant) ID on the app's Overview page
   - Set these environment variables:

   ```powershell
   # PowerShell (User scope — persists across sessions)
   [System.Environment]::SetEnvironmentVariable("EWS_USAGE_TENANT_ID", "<tenant-id>", "User")
   [System.Environment]::SetEnvironmentVariable("EWS_USAGE_AUDIT_APP_ID", "<app-id>", "User")
   [System.Environment]::SetEnvironmentVariable("EWS_USAGE_AUDIT_APP_SECRET", "<secret-value>", "User")
   ```

### Post-Setup Validation

After setup (either approach), verify:

1. **Environment variables are set:**
   ```powershell
   $env:EWS_USAGE_TENANT_ID
   $env:EWS_USAGE_AUDIT_APP_ID
   $env:EWS_USAGE_AUDIT_APP_SECRET
   ```
   All three should return non-empty values.

2. **App permissions are granted:**
   The admin should confirm that admin consent has been granted for both permissions in the Entra portal. The permissions status should show green checkmarks.

## Acceptance Criteria

- [ ] App registration exists in the tenant with a descriptive name
- [ ] `Application.Read.All` permission assigned and admin consent granted
- [ ] `AuditLog.Read.All` permission assigned and admin consent granted
- [ ] Client secret created with appropriate expiration
- [ ] `EWS_USAGE_TENANT_ID` environment variable set
- [ ] `EWS_USAGE_AUDIT_APP_ID` environment variable set
- [ ] `EWS_USAGE_AUDIT_APP_SECRET` environment variable set

## Human Checkpoint

Before proceeding to data collection, confirm:

1. **"Are all three environment variables set and correct?"**
   - If no: help troubleshoot — check variable scope, spelling, restart terminal if needed
2. **"Has admin consent been granted for both permissions?"**
   - If no: guide through granting consent or identify who can
3. **"Ready to proceed to data collection?"**
   - Options: [✅ Proceed] [🔄 Re-run setup] [⏸️ Pause]

Do NOT proceed to the next skill without explicit human approval.

## Next Skill

Upon approval → **Step 01: Collect EWS Usage Data** (`ews-usage-collect`)
