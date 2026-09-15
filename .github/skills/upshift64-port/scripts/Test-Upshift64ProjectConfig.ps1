[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$Path,

  [switch]$AllowPlaceholders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-ValidationError {
  param([string]$Message)
  $script:errors.Add($Message)
}

function Require-Property {
  param(
    [object]$Object,
    [string]$Name,
    [string]$Context
  )

  if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Name]) {
    Add-ValidationError "$Context.$Name is required."
    return $null
  }

  return $Object.$Name
}

function Test-Revision {
  param([object]$Repository, [string]$Context)

  if ($null -eq $Repository) {
    return
  }

  $revision = Require-Property $Repository "revision" $Context
  if ($null -ne $revision -and [string]$revision -notmatch "^[0-9a-fA-F]{40}$") {
    Add-ValidationError "$Context.revision must be a full 40-character commit."
  } elseif (
    -not $AllowPlaceholders -and
    [string]$revision -eq "0000000000000000000000000000000000000000"
  ) {
    Add-ValidationError "$Context.revision must replace the all-zero example value."
  }
}

function Test-Repository {
  param([object]$Repository, [string]$Context)

  if ($null -eq $Repository) {
    return
  }

  Test-Revision $Repository $Context
  $urlValue = Require-Property $Repository "url" $Context
  if ($null -ne $urlValue) {
    $uri = $null
    if (
      -not [Uri]::TryCreate([string]$urlValue, [UriKind]::Absolute, [ref]$uri) -or
      $uri.Scheme -notin @("https", "ssh")
    ) {
      Add-ValidationError "$Context.url must be an absolute HTTPS or SSH URL."
    }
  }

  $branch = Require-Property $Repository "branch" $Context
  if ([string]::IsNullOrWhiteSpace([string]$branch)) {
    Add-ValidationError "$Context.branch must not be empty."
  }

  if ($null -ne $Repository.PSObject.Properties["submodules"]) {
    foreach ($submodule in @($Repository.submodules)) {
      Require-Property $submodule "path" "$Context.submodules[]" | Out-Null
      Test-Revision $submodule "$Context.submodules[]"
    }
  }
}

function Test-Sha256 {
  param([object]$Value, [string]$Context)

  if ($null -eq $Value -or [string]$Value -notmatch "^[0-9a-fA-F]{64}$") {
    Add-ValidationError "$Context must be a 64-character SHA256."
  } elseif (
    -not $AllowPlaceholders -and
    [string]$Value -eq ("0" * 64)
  ) {
    Add-ValidationError "$Context must replace the all-zero example value."
  }
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
$rawConfig = Get-Content -LiteralPath $resolvedPath -Raw
$config = $rawConfig | ConvertFrom-Json
$script:errors = [System.Collections.Generic.List[string]]::new()

if (-not $AllowPlaceholders -and $rawConfig -match "<[^>]+>") {
  Add-ValidationError "config contains unreplaced <placeholder> values."
}

$schemaVersion = Require-Property $config "schemaVersion" "config"
if ($schemaVersion -ne 1) {
  Add-ValidationError "config.schemaVersion must equal 1."
}

$project = Require-Property $config "project" "config"
$projectId = Require-Property $project "id" "config.project"
if ($null -ne $projectId -and [string]$projectId -notmatch "^[a-z0-9][a-z0-9-]*$") {
  Add-ValidationError "config.project.id must use lowercase letters, digits, and hyphens."
}
Require-Property $project "displayName" "config.project" | Out-Null

$repositories = Require-Property $config "repositories" "config"
$application = Require-Property $repositories "application" "config.repositories"
Test-Repository $application "config.repositories.application"

if ($null -ne $repositories -and $null -ne $repositories.PSObject.Properties["backend"]) {
  Test-Repository $repositories.backend "config.repositories.backend"
}

$target = Require-Property $config "target" "config"
$targetOs = Require-Property $target "os" "config.target"
if ($targetOs -ne "windows") {
  Add-ValidationError "config.target.os must equal windows."
}
$targetArchitecture = Require-Property $target "architecture" "config.target"
if ($targetArchitecture -notin @("arm64", "arm64ec")) {
  Add-ValidationError "config.target.architecture must be arm64 or arm64ec."
}
$compatibilityArchitectures = Require-Property $target "compatibilityArchitectures" "config.target"
foreach ($architecture in @($compatibilityArchitectures)) {
  if ($architecture -notin @("arm64", "arm64ec", "x64", "x86")) {
    Add-ValidationError "config.target.compatibilityArchitectures contains unsupported value '$architecture'."
  }
}

$build = Require-Property $config "build" "config"
Require-Property $build "runner" "config.build" | Out-Null
Require-Property $build "configuration" "config.build" | Out-Null

$artifacts = Require-Property $config "artifacts" "config"
Require-Property $artifacts "evidenceRoot" "config.artifacts" | Out-Null
$nativePolicy = Require-Property $artifacts "nativeFilePolicy" "config.artifacts"
Require-Property $nativePolicy "requiredArchitecture" "config.artifacts.nativeFilePolicy" | Out-Null
$exceptions = Require-Property $nativePolicy "exceptions" "config.artifacts.nativeFilePolicy"
foreach ($exception in @($exceptions)) {
  $exceptionPath = Require-Property $exception "path" "config.artifacts.nativeFilePolicy.exceptions[]"
  $exceptionReason = Require-Property $exception "reason" "config.artifacts.nativeFilePolicy.exceptions[]"
  Require-Property $exception "architectures" "config.artifacts.nativeFilePolicy.exceptions[]" | Out-Null
  if ([string]::IsNullOrWhiteSpace([string]$exceptionPath)) {
    Add-ValidationError "config.artifacts.nativeFilePolicy.exceptions[].path must not be empty."
  }
  if ([string]::IsNullOrWhiteSpace([string]$exceptionReason)) {
    Add-ValidationError "config.artifacts.nativeFilePolicy.exceptions[].reason must not be empty."
  }
}

$validation = Require-Property $config "validation" "config"
$fixture = Require-Property $validation "fixture" "config.validation"
if ($null -ne $fixture) {
  Require-Property $fixture "path" "config.validation.fixture" | Out-Null
  Test-Sha256 (Require-Property $fixture "sha256" "config.validation.fixture") "config.validation.fixture.sha256"
}
if ($null -ne $validation -and $null -ne $validation.PSObject.Properties["providerPolicy"]) {
  $providerPolicy = $validation.providerPolicy
  Require-Property $providerPolicy "api" "config.validation.providerPolicy" | Out-Null
  $allowedIdentifiers = @(
    Require-Property $providerPolicy "allowedIdentifiers" "config.validation.providerPolicy"
  )
  $deniedIdentifiers = @(
    Require-Property $providerPolicy "deniedIdentifiers" "config.validation.providerPolicy"
  )
  $overlap = @($allowedIdentifiers | Where-Object { $_ -in $deniedIdentifiers })
  if ($overlap.Count -gt 0) {
    Add-ValidationError "Provider identifiers cannot be both allowed and denied: $($overlap -join ', ')."
  }
}
Require-Property $validation "offlineRequired" "config.validation" | Out-Null

if ($null -ne $validation -and $null -ne $validation.PSObject.Properties["model"]) {
  $modelFiles = Require-Property $validation.model "files" "config.validation.model"
  foreach ($file in @($modelFiles)) {
    Test-Sha256 (Require-Property $file "sha256" "config.validation.model.files[]") "config.validation.model.files[].sha256"
  }
}

$privacy = Require-Property $config "privacy" "config"
$publicationMode = Require-Property $privacy "publicationMode" "config.privacy"
if ($publicationMode -notin @("private", "public")) {
  Add-ValidationError "config.privacy.publicationMode must be private or public."
}
Require-Property $privacy "requireImageReview" "config.privacy" | Out-Null

if ($errors.Count -gt 0) {
  $message = "Invalid Upshift64 project configuration:`n- " + ($errors -join "`n- ")
  throw $message
}

[pscustomobject]@{
  Path = $resolvedPath
  ProjectId = $project.id
  Architecture = $target.architecture
  PublicationMode = $privacy.publicationMode
  Valid = $true
}
