# Three-Level Codebase Analysis — /CA_init

Generate (or refresh) a three-level "onion" analysis of the current repository. The levels serve different reading modes across many
repositories: level 1 to grok a repo quickly, level 2 to navigate and reason about it, level 3 to answer specific technical questions
without re-exploring.

## Output files

Write to `analysis/` at the repository root. If upstream already owns a directory named `analysis/`, use `ca/` instead and say so.

- `analysis/level-1-overview.md`
- `analysis/level-2-architecture.md`
- `analysis/level-3-reference.md`

Every file starts with this frontmatter:

```yaml
---
repo: <org/name, or local path if no remote>
analyzed-commit: <output of git rev-parse --short HEAD>
analyzed-date: <YYYY-MM-DD>
generator: /CA_init v2
---
```

## Process (order matters)

1. **Classify the repo first.** Determine what kind of repository this is: application, library/framework, spec/documentation umbrella,
   examples/blueprints, infrastructure. Shape the whole analysis accordingly. If it is a spec/docs or umbrella repo, state that prominently
   in level 1 and identify where the actual code lives (sibling repos, upstream projects).
2. **Explore deeply, once.** Use Glob/Grep/Read systematically: READMEs, build files, entry points, config files, models/schemas, a sample
   of core source files. Distinguish hand-written from generated code. Focus on understanding, not cataloging.
3. **Write by distillation, top of the onion last.** Write level 3 first (raw reference from your exploration), distill level 2 from it,
   then distill level 1 from level 2. Test: level 1 must be writable from level 2 alone — if it isn't, level 2 is missing something.

## Level definitions

### Level 1 — Overview (hard cap: ~1 page / ~60 lines)

The *why* and *what* at a conceptual and vision level:

- The problem the project exists to solve, and its goals
- What this repository itself contains vs. what lives in related/sibling repositories
- The surrounding ecosystem (related projects, upstream/downstream dependencies) — a small table is appropriate
- The core workflow or data flow in one sentence
- Status and posture (maturity, activity, production-readiness)

No implementation detail. No file paths except where genuinely illustrative.

### Level 2 — Architecture (target: 3–4 pages)

The *how*, deep enough to cover design decisions:

- The end-to-end pipeline / data flow / request flow, stage by stage
- Key design decisions **with their rationale and trade-offs** (each as its own short subsection)
- Architectural and code design patterns actually used (not a generic catalog)
- Component map and how the repository is organized
- Build and development workflow at summary level
- Close with a short "mental model to carry forward" paragraph

File and directory paths are appropriate here; API signatures are not.

### Level 3 — Technical reference (no length cap, but index-style)

A lookup reference, **not** prose re-narration of the code:

- Repository file map with one-line purposes
- Observed API surfaces (function/class signatures, generated code patterns), quoted minimally with `file:line` pointers
- Data formats, schemas, and config file structures with short examples
- CLI commands, build chain, toolchain versions
- Known quirks, gotchas, and inconsistencies found during exploration
- End with a `## Recommended prompts` section: 8–15 **filled-in, repo-specific** prompts for deeper investigation (real component and
  feature names — never placeholder templates like "[specific component]")

## What NOT to include

- No code-quality / technical-debt / security audit — that is a separate, on-demand task, not onboarding
- No generic boilerplate that would be identical across repos
- No duplicated content between levels; each level may link to the level below it instead

## Update mode

If invoked as `/CA_init update`: read `analyzed-commit` from the frontmatter, run `git diff --stat <analyzed-commit>..HEAD`, refresh only
the sections affected by the changes, and update the frontmatter commit and date.

## Conventions

- These files are committed on the personal annotation branch (`claude`), never on main or PR branches. Commit them in their own commit
  with a message prefixed `analysis:` (see the claude-branch workflow cheat sheet in
  `~/dev/claudecode_workflows/docs/claude-branch-workflow.md`).
- Follow the global markdown formatting rules (blank line between paragraph and list, aligned pipe tables, grid tables when wider than
  150 characters).
