# Bulletize — Convert Text to Hierarchical Bullet Points

Break text into one idea per bullet, with sub-bullets for supporting detail, clarification, conditionals, or elaboration. Bulletize never processes raw source material directly — text input is first cleaned via `/text-clean`, and audio/video input is first distilled via `/distill`. Bulletize then reformats the output of those commands into hierarchical bullet format.

## Usage

```
/bulletize [-conversational | -journal] [-mmap] [-summarize] <file path, audio/video file, URL, or inline text>
```

- `-conversational` — optional flag; passed through to `/text-clean` for tone
- `-journal` — optional flag; passed through to `/text-clean` for personal, reflective tone
- `-mmap` — optional flag; omits the `- ` prefix from each line for pasting into a mind map file
- `-summarize` — optional flag; sends text input through `/distill` instead of `/text-clean`, extracting key ideas rather than cleaning prose. Always implied for audio/video input.
- Input — a file path, an audio/video file path, a YouTube or audio URL, or inline text pasted after the command

## Instructions

### Step 0: Parse arguments

1. Check whether the first tokens after `/bulletize` are `-conversational`, `-journal`, `-mmap`, or `-summarize` (in any order).
   - If `-conversational` is present, note it — it will be passed to the text-clean step.
   - If `-journal` is present, note it — it will be passed to the text-clean step.
   - If `-mmap` is present, set **mmap mode** on. In mmap mode, output lines have no `- ` prefix (only tab indentation and text).
   - If `-summarize` is present, set **summarize mode** on. Text input will be sent through `/distill` instead of `/text-clean`.
   - Treat everything after the flags as input.
2. Determine the input source:
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

Transform the cleaned text into hierarchical bullet format following these rules:

#### Format

- Every line starts with zero or more tab characters for indentation, then (unless mmap mode is active) `- `, then the text.
- **No space characters for indentation. Only tab characters.** Top-level bullets begin at column 0 with no leading whitespace. Sub-levels use exactly one tab per level. Never use spaces to indent.
- One tab per indentation level. Top-level bullets have no tabs. First sub-level has one tab. Second sub-level has two tabs, and so on.
- No blank lines between bullets.

#### mmap mode (`-mmap`)

When the `-mmap` flag is set, omit the `- ` prefix entirely. Each line is just tabs (for indentation level) followed by the text. This produces a plain tab-indented outline suitable for pasting into a mind map tool.

#### Decomposition rules

1. **One idea per bullet.** Each bullet contains exactly one idea, concept, or point. If a sentence has multiple ideas joined by conjunctions, commas, or semicolons, split them.
2. **Supporting detail becomes sub-bullets.** Description, clarification, conditionals, examples, elaboration, or further detail of a parent idea goes on separate indented lines beneath it.
3. **Apply recursively.** If a sub-bullet itself contains an idea with additional decoration, that decoration becomes a sub-bullet of the sub-bullet, and so on. Keep going until each bullet is a single atomic thought.
4. **Preserve all meaning.** Every piece of information from the input must appear somewhere in the output. Do not drop details. (For audio/video input, `/distill` has already extracted the key ideas — preserve everything in the distilled output.)
5. **Preserve chronological and logical order.** Bullets should follow the same sequence as the input unless reordering clearly improves logical grouping.

#### Example (default mode)

Input:

```
Today was an interesting day. I had just a few meetings early in the morning
and then nothing for the rest of the day, so I was looking at 5 1/2 to 6 hours
and taking 60% judgement, four hours of concentrated work time, so I was pretty
excited about that. I am surprised it took the entire afternoon to go over both,
but it was a time well spent because we worked through a lot of nitty-gritty
details, especially in the flow chart for handling customer defects.
```

Output:

```
- Today was an interesting day
	- I had just a few meetings early in the morning and then nothing for the rest of the day
		- so I was looking at 5 1/2 to 6 hours and taking 60% judgement, four hours of concentrated work time
		- I was pretty excited about that
- I am surprised it took the entire afternoon to go over both
	- it was a time well spent because we worked through a lot of nitty-gritty details
		- especially in the flow chart for handling customer defects
```

#### Example (mmap mode)

Same input with `-mmap`:

```
Today was an interesting day
	I had just a few meetings early in the morning and then nothing for the rest of the day
		so I was looking at 5 1/2 to 6 hours and taking 60% judgement, four hours of concentrated work time
		I was pretty excited about that
I am surprised it took the entire afternoon to go over both
	it was a time well spent because we worked through a lot of nitty-gritty details
		especially in the flow chart for handling customer defects
```

### Step 3: Output

- **Always write output to a file** using the Write tool. Terminal copy-paste destroys tab characters, so file output is required to preserve exact indentation.
- If the input was a text file path, write the bulletized text back to the same file.
- Otherwise (inline text, audio file, or URL), write the bulletized text to `/tmp/bulletized.md`.
- Write directly to the output path without asking for confirmation — overwrite any existing file.
- After writing, confirm with a single line: `Bulletized: <file path>`
- Do not print the bulletized text to the terminal. The file is the output.
