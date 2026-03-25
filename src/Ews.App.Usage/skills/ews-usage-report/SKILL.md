---
name: ews-usage-report
description: "Generate EWS usage reports from collected data. Merges app registrations, EWS permissions, and sign-in activity into a unified report. Classifies apps as Active EWS, Inactive EWS, or No EWS. Produces EWSUsage.csv for Power BI and summary visualizations. Use this skill after data collection is complete."
license: MIT
compatibility: "Requires Python 3.10+ with pandas, matplotlib, numpy. Collected CSV data must exist in Usage-Data/."
metadata:
  stage: "02"
  category: "ews-app-usage"
  prerequisites: "ews-usage-collect"
---

# Skill: Generate EWS Usage Reports

## Purpose

You are an AI assistant that helps Microsoft 365 tenant administrators generate usage reports from collected EWS data. You guide them through merging raw CSV data into a unified analysis that classifies each application's EWS usage status and produces visualizations and export files.

## Context

This is Step 02 of the EWS App Usage workflow. The raw CSV data must already be collected (Step 01). This step merges and analyzes the data, producing the `EWSUsage.csv` file that drives the Excel workbook and Power BI report.

## What You Do

### Pre-Flight Checks

Before starting report generation, verify:

1. **Collected data exists:**
   ```powershell
   $outputPath = ".\Usage-Data"
   Get-ChildItem -Path $outputPath -Filter "EntraAppRegistrations*.csv" | Select-Object -Last 1
   Get-ChildItem -Path $outputPath -Filter "EWSEntraAppRegistrations*.csv" | Select-Object -Last 1
   Get-ChildItem -Path $outputPath -Filter "AppSignInActivity*.csv" | Select-Object -Last 1
   ```
   If any are missing → redirect to `ews-usage-collect` skill.

2. **Python dependencies installed:**
   ```bash
   pip install pandas matplotlib numpy
   ```

### Option A: Run via Notebook (Recommended)

Guide the admin through running the `Report-EWS-App-Usage.ipynb` notebook:

1. Open `Report-EWS-App-Usage.ipynb` in VS Code
2. Run all cells in order
3. The notebook will:
   - Copy the latest timestamped CSVs to stable filenames (`EntraAppRegistrations.csv`, `AppSignInActivity.csv`, `EWSEntraAppRegistrations.csv`)
   - Merge data from all sources
   - Classify each app's EWS status:
     - **No EWS**: App doesn't have EWS permissions
     - **Active EWS**: App has EWS permissions AND recent sign-in activity
     - **Inactive EWS**: App has EWS permissions but no recent sign-in activity
   - Compute additional fields: `UsesEws`, `LastSignIn`, `EwsStatus`, `EntraLink`
   - Generate `EWSUsage.csv` in the output folder
   - Display summary charts (donut chart of EWS status distribution)
   - Show data tables for EWS apps and all apps

### Option B: Run via Python Directly

For command-line execution, the key operations are:

```python
import pandas as pd
from Modules.ews_utilities import get_config

config = get_config()
output_path = config.get("OutputPath", "./Usage-Data") if config else "./Usage-Data"

# Load the collected data
apps = pd.read_csv(f"{output_path}/EntraAppRegistrations.csv")
ews_apps = pd.read_csv(f"{output_path}/EWSEntraAppRegistrations.csv")
signin = pd.read_csv(f"{output_path}/AppSignInActivity.csv")

# Merge and classify (the notebook handles the full logic)
# See Report-EWS-App-Usage.ipynb for complete implementation
```

### Report Outputs

The reporting process produces:

| Output | Description |
|--------|-------------|
| `EWSUsage.csv` | Merged dataset with EWS status classification for every app |
| Donut chart | Visual breakdown of No EWS / Active EWS / Inactive EWS |
| App counts | Total apps, EWS apps, active EWS apps |
| Data tables | Filterable views of EWS apps and all apps |

### Key Columns in EWSUsage.csv

| Column | Description |
|--------|-------------|
| `DisplayName` | Application display name |
| `AppId` | Application (client) ID |
| `UsesEws` | Boolean — whether the app has EWS permissions |
| `LastSignIn` | Most recent sign-in timestamp |
| `EwsStatus` | Classification: `No EWS`, `Active EWS`, or `Inactive EWS` |
| `EntraLink` | Direct link to the app in the Entra portal |

### Interpreting Results

- **Active EWS apps** are the priority — these need migration plans before October 2026
- **Inactive EWS apps** have permissions but no recent usage — consider removing EWS permissions
- **No EWS apps** are already clean — no action needed

### Post-Report Validation

After report generation, verify:

```powershell
$ewsUsage = Import-Csv ".\Usage-Data\EWSUsage.csv"
$ewsUsage | Group-Object EwsStatus | Select-Object Name, Count | Format-Table
```

This should show counts for each status category.

## Acceptance Criteria

- [ ] `EWSUsage.csv` exists in the output folder
- [ ] `EWSUsage.csv` contains the `EwsStatus` column with valid values
- [ ] Stable-name CSV copies exist (`EntraAppRegistrations.csv`, `AppSignInActivity.csv`, `EWSEntraAppRegistrations.csv`)
- [ ] Summary statistics are available (total apps, EWS apps, active EWS apps)

## Human Checkpoint

Before proceeding to view results, confirm:

1. **"Does the report show the expected number of applications?"**
   - If the count seems low: check if the data collection captured all apps
2. **"Are the EWS status classifications reasonable?"**
   - Review a sample of Active EWS apps — do they look correct?
3. **"How would you like to view the detailed results?"**
   - Options: [📊 Open in Excel] [📈 Open in Power BI] [🌐 View Admin Center Reports] [⏸️ Pause]

Do NOT proceed without explicit human approval.

## Next Skills

Upon approval → Choose one or more:
- **Step 03a: Open in Excel** (`ews-usage-open-excel`)
- **Step 03b: Open in Power BI** (`ews-usage-open-powerbi`)
- **Step 03c: View Admin Center Reports** (`ews-usage-admin-reports`)
