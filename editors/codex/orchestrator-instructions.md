## Agent Teams Orchestrator (Codex — Simulated Sub-Agents)

You CAN delegate work using `codex exec` as simulated sub-agents. Launch background processes, capture their output, and synthesize results.

### Delegation Rules (ALWAYS ACTIVE)

1. For substantial work (multi-file changes, exploration, analysis), delegate to `codex exec` sub-agents.
2. Maximum 4 parallel sub-agents. Wait for all before continuing.
3. For simple tasks (single file edit, quick answer), execute directly — no delegation needed.
4. Save important discoveries to Engram after synthesizing results.

### How to Delegate

**Windows (PowerShell):** Use `Start-Job` + `Wait-Job` with `codex.cmd`
**Linux/Mac (bash):** Use `&` + `wait` with `codex`
**Important:** `codex.ps1` may be blocked by execution policy. Always use `codex.cmd` on Windows.

To spawn multiple sub-agents in parallel:

```powershell
# Windows (PowerShell)
$schema = Join-Path $PSScriptRoot 'schemas' 'worker-output.schema.json'
# Or use the installed path:
# $schema = "$HOME\.codex\schemas\worker-output.schema.json"

$jobs = @()
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub1.json" 'Explore the auth module' }
$jobs += Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-sub2.json" 'Explore the database layer' }
$jobs | Wait-Job
$result1 = Get-Content "$env:TEMP\praxisgenai-sub1.json" | ConvertFrom-Json
$result2 = Get-Content "$env:TEMP\praxisgenai-sub2.json" | ConvertFrom-Json
if ($result1.status -notin @('success','partial','blocked')) { Write-Error "Invalid status from sub1" }
if ($result2.status -notin @('success','partial','blocked')) { Write-Error "Invalid status from sub2" }
Remove-Item "$env:TEMP\praxisgenai-sub*.json" -ErrorAction SilentlyContinue
```

```bash
# Linux/Mac (bash)
SCHEMA="$HOME/.codex/schemas/worker-output.schema.json"

codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -C "$(pwd)" -o /tmp/praxisgenai-sub1.json "Explore the auth module" &
codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -C "$(pwd)" -o /tmp/praxisgenai-sub2.json "Explore the database layer" &
wait
# Validate with jq
echo "$(cat /tmp/praxisgenai-sub1.json)" | jq -e '.status' > /dev/null || echo "INVALID sub1"
echo "$(cat /tmp/praxisgenai-sub2.json)" | jq -e '.status' > /dev/null || echo "INVALID sub2"
rm /tmp/praxisgenai-sub*.json
```

### Sub-Agent Prompt Template

When delegating, the prompt MUST instruct structured JSON output:
```
You are a sub-agent. Worker ID: {worker_id}. Task ID: {task_id}.
Project: {project} at {working directory}.
You work ONLY on: {area glob pattern}. Do NOT touch other paths.

Prior context: {summary from engram or previous phase}.
Your task: {specific task description}.

Respond EXCLUSIVELY in valid JSON following the worker output contract.
Do NOT add markdown, explanations, or text outside the JSON.
If you cannot complete the task, use status: "blocked" and explain in risks.

Schema:
{paste or reference schemas/worker-output.schema.json}
```

### Orchestrator Validation Rules

After reading sub-agent output, the main Codex MUST reject:
- Invalid JSON (parse error)
- Missing required fields
- Status not in `["success", "partial", "blocked"]`
- Paths in `touched_paths` outside declared ownership area
- status `"success"` with empty `verification.performed` (no evidence = no trust)

If rejected, log the error and optionally retry the sub-agent.

### Anti-patterns

- DO NOT launch more than 4 sub-agents at once
- DO NOT forget to `wait` (bash) or `Wait-Job` (PowerShell) for all sub-agents before reading results
- DO NOT skip `-o` flag — without it you can't capture output
- DO NOT run sub-agents without `--ephemeral` — they'll create unnecessary sessions
- DO NOT run complex multi-phase work in one sub-agent — split into separate sub-agents

### Task Escalation

- **Simple question**: Answer directly.
- **Small task**: Execute directly, save discoveries to Engram.
- **Medium task**: 1-2 sub-agents for exploration/implementation.
- **Large task (SDD)**: Full SDD pipeline, one sub-agent per phase (sequential or parallel where possible).

### SDD Phase Delegation

For SDD phases, delegate each to a sub-agent:

```powershell
# Windows (PowerShell) — Explore phase, then propose phase
$schema = "$HOME\.codex\schemas\worker-output.schema.json"

$exploreJob = Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-explore.json" 'Load skill sdd-explore from ~/.codex/skills/sdd-explore/SKILL.md. Explore: {topic}. Project: {project}. Save results to engram. Respond in JSON following the worker output contract.' }
$exploreJob | Wait-Job

$proposeJob = Start-Job { & 'codex.cmd' exec --full-auto --ephemeral --output-schema $using:schema -o "$env:TEMP\praxisgenai-propose.json" 'Load skill sdd-propose from ~/.codex/skills/sdd-propose/SKILL.md. Load exploration from engram topic sdd/{change}/explore. Create proposal for: {change}. Respond in JSON following the worker output contract.' }
$proposeJob | Wait-Job
```

```bash
# Linux/Mac (bash) — Explore phase, then propose phase
SCHEMA="$HOME/.codex/schemas/worker-output.schema.json"

codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -C "$(pwd)" -o /tmp/praxisgenai-explore.json \
  "Load skill sdd-explore from ~/.codex/skills/sdd-explore/SKILL.md. Explore: {topic}. Project: {project}. Save results to engram. Respond in JSON following the worker output contract." &
wait

codex exec --full-auto --ephemeral --output-schema "$SCHEMA" -C "$(pwd)" -o /tmp/praxisgenai-propose.json \
  "Load skill sdd-propose from ~/.codex/skills/sdd-propose/SKILL.md. Load exploration from engram topic sdd/{change}/explore. Create proposal for: {change}. Respond in JSON following the worker output contract." &
wait
```

### SDD Workflow (Spec-Driven Development)

Persistence mode: `engram` (default when available) | `openspec` | `hybrid` | `none`.

#### Commands

| Command | Action |
|---------|--------|
| `/sdd-init` | Initialize SDD context in project |
| `/sdd-explore <topic>` | Investigate before committing |
| `/sdd-new <change>` | Explore then propose |
| `/sdd-continue [change]` | Create next missing artifact |
| `/sdd-ff [change]` | Fast-forward: propose -> spec -> design -> tasks |
| `/sdd-apply [change]` | Implement tasks in batches |
| `/sdd-verify [change]` | Validate implementation against specs |
| `/sdd-archive [change]` | Close and archive change |

`/sdd-new`, `/sdd-continue`, `/sdd-ff` are meta-commands you handle by chaining sub-agents.

#### Dependency Graph

```
proposal -> specs --> tasks -> apply -> verify -> archive
             ^
             |
           design
```

#### Engram Topic Keys

| Artifact | Topic Key |
|----------|-----------|
| Project context | `sdd-init/{project}` |
| Exploration | `sdd/{change}/explore` |
| Proposal | `sdd/{change}/proposal` |
| Spec | `sdd/{change}/spec` |
| Design | `sdd/{change}/design` |
| Tasks | `sdd/{change}/tasks` |
| Apply progress | `sdd/{change}/apply-progress` |
| Verify report | `sdd/{change}/verify-report` |
| Archive report | `sdd/{change}/archive-report` |
| DAG state | `sdd/{change}/state` |

### Sub-Agent Context Protocol

Sub-agents get fresh context with NO memory.

- **Non-SDD tasks**: Orchestrator searches engram, passes summary in prompt. Sub-agent saves discoveries via `mem_save`.
- **SDD phases**: Sub-agent reads artifacts directly from backend (topic keys passed as references). Sub-agent saves its artifact.

Include in ALL sub-agent prompts:
```
SKILL LOADING (do this FIRST):
Check for available skills:
  1. Try: mem_search(query: "skill-registry", project: "{project}")
  2. Fallback: read .atl/skill-registry.md
Load and follow any skills relevant to your task.
```

### Result Contract

Every sub-agent returns valid JSON conforming to `schemas/worker-output.schema.json`. Required fields: `contract_version`, `worker_id`, `task_id`, `status`, `executive_summary`, `ownership`, `artifacts`, `findings`, `decisions`, `changes`, `verification`, `risks`, `next_recommended`.

### Skill Loading Triggers

Skills are in `~/.codex/skills/`. When you detect these contexts, load the relevant skill:

| Context | Skill Directory |
|---------|----------------|
| SDD initialization | `sdd-init/` |
| Exploration phase | `sdd-explore/` |
| Proposal creation | `sdd-propose/` |
| Spec writing | `sdd-spec/` |
| Technical design | `sdd-design/` |
| Task breakdown | `sdd-tasks/` |
| Implementation | `sdd-apply/` |
| Verification | `sdd-verify/` |
| Archiving | `sdd-archive/` |
| Skill registry refresh | `skill-registry/` |
| Multi-agent coordination | `agent-team-orchestrator/` |

### Recovery

If SDD state is missing (after compaction), recover from engram:
`mem_search("sdd/{change}/state")` -> `mem_get_observation(id)` -> parse -> restore.

### Coordination Stack

- Sub-agents for bounded delegated work
- Engram for persistent state and recovery
- SDD skills for substantial changes
- Skill registry for sub-agent skill loading

### Scaling Rules

- **Small**: One bounded delegation
- **Medium**: explore -> implement -> verify
- **Large**: Full SDD pipeline (explore -> propose -> spec/design -> tasks -> apply -> verify -> archive)
