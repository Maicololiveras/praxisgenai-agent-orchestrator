# Gemini CLI Installation & Usage Guide

## Prerequisites

1. **Gemini CLI** installed and working (`gemini` command available)
2. **Engram** installed and running (`engram` binary available)
3. Gemini CLI configured with a model provider

## One-Command Install

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/praxisgenai/agent-orchestrator/main/scripts/install.sh | bash -s -- --editor gemini

# Windows (PowerShell)
irm https://raw.githubusercontent.com/praxisgenai/agent-orchestrator/main/scripts/install.ps1 | iex
```

## Manual Install

### Step 1: Clone the repository

```bash
git clone https://github.com/praxisgenai/agent-orchestrator.git
cd agent-orchestrator
```

### Step 2: Copy skills

Gemini uses the same skill files as all editors. Copy them to the Gemini skills directory:

```bash
# Linux / macOS
mkdir -p ~/.gemini/antigravity/skills
cp -r skills/* ~/.gemini/antigravity/skills/

# Windows (PowerShell)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gemini\antigravity\skills"
Copy-Item -Recurse -Force skills\* "$env:USERPROFILE\.gemini\antigravity\skills\"
```

### Step 3: Append orchestrator rules to GEMINI.md

The orchestrator rules need to be appended to your global `~/.gemini/GEMINI.md`:

```bash
# Linux / macOS
cat editors/gemini/GEMINI_ORCHESTRATOR.md >> ~/.gemini/GEMINI.md

# Windows (PowerShell)
Get-Content editors\gemini\GEMINI_ORCHESTRATOR.md | Add-Content "$env:USERPROFILE\.gemini\GEMINI.md"
```

If you don't have a `GEMINI.md` yet, copy it directly:

```bash
cp editors/gemini/GEMINI_ORCHESTRATOR.md ~/.gemini/GEMINI.md
```

### Step 4: Add the skills table entry

If your `GEMINI.md` has a skills auto-load table, add the row from `editors/gemini/skills-table-patch.md`:

```markdown
| Multi-agent coordination, phased work, SDD routing | agent-team-orchestrator |
```

### Step 5: Configure Engram

Ensure Engram is configured as an MCP server for Gemini. Check your Gemini settings for MCP server configuration and add:

```json
{
  "mcpServers": {
    "engram": {
      "command": "engram",
      "args": ["mcp", "--tools=agent"]
    }
  }
}
```

## Verify Installation

Start a Gemini session and ask:

```
Check if the agent-team-orchestrator skill is loaded and Engram is available. Run /orch-status equivalent.
```

The orchestrator should:
- Confirm it can detect the skill
- Confirm Engram MCP tools are available
- Report whether the project has a skill registry

## How It Works in Gemini

Gemini CLI does not have native agents or slash commands like OpenCode. Instead, orchestration works through:

1. **Skill auto-loading**: The `GEMINI.md` rules table triggers `agent-team-orchestrator` skill loading when multi-agent coordination patterns are detected.
2. **Inline skill execution**: Gemini loads the skill's SKILL.md and follows its instructions directly in the conversation.
3. **SDD commands as natural language**: Instead of `/sdd-new add-auth`, you say "Start a new SDD change called add-auth" and the loaded orchestrator skill handles the routing.
4. **Engram persistence**: All artifacts are persisted to Engram, surviving across sessions.

## Usage Examples

### Initialize orchestration

```
Initialize SDD for this project.
```

The orchestrator detects your project stack, creates a skill registry, and persists context to Engram.

### Start a change

```
Start a new SDD change called add-dark-mode.
```

Runs exploration then creates a proposal.

### Fast-forward planning

```
Fast-forward planning for add-dark-mode through all planning phases.
```

Chains propose -> spec -> design -> tasks.

### Implement

```
Apply the next batch of tasks for add-dark-mode.
```

### Verify and archive

```
Verify the add-dark-mode change against its specs.
Archive the add-dark-mode change.
```

## Limitations vs OpenCode

- **No native slash commands**: Commands are expressed as natural language, not `/sdd-*` prefixes. The orchestrator skill interprets intent.
- **No dedicated agent definitions**: Gemini runs everything in a single thread with skill-based routing rather than separate agent processes.
- **Sub-agent delegation**: Gemini's Task tool (if available) handles delegation. Without it, the orchestrator runs phases sequentially in the same context.
