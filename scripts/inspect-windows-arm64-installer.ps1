[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$InstallerPath,

  [string]$ReportDirectory = ".upshift64\evidence\installer"
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
      throw "$Path is not a PE file (missing MZ signature)."
    }

    $stream.Position = 0x3C
    $peOffset = $reader.ReadUInt32()
    if ($peOffset -gt ($stream.Length - 6)) {
      throw "$Path has an invalid PE header offset."
    }

    $stream.Position = $peOffset
    if ($reader.ReadUInt32() -ne 0x00004550) {
      throw "$Path is not a PE file (missing PE signature)."
    }

    return $reader.ReadUInt16()
  }
  finally {
    $stream.Dispose()
  }
}

$installer = Get-Item -LiteralPath $InstallerPath
if ($installer.Name -notmatch "-win-arm64\.exe$") {
  throw "Installer name must end with -win-arm64.exe, found $($installer.Name)."
}

$machine = Get-PeMachine -Path $installer.FullName
if (-not $machineNames.ContainsKey([int]$machine)) {
  throw "Unknown installer PE machine 0x$($machine.ToString('X4'))."
}

$machineName = $machineNames[[int]$machine]
$bootstrapPolicy = if ($machine -eq 0xAA64) {
  "native-arm64"
}
else {
  "compatibility-bootstrap"
}

$signature = Get-AuthenticodeSignature -LiteralPath $installer.FullName
$report = [ordered]@{
  generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
  installer = $installer.FullName
  name = $installer.Name
  size = $installer.Length
  sha256 = (Get-FileHash -LiteralPath $installer.FullName -Algorithm SHA256).Hash
  peMachine = "0x$($machine.ToString('X4'))"
  architecture = $machineName
  policy = $bootstrapPolicy
  signatureStatus = $signature.Status.ToString()
  signer = if ($signature.SignerCertificate) {
    $signature.SignerCertificate.Subject
  }
  else {
    $null
  }
  scope = "The installer bootstrap is classified separately from the verified ARM64 application payload."
}

$resolvedReportDirectory = [System.IO.Path]::GetFullPath(
  (Join-Path (Get-Location) $ReportDirectory)
)
New-Item -ItemType Directory -Path $resolvedReportDirectory -Force | Out-Null

$jsonPath = Join-Path $resolvedReportDirectory "installer.json"
$markdownPath = Join-Path $resolvedReportDirectory "installer.md"
$report | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $jsonPath -Encoding utf8

@(
  "# Windows ARM64 installer"
  ""
  "- Name: ``$($report.name)``"
  "- Size: $($report.size) bytes"
  "- SHA256: ``$($report.sha256)``"
  "- PE machine: $($report.peMachine) ($($report.architecture))"
  "- Bootstrap policy: **$($report.policy)**"
  "- Signature status: $($report.signatureStatus)"
  "- Signer: $(if ($report.signer) { $report.signer } else { 'unsigned diagnostic artifact' })"
  ""
  $report.scope
) | Set-Content -LiteralPath $markdownPath -Encoding utf8

Write-Output "Installer JSON: $jsonPath"
Write-Output "Installer Markdown: $markdownPath"
Write-Output "Installer bootstrap: $machineName ($bootstrapPolicy)"
