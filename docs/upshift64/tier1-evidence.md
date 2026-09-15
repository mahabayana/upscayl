# Tier 1 evidence: physical Windows-on-Arm Vulkan inference

## Result

**PASS.** The CI-produced native ARM64 backend completed the fixed Upshift64
upscale offline through the native Qualcomm Adreno Vulkan ICD on physical
Windows-on-Arm hardware.

This result validates the backend CLI only. Electron packaging, installation,
GUI behavior, updater behavior, and application-level backend selection were
not tested.

## Provenance chain

| Item | Value |
| --- | --- |
| Backend repository | <https://github.com/mahabayana/upscayl-ncnn> |
| Branch | `hackathon/upshift64-win-arm64` |
| Backend commit | `fd72e621d143f21747fcf0522356480125075fea` |
| CI run | <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34900090037> |
| ARM64 job | `104163707942` |
| Artifact ID | `10371015381` |
| Artifact name | `upscayl-bin-windows-arm64-diagnostics-34900090037-1` |
| Artifact ZIP SHA256 | `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64` |
| Corrected evidence manifest SHA256 | `4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2` |

GitHub's Actions artifact endpoint rejected an unauthenticated target-device
download with HTTP 401. No CLI or credential was installed. The already
verified ZIP, fixture, and model files were transferred by the owner and
rehashed on the target.

## Device and Vulkan environment

| Field | Observed value |
| --- | --- |
| Manufacturer/model | OEMBR / `OEMBR Product Name DV CVL2` |
| Native system | ARM64-based PC |
| Processor evidence | Qualcomm ARMv8, 10 cores; CIM exposed a conflicting `8cx gen 3` brand string |
| Windows evidence | Windows 11, DisplayVersion 25H2; build strings reported `26100.1.arm64fre` and `26200` |
| GPU | Qualcomm Adreno X1-85 |
| Display driver | `31.0.133.1`, dated 2025-11-08 |
| Power at initial inventory | Battery, 40%, Balanced plan |
| System Vulkan loader | Microsoft-signed `vulkan-1.dll` `1.3.300.0` |
| Native ICD | `DRIVER_ID_QUALCOMM_PROPRIETARY` |
| Vulkan API | `1.3.295` |
| Vendor | `0x5143`, Qualcomm |

The firmware/CIM processor label conflicts with the GPU/platform evidence and
is preserved as observed rather than normalized into an unsupported exact CPU
SKU claim.

`vulkaninfo --summary` enumerated:

1. native Qualcomm proprietary Adreno ICD — selected as GPU 0;
2. Mesa Dozen Vulkan-over-D3D12 mapping of the Adreno GPU — excluded;
3. Mesa Dozen Microsoft Basic Render Driver software device — excluded.

Provider identity, not the shared Adreno name, distinguished the native ICD.

## Payload and fixed inputs

| File | Target evidence | SHA256 |
| --- | --- | --- |
| `upscayl-bin.exe` | PE `0xaa64`; expected imports | `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` |
| `vcomp140.dll` | PE `0xaa64`; valid Microsoft signature; imports only `KERNEL32.dll` | `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` |
| Input JPEG | 256x256 fixed fixture | `8E9EB94064D1776381B7364AF571AF7953407586B8FF4267FCA3B881D671EE5C` |
| Model parameter file | `upscayl-standard-4x` | `35330ECECCEA33B6C397A72548E788D5D53BECEE4734C50B7FADA36E89F10A86` |
| Model binary | `upscayl-standard-4x` | `713EE713B0353AFAA27976F0563A64A5043BD70B9BD8936C2E26E25EBCDBCDDF` |

`dumpbin` was unavailable on the target. An approved no-install PowerShell
parser independently validated the PE signature, COFF Machine field, and
direct import table. CI retained the authoritative `dumpbin` evidence.

No app-local `vulkan-1.dll` was present. Windows supplied the Microsoft-signed
loader, which dispatched to the installed Qualcomm ICD.

## Run history

| Run | Parameters | Offline proof | Result |
| --- | --- | --- | --- |
| 1 | GPU 0, `-t 0` | Retracted: event history showed a silent remembered-network reconnection before execution | Exit 0 and output, retained only as functional history |
| 2 | GPU 0, `-t 0` | Valid immediate checks | `VK_ERROR_DEVICE_LOST`, repeated queue-submit failures, then `0xc0000005`; no accepted output |
| 3 | GPU 0, `-t 200` | Valid immediate checks and NetworkProfile correlation | Exit 0; authoritative PASS |

The tile-size change was separately approved only after preserving the Run 2
failure. It is a proven remediation for this device/driver/fixture, not a
universal Windows-on-Arm default.

## Authoritative command

Machine-specific roots and the public connectivity probe are represented by
placeholders:

```powershell
<payload>\upscayl-bin.exe `
  -i <evidence-root>\fixture\to_upscale.jpeg `
  -o <evidence-root>\output\to_upscale-upscayl-standard-4x-arm64-t200.png `
  -m <evidence-root>\fixture\models `
  -n upscayl-standard-4x `
  -g 0 `
  -t 200 `
  -f png `
  -v
```

The adapter was disabled immediately before execution. Connectivity checks
were false immediately before and after the process while the adapter remained
disabled. NetworkProfile events contained no connection during the run window.
The adapter was re-enabled and connectivity restoration was confirmed.

## Authoritative output

| Field | Value |
| --- | --- |
| Exit code | `0` |
| Start | `2026-09-15T01:51:58Z` |
| End | `2026-09-15T01:52:06Z` |
| Duration | `7603.69 ms` |
| Selected device | GPU 0, Qualcomm Adreno X1-85 |
| Dimensions | 1024x1024 |
| Bytes | 1,952,322 |
| SHA256 | `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269` |

Run 1 and Run 3 produced byte-identical output despite different tile sizes.
The ARM64/Adreno hash differs from the x64/NVIDIA reference
`DCC617E967905E61F987374A7F692407EE2C4CE90484F1509ABFBFB1597F2404`.
That cross-vendor difference is not by itself a failure; floating-point and
shader implementations can produce bit-different valid images. No separately
approved pixel/perceptual comparison was run.

The timing is a single functional observation, not a benchmark. Exact run-time
power state was not recaptured, the device and GPU differ from the x64
reference, and the successful ARM64 run used an explicit tile size.

## Evidence integrity

The external evidence bundle was sanitized after execution:

- personal network names were redacted;
- device and driver UUID values were redacted;
- the public probe IP was replaced with a placeholder;
- the Run 2 `-t 0` failure remained distinct from the Run 3 `-t 200` success;
- stale timing/command claims were corrected;
- every one of 31 manifest rows was recomputed and matched its file;
- privacy and stale-value searches returned no matches.

The manifest does not hash itself. Its final SHA256 is
`4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2`.

## Tier 1 conclusion and remaining scope

Tier 1 is complete: a native ARM64 backend with a signed ARM64 OpenMP runtime
was built in CI, statically closed, transferred with intact hashes, loaded the
system Vulkan stack, selected the native Qualcomm ICD, and completed the fixed
upscale offline on physical Windows-on-Arm hardware.

Still unproven:

- Electron ARM64 packaging and resource staging;
- Sharp/native Node module and helper executable closure;
- installer, launch, GUI, cancellation, output-opening, and offline app flow;
- architecture-specific artifacts and updater metadata;
- repeatable performance under controlled power/thermal conditions.
