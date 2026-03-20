#!/usr/bin/env bash
# PostToolUse hook: run md-lint on any markdown file that was just written or edited.
# Only prints output if violations are found (silent on clean files).
#
# Requires: utility-scripts repo at $HOME/dev/utility-scripts/
# See: https://github.com/jonimake/utility-scripts (or local equivalent)

LINTER="python3 $HOME/dev/utility-scripts/formatting/md-lint.py"

# Extract file_path from the tool input JSON passed via TOOL_INPUT env var,
# or fall back to the first CLI argument (for manual invocation).
if [[ $# -ge 1 ]]; then
    FILE_PATH="$1"
else
    FILE_PATH=$(python3 -c "
import json, os, sys
try:
    inp = json.loads(os.environ.get('TOOL_INPUT', '{}'))
    print(inp.get('file_path', ''))
except Exception:
    print('')
")
fi

# Only proceed for markdown files.
if [[ "$FILE_PATH" != *.md && "$FILE_PATH" != *.markdown ]]; then
    exit 0
fi

# Only proceed if the linter exists.
if ! python3 -c "import pathlib; exit(0 if pathlib.Path('$HOME/dev/utility-scripts/formatting/md-lint.py').exists() else 1)" 2>/dev/null; then
    exit 0
fi

# Run linter; only emit output if there are violations.
OUTPUT=$($LINTER "$FILE_PATH" 2>&1)
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    echo ""
    echo "⚠️  md-lint: violations found in $FILE_PATH"
    echo "$OUTPUT"
    exit 1
fi

exit 0
