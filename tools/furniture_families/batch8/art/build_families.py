"""Build Corner Office catalogue-family GLBs (batch 8), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 8 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch8
MINE = ["wellies", "wheelbarrow_v", "watering_v", "office_bin", "office_shelf", "desk_v", "office_clock", "safe", "notice_board", "umbrella_stand"]
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
WAY_ALIAS = {"painted white": "white", "painted sage": "sage", "tan": "kraft", "wicker": "kraft", "off": "dark", "brown": "walnut", "antique": "kraft", "cast iron": "black", "aluminium": "steel", "carbon": "black", "galvanised": "steel"}
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


def bar(p0, p1, sx, sy, color, name="part", bevel=0.004):
    """Box of cross-section sx x sy running from p0 to p1 (keeps X/Y roll for
    lines in the YZ or XZ plane)."""
    p0, p1 = Vector(p0), Vector(p1)
    v = p1 - p0
    o = box((sx, sy, v.length), (p0 + p1) / 2, color, bevel, name=name)
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(v.normalized())
    return o


def loft(bot, top, z0, z1, color, name="part", bevel=0.0, cap_top=True):
    """Solid between two closed XY outlines with the same point count."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    A = [bm.verts.new((x, y, z0)) for x, y in bot]
    B = [bm.verts.new((x, y, z1)) for x, y in top]
    n = len(bot)
    bm.faces.new(list(reversed(A)))
    if cap_top:
        bm.faces.new(B)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((A[i], A[j], B[j], B[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return _finish(o, color, bevel, name)


def rrect(w, d, r, n=4, cx=0.0, cy=0.0):
    """Rounded-rectangle XY outline (counter-clockwise)."""
    pts = []
    for qx, qy, a0 in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        ox, oy = cx + qx * (w / 2 - r), cy + qy * (d / 2 - r)
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((ox + r * math.cos(a), oy + r * math.sin(a)))
    return pts


def ellipse(rx, ry, n=20, cx=0.0, cy=0.0):
    return [(cx + rx * math.cos(2 * math.pi * k / n), cy + ry * math.sin(2 * math.pi * k / n)) for k in range(n)]


def rotX(p, t, pivot=(0, 0, 0)):
    """Rotate point p about the X axis through pivot by t (negative t tips +Z toward +Y)."""
    x, y, z = p[0] - pivot[0], p[1] - pivot[1], p[2] - pivot[2]
    return (x + pivot[0], y * math.cos(t) - z * math.sin(t) + pivot[1], y * math.sin(t) + z * math.cos(t) + pivot[2])
def wellies(w, d, h):
    # pair of wellington boots side by side, toes to -Y: 'way' shafts and feet, dark soles, red side badge, cream top rim
    for s in (-1, 1):
        x = s * 0.084
        box((0.13, 0.3, 0.025), (x, 0.0, 0.0125), "dark", 0.008, name="sole")
        box((0.124, 0.2, 0.1), (x, -0.045, 0.072), WAY, 0.045, name="boot_foot")
        sphere(0.062, (x, -0.085, 0.07), WAY, scale=(1, 1.05, 0.75), name="boot_toe")
        cyl(0.064, 0.27, (x, 0.07, 0.025 + 0.135 + 0.02), WAY, "Z", 18, bevel=0.01, name="boot_shaft")
        cyl(0.066, 0.025, (x, 0.07, h - 0.0125), "cream", "Z", 18, bevel=0.004, name="rim")
        cyl(0.055, 0.004, (x, 0.07, h - 0.0005), "dark", "Z", 18, name="boot_opening")
        box((0.05, 0.004, 0.03), (x, 0.07 - 0.064 - 0.001, 0.25), "red", 0.002, name="badge")
        box((0.004, 0.06, 0.012), (x + s * 0.064, 0.07, 0.32), "dark", 0.002, name="pull_tab")


def wheelbarrow_v(w, d, h):
    # builder's wheelbarrow, wheel to -Y: 'way' (black) tub with grey inside, dark tyre, steel frame, hub and legs, red grips
    zb, zt = 0.3, h - 0.002
    bot = rrect(0.36, 0.5, 0.06, cy=-0.02)
    top = rrect(0.6, 0.8, 0.08, cy=-0.04)
    loft(bot, top, zb, zt, WAY, name="tub")
    loft(rrect(0.56, 0.76, 0.07, cy=-0.04), rrect(0.56, 0.76, 0.07, cy=-0.04), zt - 0.004, zt + 0.001, "grey", name="tub_inside")
    yw, zw = -d / 2 + 0.195, 0.195
    torus(0.15, 0.045, (0, yw, zw), "dark", rot=(0, math.pi / 2, 0), name="tyre", seg=22)
    cyl(0.12, 0.05, (0, yw, zw), "grey", "X", 18, name="wheel_rim")
    cyl(0.03, 0.14, (0, yw, zw), "steel", "X", 12, name="hub")
    gx, gy, gz = w / 2 - 0.022, d / 2 - 0.01, 0.44
    for s in (-1, 1):
        pts = [(s * 0.07, yw, zw), (s * 0.2, yw + 0.35, 0.27), (s * gx, 0.4, 0.36), (s * gx, gy - 0.1, gz)]
        for a, b in zip(pts, pts[1:]):
            rod(a, b, 0.016, "steel", name="frame")
        cyl(0.022, 0.13, (s * gx, gy - 0.065, gz + 0.006), "red", "Y", 12, bevel=0.004, name="grip", rot=(math.pi / 2 - 0.08, 0, 0))
        rod((s * 0.2, 0.25, 0.33), (s * 0.2, 0.3, 0.02), 0.014, "steel", name="leg")
        box((0.05, 0.08, 0.02), (s * 0.2, 0.3, 0.01), "dark", 0.006, name="leg_foot")
    rod((-0.2, 0.28, 0.12), (0.2, 0.28, 0.12), 0.01, "steel", name="leg_brace")


def watering_v(w, d, h):
    # classic watering can, spout to -X: 'way' (blue) round body and handle, steel rose, dark filler cap, cream label on the front
    cx = 0.06
    lathe([(0, 0), (0.097, 0), (0.1, 0.012), (0.1, 0.17), (0.085, 0.21), (0.05, 0.23), (0, 0.232)], WAY, name="can_body", segs=24, at=(cx, 0, 0), smooth=False)
    cyl(0.035, 0.03, (cx + 0.01, 0, 0.24), WAY, "Z", 16, bevel=0.004, name="filler_neck")
    cyl(0.038, 0.008, (cx + 0.01, 0, 0.255), "dark", "Z", 16, bevel=0.002, name="filler_cap")
    arc_bar([(cx - 0.04, 0.22), (cx - 0.02, 0.285), (cx + 0.07, 0.29), (0.185, 0.24), (0.19, 0.13), (cx + 0.095, 0.06)], 0.018, 0.02, WAY, name="can_handle", plane="XZ", offset=0.0)
    rod((cx - 0.09, 0, 0.04), (-0.165, 0, 0.245), 0.014, WAY, name="spout")
    rod((-0.165, 0, 0.245), (-0.182, 0, 0.272), 0.03, "steel", name="rose", verts=14)
    cyl(0.026, 0.002, (-0.183, 0, 0.274), "dark", "Z", 12, rot=(0, -0.55, 0), name="rose_holes")
    box((0.09, 0.003, 0.07), (cx, -0.1, 0.1), "cream", 0.001, name="label")
    sphere(0.016, (cx - 0.015, -0.1015, 0.1), "blue", scale=(1, 0.15, 1), name="label_drop")


def office_bin(w, d, h):
    # office waste-paper bin: 'way' (black) tapered hollow bin, dark rim and band, crumpled white and cream paper inside
    R0, R1 = 0.115, w / 2 - 0.006
    lathe([(0, 0), (R0, 0), (R1, h - 0.01), (R1 - 0.006, h - 0.01), (R0 - 0.006, 0.012), (0, 0.012)], WAY, name="bin_body", segs=24, smooth=False)
    torus(R1 - 0.001, 0.006, (0, 0, h - 0.01 + 0.0), "dark", name="rim", seg=24)
    torus(R0 + 0.004, 0.006, (0, 0, 0.03), "dark", name="band", seg=24)
    for p, r, c in (((0.03, 0.02, 0.27), 0.05, "white"), ((-0.05, -0.02, 0.26), 0.045, "cream"), ((0.0, -0.05, 0.25), 0.04, "white"), ((-0.02, 0.06, 0.24), 0.04, "cream"), ((0.06, -0.04, 0.22), 0.035, "cream")):
        sphere(r, p, c, scale=(1, 0.9, 0.85), name="paper_ball", rot=(0.4, 0.3, 0.2))


def office_shelf(w, d, h):
    # tall office bookcase: 'way' (grey) carcass, card back, coloured binders with dark labels, books, a sage plant
    t = 0.022
    for s in (-1, 1):
        box((t, d, h), (s * (w / 2 - t / 2), 0, h / 2), WAY, 0.004, name="side_panel")
    box((w, d, t), (0, 0, h - t / 2), WAY, 0.004, name="shelf_cap")
    box((w - 2 * t, 0.012, 0.07), (0, -d / 2 + 0.014, 0.035), WAY, 0.003, name="plinth")
    box((w - 2 * t, 0.006, h - t), (0, d / 2 - 0.006, (h - t) / 2), "card", 0.0, name="back_panel")
    zs = [0.07, 0.42, 0.78, 1.14, 1.48]
    for z in zs:
        box((w - 2 * t, d - 0.012, t), (0, -0.006, z + t / 2), WAY, 0.003, name="shelf")
        box((w - 2 * t, 0.004, t), (0, -d / 2 + 0.002, z + t / 2), WAY, 0.0, name="shelf_lip")
    iw = w - 2 * t
    rows = {0: [("blue", 0.07)] * 5 + [("red", 0.07)] * 3,
            1: [("mustard", 0.05), ("red", 0.035), ("blue", 0.045), ("sage", 0.04), ("mustard", 0.03), ("blue", 0.05), ("red", 0.04)],
            2: [("red", 0.07)] * 4,
            3: [("blue", 0.04), ("blue", 0.04), ("sage", 0.05), ("mustard", 0.035), ("red", 0.045)]}
    for k, row in rows.items():
        z = zs[k] + t
        x = -iw / 2 + 0.02
        for col, bw in row:
            bh = 0.31 if k in (0, 2) else 0.24 - (int(bw * 1000) % 4) * 0.012
            box((bw - 0.003, 0.26, bh), (x + bw / 2, 0.0, z + bh / 2), col, 0.004, name="binder")
            if k in (0, 2):
                box((bw * 0.55, 0.002, 0.05), (x + bw / 2, -0.131, z + bh * 0.7), "card", 0.0, name="binder_label")
                cyl(0.009, 0.002, (x + bw / 2, -0.131, z + bh * 0.3), "card", "Y", 10, name="binder_hole")
            x += bw
    z = zs[1] + t
    box((0.22, 0.24, 0.05), (0.22, 0.0, z + 0.025), "card", 0.006, name="paper_stack")
    z = zs[4] + t
    cyl(0.07, 0.12, (-0.2, 0.0, z + 0.06), WAY, "Z", 16, bevel=0.006, r2=0.055, name="plant_pot")
    for a in range(6):
        ang = a * math.pi / 3
        sphere(0.06, (-0.2 + 0.04 * math.cos(ang), 0.04 * math.sin(ang), z + 0.17 + 0.02 * (a % 2)), "sage", scale=(1, 1, 0.7), name="leaves")
    for k, col in enumerate(("blue", "red", "mustard")):
        box((0.2, 0.25, 0.035), (0.18, 0.0, z + 0.0175 + k * 0.035), col, 0.004, name="book_flat", rot=(0, 0, 0.06 * (k - 1)))


def desk_v(w, d, h):
    # office desk: 'way' (oak) desk surface, grey three-drawer pedestal on the right with steel handles, steel legs on the left, grey modesty panel
    tt = 0.03
    box((w, d, tt), (0, 0, h - tt / 2), WAY, 0.006, name="desk_surface")
    px0, px1 = w / 2 - 0.44, w / 2 - 0.02
    pw = px1 - px0
    pcx = (px0 + px1) / 2
    box((pw, d - 0.06, h - tt - 0.02), (pcx, 0.01, 0.02 + (h - tt - 0.02) / 2), "grey", 0.006, name="pedestal")
    box((pw - 0.02, d - 0.08, 0.02), (pcx, 0.01, 0.01), "dark", 0.004, name="plinth")
    fz = [(0.03, 0.31), (0.32, 0.5), (0.51, h - tt - 0.02)]
    for z0, z1 in fz:
        box((pw - 0.02, 0.012, z1 - z0 - 0.01), (pcx, -d / 2 + 0.024, (z0 + z1) / 2), "grey", 0.004, name="drawer_front")
        box((0.12, 0.018, 0.016), (pcx, -d / 2 + 0.012, z1 - 0.035), "steel", 0.005, name="drawer_handle")
    lx = -w / 2 + 0.05
    for sy in (-1, 1):
        box((0.05, 0.05, h - tt), (lx, sy * (d / 2 - 0.06), (h - tt) / 2), "steel", 0.008, name="desk_leg")
        box((0.06, 0.06, 0.012), (lx, sy * (d / 2 - 0.06), 0.006), "dark", 0.004, name="leg_foot")
    box((0.04, d - 0.17, 0.04), (lx, 0, 0.1), "steel", 0.006, name="leg_rail")
    box((px0 - lx, 0.018, 0.36), ((lx + px0) / 2, d / 2 - 0.08, h - tt - 0.2), "grey", 0.004, name="modesty_panel")
    box((0.06, 0.03, 0.002), (-0.25, d / 2 - 0.08, h - 0.001), "dark", 0.0, name="cable_grommet")


def office_clock(w, d, h):
    # office wall clock: 'way' (black) case and front rim, white face with dark ticks and hands, red second hand; back plate toward +Y
    R = w / 2
    zc = h / 2
    box((0.08, 0.006, 0.08), (0, d / 2 - 0.003, zc), "dark", 0.002, name="back_plate")
    cyl(R - 0.012, 0.024, (0, 0.002, zc), WAY, "Y", 32, bevel=0.006, name="clock_case")
    torus(R - 0.012, 0.012, (0, -d / 2 + 0.012 + 0.0, zc), WAY, rot=(math.pi / 2, 0, 0), name="rim", seg=32)
    fy = -0.011
    cyl(R - 0.02, 0.002, (0, fy, zc), "white", "Y", 32, name="clock_face")
    for k in range(12):
        a = k * math.pi / 6
        L = 0.024 if k % 3 == 0 else 0.013
        r = R - 0.03 - L / 2
        box((0.006 if k % 3 == 0 else 0.004, 0.002, L), (r * math.sin(a), fy - 0.002, zc + r * math.cos(a)), "dark", 0.0, rot=(0, a, 0), name="tick")
    for a, L, t in ((math.radians(300), 0.07, 0.009), (math.radians(60), 0.105, 0.006)):
        box((t, 0.002, L), (L / 2 * math.sin(a), fy - 0.004, zc + L / 2 * math.cos(a)), "dark", 0.001, rot=(0, a, 0), name="clock_hand")
    a = math.radians(200)
    box((0.0025, 0.0015, 0.11), (0.045 * math.sin(a), fy - 0.0058, zc + 0.045 * math.cos(a)), "red", 0.0, rot=(0, a, 0), name="second_hand")
    cyl(0.008, 0.006, (0, fy - 0.004, zc), "red", "Y", 12, name="hand_boss")


def safe(w, d, h):
    # office safe: 'way' (black) body and recessed door, steel combination dial and spoked handle, brass maker's plate, dark hinges and feet
    fh = 0.03
    box((w, d - 0.03, h - fh), (0, 0.015, fh + (h - fh) / 2), WAY, 0.02, name="safe_body")
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((0.05, 0.05, fh), (sx * (w / 2 - 0.05), sy * (d / 2 - 0.06), fh / 2), "dark", 0.008, name="safe_foot")
    fy = -d / 2 + 0.03
    box((w - 0.06, 0.02, h - fh - 0.06), (0, fy - 0.005, fh + (h - fh) / 2), WAY, 0.01, name="door")
    for z in (0.15, 0.42):
        cyl(0.014, 0.06, (-w / 2 + 0.03, fy - 0.01, z), "dark", "Z", 12, name="hinge")
    zc = fh + (h - fh) / 2
    cyl(0.055, 0.012, (0.02, fy - 0.02, zc + 0.07), "steel", "Y", 24, bevel=0.003, name="dial")
    cyl(0.03, 0.006, (0.02, fy - 0.025, zc + 0.07), "dark", "Y", 18, name="dial_centre")
    for k in range(12):
        a = k * math.pi / 6
        box((0.003, 0.003, 0.01), (0.02 + 0.046 * math.sin(a), fy - 0.027, zc + 0.07 + 0.046 * math.cos(a)), "dark", 0.0, rot=(0, a, 0), name="dial_tick")
    cyl(0.02, 0.012, (0.02, fy - 0.02, zc - 0.07), "steel", "Y", 14, bevel=0.003, name="handle_hub")
    for k in range(3):
        a = k * 2 * math.pi / 3 + 0.3
        rod((0.02, fy - 0.022, zc - 0.07), (0.02 + 0.055 * math.sin(a), fy - 0.022, zc - 0.07 + 0.055 * math.cos(a)), 0.006, "steel", name="handle_spoke")
        sphere(0.009, (0.02 + 0.055 * math.sin(a), fy - 0.022, zc - 0.07 + 0.055 * math.cos(a)), "steel", name="handle_knob")
    box((0.12, 0.003, 0.03), (0.02, fy - 0.0165, h - 0.09), "brass", 0.001, name="maker_plate")


def notice_board(w, d, h):
    # office notice board: 'way' (oak) frame, kraft cork with pinned cream, mustard, blue and white notes, red pins; kraft back panel toward +Y
    box((w - 0.02, 0.006, h - 0.02), (0, d / 2 - 0.003, h / 2), "kraft", 0.0, name="back_panel")
    f = 0.035
    for z in (f / 2, h - f / 2):
        box((w, d - 0.006, f), (0, -0.003, z), WAY, 0.006, name="frame")
    for x in (-w / 2 + f / 2, w / 2 - f / 2):
        box((f, d - 0.006, h), (x, -0.003, h / 2), WAY, 0.006, name="frame")
    cy = -d / 2 + 0.014
    box((w - 2 * f, 0.016, h - 2 * f), (0, cy + 0.008, h / 2), "kraft", 0.0, name="cork")
    notes = [(-0.3, 0.38, 0.13, 0.16, "cream", 0.06), (-0.12, 0.42, 0.1, 0.1, "mustard", -0.08), (0.06, 0.36, 0.17, 0.22, "white", 0.02),
             (0.27, 0.4, 0.11, 0.11, "blue", 0.1), (-0.25, 0.17, 0.16, 0.11, "white", -0.04), (-0.05, 0.15, 0.1, 0.1, "mustard", 0.05),
             (0.25, 0.16, 0.14, 0.16, "cream", -0.06)]
    for k, (x, z, nw, nh, col, rr) in enumerate(notes):
        ny = cy - 0.001 - 0.0012 * (k % 2)
        box((nw, 0.002, nh), (x, ny, z), col, 0.0, rot=(0, rr, 0), name="note")
        if col in ("white", "cream"):
            for j in range(3):
                box((nw * 0.6, 0.002, 0.008), (x, ny - 0.0012, z + nh * 0.25 - j * nh * 0.2), "blue" if col == "white" else "kraft", 0.0, rot=(0, rr, 0), name="note_lines")
        sphere(0.008, (x, ny - 0.006, z + nh / 2 - 0.015), "red", scale=(1, 0.6, 1), name="pin")


def umbrella_stand(w, d, h):
    # umbrella stand: 'way' (black) cylinder with brass bands, a red and a blue furled umbrella with walnut crook handles and steel tips
    R = w / 2 - 0.004
    lathe([(0, 0), (R, 0), (R, 0.5), (R - 0.008, 0.5), (R - 0.008, 0.012), (0, 0.012)], WAY, name="stand", segs=24, smooth=False)
    for z in (0.03, 0.47):
        torus(R - 0.002, 0.006, (0, 0, z), "brass", name="band", seg=24)
    for (x, y, col, top, lean) in ((-0.03, 0.025, "red", h, -0.06), (0.035, -0.025, "blue", h - 0.07, 0.05)):
        L = top - 0.13 - 0.05
        dx = math.sin(lean) * L / 2
        cyl(0.004, 0.04, (x - dx, y, 0.035), "steel", "Z", 6, name="tip")
        cyl(0.034, L, (x, y, 0.05 + L / 2), col, "Z", 8, r2=0.013, name="canopy", rot=(0, lean, 0))
        cyl(0.026, 0.025, (x + dx * 0.5, y, 0.05 + L * 0.75), col, "Z", 8, name="canopy_tie", rot=(0, lean, 0))
        hx = x + dx + math.sin(lean) * 0.04
        rod((x + dx, y, top - 0.13), (hx, y, top - 0.06), 0.007, "steel", name="umbrella_shaft")
        sx = -1 if x > 0 else 1
        arc_bar([(hx, top - 0.07), (hx, top - 0.03), (hx + sx * 0.01, top - 0.008), (hx + sx * 0.035, top - 0.008), (hx + sx * 0.045, top - 0.03), (hx + sx * 0.045, top - 0.055)], 0.016, 0.018, "walnut", name="crook", plane="XZ", offset=y)


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
