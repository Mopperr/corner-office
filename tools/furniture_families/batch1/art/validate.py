"""Validate hh_cat_*.glb files (pure Python, no Blender).

    python3 validate.py            # validates MINE in ../../, writes VALIDATION.md/.json there

Checks per file: valid glTF 2.0 GLB (header, chunks, JSON, buffer/accessor
ranges), bbox within 3% of the CSV plain-variant w/d/h, origin at bottom
centre, front toward -Y Blender / +Z glTF (via a named front/back part where the
piece has a front; round or symmetric pieces are marked n/a), a material named
exactly 'way' coloured as the first CSV colour-way, size < 1 MB, no material
near copper B87333, and at most 7 materials (Props caps hh_ props at 7).
"""
import csv, json, math, os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))
CSV = os.path.join(os.path.dirname(OUT), "families.csv")
CFG = json.load(open(os.path.join(HERE, "validate_config.json")))
MINE = CFG["mine"]
FRONT = CFG["front"]   # id -> [part prefix, "front"|"back"] or null
PAL = {"oak": "C68B59", "walnut": "6B4A3A", "pine": "D9B98A", "dark": "2B2622", "cream": "F4F1EA",
       "white": "EAE6DC", "card": "E7DCC6", "terracotta": "D9765F", "sage": "8FA882", "mustard": "E6B655",
       "blue": "4A6FA5", "rose": "E8B4A8", "night": "3E3A4F", "red": "B6453F", "green": "5E7B52",
       "steel": "C9CED3", "grey": "8E8276", "teal": "4F8A8B", "plum": "6E4B6E", "brass": "C9A24E",
       "kraft": "C9A070", "glass": "BFD6DA", "black": "1E1B19"}
ALIAS = {"painted white": "white", "painted sage": "sage", "tan": "kraft", "wicker": "kraft"}
COPPER = (0xB8, 0x73, 0x33)


def lin2srgb(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def qmat(q):
    x, y, z, w = q
    return [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]


def node_m4(n):
    if "matrix" in n:
        m = n["matrix"]
        return [[m[c * 4 + r] for c in range(4)] for r in range(4)]
    t = n.get("translation", [0, 0, 0]); s = n.get("scale", [1, 1, 1]); r = qmat(n.get("rotation", [0, 0, 0, 1]))
    return [[r[i][0] * s[0], r[i][1] * s[1], r[i][2] * s[2], t[i]] for i in range(3)] + [[0, 0, 0, 1]]


def mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def xf(m, p):
    return [m[i][0] * p[0] + m[i][1] * p[1] + m[i][2] * p[2] + m[i][3] for i in range(3)]


def check(fid, row):
    path = os.path.join(OUT, "hh_cat_%s.glb" % fid)
    r = {"family_id": fid, "file": os.path.basename(path), "checks": {}, "notes": []}
    C = r["checks"]
    b = open(path, "rb").read()
    r["size_bytes"] = len(b)
    # --- glTF validity
    ok = True
    magic, ver, length = struct.unpack("<4sII", b[:12])
    ok &= magic == b"glTF" and ver == 2 and length == len(b)
    jl, jt = struct.unpack("<II", b[12:20]); ok &= jt == 0x4E4F534A
    j = json.loads(b[20:20 + jl])
    off = 20 + jl
    bl, bt = struct.unpack("<II", b[off:off + 8]); ok &= bt == 0x004E4942
    ok &= j["asset"]["version"] == "2.0" and j["buffers"][0]["byteLength"] <= bl
    for bv in j["bufferViews"]:
        ok &= bv.get("byteOffset", 0) + bv["byteLength"] <= bl
    for a in j["accessors"]:
        bv = j["bufferViews"][a["bufferView"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]] * {5126: 4, 5123: 2, 5125: 4, 5121: 1}[a["componentType"]]
        ok &= a.get("byteOffset", 0) + (a["count"] - 1) * bv.get("byteStride", n) + n <= bv["byteLength"]
    C["valid_gltf2_glb"] = bool(ok)
    # --- world bbox (glTF Y-up) and per-part centroids
    lo, hi = [1e9] * 3, [-1e9] * 3
    parts = []
    def walk(ni, pm):
        n = j["nodes"][ni]; m = mul(pm, node_m4(n))
        if "mesh" in n:
            mesh = j["meshes"][n["mesh"]]
            plo, phi = [1e9] * 3, [-1e9] * 3
            for p in mesh["primitives"]:
                a = j["accessors"][p["attributes"]["POSITION"]]
                for cx in (a["min"][0], a["max"][0]):
                    for cy in (a["min"][1], a["max"][1]):
                        for cz in (a["min"][2], a["max"][2]):
                            q = xf(m, (cx, cy, cz))
                            for k in range(3):
                                lo[k] = min(lo[k], q[k]); hi[k] = max(hi[k], q[k])
                                plo[k] = min(plo[k], q[k]); phi[k] = max(phi[k], q[k])
            parts.append((mesh.get("name", n.get("name", "")), [(plo[k] + phi[k]) / 2 for k in range(3)]))
        for c in n.get("children", []):
            walk(c, m)
    I = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    for ni in j["scenes"][j.get("scene", 0)]["nodes"]:
        walk(ni, I)
    w, h, d = hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]   # glTF X=w, Y=h, Z=d (Blender Y = -Z)
    cw, cd, ch = float(row["typical_w"]), float(row["typical_d"]), float(row["typical_h"])
    r["size_m"] = {"w": round(w, 4), "d": round(d, 4), "h": round(h, 4)}
    r["csv_m"] = {"w": cw, "d": cd, "h": ch}
    dev = max(abs(w - cw) / cw, abs(d - cd) / cd, abs(h - ch) / ch)
    r["max_size_deviation_pct"] = round(dev * 100, 2)
    C["bbox_within_3pct"] = dev <= 0.03
    tol = 0.003
    C["origin_bottom_centre"] = abs(lo[1]) < tol and abs(lo[0] + hi[0]) / 2 < tol and abs(lo[2] + hi[2]) / 2 < tol
    # --- front (+Z glTF == -Y Blender)
    fr = FRONT.get(fid)
    if fr:
        pref, side = fr
        zs = [c[2] for nm, c in parts if nm.split(".")[0] == pref]
        if zs:
            z = sum(zs) / len(zs); cz = (lo[2] + hi[2]) / 2
            C["front_minus_y"] = (z > cz) if side == "front" else (z < cz)
            r["notes"].append("front check: '%s' parts sit at the %s (glTF z=%.3f, centre %.3f)" % (pref, side, z, cz))
        else:
            C["front_minus_y"] = False
            r["notes"].append("front marker '%s' not found" % pref)
    else:
        C["front_minus_y"] = None
        r["notes"].append("front check n/a: round/symmetric piece; built with front at -Y by convention")
    # --- materials
    mats = j.get("materials", [])
    names = [m.get("name", "") for m in mats]
    way_key = row["colourways"].split(";")[0].strip().lower()
    way_key = ALIAS.get(way_key, way_key)
    want = PAL.get(way_key)
    way_hex = None
    for m in mats:
        if m.get("name") == "way":
            f = m.get("pbrMetallicRoughness", {}).get("baseColorFactor", [1, 1, 1, 1])
            way_hex = "%02X%02X%02X" % tuple(round(lin2srgb(c) * 255) for c in f[:3])
    r["way_colour"] = {"colourway": way_key, "expected": want, "actual": way_hex}
    C["way_material"] = way_hex is not None
    C["way_colour_matches_first_colourway"] = way_hex is not None and want is not None and all(
        abs(int(way_hex[i:i + 2], 16) - int(want[i:i + 2], 16)) <= 2 for i in (0, 2, 4))
    near = []
    for m in mats:
        f = m.get("pbrMetallicRoughness", {}).get("baseColorFactor", [1, 1, 1, 1])
        rgb = [lin2srgb(c) * 255 for c in f[:3]]
        if math.dist(rgb, COPPER) < 40:
            near.append(m.get("name"))
    C["no_copper_B87333"] = not near
    C["under_1MB"] = len(b) < 1024 * 1024
    C["max_7_materials"] = len(mats) <= 7
    C["no_textures"] = not j.get("images") and not j.get("textures")
    r["materials"] = names
    r["mesh_parts"] = len(parts)
    r["pass"] = all(v is not False for v in C.values())
    return r


def main():
    rows = {r["family_id"]: r for r in csv.DictReader(open(CSV))}
    res = [check(f, rows[f]) for f in MINE]
    json.dump({"generated_by": "_build/art/validate.py", "files": res,
               "all_pass": all(r["pass"] for r in res)}, open(os.path.join(OUT, "VALIDATION.json"), "w"), indent=1)
    keys = list(res[0]["checks"])
    L = ["# VALIDATION - %s (art share)" % os.path.basename(OUT), "",
         "Created by Andrew's Helpers (Grok Bots)", "",
         "Generated by `_build/art/validate.py` (pure-Python GLB parser). Sizes in metres, glTF Y-up: w = X, h = Y, d = Z.",
         "PASS = ok, FAIL = not to spec, n/a = not applicable.", "",
         "| file | w x d x h (actual) | CSV | max dev | KB | " + " | ".join(keys) + " | result |",
         "|---|---|---|---|---|" + "---|" * len(keys) + "---|"]
    for r in res:
        s, c = r["size_m"], r["csv_m"]
        L.append("| %s | %.3f x %.3f x %.3f | %.2f x %.2f x %.2f | %.2f%% | %.0f | %s | **%s** |" % (
            r["file"], s["w"], s["d"], s["h"], c["w"], c["d"], c["h"], r["max_size_deviation_pct"],
            r["size_bytes"] / 1024, " | ".join({True: "PASS", False: "FAIL", None: "n/a"}[r["checks"][k]] for k in keys),
            "PASS" if r["pass"] else "FAIL"))
    L += ["", "## Notes", ""]
    for r in res:
        L.append("- **%s**: way %s (expected %s from '%s'); materials: %s; %s" % (
            r["family_id"], r["way_colour"]["actual"], r["way_colour"]["expected"], r["way_colour"]["colourway"],
            ", ".join(r["materials"]), "; ".join(r["notes"])))
    L += ["", "Overall: **%s** (%d/%d files pass)" % ("ALL PASS" if all(r["pass"] for r in res) else "SOME FAIL",
                                                     sum(r["pass"] for r in res), len(res))]
    open(os.path.join(OUT, "VALIDATION.md"), "w").write("\n".join(L) + "\n")
    for r in res:
        print(r["family_id"], "PASS" if r["pass"] else "FAIL", r["size_m"], r["max_size_deviation_pct"],
              {k: v for k, v in r["checks"].items() if v is not True}, r["notes"][0][:70])


if __name__ == "__main__":
    main()
