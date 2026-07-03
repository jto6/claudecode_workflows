#!/usr/bin/env bash
# PostToolUse hook: objective usage telemetry for the personal knowledge base
# index (~/dev/kb/index, built by ~/dev/kbi).
#
# Appends one JSONL event to ~/dev/kb/telemetry.jsonl when a session:
#   • index_read  — reads a file under ~/dev/kb/index/ (consulted the index)
#   • card_read   — reads a knowledge card (.kb/<name>.kb.md)
#   • source_read — reads a source file that HAS a card (signal: card was
#                   insufficient, or was skipped)
#   • fs_search   — runs Grep/Glob (or grep/rg/find/fd via Bash) against an
#                   indexed root OUTSIDE the current project dir (signal: the
#                   index was bypassed for a cross-filesystem knowledge lookup)
#
# Indexed roots are parsed at runtime from the kbi config (directories.include),
# NOT hard-coded, so they track config changes. In-project searches are never
# logged: working inside your own repo is coding, not knowledge lookup.
#
# Always exits 0 and prints nothing — telemetry must never block or distract
# a session. Consumed by /kb-retro.

# Capture the hook JSON here: `python3 -` reads its *program* from stdin, so
# the payload must travel via the environment instead.
HOOK_INPUT="$(cat)" export HOOK_INPUT

python3 - <<'PYEOF'
import json, os, re, sys, glob
from datetime import datetime, timezone

try:
    data = json.loads(os.environ.get("HOOK_INPUT") or "{}")

    HOME = os.path.expanduser("~")
    LOG = os.path.join(HOME, "dev/kb/telemetry.jsonl")
    INDEX_DIR = os.path.join(HOME, "dev/kb/index")
    KBI_CONFIG = os.path.join(HOME, "dev/kbi/configs/Study25-cards-md.yml")

    tool = data.get("tool_name", "")
    ti = data.get("tool_input", {}) or {}
    session = (data.get("session_id") or "")[:8]
    cwd = data.get("cwd") or ""
    project = os.environ.get("CLAUDE_PROJECT_DIR") or cwd

    def indexed_roots():
        """Parse directories.include from the kbi config (minimal YAML walk)."""
        roots, in_dirs, in_inc = [], False, False
        try:
            with open(KBI_CONFIG) as f:
                for line in f:
                    if re.match(r"^directories:", line):
                        in_dirs, in_inc = True, False
                    elif re.match(r"^\S", line):
                        in_dirs = in_inc = False
                    elif in_dirs and re.match(r"^\s+include:", line):
                        in_inc = True
                    elif in_dirs and re.match(r"^\s+\w+:", line):
                        in_inc = False
                    elif in_inc:
                        m = re.match(r"""^\s+-\s*["']?(/[^"']+?)["']?\s*$""", line)
                        if m:
                            roots.append(m.group(1).rstrip("/"))
        except OSError:
            pass
        return roots

    def under(path, base):
        return base and (path == base or path.startswith(base.rstrip("/") + "/"))

    def emit(event, **fields):
        rec = {"ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
               "session": session, "event": event, "project": project}
        rec.update(fields)
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        with open(LOG, "a") as f:
            f.write(json.dumps(rec) + "\n")

    def fsize(path):
        try:
            return os.path.getsize(path)
        except OSError:
            return None

    if tool == "Read":
        fp = ti.get("file_path", "")
        if not fp:
            pass
        elif under(fp, INDEX_DIR):
            emit("index_read", path=fp, bytes=fsize(fp))
        elif fp.endswith(".kb.md") and "/.kb/" in fp:
            emit("card_read", path=fp, bytes=fsize(fp))
        else:
            d, b = os.path.split(fp)
            stem = os.path.splitext(b)[0]
            if d and stem and glob.glob(os.path.join(d, ".kb", glob.escape(stem) + "*.kb.md")):
                emit("source_read", path=fp, bytes=fsize(fp), has_card=True)

    elif tool in ("Grep", "Glob"):
        path = ti.get("path") or cwd
        roots = indexed_roots()
        if any(under(path, r) for r in roots) and not under(path, project):
            emit("fs_search", tool=tool, path=path,
                 pattern=ti.get("pattern", ""))

    elif tool == "Bash":
        cmd = ti.get("command", "")
        if re.search(r"\b(grep|rg|find|fd)\b", cmd):
            roots = indexed_roots()
            # Absolute or ~-prefixed path tokens mentioned in the command.
            tokens = re.findall(r"(?:~|/)[\w./~+-]*", cmd)
            hits = [os.path.expanduser(t) for t in tokens]
            hits = [h for h in hits
                    if any(under(h, r) for r in roots) and not under(h, project)]
            if hits:
                emit("fs_search", tool="Bash", path=hits[0],
                     pattern=cmd[:200])
except Exception:
    pass  # telemetry must never break a session
PYEOF

exit 0
