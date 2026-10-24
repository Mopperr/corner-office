#!/usr/bin/env bash
# Import the global class cache before the smoke scene. A fresh Godot
# checkout otherwise hangs inside that scan when smoke.gd first mentions a class_name.
# The scene quits on its own; --quit-after is only a backstop, and the run
# counts only if SMOKE_OK was printed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path "$ROOT" --import --quit
"$GODOT" --headless --path "$ROOT" --quit-after 20000 res://tests/smoke.tscn 2>&1 | tee /tmp/smoke.log
grep -q "SMOKE_OK" /tmp/smoke.log
