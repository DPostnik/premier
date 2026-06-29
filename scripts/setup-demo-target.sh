#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:?usage: setup-demo-target.sh <path>}"
rm -rf "$TARGET"
mkdir -p "$TARGET"
git -C "$TARGET" init -q -b main
printf '# demo target\n\nNo project checks. Crewmates just create the requested files.\n' > "$TARGET/CLAUDE.md"
git -C "$TARGET" add CLAUDE.md
git -C "$TARGET" -c user.email=demo@local -c user.name=demo commit -q -m "init demo target"
echo "demo target ready at $TARGET on branch $(git -C "$TARGET" branch --show-current)"
