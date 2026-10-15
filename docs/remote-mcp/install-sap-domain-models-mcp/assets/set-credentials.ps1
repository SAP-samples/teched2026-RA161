<#
.SYNOPSIS
Creates a private Remote MCP credentials file from SAP Domain Models and IAS service bindings.

.PARAMETER SapDomainModelsBinding
Path to the SAP Domain Models service binding JSON file (sap-domain-models-prod-usea.json).

.PARAMETER IasBinding
Path to the IAS service binding JSON file (ias-prod-usea.json).

.PARAMETER Force
Replace the environment-specific credentials file if it already exists.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File .\sap-domain-models-set-credentials.ps1 `
  -SapDomainModelsBinding C:\Downloads\sap-domain-models-prod-usea.json `
  -IasBinding C:\Downloads\ias-prod-usea.json

.NOTES
Unblock a script downloaded from a browser with Unblock-File before running it.
The script creates owner-only Windows ACLs before writing credential values.
#>
param(
  [string] $SapDomainModelsBinding,
  [string] $IasBinding,
  [switch] $Force
)

$ErrorActionPreference = "Stop"

$hasDomainBinding = $PSBoundParameters.ContainsKey("SapDomainModelsBinding")
$hasIasBinding = $PSBoundParameters.ContainsKey("IasBinding")
if ($hasDomainBinding -xor $hasIasBinding) {
  throw "Provide both -SapDomainModelsBinding and -IasBinding, or omit both for interactive prompts."
}
# Workshop binding files ship in the repository's credentials\ directory;
# pressing Enter at a prompt uses these. Run the wizard from the repository
# root so the defaults resolve.
$defaultBindingDir = Join-Path (Get-Location).Path "credentials"
$defaultDomainModelsBinding = Join-Path $defaultBindingDir "sap-domain-models-prod-usea.json"
$defaultIasBinding = Join-Path $defaultBindingDir "ias-prod-usea.json"

if (-not $hasDomainBinding) {
  if ([Console]::IsInputRedirected) {
    throw "Provide both service binding file paths or run this script in an interactive terminal."
  }
  $SapDomainModelsBinding = (Read-Host "Location of sap-domain-models-prod-usea.json [$defaultDomainModelsBinding]").Trim()
  if ([string]::IsNullOrWhiteSpace($SapDomainModelsBinding)) {
    $SapDomainModelsBinding = $defaultDomainModelsBinding
  }
  $IasBinding = (Read-Host "Location of ias-prod-usea.json [$defaultIasBinding]").Trim()
  if ([string]::IsNullOrWhiteSpace($IasBinding)) {
    $IasBinding = $defaultIasBinding
  }
}
$SapDomainModelsBinding = $SapDomainModelsBinding.Trim()
$IasBinding = $IasBinding.Trim()
if ([string]::IsNullOrWhiteSpace($SapDomainModelsBinding)) {
  throw "SAP Domain Models service binding path is required."
}
if ([string]::IsNullOrWhiteSpace($IasBinding)) {
  throw "IAS service binding path is required."
}

function Test-JsonObject($value) {
  return $null -ne $value -and $value -isnot [Array] -and $value -is [PSCustomObject]
}

function Read-Binding([string] $bindingPath, [string] $label) {
  if (-not (Test-Path -LiteralPath $bindingPath -PathType Leaf)) {
    throw "$label is not a readable regular file: $bindingPath"
  }
  try {
    $content = [IO.File]::ReadAllText($bindingPath)
  } catch {
    throw "$label could not be read: $bindingPath ($($_.Exception.Message))"
  }
  if ($content.Length -gt 0 -and [int][char]$content[0] -eq 0xFEFF) {
    $content = $content.Substring(1)
  }
  try {
    $value = $content | ConvertFrom-Json
  } catch {
    throw "$label contains invalid JSON: $bindingPath ($($_.Exception.Message))"
  }
  if (-not (Test-JsonObject $value)) {
    throw "$label must contain a JSON object: $bindingPath"
  }

  $credentialsProperty = @($value.PSObject.Properties | Where-Object { $_.Name -ceq "credentials" })
  if ($credentialsProperty.Count -eq 1) {
    if (-not (Test-JsonObject $credentialsProperty[0].Value)) {
      throw "$label field `"credentials`" must contain a JSON object."
    }
    return $credentialsProperty[0].Value
  }
  return $value
}

function Get-RequiredString($binding, [string] $field, [string] $label) {
  $property = @($binding.PSObject.Properties | Where-Object { $_.Name -ceq $field })
  $value = if ($property.Count -eq 1) { $property[0].Value } else { $null }
  if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
    throw "$label is missing required string field `"$field`"."
  }
  if ($value -match "[\x00-\x1F\x7F]") {
    throw "$label field `"$field`" contains an unsupported control character."
  }
  return $value
}

function Get-HttpsOrigin([string] $value, [string] $label) {
  try {
    $uri = [Uri] $value.Trim()
  } catch {
    throw "$label field `"url`" is not a valid URL."
  }
  if (
    -not $uri.IsAbsoluteUri -or
    $uri.Scheme -cne "https" -or
    -not [string]::IsNullOrEmpty($uri.UserInfo) -or
    ($uri.AbsolutePath -ne "/" -and $uri.AbsolutePath -ne "") -or
    -not [string]::IsNullOrEmpty($uri.Query) -or
    -not [string]::IsNullOrEmpty($uri.Fragment)
  ) {
    throw "$label field `"url`" must be an HTTPS origin without a path, query, or fragment."
  }
  return $uri.GetLeftPart([UriPartial]::Authority)
}

$targets = @{
  "https://nova-service-prod-dewc.appai.cloud.sap" = @{
    Label = "Prod DEWC"
    Endpoint = "https://sap-domain-models-mcp-prod-dewc.appai.cloud.sap/mcp"
    CredentialsFile = "mcp-prod-dewc-credentials.env"
    ServerName = "prod_dewc_sap_domain_models_mcp"
  }
  "https://nova-service-prod-usea.appai.cloud.sap" = @{
    Label = "Prod USEA"
    Endpoint = "https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp"
    CredentialsFile = "mcp-prod-usea-credentials.env"
    ServerName = "prod_usea_sap_domain_models_mcp"
  }
}

$domainBinding = Read-Binding $SapDomainModelsBinding "SAP Domain Models service binding"
$serviceOrigin = Get-HttpsOrigin (Get-RequiredString $domainBinding "url" "SAP Domain Models service binding") "SAP Domain Models service binding"
$target = $targets[$serviceOrigin]
if (-not $target) {
  throw "Unsupported SAP Domain Models service binding URL: $serviceOrigin"
}

$ias = Read-Binding $IasBinding "IAS service binding"
$tenant = Get-HttpsOrigin (Get-RequiredString $ias "url" "IAS service binding") "IAS service binding"
$tenantHost = ([Uri] $tenant).Host
if (
  -not $tenantHost.EndsWith(".accounts.ondemand.com", [StringComparison]::OrdinalIgnoreCase) -and
  -not $tenantHost.EndsWith(".accounts400.ondemand.com", [StringComparison]::OrdinalIgnoreCase)
) {
  throw "IAS service binding field `"url`" is not an SAP IAS tenant URL."
}
$clientId = Get-RequiredString $ias "clientid" "IAS service binding"
$clientSecret = Get-RequiredString $ias "clientsecret" "IAS service binding"

function ConvertTo-EnvValue([string] $value) {
  return $value.Replace("\", "\\").Replace('"', '\"').Replace('$', '\$').Replace('`', '\`')
}

function New-OwnerOnlyDirectoryAcl($identity) {
  $acl = [Security.AccessControl.DirectorySecurity]::new()
  $acl.SetOwner($identity)
  $acl.SetAccessRuleProtection($true, $false)
  $rule = [Security.AccessControl.FileSystemAccessRule]::new(
    $identity,
    [Security.AccessControl.FileSystemRights]::FullControl,
    [Security.AccessControl.InheritanceFlags] "ContainerInherit, ObjectInherit",
    [Security.AccessControl.PropagationFlags]::None,
    [Security.AccessControl.AccessControlType]::Allow
  )
  $acl.AddAccessRule($rule)
  return $acl
}

function New-OwnerOnlyFileAcl($identity) {
  $acl = [Security.AccessControl.FileSecurity]::new()
  $acl.SetOwner($identity)
  $acl.SetAccessRuleProtection($true, $false)
  $rule = [Security.AccessControl.FileSystemAccessRule]::new(
    $identity,
    [Security.AccessControl.FileSystemRights]::FullControl,
    [Security.AccessControl.AccessControlType]::Allow
  )
  $acl.AddAccessRule($rule)
  return $acl
}

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
  throw "This PowerShell wizard must run on Windows. Use set-credentials.sh on macOS or Linux."
}

function Set-OwnerOnlyAccessControl($info, $acl) {
  # Set-Acl lives in Microsoft.PowerShell.Security, which fails to load when
  # the wizard is spawned with a mangled PSModulePath (e.g. from a coding
  # agent's shell). The .NET ACL APIs need no PowerShell module: Windows
  # PowerShell has SetAccessControl on FileInfo/DirectoryInfo, PowerShell 7
  # exposes it through FileSystemAclExtensions.
  if ($info.GetType().GetMethod("SetAccessControl", [Type[]]@($acl.GetType()))) {
    $info.SetAccessControl($acl)
  } else {
    [System.IO.FileSystemAclExtensions]::SetAccessControl($info, $acl)
  }
}

$directory = Join-Path (Join-Path $HOME ".config") "sap-domain-models"
[IO.Directory]::CreateDirectory($directory) | Out-Null
$currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
try {
  Set-OwnerOnlyAccessControl ([IO.DirectoryInfo]::new($directory)) (New-OwnerOnlyDirectoryAcl $currentSid)
} catch [System.Security.AccessControl.PrivilegeNotHeldException] {
  # SeSecurityPrivilege is not available to non-elevated processes on Windows.
  # The directory is already owned by the current user; skip owner-setting.
}

$destination = Join-Path $directory $target.CredentialsFile
$destinationExists = Test-Path -LiteralPath $destination
if ($destinationExists -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
  throw "Credentials destination exists but is not a regular file: $destination"
}
$replaced = $destinationExists
if ($replaced -and -not $Force) {
  throw "Credentials file already exists: $destination. Re-run with -Force to replace it."
}

$temporary = Join-Path $directory ".mcp-credentials.$PID.$([Guid]::NewGuid().ToString('N'))"
$content = @(
  "export SAP_DOMAIN_MODELS_IAS_TENANT=`"$(ConvertTo-EnvValue $tenant)`""
  "export SAP_DOMAIN_MODELS_IAS_CLIENT_ID=`"$(ConvertTo-EnvValue $clientId)`""
  "export SAP_DOMAIN_MODELS_IAS_CLIENT_SECRET=`"$(ConvertTo-EnvValue $clientSecret)`""
  ""
) -join "`n"

try {
  [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None).Dispose()
  Set-OwnerOnlyAccessControl ([IO.FileInfo]::new($temporary)) (New-OwnerOnlyFileAcl $currentSid)
  [IO.File]::WriteAllText($temporary, $content, [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $destination -Force
} finally {
  if (Test-Path -LiteralPath $temporary -PathType Leaf) {
    try {
      Remove-Item -LiteralPath $temporary -Force -ErrorAction Stop
    } catch {
      # Cleanup must not hide the original validation or write failure.
    }
  }
}

Write-Host "Detected environment: $($target.Label)"
Write-Host "MCP endpoint: $($target.Endpoint)"
Write-Host "MCP server name: $($target.ServerName)"
Write-Host "$(if ($replaced) { 'Replaced' } else { 'Wrote' }) $destination"
