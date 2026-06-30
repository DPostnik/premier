#!/usr/bin/env bash
set -euo pipefail
REPO="${1:?usage: resolve-board.sh <repo-abs-path>}"
CONFIG="${PREMIER_CONFIG:-$HOME/.premier/boards.json}"
[ -f "$CONFIG" ] || { echo ""; exit 0; }
python3 - "$CONFIG" "$REPO" <<'PY'
import json, sys
cfg, repo = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(cfg))
except Exception:
    print(""); raise SystemExit(0)
print(data.get(repo, "") if isinstance(data, dict) else "")
PY
