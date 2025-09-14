# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This repository provides standardized Claude Code workflows and commands for consistent development practices across projects.

### Commands Directory Structure

All slash commands are defined as individual markdown files in the `commands/` directory following this pattern:

```
commands/
├── CA_init.md          # /CA_init command
├── commit.md           # /commit command
├── drawio-to-svg.md    # /drawio-to-svg command
├── kb-import.md        # /kb-import command
└── md-to-pdf.md        # /md-to-pdf command
```

### Command File Format

Each command file follows this markdown structure:

```markdown
# Command Title - /command_name

Brief description of what this command does.

## Usage
/command_name [arguments]

## Description
Detailed explanation of functionality...

## Implementation
Technical details and code blocks...

## Examples
Usage examples...

## Dependencies
Required tools/packages...
```

## Adding New Commands

When creating new commands:

1. **Always create the command file** in `commands/` directory first
2. **Follow the established naming pattern**: `command-name.md` 
3. **Use the markdown template** shown above for consistency
4. **Update this CLAUDE.md file** to reference the new command
5. **Update README.md** with the new command description
6. **Update repository structure** in README.md if needed

**NEVER** put command implementation directly in CLAUDE.md - always create separate files in `commands/` directory to match the existing pattern.

## Existing Commands

- `/CA_init` - Comprehensive codebase analysis initialization
- `/commit` - Interactive atomic commit workflow with testing
- `/drawio-to-svg` - Convert Draw.io files to SVG format with smart batch processing
- `/kb-import` - Import files or URLs to create rich markdown knowledge base files
- `/md-to-pdf` - Convert markdown files to professionally formatted PDFs

See individual command files in `commands/` directory for detailed usage instructions.