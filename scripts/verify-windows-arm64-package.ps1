[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$PackageRoot,

  [string]$AsarExtractRoot,

  [string]$ReportDirectory = ".upshift64\evidence\package-closure",

  [Parameter(Mandatory = $true)]
  [ValidatePattern("^[0-9A-Fa-f]{64}$")]
  [string]$BackendSha256,

  [Parameter(Mandatory = $true)]
  [ValidatePattern("^[0-9A-Fa-f]{64}$")]
  [string]$OpenMpSha256
)

$ErrorActionPreference = "Stop"

$machineNames = @{
  0x014C = "x86"
  0x8664 = "x64"
  0xAA64 = "ARM64"
  0xA641 = "ARM64EC"
}

function Get-PeMachine {
  param([Parameter(Mandatory = $true)][string]$Path)

  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $reader = [System.IO.BinaryReader]::new($stream)
    if ($reader.ReadUInt16() -ne 0x5A4D) {
      throw "Missing MZ signature."
    }

    $stream.Position = 0x3C
    $peOffset = $reader.ReadUInt32()
    if ($peOffset -gt ($stream.Length - 6)) {
      throw "Invalid PE header offset."
    }

    $stream.Position = $peOffset
    if ($reader.ReadUInt32() -ne 0x00004550) {
      throw "Missing PE signature."
    }

    return $reader.ReadUInt16()
  }
  finally {
    $stream.Dispose()
  }
}

function Get-RelativePortablePath {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Path
  )

  return [System.IO.Path]::GetRelativePath($Root, $Path).Replace("\", "/")
}

$resolvedPackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
$scanRoots = @(
  [ordered]@{
    label = "package"
    path = $resolvedPackageRoot
  }
)

if ($AsarExtractRoot) {
  $resolvedAsarRoot = (Resolve-Path -LiteralPath $AsarExtractRoot).Path
  $scanRoots += [ordered]@{
    label = "app.asar"
    path = $resolvedAsarRoot
  }
}

$forbiddenNames = @("vcomp140d.dll")
$results = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($scanRoot in $scanRoots) {
  $files = Get-ChildItem -LiteralPath $scanRoot.path -File -Recurse |
    Where-Object { $_.Extension -iin @(".exe", ".dll", ".node") }

  foreach ($file in $files) {
    $relativePath = Get-RelativePortablePath -Root $scanRoot.path -Path $file.FullName
    $displayPath = "$($scanRoot.label):$relativePath"
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    $machine = $null
    $machineName = "invalid"
    $policy = "reject"
    $reason = ""

    try {
      $machine = Get-PeMachine -Path $file.FullName
      $machineName = if ($machineNames.ContainsKey([int]$machine)) {
        $machineNames[[int]$machine]
      }
      else {
        "0x$($machine.ToString('X4'))"
      }

      $isExifTool = $relativePath -match "(^|/)exiftool(?:-vendored)?(?:\.exe)?(/|$)" -or
        $file.Name -match "^exiftool(?:\(-k\))?\.exe$"
      $isNsisElevateHelper = $scanRoot.label -eq "package" -and
        $relativePath -eq "resources/elevate.exe"

      if ($machine -eq 0xAA64) {
        $policy = "native"
        $reason = "Native Windows ARM64"
      }
      elseif ($isExifTool -and $machine -in @(0x014C, 0x8664)) {
        $policy = "approved-emulation"
        $reason = "Declared ExifTool compatibility exception"
      }
      elseif ($isNsisElevateHelper -and $machine -eq 0x014C) {
        $policy = "approved-emulation"
        $reason = "Required electron-builder NSIS elevation helper"
      }
      else {
        $reason = "Undeclared non-ARM64 PE file"
        $failures.Add("$displayPath is $machineName.")
      }
    }
    catch {
      $reason = $_.Exception.Message
      $failures.Add("$displayPath is not a valid PE file: $reason")
    }

    $isElectronVulkanLoader = $scanRoot.label -eq "package" -and
      $relativePath -eq "vulkan-1.dll"
    if ($file.Name -iin $forbiddenNames -or
      ($file.Name -ieq "vulkan-1.dll" -and -not $isElectronVulkanLoader)) {
      $policy = "reject"
      $reason = "Forbidden backend-local runtime"
      $failures.Add("$displayPath is forbidden.")
    }

    $results.Add([ordered]@{
      source = $scanRoot.label
      path = $relativePath
      size = $file.Length
      sha256 = $hash
      machine = $machineName
      policy = $policy
      reason = $reason
    })
  }
}

$backendPath = Join-Path $resolvedPackageRoot "resources\bin\upscayl-bin.exe"
$openMpPath = Join-Path $resolvedPackageRoot "resources\bin\vcomp140.dll"
$modelsPath = Join-Path $resolvedPackageRoot "resources\models"
$requiredFiles = @(
  [ordered]@{ name = "ARM64 backend"; path = $backendPath; sha256 = $BackendSha256 },
  [ordered]@{ name = "ARM64 OpenMP runtime"; path = $openMpPath; sha256 = $OpenMpSha256 }
)

foreach ($required in $requiredFiles) {
  if (-not (Test-Path -LiteralPath $required.path -PathType Leaf)) {
    $failures.Add("Missing $($required.name) at $($required.path).")
    continue
  }

  $actualHash = (Get-FileHash -LiteralPath $required.path -Algorithm SHA256).Hash
  if ($actualHash -ne $required.sha256) {
    $failures.Add(
      "$($required.name) hash mismatch: expected $($required.sha256), found $actualHash."
    )
  }
}

if (-not (Test-Path -LiteralPath $modelsPath -PathType Container)) {
  $failures.Add("Missing packaged models directory at $modelsPath.")
}
elseif (@(Get-ChildItem -LiteralPath $modelsPath -File -Recurse).Count -eq 0) {
  $failures.Add("Packaged models directory is empty at $modelsPath.")
}

$appExecutables = @(Get-ChildItem -LiteralPath $resolvedPackageRoot -File -Filter "*.exe")
if ($appExecutables.Count -ne 1) {
  $failures.Add(
    "Expected exactly one top-level Electron executable, found $($appExecutables.Count)."
  )
}

$report = [ordered]@{
  generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
  packageRoot = $resolvedPackageRoot
  asarExtractRoot = if ($AsarExtractRoot) { $resolvedAsarRoot } else { $null }
  approvedExceptions = @(
    "ExifTool may use Windows x86/x64 emulation."
    "The electron-builder NSIS helper at resources/elevate.exe may use Windows x86 emulation."
  )
  files = @($results | Sort-Object source, path)
  failures = @($failures)
  passed = $failures.Count -eq 0
}

$resolvedReportDirectory = [System.IO.Path]::GetFullPath(
  (Join-Path (Get-Location) $ReportDirectory)
)
New-Item -ItemType Directory -Path $resolvedReportDirectory -Force | Out-Null

$jsonPath = Join-Path $resolvedReportDirectory "package-closure.json"
$markdownPath = Join-Path $resolvedReportDirectory "package-closure.md"
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding utf8

$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add("# Windows ARM64 package closure")
$markdown.Add("")
$markdown.Add("- Result: **$(if ($report.passed) { 'PASS' } else { 'FAIL' })**")
$markdown.Add("- Package: ``$resolvedPackageRoot``")
$markdown.Add("- Native files inspected: $($results.Count)")
$markdown.Add("- Approved exception: ExifTool x86/x64 under Windows emulation")
$markdown.Add("- Approved exception: electron-builder NSIS resources/elevate.exe x86 helper")
$markdown.Add("")
$markdown.Add("| Source | Path | Machine | Policy | SHA256 |")
$markdown.Add("| --- | --- | --- | --- | --- |")
foreach ($result in $report.files) {
  $markdown.Add(
    "| $($result.source) | ``$($result.path)`` | $($result.machine) | $($result.policy) | ``$($result.sha256)`` |"
  )
}

if ($failures.Count -gt 0) {
  $markdown.Add("")
  $markdown.Add("## Failures")
  $markdown.Add("")
  foreach ($failure in $failures) {
    $markdown.Add("- $failure")
  }
}

$markdown | Set-Content -LiteralPath $markdownPath -Encoding utf8

Write-Output "Package closure JSON: $jsonPath"
Write-Output "Package closure Markdown: $markdownPath"

if ($failures.Count -gt 0) {
  throw "Windows ARM64 package closure failed with $($failures.Count) issue(s)."
}

Write-Output "Windows ARM64 package closure passed."
