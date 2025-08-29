# Claude Code Workflows

Standardized Claude Code commands and workflows for consistent development practices across projects and users.

## Overview

This repository provides:
- **Custom slash commands** for common development workflows
- **Hooks configuration** for enhanced Claude Code behavior  
- **Auto-updating templates** that stay current with git pulls

## Installation

1. Clone this repository to a persistent location:
```bash
git clone git@github.com:jto6/claudecode_workflows.git ~/.claude/workflows
cd ~/.claude/workflows
```

2. Run the install script:
```bash
chmod +x install.zsh
./install.zsh
```

3. The installer will:
   - Create symlinks to commands in `~/.claude/commands/`
   - Merge hooks configuration into `~/.claude/settings.json`
   - Backup your existing settings

## Available Commands

### `/CA_init` - Comprehensive Codebase Analysis
Initializes a thorough analysis of any codebase by creating a structured `code_analysis.md` file.

**What it does:**
- High-level architecture survey
- Component mapping and dependencies
- Technology stack identification
- Design pattern analysis
- Entry points and data flow mapping
- Build and development workflow documentation
- Code quality assessment

**Usage:** Simply type `/CA_init` in any Claude Code session.

### `/commit` - Standardized Git Commit Workflow
Executes a comprehensive git commit workflow with proper analysis and validation.

**What it does:**
- Pre-commit analysis (status, diffs, history)
- Code quality checks (linting, type checking, tests)
- Commit message analysis and formatting
- Security review for sensitive data
- Commit execution with validation
- Post-commit verification

**Usage:** Type `/commit` when ready to commit changes.

### `/drawio-to-svg` - Draw.io to SVG Converter
Converts Draw.io (.drawio) files to SVG format with intelligent batch processing.

**What it does:**
- Converts individual .drawio files to .svg in the same directory
- Batch processes directories, only converting when needed (missing or outdated SVG files)
- Repository-wide search when no arguments provided
- Smart file comparison based on modification timestamps
- Comprehensive error handling and progress feedback

**Usage:** 
- Single file: `/drawio-to-svg diagram.drawio`
- Directory: `/drawio-to-svg docs/diagrams/`  
- Repository-wide: `/drawio-to-svg`

### `/md-to-pdf` - Markdown to PDF Converter
Converts markdown files to professionally formatted PDFs with consistent styling.

**What it does:**
- Converts markdown to PDF using pandoc and wkhtmltopdf
- Automatically detects and uses appropriate CSS styling
- Applies Times New Roman font with proper margins
- Adds page numbering and professional formatting
- Supports both local and fallback CSS files

**Usage:** Type `/md-to-pdf filename.md` to convert any markdown file to PDF.

## Updating Workflows

To get the latest workflow updates:
```bash
cd ~/.claude/workflows
git pull
```

No reinstallation needed - symlinks automatically use the updated templates.

## Configuration

The workflows install hooks that provide:
- **Tool execution feedback** - Shows what commands are being run
- **File modification alerts** - Reminds to run tests after edits
- **Session context** - Displays current project directory

Hooks configuration is in `hooks/settings_template.json` and gets merged with your existing Claude Code settings.

## Repository Structure

```
claude_code_workflows/
├── README.md
├── install.zsh                    # Installation script
├── commands/                      # Slash command templates
│   ├── CA_init.md                # Codebase analysis workflow
│   ├── commit.md                 # Git commit workflow
│   ├── drawio-to-svg.md          # Draw.io to SVG converter
│   └── md-to-pdf.md              # Markdown to PDF converter
└── hooks/                        # Claude Code configuration
    └── settings_template.json    # Hooks and permissions
```

## Requirements

- **jq** - JSON processor for settings management
  - macOS: `brew install jq`
  - Ubuntu: `sudo apt install jq`
- **Claude Code** - Latest version recommended

## Customization

### Adding New Commands
1. Create a new `.md` file in `commands/`
2. Re-run `./install.zsh` to create the symlink
3. Commit and push for others to get the new command

### Modifying Hooks
1. Edit `hooks/settings_template.json`
2. Re-run `./install.zsh` to update user settings
3. See [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks) for syntax

### Command Template Format
Commands use markdown format with instructions for Claude Code:
```markdown
# Command Title - /command_name

Description of what this command does.

## Instructions

Detailed instructions for Claude Code to execute...
```

## Troubleshooting

### Commands Not Available
- Verify symlinks exist: `ls -la ~/.claude/commands/`
- Check Claude Code is reading user commands: `claude config get`

### Hooks Not Working  
- Verify settings merge: `cat ~/.claude/settings.json`
- Check for JSON syntax errors with: `jq . ~/.claude/settings.json`

### Installation Issues
- Ensure jq is installed and available in PATH
- Check file permissions on install script: `chmod +x install.zsh`
- Verify Claude Code directories exist: `ls ~/.claude/`

## Contributing

1. Fork this repository
2. Create new commands or improve existing ones
3. Test with your workflows
4. Submit pull request with description of changes

## License

MIT License - Feel free to adapt for your organization's needs.
