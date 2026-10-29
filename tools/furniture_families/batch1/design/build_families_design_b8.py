"""Design Specialist builder, batch 8 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b8.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only),
scaled() from b3, rod()/lathe()/prism_xz() from b4, xform()/M_at() from b6, ell()/prism_yz() from b7.
Output: families/batch8/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender), hang items wall at +Y,
flat matte rough 0.82, palette only, material 'way' = first colour-way.
"""
import math
import os
import sys

import bmesh
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402
import build_families_design_b3 as D3  # noqa: E402
import build_families_design_b4 as D4  # noqa: E402
import build_families_design_b6 as D6  # noqa: E402
import build_families_design_b7 as D7  # noqa: E402  (also registers wood -> oak)

art = D.art
box, cyl, sphere, torus, arc_bar = art.box, art.cyl, art.sphere, art.torus, art.arc_bar
scaled, rod, lathe, prism_xz = D3.scaled, D4.rod, D4.lathe, D4.prism_xz
snapshot, objs_since, xform, M_at = D6.snapshot, D6.objs_since, D6.xform, D6.M_at
ell, prism_yz = D7.ell, D7.prism_yz
WAY = art.WAY
# Off-palette first colour-ways in batch 8: string_lights "mixed" -> mustard, trophy "bronze" -> terracotta.
# Later colour-ways (not baked): warm -> mustard, gold -> brass, silver -> steel, tarnished -> grey,
# galvanised -> steel (same as Art's table).
D.ALIAS.update({"mixed": "mustard", "warm": "mustard", "bronze": "terracotta", "gold": "brass",
                "silver": "steel", "tarnished": "grey", "galvanised": "steel"})

BATCH8 = ["loo_roll", "medicine_cabinet", "bath_caddy", "string_lights", "console", "chess_set",
          "trophy", "old_lamp", "model_ship", "bucket"]
B8 = {}


def reg(f):
    B8[f.__name__] = f
    return f


def loft(rings, color, name="part", smooth=True):
    """Closed rings of (x, y, z) points (same count), joined in order, capped at both ends."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    R = [[bm.verts.new(p) for p in ring] for ring in rings]
    n = len(rings[0])
    for A, B in zip(R, R[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((A[i], A[j], B[j], B[i]))
    bm.faces.new(list(reversed(R[0])))
    bm.faces.new(R[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    art._finish(o, color, 0.0, name)
    if smooth:
        for p in o.data.polygons:
            p.use_smooth = True
    return o


# ------------------------------------------------------------------ bathroom
@reg
def loo_roll(w, d, h):
    # plain variant "Loo roll stack": three `way` (white) rolls, top one shows its kraft core and a hanging tail
    r = w / 2 - 0.001
    rh = (h - 0.004) / 3
    for k in range(3):
        z0 = k * (rh + 0.002)
        dx = (0.0015, -0.0015, 0.0)[k]
        lathe([(r - 0.006, 0.0), (r - 0.002, 0.001), (r, 0.006), (r, rh - 0.006), (r - 0.002, rh - 0.001),
               (r - 0.006, rh)], WAY, segs=36, name="roll", at=(dx, 0, z0))
    zt = 2 * (rh + 0.002) + rh
    cyl(0.023, 0.004, (0, 0, zt), "kraft", verts=28, name="core")
    cyl(0.019, 0.0042, (0, 0, zt), "dark", verts=28, name="core_hole")
    for rr in (0.032, 0.041, 0.05):  # wound layers on the top face
        torus(rr, 0.0007, (0, 0, zt), "card", seg=36, name="layers")
    # tail sheet hanging down the front, with perforations
    pts = [(0.0, zt + 0.0008), (-0.0025, zt - 0.0015)] + [(-0.0028 - 0.0002 * i, zt - 0.006 - 0.012 * i) for i in range(8)]
    pts = [(y - r + 0.002, z) for y, z in pts]
    arc_bar(pts, 0.0016, 0.07, WAY, name="tail", bevel=0.0, plane="YZ")
    for zz in (zt - 0.035, zt - 0.075):
        for i in range(9):
            box((0.004, 0.0012, 0.0012), (-0.03 + i * 0.0075, -r - 0.0018 - (zt - zz) * 0.017, zz), "card", 0.0, name="perforation")


@reg
def medicine_cabinet(w, d, h):
    # hang: `way` (oak) carcass, wall at +Y; mirror door over the upper part, open shelf below, crown with a red cross
    t = 0.016
    yb, yf = d / 2, -d / 2 + 0.022       # carcass back / front
    cy, cd = (yb + yf) / 2, yb - yf
    hc = 0.06                           # crown height
    for s in (-1, 1):
        box((t, cd, h - hc), (s * (w / 2 - t / 2), cy, (h - hc) / 2), WAY, 0.002, name="side")
    box((w, 0.008, h - hc), (0, yb - 0.004, (h - hc) / 2), WAY, 0.001, name="back")
    box((w - 2 * t, cd, t), (0, cy, t / 2), WAY, 0.002, name="bottom")
    zs = 0.11
    box((w - 2 * t, cd, t), (0, cy, zs - t / 2), WAY, 0.002, name="shelf")
    # crown with a white plaque and a red cross
    box((w, d - 0.006, hc), (0, 0.003, h - hc / 2), WAY, 0.004, name="crown")
    box((w + 0.0, d - 0.002, 0.012), (0, 0.001, h - hc - 0.006 + 0.012), WAY, 0.003, name="crown_moulding")
    box((0.05, 0.004, 0.04), (0, -d / 2 + 0.001, h - hc / 2), "white", 0.004, name="plaque")
    box((0.03, 0.004, 0.009), (0, -d / 2 - 0.0005, h - hc / 2), "red", 0.0, name="cross")
    box((0.009, 0.004, 0.03), (0, -d / 2 - 0.0005, h - hc / 2), "red", 0.0, name="cross")
    # mirror door
    z0, z1 = zs + 0.002, h - hc - 0.002
    dh, dw, ft = z1 - z0, w - 0.006, 0.03
    yd = yf - 0.009
    for s in (-1, 1):
        box((ft, 0.018, dh), (s * (dw / 2 - ft / 2), yd, z0 + dh / 2), WAY, 0.003, name="door_frame")
        box((dw, 0.018, ft), (0, yd, (z0 + ft / 2) if s < 0 else (z1 - ft / 2)), WAY, 0.003, name="door_frame")
    box((dw - 2 * ft + 0.004, 0.006, dh - 2 * ft + 0.004), (0, yd - 0.002, z0 + dh / 2), "glass", 0.0, name="mirror")
    for k, (dx, L) in enumerate(((-0.06, 0.16), (-0.02, 0.1))):  # glints
        box((0.008, 0.002, L), (dx, yd - 0.0055, z0 + dh / 2 + 0.03), "white", 0.0, rot=(0, math.radians(-35), 0), name="glint")
    sphere(0.008, (dw / 2 - ft / 2, yd - 0.012, z0 + dh / 2), "steel", (1, 0.8, 1), name="knob")
    for zz in (z0 + 0.05, z1 - 0.05):
        cyl(0.004, 0.04, (-w / 2 + 0.002, yd + 0.004, zz), "steel", verts=8, name="hinge")
    # open shelf contents
    zb = t
    lathe([(0.018, 0), (0.018, 0.05), (0.012, 0.058), (0.006, 0.062), (0.006, 0.07), (0.001, 0.07)], "teal",
          segs=18, name="bottle", at=(-0.11, cy - 0.01, zb))
    cyl(0.008, 0.012, (-0.11, cy - 0.01, zb + 0.074), "white", verts=14, name="cap")
    cyl(0.022, 0.04, (-0.03, cy - 0.005, zb + 0.02), "white", verts=20, name="pot")
    cyl(0.023, 0.012, (-0.03, cy - 0.005, zb + 0.046), "red", verts=20, bevel=0.002, name="pot_lid")
    lathe([(0.022, 0), (0.026, 0.07), (0.001, 0.07)], "white", segs=18, name="cup", at=(0.07, cy - 0.005, zb))
    for k, (dx, c) in enumerate(((-0.006, "teal"), (0.007, "red"))):
        rod((0.07 + dx, cy - 0.005, zb + 0.03), (0.07 + dx * 2.2, cy - 0.005 - 0.006 * (1 - 2 * k), zb + 0.088), 0.0035, c, name="toothbrush", verts=8)
    lathe([(0.016, 0), (0.016, 0.03), (0.01, 0.036), (0.001, 0.036)], "white", segs=16, name="tub", at=(0.14, cy - 0.01, zb))


@reg
def bath_caddy(w, d, h):
    # `way` (oak) slatted rack across a tub, rubber grips underneath, an open book, bottles and a sponge
    rt, rh = 0.018, 0.02
    z0 = 0.008
    for s in (-1, 1):
        box((w, rt, rh), (0, s * (d / 2 - rt / 2), z0 + rh / 2), WAY, 0.004, name="rail")
    for i in range(23):
        x = -w / 2 + 0.02 + i * (w - 0.04) / 22
        box((0.018, d - 2 * rt, 0.008), (x, 0, z0 + rh - 0.004), WAY, 0.002, name="slat")
    for s in (-1, 1):  # end bars and grips on the tub rim
        box((0.02, d, rh), (s * (w / 2 - 0.01), 0, z0 + rh / 2), WAY, 0.004, name="end_bar")
        for sy in (-1, 1):
            box((0.05, 0.016, z0 + 0.002), (s * (w / 2 - 0.08), sy * (d / 2 - 0.009), (z0 + 0.002) / 2), "dark", 0.002, name="grip")
    zt = z0 + rh
    # open book, slightly angled
    o0 = snapshot()
    box((0.21, 0.132, 0.004), (0, 0, 0.002), "blue", 0.001, name="book_cover")
    for s in (-1, 1):
        box((0.1, 0.124, 0.012), (s * 0.051, 0, 0.004 + 0.006 + 0.002), "white", 0.004,
            rot=(0, math.radians(-5 * s), 0), name="pages")
        for k in range(7):
            box((0.075 if k < 6 else 0.04, 0.003, 0.0006), (s * 0.052 - (0.0175 if k == 6 else 0), 0.045 - k * 0.014,
                0.0185 + 0.0045 * (1 - abs(s * 0.052) / 0.1) * 0 + (0.004 if True else 0) - 0.0 + 0.0 * k
                - (abs(0.052) - 0.0) * math.tan(math.radians(5)) * 0), "dark", 0.0, rot=(0, math.radians(-5 * s), 0), name="text")
    xform(objs_since(o0), M_at((-0.15, 0.0, zt), (0, 0, math.radians(-3))))
    # bottles
    lathe([(0.022, 0), (0.023, 0.05), (0.016, 0.06), (0.009, 0.064), (0.001, 0.064)], "sage", segs=20,
          name="bottle", at=(0.06, 0.02, zt))
    cyl(0.01, 0.008, (0.06, 0.02, zt + 0.068), "white", verts=16, name="cap")
    box((0.03, 0.002, 0.026), (0.06, 0.02 - 0.023, zt + 0.026), "white", 0.0, name="sticker")
    lathe([(0.02, 0), (0.02, 0.05), (0.012, 0.056), (0.001, 0.056)], "white", segs=20, name="bottle", at=(0.12, -0.025, zt))
    cyl(0.005, 0.01, (0.12, -0.025, zt + 0.061), "steel", verts=10, name="pump")
    box((0.006, 0.022, 0.006), (0.12, -0.035, zt + 0.068), "steel", 0.002, name="pump")
    box((0.024, 0.002, 0.022), (0.12, -0.025 - 0.0205, zt + 0.025), "sage", 0.0, name="sticker")
    box((0.09, 0.06, 0.035), (0.24, 0.0, zt + 0.0175), "mustard", 0.012, rot=(0, 0, math.radians(10)), name="sponge")


@reg
def string_lights(w, d, h):
    # hang: chunky festoon of nine globe bulbs on a dark cable between three wall hooks (wall at +Y)
    xs = (-w / 2 + 0.012, 0.0, w / 2 - 0.012)
    zh, sag = h - 0.018, 0.085
    for x in xs:   # wall hooks: steel plate on the wall, arm forward, cup hook
        box((0.016, 0.004, 0.024), (x, d / 2 - 0.002, h - 0.012), "steel", 0.001, name="hook_plate")
        rod((x, d / 2 - 0.004, zh + 0.004), (x, 0.0, zh + 0.004), 0.002, "steel", name="hook", verts=6)
    pts = []
    for a, b in ((xs[0], xs[1]), (xs[1], xs[2])):
        c, hw = (a + b) / 2, (b - a) / 2
        for i in range(25):
            x = a + (b - a) * i / 24
            pts.append((x, zh - sag * (1 - ((x - c) / hw) ** 2)))
    pts = [p for i, p in enumerate(pts) if i == 0 or p[0] > pts[i - 1][0] + 1e-6]
    arc_bar(pts, 0.006, 0.006, "dark", name="cable", bevel=0.001, plane="XZ")
    cols = [WAY, "red", "green", "blue", WAY, "red", "green", "blue", WAY]
    br, bh = 0.03, 0.04
    for k in range(9):
        x = -w / 2 + 0.06 + k * (w - 0.12) / 8
        sw = 0 if x < 0 else 1
        a, b = (xs[0], xs[1]) if sw == 0 else (xs[1], xs[2])
        c, hw = (a + b) / 2, (b - a) / 2
        zc = zh - sag * (1 - ((x - c) / hw) ** 2)
        drop = 0.01 + 0.012 * (k % 2)
        rod((x, 0, zc), (x, 0, zc - drop), 0.002, "dark", name="drop", verts=6)
        cyl(0.01, 0.018, (x, 0, zc - drop - 0.009), "dark", verts=14, bevel=0.002, name="socket")
        ell((br, br, bh), (x, 0, zc - drop - 0.018 - bh + 0.003), cols[k], name="bulb")


# ------------------------------------------------------------------ living
@reg
def console(w, d, h):
    # games console (CSV display name): `way` (black) body with vents, LED strip and ports; controller on top
    bh = 0.046
    box((w, d, bh), (0, 0, 0.004 + bh / 2), WAY, 0.006, name="body")
    for s in (-1, 1):
        for sy in (-1, 1):
            cyl(0.012, 0.004, (s * (w / 2 - 0.03), sy * (d / 2 - 0.03), 0.002), "dark", verts=12, name="foot")
    for i in range(9):  # top vents at the back
        box((w - 0.08, 0.004, 0.0012), (0, d / 2 - 0.012 - i * 0.008, 0.004 + bh), "dark", 0.0, name="vent")
    zf = 0.004 + bh / 2
    box((0.15, 0.002, 0.004), (-0.055, -d / 2 - 0.0005, zf + 0.008), "dark", 0.0, name="disc_slot")
    box((w - 0.03, 0.002, 0.003), (0, -d / 2 - 0.0005, 0.004 + 0.008), "blue", 0.0, name="led_strip")
    cyl(0.006, 0.003, (0.11, -d / 2 - 0.0005, zf + 0.008), "white", "Y", 16, name="power_button")
    for k in range(2):
        box((0.012, 0.002, 0.005), (0.06 + k * 0.018, -d / 2 - 0.0005, zf - 0.004), "dark", 0.0, name="usb_port")
    # controller lying on top
    o0 = snapshot()
    ell((0.06, 0.035, 0.012), (0, 0, 0.012), "grey", name="pad_body")
    for s in (-1, 1):
        ell((0.022, 0.034, 0.012), (s * 0.048, -0.025, 0.011), "grey", name="pad_grip", rot=(0, 0, math.radians(20 * s)))
    for s in (-1, 1):
        cyl(0.009, 0.008, (s * 0.022, -0.016, 0.024), "dark", verts=14, bevel=0.002, name="stick")
    box((0.016, 0.005, 0.004), (-0.045, 0.006, 0.023), "dark", 0.001, name="dpad")
    box((0.005, 0.016, 0.004), (-0.045, 0.006, 0.023), "dark", 0.001, name="dpad")
    for (dx, dy), c in zip(((0, 0.008), (0.008, 0), (0, -0.008), (-0.008, 0)), ("green", "red", "blue", "white")):
        cyl(0.0035, 0.004, (0.045 + dx, 0.006 + dy, 0.023), c, verts=12, name="face_button")
    box((0.04, 0.012, 0.002), (0, 0.012, 0.0235), "dark", 0.001, name="touch_pad")
    xform(objs_since(o0), M_at((0.04, -0.02, 0.004 + bh), (0, 0, math.radians(-12))))


_PIECES = {   # lathe profiles in mm (radius, z) + extras built in chess_set
    "P": [(10, 0), (10, 3), (8, 4.5), (5, 8), (3.5, 15), (3, 18), (6.5, 19), (6.5, 20.5), (0.1, 20.5)],
    "R": [(11, 0), (11, 3), (9, 4.5), (7, 9), (6.5, 22), (8.5, 24), (8.5, 32), (0.1, 32)],
    "N": [(11, 0), (11, 3), (9, 4.5), (7.5, 8), (7, 11), (0.1, 11)],
    "B": [(10.5, 0), (10.5, 3), (8.5, 4.5), (5.5, 9), (4, 22), (7, 24), (7, 25.5), (4, 26), (6, 30), (6, 33),
          (4, 37), (1.5, 39.5), (0.1, 40)],
    "Q": [(12, 0), (12, 3), (10, 4.5), (6, 10), (4.5, 30), (8, 32), (8, 33.5), (5, 34), (7.5, 41), (8, 44), (0.1, 44)],
    "K": [(12.5, 0), (12.5, 3), (10.5, 4.5), (6.5, 10), (5, 32), (8.5, 34), (8.5, 35.5), (5.5, 36), (7.5, 44),
          (8, 46), (0.1, 46)],
}


def _piece(kind, x, y, z, col, facing):
    m = 0.001
    lathe([(r * m, zz * m) for r, zz in _PIECES[kind]], col, segs=12, name="piece", at=(x, y, z))
    top = _PIECES[kind][-1][1] * m + z
    if kind == "P":
        sphere(0.0058, (x, y, top + 0.0045), col, name="piece")
    elif kind == "R":
        for k in range(4):
            a = math.radians(45 + 90 * k)
            box((0.004, 0.004, 0.004), (x + 0.0062 * math.cos(a), y + 0.0062 * math.sin(a), top + 0.002), col, 0.0,
                rot=(0, 0, a), name="piece")
    elif kind == "B":
        sphere(0.0025, (x, y, top + 0.002), col, name="piece")
    elif kind == "Q":
        for k in range(8):
            a = 2 * math.pi * k / 8
            cyl(0.0016, 0.004, (x + 0.0065 * math.cos(a), y + 0.0065 * math.sin(a), top + 0.002), col, verts=6,
                r2=0.0004, name="piece")
        sphere(0.003, (x, y, top + 0.003), col, name="piece")
    elif kind == "K":
        box((0.0032, 0.0032, 0.011), (x, y, top + 0.0055), col, 0.0, name="piece")
        box((0.009, 0.0032, 0.0032), (x, y, top + 0.0075), col, 0.0, name="piece")
    elif kind == "N":
        mm = [(-6, 9), (6, 9), (6.5, 17), (5, 23), (9.5, 27), (11, 31), (8, 34), (2.5, 38), (0, 41), (-3, 39),
              (-6.5, 34), (-8, 26), (-7.5, 17)]
        o = prism_yz([(facing * a * m, b * m) for a, b in mm], -0.0042, 0.0042, col, name="piece")
        o.location = (x, y, z)
        box((0.0012, 0.003, 0.003), (x - 0.0043, y + facing * 0.0045, z + 0.032), "walnut" if col != "walnut" else "dark", 0.0, name="piece_eye")
        box((0.0012, 0.003, 0.003), (x + 0.0043, y + facing * 0.0045, z + 0.032), "walnut" if col != "walnut" else "dark", 0.0, name="piece_eye")


@reg
def chess_set(w, d, h):
    # `way` (oak) board frame, pine and walnut squares, cream and dark pieces; opening 1. e4 e5
    bt = 0.022
    box((w, d, bt), (0, 0, bt / 2), WAY, 0.003, name="board")
    fr = 0.022
    sq = (w - 2 * fr) / 8
    box((8 * sq, 8 * sq, 0.002), (0, 0, bt + 0.0005), "pine", 0.0, name="squares")
    for i in range(8):
        for j in range(8):
            if (i + j) % 2 == 0:
                box((sq, sq, 0.0022), ((i - 3.5) * sq, (j - 3.5) * sq, bt + 0.0006), "walnut", 0.0, name="square")
    z = bt + 0.0017
    back = "RNBQKBNR"
    for i in range(8):
        x = (i - 3.5) * sq
        _piece(back[i], x, -3.5 * sq, z, "cream", 1)
        _piece(back[i], x, 3.5 * sq, z, "dark", -1)
        _piece("P", x, (-1.5 if i != 4 else -0.5) * sq, z, "cream", 1)
        _piece("P", x, (2.5 if i != 4 else 0.5) * sq, z, "dark", -1)


@reg
def trophy(w, d, h):
    # `way` (bronze -> terracotta) loving cup with two handles and a lid, on a stepped walnut plinth with a brass plaque
    box((w, d, 0.032), (0, 0, 0.016), "walnut", 0.004, name="plinth")
    box((0.11, 0.11, 0.028), (0, 0, 0.032 + 0.014), "walnut", 0.004, name="plinth")
    box((0.06, 0.003, 0.018), (0, -d / 2 - 0.001, 0.016), "brass", 0.001, name="plaque")
    for k, L in enumerate((0.04, 0.028)):
        box((L, 0.001, 0.0018), (0, -d / 2 - 0.0027, 0.019 - k * 0.006), "dark", 0.0, name="engraving")
    z0 = 0.06
    lathe([(0.034, 0), (0.034, 0.006), (0.022, 0.012), (0.01, 0.02), (0.007, 0.045), (0.012, 0.052), (0.007, 0.058),
           (0.009, 0.064), (0.02, 0.07), (0.035, 0.088), (0.044, 0.115), (0.049, 0.145), (0.052, 0.162),
           (0.052, 0.166), (0.001, 0.166)], WAY, segs=32, name="cup", at=(0, 0, z0))
    torus(0.045, 0.0025, (0, 0, z0 + 0.115), WAY, seg=32, name="band")
    zl = z0 + 0.166
    lathe([(0.049, 0), (0.046, 0.008), (0.03, 0.02), (0.012, 0.027), (0.006, 0.03), (0.012, 0.042), (0.012, 0.046),
           (0.005, 0.056), (0.001, h - zl)], WAY, segs=24, name="lid", at=(0, 0, zl))
    for s in (-1, 1):
        pts = [(0.046, 0.152), (0.058, 0.156), (0.064, 0.145), (0.063, 0.125), (0.055, 0.105), (0.042, 0.095)]
        arc_bar([(s * x, z0 + z) for x, z in pts], 0.008, 0.008, WAY, name="handle", bevel=0.002, plane="XZ")


@reg
def old_lamp(w, d, h):
    # oil lamp: brass foot, `way` (blue) glazed font with white bands, brass burner and wick knob,
    # tall glass chimney through a `way` tulip shade
    lathe([(0.062, 0), (0.062, 0.008), (0.046, 0.016), (0.02, 0.03), (0.015, 0.05), (0.026, 0.056), (0.001, 0.058)],
          "brass", segs=32, name="foot")
    lathe([(0.025, 0.054), (0.06, 0.072), (0.076, 0.098), (0.072, 0.122), (0.045, 0.142), (0.023, 0.15), (0.001, 0.15)],
          WAY, segs=32, name="font")
    torus(0.0755, 0.002, (0, 0, 0.098), "white", seg=32, name="band")
    torus(0.06, 0.0018, (0, 0, 0.073), "white", seg=32, name="band")
    lathe([(0.024, 0.146), (0.026, 0.165), (0.031, 0.172), (0.031, 0.19), (0.001, 0.19)], "brass", segs=24, name="burner")
    rod((0, -0.02, 0.172), (0, -0.05, 0.172), 0.003, "brass", name="wick_spindle", verts=8)
    cyl(0.011, 0.005, (0, -0.052, 0.172), "brass", "Y", 16, bevel=0.0015, name="wick_knob")
    torus(0.046, 0.0025, (0, 0, 0.212), "brass", seg=32, name="gallery")
    for k in range(4):
        a = math.radians(45 + 90 * k)
        rod((0.03 * math.cos(a), 0.03 * math.sin(a), 0.19), (0.046 * math.cos(a), 0.046 * math.sin(a), 0.212), 0.0022, "brass", name="gallery_arm", verts=6)
    # open tulip shade (hollow: outer wall up, inner wall down) so it reads as a glass shade around the chimney
    lathe([(0.046, 0.212), (0.07, 0.232), (0.1, 0.262), (0.12, 0.3), (0.128, 0.34), (0.122, 0.342), (0.113, 0.302),
           (0.094, 0.266), (0.064, 0.238), (0.03, 0.224)], WAY, segs=40, name="shade")
    torus(0.125, 0.004, (0, 0, 0.341), "white", seg=40, name="shade_rim")
    torus(0.1195, 0.002, (0, 0, 0.3), "white", seg=40, name="shade_band")
    lathe([(0.021, 0.19), (0.023, 0.205), (0.034, 0.235), (0.036, 0.255), (0.024, 0.29), (0.02, 0.32), (0.02, h)],
          "glass", segs=24, name="chimney")
    cyl(0.017, 0.002, (0, 0, h - 0.0005), "dark", verts=20, name="chimney_top")


# ------------------------------------------------------------------ loft / shed
def _hull(x0, x1, B, zk, zd):
    """Lofted hull: stations along X, U-shaped sections closed by the deck. Bow at +X."""
    rings = []
    n, m = 22, 10
    for i in range(n + 1):
        t = -1 + 2 * i / n                  # -1 stern .. +1 bow
        x = x0 + (x1 - x0) * i / n
        bb = B / 2 * (1 - abs(t) ** (2.4 if t > 0 else 4.0)) ** 0.6
        bb = max(bb, 0.004)
        sheer = zd + 0.012 * t * t + (0.012 if t < -0.75 else 0)
        depth = (sheer - zk) * (1 - 0.55 * abs(t) ** 3)
        ring = []
        for k in range(m + 1):
            ph = math.pi * k / m
            ring.append((x, -bb * math.cos(ph), sheer - depth * math.sin(ph) ** 0.7))
        rings.append(ring)
    return rings


@reg
def model_ship(w, d, h):
    # three-masted ship model: `way` (oak) hull on a walnut stand; cream billowed sails, dark rigging, red pennants
    x0, x1, B = -0.24, 0.17, 0.1
    zk, zd = 0.05, 0.12
    rings = _hull(x0, x1, B, zk, zd)
    loft(rings, WAY, name="hull")
    # deck (pine) slightly below the gunwale, following the hull plan
    deck = []
    for ring in rings[1:-1]:
        x, y, z = ring[0]
        deck.append((x, abs(y) - 0.005, z - 0.003))
    pts = [(x, -yy) for x, yy, _ in deck] + [(x, yy) for x, yy, _ in reversed(deck)]
    me = bpy.data.meshes.new("deck")
    bm = bmesh.new()
    zz = [z for _, _, z in deck]
    top = [bm.verts.new((x, y, zz[min(i, len(zz) - 1)] if i < len(deck) else zz[len(pts) - 1 - i])) for i, (x, y) in enumerate(pts)]
    bm.faces.new(top)
    bm.to_mesh(me)
    bm.free()
    od = bpy.data.objects.new("deck", me)
    bpy.context.collection.objects.link(od)
    art._finish(od, "pine", 0.0, "deck")
    # wale stripe and gun ports along both sides
    for s in (-1, 1):
        for i in range(2, 21):
            ring = rings[i]
            x, yy, z = ring[0]
            nxt = rings[i + 1][0]
            box((abs(nxt[0] - x) + 0.001, 0.002, 0.006), ((x + nxt[0]) / 2, s * (abs(yy) - 0.0), z - 0.016), "dark", 0.0, name="wale")
        for i in (5, 8, 11, 14, 17):
            x, yy, z = rings[i][0]
            box((0.009, 0.002, 0.008), (x, s * (abs(yy) + 0.0005), z - 0.03), "dark", 0.0, name="gun_port")
    # stern castle rail, rudder
    box((0.05, B * 0.7, 0.012), (x0 + 0.03, 0, zd + 0.024), WAY, 0.002, name="stern_castle")
    box((0.012, 0.006, 0.06), (x0 + 0.002, 0, zk + 0.035), WAY, 0.002, name="rudder")
    # bowsprit
    bs0, bs1 = (x1 - 0.02, 0, zd + 0.012), (w / 2 + (x0 + x1) / 2 + 0.004, 0, zd + 0.055)
    bs1 = (0.26, 0, zd + 0.055)
    rod(bs0, bs1, 0.004, "walnut", name="bowsprit", verts=8)
    # stand
    box((0.28, 0.08, 0.016), (-0.035, 0, 0.008), "walnut", 0.004, name="stand_base")
    for xp in (-0.13, 0.06):
        box((0.014, 0.05, zk + 0.008), (xp, 0, (zk + 0.008) / 2), "walnut", 0.003, name="stand_post")
    # masts, yards, sails
    masts = ((-0.13, h - 0.05), (-0.035, h - 0.012), (0.06, h - 0.035))
    for mx, mt in masts:
        rod((mx, 0, zd - 0.01), (mx, 0, mt), 0.0045, "walnut", name="mast", verts=10)
        box((0.012, 0.012, 0.004), (mx, 0, mt - 0.11), "walnut", 0.001, name="mast_top")
        tiers = [(zd + 0.03, 0.075, 0.13), (zd + 0.115, 0.07, 0.11), (zd + 0.19, 0.06 if mt > h - 0.03 else 0.045, 0.085)]
        if mt < h - 0.04:
            tiers = [(zd + 0.03, 0.07, 0.12), (zd + 0.11, 0.065, 0.1), (zd + 0.18, 0.045, 0.08)]
        for zb, sh, sw in tiers:
            zt = zb + sh
            if zt > mt - 0.02:
                continue
            rod((mx, -sw / 2 - 0.003, zt), (mx, sw / 2 + 0.003, zt), 0.0022, "walnut", name="yard", verts=6)
            pts = [(mx + 0.004 + 0.014 * math.sin(math.pi * k / 6), zt - sh * k / 6) for k in range(7)]
            arc_bar(pts, 0.0025, sw, "cream", name="sail", bevel=0.0, plane="XZ")
        # pennant
        prism_xz([(mx, mt - 0.012), (mx + 0.04, mt - 0.006), (mx, mt)], -0.001, 0.001, "red", name="pennant")
        # shrouds
        for s in (-1, 1):
            for k in range(3):
                xx = mx - 0.015 + k * 0.015
                rod((xx, s * (B / 2 - 0.004), zd + 0.004), (mx, s * 0.006, mt - 0.11), 0.0009, "dark", name="shroud", verts=4)
    # stays
    rod((masts[2][0], 0, masts[2][1] - 0.04), bs1, 0.001, "dark", name="stay", verts=4)
    rod((masts[1][0], 0, masts[1][1] - 0.04), (masts[2][0], 0, zd + 0.02), 0.001, "dark", name="stay", verts=4)
    rod((masts[0][0], 0, masts[0][1] - 0.04), (masts[1][0], 0, zd + 0.03), 0.001, "dark", name="stay", verts=4)
    rod((masts[0][0], 0, masts[0][1] - 0.06), (x0 + 0.01, 0, zd + 0.03), 0.001, "dark", name="stay", verts=4)
    # jib and spanker
    prism_xz([(masts[2][0] + 0.012, zd + 0.03), (bs1[0] - 0.01, bs1[2] - 0.002), (masts[2][0] + 0.012, masts[2][1] - 0.06)],
             -0.0012, 0.0012, "cream", name="jib")
    prism_xz([(masts[0][0] - 0.006, zd + 0.035), (x0 - 0.0, zd + 0.04), (x0 + 0.01, zd + 0.11), (masts[0][0] - 0.006, zd + 0.15)],
             -0.0012, 0.0012, "cream", name="spanker")


@reg
def bucket(w, d, h):
    # `way` (blue) hollow tapered bucket with rolled rim and ribs; steel wire handle with a dark grip, resting forward
    R1, R0, hb = w / 2 - 0.008, 0.11, 0.255
    lathe([(0.001, 0), (R0 - 0.004, 0), (R0, 0.006), (R1, hb), (R1 - 0.006, hb), (R0 - 0.007, 0.014), (0.001, 0.014)],
          WAY, segs=40, name="bucket")
    torus(R1 - 0.001, 0.005, (0, 0, hb), WAY, seg=40, name="rim")
    for z in (0.06, 0.19):
        r = R0 + (R1 - R0) * (z - 0.006) / (hb - 0.006)
        torus(r + 0.0005, 0.003, (0, 0, z), WAY, seg=40, name="rib")
    zl = hb - 0.022
    rl = R0 + (R1 - R0) * (zl - 0.006) / (hb - 0.006)
    for s in (-1, 1):
        box((0.008, 0.026, 0.03), (s * (rl + 0.003), 0, zl), WAY, 0.003, name="lug")
        cyl(0.004, 0.012, (s * (rl + 0.008), 0, zl), "steel", "X", 10, name="pivot")
    o0 = snapshot()
    Rh = rl + 0.008
    pts = [(-Rh * math.cos(math.pi * k / 20), Rh * math.sin(math.pi * k / 20)) for k in range(21)]
    arc_bar(pts, 0.0065, 0.0065, "steel", name="handle", bevel=0.001, plane="XZ")
    cyl(0.011, 0.09, (0, 0, Rh), "dark", "X", 14, bevel=0.003, name="grip")
    xform(objs_since(o0), M_at((0, 0, zl), (math.radians(62), 0, 0)))


def main(argv):
    out = os.path.join(D.FAM, "batch8")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B8)
    rows = art.read_csv()
    for fid in (argv or BATCH8):
        assert fid in BATCH8, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
