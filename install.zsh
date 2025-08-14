#!/usr/bin/env zsh

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or sudo apt install jq (Ubuntu)"
    exit 1
fi

REPO_PATH="${0:A:h}"
CLAUDE_USER_COMMANDS="$HOME/.claude/commands"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo "🚀 Installing Claude Code workflows..."

# Create user commands directory
mkdir -p "$CLAUDE_USER_COMMANDS"

# Create symlinks to commands (so they auto-update with git pulls)
for cmd_file in "$REPO_PATH/commands"/*.md; do
    if [[ -f "$cmd_file" ]]; then
        cmd_name=$(basename "$cmd_file")
        ln -sf "$cmd_file" "$CLAUDE_USER_COMMANDS/$cmd_name"
        echo "✅ Linked /$cmd_name command"
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
echo "🎉 Claude Code workflows installed successfully!"
echo ""
echo "Available commands:"
echo "  /CA_init  - Initialize comprehensive codebase analysis"
echo "  /commit   - Standardized git commit workflow"
echo ""
echo "To update: cd $(dirname $0) && git pull"