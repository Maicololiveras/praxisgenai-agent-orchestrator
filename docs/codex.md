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

**Important:** Codex reads its config from `~/.codex/config.toml` on **all platforms** (including Windows). This is `$HOME/.codex/config.toml`, NOT `%APPDATA%/codex/config.toml`.

The instruction **files** live in a separate location:
- **Windows:** `%APPDATA%/codex/` (e.g. `C:\Users\you\AppData\Roaming\codex\`)
- **Linux/macOS:** `~/.config/codex/`

The `model_instructions_file` key in the config uses a **full path** to point from the config to the instruction files.

Edit `~/.codex/config.toml`:

```toml
# Windows — use full path with escaped backslashes
model_instructions_file = "C:\\Users\\you\\AppData\\Roaming\\codex\\instructions.md"
experimental_compact_prompt_file = "C:\\Users\\you\\AppData\\Roaming\\codex\\engram-compact-prompt.md"

# Linux/macOS — use full path
# model_instructions_file = "/home/you/.config/codex/instructions.md"
# experimental_compact_prompt_file = "/home/you/.config/codex/engram-compact-prompt.md"

# Engram MCP server
[mcp_servers.engram]
command = "engram"
args = ["mcp", "--tools=agent"]
```

If you already have a `model_instructions_file`, append the content of `instructions.md` to your existing instructions file rather than replacing it.

## Verify Installation

Start a Codex session and ask:

```
Are the orchestration instructions loaded? Can you access Engram MCP tools? Check if mem_search is available.
```

The assistant should confirm:
- Orchestrator delegation rules are active
- Engram MCP tools (`mem_save`, `mem_search`, `mem_get_observation`) are accessible
- SDD workflow commands are understood

## Simulated Sub-Agents

Codex doesn't have native sub-agents, but the orchestrator simulates them using `codex exec`:

1. Main Codex (interactive) runs as the orchestrator
2. It spawns up to 4 `codex exec` processes in parallel
3. Each process writes structured JSON to a temp file (`praxisgenai-sub{N}.json`)
4. Main Codex reads all outputs, validates against the schema, and synthesizes

This gives Codex effective multi-agent capability with:
- Context isolation (each sub-agent has fresh context)
- Parallel execution (up to 4 concurrent)
- Clean output capture (via `-o` flag)
- No session pollution (`--ephemeral`)
- **Structured JSON output** (via `--output-schema`)

## Worker Output Contract

Sub-agents return structured JSON instead of freeform markdown. This enables programmatic validation and reliable orchestration.

### Schema

The contract is defined in `schemas/worker-output.schema.json` and enforced via `codex exec --output-schema`:

```bash
SCHEMA="$HOME/.codex/schemas/worker-output.schema.json"
codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -o /tmp/result.json "prompt..."
```

### Required Fields

Every worker output includes: `contract_version`, `worker_id`, `task_id`, `status`, `executive_summary`, `ownership` (area, touched_paths, untouched_paths), `artifacts`, `findings`, `decisions`, `changes`, `verification` (performed, not_performed), `risks`, `next_recommended`.

### Status Values

| Status | Meaning |
|--------|---------|
| `success` | Task completed. `verification.performed` MUST be non-empty. |
| `partial` | Partially done. Some work completed. |
| `blocked` | Cannot proceed. Reason in `risks`. |

### Validation Rules

The orchestrator rejects output that has:
- Invalid JSON (parse error)
- Missing required fields
- Status not in `["success", "partial", "blocked"]`
- Paths in `touched_paths` outside declared `ownership.area`
- Status `"success"` with empty `verification.performed`

See `schemas/worker-output.example.json` for a concrete example.

### Platform Notes

**Windows (PowerShell):** Use `Start-Job` + `Wait-Job` with `codex.cmd`
**Linux/Mac (bash):** Use `&` + `wait` with `codex`
**Important:** `codex.ps1` may be blocked by execution policy. Always use `codex.cmd` on Windows.

The bash `&` background operator does NOT work in PowerShell 5.1. On Windows, use `Start-Job` for parallelism. On Linux/Mac, use the traditional `&` + `wait` pattern.

```powershell
# Windows (PowerShell)
$schema = "$HOME\.codex\schemas\worker-output.schema.json"

$jobs = @()
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub1.json" 'prompt' }
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub2.json" 'prompt' }
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub3.json" 'prompt' }
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub4.json" 'prompt' }
$jobs | Wait-Job
Get-Content "$env:TEMP\praxisgenai-sub*.json" | ConvertFrom-Json
Remove-Item "$env:TEMP\praxisgenai-sub*.json" -ErrorAction SilentlyContinue
```

```bash
# Linux/Mac (bash)
SCHEMA="$HOME/.codex/schemas/worker-output.schema.json"

codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -o /tmp/praxisgenai-sub1.json "prompt" &
codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -o /tmp/praxisgenai-sub2.json "prompt" &
codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -o /tmp/praxisgenai-sub3.json "prompt" &
codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -o /tmp/praxisgenai-sub4.json "prompt" &
wait
# Validate each result
for f in /tmp/praxisgenai-sub*.json; do jq -e '.status' "$f" > /dev/null || echo "INVALID: $f"; done
rm /tmp/praxisgenai-sub*.json
```

## How It Works in Codex

Codex uses a single-agent architecture with simulated sub-agent orchestration:

1. **Instructions file**: The `orchestrator-instructions.md` gives Codex the delegation rules, SDD workflow definitions, and Engram protocol.
2. **Sub-agent delegation**: Codex simulates sub-agents by spawning `codex exec` processes in background with `--full-auto --ephemeral` flags.
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
- **No separate agent definitions**: Codex runs a single agent with simulated sub-agents via `codex exec`, rather than OpenCode's named agent roster.
- **Simulated sub-agents**: Sub-agents are `codex exec` background processes (max 4 parallel), not native isolated contexts like OpenCode's `subtask` flag.
- **Config is TOML-based**: Codex uses `config.toml` rather than JSON for configuration.
