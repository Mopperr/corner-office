"""Build Corner Office catalogue-family GLBs (batch 6), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 6 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch6
MINE = ["laundry_bag", "record_player", "magazine_pile", "locker", "parasol", "office_chair", "spice_jars", "coffee_grinder", "scales", "soap_dispenser"]
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


def _orient(o, direction):
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(Vector(direction).normalized())
    return o


def laundry_bag(w, d, h):
    # full drawstring laundry bag: soft 'way' lathed sack, cream cord and label, clothes peeking out
    R = w / 2 - 0.004
    prof = [(0, 0.0), (R * 0.82, 0.0), (R * 0.97, 0.04), (R, 0.15), (R * 0.97, 0.3), (R * 0.85, 0.37), (R * 0.6, 0.41), (R * 0.42, 0.43), (R * 0.45, 0.45), (R * 0.5, 0.46), (0, 0.46)]
    lathe(prof, WAY, name="laundry_bag", segs=24)
    torus(R * 0.43, 0.008, (0, 0, 0.43), "cream", name="drawcord", seg=20)
    for s in (-1, 1):
        rod((s * 0.02, -R * 0.42, 0.43), (s * 0.035, -R * 0.55, 0.33), 0.006, "cream", name="cord_end", verts=6)
        sphere(0.012, (s * 0.035, -R * 0.56, 0.325), "kraft", name="toggle")
    box((0.09, 0.005, 0.06), (0, -R * 0.99, 0.2), "cream", 0.002, rot=(0.05, 0, 0), name="label")
    sphere(0.05, (-0.03, 0.01, 0.47), "mustard", scale=(1.4, 1.0, 0.6), name="shirt")
    rod((0.02, -0.02, 0.46), (0.07, -0.05, h - 0.012), 0.016, "red", name="sock", verts=10)
    sphere(0.018, (0.072, -0.052, h - 0.016), "red", scale=(1.3, 1, 0.7), name="sock_toe")
    sphere(0.04, (0.03, 0.05, 0.465), "white", scale=(1.2, 1, 0.5), name="tshirt")


def record_player(w, d, h):
    # record player: 'way' (oak) plinth on feet, steel platter, black record with red label, tonearm, front knobs
    ph = 0.085
    ft = 0.012
    box((w, d, ph), (0, 0, ft + ph / 2), WAY, 0.01, name="plinth")
    box((w - 0.02, d - 0.02, 0.004), (0, 0, ft + ph + 0.001), "dark", 0.0, name="deck_plate")
    for x in (-1, 1):
        for y in (-1, 1):
            cyl(0.02, ft, (x * (w / 2 - 0.04), y * (d / 2 - 0.04), ft / 2), "dark", "Z", 12, name="foot")
    zt = ft + ph + 0.003
    px = -0.05
    cyl(0.15, 0.014, (px, 0.01, zt + 0.007), "steel", "Z", 32, bevel=0.003, name="platter")
    cyl(0.148, 0.003, (px, 0.01, zt + 0.0155), "black", "Z", 32, name="record")
    for rr in (0.12, 0.09, 0.065):
        torus(rr, 0.0008, (px, 0.01, zt + 0.0172), "dark", name="groove", seg=32)
    cyl(0.045, 0.002, (px, 0.01, zt + 0.0175), "red", "Z", 20, name="record_label")
    cyl(0.004, 0.02, (px, 0.01, zt + 0.025), "steel", "Z", 8, name="spindle")
    tx, ty = w / 2 - 0.05, d / 2 - 0.06
    cyl(0.022, 0.03, (tx, ty, zt + 0.015), "steel", "Z", 14, bevel=0.004, name="tonearm_base")
    rod((tx, ty, zt + 0.032), (px + 0.11, 0.0 - 0.05, zt + 0.028), 0.004, "steel", name="tonearm")
    box((0.03, 0.015, 0.008), (px + 0.105, -0.055, zt + 0.024), "dark", 0.002, rot=(0, 0, 0.7), name="headshell")
    cyl(0.012, 0.03, (tx + 0.0, ty + 0.03, zt + 0.032), "dark", "Y", 12, name="counterweight")
    box((0.022, 0.01, 0.012), (tx + 0.002, ty - 0.08, zt + 0.006), "steel", 0.002, name="arm_rest")
    for x in (w / 2 - 0.12, w / 2 - 0.07):
        cyl(0.012, 0.01, (x, -d / 2 - 0.003, ft + ph / 2), "steel", "Y", 14, bevel=0.002, name="knob")
    box((0.03, 0.004, 0.01), (-w / 2 + 0.06, -d / 2 - 0.001, ft + ph / 2), "cream", 0.0, name="speed_badge")


def magazine_pile(w, d, h):
    # untidy pile of magazines: cream page blocks between colour covers, top one 'way' with a cover design
    mags = [("night", 0.05), ("mustard", -0.07), (WAY, 0.11), ("rose", -0.03), ("sage", 0.08), ("red", -0.1), ("mustard", 0.02), (WAY, -0.05)]
    mw, md = 0.27, 0.205
    n = len(mags)
    mt = h / n
    z = 0.0
    for i, (col, rz) in enumerate(mags):
        c, s = math.cos(rz), math.sin(rz)
        ox, oy = 0.008 * ((i % 3) - 1), 0.006 * ((i % 2) * 2 - 1)
        def P(x, y, zz):
            return (x * c - y * s + ox, x * s + y * c + oy, zz)
        box((mw - 0.004, md - 0.004, mt - 0.002), P(0, 0, z + mt / 2), "cream", 0.0, rot=(0, 0, rz), name="pages")
        box((mw, md, 0.0012), P(0, 0, z + 0.0006), col, 0.0, rot=(0, 0, rz), name="cover")
        box((mw, md, 0.0012), P(0, 0, z + mt - 0.0006), col, 0.0, rot=(0, 0, rz), name="cover")
        box((mw, 0.004, mt), P(0, -md / 2 + 0.002, z + mt / 2), col, 0.0, rot=(0, 0, rz), name="spine")
        z += mt
    c, s = math.cos(-0.05), math.sin(-0.05)
    def Q(x, y):
        return (x * c - y * s + 0.008 * ((7 % 3) - 1), x * s + y * c + 0.006)
    box((0.2, 0.035, 0.001), (*Q(0, 0.065), h + 0.0004), "cream", 0.0, rot=(0, 0, -0.05), name="masthead")
    box((0.13, 0.1, 0.001), (*Q(-0.04, -0.025), h + 0.0004), "mustard", 0.0, rot=(0, 0, -0.05), name="cover_photo")
    sphere(0.03, (*Q(-0.04, -0.025), h + 0.0008), "sage", scale=(1, 1, 0.02), name="cover_photo")
    for k in range(3):
        box((0.06, 0.008, 0.001), (*Q(0.075, -0.0 - k * 0.022), h + 0.0004), "cream", 0.0, rot=(0, 0, -0.05), name="cover_lines")


def locker(w, d, h):
    # steel locker: 'way' carcass and door, dark louvres, steel handle and hinges, cream number plate, feet
    ft = 0.05
    box((w, d - 0.02, h - ft), (0, 0.01, ft + (h - ft) / 2), WAY, 0.006, name="carcass")
    for x in (-1, 1):
        for y in (-1, 1):
            box((0.03, 0.03, ft), (x * (w / 2 - 0.03), y * (d / 2 - 0.05), ft / 2), "dark", 0.004, name="foot")
    fy = -d / 2 + 0.012
    dw, dh = w - 0.03, h - ft - 0.04
    dz = ft + 0.02 + dh / 2
    box((dw, 0.012, dh), (0, fy, dz), WAY, 0.006, name="door")
    for zb in (dz + dh / 2 - 0.12, dz - dh / 2 + 0.08):
        for k in range(5):
            box((dw * 0.6, 0.004, 0.008), (0, fy - 0.007, zb + k * 0.018), "dark", 0.001, name="louvre")
    box((0.03, 0.016, 0.12), (dw / 2 - 0.045, fy - 0.01, dz + 0.05), "steel", 0.005, name="handle")
    cyl(0.009, 0.008, (dw / 2 - 0.045, fy - 0.016, dz + 0.15), "steel", "Y", 12, name="lock")
    box((0.07, 0.003, 0.04), (0, fy - 0.007, dz + dh / 2 - 0.2), "cream", 0.001, name="number_plate")
    box((0.016, 0.004, 0.012), (-0.008, fy - 0.009, dz + dh / 2 - 0.2), "dark", 0.0, name="number")
    box((0.016, 0.004, 0.012), (0.012, fy - 0.009, dz + dh / 2 - 0.2), "dark", 0.0, name="number")
    for z in (dz - dh / 2 + 0.15, dz + dh / 2 - 0.15):
        cyl(0.008, 0.06, (-dw / 2 - 0.001, fy, z), "steel", "Z", 8, name="hinge")
    box((w + 0.004, d - 0.016, 0.012), (0, 0.01, h - 0.006), "steel", 0.003, name="lid_trim")


def parasol(w, d, h):
    # furled garden parasol: 'way' canopy wrapped round the oak pole, cream tie, steel finial and crank, dark weighted base
    pr = 0.018
    cyl(w / 2, 0.06, (0, 0, 0.03), "dark", "Z", 28, bevel=0.012, r2=w / 2 - 0.02, name="parasol_base")
    cyl(0.05, 0.08, (0, 0, 0.1), "dark", "Z", 14, bevel=0.008, r2=0.035, name="base_socket")
    cyl(pr, h - 0.1, (0, 0, 0.05 + (h - 0.1) / 2), "oak", "Z", 12, name="pole")
    ct, cb = h - 0.12, 0.85
    prof = [(pr, cb - 0.04), (0.04, cb), (0.07, cb + 0.12), (0.085, cb + 0.32), (0.075, cb + 0.6), (0.05, ct - 0.15), (pr + 0.008, ct)]
    lathe(prof, WAY, name="canopy", segs=16)
    for k in range(8):
        a = 2 * math.pi * k / 8
        rod((math.cos(a) * 0.03, math.sin(a) * 0.03, cb + 0.01), (math.cos(a) * 0.072, math.sin(a) * 0.072, cb + 0.13), 0.005, "steel", name="rib_tip", verts=6)
    for k in range(7):
        a = 2 * math.pi * k / 7 + 0.3
        rr = 0.083
        rod((math.cos(a) * (rr - 0.006), math.sin(a) * (rr - 0.006), cb + 0.2), (math.cos(a) * rr, math.sin(a) * rr, cb + 0.5), 0.003, "cream", name="seam", verts=5) if False else None
    torus(0.087, 0.009, (0, 0, cb + 0.32), "cream", name="tie", seg=20)
    box((0.05, 0.012, 0.012), (0.09, -0.0, cb + 0.31), "cream", 0.004, name="tie_tab")
    cyl(0.03, 0.05, (0, 0, ct + 0.02), "steel", "Z", 12, bevel=0.006, name="hub")
    cyl(pr * 0.8, h - ct - 0.045, (0, 0, ct + 0.045 + (h - ct - 0.045) / 2 - 0.01), "oak", "Z", 10, name="pole_top")
    sphere(0.022, (0, 0, h - 0.022), "steel", scale=(1, 1, 1.0), name="finial")
    cyl(0.026, 0.06, (0, 0, 0.62), "steel", "Z", 12, bevel=0.005, name="crank_housing")
    rod((0.02, 0, 0.62), (0.08, 0, 0.6), 0.006, "steel", name="crank_arm")
    cyl(0.01, 0.03, (0.08, 0, 0.6), "dark", "Y", 10, name="crank_knob")


def office_chair(w, d, h):
    # swivel office chair facing -Y: 'way' seat and backrest, dark five-star base and casters, steel gas lift, dark arms
    R = (w / 2 - 0.028) / math.cos(math.radians(18))
    cyl(0.04, 0.04, (0, 0, 0.09), "dark", "Z", 14, bevel=0.008, name="star_hub")
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        c, s = math.cos(a), math.sin(a)
        rod((c * 0.03, s * 0.03, 0.09), (c * R, s * R, 0.07), 0.018, "dark", name="star_leg", verts=8)
        sphere(0.028, (c * R, s * R, 0.03), "dark", scale=(1, 0.7, 1), name="caster", rot=(0, 0, a))
        cyl(0.008, 0.02, (c * R, s * R, 0.06), "steel", "Z", 8, name="caster_stem")
    sz = 0.47
    cyl(0.02, sz - 0.13, (0, 0, 0.11 + (sz - 0.13) / 2 - 0.01), "steel", "Z", 12, name="gas_lift")
    cyl(0.035, 0.06, (0, 0, 0.17), "dark", "Z", 12, name="lift_sleeve")
    box((0.2, 0.2, 0.03), (0, 0, sz - 0.05), "dark", 0.006, name="seat_plate")
    box((0.48, 0.47, 0.07), (0, -0.02, sz), WAY, 0.03, name="chair_seat")
    rod((0, 0.08, sz - 0.04), (0, 0.215, sz + 0.06), 0.025, "dark", name="back_spine", verts=8)
    rod((0, 0.215, sz + 0.06), (0, 0.235, sz + 0.12), 0.025, "dark", name="back_spine", verts=8)
    box((0.44, 0.07, h - sz - 0.11), (0, d / 2 - 0.065, sz + 0.11 + (h - sz - 0.11) / 2 - 0.0), WAY, 0.03, rot=(-0.1, 0, 0), name="backrest")
    for s in (-1, 1):
        x = s * 0.255
        box((0.03, 0.03, 0.16), (x, 0.0, sz + 0.05), "dark", 0.006, name="arm_post")
        box((0.055, 0.24, 0.03), (x, -0.02, sz + 0.14), "dark", 0.01, name="armrest")
        rod((x, 0.0, sz - 0.03), (s * 0.08, 0.0, sz - 0.05), 0.012, "dark", name="arm_bracket")
    box((0.06, 0.04, 0.012), (0.12, -0.1, sz - 0.05), "dark", 0.004, name="lever")


def spice_jars(w, d, h):
    # oak spice rack with four glass jars of spice, 'way' screw lids, cream labels
    rh = 0.012
    box((w, d, rh), (0, 0, rh / 2), "oak", 0.004, name="rack")
    box((w, 0.01, 0.045), (0, d / 2 - 0.005, 0.0225), "oak", 0.003, name="rack_back")
    for x in (-w / 2 + 0.006, w / 2 - 0.006):
        box((0.012, d, 0.03), (x, 0, 0.015), "oak", 0.003, name="rack_end")
    jr = 0.025
    n = 4
    sp = (w - 0.03) / n
    for i, col in enumerate(("terracotta", "mustard", "red", "oak")):
        x = -w / 2 + 0.015 + sp * (i + 0.5)
        jh = h - rh - 0.02
        cyl(jr, jh, (x, -0.004, rh + jh / 2), "glass", "Z", 16, bevel=0.004, name="jar")
        cyl(jr + 0.0008, jh * 0.62, (x, -0.004, rh + 0.004 + jh * 0.31), col, "Z", 16, name="spice")
        cyl(jr + 0.002, 0.02, (x, -0.004, h - 0.01), WAY, "Z", 16, bevel=0.004, name="lid")
        box((0.032, 0.003, 0.022), (x, -0.004 - jr - 0.0005, rh + jh * 0.45), "cream", 0.001, name="label")


def coffee_grinder(w, d, h):
    # vintage box coffee grinder: 'way' (oak) wooden body, walnut drawer with brass knob, steel hopper and crank
    bh = 0.11
    box((w - 0.006, d - 0.012, bh), (0, 0.0, bh / 2), WAY, 0.006, name="grinder_body")
    box((w - 0.002, d - 0.008, 0.012), (0, 0, bh - 0.004), WAY, 0.004, name="body_cap")
    box((0.08, 0.008, 0.04), (0, -d / 2 + 0.007, 0.03), "walnut", 0.003, name="drawer")
    sphere(0.007, (0, -d / 2 + 0.004, 0.03), "brass", name="drawer_knob")
    lathe([(0, bh), (0.045, bh), (0.05, bh + 0.012), (0.042, bh + 0.035), (0.03, bh + 0.045), (0.0, bh + 0.045)], "brass", name="hopper", segs=20)
    cyl(0.006, 0.03, (0, 0, bh + 0.06), "steel", "Z", 8, name="crank_shaft")
    rod((0, 0, bh + 0.072), (0.05, 0, bh + 0.08), 0.005, "steel", name="crank_arm")
    cyl(0.009, h - bh - 0.08, (0.05, 0, bh + 0.08 + (h - bh - 0.08) / 2), "walnut", "Z", 10, bevel=0.003, r2=0.007, name="crank_knob")
    sphere(0.01, (0, 0, bh + 0.074), "steel", name="crank_nut")


def scales(w, d, h):
    # kitchen dial scale: 'way' body, cream dial face with dark ticks and red needle, steel bowl on top
    bh = 0.1
    box((w - 0.05, d - 0.06, bh), (0, 0.01, bh / 2), WAY, 0.02, name="scale_body")
    box((w - 0.04, d - 0.05, 0.012), (0, 0.01, 0.006), WAY, 0.004, name="scale_foot")
    fy = -(d - 0.06) / 2 + 0.01
    cyl(0.045, 0.012, (0, fy - 0.004, bh * 0.5), "cream", "Y", 28, bevel=0.003, name="dial")
    torus(0.046, 0.004, (0, fy - 0.01, bh * 0.5), "steel", rot=(math.pi / 2, 0, 0), name="dial_bezel", seg=28)
    for k in range(9):
        a = math.radians(-135 + 270 * k / 8)
        box((0.002, 0.002, 0.009), (0.036 * math.sin(a), fy - 0.011, bh * 0.5 + 0.036 * math.cos(a)), "dark", 0.0, rot=(0, a, 0), name="dial_tick")
    box((0.002, 0.002, 0.034), (0.008, fy - 0.012, bh * 0.5 + 0.015), "red", 0.0, rot=(0, 0.5, 0), name="needle")
    cyl(0.006, 0.006, (0, fy - 0.012, bh * 0.5), "dark", "Y", 10, name="needle_hub")
    cyl(0.03, 0.012, (0, 0.01, bh + 0.006), "steel", "Z", 14, name="bowl_stem")
    lathe([(0, bh + 0.012), (0.05, bh + 0.012), (0.085, bh + 0.03), (w / 2 - 0.002, h - 0.003), (w / 2 - 0.008, h), (0.08, bh + 0.035), (0.0, bh + 0.02)], "steel", name="bowl", segs=28, at=(0, 0.01 * 0, 0))


def soap_dispenser(w, d, h):
    # ceramic soap dispenser: 'way' lathed bottle, cream label, steel pump collar, head and nozzle toward -X
    R = d / 2 - 0.0015
    bx = 0.03
    lathe([(0, 0), (R - 0.006, 0), (R, 0.01), (R, 0.08), (R * 0.85, 0.1), (0.016, 0.108), (0, 0.108)], WAY, name="bottle", segs=24, at=(bx, 0, 0))
    cyl(R + 0.0005, 0.035, (bx, 0, 0.05), "cream", "Z", 24, name="label_band")
    cyl(0.016, 0.014, (bx, 0, 0.115), "steel", "Z", 16, bevel=0.003, name="pump_collar")
    cyl(0.005, 0.02, (bx, 0, 0.13), "steel", "Z", 8, name="pump_stem")
    box((0.03, 0.022, 0.016), (bx, 0, h - 0.008), "steel", 0.006, name="pump_head")
    rod((bx - 0.01, 0, h - 0.01), (bx - 0.094, 0, h - 0.018), 0.005, "steel", name="nozzle")
    cyl(0.006, 0.006, (bx - 0.094, 0, h - 0.022), "steel", "Z", 8, name="nozzle_tip")
    sphere(0.008, (bx, -R - 0.0, 0.05), "sage", scale=(1, 0.25, 1), name="label_leaf")


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
