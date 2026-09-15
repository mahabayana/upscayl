---
name: upshift64-port
description: Govern an approval-gated, agent-authored port of a local-AI desktop application to Windows Arm64.
---

# Upshift64 Windows Arm64 Port

## Purpose

Guide agents porting local-AI desktop applications and their native inference
backends to Windows Arm64 while preserving reproducibility, human control, and
an auditable provenance trail.

## Maturity

The Step 3 backend checkout and Step 4 unchanged x64 functional baseline
procedures are proven. The Step 5 read-only audit procedure is proven through
manual application of pinned EasyWoS methodology, direct build-graph
inspection, local toolchain inventory, and binary inspection. The optional
native-Windows EasyWoS setup was proven only through dependency installation
and core imports; it stopped because `python-magic` could not load `libmagic`.
The scanner, report generation, implementation, Arm64 build, packaging,
inference, and device-validation procedures are not proven.

Never present methodology use as scanner execution, the x64 baseline as Arm64
evidence, an installed toolchain as a successful build, or a proposed
remediation as an adopted decision.

## Mandatory approval gate

Before changing code, configuration, workflows, tests, scripts, documentation,
or making a major technical or scope decision:

1. Present the exact proposed action, affected paths, commands, expected
   outputs, risks, and validation to the human owner.
2. Wait for explicit approval that refers to that action.
3. Create or update the provenance record for the approved action.
4. Perform only the approved action. Return to the gate if its scope changes.

Investigation may be read-only, but any consequential decision produced by it
must pass the gate before it is adopted.

## Agent-only authorship

- Agents must generate every repository artifact and every modification.
- Humans approve, reject, constrain, and review work; approval is not artifact
  authorship.
- Record the responsible agent, skill, and model for each generated artifact.
- Do not copy hidden system or developer prompts into provenance. Record only
  task prompts supplied for the work and human approval quotations or durable
  references.
- Do not manually alter an agent-generated artifact outside an approved,
  provenance-recorded agent action.

## Inputs

- Application repository URL, branch, and exact revision.
- Backend repository URL, branch, exact revision, and recursive submodule
  revisions.
- Human-approved objective and scope.
- Target Windows Arm64 environment and constraints, when known.
- Available toolchain details, when verified.
- Existing provenance records and validation evidence.

## Outputs

- Agent-generated changes limited to the approved scope.
- One provenance record per approval-gated action.
- Exact commands and captured outputs needed to reproduce each proven step.
- Explicit validation results, unresolved risks, and known limitations.
- Commit, pull request, and CI links when they exist.

## Windows Arm64 audit method

Use this method for a native application and its backend. Keep universal
requirements separate from case-specific findings.

### Establish immutable scope

1. Record repository URLs, branches, exact commits, recursive submodule
   commits, and working-tree status.
2. Record the target operating system, architecture, compiler family,
   packaging architecture, runtime device, and intended CI runner.
3. Refuse to modify either repository during an audit unless a separate,
   explicit approval authorizes exact files and changes.
4. Inventory already-installed tools read-only. An installed cross compiler or
   SDK is capability evidence only.

### Inspect every named area

The audit must explicitly cover each area rather than referring to a generic
"nine-area audit":

1. CMake and CI/release architecture restrictions, including explicit
   generator platforms such as `-A x64`, implicit runner architecture, cache
   keys, matrices, packaging commands, and release names.
2. Visual Studio/MSVC ARM64 compiler availability, Windows SDK target
   libraries, official CMake generator spelling, and GitHub
   `windows-11-arm` runner readiness.
3. NCNN ARM64 target detection, ARM/AArch64/NEON guards, Vulkan options,
   shader generation, runtime CPU dispatch, and x86 fallback behavior.
4. Vulkan architecture separation: headers, target import libraries, target
   loader/driver runtime, host-only tools such as `glslangValidator`, generated
   shader data, and target-linked glslang libraries.
5. libwebp Windows ARM64 compilation, SIMD compile probes, NEON dispatch,
   x86-only sources, and the source-exclusion mechanism.
6. WIC, COM, filesystem, Unicode paths, entry points, and every relevant
   `_WIN32` source path.
7. OpenMP discovery and linking, target import library, ARM64 release runtime
   distribution, and rejection of x64 or debug `vcomp` payloads.
8. Static and dynamic backend dependency closure, including direct imports,
   transitive non-system DLLs, PE machine types, debug runtimes, and target
   loader resolution.
9. Backend/application artifact names, architecture-specific staging,
   package/update collisions, Electron/native helper architecture, and native
   Node modules.

### Evidence hierarchy and citations

Prefer evidence in this order:

1. exact checked-out source at recorded revisions;
2. observed tool output from read-only local inspection;
3. official toolchain, platform, runner, and dependency documentation pinned
   by URL/version where possible;
4. clearly labeled inference requiring validation.

For repository evidence, cite `path:line-range` and the relevant symbol or
option. For local tools, record the command, resolved path/version, and
meaningful output. For public documentation, use the official URL and state
whether it describes current behavior or only general support.

Never report a scanner rule, web statement, or source match as a product
finding until it is reconciled with the actual build graph.

### Build-graph reconciliation and false positives

For every source-level concern:

1. Determine whether the file is selected by the pinned CMake options,
   platform guards, generated source lists, and workflow invocation.
2. Distinguish host executables, architecture-neutral generated data, target
   static libraries, target import libraries, target executables/DLLs, and
   operating-system components.
3. Mark excluded test, example, benchmark, tool, or platform source as
   `false positive/not built`, retaining the evidence for that classification.
4. Mark conditional paths as `unknown` until configure output or compile
   commands prove selection.
5. Reconcile dynamic imports against both package contents and the target
   system boundary; do not require application-local copies of Windows system
   components.

### Status and severity

Use exactly these finding statuses:

- `ready`: direct evidence supports use without a known porting change,
  subject to integration checks;
- `change required`: current source, workflow, configuration, or payload is
  incompatible with the intended native result;
- `runtime validation`: static evidence is favorable or inconclusive and
  execution is required;
- `unknown`: required evidence is absent.

Rank blockers separately:

- `critical`: prevents or invalidates the primary build/runtime objective;
- `high`: blocks shipping, dependency closure, or reliable release handling;
- `medium`: important integration or behavior remains unproven;
- `low`: bounded hardening or pre-existing risk not shown to block the port.

Each finding must include exact evidence, impact, the smallest remediation
candidate, and a validation test. A candidate is not adopted until approved.

### Host-tool versus target-binary table

Always provide a table classifying at least:

- CMake and the build driver;
- compiler, linker, and librarian;
- shader compiler/validator;
- Vulkan headers, import library, loader, and driver;
- generated shader data;
- NCNN, glslang libraries, and libwebp;
- OpenMP import/runtime;
- Windows SDK libraries;
- backend executable;
- Electron, native Node modules, and helper executables.

An x64 host tool is valid in an x64-host cross-build if it only produces
architecture-neutral or ARM64 target output. Anything linked into or loaded by
the target process must be ARM64 unless a deliberately approved compatibility
architecture is part of the design.

### Dependency closure and validation design

Record current direct imports separately from inferred future ARM64 imports.
After a build is approved and available:

1. verify the executable and all app-local PE files;
2. recursively resolve non-system imports;
3. reject x64, unexpected ARM64EC, and debug runtime payloads;
4. record approved system dependencies and their target-runtime source;
5. test startup, Vulkan enumeration, fixed-fixture inference, image codecs,
   Unicode paths, cancellation, and diagnostic output on physical target
   hardware.

Validation must test the claimed outcome. Configure success does not prove a
build; build success does not prove dependency closure; startup does not prove
Vulkan inference; one functional run is not a benchmark.

## EasyWoS method and optional isolated scanner

### Identify and pin

1. Establish that the repository is the vendor's official source.
2. record the exact commit before using documentation or scanner behavior;
3. cite pinned source URLs;
4. distinguish:
   - `methodology applied`: guidance manually mapped to repository evidence;
   - `setup attempted`: clone/environment/dependencies were attempted;
   - `scanner executed`: the scanner reached source traversal and produced a
     retained report.

Never claim scanner findings unless the third state is true and the report is
available.

### Optional scanner approval and isolation

Scanner setup requires explicit approval because it clones content, creates a
virtual environment, installs dependencies, writes caches/temp files, and may
generate scanner-internal files. The approval must name:

- official repository and exact commit;
- an isolated root that must not already exist;
- Python version and exact requirements file;
- venv, pip cache, `TEMP`, `TMP`, logs, and output paths;
- target repository and exact scanner arguments;
- dependency/import stop conditions;
- evidence hashes and cleanup boundary.

Use explicit absolute output paths and formats. Capture the dependency freeze,
`pip check`, imports, help, combined run log, report, source revision, and
SHA256 hashes. Reconcile every reported issue with the real build graph before
classifying it.

Do not install an alternate package, system DLL, container runtime, or scanner
workaround without a new approval. On the current Upshift64 case study, the
pinned EasyWoS setup used Python 3.11.9 and installed the declared standalone
requirements, but `python-magic` failed with
`ImportError: failed to find libmagic.  Check your installation`. Help and the
scanner were not run. Native Windows scanner execution is therefore not proven
end-to-end.

## Remediation proposal rules

After the audit:

1. List exact anticipated files by independently reviewable slice.
2. Propose the smallest first slice that creates decisive evidence.
3. Explain expected behavior, validation, risks, alternatives, and rollback.
4. Keep dependency upgrades, diagnostic feature reductions, release
   packaging, application packaging, and device work separate unless coupling
   is demonstrated.
5. Return to the mandatory approval gate. Never implement automatically.

For the current Upshift64 case study, the approved Step 6 and Step 7 slices
changed only the backend `.github/workflows/CI.yml`. The proven implementation
and closure procedure is recorded below. An x64-host ARM64 cross-build,
diagnostic OpenMP-off build, and NCNN update remain unselected alternatives.

## Step 6: native Windows ARM64 CI build

Use a separate `windows-11-arm` job so existing platforms remain behaviorally
independent. Give the job `contents: read`, a bounded timeout, and recursive
submodule checkout.

Before configuring:

1. record runner, OS, and process architecture plus runner-image metadata;
2. select Visual Studio 2022 with the ARM64 C++ tools using `vswhere`;
3. require an ARM64-targeting `cl.exe` and a usable `dumpbin.exe`;
4. require ARM64 Windows SDK `kernel32.lib` and `windowscodecs.lib`;
5. download an official Windows ARM64 Vulkan SDK from LunarG;
6. verify its pinned SHA256 before executing it;
7. use a workspace-local copy installation;
8. require and inspect native `Bin\glslangValidator.exe`,
   `Lib\vulkan-1.lib`, and Vulkan headers;
9. run `glslangValidator --version`.

The proven Upshift64 SDK input was:

| Property | Value |
| --- | --- |
| Version | `1.4.357.0` |
| Platform key | `warm` |
| SHA256 | `c10f18a9085018f66e1f50bd60623f17b7081faca165248de54f78728120f334` |

Configure one clean `build-arm64` tree with Visual Studio 2022, the selected
instance, explicit target Vulkan paths, the native shader validator,
`-DCMAKE_POLICY_VERSION_MINIMUM=3.5`, and `-A arm64`.

The lowercase platform spelling is deliberate and case-study-specific.
Visual Studio still selects its ARM64 compiler, while pinned NCNN
`6125c9f47cd14b589de0521350668cf9d3d37e3c` case-sensitively matches
`CMAKE_GENERATOR_PLATFORM` against lowercase `arm64`. Require the configure log
to contain `Target arch: arm`; fail on `Target arch: x86` or absence of the ARM
classification.

Build only `upscayl-bin` Release. Preserve `configure.log` and `build.log` even
when a step fails. Do not treat a successful compile as architecture proof:
run `dumpbin /headers` and require `AA64 machine (ARM64)` while rejecting
`8664 machine (x64)`.

The observed failure-driven sequence was:

1. Run `34893473570` reached CMake but failed because compatibility below 3.5
   had been removed.
2. Commit `0c6983a32b279179018d249f09da49ae4b40f25d` added the explicit policy
   minimum.
3. Run `34894677848` configured far enough to prove NCNN reported
   `Target arch: x86` for uppercase `ARM64`.
4. A local isolated generator probe proved `-A arm64` still selected the
   Microsoft ARM64 compiler and preserved lowercase
   `CMAKE_GENERATOR_PLATFORM`.
5. Commit `147fdf1a79c4715b3a1f3b351a05eac61a1e2caa` applied that narrow
   workaround.
6. Run `34895652256` configured, compiled, and verified native AA64
   `upscayl-bin.exe`.

Do not generalize either compatibility argument to another project without
observing the same failure and checking its dependency/toolchain versions.

## Step 7: Windows ARM64 dependency closure

Start from the final executable import table, not from names copied by an old
packaging script. Classify every direct import as:

- a Windows system DLL;
- a driver/system API loader;
- an application-local redistributable; or
- unresolved.

For Upshift64, the observed executable imports were:

| Dependency | Classification | Packaging decision |
| --- | --- | --- |
| `ole32.dll` | Windows COM system DLL | Do not package |
| `KERNEL32.dll` | Windows system DLL | Do not package |
| `OLEAUT32.dll` | Windows Automation system DLL | Do not package |
| `vulkan-1.dll` | Vulkan loader supplied by the Windows-on-Arm GPU stack | Do not package an SDK copy |
| `VCOMP140.DLL` | Microsoft OpenMP runtime | Package the signed release ARM64 redistributable |

Locate `vcomp140.dll` only under Visual Studio's release
`VC\Redist\MSVC\<version>\arm64\Microsoft.VC*.OpenMP` directory. Exclude
OneCore, debug, and Spectre directories. Require:

- `AA64 machine (ARM64)` and no x64 machine record;
- a valid Authenticode signature whose signer is Microsoft Corporation;
- a release filename, rejecting `vcomp140d.dll` and other common debug runtime
  patterns;
- transitive imports containing no debug runtime.

Copy the verified runtime beside `upscayl-bin.exe`, then run
`dumpbin /headers /dependents` on every application-local EXE and DLL. Upload
the payload and diagnostics together.

The proven closure at commit
`fd72e621d143f21747fcf0522356480125075fea` is:

| File | Machine | SHA256 | Direct non-system obligation |
| --- | --- | --- | --- |
| `upscayl-bin.exe` | AA64 | `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` | GPU-driver `vulkan-1.dll`; packaged `VCOMP140.DLL` |
| `vcomp140.dll` | AA64/ARM64X, Microsoft-signed | `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` | `KERNEL32.dll` only |

CI run `34900090037` and job `104163707942` passed. The artifact
`upscayl-bin-windows-arm64-diagnostics-34900090037-1` had ZIP SHA256
`A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64`.

This establishes build and static dependency closure only. It does not prove
that a target device has a working Vulkan driver, that model inference
completes, or that the Electron package selects the ARM64 payload.

## Step 8: physical Windows-on-Arm Vulkan validation

Treat device execution as a separate approval-gated phase. Build and static
closure are prerequisites, not substitutes.

### Approval gates

Use four independently approved gates:

1. **Inventory:** read-only OS, native architecture, CPU, GPU, driver, power,
   Vulkan loader, Vulkan tooling, and PE-inspection-tool availability.
2. **Staging:** evidence directories, artifact transfer/download, extraction,
   hashes, signatures, PE inspection, fixture/model copying, and manifest
   preparation.
3. **Execution:** Vulkan enumeration, network disconnect/restore method, exact
   inference command, output path, and validation.
4. **Remediation:** any driver/tool install, parameter change, rerun,
   compatibility mode, source edit, or packaging change.

Approval to inspect is not approval to write evidence. Approval to stage is
not approval to execute. A general execution approval does not authorize a
changed tile size after a failure.

### Target inventory

Prefer built-in PowerShell and CIM:

- `Get-ComputerInfo`;
- `Get-CimInstance Win32_Processor`;
- `Get-CimInstance Win32_ComputerSystem`;
- `Get-CimInstance Win32_VideoController`;
- `Get-CimInstance Win32_Battery`;
- `powercfg /getactivescheme`;
- `Get-FileHash` and `Get-AuthenticodeSignature` on the system Vulkan loader;
- `Get-Command vulkaninfo,dumpbin -ErrorAction SilentlyContinue`.

Exclude machine names, users, serials, UUIDs, asset tags, personal network
names, IP/MAC addresses, and credentials from publishable evidence. Record
manufacturer/model only when it is necessary to identify the tested hardware.
Preserve conflicting firmware/CIM strings as observations rather than
silently choosing one.

Stop unless Windows and the native process architecture are ARM64.

### Artifact transfer and no-install verification

GitHub Actions artifact REST downloads require authentication even for public
repositories. If the device lacks an already-authenticated tool, prefer a
human-transferred ZIP over installing `gh` or handling a token. Reverify the
ZIP, executable, runtime, fixture, and model hashes after transfer.

If `dumpbin` is absent, an approved no-install PowerShell PE parser may:

1. read `e_lfanew` at DOS offset `0x3c`;
2. validate the `PE\0\0` signature;
3. read the COFF Machine field at PE offset plus four;
4. require `0xaa64` and reject `0x8664`;
5. map import-directory RVAs through section headers and enumerate direct
   import names.

This fallback must retain its method and output. It does not replace the CI
`dumpbin` evidence; it independently confirms the transferred bytes on the
target device.

Require a valid Microsoft signature on `vcomp140.dll`, the exact expected
imports, and no app-local `vulkan-1.dll`.

### Native Vulkan device selection

Use `vulkaninfo --summary` when available. Select by provider identity, not
device-name substring alone. A translation layer can expose the same physical
GPU name.

For the proven device:

- native GPU 0: `DRIVER_ID_QUALCOMM_PROPRIETARY`, vendor `0x5143`;
- excluded GPU 1: `DRIVER_ID_MESA_DOZEN`, Vulkan over Direct3D 12;
- excluded GPU 2: `DRIVER_ID_MESA_DOZEN`, Microsoft Basic Render Driver.

Record the API version, driver version, device type, `driverID`, `driverName`,
and vendor ID. Redact device and driver UUID values before publishing.

### Offline execution protocol

Use one approved script to minimize the interval between offline checks and
execution. The operator may reserve adapter changes for themselves; the agent
must honor that boundary. Use `try`/`finally` so the adapter restoration is
attempted even when inference fails.

```powershell
$evidenceRoot = "<evidence-root>\step8-snapdragon-vulkan"
$probeHost = "<public-connectivity-probe-host>"
$adapter = "<approved-network-adapter>"
$start = $null
$end = $null

try {
  Disable-NetAdapter -Name $adapter -Confirm:$false
  Start-Sleep -Seconds 2
  $pre = Test-NetConnection -ComputerName $probeHost -InformationLevel Quiet `
    -WarningAction SilentlyContinue
  if ($pre) { throw "Connectivity remained available before inference." }

  Push-Location "$evidenceRoot\payload\extracted"
  try {
    $start = Get-Date
    .\upscayl-bin.exe `
      -i "$evidenceRoot\fixture\to_upscale.jpeg" `
      -o "$evidenceRoot\output\to_upscale-upscayl-standard-4x-arm64-t200.png" `
      -m "$evidenceRoot\fixture\models" `
      -n upscayl-standard-4x -g 0 -t 200 -f png -v `
      *> "$evidenceRoot\inference-t200.log"
    $exitCode = $LASTEXITCODE
    $end = Get-Date
  } finally {
    Pop-Location
  }

  $post = Test-NetConnection -ComputerName $probeHost -InformationLevel Quiet `
    -WarningAction SilentlyContinue
  if ($post) { throw "Connectivity returned during inference." }
} finally {
  Enable-NetAdapter -Name $adapter -Confirm:$false
}
```

Capture NetworkProfile events from shortly before `$start` through shortly
after `$end`. A pre-run `False` check alone is insufficient: the proven device
silently reconnected to a remembered network between an earlier check and Run
1. Require no connection event during the actual inference window and sanitize
network names from retained event text.

Do not use `-t 200` as an untested universal default. In this case study, the
first genuinely offline `-t 0` run emitted `VK_ERROR_DEVICE_LOST` and crashed
with `0xc0000005`. After separate approval, `-t 200` succeeded. Record both;
generalize only that tile-size remediation must be failure-driven and
separately approved.

### Success criteria and evidence

Require:

- native ARM64 device and payload;
- verified payload/fixture/model hashes;
- physical native Vulkan ICD selected, not Dozen/software;
- offline state immediately before and after the process, plus event-log
  corroboration;
- exit code 0;
- expected non-empty output dimensions and retained SHA256;
- network restoration;
- complete sanitized evidence manifest whose rows match actual bytes.

Cross-vendor output hashes may differ. Do not fail only because an ARM64/Adreno
hash differs from an x64/NVIDIA hash. Preserve dimensions, validity, and hash;
perform perceptual/pixel comparison only under a separately approved protocol.

For Upshift64, the authoritative result was:

| Field | Value |
| --- | --- |
| GPU | Qualcomm Adreno X1-85, native GPU 0 |
| Driver | `31.0.133.1` |
| Tile size | `200` after approved `-t 0` device-lost remediation |
| Exit | `0` |
| Duration | `7603.69 ms`, single functional observation |
| Output | 1024x1024, 1,952,322 bytes |
| Output SHA256 | `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269` |
| Evidence manifest SHA256 | `4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2` |

The timing is not a benchmark: power state was not recaptured at the exact run
and the x64 reference used different hardware and tile size.

## Recorded source baseline

| Component | Repository | Branch | Revision |
| --- | --- | --- | --- |
| Application | `upscayl/upscayl` | `hackathon/upshift64-win-arm64` | `a00d55fee90e0f9435d5eaa86e76700df8199af8` |
| Backend baseline | `upscayl/upscayl-ncnn` | `hackathon/upshift64-win-arm64` | `0beb39028a0ddd83250e845b4c3333c0675e3b97` |
| Backend after Step 7 | `mahabayana/upscayl-ncnn` | `hackathon/upshift64-win-arm64` | `fd72e621d143f21747fcf0522356480125075fea` |
| libwebp submodule | upstream recorded by the backend checkout | backend-recorded | `8ea81561d2fdd382da60f57958741a7c23a18eb6` |
| ncnn submodule | upstream recorded by the backend checkout | backend-recorded | `6125c9f47cd14b589de0521350668cf9d3d37e3c` |
| glslang nested submodule | upstream recorded by the backend checkout | backend-recorded | `4afd69177258d0636f78d2c4efb823ab6382a187` |
| pybind11 nested submodule | upstream recorded by the backend checkout | backend-recorded | `70a58c577eaf067748c2ec31bfd0b0a614cffba6` |

## Step 3: reproducible backend checkout

Use this procedure only after approval. First ensure that `C:\upscayl-ncnn`
does not exist; stop rather than overwrite an existing checkout. The
`hackathon/upshift64-win-arm64` branch is local-only at this stage, so clone the
upstream default branch rather than requesting that branch from upstream.

```powershell
git clone --recurse-submodules https://github.com/upscayl/upscayl-ncnn.git C:\upscayl-ncnn
```

The observed initial clone created the top-level checkout, then failed while
initializing SSH submodules. When that failure occurs, keep the partial
checkout and use the command-scoped HTTPS retry:

```powershell
git -C C:\upscayl-ncnn -c url."https://github.com/".insteadOf=git@github.com: submodule update --init --recursive
```

After the recursive submodules initialize successfully, create the local port
branch:

```powershell
git -C C:\upscayl-ncnn switch -c hackathon/upshift64-win-arm64
```

Verify the backend HEAD, clean working-tree status, and recursive submodule
revisions:

```powershell
git -C C:\upscayl-ncnn rev-parse HEAD
git -C C:\upscayl-ncnn status --short
git -C C:\upscayl-ncnn submodule status --recursive
```

`HEAD` and every recursive submodule revision must match the recorded source
baseline, and `status --short` must produce no output. Treat a leading `-`, `+`,
or `U` in submodule status, a missing submodule, any revision mismatch, or
working-tree output as a failure. The URL rewrite applies only to the retry
command; do not change global Git configuration or `.gitmodules`.

## Step 4: unchanged x64 functional baseline

Use the approved fixed fixture, bundled model, unchanged x64 executable, and
isolated evidence directory:

| Item | Value |
| --- | --- |
| Input | `<app-repository>\to_upscale.jpeg` (256x256) |
| Input SHA256 | `8E9EB94064D1776381B7364AF571AF7953407586B8FF4267FCA3B881D671EE5C` |
| Model | `upscayl-standard-4x` |
| Model param SHA256 | `35330ECECCEA33B6C397A72548E788D5D53BECEE4734C50B7FADA36E89F10A86` |
| Model bin SHA256 | `713EE713B0353AFAA27976F0563A64A5043BD70B9BD8936C2E26E25EBCDBCDDF` |
| x64 executable SHA256 | `704FD622984220C8C646A8DFF4C7EBA1CC62FBB8C47383996F38571F76B73FBF` |
| Selected Vulkan device | GPU 1, NVIDIA GeForce RTX 4060 Laptop GPU |
| Evidence directory | `<evidence-root>\step4-x64-baseline` |

The exact historical invocation is represented by this public-safe equivalent;
only machine-specific roots are replaced by placeholders:

```powershell
<app-repository>\resources\win\bin\upscayl-bin.exe -i <app-repository>\to_upscale.jpeg -o <evidence-root>\step4-x64-baseline\to_upscale-upscayl-standard-4x.png -m <app-repository>\resources\models -n upscayl-standard-4x -g 1 -t 0 -f png -v
```

Retain these approved evidence files in the evidence directory:

- `vulkaninfo-summary.txt`
- `inference.log`
- `to_upscale-upscayl-standard-4x.png`
- `metadata.json`

Validation succeeds only when the fixture, model, and executable hashes match;
the log identifies GPU 1 as NVIDIA GeForce RTX 4060 Laptop GPU; the process
exits 0; and the PNG is 1024x1024 with SHA256
`DCC617E967905E61F987374A7F692407EE2C4CE90484F1509ABFBFB1597F2404`.
The observed run met those criteria in 4245 ms. That elapsed time is a single
functional reference only, not a benchmark or cross-device performance
comparison.

The approved evidence hashes are:

| Evidence file | SHA256 |
| --- | --- |
| `vulkaninfo-summary.txt` | `B9492E3373522DF430EF9E5EF5E8F636A2351FC707F6463DB1340F279650282F` |
| `inference.log` | `036B22303CEB51318E2C6DE00A5B89FDEF70730B80A1E0B234E3564D083ABB28` |
| `to_upscale-upscayl-standard-4x.png` | `DCC617E967905E61F987374A7F692407EE2C4CE90484F1509ABFBFB1597F2404` |
| `metadata.json` | `05D548E006ED9245F5659C431F1F085BA0407226454AEA7DC025C1B0157D7BF1` |

## Provenance requirements

Follow `docs/upshift64/provenance/README.md`. Record the approval before acting
and complete the command, diff or decision, validation, output, and limitation
fields immediately afterward. Distinguish observed output from owner-supplied
or historical facts.

## Safety and stop conditions

Stop and request a new approval when:

- approval is absent, ambiguous, or does not cover the exact action;
- a command would overwrite an existing checkout or unrelated work;
- an expected revision, branch, submodule, tool, or output differs;
- credentials, secrets, signing material, or privileged access would be needed;
- a proposed workaround changes global machine state;
- the requested scope expands to another repository or unapproved path;
- provenance cannot be recorded accurately;
- validation fails or evidence is incomplete.

Never claim success from an unrun command, an owner-supplied revision alone, or
an unverified artifact.

## Roadmap

Steps 3 through 8 now have procedures proven to their accurately stated
boundaries: reproducible checkout, unchanged x64 reference, read-only audit,
native ARM64 CI, binary closure, and physical offline Vulkan inference. The
Electron ARM64 packaging, installed application validation, updater behavior,
and release process remain unproven and must be added only after separate
approval and captured execution evidence.
