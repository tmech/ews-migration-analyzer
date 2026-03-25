# EWS Usage Data Collection Reference

## Find-EwsUsage.ps1 Parameters (GetEwsActivity Operation)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-OutputPath` | Yes | Directory for CSV output files |
| `-OAuthClientId` | Yes | App registration client ID |
| `-OAuthTenantId` | Yes | Entra tenant ID |
| `-OAuthClientSecret` | Yes | App registration client secret |
| `-Operation` | Yes | Set to `GetEwsActivity` for usage data collection |

## Output Files

| File Pattern | Contents |
|-------------|----------|
| `EntraAppRegistrations-<timestamp>.csv` | All app registrations in the tenant |
| `EntraServicePrincipals-<timestamp>.csv` | Service principals for each app |
| `EWSEntraAppRegistrations-<timestamp>.csv` | Apps with EWS permissions |
| `AppSignInActivity-<timestamp>.csv` | Sign-in activity for EWS apps |
| `EWS-ApiPermissions-<timestamp>.csv` | Detailed EWS API permission grants |
| `Oauth2PermissionGrants-<timestamp>.csv` | OAuth2 delegated permission grants |

## EWS Permission Identifiers

The script identifies EWS apps by checking for these permissions:

| Permission | Type | Scope |
|------------|------|-------|
| `EWS.AccessAsUser.All` | Delegated | User-context EWS access |
| `full_access_as_app` | Application | App-only EWS access |

## Graph API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `GET /applications` | List all app registrations |
| `GET /servicePrincipals` | List service principals |
| `GET /reports/servicePrincipalSignInActivities` | Sign-in activity per app |

## Azure Cloud Support

| Cloud | Login Endpoint | Graph Endpoint |
|-------|---------------|----------------|
| Global | `login.microsoftonline.com` | `graph.microsoft.com` |
| USGovernmentL4 | `login.microsoftonline.us` | `graph.microsoft.us` |
| USGovernmentL5 | `login.microsoftonline.us` | `dod-graph.microsoft.us` |
| ChinaCloud | `login.chinacloudapi.cn` | `microsoftgraph.chinacloudapi.cn` |

## Microsoft Documentation

- [Microsoft Graph API — List applications](https://learn.microsoft.com/en-us/graph/api/application-list)
- [Microsoft Graph API — Service principal sign-in activity](https://learn.microsoft.com/en-us/graph/api/reportroot-list-serviceprincipalSignInActivities)
- [Identify EWS-using applications](https://aka.ms/ewsIdentifyApps)
