# Claude Annotation-Branch Workflow — Cheat Sheet

Development workflow for repos with a personal `claude` annotation branch (analysis files in `analysis/`), a private GitHub mirror as
`origin`, and the original project repo as `upstream`.

## Branch model

- `upstream/main` — the project's real history; never push here directly
- `claude` — **pure**: exactly `upstream/main` + `analysis:` commits, nothing else, ever
- `feat-*` — feature branches, branched off `claude` so analysis files are in-tree while developing
- `pr-*` — throwaway clean branches built from `upstream/main` for pull requests

## The three pitfalls and their rules

1. **Duplicate-commit trap**: if feature commits land on `claude` itself, a later rebase after a squash-merged PR produces conflicts or
   phantom duplicates. *Rule: never commit feature work on `claude`; features live only on `feat-*` branches, deleted after merge.*
2. **Analysis leaking into PRs**: a mixed commit touching code **and** `analysis/` gets transplanted into the PR. *Rule: commit analysis
   changes separately with an `analysis:` message prefix, and run the leak check before every PR.*
3. **Tested tree ≠ PR tree**: the feature branch contains analysis files; the PR branch does not, and hand-picking commits can drop a
   dependency. *Rule: transplant the whole branch with `rebase --onto` instead of cherry-picking, then build/test the `pr-*` branch
   itself.*

## One-time repo setup

```bash
git remote rename origin upstream          # original project repo becomes upstream
gh repo create <me>/<repo> --private       # private mirror (NOT a GitHub fork)
git remote add origin git@github.com:<me>/<repo>.git
git push origin main                       # mirror main (keeps tracking upstream/main)
git push -u origin claude                  # claude branch lives on the private mirror
git config remote.pushDefault origin       # `git push` defaults to origin; `git pull` on main still pulls upstream
```

## Sync with upstream (regularly, and after every merged PR)

```bash
git fetch upstream
git checkout main && git merge --ff-only upstream/main && git push origin main
git checkout claude && git rebase upstream/main
git push --force-with-lease origin claude
```

Rebasing moves the analysis files to the new tip but does **not** re-verify them — the `analyzed-commit` in each file's frontmatter is the
truth. Refresh with `/CA_init update` when the drift matters.

## Daily development

```bash
git checkout claude
git checkout -b feat-x                     # analysis/ is in-tree while you work
# ...code, commit; never touch analysis/ in code commits
# analysis edits: separate commits, message prefix "analysis:"
```

## Creating a pull request

```bash
git branch pr-feat-x feat-x                          # work on a copy; feat-x stays intact
git rebase --onto upstream/main claude pr-feat-x     # transplant everything after claude onto main

git diff upstream/main...pr-feat-x --name-only | grep '^analysis/' \
  && echo 'LEAK — fix before PR' || echo 'clean'

# build and test pr-feat-x ITSELF (this is the tree the PR will contain)
# push pr-feat-x to a public fork created at PR time, then open the PR
```

The private mirror cannot open PRs against upstream. When ready to contribute: fork on GitHub, `git remote add fork <fork-url>`, and push
**only** the `pr-*` branch there. Private work stays private.

## After the PR merges

```bash
git fetch upstream
git checkout claude && git rebase upstream/main      # clean — claude has only analysis: commits
git push --force-with-lease origin claude
git branch -D feat-x pr-feat-x
git push fork --delete pr-feat-x                     # optional tidy-up
```

## Quick reference

```text
upstream/main ──o──o──o──────────o (their history; PRs merge here)
                       \
claude                  a──a       (analysis: commits ONLY; rebased forward)
                            \
feat-x                       c──c  (feature commits; analysis in-tree)
pr-feat-x  = c──c transplanted onto upstream/main (clean, tested, PR'd, deleted)
```
