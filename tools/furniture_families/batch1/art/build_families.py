"""Build Corner Office catalogue-family GLBs (batch 1), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: this script builds only the 10 families in MINE (the other 10 of
batch 1 belong to Design Specialist; their builders here are unused).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch1
MINE = ["bin_kitchen", "bath_mat", "wine_rack", "suitcase", "toy_box", "ottoman", "bar_stool", "shoe_rack", "bookshelf_v", "plant_pot_v"]
CSV = os.path.join(os.path.dirname(OUT), "families.csv")

# Catalogue palette (gen_items.py, see FAMILIES.md). Copper B87333 is never used.
PAL = {
    "oak": "C68B59", "walnut": "6B4A3A", "pine": "D9B98A", "dark": "2B2622",
    "cream": "F4F1EA", "white": "EAE6DC", "card": "E7DCC6", "terracotta": "D9765F",
    "sage": "8FA882", "mustard": "E6B655", "blue": "4A6FA5", "rose": "E8B4A8",
    "night": "3E3A4F", "red": "B6453F", "green": "5E7B52", "steel": "C9CED3",
    "grey": "8E8276", "teal": "4F8A8B", "plum": "6E4B6E", "brass": "C9A24E",
    "kraft": "C9A070", "glass": "BFD6DA", "black": "1E1B19",
}
# colour-way names in the CSV that are not palette keys
WAY_ALIAS = {"painted white": "white", "painted sage": "sage", "tan": "kraft", "wicker": "kraft"}
WAY = "way"

_mats = {}


def _lin(hex_color):
    r, g, b = (int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (r, g, b)]


def mat(key, rough=0.82, metal=0.0):
    """key is a palette name or WAY. Materials are named after the key."""
    if key in _mats:
        return _mats[key]
    hx = _WAY_HEX if key == WAY else PAL[key]
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*_lin(hx), 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    m.diffuse_color = (*_lin(hx), 1.0)
    _mats[key] = m
    return m


_WAY_HEX = "C68B59"


def _finish(o, color, bevel, name):
    o.name = name
    o.data.name = name
    o.data.materials.append(mat(color))
    if bevel > 0:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
    for p in o.data.polygons:
        p.use_smooth = False
    return o


def box(size, at, color, bevel=0.008, rot=(0, 0, 0), name="part"):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=at, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, color, min(bevel, min(size) * 0.3), name)


def cyl(r, h, at, color, axis="Z", verts=18, rot=None, bevel=0.0, name="part", r2=None):
    rotation = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}[axis]
    if rot is not None:
        rotation = rot
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=at, rotation=rotation)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=h, location=at, rotation=rotation)
    o = bpy.context.active_object
    return _finish(o, color, min(bevel, h * 0.3, r * 0.3) if bevel else 0.0, name)


def sphere(r, at, color, scale=(1, 1, 1), name="part", rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=r, location=at, rotation=rot)
    o = bpy.context.active_object
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o = _finish(o, color, 0.0, name)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def torus(R, r, at, color, rot=(0, 0, 0), name="part", seg=18):
    bpy.ops.mesh.primitive_torus_add(major_segments=seg, minor_segments=8, major_radius=R, minor_radius=r, location=at, rotation=rot)
    o = bpy.context.active_object
    o = _finish(o, color, 0.0, name)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def arc_bar(pts, thick, width, color, name="part", bevel=0.006, plane="YZ", offset=0.0):
    """A bent bar along a 2D polyline pts [(u, v)], extruded `width` along the
    third axis, `thick` across the line. plane 'YZ' -> u=y, v=z, offset=x."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    n = len(pts)
    rings = []
    for i, (u, v) in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, n - 1)]
        tu, tv = b[0] - a[0], b[1] - a[1]
        L = math.hypot(tu, tv) or 1.0
        nu, nv = -tv / L, tu / L
        ring = []
        for s in (-1, 1):
            for e in (-1, 1):
                pu, pv = u + nu * thick / 2 * s, v + nv * thick / 2 * s
                if plane == "YZ":
                    co = (offset + e * width / 2, pu, pv)
                else:  # XZ
                    co = (pu, offset + e * width / 2, pv)
                ring.append(bm.verts.new(co))
        rings.append(ring)  # order: (s-,e-),(s-,e+),(s+,e-),(s+,e+)
    quad = [(0, 1, 3, 2)]
    for i in range(n - 1):
        A, B = rings[i], rings[i + 1]
        for p, q in ((0, 1), (1, 3), (3, 2), (2, 0)):
            bm.faces.new((A[p], A[q], B[q], B[p]))
    bm.faces.new([rings[0][k] for k in (0, 2, 3, 1)])
    bm.faces.new([rings[-1][k] for k in (0, 1, 3, 2)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return _finish(o, color, min(bevel, thick * 0.3, width * 0.3), name)


def legs4(w, d, h, color, t=0.04, inset=0.0, z0=0.0, name="leg", taper=None):
    for x in (-w / 2 + inset + t / 2, w / 2 - inset - t / 2):
        for y in (-d / 2 + inset + t / 2, d / 2 - inset - t / 2):
            if taper:
                cyl(t / 2, h, (x, y, z0 + h / 2), color, "Z", 12, r2=taper / 2, name=name, bevel=0.004)
            else:
                box((t, t, h), (x, y, z0 + h / 2), color, 0.004, name=name)


def splay_leg(top, bot, t, color, name="leg", round_=False):
    top, bot = Vector(top), Vector(bot)
    v = top - bot
    L = v.length
    mid = (top + bot) / 2
    q = Vector((0, 0, 1)).rotation_difference(v.normalized())
    if round_:
        o = cyl(t / 2, L, mid, color, "Z", 12, name=name, r2=t * 0.38, bevel=0.003)
        # cone: radius1 at bottom (-Z local); we want thin at bottom -> flip
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = q @ Vector((0, 0, 1)).rotation_difference(Vector((0, 0, -1)))
    else:
        o = box((t, t, L), mid, color, 0.004, name=name)
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = q
    return o

# ========================================================== builders
# Each builder gets the plain variant's w, d, h and must stay inside it.


def bin_kitchen(w, d, h):
    # square-ish swing/pedal bin: rounded body, steel lid with a flip, pedal
    bh = h - 0.05
    box((w - 0.02, d - 0.03, bh - 0.025), (0, 0.005, 0.025 + (bh - 0.025) / 2), WAY, 0.05, name="body")
    box((w - 0.04, d - 0.05, 0.025), (0, 0.005, 0.0125), "dark", 0.006, name="base")
    box((w, d - 0.01, 0.035), (0, 0.005, bh + 0.0175), "steel", 0.012, name="lid_rim")
    box((w - 0.06, d - 0.06, 0.015), (0, 0.005, bh + 0.035 + 0.0075), "steel", 0.006, name="lid")
    box((0.1, 0.03, 0.012), (0, -d / 2 + 0.02, bh + 0.043), "dark", 0.004, name="lid_grip")
    box((0.13, 0.04, 0.02), (0, -d / 2 + 0.02, 0.03), "steel", 0.006, name="pedal")
    box((w - 0.12, 0.004, 0.07), (0, -d / 2 + 0.015 - 0.002, bh * 0.62), "steel", 0.0, name="label_plate")


def bath_mat(w, d, h):
    box((w, d, h * 0.7), (0, 0, h * 0.35), WAY, 0.008, name="mat")
    # raised pile ridges and a cream border
    for i in range(5):
        y = -d / 2 + 0.07 + i * (d - 0.14) / 4
        box((w - 0.12, 0.035, h * 0.3), (0, y, h * 0.7 + h * 0.15), WAY, 0.004, name="mat_ridge")
    for y in (-d / 2 + 0.025, d / 2 - 0.025):
        box((w - 0.02, 0.018, h * 0.32), (0, y, h * 0.7 + h * 0.15), "cream", 0.004, name="trim")
    for x in (-w / 2 + 0.025, w / 2 - 0.025):
        box((0.018, d - 0.02, h * 0.32), (x, 0, h * 0.7 + h * 0.15), "cream", 0.004, name="trim")


def wine_rack(w, d, h):
    t = 0.03
    for x in (-w / 2 + t / 2, w / 2 - t / 2):
        for y in (-d / 2 + t / 2, d / 2 - t / 2):
            box((t, t, h), (x, y, h / 2), WAY, 0.006, name="post")
    rows = 3
    for i in range(rows + 1):
        z = 0.06 + i * (h - 0.1) / rows
        for y in (-d / 2 + t / 2, d / 2 - t / 2):
            box((w - 2 * t, 0.022, 0.03), (0, y, z), WAY, 0.005, name="rail")
    box((w, d, 0.025), (0, 0, h - 0.0125), WAY, 0.006, name="top")
    # 3x3 bottles lying front-to-back, neck to the front
    sx = (w - 2 * t) / 3
    for i in range(rows):
        z = 0.06 + (i + 0.5) * (h - 0.1) / rows + 0.005
        for j in range(3):
            x = -w / 2 + t + sx * (j + 0.5)
            col = ["green", "red", "green"][(i + j) % 3]
            r = min(0.038, sx * 0.42)
            cyl(r, d * 0.6, (x, d * 0.13, z), col, "Y", 14, name="bottle", bevel=0.006)
            cyl(r * 0.95, 0.03, (x, -d * 0.2 + 0.0, z), col, "Y", 14, r2=r * 0.4, name="bottle_shoulder")
            cyl(r * 0.36, d * 0.17, (x, -d * 0.31, z), col, "Y", 10, name="bottle_neck")
            cyl(r * 0.4, 0.02, (x, -d / 2 + 0.012, z), "cream" if col == "green" else "brass", "Y", 10, name="cork")


def suitcase(w, d, h):
    wh = 0.035
    bh = h - wh - 0.1
    z0 = wh * 1.2
    box((w, d - 0.01, bh), (0, 0.005, z0 + bh / 2), WAY, 0.035, name="body")
    box((w + 0.0, d + 0.0, 0.016), (0, 0, z0 + bh * 0.52), "dark", 0.006, name="zip_seam")
    # vertical ribs on the front shell
    for x in (-w * 0.27, -w * 0.09, w * 0.09, w * 0.27):
        box((0.035, 0.012, bh * 0.82), (x, -d / 2 + 0.006, z0 + bh / 2), WAY, 0.005, name="body_rib")
    # corner guards and wheels at the back
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        cyl(wh, 0.03, (x, d / 2 - 0.045, wh), "black", "X", 14, name="wheel")
        box((0.06, 0.05, 0.03), (x, d / 2 - 0.045, z0 + 0.01), "dark", 0.006, name="wheel_housing")
        box((0.07, 0.01, 0.07), (x, -d / 2 + 0.008, z0 + 0.04), "dark", 0.004, name="corner_guard")
    # telescopic handle at the back
    ztop = z0 + bh
    for x in (-w * 0.25, w * 0.25):
        box((0.02, 0.015, h - ztop - 0.01), (x, d / 2 - 0.03, ztop + (h - ztop - 0.01) / 2), "steel", 0.003, name="handle_rod")
    box((w * 0.5 + 0.03, 0.03, 0.03), (0, d / 2 - 0.03, h - 0.015), "black", 0.01, name="handle_grip")
    box((0.14, 0.03, 0.03), (0, -0.01, ztop + 0.012), "black", 0.01, name="carry_handle")
    box((0.08, 0.012, 0.05), (w * 0.22, -d / 2 + 0.002, z0 + bh * 0.78), "cream", 0.004, name="luggage_tag")


def toy_box(w, d, h):
    bw = w - 0.04
    bh = h - 0.06
    box((bw, d - 0.02, bh), (0, 0, bh / 2), WAY, 0.015, name="chest")
    box((bw + 0.02, d, 0.06), (0, 0, bh + 0.03), WAY, 0.015, name="lid")
    box((bw + 0.004, d - 0.016, 0.04), (0, 0, bh - 0.05), "cream", 0.006, name="band")
    box((bw + 0.004, d - 0.016, 0.03), (0, 0, 0.05), "cream", 0.006, name="band")
    # alphabet blocks painted on the front
    for i, c in enumerate(("red", "mustard", "sage")):
        x = -0.15 + i * 0.15
        box((0.11, 0.014, 0.11), (x, -d / 2 + 0.006, bh * 0.5), c, 0.008, name="block_letter")
        box((0.05, 0.016, 0.05), (x, -d / 2 + 0.003, bh * 0.5), "cream", 0.004, name="block_letter_mark")
    for x in (-w / 2 + 0.012, w / 2 - 0.012):
        box((0.024, 0.12, 0.035), (x, 0, bh * 0.75), "kraft", 0.008, name="rope_handle")


def ottoman(w, d, h):
    fh = 0.06
    bh = h - fh - 0.08
    box((w, d, bh), (0, 0, fh + bh / 2), WAY, 0.035, name="body")
    box((w - 0.01, d - 0.01, 0.09), (0, 0, h - 0.045), WAY, 0.04, name="cushion")
    box((w + 0.0, d + 0.0, 0.012), (0, 0, h - 0.088), "cream", 0.004, name="piping")
    for x in (-w * 0.3, 0.0, w * 0.3):
        for y in (-d * 0.2, d * 0.2):
            sphere(0.012, (x, y, h - 0.004), "cream", scale=(1, 1, 0.6), name="button")
    legs4(w, d, fh, "walnut", 0.05, 0.04, name="foot", taper=0.035)


def bar_stool(w, d, h):
    r = w / 2
    cyl(r * 0.95, 0.06, (0, 0, h - 0.03), WAY, "Z", 18, name="seat", bevel=0.015)
    cyl(r * 0.85, 0.02, (0, 0, h - 0.07), "dark", "Z", 18, name="seat_pan")
    cyl(0.022, h - 0.1, (0, 0, (h - 0.1) / 2 + 0.02), "steel", "Z", 12, name="pole")
    cyl(0.04, 0.06, (0, 0, h - 0.1), "steel", "Z", 12, name="gas_lift")
    torus(r * 0.62, 0.012, (0, 0, h * 0.36), "steel", name="foot_ring")
    for a in range(4):
        ang = a * math.pi / 2 + math.pi / 4
        box((r * 0.62, 0.012, 0.012), (math.cos(ang) * r * 0.31, math.sin(ang) * r * 0.31, h * 0.36), "steel", 0.003, rot=(0, 0, ang), name="foot_ring_spoke")
    cyl(r, 0.025, (0, 0, 0.0125), "steel", "Z", 18, r2=r * 0.85, name="base", bevel=0.006)


def shoe_rack(w, d, h):
    t = 0.025
    for x in (-w / 2 + t / 2, w / 2 - t / 2):
        box((t, d, h), (x, 0, h / 2), WAY, 0.006, name="side")
    shelves = (0.05, h * 0.5)
    for z in shelves:
        for k in range(3):
            y = -d / 2 + 0.05 + k * (d - 0.1) / 2
            box((w - 2 * t, 0.06, 0.018), (0, y, z + k * 0.025), WAY, 0.004, name="slat")
    box((w, d, 0.022), (0, 0, h - 0.011), WAY, 0.006, name="top")
    # shoes: pairs on each slanted shelf
    cols = [("terracotta", "blue", "dark"), ("cream", "mustard", "night")]
    for si, z in enumerate(shelves):
        for pi, c in enumerate(cols[si]):
            xc = -w / 2 + t + (w - 2 * t) * (pi + 0.5) / 3
            for s in (-1, 1):
                x = xc + s * 0.04
                sh = min(0.075, h * 0.5 - 0.06 - 0.035)
                box((0.07, d * 0.78, sh * 0.55), (x, 0, z + 0.04 + sh * 0.27), c, 0.015, rot=(-0.08, 0, 0), name="shoe")
                box((0.068, d * 0.32, sh * 0.5), (x, d * 0.2, z + 0.06 + sh * 0.5), c, 0.015, rot=(-0.08, 0, 0), name="shoe_heel")
                box((0.072, d * 0.8, 0.012), (x, 0, z + 0.035), "cream" if c == "dark" else "dark", 0.004, rot=(-0.08, 0, 0), name="shoe_sole")


def bookshelf_v(w, d, h):
    t = 0.025
    for x in (-w / 2 + t / 2, w / 2 - t / 2):
        box((t, d, h), (x, 0, h / 2), WAY, 0.008, name="side")
    box((w, d, t), (0, 0, h - t / 2), WAY, 0.008, name="top")
    box((w - 2 * t, d - 0.02, 0.06), (0, -0.0, 0.03), WAY, 0.006, name="plinth")
    box((w - 2 * t, 0.012, h - 0.06), (0, d / 2 - 0.006, h / 2 + 0.03), WAY, 0.003, name="back")
    n = 3
    inner = h - t - 0.06
    zs = [0.06 + i * inner / n for i in range(n)]
    for z in zs[1:]:
        box((w - 2 * t, d - 0.02, 0.022), (0, -0.005, z), WAY, 0.005, name="shelf")
    cols = ["terracotta", "blue", "mustard", "sage", "cream", "night", "terracotta", "sage", "blue", "mustard", "cream"]
    import random
    rnd = random.Random(7)
    for si, z in enumerate(zs):
        base = z + (0.011 if si else 0.0)
        gap = inner / n - 0.035
        x = -w / 2 + t + 0.02
        k = si * 3
        limit = w / 2 - t - (0.18 if si == 1 else 0.03)
        while True:
            bw = rnd.choice((0.03, 0.035, 0.045, 0.05))
            if x + bw > limit:
                break
            bh_ = gap * rnd.uniform(0.62, 0.86)
            box((bw - 0.004, d * 0.72, bh_), (x + bw / 2, 0.0, base + bh_ / 2), cols[k % len(cols)], 0.004, name="book")
            x += bw
            k += 1
        if si == 1:  # a leaning book and a little pile
            for j in range(3):
                box((0.14, d * 0.6, 0.03), (w / 2 - t - 0.09, 0.0, base + 0.015 + j * 0.031), cols[(j + 4) % len(cols)], 0.004, name="book")
    sphere(0.045, (w / 2 - t - 0.06, 0, zs[2] + 0.011 + 0.045), "terracotta", name="ornament")


def plant_pot_v(w, d, h):
    pr = w * 0.36
    ph = h * 0.38
    cyl(pr * 0.82, ph, (0, 0, ph / 2), WAY, "Z", 18, r2=pr, name="pot", bevel=0.01)
    torus(pr - 0.005, 0.016, (0, 0, ph - 0.01), WAY, name="pot_rim")
    cyl(pr - 0.02, 0.02, (0, 0, ph - 0.015), "dark", "Z", 18, name="soil")
    # stems and big leaves (monstera-ish), each leaf points out from the
    # centre and droops a little; kept inside w x d x h
    sl = 0.095
    leaves = [  # (angle deg, centre radius, centre z, droop rad)
        (90, 0.02, h - sl * 0.93 - 0.015, -1.2),
        (-90, 0.03, h - 0.12, -0.9),
        (20, 0.09, h * 0.8, -0.35), (140, 0.09, h * 0.83, -0.3), (260, 0.09, h * 0.78, -0.35),
        (90, w / 2 - sl - 0.005, h * 0.66, 0.05), (180, w / 2 - sl - 0.005, h * 0.64, 0.1),
        (0, w / 2 - sl - 0.005, h * 0.68, 0.0), (270, w / 2 - sl - 0.005, h * 0.57, 0.15),
        (45, 0.13, h * 0.56, 0.3), (225, 0.13, h * 0.55, 0.3),
    ]
    for i, (ang, rc, zc, droop) in enumerate(leaves):
        yaw = math.radians(ang)
        cx, cy = math.cos(yaw) * rc, math.sin(yaw) * rc
        col = "green" if i % 2 == 0 else "sage"
        # inner end of the leaf, where the stem meets it
        ix = cx - math.cos(yaw) * sl * math.cos(droop) * 0.8
        iy = cy - math.sin(yaw) * sl * math.cos(droop) * 0.8
        iz = zc + sl * math.sin(droop) * 0.8
        splay_leg((ix, iy, iz), (math.cos(yaw) * 0.02, math.sin(yaw) * 0.02, ph - 0.01), 0.012, "green", name="stem")
        o = sphere(sl, (cx, cy, zc), col, scale=(1.0, 0.6, 0.14), name="leaf")
        o.rotation_euler = (0, droop, yaw)
        v = box((sl * 1.8, 0.008, 0.008), (cx, cy, zc + 0.006), "sage" if col == "green" else "green", 0.0, name="leaf_vein")
        v.rotation_euler = (0, droop, yaw)


def floor_lamp_v(w, d, h):
    cyl(w * 0.34, 0.03, (0, 0, 0.015), "dark", "Z", 18, r2=w * 0.3, name="base", bevel=0.008)
    cyl(0.014, h - 0.3, (0, 0, (h - 0.3) / 2 + 0.02), "brass", "Z", 10, name="pole")
    cyl(0.025, 0.06, (0, 0, h * 0.45), "brass", "Z", 10, name="pole_joint")
    cyl(0.02, 0.05, (0, 0, h - 0.3), "brass", "Z", 10, name="bulb_holder")
    sphere(0.035, (0, 0, h - 0.24), "cream", name="bulb")
    cyl(w / 2, 0.32, (0, 0, h - 0.16), WAY, "Z", 18, r2=w / 2 * 0.62, name="shade", bevel=0.006)
    torus(w / 2 - 0.002, 0.008, (0, 0, h - 0.316), "brass", name="shade_trim")
    box((0.04, 0.02, 0.012), (0, -w * 0.2, 0.034), "brass", 0.004, name="foot_switch")


def kitchen_trolley(w, d, h):
    cr = 0.035
    leg_h = h - 0.05 - 2 * cr
    z0 = 2 * cr
    t = 0.035
    bw = w - 0.08  # leave room for side rail on +X
    xo = -0.04
    for x in (xo - bw / 2 + t / 2, xo + bw / 2 - t / 2):
        for y in (-d / 2 + cr + t / 2 - 0.016, d / 2 - cr - t / 2 + 0.016):
            box((t, t, leg_h), (x, y, z0 + leg_h / 2), "steel", 0.006, name="leg")
            cyl(cr, 0.025, (x, y, cr), "black", "X", 12, name="castor")
            box((0.03, 0.03, 0.02), (x, y, 2 * cr - 0.005), "steel", 0.004, name="castor_fork")
    box((bw + 0.01, d, 0.05), (xo, 0, h - 0.025), WAY, 0.01, name="top")
    for z in (z0 + 0.06, z0 + leg_h * 0.5):
        box((bw - 0.01, d - 0.03, 0.025), (xo, 0, z), WAY, 0.006, name="shelf")
        for y in (-d / 2 + 0.012, d / 2 - 0.012):
            box((bw - 2 * t, 0.012, 0.05), (xo, y, z + 0.035), WAY, 0.003, name="shelf_lip")
    # side towel rail on the right
    for y in (-d * 0.3, d * 0.3):
        box((0.06, 0.015, 0.015), (xo + bw / 2 + 0.03, y, h - 0.12), "steel", 0.003, name="rail_bracket")
    cyl(0.01, d * 0.66, (w / 2 - 0.012, 0, h - 0.12), "steel", "Y", 10, name="towel_rail")
    box((0.012, d * 0.4, 0.2), (w / 2 - 0.012, 0, h - 0.22), "terracotta", 0.004, name="towel")
    # things on the shelves
    zm = z0 + leg_h * 0.5 + 0.0125
    for i in range(3):
        x = xo - bw * 0.3 + i * bw * 0.22
        cyl(0.045, 0.14, (x, 0, zm + 0.07), "glass", "Z", 14, name="jar")
        cyl(0.047, 0.025, (x, 0, zm + 0.152), "steel", "Z", 14, name="jar_lid")
    zb = z0 + 0.06 + 0.0125
    box((0.22, d * 0.6, 0.12), (xo - bw * 0.2, 0, zb + 0.06), "kraft", 0.012, name="basket")
    for i in range(3):
        cyl(0.04, 0.1, (xo + bw * 0.15 + i * 0.09, 0, zb + 0.05), ["terracotta", "mustard", "terracotta"][i], "Z", 12, name="produce")


def high_chair(w, d, h):
    seat_z = h * 0.55
    sw, sd = w * 0.62, d * 0.5
    sy = d * 0.06
    for sx_ in (-1, 1):
        for sy_ in (-1, 1):
            top = (sx_ * (sw / 2 - 0.03), sy + sy_ * (sd / 2 - 0.03), seat_z)
            bot = (sx_ * (w / 2 - 0.025), sy_ * (d / 2 - 0.025), 0.0)
            o = splay_leg(top, bot, 0.035, WAY, name="leg")
    # lower stretchers and footrest
    for sy_ in (-1, 1):
        y = sy_ * (d / 2 - 0.06) + sy * 0.3
        box((w * 0.8, 0.022, 0.022), (0, y * 0.9, h * 0.16), WAY, 0.004, name="stretcher")
    box((sw + 0.04, 0.09, 0.02), (0, sy - sd / 2 - 0.02, seat_z * 0.55), WAY, 0.005, name="footrest")
    box((sw, sd, 0.035), (0, sy, seat_z), WAY, 0.008, name="seat")
    box((sw - 0.06, sd - 0.06, 0.025), (0, sy, seat_z + 0.03), "mustard", 0.01, name="cushion")
    # back
    by = sy + sd / 2 - 0.02
    for x in (-sw / 2 + 0.02, sw / 2 - 0.02):
        box((0.032, 0.032, h - seat_z), (x, by, seat_z + (h - seat_z) / 2), WAY, 0.005, name="back_post")
    box((sw, 0.03, 0.09), (0, by, h - 0.045), WAY, 0.01, name="back_rail")
    box((sw - 0.04, 0.02, 0.06), (0, by, seat_z + 0.16), WAY, 0.006, name="back_slat")
    # arms and front feeding table
    for x in (-sw / 2 + 0.016, sw / 2 - 0.016):
        box((0.03, sd * 0.9, 0.03), (x, sy - 0.01, seat_z + 0.17), WAY, 0.006, name="arm")
        box((0.03, 0.03, 0.17), (x, sy - sd / 2 + 0.03, seat_z + 0.085), WAY, 0.005, name="arm_post")
    box((sw + 0.06, 0.14, 0.025), (0, sy - sd / 2 - 0.02, seat_z + 0.2), "cream", 0.01, name="front_table")
    box((sw, 0.12, 0.012), (0, sy - sd / 2 - 0.02, seat_z + 0.218), "cream", 0.005, name="front_table_lip")


def laundry_hamper(w, d, h):
    r = w / 2 - 0.012
    bh = h - 0.07
    cyl(r * 0.9, bh, (0, 0, bh / 2), WAY, "Z", 18, r2=r, name="body", bevel=0.008)
    for i in range(5):
        z = 0.06 + i * (bh - 0.08) / 4
        rr = r * 0.9 + (r - r * 0.9) * (z / bh)
        torus(rr + 0.003, 0.008, (0, 0, z), WAY, name="weave_band")
    torus(r + 0.002, 0.014, (0, 0, bh - 0.005), WAY, name="rim")
    cyl(r + 0.004, 0.04, (0, 0, bh + 0.02), WAY, "Z", 18, r2=r - 0.02, name="lid", bevel=0.01)
    cyl(0.025, 0.03, (0, 0, h - 0.015), "oak", "Z", 12, name="lid_knob", bevel=0.006)
    for s in (-1, 1):
        o = torus(0.04, 0.008, (s * (r + 0.002), 0, bh - 0.08), "kraft", rot=(0, math.pi / 2, 0), name="rope_handle")
        o.scale = (1, 1, 1)


def bath_bin(w, d, h):
    r = w / 2 - 0.006
    bh = h - 0.035
    cyl(r, bh - 0.015, (0, 0.004, 0.015 + (bh - 0.015) / 2), WAY, "Z", 18, name="body", bevel=0.008)
    cyl(r - 0.008, 0.015, (0, 0.004, 0.0075), "dark", "Z", 18, name="base")
    cyl(r + 0.002, 0.012, (0, 0.004, bh + 0.006), "steel", "Z", 18, name="lid_rim")
    o = sphere(r - 0.004, (0, 0.004, bh + 0.012), "steel", scale=(1, 1, (h - bh - 0.012) / (r - 0.004)), name="lid")
    # cut to dome: squash the lower half into the rim
    for v in o.data.vertices:
        if v.co.z < 0:
            v.co.z = 0
    box((0.06, 0.03, 0.012), (0, -w / 2 + 0.015, 0.02), "steel", 0.004, name="pedal")
    box((0.03, 0.01, 0.03), (0, -r - 0.0, bh + 0.0), "steel", 0.003, name="hinge_tab")


def side_table_v(w, d, h):
    r = w / 2
    cyl(r, 0.035, (0, 0, h - 0.0175), WAY, "Z", 18, name="top", bevel=0.01)
    cyl(r - 0.03, 0.04, (0, 0, h - 0.055), WAY, "Z", 18, name="apron")
    cyl(r * 0.72, 0.02, (0, 0, h * 0.3), WAY, "Z", 18, name="shelf", bevel=0.005)
    for i in range(3):
        a = i * 2 * math.pi / 3 + math.pi / 2
        top = (math.cos(a) * (r - 0.06), math.sin(a) * (r - 0.06), h - 0.07)
        bot = (math.cos(a) * (r - 0.03), math.sin(a) * (r - 0.03), 0.0)
        splay_leg(top, bot, 0.04, WAY, name="leg", round_=True)


def dressing_stool(w, d, h):
    ch = 0.07
    cz = h - ch / 2
    box((w, d, ch), (0, 0, cz), WAY, 0.03, name="cushion")
    box((w + 0.0, d + 0.0, 0.01), (0, 0, h - ch + 0.005), "cream", 0.004, name="piping")
    for x in (-w * 0.2, w * 0.2):
        sphere(0.01, (x, 0, h - 0.003), "cream", scale=(1, 1, 0.5), name="button")
    sphere(0.01, (0, 0, h - 0.003), "cream", scale=(1, 1, 0.5), name="button")
    az = h - ch - 0.04
    box((w - 0.04, d - 0.04, 0.06), (0, 0, az), "white", 0.008, name="apron")
    for sx in (-1, 1):
        for sy in (-1, 1):
            top = (sx * (w / 2 - 0.045), sy * (d / 2 - 0.045), h - ch)
            bot = (sx * (w / 2 - 0.022), sy * (d / 2 - 0.022), 0.0)
            splay_leg(top, bot, 0.038, "white", name="leg", round_=True)
    box((w - 0.1, 0.018, 0.018), (0, 0, h * 0.2), "white", 0.004, name="stretcher")


def armchair_v(w, d, h):
    lh = 0.1
    seat_z = lh + 0.3
    aw = 0.13
    # base box and seat cushion
    box((w - 2 * aw + 0.02, d - 0.04, seat_z - lh - 0.06), (0, 0.0, lh + (seat_z - lh - 0.06) / 2), WAY, 0.03, name="base")
    box((w - 2 * aw, d * 0.72, 0.13), (0, -d * 0.12, seat_z + 0.0), WAY, 0.04, name="cushion")
    # back with a soft top roll
    box((w - 0.04, 0.18, h - lh - 0.06), (0, d / 2 - 0.09, lh + (h - lh - 0.06) / 2), WAY, 0.04, name="back")
    cyl(0.06, w - 0.06, (0, d / 2 - 0.09, h - 0.06), WAY, "X", 18, name="back_roll", bevel=0.015)
    box((w - 2 * aw - 0.02, 0.12, (h - seat_z) * 0.62), (0, d / 2 - 0.22, seat_z + (h - seat_z) * 0.36), WAY, 0.04, rot=(-0.12, 0, 0), name="back_cushion")
    # rolled arms
    ah = h * 0.6
    for s in (-1, 1):
        x = s * (w / 2 - aw / 2)
        box((aw, d - 0.04, ah - lh - 0.06), (x, 0.0, lh + (ah - lh - 0.06) / 2), WAY, 0.03, name="arm")
        cyl(aw / 2 + 0.005, d - 0.06, (x, -0.0, ah - 0.06), WAY, "Y", 18, name="arm_roll", bevel=0.02)
        cyl(aw / 2 - 0.01, 0.01, (x, -d / 2 + 0.035, ah - 0.06), "cream", "Y", 18, name="arm_button")
    legs4(w - 0.04, d - 0.06, lh, "walnut", 0.05, 0.02, name="leg", taper=0.032)
    box((w - 0.04, d - 0.04, 0.012), (0, 0, lh + 0.006), "cream", 0.004, name="piping")


def coat_stand(w, d, h):
    cyl(0.022, h - 0.05, (0, 0, (h - 0.05) / 2 + 0.03), WAY, "Z", 12, name="pole", bevel=0.004)
    sphere(0.035, (0, 0, h - 0.035), WAY, name="finial")
    cyl(0.04, 0.05, (0, 0, 0.12), WAY, "Z", 12, name="collar", bevel=0.006)
    for i in range(4):
        a = i * math.pi / 2
        ca, sa = math.cos(a), math.sin(a)
        r_end = w / 2 - 0.022
        splay_leg((ca * 0.03, sa * 0.03, 0.17), (ca * (r_end - 0.01), sa * (r_end - 0.01), 0.02), 0.032, WAY, name="foot")
        sphere(0.022, (ca * r_end, sa * r_end, 0.016), "dark", scale=(1, 1, 0.7), name="foot_pad")
    # 4 curved hooks up top, and one at mid height
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        zc = h - 0.14
        pts = [(0.0, zc - 0.05), (0.06, zc - 0.02), (0.11, zc + 0.02), (0.13, zc + 0.07), (0.125, zc + 0.095)]
        o = arc_bar(pts, 0.018, 0.018, WAY, name="hook", plane="XZ")
        o.rotation_euler = (0, 0, a)
        sphere(0.014, (math.cos(a) * 0.125, math.sin(a) * 0.125, zc + 0.1), WAY, name="hook_tip")
    # a scarf and a hat hanging so it reads as a coat stand
    a = math.pi / 4
    hx, hy = math.cos(a) * 0.11, math.sin(a) * 0.11
    cyl(0.1, 0.012, (hx, hy, h - 0.07), "night", "Z", 18, name="hat_brim", rot=(0.0, 0.0, 0))
    cyl(0.065, 0.08, (hx, hy, h - 0.03), "night", "Z", 18, r2=0.058, name="hat_crown", bevel=0.01)
    cyl(0.066, 0.016, (hx, hy, h - 0.055), "mustard", "Z", 18, name="hat_band")
    a2 = math.pi * 5 / 4
    sx, sy = math.cos(a2) * 0.1, math.sin(a2) * 0.1
    box((0.07, 0.025, 0.55), (sx, sy, h - 0.42), "red", 0.008, rot=(0, 0, a2), name="scarf")
    box((0.07, 0.025, 0.45), (sx * 0.6, sy * 0.6, h - 0.37), "red", 0.008, rot=(0, 0, a2), name="scarf")
    for k in range(3):
        box((0.074, 0.028, 0.03), (sx, sy, h - 0.5 - k * 0.1), "cream", 0.004, rot=(0, 0, a2), name="scarf_stripe")
    # long coat on another hook: shoulders, tapered body, collar
    a3 = math.pi * 3 / 4
    ca, sa = math.cos(a3), math.sin(a3)
    for o in (
        box((0.2, 0.07, 0.08), (ca * 0.14, sa * 0.14, h - 0.2), "sage", 0.03, name="coat"),
        cyl(0.1, 0.72, (ca * 0.15, sa * 0.15, h - 0.56), "sage", "Z", 14, r2=0.07, name="coat", bevel=0.01),
        box((0.1, 0.05, 0.05), (ca * 0.12, sa * 0.12, h - 0.15), "sage", 0.015, name="coat_collar"),
    ):
        o.rotation_euler = (0, 0, a3 + math.pi / 2)
    for k in range(3):
        sphere(0.009, (ca * 0.15 + ca * 0.075, sa * 0.15 + sa * 0.075, h - 0.3 - k * 0.12), "cream", name="coat_button")


def rocking_chair(w, d, h):
    seat_z = 0.42
    sw, sd = w - 0.07, d * 0.56
    rock_x = sw / 2 - 0.02
    # rockers: shallow arc along Y, length d
    R = 1.2
    pts = []
    n = 10
    half = d / 2 - 0.01
    for i in range(n + 1):
        y = -half + i * 2 * half / n
        z = R - math.sqrt(R * R - y * y) + 0.02
        pts.append((y, z))
    rise = pts[0][1]
    for s in (-1, 1):
        arc_bar(pts, 0.04, 0.04, WAY, name="rocker", plane="YZ", offset=s * rock_x)
    # legs from rockers to seat
    for s in (-1, 1):
        for yy in (-sd / 2 + 0.05, sd / 2 - 0.05):
            zb = R - math.sqrt(R * R - yy * yy) + 0.02 + 0.015
            box((0.035, 0.035, seat_z - zb), (s * rock_x, yy, zb + (seat_z - zb) / 2), WAY, 0.005, name="leg")
        box((0.025, sd - 0.1, 0.025), (s * rock_x, 0, seat_z * 0.45), WAY, 0.004, name="stretcher")
    box((sw, sd, 0.035), (0, 0, seat_z), WAY, 0.01, name="seat")
    box((sw - 0.06, sd - 0.06, 0.05), (0, -0.01, seat_z + 0.04), "cream", 0.02, name="cushion")
    # back: tilted posts with spindles and a curved top rail
    tilt = 0.18
    by = sd / 2 - 0.03
    bh = h - seat_z - 0.02
    top_y = by + math.sin(tilt) * bh
    top_y = min(top_y, half - 0.0)
    for s in (-1, 1):
        splay_leg((s * (sw / 2 - 0.03), top_y, h - 0.04), (s * (sw / 2 - 0.03), by, seat_z), 0.035, WAY, name="back_post")
    for i in range(5):
        x = -sw / 2 + 0.08 + i * (sw - 0.16) / 4
        splay_leg((x, top_y - 0.005, h - 0.06), (x, by, seat_z + 0.02), 0.018, WAY, name="spindle", round_=False)
    box((sw + 0.02, 0.035, 0.08), (0, top_y, h - 0.04), WAY, 0.012, rot=(-tilt, 0, 0), name="top_rail")
    # arms
    for s in (-1, 1):
        x = s * (sw / 2 + 0.0)
        box((0.06, sd * 0.95, 0.03), (x, 0.0, seat_z + 0.24), WAY, 0.008, name="arm")
        box((0.03, 0.03, 0.24), (x, -sd / 2 + 0.06, seat_z + 0.12), WAY, 0.005, name="arm_post")


BUILDERS = {k: v for k, v in dict(globals()).items() if callable(v) and k in (
    "bin_kitchen", "bath_mat", "wine_rack", "suitcase", "toy_box", "ottoman", "bar_stool", "shoe_rack",
    "bookshelf_v", "plant_pot_v", "floor_lamp_v", "kitchen_trolley", "high_chair", "laundry_hamper",
    "bath_bin", "side_table_v", "dressing_stool", "armchair_v", "coat_stand", "rocking_chair")}


def fit_and_centre(w, d, h, snap=0.06):
    """Bake modifiers and transforms, put the origin at the bottom centre of the
    bbox, and if the raw size is within `snap` of the CSV size, scale it to the
    exact CSV size. Returns (raw_size, final_size)."""
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="SELECT")
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.convert(target="MESH")  # applies the bevel modifiers
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    pts = [v.co for o in meshes for v in o.data.vertices]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    raw = mx - mn
    want = Vector((w, d, h))
    k = Vector([want[i] / raw[i] if abs(want[i] / raw[i] - 1) <= snap else 1.0 for i in range(3)])
    c = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    for o in meshes:
        for v in o.data.vertices:
            p = v.co - c
            v.co = Vector((p.x * k.x, p.y * k.y, p.z * k.z))
        o.data.update()
    return raw, Vector((raw.x * k.x, raw.y * k.y, raw.z * k.z))


def read_csv():
    rows = {}
    with open(CSV) as f:
        for r in csv.DictReader(f):
            rows[r["family_id"]] = r
    return rows


def build(fid, row):
    global _WAY_HEX
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    first = row["colourways"].split(";")[0].strip()
    _WAY_HEX = PAL[WAY_ALIAS.get(first, first)]
    w, d, h = float(row["typical_w"]), float(row["typical_d"]), float(row["typical_h"])
    BUILDERS[fid](w, d, h)
    raw, size = fit_and_centre(w, d, h)
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(OUT, "hh_cat_%s.glb" % fid)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=False, export_yup=True,
                              export_texcoords=False, export_normals=True, export_extras=False,
                              export_cameras=False, export_lights=False, export_animations=False)
    print("BUILT %s way=%s(%s) raw=%.3f x %.3f x %.3f size=%.3f x %.3f x %.3f (csv %.3f x %.3f x %.3f) -> %s" % (
        fid, first, _WAY_HEX, raw.x, raw.y, raw.z, size.x, size.y, size.z, w, d, h, path))


def main(argv):
    rows = read_csv()
    wanted = [a for a in argv if a in MINE] or list(MINE)
    for fid in wanted:
        build(fid, rows[fid])


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    main(argv)
