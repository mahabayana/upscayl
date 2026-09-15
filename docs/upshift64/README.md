# Upshift64 progress

Upshift64 is an agent-generated Windows-on-Arm port of the Upscayl native
NCNN/Vulkan backend, with reusable agents and skills for future application
ports. Humans approve and review every gated action; agents generate all
repository changes.

For one-page navigation across the plan, reusable skill, and all custom agents,
start with [`workflow-guide.md`](workflow-guide.md).

## Current status

| Step | Outcome |
| --- | --- |
| 1-2 | Scope, success tiers, approval model, and repository boundaries established |
| 3 | Backend and recursive dependencies pinned reproducibly |
| 4 | Unchanged x64 Vulkan inference baseline captured |
| 5 | Windows ARM64 blocker audit completed; EasyWoS methodology applied |
| 6 | Native Windows ARM64 backend built and verified in GitHub Actions |
| 7 | Native executable and Microsoft OpenMP runtime dependency closure verified |
| 8 | Native backend completed offline Vulkan inference on physical Snapdragon X-class hardware |
| 9 | Tier 1 evidence and reusable device-validation workflow published locally |
| 10 | Electron ARM64 package, ZIP, and NSIS installer built and closure-verified in CI |
| 11 | Installed application passed architecture closure, GUI, cancellation, output opening, and offline inference on Snapdragon X |
| 12 | Reusable skill finalized with portable config/evidence schemas, handoff templates, validation scripts, and positive/negative fixtures |

## Proven ARM64 payload

The final Step 7 artifact was produced by:

- backend branch: `hackathon/upshift64-win-arm64`;
- backend commit: `fd72e621d143f21747fcf0522356480125075fea`;
- CI run:
  <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34900090037>;
- successful ARM64 job: `104163707942`;
- artifact: `upscayl-bin-windows-arm64-diagnostics-34900090037-1`.

| File | Evidence |
| --- | --- |
| `upscayl-bin.exe` | AA64; SHA256 `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` |
| `vcomp140.dll` | AA64/ARM64X; valid Microsoft signature; SHA256 `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` |
| Artifact ZIP | SHA256 `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64` |

The executable imports only:

- `vulkan-1.dll`, supplied by the Windows-on-Arm GPU driver;
- Windows system DLLs `ole32.dll`, `KERNEL32.dll`, and `OLEAUT32.dll`;
- packaged Microsoft OpenMP runtime `VCOMP140.DLL`.

No x64 or debug runtime is present in the verified payload.

## Physical Windows-on-Arm validation

The verified payload was transferred to a native ARM64 Windows device and
revalidated before execution.

| Field | Observed value |
| --- | --- |
| Device class | OEM Snapdragon X-class ARM64 PC |
| GPU | Qualcomm Adreno X1-85 |
| GPU driver | `31.0.133.1` |
| Native Vulkan device | GPU 0, `DRIVER_ID_QUALCOMM_PROPRIETARY`, vendor `0x5143` |
| Vulkan API | `1.3.295` |
| System Vulkan loader | Microsoft-signed `vulkan-1.dll` `1.3.300.0` |
| Command parameters | `-n upscayl-standard-4x -g 0 -t 200 -f png -v` |
| Exit code | `0` |
| Duration | `7603.69 ms` |
| Output | 1024x1024 PNG, 1,952,322 bytes |
| Output SHA256 | `7306369C3CC6C71C3FE1DBDA30205B076866BAF02226B1A3DF34713842BE3269` |
| Evidence manifest SHA256 | `4D364D7CE93D8428448AC71D206F0A1E13FC44CF112E14411CDAD0D6CB719DC2` |

The authoritative run remained offline from immediately before process launch
through process exit. This was established by connectivity checks on both
sides of the process and corroborated with the Windows NetworkProfile event
log. Wi-Fi was restored afterward.

The native Qualcomm ICD was selected deliberately. Two other Vulkan devices
were excluded: a Dozen Vulkan-over-D3D12 mapping of the same Adreno GPU and a
Microsoft Basic Render Driver software device.

### Failure-driven target iteration

| Run | Tile size | Offline evidence | Result |
| --- | --- | --- | --- |
| 1 | Auto (`0`) | Retracted after the device silently reconnected before execution | Exit 0; output preserved but not accepted as offline proof |
| 2 | Auto (`0`) | Valid | `VK_ERROR_DEVICE_LOST`, then `0xC0000005`; no output |
| 3 | `200` | Valid pre/post checks plus event-log corroboration | Exit 0; authoritative output |

The Run 1 and Run 3 outputs were byte-identical. The ARM64/Adreno output differs
from the x64/NVIDIA reference hash; cross-vendor floating-point differences
make byte identity an inappropriate cross-GPU pass criterion. The validated
functional criteria are native device selection, exit 0, a valid non-empty
1024x1024 PNG, and retained output hash.

See [`tier1-evidence.md`](tier1-evidence.md) for the complete sanitized report.

## Failure-driven build history

| Run | Result | Narrow response |
| --- | --- | --- |
| `34893473570` | Current CMake rejected NCNN's legacy policy floor | Added `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` |
| `34894677848` | Pinned NCNN reported `Target arch: x86` for uppercase `ARM64` | Proved and applied lowercase `-A arm64` |
| `34895652256` | Native ARM64 configure, build, and executable verification passed | Proceeded to runtime closure |
| `34900090037` | Executable plus signed ARM64 OpenMP runtime closure passed | Steps 6 and 7 complete |

The inherited Windows x64 and Ubuntu jobs separately fail because their old
Vulkan SDK `1.3.261.1` URLs return 404. The macOS 13 job remained queued during
the observed runs. These conditions are not ARM64 build failures and their job
definitions were intentionally left unchanged.

## Reusable outputs

- `.github/skills/upshift64-port/SKILL.md`: approval-gated audit, build,
  closure, packaging, device, and evidence procedure with portable schemas,
  templates, validation scripts, self-tests, and an explicitly separated
  Upscayl case study.
- `.github/agents/upshift64-auditor.agent.md`: read-only Windows ARM64 audit
  specialist.
- `.github/agents/upshift64-builder.agent.md`: failure-driven native ARM64 CI
  and closure specialist.
- `.github/agents/upshift64-device-tester.agent.md`: approval-gated physical
  Windows-on-Arm backend and installed-application validation specialist.
- `docs/upshift64/arm64-port-audit.md`: detailed blocker and architecture
  analysis.
- `docs/upshift64/tier1-evidence.md`: physical Snapdragon X-class validation
  report and limitations.
- `docs/upshift64/provenance/`: owner approvals, generated changes, CI
  evidence, and limitations.
- `docs/upshift64/workflow-guide.md`: one-page plan, skill, agent, and handoff
  navigation.

## What is not yet proven

- application signing, updater behavior, and release publication;
- uninstall behavior, which the project owner explicitly left untested;
- performance or energy improvements against a controlled baseline;
- operation on a second Snapdragon or NVIDIA RTX device.

Tier 1 proves the native backend. Step 11 extends that evidence to the installed
Electron application on physical Snapdragon X hardware. See
[`step11-evidence.md`](step11-evidence.md) for the validated scope and
limitations.
