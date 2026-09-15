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
