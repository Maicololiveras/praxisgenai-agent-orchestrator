# PraxisGenAI Agent Orchestrator — Installer
# Usage:
#   irm https://raw.githubusercontent.com/Maicololiveras/praxisgenai-agent-orchestrator/main/scripts/install.ps1 | iex
#   OR
#   .\scripts\install.ps1 -Editor opencode
#   .\scripts\install.ps1 -Editor gemini
#   .\scripts\install.ps1 -Editor codex
#   .\scripts\install.ps1 -Editor all
#   .\scripts\install.ps1 -Editor all -DryRun

[CmdletBinding()]
param(
    [ValidateSet("opencode", "gemini", "codex", "all")]
    [string]$Editor,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$MARKER = "# >>> PraxisGenAI Agent Orchestrator — DO NOT REMOVE THIS LINE <<<"

# --- Resolve repo root ---
$RepoRoot = if ($PSScriptRoot) {
    Split-Path $PSScriptRoot -Parent
} else {
    # When piped via irm | iex, clone to temp
    $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "praxisgenai-agent-orchestrator"
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    Write-Host "[*] Cloning repository to temp directory..." -ForegroundColor Cyan
    git clone --depth 1 https://github.com/Maicololiveras/praxisgenai-agent-orchestrator.git $TempDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone repository."
        exit 1
    }
    $TempDir
}

# --- Target directories ---
$HomePath = $env:USERPROFILE
if (-not $HomePath) { $HomePath = $env:HOME }

$Targets = @{
    opencode = Join-Path $HomePath ".config/opencode"
    gemini   = Join-Path $HomePath ".gemini"
    codex_skills = Join-Path $HomePath ".codex"
    codex_config = if ($env:APPDATA) { Join-Path $env:APPDATA "codex" } else { Join-Path $HomePath ".config/codex" }
}

# --- Helpers ---
function Write-Step {
    param([string]$Message)
    Write-Host "  -> $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [i] $Message" -ForegroundColor Yellow
}

function Copy-Directory {
    param(
        [string]$Source,
        [string]$Destination
    )
    if ($DryRun) {
        Write-Info "[DRY RUN] Would copy: $Source -> $Destination"
        return
    }
    if (-not (Test-Path $Source)) {
        Write-Warning "Source not found: $Source"
        return
    }
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    Copy-Item -Path "$Source/*" -Destination $Destination -Recurse -Force
}

function Copy-SingleFile {
    param(
        [string]$Source,
        [string]$Destination
    )
    if ($DryRun) {
        Write-Info "[DRY RUN] Would copy: $Source -> $Destination"
        return
    }
    if (-not (Test-Path $Source)) {
        Write-Warning "Source not found: $Source"
        return
    }
    $DestDir = Split-Path $Destination -Parent
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    Copy-Item -Path $Source -Destination $Destination -Force
}

# --- Merge opencode.agents.json into opencode.json ---
function Merge-OpenCodeConfig {
    param(
        [string]$PatchFile,
        [string]$TargetFile
    )
    if ($DryRun) {
        Write-Info "[DRY RUN] Would merge agent config: $PatchFile -> $TargetFile"
        return
    }
    if (-not (Test-Path $PatchFile)) {
        Write-Warning "Patch file not found: $PatchFile"
        return
    }

    $PatchJson = Get-Content $PatchFile -Raw | ConvertFrom-Json
    $PatchAgents = $PatchJson.agent

    if (Test-Path $TargetFile) {
        $TargetJson = Get-Content $TargetFile -Raw | ConvertFrom-Json
    } else {
        $TargetDir = Split-Path $TargetFile -Parent
        if (-not (Test-Path $TargetDir)) {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        }
        $TargetJson = [PSCustomObject]@{}
    }

    # Ensure agent property exists
    if (-not ($TargetJson.PSObject.Properties.Name -contains "agent")) {
        $TargetJson | Add-Member -NotePropertyName "agent" -NotePropertyValue ([PSCustomObject]@{})
    }

    # Merge each agent entry
    foreach ($prop in $PatchAgents.PSObject.Properties) {
        $agentName = $prop.Name
        $agentValue = $prop.Value
        if ($TargetJson.agent.PSObject.Properties.Name -contains $agentName) {
            Write-Info "Agent '$agentName' already exists in config, updating..."
            $TargetJson.agent.$agentName = $agentValue
        } else {
            $TargetJson.agent | Add-Member -NotePropertyName $agentName -NotePropertyValue $agentValue
        }
    }

    $TargetJson | ConvertTo-Json -Depth 10 | Set-Content $TargetFile -Encoding UTF8
    Write-Step "Merged agent config into $TargetFile"
}

# --- Install functions ---
function Install-OpenCode {
    Write-Host "`n[OpenCode] Installing..." -ForegroundColor Cyan
    $target = $Targets.opencode

    # 1. Copy skills
    Copy-Directory -Source "$RepoRoot/skills" -Destination "$target/skills"
    Write-Step "Copied skills/ -> $target/skills/"

    # 2. Copy agents
    Copy-Directory -Source "$RepoRoot/editors/opencode/agents" -Destination "$target/agents"
    Write-Step "Copied agents/ -> $target/agents/"

    # 3. Copy commands
    Copy-Directory -Source "$RepoRoot/editors/opencode/commands" -Destination "$target/commands"
    Write-Step "Copied commands/ -> $target/commands/"

    # 4. Merge config
    Merge-OpenCodeConfig `
        -PatchFile "$RepoRoot/editors/opencode/opencode.agents.json" `
        -TargetFile "$target/opencode.json"

    # 5. Copy AGENTS.md (personality + orchestrator)
    $agentsMdSrc = "$RepoRoot/editors/opencode/AGENTS.md"
    $agentsMdDst = Join-Path $target "AGENTS.md"

    if (-not (Test-Path $agentsMdSrc)) {
        Write-Warning "AGENTS.md not found in repo: $agentsMdSrc"
    } elseif ($DryRun) {
        Write-Info "[DRY RUN] Would copy AGENTS.md to $agentsMdDst"
    } else {
        if (Test-Path $agentsMdDst) {
            $existingContent = Get-Content $agentsMdDst -Raw
            if ($existingContent -and $existingContent.Contains($MARKER)) {
                Write-Info "AGENTS.md already has orchestrator marker, replacing with full version..."
            }
        }
        Copy-Item -Path $agentsMdSrc -Destination $agentsMdDst -Force
        Write-Step "Copied AGENTS.md -> $agentsMdDst"
    }

    Write-Host "[OpenCode] Done!" -ForegroundColor Green
}

function Install-Gemini {
    Write-Host "`n[Gemini CLI] Installing..." -ForegroundColor Cyan
    $target = $Targets.gemini

    # 1. Copy skills
    Copy-Directory -Source "$RepoRoot/skills" -Destination "$target/skills"
    Write-Step "Copied skills/ -> $target/skills/"

    # 2. Handle GEMINI.md (personality + orchestrator)
    $geminiMd = Join-Path $target "GEMINI.md"
    $orchestratorMd = "$RepoRoot/editors/gemini/GEMINI_ORCHESTRATOR.md"
    $personalityMd = "$RepoRoot/editors/gemini/GEMINI_PERSONALITY.md"

    if ($DryRun) {
        Write-Info "[DRY RUN] Would configure GEMINI.md at $geminiMd"
    } else {
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        if (-not (Test-Path $geminiMd)) {
            # GEMINI.md does not exist — create from personality + orchestrator
            $newContent = ""
            if (Test-Path $personalityMd) {
                $newContent += (Get-Content $personalityMd -Raw)
            }
            if (Test-Path $orchestratorMd) {
                $orchestratorContent = Get-Content $orchestratorMd -Raw
                $newContent += "`n`n$MARKER`n$orchestratorContent`n"
            }
            Set-Content -Path $geminiMd -Value $newContent -Encoding UTF8
            Write-Step "Created GEMINI.md with personality + orchestrator at $geminiMd"
        } else {
            $existingContent = Get-Content $geminiMd -Raw

            # Check and prepend personality if missing
            if ($existingContent -and -not $existingContent.Contains("## Personality")) {
                if (Test-Path $personalityMd) {
                    $personalityContent = Get-Content $personalityMd -Raw
                    $existingContent = $personalityContent + "`n`n" + $existingContent
                    Set-Content -Path $geminiMd -Value $existingContent -Encoding UTF8
                    Write-Step "Prepended personality section to GEMINI.md"
                }
            } else {
                Write-Info "Personality section already present in GEMINI.md."
            }

            # Reload content after potential personality prepend
            $existingContent = Get-Content $geminiMd -Raw

            # Append orchestrator if not present
            if ($existingContent -and $existingContent.Contains($MARKER)) {
                Write-Info "Orchestrator rules already present in GEMINI.md, skipping append."
            } else {
                if (Test-Path $orchestratorMd) {
                    $orchestratorContent = Get-Content $orchestratorMd -Raw
                    $appendBlock = "`n`n$MARKER`n$orchestratorContent`n"
                    Add-Content -Path $geminiMd -Value $appendBlock -Encoding UTF8
                    Write-Step "Appended orchestrator rules to $geminiMd"
                } else {
                    Write-Warning "Orchestrator file not found: $orchestratorMd"
                }
            }
        }
    }

    # 3. Add skills table row
    $skillsTablePatch = "$RepoRoot/editors/gemini/skills-table-patch.md"
    $skillsRow = "| Multi-agent coordination, phased work, SDD routing | agent-team-orchestrator |"

    if ($DryRun) {
        Write-Info "[DRY RUN] Would add skills table row to $geminiMd"
    } else {
        if (Test-Path $geminiMd) {
            $content = Get-Content $geminiMd -Raw
            if ($content -and $content.Contains("agent-team-orchestrator")) {
                Write-Info "Skills table row already present in GEMINI.md, skipping."
            } else {
                # Try to find the skills table and append row
                $tablePattern = "(\| Context\s+\| Skill to load \|`n\| [-\s|]+ \|)"
                if ($content -match "\| Context") {
                    # Find last table row and append after it
                    $lines = $content -split "`n"
                    $lastTableRow = -1
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match "^\|.*\|$") {
                            $lastTableRow = $i
                        }
                    }
                    if ($lastTableRow -ge 0) {
                        $lines = [System.Collections.ArrayList]@($lines)
                        $lines.Insert($lastTableRow + 1, $skillsRow)
                        ($lines -join "`n") | Set-Content $geminiMd -Encoding UTF8
                        Write-Step "Added skills table row to GEMINI.md"
                    } else {
                        Add-Content -Path $geminiMd -Value "`n$skillsRow" -Encoding UTF8
                        Write-Step "Appended skills table row to GEMINI.md"
                    }
                } else {
                    Write-Info "No skills table found in GEMINI.md. Add manually:"
                    Write-Info "  $skillsRow"
                }
            }
        } else {
            Write-Info "GEMINI.md not found at $geminiMd. Skills table row not added."
        }
    }

    Write-Host "[Gemini CLI] Done!" -ForegroundColor Green
}

function Install-Codex {
    Write-Host "`n[Codex] Installing..." -ForegroundColor Cyan

    # 1. Copy skills
    Copy-Directory -Source "$RepoRoot/skills" -Destination "$($Targets.codex_skills)/skills"
    Write-Step "Copied skills/ -> $($Targets.codex_skills)/skills/"

    # 2. Copy full instructions.md (personality + engram + orchestrator)
    $instrSrc = "$RepoRoot/editors/codex/instructions.md"
    $instrDst = Join-Path $Targets.codex_config "instructions.md"
    Copy-SingleFile -Source $instrSrc -Destination $instrDst
    Write-Step "Copied instructions.md -> $instrDst"

    # 3. Copy engram-instructions.md
    $engramSrc = "$RepoRoot/editors/codex/engram-instructions.md"
    $engramDst = Join-Path $Targets.codex_config "engram-instructions.md"
    Copy-SingleFile -Source $engramSrc -Destination $engramDst
    Write-Step "Copied engram-instructions.md -> $engramDst"

    # 4. Copy engram-compact-prompt.md
    $compactSrc = "$RepoRoot/editors/codex/engram-compact-prompt.md"
    $compactDst = Join-Path $Targets.codex_config "engram-compact-prompt.md"
    Copy-SingleFile -Source $compactSrc -Destination $compactDst
    Write-Step "Copied engram-compact-prompt.md -> $compactDst"

    # 5. Write config entries to ~/.codex/config.toml (Codex reads config from $HOME/.codex/)
    #    Instruction FILES stay in %APPDATA%/codex/ — the config just points to them.
    $codexConfigDir = Join-Path $HomePath ".codex"
    $configToml = Join-Path $codexConfigDir "config.toml"

    # Resolve full paths to instruction files (in %APPDATA%/codex/)
    $instrFullPath = (Join-Path $Targets.codex_config "instructions.md") -replace '\\', '\\'
    $compactFullPath = (Join-Path $Targets.codex_config "engram-compact-prompt.md") -replace '\\', '\\'

    if ($DryRun) {
        Write-Info "[DRY RUN] Would ensure config entries in $configToml"
        Write-Info "  model_instructions_file = `"$instrFullPath`""
        Write-Info "  experimental_compact_prompt_file = `"$compactFullPath`""
    } else {
        if (-not (Test-Path $codexConfigDir)) {
            New-Item -ItemType Directory -Path $codexConfigDir -Force | Out-Null
        }

        $configContent = ""
        if (Test-Path $configToml) {
            $configContent = Get-Content $configToml -Raw
            if (-not $configContent) { $configContent = "" }
        }

        $changed = $false

        # Add model_instructions_file if not present
        if (-not ($configContent -match "model_instructions_file")) {
            $configContent = $configContent.TrimEnd() + "`nmodel_instructions_file = `"$instrFullPath`"`n"
            $changed = $true
            Write-Step "Added model_instructions_file to $configToml"
        } else {
            Write-Info "model_instructions_file already set in $configToml"
        }

        # Add experimental_compact_prompt_file if not present
        if (-not ($configContent -match "experimental_compact_prompt_file")) {
            $configContent = $configContent.TrimEnd() + "`nexperimental_compact_prompt_file = `"$compactFullPath`"`n"
            $changed = $true
            Write-Step "Added experimental_compact_prompt_file to $configToml"
        } else {
            Write-Info "experimental_compact_prompt_file already set in $configToml"
        }

        if ($changed) {
            Set-Content -Path $configToml -Value $configContent -Encoding UTF8
        }
    }

    Write-Host "[Codex] Done!" -ForegroundColor Green
}

# --- Main ---
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PraxisGenAI Agent Orchestrator Installer" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repo root: $RepoRoot"
if ($DryRun) {
    Write-Host "[DRY RUN MODE] No files will be modified." -ForegroundColor Yellow
}

# If no editor specified (piped from irm), prompt user
if (-not $Editor) {
    Write-Host ""
    Write-Host "Which editor do you want to install for?" -ForegroundColor Yellow
    Write-Host "  1) opencode"
    Write-Host "  2) gemini"
    Write-Host "  3) codex"
    Write-Host "  4) all"
    Write-Host ""
    $choice = Read-Host "Enter choice (1-4)"
    switch ($choice) {
        "1" { $Editor = "opencode" }
        "2" { $Editor = "gemini" }
        "3" { $Editor = "codex" }
        "4" { $Editor = "all" }
        "opencode" { $Editor = "opencode" }
        "gemini" { $Editor = "gemini" }
        "codex" { $Editor = "codex" }
        "all" { $Editor = "all" }
        default {
            Write-Error "Invalid choice: $choice"
            exit 1
        }
    }
}

switch ($Editor) {
    "opencode" { Install-OpenCode }
    "gemini"   { Install-Gemini }
    "codex"    { Install-Codex }
    "all" {
        Install-OpenCode
        Install-Gemini
        Install-Codex
    }
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
