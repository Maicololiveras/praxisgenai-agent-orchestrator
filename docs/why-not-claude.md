# Why Claude Code Does Not Need This Package

## Short Answer

Claude Code already has native multi-agent orchestration built in. This package would be redundant.

## What Claude Code Has Natively

### Built-in Agent Tool

Claude Code provides a first-class `Agent` tool (also called "sub-agents" or "Task" in the SDK). This is not a plugin or an extension -- it is a core primitive of the runtime.

- Sub-agents get fresh context windows automatically.
- The orchestrator can launch sub-agents with specific prompts and tool access.
- Results flow back as structured responses.

### Sub-Agent Types

Claude Code supports multiple sub-agent delegation patterns:

- **Bounded tasks**: "Read these files and tell me what you find."
- **Full implementation**: "Implement this feature following these specs."
- **Verification**: "Run tests and report results."

These map directly to the SDD phases (explore, apply, verify) without any additional infrastructure.

### Native Skill Loading

Claude Code's `CLAUDE.md` file (both global `~/.claude/CLAUDE.md` and project-level) already supports:

- Auto-loading skills based on context detection
- Skills table with trigger patterns
- Framework/library detection rules

This is exactly what the `agent-team-orchestrator` skill provides for other editors.

### Engram Integration

Claude Code can use Engram via the same MCP server protocol. The persistent memory layer works identically. No adapter needed.

## What This Package Solves for Other Editors

| Problem | Claude Code Solution | OpenCode / Gemini / Codex Solution |
|---------|---------------------|-----------------------------------|
| Sub-agent delegation | Native Agent tool | Agent definitions (OpenCode), Task tool (Gemini), Sub-agents (Codex) |
| Skill-based behavior | CLAUDE.md skills table | Skills directory + SKILL.md files |
| Slash commands | Built-in (via CLAUDE.md) | Commands directory (OpenCode), natural language (Gemini/Codex) |
| Orchestrator rules | CLAUDE.md orchestrator section | Editor-specific config files |
| SDD pipeline | CLAUDE.md SDD section + skills | Skills + commands + agent definitions |

## The Pattern

Claude Code was the original environment where this orchestration pattern was developed. The `CLAUDE.md` in this repository's parent project contains the full orchestrator, SDD workflow, and Engram protocol inline.

This package extracts that pattern into portable skills that work in editors without Claude Code's native capabilities.

If you are using Claude Code, your existing `CLAUDE.md` with the Agent Teams Orchestrator section is sufficient. You do not need to install this package.

## When You Might Still Want It

The only scenario where Claude Code users might want parts of this package:

- **Skill files**: If you want the standalone SKILL.md files for reference or to share with team members using other editors.
- **Documentation**: The architecture docs explain the coordination model in detail.
- **Cross-editor teams**: If your team uses a mix of editors and you want everyone following the same SDD pipeline.
