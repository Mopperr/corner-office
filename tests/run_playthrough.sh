#!/usr/bin/env bash
# Plays the slice end to end, headless: menu, garage, computer, three jobs
# (pack, truck, drive, unpack, results), the Bakery Loft move, and a save
# roundtrip after each step. Takes about seven minutes because the drives are real.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path "$ROOT" --import --quit
"$GODOT" --headless --path "$ROOT" --resolution 1920x1080 --quit-after 200000 res://tests/playthrough.tscn 2>&1 | tee /tmp/playthrough.log
grep -q "PLAYTHROUGH_OK" /tmp/playthrough.log
