# Distill — Extract Core Concepts

Distill the essential ideas from any source (URL, image, video, or text) into a concise, well-structured markdown file.

## Usage

```
/distill [level | -quotes] <source>
```

- `level` — optional integer **1**, **2**, or **3** controlling output depth (default: **2**)
- `-quotes` — optional flag; extracts the most powerful exact quotes and organizes them by theme
- `source` — a URL, file path, pasted text, or attachment

**Level meanings:**

- **1** — Minimal: just the core concepts, each with a single brief description. For material you want to capture but aren't deeply invested in.
- **2** — Standard (default): ruthlessly compressed nested bullets showing relationships, context, and nuance. 3–7 top-level concepts.
- **3** — Detailed: more concepts, deeper sub-points, and important examples or anecdotes retained where they meaningfully clarify a concept. For material that is important or exceptionally well-presented.
- **-quotes** — Key quotes: extract the most impactful exact quotes from the source and organize them under descriptive thematic headings.

## Instructions

The user will provide one or more of:

- A URL (article, blog post, YouTube video, documentation page, etc.)
- An image attachment (screenshot, slide deck photo, diagram, etc.)
- A video attachment
- Pasted text or a file path

### Step 0: Determine the distillation mode

Check whether the first argument is a bare integer 1, 2, or 3, or the flag `-quotes`.

- If it is `-quotes`, set mode to **quotes** and treat the remainder as the source. Skip Steps 2–3 and proceed to Step 4 after ingestion.
- If it is a bare integer 1, 2, or 3, record that as the level and treat the remainder as the source.
- If it is none of the above, default to level 2.

### Step 1: Ingest the source

- **URL**: Fetch the content with WebFetch. For YouTube URLs, use `python3` with the `youtube_transcript_api` library to fetch the transcript (see YouTube note below).
- **Image/video attachment**: Read the file visually; examine all visible text, diagrams, and structure.
- **Text/file**: Read the content directly.

If the source is inaccessible or ambiguous, ask the user to clarify before proceeding.

#### YouTube transcript fetching

```python
from youtube_transcript_api import YouTubeTranscriptApi
api = YouTubeTranscriptApi()
transcript = api.fetch('VIDEO_ID')
text = ' '.join([x.text for x in transcript])
print(text)
```

If the library is missing, install it first: `pip install youtube-transcript-api --break-system-packages`

### Step 2: Identify core concepts

Analyze the content and extract:

- The **central thesis or purpose** — what is this fundamentally about?
- The **key principles, precepts, or arguments** — the load-bearing ideas
- Any **supporting sub-points**, context, or examples — weighted by the chosen level

### Step 3: Produce the markdown file

Write a `.md` file whose structure and depth depend on the level:

---

#### Level 1 — Minimal

Flat list of concepts, each with at most one brief clarifying phrase. No nested bullets. No examples. No context notes.

```markdown
# [Concise, descriptive title]

> [One-sentence summary of the central thesis, or a direct quote if the source states it better]

## Core Concepts

- [Concept 1]: [one brief phrase]
- [Concept 2]: [one brief phrase]
- [Concept 3]: [one brief phrase]

## Source

[Source title or description](URL or file path)
```

---

#### Level 2 — Standard (default)

Nested bullet structure showing logical relationships. 3–7 top-level concepts. Omit examples, anecdotes, filler, and repetition unless they are themselves the point.

```markdown
# [Concise, descriptive title]

> [One-sentence summary of the central thesis, or a direct quote if the source states it better]

## Core Concepts

- [Concept 1]
	- [short atomic sub-point]
	- [connector phrase]
		- [item]
		- [item]
	- [thing being contrasted]
		- [one pole]
		- [other pole]
- [Concept 2]
	- [short atomic sub-point]
		- (parenthetical context)
		- [elaboration]

## Source

[Source title or description](URL or file path)
```

---

#### Level 3 — Detailed

Same nested structure as level 2, but:

- Include more top-level concepts (no strict upper limit — cover everything meaningful)
- Add deeper sub-points where they genuinely clarify
- Retain important examples or anecdotes as child bullets when they are the clearest way to understand a concept
- Label retained examples inline: `(example: ...)` or `(e.g. ...)`

```markdown
# [Concise, descriptive title]

> [One-sentence summary of the central thesis, or a direct quote if the source states it better]

## Core Concepts

- [Concept 1]
	- [sub-point]
	- [sub-point]
		- (e.g. [concrete example that illuminates the point])
- [Concept 2]
	- [sub-point]
	- [sub-point]
		- [deeper elaboration]

## Source

[Source title or description](URL or file path)
```

---

### Output rules

#### Structure and hierarchy
- Use indented bullet levels to show logical relationships — cause→effect, thing→properties, contrast, sequence
- Maximum 3 levels of indentation (level 3 output may use all three)
- No bold on any bullet text — hierarchy and indentation carry the emphasis

#### Bullet length and decomposition
- Each bullet is the **shortest complete unit of meaning** — a short phrase or a single clause
- Long sentences must be decomposed: break conjunctions, lists, and clauses into sibling or child bullets
- A bullet that packs multiple ideas into one sentence is always wrong — split it

#### Specific patterns to use

**Cause → effect:** Use a connector phrase as the parent bullet, items as children
```
- the West's policies led to
	- deindustrialization
	- outsourced supply chains
	- neglected defense
```

**Contrast / "not X, but Y":** Use sibling bullets under the concept
```
- decline
	- a policy choice
	- not an inevitability
```

**Contextual note:** Use parentheses inline on a child bullet
```
- the West adopted this fantasy
	- (after defeating Soviet communism)
	- trade ties would replace national interest
```

**List of properties:** Omit connector prose, just list children
```
- armies fight for
	- a people
	- a way of life
	- not abstractions
```

**Direct quote:** When an idea is most powerfully expressed by the source's own words, use the exact quote rather than paraphrasing. Quotes can appear in two places:

*As the thesis summary* — when a single line from the source captures the entire central argument better than any paraphrase:
```
> "After a certain age with a certain amount of wealth, continued aggressive
> saving stops being prudent and starts being a mistake."
```

*As a child bullet* — when a quote crystallizes a specific concept within the list:
```
- the game changes after 60
	- stop optimizing for maximum wealth at death
	- "You built wealth for freedom. And then you refuse to be free."
```

Quote rules:

- Exact wording only — never paraphrase inside quotes
- One sentence or clause maximum; trim to the sharpest part if needed
- No attribution needed — the Source section covers that
- High bar: most concepts won't have a quote; never add one just to fill space

#### Other rules
- Do not pad: if a concept has no meaningful sub-points, omit sub-bullets
- No blank lines between bullets at any level — the list is continuous
- Save the file as `[slug-of-title].md` in the current working directory
- Report the filename, the level used, and a one-line summary of what was distilled

### Tone

Direct. No hedging, no "the author argues that...". State the ideas as facts.

---

### Step 4: Quotes mode (`-quotes`)

Use this step only when `-quotes` was set in Step 0. After ingesting the source (Step 1), skip Steps 2–3 and produce the output here instead.

#### Extraction rules

- **Exact wording.** Use the source's own words. Never paraphrase or reword a quote.
- **Standalone impact.** Each quote should resonate on its own, without needing surrounding context to make sense.
- **Turning points preferred.** Favor quotes that capture a shift in understanding, a revelation, a conviction, or a core insight.
- **Ruthlessly selective.** Only the most significant, motivating, and impactful quotes. For a short piece (under 5 minutes / 1 page), expect 2–4 quotes total. For a long piece (30+ minutes / 10+ pages), expect 5–10 quotes total — not dozens. Most of the source material will not produce a quote worth keeping. If a quote doesn't stop you in your tracks, leave it out.

#### Organization rules

- **Thematic headings.** Group quotes under descriptive headings that capture the arc or essence of the group — not just a topic label. A good heading tells the reader what these quotes, taken together, reveal.
- **Commentary when it helps.** If a brief explanation or commentary on the heading genuinely clarifies the key idea, core principle, or why these quotes belong together, include it. Do not add commentary by default — only when it earns its place.

#### Output format

```markdown
# [Concise, descriptive title] — Key Quotes

- [Thematic heading 1]
	- "[exact quote]"
	- "[exact quote]"
- [Thematic heading 2]
	- [brief commentary if it clarifies the theme]
	- "[exact quote]"

## Source

[Source title or description](URL or file path)
```

#### Output rules

- Save the file as `[slug-of-title]-quotes.md` in the current working directory
- Report the filename and a one-line summary of what was extracted
- **Wrap every quote in double quotes** (`"..."`) so quotes are visually distinct from commentary and headings
- No bold on quote text — let the words speak for themselves
- No blank lines between bullets at any level
- No attribution on individual quotes — the Source section covers that
