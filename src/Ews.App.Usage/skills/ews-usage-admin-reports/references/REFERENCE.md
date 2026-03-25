# EWS Admin Center Reports Reference

## Report URL

```
https://admin.cloud.microsoft/?source=applauncher#/reportsUsage/EWSWeeklyUsage
```

## Required Roles

To access the EWS Usage Reports in the M365 Admin Center, the user needs one of these roles:

| Role | Access Level |
|------|-------------|
| Global Administrator | Full access to all admin features |
| Reports Reader | Read-only access to usage reports |
| Exchange Administrator | Exchange-specific admin access |
| Global Reader | Read-only access to all admin features |

## Cloud Availability

| Cloud Environment | Reports Available | Alternative |
|-------------------|-------------------|-------------|
| Worldwide (Commercial) | ✅ Yes | — |
| US Government GCC | ❌ No | Use local data collection tools |
| US Government GCC High | ❌ No | Use local data collection tools |
| US Government DoD | ❌ No | Use local data collection tools |
| China (21Vianet) | ❌ No | Use local data collection tools |

## Admin Center vs Local Tools Comparison

| Capability | Admin Center | Local Tools |
|------------|-------------|-------------|
| No setup required | ✅ | ❌ (needs app registration) |
| All cloud support | ❌ | ✅ |
| Permission-based detection | ❌ | ✅ |
| Activity-based detection | ✅ | ✅ |
| Detailed CSV export | Limited | ✅ |
| Power BI dashboards | ❌ | ✅ |
| Excel workbook | ❌ | ✅ |
| Offline analysis | ❌ | ✅ |
| Custom date ranges | Limited | ✅ |

## Microsoft Documentation

- [EWS Usage Reports in M365 Admin Center](https://aka.ms/ewsAdminUsage)
- [Deprecation of EWS in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online)
- [Identify EWS-using applications](https://aka.ms/ewsIdentifyApps)
- [Microsoft 365 admin center overview](https://learn.microsoft.com/en-us/microsoft-365/admin/admin-overview/admin-center-overview)
