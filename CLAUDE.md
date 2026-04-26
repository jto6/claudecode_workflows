# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This repository provides standardized Claude Code workflows and commands for consistent development practices across projects.

### Directory layout

```
claudecode_workflows/
├── commands/       # Slash command definitions (markdown) — used by Claude Code interactively
├── bin/            # CLI wrapper scripts — usable from the shell and by external tools
├── prompts/        # Reusable system prompt files — loaded by bin/ scripts for the fast path
├── skills/         # Multi-file AI assistant modules
├── hooks/          # Shell hooks (PostToolUse, PreToolUse, etc.)
├── templates/      # File templates (CSS for PDF, CLAUDE.md skeleton, etc.)
└── install.zsh     # Symlinks everything into ~/.claude/{commands,bin,skills,...}
```

### Commands directory

All slash commands are defined as individual markdown files in the `commands/` directory. `install.zsh` symlinks them into `~/.claude/commands/` so Claude Code can invoke them as `/command-name`.

```
commands/
├── CA_init.md          # /CA_init command
├── bulletize.md        # /bulletize command  ← references prompts/bulletize.md
├── commit.md           # /commit command
├── drawio-to-svg.md    # /drawio-to-svg command
├── kb-import.md        # /kb-import command
├── md-to-pdf.md        # /md-to-pdf command
└── text-clean.md       # /text-clean command  ← references prompts/text-clean*.md
```

### Bin directory

`bin/` contains shell scripts callable from the terminal. `install.zsh` symlinks them into `~/.claude/bin/` and makes them executable. Some `bin/` scripts have a **dual-path design**: they try a direct Anthropic API call (fast, ~1s) and fall back to `claude -p /<command>` (slow, ~10–15s) when no API access is configured.

```
bin/
├── clip            # clipboard helper: `clip read` / `clip write` (auto-detects wl-clipboard/xclip/pbcopy)
├── distill         # standalone wrapper — always runs slow path via `claude -p /distill`
├── llm-rewrite     # fast-path engine: stdin → Anthropic API → stdout (no clipboard knowledge)
├── text-clean      # router: fast path (llm-rewrite) or slow path (claude -p /text-clean)
└── bulletize       # router: fast path (llm-rewrite) or slow path (claude -p /bulletize)
```

**Fast vs. slow path routing** (applies to `text-clean` and `bulletize`):

| Condition                                                          | Path                           |
|--------------------------------------------------------------------|--------------------------------|
| `--slow` flag                                                      | slow                           |
| `--fast` flag                                                      | fast (errors if no API access) |
| Positional non-flag arg (file, URL, audio)                         | slow                           |
| `-summarize` (bulletize only)                                      | slow                           |
| `ANTHROPIC_API_KEY` or `ANTHROPIC_BASE_URL` set, no positional arg | fast                           |
| Otherwise                                                          | slow                           |

**`llm-rewrite` auth** (in priority order):

1. `ANTHROPIC_API_KEY` set → use directly
2. `ANTHROPIC_BASE_URL` set → call the `@ti/claude-code` Kerberos JWT token helper
3. Neither set → error

`ANTHROPIC_CUSTOM_HEADERS` (newline-separated `Name: Value` pairs) is forwarded as curl `-H` args.

### Prompts directory

`prompts/` contains self-contained system prompt files for the fast path. Each file ends with an "Output ONLY" instruction so the model returns bare text with no preamble.

```
prompts/
├── text-clean.md                   # technical tone (default)
├── text-clean.conversational.md    # conversational tone
├── text-clean.journal.md           # journal tone (less aggressive trimming)
└── bulletize.md                    # hierarchical bullet decomposition
```

The corresponding slash commands (`commands/text-clean.md`, `commands/bulletize.md`) now reference these files instead of inlining the rules, so both paths share the same rewriting rules.

### Skills Directory Structure

Skills are multi-file AI assistant modules in the `skills/` directory. Each skill is a subdirectory containing a `SKILL.md` and any supporting files (Python modules, templates, etc.):

```
skills/
├── ti-pptx/            # ti-pptx skill
│   ├── SKILL.md
│   ├── pptx_builder.py
│   └── templates/
└── vdk-tda54/          # vdk-tda54 skill
    ├── SKILL.md
    └── simprobe_boot_template.py
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

## Adding new things

### New slash command

1. Create `commands/<name>.md` (the slash command definition)
2. If it has rewrite rules shared with a fast-path bin script, extract them into `prompts/<name>.md`
3. Run `./install.zsh` to symlink it into `~/.claude/commands/`
4. Update the **Existing commands** list below and README.md

### New bin script

1. Create `bin/<name>` as an executable shell script
2. If it's a fast/slow router, follow the pattern in `bin/text-clean`: parse flags, check `ANTHROPIC_API_KEY`/`ANTHROPIC_BASE_URL`, dispatch to `llm-rewrite` or `claude -p`
3. Run `./install.zsh` — it `chmod +x`s and symlinks everything in `bin/` into `~/.claude/bin/`
4. Update the **Existing bin scripts** list below

### New skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter fields: `name`, `description`, `version`, `author`, `source`
2. Add Python dependencies to `reqs_for_skills.txt` if needed
3. Run `./install.zsh` to create the symlink at `~/.claude/skills/<skill-name>`
4. Update the **Existing skills** list below and README.md

## Existing commands

- `/bulletize` — convert clipboard text into hierarchical bullet points; `bin/bulletize` is the fast-path router
- `/CA_init` — comprehensive codebase analysis initialization
- `/commit` — interactive atomic commit workflow with testing
- `/distill` — extract core concepts from any source (URL, image, video, or text) into a concise markdown file
- `/drawio-to-svg` — convert Draw.io files to SVG format with smart batch processing
- `/kb-import` — import files or URLs to create rich markdown knowledge base files
- `/md-to-pdf` — convert markdown files to professionally formatted PDFs
- `/text-clean` — grammar, clarity, and conciseness editor; `bin/text-clean` is the fast-path router

## Existing bin scripts

- `clip` — clipboard helper: `clip read` / `clip write`; auto-detects wl-clipboard, xclip, pbcopy
- `bulletize` — fast/slow router for `/bulletize`; fast path uses `llm-rewrite` + `prompts/bulletize.md`
- `distill` — thin wrapper: always runs slow path via `claude -p /distill`
- `llm-rewrite` — fast-path engine: reads stdin, calls Anthropic API, writes stdout; see `bin/` section above for auth details
- `text-clean` — fast/slow router for `/text-clean`; fast path uses `llm-rewrite` + `prompts/text-clean*.md`

## Existing skills

- `/ti-pptx` — create TI-branded PowerPoint presentations using bundled templates and `TIPresentationBuilder`
  (originally from [TI AI Tools repo](https://bitbucket.itg.ti.com/projects/TI_AI/repos/util_claude_code_tiai/browse/collaterals/skills/ti-pptx))
- `vdk-tda54` — operate the TDA54 Synopsys Virtualizer VDK simulation: launch simulations, monitor UART
  output, configure core reset via simprobe, attach TRACE32/GDB debuggers, and SSH into the Linux guest