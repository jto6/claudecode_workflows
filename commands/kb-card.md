# kb-card — Author Knowledge Base Cards

Create or update distilled **knowledge-base cards** — `.kb/*.kb.md` — from
sources, and record how each directory's sources are divided into cards in a
per-directory `.kb/cards.yml` manifest. Card granularity is **adaptive-first**:
the command proposes how to scope cards by analyzing content, with optional
`kb.yml` overrides and manual review. Re-runs **reconcile** against `cards.yml` —
they refine decisions, they do not redo them.

This command is **author-side**: run by the repo owner inside the repo; cards and
`cards.yml` are committed with that repo. It does **not** index anything — the
external indexer (`kbi`) reads `*.kb.md` cards read-only to build the cross-repo
catalog as a separate step (and ignores `cards.yml`).

Full reference for the card schema, `kb.yml`, `cards.yml`, and this command:
`/home/jon/dev/kbi/docs/REFERENCE.md`. Rationale and decisions:
`/home/jon/dev/kbi/docs/DESIGN_PRINCIPLES_AND_DECISIONS.md`.

## Usage

```
/kb-card [source | <url>] [-r] [-plan] [-resegment] [-update] [-visual]
         [-density coarse|normal|fine|exhaustive] [-cards <N>]
         [-domain <d>] [-level 1|2|3] [-quotes | -no-quotes]
```

- `source` — a file, a directory, a **URL**, or omitted (defaults to the current
  directory). A URL is captured to a local transcript first (see Step 0).
- `-r` — recurse: walk the tree under `source` and author a card per unit.
- `-plan` — propose/update `cards.yml` (the segmentation) and stop **before**
  authoring card bodies. **This is the review/adjustment gate** — see Step 2.
- `-resegment` — discard the existing boundaries for `source` and re-propose from
  scratch (use when content changed dramatically).
- `-update` — refresh the content of existing cards whose source drifted.
- `-visual` — **(planned, not implemented)** request multimodal capture of a video
  source (transcript + on-screen text + visual descriptions). Until implemented,
  reject with a notice; default capture is transcript-only.
- `-density coarse|normal|fine|exhaustive` — how *deep* to partition (themes →
  section groups → sections → subsections). Overrides the area's `card_density`.
- `-cards <N>` — a **maximum** card count (a ceiling, never a quota): partitioning
  stops at the finest *meaningful* boundaries and will not invent or fragment
  topics to reach N; if a depth would exceed N, the least-distinct boundaries are
  merged.
- `-domain` / `-level` / `-quotes` / `-no-quotes` — override domain and the
  distill profile (level / quotes).

## Concepts (see `REFERENCE.md` §4)

- **Granularity = a cut across `repo → directory → file → section`.** A card
  should be one cohesive, self-contained, bounded topic.
- **Adaptive proposal + declarative override.** The command proposes the cut;
  `card_unit` (`repo|directory|file|section`) and `card_split` (`auto|never`) in
  `kb.yml` (inherited per subtree) override it where the author wants control.
- **Depth (density).** `card_density` (`coarse|normal|fine|exhaustive`) sets how
  deep the cuts go; `-density`/`-cards` override per run (`-cards` is a max, not a
  quota). Depth may be non-uniform — a `density_overrides` entry in `cards.yml`
  raises/lowers it for one `(source, section)` while the rest uses the global
  `density`.
- **`cards.yml`** — the per-directory record of reviewed boundaries (not a
  forward plan). Re-runs reconcile against it.
- **Boundaries vs. content.** Boundaries are sticky (in `cards.yml`); content is
  regenerated. Updating a source refreshes content but keeps the boundary.

## Instructions

### Step 0: Capture a remote source (URL)

If `source` is a URL, first acquire a local source document, then run the normal
steps over that local file:

- Fetch the **transcript** via `/distill`'s URL/YouTube support (spoken text).
- Write it as a **visible** local file in the target directory, named from a slug
  (e.g. a date-prefixed slug), with the URL and any metadata (speaker, date) in its
  frontmatter. This file is the directory's source content — browsable and
  re-segmentable; the card sidecars it in `.kb/`.
- Scan the transcript for on-screen-visual references ("as you can see on the
  slide", "this chart/diagram", "on the screen"); if present, **warn** that
  transcript-only capture may be lossy and suggest `-visual`.
- `-visual` (multimodal: transcript + OCR'd on-screen text + short visual
  descriptions) is **not yet implemented** — reject it with a notice for now.
- The resulting card's `source` lists the **URL first** (canonical) and the local
  transcript second; record `meta.capture: transcript`.

Then continue from Step 1 with the captured local file as the source.

### Step 1: Resolve scope and area config

- Determine the operating scope: a single `source` (file/dir), or a recursive
  walk of the tree under `source`/cwd when `-r` is given.
- For each directory in scope, find the nearest ancestor `.kb/kb.yml` and load:
  `domain`, `profile`, `distill_level`/`quotes`, `seed_tags`, `meta_fields`, and
  the optional `card_unit` / `card_split` / `card_density` overrides. Resolve the
  distill behavior with precedence: command flags → explicit `distill_level`/`quotes`
  → named `profile` → domain default → `standard`.
- Resolve the effective **density**: `-density` flag → `kb.yml card_density` →
  `normal`. Note any `-cards N` ceiling. Per-section `density_overrides` recorded in
  `cards.yml` take precedence within their `(source, section)` scope.
- If no `kb.yml` and no `-domain`, ask the user for the domain and use
  `standard`.

### Step 2: Segment — propose boundaries (adaptive-first), then reconcile

For each directory in scope, decide how its sources divide into cards:

1. **Propose (adaptive).** Analyze the directory's sources and propose the set of
   cards, honoring any declared `card_unit`/`card_split`, otherwise choosing
   adaptively:
	- detect the natural atom — a folder of variants of one thing → one card; a
	  folder of distinct documents → one card each;
	- split an over-dense / multi-topic unit into per-section cards when
	  `card_split: auto` or when a single card would lose too much (a unit fails
	  the cohesion/bounded-size test);
	- choose the **depth** of the split from the effective density — cut deeper into
	  the section/subsection hierarchy for `fine`/`exhaustive`, shallower (merged
	  themes) for `coarse`. Apply per-section `density_overrides` within their
	  scope. Never exceed a `-cards N` ceiling, and never split past the finest
	  *meaningful* boundary just to add cards (cohesion is the floor);
	- for each proposed card record: a `title`, the `source` (file or directory),
	  and a `scope` (section identity + a short semantic `signature`) for
	  section-level cards.
2. **Reconcile** the proposal against the existing `.kb/cards.yml`:
	- existing card, `source_hash` unchanged → keep as-is;
	- source changed, boundary still resolves (validate the `scope`
	  **semantically** against the new content — section/signature, not page
	  numbers) → mark **refresh**;
	- source changed, boundary no longer resolves → break `locked` and mark
	  **re-segment** (needs review);
	- new source/section → mark **new** (needs review);
	- source gone → mark the card **orphan**.
3. **Review the delta (the manual adjustment gate).** Present only the changed
   entries (new / re-segment / orphan / refresh). This is where the author steers
   segmentation — merge, split, relabel, lock/unlock, and **adjust depth**: change
   the global `density`, or go deeper/shallower on specific sections by adding a
   `density_overrides` entry (non-uniform depth). (`-resegment <source>` forces step
   1 fresh for that source, discarding its old entries.) With `-plan`, this is the
   explicit stop for review before any card body is written.
4. **Write `cards.yml`** with the reviewed result — the effective `density`, any
   `density_overrides`, and the card entries (slug, id, file, source, scope,
   `locked`, `source_hash`). **If `-plan` was given, stop here.**

`locked` means "never change this boundary silently" — it is still auto-escalated
to review when content drift invalidates it; it is not immutable.

### Step 3: Author / refresh cards per `cards.yml`

For each card entry that is new, refresh, or re-segmented:

- **Distill** its scoped source (a whole file/dir, or a single section) using the
  resolved profile — produce the one-line essence, ruthlessly compressed Core
  Concepts (tabs for nesting), and a Key Quotes section when quotes are enabled.
  (Apply the `/distill` logic at the resolved level.)
- **Reconcile tags.** Gather the vocabulary — `seed_tags` plus the `tags`/`defines`
  of sibling cards under the area root — and choose 4–8 tags, **reusing** existing
  tags where they fit and coining new kebab-case tags only when genuinely novel.
- **Extract meta.** For each key in `meta_fields` (e.g. `scripture`), pull values
  from the source into a `meta` map.
- **Assemble frontmatter:** `id` (new UUID via
  `python3 -c 'import uuid; print(uuid.uuid4())'`; **preserved** for existing
  cards), `slug` (readable kebab-case, unique; preserved for existing), `title`,
  `source` (relative to the card's `.kb/`), `domain`, `tags`, `defines` (if any),
  `builds_on` (only if known — do not invent), `created` (today; kept on update),
  `updated` (today), `meta`. For a section card, record the section in `meta`
  (e.g. `meta.section`).
- **Linkify** known terms best-effort: convert the first occurrence of any term
  in the gathered term index to `[[defining-card-slug|surface text]]`.
- **Write** the card to `.kb/<file>.kb.md` (the `file` from `cards.yml`).

### Step 4: Retire orphans and report

- For orphaned cards, confirm, then delete the `.kb.md` and remove the entry from
  `cards.yml`.
- Do **not** run `kbi`. Report: cards created / refreshed / re-segmented /
  retired; tags reused vs newly coined; and a reminder that the central catalog
  updates only when the indexer is next run.

## Naming conventions

- One card per file/dir: `<stem>.kb.md` (e.g. `Plan.kb.md`); whole-directory card
  may use the directory basename.
- Multiple cards from one file (section splits): `<stem>.<section-slug>.kb.md`
  (e.g. `foo.architecture.kb.md`, `foo.safety.kb.md`), each with the same
  `source` and a distinct `scope`.

## `cards.yml` format

```yaml
# .kb/cards.yml — reviewed segmentation manifest for this directory.
version: 1
updated: 2026-06-07
density: normal                  # effective depth (from kb.yml/-run)
density_overrides:               # optional: non-uniform depth, by (source, section)
  - source: ../reports/foo.pdf
    section: "Architecture"
    density: fine
cards:
  - slug: sdv-arch-overview
    id: 7f3a...
    file: foo.architecture.kb.md
    source: ../reports/foo.pdf
    scope:                       # omit for whole-file / whole-directory cards
      section: "Architecture"
      signature: "<short topic fingerprint>"
    title: SDV Architecture Overview
    locked: true
    source_hash: sha256:...
```

## Card body shape

`# <title>`, then the `>` essence (one sentence), then `## Core Concepts` (nested
bullets), then `## Key Quotes` (only when quotes are enabled).
