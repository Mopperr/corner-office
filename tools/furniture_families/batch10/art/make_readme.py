"""Write ../../README.md from VALIDATION.json, the GLBs and readme_notes.json."""
import json, os, struct
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))
V = json.load(open(os.path.join(OUT, "VALIDATION.json")))
N = json.load(open(os.path.join(HERE, "readme_notes.json")))
batch = os.path.basename(OUT)


def way_parts(path):
    b = open(path, "rb").read(); n = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + n])
    wi = [i for i, m in enumerate(j["materials"]) if m.get("name") == "way"]
    parts = []
    for m in j["meshes"]:
        if any(p.get("material") in wi for p in m["primitives"]):
            nm = m["name"].split(".")[0]
            if nm not in parts:
                parts.append(nm)
    return parts


L = ["# Corner Office catalogue families - %s (art share)" % batch, "",
     "Created by Andrew's Helpers (Grok Bots)", "",
     N["scope"], "",
     "## Spec", "",
     "- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).",
     "- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).",
     "- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).",
     "- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style "
     "matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).",
     "- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).",
     "- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. "
     "Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).",
     "- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` "
     "(`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).",
     "- Contact sheet: `%s_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`." % batch,
     "- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, "
     "`soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; "
     "no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug`, `mat`, `seat` or any other hook name (checked by validate.py), so none of these 12 pick up a triplanar texture.", "",
     "Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && "
     "~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`", "",
     "## Families", "",
     "| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |",
     "|---|---|---|---|---|---|---|---|"]
for r in V["files"]:
    s, c = r["size_m"], r["csv_m"]
    L.append("| %s | %.3f x %.3f x %.3f | %.2f x %.2f x %.2f | %.0f | %s %s | %s | %s | %s |" % (
        r["family_id"], s["w"], s["d"], s["h"], c["w"], c["d"], c["h"], r["size_bytes"] / 1024,
        r["way_colour"]["colourway"], r["way_colour"]["actual"], ", ".join(way_parts(os.path.join(OUT, r["file"]))),
        "PASS" if r["pass"] else "FAIL", N["notes"].get(r["family_id"], "")))
L += ["", N.get("footer", "")]
open(os.path.join(OUT, "README.md"), "w").write("\n".join(L) + "\n")
print("README written", len(V["files"]))
