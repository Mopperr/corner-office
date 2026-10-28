"""Validate catalogue files: data/items/*.json, or the files given.

    python3 tools/check_items.py                 # every file in data/items
    python3 tools/check_items.py data/items/team_kitchen.json

Checks the format docs/ITEMS.md describes: every item has a name, a line,
a room, a mount, positive sizes and a model "proc:<id>" whose props entry
exists with at least two parts, each part a box, cyl or sph with a size, a
centre inside the item's own footprint and a six-digit hex colour. Ids
must be unique across the folder and data/content.json. Exit code 1 on
any error. Needs only Python.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOMS = {"kitchen", "bathroom", "bedroom", "living", "loft", "shed", "office"}
MOUNTS = {"floor", "small", "hang"}
HEX = re.compile(r"^[0-9A-Fa-f]{6}$")


def check_file(path, seen, errors):
    try:
        data = json.load(open(path))
    except Exception as exc:  # noqa: BLE001
        errors.append("%s: not valid JSON (%s)" % (path, exc))
        return 0
    if not isinstance(data, dict) or "items" not in data or "props" not in data:
        errors.append("%s: needs top-level \"items\" and \"props\" objects" % path)
        return 0
    items, props = data["items"], data["props"]
    for item_id, defn in items.items():
        where = "%s:%s" % (os.path.basename(path), item_id)
        if not re.match(r"^[a-z0-9_]+$", item_id):
            errors.append("%s: id must be lowercase letters, digits and underscores" % where)
        if item_id in seen:
            errors.append("%s: duplicate id (also in %s)" % (where, seen[item_id]))
        seen[item_id] = os.path.basename(path)
        for key in ("name", "flavor"):
            if not isinstance(defn.get(key), str) or not defn[key].strip():
                errors.append("%s: missing %s" % (where, key))
        if defn.get("room") not in ROOMS:
            errors.append("%s: room must be one of %s" % (where, sorted(ROOMS)))
        if defn.get("mount") not in MOUNTS:
            errors.append("%s: mount must be one of %s" % (where, sorted(MOUNTS)))
        dims = []
        for key in ("w", "d", "h"):
            v = defn.get(key)
            if not isinstance(v, (int, float)) or v <= 0 or v > 3.0:
                errors.append("%s: %s must be a number between 0 and 3" % (where, key))
                v = 1.0
            dims.append(float(v))
        model = str(defn.get("model", ""))
        if not model.startswith("proc:"):
            errors.append("%s: model must be \"proc:<id>\"" % where)
            continue
        parts = props.get(model[5:])
        if not isinstance(parts, list) or len(parts) < 2:
            errors.append("%s: props[%s] must be a list of at least two parts" % (where, model[5:]))
            continue
        w, d, h = dims
        for i, part in enumerate(parts):
            pw = "%s part %d" % (where, i)
            if part.get("t", "box") not in ("box", "cyl", "sph"):
                errors.append("%s: t must be box, cyl or sph" % pw)
            size = part.get("s", [])
            need = {"box": 3, "cyl": 2, "sph": 1}.get(part.get("t", "box"), 3)
            if not isinstance(size, list) or len(size) < need or any((not isinstance(v, (int, float)) or v <= 0) for v in size[:need]):
                errors.append("%s: s needs %d positive numbers" % (pw, need))
            centre = part.get("p", [0, 0, 0])
            if not isinstance(centre, list) or len(centre) != 3 or any(not isinstance(v, (int, float)) for v in centre):
                errors.append("%s: p must be [x, y, z]" % pw)
            else:
                if abs(centre[0]) > w * 0.6 + 0.08 or abs(centre[2]) > d * 0.6 + 0.08 or centre[1] > h * 1.15 + 0.08 or centre[1] < -0.02:
                    errors.append("%s: centre %s is outside the item's %.2f x %.2f x %.2f" % (pw, centre, w, d, h))
            if not HEX.match(str(part.get("c", ""))):
                errors.append("%s: c must be a six-digit hex colour" % pw)
            if "r" in part and (not isinstance(part["r"], list) or len(part["r"]) != 3):
                errors.append("%s: r must be [x, y, z] radians" % pw)
    for prop_id in props:
        if prop_id not in items:
            errors.append("%s: props[%s] has no item" % (os.path.basename(path), prop_id))
    return len(items)


def main(argv):
    paths = argv[1:] or sorted(glob.glob(os.path.join(ROOT, "data", "items", "*.json")))
    seen = {}
    content = os.path.join(ROOT, "data", "content.json")
    if os.path.exists(content):
        for item_id in json.load(open(content)).get("items", {}):
            seen[item_id] = "content.json"
    errors = []
    total = 0
    for path in paths:
        n = check_file(path, seen, errors)
        total += n
        print("%s: %d items" % (os.path.relpath(path, ROOT), n))
    for line in errors[:60]:
        print("ERROR " + line)
    if len(errors) > 60:
        print("... and %d more" % (len(errors) - 60))
    print("%d items, %d errors" % (total, len(errors)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
