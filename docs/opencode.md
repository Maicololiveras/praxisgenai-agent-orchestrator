# OpenCode Installation & Usage Guide

## Prerequisites

1. **OpenCode** installed and working (`opencode` command available)
2. **Engram** installed and running (`engram` binary available, `engram mcp` works)
3. **A model provider configured** in OpenCode (Anthropic, OpenAI, etc.)

## One-Command Install

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/praxisgenai/agent-orchestrator/main/scripts/install.sh | bash -s -- --editor opencode

# Windows (PowerShell)
irm https://raw.githubusercontent.com/praxisgenai/agent-orchestrator/main/scripts/install.ps1 | iex
```

## Manual Install

### Step 1: Clone the repository

```bash
git clone https://github.com/praxisgenai/agent-orchestrator.git
cd agent-orchestrator
```

### Step 2: Copy skills to OpenCode skills directory

```bash
# Linux / macOS
cp -r skills/* ~/.config/opencode/skills/

# Windows (PowerShell)
Copy-Item -Recurse -Force skills\* "$env:USERPROFILE\.config\opencode\skills\"
```

### Step 3: Copy agent prompt files

```bash
# Linux / macOS
cp editors/opencode/agents/*.md ~/.config/opencode/agents/

# Windows (PowerShell)
Copy-Item -Force editors\opencode\agents\*.md "$env:USERPROFILE\.config\opencode\agents\"
```

### Step 4: Copy slash commands

```bash
# Linux / macOS
cp editors/opencode/commands/*.md ~/.config/opencode/commands/

# Windows (PowerShell)
Copy-Item -Force editors\opencode\commands\*.md "$env:USERPROFILE\.config\opencode\commands\"
```

### Step 5: Merge agent definitions into opencode.json

The file `editors/opencode/opencode.agents.json` contains the agent definitions. You need to merge the `"agent"` block into your existing `opencode.json`:

```bash
# If you don't have an opencode.json yet, copy it directly:
cp editors/opencode/opencode.agents.json ~/.config/opencode/opencode.json

# If you already have one, manually merge the "agent" key from opencode.agents.json
# into your existing opencode.json.
```

### Step 6: Configure Engram MCP server

In your `opencode.json`, ensure you have the Engram MCP server configured:

```json
{
  "mcpServers": {
    "engram": {
      "type": "stdio",
      "command": "engram",
      "args": ["mcp", "--tools=agent"]
    }
  }
}
```

## Verify Installation

Run OpenCode and execute:

```
/orch-doctor
```

This command checks:
- Agent wiring in `opencode.json`
- Skills installed under `~/.config/opencode/skills/`
- Commands installed under `~/.config/opencode/commands/`
- Agent prompt files under `~/.config/opencode/agents/`
- Engram availability and configuration

All items should report as present. If anything is missing, the doctor command provides concrete fix instructions.

## Available Commands

### Orchestration Commands

| Command | Description |
|---------|-------------|
| `/orch-help` | Show available commands and when to use each mode |
| `/orch-status` | Check orchestrator readiness for current workspace |
| `/orch-doctor` | Run deep diagnostics on setup and wiring |
| `/orch-init` | Initialize skill registry + SDD context for workspace |

### SDD (Spec-Driven Development) Commands

| Command | Description |
|---------|-------------|
| `/sdd-init` | Initialize SDD context (detects stack, creates registry) |
| `/sdd-explore <topic>` | Investigate a topic before committing to a change |
| `/sdd-new <change-name>` | Start a new change: explore + propose |
| `/sdd-continue [change]` | Run the next dependency-ready phase |
| `/sdd-ff [change]` | Fast-forward: propose -> spec -> design -> tasks |
| `/sdd-apply [change]` | Implement the next batch of planned tasks |
| `/sdd-verify [change]` | Verify implementation against specs |
| `/sdd-archive [change]` | Archive completed change and sync specs |
| `/skill-registry` | Build or refresh the project skill registry |

## Usage Examples

### Quick start for a new project

```
/orch-init
```

This scans your project, detects the tech stack, creates a skill registry at `.atl/skill-registry.md`, and initializes the SDD context in Engram.

### Starting a substantial change

```
/sdd-new add-dark-mode
```

This runs exploration (reads your codebase, analyzes approaches) then creates a proposal with intent, scope, risks, and rollback plan.

### Fast-forwarding through planning

```
/sdd-ff add-dark-mode
```

This chains propose -> spec -> design -> tasks in sequence, producing all planning artifacts before implementation.

### Implementing in batches

```
/sdd-apply add-dark-mode
```

The orchestrator picks the next batch of dependency-ready tasks and delegates implementation to the `sdd-apply` agent.

### Verifying and closing

```
/sdd-verify add-dark-mode
/sdd-archive add-dark-mode
```

Verify runs tests, checks spec compliance, and produces a verification report. Archive syncs delta specs into the main spec source of truth and closes the change.

## Scaling Rules

- **Small task** (single file, quick fix): Just ask. The orchestrator delegates to a single bounded sub-agent.
- **Medium task** (multi-file, clear scope): `/sdd-explore` -> implement -> verify.
- **Large task** (multi-module, architecture change): Full SDD pipeline with `/sdd-new` -> `/sdd-ff` -> `/sdd-apply` -> `/sdd-verify` -> `/sdd-archive`.
