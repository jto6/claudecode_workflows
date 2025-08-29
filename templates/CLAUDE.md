# Claude Code Global Instructions

**IMPORTANT: Always check ~/.claude/commands directory for custom slash commands before attempting to execute them as bash commands. Slash commands (starting with /) are Claude Code custom commands, not bash commands.**

When encountering any command starting with `/`, first read the corresponding `.md` file in `~/.claude/commands/` to understand the proper usage and implementation before executing.

## Available Custom Commands

Custom slash commands are installed in `~/.claude/commands/`. These are NOT bash commands and should be executed as Claude Code slash commands.

To see all available commands, check: `ls ~/.claude/commands/`

## Workflow Instructions

1. Before executing any `/command`, read its implementation from `~/.claude/commands/command.md`
2. Follow the specific instructions provided in each command file
3. These commands are designed to work across all repositories and projects