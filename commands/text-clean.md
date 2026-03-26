# Text Clean — Grammar, Clarity, and Conciseness Editor

Rewrite text for correct grammar, clear organization, clarity, and conciseness — similar to what Grammarly does, but with structural reorganization when needed.

## Usage

```
/text-clean [-conversational | -journal] <file path, audio/video file, URL, or inline text>
```

- `-conversational` — optional flag as the first argument; switches tone from technical (default) to conversational
- `-journal` — optional flag as the first argument; uses a personal, reflective tone that preserves thought patterns and emotions
- Input — a file path, an audio/video file path, a YouTube or audio URL, or inline text pasted after the command

## Instructions

### Step 0: Parse arguments

1. Check whether the first token after `/text-clean` is `-conversational` or `-journal`.
   - If `-conversational`, set tone to **conversational** and treat the remainder as input.
   - If `-journal`, set tone to **journal** and treat the remainder as input.
   - Otherwise, set tone to **technical** (default) and treat everything as input.
2. Determine the input source:
   - If the input starts with `http://` or `https://`: treat as a **URL** (YouTube video or audio URL). Proceed to Step 0.5.
   - If the input is a file path ending with an audio or video extension (`.mp3`, `.m4a`, `.wav`, `.flac`, `.ogg`, `.aac`, `.wma`, `.opus`, `.mp4`, `.mkv`, `.avi`, `.mov`, `.webm`, `.m4v`): treat as a **local audio/video file**. Proceed to Step 0.5.
   - If the input is a valid file path to a text file: read the file contents and proceed to Step 1.
   - Otherwise: treat the raw text as the input and proceed to Step 1.

### Step 0.5: Transcribe audio/video input

Use this step only when the input was identified as a URL or local audio/video file in Step 0. After transcription, treat the transcript as inline text and proceed to Step 1. Output will always be written to `/tmp/text-cleaned.md` for audio/URL inputs.

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

Apply all of the following rules to the input text:

#### Organization
- If the thoughts and ideas are scattered or poorly structured, reorganize them for logical flow and clarity.
- Group related ideas together. Ensure each paragraph has a single clear point.

#### Grammar and mechanics
- Fix all grammar, spelling, and punctuation errors.

#### Conciseness (technical and conversational tones only)
- Shorten or split long sentences.
- Remove filler words, redundancy, and repetition.
- Eliminate weasel words and unnecessary qualifiers.
- **Journal tone exception:** Do not aggressively trim for brevity. Preserve the natural rhythm and flow of the writing. Only remove true redundancy where the same point is stated identically, not where repetition serves emphasis or reflection.

#### Clarity
- Rewrite ambiguous statements to be explicit.
- Replace vague language with precise, specific wording.
- Use active voice where possible.

#### Tone
- **Technical (default):** confident, direct, precise. Appropriate for documentation, technical writing, emails to colleagues, and professional communication.
- **Conversational (`-conversational`):** natural, approachable, readable. Appropriate for blog posts, casual updates, and informal communication.
- **Journal (`-journal`):** personal, reflective, and introspective. Preserve the author's thought patterns, emotions, and the texture of their experience. The goal is to capture how they think and feel, not to compress the text into its most efficient form. Keep stream-of-consciousness flow where it reveals the author's mindset. Appropriate for diary entries, personal reflections, and experience logs.
- In technical and conversational modes: make the text more confident, direct, and readable while preserving the author's voice.
- In journal mode: prioritize authenticity and emotional fidelity over directness. Clean up grammar and clarity, but do not flatten the voice.

#### Preservation
- Preserve the original meaning and all key details.
- Do not add new information or opinions.
- Maintain existing formatting conventions (markdown, bullet lists, headers, etc.).

### Step 2: Output

- **Always write output to a file** using the Write tool. Terminal copy-paste can alter whitespace and formatting, so file output is required to preserve the exact text.
- If the input was a text file path, write the cleaned text back to the same file.
- Otherwise (inline text, audio file, or URL), write the cleaned text to `/tmp/text-cleaned.md`.
- Write directly to the output path without asking for confirmation — overwrite any existing file.
- After writing, confirm with a single line: `Cleaned: <file path>`
- Do not print the cleaned text to the terminal. The file is the output.
