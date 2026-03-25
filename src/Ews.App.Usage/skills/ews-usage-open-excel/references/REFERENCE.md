# EWS Usage Open Excel Reference

## File Locations

| File | Path | Description |
|------|------|-------------|
| Excel Workbook | `src/Ews.App.Usage/EWS-Usage.xlsx` | Interactive analysis workbook |
| Report Data | `src/Ews.App.Usage/Usage-Data/EWSUsage.csv` | Merged usage data (workbook data source) |

## Excel Detection Methods

| Method | Command | Notes |
|--------|---------|-------|
| Direct path check | `Test-Path "${env:ProgramFiles}\Microsoft Office\root\Office16\EXCEL.EXE"` | Most reliable for Click-to-Run installs |
| Command lookup | `Get-Command "excel.exe" -ErrorAction SilentlyContinue` | Works if Excel is in PATH |
| File association | `cmd /c assoc .xlsx` | Checks Windows file type association |

## Alternative Viewing Options

If Excel is not available:

| Alternative | How |
|-------------|-----|
| VS Code notebook | Open `Report-EWS-App-Usage.ipynb` — shows charts and tables inline |
| Power BI Desktop | Open `EWS-Usage.pbix` — rich interactive dashboards |
| CSV viewer | Open `Usage-Data/EWSUsage.csv` in any text editor |
| M365 Admin Center | Visit <https://admin.cloud.microsoft/?#/reportsUsage/EWSWeeklyUsage> |

## Microsoft Documentation

- [Microsoft 365 Apps installation](https://www.microsoft.com/en-us/microsoft-365)
- [Deprecation of EWS in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online)
