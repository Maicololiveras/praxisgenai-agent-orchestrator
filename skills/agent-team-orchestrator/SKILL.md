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

Every delegated worker must return:

```yaml
status: success | partial | blocked
executive_summary: >
  Short outcome-focused summary.
ownership:
  area: "<owned area/path/capability>"
  touched_paths: []
artifacts:
  created: []
  updated: []
  references: []
findings: []
decisions: []
changes: []
verification:
  performed: []
  not_performed: []
risks: []
next_recommended: []
memory_saved: []
```

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
```bash
# Launch up to 4 sub-agents in parallel
codex exec --full-auto --ephemeral -C "$(pwd)" -o /tmp/praxisgenai-sub1.md "PROMPT FOR TASK 1" &
codex exec --full-auto --ephemeral -C "$(pwd)" -o /tmp/praxisgenai-sub2.md "PROMPT FOR TASK 2" &
wait
# Read results
cat /tmp/praxisgenai-sub1.md
cat /tmp/praxisgenai-sub2.md
```

**Rules:**
- Maximum 4 parallel sub-agents (to avoid saturating the machine)
- Always use `--ephemeral` (no session persistence for sub-agents)
- Always use `--full-auto` (no approval prompts)
- Always use `-C "$(pwd)"` (same working directory)
- Always use `-o <file>` (capture output to file)
- Use `/tmp/praxisgenai-sub{N}.md` naming convention
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
