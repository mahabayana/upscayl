[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$Root,

  [Parameter(Mandatory)]
  [string]$JsonPath,

  [Parameter(Mandatory)]
  [string]$CsvPath,

  [Parameter(Mandatory)]
  [string]$Phase,

  [ValidateSet(
    "not-started",
    "approved",
    "running",
    "blocked",
    "partial",
    "passed",
    "published"
  )]
  [string]$Status = "passed",

  [ValidateSet("Private", "Public")]
  [string]$PublicationMode = "Private",

  [string]$PrivacyAllowlistPath,

  [switch]$ImagesReviewed,

  [switch]$NonTextFilesReviewed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-TextSha256 {
  param([string]$Value)

  $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try {
    return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace("-", "")
  } finally {
    $algorithm.Dispose()
  }
}

function Get-RelativePathPortable {
  param([string]$BasePath, [string]$ChildPath)

  $baseUri = [Uri](([IO.Path]::GetFullPath($BasePath).TrimEnd("\") + "\"))
  $childUri = [Uri][IO.Path]::GetFullPath($ChildPath)
  return [Uri]::UnescapeDataString(
    $baseUri.MakeRelativeUri($childUri).ToString()
  )
}

function Test-LikelyTextFile {
  param([string]$Path)

  $stream = [IO.File]::OpenRead($Path)
  try {
    $length = [Math]::Min(8192, $stream.Length)
    if ($length -eq 0) {
      return $true
    }

    $bytes = [byte[]]::new($length)
    [void]$stream.Read($bytes, 0, $length)
    $hasUnicodeBom = (
      ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or
      ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) -or
      ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    )
    if ($hasUnicodeBom) {
      return $true
    }
    if ($bytes -contains 0) {
      return $false
    }

    try {
      [void][Text.UTF8Encoding]::new($false, $true).GetString($bytes)
      return $true
    } catch [Text.DecoderFallbackException] {
      return $false
    }
  } finally {
    $stream.Dispose()
  }
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
  throw "Root must be a directory."
}
$jsonFullPath = [IO.Path]::GetFullPath($JsonPath)
$csvFullPath = [IO.Path]::GetFullPath($CsvPath)
if ($jsonFullPath -eq $csvFullPath) {
  throw "JsonPath and CsvPath must be different files."
}

$allowlist = @()
if ($PrivacyAllowlistPath) {
  $allowlist = @(
    Get-Content -LiteralPath $PrivacyAllowlistPath -Raw | ConvertFrom-Json
  )
}

$imageExtensions = @(".bmp", ".gif", ".jpeg", ".jpg", ".png", ".webp")
$privacyPatterns = [ordered]@{
  Credential = "(?i)\b(authorization|bearer|password|passwd|secret|api[_-]?key|token)\b[`"']?\s*[:=]\s*[`"']?\S+"
  AccessToken = "(?i)\b(?:gh[pousr]_[a-z0-9]{20,}|github_pat_[a-z0-9_]{20,}|(?:AKIA|ASIA)[0-9A-Z]{16}|eyJ[a-z0-9_-]{10,}\.[a-z0-9_-]{10,}\.[a-z0-9_-]{10,})\b"
  PrivateKey = "-----BEGIN (?:[A-Z0-9]+ )?PRIVATE KEY-----"
  CredentialUrl = "(?i)\b(?:https?|ssh|git)://[^/\s:@]+:[^@\s/]+@[^\s/]+"
  EmailAddress = "(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"
  UserPath = "(?i)\b[A-Z]:[\\/]+Users[\\/]+(?!<user>(?:[\\/]|$))[^\\/\s]+"
  UncPath = "(?i)(?<!\\)\\\\(?![.?]\\)[^\\\s]+\\[^\\\s]+"
  IPv4 = "(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])"
  IPv6 = "(?i)(?<![0-9a-f:])(?:[0-9a-f]{1,4}:){2,7}[0-9a-f]{1,4}(?![0-9a-f:])"
  MacAddress = "(?i)\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b"
  Guid = "(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b"
  MachineIdentifier = "(?i)\b(hostname|computername|machine[_-]?id|device[_-]?id|serial(?:number)?)\b[`"']?\s*[:=]\s*[`"']?\S+"
}

$files = @(
  Get-ChildItem -LiteralPath $rootPath -File -Recurse |
    Where-Object {
      $_.FullName -ne $jsonFullPath -and
      $_.FullName -ne $csvFullPath
    } |
    Sort-Object FullName
)
if ($files.Count -eq 0) {
  throw "Evidence root contains no files."
}

$findings = [System.Collections.Generic.List[object]]::new()
$nonTextFiles = [System.Collections.Generic.List[string]]::new()
foreach ($file in $files) {
  $relativePath = Get-RelativePathPortable $rootPath $file.FullName
  foreach ($entry in $privacyPatterns.GetEnumerator()) {
    foreach ($match in [regex]::Matches($relativePath, $entry.Value)) {
      $matchSha256 = Get-TextSha256 $match.Value
      $allowed = @(
        $allowlist | Where-Object {
          $_.path -eq $relativePath -and
          $_.category -eq $entry.Key -and
          $_.matchSha256 -eq $matchSha256 -and
          -not [string]::IsNullOrWhiteSpace($_.rationale)
        }
      ) | Select-Object -First 1

      $findings.Add([pscustomobject]@{
        path = $relativePath
        line = 0
        category = $entry.Key
        matchSha256 = $matchSha256
        allowlisted = $null -ne $allowed
        rationale = if ($null -ne $allowed) {
          [string]$allowed.rationale
        } else {
          ""
        }
      })
    }
  }

  if ($file.Extension.ToLowerInvariant() -in $imageExtensions) {
    continue
  }

  if (-not (Test-LikelyTextFile $file.FullName)) {
    $nonTextFiles.Add($relativePath)
    continue
  }

  $lineNumber = 0
  $reader = [IO.StreamReader]::new(
    $file.FullName,
    [Text.UTF8Encoding]::new($false, $true),
    $true
  )
  try {
    while (-not $reader.EndOfStream) {
      $line = $reader.ReadLine()
      $lineNumber++
      foreach ($entry in $privacyPatterns.GetEnumerator()) {
        foreach ($match in [regex]::Matches($line, $entry.Value)) {
          $matchSha256 = Get-TextSha256 $match.Value
          $allowed = @(
            $allowlist | Where-Object {
              $_.path -eq $relativePath -and
              $_.category -eq $entry.Key -and
              $_.matchSha256 -eq $matchSha256 -and
              -not [string]::IsNullOrWhiteSpace($_.rationale)
            }
          ) | Select-Object -First 1

          $findings.Add([pscustomobject]@{
            path = $relativePath
            line = $lineNumber
            category = $entry.Key
            matchSha256 = $matchSha256
            allowlisted = $null -ne $allowed
            rationale = if ($null -ne $allowed) {
              [string]$allowed.rationale
            } else {
              ""
            }
          })
        }
      }
    }
  } catch [Text.DecoderFallbackException] {
    $nonTextFiles.Add($relativePath)
  } finally {
    $reader.Dispose()
  }
}

$imageCount = @(
  $files | Where-Object { $_.Extension.ToLowerInvariant() -in $imageExtensions }
).Count
$unresolvedFindings = @($findings | Where-Object { -not $_.allowlisted })

if ($PublicationMode -eq "Public") {
  if ($unresolvedFindings.Count -gt 0) {
    $locations = $unresolvedFindings |
      ForEach-Object { "$($_.path):$($_.line) [$($_.category)]" }
    throw "Public evidence has unresolved privacy findings:`n- $($locations -join "`n- ")"
  }
  if ($imageCount -gt 0 -and -not $ImagesReviewed) {
    throw "Public evidence contains $imageCount image(s); pass -ImagesReviewed only after manual review."
  }
  if ($nonTextFiles.Count -gt 0 -and -not $NonTextFilesReviewed) {
    throw "Public evidence contains $($nonTextFiles.Count) non-text file(s); pass -NonTextFilesReviewed only after manual review."
  }
}
if ($Status -eq "published" -and $PublicationMode -ne "Public") {
  throw "Status published requires PublicationMode Public."
}

$fileRecords = @(
  $files | ForEach-Object {
    [pscustomobject]@{
      path = Get-RelativePathPortable $rootPath $_.FullName
      bytes = $_.Length
      sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
  }
)

$record = [ordered]@{
  schemaVersion = 1
  generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
  phase = $Phase
  status = $Status
  publicationMode = $PublicationMode.ToLowerInvariant()
  privacy = [ordered]@{
    potentialFindingCount = $findings.Count
    unresolvedFindingCount = $unresolvedFindings.Count
    imageCount = $imageCount
    imagesReviewed = [bool]$ImagesReviewed
    nonTextFileCount = $nonTextFiles.Count
    nonTextFilesReviewed = [bool]$NonTextFilesReviewed
  }
  privacyFindings = @($findings)
  files = $fileRecords
}

foreach ($outputPath in @($jsonFullPath, $csvFullPath)) {
  $parent = Split-Path -Parent $outputPath
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
}

$utf8NoBom = [Text.UTF8Encoding]::new($false)
$json = $record | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($jsonFullPath, $json + [Environment]::NewLine, $utf8NoBom)

$csvLines = $fileRecords | ConvertTo-Csv -NoTypeInformation
[IO.File]::WriteAllLines($csvFullPath, $csvLines, $utf8NoBom)

[pscustomobject]@{
  Root = $rootPath
  FileCount = $fileRecords.Count
  JsonPath = $jsonFullPath
  JsonSha256 = (Get-FileHash -LiteralPath $jsonFullPath -Algorithm SHA256).Hash
  CsvPath = $csvFullPath
  CsvSha256 = (Get-FileHash -LiteralPath $csvFullPath -Algorithm SHA256).Hash
  PotentialPrivacyFindings = $findings.Count
  UnresolvedPrivacyFindings = $unresolvedFindings.Count
  ImageCount = $imageCount
  NonTextFileCount = $nonTextFiles.Count
  PublicationMode = $PublicationMode
}
