#Requires -Version 5.1
<#
.SYNOPSIS
    Registers (or updates) the Microsoft Entra application for Auth.js and Business Central.

.DESCRIPTION
    BCM-010 helper. Reads config/entra-app.json and uses Azure CLI to:
      1. Create an app registration (or reuse one by display name / appId)
      2. Assign Microsoft Graph delegated and Business Central API permissions
      3. Create a client secret (new apps only, unless -RotateSecret)
      4. Optionally grant admin consent

    The script never writes the client secret to disk. Copy printed values into
    the local gitignored .env. Enabling the app in Business Central remains manual
    (see docs/entra-app.md).

.PARAMETER ValidateOnly
    Validate entra-app.json and exit without calling Azure.

.PARAMETER RotateSecret
    Create a new client secret when reusing an existing app registration.

.EXAMPLE
    pwsh -File scripts/Register-EntraApp.ps1 -ValidateOnly

.EXAMPLE
    az login --allow-no-subscriptions
    pwsh -File scripts/Register-EntraApp.ps1 -GrantAdminConsent
#>

[CmdletBinding()]
param(
    [string] $ConfigPath,
    [string] $DisplayName,
    [string] $AppId,
    [int] $SecretValidityMonths,
    [switch] $GrantAdminConsent,
    [switch] $AllowNoSubscriptions,
    [switch] $ValidateOnly,
    [switch] $RotateSecret
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:GuidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
$script:BcResourceAppId = '996def3d-b36c-4153-8607-a6fd3c01b89f'
$script:GraphResourceAppId = '00000003-0000-0000-c000-000000000000'
$script:RequiredBcApplication = @{
    'API.ReadWrite.All'        = 'a42b0b75-311e-488d-b67e-8fe84f924341'
    'Automation.ReadWrite.All' = 'd365bc00-a990-0000-00bc-160000000001'
}
$script:RequiredBcDelegated = @{
    'Financials.ReadWrite.All' = '2fb13c28-9d89-417f-9af2-ec3065bc16e6'
}

function Get-RepoRoot {
    if ($PSScriptRoot) {
        return (Split-Path -Parent $PSScriptRoot)
    }
    return (Get-Location).Path
}

function Assert-PermissionEntry {
    param(
        [Parameter(Mandatory = $true)] $Permission,
        [Parameter(Mandatory = $true)][string] $ExpectedType
    )

    if (-not $Permission.value -or -not $Permission.id -or -not $Permission.type) {
        throw 'Each permission entry needs value, id, and type.'
    }
    if ([string]$Permission.type -ne $ExpectedType) {
        throw "Permission '$($Permission.value)' must use type $ExpectedType."
    }
    if ([string]$Permission.id -notmatch $script:GuidPattern) {
        throw "Permission '$($Permission.value)' id is not a GUID: $($Permission.id)"
    }
}

function Assert-RequiredMap {
    param(
        [Parameter(Mandatory = $true)] $Entries,
        [Parameter(Mandatory = $true)][hashtable] $Required,
        [Parameter(Mandatory = $true)][string] $Label
    )

    $values = @{}
    foreach ($entry in @($Entries)) {
        $values[[string]$entry.value] = [string]$entry.id
    }
    foreach ($name in $Required.Keys) {
        if (-not $values.ContainsKey($name)) {
            throw "Missing required $Label permission: $name"
        }
        if ($values[$name] -ne $Required[$name]) {
            throw "$Label permission $name must use id $($Required[$name])."
        }
    }
}

function Assert-EntraAppConfig {
    param(
        [Parameter(Mandatory = $true)] $Config,
        [string] $Path = 'config'
    )

    if (-not $Config.displayName) { throw "Config is missing displayName: $Path" }
    if (-not $Config.signInAudience) { throw "Config is missing signInAudience: $Path" }
    if (-not $Config.businessCentralResource -or -not $Config.businessCentralResource.resourceAppId) {
        throw "Config is missing businessCentralResource.resourceAppId: $Path"
    }

    $resourceAppId = [string]$Config.businessCentralResource.resourceAppId
    if ($resourceAppId -ne $script:BcResourceAppId) {
        throw "businessCentralResource.resourceAppId must be Dynamics 365 Business Central ($($script:BcResourceAppId))."
    }

    foreach ($permission in @($Config.applicationPermissions)) {
        Assert-PermissionEntry -Permission $permission -ExpectedType 'Role'
    }
    foreach ($permission in @($Config.delegatedPermissions)) {
        Assert-PermissionEntry -Permission $permission -ExpectedType 'Scope'
    }
    Assert-RequiredMap -Entries $Config.applicationPermissions -Required $script:RequiredBcApplication -Label 'Business Central application'
    Assert-RequiredMap -Entries $Config.delegatedPermissions -Required $script:RequiredBcDelegated -Label 'Business Central delegated'

    if (-not $Config.microsoftGraph -or [string]$Config.microsoftGraph.resourceAppId -ne $script:GraphResourceAppId) {
        throw 'microsoftGraph.resourceAppId must be Microsoft Graph (00000003-0000-0000-c000-000000000000).'
    }
    foreach ($permission in @($Config.microsoftGraph.delegatedPermissions)) {
        Assert-PermissionEntry -Permission $permission -ExpectedType 'Scope'
    }

    $sets = @($Config.businessCentralApplicationCard.recommendedPermissionSets)
    if ($sets -contains 'SUPER') {
        throw 'Do not recommend the SUPER permission set for an Entra application.'
    }
}

function Read-EntraAppConfig {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Entra app config not found: $Path"
    }
    $config = (Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Json
    Assert-EntraAppConfig -Config $config -Path $Path
    return $config
}

function Get-PermissionTuples {
    param([Parameter(Mandatory = $true)] $Config)

    $tuples = @()
    foreach ($permission in @($Config.applicationPermissions) + @($Config.delegatedPermissions)) {
        $tuples += [pscustomobject]@{
            ResourceAppId = [string]$Config.businessCentralResource.resourceAppId
            Id            = [string]$permission.id
            Type          = [string]$permission.type
        }
    }
    foreach ($permission in @($Config.microsoftGraph.delegatedPermissions)) {
        $tuples += [pscustomobject]@{
            ResourceAppId = [string]$Config.microsoftGraph.resourceAppId
            Id            = [string]$permission.id
            Type          = [string]$permission.type
        }
    }
    return $tuples
}

function New-RequiredResourceAccessJson {
    param([Parameter(Mandatory = $true)] $Config)

    $byResource = @{}
    foreach ($tuple in (Get-PermissionTuples -Config $Config)) {
        if (-not $byResource.ContainsKey($tuple.ResourceAppId)) {
            $byResource[$tuple.ResourceAppId] = @()
        }
        $byResource[$tuple.ResourceAppId] += @{
            id   = $tuple.Id
            type = $tuple.Type
        }
    }

    $payload = @()
    foreach ($resourceAppId in $byResource.Keys) {
        $payload += @{
            resourceAppId  = $resourceAppId
            resourceAccess = @($byResource[$resourceAppId])
        }
    }
    return ($payload | ConvertTo-Json -Depth 8 -Compress)
}

function Assert-AzCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        $login = 'az login'
        if ($AllowNoSubscriptions) { $login = 'az login --allow-no-subscriptions' }
        throw "Azure CLI (az) was not found on PATH. Install it, then: $login`nSee docs/entra-app.md."
    }
}

function Invoke-AzJson {
    param([Parameter(Mandatory = $true)][string[]] $AzArgs)

    $output = & az @AzArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed ($LASTEXITCODE): az $($AzArgs -join ' ')`n$(($output | Out-String).Trim())"
    }
    $text = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($text) -or $text -eq 'None' -or $text -eq 'null') {
        return $null
    }
    return ($text | ConvertFrom-Json)
}

function Get-SignedInTenantId {
    $account = Invoke-AzJson -AzArgs @('account', 'show', '-o', 'json')
    if (-not $account -or -not $account.tenantId) {
        $hint = if ($AllowNoSubscriptions) { 'az login --allow-no-subscriptions' } else { 'az login' }
        throw "Unable to read the signed-in tenant. Run: $hint"
    }
    return [string]$account.tenantId
}

function Find-AppByDisplayName {
    param([Parameter(Mandatory = $true)][string] $Name)

    $apps = Invoke-AzJson -AzArgs @('ad', 'app', 'list', '--filter', "displayName eq '$Name'", '-o', 'json')
    if (-not $apps) { return $null }
    $list = @($apps)
    if ($list.Count -eq 0) { return $null }
    if ($list.Count -gt 1) {
        throw "Multiple app registrations named '$Name'. Pass -AppId to select one."
    }
    return $list[0]
}

function Ensure-AppRegistration {
    param(
        [Parameter(Mandatory = $true)] $Config,
        [string] $ExistingAppId,
        [string] $Name
    )

    if ($ExistingAppId) {
        $app = Invoke-AzJson -AzArgs @('ad', 'app', 'show', '--id', $ExistingAppId, '-o', 'json')
        if (-not $app) { throw "No app registration found for AppId $ExistingAppId." }
        Write-Host "Using existing app registration $($app.appId) ($($app.displayName))."
        return $app
    }

    $existing = Find-AppByDisplayName -Name $Name
    if ($existing) {
        Write-Host "Reusing existing app registration $($existing.appId) ($Name)."
        return $existing
    }

    Write-Host "Creating app registration '$Name'..."
    $createArgs = @(
        'ad', 'app', 'create',
        '--display-name', $Name,
        '--sign-in-audience', ([string]$Config.signInAudience),
        '-o', 'json'
    )
    if ($Config.webRedirectUris -and @($Config.webRedirectUris).Count -gt 0) {
        $createArgs += @('--web-redirect-uris') + @($Config.webRedirectUris | ForEach-Object { [string]$_ })
    }
    return (Invoke-AzJson -AzArgs $createArgs)
}

function Set-AppPermissions {
    param(
        [Parameter(Mandatory = $true)][string] $ApplicationId,
        [Parameter(Mandatory = $true)] $Config
    )

    Write-Host 'Assigning Graph and Business Central API permissions...'
    $grouped = Get-PermissionTuples -Config $Config | Group-Object ResourceAppId
    foreach ($group in $grouped) {
        $permissionArgs = @($group.Group | ForEach-Object { '{0}={1}' -f $_.Id, $_.Type })
        $addOutput = & az ad app permission add --id $ApplicationId --api $group.Name --api-permissions @permissionArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            $text = ($addOutput | Out-String).Trim()
            if ($text -notmatch '(?i)already|conflict|exists') {
                throw "Failed to add API permissions for $($group.Name): $text"
            }
            Write-Host "Permissions already present for $($group.Name); continuing."
        }
    }

    $json = New-RequiredResourceAccessJson -Config $Config
    $temp = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($temp, $json)
        & az ad app update --id $ApplicationId --required-resource-accesses "@$temp" 2>&1 | Out-Null
    }
    finally {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}

function New-AppClientSecret {
    param(
        [Parameter(Mandatory = $true)][string] $ApplicationId,
        [Parameter(Mandatory = $true)][string] $SecretDisplayName,
        [Parameter(Mandatory = $true)][int] $ValidityMonths
    )

    $endDate = (Get-Date).ToUniversalTime().AddMonths($ValidityMonths).ToString('yyyy-MM-ddTHH:mm:ssZ')
    Write-Host "Creating client secret '$SecretDisplayName' (valid until $endDate)..."
    $credential = Invoke-AzJson -AzArgs @(
        'ad', 'app', 'credential', 'reset',
        '--id', $ApplicationId,
        '--append',
        '--display-name', $SecretDisplayName,
        '--end-date', $endDate,
        '-o', 'json'
    )
    if (-not $credential -or -not $credential.password) {
        throw 'Client secret was created but Azure CLI did not return password.'
    }
    return [string]$credential.password
}

function Grant-AppAdminConsent {
    param([Parameter(Mandatory = $true)][string] $ApplicationId)

    Write-Host "Granting admin consent for $ApplicationId..."
    & az ad app permission admin-consent --id $ApplicationId 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning @'
Admin consent via Azure CLI failed. Grant consent in the Entra portal
(API permissions → Grant admin consent) or from Business Central
(Microsoft Entra Applications → Grant Consent).
'@
    }
    else {
        Write-Host 'Admin consent granted.'
    }
}

function Write-EnvGuidance {
    param(
        [Parameter(Mandatory = $true)][string] $TenantId,
        [Parameter(Mandatory = $true)][string] $ClientId,
        [Parameter(Mandatory = $true)][string] $ClientSecret
    )

    Write-Host ''
    Write-Host 'Entra application is ready. Copy these values into local .env (never commit .env):'
    Write-Host "ENTRA_TENANT_ID=$TenantId"
    Write-Host "AUTH_MICROSOFT_ENTRA_ID_ID=$ClientId"
    Write-Host "AUTH_MICROSOFT_ENTRA_ID_SECRET=$ClientSecret"
    Write-Host 'AUTH_MICROSOFT_ENTRA_ID_ISSUER=https://login.microsoftonline.com/organizations/v2.0'
    Write-Host "BC_CLIENT_ID=$ClientId"
    Write-Host "BC_CLIENT_SECRET=$ClientSecret"
    Write-Host 'BC_TOKEN_SCOPE=https://api.businesscentral.dynamics.com/.default'
    Write-Host ''
    Write-Host 'Still required in Business Central (manual):'
    Write-Host '  Microsoft Entra Applications → New → Client ID + Enabled'
    Write-Host '  Permission sets: D365 AUTOMATION, D365 BUS FULL ACCESS (not SUPER)'
    Write-Host 'See docs/entra-app.md.'
}

# --- main ---

$repoRoot = Get-RepoRoot
if (-not $ConfigPath) {
    $ConfigPath = Join-Path $repoRoot 'config/entra-app.json'
}

$config = Read-EntraAppConfig -Path $ConfigPath
$name = if ($DisplayName) { $DisplayName } else { [string]$config.displayName }

if ($ValidateOnly) {
    Write-Host "Entra app config is valid: $ConfigPath"
    Write-Host "Display name: $name"
    Write-Host "Sign-in audience: $($config.signInAudience)"
    Write-Host 'Business Central application permissions:'
    foreach ($permission in @($config.applicationPermissions)) {
        Write-Host ("  - {0} ({1})" -f [string]$permission.value, [string]$permission.id)
    }
    Write-Host 'Business Central delegated permissions:'
    foreach ($permission in @($config.delegatedPermissions)) {
        Write-Host ("  - {0} ({1})" -f [string]$permission.value, [string]$permission.id)
    }
    return [pscustomobject]@{
        Valid       = $true
        DisplayName = $name
        ConfigPath  = $ConfigPath
    }
}

Assert-AzCli

if ($PSBoundParameters.ContainsKey('SecretValidityMonths')) {
    if ($SecretValidityMonths -lt 1 -or $SecretValidityMonths -gt 24) {
        throw 'SecretValidityMonths must be between 1 and 24.'
    }
    $months = $SecretValidityMonths
}
elseif ($config.clientSecret -and $config.clientSecret.defaultValidityMonths) {
    $months = [int]$config.clientSecret.defaultValidityMonths
}
else {
    $months = 24
}

$secretName = 'executive-intelligence-agent'
if ($config.clientSecret -and $config.clientSecret.displayName) {
    $secretName = [string]$config.clientSecret.displayName
}

$tenantId = Get-SignedInTenantId
$createdNewApp = $false
if (-not $AppId) {
    $existingByName = Find-AppByDisplayName -Name $name
    if (-not $existingByName) { $createdNewApp = $true }
}

$app = Ensure-AppRegistration -Config $config -ExistingAppId $AppId -Name $name
$applicationId = [string]$app.appId
Set-AppPermissions -ApplicationId $applicationId -Config $config

try {
    $sp = Invoke-AzJson -AzArgs @('ad', 'sp', 'show', '--id', $applicationId, '-o', 'json')
}
catch {
    $sp = $null
}
if (-not $sp) {
    Write-Host 'Creating service principal for the app registration...'
    Invoke-AzJson -AzArgs @('ad', 'sp', 'create', '--id', $applicationId, '-o', 'json') | Out-Null
}

if ($RotateSecret -or $createdNewApp) {
    $clientSecret = New-AppClientSecret -ApplicationId $applicationId -SecretDisplayName $secretName -ValidityMonths $months
}
else {
    Write-Host 'Reusing existing app registration; not rotating the client secret. Pass -RotateSecret to create a new credential.'
    $clientSecret = '<unchanged — set secrets from your existing .env or pass -RotateSecret>'
}

if ($GrantAdminConsent) {
    Grant-AppAdminConsent -ApplicationId $applicationId
}
else {
    Write-Host 'Skipping admin consent (pass -GrantAdminConsent to attempt it).'
}

Write-EnvGuidance -TenantId $tenantId -ClientId $applicationId -ClientSecret $clientSecret

[pscustomobject]@{
    TenantId            = $tenantId
    ClientId            = $applicationId
    DisplayName         = $name
    SecretDisplayName   = $secretName
    SecretExpiresMonths = $months
    GrantAdminConsent   = [bool]$GrantAdminConsent
    ConfigPath          = $ConfigPath
}
