#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:?usage: assert-notion-demo.sh <path>}"
cd "$TARGET"
fail() { echo "ASSERT FAIL: $1" >&2; exit 1; }
[ "$(git branch --show-current)" = "main" ] || fail "target not on main"
git cat-file -e "HEAD:shared/button.txt" 2>/dev/null || fail "button task did not land on main"
git cat-file -e "HEAD:pages/home.txt"    2>/dev/null || fail "home task did not land on main"
home="$(git show HEAD:pages/home.txt)"
echo "$home" | grep -qi button || fail "home.txt does not reference button (cross-task order broken)"
[ "$(git worktree list | wc -l | tr -d ' ')" = "1" ] || fail "leftover worktrees not pruned"
echo "ASSERT PASS"
