#!/usr/bin/env bash
# PostToolUse hook: run md-lint on any markdown file that was just written or edited.
# Feeds violations back to Claude via exit 2 + stderr JSON systemMessage.
# Silent (exit 0) when the file is clean or not a markdown file.
#
# Requires: utility-scripts repo at $HOME/dev/utility-scripts/
# See: https://github.com/jonimake/utility-scripts (or local equivalent)

LINTER="python3 $HOME/dev/utility-scripts/formatting/md-lint.py"

# Extract file_path from the tool input JSON delivered via stdin by Claude Code,
# or fall back to the first CLI argument (for manual invocation).
if [[ $# -ge 1 ]]; then
    FILE_PATH="$1"
else
    FILE_PATH=$(python3 -c "
import json, sys
try:
    inp = json.loads(sys.stdin.read() or '{}')
    print(inp.get('tool_input', {}).get('file_path', ''))
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

# Run linter; feed violations back to Claude via exit 2 + JSON systemMessage on stderr.
OUTPUT=$($LINTER "$FILE_PATH" 2>&1)
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    # Build JSON response so Claude sees violations in its context (exit 2 + stderr).
    python3 -c "
import json, sys
msg = 'md-lint violations found in $FILE_PATH — fix these before finishing:\n' + sys.stdin.read()
print(json.dumps({'continue': True, 'suppressOutput': False, 'systemMessage': msg}))
" <<< "$OUTPUT" >&2
    exit 2
fi

exit 0
