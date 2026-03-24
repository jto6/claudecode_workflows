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

### Skills Directory Structure

Skills are multi-file AI assistant modules in the `skills/` directory. Each skill is a subdirectory containing a `SKILL.md` and any supporting files (Python modules, templates, etc.):

```
skills/
└── ti-pptx/            # /ti-pptx skill
    ├── SKILL.md
    ├── pptx_builder.py
    └── templates/
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

## Adding New Skills

When creating new skills:

1. **Create a subdirectory** in `skills/skill-name/` containing a `SKILL.md` file
2. **Use the frontmatter fields**: `name`, `description`, `version`, `author`, `source` (original URL if applicable)
3. **Add Python dependencies** to `reqs_for_skills.txt` if needed
4. **Re-run `./install.zsh`** to create the symlink at `~/.claude/skills/skill-name`
5. **Update this CLAUDE.md** and **README.md** with the new skill

## Existing Commands

- `/CA_init` - Comprehensive codebase analysis initialization
- `/commit` - Interactive atomic commit workflow with testing
- `/distill` - Extract core concepts from any source (URL, image, video, or text) into a concise markdown file
- `/drawio-to-svg` - Convert Draw.io files to SVG format with smart batch processing
- `/kb-import` - Import files or URLs to create rich markdown knowledge base files
- `/md-to-pdf` - Convert markdown files to professionally formatted PDFs

See individual command files in `commands/` directory for detailed usage instructions.

## Existing Skills

- `/ti-pptx` - Create TI-branded PowerPoint presentations using bundled templates and `TIPresentationBuilder`
  (originally from [TI AI Tools repo](https://bitbucket.itg.ti.com/projects/TI_AI/repos/util_claude_code_tiai/browse/collaterals/skills/ti-pptx))