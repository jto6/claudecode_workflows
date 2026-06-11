# Private Mirror Setup — Working Privately on a Public GitHub Repo

How to keep a personal `claude` annotation branch (and any other private work) on GitHub without exposing it, for a repo whose original
lives in a public org (e.g. `eclipse-autoapiframework`).

## Why not a GitHub fork

- A fork of a **public** repo is always public — GitHub will not let you make it private
- All forks are listed in the original repo's fork network, so the work is discoverable from the upstream page
- Solution: a **private mirror** — an ordinary private repo you push to; it is not a fork, so it appears nowhere on the original repo

## The triangular remote model

| Remote     | Points to                       | Used for                                                  |
|------------|---------------------------------|-----------------------------------------------------------|
| `upstream` | The original public repo        | Fetch/pull only — never push                              |
| `origin`   | Your private mirror             | All pushes; home of `claude` and `feat-*`                 |
| `fork`     | Public fork, created at PR time | Push only the clean `pr-*` branch, only when contributing |

## Setup commands

```bash
# in a clone where the original repo is currently 'origin'
git remote rename origin upstream            # branch tracking (e.g. main -> upstream/main) follows the rename

gh repo create <your-user>/<repo> --private  # or create an empty private repo in the GitHub web UI
git remote add origin git@github.com:<your-user>/<repo>.git

git push origin main                         # mirror main; NO -u, so main keeps tracking upstream/main
git push -u origin claude                    # claude tracks origin/claude

git config remote.pushDefault origin         # every `git push` defaults to origin, regardless of tracking
```

## What `-u` / `--set-upstream` does

`git push -u origin claude` pushes **and** records `branch.claude.remote = origin` + `branch.claude.merge = refs/heads/claude` in
`.git/config`. Consequences for that branch: argument-less `git pull`/`git push` know their target, and `git status` / `git branch -vv`
report ahead/behind counts against `origin/claude`.

Deliberately **omit** `-u` when pushing `main`: its tracking should stay `upstream/main` so that `git pull` on main fetches new upstream
commits. `-u` there would silently re-point tracking to `origin/main`.

## How the directions resolve afterward

- On `main`: `git pull` → `upstream` (branch tracking), `git push` → `origin` (remote.pushDefault)
- On `claude` / `feat-*`: both directions → `origin`
- Pushing to `upstream` requires naming it explicitly — accidental pushes to the public repo become impossible

## Caveats

- A private mirror **cannot open pull requests** against the original repo. When ready to contribute: create the public fork at that
  moment, `git remote add fork <fork-url>`, and push only the clean `pr-*` branch there (see
  [claude-branch-workflow.md](claude-branch-workflow.md) for the PR extraction steps and leak check)
- The mirror does not auto-sync; keeping `origin/main` current is your job (part of the regular sync loop in the workflow cheat sheet)
- Upstream's CI/GitHub Actions do not run on the mirror; test locally or set up your own workflows
- License note: mirroring open-source code into a private repo is fine for typical permissive/copyleft licenses (you are not distributing),
  but the obligations apply once you publish
