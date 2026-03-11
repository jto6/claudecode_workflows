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
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

CLAUDE_SKILLS_VENV="$HOME/.venvs/claude-skills"

echo "🚀 Installing/Updating Claude Code workflows..."

# Create user directories
mkdir -p "$CLAUDE_USER_COMMANDS"
mkdir -p "$CLAUDE_USER_TEMPLATES"
mkdir -p "$CLAUDE_USER_HOOKS"

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

echo ""
echo "🎉 Claude Code workflows updated successfully!"
echo ""
echo "Global CLAUDE.md file updated with slash command instructions."
echo ""
echo "Available commands:"
echo "  /CA_init       - Initialize comprehensive codebase analysis"
echo "  /commit        - Standardized git commit workflow"
echo "  /drawio-to-svg - Convert Draw.io files to SVG with batch processing"
echo "  /kb-import     - Import files or URLs to create rich markdown knowledge base files"
echo "  /md-to-pdf     - Convert markdown files to PDF"
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