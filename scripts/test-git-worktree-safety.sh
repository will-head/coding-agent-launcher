#!/usr/bin/env bash
# Test: check_vm_git_changes worktree awareness
# Exercises the detection logic in isolation (no VM/SSH needed)
set -uo pipefail

PASS=0; FAIL=0
pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# --- GREEN state: worktree-aware logic (matches updated calf-bootstrap) ---
detect_uncommitted() {
  local root="$1"
  for gitdir in $(find "$root" -name ".git" -type d 2>/dev/null); do
    dir=$(dirname "$gitdir")
    (cd "$dir" 2>/dev/null && [ -n "$(git status --porcelain 2>/dev/null)" ] && echo "$dir") || true
    git -C "$dir" worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{print $2}' \
      | grep -v "^$(cd "$dir" 2>/dev/null && pwd -P 2>/dev/null)$" \
      | while read -r wt_dir; do
          (cd "$wt_dir" 2>/dev/null && [ -n "$(git status --porcelain 2>/dev/null)" ] && echo "$wt_dir") || true
        done
  done
}

detect_unpushed() {
  local root="$1"
  for gitdir in $(find "$root" -name ".git" -type d 2>/dev/null); do
    dir=$(dirname "$gitdir")
    (cd "$dir" 2>/dev/null \
      && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) \
      && [ "$branch" != "HEAD" ] \
      && git rev-parse "${branch}@{u}" >/dev/null 2>&1 \
      && [ -n "$(git log "@{u}.." --oneline 2>/dev/null)" ] \
      && echo "$dir") || true
    git -C "$dir" worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{print $2}' \
      | grep -v "^$(cd "$dir" 2>/dev/null && pwd -P 2>/dev/null)$" \
      | while read -r wt_dir; do
          (cd "$wt_dir" 2>/dev/null \
            && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) \
            && [ "$branch" != "HEAD" ] \
            && git rev-parse "${branch}@{u}" >/dev/null 2>&1 \
            && [ -n "$(git log "@{u}.." --oneline 2>/dev/null)" ] \
            && echo "$wt_dir") || true
        done
  done
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- Test 1: repo with no worktrees — no false positives ---
REPO="$TMP/plain"
git init -q "$REPO"
git -C "$REPO" commit -q --allow-empty -m "init"
result=$(detect_uncommitted "$TMP")
[ -z "$result" ] && pass "no-worktree repo: clean — no false positive" \
                 || fail "no-worktree repo: unexpected output: $result"

# --- Test 2: uncommitted change in main checkout still detected ---
echo "change" > "$REPO/file.txt"
result=$(detect_uncommitted "$TMP")
echo "$result" | grep -q "$REPO" \
  && pass "main checkout: uncommitted change detected" \
  || fail "main checkout: uncommitted change NOT detected"
git -C "$REPO" add . && git -C "$REPO" commit -q -m "add file"

# --- Test 3: linked worktree with uncommitted changes triggers warning ---
# This test FAILS in Red state (current code has no worktree support)
WT="$TMP/worktree"
git -C "$REPO" worktree add -q "$WT" -b wt-branch
echo "worktree change" > "$WT/wt-file.txt"
result=$(detect_uncommitted "$TMP")
echo "$result" | grep -q "$WT" \
  && pass "linked worktree: uncommitted change detected" \
  || fail "linked worktree: uncommitted change NOT detected"

# --- Test 4: non-existent worktree directory — graceful skip ---
git -C "$REPO" worktree add -q "$TMP/ghost-wt" -b ghost-branch
rm -rf "$TMP/ghost-wt"
result=$(detect_uncommitted "$TMP" 2>&1)
echo "$result" | grep -qi "error\|fatal" \
  && fail "ghost worktree: error output" \
  || pass "ghost worktree: graceful skip (non-existent worktree)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
