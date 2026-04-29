#!/usr/bin/env zsh

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or sudo apt install jq (Ubuntu)"
    exit 1
fi

REPO_PATH="${0:A:h}"
CLAUDE_USER_COMMANDS="$HOME/.claude/commands"
CLAUDE_USER_TEMPLATES="$HOME/.claude/templates"
CLAUDE_USER_HOOKS="$HOME/.claude/hooks"
CLAUDE_USER_SKILLS="$HOME/.claude/skills"
CLAUDE_USER_BIN="$HOME/.claude/bin"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_SETTINGS_LOCAL="$HOME/.claude/settings.local.json"

CLAUDE_SKILLS_VENV="$HOME/.venvs/claude-skills"

echo "🚀 Installing/Updating Claude Code workflows..."

# Create user directories
mkdir -p "$CLAUDE_USER_COMMANDS"
mkdir -p "$CLAUDE_USER_TEMPLATES"
mkdir -p "$CLAUDE_USER_HOOKS"
mkdir -p "$CLAUDE_USER_SKILLS"
mkdir -p "$CLAUDE_USER_BIN"

# Create Python virtual environment for skills dependencies
if [[ -f "$REPO_PATH/reqs_for_skills.txt" ]]; then
    if [[ ! -d "$CLAUDE_SKILLS_VENV" ]]; then
        echo "📦 Creating Python virtual environment for skills..."
        python3 -m venv "$CLAUDE_SKILLS_VENV"
        echo "✅ Created venv at $CLAUDE_SKILLS_VENV"
    else
        echo "🔄 Updating Python virtual environment for skills..."
    fi
    "$CLAUDE_SKILLS_VENV/bin/pip" install --quiet -r "$REPO_PATH/reqs_for_skills.txt"
    echo "✅ Installed Python dependencies for skills"
fi

# Create symlinks to commands (so they auto-update with git pulls)
for cmd_file in "$REPO_PATH/commands"/*.md; do
    if [[ -f "$cmd_file" ]]; then
        cmd_name=$(basename "$cmd_file")
        if [[ -L "$CLAUDE_USER_COMMANDS/$cmd_name" ]]; then
            echo "🔄 Updated /$cmd_name command"
        else
            echo "✅ Linked /$cmd_name command"
        fi
        ln -sf "$cmd_file" "$CLAUDE_USER_COMMANDS/$cmd_name"
    fi
done

# Create symlinks to bin scripts (so they auto-update with git pulls)
for bin_file in "$REPO_PATH/bin"/*; do
    if [[ -f "$bin_file" ]]; then
        bin_name=$(basename "$bin_file")
        chmod +x "$bin_file"
        if [[ -L "$CLAUDE_USER_BIN/$bin_name" ]]; then
            echo "🔄 Updated bin: $bin_name"
        else
            echo "✅ Linked bin: $bin_name"
        fi
        ln -sf "$bin_file" "$CLAUDE_USER_BIN/$bin_name"
    fi
done

# Create symlink to default CSS file for md-to-pdf
if [[ -f "$REPO_PATH/css/pdf-style.css" ]]; then
    ln -sf "$REPO_PATH/css/pdf-style.css" "$CLAUDE_USER_TEMPLATES/pdf-style.css"
    echo "✅ Linked default PDF styling template"
fi

# Install global CLAUDE.md instructions
if [[ -f "$REPO_PATH/templates/CLAUDE.md" ]]; then
    if [[ -L "$HOME/.claude/CLAUDE.md" ]]; then
        echo "🔄 Updated global Claude Code instructions"
    else
        echo "✅ Installed global Claude Code instructions"
    fi
    ln -sf "$REPO_PATH/templates/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
fi

# Create symlinks to hook scripts (so they auto-update with git pulls)
for hook_file in "$REPO_PATH/hooks"/*.sh; do
    if [[ -f "$hook_file" ]]; then
        hook_name=$(basename "$hook_file")
        chmod +x "$hook_file"
        if [[ -L "$CLAUDE_USER_HOOKS/$hook_name" ]]; then
            echo "🔄 Updated hook: $hook_name"
        else
            echo "✅ Linked hook: $hook_name"
        fi
        ln -sf "$hook_file" "$CLAUDE_USER_HOOKS/$hook_name"
    fi
done

# Merge hooks configuration if settings.json exists
if [[ -f "$REPO_PATH/hooks/settings_template.json" ]]; then
    if [[ -f "$CLAUDE_SETTINGS" ]]; then
        # Backup existing settings
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup"
        # Merge with new settings
        jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$REPO_PATH/hooks/settings_template.json" > "$CLAUDE_SETTINGS.tmp"
        mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
        echo "✅ Merged workflow hooks (backup created)"
    else
        cp "$REPO_PATH/hooks/settings_template.json" "$CLAUDE_SETTINGS"
        echo "✅ Created workflow hooks configuration"
    fi
fi

# Apply environment-specific settings into settings.json
echo ""
echo "⚙️  Select environment:"
echo "  1) TI (work) — adds Opus 4.7 → 4.6 model remap for TI gateway"
echo "  2) Home"
echo "  3) Skip"
read "env_choice?Enter choice [1/2/3]: "
case "$env_choice" in
    1) jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$REPO_PATH/hooks/settings.env.ti.json" > "$CLAUDE_SETTINGS.tmp"
       mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
       echo "✅ Applied TI environment settings" ;;
    2) echo "✅ Home environment — no additional settings needed" ;;
    *) echo "⏭️  Skipped environment selection" ;;
esac

# Create settings.local.json for new machines
if [[ ! -f "$CLAUDE_SETTINGS_LOCAL" ]]; then
    cp "$REPO_PATH/hooks/settings.local.template.json" "$CLAUDE_SETTINGS_LOCAL"
    echo "✅ Created settings.local.json from template"
else
    echo "⏭️  settings.local.json already exists, skipping"
fi

# Create symlinks to skills (directories, so they auto-update with git pulls)
for skill_dir in "$REPO_PATH/skills"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        target="$CLAUDE_USER_SKILLS/$skill_name"
        if [[ -d "$target" && ! -L "$target" ]]; then
            mv "$target" "${target}.backup"
            echo "⚠️  Backed up existing $skill_name/ to ${target}.backup"
        fi
        ln -sfn "$skill_dir" "$target"
        if [[ -L "$target" ]]; then
            echo "🔄 Updated skill: $skill_name"
        else
            echo "✅ Linked skill: $skill_name"
        fi
    fi
done

# --- Local-backend (Ollama) setup for llm-rewrite ----------------------------
# llm-rewrite's `--backend local` mode picks the best installed Ollama model
# from a preference ladder at runtime, so all this script needs to do is pull
# a model appropriate for the local GPU's VRAM.
_pick_default_model() {
    local vram_mib=0
    if command -v nvidia-smi &>/dev/null; then
        vram_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null \
                   | head -1 | tr -d ' ' || echo 0)
        [[ -z "$vram_mib" || "$vram_mib" == *[!0-9]* ]] && vram_mib=0
    fi
    if   (( vram_mib >= 16000 )); then echo "qwen2.5:14b-instruct-q4_K_M"
    elif (( vram_mib >= 6000  )); then echo "qwen2.5:7b-instruct-q4_K_M"
    else                               echo "llama3.2:3b-instruct-q4_K_M"
    fi
}

if command -v ollama &>/dev/null; then
    DEFAULT_MODEL=$(_pick_default_model)
    if curl -sS --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
        if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$DEFAULT_MODEL"; then
            echo "✅ Ollama model already installed: $DEFAULT_MODEL"
        else
            echo "📥 Pulling Ollama model: $DEFAULT_MODEL (this may take a few minutes)"
            if ollama pull "$DEFAULT_MODEL"; then
                echo "✅ Pulled $DEFAULT_MODEL"
            else
                echo "⚠️  Failed to pull $DEFAULT_MODEL — run 'ollama pull $DEFAULT_MODEL' manually"
            fi
        fi
    else
        echo "⚠️  Ollama daemon not reachable at localhost:11434 — start it, then run:"
        echo "      ollama pull $DEFAULT_MODEL"
    fi
else
    echo "ℹ️  ollama not found on PATH. The local backend (--backend local) will not work."
    echo "   Install Ollama from https://ollama.com/ if you want offline rewrites."
fi
# -----------------------------------------------------------------------------

echo ""
echo "🎉 Claude Code workflows updated successfully!"
echo ""
echo "Global CLAUDE.md file updated with slash command instructions."
echo ""
echo "Available commands:"
echo "  /bolden-import - Import Bolden retirement planning data"
echo "  /bulletize     - Convert text to hierarchical bullet points"
echo "  /CA_init       - Initialize comprehensive codebase analysis"
echo "  /commit        - Standardized git commit workflow"
echo "  /distill       - Extract core concepts from any source into markdown"
echo "  /drawio-to-svg - Convert Draw.io files to SVG with batch processing"
echo "  /kb-import     - Import files or URLs to create rich markdown knowledge base files"
echo "  /md-to-pdf     - Convert markdown files to PDF"
echo "  /text-clean    - Rewrite text for grammar, clarity, and conciseness"
echo ""
echo "Available skills:"
echo "  /ti-pptx       - Create TI-branded PowerPoint presentations"
echo ""
echo "Python skills venv: $CLAUDE_SKILLS_VENV"
echo ""
echo "To make the venv available to claude, add this to your ~/.zshrc:"
echo ""
echo '  claude() {'
echo '      ('
echo '          source "$HOME/.venvs/claude-skills/bin/activate"'
echo '          command claude "$@"'
echo '      )'
echo '  }'
echo ""
echo "To update: cd $(dirname $0) && git pull"