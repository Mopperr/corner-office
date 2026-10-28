"""QA for hh_cat_*.glb catalogue-family models (read-only, never edits a GLB).

    python3 qa_batch1.py <batch_dir> <out.md> [family_id ...]

Checks per file: opens/parses (own GLB reader + trimesh load), bbox in metres
within 5% of the plain variant's w x d x h in families.csv (glTF Y-up: x=w,
y=h, z=d), origin at bottom centre (min y ~0 within 5 mm, x/z centred within
3 cm), material named exactly 'way' exists and is used, materials flat matte
(roughness 0.82 +-0.05, metallic <= 0.05, no textures/images, <= 7 materials),
all colours on the FAMILIES.md (b) palette (copper B87333 / A67B4C flagged),
file < 1 MB, and a front-facing hint: meshes that only belong on the front
(pedal, latch, foot_switch, front_table, label...) must sit at +Z (Godot front
= Blender -Y). Families with no such part report 'n/a'.
"""
import csv, json, os, struct, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
FAM = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
PAL = {"oak": "C68B59", "walnut": "6B4A3A", "pine": "D9B98A", "dark": "2B2622", "cream": "F4F1EA", "white": "EAE6DC",
       "card": "E7DCC6", "terracotta": "D9765F", "sage": "8FA882", "mustard": "E6B655", "blue": "4A6FA5", "rose": "E8B4A8",
       "night": "3E3A4F", "red": "B6453F", "green": "5E7B52", "steel": "C9CED3", "grey": "8E8276", "teal": "4F8A8B",
       "plum": "6E4B6E", "brass": "C9A24E", "kraft": "C9A070", "glass": "BFD6DA", "black": "1E1B19"}
OFF = {"B87333": "copper", "A67B4C": "off-palette A67B4C"}
FRONT_HINTS = ("pedal", "latch", "foot_switch", "front_table", "label", "lid_grip")
TOL_SIZE, TOL_MINY, TOL_CTR = 0.05, 0.005, 0.03


def srgb_hex(lin):
    out = []
    for c in lin[:3]:
        c = max(0.0, min(1.0, c))
        s = c * 12.92 if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
        out.append(int(round(s * 255)))
    return "%02X%02X%02X" % tuple(out)


def near_pal(hx):
    r, g, b = (int(hx[i:i + 2], 16) for i in (0, 2, 4))
    best = None
    for name, p in list(PAL.items()) + [(v, k) for k, v in OFF.items()]:
        pr, pg, pb = (int(p[i:i + 2], 16) for i in (0, 2, 4))
        dist = max(abs(r - pr), abs(g - pg), abs(b - pb))
        if best is None or dist < best[0]:
            best = (dist, name, p)
    return best


def read_glb(path):
    data = open(path, "rb").read()
    magic, ver, length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "not a GLB"
    assert length == len(data), "length mismatch"
    off, js, binc = 12, None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk)
        elif ctype == 0x004E4942:
            binc = chunk
        off += 8 + clen
    return js, binc


def node_mats(js):
    def trs(n):
        if "matrix" in n:
            return np.array(n["matrix"], dtype=float).reshape(4, 4).T
        t = np.array(n.get("translation", [0, 0, 0]), float)
        x, y, z, w = n.get("rotation", [0, 0, 0, 1])
        R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                      [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                      [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
        S = np.diag(n.get("scale", [1, 1, 1]))
        M = np.eye(4)
        M[:3, :3] = R @ S
        M[:3, 3] = t
        return M
    out = []
    def walk(i, P):
        n = js["nodes"][i]
        M = P @ trs(n)
        if "mesh" in n:
            out.append((n.get("name", ""), n["mesh"], M))
        for c in n.get("children", []):
            walk(c, M)
    scene = js["scenes"][js.get("scene", 0)]
    for r in scene["nodes"]:
        walk(r, np.eye(4))
    return out


def positions(js, binc, acc_i):
    a = js["accessors"][acc_i]
    bv = js["bufferViews"][a["bufferView"]]
    assert a["componentType"] == 5126 and a["type"] == "VEC3"
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", 12)
    raw = np.frombuffer(binc, dtype=np.uint8, count=stride * (a["count"] - 1) + 12, offset=start)
    return np.lib.stride_tricks.as_strided(raw.view(np.float32) if stride == 12 else np.frombuffer(binc, np.float32, offset=start),
                                           shape=(a["count"], 3), strides=(stride, 4)).astype(float)


def qa(path, row):
    res = {"file": os.path.basename(path), "problems": [], "notes": []}
    P = res["problems"]
    res["bytes"] = os.path.getsize(path)
    if res["bytes"] >= 1024 * 1024:
        P.append("file size %d bytes >= 1 MB" % res["bytes"])
    try:
        js, binc = read_glb(path)
    except Exception as e:  # noqa
        P.append("does not parse: %s" % e)
        res["opens"] = False
        return res
    try:
        import trimesh
        trimesh.load(path, force="scene")
        res["opens"] = True
    except Exception as e:  # noqa
        res["opens"] = False
        P.append("trimesh load failed: %s" % e)
    pts, used_mats, mesh_names, tris = [], set(), [], 0
    front = []
    for name, mi, M in node_mats(js):
        mesh_names.append(name)
        mpts = []
        for prim in js["meshes"][mi]["primitives"]:
            v = positions(js, binc, prim["attributes"]["POSITION"])
            v = (M @ np.c_[v, np.ones(len(v))].T).T[:, :3]
            mpts.append(v)
            if "material" in prim:
                used_mats.add(prim["material"])
            if "indices" in prim:
                tris += js["accessors"][prim["indices"]]["count"] // 3
        allv = np.vstack(mpts)
        pts.append(allv)
        if any(h in name.lower() for h in FRONT_HINTS):
            front.append((name, float(allv[:, 2].mean())))
    pts = np.vstack(pts)
    mn, mx = pts.min(0), pts.max(0)
    w, h, d = mx - mn
    res["bbox"] = (w, d, h)
    res["tris"] = tris
    res["meshes"] = len(mesh_names)
    want = (float(row["typical_w"]), float(row["typical_d"]), float(row["typical_h"]))
    res["want"] = want
    for lab, got, exp in zip("wdh", (w, d, h), want):
        if abs(got / exp - 1) > TOL_SIZE:
            P.append("%s = %.3f m vs CSV %.3f (%+.1f%%)" % (lab, got, exp, 100 * (got / exp - 1)))
    cx, cz = (mn[0] + mx[0]) / 2, (mn[2] + mx[2]) / 2
    res["origin"] = (cx, mn[1], cz)
    if abs(mn[1]) > TOL_MINY:
        P.append("min y = %.4f (bottom not at origin)" % mn[1])
    if abs(cx) > TOL_CTR or abs(cz) > TOL_CTR:
        P.append("bbox centre x=%.3f z=%.3f not centred" % (cx, cz))
    mats = js.get("materials", [])
    names = [m.get("name", "") for m in mats]
    res["materials"] = names
    if "way" not in names:
        P.append("no material named 'way'")
    elif names.index("way") not in used_mats:
        P.append("material 'way' exists but no mesh uses it")
    if len(mats) > 7:
        P.append("%d materials (> 7)" % len(mats))
    if js.get("textures") or js.get("images"):
        P.append("has textures/images")
    cols = []
    for m in mats:
        pbr = m.get("pbrMetallicRoughness", {})
        r = pbr.get("roughnessFactor", 1.0)
        me = pbr.get("metallicFactor", 1.0)
        if abs(r - 0.82) > 0.05:
            P.append("material %s roughness %.2f" % (m.get("name"), r))
        if me > 0.05:
            P.append("material %s metallic %.2f" % (m.get("name"), me))
        for k in ("baseColorTexture", "metallicRoughnessTexture"):
            if k in pbr:
                P.append("material %s has %s" % (m.get("name"), k))
        for k in ("normalTexture", "occlusionTexture", "emissiveTexture"):
            if k in m:
                P.append("material %s has %s" % (m.get("name"), k))
        if any(c > 0.001 for c in m.get("emissiveFactor", [0, 0, 0])):
            P.append("material %s is emissive" % m.get("name"))
        hx = srgb_hex(pbr.get("baseColorFactor", [1, 1, 1, 1]))
        dist, pname, phx = near_pal(hx)
        cols.append("%s=%s" % (m.get("name"), hx))
        if pname in OFF.values() and dist <= 3:
            P.append("material %s colour %s is %s (not allowed)" % (m.get("name"), hx, pname))
        elif dist > 3:
            P.append("material %s colour %s off palette (nearest %s %s, diff %d)" % (m.get("name"), hx, pname, phx, dist))
    res["colours"] = cols
    if front:
        bad = [n for n, z in front if z <= cz]
        res["front"] = "fail" if bad else "ok"
        if bad:
            P.append("front-only parts at -Z (back in Godot): %s" % ", ".join(sorted(set(bad))))
    else:
        res["front"] = "n/a"
    return res


def main(argv):
    bdir, out = argv[0], argv[1]
    ids = argv[2:]
    rows = {r["family_id"]: r for r in csv.DictReader(open(os.path.join(FAM, "families.csv")))}
    files = [os.path.join(bdir, "hh_cat_%s.glb" % i) for i in ids] if ids else sorted(
        os.path.join(bdir, f) for f in os.listdir(bdir) if f.startswith("hh_cat_") and f.endswith(".glb"))
    results = []
    for f in files:
        fid = os.path.basename(f)[7:-4]
        if not os.path.exists(f):
            results.append({"file": os.path.basename(f), "problems": ["missing"], "bytes": 0})
            continue
        results.append(qa(f, rows[fid]))
    L = ["# QA: %s" % os.path.relpath(bdir, FAM), "",
         "Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.", "",
         "| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |",
         "|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in results:
        if "bbox" not in r:
            L.append("| %s | | | | | | | | | | FAIL |" % r["file"])
            continue
        L.append("| %s | %.0f | %.3f x %.3f x %.3f | %.2f x %.2f x %.2f | %.4f | %.3f / %.3f | %d | %s | %d | %s | %s |" % (
            r["file"], r["bytes"] / 1024, *r["bbox"], *r["want"], r["origin"][1], r["origin"][0], r["origin"][2],
            len(r["materials"]), "yes" if "way" in r["materials"] else "NO", r["tris"], r["front"],
            "PASS" if not r["problems"] else "FAIL (%d)" % len(r["problems"])))
    npass = sum(1 for r in results if not r["problems"])
    L += ["", "**%d / %d pass.**" % (npass, len(results)), "", "## Problems", ""]
    if npass == len(results):
        L.append("None.")
    for r in results:
        for p in r["problems"]:
            L.append("- `%s`: %s" % (r["file"], p))
    L += ["", "## Materials (sRGB hex)", ""]
    for r in results:
        if "colours" in r:
            L.append("- `%s`: %s" % (r["file"], ", ".join(r["colours"])))
    open(out, "w").write("\n".join(L) + "\n")
    print("\n".join(L))


if __name__ == "__main__":
    main(sys.argv[1:])
