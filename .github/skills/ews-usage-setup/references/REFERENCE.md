# EWS Usage Setup Reference

## Required Graph API Permissions

| Permission | Type | Purpose |
|------------|------|---------|
| `Application.Read.All` | Application | Read all Entra app registrations and their properties |
| `AuditLog.Read.All` | Application | Read sign-in activity logs to identify active EWS apps |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `EWS_USAGE_TENANT_ID` | Entra / Azure AD tenant GUID | `12345678-abcd-1234-abcd-123456789012` |
| `EWS_USAGE_AUDIT_APP_ID` | App registration client ID | `87654321-dcba-4321-dcba-210987654321` |
| `EWS_USAGE_AUDIT_APP_SECRET` | Client secret value | `abc~...` |

## New-EwsUsageAuditApp.ps1 Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-AppDisplayName` | `"EWS Usage Audit Reporter"` | Display name for the app registration |
| `-TenantId` | Auto-detected from `az` CLI | Target tenant GUID |
| `-SecretLifetimeDays` | `14` | Client secret expiration in days |
| `-EnvironmentVariableScope` | `User` | Where to store env vars: `User` or `Process` |
| `-ForceOverwriteEnvironmentVariables` | `$false` | Overwrite existing env var values |
| `-SkipAdminConsent` | `$false` | Skip automatic admin consent grant |

## Manual Setup Portal Links

- [Entra Admin Center — App Registrations](https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM)
- [Azure Portal — App Registrations](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)

## Microsoft Documentation

- [Register an application in Entra ID](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
- [Add application permissions](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-access-web-apis)
- [Grant admin consent](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent)
- [Identify EWS-using applications](https://aka.ms/ewsIdentifyApps)
