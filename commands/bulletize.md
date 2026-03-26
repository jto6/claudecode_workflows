# Bulletize — Convert Text to Hierarchical Bullet Points

Break text into one idea per bullet, with sub-bullets for supporting detail, clarification, conditionals, or elaboration. Input is first cleaned via `/text-clean` before bulletizing.

## Usage

```
/bulletize [-conversational | -journal] [-mmap] <file path, audio/video file, URL, or inline text>
```

- `-conversational` — optional flag; passed through to `/text-clean` for tone
- `-journal` — optional flag; passed through to `/text-clean` for personal, reflective tone
- `-mmap` — optional flag; omits the `- ` prefix from each line for pasting into a mind map file
- Input — a file path, an audio/video file path, a YouTube or audio URL, or inline text pasted after the command

## Instructions

### Step 0: Parse arguments

1. Check whether the first tokens after `/bulletize` are `-conversational`, `-journal`, or `-mmap` (in any order).
   - If `-conversational` is present, note it — it will be passed to the text-clean step.
   - If `-journal` is present, note it — it will be passed to the text-clean step.
   - If `-mmap` is present, set **mmap mode** on. In mmap mode, output lines have no `- ` prefix (only tab indentation and text).
   - Treat everything after the flags as input.
2. Determine the input source:
   - If the input starts with `http://` or `https://`: treat as a **URL** (YouTube video or audio URL). Proceed to Step 0.5.
   - If the input is a file path ending with an audio or video extension (`.mp3`, `.m4a`, `.wav`, `.flac`, `.ogg`, `.aac`, `.wma`, `.opus`, `.mp4`, `.mkv`, `.avi`, `.mov`, `.webm`, `.m4v`): treat as a **local audio/video file**. Proceed to Step 0.5.
   - If the input is a valid file path to a text file: read the file contents and proceed to Step 1.
   - Otherwise: treat the raw text as the input and proceed to Step 1.

### Step 0.5: Transcribe audio/video input

Use this step only when the input was identified as a URL or local audio/video file in Step 0. After transcription, treat the transcript as inline text and proceed to Step 1. Output will always be written to `/tmp/bulletized.md` for audio/URL inputs.

#### For a local audio/video file

Transcribe using Whisper via the Bash tool:

```
python3 -c "import whisper, warnings; warnings.filterwarnings('ignore'); model = whisper.load_model('base'); result = model.transcribe('<audio-file-path>'); print(result['text'])"
```

If `import whisper` fails, stop and report:

```
Error: openai-whisper is not available in the current Python environment.
To install it, add 'openai-whisper' to reqs_for_skills.txt in the claudecode_workflows
repo and re-run install.zsh, then restart Claude with the skills venv active.
```

Do not attempt to install packages inline.

#### For a URL

First, download the audio using yt-dlp via the Bash tool:

```
yt-dlp -x --audio-format mp3 -o "/tmp/yt_audio.%(ext)s" "<URL>"
```

If yt-dlp is not found or fails, stop and report:

```
Error: yt-dlp is not available. Install it with: pip install yt-dlp
```

Then transcribe the downloaded file (typically `/tmp/yt_audio.mp3`) using Whisper as described above for local files.

### Step 1: Clean the text

Run the input through the `/text-clean` command logic first (with `-conversational` or `-journal` if either flag was set). This fixes grammar, improves clarity, and tightens the prose before bulletizing. Do not output the cleaned text — proceed directly to Step 2 with it.

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
4. **Preserve all meaning.** Every piece of information from the original text must appear somewhere in the output. Do not drop details.
5. **Preserve chronological and logical order.** Bullets should follow the same sequence as the original text unless reordering clearly improves logical grouping.

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
