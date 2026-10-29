"""Build Corner Office catalogue-family GLBs (batch 4), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 4 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch4
MINE = ["board_games", "child_bike", "barbecue", "deck_chair", "teapot", "chopping_board", "biscuit_tin", "book_stack", "broken_chair", "hat_stand_loft"]
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
WAY_ALIAS = {"painted white": "white", "painted sage": "sage", "tan": "kraft", "wicker": "kraft", "off": "dark", "brown": "walnut"}
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

def lathe(profile, color, name="part", segs=18, smooth=True, at=(0, 0, 0), bevel=0.0):
    """Revolve a list of (r, z) points around Z. r == 0 points close the ends."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        if r <= 1e-6:
            rings.append([bm.verts.new((at[0], at[1], at[2] + z))])
        else:
            rings.append([bm.verts.new((at[0] + r * math.cos(2 * math.pi * i / segs),
                                        at[1] + r * math.sin(2 * math.pi * i / segs), at[2] + z)) for i in range(segs)])
    for A, B in zip(rings, rings[1:]):
        if len(A) == 1 and len(B) == 1:
            continue
        for i in range(segs):
            j = (i + 1) % segs
            if len(A) == 1:
                bm.faces.new((A[0], B[i], B[j]))
            elif len(B) == 1:
                bm.faces.new((A[i], B[0], A[j]))
            else:
                bm.faces.new((A[i], B[i], B[j], A[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o = _finish(o, color, bevel, name)
    for p in o.data.polygons:
        p.use_smooth = smooth
    return o


def extrude_xz(pts, depth, y, color, name="part", bevel=0.0):
    """Extrude a closed (x, z) outline along Y, centred on y."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    F = [bm.verts.new((x, y - depth / 2, z)) for x, z in pts]
    B = [bm.verts.new((x, y + depth / 2, z)) for x, z in pts]
    n = len(pts)
    bm.faces.new(F)
    bm.faces.new(list(reversed(B)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((F[i], F[j], B[j], B[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return _finish(o, color, bevel, name)


def rod(p0, p1, r, color, name="part", verts=10, bevel=0.0):
    """Cylinder from point p0 to point p1."""
    p0, p1 = Vector(p0), Vector(p1)
    v = p1 - p0
    o = cyl(r, v.length, (p0 + p1) / 2, color, "Z", verts, name=name, bevel=bevel)
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(v.normalized())
    return o


def board_games(w, d, h):
    # stack of four board-game boxes (lid colour + cream base), a die and counters on top
    games = [((w, d, 0.055), WAY, 0.0), ((0.36, 0.255, 0.045), "mustard", 0.05),
             ((0.33, 0.235, 0.042), "sage", -0.06), ((0.28, 0.2, 0.038), "red", 0.03)]
    z = 0.0
    for (gw, gd, gh), col, rz in games:
        lh = gh * 0.62
        box((gw - 0.006, gd - 0.006, gh - lh + 0.004), (0, 0, z + (gh - lh + 0.004) / 2), "cream", 0.003, rot=(0, 0, rz), name="game_base")
        box((gw, gd, lh), (0, 0, z + gh - lh / 2), col, 0.004, rot=(0, 0, rz), name="game_lid")
        c, s = math.cos(rz), math.sin(rz)
        # lid art: a cream band and a dot on the front face of the lid
        bx, by = 0.0, -gd / 2 - 0.0015
        box((gw * 0.55, 0.003, lh * 0.35), (bx * c - by * s, bx * s + by * c, z + gh - lh / 2), "cream", 0.0, rot=(0, 0, rz), name="lid_label")
        z += gh
    top = z
    zt = top + 0.0
    sphere(0.045, (-0.06, 0.01, zt + 0.001), "cream", scale=(1, 1, 0.04), name="lid_art")
    cs = h - top - 0.001
    box((cs, cs, cs), (0.05, -0.02, top + cs / 2), "cream", 0.004, rot=(0, 0, 0.4), name="die")
    for k, (px, py) in enumerate(((0.05 - 0.0, -0.02), (0.05 - 0.006, -0.02 - 0.006), (0.05 + 0.006, -0.02 + 0.006))):
        cyl(0.0025, 0.002, (px, py, top + cs + 0.0005), "dark", "Z", 8, name="pip")
    for i, (x, y, col) in enumerate(((-0.08, -0.07, "mustard"), (-0.04, -0.08, "red"), (0.1, 0.05, WAY))):
        cyl(0.011, 0.006, (x, y, top + 0.003), col, "Z", 12, bevel=0.002, name="counter")
    cyl(0.007, 0.016, (-0.11, 0.04, top + 0.008), "red", "Z", 10, r2=0.004, name="pawn")
    sphere(0.006, (-0.11, 0.04, top + 0.019), "red", name="pawn_head")


def child_bike(w, d, h):
    # child's bike in side view along X (front wheel at +X); 'way' frame and chain guard
    wr = 0.165
    wx = w / 2 - wr
    tr = 0.024
    for x in (-wx, wx):
        torus(wr - tr, tr, (x, 0, wr), "dark", rot=(math.pi / 2, 0, 0), name="tyre", seg=24)
        torus(wr - tr * 2 - 0.004, 0.006, (x, 0, wr), "steel", rot=(math.pi / 2, 0, 0), name="rim", seg=24)
        cyl(0.022, 0.05, (x, 0, wr), "steel", "Y", 12, name="hub")
        for k in range(6):
            a = k * math.pi / 6
            rod((x - math.cos(a) * (wr - 0.05), 0, wr - math.sin(a) * (wr - 0.05)),
                (x + math.cos(a) * (wr - 0.05), 0, wr + math.sin(a) * (wr - 0.05)), 0.0025, "steel", name="spoke", verts=6)
    R = Vector((-wx, 0, wr)); F = Vector((wx, 0, wr))
    B = Vector((-0.04, 0, 0.17)); S = Vector((-0.12, 0, 0.42))
    Ht, Hb = Vector((0.2, 0, 0.45)), Vector((0.23, 0, 0.34))
    for a, b in ((B, Hb), (S, Ht), (R, B), (R, S), (B, S), (Hb, Ht)):
        rod(a, b, 0.016, WAY, name="frame", bevel=0.0)
    for s in (-1, 1):
        rod(Hb + Vector((0, s * 0.03, 0)), F + Vector((0, s * 0.03, 0)), 0.011, "steel", name="fork")
    rod(Ht, Vector((0.19, 0, 0.56)), 0.012, "steel", name="stem")
    cyl(0.011, d - 0.08, (0.19, 0, 0.56), "steel", "Y", 10, name="handlebar")
    for s in (-1, 1):
        cyl(0.019, 0.045, (0.19, s * (d / 2 - 0.0225), 0.56), "dark", "Y", 12, bevel=0.005, name="grip")
    rod(S, S + Vector((-0.012, 0, 0.06)), 0.011, "steel", name="seat_post")
    sphere(0.06, (-0.135, 0, 0.495), "dark", scale=(1.25, 0.65, 0.3), name="saddle")
    cyl(0.055, 0.008, (B.x, -0.035, B.z), "steel", "Y", 18, name="chainring")
    box((0.2, 0.012, 0.05), (B.x - 0.1, -0.045, B.z + 0.01), WAY, 0.006, name="chain_guard", rot=(0, 0.03, 0))
    for s in (-1, 1):
        a = Vector((B.x + s * 0.06, s * 0.05, B.z - s * 0.06))
        rod(Vector((B.x, s * 0.045, B.z)), a, 0.007, "steel", name="crank")
        box((0.05, 0.04, 0.014), (a.x, s * 0.075, a.z), "dark", 0.004, name="pedal")
    cyl(0.018, 0.005, (-wx - 0.02, -0.0, wr + 0.13), "red", "X", 12, name="reflector")
    rod((-wx - 0.02, 0, wr + 0.13), (-0.08, 0, 0.36), 0.005, "steel", name="reflector_arm")
    cyl(0.02, 0.025, (0.19, -0.07, 0.585), "mustard", "Z", 12, bevel=0.004, name="bell")


def barbecue(w, d, h):
    # kettle barbecue: 'way' bowl and lid on three steel legs with wheels, oak lid handle
    R = 0.28
    zc = 0.6
    bowl = [(0, zc - 0.21)] + [(R * math.sin(math.pi / 2 * t / 6), zc - 0.21 * math.cos(math.pi / 2 * t / 6)) for t in range(1, 7)]
    lathe(bowl, WAY, name="bowl", segs=24)
    lid = [(R + 0.004, zc + 0.004)] + [(R * 1.004 * math.cos(math.pi / 2 * t / 6), zc + 0.004 + 0.21 * math.sin(math.pi / 2 * t / 6)) for t in range(1, 6)] + [(0, zc + 0.214)]
    lathe(lid, WAY, name="lid", segs=24)
    torus(R + 0.002, 0.007, (0, 0, zc + 0.002), "steel", name="lid_rim", seg=24)
    lt = zc + 0.214
    for x in (-0.07, 0.07):
        box((0.014, 0.03, 0.05), (x, 0, lt + 0.02), "steel", 0.003, name="handle_bracket")
    cyl(0.017, 0.2, (0, 0, h - 0.017), "oak", "X", 12, bevel=0.004, name="lid_handle")
    cyl(0.04, 0.008, (0.08, -0.16, lt - 0.045), "steel", "Z", 12, rot=(0.6, 0, 0), name="vent")
    legs = []
    for k in range(3):
        a = math.radians(-90 + 120 * k)
        top = (math.cos(a) * 0.17, math.sin(a) * 0.17, zc - 0.15)
        bot = (math.cos(a) * (w / 2 - 0.006), math.sin(a) * (w / 2 - 0.006), 0.04 if k else 0.015)
        rod(top, bot, 0.014, "steel", name="leg")
        legs.append(bot)
    for k in (1, 2):
        x, y, z = legs[k]
        cyl(0.04, 0.025, (x, y, 0.04), "dark", "X", 14, bevel=0.006, name="wheel")
    cyl(0.12, 0.02, (0, 0, 0.2), "steel", "Z", 18, r2=0.14, name="ash_pan")
    for k in range(3):
        a = math.radians(-90 + 120 * k)
        rod((math.cos(a) * 0.12, math.sin(a) * 0.12, 0.2), (math.cos(a) * 0.205, math.sin(a) * 0.205, 0.2), 0.006, "steel", name="pan_strut")
    box((0.02, 0.012, 0.05), (R + 0.006, 0, zc - 0.06), "steel", 0.003, name="side_hook")


def deck_chair(w, d, h):
    # folding deck chair, front to -Y: oak frame, striped canvas sling ('way' + cream)
    fx = w / 2 - 0.015
    t = 0.032
    Bf, Bt = (-0.12, 0.0), (d / 2 - 0.016, h - 0.016)   # back rails (y, z): front foot -> high back top
    Lf, Lt = (-d / 2 + 0.016, 0.0), (0.0, 0.46)        # front legs
    Sf, St = (d / 2 - 0.016, 0.0), (0.1, 0.4)          # rear struts
    for x in (-fx, fx):
        xi = x - math.copysign(t, x)
        rod((x, Bf[0], Bf[1] + t / 2), (x, Bt[0], Bt[1]), t / 2, "oak", name="back_rail", verts=8)
        rod((xi, Lf[0], Lf[1] + t / 2), (xi, Lt[0], Lt[1]), t / 2, "oak", name="front_leg", verts=8)
        rod((xi - math.copysign(t, x), Sf[0], Sf[1] + t / 2), (xi - math.copysign(t, x), St[0], St[1]), t / 2, "oak", name="rear_strut", verts=8)
        cyl(0.01, 0.012, (x + math.copysign(0.004, x), -0.035, 0.18), "brass", "X", 10, name="bolt")
    for (y, z), ww in ((Bt, 2 * fx), (Lt, 2 * fx - 2 * t), (St, 2 * fx - 4 * t), ((-0.06, 0.1), 2 * fx)):
        cyl(t / 2, ww, (0, y, z), "oak", "X", 10, name="cross_bar")
    # sling: sags from the top bar to the front-leg bar
    p0, p1 = (Bt[0] - 0.01, Bt[1] - 0.01), (Lt[0] + 0.0, Lt[1] + 0.012)
    pts = []
    for i in range(13):
        u = i / 12
        y = p0[0] + (p1[0] - p0[0]) * u
        z = p0[1] + (p1[1] - p0[1]) * u - 0.16 * math.sin(math.pi * u) ** 1.3
        pts.append((y, z))
    n = 7
    sw = (2 * fx - 2 * t - 0.01) / n
    for i in range(n):
        x = -(2 * fx - 2 * t - 0.01) / 2 + sw * (i + 0.5)
        arc_bar(pts, 0.008, sw + 0.0005, WAY if i % 2 == 0 else "cream", name="sling", plane="YZ", offset=x, bevel=0.0)


def teapot(w, d, h):
    # round teapot: 'way' body, lid and spout, cream knob and band, handle at +X
    R = d / 2 - 0.004
    bx = 0.012
    prof = [(0, 0.0), (0.05, 0.0), (0.06, 0.008), (0.074, 0.03), (R, 0.06), (0.072, 0.095), (0.06, 0.12), (0.045, 0.13), (0, 0.13)]
    lathe(prof, WAY, name="body", segs=24, at=(bx, 0, 0))
    lathe([(0, 0.128), (0.05, 0.128), (0.048, 0.138), (0.03, 0.152), (0.012, 0.156), (0, 0.156)], WAY, name="lid", segs=24, at=(bx, 0, 0))
    sphere(0.014, (bx, 0, 0.165), "cream", scale=(1, 1, 0.9), name="knob")
    torus(R - 0.001, 0.004, (bx, 0, 0.06), "cream", name="band", seg=24)
    # spout to -X: a tapering chain of short cones
    pts = [(-0.06, 0.04), (-0.085, 0.06), (-0.1, 0.085), (-0.112, 0.11)]
    rr = [0.02, 0.016, 0.013, 0.011]
    for (x0, z0), (x1, z1), r0, r1 in zip(pts, pts[1:], rr, rr[1:]):
        v = Vector((x1 - x0, 0, z1 - z0))
        o = cyl(r0, v.length, ((x0 + x1) / 2 + bx, 0, (z0 + z1) / 2), WAY, "Z", 12, r2=r1, name="spout")
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(v.normalized())
    hp = [(0.07 + bx, 0.105), (0.095 + bx, 0.105), (0.112 + bx, 0.085), (0.112 + bx, 0.05), (0.095 + bx, 0.03), (0.072 + bx, 0.028)]
    arc_bar(hp, 0.014, 0.016, WAY, name="handle", plane="XZ", offset=0.0, bevel=0.004)
    sphere(0.01, (bx - 0.035, -0.06, 0.08), "mustard", scale=(1, 0.3, 1), name="flower")
    sphere(0.01, (bx + 0.0, -0.068, 0.085), "mustard", scale=(1, 0.3, 1), name="flower")


def chopping_board(w, d, h):
    # chopping board with handle hole at +X, on little feet; carrot coins and a knife on it
    bt = h - 0.012
    z0 = 0.004
    bw = w - 0.07
    box((bw, d, bt), (-0.035, 0, z0 + bt / 2), WAY, 0.006, name="board")
    box((0.08, 0.1, bt), (w / 2 - 0.045, 0, z0 + bt / 2), WAY, 0.006, name="board_handle")
    hole = cyl(0.016, bt * 3, (w / 2 - 0.035, 0, z0 + bt / 2), "dark", "Z", 16, name="cutter")
    tgt = [o for o in bpy.context.scene.objects if o.name.startswith("board_handle")][0]
    m = tgt.modifiers.new("hole", "BOOLEAN")
    m.object = hole
    m.operation = "DIFFERENCE"
    bpy.context.view_layer.objects.active = tgt
    bpy.ops.object.select_all(action="DESELECT")
    tgt.select_set(True)
    for mm in list(tgt.modifiers):
        bpy.ops.object.modifier_apply(modifier=mm.name)
    bpy.data.objects.remove(hole)
    for x in (-bw / 2 + 0.02 - 0.035, w / 2 - 0.08):
        for y in (-d / 2 + 0.03, d / 2 - 0.03):
            cyl(0.012, z0, (x, y, z0 / 2), "dark", "Z", 10, name="foot")
    zt = z0 + bt
    for i, (x, y) in enumerate(((-0.1, -0.05), (-0.07, -0.03), (-0.115, -0.015), (-0.08, 0.005), (-0.045, -0.06))):
        cyl(0.014, 0.006, (x, y, zt + 0.003 + 0.0005 * i), "terracotta", "Z", 14, bevel=0.002, name="carrot_coin")
    for i, (x, y) in enumerate(((0.0, 0.06), (0.03, 0.07), (0.015, 0.04))):
        cyl(0.017, 0.005, (x, y, zt + 0.0025), "green", "Z", 14, bevel=0.0015, name="cucumber_slice")
    box((0.15, 0.03, 0.002), (0.02, -0.07, zt + 0.001), "steel", 0.0, rot=(0, 0, 0.15), name="knife_blade")
    box((0.08, 0.018, 0.008), (0.135, -0.053, zt + 0.004), "walnut", 0.003, rot=(0, 0, 0.15), name="knife_handle")


def biscuit_tin(w, d, h):
    # round biscuit tin: 'way' drum and lid, cream lid band and rim lines, mustard rosette on the lid
    R = w / 2
    lh = 0.032
    cyl(R - 0.004, h - lh + 0.004, (0, 0, (h - lh + 0.004) / 2), WAY, "Z", 32, bevel=0.005, name="tin_body")
    for z in (0.012, h - lh - 0.012):
        cyl(R - 0.0035, 0.006, (0, 0, z), "cream", "Z", 32, name="tin_band")
    for i in range(10):
        a = 2 * math.pi * i / 10
        sphere(0.007, ((R - 0.0095) * math.cos(a), (R - 0.0095) * math.sin(a), (h - lh) / 2), "cream", scale=(1, 1, 1), name="tin_dot")
    cyl(R, lh, (0, 0, h - lh / 2), WAY, "Z", 32, bevel=0.006, name="lid")
    cyl(R + 0.0006, 0.012, (0, 0, h - lh / 2), "cream", "Z", 32, name="lid_band")
    cyl(0.06, 0.003, (0, 0, h), "mustard", "Z", 24, name="lid_art")
    cyl(0.035, 0.003, (0, 0, h + 0.0005), "red", "Z", 18, name="lid_art")
    for i in range(8):
        a = 2 * math.pi * i / 8
        cyl(0.012, 0.003, (0.075 * math.cos(a), 0.075 * math.sin(a), h - 0.0005), "cream", "Z", 12, name="lid_art")


def book_stack(w, d, h):
    # five books lying flat, spines toward the front (-Y); boards, spine, cream page block
    books = [(0.2, 0.145, 0.045, WAY, 0.0), (0.185, 0.135, 0.034, "red", 0.06), (0.195, 0.14, 0.05, "green", -0.04),
             (0.17, 0.125, 0.03, "mustard", 0.09), (0.18, 0.13, 0.041, "night", -0.02)]
    z = 0.0
    for bw, bd, bh, col, rz in books:
        c, s = math.cos(rz), math.sin(rz)
        def P(x, y, zz):
            return (x * c - y * s, x * s + y * c, zz)
        bt = 0.004
        box((bw, bd, bt), P(0, 0, z + bt / 2), col, 0.0015, rot=(0, 0, rz), name="cover")
        box((bw, bd, bt), P(0, 0, z + bh - bt / 2), col, 0.0015, rot=(0, 0, rz), name="cover")
        box((bw, 0.008, bh), P(0, -bd / 2 + 0.004, z + bh / 2), col, 0.003, rot=(0, 0, rz), name="spine")
        box((bw - 0.008, bd - 0.008, bh - 2 * bt + 0.001), P(0, 0.0, z + bh / 2), "cream", 0.0, rot=(0, 0, rz), name="pages")
        for xo in (-bw / 2 + 0.025, bw / 2 - 0.025):
            box((0.006, 0.002, bh * 0.7), P(xo, -bd / 2 - 0.0005, z + bh / 2), "brass", 0.0, rot=(0, 0, rz), name="spine_band")
        box((bw * 0.4, 0.002, bh * 0.35), P(0, -bd / 2 - 0.0005, z + bh / 2), "cream" if col != WAY else "brass", 0.0, rot=(0, 0, rz), name="spine_title")
        z += bh
    box((0.012, 0.004, 0.06), (0.04, -0.0, z - 0.004 - 0.03 + 0.03), "red", 0.0, name="bookmark") if False else None


def broken_chair(w, d, h):
    # old kitchen chair with a snapped front-left leg and a loose back slat; 'way' wood
    sh = 0.45
    st = 0.035
    lt = 0.038
    x0, y0 = w / 2 - lt / 2 - 0.01, d / 2 - lt / 2 - 0.01
    box((w - 0.01, d - 0.01, st), (0, 0, sh - st / 2), WAY, 0.008, name="seat")
    for x in (-x0, x0):
        box((lt, lt, h), (x, y0, h / 2), WAY, 0.006, name="back_post")
        box((lt, lt, sh - st), (x, -y0, (sh - st) / 2) if x > 0 else (x, -y0, sh - st - 0.11), WAY, 0.006, name="leg") if x > 0 else None
    # broken leg: a short stub under the seat with a jagged pine break
    stub = 0.12
    box((lt, lt, stub), (-x0, -y0, sh - st - stub / 2), WAY, 0.006, name="leg")
    for k, (dx, dy, hh) in enumerate(((-0.01, -0.01, 0.03), (0.01, 0.0, 0.02), (0.0, 0.012, 0.035))):
        cyl(0.011, hh, (-x0 + dx, -y0 + dy, sh - st - stub - hh / 2 + 0.002), "pine", "Z", 6, r2=0.002, rot=(math.pi, 0, 0), name="splinter")
    # the snapped-off piece lies on the floor in front
    L = sh - st - stub - 0.03
    box((L, lt, lt), (-w / 2 + L / 2 + 0.02, -d / 2 + lt / 2 + 0.005, lt / 2), WAY, 0.006, rot=(0, 0, 0.0), name="broken_leg")
    cyl(0.011, 0.025, (-w / 2 + L + 0.02 + 0.012, -d / 2 + lt / 2 + 0.005, lt / 2), "pine", "X", 6, r2=0.002, name="splinter")
    for x in (-x0, x0):
        box((lt * 0.7, d - 0.08, 0.025), (x, 0, 0.14), WAY, 0.004, name="stretcher") if x > 0 else None
    box((2 * x0, lt * 0.7, 0.025), (0, y0, 0.14), WAY, 0.004, name="stretcher")
    # back: top rail, one good slat, one slat hanging askew from a single nail
    box((w - 0.01, 0.03, 0.07), (0, y0, h - 0.035), WAY, 0.006, name="back_rail")
    box((0.05, 0.02, 0.33), (0.07, y0, sh + 0.06 + 0.165), WAY, 0.004, name="back_slat")
    box((0.05, 0.02, 0.3), (-0.07, y0 - 0.01, sh + 0.21 - 0.02), WAY, 0.004, rot=(0, -0.35, 0), name="back_slat")
    for z in (h - 0.05,):
        cyl(0.004, 0.03, (-0.035, y0 - 0.025, z - 0.04), "steel", "Y", 6, name="nail")
    cyl(0.003, 0.025, (-0.1, y0 - 0.02, h - 0.075), "steel", "Y", 6, name="nail")
    box((0.12, 0.004, 0.006), (0.06, -d / 2 + 0.003 + 0.0, sh - 0.012), "dark", 0.0, rot=(0, 0.2, 0), name="crack")


def hat_stand_loft(w, d, h):
    # old hat stand: 'way' pole on four curved feet, brass hooks, a felt hat on top, a scarf on a hook
    pr = 0.022
    ph = h - 0.09
    cyl(pr, ph - 0.05, (0, 0, 0.05 + (ph - 0.05) / 2), WAY, "Z", 14, bevel=0.004, name="pole")
    cyl(0.04, 0.06, (0, 0, 0.08), WAY, "Z", 14, bevel=0.008, name="pole_collar")
    for k in range(4):
        a = math.radians(45 + 90 * k)
        c, s = math.cos(a), math.sin(a)
        prof = [(0.03, 0.12), (0.09, 0.07), (0.15, 0.03), (w / 2 * 1.41 * 0.7 - 0.012, 0.012)]
        rr = min(w / 2 - 0.012, d / 2 - 0.012) / max(abs(c), abs(s))
        prof[-1] = (min(rr, 0.27), 0.012)
        for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
            rod((c * r0, s * r0, z0), (c * r1, s * r1, z1), 0.014, WAY, name="foot")
        cyl(0.015, 0.012, (c * prof[-1][0], s * prof[-1][0], 0.006), "dark", "Z", 10, name="foot_pad")
    zh = ph - 0.12
    for k in range(4):
        a = math.radians(90 * k)
        c, s = math.cos(a), math.sin(a)
        rod((c * pr, s * pr, zh), (c * 0.11, s * 0.11, zh + 0.05), 0.007, "brass", name="hook")
        sphere(0.012, (c * 0.115, s * 0.115, zh + 0.055), "brass", name="hook_tip")
    cyl(0.03, 0.03, (0, 0, ph + 0.0), WAY, "Z", 14, bevel=0.006, name="finial_base")
    # felt hat sitting on the top
    cyl(0.13, 0.008, (0, 0, ph + 0.019), "grey", "Z", 24, bevel=0.003, name="hat_brim")
    cyl(0.075, h - ph - 0.023, (0, 0, ph + 0.023 + (h - ph - 0.023) / 2), "grey", "Z", 20, r2=0.068, bevel=0.012, name="hat_crown")
    cyl(0.0765, 0.018, (0, 0, ph + 0.032), "dark", "Z", 20, name="hat_band")
    # scarf hanging from the front-left hook
    a = math.radians(270)
    hx, hy = 0.0, -0.11
    pts = [(-0.11 + 0.0, zh + 0.05), (-0.13, zh - 0.06), (-0.125, zh - 0.35), (-0.115, zh - 0.55)]
    arc_bar([(u, v) for u, v in pts], 0.012, 0.07, "red", name="scarf", plane="YZ", offset=-0.03)
    pts2 = [(-0.11, zh + 0.05), (-0.09, zh - 0.05), (-0.095, zh - 0.3), (-0.1, zh - 0.45)]
    arc_bar(pts2, 0.012, 0.065, "red", name="scarf", plane="YZ", offset=0.035)
    for off, zz in ((-0.03, zh - 0.55), (0.035, zh - 0.45)):
        for dz in (0.03, 0.06):
            box((0.072, 0.014, 0.008), (off, -0.12 + (0.005 if off < 0 else 0.02), zz + dz), "cream", 0.0, name="scarf_stripe")


BUILDERS = {k: globals()[k] for k in MINE}


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
    FIT[fid] = {"raw": [round(raw.x, 4), round(raw.y, 4), round(raw.z, 4)], "final": [round(size.x, 4), round(size.y, 4), round(size.z, 4)],
                "stretch_pct": [round((size[i] / raw[i] - 1) * 100, 2) for i in range(3)]}
    print("BUILT %s way=%s(%s) raw=%.3f x %.3f x %.3f size=%.3f x %.3f x %.3f (csv %.3f x %.3f x %.3f) -> %s" % (
        fid, first, _WAY_HEX, raw.x, raw.y, raw.z, size.x, size.y, size.z, w, d, h, path))


FIT = {}


def main(argv):
    import json
    rows = read_csv()
    wanted = [a for a in argv if a in MINE] or list(MINE)
    for fid in wanted:
        build(fid, rows[fid])
    fp = os.path.join(HERE, "fit_log.json")
    old = json.load(open(fp)) if os.path.exists(fp) else {}
    old.update(FIT)
    json.dump(old, open(fp, "w"), indent=1)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    main(argv)
