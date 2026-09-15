# Step 008: Physical Snapdragon Vulkan inference

- **Timestamp (UTC):** `2026-09-15T01:51:58Z` through
  `2026-09-15T01:52:06Z` for the authoritative run
- **Objective:** Prove native offline Vulkan inference on physical
  Windows-on-Arm hardware.
- **Owner approval:** Durable reference: the owner approved each inventory,
  staging, execution, and tile-size remediation gate in the physical-device
  session. The owner directly executed the final adapter/inference/restore
  script.
- **Agent:** GitHub Copilot CLI on the physical device, with final evidence
  correction and verification by this GitHub Copilot CLI session
- **Skill:** `upshift64-port`
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Task prompt:** The detailed Step 8 physical-device prompt requiring
  native ARM64, payload/fixture hashes, native Vulkan selection, offline proof,
  output validation, sanitization, and skill/agent learning.
- **Affected files:** External evidence bundle only during execution; this
  record documents the result.
- **Commit:** Not created
- **Pull request:** Not created
- **CI:** Source artifact from
  <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34900090037>

## Inputs

| Item | Value |
| --- | --- |
| Backend commit | `fd72e621d143f21747fcf0522356480125075fea` |
| Artifact ID | `10371015381` |
| Artifact ZIP SHA256 | `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64` |
| Executable SHA256 | `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` |
| OpenMP DLL SHA256 | `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` |
| Input SHA256 | `8E9EB94064D1776381B7364AF571AF7953407586B8FF4267FCA3B881D671EE5C` |
| Model param SHA256 | `35330ECECCEA33B6C397A72548E788D5D53BECEE4734C50B7FADA36E89F10A86` |
| Model bin SHA256 | `713EE713B0353AFAA27976F0563A64A5043BD70B9BD8936C2E26E25EBCDBCDDF` |

The target lacked `gh` and `dumpbin`. An unauthenticated artifact request
returned HTTP 401, so the owner transferred the ZIP and fixed inputs. Hashes
were reverified after transfer. An approved built-in PowerShell parser checked
the PE signature, `0xaa64` machine field, and import tables. The Microsoft
OpenMP DLL signature was valid.

## Device and Vulkan evidence

- native ARM64 Windows device;
- Qualcomm Adreno X1-85, display driver `31.0.133.1`;
- Microsoft-signed system Vulkan loader `1.3.300.0`;
- native GPU 0:
  `DRIVER_ID_QUALCOMM_PROPRIETARY`, vendor `0x5143`, Vulkan `1.3.295`;
- Dozen Vulkan-over-D3D12 and Basic Render Driver devices excluded.

## Run history and decision

Run 1 completed but its offline claim was retracted when event history proved a
remembered network had reconnected before execution.

Run 2 was genuinely offline with auto tile size. It emitted
`VK_ERROR_DEVICE_LOST`, repeated `vkQueueSubmit failed -3`, and exited
`0xc0000005`.

After the owner separately approved a diagnostic tile-size change, Run 3 used
GPU 0 and `-t 200`. Immediate connectivity checks were false before and after
the process while the adapter remained disabled. NetworkProfile events showed
no connection during the run window. Wi-Fi and connectivity were restored.

## Authoritative output

- exit code: `0`;
- duration: `7603.69 ms`;
- selected device: Qualcomm Adreno X1-85 GPU 0;
- dimensions: 1024x1024;
- bytes: `1,952,322`;
- SHA256:
  `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269`.

The output differs from the x64/NVIDIA reference hash, which is not a
cross-vendor failure criterion. Run 1 and Run 3 were byte-identical.

## Evidence correction and validation

The transferred evidence copy was corrected without rerunning inference:

- personal network names, Vulkan UUID values, and the public probe IP were
  redacted;
- the authoritative `-t 200` command and `7603.69 ms` timing replaced stale
  success statements;
- Run 2's `-t 0` crash was preserved;
- 31 manifest rows were recomputed and matched actual file hashes and sizes;
- privacy and stale-value scans returned no matches.

Corrected evidence manifest SHA256:
`4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2`.

## Known limitations

- Backend CLI only; Electron was not packaged or tested.
- `dumpbin` was unavailable on-device; CI `dumpbin` evidence and an independent
  PowerShell PE parser were used.
- No peak-memory measurement or perceptual image comparison was performed.
- Timing is one uncontrolled functional observation, not a benchmark.
- The tile-size result is specific to this device, driver, model, and input.
