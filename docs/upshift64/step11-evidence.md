# Step 11 evidence: installed Windows ARM64 application on Snapdragon X

## Result

**PASS.** The installed Windows ARM64 Upscayl 2.15.0 application passed
package-reference comparison, recursive native-binary closure, the agreed GUI
journey, and offline inference on a physical Snapdragon X-class Windows
device.

This extends the backend-only proof in
[`tier1-evidence.md`](tier1-evidence.md) to the packaged application. It does
not prove signing, updating, uninstall, release publication, performance, or
energy efficiency.

## Provenance

| Item | Value |
| --- | --- |
| Application repository | <https://github.com/mahabayana/upscayl> |
| Branch | `hackathon/upshift64-win-arm64` |
| Package source commit | `e3fb24064e9eedfe700c039cde43cc4a59f8705c` |
| Workflow run | <https://github.com/mahabayana/upscayl/actions/runs/34936161073> |
| Artifact | `upscayl-windows-arm64-diagnostics-34936161073-1` (ID `10384470075`) |
| Artifact SHA256 | `8D0E4FE6ED6386B6ED60D04AE1234C976EC3D91CE3295829101CE331DD5ECF39` |
| Installer | `upscayl-2.15.0-win-arm64.exe`, 282,727,113 bytes |
| Installer SHA256 | `29A4778DFB85F5F5EDF3D447F7B18BA1B794A259DDE6571E8610B3B86A258769` |
| Received evidence ZIP SHA256 | `9B373A6769907985B8D1DAF18FD19AA3FD4A8498CC5A26E1AF20A61AA84B5675` |

The owner transferred the artifact and evidence archive to the device. Their
hashes were independently verified before use.

## Installed architecture closure

- Install location: `C:\Program Files (x86)\Upscayl`, expected for the
  all-users x86 NSIS compatibility bootstrap.
- All 601 files in `dist\win-arm64-unpacked` matched the installed copies by
  hash. No reference file was missing or changed.
- The sole added file was installer-generated `Uninstall Upscayl.exe`, an
  approved x86 compatibility bootstrap.
- All 49 installed native files were inspected.
- `Upscayl.exe`, `upscayl-bin.exe`, `vcomp140.dll`, Electron/Chromium native
  libraries, and the top-level `vulkan-1.dll` are ARM64.
- `resources\app.asar` matched the package reference:
  `E86262FAA3888AC02B8FFC9B926311D48503882DF9B387E5D9E62A8FEC281245`.
- Declared non-ARM64 boundaries were limited to the generated uninstaller,
  exact-path x86 `resources\elevate.exe`, and ExifTool's x64 runtime.
- No debug runtime, backend-local Vulkan loader, missing file, changed file, or
  unexplained native payload was found.
- Sharp is build-time-only. Its ARM64 native module was verified in Step 10 CI
  and is correctly absent from the installed application.

## GUI journey

The fixed input was a 256x256 JPEG with SHA256
`8E9EB94064D1776381B7364AF571AF7953407586B8FF4267FCA3B881D671EE5C`.
The selected model was `upscayl-standard-4x`; tile size `200` was reused from
the separately proven Step 8 device result.

| Journey | Observed result |
| --- | --- |
| Launch | Responsive Upscayl 2.15.0 window |
| Input | Fixed image selected and displayed through the normal UI |
| Cancellation | Backend processes stopped; Reset Image returned the UI fully to idle |
| Successful inference | Native Qualcomm Adreno Vulkan provider selected; Dozen and Basic Render Driver were enumerated but not selected |
| Output | 1024x1024 PNG, 1,952,322 bytes, SHA256 `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269` |
| Output opening | Windows default Photos handler opened the result |

The app has no single-image Open Folder control, so opening the result through
the operating-system handler is the applicable journey. UI automation did not
reliably control every dialog; the owner performed bounded clicks while the
agent retained logs and screenshots.

## Offline proof

The accepted third attempt ran from
`2026-09-15T18:31:12.1286072Z` through
`2026-09-15T18:33:11.2344523Z`.

- Connectivity was available before adapter disable.
- `TcpTestSucceeded=False` was recorded after disable and again immediately
  before restore.
- The app launch was recorded at 11:31:24 local.
- A fresh 1024x1024 output was created at 11:32:41 local, inside the offline
  interval.
- The retained NetworkProfile CSV contains an explicit `Network Disconnected`
  event at 11:31:12 and subsequent state-change events. It does not contain an
  explicit reconnect event.
- A separate post-restore check records `TcpTestSucceeded=True`, proving
  networking restoration independently of the NetworkProfile CSV.

The offline output is byte-identical to the earlier successful GUI and Step 8
backend outputs. This is expected for the deterministic fixture. Freshness is
established by moving prior outputs away before the accepted attempt and by
the new file creation time inside the offline interval, not by hash
difference.

Attempts 1 and 2 were retained. Attempt 1 exposed a stale-output problem;
attempt 2 created a fresh result but lacked the requested live screenshot;
attempt 3 supplied the accepted timestamp, connectivity, log, and output
evidence. The attempt-3 screenshot was captured after network restoration and
is supplementary only.

## Evidence audit and publication status

The received archive contains 61 files. The two device-side curated manifest
files cited by the original report were not included, so their claimed digest
could not be verified. An independent manifest was regenerated from every
received file; its CSV SHA256 is
`47088F3416E2C03B78A6FA6B6AD077ABEFD72553F96FCF34C622E0E018A7C53C`
and its JSON SHA256 is
`A9C96CFBE470CF59205D245BD3FE4918D512CDE4012D474255B8C4AC325F7B44`.

The raw transfer is valid private audit evidence but is **not a
publication-ready bundle**. It contains public endpoint IP addresses,
network GUIDs in a superseded attempt, and screenshots exposing unrelated
desktop/session details. Public demo evidence must use a redacted subset,
cropped application-only screenshots, and a new manifest generated after
redaction.

## Limitations

- One physical Snapdragon X-class device, one fixture, one model, and one
  device-specific tile size were tested.
- The diagnostic installer and application are unsigned.
- Uninstall was left untested by explicit project-owner decision.
- Updater behavior, release publication, performance, energy efficiency, and
  NVIDIA RTX hardware were not tested.
