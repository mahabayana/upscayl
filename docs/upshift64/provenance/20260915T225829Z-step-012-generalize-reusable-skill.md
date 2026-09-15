# Step 012: Generalize the reusable skill

- **Timestamp (UTC):** `2026-09-15T22:58:29Z`
- **Objective:** Remove Upscayl-specific assumptions from the reusable skill
  and agents while preserving the full implementation as an explicit case
  study and local recovery archive.
- **Owner approval:** `"can we dump this info into a backup file and work on edits"` followed by `"yes"`
- **Agent:** GitHub Copilot CLI
- **Skill:** `upshift64-port`
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Task prompt:** The owner asked whether the NCNN/Vulkan/libwebp/OpenMP
  checklist and hashes could be transformed into generic categories, with the
  current information backed up before editing.
- **Affected files:**
  - `.github/skills/upshift64-port/SKILL.md`
  - `.github/skills/upshift64-port/references/project-config.schema.json`
  - `.github/skills/upshift64-port/references/project-config.example.json`
  - `.github/skills/upshift64-port/references/upscayl-project-config.example.json`
  - `.github/skills/upshift64-port/references/upscayl-case-study.md`
  - `.github/skills/upshift64-port/scripts/Test-Upshift64ProjectConfig.ps1`
  - `.github/skills/upshift64-port/tests/run-tests.ps1`
  - `.github/agents/upshift64-auditor.agent.md`
  - `.github/agents/upshift64-builder.agent.md`
  - `.github/agents/upshift64-device-tester.agent.md`
  - `docs/upshift64/workflow-guide.md`
  - `docs/upshift64/README.md`
  - `plan.md`
  - this provenance record
- **Commit:** Not created
- **Pull request:** Not created
- **CI:** Not run; skill self-tests were run locally.

## Backup

Before editing, the existing skill directory, all three agents, plan, README,
and workflow guide were copied into:

`E:\upshift64-step12-pre-generalization-backup-20260915.zip`

- Files: 16
- Bytes: 55,571
- SHA256:
  `87F560E1AFBCAA94DEED8E4FB4D1CE8164282721BDE39DFAE9874AA29BAA1E36`

The archive is a recovery snapshot and is not required by the reusable skill.

## Generalization

The active skill now audits 11 application-neutral categories:

1. source/release topology;
2. build-system and CI restrictions;
3. compiler, SDK, linker, and ABI;
4. processor-specific code and dispatch;
5. acceleration APIs and providers;
6. native frameworks, codecs, modules, and generated assets;
7. Windows integration;
8. language/threading/vendor runtimes;
9. binary dependency closure;
10. packaging, installation, updating, and signing;
11. physical-device behavior and evidence.

Vulkan, DirectML, Windows ML, CUDA, and CPU are examples of acceleration
choices. NCNN and other inference frameworks are examples within the native
framework category. libwebp, OpenMP, Electron, Sharp, and ExifTool are no
longer mandatory audit items.

All Upscayl-specific commits, hashes, commands, CI iterations, provider IDs,
tile settings, compatibility exceptions, and device outcomes moved to
`references/upscayl-case-study.md`. A generic schema-valid configuration
template is now separate from the concrete Upscayl example.

## Validation

The dependency-free self-test passed:

| Fixture | Result |
| --- | --- |
| Generic configuration example | PASS |
| Upscayl case-study configuration | PASS |
| Unreplaced placeholder rejection | PASS |
| Configuration without an accelerator provider | PASS |
| Invalid revision rejection | PASS |
| Private manifest | PASS |
| Public clean manifest | PASS |
| Public privacy blocking | PASS |
| Exact match-hash allowlist | PASS |
| Public image-review gate | PASS |

Both configuration examples matched `project-config.schema.json`, and all
PowerShell scripts parsed without syntax errors.

## Limitations

- The agents retain the `upshift64-*` brand for continuity, but their active
  instructions are application-neutral.
- The case study remains intentionally detailed so future users can see a
  complete worked implementation without confusing it with required defaults.
- No commit, push, CI run, or product-code change is included.
