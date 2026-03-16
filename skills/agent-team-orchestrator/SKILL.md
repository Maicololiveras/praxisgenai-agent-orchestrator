---
name: agent-team-orchestrator
description: >
  Coordinate multi-agent work in OpenCode using skills, Engram memory, and
  host-native delegation primitives instead of file-based mailboxes or lock files.
  Trigger: When work spans multiple areas, requires delegation, or the assistant
  must act as a director rather than a solo executor.
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Requests that touch multiple files, modules, or architectural areas
- Work that benefits from exploration before implementation
- Multi-step execution that risks context bloat
- Any SDD workflow

Do NOT force heavy orchestration for trivial factual answers.

## Hard Rules

- Do NOT use `tasks.json`, mailbox folders, `.lock` files, or claim files as the primary coordination layer
- Use host-native primitives: subagents, matching skills, slash commands, Engram, and `TodoWrite` when useful
- Assign ownership by area, path, capability, or phase
- Do NOT parallelize overlapping paths
- Save meaningful discoveries, bug fixes, decisions, and conventions with `mem_save`

## Coordination Stack

- `Task` when you need bounded delegated work
- `TodoWrite` when tracking adds clarity
- `engram` for persistent state and recovery
- SDD skills for substantial changes
- `explore` for investigation and `general` for implementation when those subagents are available

## Scaling Rules

- Small task: one bounded delegation or one matching skill
- Medium task: explore -> implement -> verify
- Large task: `sdd-explore -> sdd-propose -> sdd-spec/design -> sdd-tasks -> sdd-apply -> sdd-verify -> sdd-archive`

## Ownership Model

Good boundaries:

- `src/auth/**`
- `docs/api/**`
- `verify regression coverage`
- `design state persistence`

Bad boundaries:

- "whatever is free"
- "take backend maybe"
- lock-file claims

## Memory Rules

Save important outcomes with `mem_save` using:

- `title`
- `type`
- `project`
- `content` with `What`, `Why`, `Where`, and `Learned`

For evolving topics, reuse `topic_key`.

## Sub-Agent Output Contract

Every delegated worker MUST return valid JSON conforming to `schemas/worker-output.schema.json`.

**Schema reference:** `schemas/worker-output.schema.json` (repo) or `~/.codex/schemas/worker-output.schema.json` (installed).

**Enforcement by editor:**
- **Codex**: Uses `codex exec --output-schema <path>` to enforce the schema at runtime.
- **OpenCode** and **Gemini**: Follow the same contract via prompt instruction (no native schema enforcement).

### Status Values

| Status | Meaning |
|--------|---------|
| `success` | Task completed fully. `verification.performed` MUST be non-empty. |
| `partial` | Task partially done. Some work completed, but not everything. |
| `blocked` | Cannot proceed. Explain why in `risks`. |

### Example Output

```json
{
  "contract_version": "1.0",
  "worker_id": "sub1",
  "task_id": "explore-auth",
  "status": "success",
  "executive_summary": "Traced the full authentication flow...",
  "ownership": {
    "area": "src/auth/**",
    "touched_paths": ["src/auth/login.ts", "src/auth/session.ts"],
    "untouched_paths": ["src/payments/**"]
  },
  "artifacts": { "created": [], "updated": [], "references": ["docs/auth-flow.md"] },
  "findings": ["Sessions persist in localStorage — vulnerable to XSS"],
  "decisions": ["Focus on token lifecycle before session storage"],
  "changes": [],
  "verification": {
    "performed": ["Code reading", "Flow tracing"],
    "not_performed": ["Unit tests", "E2E flow"]
  },
  "risks": ["The interceptor is a global singleton — changes affect ALL API calls"],
  "next_recommended": ["Implement refresh token rotation"],
  "memory_saved": []
}
```

See `schemas/worker-output.example.json` for a complete example.

### Orchestrator Validation Rules

After reading sub-agent output, the orchestrator MUST reject:
- **Invalid JSON** (parse error)
- **Missing required fields** (any field from the schema's `required` list)
- **Invented status** (status not in `["success", "partial", "blocked"]`)
- **Paths outside ownership** (paths in `touched_paths` outside declared `ownership.area`)
- **Success without evidence** (status `"success"` with empty `verification.performed` — no evidence = no trust)

If rejected, log the error and optionally retry the sub-agent.

## Delegation Model per Editor

The orchestrator adapts its behavior based on the runtime's actual capabilities:

### Claude Code (native — no orchestrator needed)
- Uses built-in `Agent` tool with typed sub-agents (Explore, Plan, general)
- Full context isolation per sub-agent
- This skill is NOT needed in Claude Code

### OpenCode (full sub-agent support)
- Uses `subtask: true` in command definitions to spawn isolated agent contexts
- Each SDD phase runs as a dedicated agent with its own system prompt
- The orchestrator delegates via slash commands: `/sdd-explore`, `/sdd-apply`, etc.
- Results flow back through the conversation

### Gemini CLI (sub-agent via tools)
- Uses `SubagentTool` — sub-agents are exposed as callable tools
- Skills can be loaded dynamically with `activate_skill`
- Use `enter_plan_mode` for structured planning before implementation
- The orchestrator invokes skills directly, each running in isolated context

### Codex (Simulated Sub-Agents via `codex exec`)
- Codex has NO native sub-agents, but can SIMULATE them using `codex exec` in background
- The main Codex spawns up to **4 parallel** `codex exec` processes
- Each sub-process writes its result to a temp file via `-o` flag
- Main Codex reads all output files and synthesizes

**How to delegate in Codex:**

**Windows (PowerShell):** Use `Start-Job` + `Wait-Job` with `codex.cmd`
**Linux/Mac (bash):** Use `&` + `wait` with `codex`
**Important:** `codex.ps1` may be blocked by execution policy. Always use `codex.cmd` on Windows.

```powershell
# Windows (PowerShell) — Launch up to 4 sub-agents in parallel
$schema = Join-Path $PSScriptRoot 'schemas' 'worker-output.schema.json'
# Or use the installed path:
# $schema = "$HOME\.codex\schemas\worker-output.schema.json"

$jobs = @()
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub1.json" 'PROMPT FOR TASK 1' }
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub2.json" 'PROMPT FOR TASK 2' }
$jobs | Wait-Job
$result1 = Get-Content "$env:TEMP\praxisgenai-sub1.json" | ConvertFrom-Json
$result2 = Get-Content "$env:TEMP\praxisgenai-sub2.json" | ConvertFrom-Json
if ($result1.status -notin @('success','partial','blocked')) { Write-Error "Invalid status from sub1" }
if ($result2.status -notin @('success','partial','blocked')) { Write-Error "Invalid status from sub2" }
Remove-Item "$env:TEMP\praxisgenai-sub*.json" -ErrorAction SilentlyContinue
```

```bash
# Linux/Mac (bash) — Launch up to 4 sub-agents in parallel
SCHEMA="$HOME/.codex/schemas/worker-output.schema.json"

codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -C "$(pwd)" -o /tmp/praxisgenai-sub1.json "PROMPT FOR TASK 1" &
codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -C "$(pwd)" -o /tmp/praxisgenai-sub2.json "PROMPT FOR TASK 2" &
wait
# Validate with jq
echo "$(cat /tmp/praxisgenai-sub1.json)" | jq -e '.status' > /dev/null || echo "INVALID sub1"
echo "$(cat /tmp/praxisgenai-sub2.json)" | jq -e '.status' > /dev/null || echo "INVALID sub2"
rm /tmp/praxisgenai-sub*.json
```

**Rules:**
- Maximum 4 parallel sub-agents (to avoid saturating the machine)
- Always use `--ephemeral` (no session persistence for sub-agents)
- Always use `--full-auto` (no approval prompts)
- Always use `-o <file>` (capture output to file)
- **Windows**: Use `codex.cmd` (not `codex.ps1`), `$env:TEMP` for temp dir, `Start-Job`/`Wait-Job` for parallelism
- **Linux/Mac**: Use `-C "$(pwd)"` (same working directory), `/tmp/` for temp dir, `&`/`wait` for parallelism
- Use `praxisgenai-sub{N}.json` naming convention (JSON output, not markdown)
- Clean up temp files after reading
- If a sub-agent fails, read its output for error info

**For sequential phases (when parallelism doesn't help):**
- Still use `codex exec` but run one at a time
- Save results to Engram between phases for cross-session continuity

### Detection Rule
If you are running in an editor without native sub-agents:
- In Codex: use `codex exec` to simulate sub-agents (see Codex section above)
- In other editors without sub-agents: execute phases inline sequentially
- ALWAYS save results to Engram after each phase
- ALWAYS load prior artifacts from Engram before each phase

## Commands

```bash
/orch-help
/orch-status
/orch-doctor
/orch-init
/skill-registry
/sdd-init
/sdd-new change-name
/sdd-apply change-name
```
