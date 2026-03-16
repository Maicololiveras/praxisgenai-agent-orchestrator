# PraxisGenAI Agent Orchestrator

Multi-agent orchestration package for AI coding assistants. Coordinates work using host-native primitives (skills, sub-agents, Engram memory) instead of file-based mailboxes or lock files.

## Supported Editors

| Editor | Install | Status |
|---|---|---|
| OpenCode | Full (skills + agents + commands + config) | Ready |
| Gemini CLI | Full (skills + instructions) | Ready |
| Codex | Full (skills + instructions) | Ready |
| Claude Code | Not needed (native support) | Native |

## Quick Install

### Windows (PowerShell)

```powershell
# Clone and install for all editors
git clone https://github.com/Maicololiveras/praxisgenai-agent-orchestrator.git
cd praxisgenai-agent-orchestrator
.\scripts\install.ps1 -Editor all

# Or install for a specific editor
.\scripts\install.ps1 -Editor opencode
.\scripts\install.ps1 -Editor gemini
.\scripts\install.ps1 -Editor codex

# Preview changes without modifying anything
.\scripts\install.ps1 -Editor all -DryRun
```

### Linux / macOS

```bash
git clone https://github.com/Maicololiveras/praxisgenai-agent-orchestrator.git
cd praxisgenai-agent-orchestrator
./scripts/install.sh --editor all

# Or install for a specific editor
./scripts/install.sh --editor opencode
./scripts/install.sh --editor gemini
./scripts/install.sh --editor codex

# Preview changes without modifying anything
./scripts/install.sh --editor all --dry-run
```

### One-liner (remote install)

**Windows:**
```powershell
irm https://raw.githubusercontent.com/Maicololiveras/praxisgenai-agent-orchestrator/main/scripts/install.ps1 | iex
```

**Linux / macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/Maicololiveras/praxisgenai-agent-orchestrator/main/scripts/install.sh | bash
```

## Prerequisites

- One or more supported editors installed
- [Engram](https://github.com/Gentleman-Programming/engram) installed and working (`engram stats`)
- Git

## What It Includes

### Skills (shared across all editors)

| Skill | Description |
|---|---|
| `agent-team-orchestrator` | Global coordination — delegate-first orchestration |
| `skill-registry` | Project skill catalog builder |
| `sdd-init` | Initialize SDD context for a project |
| `sdd-explore` | Explore a change topic |
| `sdd-propose` | Create a change proposal |
| `sdd-spec` | Write change specifications |
| `sdd-design` | Write technical design |
| `sdd-tasks` | Plan implementation tasks |
| `sdd-apply` | Implement planned tasks |
| `sdd-verify` | Verify implementation against specs |
| `sdd-archive` | Archive a completed change |
| `_shared` | Convention reference docs (engram, openspec, persistence) |

### Editor-Specific

- **OpenCode**: Agent prompts (11 agents), slash commands (`/orch-*`, `/sdd-*`), config merge
- **Gemini CLI**: Orchestrator rules appended to `GEMINI.md`, skills table patch
- **Codex**: Orchestrator instructions file for `config.toml`

## Architecture

This package coordinates with **host-native primitives**:

- **Sub-agents and skills** — not file-based mailboxes
- **Engram** for persistent memory — not `tasks.json`
- **Ownership by area/path** — not `.lock` files
- **SDD** (Spec-Driven Development) for substantial changes

The orchestrator acts as a thin coordinator that delegates all real work to specialized sub-agents. Each sub-agent gets a fresh context, does focused work, and returns only the summary. This keeps the main conversation lean and prevents context bloat.

### SDD Dependency Graph

```
proposal -> specs --> tasks -> apply -> verify -> archive
             ^
             |
           design
```

See [docs/architecture.md](docs/architecture.md) for the full design.

## Why Not Claude Code?

Claude Code already has native orchestration:

- Built-in `Agent` tool with typed sub-agents
- Native skill loading from `~/.claude/skills/`
- Engram MCP plugin
- Full SDD support via Agent Teams Lite skills

This package is for editors that **lack** native multi-agent primitives. See [docs/why-not-claude.md](docs/why-not-claude.md) for details.

## Commands (OpenCode)

| Command | Description |
|---|---|
| `/orch-help` | Show available commands |
| `/orch-status` | Check workspace readiness |
| `/orch-doctor` | Run setup diagnostics |
| `/orch-init` | Initialize skill registry + SDD |
| `/sdd-new <change>` | Start new change with exploration |
| `/sdd-ff <change>` | Fast-forward planning phases |
| `/sdd-apply <change>` | Implement planned tasks |
| `/sdd-verify <change>` | Verify implementation |
| `/sdd-explore <topic>` | Explore a topic before proposing |
| `/sdd-continue [change]` | Continue next missing artifact |
| `/sdd-archive [change]` | Archive a completed change |
| `/skill-registry` | Build project skill catalog |

## File Structure

```
praxisgenai-agent-orchestrator/
  skills/                          # Shared skills (all editors)
    agent-team-orchestrator/SKILL.md
    skill-registry/SKILL.md
    sdd-init/SKILL.md
    sdd-explore/SKILL.md
    sdd-propose/SKILL.md
    sdd-spec/SKILL.md
    sdd-design/SKILL.md
    sdd-tasks/SKILL.md
    sdd-apply/SKILL.md
    sdd-verify/SKILL.md
    sdd-archive/SKILL.md
    _shared/
      engram-convention.md
      openspec-convention.md
      persistence-contract.md
  editors/
    opencode/
      agents/                      # Agent prompt files
      commands/                    # Slash command definitions
      opencode.agents.json         # Config to merge
    gemini/
      GEMINI_ORCHESTRATOR.md       # Rules to append
      skills-table-patch.md        # Skills table row
    codex/
      orchestrator-instructions.md
      config-patch.toml
  scripts/
    install.ps1                    # Windows installer
    install.sh                     # Linux/macOS installer
  docs/
    architecture.md
    opencode.md
    gemini.md
    codex.md
    why-not-claude.md
```

## Documentation

- [OpenCode Guide](docs/opencode.md)
- [Gemini CLI Guide](docs/gemini.md)
- [Codex Guide](docs/codex.md)
- [Architecture](docs/architecture.md)
- [Why Not Claude](docs/why-not-claude.md)

## Related Projects

- [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai) — Universal AI configurator
- [engram](https://github.com/Gentleman-Programming/engram) — Persistent memory for AI agents
- [agent-teams-lite](https://github.com/Gentleman-Programming/agent-teams-lite) — SDD skills and conventions

## License

MIT
