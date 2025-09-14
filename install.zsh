#!/usr/bin/env zsh

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or sudo apt install jq (Ubuntu)"
    exit 1
fi

REPO_PATH="${0:A:h}"
CLAUDE_USER_COMMANDS="$HOME/.claude/commands"
CLAUDE_USER_TEMPLATES="$HOME/.claude/templates"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo "🚀 Installing/Updating Claude Code workflows..."

# Create user directories
mkdir -p "$CLAUDE_USER_COMMANDS"
mkdir -p "$CLAUDE_USER_TEMPLATES"

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
echo "To update: cd $(dirname $0) && git pull"