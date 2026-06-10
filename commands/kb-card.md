# kb-card — Author Knowledge Base Cards

Create or update distilled **knowledge-base cards** — `.kb/*.kb.md` — from
sources, and record how each directory's sources are divided into cards in a
per-directory `.kb/segmentation.yml` manifest. Card granularity is
**adaptive-first**: the command proposes how to scope cards by analyzing
content, with optional `kb.yml` overrides and manual review. Re-runs
**reconcile** against `segmentation.yml` — they refine decisions, they do not
redo them.

This command is **author-side**: run by the repo owner inside the repo; cards
and `segmentation.yml` are committed with that repo. It does **not** index
anything — the external indexer (`kbi`) reads `*.kb.md` cards read-only to
build the cross-repo catalog as a separate step (and ignores
`segmentation.yml`).

Full reference for the card schema, `kb.yml`, `segmentation.yml`, and this
command: `/home/jon/dev/kbi/docs/REFERENCE.md`. Rationale and decisions:
`/home/jon/dev/kbi/docs/DESIGN_PRINCIPLES_AND_DECISIONS.md`.

## Usage

```
/kb-card [source | <url>] [-r] [-plan] [-resegment] [-update] [-visual]
         [-density coarse|normal|fine|exhaustive] [-cards <N>]
         [-file-summary | -no-file-summary]
         [-domain <d>] [-level 1|2|3] [-quotes | -no-quotes]
```

- `source` — a file, a directory, a **URL**, or omitted (defaults to the current
  directory). A URL is captured to a local transcript first (see Step 0).
- `-r` — recurse: walk the tree under `source` and author a card per unit.
- `-plan` — propose/update `segmentation.yml` (the segmentation) and stop
  **before** authoring card bodies. **This is the review/adjustment gate** —
  see Step 2.
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
- `-file-summary` / `-no-file-summary` — per-run override of the area's
  `kb.yml file_summary` setting. When effective, author a `kind: file_summary`
  card per source whose section split yields ≥2 topic cards (see Step 3a). The
  N=1 short-circuit always applies: a source with only one topic card never
  gets a separate summary card.
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
  quota). Depth may be non-uniform — a `density_overrides` entry in
  `segmentation.yml` raises/lowers it for one `(source, section)` while the rest
  uses the global `density`.
- **`segmentation.yml`** — the per-directory record of reviewed boundaries (not
  a forward plan). Re-runs reconcile against it. Renamed from `cards.yml` per
  D21; carries segmentation state (signature, locked, source_hash, density),
  not a card index.
- **Boundaries vs. content.** Boundaries are sticky (in `segmentation.yml`);
  content is regenerated. Updating a source refreshes content but keeps the
  boundary.
- **Card roles (`kind`).** A card with `kind: file_summary` distills the source
  *as a whole* (one card per source, opt-in via `kb.yml file_summary` or the
  `-file-summary` flag, only when the source produces ≥2 topic cards). All
  other cards are topic cards (no `kind` field). See Step 3a.

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
  the optional `card_unit` / `card_split` / `card_density` / `file_summary`
  overrides. Resolve the distill behavior with precedence: command flags →
  explicit `distill_level`/`quotes` → named `profile` → domain default →
  `standard`.
- Resolve the effective **density**: `-density` flag → `kb.yml card_density` →
  `normal`. Note any `-cards N` ceiling. Per-section `density_overrides` recorded
  in `segmentation.yml` take precedence within their `(source, section)` scope.
- Resolve **file_summary**: `-file-summary`/`-no-file-summary` flag → `kb.yml
  file_summary` (`auto|on|off`) → `auto`. `auto` currently resolves to `on`.
- **First-run bootstrap.** `.kb/` directories are created automatically as needed
  — never require the user to pre-create them. If **no `.kb/kb.yml`** is found
  anywhere up the tree, create one at the **root of the current scope** (the
  `source` directory, or the `-r` root):
	- If `-domain` was given, write a minimal `kb.yml` (that `domain` + the domain's
	  default profile) without prompting.
	- Otherwise ask a few short questions and write the answers:
		- **domain** (required) — e.g. `spiritual`, `technical`, `finance`.
		- **include key quotes?** — yes → `profile: reflective`, no → `standard`
		  (default inferred from the domain: `spiritual` / `personal-dev` →
		  reflective).
		- **seed tags** (optional) — a few anchor tags, or skip.
	- Confirm the location before writing, so running inside a sub-directory of a
	  larger area doesn't root the area too deep (offer a parent directory when the
	  area is bigger than the current folder).
	- Then proceed using the newly created `kb.yml`.

### Step 2: Segment — propose boundaries (adaptive-first), then reconcile

For each directory in scope, decide how its sources divide into cards:

1. **Propose (adaptive).** Analyze the directory's sources and propose the set of
   cards, honoring any declared `card_unit`/`card_split`, otherwise choosing
   adaptively:
	- **Near-duplicate / refinement scan (before per-file assignment).** Compare
	  all files in the directory pairwise for similarity signals:
		- filename versioning patterns (e.g. `_v1`/`_v2`, `_old`/`_new`,
		  `_draft`/`_final`, date suffixes, numeric suffixes);
		- file sizes within a factor of ~2 of each other;
		- overlapping opening headings or first paragraphs (read the first
		  ~20 lines of each file to compare structure and opening content).
	  Classify pairs as:
		- **duplicate** — content is essentially identical (same headings,
		  same core sentences); mtime may differ only slightly;
		- **refinement** — one is a clear superset/evolution of the other
		  (later mtime, same topic, some content added or changed, but
		  clearly the same document).
	  For a detected pair, propose **one card** for the **canonical** file
	  (latest mtime, or higher version/final suffix), and record the superseded
	  file(s) in that card entry's `supersedes` list. Flag the pair at the
	  review gate (Step 2.3) so the author can confirm or override.
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
2. **Reconcile** the proposal against the existing `.kb/segmentation.yml`:
	- existing card, `source_hash` unchanged → keep as-is;
	- source changed, boundary still resolves (validate the `scope`
	  **semantically** against the new content — section/signature, not page
	  numbers) → mark **refresh**;
	- source changed, boundary no longer resolves → break `locked` and mark
	  **re-segment** (needs review);
	- new source/section → mark **new** (needs review);
	- source gone → mark the card **orphan**.
3. **Review the delta (the manual adjustment gate).** Present only the changed
   entries (new / re-segment / orphan / refresh). Also surface any detected
   **near-duplicate or refinement pairs** here — show which file is proposed as
   canonical and which is recorded in `supersedes`, and allow the author to
   override (keep them as separate cards, or reverse the canonical choice).
   This is where the author steers segmentation — merge, split, relabel,
   lock/unlock, and **adjust depth**: change the global `density`, or go
   deeper/shallower on specific sections by adding a `density_overrides` entry
   (non-uniform depth). (`-resegment <source>` forces step 1 fresh for that
   source, discarding its old entries.) With `-plan`, this is the explicit stop
   for review before any card body is written.
4. **Write `segmentation.yml`** with the reviewed result — the effective
   `density`, any `density_overrides`, and the card entries (slug, id, file,
   source, scope, `locked`, `source_hash`). **If `-plan` was given, stop
   here.**

`locked` means "never change this boundary silently" — it is still auto-escalated
to review when content drift invalidates it; it is not immutable.

### Step 3: Author / refresh cards per `segmentation.yml`

For each card entry that is new, refresh, or re-segmented:

- **Skip superseded sources.** If the entry has a `supersedes` list, distill only
  the **canonical** source (the entry's own `source`). Do not distill the
  superseded files separately — they are absorbed. (Token savings: no duplicate
  distillation of near-identical content.)
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
  `updated` (today), `meta`. If the entry has a `supersedes` list, add
  `refines: [relative-path-to-superseded-source]` (the oldest/most-superseded
  source first). For a section card, record the section in `meta` (e.g.
  `meta.section`). Topic cards omit `kind`.
- **Linkify** known terms best-effort: convert the first occurrence of any term
  in the gathered term index to `[[defining-card-slug|surface text]]`.
- **Write** the card to `.kb/<file>.kb.md` (the `file` from `segmentation.yml`).

### Step 3a: Author / refresh file-summary cards (when enabled)

When the effective `file_summary` is `on` (default), for each source whose
section split yields ≥2 topic cards (after Step 3), author or refresh a
**file-summary card** distilling the source as a whole:

- **Skip the N=1 short-circuit.** A source whose split yields exactly one topic
  card never gets a separate summary — the lone topic card's essence already
  serves as the file's summary.
- **At most one** file-summary card per source. If one already exists in
  `segmentation.yml` for this source, refresh it; otherwise create one.
- **Distill** the *whole* source (not a section) at the same resolved profile.
  The body should articulate the file's overall content/argument, **not** a
  TOC of the topic cards. The `>` essence is one sentence on what the file is
  conveying as a unit.
- **Filename:** the bare-stem slot `<source-stem>.kb.md`. Topic cards alongside
  one always take `<source-stem>.<section-slug>.kb.md`. If a topic card was
  previously written to the bare-stem slot, rename it to its
  `<section-slug>` form (and update its `file:` entry in `segmentation.yml`).
- **Frontmatter:** the same fields as a topic card, plus `kind: file_summary`.
  No `meta.section` (the scope is the whole file). Tags should reflect the
  file's overall themes; reconcile against the same vocabulary.
- **Refresh dependency:** when any topic card under the same source is
  refreshed or re-segmented, regenerate the file-summary in the same pass.
- **`segmentation.yml` entry:** record the file-summary card alongside its
  topic siblings, with `scope` omitted (whole-file scope) — this lets the
  manifest carry boundary state for it (signature/locked/source_hash) the
  same as any other card.
- When `file_summary` resolves to `off` (or `-no-file-summary` is given), do
  not create new file-summary cards; existing ones remain unless the author
  removes them. (Removing a file-summary card is treated like any retirement
  in Step 4.)

### Step 4: Retire orphans and report

- For orphaned cards, confirm, then delete the `.kb.md` and remove the entry from
  `segmentation.yml`.
- Do **not** run `kbi`. Report: cards created / refreshed / re-segmented /
  retired; tags reused vs newly coined; and a reminder that the central catalog
  updates only when the indexer is next run.

## Naming conventions

- One card per file/dir, no file-summary: `<stem>.kb.md` (e.g. `Plan.kb.md`);
  whole-directory card may use the directory basename.
- Multiple cards from one file (section splits): `<stem>.<section-slug>.kb.md`
  (e.g. `foo.architecture.kb.md`, `foo.safety.kb.md`), each with the same
  `source` and a distinct `scope`.
- The **bare-stem slot `<stem>.kb.md` is reserved for the file-summary card**
  (Step 3a) when one exists. Whenever a file-summary is present for a source,
  *every* topic card from that source must take the
  `<stem>.<section-slug>.kb.md` form — the bare stem is never shared.

## `segmentation.yml` format

```yaml
# .kb/segmentation.yml — reviewed segmentation manifest for this directory.
version: 1
updated: 2026-06-07
density: normal                  # effective depth (from kb.yml/-run)
density_overrides:               # optional: non-uniform depth, by (source, section)
  - source: ../reports/foo.pdf
    section: "Architecture"
    density: fine
cards:
  - slug: foo                    # file-summary card for ../reports/foo.pdf
    id: 1a2b...
    file: foo.kb.md              # bare-stem slot — reserved for the summary
    kind: file_summary
    source: ../reports/foo.pdf
    title: Foo
    source_hash: sha256:...
  - slug: sdv-arch-overview
    id: 7f3a...
    file: foo.architecture.kb.md
    source: ../reports/foo.pdf
    supersedes:                  # optional: near-duplicate/refined sources absorbed
      - ../reports/foo_v1.pdf    #   into this card; not separately distilled
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

## Refinement / supersession fields

When a card absorbs one or more near-duplicate or earlier-version sources:

- **`refines`** (frontmatter list, relative paths) — present on the canonical card;
  lists the superseded source file(s) this card refines or supersedes. The oldest/
  most-superseded source comes first.
- **`refined_by`** (frontmatter string, slug) — present on an older card *only if*
  that card is kept as a separate entry (author override); names the slug of the
  canonical card that supersedes it.

Default behavior is no separate card for the superseded source — it is absorbed and
only `refines:` appears on the canonical card. The `refined_by:` field is written
only when the author explicitly keeps both cards.
