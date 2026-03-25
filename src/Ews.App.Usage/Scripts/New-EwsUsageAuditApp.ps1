<#
    MIT License

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$AppDisplayName = "EWS Usage Audit Reporter",

    [Parameter(Mandatory = $false)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [int]$SecretLifetimeDays = 14,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Process", "User")]
    [string]$EnvironmentVariableScope = "User",

    [Parameter(Mandatory = $false)]
    [switch]$ForceOverwriteEnvironmentVariables,

    [Parameter(Mandatory = $false)]
    [switch]$SkipAdminConsent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertFrom-Base64Url {
    param(
        [Parameter(Mandatory = $true)][string]$Value
    )

    $base64 = $Value.Replace('-', '+').Replace('_', '/')
    switch ($base64.Length % 4) {
        2 { $base64 += '==' }
        3 { $base64 += '=' }
        0 { }
        default { throw "Invalid base64url value." }
    }

    $bytes = [Convert]::FromBase64String($base64)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Get-TenantIdFromJwt {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken
    )

    $parts = $AccessToken.Split('.')
    if ($parts.Count -lt 2) {
        throw "Access token is not in expected JWT format."
    }

    $payloadJson = ConvertFrom-Base64Url -Value $parts[1]
    $payload = $payloadJson | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($payload.tid)) {
        throw "Could not read tenant id (tid) claim from Graph access token."
    }

    return [string]$payload.tid
}

function Test-AzCliAvailable {
    $azCommand = Get-Command az -ErrorAction SilentlyContinue
    return ($null -ne $azCommand)
}

function Ensure-AzLogin {
    param(
        [Parameter(Mandatory = $false)][string]$TenantIdHint
    )

    if (-not (Test-AzCliAvailable)) {
        throw "Azure CLI was not found. Install Azure CLI and run 'az login --allow-no-subscriptions'."
    }

    $accountArgs = @("account", "show", "--output", "none")
    if (-not [string]::IsNullOrWhiteSpace($TenantIdHint)) {
        $accountArgs += @("--tenant", $TenantIdHint)
    }

    az @accountArgs 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Warning "You are not currently logged in to Azure CLI for this context."
    $loginPrompt = Read-Host "Run 'az login --allow-no-subscriptions' now? (Y/N)"
    if ($loginPrompt -notmatch '^(?i)y(es)?$') {
        throw "Sign-in is required. Run 'az login --allow-no-subscriptions' and re-run this script."
    }

    $loginArgs = @("login", "--allow-no-subscriptions")
    if (-not [string]::IsNullOrWhiteSpace($TenantIdHint)) {
        $loginArgs += @("--tenant", $TenantIdHint)
    }

    az @loginArgs | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI login did not complete successfully."
    }
}

function Set-EwsUsageEnvironmentVariables {
    param(
        [Parameter(Mandatory = $true)][string]$TenantId,
        [Parameter(Mandatory = $true)][string]$ClientId,
        [Parameter(Mandatory = $true)][string]$ClientSecret,
        [Parameter(Mandatory = $true)][ValidateSet("Process", "User")][string]$Scope,
        [Parameter(Mandatory = $false)][switch]$Force
    )

    $variables = @{
        "EWS_USAGE_TENANT_ID" = $TenantId
        "EWS_USAGE_AUDIT_APP_ID" = $ClientId
        "EWS_USAGE_AUDIT_APP_SECRET" = $ClientSecret
    }

    foreach ($name in $variables.Keys) {
        $existingValue = [Environment]::GetEnvironmentVariable($name, $Scope)
        if (-not [string]::IsNullOrWhiteSpace($existingValue) -and -not $Force) {
            throw "Environment variable '$name' already exists at scope '$Scope'. Re-run with -ForceOverwriteEnvironmentVariables to replace it."
        }
    }

    foreach ($name in $variables.Keys) {
        [Environment]::SetEnvironmentVariable($name, $variables[$name], $Scope)
        [Environment]::SetEnvironmentVariable($name, $variables[$name], "Process")
    }
}

function Get-GraphAccessToken {
    param(
        [Parameter(Mandatory = $false)][string]$TenantIdHint
    )

    $tokenCommand = @("account", "get-access-token", "--resource-type", "ms-graph", "--output", "json")
    if (-not [string]::IsNullOrWhiteSpace($TenantIdHint)) {
        $tokenCommand += @("--tenant", $TenantIdHint)
    }

    $tokenResponseRaw = az @tokenCommand 2>$null
    if ([string]::IsNullOrWhiteSpace($tokenResponseRaw)) {
        throw "Could not acquire Microsoft Graph access token. Run 'az login --allow-no-subscriptions' and ensure Azure CLI is installed."
    }

    $tokenResponse = $tokenResponseRaw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($tokenResponse.accessToken)) {
        throw "Access token response did not include an access token."
    }

    $tenantId = $null
    if (-not [string]::IsNullOrWhiteSpace($tokenResponse.tenant)) {
        $tenantId = [string]$tokenResponse.tenant
    }
    else {
        $tenantId = Get-TenantIdFromJwt -AccessToken $tokenResponse.accessToken
    }

    return [pscustomobject]@{
        AccessToken = [string]$tokenResponse.accessToken
        TenantId    = $tenantId
    }
}

function Invoke-Graph {
    param (
        [Parameter(Mandatory = $true)][ValidateSet("GET", "POST", "PATCH")][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $false)][object]$Body,
        [Parameter(Mandatory = $true)][string]$AccessToken
    )

    $headers = @{ Authorization = "Bearer $AccessToken" }

    if ($null -ne $Body) {
        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body ($Body | ConvertTo-Json -Depth 10)
    }

    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
}

Ensure-AzLogin -TenantIdHint $TenantId
$authContext = Get-GraphAccessToken -TenantIdHint $TenantId
$accessToken = $authContext.AccessToken
$resolvedTenantId = $authContext.TenantId

$graphServicePrincipalAppId = "00000003-0000-0000-c000-000000000000"
$graphServicePrincipal = Invoke-Graph -Method "GET" -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$graphServicePrincipalAppId'" -AccessToken $accessToken
if ($graphServicePrincipal.value.Count -ne 1) {
    throw "Could not resolve Microsoft Graph service principal in this tenant."
}

$graphSp = $graphServicePrincipal.value[0]
$requiredRoleNames = @("Application.Read.All", "AuditLog.Read.All")
$roleMap = @{}
foreach ($name in $requiredRoleNames) {
    $role = $graphSp.appRoles | Where-Object { $_.value -eq $name -and $_.isEnabled -eq $true -and $_.allowedMemberTypes -contains "Application" } | Select-Object -First 1
    if ($null -eq $role) {
        throw "Required Graph application permission '$name' was not found."
    }

    $roleMap[$name] = $role.id
}

$appCreateBody = @{
    displayName = $AppDisplayName
    signInAudience = "AzureADMyOrg"
    requiredResourceAccess = @(
        @{
            resourceAppId = $graphServicePrincipalAppId
            resourceAccess = @(
                @{ id = $roleMap["Application.Read.All"]; type = "Role" },
                @{ id = $roleMap["AuditLog.Read.All"]; type = "Role" }
            )
        }
    )
}

$newApplication = Invoke-Graph -Method "POST" -Uri "https://graph.microsoft.com/v1.0/applications" -Body $appCreateBody -AccessToken $accessToken
Write-Host "Created application registration '$($newApplication.displayName)' (AppId: $($newApplication.appId))."

$newServicePrincipal = Invoke-Graph -Method "POST" -Uri "https://graph.microsoft.com/v1.0/servicePrincipals" -Body @{ appId = $newApplication.appId } -AccessToken $accessToken
Write-Host "Created service principal '$($newServicePrincipal.id)'."

$secretEndDate = (Get-Date).ToUniversalTime().AddDays($SecretLifetimeDays).ToString("o")
$secretResult = Invoke-Graph -Method "POST" -Uri "https://graph.microsoft.com/v1.0/applications/$($newApplication.id)/addPassword" -Body @{
    passwordCredential = @{
        displayName = "ews-usage-secret"
        endDateTime = $secretEndDate
    }
} -AccessToken $accessToken

if (-not $SkipAdminConsent) {
    foreach ($permissionName in $requiredRoleNames) {
        Invoke-Graph -Method "POST" -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($newServicePrincipal.id)/appRoleAssignments" -Body @{
            principalId = $newServicePrincipal.id
            resourceId  = $graphSp.id
            appRoleId   = $roleMap[$permissionName]
        } -AccessToken $accessToken | Out-Null
    }
    Write-Host "Granted admin consent for required Microsoft Graph application permissions."
}
else {
    Write-Warning "Skipped admin consent. Grant admin consent for Application.Read.All and AuditLog.Read.All before running data collection."
}

Set-EwsUsageEnvironmentVariables `
    -TenantId $resolvedTenantId `
    -ClientId $newApplication.appId `
    -ClientSecret $secretResult.secretText `
    -Scope $EnvironmentVariableScope `
    -Force:$ForceOverwriteEnvironmentVariables

Write-Host "Set environment variables for EWS usage data collection at scope '$EnvironmentVariableScope'."
Write-Host "EWS_USAGE_TENANT_ID: $resolvedTenantId"
Write-Host "EWS_USAGE_AUDIT_APP_ID: $($newApplication.appId)"
Write-Host "EWS_USAGE_AUDIT_APP_SECRET: (set as environment variable; value not displayed)"
Write-Host "If your notebook kernel is already running, restart it so it picks up updated environment variables."
