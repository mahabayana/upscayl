# Step 012: Create the unified plan, skill, and agent guide

- **Timestamp (UTC):** `2026-09-15T20:34:30Z`
- **Objective:** Provide one maintainable review entry point for the complete
  Upshift64 plan, reusable skill, and custom-agent workflow.
- **Owner approval:** `"could u gather all the plan, skills and agents in one place easy to go through"`
- **Agent:** GitHub Copilot CLI
- **Skill:** `upshift64-port`
- **Model:** GPT-5.6 Sol (`gpt-5.6-sol`)
- **Task prompt:** The owner approval quoted above.
- **Affected files:** `docs/upshift64/workflow-guide.md`,
  `docs/upshift64/README.md`, and this provenance record.
- **Commands:** Read-only heading and reference searches plus Git whitespace
  and local-link validation.
- **Commit:** Not created
- **Pull request:** Not created
- **CI:** Not run; documentation-only change.

## Generated decision

Create a concise navigation and workflow guide rather than copying the full
plan, skill, and agent files into a second monolithic document. The guide:

- links every canonical source;
- shows all 14 plan steps and current status;
- explains agent selection and handoffs;
- summarizes the reusable skill's input, output, state, approval, rollback,
  evidence, and privacy contracts;
- records how EasyWoS, WinAppCli, `win-dev-skills`, and `winml-cli` compose
  with the skill;
- provides a recommended review order.

This structure keeps one easy review entry point while avoiding duplicated
instructions that could drift from their canonical definitions.

## Validation

- Confirm each relative Markdown link resolves from
  `docs/upshift64/workflow-guide.md`.
- Run `git diff --check`.
- Confirm the README links to the new guide.

## Limitations

- This guide is an index and operational summary, not a replacement for the
  complete canonical files.
- Step 12 remains in progress until the reusable skill's portable
  configuration, evidence schemas, and handoff templates are finalized.
