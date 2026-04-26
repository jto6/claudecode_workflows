# Bulletize — Convert Text to Hierarchical Bullet Points

Break text into one idea per bullet, with sub-bullets for supporting detail, clarification, conditionals, or elaboration. Bulletize never processes raw source material directly — text input is first cleaned via `/text-clean`, and audio/video input is first distilled via `/distill`. Bulletize then reformats the output of those commands into hierarchical bullet format.

## Usage

```
/bulletize [-conversational | -journal] [-mmap] [-summarize] [-outfile <path>] [<file path, audio/video file, URL, or inline text>]
```

- `-conversational` — optional flag; passed through to `/text-clean` for tone
- `-journal` — optional flag; passed through to `/text-clean` for personal, reflective tone
- `-mmap` — optional flag; omits the `- ` prefix from each line for pasting into a mind map file
- `-summarize` — optional flag; sends text input through `/distill` instead of `/text-clean`, extracting key ideas rather than cleaning prose. Always implied for audio/video input.
- `-outfile <path>` — optional; writes the bulletized text to the given file path instead of the clipboard. The next token after `-outfile` is consumed as the path.
- Input — a file path, an audio/video file path, a YouTube or audio URL, or inline text pasted after the command. **If no input is provided, the system clipboard is used as the input source.**

By default (no `-outfile`), the bulletized text is written back to the system clipboard via `~/.claude/bin/clip`, which preserves tab characters at the byte level.

## Instructions

### Step 0: Parse arguments

1. Inspect the leading flag tokens after `/bulletize` (any order, before any input). Recognized flags: `-conversational`, `-journal`, `-mmap`, `-summarize`, `-outfile`.
   - If `-conversational` is present, note it — it will be passed to the text-clean step.
   - If `-journal` is present, note it — it will be passed to the text-clean step.
   - If `-mmap` is present, set **mmap mode** on. In mmap mode, output lines have no `- ` prefix (only tab indentation and text).
   - If `-summarize` is present, set **summarize mode** on. Text input will be sent through `/distill` instead of `/text-clean`.
   - If `-outfile <path>` is present, consume the next token as the output file path. Set the output destination to that path (overrides the default of clipboard).
   - If `-outfile` is not given, the output destination is the system clipboard.
   - Treat everything else after the flags as input.
2. Determine the input source from whatever remains after the flags:
   - If nothing remains (no input argument): read the system clipboard with `~/.claude/bin/clip read > /tmp/bulletize-input.tmp` (Bash tool), then Read that file's contents as the input. Skip URL/audio/file detection. If summarize mode is on, proceed to Step 0.5; otherwise proceed to Step 1.
   - If the input starts with `http://` or `https://`: treat as a **URL** (YouTube video or audio URL). Proceed to Step 0.5.
   - If the input is a file path ending with an audio or video extension (`.mp3`, `.m4a`, `.wav`, `.flac`, `.ogg`, `.aac`, `.wma`, `.opus`, `.mp4`, `.mkv`, `.avi`, `.mov`, `.webm`, `.m4v`): treat as a **local audio/video file**. Proceed to Step 0.5.
   - If the input is a valid file path to a text file: read the file contents. If summarize mode is on, proceed to Step 0.5. Otherwise, proceed to Step 1.
   - Otherwise: treat the raw text as the input. If summarize mode is on, proceed to Step 0.5. Otherwise, proceed to Step 1.

### Step 0.5: Distill input

Use this step when:

- The input is a URL or local audio/video file (always), OR
- The `-summarize` flag was set (for any input type)

Run the `/distill` command on the input source. `/distill` will handle transcription (for audio/video) and produce a markdown file of key ideas and concepts. Read the markdown file that `/distill` produces, then proceed directly to Step 2 (skip Step 1).

### Step 1: Clean text input

**Skip this step if the input came through Step 0.5.** It has already been distilled.

For text file or inline text input: run the input through the `/text-clean` command logic first (with `-conversational` or `-journal` if either flag was set). This fixes grammar, improves clarity, and tightens the prose before bulletizing. Do not output the cleaned text — proceed directly to Step 2 with it.

### Step 2: Bulletize

Apply the system prompt at `prompts/bulletize.md` to the text. Read the prompt file to get the full formatting rules. The mmap-mode rule (omit `- ` prefix, output only tabs + text) applies when the `-mmap` flag was set.

### Step 3: Output

- Always write output to a file via the Write tool — never assemble it inline via heredoc or `echo`. Terminal echo can mangle tab characters; `~/.claude/bin/clip` and the Write tool both preserve tabs at the byte level.
- **Default (no `-outfile`)**: write the bulletized text to `/tmp/bulletized.md`, then copy it to the clipboard with `~/.claude/bin/clip write < /tmp/bulletized.md` (Bash tool). Confirm with: `Bulletized: clipboard`.
- **With `-outfile <path>`**: write the bulletized text directly to `<path>`. Confirm with: `Bulletized: <path>`.
- Write directly to the output path without asking for confirmation — overwrite any existing file.
- Do not print the bulletized text to the terminal. The file or clipboard is the output.

#### Rich-editor caveat for `-mmap` mode

In mmap mode the output is tab-indented with no `- ` prefix, so the structure depends on tab characters surviving into the destination. Tabs make it through plain-text editors (vim, VS Code, Sublime) and most mind-map import fields. Rich-text editors (Gmail rich compose, Outlook web, Confluence) often strip or reinterpret tabs. If the destination is a rich editor, prefer the default mode (with `- ` bullets), which renders as a proper bulleted list.
