"""Design Specialist builder, batch 4 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b4.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only)
and scaled() from build_families_design_b3.py. Output: families/batch4/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender),
flat matte rough 0.82, palette only, material 'way' = first colour-way.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402
import build_families_design_b3 as D3  # noqa: E402

art = D.art
box, cyl, sphere, torus, arc_bar = art.box, art.cyl, art.sphere, art.torus, art.arc_bar
scaled = D3.scaled
WAY = art.WAY
# later (non-first) colour-ways not in the palette, for the record: navy -> night, linen -> cream
D.ALIAS.update({"navy": "night", "linen": "cream", "canvas": "card"})

BATCH4 = ["poster", "towel_rail", "pram", "skis", "mannequin", "planter_box", "bowl_set",
          "casserole", "cookbooks", "bath_plant"]
B4 = {}


def reg(f):
    B4[f.__name__] = f
    return f


def rod(p1, p2, r, color, name="part", verts=12):
    p1, p2 = Vector(p1), Vector(p2)
    v = p2 - p1
    o = cyl(r, v.length, (p1 + p2) / 2, color, "Z", verts, name=name)
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(v.normalized())
    return o


def lathe(profile, color, yscale=1.0, segs=18, name="body", at=(0, 0, 0)):
    """Surface of revolution from [(radius, z)] bottom->top, caps at both ends,
    squashed by yscale on Y (oval cross-section). Smooth shaded."""
    import bmesh
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        rings.append([bm.verts.new((at[0] + r * math.cos(2 * math.pi * i / segs),
                                     at[1] + r * math.sin(2 * math.pi * i / segs) * yscale, at[2] + z))
                      for i in range(segs)])
    for A, B in zip(rings, rings[1:]):
        for i in range(segs):
            j = (i + 1) % segs
            bm.faces.new((A[i], A[j], B[j], B[i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    art._finish(o, color, 0.0, name)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def prism_xz(pts, y0, y1, color, name="part"):
    """Flat polygon [(x, z)] in the XZ plane extruded from y0 to y1."""
    import bmesh
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    a = [bm.verts.new((x, y0, z)) for x, z in pts]
    b = [bm.verts.new((x, y1, z)) for x, z in pts]
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return art._finish(o, color, 0.0, name)


@reg
def poster(w, d, h):
    # framed print: thin dark frame, cream mount, `way` print with a sun-over-hills graphic + title bars
    t = 0.014
    for s in (-1, 1):
        box((w, d, t), (0, 0, h / 2 + s * (h / 2 - t / 2)), "dark", 0.002, name="frame")
        box((t, d, h), (s * (w / 2 - t / 2), 0, h / 2), "dark", 0.002, name="frame")
    box((w - 2 * t, d * 0.4, h - 2 * t), (0, d * 0.15, h / 2), "cream", 0.0, name="mount")
    pw, ph = w - 0.1, h - 0.16
    pz = h / 2 + 0.03
    fy = -d * 0.05 - 0.001
    box((pw, 0.002, ph), (0, fy, pz), WAY, 0.0, name="print")
    cyl(0.07, 0.002, (0.07, fy - 0.0015, pz + ph * 0.18), "mustard", "Y", 24, name="sun")
    box((pw * 0.75, 0.002, ph * 0.28), (-pw * 0.12, fy - 0.003, pz - ph * 0.36), "sage", 0.0, rot=(0, math.radians(8), 0), name="hill")
    box((pw * 0.7, 0.002, ph * 0.2), (pw * 0.16, fy - 0.004, pz - ph * 0.4), "terracotta", 0.0, rot=(0, math.radians(-6), 0), name="hill")
    for i, L in enumerate((0.3, 0.2)):  # title lines on the mount below the print
        box((L, 0.002, 0.014 - i * 0.004), (0, fy, 0.05 - i * 0.022 + 0.012), "night", 0.0, name="title")


@reg
def towel_rail(w, d, h):
    # wall-mounted steel rail (wall at +Y) with a `way` towel folded over it
    ry, rz = -0.017, h - 0.03
    rod((-w / 2 + 0.01, ry, rz), (w / 2 - 0.01, ry, rz), 0.011, "steel", name="rail", verts=18)
    for s in (-1, 1):
        box((0.04, 0.012, 0.07), (s * (w / 2 - 0.02), d / 2 - 0.006, rz), "steel", 0.003, name="bracket")
        rod((s * (w / 2 - 0.02), d / 2 - 0.012, rz), (s * (w / 2 - 0.02), ry, rz), 0.009, "steel", name="arm")
        sphere(0.014, (s * (w / 2 - 0.014), ry, rz), "steel", name="end_cap")
    tw = w - 0.1
    r = 0.022
    cyl(r, tw, (0, ry, rz), WAY, "X", 18, name="towel_fold")
    for y, hh in ((ry - r + 0.006, rz - 0.0), (ry + r - 0.006, rz - 0.04)):  # front leg longer than back leg
        box((tw, 0.012, hh), (0, y, hh / 2), WAY, 0.004, name="towel")
    for zz in (0.035, 0.055):  # woven stripes near the hem
        box((tw + 0.002, 0.014, 0.008), (0, ry - r + 0.006, zz), "cream", 0.002, name="stripe")


@reg
def pram(w, d, h):
    # bassinet with folding hood at the +X end, push handle rising from that end, chassis + 4 wheels
    wr, wt = 0.12, 0.04
    bl, bd = 0.66, d - 2 * wt - 0.02
    bz0, bh = 0.4, 0.3
    bx = -0.05
    box((bl, bd, bh), (bx, 0, bz0 + bh / 2), WAY, 0.05, name="body")
    zt = bz0 + bh
    box((bl - 0.08, bd - 0.08, 0.01), (bx, 0, zt - 0.002), "dark", 0.0, name="opening")
    for sy in (-1, 1):  # padded cream trim around the opening
        box((bl - 0.04, 0.025, 0.02), (bx, sy * (bd / 2 - 0.03), zt + 0.002), "cream", 0.008, name="trim")
    box((0.025, bd - 0.04, 0.02), (bx - bl / 2 + 0.03, 0, zt + 0.002), "cream", 0.008, name="trim")
    box((bl * 0.45, bd - 0.1, 0.03), (bx - bl * 0.2, 0, zt + 0.004), "cream", 0.012, name="blanket")
    # hood: quarter-round shell with closed sides over the +X end, opening toward -X
    R = 0.3
    cx, cz = bx + bl / 2 - R + 0.01, zt - 0.01
    arc = [(cx + R * math.cos(math.radians(v)), cz + R * math.sin(math.radians(v))) for v in range(0, 91, 10)]
    # arc from the handle end (cx + R, cz) up over to (cx, cz + R): closed back toward the handle (+X), open toward -X
    arc_bar(arc, 0.03, bd + 0.012, WAY, name="hood", plane="XZ")
    fan = [(cx, cz)] + arc
    for sy in (-1, 1):
        prism_xz(fan, sy * (bd / 2 + 0.006) - 0.008 * sy, sy * (bd / 2 + 0.006), WAY, name="hood")
    for v in (25, 50, 75):
        for sy in (-1, 1):
            sphere(0.012, (cx + R * math.cos(math.radians(v)) * 0.98, sy * (bd / 2 + 0.008), cz + R * math.sin(math.radians(v)) * 0.98), "dark", scale=(1, 0.6, 1), name="hood_rib")
    # push handle
    hx0, hz0 = bx + bl / 2 - 0.02, bz0 + 0.12
    hx1, hz1 = w / 2 - 0.03, h - 0.03
    for s in (-1, 1):
        rod((hx0, s * (bd / 2 - 0.02), hz0), (hx1, s * (bd / 2 - 0.02), hz1), 0.012, "steel", name="handle")
    rod((hx1, -bd / 2 + 0.02, hz1), (hx1, bd / 2 - 0.02, hz1), 0.022, "dark", name="handle_grip")
    # chassis
    for s in (-1, 1):
        y = s * (bd / 2 - 0.02)
        rod((-0.3, y, wr), (bx - 0.1, y, bz0 + 0.02), 0.011, "steel", name="frame")
        rod((0.28, y, wr), (bx + 0.12, y, bz0 + 0.02), 0.011, "steel", name="frame")
        rod((-0.3, y, wr), (0.28, y, wr), 0.009, "steel", name="frame")
    rod((-0.3, -d / 2 + wt, wr), (-0.3, d / 2 - wt, wr), 0.009, "steel", name="axle")
    rod((0.28, -d / 2 + wt, wr), (0.28, d / 2 - wt, wr), 0.009, "steel", name="axle")
    for x in (-0.3, 0.28):
        for s in (-1, 1):
            cyl(wr, wt * 0.8, (x, s * (d / 2 - wt / 2), wr), "dark", "Y", 18, bevel=0.01, name="wheel")
            cyl(wr * 0.45, wt, (x, s * (d / 2 - wt / 2), wr), "steel", "Y", 18, name="hub")


@reg
def skis(w, d, h):
    # a pair of skis standing upright, tips curled toward the front (-Y), bindings + strap
    sw, st = 0.075, 0.016
    yb = d / 2 - st / 2 - 0.01
    L = h - 0.16
    for s in (-1, 1):
        x = s * 0.05
        box((sw, st, L), (x, yb, L / 2), WAY, 0.005, name="ski")
        box((sw * 0.3, 0.002, L * 0.7), (x, yb - st / 2 - 0.0005, L * 0.48), "white", 0.0, name="stripe")
        z, y = L, yb
        for i, a in enumerate((10, 20, 32, 45)):  # curled tip
            seg = 0.045
            ang = math.radians(a)
            cz, cy = z + seg / 2 * math.cos(ang), y - seg / 2 * math.sin(ang)
            box((sw * (1 - 0.06 * i), st, seg + 0.004), (x, cy, cz), WAY, 0.004, rot=(-ang, 0, 0), name="ski_tip")
            z, y = z + seg * math.cos(ang), y - seg * math.sin(ang)
        bz = L * 0.42
        box((sw * 0.9, 0.035, 0.09), (x, yb - st / 2 - 0.0175, bz + 0.12), "dark", 0.008, name="binding")
        box((sw * 0.9, 0.03, 0.07), (x, yb - st / 2 - 0.015, bz - 0.14), "dark", 0.008, name="binding")
        box((sw * 0.7, 0.012, 0.05), (x, yb - st / 2 - 0.04, bz + 0.12), "mustard", 0.004, name="binding_lever")
        cyl(0.018, sw * 0.9, (x, yb - st / 2 - 0.03, bz - 0.14), "steel", "X", 12, name="heel")
    box((0.2, d * 0.5, 0.035), (0, yb, L * 0.25), "dark", 0.006, name="strap")
    box((0.2, d * 0.5, 0.035), (0, yb, L * 0.62), "dark", 0.006, name="strap")


@reg
def mannequin(w, d, h):
    # dress-form torso on a pole with a tripod base
    yo = -0.005
    prof = [(0.06, 0.8), (0.15, 0.82), (0.195, 0.88), (0.205, 0.95), (0.19, 1.02), (0.155, 1.1), (0.15, 1.13),
            (0.17, 1.2), (0.19, 1.26), (0.2, 1.31), (0.19, 1.35), (0.13, 1.385), (0.05, 1.4)]
    lathe(prof, WAY, yscale=0.72, segs=20, name="body", at=(0, yo, 0))
    cyl(0.045, 0.06, (0, yo, 1.42), WAY, name="neck")
    cyl(0.055, 0.02, (0, yo, 1.46), "walnut", bevel=0.004, name="cap")
    sphere(0.02, (0, yo, h - 0.016), "walnut", name="cap")
    rod((0, yo, 0.38), (0, yo, 0.82), 0.014, "brass", name="pole")
    cyl(0.03, 0.06, (0, yo, 0.38), "walnut", bevel=0.006, name="hub")
    for a in (90, 210, 330):
        r = 0.15 if a == 90 else 0.17
        fx, fy = r * math.cos(math.radians(a)), r * math.sin(math.radians(a))
        fy = max(min(fy, d / 2 - 0.012), -d / 2 + 0.012)
        art.splay_leg((0, yo, 0.38), (fx, fy, 0.0), 0.024, "walnut", name="leg", round_=True)


@reg
def planter_box(w, d, h):
    th = 0.25
    box((w - 0.04, d - 0.04, th - 0.03), (0, 0, (th - 0.03) / 2 + 0.03), "walnut", 0.0, name="liner")
    for s in (-1, 1):  # corner posts and plank sides
        for sy in (-1, 1):
            box((0.04, 0.04, th), (s * (w / 2 - 0.02), sy * (d / 2 - 0.02), th / 2), WAY, 0.004, name="post")
    for i in range(3):
        z = 0.03 + i * 0.074 + 0.035
        for sy in (-1, 1):
            box((w - 0.08, 0.02, 0.066), (0, sy * (d / 2 - 0.016), z), WAY, 0.006, name="plank")
        for s in (-1, 1):
            box((0.02, d - 0.08, 0.066), (s * (w / 2 - 0.016), 0, z), WAY, 0.006, name="plank")
    box((w - 0.06, d - 0.06, 0.01), (0, 0, th - 0.02), "walnut", 0.003, name="planter_soil")
    plants = [(-0.28, 0.0, 0.09, "green"), (-0.1, 0.03, 0.11, "sage"), (0.1, -0.02, 0.1, "green"), (0.28, 0.02, 0.085, "sage")]
    for x, y, r, c in plants:
        sphere(r, (x, y, th - 0.02 + r * 0.7), c, scale=(1, 0.9, 0.8), name="plant")
    rng = [(-0.21, -0.05, "rose"), (-0.02, -0.08, "mustard"), (0.19, -0.06, "rose"), (0.33, -0.05, "mustard"), (-0.33, -0.06, "mustard")]
    for x, y, c in rng:  # flowers at the front
        sphere(0.03, (x, y, th + 0.07), c, scale=(1, 1, 0.7), name="flower")
    for a in range(5):  # a few tall leaves to reach full height
        x = -0.2 + a * 0.1
        box((0.025, 0.008, 0.16), (x, 0.06, h - 0.08), "green", 0.002, rot=(math.radians(-10), math.radians((a - 2) * 9), 0), name="leaf")


@reg
def bowl_set(w, d, h):
    # three nested bowls, each sitting inside the bigger one
    R = w / 2
    bowls = [(R, 0.0, 0.07), (R * 0.78, 0.028, 0.062), (R * 0.56, 0.058, 0.062)]
    for i, (r, z, bh) in enumerate(bowls):
        cyl(r * 0.5, 0.008, (0, 0, z + 0.004), WAY, verts=24, name="foot")
        cyl(r * 0.55, bh - 0.006, (0, 0, z + 0.006 + (bh - 0.006) / 2), WAY, verts=24, r2=r, name="bowl")
        torus(r - 0.004, 0.004, (0, 0, z + bh), "cream", seg=24, name="rim")
        cyl(r - 0.008, 0.002, (0, 0, z + bh - 0.001), "cream", verts=24, name="inside")


@reg
def casserole(w, d, h):
    r = d / 2
    bh = 0.095
    cyl(r, bh, (0, 0, bh / 2), WAY, verts=24, bevel=0.01, name="body")
    torus(r - 0.002, 0.005, (0, 0, bh), "cream", seg=24, name="rim")
    for s in (-1, 1):  # loop handles
        box((w / 2 - r + 0.02, 0.09, 0.018), (s * (r + (w / 2 - r) / 2 - 0.01), 0, bh - 0.02), WAY, 0.007, name="handle")
    sphere(r - 0.004, (0, 0, bh + 0.002), WAY, scale=(1, 1, 0.3), name="lid")
    cyl(0.018, 0.016, (0, 0, bh + 0.002 + (r - 0.004) * 0.3 + 0.006), "cream", name="knob")
    sphere(0.026, (0, 0, h - 0.012), "cream", scale=(1, 1, 0.48), name="knob")


@reg
def cookbooks(w, d, h):
    # small stack lying flat, spines toward the front (-Y), page edges cream
    books = [(0.24, 0.19, 0.04, WAY, 2), (0.22, 0.17, 0.032, "mustard", -4), (0.23, 0.18, 0.036, "terracotta", 3), (0.2, 0.15, 0.032, "sage", -2)]
    z = 0.0
    for bw, bd, bt, c, rz in books:
        bw, bd = bw * 0.96, bd * 0.96
        rot = (0, 0, math.radians(rz))
        k = math.radians(rz)

        def at(x, y, zz):
            return (x * math.cos(k) - y * math.sin(k), x * math.sin(k) + y * math.cos(k), zz)
        cv = 0.004
        box((bw, bd, cv), at(0, 0, z + cv / 2), c, 0.001, rot=rot, name="cover")
        box((bw, bd, cv), at(0, 0, z + bt - cv / 2), c, 0.001, rot=rot, name="cover")
        box((bw, 0.008, bt), at(0, -bd / 2 + 0.004, z + bt / 2), c, 0.003, rot=rot, name="spine")
        box((bw - 0.008, bd - 0.01, bt - 2 * cv), at(0, 0.002, z + bt / 2), "cream", 0.0, rot=rot, name="pages")
        box((bw * 0.4, 0.002, bt * 0.3), at(-bw * 0.12, -bd / 2 - 0.0005, z + bt / 2), "cream", 0.0, rot=rot, name="spine_label")
        z += bt


@reg
def bath_plant(w, d, h):
    # spider plant in a `way` pot: upright + arching strap leaves
    ph = 0.13
    cyl(0.07, ph, (0, 0, ph / 2), WAY, verts=18, r2=0.085, bevel=0.006, name="pot")
    torus(0.084, 0.008, (0, 0, ph), WAY, name="pot_rim")
    cyl(0.078, 0.004, (0, 0, ph - 0.006), "walnut", name="planter_soil")
    leaves = []
    for i in range(7):  # upright leaves
        a = math.radians(i * 360 / 7 + 10)
        leaves.append((a, 0.17 + 0.03 * (i % 3), 18 + 6 * (i % 2), "green" if i % 2 else "sage"))
    for a, L, tilt, c in leaves:
        r0 = 0.02
        x, y = r0 * math.cos(a), r0 * math.sin(a)
        tl = math.radians(tilt)
        cx = x + math.cos(a) * math.sin(tl) * L / 2
        cy = y + math.sin(a) * math.sin(tl) * L / 2
        box((0.022, 0.006, L), (cx, cy, ph + math.cos(tl) * L / 2), c, 0.002,
            rot=(0, tl, a), name="leaf")
    for i in range(8):  # arching leaves spilling over the rim
        a = math.radians(i * 45 + 22)
        pts = []
        for t in range(6):
            u = t / 5
            rr = 0.02 + u * 0.11
            zz = ph + 0.03 + math.sin(u * math.pi * 0.9) * 0.09 - u * 0.03
            pts.append((rr, zz))
        o = arc_bar(pts, 0.005, 0.02, "green" if i % 2 else "sage", name="leaf", bevel=0.0, plane="XZ")
        o.rotation_euler = (0, 0, a)


def main(argv):
    out = os.path.join(D.FAM, "batch4")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B4)
    rows = art.read_csv()
    for fid in (argv or BATCH4):
        assert fid in BATCH4, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
