# Upshift64 provenance

This directory records how agent-generated Upshift64 artifacts and major
decisions were authorized, produced, and validated. Create one record for every
approval-gated action; do not combine separate approvals into a single record.
Provenance contains task prompts and owner approvals only. Never include hidden
system or developer prompts.

## Required metadata

Every record must include:

- UTC timestamp for the approved action;
- port step and objective;
- owner approval quotation or durable reference;
- agent, skill, and model;
- complete task prompt or a durable reference that preserves it;
- affected files and exact commands;
- generated diff, artifact, or decision;
- validation performed and captured outputs;
- commit, pull request, and CI links when present;
- known limitations, assumptions, and unresolved failures.

Clearly label facts that were supplied by the owner or imported from historical
evidence rather than observed by the recording agent. Never reconstruct missing
commands, output, approval language, or timestamps.

## Naming convention

Store future records beside this file as:

```text
YYYYMMDDTHHMMSSZ-step-NNN-short-action.md
```

Use the action's UTC timestamp, a zero-padded step number, and a short lowercase
ASCII kebab-case description. If one approval authorizes several inseparable
commands, keep them in one record. Otherwise, create separate records.

## Copyable record template

```markdown
# Step NNN: <short action>

- **Timestamp (UTC):** <YYYY-MM-DDTHH:MM:SSZ>
- **Objective:** <approved outcome>
- **Owner approval:** "<quotation>" or <durable reference>
- **Agent:** <agent name/version>
- **Skill:** <skill name/version or revision>
- **Model:** <model name and identifier>
- **Task prompt:** <complete prompt or durable reference>
- **Affected files:** <paths, or "none">
- **Commands:** <exact commands, or "none">
- **Commit:** <URL/SHA, or "not created">
- **Pull request:** <URL, or "not created">
- **CI:** <URL, or "not run">

## Generated diff or decision

<diff/artifact reference or complete decision>

## Validation and outputs

<exact checks and relevant output; distinguish observed from supplied facts>

## Known limitations

<limitations, assumptions, unresolved failures, and missing evidence>
```

## Step 3 record: pin the backend checkout

- **Record created (UTC):** `2026-09-14T18:45:47.025Z`
- **Action timestamp (UTC):** Not supplied in the available task context.
- **Objective:** Establish a reproducible backend checkout on the
  `hackathon/upshift64-win-arm64` branch at the approved backend revision and
  initialize its recursive submodules at the recorded revisions.
- **Owner approval:** Approval was based on the user's instruction to start
  implementing after the exact Step 3 checkout actions were presented. The user
  then explicitly approved this correction after the exact correction list was
  presented. No verbatim approval quotation or action timestamp was supplied.
- **Agent:** GitHub Copilot CLI
- **Skill:** `upshift64-port` initial scaffold
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Task prompt:** Durable reference: the user task that authorized the initial
  reusable skill/provenance foundation and supplied the recorded revisions.
  Hidden system and developer prompts are intentionally excluded.
- **Affected files:** Backend checkout at `C:\upscayl-ncnn`; no backend source
  file modification is asserted by this record.
- **Commit:** Not created.
- **Pull request:** Not created.
- **CI:** Not run.

### Commands

The exact commands executed were:

```powershell
git clone --recurse-submodules https://github.com/upscayl/upscayl-ncnn.git C:\upscayl-ncnn
git -C C:\upscayl-ncnn -c url."https://github.com/".insteadOf=git@github.com: submodule update --init --recursive
git -C C:\upscayl-ncnn switch -c hackathon/upshift64-win-arm64
```

The recursive clone partially succeeded: it cloned the top-level repository,
then failed during recursive submodule initialization because the submodules
used SSH GitHub URLs and SSH authentication was unavailable. The command-scoped
HTTPS rewrite retried `submodule update --init --recursive` successfully
without changing global Git configuration or `.gitmodules`. The final command
then created the local `hackathon/upshift64-win-arm64` branch.

### Generated decision

Pin the port to these revisions observed in terminal output by the parent agent
and supplied to this documenting agent:

| Component | Branch | Revision |
| --- | --- | --- |
| Application (`upscayl/upscayl`) | `hackathon/upshift64-win-arm64` | `a00d55fee90e0f9435d5eaa86e76700df8199af8` |
| Backend (`upscayl/upscayl-ncnn`) | `hackathon/upshift64-win-arm64` | `0beb39028a0ddd83250e845b4c3333c0675e3b97` |
| libwebp | backend-recorded | `8ea81561d2fdd382da60f57958741a7c23a18eb6` |
| ncnn | backend-recorded | `6125c9f47cd14b589de0521350668cf9d3d37e3c` |
| glslang | backend-recorded | `4afd69177258d0636f78d2c4efb823ab6382a187` |
| pybind11 | backend-recorded | `70a58c577eaf067748c2ec31bfd0b0a614cffba6` |

### Validation and outputs

The parent agent observed the following terminal results and supplied them to
this documenting agent:

- backend `HEAD`: `0beb39028a0ddd83250e845b4c3333c0675e3b97`;
- libwebp: `8ea81561d2fdd382da60f57958741a7c23a18eb6`;
- ncnn: `6125c9f47cd14b589de0521350668cf9d3d37e3c`;
- glslang: `4afd69177258d0636f78d2c4efb823ab6382a187`;
- pybind11: `70a58c577eaf067748c2ec31bfd0b0a614cffba6`;
- backend working-tree status: clean.

This documentation correction did not access or rerun commands in
`C:\upscayl-ncnn`. It records the parent agent's observed terminal output
rather than claiming direct observation by this documenting agent.

### Known limitations

- The exact Step 3 action timestamp, verbatim approval quotation, complete
  original Step 3 task prompt, and full terminal transcript are not present in
  the available task context.
- No build, CI, packaging, inference, or Windows Arm64 device validation is
  claimed.
- The record captures the parent agent's observed results without inventing
  missing historical evidence.
