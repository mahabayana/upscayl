# Upshift64 Steps 1-9 Summary

Tier 1 is complete. The first nine steps established a reproducible native
Windows ARM64 backend, proved it on physical Snapdragon X-class hardware, and
captured the process as reusable agent tooling.

## Step 1: Choose and scope the app

**Why:** We needed a useful open-source app with a clear Windows-on-Arm gap and
a realistic hackathon boundary.

**What we did:** Selected Upscayl and divided the project into:

- Tier 1: native ARM64 inference backend;
- Tier 2: usable Windows ARM64 Electron application;
- optional exceeds-expectations work.

## Step 2: Prepare the Upscayl application repository

**Why:** Reproducible work needs a known starting commit and an isolated branch.

**What we did:** Prepared `C:\upscayl`, pinned application commit
`a00d55fee90e0f9435d5eaa86e76700df8199af8`, and created
`hackathon/upshift64-win-arm64`. No application implementation was changed at
this stage.

## Step 3: Prepare the native backend repository

**Why:** Electron launches a separate native NCNN/Vulkan executable, so the
backend had to be handled independently from the application.

**What we did:** Prepared `upscayl-ncnn`, initialized and pinned NCNN, libwebp,
glslang, and pybind11, created an isolated backend branch, and started the
agent-authorship and provenance records.

## Step 4: Create an unchanged x64 reference

**Why:** We needed a known-good input, model, command, and output before
changing architectures. This gave us a functional reference for later ARM64
testing.

**What we did:** Ran the unchanged x64 backend on an NVIDIA GeForce RTX 4060
Laptop GPU using:

- a fixed 256x256 input image;
- the bundled `upscayl-standard-4x` model;
- a recorded command and Vulkan device;
- hashes for the executable, input, model, logs, and output.

The run exited successfully in 4245 ms and produced a 1024x1024 output image.
This was one functional reference, not a cross-device performance benchmark.

## Step 5: Audit Windows ARM64 blockers

**Why:** Changing files before understanding the build graph could create
unnecessary fixes, hide architecture problems, or package incompatible native
binaries.

**What we did:** Audited:

- CI, CMake, and release architecture restrictions;
- Visual Studio, MSVC ARM64, and Windows SDK readiness;
- NCNN ARM64 detection, ARM/NEON code, and x86 fallback behavior;
- Vulkan headers, target libraries, loader/driver ownership, and shader tools;
- libwebp ARM64 SIMD support;
- WIC, COM, Unicode, and Windows filesystem paths;
- OpenMP linking and the `vcomp140.dll` runtime;
- native executable and DLL dependency closure;
- Sharp, Electron helpers, application staging, updater metadata, and artifact
  naming.

We separated build-host tools from ARM64 target binaries and documented the
smallest implementation path. Qualcomm EasyWoS methodology was applied
manually; its scanner was not claimed as executed because its approved setup
stopped at a missing `libmagic` dependency.

## Step 6: Build the backend natively in ARM64 CI

**Why:** A local cross-build alone would not prove that the backend builds
correctly on real Windows ARM64 infrastructure.

**What we did:** Added a separate GitHub Actions `windows-11-arm` job and:

- pinned and checksum-verified the official ARM64 Vulkan SDK;
- verified the ARM64 compiler, Windows SDK, Vulkan import library, and shader
  validator;
- added a CMake compatibility setting after the first observed failure;
- discovered that pinned NCNN misclassified uppercase `ARM64` as x86;
- validated and used lowercase `-A arm64`;
- built only the Release `upscayl-bin` target;
- required CMake to report `Target arch: arm`;
- verified the output as an AA64 executable.

This produced the first CI-built native Windows ARM64 backend.

## Step 7: Close the native dependency chain

**Why:** An ARM64 executable still cannot launch correctly if it loads an x64
or debug DLL.

**What we did:** Inspected every direct dependency and classified it:

- Windows supplies the COM and kernel system DLLs;
- the installed GPU driver supplies `vulkan-1.dll`;
- the application must package Microsoft OpenMP runtime `vcomp140.dll`.

We selected Visual Studio's signed release ARM64 OpenMP runtime, rejected x64,
debug, OneCore, and Spectre variants, copied the correct DLL beside
`upscayl-bin.exe`, and inspected both files. The resulting two-file artifact
contained no x64 or debug runtime payload.

## Step 8: Run real offline inference on Snapdragon X-class hardware

**Why:** A successful build does not prove that the Qualcomm Vulkan driver can
load the backend and execute the model on a physical Windows-on-Arm device.

**What we did:** On a native ARM64 device with a Qualcomm Adreno X1-85 GPU:

- reverified the artifact, executable, runtime, input, and model hashes;
- verified both payload files as ARM64;
- confirmed the Microsoft signature on `vcomp140.dll`;
- used the system Microsoft-signed Vulkan loader;
- selected the native Qualcomm ICD as GPU 0;
- excluded the Vulkan-over-D3D12 Dozen device and software renderer;
- ran the fixed upscale with networking disabled;
- checked offline status immediately before and after inference;
- corroborated the run window using Windows NetworkProfile events;
- restored Wi-Fi afterward.

The first genuinely offline auto-tile run (`-t 0`) encountered
`VK_ERROR_DEVICE_LOST` and exited with `0xc0000005`. After a separately approved
diagnostic change, the `-t 200` run succeeded:

- exit code: `0`;
- duration: `7603.69 ms`;
- output: 1024x1024 PNG;
- output size: 1,952,322 bytes;
- output SHA256:
  `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269`.

The ARM64/Adreno output hash differs from the x64/NVIDIA reference, which is
acceptable because different GPU vendors can produce bit-different valid
floating-point results. The run passed the functional criteria.

## Step 9: Publish Tier 1 evidence and reusable tooling

**Why:** The hackathon requires reusable agents and skills plus defensible
evidence, not only a working executable.

**What we did:**

- sanitized the physical-device evidence;
- preserved all three run outcomes and corrected the initial offline claim;
- redacted personal network names, UUID values, and the connectivity-probe IP;
- verified all 31 evidence-manifest entries against the actual files;
- recorded corrected manifest SHA256
  `4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2`;
- published the Tier 1 report and provenance;
- updated the project plan, README, audit, reusable porting skill, and builder
  agent;
- added a dedicated physical Windows-on-Arm device-testing agent.

Tier 1 now proves that the native backend builds in ARM64 CI, has a compatible
dependency closure, and performs real offline Vulkan inference on physical
Windows-on-Arm hardware.

## Moving to Tier 2

Tier 2 begins with Step 10: package the complete Electron application for
Windows ARM64.

The next work must:

- stage the verified ARM64 backend and OpenMP runtime correctly;
- make the application select architecture-compatible resources;
- resolve Sharp, native Node modules, and helper executable architectures;
- produce uniquely named Windows ARM64 ZIP and installer artifacts;
- recursively inspect every packaged native binary;
- install and test the complete GUI on Snapdragon hardware;
- validate launch, file selection, upscale, cancellation, output opening,
  diagnostics, and offline operation.

No Tier 2 implementation has started. Its packaging design and exact generated
changes require separate approval.
