[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$PayloadRoot,

  [string]$StagingRoot = ".upshift64\staging\win-arm64\bin",

  [string]$BackendSha256 = "55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F",

  [string]$OpenMpSha256 = "1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71",

  [string]$ReportPath = ".upshift64\evidence\staged-payload.json"
)

$ErrorActionPreference = "Stop"

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

function Get-UniquePayloadFile {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Name
  )

  $matches = @(Get-ChildItem -LiteralPath $Root -File -Recurse |
    Where-Object { $_.Name -ieq $Name })

  if ($matches.Count -ne 1) {
    throw "Expected exactly one $Name under $Root, found $($matches.Count)."
  }

  return $matches[0]
}

function Assert-Sha256 {
  param(
    [Parameter(Mandatory = $true)][System.IO.FileInfo]$File,
    [Parameter(Mandatory = $true)][string]$Expected
  )

  $actual = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash
  if ($actual -ne $Expected) {
    throw "SHA256 mismatch for $($File.Name): expected $Expected, found $actual."
  }

  return $actual
}

$resolvedPayloadRoot = (Resolve-Path -LiteralPath $PayloadRoot).Path
$backend = Get-UniquePayloadFile -Root $resolvedPayloadRoot -Name "upscayl-bin.exe"
$openMp = Get-UniquePayloadFile -Root $resolvedPayloadRoot -Name "vcomp140.dll"

$forbidden = @(Get-ChildItem -LiteralPath $resolvedPayloadRoot -File -Recurse |
  Where-Object { $_.Name -iin @("vcomp140d.dll", "vulkan-1.dll") })
if ($forbidden.Count -gt 0) {
  throw "Forbidden payload file(s): $($forbidden.FullName -join ', ')."
}

$backendHash = Assert-Sha256 -File $backend -Expected $BackendSha256
$openMpHash = Assert-Sha256 -File $openMp -Expected $OpenMpSha256

foreach ($file in @($backend, $openMp)) {
  $machine = Get-PeMachine -Path $file.FullName
  if ($machine -ne 0xAA64) {
    throw "$($file.Name) is not ARM64: PE machine is 0x$($machine.ToString('X4'))."
  }
}

$signature = Get-AuthenticodeSignature -LiteralPath $openMp.FullName
if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "Microsoft Corporation") {
  throw "vcomp140.dll does not have a valid Microsoft signature."
}

$resolvedStagingRoot = [System.IO.Path]::GetFullPath(
  (Join-Path (Get-Location) $StagingRoot)
)
if (Test-Path -LiteralPath $resolvedStagingRoot) {
  Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $resolvedStagingRoot -Force | Out-Null

Copy-Item -LiteralPath $backend.FullName -Destination $resolvedStagingRoot
Copy-Item -LiteralPath $openMp.FullName -Destination $resolvedStagingRoot

$report = [ordered]@{
  generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
  sourceRoot = $resolvedPayloadRoot
  stagingRoot = $resolvedStagingRoot
  files = @(
    [ordered]@{
      name = "upscayl-bin.exe"
      sha256 = $backendHash
      machine = "0xAA64"
    },
    [ordered]@{
      name = "vcomp140.dll"
      sha256 = $openMpHash
      machine = "0xAA64"
      signatureStatus = $signature.Status.ToString()
      signer = $signature.SignerCertificate.Subject
    }
  )
}

$resolvedReportPath = [System.IO.Path]::GetFullPath(
  (Join-Path (Get-Location) $ReportPath)
)
New-Item -ItemType Directory -Path (Split-Path $resolvedReportPath) -Force | Out-Null
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $resolvedReportPath -Encoding utf8

Write-Output "Staged verified Windows ARM64 payload at $resolvedStagingRoot"
Write-Output "Evidence report: $resolvedReportPath"
