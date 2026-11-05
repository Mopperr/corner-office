"""Build Corner Office catalogue-family GLBs (batch 9), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 9 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch9
MINE = ["hose_v", "seed_trays", "bird_feeder", "lantern", "cool_box", "kayak", "water_cooler", "shredder", "heater", "office_trolley"]
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
def hose_v(w, d, h):
    # coiled garden hose: 'way' (black) three-turn coil, brass connectors, mustard and dark spray gun resting on top toward the front
    r = h / (2 + 4 * 0.98)
    R = w / 2 - r
    for k in range(3):
        torus(R - 0.004 * k, r, (0, 0, r + k * 2 * r * 0.98), WAY, name="hose_coil", seg=32)
    zt = r + 2 * 2 * r * 0.98 + r
    rod((0.12, -0.13, zt - 0.02), (0.0, -0.04, zt - 0.02), 0.016, WAY, name="hose_end")
    cyl(0.018, 0.04, (0.0, -0.04, zt - 0.02), "brass", "X", 12, name="hose_connector", rot=(0, math.pi / 2, 0.64))
    box((0.13, 0.03, 0.026), (-0.08, -0.06, zt - 0.016), "mustard", 0.008, rot=(0, 0, 0.6), name="spray_gun")
    box((0.03, 0.03, 0.06), (-0.03, -0.035, zt - 0.045), "dark", 0.008, rot=(0, 0, 0.6), name="spray_gun_grip")
    cyl(0.015, 0.02, (-0.14, -0.1, zt - 0.016), "brass", "X", 12, rot=(0, math.pi / 2, 0.6), name="nozzle")
    box((0.05, 0.03, 0.012), (0.16, 0.08, 0.01), "brass", 0.004, name="tap_connector")


def seed_trays(w, d, h):
    # seed tray of 6x4 cells: 'way' (black) seed flat, walnut compost plugs, green and sage seedlings, white plant labels at the front
    th = 0.05
    box((w, d, 0.008), (0, 0, 0.004), WAY, 0.002, name="seed_flat")
    for s in (-1, 1):
        box((w, 0.006, th), (0, s * (d / 2 - 0.003), th / 2), WAY, 0.002, name="seed_flat")
        box((0.006, d, th), (s * (w / 2 - 0.003), 0, th / 2), WAY, 0.002, name="seed_flat")
    nx, ny = 6, 4
    cw, cd = (w - 0.012) / nx, (d - 0.012) / ny
    for i in range(nx):
        for j in range(ny):
            x = -w / 2 + 0.006 + cw * (i + 0.5)
            y = -d / 2 + 0.006 + cd * (j + 0.5)
            box((cw - 0.004, cd - 0.004, th - 0.012), (x, y, 0.008 + (th - 0.012) / 2), "walnut", 0.004, name="compost")
            if (i + j) % 5 != 3:
                hh = 0.025 + 0.012 * ((i * 3 + j) % 3)
                cyl(0.0025, hh, (x, y, th - 0.004 + hh / 2), "green", "Z", 6, name="stem")
                for s in (-1, 1):
                    sphere(0.011, (x + s * 0.009, y, th - 0.004 + hh), "sage" if (i + j) % 2 else "green", scale=(1, 0.55, 0.3), rot=(0, s * 0.4, 0), name="seedling_leaf")
        for i in range(nx - 1):
            box((0.003, d - 0.012, th - 0.006), (-w / 2 + 0.006 + cw * (i + 1), 0, th / 2), WAY, 0.0, name="cell_wall")
    for x in (-0.12, 0.08):
        box((0.022, 0.003, 0.07), (x, -d / 2 + 0.03, th + 0.012), "white", 0.001, rot=(0.15, 0, 0), name="plant_label")


def bird_feeder(w, d, h):
    # tube bird feeder: 'way' (green) roof and seed dish, glass tube with kraft seed, steel perches and hanging loop
    R = w / 2
    cyl(R, 0.015, (0, 0, 0.0075), WAY, "Z", 22, bevel=0.005, name="seed_dish")
    torus(R - 0.006, 0.006, (0, 0, 0.018), WAY, name="dish_rim", seg=22)
    cyl(0.03, 0.03, (0, 0, 0.03), WAY, "Z", 16, name="feeder_foot")
    cyl(0.045, 0.14, (0, 0, 0.245 + 0.07), "glass", "Z", 18, name="feeder_tube")
    cyl(0.044, 0.2, (0, 0, 0.045 + 0.1), "kraft", "Z", 18, name="seed")
    for z in (0.11, 0.18):
        torus(0.045, 0.003, (0, 0, z), "steel", name="tube_band", seg=18)
    for z, a in ((0.08, 0.0), (0.24, math.pi / 2)):
        rod((-0.085 * math.cos(a), -0.085 * math.sin(a), z), (0.085 * math.cos(a), 0.085 * math.sin(a), z), 0.004, "steel", name="perch")
        for s in (-1, 1):
            cyl(0.014, 0.01, (s * 0.046 * math.cos(a), s * 0.046 * math.sin(a), z + 0.02), WAY, "Z", 10, rot=(math.pi / 2, 0, a + math.pi / 2), name="feed_port")
    cyl(0.09, 0.07, (0, 0, 0.385 + 0.035), WAY, "Z", 18, r2=0.012, bevel=0.004, name="roof")
    cyl(0.05, 0.012, (0, 0, 0.385 + 0.006), WAY, "Z", 18, name="roof_collar")
    rod((0, 0, 0.44), (0, 0, 0.465), 0.005, "steel", name="hanger")
    torus(0.016, 0.004, (0, 0, h - 0.02), "steel", rot=(math.pi / 2, 0, 0), name="hanger_loop")


def lantern(w, d, h):
    # hurricane lantern: 'way' (black) fount and cap, glass globe with mustard flame, steel guard and bail, brass wick knob at the front
    R = w / 2
    lathe([(0, 0), (0.07, 0), (0.079, 0.015), (0.076, 0.045), (0.055, 0.06), (0, 0.06)], WAY, name="fount", segs=20, smooth=False)
    lathe([(0, 0.06), (0.04, 0.06), (0.058, 0.1), (0.06, 0.14), (0.05, 0.18), (0.035, 0.205), (0, 0.205)], "glass", name="globe", segs=20)
    cyl(0.008, 0.03, (0, 0, 0.1), "mustard", "Z", 10, r2=0.002, name="flame")
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        rod((0.07 * math.cos(a), 0.07 * math.sin(a), 0.06), (0.068 * math.cos(a), 0.068 * math.sin(a), 0.205), 0.004, "steel", name="guard")
    torus(0.068, 0.004, (0, 0, 0.13), "steel", name="guard_ring", seg=20)
    cyl(0.055, 0.035, (0, 0, 0.205 + 0.0175), WAY, "Z", 20, r2=0.03, name="lantern_cap")
    cyl(0.022, 0.02, (0, 0, 0.25), WAY, "Z", 14, name="chimney")
    pts = [(-0.074, 0.06), (-0.078, 0.18), (-0.06, 0.26), (-0.02, h - 0.006), (0.02, h - 0.006), (0.06, 0.26), (0.078, 0.18), (0.074, 0.06)]
    arc_bar(pts, 0.006, 0.006, "steel", name="bail", plane="XZ", offset=0.0)
    rod((0, -0.05, 0.05), (0, -0.074, 0.05), 0.004, "steel", name="wick_shaft")
    cyl(0.012, 0.006, (0, -R + 0.002, 0.05), "brass", "Y", 12, name="wick_knob")


def cool_box(w, d, h):
    # picnic cool box: 'way' (blue) body, white lid, grey swing handle, white front latch, dark drain plug
    bh = h - 0.07
    box((w - 0.03, d - 0.01, bh), (0, 0, bh / 2), WAY, 0.025, name="cooler_body")
    box((w - 0.02, d, 0.05), (0, 0, bh + 0.025), "white", 0.02, name="lid")
    box((w - 0.08, d - 0.06, 0.012), (0, 0, bh + 0.052), "white", 0.006, name="lid_rib")
    for s in (-1, 1):
        box((0.015, 0.06, 0.03), (s * (w / 2 - 0.0225), 0, bh - 0.02), "grey", 0.005, name="handle_pivot")
    arc_bar([(-(w / 2 - 0.0075), bh - 0.02), (-(w / 2 - 0.0075), h - 0.0075), ((w / 2 - 0.0075), h - 0.0075), ((w / 2 - 0.0075), bh - 0.02)], 0.015, 0.05, "grey", name="handle", plane="XZ", offset=0.0)
    box((0.07, 0.014, 0.05), (0, -d / 2 + 0.003, bh + 0.005), "white", 0.005, name="latch")
    cyl(0.012, 0.01, (w / 2 - 0.09, -d / 2 + 0.004, 0.03), "dark", "Y", 12, name="drain_plug")
    box((0.12, 0.003, 0.03), (0.08, -d / 2 + 0.004, bh * 0.55), "white", 0.001, name="logo")


def kayak(w, d, h):
    # sit-on-top kayak lying along X: 'way' (blue) hull, dark cockpit and coaming, mustard seat back, dark deck bungees, grey toggles
    L = w / 2 - 0.004
    prof = []
    for k in range(17):
        t = -L + 2 * L * k / 16
        f = max(0.0, 1 - (abs(t) / L) ** 2.2) ** 0.75
        prof.append((max(0.3 * f, 0.004 if 0 < k < 16 else 0.0), t))
    hull = lathe(prof, WAY, name="hull", segs=16)
    hz = 0.15
    hull.rotation_euler = (0, math.pi / 2, 0)
    hull.scale = (hz / 0.3, 1, 1)
    hull.location = (0, 0, hz)
    zt = 2 * hz
    loft(ellipse(0.3, 0.16, 18, cx=0.05), ellipse(0.28, 0.14, 18, cx=0.05), zt - 0.03, zt + 0.006, "dark", name="cockpit")
    torus(1.0, 0.012, (0.05, 0, zt + 0.002), "dark", name="coaming", seg=24).scale = (0.3, 0.16, 1)
    box((0.04, 0.3, 0.08), (0.3, 0, zt + 0.01), "mustard", 0.02, rot=(0, -0.35, 0), name="kayak_seat_back")
    box((0.3, 0.24, 0.02), (0.12, 0, zt - 0.02), "mustard", 0.01, name="kayak_pad")
    for x in (-0.55, -0.75):
        rod((x, -0.15, zt - 0.025), (x - 0.12, 0.15, zt - 0.03), 0.005, "dark", name="bungee")
        rod((x, 0.15, zt - 0.025), (x - 0.12, -0.15, zt - 0.03), 0.005, "dark", name="bungee")
    for x in (-w / 2 + 0.06, w / 2 - 0.06):
        torus(0.025, 0.006, (x, 0, hz + 0.02), "grey", rot=(math.pi / 2, 0, 0), name="toggle")
    box((0.5, 0.004, 0.03), (-0.5, -0.218, hz + 0.08), "white", 0.0, rot=(0, 0, 0.12), name="hull_stripe")


def water_cooler(w, d, h):
    # office water cooler: 'way' (black) cabinet, glass bottle on top, red and blue taps at the front, steel drip grate, white cup holder
    cw = w - 0.002
    cd = 0.315
    ch = 0.86
    box((cw, cd, ch), (0, d / 2 - 0.0 - cd / 2, ch / 2), WAY, 0.02, name="cooler_cabinet")
    fy = d / 2 - cd
    box((cw - 0.06, 0.03, 0.2), (0, fy + 0.005, 0.66), "dark", 0.01, name="tap_recess")
    for x, col in ((-0.06, "blue"), (0.06, "red")):
        box((0.04, 0.03, 0.035), (x, fy - 0.012, 0.72), col, 0.008, name="tap")
        cyl(0.007, 0.03, (x, fy - 0.015, 0.69), "steel", "Z", 8, name="tap_nozzle")
    box((cw - 0.08, 0.04, 0.012), (0, fy - 0.012, 0.57), "steel", 0.004, name="drip_grate")
    cyl(0.12, 0.012, (0, 0, ch + 0.006), "dark", "Z", 22, name="bottle_collar")
    lathe([(0, ch + 0.01), (0.03, ch + 0.01), (0.03, ch + 0.05), (0.13, ch + 0.11), (w / 2 - 0.04, 1.0), (0.14, h - 0.03), (0.11, h - 0.003), (0, h)], "glass", name="water_bottle", segs=22)
    for z in (1.04, 1.12):
        torus(0.141, 0.005, (0, 0, z), "glass", name="bottle_rib", seg=22)


def shredder(w, d, h):
    # office paper shredder: 'way' (black) bin with glass front window full of white shreds, grey cutting head, white paper in the slot, green and red buttons
    bh = 0.4
    box((w, d - 0.01, bh), (0, 0.005, bh / 2), WAY, 0.015, name="shredder_bin")
    fy = -d / 2 + 0.005
    box((w - 0.12, 0.006, 0.2), (0, fy - 0.001, 0.2), "glass", 0.003, name="window")
    for k in range(9):
        box((0.006, 0.004, 0.06 + 0.03 * (k % 3)), (-0.1 + k * 0.025, fy - 0.005, 0.13 + 0.015 * (k % 3)), "white", 0.0, rot=(0, 0.3 * ((k % 3) - 1), 0), name="shreds")
    box((0.22, 0.003, 0.014), (0, fy - 0.002, 0.34), "white", 0.0, name="bin_handle_mark")
    box((w - 0.004, d - 0.004, 0.065), (0, 0.003, bh + 0.0325), "grey", 0.012, name="shredder_head")
    box((w - 0.08, 0.012, 0.004), (0, 0.02, bh + 0.065), "dark", 0.0, name="paper_slot")
    box((0.21, 0.003, h - bh - 0.04), (0, 0.02, bh + 0.04 + (h - bh - 0.04) / 2), "white", 0.0, rot=(0.12, 0, 0), name="paper_sheet")
    for x, col in ((0.12, "green"), (0.145, "red")):
        cyl(0.008, 0.006, (x, -0.07, bh + 0.067), col, "Z", 10, name="button")


def heater(w, d, h):
    # oil-filled radiator heater: 'way' (black) fins, steel feet with dark castors, side control box with white knob and red light
    nf = 9
    zf0, zf1 = 0.07, h
    x0, x1 = -w / 2 + 0.018, w / 2 - 0.1
    pitch = (x1 - x0) / (nf - 1)
    for k in range(nf):
        box((0.036, d - 0.04, zf1 - zf0), (x0 + k * pitch, 0, (zf0 + zf1) / 2), WAY, 0.016, name="fin")
    for z in (zf0 + 0.04, zf1 - 0.04):
        box((x1 - x0, 0.05, 0.03), ((x0 + x1) / 2, 0, z), WAY, 0.008, name="fin_rail")
    bx = w / 2 - 0.045
    box((0.09, 0.12, 0.2), (bx, 0, zf1 - 0.12), WAY, 0.015, name="control_box")
    cyl(0.025, 0.02, (bx, -0.07, zf1 - 0.09), "white", "Y", 16, bevel=0.004, name="knob")
    box((0.006, 0.004, 0.02), (bx, -0.081, zf1 - 0.08), "dark", 0.0, name="knob_mark")
    cyl(0.007, 0.008, (bx, -0.064, zf1 - 0.16), "red", "Y", 10, name="power_light")
    for x in (x0 + pitch, x1 - pitch):
        box((0.04, d - 0.004, 0.02), (x, 0, 0.05), "steel", 0.006, name="foot")
        for s in (-1, 1):
            cyl(0.02, 0.018, (x, s * (d / 2 - 0.02), 0.02), "dark", "X", 12, name="castor")
    rod((x0, d / 2 - 0.05, zf1 - 0.25), (x0 - 0.0, d / 2 - 0.02, zf1 - 0.35), 0.005, "dark", name="cable")


def office_trolley(w, d, h):
    # office/post trolley: 'way' (black) tube posts, two lipped decks and push handle, dark castors, white paper reams, kraft parcels
    r = 0.012
    cz = 0.06
    xs, ys = w / 2 - 0.02, d / 2 - 0.03
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl(r, 0.5, (sx * xs, sy * ys, cz + 0.27), WAY, "Z", 10, name="post")
            cyl(0.03, 0.025, (sx * xs, sy * ys, 0.03), "dark", "X", 12, name="castor")
            box((0.02, 0.03, 0.02), (sx * xs, sy * ys, 0.053), "grey", 0.003, name="castor_fork")
    for z in (0.1, 0.5):
        box((w - 0.03, d - 0.03, 0.02), (0, 0, z), WAY, 0.004, name="deck")
        box((w - 0.02, 0.008, 0.05), (0, -d / 2 + 0.006, z + 0.02), WAY, 0.002, name="front_lip")
        box((w - 0.02, 0.008, 0.05), (0, d / 2 - 0.006, z + 0.02), WAY, 0.002, name="back_lip")
        for s in (-1, 1):
            box((0.008, d - 0.02, 0.05), (s * (w / 2 - 0.006), 0, z + 0.02), WAY, 0.002, name="side_lip")
    for s in (-1, 1):
        rod((s * xs, ys, 0.52), (s * xs, ys, h - 0.02), r, WAY, name="handle_post")
    rod((-xs, ys, h - 0.02), (xs, ys, h - 0.02), r, WAY, name="push_handle")
    cyl(0.02, 0.3, (0, ys, h - 0.02), "grey", "X", 12, name="handle_grip")
    for k in range(3):
        box((0.21, 0.3, 0.05), (-0.13, 0.0, 0.51 + 0.025 + k * 0.05), "white", 0.004, name="paper_ream")
        box((0.212, 0.302, 0.015), (-0.13, 0.0, 0.51 + 0.025 + k * 0.05), "red" if k == 1 else "blue", 0.0, name="ream_wrap")
    box((0.22, 0.24, 0.16), (0.15, 0.02, 0.51 + 0.08), "kraft", 0.006, name="parcel")
    box((0.04, 0.242, 0.162), (0.15, 0.02, 0.51 + 0.08), "white", 0.0, name="parcel_tape")
    box((0.4, 0.3, 0.2), (0, 0, 0.11 + 0.1), "kraft", 0.006, name="parcel")


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
