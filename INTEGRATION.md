# INTEGRATION — praxisgenai-agent-orchestrator

> Este repo es un **Monarca instalable cross-platform** del ecosistema
> **ARISE**. Permite instalar la orquestación multi-agente (OpenCode,
> Gemini CLI, Codex) en cualquier máquina del usuario con un solo
> comando.

**Documento maestro del ecosistema**:
[jarvis-core/docs/ecosystem/](https://github.com/Maicololiveras/jarvis-core/tree/main/docs/ecosystem)

---

## 1. Identidad rápida

| Campo | Valor |
|---|---|
| **Repo** | `praxisgenai-agent-orchestrator` |
| **Owner / remote** | `Maicololiveras/praxisgenai-agent-orchestrator` |
| **Categoría ARISE** | **Core** (Monarca instalable) |
| **Mariscal padre** | Monarca (rol de instalador del Monarca) |
| **Rango en la jerarquía 00B** | Monarca (despliegue) |
| **Stack principal** | scripts cross-platform (PowerShell + bash) + Python wrapper |
| **Estado** | beta — instala SDD workflow + Engram + skill registry |
| **Última auditoría ARISE** | 2026-06-15 |

---

## 2. Qué hace este repo dentro de ARISE

Es el **instalador y distribuidor** del Monarca de ARISE en cualquier
máquina del usuario. Cuando un colaborador empieza a trabajar, ejecuta
un solo comando y queda con:

- Engram (memoria persistente)
- Skill registry (skills locales + ecosystem)
- SDD workflow (sdd-init, sdd-new, etc.)
- Conexión al motor router via `praxisgenai-motor-ai-sdk`
- Soporte para OpenCode, Gemini CLI, Codex como motores LLM

### Armas / scripts que expone

| Arma | Tipo | Para qué |
|---|---|---|
| `install.ps1` / `install.sh` | shell | Bootstrap completo del Monarca |
| `skill-registry sync` | CLI | Sincroniza skills disponibles |
| `engram bootstrap` | CLI | Setup local de Engram |

---

## 3. Conexión con el ecosistema

```yaml
relacion_con_jarvis_core:
  rol: "instalador del Monarca + setup distribuido"
  consume:
    - engram (binario)
    - praxisgenai-motor-ai-sdk (config)
    - agent-teams-lite (workflow SDD)

instalado_donde:
  - máquina local del usuario
  - VPS opcional (multi-tenant futuro)

expone:
  - Setup CLI para nuevos colaboradores
  - Pinned versions de skills/engram/motor para reproducibilidad
```

---

## 4. Setup local

```bash
git clone https://github.com/Maicololiveras/praxisgenai-agent-orchestrator.git
cd praxisgenai-agent-orchestrator

# Windows
./install.ps1

# macOS / Linux
./install.sh

# Verificar
praxis-agent --version
praxis-agent skills list
```

---

## 5. SDD en este repo

Topic keys:
- `sdd-init/praxisgenai-agent-orchestrator`
- `sdd/praxisgenai-agent-orchestrator/{change}/state`

---

## 6. Roadmap propio

- [ ] **Versionado pinned** de Engram + motor-ai-sdk en cada release del orchestrator
- [ ] **Auto-update channel** — el orchestrator se auto-actualiza sin pisar config del usuario
- [ ] **Bootstrap multi-runtime** — soporte para Codex, Gemini CLI, OpenCode, Claude Code en un solo install
- [ ] **Decisión D-CORE-01b**: ¿este repo se mantiene o se merge con jarvis-core/cli?

---

## 7. Contratos críticos

- **No pisar config existente** del usuario — los `install.*` scripts
  deben detectar y respetar `~/.engram/`, `~/.praxisgenai/`, etc.
- **Versionado de skills**: cuando este repo instala un skill, debe
  versionar el lock para reproducibilidad cross-machine.

---

## 8. Versionado de este INTEGRATION.md

| Versión | Fecha | Cambio |
|---|---|---|
| v0.1 | 2026-06-15 | Manifest inicial. D-CORE-01b abierta (merge con jarvis-core o standalone). |
