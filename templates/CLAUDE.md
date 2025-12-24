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

## General Formatting Guidelines

When editing a source file that uses tabs (vs spaces) for indention, preserve the use of tabs.

## Markdown Formatting Guidelines

### Overall structure

- Use only one H1 heading (#) for the document title. This means:
  - Use # Document Title for the main title
  - Use ## Section Headings for major sections
  - Use ### Subsection Headings for subsections

### Lists

- Always include a blank line *before* starting any list
- Do NOT include blank lines between list items
- For nested lists, use proper indentation (usually a tab)

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

### Tables

Use pipe tables for simple tabular data, but ensure proper formatting and consider width constraints.

#### Pipe Table Formatting

- Add spaces within cells so all vertical bar delimiters (`|`) align vertically across rows
- Each column should have consistent width with content left-padded or right-padded as appropriate
- The header separator row (`|---|`) should match the column widths

##### Incorrect (unaligned):

```
| Name | Description |
|------|-------------|
| **Short** | A brief item |
| **Much Longer Name** | This has more text |
```

##### Correct (aligned):

```
| Name                 | Description        |
|----------------------|--------------------|
| **Short**            | A brief item       |
| **Much Longer Name** | This has more text |
```

#### When to Use Grid Tables

If a properly formatted pipe table would exceed **70 characters in width**, use grid table format (emacs table.el style) instead. Grid tables support multi-line cells, allowing wide content to wrap and keep the table within the 70-character limit.

When converting to a grid table:

- Distribute column widths to fit within 70 characters total
- Wrap cell content across multiple lines as needed
- Choose column widths that make the table readable and professional
- Use `=` for the header separator row, `-` for all other row separators

#### Grid Table Format

Basic structure:

```
+------------+------------+------------+
| Header 1   | Header 2   | Header 3   |
+============+============+============+
| Cell 1     | Cell 2     | Cell 3     |
+------------+------------+------------+
| Cell 4     | Cell 5     | Cell 6     |
+------------+------------+------------+
```

With multi-line cells (for wrapping wide content):

```
+----------------------+----------------------------------------------+
| Specification Area   | Relevance to Part 1                          |
+======================+==============================================+
| **SWS OS**           | Task configuration, scheduling, interrupt    |
|                      | handling, alarms, and counters               |
+----------------------+----------------------------------------------+
| **SWS MCU Driver**   | Clock configuration, reset handling,         |
|                      | low-power modes                              |
+----------------------+----------------------------------------------+
```

### ASCII Art Diagrams

When creating ASCII art box diagrams (using characters like `┌`, `─`, `┐`, `│`, `└`, `┘`):

- All lines within a box diagram must have identical **display width**
- Pad inner lines with spaces so the right border `│` aligns perfectly with the outer box edges
- The top border line (`┌───...───┐`) sets the target width - all other lines must match exactly
- For nested boxes, ensure the inner box plus surrounding padding equals the outer box width

#### Important: Unicode Characters are Multi-Byte

Box-drawing characters (`┌`, `─`, `│`, etc.) are Unicode and occupy 3 bytes each but display as 1 character width. Standard tools like `awk '{print length}'` count bytes, not display width, giving incorrect results.

#### Verification Method

After creating or editing a diagram, verify alignment using this Python script:

```python
python3 -c "
import unicodedata
def display_width(s):
    return sum(2 if unicodedata.east_asian_width(c) in ('F','W') else 1 for c in s)
with open('FILENAME', 'r') as f:
    for i, line in enumerate(f, 1):
        line = line.rstrip('\n')
        if line and line[0] in '┌├│└':
            print(f'{display_width(line):3d}: {line}')
"
```

All box lines should show the same width number. If any differ, add or remove spaces before the closing `│` to fix alignment.

#### Example of Correct Alignment:

```
┌─────────────────────────────────────────┐
│           PROPERLY ALIGNED BOX          │
├─────────────────────────────────────────┤
│                                         │
│  Content line 1                         │
│  Content line 2 (longer text here)      │
│  Short                                  │
│                                         │
└─────────────────────────────────────────┘
```

Every line above has exactly 43 display width, with padding added before the closing `│`.
