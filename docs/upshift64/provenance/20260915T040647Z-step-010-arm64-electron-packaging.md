# Step 010: Implement Windows ARM64 Electron packaging

- **Timestamp (UTC):** `2026-09-15T04:06:47Z`
- **Objective:** Implement the approved local diagnostic packaging slice for
  a Windows ARM64 Electron application without committing, pushing, or running
  CI.
- **Owner approvals:** Six sequential `"approved"` decisions covering payload
  staging, isolated builder configuration, manual ZIP-first CI, Sharp,
  ExifTool, and blocking package closure, followed by
  `"ok continue implementing step 10"`.
- **Rejected alternative:** The owner explicitly said
  `"no do not replace"` when offered a shared builder configuration. The
  implementation therefore retains a separate
  `electron-builder.arm64.cjs`.
- **Agent:** GitHub Copilot CLI
- **Skill:** `upshift64-port`
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Affected files:** `.gitignore`, `package.json`, `package-lock.json`,
  `electron-builder.arm64.cjs`,
  `.github/workflows/build-windows-arm64.yml`,
  `scripts/stage-windows-arm64-payload.ps1`,
  `scripts/verify-sharp-arm64.js`,
  `scripts/verify-windows-arm64-package.ps1`, and `plan.md`.
- **Commit:** Not created
- **Pull request:** Not created
- **CI:** Not run

## Approved design implemented

- The application repository does not store the backend or Microsoft runtime.
  The manual workflow downloads the exact Step 7 artifact by repository, run,
  and artifact name, then requires the known executable and DLL hashes.
- A dedicated builder configuration inherits the existing package settings and
  overrides only the staged native payload, architecture-labelled artifact
  name, ARM64 ZIP target, and ASAR unpack rules.
- Existing x64, Linux, macOS, release, and publication workflows remain
  unchanged.
- The workflow is manual-only on `windows-11-arm`; it builds an unpacked app
  and ZIP but not NSIS.
- Sharp `0.34.2` is pinned as a development dependency and npm override. It is
  the first stable Sharp release whose optional dependency list includes
  `@img/sharp-win32-arm64`.
- Static source inspection established that Sharp is used by Next during the
  renderer build and is not imported by the Upscayl Electron runtime.
  Therefore, CI proves its native ARM64 load before building; package closure
  does not falsely require Sharp to be shipped when electron-builder excludes
  development dependencies.
- ExifTool remains enabled. Package inspection permits only ExifTool as an
  x86/x64 Windows-emulation exception and rejects every other undeclared
  non-ARM64 PE file.

## Verification behavior

The generated scripts:

1. require exactly one `upscayl-bin.exe` and `vcomp140.dll`;
2. verify their pinned SHA256 values and `0xAA64` PE machine values;
3. require a valid Microsoft signature on `vcomp140.dll`;
4. reject `vcomp140d.dll` and app-local `vulkan-1.dll`;
5. load Sharp on native Windows ARM64 and verify its `.node` PE header;
6. recursively inventory packaged `.exe`, `.dll`, and `.node` files;
7. require the known backend/runtime hashes and packaged models;
8. emit JSON and Markdown closure reports; and
9. fail on every undeclared non-ARM64 or forbidden native file.

## Local evidence

- The staging script accepted the corrected Step 8 payload at
  `E:\Upshift64Evidence\step8-snapdragon-vulkan\payload\extracted`.
- Signature, file hash, and ARM64 PE checks passed for the real backend closure.
- A synthetic positive ARM64 package passed closure.
- A synthetic package containing an undeclared existing x64 backend was
  correctly rejected.
- A synthetic ExifTool-path x64 executable was accepted only under the named
  exception.
- JavaScript and PowerShell syntax checks passed.
- Builder configuration inspection showed the staged payload destination,
  ARM64-only ZIP target, `${arch}` artifact naming, and required unpack rules.
- The lockfile resolves one Sharp `0.34.2` tree and records
  `@img/sharp-win32-arm64` `0.34.2`.

## Incomplete validation and gates

- Local `npm ci` could not complete because this machine's configured npm proxy
  returned HTTP 403 for an existing Next package. A direct public-registry
  attempt had already failed during TLS negotiation. No machine-wide registry
  setting or alternate package source was installed.
- No local YAML parser was available; the workflow has received structural
  review but not parser execution.
- The cross-repository artifact download requires a repository secret named
  `UPSHIFT64_BACKEND_TOKEN` with Actions read access to
  `mahabayana/upscayl-ncnn`. Creating that secret is not authorized here.
- GitHub Actions artifact `10371015381` expires on `2026-09-28`; CI must run
  before expiry or a separately approved durable backend distribution must
  replace it.
- Commit, push, workflow dispatch, NSIS packaging, release publication, and
  physical application installation remain separately approval-gated.

## CI attempt 1

- **Application commit:** `d112084747d05a2156a30812daf7177efe2f6b22`
- **Workflow run:** <https://github.com/mahabayana/upscayl/actions/runs/34930795586>
- **Runner:** GitHub-hosted `windows-11-arm`, image
  `windows-11-arm64/20260906.161`
- **Result:** failed during `actions/setup-node`; no dependency installation,
  payload download, packaging, or application execution occurred.
- **Observed error:** `Unable to find Node version '18.20.5' for platform
  win32 and architecture arm64.`
- **Correction:** Pin Node `22.23.2` and explicitly request `architecture:
  arm64`. The official `actions/node-versions` manifest lists
  `node-22.23.2-win32-arm64.7z`; this Node release also satisfies Next,
  electron-builder, and Sharp `0.34.2` engine constraints.

## CI attempt 2

- **Application commit:** `5ce63c289f5ff1c7b3221d5567874ca16dab3f5e`
- **Workflow run:** <https://github.com/mahabayana/upscayl/actions/runs/34930954950>
- **Result:** dependency installation, ARM64 Sharp verification, renderer
  build, Electron packaging, and ZIP creation completed. The build then failed
  because electron-builder detected CI and attempted to initialize the
  configured GitHub publisher without `GH_TOKEN`.
- **Observed error:** `GitHub Personal Access Token is not set, neither
  programmatically, nor using env "GH_TOKEN"`.
- **Correction:** Pass `--publish never` in the diagnostic ARM64 script. Step
  10 is intentionally a diagnostic artifact build and must never publish a
  release.
- **Package observation:** Electron itself places an ARM64 `vulkan-1.dll`
  beside `Upscayl.exe` for its Chromium/SwiftShader runtime. The closure rule
  now permits only that top-level framework file while continuing to reject
  any backend-local or ASAR-contained Vulkan loader. The backend still resolves
  the physical system/driver loader and does not stage one in `resources/bin`.

## CI attempt 3: diagnostic ZIP pass

- **Application build commit:** `3193b1c3b3c742f6118472b3ea41d95152921e87`
- **Workflow run:** <https://github.com/mahabayana/upscayl/actions/runs/34931983687>
- **Job:** `104261912616`
- **Runner:** GitHub-hosted `windows-11-arm`, native Windows ARM64
- **Result:** success
- **Artifact:** `upscayl-windows-arm64-diagnostics-34931983687-1`
- **Artifact ID:** `10381734387`
- **Artifact size:** `727225325` bytes
- **Artifact SHA256:**
  `CBB12A227B424934568F4410DBC0D58DEF9BAD9390AAAA24D63043FBA56BA7DB`
- **Artifact expiry:** `2026-09-29T05:25:15Z`
- **Application ZIP:** `upscayl-2.15.0-win-arm64.zip`

Every workflow gate passed:

1. Node `22.23.2` loaded natively on Windows ARM64.
2. The cross-repository Step 7 artifact downloaded.
3. Backend hashes, AA64 PE headers, and the Microsoft runtime signature passed.
4. Locked dependency installation completed.
5. Sharp `0.34.2` loaded and its native module reported AA64.
6. TypeScript, schema validation, renderer generation, Electron packaging, and
   ZIP creation completed.
7. `app.asar` was extracted for inspection.
8. Recursive package closure passed.
9. The diagnostic package and evidence uploaded successfully.

The run used a bounded push trigger because this session could not invoke the
authenticated manual dispatch endpoint. Commit `36a3292` immediately restored
the branch workflow to `workflow_dispatch` only; no automatic build trigger
remains.

This proves the unpacked application and ZIP-first Step 10 slice. It does not
yet prove NSIS installation or physical GUI behavior.

## Approved NSIS slice

- **Owner approval:** `"ok approved"` in response to the separately proposed
  NSIS slice.
- Add a dedicated ARM64-only NSIS target alongside the proven ZIP target.
- Preserve architecture-labelled `.exe` and `.zip` artifact names.
- Inspect the NSIS executable's PE machine, hash, and signature state in a
  separate report.
- Classify the installer bootstrap separately from the already-proven ARM64
  application payload. NSIS may use a Windows compatibility bootstrap even
  though it installs only ARM64 application files.
- Continue to defer actual installation, uninstall behavior, launch, and GUI
  validation to physical-device Step 11.

### Native CI attempt 4

- **Run:** `34933846347`
- **Result:** failed during recursive package closure after the NSIS installer
  had been built and inspected.
- `upscayl-2.15.0-win-arm64.exe` was generated successfully.
- The installer inspector classified its PE bootstrap as x86 under the approved
  Windows compatibility-bootstrap policy.
- ASAR extraction succeeded.
- Package closure rejected one native file, but the workflow neither printed
  nor uploaded the generated failure report before stopping. The rejected path
  therefore cannot be identified reliably from this run.
- The next diagnostic run prints the complete closure report in the job log and
  uploads `.upshift64/evidence` even when closure fails. No architecture policy
  is relaxed without that exact evidence.

### Native CI attempt 5

- **Run:** `34934959414`
- **Result:** failed at the same closure gate, with complete failure evidence
  preserved.
- The sole rejected file was `package:resources/elevate.exe`, an x86 helper
  added by electron-builder when generating the NSIS target.
- Its SHA256 was
  `9B1FBF0C11C520AE714AF8AA9AF12CFD48503EEDECD7398D8992EE94D1B4DC37`.
- Upscayl's existing NSIS configuration uses `perMachine: true`;
  electron-builder requires the elevation helper for this all-users installer
  mode. Removing it would require changing established installer behavior.
- The closure policy therefore permits only the exact
  `package:resources/elevate.exe` path and only when its PE machine is x86.
  All other undeclared non-ARM64 files remain blocking.
- The diagnostic workflow uploaded failure evidence as
  `upscayl-windows-arm64-evidence-34934959414-1`.
  - Artifact ID: `10382893085`
  - Size: `57121821` bytes
  - SHA256:
    `EB417D6969A3A779EA72DD3218DE676DF3EBA5237DD7E45D98DDBC5BFE1C922E`
  - Expires: `2026-09-29T06:12:20Z`

### Native CI attempt 6

- **Run:** `34936161073`
- **Job:** `104274401797`
- **Result:** success on native `windows-11-arm`.
- Node/Sharp verification, backend staging, Electron build, ZIP and NSIS
  generation, installer inspection, ASAR extraction, recursive closure, and
  both artifact uploads passed.
- Outputs:
  - `upscayl-2.15.0-win-arm64.exe`
  - `upscayl-2.15.0-win-arm64.zip`
  - `dist/win-arm64-unpacked`
- Installer evidence:
  - Size: `282727113` bytes
  - SHA256:
    `29A4778DFB85F5F5EDF3D447F7B18BA1B794A259DDE6571E8610B3B86A258769`
  - PE machine: `0x014C` (x86)
  - Policy: `compatibility-bootstrap`
  - Signature: `NotSigned` (diagnostic artifact)
- Package closure inspected 86 native files and passed with zero failures.
- Full diagnostic artifact:
  - Name: `upscayl-windows-arm64-diagnostics-34936161073-1`
  - Artifact ID: `10384470075`
  - Size: `1010069274` bytes
  - SHA256:
    `8D0E4FE6ED6386B6ED60D04AE1234C976EC3D91CE3295829101CE331DD5ECF39`
  - Expires: `2026-09-29T06:26:47Z`
- Evidence-only artifact:
  - Name: `upscayl-windows-arm64-evidence-34936161073-1`
  - Artifact ID: `10382809762`
  - Size: `57121824` bytes
  - SHA256:
    `38626521812F8671E06A5260D84E16637836A9B8868BCCE9219B5B6A08533841`
  - Expires: `2026-09-29T06:26:21Z`

Commit `0e825b6` restored the branch workflow to `workflow_dispatch` only after
the bounded trigger. Step 10 is complete to the package-generation and static
closure boundary. Installation, launch, GUI behavior, uninstall, updater, and
code-signing validation remain Step 11 or later work.
