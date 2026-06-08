# kb-card — Author a Knowledge Base Card

Create (or update) a distilled **knowledge-base card** — `<source-dir>/.kb/<stem>.kb.md` —
from a source, using the area's `.kb/kb.yml` profile. A card is the curated,
distilled unit of the knowledge base: frontmatter + a one-line essence + core
concepts (+ key quotes for reflective domains).

This command is **author-side**: it is run by the repo owner inside the repo, and
the card is committed with that repo. It does **not** index anything — the
external knowledge-base indexer (`kbi`) reads cards read-only to build the
cross-repo catalog as a separate step.

Card schema and profiles are defined in the kbi repo:
`/home/jon/dev/kbi/docs/DESIGN_PRINCIPLES_AND_DECISIONS.md` (§5, §6).

## Usage

```
/kb-card [source] [-domain <d>] [-level 1|2|3] [-quotes | -no-quotes] [-update]
```

- `source` — a file (e.g. `Plan.md`), a directory, or omitted. If omitted, the
  **current directory** is the source (the card summarizes the folder).
- `-domain <d>` — override the domain (otherwise taken from `kb.yml`).
- `-level 1|2|3` — override the profile's distill level.
- `-quotes` / `-no-quotes` — force the Key Quotes section on/off, overriding the
  profile.
- `-update` — regenerate an existing card at the target path, **preserving its
  `id`, `slug`, and `created` date**; refresh everything else and bump `updated`.

## Instructions

### Step 1: Resolve the source and target path

- Determine the source from the argument, or the current working directory if
  omitted.
- The card's target path is `<source-dir>/.kb/<stem>.kb.md`, where:
	- `<source-dir>` is the source file's directory, or the source directory itself.
	- `<stem>` is the source file's name stem (e.g. `Plan.md` → `Plan`). For a
	  directory source, prefer a `Plan.md` inside it (`Plan`); otherwise use the
	  directory's basename.
- If a card already exists at the target path and `-update` was not given, stop
  and tell the user to pass `-update` (so an existing card is never silently
  overwritten and its stable `id` is never lost).

### Step 2: Resolve the area config (`kb.yml`)

- Walk **up** from the source directory looking for the nearest ancestor that
  contains `.kb/kb.yml`. Load it: `domain`, `profile`, `distill_level`, `quotes`,
  `seed_tags`, `meta_fields`.
- Resolve the effective distill behavior, precedence highest first:
	1. command flags (`-level`, `-quotes`/`-no-quotes`),
	2. explicit `distill_level` / `quotes` in `kb.yml`,
	3. the named `profile` (`standard` = level 2, no quotes; `reflective` = level 2
	   + quotes; `deep` = level 3 + quotes),
	4. the domain default (`spiritual`/`personal-dev` → `reflective`, else
	   `standard`),
	5. fallback `standard`.
- `domain` comes from `-domain`, else `kb.yml`. If no `kb.yml` is found and no
  `-domain` given, ask the user for the domain and use the `standard` profile.

### Step 3: Gather the existing vocabulary (for tag/term reconciliation)

- Collect the reconciliation vocabulary so the bottom-up tag set stays
  convergent instead of sprawling:
	- `seed_tags` from `kb.yml`, plus
	- the `tags` and `defines` from every sibling card under the area root
	  (`<area>/**/.kb/*.kb.md`) — read their frontmatter.
- Keep a map of `term → defining-card-slug` from those `defines` (the term index)
  for linkification in Step 6.

### Step 4: Distill the source

Apply the `/distill` logic at the resolved level (and `-quotes` when quotes are
enabled) to produce:

- a **one-line essence** (the `>` blockquote — the single most important sentence);
- **Core Concepts** as ruthlessly compressed nested bullets (tabs for nesting);
- a **Key Quotes** section when quotes are enabled — exact quotes only, grouped
  under short thematic sub-bullets.

For a directory source, distill across its processable files, preferring a
`Plan.md` or primary document if present.

### Step 5: Reconcile tags, terms, and meta

- Choose **4–8 tags**. **Reuse** tags from the gathered vocabulary wherever they
  fit; coin a new kebab-case tag only when genuinely novel. Note which were
  reused vs newly coined (reported at the end).
- Optionally identify **0–2 terms this card canonically defines** (`defines`) —
  concepts this lesson is the natural home for.
- For each key in `meta_fields` (e.g. `scripture`), extract the corresponding
  values from the source into a `meta` map.

### Step 6: Assemble the card

Frontmatter (omit optional fields that are empty):

- `id` — a new UUID via `python3 -c 'import uuid; print(uuid.uuid4())'`. For
  `-update`, **keep the existing `id`**.
- `slug` — readable kebab-case derived from the title (optionally series-prefixed,
  e.g. `fall-2025-l07-when-god-interrupts`). Ensure it is unique among existing
  card slugs. For `-update`, keep the existing `slug`.
- `title` — the source's title (its H1 / lesson title).
- `source` — path **relative to the card's `.kb/` directory** (e.g. `../Plan.md`,
  or `..` for a whole-folder source).
- `domain`, `tags`, `defines` (if any), `builds_on` (leave empty unless the
  author knows prerequisite card slugs — do not invent), `created` (today; keep
  prior value on `-update`), `updated` (today), `meta` (if any).

Body: `# <title>`, then the `>` essence, then `## Core Concepts`, then
`## Key Quotes` (only when quotes are enabled).

### Step 7: Linkify known terms (best-effort)

- For each term in the gathered term index that appears in the body, convert its
  **first** occurrence to `[[defining-card-slug|surface text]]`. Skip any term
  this card itself defines. Leave the prose reading naturally.

### Step 8: Write the card

- Write the card to the target path, creating `.kb/` if needed. On `-update`,
  overwrite while preserving `id`/`slug`/`created`.
- Do **not** run `kbi`. Remind the user that refreshing the catalog (running the
  indexer) is a separate step they control.

### Output

Confirm: `Card: <path>`, the resolved domain + profile, the tags **reused** vs
**newly coined**, and any `defines`/`builds_on`. Note that the central catalog
will reflect this card the next time the indexer runs.
