#!/usr/bin/env bash
# Test: check_vm_git_changes worktree awareness
# Exercises the detection logic in isolation (no VM/SSH needed)
set -uo pipefail

PASS=0; FAIL=0
pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# --- detect_changes: single-call combining uncommitted + unpushed checks ---
# Outputs "U:/path" for uncommitted, "P:/path" for unpushed
# Mirrors the logic embedded in calf-bootstrap's single SSH call.
detect_changes() {
  local root="$1"
  for gitdir in $(find "$root" -name ".git" -type d 2>/dev/null); do
    dir=$(dirname "$gitdir")
    (cd "$dir" 2>/dev/null && [ -n "$(git status --porcelain 2>/dev/null)" ] && echo "U:$dir") || true
    (cd "$dir" 2>/dev/null \
      && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) \
      && [ "$branch" != "HEAD" ] \
      && git rev-parse "${branch}@{u}" >/dev/null 2>&1 \
      && [ -n "$(git log "@{u}.." --oneline 2>/dev/null)" ] \
      && echo "P:$dir") || true
    git -C "$dir" worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{print $2}' \
      | grep -v "^$(cd "$dir" 2>/dev/null && pwd -P 2>/dev/null)$" \
      | while read -r wt_dir; do
          (cd "$wt_dir" 2>/dev/null && [ -n "$(git status --porcelain 2>/dev/null)" ] && echo "U:$wt_dir") || true
          (cd "$wt_dir" 2>/dev/null \
            && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) \
            && [ "$branch" != "HEAD" ] \
            && git rev-parse "${branch}@{u}" >/dev/null 2>&1 \
            && [ -n "$(git log "@{u}.." --oneline 2>/dev/null)" ] \
            && echo "P:$wt_dir") || true
        done
  done
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/plain"
git init -q "$REPO"
git -C "$REPO" commit -q --allow-empty -m "init"

# --- Test 1: when_clean_repo_should_produce_no_output ---
result=$(detect_changes "$TMP")
[ -z "$result" ] && pass "detect_changes: clean repo produces no output" \
                 || fail "detect_changes: clean repo — unexpected output: $result"

# --- Test 2: when_uncommitted_changes_should_produce_U_tagged_line ---
echo "change" > "$REPO/file.txt"
result=$(detect_changes "$TMP")
echo "$result" | grep -q "^U:" \
  && pass "detect_changes: uncommitted change produces U: tagged line" \
  || fail "detect_changes: uncommitted change — no U: tagged line in output"
git -C "$REPO" add . && git -C "$REPO" commit -q -m "add file"

# --- Test 3: when_worktree_has_uncommitted_should_produce_U_tagged_line ---
WT="$TMP/worktree"
git -C "$REPO" worktree add -q "$WT" -b wt-branch
echo "worktree change" > "$WT/wt-file.txt"
result=$(detect_changes "$TMP")
echo "$result" | grep -q "^U:" \
  && pass "detect_changes: linked worktree uncommitted change produces U: tagged line" \
  || fail "detect_changes: linked worktree uncommitted change — no U: tagged line"

# --- Test 4: when_ghost_worktree_should_gracefully_skip ---
git -C "$REPO" worktree add -q "$TMP/ghost" -b ghost-branch
rm -rf "$TMP/ghost"
result=$(detect_changes "$TMP" 2>&1)
echo "$result" | grep -qi "error\|fatal" \
  && fail "detect_changes: ghost worktree caused error output" \
  || pass "detect_changes: ghost worktree gracefully skipped"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
