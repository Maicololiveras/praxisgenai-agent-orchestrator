# Architecture Overview

## Why No File-Based Coordination

Most multi-agent orchestration systems use file-based coordination primitives:
- `tasks.json` for task queues
- Mailbox folders for agent-to-agent messaging
- `.lock` files for resource claims
- Claim files for ownership

**This package uses none of those.** Here is why:

### Problems with file-based coordination

1. **Race conditions**: Multiple agents writing to the same file creates conflicts that require complex resolution logic.
2. **Stale state**: Lock files and claim files become stale when agents crash or context compacts. There is no built-in garbage collection.
3. **Context pollution**: Every file an agent reads consumes context tokens. Coordination files that agents must poll add constant overhead.
4. **Coupling**: File formats become implicit APIs. Changing the coordination format requires updating every agent that reads it.
5. **No cross-session persistence**: Files in the working directory are session-scoped. After `git clean` or a fresh clone, all coordination state is lost.

### What we use instead

Host-native primitives that each editor already provides:

| Primitive | What it replaces | Available in |
|-----------|-----------------|--------------|
| Sub-agents / Task delegation | Task queues, mailbox folders | OpenCode (agents), Codex (sub-agents), Gemini (Task tool) |
| Skills (SKILL.md files) | Hardcoded agent behavior | All editors (read file, follow instructions) |
| Engram (persistent memory) | Lock files, state files, claim files | All editors via MCP server |
| Slash commands / natural language | CLI scripts, make targets | OpenCode (commands), Gemini/Codex (natural language) |

## Coordination Model

```
                    USER
                      |
                      v
               +--------------+
               | ORCHESTRATOR |  <-- thin thread, delegates everything
               +--------------+
              /    |    |    \
             v     v    v     v
          [init] [explore] [spec] [apply]  <-- sub-agents (fresh context each)
             |     |    |    |
             v     v    v    v
           +-------------------+
           |      ENGRAM       |  <-- persistent memory layer
           | (MCP server)      |
           +-------------------+
```

### How a request flows

1. **User** asks the orchestrator for something (via slash command or natural language).
2. **Orchestrator** determines the right phase/skill and launches a sub-agent with:
   - A focused prompt (the agent's `.md` file)
   - Artifact references (Engram topic keys, not raw content)
   - Persistence instructions (what to save and where)
3. **Sub-agent** starts fresh, loads the skill registry, reads its dependencies from Engram, does the work, saves its artifact to Engram, and returns a structured result.
4. **Orchestrator** receives the result, updates DAG state in Engram, and reports to the user.

### Why sub-agents get fresh context

- The orchestrator is always-loaded context. Every token it consumes survives for the entire conversation.
- Sub-agents get a fresh context window. They can read large files (specs, designs, source code) without bloating the orchestrator's context.
- When a sub-agent finishes, only its structured summary returns to the orchestrator. The detailed work stays in Engram.

## SDD Dependency Graph

```
                +----------+
                | proposal |
                +----+-----+
                     |
              +------+------+
              |             |
         +----v----+   +----v----+
         |  specs  |   | design  |
         +----+----+   +----+----+
              |             |
              +------+------+
                     |
                +----v----+
                |  tasks  |
                +----+----+
                     |
                +----v----+
                |  apply  |
                +----+----+
                     |
                +----v----+
                | verify  |
                +----+----+
                     |
                +----v----+
                | archive |
                +---------+
```

Each node produces an artifact. Each edge is a data dependency. The orchestrator only advances to the next node when its dependencies are satisfied.

## Scaling Rules

| Task Size | Strategy | Example |
|-----------|----------|---------|
| **Small** | One bounded delegation | "Fix the typo in README" |
| **Medium** | explore -> implement -> verify | "Add input validation to the login form" |
| **Large** | Full SDD pipeline | "Add multi-tenant support to the auth system" |

The orchestrator determines size by analyzing:
- Number of files affected
- Number of modules/domains touched
- Whether architecture decisions are needed
- Whether the change is reversible without planning

## Ownership Model

Sub-agents own bounded areas during their execution:

**Good ownership boundaries:**
- `src/auth/**` -- path-based
- `docs/api/**` -- path-based
- `verify regression coverage` -- capability-based
- `design state persistence` -- phase-based

**Bad ownership boundaries:**
- "whatever is free" -- undefined scope
- "take backend maybe" -- vague
- Lock-file claims -- brittle

Ownership is implicit in the delegation prompt, not tracked in coordination files. Two sub-agents are never given overlapping paths.

## Persistence Modes

The orchestrator supports four persistence backends:

| Mode | Description | When to use |
|------|-------------|-------------|
| `engram` | Persist to Engram only. No project files. | Default. Best for most workflows. |
| `openspec` | Persist to filesystem (`openspec/` directory). | When you need version-controlled artifacts. |
| `hybrid` | Persist to both Engram and filesystem. | When you need both cross-session memory and local files. |
| `none` | No persistence. Results are inline only. | When Engram is not available and you don't want files. |

### Engram as the coordination layer

Engram replaces coordination files with a semantic memory layer:

- **Deterministic topic keys**: `sdd/{change-name}/{artifact-type}` enables exact-match retrieval.
- **Upsert semantics**: Saving with the same `topic_key` updates instead of duplicating.
- **Cross-session survival**: Artifacts persist across conversation sessions and context compactions.
- **Two-step retrieval**: `mem_search` (fast, returns truncated preview) then `mem_get_observation` (full content).

### Recovery after compaction

When the conversation context compacts:
1. The orchestrator calls `mem_search("sdd/{change-name}/state")` to find the DAG state.
2. It calls `mem_get_observation(id)` to get the full state YAML.
3. It parses the state to know which phases are complete and which are pending.
4. It resumes from the next dependency-ready phase.

This works because Engram state is external to the conversation context. File-based state would be lost if the conversation resets.

## Cross-Editor Compatibility

All three supported editors (OpenCode, Gemini CLI, Codex) use the same:
- **Skills**: Identical SKILL.md files define agent behavior.
- **Engram protocol**: Same topic keys, same two-step retrieval, same persistence contract.
- **SDD pipeline**: Same phases, same dependency graph, same artifact formats.

What differs per editor is the **delegation model** — how the orchestrator dispatches work:

### Delegation Models

| Editor | Delegation Model | Mechanism | Context Isolation |
|--------|-----------------|-----------|-------------------|
| **Claude Code** | Native sub-agents | Built-in `Agent` tool with typed sub-agents (Explore, Plan, general) | Full — each sub-agent gets fresh context |
| **OpenCode** | Native sub-agents | `subtask: true` in command definitions spawns isolated agent contexts | Full — dedicated agent per SDD phase |
| **Gemini CLI** | Native sub-agents | `SubagentTool` exposes sub-agents as callable tools; `activate_skill` loads skills dynamically | Full — isolated context with own tool permissions |
| **Codex** | Simulated sub-agents via `codex exec` | Spawns up to 4 background `codex exec` processes with `--full-auto --ephemeral -o`; reads output files and synthesizes | Full — each `codex exec` process gets fresh context |

### Why the models differ

Sub-agent support is a **runtime capability**, not a configuration choice:

- **OpenCode** was designed with multi-agent orchestration in mind. Its `subtask` flag creates true isolated contexts.
- **Gemini CLI** exposes sub-agents as tools (`SubagentTool`), making delegation a tool call rather than a conversation fork.
- **Codex** is architecturally single-agent within a session, but can simulate sub-agents by spawning background `codex exec` processes. Each process runs with `--full-auto --ephemeral` and writes its output to a temp file via `-o`. The main Codex reads all outputs and synthesizes. This gives effective context isolation (each `codex exec` gets fresh context) with up to 4 parallel sub-agents.
- **Claude Code** has the most complete native support — `Agent` tool with typed sub-agents, native skill loading, and Engram MCP plugin. This package is not needed for Claude Code.

### Codex simulated sub-agent pattern

Codex simulates sub-agents by spawning `codex exec` processes in background:

```
Main Codex (interactive orchestrator)
  |-- codex exec --full-auto --ephemeral -C "$(pwd)" -o /tmp/praxisgenai-sub1.md "explore prompt" &
  |-- codex exec --full-auto --ephemeral -C "$(pwd)" -o /tmp/praxisgenai-sub2.md "analyze prompt" &
  wait
  |-- Reads /tmp/praxisgenai-sub1.md and /tmp/praxisgenai-sub2.md
  '-- Synthesizes results, saves to Engram, cleans up temp files
```

Rules:
- Maximum 4 parallel sub-agents
- Always use `--ephemeral` (no session persistence) and `--full-auto` (no approval prompts)
- Always use `-o <file>` to capture output
- Each phase MUST save to Engram before completing
- Each phase MUST load prior artifacts from Engram before starting
- Engram remains the critical state bridge for cross-phase and cross-session continuity

### What differs per editor (configuration)
- **Invocation**: OpenCode uses slash commands, Gemini/Codex use natural language.
- **Configuration**: OpenCode uses JSON, Codex uses TOML, Gemini uses markdown rules.

The skills layer abstracts these differences. A skill written once works in all editors.
