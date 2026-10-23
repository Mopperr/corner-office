#!/usr/bin/env bash
# Import the global class cache before the smoke scene. A fresh Godot
# checkout otherwise hangs inside that scan when smoke.gd first mentions a class_name.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path "$ROOT" --import --quit
"$GODOT" --headless --path "$ROOT" --quit-after 240 res://tests/smoke.tscn
