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
