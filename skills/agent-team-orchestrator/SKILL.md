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
