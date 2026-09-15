[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$skillRoot = Split-Path -Parent $PSScriptRoot
$configScript = Join-Path $skillRoot "scripts\Test-Upshift64ProjectConfig.ps1"
$manifestScript = Join-Path $skillRoot "scripts\New-Upshift64EvidenceManifest.ps1"
$exampleConfig = Join-Path $skillRoot "references\project-config.example.json"
$upscaylExampleConfig = Join-Path $skillRoot "references\upscayl-project-config.example.json"
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "upshift64-skill-test-$PID"
$tempRoot = Split-Path -Parent $testRoot
$invalidConfigPath = Join-Path $tempRoot "upshift64-invalid-config-$PID.json"
$noProviderConfigPath = Join-Path $tempRoot "upshift64-no-provider-$PID.json"
$privateJson = Join-Path $tempRoot "upshift64-private-manifest-$PID.json"
$privateCsv = Join-Path $tempRoot "upshift64-private-manifest-$PID.csv"
$publicCleanJson = Join-Path $tempRoot "upshift64-public-clean-manifest-$PID.json"
$publicCleanCsv = Join-Path $tempRoot "upshift64-public-clean-manifest-$PID.csv"
$publicJson = Join-Path $tempRoot "upshift64-public-manifest-$PID.json"
$publicCsv = Join-Path $tempRoot "upshift64-public-manifest-$PID.csv"
$privateNegativeJson = Join-Path $tempRoot "upshift64-private-negative-$PID.json"
$privateNegativeCsv = Join-Path $tempRoot "upshift64-private-negative-$PID.csv"
$allowlistPath = Join-Path $tempRoot "upshift64-privacy-allowlist-$PID.json"
$publicAllowedJson = Join-Path $tempRoot "upshift64-public-allowed-$PID.json"
$publicAllowedCsv = Join-Path $tempRoot "upshift64-public-allowed-$PID.csv"
$imageReviewedJson = Join-Path $tempRoot "upshift64-image-reviewed-$PID.json"
$imageReviewedCsv = Join-Path $tempRoot "upshift64-image-reviewed-$PID.csv"

try {
  $configResult = & $configScript -Path $exampleConfig -AllowPlaceholders
  if (-not $configResult.Valid) {
    throw "Example configuration did not validate."
  }
  $upscaylConfigResult = & $configScript `
    -Path $upscaylExampleConfig `
    -AllowPlaceholders
  if (-not $upscaylConfigResult.Valid) {
    throw "Upscayl example configuration did not validate."
  }

  $placeholderBlocked = $false
  try {
    & $configScript -Path $exampleConfig | Out-Null
  } catch {
    $placeholderBlocked = $_.Exception.Message -match "unreplaced|all-zero"
  }
  if (-not $placeholderBlocked) {
    throw "Unreplaced generic example values were not blocked."
  }

  $noProviderConfig = Get-Content -LiteralPath $exampleConfig -Raw |
    ConvertFrom-Json
  $noProviderConfig.validation.PSObject.Properties.Remove("providerPolicy")
  [IO.File]::WriteAllText(
    $noProviderConfigPath,
    ($noProviderConfig | ConvertTo-Json -Depth 10),
    [Text.UTF8Encoding]::new($false)
  )
  $noProviderResult = & $configScript `
    -Path $noProviderConfigPath `
    -AllowPlaceholders
  if (-not $noProviderResult.Valid) {
    throw "Configuration without an accelerator provider did not validate."
  }

  New-Item -ItemType Directory -Path $testRoot | Out-Null
  $invalidConfig = Get-Content -LiteralPath $exampleConfig -Raw | ConvertFrom-Json
  $invalidConfig.repositories.application.revision = "not-a-full-commit"
  [IO.File]::WriteAllText(
    $invalidConfigPath,
    ($invalidConfig | ConvertTo-Json -Depth 10),
    [Text.UTF8Encoding]::new($false)
  )
  $invalidConfigBlocked = $false
  try {
    & $configScript -Path $invalidConfigPath -AllowPlaceholders | Out-Null
  } catch {
    $invalidConfigBlocked = $_.Exception.Message -match "full 40-character commit"
  }
  if (-not $invalidConfigBlocked) {
    throw "Invalid project configuration fixture was not blocked."
  }

  [IO.File]::WriteAllText(
    (Join-Path $testRoot "evidence.txt"),
    "portable evidence fixture",
    [Text.UTF8Encoding]::new($false)
  )

  $privateResult = & $manifestScript `
    -Root $testRoot `
    -JsonPath $privateJson `
    -CsvPath $privateCsv `
    -Phase "self-test" `
    -PublicationMode Private
  if ($privateResult.FileCount -ne 1 -or $privateResult.UnresolvedPrivacyFindings -ne 0) {
    throw "Private manifest positive fixture failed."
  }

  $publicResult = & $manifestScript `
    -Root $testRoot `
    -JsonPath $publicCleanJson `
    -CsvPath $publicCleanCsv `
    -Phase "self-test" `
    -PublicationMode Public
  if ($publicResult.UnresolvedPrivacyFindings -ne 0) {
    throw "Public manifest positive fixture failed."
  }

  $standaloneTokenFixture = "gh" + "p_" + ("a" * 24)
  $privateKeyHeaderFixture = "-----BEGIN " + "PRIVATE KEY-----"
  $credentialUrlFixture = "https://fixture-user:" +
    "fixture-password@example.test/resource"
  [IO.File]::WriteAllText(
    (Join-Path $testRoot "privacy-negative.txt"),
    @"
token=fixture-value
$standaloneTokenFixture
$privateKeyHeaderFixture
$credentialUrlFixture
fixture-user@example.test
C:/Users/fixture-user/evidence
\\fixture-host\fixture-share
2001:0db8:0000:0000:0000:ff00:0042:8329
hostname=fixture-host
"@,
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    (Join-Path $testRoot "HOST-fixture-user@example.test.log"),
    "filename privacy fixture",
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    (Join-Path $testRoot "extensionless-log"),
    "device_id=fixture-device-123",
    [Text.UTF8Encoding]::new($false)
  )
  [IO.File]::WriteAllText(
    (Join-Path $testRoot "unicode.ini"),
    "password=fixture-unicode",
    [Text.Encoding]::Unicode
  )
  [IO.File]::WriteAllBytes(
    (Join-Path $testRoot "opaque.bin"),
    [byte[]]@(0, 1, 2, 3)
  )

  $publicBlocked = $false
  try {
    & $manifestScript `
      -Root $testRoot `
      -JsonPath $publicJson `
      -CsvPath $publicCsv `
      -Phase "self-test" `
      -PublicationMode Public | Out-Null
  } catch {
    $publicBlocked = $_.Exception.Message -match "unresolved privacy findings"
  }
  if (-not $publicBlocked) {
    throw "Public manifest negative fixture was not blocked."
  }

  & $manifestScript `
    -Root $testRoot `
    -JsonPath $privateNegativeJson `
    -CsvPath $privateNegativeCsv `
    -Phase "self-test" `
    -PublicationMode Private | Out-Null
  $negativeRecord = Get-Content -LiteralPath $privateNegativeJson -Raw |
    ConvertFrom-Json
  $requiredCategories = @(
    "Credential",
    "AccessToken",
    "PrivateKey",
    "CredentialUrl",
    "EmailAddress",
    "UserPath",
    "UncPath",
    "IPv6",
    "MachineIdentifier"
  )
  foreach ($category in $requiredCategories) {
    if ($category -notin @($negativeRecord.privacyFindings.category)) {
      throw "Private manifest did not record the $category fixture."
    }
  }
  $filenameFinding = @(
    $negativeRecord.privacyFindings |
      Where-Object {
        $_.path -eq "HOST-fixture-user@example.test.log" -and
        $_.category -eq "EmailAddress" -and
        $_.line -eq 0
      }
  )
  if ($filenameFinding.Count -ne 1) {
    throw "Private manifest did not record the filename privacy fixture."
  }
  $extensionlessFinding = @(
    $negativeRecord.privacyFindings |
      Where-Object {
        $_.path -eq "extensionless-log" -and
        $_.category -eq "MachineIdentifier"
      }
  )
  if ($extensionlessFinding.Count -ne 1) {
    throw "Private manifest did not scan the extensionless text fixture."
  }
  $unicodeFinding = @(
    $negativeRecord.privacyFindings |
      Where-Object {
        $_.path -eq "unicode.ini" -and
        $_.category -eq "Credential"
      }
  )
  if ($unicodeFinding.Count -ne 1) {
    throw "Private manifest did not scan the Unicode text fixture."
  }
  @(
    $negativeRecord.privacyFindings | ForEach-Object {
      [pscustomobject]@{
        path = $_.path
        category = $_.category
        matchSha256 = $_.matchSha256
        rationale = "Synthetic negative-test fixture."
      }
    }
  ) | ConvertTo-Json | Set-Content -LiteralPath $allowlistPath -Encoding utf8

  $nonTextBlocked = $false
  try {
    & $manifestScript `
      -Root $testRoot `
      -JsonPath $publicAllowedJson `
      -CsvPath $publicAllowedCsv `
      -Phase "self-test" `
      -PublicationMode Public `
      -PrivacyAllowlistPath $allowlistPath | Out-Null
  } catch {
    $nonTextBlocked = $_.Exception.Message -match "pass -NonTextFilesReviewed"
  }
  if (-not $nonTextBlocked) {
    throw "Public non-text review gate fixture was not blocked."
  }

  $allowedResult = & $manifestScript `
    -Root $testRoot `
    -JsonPath $publicAllowedJson `
    -CsvPath $publicAllowedCsv `
    -Phase "self-test" `
    -PublicationMode Public `
    -PrivacyAllowlistPath $allowlistPath `
    -NonTextFilesReviewed
  if ($allowedResult.UnresolvedPrivacyFindings -ne 0) {
    throw "Exact match-hash allowlist fixture failed."
  }

  [IO.File]::WriteAllBytes((Join-Path $testRoot "manual-review.png"), [byte[]]@())
  $imageBlocked = $false
  try {
    & $manifestScript `
      -Root $testRoot `
      -JsonPath $imageReviewedJson `
      -CsvPath $imageReviewedCsv `
      -Phase "self-test" `
      -PublicationMode Public `
      -PrivacyAllowlistPath $allowlistPath `
      -NonTextFilesReviewed | Out-Null
  } catch {
    $imageBlocked = $_.Exception.Message -match "pass -ImagesReviewed"
  }
  if (-not $imageBlocked) {
    throw "Public image-review gate fixture was not blocked."
  }

  $imageResult = & $manifestScript `
    -Root $testRoot `
    -JsonPath $imageReviewedJson `
    -CsvPath $imageReviewedCsv `
    -Phase "self-test" `
    -Status published `
    -PublicationMode Public `
    -PrivacyAllowlistPath $allowlistPath `
    -NonTextFilesReviewed `
    -ImagesReviewed
  if ($imageResult.ImageCount -ne 1) {
    throw "Reviewed-image public manifest fixture failed."
  }

  [pscustomobject]@{
    ConfigValidation = "PASS"
    UpscaylExample = "PASS"
    PlaceholderGate = "PASS"
    OptionalProvider = "PASS"
    InvalidConfigGate = "PASS"
    PrivateManifest = "PASS"
    PublicManifest = "PASS"
    PublicPrivacyGate = "PASS"
    ExtendedPrivacyPatterns = "PASS"
    FilenamePrivacyGate = "PASS"
    MatchHashAllowlist = "PASS"
    NonTextReviewGate = "PASS"
    PublicImageReviewGate = "PASS"
  }
} finally {
  $cleanup = @(
    $testRoot,
    $invalidConfigPath,
    $noProviderConfigPath,
    $privateJson,
    $privateCsv,
    $publicCleanJson,
    $publicCleanCsv,
    $publicJson,
    $publicCsv,
    $privateNegativeJson,
    $privateNegativeCsv,
    $allowlistPath,
    $publicAllowedJson,
    $publicAllowedCsv,
    $imageReviewedJson,
    $imageReviewedCsv
  )
  foreach ($path in $cleanup) {
    if (Test-Path -LiteralPath $path) {
      Remove-Item -LiteralPath $path -Recurse -Force
    }
  }
}
