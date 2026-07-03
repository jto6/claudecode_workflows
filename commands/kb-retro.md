# Knowledge Base Retrospective - /kb-retro

Digest the knowledge base usage logs (telemetry + feedback comment cards) into an effectiveness report and a concrete improvement action list.

## Usage

/kb-retro [--keep-logs]

## Description

The KB instrumentation produces two logs under `~/dev/kb/`:

- `telemetry.jsonl` — objective events appended by the `kb-telemetry.sh` PostToolUse hook: `index_read`, `card_read`, `source_read` (a source that has a card was opened), and `fs_search` (a filesystem search over an indexed root, outside the current project — i.e. the index was bypassed)
- `feedback.jsonl` — subjective comment cards left by sessions via `kb-feedback`: outcome (`hit`/`partial`/`miss`), what was sought, what happened, and what would have fixed it

This command reads both, answers "is the index working, and where does it fail?", writes a dated report, and archives the digested logs so the next retro starts fresh.

## Implementation

1. **Read the logs.** If both are missing or empty, report that and stop — nothing to digest.
2. **Compute usage metrics from `telemetry.jsonl`** (group by `session` where useful):
	- Sessions that consulted the index (any `index_read`) vs. sessions that only appear via `fs_search` (bypasses — the interesting failures)
	- `card_read` vs. `source_read` counts: a high source-after-card rate means cards are too shallow; compare `bytes` of cards vs. their sources to estimate token savings
	- Most-read cards and domains (what the KB is actually used for)
	- For each `fs_search`: was there an `index_read` earlier in the same session? If yes, the index was consulted but failed (a miss); if no, the instructions were ignored or the session didn't think of the index
3. **Extract improvement signals from `feedback.jsonl`:**
	- List every `miss` and `partial` with its `sought` / `note` / `suggest` fields
	- Group recurring themes (same missing topic, same misleading summary, same wrong-domain complaint)
4. **Write the report** to `~/dev/kb/retro/YYYY-MM-DD-retro.md` with sections: Usage Summary (the metrics), Failure Analysis (bypasses + misses), and **Action List** — each action concrete and executable, e.g. "run `/kb-card` on `<source file>`", "reword the essence line of `<card>`", "move `<card>` to domain X", "add root `<dir>` to the kbi config". Show the report to the user.
5. **Archive the logs** (skip if `--keep-logs`): move `telemetry.jsonl` and `feedback.jsonl` into `~/dev/kb/retro/archive/` with a `YYYY-MM-DD.` prefix so the next period starts clean. Ask the user before archiving.
6. Offer to execute the action list items (e.g. authoring the missing cards with `/kb-card`, then regenerating the index with `cd ~/dev/kbi && ./kbi.py configs/Study25-cards-md.yml`).

## Interpretation notes

- Telemetry is the denominator (what actually happened); feedback is the qualitative color (why). Sessions under-report feedback — do not treat feedback counts as rates.
- `fs_search` uses a heuristic (indexed root, outside the project dir); a few false positives are expected. Look for patterns, not single events.
- An empty `fs_search` list plus healthy `index_read` counts is the success condition: sessions find things through the index instead of sweeping the filesystem.

## Examples

/kb-retro
/kb-retro --keep-logs   (dry run: report only, keep logs accumulating)

## Dependencies

- Logs produced by `hooks/kb-telemetry.sh` (PostToolUse hook) and `bin/kb-feedback`
- The kbi index at `~/dev/kb/index/` for cross-referencing cards named in actions
