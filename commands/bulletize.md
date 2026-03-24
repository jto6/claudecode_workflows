# Bulletize — Convert Text to Hierarchical Bullet Points

Break text into one idea per bullet, with sub-bullets for supporting detail, clarification, conditionals, or elaboration. Input is first cleaned via `/text-clean` before bulletizing.

## Usage

```
/bulletize [-conversational | -journal] <file path or inline text>
```

- `-conversational` — optional flag; passed through to `/text-clean` for tone
- `-journal` — optional flag; passed through to `/text-clean` for personal, reflective tone
- Input — either a file path or inline text pasted after the command

## Instructions

### Step 0: Parse arguments

1. Check whether the first token after `/bulletize` is `-conversational` or `-journal`.
   - If either, note the flag and treat the remainder as input.
   - Otherwise, treat everything as input.
2. Determine the input source:
   - If the input is a valid file path, read the file contents.
   - Otherwise, treat the raw text as the input.

### Step 1: Clean the text

Run the input through the `/text-clean` command logic first (with `-conversational` or `-journal` if either flag was set). This fixes grammar, improves clarity, and tightens the prose before bulletizing. Do not output the cleaned text — proceed directly to Step 2 with it.

### Step 2: Bulletize

Transform the cleaned text into hierarchical bullet format following these rules:

#### Format

- Every line starts with zero or more tab characters for indentation, then `- `, then the text.
- **No space characters for indentation. Only tab characters.** Top-level bullets begin at column 0 with no leading whitespace. Sub-levels use exactly one tab per level. Never use spaces to indent.
- One tab per indentation level. Top-level bullets have no tabs. First sub-level has one tab. Second sub-level has two tabs, and so on.
- No blank lines between bullets.

#### Decomposition rules

1. **One idea per bullet.** Each bullet contains exactly one idea, concept, or point. If a sentence has multiple ideas joined by conjunctions, commas, or semicolons, split them.
2. **Supporting detail becomes sub-bullets.** Description, clarification, conditionals, examples, elaboration, or further detail of a parent idea goes on separate indented lines beneath it.
3. **Apply recursively.** If a sub-bullet itself contains an idea with additional decoration, that decoration becomes a sub-bullet of the sub-bullet, and so on. Keep going until each bullet is a single atomic thought.
4. **Preserve all meaning.** Every piece of information from the original text must appear somewhere in the output. Do not drop details.
5. **Preserve chronological and logical order.** Bullets should follow the same sequence as the original text unless reordering clearly improves logical grouping.

#### Example

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

### Step 3: Output

- **Always write output to a file** using the Write tool. Terminal copy-paste destroys tab characters, so file output is required to preserve exact indentation.
- If the input was a file path, write the bulletized text back to the same file.
- If the input was inline text, write the bulletized text to `/tmp/bulletized.md`.
- After writing, confirm with a single line: `Bulletized: <file path>`
- Do not print the bulletized text to the terminal. The file is the output.
