# Upshift64 Windows Arm64 porting audit

## Scope and evidence boundary

This report closes the read-only Step 5 audit. It covers the application at
`a00d55fee90e0f9435d5eaa86e76700df8199af8`, the backend at
`0beb39028a0ddd83250e845b4c3333c0675e3b97`, and these recursively pinned
backend dependencies:

| Component | Revision |
| --- | --- |
| libwebp | `8ea81561d2fdd382da60f57958741a7c23a18eb6` |
| ncnn | `6125c9f47cd14b589de0521350668cf9d3d37e3c` |
| glslang | `4afd69177258d0636f78d2c4efb823ab6382a187` |
| pybind11 | `70a58c577eaf067748c2ec31bfd0b0a614cffba6` |

The audit used source inspection, Git and filesystem status checks, installed
toolchain inventory, and read-only PE header/import inspection. No backend or
application build, Windows Arm64 binary, CI run, package, or device execution
was produced. Candidate remediations below are proposals, not adopted
decisions.

> **Historical boundary:** The executive assessment and evidence matrix below
> preserve what was known at the end of Step 5. Their candidate remediations
> are not current instructions. See **Implemented Step 6 and Step 7 slice** for
> the observed CI corrections and final closure evidence.

## Executive assessment

Tier 1 is likely feasible, but the pinned source is not currently ready to
produce or distribute a verified native Windows Arm64 backend. The strongest
positive evidence is that the installed Visual Studio Enterprise toolchain has
an x64-hosted ARM64 compiler, the Windows SDK has ARM64 WIC/COM import
libraries, libwebp contains explicit MSVC ARM64/NEON support, and GitHub offers
the `windows-11-arm` hosted-runner label.

The immediate build blockers are x64-only workflow generation, likely
misclassification of uppercase CMake `ARM64` as NCNN's x86 target, and the
absence of a demonstrated ARM64 Vulkan import-library path. The immediate
distribution blockers are the x64 `vcomp` payloads, architecture-neutral
artifact names, and an application lockfile that does not contain a Windows
Arm64 Sharp package. Native Vulkan inference, WIC/WebP behavior, dependency
closure, and application packaging all still require execution on the target
architecture.

## EasyWoS usage

The authoritative source used was Qualcomm's
[EasyWoS repository](https://github.com/qualcomm/EasyWoS), pinned to commit
[`e096b5b95a25c18220be93f743a668846ef3481b`](https://github.com/qualcomm/EasyWoS/commit/e096b5b95a25c18220be93f743a668846ef3481b).
Its standalone C/C++ scanner documentation and source were used to structure
the architecture, cross-compilation, intrinsic, assembly, build-artifact, and
runtime review.

An isolated native-Windows setup was attempted under a session-scoped
`<evidence-root>\easywos` directory.
The exact commit was fetched, a Python 3.11.9 virtual environment was created,
the standalone requirements were installed, `pip check` passed, and the core
scanner imports passed. The required `python-magic` import then failed with
`ImportError: failed to find libmagic.  Check your installation`. Per the
approved stop condition, scanner help and the scanner were not run and no
scanner report or scanner findings exist. The owner selected methodology-only
completion rather than approving another dependency, Docker, or a workaround.

The pinned scanner documentation is
[`scanner/cpp/README.md`](https://github.com/qualcomm/EasyWoS/blob/e096b5b95a25c18220be93f743a668846ef3481b/scanner/cpp/README.md);
its source-confirmed target OS is the case-sensitive `Windows 11` value in
[`os_strings.py`](https://github.com/qualcomm/EasyWoS/blob/e096b5b95a25c18220be93f743a668846ef3481b/scanner/cpp/advisor/os_strings.py).
This report distinguishes that manually applied methodology from actual
scanner execution.

## Status definitions

| Status | Meaning |
| --- | --- |
| `ready` | Direct evidence supports use without a known porting change, subject to integration checks. |
| `change required` | Current source, workflow, or payload is incompatible with the intended Arm64 result. |
| `runtime validation` | Static evidence is favorable or inconclusive, but execution is required. |
| `unknown` | Required evidence is absent or an external component has not been inspected in the target configuration. |

## Evidence matrix

### 1. CMake and CI/release architecture restrictions, including `-A x64`

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| Backend CI is forced to x64. | `change required` | `C:\upscayl-ncnn\.github\workflows\CI.yml:8` uses `windows-latest`; line 30 runs `cmake -A x64 ../src`. | It cannot generate an ARM64 Visual Studio solution or prove an Arm64 build. | In a separately approved Step 6 slice, change only this workflow to a `windows-11-arm` job and generate `-A ARM64`. | Dispatch the job and require configure output to identify ARM64 plus an ARM64 PE executable. |
| Backend release is forced to x64. | `change required` | `C:\upscayl-ncnn\.github\workflows\release.yml:178-195` uses `windows-latest` and `cmake -A x64`. | Published Windows archives remain x64 even if CI gains a separate Arm64 probe. | Add an architecture-specific release job only after the CI build is proven. | Inspect release job logs and every packaged PE machine type. |
| Application Windows jobs select no architecture. | `change required` | `C:\upscayl\.github\workflows\build-windows.yml:6-21` and `C:\upscayl\.github\workflows\main.yml:55-68` run on `windows-latest` and invoke architecture-neutral scripts. | Electron and native dependency resolution default to the runner architecture, currently x64. | Add a later, separate Arm64 packaging job with explicit Electron/npm architecture selection. | Require an Arm64 Electron executable and recursively inspect native modules/helpers. |
| The CMake generator platform must use the official uppercase spelling. | `ready` | CMake documents `Win32`, `x64`, `ARM`, and `ARM64` for Visual Studio 17 2022: <https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2017%202022.html>. | Establishes the correct target selector and exposes a case-sensitivity conflict in pinned NCNN. | Use `-A ARM64`; do not invent lowercase generator names. | Check `CMAKE_GENERATOR_PLATFORM` and compiler target in configure output/cache. |

### 2. Visual Studio/MSVC ARM64 compiler, Windows SDK, CMake generator, and `windows-11-arm` runner readiness

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| An x64-hosted ARM64 compiler is installed locally. | `ready` | Read-only filesystem inspection found `C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC\14.44.35207\bin\Hostx64\arm64\cl.exe`; `vswhere` reported Enterprise 17.14.40 complete. | An x64-host cross-build is technically available without requiring an Arm64 development host. | Keep as an alternative diagnostic path, not the first CI proof. | Run a separately approved configure/build with `vcvarsall.bat x64_arm64`, then inspect the resulting PE. |
| The Community installation does not expose the same ARM64 cross compiler. | `unknown` | The same search found the ARM64 compiler only under Visual Studio Enterprise, not Community. | Machine-specific builds could accidentally select an installation without the needed component. | Pin/select the Enterprise installation or assert the required component before configuration. | Resolve `cl.exe` after environment activation and record `cl` target/version output. |
| ARM64 Windows SDK WIC libraries are installed. | `ready` | Read-only inspection found `windowscodecs.lib` under Windows Kits `10.0.22621.0\um\arm64` and `10.0.26100.0\um\arm64`. | WIC linking is not blocked by an absent ARM64 SDK import library on this machine. | Use the selected ARM64 SDK through normal CMake/MSVC discovery. | Inspect linker inputs and run WIC decode/encode on Arm64. |
| A real GitHub-hosted Windows Arm64 runner label exists. | `ready` | GitHub documents `windows-11-arm`: <https://docs.github.com/en/enterprise-cloud@latest/actions/reference/runners/github-hosted-runners>. | Tier 1 can be built on the target architecture rather than relying only on cross-compilation. | Use `windows-11-arm` for the smallest Step 6 probe. | Dispatch the workflow and record runner architecture, image, compiler, and SDK. |
| The pinned SDK/compiler combination has not configured this project for ARM64. | `runtime validation` | No CMake configure or compilation was run during Step 5. | Installed files prove capability, not project compatibility. | Make the CI-only probe first and iterate only from observed failures. | Require successful configure, compile, link, and PE verification. |

### 3. NCNN ARM64 target detection, ARM/NEON guards, Vulkan options, shaders, and CPU fallback

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| Pinned NCNN likely rejects uppercase Visual Studio `ARM64`. | `change required` | `C:\upscayl-ncnn\src\ncnn\CMakeLists.txt:145-150` matches `CMAKE_SYSTEM_PROCESSOR` against lowercase `^(arm|aarch64)` and `CMAKE_GENERATOR_PLATFORM` against lowercase `^(arm|arm64)`. CMake's platform is `ARM64`. | The target can fall through to `NCNN_TARGET_ARCH x86`, selecting incompatible x86 sources and flags. | After the CI-only probe, normalize or case-insensitively match the ARM64 platform in pinned NCNN. | Require configure output `Target arch: arm`; inspect generated source lists and compile commands. |
| NCNN's fallback is explicitly x86/SSE2. | `change required` | `C:\upscayl-ncnn\src\ncnn\CMakeLists.txt:213-218` selects x86 in the final `else`; `src\ncnn\src\CMakeLists.txt:325-329` applies `/arch:SSE2 /D__SSE2__` for MSVC x86. | Misclassification should fail compilation or, worse, configure the wrong optimized implementation set. | Correct target detection rather than suppressing individual SSE errors. | Assert no x86 layer source or `/arch:SSE2` appears in ARM64 compile commands. |
| ARM64/NEON implementation paths exist. | `ready` | `src\ncnn\CMakeLists.txt:145-169` selects `NCNN_TARGET_ARCH arm`; `src\ncnn\src\CMakeLists.txt:400-408` contains AArch64 optimization handling; ARM layer sources are present under `src\ncnn\src\layer\arm`. | The pinned dependency has an Arm implementation base; the primary problem is selection and Windows validation. | Preserve runtime CPU dispatch initially; avoid speculative optimization changes. | Compile ARM sources and run representative CPU fallback operations on Arm64. |
| Vulkan is enabled by the backend. | `ready` | `C:\upscayl-ncnn\src\CMakeLists.txt:142-143` enables `NCNN_VULKAN` and `NCNN_VULKAN_ONLINE_SPIRV`; lines 274-280 create shader-generation dependencies. | GPU inference support is intentionally in the target build graph. | Keep Vulkan enabled for the Tier 1 path. | Confirm Vulkan symbols, enumerate Adreno, and complete the fixed inference fixture. |
| Backend shaders are generated by a host executable. | `runtime validation` | `C:\upscayl-ncnn\src\CMakeLists.txt:31-73` finds `glslangValidator` with `NO_CMAKE_FIND_ROOT_PATH` and invokes it in custom commands. | Correctly separates a build-host tool from target code, but availability/execution on the selected runner is unproven. | Supply a runnable host `glslangValidator`; do not package it as a target dependency. | Generate all `.spv.hex.h` outputs and verify incremental regeneration. |
| Vulkan CPU fallback behavior is not yet proven on Windows Arm64. | `runtime validation` | `C:\upscayl-ncnn\src\main.cpp:1163-1177` creates the NCNN GPU instance and selects a default GPU; no Arm64 run exists. | Build success alone does not prove device enumeration, shader compatibility, or fallback behavior. | Preserve current behavior for the first build; diagnose only from target logs. | Test GPU enumeration, selected Adreno inference, invalid-GPU handling, and an agreed CPU diagnostic if supported. |

### 4. Vulkan target headers/import libraries/runtime versus host tools such as `glslangValidator`

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| Vulkan headers are architecture-neutral target inputs. | `ready` | `C:\upscayl-ncnn\src\CMakeLists.txt:29` uses `find_package(Vulkan REQUIRED)`; source consumes Vulkan declarations rather than shipping header binaries. | The same headers can describe an ARM64 target, subject to SDK version compatibility. | Reuse headers from the pinned SDK package. | Record `Vulkan_INCLUDE_DIR` and compile target sources. |
| `vulkan-1.lib` must match ARM64. | `unknown` | `src\CMakeLists.txt:282` links `${Vulkan_LIBRARY}`. Local Windows SDK inspection found ARM64 WIC libraries but no `vulkan-1.lib`; the workflow downloads Vulkan SDK 1.3.261.1 at `CI.yml:19-30`. | An x64 Vulkan import library cannot be linked into an ARM64 executable. | Inspect the downloaded SDK layout on the runner; provide an official ARM64 loader import library only if absent. | Use `dumpbin /headers` on the resolved library/object members and link an ARM64 binary. |
| `vulkan-1.dll` must be an ARM64 runtime supplied by Windows/OEM Vulkan installation. | `runtime validation` | Current x64 backend imports `vulkan-1.dll`; read-only `dumpbin /dependents` output recorded that import. No ARM64 runtime was inspected. | Packaging an x64 loader would break native execution; relying on a missing target loader would prevent startup. | Prefer the target's official Vulkan runtime/driver unless deployment guidance requires an app-local ARM64 loader. | On Snapdragon X, resolve the loaded module path and machine type, enumerate the Adreno device, and run inference. |
| `glslangValidator` may remain a host binary. | `ready` | `src\CMakeLists.txt:31-73` explicitly searches outside the target root and uses the executable only to generate headers. | In an x64-host cross-build it may be x64; it is not linked into or shipped with `upscayl-bin.exe`. | Keep host and target SDK paths explicit. | Run the tool on the host, hash generated shader headers, and verify it is absent from the package. |
| Bundled glslang libraries are target binaries. | `runtime validation` | NCNN is built from the pinned nested glslang submodule while `NCNN_VULKAN_ONLINE_SPIRV` is enabled at `src\CMakeLists.txt:143`. | Libraries linked into NCNN must be ARM64 even though the standalone validator may be x64. | Let the ARM64 CMake target build the nested libraries; do not reuse x64 `.lib` files. | Inspect all linked libraries/objects and final PE architecture. |

### 5. libwebp Windows ARM64 compilation, NEON/SIMD dispatch, and x86-source exclusion

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| libwebp explicitly supports MSVC ARM64 NEON intrinsics. | `ready` | `C:\upscayl-ncnn\src\libwebp\src\dsp\dsp.h:122-131` enables `WEBP_USE_NEON` and `WEBP_USE_INTRINSICS` for `_MSC_VER >= 1920 && _M_ARM64`. | The pinned library contains a direct Windows ARM64 SIMD path. | Retain SIMD for the normal build. | Confirm `_M_ARM64`, `WEBP_HAVE_NEON`, and NEON source compilation in logs. |
| SIMD availability is compile-probed. | `ready` | `src\libwebp\cmake\cpu.cmake:12-36` probes each `WEBP_USE_*`; lines 39-58 enumerate SSE/NEON flags; lines 83-123 include supported source files and exclude failed families. | Unsupported x86 intrinsics should be omitted rather than blindly compiled for ARM64. | Keep `WEBP_ENABLE_SIMD=ON` initially. | Inspect configure probe results and generated source lists for NEON present and SSE absent. |
| x86-only SIMD source exclusion must be observed, not assumed. | `runtime validation` | `src\libwebp\CMakeLists.txt:179` removes `WEBP_SIMD_FILES_NOT_TO_INCLUDE`; lines 381-392 assign flags only to included SIMD files. No ARM64 configure ran. | A probe or variable-flow defect could still include x86 files. | Change nothing until compile commands show an actual failure. | Assert no `_sse2.c`/`_sse41.c` compilation and run WebP encode/decode tests. |
| Backend limits libwebp to required libraries. | `ready` | `C:\upscayl-ncnn\src\CMakeLists.txt:249-263` enables SIMD and disables command-line tools, extras, animation utilities, and JavaScript. | Reduces the target surface and avoids unrelated host utilities. | Preserve the minimal option set. | Verify only expected webp targets enter the link graph. |

### 6. WIC, COM, filesystem, Unicode paths, and other `_WIN32` source portability

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| WIC and COM calls are processor-neutral Windows APIs. | `ready` | `C:\upscayl-ncnn\src\wic_image.h:4-32` uses `wincodec.h`, `IWICImagingFactory`, and `CoCreateInstance`; installed ARM64 SDKs contain `windowscodecs.lib`. | No x86 intrinsic or ABI assumption is visible in this path. | Keep WIC as the Windows codec path. | Decode and encode PNG/JPEG on Arm64, including alpha images. |
| The Windows entry point and arguments are Unicode. | `ready` | `C:\upscayl-ncnn\src\main.cpp:42-137` implements wide-character option parsing; lines 741-767 use `wmain`; `filesystem_utils.h:23-27` defines Windows `path_t` as `std::wstring`. | Paths are not constrained to the active ANSI code page at the process boundary. | Preserve the wide path flow. | Run the fixed fixture from paths containing non-ASCII characters and spaces. |
| Windows filesystem access uses wide APIs. | `ready` | `C:\upscayl-ncnn\src\filesystem_utils.h:50-91` uses `GetFileAttributesW` and wide directory APIs; lines 152-160 use `GetModuleFileNameW`; lines 190-194 use `_wfopen`. `webp_image.h:50-125` also uses `_wfopen` on Windows. | The major file operations are architecture-neutral and Unicode-aware. | No architecture-specific change proposed. | Test file, directory, relative-model, and long/non-ASCII path cases on Arm64. |
| Fixed-size executable path storage and filename narrowing need runtime coverage. | `runtime validation` | `filesystem_utils.h:59-65` narrows a filename to `std::string` for extension checks; lines 154-160 use a 256-wide-character buffer without truncation handling. | These are existing Windows path risks, not proven Arm64 blockers, but packaging paths could expose them. | Do not mix this cleanup into the first port slice; file a separate fix if reproduced. | Exercise long packaged paths and non-ASCII filenames, checking discovery and diagnostics. |
| COM lifecycle behavior is unverified. | `runtime validation` | `main.cpp:1163-1165` calls `CoInitializeEx`; no matching `CoUninitialize` was found by source search. | This is not architecture-specific, but target runs must confirm WIC and shutdown behavior. | Preserve behavior for the first build; address separately if diagnostics warrant it. | Run repeated decode/encode and clean process shutdown under diagnostics. |

### 7. OpenMP and ARM64 `vcomp` runtime/distribution behavior

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| OpenMP is discovered and propagated into both backend and NCNN. | `runtime validation` | `C:\upscayl-ncnn\src\CMakeLists.txt:28`, `83-87`, and `306-308` finds OpenMP, appends flags, and links `${OpenMP_CXX_LIBRARIES}`; `src\ncnn\CMakeLists.txt:60` defaults `NCNN_OPENMP` on. | The selected MSVC OpenMP mode determines the target import and redistributable runtime. | Keep current discovery for the first build and record exactly what CMake resolves. | Inspect configure variables, linker command, and final imports. |
| ARM64 release OpenMP artifacts exist in the installed Enterprise toolchain. | `ready` | Read-only inspection found ARM64 `vcomp.lib` under `VC\Tools\MSVC\14.44.35207\lib\arm64` and release `vcomp140.dll` under `VC\Redist\MSVC\14.44.35112\arm64\Microsoft.VC143.OPENMP`. Microsoft documents `/openmp`: <https://learn.microsoft.com/en-us/cpp/build/reference/openmp-enable-openmp-2-0-support?view=msvc-170>. | A plausible native release runtime exists; its actual build selection and redistribution still need proof. | If the linked import is `VCOMP140.DLL`, stage the matching ARM64 release redistributable according to Microsoft terms. | Verify DLL machine type, release provenance, loader resolution, and parallel execution on Arm64. |
| Current bundled OpenMP DLLs are unusable for an ARM64 package. | `change required` | `C:\upscayl\resources\win\bin\vcomp140.dll` and `vcomp140d.dll` both report PE machine `0x8664` (x64); the `d` file is a debug runtime by name. | Either DLL would violate native dependency closure; the debug DLL must never ship. | Reject both for Arm64 staging; select a release ARM64 runtime only after link evidence. | Recursively inspect package PEs and fail on x64 or debug runtime names. |
| Current release backend directly imports only release `VCOMP140.DLL`. | `ready` | Read-only `dumpbin /dependents` on the bundled x64 `upscayl-bin.exe` listed `VCOMP140.DLL`, not `vcomp140d.dll`. | The debug DLL is apparently extraneous today and should not be copied forward. | Remove debug-runtime staging in a later packaging slice, not during the CI probe. | Compare Release import table with packaged DLL inventory. |
| OpenMP-off is a diagnostic alternative, not a selected product decision. | `unknown` | Pinned NCNN documentation and workflows support `-DNCNN_OPENMP=OFF`; no Upshift64 Arm64 performance or correctness comparison exists. | It may isolate runtime/link issues but may affect CPU performance and behavior. | Use only as an approved diagnostic matrix entry if OpenMP blocks the native build. | Compare correctness and timing with OpenMP on/off after both configurations build. |

### 8. Static and dynamic backend dependency closure

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| NCNN and libwebp are built in-tree and linked as CMake targets. | `ready` | `C:\upscayl-ncnn\src\CMakeLists.txt:134-244` adds pinned NCNN; lines 246-266 add pinned libwebp; line 282 links `ncnn webp ${Vulkan_LIBRARY}`. | The project can rebuild these dependencies for ARM64 rather than reusing bundled x64 binaries. | Keep in-tree builds for the first native attempt. | Inspect target architecture for every produced `.lib` and the final executable. |
| Current direct dynamic imports are narrowly bounded. | `ready` | Read-only `dumpbin /dependents` on `resources\win\bin\upscayl-bin.exe` reported `vulkan-1.dll`, `ole32.dll`, `KERNEL32.dll`, `OLEAUT32.dll`, and `VCOMP140.DLL`. | The observed x64 closure has three Windows system DLLs plus Vulkan and OpenMP runtime obligations. | Use this as the expected-name baseline, not as proof of future ARM64 closure. | Record ARM64 direct imports, then recursively resolve non-system DLLs. |
| The current backend and bundled runtime files are x64. | `change required` | PE machine `0x8664` was observed for `upscayl-bin.exe`, `vcomp140.dll`, and `vcomp140d.dll`; backend SHA256 is `704FD622984220C8C646A8DFF4C7EBA1CC62FBB8C47383996F38571F76B73FBF`. | None can be reused as a native ARM64 payload. | Build a new backend and stage only architecture-matched release dependencies. | Require ARM64 PE machine type for every non-system executable/DLL. |
| Future transitive ARM64 closure is not known. | `unknown` | No ARM64 executable exists, so no target import table or loader trace can be inspected. | Additional compiler, Vulkan, or runtime dependencies may appear. | Add recursive PE/import verification immediately after the first successful build. | Fail CI on x64/ARM64EC/debug payloads unless explicitly approved and documented. |

### 9. Backend/application artifact layout, architecture names, staging, updater collisions, and native helpers

| Finding | Status | Exact evidence | Impact | Minimal candidate, not adopted | Validation test |
| --- | --- | --- | --- | --- | --- |
| Backend Windows archive naming omits architecture. | `change required` | `C:\upscayl-ncnn\.github\workflows\release.yml:178-207` names the package `...-windows`; lines 200-207 stage and upload it without an architecture suffix. | x64 and Arm64 artifacts would collide or be indistinguishable. | Add `windows-x64`/`windows-arm64` naming after the build path is proven. | Publish both in a dry-run/release candidate and assert unique names and contents. |
| Application artifact naming omits architecture. | `change required` | `C:\upscayl\package.json:76` uses `${name}-${version}-${os}.${ext}`. | Installers, ZIPs, blockmaps, and updater metadata can collide across Windows architectures. | Add architecture to artifact names in a later packaging slice. | Build both architectures and assert unique artifacts/update metadata. |
| App packaging maps one OS-wide backend directory into one runtime path. | `change required` | `package.json:81-92` copies `resources/${os}/bin` to `resources/bin`; `electron\utils\get-resource-paths.ts:7-18` resolves one `upscayl-bin` path. | A single `resources\win\bin` cannot safely represent both x64 and ARM64 source payloads. | Introduce architecture-specific source staging while preserving the packaged runtime path if practical. | Inspect packaged resources and spawn the backend on both architectures. |
| Backend spawning is architecture-neutral once the correct payload is staged. | `ready` | `electron\utils\spawn-upscayl.ts:1-24` launches the resolved executable without x64-specific flags. | Handoff code may not need modification if packaging selects the right backend. | Prefer staging changes over runtime branching unless tests require branching. | Launch, cancel, and collect diagnostics from the packaged ARM64 app. |
| Current Sharp lock data lacks a Windows ARM64 package. | `change required` | `C:\upscayl\package-lock.json:1833-1873` records Windows ia32/x64 packages; lines 11778-11796 list optional Sharp packages without `@img/sharp-win32-arm64`. | Electron packaging or runtime image operations may install an x64 native module or omit Sharp support. | Evaluate a Sharp version/package strategy in a separate app slice; do not update dependencies during backend work. | Install from a clean lockfile for win32/arm64 and inspect/load every native module. |
| Existing app workflows and upload globs do not distinguish architectures. | `change required` | `.github\workflows\build-windows.yml:31-52` uploads generic `.exe`, `.zip`, `.blockmap`, and `.yml`; `.github\workflows\main.yml:55-68` publishes one Windows build. | Release and updater channels cannot safely carry parallel x64/Arm64 products. | Design architecture-specific jobs, names, and update metadata after Tier 1. | Verify parallel publication without overwrite and test updater selection. |

## Host-tool versus ARM64 target-binary classification

| Component | Required architecture | Evidence and rule |
| --- | --- | --- |
| CMake executable and generator driver | Build host | May be x64 in a cross-build or ARM64 on `windows-11-arm`; it generates target projects. |
| MSBuild, `cl.exe`, linker, librarian | Build host executable capable of ARM64 target output | Local `Hostx64\arm64\cl.exe` is valid for cross-building; produced objects/libraries must be ARM64. |
| `glslangValidator` | Build host | Invoked by `src\CMakeLists.txt:31-73` to generate shader headers; it is not linked or shipped. |
| Vulkan headers | Architecture-neutral input | Declarations may be shared across host/target configurations. |
| `vulkan-1.lib` | ARM64 target | It participates in the final link and must match the target machine. |
| Vulkan loader/driver DLLs | ARM64 target/runtime | Must be native target components supplied by the OS/OEM or an approved ARM64 distribution. |
| Generated `.spv.hex.h` shader data | Architecture-neutral generated data | Generated on the host and compiled as data into the target. |
| NCNN, nested glslang libraries, libwebp | ARM64 target | They are linked into the final executable and cannot be reused from x64. |
| `vcomp.lib` and redistributable `vcomp140.dll` | ARM64 target | Link/runtime pair must be release ARM64; x64 and debug DLLs are rejected. |
| WIC/COM/Windows SDK import libraries | ARM64 target | Installed ARM64 `windowscodecs.lib` confirms the SDK side is available locally. |
| `upscayl-bin.exe` | ARM64 target | Tier 1 requires a native ARM64 PE and complete native dependency closure. |
| Electron executable, Sharp, native Node modules, helpers | ARM64 target | Every packaged native image must match the application architecture. |

## Ranked blockers and open questions

### Critical

1. Pinned NCNN's lowercase platform tests likely misclassify official uppercase
   Visual Studio `ARM64` and activate the x86/SSE2 fallback.
2. No ARM64 backend has been configured, built, linked, or run; Tier 1 cannot be
   claimed from static evidence.
3. The resolved ARM64 `vulkan-1.lib` source and Snapdragon X Vulkan runtime
   behavior are unproven.

### High

1. Both backend Windows workflows are x64-only, and the application Windows
   workflows do not request Arm64.
2. Current bundled backend/OpenMP DLLs are x64; the debug `vcomp140d.dll` must
   not ship.
3. Backend and application artifact names omit architecture, creating release
   and updater collision risk.
4. The application lockfile has no Windows Arm64 Sharp package.

### Medium

1. ARM64 OpenMP discovery, selected compiler switch/import library, release DLL
   staging, and redistribution behavior need build and runtime evidence.
2. Host `glslangValidator` availability and execution must be proven on the
   chosen runner while nested target glslang libraries remain ARM64.
3. libwebp's expected NEON selection and SSE source exclusion need configure
   and compile-command evidence.
4. WIC, WebP, Unicode, long-path, cancellation, and error paths need target
   execution.

### Low

1. `GetModuleFileNameW` uses a fixed 256-character buffer.
2. Directory extension checks narrow filenames even though retained paths are
   wide strings.
3. A matching `CoUninitialize` was not found; this is not an identified Arm64
   blocker but belongs in runtime diagnostics.

## Anticipated files for later approved work

### Implemented Step 6 and Step 7 slice

Only the backend `.github/workflows/CI.yml` changed.

The approved implementation added a native `windows-11-arm` diagnostic job,
then iterated from observed CI failures:

1. Current CMake rejected NCNN's legacy policy floor; the job added
   `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`.
2. Pinned NCNN classified uppercase Visual Studio platform `ARM64` as x86; an
   isolated generator probe proved lowercase `-A arm64` still selected the
   native ARM64 compiler and satisfied NCNN's case-sensitive detection.
3. CI built an AA64 `upscayl-bin.exe`.
4. Closure analysis identified `VCOMP140.DLL` as the only application
   redistributable.
5. CI selected the signed release ARM64 Microsoft OpenMP runtime, rejected
   x64/debug/OneCore/Spectre variants, copied it beside the executable, and
   inspected both files recursively.

Final evidence:

| Evidence | Value |
| --- | --- |
| Backend commit | `fd72e621d143f21747fcf0522356480125075fea` |
| CI run | <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34900090037> |
| ARM64 job | `104163707942` |
| Artifact | `upscayl-bin-windows-arm64-diagnostics-34900090037-1` |
| Artifact ZIP SHA256 | `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64` |
| ARM64 executable SHA256 | `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` |
| ARM64 OpenMP runtime SHA256 | `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` |

The executable imports `vulkan-1.dll`, `ole32.dll`, `KERNEL32.dll`,
`OLEAUT32.dll`, and `VCOMP140.DLL`. The Microsoft-signed AA64/ARM64X OpenMP
runtime imports only `KERNEL32.dll`. No x64 or debug runtime entered the
artifact. The Vulkan loader remains a target-device GPU-driver obligation and
is intentionally not copied from the SDK.

### Later backend slices, only if device or release work requires them

- `C:\upscayl-ncnn\src\ncnn\CMakeLists.txt` for the confirmed platform-case
  detection defect.
- `C:\upscayl-ncnn\src\ncnn\src\CMakeLists.txt` only if target-specific source
  or flag selection still requires correction.
- `C:\upscayl-ncnn\src\CMakeLists.txt` for demonstrated Vulkan/OpenMP
  target-resolution issues.
- `C:\upscayl-ncnn\.github\workflows\release.yml` for a proven Arm64 release
  job and architecture-specific package naming.

### Later application packaging slice

- `C:\upscayl\package.json`
- `C:\upscayl\package-lock.json`
- `C:\upscayl\.github\workflows\build-windows.yml`
- `C:\upscayl\.github\workflows\main.yml`
- Architecture-specific backend payload files under a separately approved
  `C:\upscayl\resources` layout.
- `C:\upscayl\electron\utils\get-resource-paths.ts` only if staging cannot keep
  the existing packaged `resources\bin` contract.

No file in these later slices is approved for modification by this audit.

## Implemented first slice and remaining alternatives

The recommended CI-only first slice was implemented and validated without
changing pinned NCNN source, Vulkan source wiring, OpenMP build policy, release
workflow, or application packaging. Steps 6 and 7 are complete. Physical
Snapdragon X execution remains required before claiming runtime success.

### Alternatives not selected

| Alternative | Use | Tradeoff |
| --- | --- | --- |
| x64-host cross-build | Diagnose the same ARM64 target with the locally available `Hostx64\arm64` compiler. | Useful and potentially faster, but does not replace target-runner or device proof. |
| Diagnostic OpenMP-off build | Isolate OpenMP discovery/link/runtime failures. | May change CPU behavior/performance and is not the selected shipping configuration. |
| NCNN update | Adopt newer upstream Windows ARM64 handling rather than patching the pin. | Broadens change and regression scope; requires a separate dependency decision and audit. |

None of these alternatives was adopted. They remain options only if physical
device evidence exposes a blocker that the proven CI build cannot diagnose.

## Post-audit physical validation

Steps 6 through 8 resolved the Tier 1 questions raised by this audit without
changing pinned NCNN source:

- lowercase `-A arm64` selected the native compiler while satisfying pinned
  NCNN's case-sensitive target detection;
- the native CI build and signed ARM64 OpenMP closure passed;
- the transferred payload retained its expected hashes, AA64 machine type,
  signature, and imports;
- the system Microsoft-signed Vulkan loader dispatched to the native Qualcomm
  Adreno ICD;
- physical GPU 0 completed the fixed upscale offline after an approved change
  from auto tile size to `200`.

The genuinely offline auto-tile run remains important negative evidence:
`vkQueueSubmit` returned `VK_ERROR_DEVICE_LOST`, followed by process exit
`0xc0000005`. The approved `-t 200` run exited 0 in `7603.69 ms` and produced a
1024x1024 PNG with SHA256
`7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269`.

This closes the audit's backend Tier 1 runtime boundary. It does not resolve
the application packaging, Sharp/native Node module, artifact naming, updater,
installer, or GUI validation findings.
