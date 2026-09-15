# Upscayl Windows ARM64 case study

This reference maps the generic `upshift64-port` workflow to the proven
Upshift64 implementation. These values are evidence for this application and
must not become defaults for another port.

The complete pre-generalization skill, agents, plan, and workflow guide were
backed up before this split:

- archive:
  `E:\upshift64-step12-pre-generalization-backup-20260915.zip`
- size: 55,571 bytes
- SHA256:
  `87F560E1AFBCAA94DEED8E4FB4D1CE8164282721BDE39DFAE9874AA29BAA1E36`

The archive is a local recovery artifact, not a portable dependency or
publication input.

## Generic-category mapping

| Generic category | Upscayl implementation |
| --- | --- |
| Build system | CMake backend plus npm/Next/Electron application |
| Compiler and SDK | Visual Studio 2022, MSVC ARM64, Windows SDK |
| Processor-specific code | NCNN ARM/AArch64/NEON detection and libwebp SIMD selection |
| Acceleration API | Vulkan |
| Inference framework | NCNN |
| Host accelerator tool | `glslangValidator` |
| Native media dependency | libwebp |
| Windows integration | WIC, COM, Unicode filesystem paths, Windows entry points |
| Parallel runtime | Microsoft OpenMP `vcomp140.dll` |
| Desktop framework | Electron |
| Native build dependency | Sharp |
| Compatibility dependency | ExifTool-vendored x64 runtime |
| Installer | electron-builder NSIS |
| Target hardware | Snapdragon X-class Windows ARM64 PC, Qualcomm Adreno |

## Immutable source

| Component | Repository/branch | Revision |
| --- | --- | --- |
| Application baseline | `upscayl/upscayl`, `hackathon/upshift64-win-arm64` | `a00d55fee90e0f9435d5eaa86e76700df8199af8` |
| Application after Step 10 docs | `mahabayana/upscayl`, `hackathon/upshift64-win-arm64` | `6855a2b7acb0f7e11f04c1851142e85d7471908f` |
| Backend baseline | `upscayl/upscayl-ncnn`, `hackathon/upshift64-win-arm64` | `0beb39028a0ddd83250e845b4c3333c0675e3b97` |
| Backend after closure | `mahabayana/upscayl-ncnn`, `hackathon/upshift64-win-arm64` | `fd72e621d143f21747fcf0522356480125075fea` |
| libwebp | Backend submodule | `8ea81561d2fdd382da60f57958741a7c23a18eb6` |
| NCNN | Backend submodule | `6125c9f47cd14b589de0521350668cf9d3d37e3c` |
| glslang | NCNN nested submodule | `4afd69177258d0636f78d2c4efb823ab6382a187` |
| pybind11 | NCNN nested submodule | `70a58c577eaf067748c2ec31bfd0b0a614cffba6` |

The initial recursive checkout encountered SSH submodule URLs. The approved
recovery used a command-scoped HTTPS rewrite:

```powershell
git -C C:\upscayl-ncnn `
  -c url."https://github.com/".insteadOf=git@github.com: `
  submodule update --init --recursive
```

No global Git configuration or `.gitmodules` change was required.

## Fixed functional baseline

| Item | Value |
| --- | --- |
| Fixture | `to_upscale.jpeg`, 256x256 |
| Fixture SHA256 | `8E9EB94064D1776381B7364AF571AF7953407586B8FF4267FCA3B881D671EE5C` |
| Model | `upscayl-standard-4x` |
| Param SHA256 | `35330ECECCEA33B6C397A72548E788D5D53BECEE4734C50B7FADA36E89F10A86` |
| Bin SHA256 | `713EE713B0353AFAA27976F0563A64A5043BD70B9BD8936C2E26E25EBCDBCDDF` |
| Unchanged x64 executable SHA256 | `704FD622984220C8C646A8DFF4C7EBA1CC62FBB8C47383996F38571F76B73FBF` |
| Baseline provider | NVIDIA GeForce RTX 4060 Laptop GPU |
| Baseline output | 1024x1024 PNG |
| Baseline output SHA256 | `DCC617E967905E61F987374A7F692407EE2C4CE90484F1509ABFBFB1597F2404` |

The observed 4,245 ms x64 result is a functional reference only. It is not a
cross-device or energy benchmark.

## Audit mapping

The project audit inspected:

- CMake and CI architecture restrictions;
- Visual Studio/MSVC ARM64 and Windows SDK target libraries;
- NCNN ARM64/AArch64/NEON guards and runtime dispatch;
- Vulkan headers, ARM64 import library, driver-owned loader, host shader tools,
  generated shader data, and target-linked glslang;
- libwebp ARM64/NEON selection and x86 source exclusion;
- WIC, COM, Unicode paths, filesystem behavior, and Windows entry points;
- OpenMP link and redistributable closure;
- direct/transitive PE imports and debug-runtime rejection;
- Electron packaging, native modules/helpers, artifact names, and update
  collision risk.

Qualcomm EasyWoS methodology was applied from commit
`e096b5b95a25c18220be93f743a668846ef3481b`. The approved isolated native
Windows setup stopped when `python-magic` could not load `libmagic`; scanner
help and scanning did not execute. No project finding is represented as an
EasyWoS scanner finding.

## Native backend build

The final backend CI used:

- GitHub Actions `windows-11-arm`;
- Visual Studio 2022;
- lowercase CMake `-A arm64`, required because the pinned NCNN revision
  case-sensitively classified uppercase `ARM64` as x86;
- `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` for the pinned legacy dependency;
- LunarG Windows ARM64 Vulkan SDK `1.4.357.0`;
- SDK SHA256
  `C10F18A9085018F66E1F50BD60623F17B7081FACA165248DE54F78728120F334`.

Failure-driven sequence:

| Run | Observation | Narrow correction |
| --- | --- | --- |
| `34893473570` | Current CMake rejected the legacy policy floor | Added the explicit policy minimum |
| `34894677848` | NCNN reported x86 for uppercase `ARM64` | Proved and used lowercase `arm64` |
| `34895652256` | Native configure, build, and AA64 verification passed | Proceeded to runtime closure |
| `34900090037` | Executable plus signed ARM64 OpenMP closure passed | Backend Steps 6-7 complete |

## Backend dependency closure

| File | Evidence |
| --- | --- |
| `upscayl-bin.exe` | ARM64; SHA256 `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` |
| `vcomp140.dll` | ARM64/ARM64X; valid Microsoft signature; SHA256 `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` |
| Backend artifact ZIP | SHA256 `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64` |

Direct imports were:

- Windows system: `ole32.dll`, `KERNEL32.dll`, `OLEAUT32.dll`;
- driver/system boundary: `vulkan-1.dll`;
- packaged release redistributable: `VCOMP140.DLL`.

The runtime was selected only from Visual Studio's ARM64 release
redistributable tree. Debug, OneCore, Spectre, and x64 variants were rejected.
No SDK Vulkan loader was packaged beside the backend.

## Physical backend validation

The physical device exposed:

- native GPU 0: `DRIVER_ID_QUALCOMM_PROPRIETARY`, vendor `0x5143`;
- excluded GPU 1: `DRIVER_ID_MESA_DOZEN`;
- excluded GPU 2: Dozen-backed Microsoft Basic Render Driver.

Auto tile size produced `VK_ERROR_DEVICE_LOST` and exit `0xC0000005` during the
first valid offline attempt. After separate approval, tile size `200` passed.
This value is device-specific and not a reusable default.

| Field | Accepted result |
| --- | --- |
| Command parameters | `-n upscayl-standard-4x -g 0 -t 200 -f png -v` |
| Exit | `0` |
| Duration | `7603.69 ms`, one functional observation |
| Output | 1024x1024 PNG, 1,952,322 bytes |
| Output SHA256 | `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269` |
| Evidence manifest SHA256 | `4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2` |

The run remained offline around process execution, with connectivity checks
and NetworkProfile corroboration, and networking was restored afterward.

## Electron packaging

The application package:

- stages the verified backend/runtime outside source control;
- uses a separate `electron-builder.arm64.cjs`;
- pins Sharp `0.34.2` and verifies its ARM64 native module during the build;
- treats Sharp as build-time-only rather than requiring it in the installed
  application;
- produces architecture-labelled unpacked, ZIP, and NSIS outputs;
- extracts `app.asar` and recursively inspects `.exe`, `.dll`, and `.node`;
- verifies models and exact backend/runtime hashes;
- uploads diagnostic evidence even on failure.

CI run `34936161073` produced:

- `upscayl-2.15.0-win-arm64.exe`;
- `upscayl-2.15.0-win-arm64.zip`;
- `dist\win-arm64-unpacked`.

| Artifact | Evidence |
| --- | --- |
| Complete package artifact | ID `10384470075`; SHA256 `8D0E4FE6ED6386B6ED60D04AE1234C976EC3D91CE3295829101CE331DD5ECF39` |
| NSIS installer | 282,727,113 bytes; SHA256 `29A4778DFB85F5F5EDF3D447F7B18BA1B794A259DDE6571E8610B3B86A258769` |
| Package closure | 86 native files; zero failures |

The unsigned diagnostic NSIS executable is an x86 compatibility bootstrap.
The package policy permits only:

- exact x86 `resources\elevate.exe`;
- ExifTool's path-bounded x64 runtime.

All other application/runtime native files must be ARM64. A backend-local
`resources\bin\vulkan-1.dll`, debug runtime, or undeclared non-ARM64 file is a
failure.

## Installed application validation

On the Snapdragon device:

- 601/601 unpacked-package reference files matched installed bytes;
- zero reference files were missing or changed;
- installer-generated x86 `Uninstall Upscayl.exe` was the sole added file;
- 49 installed native files were inspected;
- the app, backend, OpenMP runtime, Electron/Chromium DLLs, and top-level
  Vulkan loader were ARM64;
- `resources\app.asar` matched SHA256
  `E86262FAA3888AC02B8FFC9B926311D48503882DF9B387E5D9E62A8FEC281245`.

The GUI passed launch, fixed-input selection, cancellation, recovery through
Reset Image, successful 4x native Qualcomm inference, and output opening
through Windows Photos.

The accepted offline application attempt ran from
`2026-09-15T18:31:12.1286072Z` through
`2026-09-15T18:33:11.2344523Z`. Connectivity was unavailable after disable and
immediately before restore. The fresh output was created at 11:32:41 local,
inside that interval. The retained NetworkProfile evidence contains an
explicit disconnect event and generic state changes; reconnection is proven
by a separate successful connectivity check.

The device evidence ZIP has SHA256
`9B373A6769907985B8D1DAF18FD19AA3FD4A8498CC5A26E1AF20A61AA84B5675`.
Its raw contents are private because some logs/screenshots require redaction.

## Case-study limitations

- The package workflow currently references a fork-specific backend artifact,
  run ID, name, and secret; Step 13 must generalize this before an upstream
  application PR.
- The installer and application are unsigned diagnostic outputs.
- Uninstall, updater behavior, release publication, controlled performance,
  energy efficiency, NVIDIA RTX hardware, and a second device remain unproven.
- Output hashes differ across GPU vendors; dimensions, validity, provider
  identity, and retained per-run hashes are the functional criteria.
