---
description: Run deep orchestration setup diagnostics
agent: sdd-orchestrator
---

Run a deeper setup diagnostic for this OpenCode environment and the current workspace.

Validate:
- `opencode.json` agent wiring
- required skills under `~/.config/opencode/skills/`
- required commands under `~/.config/opencode/commands/`
- optional `agents/` prompt files
- Engram configuration and likely recovery path

Return concrete fixes for anything missing.
