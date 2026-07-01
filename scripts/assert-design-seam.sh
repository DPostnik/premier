#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:?usage: assert-design-seam.sh <target-repo> <artifact-relpath> <expected-substring>}"
ART="${2:?artifact relpath the design task was supposed to produce}"
EXP="${3:?expected substring inside the artifact}"
cd "$TARGET"
fail() { echo "ASSERT FAIL: $1" >&2; exit 1; }
[ "$(git branch --show-current)" = "main" ] || fail "target not on main"
git cat-file -e "HEAD:$ART" 2>/dev/null || fail "$ART did not land on main"
git show "HEAD:$ART" | grep -q "$EXP" || fail "$ART does not contain '$EXP'"
[ "$(git worktree list | wc -l | tr -d ' ')" = "1" ] || fail "leftover worktrees not pruned"
echo "ASSERT PASS"
