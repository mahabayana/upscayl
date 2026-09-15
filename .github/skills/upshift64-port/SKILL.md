---
name: upshift64-port
description: Port and validate native or packaged desktop applications for Windows ARM64 through approval-gated, agent-authored workflows.
---

# Windows ARM64 application porting

## Purpose

Use this skill to audit, build, package, and validate a Windows ARM64 or
ARM64EC desktop application. It is designed for native applications,
framework-based desktop applications, and local-AI applications with native
backends.

The workflow is technology-neutral. CMake, MSBuild, Rust, Go, Electron,
Vulkan, DirectML, Windows ML, CUDA, NCNN, codecs, and vendor runtimes are
possible project choices, not universal requirements.

Project-specific implementation details belong in configuration and case-study
references. The proven Upscayl implementation is retained in
`references/upscayl-case-study.md`; it is evidence and an example, not a
default recipe.

## Maturity

The following capabilities have proven procedures and dependency-free
self-tests:

- immutable source and submodule capture;
- unchanged functional baseline capture;
- Windows ARM64 blocker auditing;
- native ARM64 CI and PE architecture verification;
- recursive dependency and package closure;
- architecture-labelled application packaging;
- physical accelerator/provider validation;
- installed-tree comparison and GUI smoke testing;
- offline execution evidence;
- privacy-gated JSON/CSV evidence manifests;
- agent handoffs and approval provenance.

Application-specific build commands, runtime providers, compatibility
exceptions, performance claims, signing, updating, Store publication, and
hardware coverage still require project evidence.

## Package contents

```text
upshift64-port/
|-- SKILL.md
|-- references/
|   |-- project-config.schema.json
|   |-- project-config.example.json
|   |-- upscayl-project-config.example.json
|   |-- evidence-record.schema.json
|   |-- handoff-template.md
|   |-- provenance-template.md
|   `-- upscayl-case-study.md
|-- scripts/
|   |-- Test-Upshift64ProjectConfig.ps1
|   `-- New-Upshift64EvidenceManifest.ps1
`-- tests/
    `-- run-tests.ps1
```

## Mandatory operating rules

### Approval

Before changing code, configuration, workflows, dependencies, tests, scripts,
documentation, devices, CI state, or external systems:

1. state the exact action, paths, commands, expected outputs, risks,
   alternatives, rollback, and validation;
2. obtain explicit owner approval for that boundary;
3. create or update the provenance record;
4. perform only the approved action;
5. return to the gate if the scope, parameter, dependency, or remediation
   changes.

Read-only investigation may proceed within an approved audit scope. Approval
to inspect is not approval to edit; approval to edit is not approval to
commit, push, trigger CI, install, execute on a device, or publish.

### Agent-only authorship

- Agents generate every repository artifact and modification.
- Humans approve, reject, constrain, and review.
- Record the responsible agent, skill, model, affected paths, commands,
  observed output, failures, validation, and limitations.
- Never include hidden instructions, credentials, or private data in
  provenance.
- Never claim an unrun build, scan, test, package, or device result.

### Evidence hierarchy

Prefer evidence in this order:

1. exact source at verified revisions;
2. observed output from tools and inspected binaries;
3. official documentation pinned by version or revision;
4. clearly labeled inference awaiting validation.

Reconcile scanner findings and text matches with the real build graph before
classifying them as product findings.

## Portable project contract

Copy `references/project-config.example.json` outside the skill directory,
replace every placeholder and all-zero revision/hash, and validate it:

```powershell
& .github\skills\upshift64-port\scripts\Test-Upshift64ProjectConfig.ps1 `
  -Path <project-config.json>
```

The contract records:

- project identity;
- application/backend repositories, branches, full commits, and submodules;
- native target and explicitly accepted compatibility architectures;
- runner, configuration, and toolchain;
- evidence/staging roots;
- required native architecture and path-bounded exceptions;
- fixed fixture and optional model files;
- optional acceleration API and allowed/denied provider identifiers;
- expected output and offline requirement;
- private/public evidence mode and image-review policy;
- optional and required external tools.

A valid configuration is not proof and does not grant approval. Every phase
reverifies the values it consumes.

`references/upscayl-project-config.example.json` is the concrete case-study
configuration. Do not copy its hashes, provider identifiers, exceptions, or
paths to another application without independent evidence.

## Phase states

Use only:

| State | Meaning |
| --- | --- |
| `not-started` | Required inputs or approval are absent |
| `approved` | Exact action and validation are approved |
| `running` | Work is executing inside the approved boundary |
| `blocked` | A hard prerequisite failed |
| `partial` | Some criteria passed but exit criteria did not |
| `passed` | Every stated exit criterion has direct evidence |
| `published` | Passed evidence was sanitized, manifested, and made reviewable |

Do not collapse phases. Configure success is not build proof; build success is
not dependency closure; closure is not physical execution; execution is not
publication.

## End-to-end workflow

### Phase 1: scope and immutable inputs

1. Record application/backend URLs, branches, commits, and recursive
   submodules.
2. Record target OS, target architecture, allowed compatibility architecture,
   and required hardware classes.
3. Define success tiers and excluded work.
4. Select a fixed functional fixture and expected output properties.
5. Identify which operations require credentials, installation, elevation,
   network changes, signing material, or external writes.
6. Validate the project configuration.

Stop on floating revisions, dirty/unexplained source state, missing required
inputs, or ambiguous ownership.

### Phase 2: unchanged baseline

Run the unmodified supported build/application with the fixed fixture. Record:

- exact executable/package and input hashes;
- command or GUI journey;
- runtime provider;
- exit/status;
- output validity, dimensions, size, and hash;
- logs and environment facts needed for comparison.

A baseline is functional evidence, not target-architecture evidence or a
cross-device benchmark.

### Phase 3: generic Windows ARM64 audit

Inspect each category and mark non-applicable categories explicitly:

1. **Source and release topology:** repositories, submodules, generated code,
   artifact flow, release channels, naming, and update collisions.
2. **Build-system constraints:** architecture literals, generator/platform
   options, matrices, cache keys, conditional source lists, and packaging
   commands.
3. **Compiler, SDK, and ABI:** target compiler/linker, Windows SDK libraries,
   calling conventions, alignment, exception/runtime model, ARM64 versus
   ARM64EC, and host/target separation.
4. **Processor-specific code:** architecture guards, intrinsics, assembly,
   SIMD dispatch, feature detection, and x86 fallback behavior.
5. **Acceleration and compute providers:** API headers/import libraries,
   host-side compilers, target runtime/driver ownership, provider enumeration,
   hardware-versus-software selection, and translation layers.
6. **Native frameworks and libraries:** inference engines, media codecs,
   database/crypto libraries, optional native modules, generated assets, and
   platform source exclusions.
7. **Windows integration:** filesystem and Unicode behavior, COM/WIC/WinRT,
   services, registry, shell integration, entry points, elevation, and
   architecture-sensitive helpers.
8. **Language/runtime redistribution:** C/C++ runtimes, OpenMP/threading,
   framework runtimes, native extensions, signatures, release/debug variants,
   and licensing.
9. **Binary dependency closure:** direct/transitive imports, system boundaries,
   PE machine values, delay-loaded modules, plugins, subprocesses, and runtime
   search paths.
10. **Packaging, installation, and updating:** package architecture, installer
    bootstrap, installed layout, architecture labels, signing, updater feeds,
    uninstall, and compatibility boundaries.
11. **Device behavior and evidence:** launch, workload, cancellation,
    accelerator selection, offline readiness, output validation, power/thermal
    context when claimed, privacy, and reproducibility.

Examples:

- Vulkan is one acceleration API; DirectML, Windows ML, CUDA, OpenCL, CPU, or
  another provider may replace it.
- NCNN is one inference framework; another application may use ONNX Runtime,
  PyTorch, TensorFlow Lite, a vendor SDK, or no ML framework.
- libwebp is one native media dependency; inspect only codecs selected by the
  real build graph.
- OpenMP is one runtime obligation; inspect the actual threading/runtime stack.
- Electron native modules are one packaging case; other UI stacks have
  different native closure and installer boundaries.

### Audit statuses and severity

Use exactly:

- `ready`: direct evidence supports the target without a known change;
- `change required`: current source/configuration/payload is incompatible;
- `runtime validation`: static evidence is favorable or inconclusive;
- `unknown`: required evidence is absent;
- `not applicable`: the category is demonstrably outside the build/runtime.

Rank findings independently:

- `critical`: prevents or invalidates the primary outcome;
- `high`: blocks shipping, closure, or reliable release handling;
- `medium`: meaningful integration/runtime behavior remains unproven;
- `low`: bounded hardening or a pre-existing non-blocking risk.

Each finding requires exact evidence, impact, smallest remediation candidate,
and a validation test. A candidate is not adopted until approved.

### Host tools versus target artifacts

Classify every architecture-sensitive item as:

- host executable;
- architecture-neutral input or generated data;
- target static/import library;
- target executable, DLL, native module, plugin, or subprocess;
- operating-system or driver component.

A host tool may use the runner's architecture if it only produces
architecture-neutral or correct target output. Anything loaded or executed by
the application must satisfy the configured native-file policy.

### Phase 4: remediation plan

1. Group exact files into independently reviewable slices.
2. Choose the smallest slice that creates decisive evidence.
3. State expected behavior, tests, risks, alternatives, and rollback.
4. Separate dependency upgrades, build changes, package changes, device work,
   signing, and publication unless coupling is proven.
5. Return to the approval gate before implementation.

### Phase 5: native build

1. Preserve existing platforms unless modification is approved.
2. Use an isolated native ARM64 runner or a proven cross-build host.
3. Record runner, process, compiler, SDK, linker, and target-library
   architecture.
4. Pin downloaded tools and verify checksums before execution.
5. Use one clean target build directory and the smallest decisive target.
6. Preserve configure/build logs on success and failure.
7. Inspect output architecture and imports before reporting success.
8. Iterate from one observed failure at a time.

ARM64EC is acceptable only when selected in the project contract and proven by
binary inspection. Emulation is a deliberate compatibility boundary, not a
silent fallback.

### Phase 6: binary and dependency closure

1. Enumerate every target executable, DLL, native module, plugin, and
   subprocess.
2. Inspect PE machine type and direct imports.
3. Recursively resolve non-system dependencies.
4. Classify operating-system/driver components separately from app-local
   redistributables.
5. Verify vendor signatures and release/debug identity where applicable.
6. Reject undeclared architecture mismatches and unresolved dependencies.
7. Record each exception by exact path pattern, allowed architecture, reason,
   owner approval, and validation.

Never allow an architecture by filename or vendor alone. Broad directory-wide
exceptions require direct evidence that the entire boundary is intentional.

### Phase 7: application packaging

1. Stage immutable backend/runtime inputs outside source control.
2. Keep target-specific packaging isolated from existing release behavior.
3. verify native dependencies before packaging;
4. create architecture-labelled outputs;
5. unpack opaque archives when necessary for inspection;
6. recursively apply the native-file policy;
7. preserve package reports even when closure fails;
8. keep diagnostic artifacts unpublished unless release approval exists.

Classify installer/bootstrap architecture separately from the installed
application. A compatible installer does not permit undeclared non-native
application payloads.

### Phase 8: physical-device validation

Use separate approvals for:

1. read-only inventory;
2. artifact staging and verification;
3. execution and any network/device changes;
4. failure-driven remediation.

On the target device:

- require native Windows ARM64;
- reverify artifact, fixture, model, and payload hashes;
- verify installed or staged binary architecture;
- enumerate the configured acceleration API's providers;
- select an allowed physical provider and reject denied software/translation
  providers;
- run a fixed workload;
- test cancellation and recovery where applicable;
- validate output properties and retain its hash;
- prove offline execution when required;
- restore modified device state in a `finally` path.

Provider names alone may be ambiguous. Prefer stable API/vendor identifiers and
retain enough enumeration evidence to distinguish physical, translated, and
software providers.

For offline proof, check connectivity immediately after disable and
immediately before restore, correlate independently collected system events,
and prove output freshness inside the interval. A screenshot captured after
restoration is supplementary only.

### Phase 9: installed-application validation

1. Verify installer identity before execution.
2. Discover the actual install location.
3. Compare the installed tree with the package reference by path, size, and
   hash.
4. Explain every added, missing, or changed file.
5. rerun recursive native-file closure on installed bytes;
6. exercise launch, input, cancellation/recovery, successful workload, and
   output opening;
7. retain separate logs for distinct journeys;
8. treat uninstall as a separately approved gate.

Deterministic outputs can repeat hashes. Prove a rerun is fresh by preserving
or moving prior output and recording a new creation time in the accepted run
window.

### Phase 10: evidence and publication

Use `references/evidence-record.schema.json`. Generate manifests only after
the evidence tree is stable:

```powershell
& .github\skills\upshift64-port\scripts\New-Upshift64EvidenceManifest.ps1 `
  -Root <evidence-root> `
  -JsonPath <manifest.json> `
  -CsvPath <manifest.csv> `
  -Phase <phase-name> `
  -Status passed `
  -PublicationMode Private
```

The tool records stable relative paths, bytes, SHA256, phase/status, image
count, and privacy findings. It never reproduces the matched sensitive value.

Public mode:

- scans relative filenames and every safely decoded text file regardless of
  extension;
- blocks unresolved credential assignments, common standalone token formats,
  private-key headers, credential-bearing URLs, email addresses, user and UNC
  paths, network addresses, GUIDs, and assigned machine identifiers;
- blocks image-containing bundles until `-ImagesReviewed` is supplied;
- blocks non-text bundles until `-NonTextFilesReviewed` is supplied;
- permits only exact match-hash allowlist entries containing path, category,
  hash, and rationale;
- requires `Status published` to use `PublicationMode Public`.

Automated scanning cannot prove screenshots or arbitrary binary files safe.
Crop to the relevant application, manually review every image and non-text
file, sanitize logs, then regenerate the manifest from the final bytes.

## External tool composition

Use installed specialist tools instead of recreating them:

- **Portability scanner (for example EasyWoS):** pin the source and report
  separately whether methodology was applied, setup was attempted, or scanning
  executed. Never turn manual findings into scanner findings.
- **GUI automation (for example WinAppCli):** use for discovery and repeatable
  interaction. Require observed state; declare bounded owner-click steps when
  automation is unreliable.
- **Windows development skills (for example `win-dev-skills`):** invoke the
  relevant available skill rather than copying its private instructions.
- **Accelerator tooling (for example `winml-cli`):** use only when the selected
  API and approved scope require it.

Record required/optional status and version/revision in the project contract.
If a required tool is unavailable, block. If an optional tool is unavailable,
use an approved documented fallback or mark the criterion unproven.

## Failure handling and rollback

- Preserve all failed and superseded attempts.
- Do not overwrite the only copy of a log or output.
- Make one smallest evidence-driven correction at a time.
- Require new approval for changed dependencies, parameters, providers,
  compatibility modes, installers, device state, or test inputs.
- Prefer isolated branches, worktrees, build roots, staging roots, and evidence
  roots.
- Do not use destructive Git or broad filesystem cleanup.
- Restore network, power, driver, and application state even after failure.
- Report `partial` or `blocked` instead of creating a success-shaped fallback.

## Handoff and provenance

Instantiate `references/handoff-template.md` at every agent/phase boundary.
The handoff contains immutable inputs, artifact hashes, proven/unproven claims,
compatibility exceptions, preserved failures, and the next approval gate. The
receiving agent reverifies inputs and does not inherit approval.

Use `references/provenance-template.md` in the adopting repository's chosen
provenance directory. Record each approval-gated action separately. Historical
facts supplied by an owner or earlier agent must be labeled as such.

## Agent routing

- Use `upshift64-auditor` for read-only discovery and remediation design.
- Use `upshift64-builder` for approved build, closure, and packaging changes.
- Use `upshift64-device-tester` for verified artifacts on physical hardware.
- Return to the coordinating agent for publication, upstream PR preparation,
  and scope decisions.

## Definition of done

A port is complete only when the explicitly selected scope has:

- immutable and reproducible source inputs;
- an unchanged baseline;
- a reconciled audit;
- native or deliberately approved compatibility-architecture build evidence;
- recursive binary and dependency closure;
- architecture-labelled package outputs where applicable;
- physical-device execution through an allowed provider;
- installed application behavior where claimed;
- offline proof where required;
- restored device state;
- sanitized, schema-valid, byte-accurate evidence;
- provenance and explicit limitations.

Run the package self-test after changing the skill:

```powershell
& .github\skills\upshift64-port\tests\run-tests.ps1
```

The fixtures validate both configuration examples, reject unreplaced template
values and malformed revisions, generate private/public manifests, block
credential-shaped public evidence, verify exact match-hash allowlisting, and
require manual review for public image bundles.

## Case study

See `references/upscayl-case-study.md` for the complete mapping of this generic
workflow to Upscayl: NCNN, Vulkan, libwebp, WIC/COM, OpenMP, Electron, Sharp,
ExifTool, CI iterations, hashes, compatibility exceptions, Snapdragon
validation, and known limitations.
