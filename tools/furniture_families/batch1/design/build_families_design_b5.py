"""Design Specialist builder, batch 5 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b5.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only),
scaled() from build_families_design_b3.py and rod()/lathe() from build_families_design_b4.py.
Output: families/batch5/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender),
flat matte rough 0.82, palette only, material 'way' = first colour-way.
"""
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402
import build_families_design_b3 as D3  # noqa: E402
import build_families_design_b4 as D4  # noqa: E402

art = D.art
box, cyl, sphere, torus, arc_bar, splay_leg = art.box, art.cyl, art.sphere, art.torus, art.arc_bar, art.splay_leg
scaled, rod, lathe = D3.scaled, D4.rod, D4.lathe
WAY = art.WAY

BATCH5 = ["school_desk", "sawhorse", "tray", "towel_rail_bath", "office_poster", "sideboard",
          "cushion_set", "tree_box", "utensil_jar", "stand_mixer"]
B5 = {}


def reg(f):
    B5[f.__name__] = f
    return f


def pillow(a, b, t, color, name="cushion", n=14):
    """Cushion: square-ish pad a x b (X x Z) whose thickness (Y, total 2t) bulges in the
    middle and pinches to a seam at the edges. Built centred at the origin."""
    import bmesh
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    def f(u):
        return (1 - abs(u) ** 4) ** 0.6
    grid = {}
    for side in (-1, 1):
        for i in range(n + 1):
            for j in range(n + 1):
                u, v = -1 + 2 * i / n, -1 + 2 * j / n
                edge = i in (0, n) or j in (0, n)
                key = (i, j) if edge else (i, j, side)
                if key in grid:
                    continue
                x = a / 2 * u * (1 - 0.06 * (1 - v * v))  # slight waist on the sides
                z = b / 2 * v * (1 - 0.06 * (1 - u * u))
                grid[key] = bm.verts.new((x, side * t * f(u) * f(v), z))
    def V(i, j, side):
        return grid.get((i, j)) or grid[(i, j, side)]
    for side in (-1, 1):
        for i in range(n):
            for j in range(n):
                q = [V(i, j, side), V(i + 1, j, side), V(i + 1, j + 1, side), V(i, j + 1, side)]
                bm.faces.new(q if side > 0 else q[::-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    art._finish(o, color, 0.0, name)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


@reg
def school_desk(w, d, h):
    # combined pupil desk: lift-lid desk (back, +Y) with a bench seat attached in front (-Y), iron side frames
    zb0, zb1 = 0.47, 0.6            # book box under the lid
    yb0, yb1 = -0.07, d / 2 - 0.055  # lid area; fixed pen tray behind it
    box((w - 0.04, yb1 - yb0, zb1 - zb0), (0, (yb0 + yb1) / 2, (zb0 + zb1) / 2), WAY, 0.006, name="book_box")
    box((w - 0.08, yb1 - yb0 - 0.04, 0.004), (0, (yb0 + yb1) / 2, zb1 + 0.001), "dark", 0.0, name="inside")
    box((w, d / 2 - yb1 + 0.01, 0.022), (0, (yb1 + d / 2) / 2 - 0.005, zb1 + 0.011), WAY, 0.004, name="pen_tray")
    box((w * 0.5, 0.016, 0.004), (-0.05, (yb1 + d / 2) / 2, zb1 + 0.023), "dark", 0.0, name="pen_groove")
    cyl(0.016, 0.02, (w / 2 - 0.07, (yb1 + d / 2) / 2, zb1 + 0.03), "brass", bevel=0.003, name="inkwell")
    # lid, hinged at the back edge, propped open 14 degrees
    a, L, t = math.radians(14), yb1 - yb0 + 0.01, 0.02
    hy, hz = yb1, zb1 + 0.022
    box((w, L, t), (0, hy - L / 2 * math.cos(a), hz + L / 2 * math.sin(a) + t / 2), WAY, 0.005, rot=(-a, 0, 0), name="lid")
    for s in (-1, 1):
        cyl(0.007, 0.05, (s * w * 0.3, hy, hz + 0.004), "brass", "X", 12, name="hinge")
    # bench seat + low back rail in front
    sy0, sy1 = -d / 2 + 0.01, -0.11
    box((w - 0.06, sy1 - sy0, 0.03), (0, (sy0 + sy1) / 2, 0.39), WAY, 0.006, name="seat")
    box((w - 0.06, 0.02, 0.07), (0, -d / 2 + 0.012, 0.52), WAY, 0.006, name="back_rail")
    # cast-iron side frames
    for s in (-1, 1):
        x = s * (w / 2 - 0.05)
        rod((x, -d / 2 + 0.02, 0.015), (x, d / 2 - 0.02, 0.015), 0.012, "dark", name="runner")
        for y in (yb0 + 0.04, yb1 - 0.03):
            rod((x, y, 0.015), (x, y, zb0), 0.013, "dark", name="frame")
        rod((x, (sy0 + sy1) / 2, 0.015), (x, (sy0 + sy1) / 2, 0.375), 0.013, "dark", name="frame")
        rod((x, -d / 2 + 0.012, 0.39), (x, -d / 2 + 0.012, 0.55), 0.01, "dark", name="frame")
        rod((x, (sy0 + sy1) / 2, 0.2), (x, yb0 + 0.04, 0.32), 0.01, "dark", name="frame")
        rod((x, yb0 + 0.04, 0.2), (x, yb1 - 0.03, 0.2), 0.009, "dark", name="frame")


@reg
def sawhorse(w, d, h):
    # timber beam on 4 splayed legs (A-frame at each end), braces and steel brackets
    bt = 0.09
    box((w, bt, bt), (0, 0, h - bt / 2), WAY, 0.004, name="beam")
    xe = w / 2 - 0.13
    for sx in (-1, 1):
        for sy in (-1, 1):
            splay_leg((sx * xe, sy * 0.04, h - bt + 0.01), (sx * (xe + 0.07), sy * (d / 2 - 0.03), 0.0), 0.055, WAY, name="leg")
        # cross brace between the leg pair
        box((0.025, d * 0.62, 0.08), (sx * (xe + 0.045), 0, 0.27), WAY, 0.003, name="brace")
        box((0.08, 0.004, 0.09), (sx * xe, -bt / 2 - 0.002, h - bt / 2), "steel", 0.001, name="bracket")
        box((0.08, 0.004, 0.09), (sx * xe, bt / 2 + 0.002, h - bt / 2), "steel", 0.001, name="bracket")
    # long stretcher under the beam
    box((2 * xe + 0.06, 0.03, 0.06), (0, 0, 0.42), WAY, 0.003, name="stretcher")
    for sx in (-1, 1):
        for sy in (-1, 1):
            rod((sx * (xe + 0.03), sy * 0.12, 0.42), (sx * (xe + 0.03), sy * 0.015, 0.42), 0.012, WAY, name="strut")


@reg
def tray(w, d, h):
    # shallow wooden tray: base, low rims, raised ends with cut-out handles; plate + napkin on it
    t, bh = 0.012, 0.01
    rim = 0.032
    box((w - 0.004, d - 0.004, bh), (0, 0, bh / 2), WAY, 0.003, name="base")
    for s in (-1, 1):
        box((w - 2 * t, t, rim), (0, s * (d / 2 - t / 2), rim / 2), WAY, 0.003, name="rim")
        # end board with a real handle slot: lower panel, two posts, top grip bar
        x = s * (w / 2 - t / 2)
        box((t, d, rim), (x, 0, rim / 2), WAY, 0.003, name="end")
        for sy in (-1, 1):
            box((t, d / 2 - 0.06, h - rim), (x, sy * (d / 4 + 0.03), rim + (h - rim) / 2), WAY, 0.003, name="end")
        box((t, 0.12, 0.008), (x, 0, h - 0.004), WAY, 0.002, name="grip")
    # contents (CSV h 0.05 rules out a full-height cup): a plate and a folded napkin
    cyl(0.075, 0.008, (-0.06, 0.0, bh + 0.004), "white", verts=24, r2=0.06, bevel=0.002, name="plate")
    cyl(0.05, 0.002, (-0.06, 0.0, bh + 0.009), "cream", verts=24, name="plate_well")
    box((0.1, 0.1, 0.008), (0.1, 0.02, bh + 0.004), "terracotta", 0.003, rot=(0, 0, math.radians(12)), name="napkin")
    box((0.1, 0.03, 0.004), (0.1, 0.02, bh + 0.01), "cream", 0.001, rot=(0, 0, math.radians(12)), name="napkin_band")


@reg
def towel_rail_bath(w, d, h):
    # wall-mounted bath towel bar (wall at +Y): round bar on two stand-offs with wall plates
    rz = h / 2
    ry = -d / 2 + 0.013
    rod((-w / 2 + 0.035, ry, rz), (w / 2 - 0.035, ry, rz), 0.012, WAY, name="bar", verts=20)
    for s in (-1, 1):
        x = s * (w / 2 - 0.035)
        sphere(0.016, (x + s * 0.01, ry, rz), WAY, name="end_cap")
        rod((x, ry, rz), (x, d / 2 - 0.012, rz), 0.011, WAY, name="arm")
        box((0.05, 0.012, h), (x, d / 2 - 0.006, h / 2), WAY, 0.004, name="wall_plate")
        for zz in (0.022, h - 0.022):
            cyl(0.005, 0.003, (x, d / 2 - 0.0135, zz), "steel", "Y", 12, name="screw")


@reg
def office_poster(w, d, h):
    # framed office chart poster: `way` frame (black/oak/white), cream mount, bar chart + trend line, title
    t = 0.022
    for s in (-1, 1):
        box((w, d, t), (0, 0, h / 2 + s * (h / 2 - t / 2)), WAY, 0.002, name="frame")
        box((t, d, h - 2 * t), (s * (w / 2 - t / 2), 0, h / 2), WAY, 0.002, name="frame")
    box((w - 2 * t, d * 0.5, h - 2 * t), (0, d * 0.1, h / 2), "cream", 0.0, name="mount")
    fy = -d * 0.15 - 0.001
    pw = w - 0.12
    box((pw, 0.002, 0.03), (0, fy, h - 0.085), "night", 0.0, name="title")
    box((pw * 0.6, 0.002, 0.012), (-pw * 0.2, fy, h - 0.12), "grey", 0.0, name="subtitle")
    base = 0.17
    box((pw, 0.002, 0.006), (0, fy, base), "night", 0.0, name="axis")
    box((0.006, 0.002, 0.36), (-pw / 2 + 0.003, fy, base + 0.18), "night", 0.0, name="axis")
    hs = [0.1, 0.16, 0.13, 0.22, 0.27, 0.33]
    cols = ["blue", "blue", "teal", "blue", "teal", "mustard"]
    bw = (pw - 0.06) / len(hs)
    pts = []
    for i, (hh, c) in enumerate(zip(hs, cols)):
        x = -pw / 2 + 0.04 + bw * (i + 0.5)
        box((bw * 0.62, 0.002, hh), (x, fy, base + 0.003 + hh / 2), c, 0.0, name="bar")
        pts.append((x, base + hh + 0.03))
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, z1 - z0)
        box((L, 0.002, 0.006), ((x0 + x1) / 2, fy - 0.002, (z0 + z1) / 2), "mustard", 0.0,
            rot=(0, -math.atan2(z1 - z0, x1 - x0), 0), name="trend")
    for i, L in enumerate((0.3, 0.22, 0.26)):  # caption lines
        box((L, 0.002, 0.008), (-pw / 2 + L / 2, fy, 0.11 - i * 0.022), "grey", 0.0, name="caption")


@reg
def sideboard(w, d, h):
    # low sideboard: carcass on 4 tapered walnut legs; left door, 3 drawers in the middle, right door
    lh = 0.16
    ch = h - lh - 0.025
    box((w - 0.02, d - 0.05, ch), (0, 0.02, lh + ch / 2), WAY, 0.006, name="carcass")
    box((w, d, 0.025), (0, 0, h - 0.0125), WAY, 0.005, name="top")
    for sx in (-1, 1):
        for sy in (-1, 1):
            splay_leg((sx * (w / 2 - 0.08), sy * (d / 2 - 0.07), lh), (sx * (w / 2 - 0.05), sy * (d / 2 - 0.045), 0.0), 0.04, "walnut", name="leg", round_=True)
    fy = -d / 2 + 0.03
    g = 0.008
    sec = (w - 0.02 - 4 * g) / 3
    z0, z1 = lh + 0.03, h - 0.025 - 0.02
    fh = z1 - z0
    xs = [-sec - g, 0, sec + g]
    for x in (xs[0], xs[2]):
        box((sec, 0.02, fh), (x, fy, z0 + fh / 2), WAY, 0.005, name="door")
        hx = x + (sec / 2 - 0.035) * (1 if x < 0 else -1)
        box((0.012, 0.016, 0.14), (hx, fy - 0.015, z0 + fh * 0.55), "brass", 0.004, name="handle")
    dh = (fh - 2 * g) / 3
    for i in range(3):
        z = z0 + dh / 2 + i * (dh + g)
        box((sec, 0.02, dh), (0, fy, z), WAY, 0.005, name="drawer")
        box((0.12, 0.016, 0.012), (0, fy - 0.015, z + dh * 0.15), "brass", 0.004, name="handle")
    box((w - 0.04, 0.01, 0.02), (0, fy + 0.006, lh + 0.012), "dark", 0.0, name="shadow_gap")


@reg
def cushion_set(w, d, h):
    # three scatter cushions standing upright and leaning back: two big ones side by side, a smaller one in front
    specs = [  # (x, y, width, height, thick, colour, lean deg, twist deg)
        (-0.075, 0.03, 0.25, 0.31, 0.06, WAY, 14, 6),
        (0.08, 0.035, 0.24, 0.3, 0.06, "mustard", 12, -8),
        (0.0, -0.04, 0.19, 0.19, 0.05, "cream", 8, 3),
    ]
    for x, y, a, s, t, c, lean, tw in specs:
        o = pillow(a, s, t, c, name="cushion")
        o.rotation_euler = (math.radians(-lean), 0, math.radians(tw))
        o.location = (x, y, s / 2 * math.cos(math.radians(lean)) - 0.004)
        sphere(0.009, (x, y - t * math.cos(math.radians(lean)) - 0.002, s / 2 * math.cos(math.radians(lean))), "dark", scale=(1, 0.5, 1), name="button")


@reg
def tree_box(w, d, h):
    # long planked planter (`way`) with soil and a clipped low hedge
    bh = 0.21
    t = 0.022
    for s in (-1, 1):
        box((w, t, bh - 0.02), (0, s * (d / 2 - t / 2), 0.02 + (bh - 0.02) / 2), WAY, 0.003, name="side")
        box((t, d - 2 * t, bh - 0.02), (s * (w / 2 - t / 2), 0, 0.02 + (bh - 0.02) / 2), WAY, 0.003, name="side")
    for i in range(1, 3):  # plank seams on the long faces
        for s in (-1, 1):
            box((w - 0.01, 0.003, 0.004), (0, s * (d / 2 + 0.0005), 0.02 + i * (bh - 0.02) / 3), "dark", 0.0, name="seam")
    for sx in (-1, 0, 1):  # corner posts / feet
        for sy in (-1, 1):
            if sx == 0:
                continue
            box((0.045, 0.045, bh + 0.012), (sx * (w / 2 - 0.0225), sy * (d / 2 - 0.0225), (bh + 0.012) / 2), WAY, 0.004, name="post")
    box((w - 2 * t, d - 2 * t, 0.01), (0, 0, bh - 0.025), "walnut", 0.0, name="planter_soil")
    # hedge: a rounded block with leafy bumps
    hl, hd = w - 0.24, d - 0.1
    box((hl, hd, 0.1), (0, 0, bh + 0.02), "green", 0.035, name="hedge")
    n = 7
    for i in range(n):  # irregular clipped clumps, two rows, varying size
        x = -hl / 2 + 0.07 + i * (hl - 0.14) / (n - 1)
        for k, (y, c) in enumerate(((-hd / 4, "sage"), (hd / 4, "green"))):
            r = 0.07 + 0.012 * ((i * 3 + k * 2) % 3)
            sphere(r, (x + (0.05 if k else 0), y, h - r * 0.85), c, scale=(1.25, 1.0, 0.85), name="leaves")
    for x in (-0.3, 0.05, 0.36):
        cyl(0.012, 0.06, (x, 0, bh - 0.01), "walnut", name="tree_trunk")


@reg
def utensil_jar(w, d, h):
    # ceramic crock (`way`) holding a wooden spoon, a whisk, a spatula and a ladle
    jh, jr = 0.14, 0.055
    lathe([(0.045, 0.0), (jr, 0.012), (jr, jh - 0.015), (jr - 0.003, jh)], WAY, segs=24, name="jar")
    torus(jr - 0.004, 0.005, (0, 0, jh), "cream", seg=24, name="jar_rim")
    cyl(jr - 0.008, 0.003, (0, 0, jh - 0.01), "dark", verts=24, name="jar_inside")
    for zz in (0.045, 0.06):
        torus(jr + 0.0005, 0.003, (0, 0, zz), "cream", seg=24, name="band")
    # wooden spoon (oak), leaning left
    o = rod((-0.012, 0.0, jh - 0.06), (-0.035, -0.012, h - 0.06), 0.006, "oak", name="spoon")
    sphere(0.022, (-0.037, -0.013, h - 0.04), "oak", scale=(0.7, 0.3, 1.0), name="spoon")
    # whisk (steel handle + wire loops), centre-right
    rod((0.01, 0.01, jh - 0.06), (0.018, 0.012, jh + 0.05), 0.007, "steel", name="whisk")
    for k in range(3):
        o = torus(0.022, 0.0016, (0, 0, 0), "steel", rot=(math.pi / 2, 0, math.radians(k * 60)), name="whisk_wire")
        scaled(o, (1, 1, 2.3))
        o.location = (0.018, 0.012, jh + 0.05 + 0.022 * 2.3 - 0.004)
    # spatula (dark), leaning back
    rod((0.0, 0.018, jh - 0.06), (0.03, 0.03, h - 0.11), 0.005, "dark", name="spatula")
    box((0.03, 0.004, 0.045), (0.033, 0.031, h - 0.085), "dark", 0.006, rot=(0, math.radians(-12), 0), name="spatula")
    # ladle (steel), leaning right-front
    rod((0.01, -0.01, jh - 0.06), (0.03, -0.02, h - 0.05), 0.0045, "steel", name="ladle")
    sphere(0.009, (0.031, -0.021, h - 0.048), "steel", name="ladle")


@reg
def stand_mixer(w, d, h):
    # tilt-head stand mixer facing -Y: foot plate, rear column, horizontal head, steel bowl with beater
    yb = -0.035
    box((0.19, d - 0.01, 0.035), (0, 0, 0.0175), WAY, 0.012, name="base")
    box((0.12, 0.1, 0.2), (0, d / 2 - 0.065, 0.035 + 0.1), WAY, 0.03, name="column")
    # head: lathed nose-to-tail body lying along Y
    prof = [(0.03, 0.0), (0.045, 0.006), (0.055, 0.03), (0.058, 0.12), (0.056, 0.2), (0.05, 0.24), (0.03, 0.26)]
    o = lathe(prof, WAY, yscale=1.0, segs=24, name="head")
    o.rotation_euler = (math.radians(90), 0, 0)    # local +Z -> world -Y
    o.location = (0, d / 2 - 0.02, h - 0.058)
    cyl(0.03, 0.012, (0, d / 2 - 0.02 - 0.262, h - 0.058), "steel", "Y", 24, bevel=0.003, name="hub_cap")
    box((0.008, 0.03, 0.012), (0.058, d / 2 - 0.1, h - 0.058), "steel", 0.003, name="speed_lever")
    box((0.03, 0.06, 0.006), (0, d / 2 - 0.08, h - 0.058 + 0.057), "steel", 0.002, name="trim")
    # bowl clamp plate and steel bowl (open, hollow lathe)
    cyl(0.06, 0.012, (0, yb, 0.041), "steel", verts=24, name="bowl_plate")
    bowl = [(0.035, 0.0), (0.06, 0.012), (0.085, 0.05), (0.093, 0.1), (0.095, 0.125),
            (0.089, 0.125), (0.087, 0.1), (0.079, 0.052), (0.055, 0.02), (0.001, 0.016)]
    o = lathe(bowl, "steel", segs=28, name="bowl")
    o.location = (0, yb, 0.047)
    arc_bar([(0.09, 0.15), (0.108, 0.145), (0.11, 0.1), (0.092, 0.095)], 0.008, 0.016, "steel", name="bowl_handle", plane="XZ")
    # beater (flat paddle) down from the head into the bowl
    rod((0, yb, h - 0.11), (0, yb, 0.12), 0.006, "steel", name="beater_shaft")
    box((0.06, 0.008, 0.075), (0, yb, 0.1), "dark", 0.006, name="beater")
    box((0.03, 0.009, 0.045), (0, yb, 0.1), "steel", 0.004, name="beater_hole")


def main(argv):
    out = os.path.join(D.FAM, "batch5")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B5)
    rows = art.read_csv()
    for fid in (argv or BATCH5):
        assert fid in BATCH5, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
