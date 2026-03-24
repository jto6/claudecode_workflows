# Text Clean — Grammar, Clarity, and Conciseness Editor

Rewrite text for correct grammar, clear organization, clarity, and conciseness — similar to what Grammarly does, but with structural reorganization when needed.

## Usage

```
/text-clean [-conversational | -journal] <file path or inline text>
```

- `-conversational` — optional flag as the first argument; switches tone from technical (default) to conversational
- `-journal` — optional flag as the first argument; uses a personal, reflective tone that preserves thought patterns and emotions
- Input — either a file path or inline text pasted after the command

## Instructions

### Step 0: Parse arguments

1. Check whether the first token after `/text-clean` is `-conversational` or `-journal`.
   - If `-conversational`, set tone to **conversational** and treat the remainder as input.
   - If `-journal`, set tone to **journal** and treat the remainder as input.
   - Otherwise, set tone to **technical** (default) and treat everything as input.
2. Determine the input source:
   - If the input is a valid file path, read the file contents.
   - Otherwise, treat the raw text as the input.

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
- If the input was a file path, write the cleaned text back to the same file.
- If the input was inline text, write the cleaned text to `/tmp/text-cleaned.md`.
- After writing, confirm with a single line: `Cleaned: <file path>`
- Do not print the cleaned text to the terminal. The file is the output.
