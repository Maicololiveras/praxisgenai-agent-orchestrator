---
name: skill-registry
description: >
  Build or refresh a project skill registry that catalogs installed skills and
  local instruction files for sub-agent use. Trigger: When the user asks to
  initialize orchestration, refresh project conventions, or run /skill-registry.
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Purpose

Create a small, deterministic registry at `.atl/skill-registry.md` so orchestrators can resolve relevant skills and project conventions once, then pass the result to subagents.

## What to Scan

- Global OpenCode skills under `~/.config/opencode/skills/`
- Workspace instructions such as `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.agent/rules/*.md`, and `.atl/*.md`
- Project-local skills if a workspace keeps them in `.agent/skills/` or `skills/`

## Output

Write `.atl/skill-registry.md` with these sections:

1. Project
2. Installed Skills
3. Project Conventions
4. Recommended Skill Triggers

## Engram

If Engram is available, save the registry summary with:

```text
title: "skill-registry/{project}"
topic_key: "skill-registry/{project}"
type: "pattern"
```

## Commands

```bash
/skill-registry
/orch-init
```
