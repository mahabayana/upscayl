# Step 011: Validate the full Windows ARM64 application on Snapdragon X

- **Execution timestamp (UTC):** `2026-09-15T19:24:21Z`
- **Independent evidence review (UTC):** `2026-09-15T20:27:04Z`
- **Objective:** Validate installation, installed-tree architecture closure,
  a fixed GUI journey, and offline inference for the packaged Windows ARM64
  Upscayl application on physical Snapdragon X hardware.
- **Owner approvals:** Sequential device-side approvals covered inventory,
  staging, installation, installed closure, GUI execution, and offline
  execution. The owner reserved adapter disable/enable actions and performed
  them personally. Uninstall was explicitly deferred.
- **Device-side agent/model:** GitHub Copilot CLI / Claude Sonnet 5
- **Independent review agent/model:** GitHub Copilot CLI / GPT-5.6 Sol
- **Skill:** `upshift64-port`
- **Starting documentation commit:** `6855a2b7acb0f7e11f04c1851142e85d7471908f`
- **Commit:** Not created at time of writing
- **Pull request:** Not created
- **CI:** Not run; this was physical-device validation of the Step 10 CI
  artifact.

## Artifact chain

- Package source commit:
  `e3fb24064e9eedfe700c039cde43cc4a59f8705c`
- Workflow run:
  <https://github.com/mahabayana/upscayl/actions/runs/34936161073>
- Artifact: `upscayl-windows-arm64-diagnostics-34936161073-1`,
  ID `10384470075`
- Transferred artifact size: 1,010,069,274 bytes
- Transferred artifact SHA256:
  `8D0E4FE6ED6386B6ED60D04AE1234C976EC3D91CE3295829101CE331DD5ECF39`
- Installer SHA256:
  `29A4778DFB85F5F5EDF3D447F7B18BA1B794A259DDE6571E8610B3B86A258769`
- Received evidence ZIP SHA256:
  `9B373A6769907985B8D1DAF18FD19AA3FD4A8498CC5A26E1AF20A61AA84B5675`

## Observed results

- The all-users diagnostic installer completed and installed Upscayl 2.15.0.
- Package comparison found 601 matching files, no missing or changed files,
  and one expected installer-generated x86 uninstaller.
- Recursive inspection covered 49 installed native files. Application,
  backend, OpenMP, Electron/Chromium, and top-level Vulkan binaries are ARM64.
  Exact-path `resources\elevate.exe`, the generated uninstaller, and ExifTool
  are the only declared non-ARM64 compatibility boundaries.
- Sharp is build-time-only and was not packaged; its ARM64 module was verified
  during Step 10 CI.
- The GUI launched, selected the fixed input, cancelled and recovered, ran a
  successful 4x upscale through the native Qualcomm provider, and opened the
  output with the OS default handler.
- Output dimensions, size, and SHA256 matched the established deterministic
  fixture result.
- The accepted offline attempt recorded failed connectivity checks after
  disable and immediately before restore, an output creation time inside the
  interval, an explicit NetworkProfile disconnect event, and a successful
  independent post-restore connectivity check.

## Independent evidence corrections

The independent review corrected four overstatements in the device-generated
draft:

1. Sharp is not an installed ARM64 file; it is a build-time-only dependency.
2. The accepted NetworkProfile CSV has one explicit disconnect event and
   generic state-change events, not an explicit reconnect event.
3. The correct retained event interval is 11:31-11:33 local
   (18:31-18:33 UTC), not the 10:31-10:33 text in the preliminary summary.
4. Architecture-specific package naming was already proven in Step 10.

The archive omitted the two curated manifest files named in the preliminary
report. The reviewer therefore generated fresh CSV and JSON manifests over
all 61 received files:

- CSV SHA256:
  `47088F3416E2C03B78A6FA6B6AD077ABEFD72553F96FCF34C622E0E018A7C53C`
- JSON SHA256:
  `A9C96CFBE470CF59205D245BD3FE4918D512CDE4012D474255B8C4AC325F7B44`

The review also found public endpoint IP addresses, network GUIDs in a
superseded attempt, and screenshots with unrelated desktop/session details.
The raw archive is retained as private validation evidence and must not be
published unchanged. A public subset requires redaction, application-only
cropping, and a post-redaction manifest.

## Decision

**Step 11 passes its validation scope.** Evidence quality issues affect public
release of the raw bundle, not the demonstrated installed architecture, GUI,
native Qualcomm inference, or offline result. Signing, updater behavior,
uninstall, release publication, performance, energy efficiency, and
additional hardware remain unproven.
