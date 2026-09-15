# Upshift64 Hackathon Plan

## Goal

Port Upscayl and its NCNN/Vulkan inference backend to Windows Arm64 using
agent-generated work only, prove it on a physical Snapdragon X device, and
package the proven workflow as a reusable Copilot skill.

## Operating Rules

1. No code, configuration, workflow, test, script, or documentation change is
   written manually. Changes are produced by agents or reusable skills through
   prompts.
2. Before any code change or major technical decision, present the exact
   proposed change or decision to the project owner and wait for explicit
   approval.
3. Announce completion of each step and obtain approval before moving to the
   next step.
4. Preserve prompts, agent transcripts, generated diffs, validation results,
   and commit-to-agent provenance as hackathon evidence.
5. Develop the reusable agent/skill workflow alongside the port. Each proven
   procedure should be captured in the skill rather than reconstructed at the
   end.
6. Keep the work in isolated branches and separate backend and application
   changes into independently upstreamable pull requests.
7. Do not start Tier 2 until the Tier 1 backend completes real Vulkan inference
   on Snapdragon X hardware.
8. Do not start exceeds-expectations work until Tiers 1 and 2, the reusable
   skill, evidence, and upstream-ready pull requests are complete.

## Approval Gate

Before an approval-gated action, provide:

- The current step and objective.
- The exact files, commands, or decision involved.
- The proposed generated diff or a precise description when no diff exists yet.
- Expected behavior and validation.
- Risks, alternatives, and rollback approach.

No approval-gated action begins until the project owner explicitly approves it.
Read-only inspection and reporting may proceed without approval when it does
not alter repositories, devices, dependencies, accounts, or external systems.

## Success Tiers

### Tier 1: Native Arm64 Inference Backend

- Produce a Release Arm64 `upscayl-bin.exe`.
- Build it in real Windows Arm64 CI.
- Prove that the executable and packaged native dependencies contain no x64 or
  debug runtime payloads.
- On a physical Snapdragon X Windows device, enumerate the Adreno Vulkan GPU
  and complete an offline Real-ESRGAN upscale.
- Record the exact hardware, graphics driver, command, model, input and output
  hashes, logs, timing, binary architecture report, CI URL, and agent
  provenance.

### Tier 2: Usable Arm64 Upscayl Application

- Package the verified backend in a Windows Arm64 Electron build.
- Produce architecture-specific ZIP and installer artifacts.
- Resolve native Node modules and helper executables for Arm64.
- Recursively verify the installed application's native binary closure.
- On Snapdragon X, prove launch, file selection, single-image upscale,
  cancellation, output opening, diagnostics, and offline operation.
- Package one production-quality reusable Copilot skill.
- Prepare separate upstream-ready draft pull requests for the backend and app.

### Exceeds Expectations

- Windows ML or ONNX migration.
- NPU execution.
- Automatic Snapdragon/RTX provider routing.
- Energy-measurement framework.
- Complete Fluent or WinUI redesign.
- Batch-mode automation beyond a basic manual check.
- Store publication or production signing.
- More than one reusable production-quality skill.
- A complete second app port.

## Execution Plan

### Step 1: Select and Scope the Target - Complete

- Selected `upscayl/upscayl` as a popular, visually demonstrable offline AI
  desktop application with a documented Windows Arm gap.
- Defined Upshift64 as an accelerator-portability project rather than a generic
  migration assistant.
- Locked Tier 1, Tier 2, and exceeds-expectations boundaries.

### Step 2: Prepare the Application Repository - Complete

- Cloned the application to `C:\upscayl`.
- Pinned the starting point at
  `a00d55fee90e0f9435d5eaa86e76700df8199af8`.
- Created and selected `hackathon/upshift64-win-arm64`.
- Confirmed the working tree was clean before adding this plan.

### Step 3: Prepare the Backend Repository - Complete

Approval required before execution.

- Clone `upscayl/upscayl-ncnn` beside the app at `C:\upscayl-ncnn`, including
  its NCNN and libwebp submodules.
- Record the backend commit and all submodule commits.
- Create and select `hackathon/upshift64-win-arm64` in the backend repository.
- Make no backend source or configuration changes.
- Confirm both repositories are clean.
- Start an agent/skill provenance record that captures the prompts and outputs
  used for subsequent work.

Exit criteria:

- Reproducible backend and submodule SHAs are recorded.
- Both repositories are on dedicated clean branches.
- The agent-only evidence structure is agreed and initialized.

### Step 4: Establish the Unchanged x64 Baseline - Complete

Approval required for the fixture and execution procedure.

- Select one redistributable input image and one bundled model.
- Run the unchanged x64 backend on the current RTX Windows machine.
- Record the command, environment, Vulkan device, logs, elapsed time, output
  image, and hashes.
- Add the validated baseline procedure to the developing reusable skill.

Exit criteria:

- A fixed input/model/output baseline can be repeated exactly.

Observed fixed baseline:

- Input: `C:\upscayl\to_upscale.jpeg`, 256x256, SHA256
  `8E9EB94064D1776381B7364AF571AF7953407586B8FF4267FCA3B881D671EE5C`.
- Model: `upscayl-standard-4x`; param SHA256
  `35330ECECCEA33B6C397A72548E788D5D53BECEE4734C50B7FADA36E89F10A86`;
  bin SHA256
  `713EE713B0353AFAA27976F0563A64A5043BD70B9BD8936C2E26E25EBCDBCDDF`.
- Unchanged x64 executable SHA256:
  `704FD622984220C8C646A8DFF4C7EBA1CC62FBB8C47383996F38571F76B73FBF`.
- Vulkan GPU 1: NVIDIA GeForce RTX 4060 Laptop GPU.
- Result: exit 0 in 4245 ms; 1024x1024 output with SHA256
  `DCC617E967905E61F987374A7F692407EE2C4CE90484F1509ABFBFB1597F2404`.

This is one functional reference run, not a benchmark or cross-device
performance comparison.

### Step 5: Audit Windows Arm64 Blockers - Complete

Approval required before selecting remediation decisions.

- Audited CMake and CI/release architecture restrictions, including `-A x64`.
- Audited Visual Studio/MSVC ARM64 compiler, Windows SDK, CMake generator, and
  `windows-11-arm` runner readiness.
- Audited NCNN ARM64 target detection, ARM/NEON guards, Vulkan options, shader
  generation, and CPU fallback behavior.
- Audited Vulkan target headers/import libraries/runtime versus host tools such
  as `glslangValidator`.
- Audited libwebp Windows ARM64 compilation, NEON/SIMD dispatch, and x86-source
  exclusion.
- Audited WIC, COM, filesystem, Unicode paths, and other `_WIN32` source paths.
- Audited OpenMP discovery/linking and ARM64 `vcomp` runtime/distribution.
- Audited static and dynamic backend dependency closure.
- Audited backend/application artifact naming, architecture staging, updater
  collisions, and native helpers.
- Classified host tools, target binaries, blockers, and runtime validation;
  recorded the evidence in `docs/upshift64/arm64-port-audit.md`.
- Applied the pinned Qualcomm EasyWoS methodology manually. The separately
  approved isolated scanner setup stopped when `python-magic` could not load
  `libmagic`; scanner help and the scanner did not run, and no scanner findings
  exist. The owner selected methodology-only completion.
- Encoded the proven audit procedure and its limitations in the reusable skill.

Confirmed blocker categories:

- x64-only backend workflow generation and implicit x64 application jobs;
- pinned NCNN's likely uppercase `ARM64` detection failure and x86/SSE2
  fallback;
- unresolved ARM64 Vulkan import-library/runtime path;
- unproven ARM64 OpenMP link/runtime selection and currently bundled x64/debug
  `vcomp` payloads;
- architecture-colliding backend/application artifacts and staging;
- missing Windows Arm64 Sharp package in the current lockfile;
- no ARM64 build, dependency closure, package, or physical-device inference
  evidence yet.

Exit criteria:

- Every identified native dependency and likely Arm64 blocker has a proposed
  owner, minimal candidate, and validation test in the audit.

### Step 6: Generate the Backend Arm64 Build and CI

**Status: complete.**

- Added an independent `windows-11-arm` job to the backend `CI.yml`; the
  existing Windows x64, Linux, and macOS job definitions were preserved.
- Pinned and checksum-verified LunarG Windows ARM64 Vulkan SDK `1.4.357.0`.
- Verified the native ARM64 compiler, Windows SDK libraries, Vulkan import
  library, and native `glslangValidator` before configuring.
- Added `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` after the first run proved that
  the runner's current CMake no longer accepts NCNN's legacy policy floor.
- Passed `-A arm64` after the second run proved that pinned NCNN
  case-sensitively misclassified Visual Studio's conventional `ARM64` spelling
  as x86.
- Built only `upscayl-bin` Release and required CMake to report
  `Target arch: arm`.
- Verified the executable as AA64 and uploaded it with configure, build,
  toolchain, SDK, and dependency diagnostics.

Observed successful evidence:

- backend commit:
  `147fdf1a79c4715b3a1f3b351a05eac61a1e2caa`;
- CI run:
  <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34895652256>;
- successful ARM64 job:
  `104148842328`;
- `upscayl-bin.exe` SHA256:
  `2057ED45F433D7BA2272819B33AA77393A28EC46211F9F490B1587FA8D086961`.

Exit criteria:

- Met: CI produced and architecture-verified a Release ARM64
  `upscayl-bin.exe`.

### Step 7: Verify Native Binary Closure

**Status: complete.**

- Confirmed the backend directly imports `vulkan-1.dll`, `ole32.dll`,
  `KERNEL32.dll`, `OLEAUT32.dll`, and `VCOMP140.DLL`.
- Classified the COM and kernel libraries as Windows system dependencies.
- Classified `vulkan-1.dll` as a driver/system Vulkan loader that must not be
  copied from the SDK into the application payload.
- Located Visual Studio's release ARM64 `vcomp140.dll`, rejected x64, debug,
  OneCore, and Spectre variants, and required a valid Microsoft signature.
- Packaged the verified runtime beside `upscayl-bin.exe`.
- Recursively inspected the payload with `dumpbin /headers /dependents` and
  rejected x64 machine types and common debug runtime names.

Observed successful evidence:

- backend commit:
  `fd72e621d143f21747fcf0522356480125075fea`;
- CI run:
  <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34900090037>;
- successful ARM64 job:
  `104163707942`;
- artifact:
  `upscayl-bin-windows-arm64-diagnostics-34900090037-1`;
- artifact ZIP SHA256:
  `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64`;
- `upscayl-bin.exe` SHA256:
  `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F`;
- Microsoft-signed `vcomp140.dll` SHA256:
  `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71`.

Exit criteria:

- Met: the artifact has a documented ARM64-compatible closure with no x64 or
  debug runtime payload.

### Step 8: Prove Vulkan Inference on Snapdragon X

**Status: complete.**

- Confirmed a native ARM64 Windows device with Qualcomm Adreno X1-85 GPU and
  driver `31.0.133.1`.
- Verified the system Microsoft-signed `vulkan-1.dll` and the native Qualcomm
  Vulkan ICD (`DRIVER_ID_QUALCOMM_PROPRIETARY`, vendor `0x5143`).
- Reverified the artifact ZIP, ARM64 executable, signed ARM64 OpenMP runtime,
  input, and model hashes after transferring them to the target device.
- Verified both payload PE machine fields as `0xAA64` using a no-install
  PowerShell parser because `dumpbin` was unavailable.
- Selected GPU 0, excluding the Vulkan-over-D3D12 Dozen device and Microsoft
  Basic Render Driver.
- Preserved an observed `-t 0` offline failure:
  `VK_ERROR_DEVICE_LOST`, followed by exit `0xC0000005`.
- After separate approval, completed the authoritative offline inference with
  `-t 200`, exit code `0`, and a 1024x1024 PNG.
- Proved the run remained offline through immediate pre/post connectivity
  checks and NetworkProfile event-log correlation, then restored Wi-Fi.

Exit criteria:

- Met: the native ARM64 backend completed the fixed upscale offline using the
  Qualcomm Adreno Vulkan driver.

Observed successful evidence:

- command parameters:
  `-n upscayl-standard-4x -g 0 -t 200 -f png -v`;
- duration: `7603.69 ms` as a single functional observation, not a benchmark;
- output size: `1,952,322` bytes;
- output dimensions: `1024x1024`;
- output SHA256:
  `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269`;
- corrected evidence manifest SHA256:
  `4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2`.

### Step 9: Publish Tier 1 Evidence

**Status: complete locally; not committed or pushed.**

- Published a sanitized Tier 1 evidence report under `docs/upshift64`.
- Recorded hardware, OS, GPU/driver, Vulkan provider, CI/artifact identity,
  hashes, PE architecture, signature/import closure, exact sanitized command,
  three-run history, offline proof, output dimensions/hash, timing caveats,
  limitations, and provenance.
- Extended the reusable skill with the proven target-device procedure and
  failure-driven `-t 200` remediation boundary.
- Updated the builder handoff and added a dedicated approval-gated physical
  device tester agent.
- Revalidated the corrected external evidence bundle: all 31 manifest entries
  matched their files and privacy/stale-value searches were clean.

Exit criteria:

- Met locally: Tier 1 has a reproducible procedure, verified evidence chain,
  explicit limitations, and reusable agent/skill guidance.

### Step 10: Generate the Arm64 Electron Package

**Status: implementation in progress; CI not run.**

Approval required for each proposed generated diff and packaging decision.

- Approved a separate `electron-builder.arm64.cjs` so the existing x64,
  Linux, and macOS packaging configuration remains unchanged.
- Added an architecture-labelled Arm64 ZIP build that stages the verified
  backend closure from pinned CI evidence rather than committing binaries.
- Pinned Sharp `0.34.2`, the first stable release whose optional dependencies
  include Windows Arm64, and added a native load/PE verification step.
- Preserved ExifTool metadata behavior as the only approved Windows-emulation
  exception if package inspection confirms it is not Arm64.
- Added blocking recursive PE inspection for packaged EXE, DLL, and native
  Node module files.
- Deferred NSIS until the unpacked application and ZIP pass CI inspection.

Exit criteria:

- Pending: native Arm64 CI produces and verifies the unpacked application and
  ZIP.
- Pending after separate approval: add and verify the NSIS installer.
- Application installation and physical GUI behavior remain Step 11.

### Step 11: Validate the Full Application on Snapdragon X

Approval required before installation and device-side test execution.

- Recursively verify the installed native binary closure.
- Use WinAppCli where practical to exercise launch, file selection,
  single-image upscale, cancellation, output opening, logs, and offline use.
- Capture visible demo evidence and failure diagnostics.

Exit criteria:

- The complete Arm64 app passes the agreed Snapdragon smoke journey.

### Step 12: Finalize the Reusable Skill

Approval required for the public skill interface and contents.

- Package the proven audit, build, CI, architecture verification, packaging,
  device validation, and evidence workflow as one production-quality Copilot
  skill.
- Compose with EasyWoS, WinAppCli, `win-dev-skills`, and `winml-cli` rather than
  duplicating them.
- Include approval gates, rollback guidance, failure handling, and provenance
  capture.

Exit criteria:

- A new repository can reuse the skill without relying on undocumented session
  knowledge.

### Step 13: Prepare Upstream Draft Pull Requests

Approval required before pushing branches or creating pull requests.

- Prepare separate maintainer-friendly backend and application changes.
- Follow each repository's contribution guidance.
- Include Windows Arm64 CI, physical-device evidence, limitations, and
  agent-only provenance.

Exit criteria:

- Both changes are reviewable, independently upstreamable, and free of
  hackathon-only coupling.

### Step 14: Consider Exceeds-Expectations Work

Approval required to select any item.

- Reassess remaining time only after all Tier 1 and Tier 2 exit criteria pass.
- Select at most one high-value extension unless evidence supports doing more.

## Current Position

- Steps 1 through 9 are complete to their documented evidence boundaries.
- Step 10 local implementation is in progress; its workflow has not been
  committed, pushed, or dispatched.
- The backend branch contains four approved CI commits ending at
  `fd72e621d143f21747fcf0522356480125075fea`.
- A native ARM64 backend plus its signed ARM64 OpenMP runtime exists and has
  passed CI architecture/dependency closure and physical offline Adreno Vulkan
  inference.
- Tier 1 is complete. No Electron ARM64 package, installer, GUI test, updater
  validation, or complete application claim exists.
- Step 10's six packaging decisions and first local implementation slice were
  approved. CI execution, commit, push, NSIS, release publication, and device
  installation remain separately gated.

## Plan Maintenance

Update this file as facts, risks, scope, or sequencing change. Every substantive
plan change is a major decision and requires explicit project-owner approval
before it is applied.
