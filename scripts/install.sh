#!/usr/bin/env bash
# PraxisGenAI Agent Orchestrator — Installer
# Usage:
#   curl -sSL https://raw.githubusercontent.com/Maicololiveras/praxisgenai-agent-orchestrator/main/scripts/install.sh | bash
#   OR
#   ./scripts/install.sh --editor opencode
#   ./scripts/install.sh --editor gemini
#   ./scripts/install.sh --editor codex
#   ./scripts/install.sh --editor all
#   ./scripts/install.sh --editor all --dry-run

set -euo pipefail

# --- Constants ---
MARKER="# >>> PraxisGenAI Agent Orchestrator — DO NOT REMOVE THIS LINE <<<"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Helpers ---
info()  { echo -e "  ${YELLOW}[i]${NC} $1"; }
step()  { echo -e "  ${GREEN}->${NC} $1"; }
header() { echo -e "\n${CYAN}[$1]${NC} $2"; }

copy_directory() {
    local src="$1" dst="$2"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] Would copy: $src -> $dst"
        return
    fi
    if [[ ! -d "$src" ]]; then
        echo -e "  ${RED}Warning:${NC} Source not found: $src"
        return
    fi
    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/
}

copy_file() {
    local src="$1" dst="$2"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] Would copy: $src -> $dst"
        return
    fi
    if [[ ! -f "$src" ]]; then
        echo -e "  ${RED}Warning:${NC} Source not found: $src"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

# --- Resolve repo root ---
resolve_repo_root() {
    local script_dir
    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        REPO_ROOT="$(dirname "$script_dir")"
    else
        # Piped from curl — clone to temp
        local tmp_dir
        tmp_dir="$(mktemp -d)/praxisgenai-agent-orchestrator"
        echo -e "${CYAN}[*] Cloning repository to temp directory...${NC}"
        git clone --depth 1 https://github.com/Maicololiveras/praxisgenai-agent-orchestrator.git "$tmp_dir" 2>/dev/null
        REPO_ROOT="$tmp_dir"
    fi
}

# --- Target directories ---
HOME_DIR="${HOME}"
TARGET_OPENCODE="${HOME_DIR}/.config/opencode"
TARGET_GEMINI="${HOME_DIR}/.gemini"
TARGET_CODEX_SKILLS="${HOME_DIR}/.codex"
# Linux/Mac: XDG_CONFIG_HOME or ~/.config/codex
TARGET_CODEX_CONFIG="${XDG_CONFIG_HOME:-${HOME_DIR}/.config}/codex"

# --- Merge opencode.agents.json into opencode.json ---
merge_opencode_config() {
    local patch_file="$1" target_file="$2"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] Would merge agent config: $patch_file -> $target_file"
        return
    fi
    if [[ ! -f "$patch_file" ]]; then
        echo -e "  ${RED}Warning:${NC} Patch file not found: $patch_file"
        return
    fi

    mkdir -p "$(dirname "$target_file")"

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        info "jq not found. Copying agents config as-is."
        if [[ -f "$target_file" ]]; then
            info "Existing opencode.json found. Manual merge required."
            info "Patch file: $patch_file"
        else
            cp "$patch_file" "$target_file"
            step "Copied agent config to $target_file"
        fi
        return
    fi

    if [[ -f "$target_file" ]]; then
        # Merge using jq: deep merge agent entries
        local merged
        merged=$(jq -s '
            .[0] as $target | .[1] as $patch |
            $target * { agent: (($target.agent // {}) * ($patch.agent // {})) }
        ' "$target_file" "$patch_file")
        echo "$merged" > "$target_file"
        step "Merged agent config into $target_file"
    else
        cp "$patch_file" "$target_file"
        step "Created $target_file with agent config"
    fi
}

# --- Install functions ---
install_opencode() {
    header "OpenCode" "Installing..."

    # 1. Copy skills
    copy_directory "$REPO_ROOT/skills" "$TARGET_OPENCODE/skills"
    step "Copied skills/ -> $TARGET_OPENCODE/skills/"

    # 2. Copy agents
    copy_directory "$REPO_ROOT/editors/opencode/agents" "$TARGET_OPENCODE/agents"
    step "Copied agents/ -> $TARGET_OPENCODE/agents/"

    # 3. Copy commands
    copy_directory "$REPO_ROOT/editors/opencode/commands" "$TARGET_OPENCODE/commands"
    step "Copied commands/ -> $TARGET_OPENCODE/commands/"

    # 4. Merge config
    merge_opencode_config \
        "$REPO_ROOT/editors/opencode/opencode.agents.json" \
        "$TARGET_OPENCODE/opencode.json"

    echo -e "${GREEN}[OpenCode] Done!${NC}"
}

install_gemini() {
    header "Gemini CLI" "Installing..."

    # 1. Copy skills
    copy_directory "$REPO_ROOT/skills" "$TARGET_GEMINI/skills"
    step "Copied skills/ -> $TARGET_GEMINI/skills/"

    # 2. Append orchestrator rules to GEMINI.md
    local gemini_md="$TARGET_GEMINI/GEMINI.md"
    local orchestrator_md="$REPO_ROOT/editors/gemini/GEMINI_ORCHESTRATOR.md"

    if [[ ! -f "$orchestrator_md" ]]; then
        echo -e "  ${RED}Warning:${NC} Orchestrator file not found: $orchestrator_md"
    elif [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] Would append orchestrator rules to $gemini_md"
    else
        mkdir -p "$TARGET_GEMINI"
        if [[ -f "$gemini_md" ]] && grep -qF "$MARKER" "$gemini_md" 2>/dev/null; then
            info "Orchestrator rules already present in GEMINI.md, skipping append."
        else
            {
                echo ""
                echo ""
                echo "$MARKER"
                cat "$orchestrator_md"
                echo ""
            } >> "$gemini_md"
            step "Appended orchestrator rules to $gemini_md"
        fi
    fi

    # 3. Add skills table row
    local skills_row="| Multi-agent coordination, phased work, SDD routing | agent-team-orchestrator |"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY RUN] Would add skills table row to $gemini_md"
    elif [[ -f "$gemini_md" ]]; then
        if grep -qF "agent-team-orchestrator" "$gemini_md" 2>/dev/null; then
            info "Skills table row already present in GEMINI.md, skipping."
        elif grep -q "| Context" "$gemini_md" 2>/dev/null; then
            # Find the last table row and append after it
            # Use awk to insert after the last line starting with |
            local tmp_file
            tmp_file="$(mktemp)"
            awk -v row="$skills_row" '
                /^\|/ { last_table = NR; last_line = $0 }
                { lines[NR] = $0 }
                END {
                    for (i = 1; i <= NR; i++) {
                        print lines[i]
                        if (i == last_table) print row
                    }
                }
            ' "$gemini_md" > "$tmp_file"
            mv "$tmp_file" "$gemini_md"
            step "Added skills table row to GEMINI.md"
        else
            info "No skills table found in GEMINI.md. Add manually:"
            info "  $skills_row"
        fi
    else
        info "GEMINI.md not found at $gemini_md. Skills table row not added."
    fi

    echo -e "${GREEN}[Gemini CLI] Done!${NC}"
}

install_codex() {
    header "Codex" "Installing..."

    # 1. Copy skills
    copy_directory "$REPO_ROOT/skills" "$TARGET_CODEX_SKILLS/skills"
    step "Copied skills/ -> $TARGET_CODEX_SKILLS/skills/"

    # 2. Copy orchestrator instructions
    local instr_src="$REPO_ROOT/editors/codex/orchestrator-instructions.md"
    local instr_dst="$TARGET_CODEX_CONFIG/orchestrator-instructions.md"
    copy_file "$instr_src" "$instr_dst"
    step "Copied orchestrator-instructions.md -> $instr_dst"

    echo -e "${GREEN}[Codex] Done!${NC}"
    echo ""
    info "NOTE: You must manually add this to your Codex config.toml:"
    info '  [instructions]'
    info '  files = ["orchestrator-instructions.md"]'
    info "  Config location: $TARGET_CODEX_CONFIG/config.toml"
}

# --- Parse arguments ---
EDITOR=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --editor|-e)
            EDITOR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 --editor <opencode|gemini|codex|all> [--dry-run]"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 --editor <opencode|gemini|codex|all> [--dry-run]"
            exit 1
            ;;
    esac
done

# --- Main ---
resolve_repo_root

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN} PraxisGenAI Agent Orchestrator Installer${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo "Repo root: $REPO_ROOT"

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}[DRY RUN MODE] No files will be modified.${NC}"
fi

# If no editor specified (piped from curl), prompt user
if [[ -z "$EDITOR" ]]; then
    echo ""
    echo -e "${YELLOW}Which editor do you want to install for?${NC}"
    echo "  1) opencode"
    echo "  2) gemini"
    echo "  3) codex"
    echo "  4) all"
    echo ""
    read -rp "Enter choice (1-4): " choice
    case "$choice" in
        1|opencode)  EDITOR="opencode" ;;
        2|gemini)    EDITOR="gemini" ;;
        3|codex)     EDITOR="codex" ;;
        4|all)       EDITOR="all" ;;
        *)
            echo -e "${RED}Invalid choice: $choice${NC}"
            exit 1
            ;;
    esac
fi

# Validate editor choice
case "$EDITOR" in
    opencode|gemini|codex|all) ;;
    *)
        echo -e "${RED}Invalid editor: $EDITOR${NC}"
        echo "Valid options: opencode, gemini, codex, all"
        exit 1
        ;;
esac

case "$EDITOR" in
    opencode) install_opencode ;;
    gemini)   install_gemini ;;
    codex)    install_codex ;;
    all)
        install_opencode
        install_gemini
        install_codex
        ;;
esac

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
