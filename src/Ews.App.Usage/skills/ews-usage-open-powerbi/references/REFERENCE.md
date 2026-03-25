# EWS Usage Open Power BI Reference

## File Locations

| File | Path | Description |
|------|------|-------------|
| Power BI Report | `src/Ews.App.Usage/EWS-Usage.pbix` | Interactive dashboard report |
| Report Data | `src/Ews.App.Usage/Usage-Data/EWSUsage.csv` | Merged usage data (report data source) |

## Power BI Desktop Detection Methods

| Method | Command | Notes |
|--------|---------|-------|
| Program Files (MSI) | `Test-Path "${env:ProgramFiles}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"` | Traditional installer |
| Local AppData | `Test-Path "${env:LOCALAPPDATA}\Microsoft\Power BI Desktop\bin\PBIDesktop.exe"` | Per-user install |
| Microsoft Store | `Get-ChildItem "${env:ProgramFiles}\WindowsApps\Microsoft.MicrosoftPowerBIDesktop*"` | Store version |
| File association | `cmd /c assoc .pbix` | Checks Windows file type association |

## Power BI Data Source Configuration

The `.pbix` file expects this relative data source path:

```
Usage-Data\EWSUsage.csv
```

If the admin used a custom `OutputPath`:
1. Open Power BI Desktop
2. Go to Home → Transform Data
3. Click on the data source step
4. Update the file path to point to the correct `EWSUsage.csv` location

## Power BI Desktop Installation

| Source | URL |
|--------|-----|
| Direct download | <https://powerbi.microsoft.com/en-us/desktop/> |
| Microsoft Store | Search "Power BI Desktop" in the Microsoft Store app |
| Microsoft Download Center | <https://www.microsoft.com/en-us/download/details.aspx?id=58494> |

## Alternative Viewing Options

If Power BI Desktop is not available:

| Alternative | How |
|-------------|-----|
| Excel workbook | Open `EWS-Usage.xlsx` — tabular analysis |
| VS Code notebook | Open `Report-EWS-App-Usage.ipynb` — charts and tables inline |
| CSV viewer | Open `Usage-Data/EWSUsage.csv` in any editor |
| M365 Admin Center | Visit <https://admin.cloud.microsoft/?#/reportsUsage/EWSWeeklyUsage> |

## Microsoft Documentation

- [Power BI Desktop download](https://powerbi.microsoft.com/en-us/desktop/)
- [Get started with Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-getting-started)
- [Deprecation of EWS in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online)
