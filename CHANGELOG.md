# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-03-16

### Added

- **Skills**: Editor-agnostic skill definitions for multi-agent orchestration
  - `agent-team-orchestrator` - Main orchestrator coordination skill
  - `skill-registry` - Project skill catalog builder
  - `sdd-init` through `sdd-archive` - Full SDD (Spec-Driven Development) pipeline
  - `_shared/` conventions for Engram, OpenSpec, and persistence contracts
- **OpenCode support**: Agent definitions, prompt files, and slash commands
  - 11 agent prompt files for delegation
  - 13 slash commands (`/orch-*`, `/sdd-*`, `/skill-registry`)
  - `opencode.agents.json` for merging into `opencode.json`
- **Gemini CLI support**: Orchestrator rules and skills table patch
  - `GEMINI_ORCHESTRATOR.md` for appending to `GEMINI.md`
  - `skills-table-patch.md` for the skills auto-load table
- **Codex support**: Orchestrator instructions and config patch
  - `orchestrator-instructions.md` for Codex instructions
  - `config-patch.toml` for Codex config.toml
- **Install scripts**: Cross-platform one-command install
  - `install.sh` for macOS/Linux (placeholder for external agent)
  - `install.ps1` for Windows (placeholder for external agent)
- **Documentation**: Per-editor install guides, architecture overview
