# Step 012: Finalize the reusable Windows ARM64 porting skill

- **Timestamp (UTC):** `2026-09-15T20:43:26Z`
- **Objective:** Complete Step 12 as a self-contained, production-quality
  reusable skill that another repository can adopt without session history.
- **Owner approval:** `"oh continue step 12"`
- **Agent:** GitHub Copilot CLI
- **Skill:** `upshift64-port`
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Task prompt:** The owner approval quoted above, continuing the Step 12
  scope defined in `plan.md`.
- **Affected files:**
  - `.github/skills/upshift64-port/SKILL.md`
  - `.github/skills/upshift64-port/references/project-config.schema.json`
  - `.github/skills/upshift64-port/references/project-config.example.json`
  - `.github/skills/upshift64-port/references/evidence-record.schema.json`
  - `.github/skills/upshift64-port/references/handoff-template.md`
  - `.github/skills/upshift64-port/references/provenance-template.md`
  - `.github/skills/upshift64-port/scripts/Test-Upshift64ProjectConfig.ps1`
  - `.github/skills/upshift64-port/scripts/New-Upshift64EvidenceManifest.ps1`
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
- **CI:** Not run; the package has local dependency-free self-tests.

## Generated package

The skill now provides:

1. a JSON Schema project contract and validated Upscayl example;
2. explicit reusable phase states and agent handoffs;
3. a JSON Schema evidence contract;
4. a recursive JSON/CSV evidence-manifest generator;
5. text privacy gates using match hashes rather than leaked values;
6. mandatory manual image review for public image bundles;
7. portable handoff and provenance templates;
8. explicit composition boundaries for EasyWoS, WinAppCli,
   `win-dev-skills`, and `winml-cli`;
9. agent wiring that consumes configuration and handoffs without inheriting
   approval or case-study defaults;
10. dependency-free positive and negative fixtures.

## Validation and outputs

`run-tests.ps1` passed:

| Fixture | Result |
| --- | --- |
| Valid example project configuration | PASS |
| Invalid revision rejected | PASS |
| Private evidence manifest | PASS |
| Public clean evidence manifest | PASS |
| Public credential-shaped evidence rejected | PASS |
| Exact match-hash privacy allowlist | PASS |
| Public image bundle blocked until manual review | PASS |

Additional validation passed:

- all three PowerShell scripts parsed without syntax errors;
- the example configuration matched `project-config.schema.json`;
- a generated manifest matched `evidence-record.schema.json`;
- `git diff --check` reported no whitespace errors.

## Known limitations

- Automated privacy scanning cannot determine whether screenshots expose
  unrelated applications or personal details; public image bundles therefore
  require explicit manual review.
- Privacy patterns intentionally favor blocking and may require a narrowly
  reasoned match-hash allowlist for benign version-like values.
- The manifest tool records evidence bytes and privacy state; the separate
  Tier 3 package-closure/device-validation skill remains pending and will add
  configurable PE/package/installed-tree policy orchestration rather than
  duplicating this generic evidence layer.
- No commit or push is included in this approval.
