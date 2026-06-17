#!/usr/bin/env zsh

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or sudo apt install jq (Ubuntu)"
    exit 1
fi

REPO_PATH="${0:A:h}"
CLAUDE_USER_COMMANDS="$HOME/.claude/commands"
CLAUDE_USER_TEMPLATES="$HOME/.claude/templates"
CLAUDE_USER_HOOKS="$HOME/.claude/hooks"
CLAUDE_USER_SKILLS="$HOME/.claude/skills"
CLAUDE_USER_BIN="$HOME/.claude/bin"
CLAUDE_USER_RULES="$HOME/.claude/rules"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_SETTINGS_LOCAL="$HOME/.claude/settings.local.json"

CLAUDE_SKILLS_VENV="$HOME/.venvs/claude-skills"

echo "🚀 Installing/Updating Claude Code workflows..."

# Create user directories
mkdir -p "$CLAUDE_USER_COMMANDS"
mkdir -p "$CLAUDE_USER_TEMPLATES"
mkdir -p "$CLAUDE_USER_HOOKS"
mkdir -p "$CLAUDE_USER_SKILLS"
mkdir -p "$CLAUDE_USER_BIN"
mkdir -p "$CLAUDE_USER_RULES"

# Create Python virtual environment for skills dependencies
if [[ -f "$REPO_PATH/reqs_for_skills.txt" ]]; then
    if [[ ! -d "$CLAUDE_SKILLS_VENV" ]]; then
        echo "📦 Creating Python virtual environment for skills..."
        python3 -m venv "$CLAUDE_SKILLS_VENV"
        echo "✅ Created venv at $CLAUDE_SKILLS_VENV"
    else
        echo "🔄 Updating Python virtual environment for skills..."
    fi
    "$CLAUDE_SKILLS_VENV/bin/pip" install --quiet -r "$REPO_PATH/reqs_for_skills.txt"
    echo "✅ Installed Python dependencies for skills"
fi

# Create symlinks to commands (so they auto-update with git pulls)
for cmd_file in "$REPO_PATH/commands"/*.md; do
    if [[ -f "$cmd_file" ]]; then
        cmd_name=$(basename "$cmd_file")
        if [[ -L "$CLAUDE_USER_COMMANDS/$cmd_name" ]]; then
            echo "🔄 Updated /$cmd_name command"
        else
            echo "✅ Linked /$cmd_name command"
        fi
        ln -sf "$cmd_file" "$CLAUDE_USER_COMMANDS/$cmd_name"
    fi
done

# Create symlinks to bin scripts (so they auto-update with git pulls)
for bin_file in "$REPO_PATH/bin"/*; do
    if [[ -f "$bin_file" ]]; then
        bin_name=$(basename "$bin_file")
        chmod +x "$bin_file"
        if [[ -L "$CLAUDE_USER_BIN/$bin_name" ]]; then
            echo "🔄 Updated bin: $bin_name"
        else
            echo "✅ Linked bin: $bin_name"
        fi
        ln -sf "$bin_file" "$CLAUDE_USER_BIN/$bin_name"
    fi
done

# Create symlink to default CSS file for md-to-pdf
if [[ -f "$REPO_PATH/css/pdf-style.css" ]]; then
    ln -sf "$REPO_PATH/css/pdf-style.css" "$CLAUDE_USER_TEMPLATES/pdf-style.css"
    echo "✅ Linked default PDF styling template"
fi

# Install global CLAUDE.md instructions (target set per environment below)

# Create symlinks to hook scripts (so they auto-update with git pulls)
for hook_file in "$REPO_PATH/hooks"/*.sh; do
    if [[ -f "$hook_file" ]]; then
        hook_name=$(basename "$hook_file")
        chmod +x "$hook_file"
        if [[ -L "$CLAUDE_USER_HOOKS/$hook_name" ]]; then
            echo "🔄 Updated hook: $hook_name"
        else
            echo "✅ Linked hook: $hook_name"
        fi
        ln -sf "$hook_file" "$CLAUDE_USER_HOOKS/$hook_name"
    fi
done

# ── settings.json: pick environment, then merge into the template safely ──────
# The template (hooks/settings_template.json) is authoritative. We build the new
# settings.json as `template * <env fragment>` (env wins), but before overwriting
# an existing settings.json we (1) take a timestamped backup, (2) detect any keys
# present in the working copy that the new file would drop, and (3) offer to merge
# them back, reminding that they must be committed to the template to persist.
TEMPLATE="$REPO_PATH/hooks/settings_template.json"

echo ""
echo "⚙️  Select environment:"
echo "  1) TI Linux (work)  — NVM node paths, TI gateway, CA cert, statusline"
echo "  2) TI Mac (work)    — /usr/local node paths, TI gateway, no CA cert"
echo "  3) Home             — claude-hud statusline + plugin"
echo "  4) Skip"
read "env_choice?Enter choice [1/2/3/4]: "

ENV_FRAGMENT=""
case "$env_choice" in
    1) ENV_FRAGMENT="$REPO_PATH/hooks/settings.env.ti.json"
       ln -sf "$REPO_PATH/templates/CLAUDE.ti.md" "$HOME/.claude/CLAUDE.md"
       echo "✅ Linked TI global Claude Code instructions (CLAUDE.ti.md)" ;;
    2) ENV_FRAGMENT="$REPO_PATH/hooks/settings.env.mac.json"
       ln -sf "$REPO_PATH/templates/CLAUDE.ti.md" "$HOME/.claude/CLAUDE.md"
       echo "✅ Linked TI global Claude Code instructions (CLAUDE.ti.md)" ;;
    3) ENV_FRAGMENT="$REPO_PATH/hooks/settings.env.home.json"
       ln -sf "$REPO_PATH/templates/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
       echo "✅ Linked home global Claude Code instructions (CLAUDE.md)" ;;
    *) echo "⏭️  Skipped environment selection (CLAUDE.md symlink not updated)" ;;
esac

if [[ -f "$TEMPLATE" ]]; then
    # Build the prospective new settings.json (template, with the env fragment merged on top).
    # Objects are deep-merged (env wins on scalar conflicts); arrays are concatenated so env
    # fragments can extend allow/deny lists without replacing the template's entries.
    PROSPECTIVE="$(mktemp)"
    if [[ -n "$ENV_FRAGMENT" && -f "$ENV_FRAGMENT" ]]; then
        jq -s '
          def jmerge($a; $b):
            if (($a|type) == "object") and (($b|type) == "object")
            then reduce ($b | keys_unsorted[]) as $k (
                $a;
                .[$k] = (
                  if ((.[$k]|type) == "array") and (($b[$k]|type) == "array")
                  then .[$k] + $b[$k]
                  elif ((.[$k]|type) == "object") and (($b[$k]|type) == "object")
                  then jmerge(.[$k]; $b[$k])
                  else $b[$k]
                  end
                )
              )
            else $b
            end;
          jmerge(.[0]; .[1])
        ' "$TEMPLATE" "$ENV_FRAGMENT" > "$PROSPECTIVE"
    else
        cp "$TEMPLATE" "$PROSPECTIVE"
    fi

    MERGE_DRIFT=0
    if [[ -f "$CLAUDE_SETTINGS" ]]; then
        # 1) Timestamped backup — never clobber a previous backup.
        backup="$CLAUDE_SETTINGS.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$CLAUDE_SETTINGS" "$backup"
        echo "✅ Backed up existing settings.json → ${backup:t}"

        # 2) Detect what the new (template-derived) file would drop, split into:
        #      • lost_top : whole top-level keys absent from the new file — cleanly
        #                   mergeable and persistable back into the repo.
        #      • partial  : differences *inside* a key the template also defines. The
        #                   merge keeps the template's scalars and replaces arrays
        #                   wholesale, so these may not survive — flagged for manual review.
        lost_leaf=$(comm -23 \
            <(jq -r 'paths(scalars) | map(tostring) | join(".")' "$CLAUDE_SETTINGS" 2>/dev/null | sort -u) \
            <(jq -r 'paths(scalars) | map(tostring) | join(".")' "$PROSPECTIVE"   2>/dev/null | sort -u))
        lost_top=$(comm -23 \
            <(jq -r 'keys[]' "$CLAUDE_SETTINGS" 2>/dev/null | sort -u) \
            <(jq -r 'keys[]' "$PROSPECTIVE"   2>/dev/null | sort -u))

        # A lost leaf whose top-level key still exists in the new file is partial drift.
        partial=""
        for p in ${(f)lost_leaf}; do
            [[ -z "$p" ]] && continue
            print -rl -- ${(f)lost_top} | grep -qxF -- "${p%%.*}" || partial+="${p}"$'\n'
        done
        partial=$(print -r -- "$partial" | sed -E 's/\.[0-9]+/[]/g' | sed '/^$/d' | sort -u)

        if [[ -n "$lost_top" || -n "$partial" ]]; then
            echo ""
            echo "⚠️  Your current settings.json has content NOT in the new template-derived file:"
            if [[ -n "$lost_top" ]]; then
                echo "    New top-level keys (can be merged back and saved into the repo):"
                print -rl -- ${(f)lost_top} | sed 's/^/      • /'
            fi
            if [[ -n "$partial" ]]; then
                echo "    Differences inside keys the template also defines — the merge keeps the"
                echo "    template's values (arrays are replaced, not unioned), so these may NOT survive:"
                echo "$partial" | sed 's/^/      • /'
                echo "      → compare with ${backup:t} and merge these by hand if you care about them."
            fi
            echo "    [y] merge back  [n] drop (default)  [r] review prospective  [a] abort install"
            read "merge_choice?    Choice [y/n/r/a]: "
            case "$merge_choice" in
                r|R)
                    echo ""
                    echo "    📋  Prospective settings.json (template + env, no merge) saved to:"
                    echo "          $PROSPECTIVE"
                    echo "        diff $CLAUDE_SETTINGS $PROSPECTIVE"
                    echo "⏭️  Aborted — nothing written. Backup preserved: ${backup:t}"
                    exit 0 ;;
                a|A)
                    echo "⏭️  Aborted — nothing written."
                    rm -f "$backup" "$PROSPECTIVE"
                    exit 0 ;;
                y|Y*)
                    # working * prospective: keep working-only keys, template still wins on conflicts.
                    # Array-valued settings (allow/deny lists) are replaced by the prospective's lists.
                    jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$PROSPECTIVE" > "$PROSPECTIVE.merged" \
                        && mv "$PROSPECTIVE.merged" "$PROSPECTIVE"
                    MERGE_DRIFT=1
                    echo "    ✅ Merged your settings into the new settings.json"

                    # Offer to backport each restored top-level key into the repo so the
                    # template (or env fragment) becomes the source of truth for it.
                    if [[ -n "$lost_top" ]]; then
                        echo ""
                        echo "    Persist these restored keys into the repo (so the template stays authoritative)?"
                        [[ -n "$ENV_FRAGMENT" ]] && env_label="env fragment (${ENV_FRAGMENT:t})" || env_label="env fragment (n/a — no env selected)"
                        for key in ${(f)lost_top}; do
                            val=$(jq -c --arg k "$key" '.[$k]' "$PROSPECTIVE")
                            if [[ -n "$ENV_FRAGMENT" ]]; then
                                read "dest?      • '$key' → [b]ase template / [e]nv ($env_label) / [s]kip? [b/e/s]: "
                            else
                                read "dest?      • '$key' → [b]ase template / [s]kip? [b/s]: "
                            fi
                            case "$dest" in
                                b|B) tmpf=$(mktemp)
                                     jq --arg k "$key" --argjson v "$val" '.[$k] = $v' "$TEMPLATE" > "$tmpf" \
                                         && mv "$tmpf" "$TEMPLATE"
                                     BACKPORTED="${BACKPORTED}${BACKPORTED:+, }$key→${TEMPLATE:t}" ;;
                                e|E) if [[ -n "$ENV_FRAGMENT" ]]; then
                                         tmpf=$(mktemp)
                                         jq --arg k "$key" --argjson v "$val" '.[$k] = $v' "$ENV_FRAGMENT" > "$tmpf" \
                                             && mv "$tmpf" "$ENV_FRAGMENT"
                                         BACKPORTED="${BACKPORTED}${BACKPORTED:+, }$key→${ENV_FRAGMENT:t}"
                                     else
                                         echo "        ⏭️  no env fragment selected — skipped"
                                         SKIPPED="${SKIPPED}${SKIPPED:+, }$key"
                                     fi ;;
                                *)   SKIPPED="${SKIPPED}${SKIPPED:+, }$key" ;;
                            esac
                        done
                    fi ;;
                *)
                    echo "    ⏭️  Dropped (still recoverable from ${backup:t})" ;;
            esac
        fi
    fi

    # 3) Write the result.
    # Gate: when overwriting an existing file with no prior drift prompt (no drift
    # was detected), still offer abort/review so a silent template-only update is
    # never applied without the user's awareness.
    if [[ -f "$CLAUDE_SETTINGS" && -z "$lost_top" && -z "$partial" ]] && \
       ! diff -q "$CLAUDE_SETTINGS" "$PROSPECTIVE" >/dev/null 2>&1; then
        echo ""
        echo "⚙️  settings.json will change (template/env updated since last install)."
        echo "   [Y/Enter] proceed  [r] review prospective  [a] abort"
        read "write_gate?"
        case "$write_gate" in
            r|R)
                echo ""
                echo "    📋  Prospective settings.json saved to: $PROSPECTIVE"
                echo "        diff $CLAUDE_SETTINGS $PROSPECTIVE"
                echo "⏭️  Aborted — nothing written. Backup preserved: ${backup:t}"
                exit 0 ;;
            a|A)
                echo "⏭️  Aborted — nothing written."
                rm -f "${backup:-}" "$PROSPECTIVE"
                exit 0 ;;
        esac
    fi
    cp "$PROSPECTIVE" "$CLAUDE_SETTINGS"
    rm -f "$PROSPECTIVE"
    if [[ -n "$ENV_FRAGMENT" ]]; then
        echo "✅ Wrote settings.json (template + ${ENV_FRAGMENT:t})"
    else
        echo "✅ Wrote settings.json (template only)"
    fi

    if [[ "$MERGE_DRIFT" == 1 ]]; then
        echo ""
        if [[ -n "$BACKPORTED" ]]; then
            echo "🔔 Backported into the repo: $BACKPORTED"
            echo "   → review the diff and COMMIT these files so the change persists."
        fi
        if [[ -n "$SKIPPED" ]]; then
            echo "🔔 Not persisted (live settings.json only): $SKIPPED"
            echo "   → the next install will warn about these again until you add them to the"
            echo "     template or a settings.env.*.json fragment and commit."
        fi
    fi
fi

# Create settings.local.json for new machines
if [[ ! -f "$CLAUDE_SETTINGS_LOCAL" ]]; then
    cp "$REPO_PATH/hooks/settings.local.template.json" "$CLAUDE_SETTINGS_LOCAL"
    echo "✅ Created settings.local.json from template"
else
    echo "⏭️  settings.local.json already exists, skipping"
fi

# Create symlinks to skills (directories, so they auto-update with git pulls)
for skill_dir in "$REPO_PATH/skills"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        target="$CLAUDE_USER_SKILLS/$skill_name"
        if [[ -d "$target" && ! -L "$target" ]]; then
            mv "$target" "${target}.backup"
            echo "⚠️  Backed up existing $skill_name/ to ${target}.backup"
        fi
        ln -sfn "$skill_dir" "$target"
        if [[ -L "$target" ]]; then
            echo "🔄 Updated skill: $skill_name"
        else
            echo "✅ Linked skill: $skill_name"
        fi
    fi
done

# --- Local-backend (Ollama) setup for llm-rewrite ----------------------------
# llm-rewrite's `--backend local` mode picks the best installed Ollama model
# from a preference ladder at runtime, so all this script needs to do is pull
# a model appropriate for the local GPU's VRAM.
_pick_default_model() {
    local vram_mib=0
    if command -v nvidia-smi &>/dev/null; then
        vram_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null \
                   | head -1 | tr -d ' ' || echo 0)
        [[ -z "$vram_mib" || "$vram_mib" == *[!0-9]* ]] && vram_mib=0
    fi
    if   (( vram_mib >= 16000 )); then echo "qwen2.5:14b-instruct-q4_K_M"
    elif (( vram_mib >= 6000  )); then echo "qwen2.5:7b-instruct-q4_K_M"
    else                               echo "llama3.2:3b-instruct-q4_K_M"
    fi
}

if command -v ollama &>/dev/null; then
    DEFAULT_MODEL=$(_pick_default_model)
    if curl -sS --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
        if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$DEFAULT_MODEL"; then
            echo "✅ Ollama model already installed: $DEFAULT_MODEL"
        else
            echo "📥 Pulling Ollama model: $DEFAULT_MODEL (this may take a few minutes)"
            if ollama pull "$DEFAULT_MODEL"; then
                echo "✅ Pulled $DEFAULT_MODEL"
            else
                echo "⚠️  Failed to pull $DEFAULT_MODEL — run 'ollama pull $DEFAULT_MODEL' manually"
            fi
        fi
    else
        echo "⚠️  Ollama daemon not reachable at localhost:11434 — start it, then run:"
        echo "      ollama pull $DEFAULT_MODEL"
    fi
else
    echo "ℹ️  ollama not found on PATH. The local backend (--backend local) will not work."
    echo "   Install Ollama from https://ollama.com/ if you want offline rewrites."
fi
# -----------------------------------------------------------------------------

echo ""
echo "🎉 Claude Code workflows updated successfully!"
echo ""
echo "Global CLAUDE.md file updated with slash command instructions."
echo ""
echo "Available commands:"
echo "  /bolden-import - Import Bolden retirement planning data"
echo "  /bulletize     - Convert text to hierarchical bullet points"
echo "  /CA_init       - Initialize comprehensive codebase analysis"
echo "  /commit        - Standardized git commit workflow"
echo "  /distill       - Extract core concepts from any source into markdown"
echo "  /drawio-to-svg - Convert Draw.io files to SVG with batch processing"
echo "  /kb-card       - Author distilled knowledge-base cards (.kb/*.kb.md) from sources"
echo "  /md-to-pdf     - Convert markdown files to PDF"
echo "  /text-clean    - Rewrite text for grammar, clarity, and conciseness"
echo ""
echo "Available skills:"
echo "  /vdk-tda54     - Operate the TDA54 Synopsys VDK simulation"
echo ""
echo "Skills hosted in other repos (run their own install.zsh to activate):"
echo "  slides         - On-brand slide-deck generation, TI by default (~/dev/slide-skill/)"
echo ""
echo "Python skills venv: $CLAUDE_SKILLS_VENV"
echo ""
echo "To make the venv available to claude, add this to your ~/.zshrc:"
echo ""
echo '  claude() {'
echo '      ('
echo '          source "$HOME/.venvs/claude-skills/bin/activate"'
echo '          command claude "$@"'
echo '      )'
echo '  }'
echo ""
echo "To update: cd $(dirname $0) && git pull"