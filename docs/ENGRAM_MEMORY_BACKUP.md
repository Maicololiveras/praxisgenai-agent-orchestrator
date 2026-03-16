# Engram Memory Backup — PraxisGenAI Project

> Snapshot de todas las memorias persistentes de Engram para el proyecto PraxisGenAI.
> Fecha: 2026-03-16
> Total: 10 observaciones

---

## Observation #2 [architecture] — sdd-init/praxisgenai
**Created**: 2026-03-13 12:43:35 | **Project**: praxisgenai | **Topic**: sdd-init/praxisgenai

# PRAXISGENAI Agent OS — Project Context

## Overview
Enterprise ecosystem to create, train, deploy, and monitor AI agents — customer support, sales, code generation, process automation — with persistent memory, auto-improvement, and multi-provider LLM support.

**Author:** Maicol Extic Oliveras Jimenez
**Company:** PRAXISGENAI (https://praxisgenai.com)
**Status:** Planning phase (no production code yet)

## Project Structure
```
D:/Planiacionappcreatoragentico/
├── PLAN_MAESTRO.md
├── praxisgenai-agent-os/
└── PRAXISGENAI_DOCS/
    └── praxisgenai/
        ├── 00_super_prompt.md
        ├── agent-os/
        ├── frontend-dashboard/
        └── praxis-sdk/
```

## Tech Stack (Planned)
- Agent OS: WPF/.NET via gRPC to Python backend
- Frontend Dashboard: Next.js 14, React 18, Tailwind, Supabase
- Backend: Python (Maix AI Engine) — gRPC :50051
- LLM: OpenAI, Gemini, Claude, local GGUF, Ollama
- Memory: Engram (SQLite + FTS5)
- RAG: Hybrid search, chunking + embeddings
- Skills: SKILL.md pattern from Agent Teams Lite
- Personas: Gentle AI injection pattern
- Auto-improve: Karpathy autoresearch pattern

## Three Product Layers
1. Agent OS (Desktop/WPF)
2. Web Dashboard (Next.js/Vercel)
3. Embeddable SDK (gRPC/.NET/Python)

---

## Observation #5 [architecture] — Motor AI SDK scaffold
**Created**: 2026-03-13 15:05:15 | **Project**: praxisgenai | **Topic**: architecture/motor-ai-sdk-scaffold

**What**: Created praxisgenai-motor-ai-sdk with 74 files: Python SDK (8 providers, 9 services, 6 core engines, gRPC server, CLI), 10 proto3 definitions, .NET gRPC client, install scripts, Docker, CI.
**Where**: D:/Planiacionappcreatoragentico/praxisgenai-motor-ai-sdk/
**Learned**: ProviderRegistry decorator for auto-registration, AgentRuntime 7-stage pipeline, all providers handle ImportError gracefully.

---

## Observation #7 [architecture] — Creator Agents WPF scaffold
**Created**: 2026-03-13 17:57:20 | **Project**: praxisgenai-creator-agents | **Topic**: architecture/project-scaffold

**What**: Created WPF .NET 9.0 project — 133 files, 8 projects in solution.
**Where**: D:/Planiacionappcreatoragentico/praxisgenai-creator-agents/
**Key**: DarkTheme palette (Primary #2563EB, BgMain #0F111A), CommunityToolkit.Mvvm, 10-step wizard (Preset > Identity > Provider > Persona > Documents > Skills > Parameters > Tools > Permissions > Test).

---

## Observation #41 [session_summary] — Session 1 Summary
**Created**: 2026-03-13 21:04:04 | **Project**: praxisgenai

### Instructions
- Rioplatense Spanish, conventional commits (no Co-Authored-By)
- Parallel agents for large docs (4 write parts + 1 merges)
- gis2Seco is NOT related — was just SDK testing ground

### Accomplished
- Cloned repos, verified Gentle Stack on 4 editors
- Created doc 33, doc 34 (HTML)
- Created praxisgenai-motor-ai-sdk (74 files)
- Created praxisgenai-creator-agents (134 files)
- UI/UX Guide (1273 lines)

---

## Observation #59 [architecture] — Agent Orchestrator repo structure
**Created**: 2026-03-16 13:57:52 | **Project**: praxisgenai-agent-orchestrator | **Topic**: sdd/agent-orchestrator-repo/structure

**What**: Created praxisgenai-agent-orchestrator package — skills, editor configs (OpenCode agents/commands, Gemini rules, Codex instructions), docs, install scripts.
**Where**: D:/Planiacionappcreatoragentico/praxisgenai-agent-orchestrator/

---

## Observation #61 [config] — Fixed orchestrator repo gaps
**Created**: 2026-03-16 15:25:59 | **Project**: praxisgenai-agent-orchestrator | **Topic**: orchestrator/full-instruction-files

**What**: Added complete instruction files (personality + engram + orchestrator) for all editors. Updated install scripts for fresh machine installs.
**Learned**: Codex uses %APPDATA%/codex/ on Windows vs ~/.config/codex on Linux. Install scripts handle personality prepend, orchestrator append, and full file creation.

---

## Observation #68 [session_summary] — Session 2 Summary (Orchestrator + Config)
**Created**: 2026-03-16 19:05:03 | **Project**: praxisgenai

### Key Discoveries
- Codex reads config from ~/.codex/config.toml (NOT %APPDATA%)
- Codex simulates sub-agents via `codex exec --full-auto --ephemeral --output-schema`
- PowerShell 5.1: use Start-Job + Wait-Job (not bash &)
- JSON Schema requires additionalProperties:false in ALL nested objects
- Gemini defaultApprovalMode must be "auto_edit" (not "yolo")
- OpenCode has native subtask:true, Gemini has SubagentTool, Codex has NONE

### Accomplished
- Gentle Stack verified on 4 editors
- Gemini settings fixed, Context7 MCP added to Claude
- Personality injected into Codex
- Agent orchestrator repo created (public) with install scripts
- JSON Schema validated against codex exec --output-schema
- Doc 33 updated with 9 installation gaps fixed

---

## Observation #70 [architecture] — Maix AI Engine async migration
**Created**: 2026-03-16 19:41:52 | **Project**: praxisgenai | **Topic**: architecture/maix-ai-engine-async

**What**: Migrated Maix AI Engine from sync grpc to async grpc.aio with ModelPool.
**Where**: D:/LM WEG, github.com/Maicololiveras/praxisgenai-maix-ai-engine
**Critical**:
- llama-cpp-python is sync — wrap in run_in_executor
- Max 4 pool instances (VRAM/RAM)
- Proto unchanged = .NET client backward compatible
- User demands PRODUCTION quality only
- gis2Seco at C:/Windows.old/Users/maicolj/source/repos/gis2Seco, branch LMGIS, .NET 4.8

---

## Observation #71 [architecture] — SDD Explore: Production Hardening
**Created**: 2026-03-16 19:49:38 | **Project**: praxisgenai | **Topic**: sdd/maix-engine-production/explore

Full exploration of what exists vs what's missing for production. 13 gaps identified. 5 phases planned. SDK patterns identified for porting (interceptors, config, providers, router, server class).

Key constraints: llama-cpp-python sync, pool only for local, proto backward compat, .NET netstandard2.0, Windows primary.

---

## Observation #78 [session_summary] — Session 3 Summary (Engine Production)
**Created**: 2026-03-16 21:29:15 | **Project**: praxisgenai

### Accomplished
- Fase 1 Server Hardening (5 tasks): config, interceptors, rate limit, health, circuit breaker, timeouts
- Fase 2 Multi-Provider (4 tasks): 7 providers + router + service wiring
- Fase 3 Quality (3 tasks): structlog, metrics, integration/load tests
- Parallel worktree merge (Phase 2 + Phase 3), conflict resolved
- SPRINT_PROGRESS.md handoff document (446 lines)

### Pending
- Fase 4 Deploy (Docker + CI/CD)
- Connect gis2Seco with updated engine
- Connect Creator Agents with engine

### Key Files
- D:/LM WEG/SPRINT_PROGRESS.md — full handoff
- D:/LM WEG/python/maix_ai_engine/ — production server
- praxisgenai-agent-orchestrator/schemas/worker-output.schema.json — validated contract
