---
name: ews-usage-open-excel
description: "Open the EWS-Usage.xlsx workbook in Microsoft Excel for interactive analysis of EWS application usage data. Performs pre-flight checks to verify Excel is installed and usage data has been collected. Use this skill when the admin wants to explore EWS usage data in a spreadsheet."
license: MIT
compatibility: "Requires Microsoft Excel installed on the local machine. Usage data must be collected and reports generated first."
metadata:
  stage: "03a"
  category: "ews-app-usage"
  prerequisites: "ews-usage-report"
---

# Skill: Open EWS Usage in Excel

## Purpose

You are an AI assistant that helps Microsoft 365 tenant administrators open the EWS usage data workbook in Microsoft Excel. You perform pre-flight checks to ensure Excel is available and data has been collected before launching the application.

## Context

This is Step 03a of the EWS App Usage workflow (one of three result-viewing options). The data collection and report generation steps must be complete before this skill is useful — the Excel workbook reads from the CSV data produced by earlier steps.

## What You Do

### Step 1: Check if Excel is Installed

```powershell
# Check for Excel in common installation paths
$excelPaths = @(
    "${env:ProgramFiles}\Microsoft Office\root\Office16\EXCEL.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\EXCEL.EXE",
    "${env:ProgramFiles}\Microsoft Office\root\Office15\EXCEL.EXE",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office15\EXCEL.EXE"
)

$excelFound = $false
foreach ($path in $excelPaths) {
    if (Test-Path $path) {
        $excelFound = $true
        break
    }
}

# Alternative: check if .xlsx file association exists
if (-not $excelFound) {
    $excelFound = (Get-Command "excel.exe" -ErrorAction SilentlyContinue) -ne $null
}

# Alternative: check via file type association
if (-not $excelFound) {
    try {
        $assoc = cmd /c assoc .xlsx 2>$null
        $excelFound = $assoc -match "Excel"
    } catch { }
}
```

**If Excel is NOT installed:**
- Inform the admin that Excel is required to open the workbook
- Suggest alternatives:
  - Install Microsoft 365 Apps: <https://www.microsoft.com/en-us/microsoft-365>
  - View the data in the notebook output instead (`Report-EWS-App-Usage.ipynb`)
  - Use the Power BI report (`ews-usage-open-powerbi` skill)
  - Open `EWSUsage.csv` directly in any text editor or CSV viewer

### Step 2: Check if Usage Data Exists

```powershell
$workbookPath = ".\EWS-Usage.xlsx"
$csvPath = ".\Usage-Data\EWSUsage.csv"

# Check the workbook exists
if (-not (Test-Path $workbookPath)) {
    Write-Warning "EWS-Usage.xlsx not found at $workbookPath"
}

# Check that report data has been generated
if (-not (Test-Path $csvPath)) {
    Write-Warning "EWSUsage.csv not found — run data collection and reporting first"
}
```

**If data has NOT been collected:**
- Inform the admin that usage data must be collected first
- Redirect to `ews-usage-collect` → `ews-usage-report` skills

**If the workbook exists but EWSUsage.csv is missing or empty:**
- The workbook will open but may show stale or no data
- Recommend running the collection and reporting steps first

### Step 3: Open the Workbook

```powershell
$workbookPath = Resolve-Path ".\EWS-Usage.xlsx"
Start-Process $workbookPath
```

### Step 4: Post-Launch Guidance

After opening Excel, advise the admin:

1. **Refresh data connections** — If the workbook has data connections to the CSV files, click "Refresh All" in the Data tab
2. **Review the data** — The workbook should show EWS usage data organized by application
3. **Filter and sort** — Use Excel's filtering to focus on Active EWS applications
4. **Share results** — The workbook can be saved and shared with stakeholders for migration planning

## Error Handling

| Issue | Solution |
|-------|----------|
| Excel not installed | Suggest Microsoft 365 installation or alternative viewers |
| Workbook file missing | Check that you're in the correct directory (`src/Ews.App.Usage/`) |
| No data in workbook | Run `ews-usage-collect` and `ews-usage-report` first |
| Excel opens but shows errors | Check if `EWSUsage.csv` path matches what the workbook expects (`Usage-Data/EWSUsage.csv`) |

## Acceptance Criteria

- [ ] Excel is confirmed to be installed
- [ ] `EWS-Usage.xlsx` file exists
- [ ] `EWSUsage.csv` exists with collected data
- [ ] Workbook opens successfully in Excel
- [ ] Data is visible and current in the workbook
