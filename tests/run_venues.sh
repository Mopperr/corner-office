#!/usr/bin/env bash
# Builds every job venue and every rung of the shop ladder, headless, and
# checks each comes up dressed. With CO_SHOTS set and a renderer it also
# takes a picture of each one.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path "$ROOT" --import --quit
"$GODOT" --headless --path "$ROOT" --resolution 1920x1080 --quit-after 20000 res://tests/venues.tscn 2>&1 | tee /tmp/venues.log
grep -q "VENUES_OK" /tmp/venues.log
