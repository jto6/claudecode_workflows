# Distill — Extract Core Concepts

Distill the essential ideas from any source (URL, image, video, or text) into a concise, well-structured markdown file.

## Instructions

The user will provide one or more of:
- A URL (article, blog post, YouTube video, documentation page, etc.)
- An image attachment (screenshot, slide deck photo, diagram, etc.)
- A video attachment
- Pasted text or a file path

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
- Any **supporting sub-points** that clarify or nuance the main ideas

Aim for ruthless compression: 3–7 top-level concepts is ideal. Omit examples, anecdotes, filler, and repetition unless they are themselves the point.

### Step 3: Produce the markdown file

Write a `.md` file with this structure:

```markdown
# [Concise, descriptive title]

> [One-sentence summary of the central thesis]

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

### Output rules

#### Structure and hierarchy
- Use indented bullet levels to show logical relationships — cause→effect, thing→properties, contrast, sequence
- Maximum 3 levels of indentation
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

#### Other rules
- Do not pad: if a concept has no meaningful sub-points, omit sub-bullets
- No blank lines between bullets at any level — the list is continuous
- Save the file as `[slug-of-title].md` in the current working directory
- Report the filename and a one-line summary of what was distilled

### Tone

Direct. No hedging, no "the author argues that...". State the ideas as facts.
