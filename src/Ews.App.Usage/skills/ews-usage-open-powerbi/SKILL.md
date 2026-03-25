---
name: ews-usage-open-powerbi
description: "Open the EWS-Usage.pbix report in Power BI Desktop for interactive visualization of EWS application usage data. Performs pre-flight checks to verify Power BI Desktop is installed and usage data has been collected. Use this skill when the admin wants rich visual dashboards of EWS usage."
license: MIT
compatibility: "Requires Power BI Desktop installed on the local machine. Usage data must be collected and reports generated first."
metadata:
  stage: "03b"
  category: "ews-app-usage"
  prerequisites: "ews-usage-report"
---

# Skill: Open EWS Usage in Power BI

## Purpose

You are an AI assistant that helps Microsoft 365 tenant administrators open the EWS usage Power BI report for interactive visualization and analysis. You perform pre-flight checks to ensure Power BI Desktop is available and data has been collected before launching the application.

## Context

This is Step 03b of the EWS App Usage workflow (one of three result-viewing options). The data collection and report generation steps must be complete before this skill is useful — the Power BI report reads `EWSUsage.csv` from the `Usage-Data/` folder.

## What You Do

### Step 1: Check if Power BI Desktop is Installed

```powershell
# Check common installation paths for Power BI Desktop
$pbiPaths = @(
    "${env:ProgramFiles}\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "${env:ProgramFiles(x86)}\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "${env:LOCALAPPDATA}\Microsoft\Power BI Desktop\bin\PBIDesktop.exe",
    # Microsoft Store version
    (Get-ChildItem "${env:ProgramFiles}\WindowsApps\Microsoft.MicrosoftPowerBIDesktop*\bin\PBIDesktop.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
)

$pbiFound = $false
foreach ($path in $pbiPaths) {
    if ($path -and (Test-Path $path)) {
        $pbiFound = $true
        break
    }
}

# Alternative: check if .pbix file association exists
if (-not $pbiFound) {
    try {
        $assoc = cmd /c assoc .pbix 2>$null
        $pbiFound = $assoc -match "PowerBI" -or $assoc -match "PBIDesktop"
    } catch { }
}
```

**If Power BI Desktop is NOT installed:**
- Inform the admin that Power BI Desktop is required
- Provide the download link: <https://powerbi.microsoft.com/en-us/desktop/>
- Also available from the Microsoft Store: search "Power BI Desktop"
- Suggest alternatives:
  - View the Excel workbook (`ews-usage-open-excel` skill)
  - View the notebook output (`Report-EWS-App-Usage.ipynb`)
  - View admin reports online (`ews-usage-admin-reports` skill)

### Step 2: Check if Usage Data Exists

```powershell
$pbixPath = ".\EWS-Usage.pbix"
$csvPath = ".\Usage-Data\EWSUsage.csv"

# Check the Power BI report file exists
if (-not (Test-Path $pbixPath)) {
    Write-Warning "EWS-Usage.pbix not found at $pbixPath"
}

# Check that report data has been generated
if (-not (Test-Path $csvPath)) {
    Write-Warning "EWSUsage.csv not found — run data collection and reporting first"
}
```

**If data has NOT been collected:**
- Inform the admin that usage data must be collected first
- Redirect to `ews-usage-collect` → `ews-usage-report` skills

**Important note about data path:**
The Power BI report assumes `EWSUsage.csv` is located in the `Usage-Data` folder relative to the `.pbix` file. If the admin configured a different `OutputPath` in `appSettings.json`, they need to either:
- Copy `EWSUsage.csv` to the `Usage-Data` folder, OR
- Update the data source path in Power BI (Transform Data → Source → change file path)

### Step 3: Open the Report

```powershell
$pbixPath = Resolve-Path ".\EWS-Usage.pbix"
Start-Process $pbixPath
```

### Step 4: Post-Launch Guidance

After opening Power BI Desktop, advise the admin:

1. **Click "Refresh"** — In the Home tab command bar, click the Refresh button to load the latest data from `EWSUsage.csv`
2. **Review the dashboard** — The report shows EWS usage patterns, app classifications, and sign-in activity
3. **Use slicers and filters** — Filter by EWS status, application name, or activity date
4. **Publish (optional)** — If the admin has a Power BI Pro or Premium license, they can publish the report to the Power BI service for sharing with stakeholders

## Error Handling

| Issue | Solution |
|-------|----------|
| Power BI not installed | Download from <https://powerbi.microsoft.com/en-us/desktop/> |
| `.pbix` file missing | Check that you're in the correct directory (`src/Ews.App.Usage/`) |
| Data source error on refresh | Verify `EWSUsage.csv` is at `Usage-Data/EWSUsage.csv` relative to the `.pbix` file |
| "Can't find file" error | If `OutputPath` was customized, copy `EWSUsage.csv` to `Usage-Data/` or update the Power BI data source path |
| Report shows no data | Run `ews-usage-collect` and `ews-usage-report` first, then refresh |

## Acceptance Criteria

- [ ] Power BI Desktop is confirmed to be installed
- [ ] `EWS-Usage.pbix` file exists
- [ ] `Usage-Data/EWSUsage.csv` exists with collected data
- [ ] Report opens successfully in Power BI Desktop
- [ ] Data refreshes and visuals display correctly
