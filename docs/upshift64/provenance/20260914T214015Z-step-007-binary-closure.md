# Step 007: Native binary dependency closure

- **Timestamp (UTC):** `2026-09-14T21:40:15Z` through
  `2026-09-14T21:45:40Z`
- **Objective:** Produce and verify a runnable ARM64 backend payload containing
  the required Microsoft OpenMP runtime and no x64/debug binaries.
- **Owner approval:** The owner approved the read-only closure investigation,
  then approved the exact ARM64 workflow edit, push, and validation dispatch.
  The recorded approval for implementation was `"yes"`.
- **Agent:** GitHub Copilot CLI
- **Skill:** `upshift64-port`
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Task prompt:** Durable reference: the Step 7 conversation that required
  inspection of every imported/packaged DLL and rejection of x64/debug
  runtimes.
- **Affected files:** Backend `.github/workflows/CI.yml`
- **Commit:** `fd72e621d143f21747fcf0522356480125075fea`
- **Pull request:** Not created
- **CI:** <https://github.com/mahabayana/upscayl-ncnn/actions/runs/34900090037>

## Generated change

The ARM64 job now:

1. locates Visual Studio's release ARM64
   `Microsoft.VC143.OpenMP\vcomp140.dll`;
2. excludes OneCore, debug, Spectre, and non-ARM64 variants;
3. requires AA64 machine type and no x64 record;
4. requires a valid Microsoft Authenticode signature;
5. records runtime path, version, SHA256, and headers;
6. copies the DLL beside `upscayl-bin.exe`;
7. runs `dumpbin /headers /dependents` on both payload files;
8. rejects common debug runtime filenames/imports;
9. uploads both files with configure, build, SDK, and architecture logs.

The Vulkan SDK's `vulkan-1.dll` is intentionally not packaged. Windows-on-Arm
GPU drivers own the Vulkan loader and ICD runtime.

## Validation and outputs

- ARM64 job: `104163707942`
- Result: success
- Artifact:
  `upscayl-bin-windows-arm64-diagnostics-34900090037-1`
- Artifact ID: `10371015381`
- Retention: 14 days
- Artifact ZIP SHA256:
  `A4E12BB9AD697DAFC2D946FE56A7997A93F007C693A5EEB8C1426C7C6FA11E64`

| File | Machine/signature | SHA256 | Imports |
| --- | --- | --- | --- |
| `upscayl-bin.exe` | `AA64 machine (ARM64)`; application binary not signed | `55E7A14D2588918CC3FA8DBBBFC5B5F235538F9741BBCE66AD0557666746735F` | `vulkan-1.dll`, `ole32.dll`, `KERNEL32.dll`, `OLEAUT32.dll`, `VCOMP140.DLL` |
| `vcomp140.dll` | `AA64 machine (ARM64) (ARM64X)`; valid Microsoft signature | `1A455C526E42D80D3AA3189E082500B6EB7837FCF8BE0E9FBD1F26C92ACDAB71` | `KERNEL32.dll` |

The artifact was downloaded and independently rechecked with local `dumpbin`,
`Get-FileHash`, and `Get-AuthenticodeSignature`. No x64 or debug runtime
payload was found.

## Dependency classification

| Dependency | Owner |
| --- | --- |
| `ole32.dll`, `KERNEL32.dll`, `OLEAUT32.dll` | Windows |
| `vulkan-1.dll` and Vulkan ICD | Target device GPU driver |
| `VCOMP140.DLL` | Application-local Microsoft ARM64 redistributable |

## Known limitations

- Static closure does not prove loader resolution on a particular device.
- Physical Snapdragon X inference has not run.
- The Electron application has not staged or launched this payload.
- The backend executable itself is not code-signed.
- Driver version, Vulkan device identity, offline behavior, output hash, and
  timing remain Step 8 evidence.
