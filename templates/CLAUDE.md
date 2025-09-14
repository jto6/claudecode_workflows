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

## Markdown Formatting Guidelines

### Overall structure

- Use only one H1 heading (#) for the document title. This means:
  - Use # Document Title for the main title
  - Use ## Section Headings for major sections
  - Use ### Subsection Headings for subsections

### Lists

- Always include a blank line *before* starting any list
- Do NOT include blank lines between list items
- For nested lists, use proper indentation (usually 2 or 4 spaces)

#### Examples

##### Correct:
This is a paragraph.

- Item 1
- Item 2
- Item 3

##### Incorrect:
This is a paragraph.
- Item 1
- Item 2
- Item 3

##### Incorrect:
This is a paragraph.

- Item 1

- Item 2

- Item 3
