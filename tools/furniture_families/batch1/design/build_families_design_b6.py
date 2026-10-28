"""Design Specialist builder, batch 6 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b6.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only),
scaled() from b3 and rod()/lathe()/prism_xz() from b4. Output: families/batch6/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender),
flat matte rough 0.82, palette only, material 'way' = first colour-way.
"""
import math
import os
import sys

import bpy
from mathutils import Euler, Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402
import build_families_design_b3 as D3  # noqa: E402
import build_families_design_b4 as D4  # noqa: E402

art = D.art
box, cyl, sphere, torus, arc_bar, splay_leg = art.box, art.cyl, art.sphere, art.torus, art.arc_bar, art.splay_leg
scaled, rod, lathe, prism_xz = D3.scaled, D4.rod, D4.lathe, D4.prism_xz
WAY = art.WAY
# first colour-way not in the palette: aluminium (whiteboard) -> steel.
# later ones, for the record: velvet rose -> rose, velvet -> plum, wire -> steel
D.ALIAS.update({"aluminium": "steel", "velvet rose": "rose", "velvet": "plum", "wire": "steel"})

BATCH6 = ["whiteboard", "cork_board", "fruit_bowl", "blender", "toothbrush_set", "soap_dish",
          "hair_dryer", "jewellery_box", "hangers", "dollhouse"]
B6 = {}


def reg(f):
    B6[f.__name__] = f
    return f


def objs_since(before):
    return [o for o in bpy.context.scene.objects if o.name not in before]


def snapshot():
    return {o.name for o in bpy.context.scene.objects}


def xform(objs, M):
    """Move a group of freshly built objects as one rigid piece."""
    for o in objs:
        o.matrix_basis = M @ o.matrix_basis


def M_at(loc, rot=(0, 0, 0)):
    return Matrix.Translation(Vector(loc)) @ Euler(rot).to_matrix().to_4x4()


# ------------------------------------------------------------------ hang items
@reg
def whiteboard(w, d, h):
    # wall whiteboard (wall at +Y): `way` frame (aluminium->steel), white surface, marker tray at the bottom
    fd = 0.022          # board+frame depth, back face on the wall plane y = d/2
    yb = d / 2 - fd / 2
    t = 0.022
    box((w - 2 * t, fd * 0.6, h - 0.04 - 2 * t), (0, yb + fd * 0.1, 0.04 + (h - 0.04) / 2), "white", 0.0, name="surface")
    z0 = 0.04
    for s in (-1, 1):
        box((w, fd, t), (0, yb, z0 + (h - z0) / 2 + s * ((h - z0) / 2 - t / 2)), WAY, 0.003, name="frame")
        box((t, fd, h - z0), (s * (w / 2 - t / 2), yb, z0 + (h - z0) / 2), WAY, 0.003, name="frame")
    # marker tray: a ledge running under the board and sticking out to the front
    box((w * 0.7, d, 0.008), (0, 0, z0 - 0.004), WAY, 0.002, name="pen_ledge")
    box((w * 0.7, 0.006, 0.02), (0, -d / 2 + 0.003, z0 - 0.002), WAY, 0.002, name="pen_ledge")
    for s in (-1, 1):
        box((0.02, d, 0.03), (s * w * 0.35, 0, z0 - 0.01), WAY, 0.002, name="pen_ledge")
    my = -d / 2 + 0.014
    for i, c in enumerate(("blue", "red", "dark")):
        x = -0.12 + i * 0.07
        cyl(0.007, 0.11, (x, my, z0 + 0.007), c, "X", 12, name="marker")
        cyl(0.0075, 0.035, (x + 0.07, my, z0 + 0.007), c, "X", 12, name="marker_cap")
    cyl(0.012, 0.012, (0.22, my, z0 + 0.004), "dark", verts=4, name="eraser")
    box((0.06, 0.025, 0.016), (0.22, my + 0.002, z0 + 0.008), "dark", 0.003, name="eraser")
    # some writing on the board
    fy = yb + fd * 0.1 - fd * 0.3 - 0.0006
    for i, (L, x) in enumerate(((0.36, -0.14), (0.26, -0.19), (0.3, -0.16))):
        box((L, 0.001, 0.008), (x, fy, h - 0.12 - i * 0.06), "blue", 0.0, name="ink")
    box((0.22, 0.001, 0.006), (-0.2, fy, h - 0.135 - 3 * 0.06), "red", 0.0, name="ink")
    pts = [(0.1, 0.18), (0.16, 0.26), (0.22, 0.23), (0.28, 0.33), (0.34, 0.37)]
    for (x0, z0_), (x1, z1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, z1 - z0_)
        box((L, 0.001, 0.007), ((x0 + x1) / 2, fy, (z0_ + z1) / 2), "red", 0.0,
            rot=(0, -math.atan2(z1 - z0_, x1 - x0), 0), name="ink")


@reg
def cork_board(w, d, h):
    # framed cork pin board (wall at +Y), with pinned notes and a photo
    t = 0.025
    for s in (-1, 1):
        box((w, d, t), (0, 0, h / 2 + s * (h / 2 - t / 2)), WAY, 0.003, name="frame")
        box((t, d, h - 2 * t), (s * (w / 2 - t / 2), 0, h / 2), WAY, 0.003, name="frame")
    box((w - 2 * t, d * 0.6, h - 2 * t), (0, d * 0.15, h / 2), "kraft", 0.0, name="cork")
    fy = d * 0.15 - d * 0.3
    notes = [(-0.17, 0.3, 0.1, 0.1, "mustard", 5), (-0.03, 0.31, 0.12, 0.09, "cream", -4),
             (0.15, 0.29, 0.1, 0.13, "rose", 3), (-0.15, 0.13, 0.13, 0.1, "sage", -6),
             (0.06, 0.13, 0.15, 0.11, "cream", 2), (0.2, 0.11, 0.08, 0.08, "mustard", -8)]
    for i, (x, z, nw, nh, c, a) in enumerate(notes):
        box((nw, 0.0015, nh), (x, fy - 0.001 - 0.0005 * (i % 2), z), c, 0.0, rot=(0, math.radians(a), 0), name="note")
        if c == "cream":
            for k in range(3):
                box((nw * 0.7, 0.0005, 0.005), (x, fy - 0.0025 - 0.0005 * (i % 2), z + nh * 0.25 - k * 0.022), "rose" if i == 1 else "sage", 0.0, rot=(0, math.radians(a), 0), name="note_line")
        sphere(0.005, (x, fy - 0.004, z + nh / 2 - 0.012), "red", name="pin")


# --------------------------------------------------------------- kitchen/bath
@reg
def fruit_bowl(w, d, h):
    # wide footed ceramic bowl (`way`) with apples, oranges and a banana
    bowl = [(0.05, 0.0), (0.055, 0.012), (0.075, 0.016), (0.11, 0.04), (0.135, 0.07), (0.14, 0.08),
            (0.133, 0.08), (0.128, 0.07), (0.104, 0.044), (0.07, 0.024), (0.001, 0.02)]
    lathe(bowl, WAY, segs=32, name="bowl")
    torus(0.1365, 0.0045, (0, 0, 0.08), "cream", seg=32, name="bowl_rim")
    fr = [(-0.035, -0.03, 0.04, "red"), (0.04, -0.035, 0.038, "mustard"), (0.0, 0.045, 0.04, "terracotta"),
          (0.065, 0.04, 0.034, "green"), (-0.07, 0.035, 0.036, "terracotta")]
    for x, y, r, c in fr:
        z = 0.02 + 0.6 * math.hypot(x, y) * 0.5 + r * 0.9
        sphere(r, (x, y, z), c, scale=(1, 1, 0.92), name="fruit")
        if c in ("red", "green"):
            rod((x, y, z + r * 0.85), (x + 0.004, y, z + r * 1.2), 0.0025, "dark", name="stem", verts=6)
    # banana lying over the top
    pts = [(-0.09 + 0.18 * u / 8, 0.105 + 0.03 * math.sin(math.pi * u / 8) - 0.0) for u in range(9)]
    o = arc_bar([(x, z) for x, z in pts], 0.026, 0.03, "mustard", name="banana", bevel=0.008, plane="XZ")
    o.location = (0, -0.015, 0)
    o.rotation_euler = (0, 0, math.radians(18))


@reg
def blender(w, d, h):
    # countertop blender: `way` motor base, glass jug with handle and dark lid
    bh = 0.11
    box((0.15, d - 0.002, bh), (-0.005, 0, bh / 2), WAY, 0.02, name="base")
    box((0.12, 0.004, 0.05), (-0.005, -d / 2 + 0.003, bh * 0.45), "dark", 0.004, name="panel")
    cyl(0.016, 0.01, (-0.005, -0.074, bh * 0.45), "steel", "Y", 18, bevel=0.002, name="dial")
    for x in (-0.045, 0.035):
        box((0.018, 0.006, 0.01), (x, -0.074, bh * 0.45), "cream", 0.002, name="button")
    cyl(0.055, 0.018, (-0.005, 0, bh + 0.009), "dark", verts=24, name="collar")
    jug = [(0.045, 0.0), (0.05, 0.01), (0.062, 0.16), (0.066, 0.24), (0.06, 0.24), (0.056, 0.16), (0.044, 0.012), (0.001, 0.01)]
    o = lathe(jug, "glass", segs=24, name="jug")
    o.location = (-0.005, 0, bh + 0.018)
    zj = bh + 0.018
    cyl(0.04, 0.05, (-0.005, 0, zj + 0.035), "mustard", verts=20, r2=0.05, name="smoothie")
    rod((-0.005, 0, zj + 0.012), (-0.005, 0, zj + 0.03), 0.006, "steel", name="blade")
    box((0.06, 0.012, 0.002), (-0.005, 0, zj + 0.028), "steel", 0.0, rot=(0, 0, 0.6), name="blade")
    cyl(0.068, 0.02, (-0.005, 0, zj + 0.25), "dark", verts=24, bevel=0.004, name="lid")
    cyl(0.02, 0.016, (-0.005, 0, zj + 0.268), "dark", verts=18, name="lid_cap")
    arc_bar([(0.055, zj + 0.21), (0.071, zj + 0.205), (0.071, zj + 0.08), (0.055, zj + 0.06)], 0.014, 0.018, "glass", name="jug_handle", plane="XZ")


@reg
def toothbrush_set(w, d, h):
    # bathroom tumbler (`way`) with three toothbrushes leaning out, and a paste tube
    lathe([(0.031, 0.0), (0.035, 0.006), (0.039, 0.1), (0.036, 0.1), (0.032, 0.01), (0.001, 0.008)], WAY, segs=24, name="cup")
    torus(0.0375, 0.002, (0, 0, 0.1), "cream", seg=24, name="cup_rim")
    for k, (c, lean, az) in enumerate((("cream", 12, 150), ("sage", 12, 30), ("terracotta", 11, 270))):
        before = snapshot()
        L = 0.17
        cyl(0.0045, L, (0, 0, L / 2), c, verts=10, name="brush")
        box((0.011, 0.006, 0.028), (0, 0, L + 0.012), c, 0.002, name="brush_head")
        box((0.009, 0.008, 0.024), (0, -0.007, L + 0.013), "white", 0.001, name="bristles")
        a = math.radians(az)
        xform(objs_since(before), M_at((0.01 * math.cos(a), 0.01 * math.sin(a), 0.008),
                                       (0, 0, a + math.pi / 2)) @ M_at((0, 0, 0), (math.radians(-lean), 0, 0)) @ M_at((0, 0, 0), (0, 0, math.pi)))
    # toothpaste tube leaning in too
    before = snapshot()
    cyl(0.009, 0.12, (0, 0, 0.06), "white", verts=14, name="tube")
    box((0.024, 0.004, 0.012), (0, 0, 0.122), "white", 0.001, name="tube")
    cyl(0.007, 0.012, (0, 0, -0.004), "terracotta", verts=14, name="tube_cap")
    xform(objs_since(before), M_at((-0.012, -0.012, 0.012), (math.radians(8), math.radians(-6), 0)))


@reg
def soap_dish(w, d, h):
    # oval ceramic soap dish (`way`) with drain ridges and a cream bar of soap
    dish = [(0.045, 0.0), (0.05, 0.004), (0.058, 0.018), (0.06, 0.024), (0.055, 0.024), (0.051, 0.012), (0.001, 0.01)]
    o = lathe(dish, WAY, yscale=0.74, segs=32, name="dish")
    for i in range(5):
        box((0.004, d * 0.6, 0.004), (-0.032 + i * 0.016, 0, 0.012), WAY, 0.001, name="ridge")
    box((0.075, 0.048, 0.034), (0, 0, 0.0145 + 0.017), "cream", 0.009, rot=(0, 0, math.radians(-6)), name="soap")
    box((0.035, 0.012, 0.0015), (0, -0.002, 0.049), "rose", 0.0, rot=(0, 0, math.radians(-6)), name="soap_stamp")


@reg
def hair_dryer(w, d, h):
    # hair dryer seen side-on from the front: barrel along X (nozzle +X), handle down, cord
    r = d / 2
    zc = h - r - 0.001
    lathe([(0.001, 0.0), (0.028, 0.0), (r - 0.004, 0.012), (r, 0.03), (r, 0.11), (r - 0.006, 0.13), (0.026, 0.15)],
          WAY, segs=24, name="barrel").rotation_euler = (0, math.radians(90), 0)
    bpy.context.scene.objects["barrel"].location = (-0.09, 0, zc)
    cyl(0.026, 0.065, (0.092, 0, zc), "dark", "X", 20, r2=0.02, name="nozzle")
    cyl(r - 0.008, 0.004, (-0.092, 0, zc), "dark", "X", 24, name="vent")
    for k in range(3):
        torus(0.008 + k * 0.009, 0.0016, (-0.095, 0, zc), "steel", rot=(0, math.radians(90), 0), seg=20, name="vent_ring")
    # handle, raked back
    a = math.radians(-14)
    hl = zc - 0.01
    box((0.04, 0.045, hl), (-0.03 - math.sin(-a) * hl / 2 + 0.008, 0, hl / 2 + 0.004), WAY, 0.012, rot=(0, a, 0), name="handle")
    for k, c in enumerate(("cream", "dark")):
        box((0.012, 0.006, 0.018), (-0.025 - k * 0.006, -0.0235, zc - 0.05 - k * 0.028), c, 0.002, rot=(0, a, 0), name="switch")
    sphere(0.009, (-0.012, 0, 0.007), "dark", name="cord")
    arc_bar([(-0.012, 0.004), (0.02, 0.004), (0.05, 0.008), (0.08, 0.004)], 0.008, 0.008, "dark", name="cord", plane="XZ")


@reg
def jewellery_box(w, d, h):
    # open jewellery box: `way` casket with rose velvet tray; lid tilted back with a mirror inside
    hb, L = 0.036, 0.084
    bd = L
    y0 = -d / 2                  # front of the base
    yc = y0 + bd / 2
    t = 0.007
    box((w, bd, hb), (0, yc, hb / 2), WAY, 0.003, name="base")
    box((w - 2 * t, bd - 2 * t, 0.004), (0, yc, hb - 0.004), "rose", 0.0, name="velvet")
    box((0.004, bd - 2 * t, 0.012), (-w * 0.17, yc, hb), WAY, 0.001, name="divider")
    for i in range(4):  # ring slots
        box((w * 0.3, 0.004, 0.006), (-w * 0.17 - w * 0.17 - 0.002, yc - 0.024 + i * 0.016, hb - 0.0005), "plum", 0.001, name="ring_slot")
    torus(0.009, 0.0022, (-w * 0.34, yc - 0.008, hb + 0.004), "brass", rot=(math.radians(70), 0, 0), name="ring")
    sphere(0.005, (-w * 0.34, yc - 0.006, hb + 0.014), "red", name="gem")
    torus(0.008, 0.002, (-w * 0.27, yc + 0.016, hb + 0.003), "brass", rot=(math.radians(70), 0, 0), name="ring")
    for k in range(11):  # pearl necklace loop
        u = k / 11 * 2 * math.pi
        sphere(0.0045, (0.03 + 0.032 * math.cos(u), yc + 0.022 * math.sin(u), hb + 0.0045), "white", name="pearl")
    sphere(0.008, (0.075, yc - 0.012, hb + 0.007), "red", scale=(1, 1, 0.8), name="brooch")
    torus(0.009, 0.0022, (0.075, yc - 0.012, hb + 0.004), "brass", name="brooch")
    box((0.03, 0.004, 0.008), (0, y0 - 0.001, hb - 0.012), "brass", 0.001, name="clasp")
    # lid hinged at the back top edge, opened 128 degrees (leans back past vertical)
    phi = math.radians(128)
    hy, hz = y0 + bd, hb
    th = math.pi - phi                           # local +Y of the lid box -> direction hinge->lid tip
    dy, dz = math.cos(th), math.sin(th)
    lt = 0.012
    cy, cz = hy + dy * L / 2, hz + dz * L / 2
    ny, nz = -math.sin(th), math.cos(th)         # local +Z: the inside face, now facing front/up
    box((w, L, lt), (0, cy, cz), WAY, 0.003, rot=(th, 0, 0), name="lid")
    off = lt / 2 + 0.0008
    box((w - 0.03, L - 0.02, 0.002), (0, cy + ny * off, cz + nz * off), "rose", 0.0, rot=(th, 0, 0), name="lid_lining")
    off += 0.0015
    box((w * 0.55, L * 0.62, 0.0015), (0, cy + ny * off, cz + nz * off), "glass", 0.0, rot=(th, 0, 0), name="mirror")
    for s in (-1, 1):
        cyl(0.004, 0.025, (s * w * 0.3, hy, hz), "brass", "X", 10, name="hinge")


@reg
def hangers(w, d, h):
    # three wooden coat hangers hanging one behind another, steel hooks, trouser bars
    for k, (y, dx) in enumerate(((-0.024, -0.008), (0.0, 0.0), (0.024, 0.008))):
        hw = w / 2 - 0.01
        tz, pz = 0.02, 0.135
        pts = []
        for i in range(13):
            u = -1 + 2 * i / 12
            pts.append((dx + hw * u, tz + (pz - tz) * (1 - abs(u) ** 1.6) + 0.0))
        o = arc_bar(pts, 0.022, 0.011, WAY, name="hanger", bevel=0.003, plane="XZ")
        o.location = (0, y, 0)
        rod((dx - hw + 0.03, y, 0.018), (dx + hw - 0.03, y, 0.018), 0.0035, "steel", name="bar")
        for s in (-1, 1):
            rod((dx + s * (hw - 0.03), y, 0.018), (dx + s * (hw - 0.03), y, 0.036), 0.0035, "steel", name="bar")
        rod((dx, y, pz), (dx, y, pz + 0.06), 0.0025, "steel", name="hook")
        hook = [(dx, pz + 0.06), (dx, pz + 0.09)]
        for i in range(10):
            a = math.radians(180 - i * 22)
            hook.append((dx + 0.022 + 0.022 * math.cos(a), pz + 0.09 + 0.026 * math.sin(a)))
        arc_bar(hook, 0.005, 0.005, "steel", name="hook", bevel=0.0, plane="XZ", offset=0).location = (0, y, 0)
        box((0.03, 0.0125, 0.014), (dx, y, pz - 0.002), "brass", 0.002, name="hook_collar")


@reg
def dollhouse(w, d, h):
    # open-front dolls' house: `way` walls, red gable roof, two floors + attic, tiny furniture in 5 rooms
    t = 0.014
    eave = 0.38
    yb = d / 2 - t / 2
    box((w, d, 0.02), (0, 0, 0.01), WAY, 0.003, name="plinth")
    box((w - 2 * t, t, eave - 0.02), (0, yb, 0.02 + (eave - 0.02) / 2), "cream", 0.0, name="back_wall")
    for s in (-1, 1):
        box((t, d, eave - 0.02), (s * (w / 2 - t / 2), 0, 0.02 + (eave - 0.02) / 2), WAY, 0.002, name="side_wall")
        for z in (0.1, 0.27):  # side windows
            box((0.002, 0.09, 0.08), (s * (w / 2 + 0.0005), 0.02, z), "white", 0.0, name="window")
            box((0.003, 0.006, 0.08), (s * (w / 2 + 0.001), 0.02, z), WAY, 0.0, name="window_bar")
    zf1 = 0.2
    for z in (0.02, zf1, eave):
        box((w - 2 * t, d - t, 0.012), (0, -t / 2, z + 0.006), "oak", 0.0, name="floor")
    box((t * 0.7, d - t, zf1 - 0.032), (0.04, -t / 2, 0.032 + (zf1 - 0.032) / 2), "cream", 0.0, name="partition")
    box((t * 0.7, d - t, eave - zf1 - 0.012), (-0.03, -t / 2, zf1 + 0.012 + (eave - zf1 - 0.012) / 2), "cream", 0.0, name="partition")
    for s in (-1, 1):  # front edge trim
        box((0.02, 0.008, eave - 0.02), (s * (w / 2 - 0.01), -d / 2 + 0.004, 0.02 + (eave - 0.02) / 2), "white", 0.0, name="trim")
    # gable roof with the ridge running front to back, open gable at the front, wall at the back
    rh = h - eave - 0.012
    pitch = math.atan2(rh, w / 2)
    L = math.hypot(w / 2, rh)
    for s in (-1, 1):
        box((L, d, 0.016), (s * w / 4, 0, eave + 0.012 + rh / 2 - 0.008), "red", 0.002, rot=(0, s * pitch, 0), name="roof")
    prism_xz([(-w / 2 + t, eave + 0.012), (w / 2 - t, eave + 0.012), (0, h - 0.02)], d / 2 - t, d / 2, "cream", name="gable")
    box((0.05, 0.05, 0.08), (0.17, 0.08, h - 0.075), "red", 0.002, name="chimney")
    # ground floor: kitchen (left), living room (right)
    z = 0.032
    box((0.1, 0.06, 0.006), (-0.17, 0.0, z + 0.06), "oak", 0.001, name="table")
    for x in (-0.21, -0.13):
        box((0.008, 0.008, 0.06), (x, 0.0, z + 0.03), "oak", 0.0, name="table_leg")
    box((0.14, 0.05, 0.08), (-0.18, yb - 0.035, z + 0.04), "white", 0.002, name="kitchen")
    box((0.14, 0.004, 0.006), (-0.18, yb - 0.061, z + 0.06), "sage", 0.0, name="kitchen_trim")
    box((0.14, 0.06, 0.035), (0.16, 0.07, z + 0.0175), "sage", 0.006, name="sofa")
    box((0.14, 0.02, 0.06), (0.16, 0.1, z + 0.03), "sage", 0.006, name="sofa")
    box((0.08, 0.1, 0.002), (0.16, -0.02, z + 0.001), "rose", 0.0, name="rug")
    # first floor: bedroom (left), bathroom (right)
    z = zf1 + 0.012
    box((0.16, 0.1, 0.03), (-0.17, 0.08, z + 0.015), "white", 0.004, name="bed")
    box((0.16, 0.06, 0.006), (-0.17, 0.06, z + 0.033), "rose", 0.002, name="bed")
    box((0.16, 0.012, 0.06), (-0.17, yb - 0.01, z + 0.03), "oak", 0.002, name="bed")
    box((0.14, 0.06, 0.04), (0.15, 0.08, z + 0.02), "white", 0.012, name="bath")
    box((0.04, 0.04, 0.05), (0.06, 0.12, z + 0.025), "white", 0.006, name="basin")
    # attic: toy box and rocking horse-ish chair
    z = eave + 0.012
    box((0.07, 0.05, 0.04), (-0.07, 0.06, z + 0.02), "rose", 0.003, name="toy_box")
    sphere(0.02, (0.07, 0.07, z + 0.02), "sage", name="ball")


def main(argv):
    out = os.path.join(D.FAM, "batch6")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B6)
    rows = art.read_csv()
    for fid in (argv or BATCH6):
        assert fid in BATCH6, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
