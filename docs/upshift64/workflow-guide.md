# Upshift64 plan, skill, and agent guide

This is the single review hub for the Upshift64 workflow. It summarizes how the
plan, reusable skill, and custom agents fit together and links to each canonical
file. The linked files remain the source of truth; this guide intentionally
does not duplicate their full contents.

## Start here

| Need | Canonical file |
| --- | --- |
| Project sequence, status, and exit criteria | [`../../plan.md`](../../plan.md) |
| Reusable Windows ARM64 porting method | [`../../.github/skills/upshift64-port/SKILL.md`](../../.github/skills/upshift64-port/SKILL.md) |
| Read-only architecture and blocker audit | [`../../.github/agents/upshift64-auditor.agent.md`](../../.github/agents/upshift64-auditor.agent.md) |
| Native backend and Electron package implementation | [`../../.github/agents/upshift64-builder.agent.md`](../../.github/agents/upshift64-builder.agent.md) |
| Physical-device and installed-app validation | [`../../.github/agents/upshift64-device-tester.agent.md`](../../.github/agents/upshift64-device-tester.agent.md) |
| Evidence and current results | [`README.md`](README.md) |
| Installed-app Snapdragon proof | [`step11-evidence.md`](step11-evidence.md) |
| Agent-action history | [`provenance/`](provenance/) |

## Workflow at a glance

```text
Scope and pin
    |
    v
upshift64-auditor
    |  evidence matrix + smallest remediations
    v
upshift64-builder
    |  ARM64 binaries + package closure + device handoff
    v
upshift64-device-tester
    |  native provider + offline run + installed GUI evidence
    v
Sanitize and manifest evidence
    |
    v
Upstream-ready application and backend changes
```

Every agent reads and follows `upshift64-port`. The skill owns the shared
approval, evidence, architecture, remediation, and provenance rules. Agents
specialize those rules for a phase and stop at their handoff boundary.

## Current plan

| Step | Deliverable | Status | Primary owner |
| --- | --- | --- | --- |
| 1 | Select app and define success tiers | Complete | Project owner + coordinating agent |
| 2 | Pin application repository and branch | Complete | Coordinating agent |
| 3 | Pin backend and recursive dependencies | Complete | Coordinating agent |
| 4 | Capture unchanged x64 functional baseline | Complete | Builder/device tester |
| 5 | Audit Windows ARM64 blockers | Complete | `upshift64-auditor` |
| 6 | Build native ARM64 backend in CI | Complete | `upshift64-builder` |
| 7 | Prove backend dependency closure | Complete | `upshift64-builder` |
| 8 | Prove native offline Vulkan inference | Complete | `upshift64-device-tester` |
| 9 | Publish Tier 1 evidence and workflow | Complete | Coordinating agent |
| 10 | Build and close Electron ARM64 package | Complete | `upshift64-builder` |
| 11 | Validate installed app on Snapdragon X | Complete | `upshift64-device-tester` |
| 12 | Finalize the reusable porting skill | Complete | Coordinating agent |
| 13 | Prepare two upstream-ready draft PRs | Pending | Builder + coordinating agent |
| 14 | Select at most one Tier 3 extension | Pending | Project owner |

The detailed exit criteria and approved boundaries are in
[`plan.md`](../../plan.md).

Step 12's portable package lives entirely under
`.github/skills/upshift64-port`: JSON configuration/evidence schemas, an
application-neutral configuration template, a separate Upscayl example/case
study, handoff/provenance templates, dependency-free PowerShell validation and
manifest tools, and positive/negative fixtures.

## Agent selection

### `upshift64-auditor`

Use first when feasibility, architecture, dependencies, or blockers are still
unknown.

It:

- defaults to read-only investigation;
- distinguishes host tools from target binaries;
- audits build/ABI, processor code, acceleration, native dependencies, Windows
  integration, runtimes, packaging, device behavior, and release naming;
- reconciles scanner/text matches with the actual build graph;
- produces an evidence matrix and the smallest independently approvable
  remediation slices;
- hands implementation to `upshift64-builder`.

It does not build, modify, package, run devices, or claim scanner execution
without the corresponding evidence and approval.

### `upshift64-builder`

Use after the audit has identified and the owner has approved a bounded
implementation slice.

It:

- creates isolated native ARM64 CI jobs;
- separates host tooling from ARM64 target libraries and payloads;
- verifies PE architecture, imports, signatures, and recursive dependency
  closure;
- stages exact backend/runtime artifacts into framework-appropriate packages;
- produces architecture-labelled unpacked, ZIP, and installer outputs;
- preserves failure evidence and makes one failure-driven correction at a
  time;
- hands immutable artifacts and hashes to `upshift64-device-tester`.

It does not silently modify existing platform jobs, publish releases, or begin
physical-device execution.

### `upshift64-device-tester`

Use only after the builder supplies a verified, dependency-closed artifact and
fixed fixture/model hashes.

It:

- inventories the native Windows ARM64 device without retaining identifiers;
- revalidates transferred hashes and binary architecture;
- rejects configured software or translation providers;
- proves native physical-provider execution and offline operation;
- compares an installed tree with the package reference;
- exercises launch, input, cancellation/recovery, inference, and output
  opening;
- sanitizes evidence and creates a final byte-accurate manifest.

It does not change source or packaging. Parameter changes, reruns, installs,
adapter operations, and remediation each retain their own approval boundary.

## Shared reusable-skill contract

### Required inputs

- application and backend repository URLs;
- branch, commit, and recursive submodule revisions;
- target Windows architecture and supported compatibility architecture;
- approved objective and exact change boundary;
- build runner and toolchain constraints;
- fixed fixture, model, and expected file hashes;
- package layout and expected native-file policy;
- target-device class and available validation tools;
- evidence root and privacy requirements.

Do not begin a write phase with missing or floating revisions.

### Required outputs

- audit evidence matrix and host/target classification;
- independently reviewable remediation slices;
- native build logs and machine/import inspection;
- recursive package and installed-tree closure reports;
- immutable artifact names, sizes, hashes, and retention details;
- physical-provider and offline execution evidence;
- sanitized JSON/CSV/Markdown evidence with verified hashes;
- provenance for approvals, generated changes, failures, corrections, and
  limitations;
- explicit unproven claims and the smallest next action.

### Phase state

Use these states for each phase:

| State | Meaning |
| --- | --- |
| `not-started` | Required inputs or approval are absent |
| `approved` | Exact scope and validation were approved |
| `running` | Work is executing inside the approved boundary |
| `blocked` | A hard prerequisite failed; preserve evidence and stop |
| `partial` | Some criteria passed but the phase exit criteria did not |
| `passed` | Every stated exit criterion has direct evidence |
| `published` | Evidence was sanitized, manifested, and made reviewable |

A successful command does not automatically advance the phase. For example,
configure is not build proof, build is not closure, closure is not physical
execution, and execution is not publication.

## Approval and rollback model

Before a consequential action, state:

1. exact paths and commands;
2. intended behavior and expected evidence;
3. risks and alternatives;
4. rollback or cleanup boundary;
5. validation and stop conditions.

Approval applies only to that stated action. New dependencies, changed
parameters, reruns after a failure, CI triggers, device modifications, commits,
pushes, and pull requests are separate gates unless explicitly included.

Rollback must preserve diagnostic evidence. Prefer isolated branches, build
directories, staging roots, evidence roots, and command-scoped configuration.
Never overwrite the only failing log or silently restore files with destructive
Git commands.

## Evidence contract

Every retained artifact should have:

- stable relative path;
- byte length;
- SHA256;
- producer phase and timestamp;
- source artifact/commit relationship;
- architecture or content classification where applicable;
- sanitization status;
- accepted, superseded, or failed-run status.

Generate the final manifest only after sanitization. Recompute every listed
size and hash from the final bytes. If a transferred bundle omits its claimed
manifest, generate an independent received-file manifest and disclose the
omission.

Publication evidence must exclude credentials, user/machine names, serials,
UUIDs, network names, IP/MAC addresses, personal paths, and unrelated desktop
or application content. Raw private evidence and a public redacted bundle are
different artifacts and require different manifests.

## External tool composition

The skill coordinates existing tools instead of copying their implementation:

| Tool | Use | Boundary |
| --- | --- | --- |
| Qualcomm EasyWoS | Optional source-portability methodology/scanner | Pin the source; distinguish methodology, setup, and actual scanner execution |
| WinAppCli | Windows GUI discovery and automation | Require observed UI results; use explicit owner-click boundaries when automation is unreliable |
| `win-dev-skills` | Windows development and packaging practices | Invoke the relevant installed skill rather than reproducing its instructions |
| `winml-cli` | Optional Windows ML discovery or validation | Use only for an approved ML/NPU scope; it is not required for other acceleration APIs |

Unavailable optional tools do not justify fabricated output. Use the documented
fallback, request approval for installation, or mark the affected criterion
unproven.

## Proven Upshift64 case study

The reusable rules above were proven through:

- native ARM64 backend CI and dependency closure;
- signed ARM64 Microsoft OpenMP redistribution;
- physical offline Qualcomm Adreno Vulkan inference;
- architecture-labelled Electron ARM64 ZIP and NSIS outputs;
- recursive packaged and installed native-file closure;
- installed GUI launch, cancellation/recovery, 4x inference, and output
  opening;
- failure-driven evidence preservation and independent Step 11 review.

Case-specific hashes, commits, technologies, device settings, compatibility
exceptions, and failure history remain in
`.github/skills/upshift64-port/references/upscayl-case-study.md` and the
project evidence documents. They are examples, not defaults for another
application.

## Recommended review order

1. Read this guide.
2. Review [`plan.md`](../../plan.md) for scope and current status.
3. Read the top-level contract, safety rules, and relevant phase in
   [`SKILL.md`](../../.github/skills/upshift64-port/SKILL.md).
4. Read only the agent for the next phase.
5. Review the corresponding provenance and evidence report.
6. Confirm the next approval gate before any consequential action.
