"""Design Specialist builder for Corner Office catalogue-family GLBs (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design.py -- batch1|batch2 [family_id ...]

Reuses Art Specialist's helpers and batch-1 builders from ../art/build_families.py
(imported read-only, never modified). Batch-2 builders live in this file.
Spec: plain variant w/d/h from families.csv in metres, origin bottom centre,
front toward -Y in Blender (+Z in Godot), flat matte Principled (rough 0.82),
palette colours only, recolourable surface = material 'way' (first colour-way).
Output: batch1 -> families/batch1/, batch2 -> families/batch2/.
"""
import importlib.util
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
B1 = os.path.dirname(os.path.dirname(HERE))  # .../families/batch1
FAM = os.path.dirname(B1)
_spec = importlib.util.spec_from_file_location("art_bf", os.path.join(B1, "_build", "art", "build_families.py"))
art = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(art)
box, cyl, sphere, torus, arc_bar, legs4, splay_leg = art.box, art.cyl, art.sphere, art.torus, art.arc_bar, art.legs4, art.splay_leg
WAY = art.WAY
# extra colour-way names used by batch 2 (mapped onto palette keys)
ALIAS = dict(art.WAY_ALIAS)
ALIAS.update({"gilt": "brass", "leather": "walnut", "tin": "steel"})

BATCH1 = ["floor_lamp_v", "kitchen_trolley", "high_chair", "laundry_hamper", "bath_bin",
          "side_table_v", "dressing_stool", "armchair_v", "coat_stand", "rocking_chair"]
BATCH2 = ["bean_bag", "coffee_table_v", "cot", "clothes_rail", "bedroom_chair", "footstool",
          "picture_v", "wall_mirror", "tall_bookcase", "trunk_v"]
B1_OVERRIDES = {}  # design fixes to Art's draft builders (after contact-sheet review)


def dressing_stool(w, d, h):
    """Art's draft, but the single stretcher floated mid-air at y=0 between the
    legs; replaced with an H-stretcher that meets the splayed legs."""
    ch = 0.07
    box((w, d, ch), (0, 0, h - ch / 2), WAY, 0.03, name="cushion")
    box((w, d, 0.01), (0, 0, h - ch + 0.005), "cream", 0.004, name="piping")
    for x in (-w * 0.2, 0.0, w * 0.2):
        sphere(0.01, (x, 0, h - 0.003), "cream", scale=(1, 1, 0.5), name="button")
    box((w - 0.04, d - 0.04, 0.06), (0, 0, h - ch - 0.04), "white", 0.008, name="apron")
    for sx in (-1, 1):
        for sy in (-1, 1):
            top = (sx * (w / 2 - 0.045), sy * (d / 2 - 0.045), h - ch)
            bot = (sx * (w / 2 - 0.022), sy * (d / 2 - 0.022), 0.0)
            splay_leg(top, bot, 0.038, "white", name="leg", round_=True)
    zs = h * 0.2
    t = zs / (h - ch)  # fraction up the leg
    lx = w / 2 - 0.022 - (0.023 * t)
    ly = d / 2 - 0.022 - (0.023 * t)
    for sx in (-1, 1):
        box((0.018, 2 * ly, 0.018), (sx * lx, 0, zs), "white", 0.004, name="stretcher")
    box((2 * lx, 0.018, 0.018), (0, 0, zs), "white", 0.004, name="stretcher")


B1_OVERRIDES["dressing_stool"] = dressing_stool

# ======================================================= batch 2 builders
BUILDERS2 = {}


def reg(f):
    BUILDERS2[f.__name__] = f
    return f


@reg
def bean_bag(w, d, h):
    # big slouchy pear: squashed base, a seat dent at the front, back hump, top handle
    r = w / 2
    sphere(r, (0, 0, h * 0.42), WAY, scale=(1, 1, h * 0.84 / w), name="body")
    sphere(r * 0.78, (0, d * 0.12, h * 0.62), WAY, scale=(1.05, 0.72, 0.62), name="back_hump")
    sphere(r * 0.62, (0, -d * 0.14, h * 0.55), WAY, scale=(1.0, 0.9, 0.35), name="seat")
    for s in (-1, 1):  # side seams
        sphere(r * 0.12, (s * r * 0.86, 0.0, h * 0.42), WAY, scale=(0.4, 1.2, 0.8), name="seam")
    torus(0.05, 0.012, (0, d * 0.26, h * 0.93), "cream", rot=(0, math.pi / 2, 0), name="handle")


@reg
def coffee_table_v(w, d, h):
    # oak frame with a lower shelf; the top is the colour-way surface (glass, oak, painted...)
    top_t = 0.03
    lt = 0.05
    legs4(w - 0.04, d - 0.04, h - top_t, "oak", lt, 0.0, name="leg")
    box((w - 0.04, d - 0.04, 0.07), (0, 0, h - top_t - 0.035), "oak", 0.006, name="apron")
    box((w, d, top_t), (0, 0, h - top_t / 2), WAY, 0.008, name="top")
    sz = 0.1
    box((w - 0.1, d - 0.1, 0.022), (0, 0, sz), "oak", 0.005, name="shelf")
    # a few things on the shelf so it reads at small size
    for i, (c, t) in enumerate((("blue", 0.035), ("mustard", 0.03), ("rose", 0.028))):
        box((0.26 - i * 0.03, 0.18 - i * 0.015, t), (-w * 0.22 + i * 0.01, 0.0, sz + 0.011 + sum((0.035, 0.03, 0.028)[:i]) + t / 2),
            c, 0.004, rot=(0, 0, 0.12 * (i - 1)), name="book")
    cyl(0.06, 0.12, (w * 0.25, 0.02, sz + 0.011 + 0.06), "kraft", "Z", 18, r2=0.07, name="basket", bevel=0.008)


@reg
def cot(w, d, h):
    # baby cot: four posts, top/bottom rails, bars on all sides, solid ends, mattress
    pt = 0.05
    rail_lo = 0.22
    for x in (-w / 2 + pt / 2, w / 2 - pt / 2):
        for y in (-d / 2 + pt / 2, d / 2 - pt / 2):
            box((pt, pt, h - 0.02), (x, y, (h - 0.02) / 2), WAY, 0.008, name="post")
            sphere(pt * 0.5, (x, y, h - 0.025), WAY, scale=(1, 1, 0.9), name="finial")
    for y in (-d / 2 + pt / 2, d / 2 - pt / 2):
        for z in (rail_lo, h - 0.06):
            box((w - 2 * pt, 0.035, 0.04), (0, y, z), WAY, 0.006, name="rail")
        n = 11
        for i in range(n):
            x = -w / 2 + pt + (i + 0.5) * (w - 2 * pt) / n
            box((0.022, 0.022, h - 0.06 - rail_lo), (x, y, (rail_lo + h - 0.06) / 2), WAY, 0.003, name="bar")
    for x in (-w / 2 + pt / 2, w / 2 - pt / 2):
        box((0.022, d - 2 * pt, h - 0.08 - rail_lo + 0.04), (x, 0, (rail_lo + h - 0.08) / 2 + 0.02), WAY, 0.006, name="end_panel")
    box((w - 2 * pt - 0.01, d - 2 * pt - 0.01, 0.025), (0, 0, rail_lo + 0.02), WAY, 0.004, name="base")
    box((w - 2 * pt - 0.03, d - 2 * pt - 0.03, 0.1), (0, 0, rail_lo + 0.085), "cream", 0.03, name="mattress")
    box((0.36, d - 2 * pt - 0.08, 0.04), (w * 0.22, 0, rail_lo + 0.155), "rose", 0.015, name="blanket")
    box((0.22, 0.3, 0.06), (-w * 0.32, 0, rail_lo + 0.165), "white", 0.025, name="pillow")


@reg
def clothes_rail(w, d, h):
    # metal frame (colour-way) on two castored feet, oak base shelf, garments on hangers
    pr = 0.016
    ux = w / 2 - 0.03
    for s in (-1, 1):
        cyl(pr, h - 0.08, (s * ux, 0, 0.06 + (h - 0.08) / 2), WAY, "Z", 12, name="upright")
        box((0.04, d, 0.03), (s * ux, 0, 0.055), WAY, 0.006, name="foot")
        for y in (-d / 2 + 0.03, d / 2 - 0.03):
            cyl(0.02, 0.018, (s * ux, y, 0.02), WAY, "X", 12, name="castor")
    cyl(pr, w - 0.02, (0, 0, h - 0.04), WAY, "X", 12, name="rail")
    for s in (-1, 1):
        sphere(0.022, (s * (w / 2 - 0.011), 0, h - 0.04), WAY, name="rail_cap")
    box((w - 0.1, d - 0.08, 0.02), (0, 0, 0.16), "oak", 0.004, name="shelf")
    for i, c in enumerate(("mustard", "sage", "terracotta")):  # shoe boxes on the shelf
        box((0.16, 0.24, 0.1), (-w * 0.3 + i * 0.2, 0, 0.17 + 0.05), c, 0.01, name="storage_box")
    # max 7 materials (hh_ GLBs keep up to 7 in game): way, oak, steel + 4 garment colours
    cols = ["sage", "cream", "terracotta", "mustard", "sage", "cream", "terracotta"]
    n = len(cols)
    gw = d * 0.82
    for i, c in enumerate(cols):
        x = -ux + 0.08 + i * (2 * ux - 0.16) / (n - 1)
        L = 0.75 + 0.18 * ((i * 37) % 3) / 2
        cyl(0.006, 0.05, (x, 0, h - 0.07), "steel", "Z", 8, name="hanger_hook")
        box((0.012, gw - 0.04, 0.012), (x, 0, h - 0.1), "steel", 0.003, name="hanger")
        box((0.035, gw, 0.09), (x, 0, h - 0.15), c, 0.02, name="garment_shoulder")
        box((0.03, gw * 0.9, L), (x, 0, h - 0.15 - L / 2), c, 0.01, name="garment")


@reg
def bedroom_chair(w, d, h):
    # simple wooden side chair with a padded seat and slat back
    seat_z = 0.45
    lt = 0.038
    legs4(w - 0.02, d - 0.02, seat_z - 0.03, WAY, lt, 0.0, name="leg")
    box((w, d, 0.035), (0, 0, seat_z - 0.0175), WAY, 0.008, name="seat")
    box((w - 0.06, d - 0.08, 0.05), (0, -0.02, seat_z + 0.02), "rose", 0.02, name="cushion")
    by = d / 2 - 0.01 - lt / 2
    for x in (-w / 2 + 0.01 + lt / 2, w / 2 - 0.01 - lt / 2):
        box((lt, lt, h - seat_z), (x, by, seat_z + (h - seat_z) / 2), WAY, 0.006, name="back_post")
    box((w - 0.02, 0.035, 0.09), (0, by, h - 0.045), WAY, 0.012, name="back_rail")
    for x in (-0.09, 0.0, 0.09):
        box((0.04, 0.02, h - seat_z - 0.12), (x, by, seat_z + 0.03 + (h - seat_z - 0.12) / 2), WAY, 0.005, name="back_slat")
    for y in (-d / 2 + 0.03, d / 2 - 0.03):
        box((w - 0.08, 0.02, 0.025), (0, y, 0.14), WAY, 0.004, name="stretcher")


@reg
def footstool(w, d, h):
    # buttoned upholstered top on short tapered walnut legs
    lh = 0.12
    box((w, d, h - lh), (0, 0, lh + (h - lh) / 2), WAY, 0.045, name="cushion")
    box((w - 0.03, d - 0.03, 0.012), (0, 0, lh + 0.012), "cream", 0.005, name="piping")
    for x in (-w * 0.22, 0.0, w * 0.22):
        for y in (-d * 0.18, d * 0.18):
            sphere(0.012, (x, y, h - 0.004), "cream", scale=(1, 1, 0.6), name="button")
    legs4(w - 0.03, d - 0.03, lh, "walnut", 0.045, 0.0, name="leg", taper=0.03)


@reg
def picture_v(w, d, h):
    # painting: frame (colour-way) around a little landscape, front at -Y
    ft = 0.045
    fy = 0.0
    box((w, d, ft), (0, fy, ft / 2), WAY, 0.006, name="frame")
    box((w, d, ft), (0, fy, h - ft / 2), WAY, 0.006, name="frame")
    for x in (-w / 2 + ft / 2, w / 2 - ft / 2):
        box((ft, d, h - 2 * ft), (x, fy, h / 2), WAY, 0.006, name="frame")
    iw, ih = w - 2 * ft, h - 2 * ft
    cy = d / 2 - 0.02  # canvas recessed toward the wall
    box((iw, 0.01, ih), (0, cy, h / 2), "cream", 0.0, name="canvas")
    py = cy - 0.007
    box((iw, 0.006, ih * 0.55), (0, py, ft + ih * 0.725), "blue", 0.0, name="paint_sky")
    box((iw, 0.008, ih * 0.32), (0, py - 0.001, ft + ih * 0.16), "green", 0.0, name="paint_field")
    box((iw * 0.7, 0.008, ih * 0.22), (-iw * 0.15, py - 0.002, ft + ih * 0.38), "sage", 0.0, rot=(0, 0.12, 0), name="paint_hill")
    cyl(ih * 0.1, 0.006, (iw * 0.25, py - 0.003, ft + ih * 0.75), "mustard", "Y", 18, name="paint_sun")
    box((iw * 0.08, 0.008, ih * 0.18), (iw * 0.3, py - 0.004, ft + ih * 0.3), "terracotta", 0.0, name="paint_house")


@reg
def wall_mirror(w, d, h):
    # rectangular mirror: frame (colour-way), pale glass with two highlight streaks
    ft = 0.055
    box((w, d, ft), (0, 0, ft / 2), WAY, 0.008, name="frame")
    box((w, d, ft), (0, 0, h - ft / 2), WAY, 0.008, name="frame")
    for x in (-w / 2 + ft / 2, w / 2 - ft / 2):
        box((ft, d, h - 2 * ft), (x, 0, h / 2), WAY, 0.008, name="frame")
    iw, ih = w - 2 * ft, h - 2 * ft
    gy = d / 2 - 0.016
    box((iw, 0.01, ih), (0, gy, h / 2), "glass", 0.0, name="mirror")
    for k, (xo, ww) in enumerate(((-0.12, 0.05), (-0.03, 0.022))):
        box((ww, 0.004, ih * 0.75), (xo * w / 0.7, gy - 0.007, h / 2), "white", 0.0, rot=(0, -0.55, 0), name="mirror_glint")


@reg
def tall_bookcase(w, d, h):
    # tall open bookcase: carcass (colour-way), 5 shelves of books, a plant on top shelf
    st = 0.025
    for x in (-w / 2 + st / 2, w / 2 - st / 2):
        box((st, d, h), (x, 0, h / 2), WAY, 0.006, name="side")
    box((w, d, st), (0, 0, h - st / 2), WAY, 0.006, name="top")
    box((w - 2 * st, d - 0.02, 0.08), (0, -0.01, 0.04), WAY, 0.004, name="plinth")
    box((w - 2 * st, 0.012, h - st), (0, d / 2 - 0.006, (h - st) / 2), WAY, 0.0, name="back")
    n = 5
    z0 = 0.08
    gap = (h - st - z0) / n
    shelves = [z0 + i * gap for i in range(n)]
    for z in shelves[1:]:
        box((w - 2 * st, d - 0.015, st), (0, -0.0075, z), WAY, 0.004, name="shelf")
    cols = ["blue", "mustard", "terracotta", "sage", "night", "cream"]  # <= 7 materials incl. way
    iw = w - 2 * st
    k = 0
    for si, z in enumerate(shelves):
        zb = z + (st / 2 if si else 0.0)
        x = -iw / 2 + 0.01
        lim = iw / 2 - 0.01
        fill = [0.95, 0.6, 0.85, 0.7, 0.5][si]
        while x < -iw / 2 + iw * fill:
            bw = 0.028 + 0.012 * ((k * 7) % 3)
            bh = gap * (0.62 + 0.08 * ((k * 5) % 4))
            if x + bw > lim:
                break
            box((bw, d * 0.75, bh), (x + bw / 2, -0.01, zb + bh / 2), cols[k % len(cols)], 0.004, name="book")
            x += bw + 0.002
            k += 1
        if si == 1:  # a leaning book and a box
            box((0.035, d * 0.75, gap * 0.66), (x + 0.04, -0.01, zb + gap * 0.31), "terracotta", 0.004, rot=(0, 0.35, 0), name="book")
            box((0.2, d * 0.7, 0.14), (iw / 2 - 0.13, -0.01, zb + 0.07), "mustard", 0.01, name="storage_box")
        if si == 3:
            box((0.16, 0.16, 0.025), (iw / 2 - 0.12, -0.02, zb + 0.0125), "blue", 0.003, name="book")
            box((0.14, 0.15, 0.025), (iw / 2 - 0.12, -0.02, zb + 0.0375), "mustard", 0.003, name="book")
        if si == 4:
            cyl(0.07, 0.12, (iw / 2 - 0.14, -0.02, zb + 0.06), "terracotta", "Z", 18, r2=0.085, name="pot", bevel=0.006)
            sphere(0.1, (iw / 2 - 0.14, -0.02, zb + 0.2), "sage", scale=(1, 1, 0.8), name="plant")


@reg
def trunk_v(w, d, h):
    # storage trunk: body + slightly domed lid (colour-way), oak bands, brass corners and latch
    lid_h = 0.13
    bh = h - lid_h
    box((w - 0.02, d - 0.02, bh), (0, 0, bh / 2), WAY, 0.012, name="body")
    box((w - 0.02, d - 0.02, lid_h * 0.6), (0, 0, bh + lid_h * 0.3), WAY, 0.015, name="lid")
    zt = bh + lid_h * 0.6  # top of the flat lid part; the dome adds the rest up to h
    rr = (d - 0.02) / 2
    o = cyl(rr, w - 0.03, (0, 0, 0), WAY, "X", 18, name="lid_dome")
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    k = (h - zt) / rr
    for v in o.data.vertices:
        v.co.z = v.co.z * k + zt
    for x in (-w * 0.28, w * 0.28):  # wooden bands wrap front, top, back
        box((0.06, d, bh), (x, 0, bh / 2), "oak", 0.006, name="band")
        box((0.06, d, lid_h * 0.6), (x, 0, bh + lid_h * 0.3), "oak", 0.006, name="band")
    box((w, d, 0.03), (0, 0, bh - 0.015), "oak", 0.006, name="lid_rim")
    box((w, d, 0.03), (0, 0, 0.015), "oak", 0.006, name="base_rim")
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for z in (0.03, bh - 0.03):
            box((0.06, d, 0.06), (x, 0, z), "brass", 0.008, name="corner")
    box((0.08, 0.02, 0.1), (0, -d / 2 + 0.005, bh), "brass", 0.006, name="latch")
    for s in (-1, 1):
        torus(0.045, 0.01, (s * (w / 2 - 0.005), 0, bh * 0.62), "dark", rot=(0, math.pi / 2, 0), name="handle")



# ======================================================= build driver
def build(fid, row, outdir):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    art._mats.clear()
    first = row["colourways"].split(";")[0].strip()
    art._WAY_HEX = art.PAL[ALIAS.get(first, first)]
    w, d, h = float(row["typical_w"]), float(row["typical_d"]), float(row["typical_h"])
    fn = B1_OVERRIDES.get(fid) or BUILDERS2.get(fid) or art.BUILDERS[fid]
    fn(w, d, h)
    raw, size = art.fit_and_centre(w, d, h)
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(outdir, "hh_cat_%s.glb" % fid)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=False, export_yup=True,
                              export_texcoords=False, export_normals=True, export_extras=False,
                              export_cameras=False, export_lights=False, export_animations=False)
    print("BUILT %s way=%s(%s) raw=%.3f x %.3f x %.3f size=%.3f x %.3f x %.3f (csv %.3f x %.3f x %.3f) -> %s" % (
        fid, first, art._WAY_HEX, raw.x, raw.y, raw.z, size.x, size.y, size.z, w, d, h, path))


def main(argv):
    which = argv[0] if argv and argv[0] in ("batch1", "batch2") else "batch1"
    ids = [a for a in argv[1:] if a not in ("batch1", "batch2")]
    fams = BATCH1 if which == "batch1" else BATCH2
    outdir = B1 if which == "batch1" else os.path.join(FAM, "batch2")
    os.makedirs(outdir, exist_ok=True)
    rows = art.read_csv()
    for fid in (ids or fams):
        assert fid in fams, fid
        build(fid, rows[fid], outdir)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
