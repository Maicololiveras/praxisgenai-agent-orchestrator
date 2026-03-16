# Codex Installation & Usage Guide

## Prerequisites

1. **Codex CLI** installed and working (`codex` command available)
2. **Engram** installed and running (`engram` binary available)
3. Codex configured with a model provider (typically OpenAI)

## One-Command Install

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/praxisgenai/agent-orchestrator/main/scripts/install.sh | bash -s -- --editor codex

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

Codex uses the same skill files as all editors. Copy them to the Codex skills directory:

```bash
# Linux / macOS
mkdir -p ~/.codex/skills
cp -r skills/* ~/.codex/skills/

# Windows (PowerShell)
New-Item -ItemType Directory -Force "$env:APPDATA\codex\skills"
Copy-Item -Recurse -Force skills\* "$env:APPDATA\codex\skills\"
```

### Step 3: Install orchestrator instructions

Copy the orchestrator instructions file:

```bash
# Linux / macOS
cp editors/codex/orchestrator-instructions.md ~/.codex/orchestrator-instructions.md

# Windows (PowerShell)
Copy-Item editors\codex\orchestrator-instructions.md "$env:APPDATA\codex\orchestrator-instructions.md"
```

### Step 4: Update config.toml

Edit your Codex config file (`~/.codex/config.toml` on Linux/macOS, `%APPDATA%/codex/config.toml` on Windows):

```toml
# Point to the orchestrator instructions
model_instructions_file = "~/.codex/orchestrator-instructions.md"

# If you have existing instructions, APPEND the orchestrator content
# to your existing file instead of replacing model_instructions_file.

# Engram MCP server
[mcp_servers.engram]
command = "engram"
args = ["mcp", "--tools=agent"]
```

If you already have a `model_instructions_file`, append the content of `orchestrator-instructions.md` to your existing instructions file rather than replacing it.

### Step 5: (Optional) Add compact prompt for Engram

If you use Engram's compaction feature, copy the compact prompt:

```bash
# Linux / macOS
cp editors/codex/orchestrator-instructions.md ~/.codex/engram-compact-prompt.md

# Windows (PowerShell)
# The compact prompt is a separate concern; configure it per Engram docs.
```

And add to `config.toml`:

```toml
experimental_compact_prompt_file = "~/.codex/engram-compact-prompt.md"
```

## Verify Installation

Start a Codex session and ask:

```
Are the orchestration instructions loaded? Can you access Engram MCP tools? Check if mem_search is available.
```

The assistant should confirm:
- Orchestrator delegation rules are active
- Engram MCP tools (`mem_save`, `mem_search`, `mem_get_observation`) are accessible
- SDD workflow commands are understood

## How It Works in Codex

Codex uses a single-agent architecture with instructions-based orchestration:

1. **Instructions file**: The `orchestrator-instructions.md` gives Codex the delegation rules, SDD workflow definitions, and Engram protocol.
2. **Sub-agent delegation**: Codex uses its native sub-agent/task primitives for bounded delegation.
3. **Skill loading**: Sub-agents check for the skill registry (Engram or `.atl/skill-registry.md`) as their first step, then load relevant skills.
4. **Engram persistence**: All SDD artifacts are persisted to Engram with deterministic topic keys.

## Usage Examples

### Initialize

```
Initialize SDD for this project. Detect the stack and create a skill registry.
```

### Start a change

```
Start a new SDD change called add-auth-middleware. Explore first, then propose.
```

### Fast-forward

```
Fast-forward planning for add-auth-middleware. Run propose, spec, design, and tasks.
```

### Implement

```
Apply the next batch of tasks for add-auth-middleware.
```

### Verify and archive

```
Verify add-auth-middleware against its specs.
Archive the add-auth-middleware change.
```

## SDD Commands Reference

Since Codex doesn't have slash commands, use natural language equivalents:

| Intent | What to say |
|--------|-------------|
| `/sdd-init` | "Initialize SDD for this project" |
| `/sdd-explore <topic>` | "Explore <topic> before we commit to a change" |
| `/sdd-new <name>` | "Start a new SDD change called <name>" |
| `/sdd-continue` | "Continue the active SDD change to the next phase" |
| `/sdd-ff <name>` | "Fast-forward planning for <name>" |
| `/sdd-apply <name>` | "Apply the next batch of tasks for <name>" |
| `/sdd-verify <name>` | "Verify <name> against its specs" |
| `/sdd-archive <name>` | "Archive the <name> change" |

## Limitations vs OpenCode

- **No slash commands**: All interaction is natural language. The orchestrator instructions teach Codex to recognize SDD intent.
- **No separate agent definitions**: Codex runs a single agent with sub-agent delegation, rather than OpenCode's named agent roster.
- **Config is TOML-based**: Codex uses `config.toml` rather than JSON for configuration.
