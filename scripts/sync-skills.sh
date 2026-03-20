#!/usr/bin/env bash
# sync-skills.sh — Sync skills from the authoritative source into this project.
#
# Derives the skills source by resolving symlinks in ~/.claude/skills/.
# Override: SKILLS_SOURCE=/path/to/skills/skills sync-skills.sh
#
# Project skill files are made read-only after sync to prevent direct edits.
# To update a skill: edit in the skills repo, then re-run this script.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DEST="$PROJECT_ROOT/.claude/skills"
SKILLS_LIST="$PROJECT_ROOT/.claude/skills.list"

# Derive SKILLS_SOURCE from ~/.claude/skills symlinks (unless overridden).
# Looks for a symlink matching a skill in our sync list, not just any symlink.
if [[ -z "${SKILLS_SOURCE:-}" ]]; then
    global_skills_dir="$HOME/.claude/skills"
    SKILLS_SOURCE=""
    # Read skills list to find a candidate skill to resolve
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [[ -z "$line" ]] && continue
        candidate="$global_skills_dir/$line"
        if [[ -L "$candidate" ]]; then
            target="$(readlink "$candidate")"
            # Handle relative symlinks
            if [[ "$target" != /* ]]; then
                target="$(cd "$(dirname "$candidate")" && cd "$(dirname "$target")" && pwd)/$(basename "$target")"
            fi
            SKILLS_SOURCE="$(dirname "$target")"
            break
        fi
    done < "$SKILLS_LIST"
fi

if [[ -z "$SKILLS_SOURCE" || ! -d "$SKILLS_SOURCE" ]]; then
    echo "ERROR: could not derive skills source from ~/.claude/skills symlinks." >&2
    echo "Set SKILLS_SOURCE env var to override." >&2
    exit 1
fi

# Read skills list (skip blank lines and comments)
skills=()
while IFS= read -r line; do
    line="${line%%#*}"   # strip inline comments
    line="${line//[[:space:]]/}"  # strip whitespace
    [[ -z "$line" ]] && continue
    skills+=("$line")
done < "$SKILLS_LIST"

if [[ ${#skills[@]} -eq 0 ]]; then
    echo "No skills listed in $SKILLS_LIST" >&2
    exit 1
fi

echo "Syncing ${#skills[@]} skill(s) from $SKILLS_SOURCE"

for skill in "${skills[@]}"; do
    src="$SKILLS_SOURCE/$skill"
    dst="$SKILLS_DEST/$skill"

    if [[ ! -d "$src" ]]; then
        echo "ERROR: skill '$skill' not found in $SKILLS_SOURCE" >&2
        exit 1
    fi

    # Warn if any project skill files are writable — means they were edited directly
    if [[ -d "$dst" ]]; then
        edits=$(find "$dst" -type f -perm -200 2>/dev/null | wc -l || echo 0)
        if [[ "$edits" -gt 0 ]]; then
            echo "WARNING: $skill has locally edited files (writable). These will be overwritten." >&2
            echo "  Edit in the skills repo instead: $src" >&2
        fi
        # Make writable before sync
        chmod -R u+w "$dst" 2>/dev/null || true
    fi

    # Sync
    rsync -a --delete "$src/" "$dst/"

    # Write sync marker — records skill name so source is identifiable without absolute path
    echo "skill: $skill" > "$dst/.sync-source"

    # Make read-only to prevent direct edits
    find "$dst" -type f -exec chmod 444 {} \;

    echo "  ✓ $skill"
done

echo "Done. Project skill copies are read-only — edit in the skills repo and re-sync."
