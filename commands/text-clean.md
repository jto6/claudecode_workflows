# Text Clean — Grammar, Clarity, and Conciseness Editor

Rewrite text for correct grammar, clear organization, clarity, and conciseness — similar to what Grammarly does, but with structural reorganization when needed.

## Usage

```
/text-clean [-conversational | -journal] [-outfile <path>] [<file path, audio/video file, URL, or inline text>]
```

- `-conversational` — optional flag; switches tone from technical (default) to conversational
- `-journal` — optional flag; uses a personal, reflective tone that preserves thought patterns and emotions
- `-outfile <path>` — optional; writes the cleaned text to the given file path instead of the clipboard. The next token after `-outfile` is consumed as the path.
- Input — a file path, an audio/video file path, a YouTube or audio URL, or inline text pasted after the command. **If no input is provided, the system clipboard is used as the input source.**

By default (no `-outfile`), the cleaned text is written back to the system clipboard via `~/.claude/bin/clip`, which preserves whitespace at the byte level.

## Instructions

### Step 0: Parse arguments

1. Inspect the leading flag tokens after `/text-clean` (any order, before any input):
   - `-conversational` → set tone to **conversational**
   - `-journal` → set tone to **journal**
   - `-outfile <path>` → consume the next token as the output file path. Set the output destination to that path (overrides the default of clipboard).
   - If no tone flag is set, default tone is **technical**.
   - If `-outfile` is not given, the output destination is the system clipboard.
2. Determine the input source from whatever remains after the flags:
   - If nothing remains (no input argument): read the system clipboard with `~/.claude/bin/clip read > /tmp/text-clean-input.tmp` (Bash tool), then Read that file's contents as the input. Skip URL/audio/file detection. Proceed to Step 1.
   - If the input starts with `http://` or `https://`: treat as a **URL** (YouTube video or audio URL). Proceed to Step 0.5.
   - If the input is a file path ending with an audio or video extension (`.mp3`, `.m4a`, `.wav`, `.flac`, `.ogg`, `.aac`, `.wma`, `.opus`, `.mp4`, `.mkv`, `.avi`, `.mov`, `.webm`, `.m4v`): treat as a **local audio/video file**. Proceed to Step 0.5.
   - If the input is a valid file path to a text file: read the file contents and proceed to Step 1.
   - Otherwise: treat the raw text as the input and proceed to Step 1.

### Step 0.5: Transcribe audio/video input

Use this step only when the input was identified as a URL or local audio/video file in Step 0. After transcription, treat the transcript as inline text and proceed to Step 1.

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

### Step 1: Rewrite the text

Apply the system prompt at `prompts/text-clean.md` (default technical tone), `prompts/text-clean.conversational.md` (for `-conversational`), or `prompts/text-clean.journal.md` (for `-journal`) to the input text. Read the appropriate prompt file to get the full rewriting rules.

### Step 2: Output

- Always write output to a file via the Write tool — never assemble it inline via heredoc or `echo`.
- **Default (no `-outfile`)**: write the cleaned text to `/tmp/text-cleaned.md`, then copy it to the clipboard with `~/.claude/bin/clip write < /tmp/text-cleaned.md` (Bash tool). Confirm with: `Cleaned: clipboard`.
- **With `-outfile <path>`**: write the cleaned text directly to `<path>`. Confirm with: `Cleaned: <path>`.
- Write directly to the output path without asking for confirmation — overwrite any existing file.
- Do not print the cleaned text to the terminal. The file or clipboard is the output.
