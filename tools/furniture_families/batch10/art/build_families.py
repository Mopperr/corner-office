"""Build Corner Office catalogue-family GLBs (batch 10), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 12 families in MINE (the other 10 of batch 10 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch10
MINE = ["coffee_machine_v", "mug_tree", "folder_stack", "desk_fan", "office_kettle", "reception_sign", "projector", "office_speaker", "stapler_set", "dispatch_scale", "globe_office", "desk_calendar"]
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
def coffee_machine_v(w, d, h):
    # espresso machine: 'way' (black) body and group head, steel portafilter, drip grate and cup warmer, glass water tank, cream cup
    y0, y1 = -d / 2, d / 2
    box((w, d, 0.05), (0, 0, 0.025), WAY, 0.008, name="machine_base")
    box((w, 0.2, h - 0.07), (0, y1 - 0.1 - 0.02, 0.05 + (h - 0.07) / 2), WAY, 0.01, name="machine_body")
    box((0.1, 0.02, h - 0.1), (0.07, y1 - 0.01, 0.05 + (h - 0.1) / 2), "glass", 0.004, name="water_tank")
    box((w, 0.13, 0.08), (0, y1 - 0.22 - 0.065 + 0.01, h - 0.02 - 0.04), WAY, 0.01, name="group_head")
    box((w - 0.03, 0.18, 0.012), (0, 0.02, h - 0.014), "steel", 0.004, name="cup_warmer")
    for x in (-0.09, 0.09):
        box((0.02, 0.02, 0.016), (x, 0.08, h - 0.008), "steel", 0.003, name="warmer_rail")
    yp = y1 - 0.22 - 0.09
    cyl(0.035, 0.03, (-0.05, yp + 0.02, h - 0.075), "steel", "Z", 18, bevel=0.004, name="portafilter")
    rod((-0.05, yp + 0.0, h - 0.085), (-0.05, y0 + 0.012, h - 0.1), 0.011, "dark", name="portafilter_handle")
    sphere(0.013, (-0.05, y0 + 0.013, h - 0.1), "dark", name="portafilter_handle")
    box((w - 0.04, 0.15, 0.012), (0, y0 + 0.085, 0.056), "steel", 0.003, name="drip_grate")
    lathe([(0, 0), (0.024, 0), (0.03, 0.05), (0.026, 0.05), (0.021, 0.006), (0, 0.006)], "cream", name="cup", at=(-0.05, yp + 0.02, 0.062))
    rod((0.09, yp + 0.01, h - 0.07), (0.1, y0 + 0.05, 0.12), 0.006, "steel", name="steam_wand")
    for x, c in ((0.08, "steel"), (0.115, "steel")):
        cyl(0.012, 0.01, (x, y1 - 0.22 - 0.065 + 0.01 - 0.065 - 0.004, h - 0.06), c, "Y", 14, name="dial")


def mug_tree(w, d, h):
    # mug tree: 'way' (oak) base, post and pegs, four mugs in cream, terracotta, sage and blue
    cyl(w / 2, 0.022, (0, 0, 0.011), WAY, "Z", 24, bevel=0.006, name="mug_tree_base")
    cyl(0.012, h - 0.034, (0, 0, 0.022 + (h - 0.034) / 2), WAY, "Z", 12, name="mug_tree_post")
    sphere(0.017, (0, 0, h - 0.017), WAY, name="post_knob")
    cols = ["cream", "terracotta", "sage", "blue"]
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        z = 0.25 if i % 2 == 0 else 0.29
        ca, sa = math.cos(a), math.sin(a)
        rod((ca * 0.01, sa * 0.01, z - 0.01), (ca * 0.06, sa * 0.06, z + 0.012), 0.005, WAY, name="peg")
        R = 0.0755
        cx, cy = ca * R, sa * R
        top = z - 0.0
        lathe([(0, 0), (0.028, 0), (0.03, 0.07), (0.026, 0.07), (0.024, 0.006), (0, 0.006)], cols[i], name="mug",
              at=(cx, cy, top - 0.075))
        o = torus(0.016, 0.004, (ca * (R - 0.033), sa * (R - 0.033), top - 0.04), cols[i], name="mug_handle", seg=14)
        o.rotation_euler = (math.pi / 2, 0, a + math.pi / 2)


def folder_stack(w, d, h):
    # stack of five ring binders lying flat, spines to the front: 'way' (blue), red, mustard, sage, grey covers, cream spine labels, white paper
    cols = [WAY, "red", "mustard", "sage", "grey"]
    t = h / 5
    for i, c in enumerate(cols):
        z = i * t
        rz = (0.02, -0.015, 0.01, -0.02, 0.012)[i]
        dx = (0.0, 0.006, -0.005, 0.004, -0.004)[i]
        ww, dd = w - 0.014, d - 0.012
        for zz in (z + 0.002, z + t - 0.002):
            box((ww, dd, 0.004), (dx, 0.0, zz), c, 0.001, rot=(0, 0, rz), name="folder_cover")
        o = box((ww, 0.012, t - 0.002), (dx, -dd / 2 + 0.006, z + t / 2), c, 0.003, rot=(0, 0, rz), name="folder_spine")
        box((ww - 0.02, dd - 0.03, t - 0.012), (dx, 0.008, z + t / 2), "white", 0.001, rot=(0, 0, rz), name="paper_sheets")
        lx, ly = dx + 0.06 * math.cos(rz) - (-dd / 2) * math.sin(rz), 0.06 * math.sin(rz) + (-dd / 2) * math.cos(rz)
        box((0.09, 0.003, t * 0.5), (lx, ly - 0.001, z + t / 2), "cream", 0.001, rot=(0, 0, rz), name="spine_label")


def desk_fan(w, d, h):
    # desk fan: 'way' (black) base, stem and motor, steel blades, black wire guard with front ring and badge
    zc = h - 0.152
    R = w / 2 - 0.006
    loft(ellipse(0.1, d / 2 + 0.003, 24), ellipse(0.07, d / 2 - 0.025, 24), 0.0, 0.032, WAY, name="fan_base", bevel=0.006)
    box((0.12, 0.08, 0.002), (0, 0, 0.001), "dark", 0.0, name="fan_base_felt")
    cyl(0.011, zc - 0.03, (0, 0.02, (zc - 0.03) / 2 + 0.02), WAY, "Z", 10, name="fan_stem")
    cyl(0.045, 0.06, (0, 0.035, zc), WAY, "Y", 18, bevel=0.01, name="motor_housing")
    cyl(0.02, 0.02, (0, -0.005, zc), "steel", "Y", 12, name="blade_hub")
    for k in range(3):
        a = k * 2 * math.pi / 3
        o = sphere(0.06, (math.cos(a) * 0.07, -0.015, zc + math.sin(a) * 0.07), "steel", scale=(1.0, 0.12, 0.55), name="blade")
        o.rotation_euler = (0, -a, 0)
    for y, nm in ((-0.04, "guard_front"), (0.004, "guard_ring")):
        torus(R, 0.005, (0, y, zc), WAY, rot=(math.pi / 2, 0, 0), name=nm, seg=36)
    for k in range(12):
        a = k * math.pi / 6
        rod((0, -0.045, zc), (math.cos(a) * R, -0.04, zc + math.sin(a) * R), 0.0022, WAY, name="guard_wire", verts=6)
        rod((math.cos(a) * R, -0.04, zc + math.sin(a) * R), (math.cos(a) * R, 0.004, zc + math.sin(a) * R), 0.0022, WAY, name="guard_wire", verts=6)
    torus(R * 0.55, 0.003, (0, -0.043, zc), WAY, rot=(math.pi / 2, 0, 0), name="guard_front", seg=24)
    cyl(0.022, 0.008, (0, -0.048, zc), "steel", "Y", 16, name="fan_badge")
    cyl(0.01, 0.012, (0, -d / 2 + 0.03, 0.03), "white", "Z", 10, name="speed_knob")


def office_kettle(w, d, h):
    # cordless kettle: dark power base, 'way' (blue) body and lid, glass water window at the front, white switch, dark handle
    rb = d / 2 - 0.004
    cyl(rb, 0.018, (0, 0, 0.009), "dark", "Z", 24, bevel=0.004, name="power_base")
    lathe([(0, 0.018), (rb - 0.004, 0.018), (rb - 0.002, 0.03), (rb - 0.012, h - 0.04), (0.05, h - 0.03), (0, h - 0.03)], WAY, name="kettle_body", segs=24)
    lathe([(0, h - 0.032), (0.05, h - 0.032), (0.045, h - 0.012), (0, h - 0.012)], WAY, name="kettle_lid", segs=20)
    cyl(0.012, 0.012, (0, 0, h - 0.006), "dark", "Z", 12, name="lid_knob")
    box((0.03, 0.02, 0.13), (0, -rb + 0.004, 0.11), "glass", 0.006, rot=(0.04, 0, 0), name="water_window")
    # handle on +X, spout on -X
    hx = w / 2 - 0.012
    bar((rb - 0.02, 0, h - 0.045), (hx, 0, h - 0.06), 0.024, 0.026, "dark", name="kettle_handle", bevel=0.008)
    bar((hx, 0, h - 0.06), (hx - 0.012, 0, 0.06), 0.024, 0.026, "dark", name="kettle_handle", bevel=0.008)
    bar((hx - 0.012, 0, 0.06), (rb - 0.02, 0, 0.05), 0.02, 0.026, "dark", name="kettle_handle", bevel=0.008)
    box((0.02, 0.016, 0.01), (hx - 0.004, 0, h - 0.05), "white", 0.003, name="kettle_switch")
    cyl(0.022, 0.05, (-w / 2 + 0.03, 0, h - 0.06), WAY, rot=(0, -math.pi / 2 + 0.5, 0), r2=0.012, name="spout", verts=14)


FONT = {
    "R": ["XX.", "X.X", "XX.", "X.X", "X.X"], "E": ["XXX", "X..", "XX.", "X..", "XXX"],
    "C": [".XX", "X..", "X..", "X..", ".XX"], "P": ["XX.", "X.X", "XX.", "X..", "X.."],
    "T": ["XXX", ".X.", ".X.", ".X.", ".X."], "I": ["XXX", ".X.", ".X.", ".X.", "XXX"],
    "O": [".X.", "X.X", "X.X", "X.X", ".X."], "N": ["X..X", "XX.X", "X.XX", "X..X", "X..X"],
}


def pixel_text(text, cx, z0, px, face_y, t, tilt, pivot, color):
    """Brass pixel letters on a plane leaning back by `tilt` (top toward +Y) about pivot."""
    widths = [len(FONT[c][0]) for c in text]
    total = sum(widths) + len(text) - 1
    x = cx - total * px / 2
    for c, wdt in zip(text, widths):
        rows = FONT[c]
        for r, row in enumerate(rows):
            j = 0
            while j < wdt:
                if row[j] == "X":
                    k = j
                    while k < wdt and row[k] == "X":
                        k += 1
                    px0 = x + j * px
                    zz = z0 + (4 - r) * px + px / 2
                    p = rotX(((px0 + (px0 + (k - j) * px)) / 2, face_y - t / 2, zz), -tilt, pivot)
                    box(((k - j) * px * 0.96, t, px * 0.96), p, color, 0.0006, rot=(-tilt, 0, 0), name="letter")
                    j = k
                else:
                    j += 1
        x += (wdt + 1) * px


def reception_sign(w, d, h):
    # desk reception sign: 'way' (black) plaque leaning back on a walnut base, brass pixel lettering 'RECEPTION', steel standoffs
    tilt = 0.24
    bh = 0.026
    box((w, d, bh), (0, 0, bh / 2), "walnut", 0.006, name="sign_base")
    L = (h - bh + 0.006) / math.cos(tilt) - 0.012 * math.sin(tilt) + 0.0036
    th = 0.012
    pivot = (0, -0.022, bh - 0.006)
    c = rotX((0, pivot[1] + th / 2, pivot[2] + L / 2), -tilt, pivot)
    box((w - 0.004, th, L), c, WAY, 0.003, rot=(-tilt, 0, 0), name="plaque")
    box((w - 0.02, 0.012, 0.012), (0, -0.022 - 0.004, bh + 0.002), "walnut", 0.003, name="plaque_slot")
    pixel_text("RECEPTION", 0, pivot[2] + L / 2 - 2.5 * 0.0098, 0.0098, pivot[1], 0.003, tilt, pivot, "brass")
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        for zz in (0.025, L - 0.02):
            p = rotX((x, pivot[1] - 0.001, pivot[2] + zz), -tilt, pivot)
            cyl(0.005, 0.003, p, "steel", rot=(math.pi / 2 - tilt, 0, 0), name="standoff", verts=10)
    box((w - 0.06, 0.003, 0.005), (0, -d / 2 + 0.001, bh * 0.5), "brass", 0.001, name="base_inlay")


def projector(w, d, h):
    # office projector: 'way' (black) body, grey top panel, dark lens barrel with glass lens and steel focus ring, dark vents, white buttons
    fh = 0.012
    loft(rrect(w, d - 0.004, 0.03, 4, cy=0.002), rrect(w - 0.01, d - 0.014, 0.026, 4, cy=0.002), fh, h - 0.004, WAY, name="projector_body", bevel=0.004)
    loft(rrect(w - 0.06, d - 0.06, 0.02, 3), rrect(w - 0.062, d - 0.062, 0.02, 3), h - 0.006, h, "grey", name="top_panel")
    for x in (-w / 2 + 0.04, w / 2 - 0.04):
        for y in (-d / 2 + 0.04, d / 2 - 0.04):
            cyl(0.012, fh, (x, y, fh / 2), "dark", "Z", 10, name="foot")
    lx = -0.075
    zc = fh + (h - fh) / 2 - 0.004
    cyl(0.032, 0.012, (lx, -d / 2 + 0.006, zc), "dark", "Y", 20, bevel=0.003, name="lens")
    cyl(0.03, 0.004, (lx, -d / 2 + 0.002, zc), "steel", "Y", 20, name="focus_ring")
    cyl(0.022, 0.004, (lx, -d / 2 + 0.0025, zc), "glass", "Y", 18, name="lens")
    for k in range(5):
        box((0.004, 0.003, 0.05), (0.04 + k * 0.012, -d / 2 + 0.006, zc), "dark", 0.0, name="vent")
    for k in range(3):
        cyl(0.007, 0.004, (0.06 + k * 0.022, 0.03, h - 0.002), "white", "Z", 10, name="button")
    cyl(0.004, 0.003, (0.12, -0.08, h - 0.0015), "green", "Z", 8, name="power_led")


def _rtri(w, d, rc, n=6):
    pts = []
    for i, ang in enumerate((90, 210, 330)):
        a = math.radians(ang)
        cx, cy = math.cos(a) * (0.5 - rc), math.sin(a) * (0.5 - rc)
        for k in range(n + 1):
            b = math.radians(ang - 60 + 120 * k / n)
            pts.append((cx + rc * math.cos(b), cy + rc * math.sin(b)))
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    sx, sy = w / (max(xs) - min(xs)), d / (max(ys) - min(ys))
    oy = (max(ys) + min(ys)) / 2
    return [(x * sx, (y - oy) * sy) for x, y in pts]


def office_speaker(w, d, h):
    # conference speakerphone: rounded-triangle 'way' (black) body, dark grille top, grey side band, green LED bar at the front edge, white keys
    base = _rtri(w, d, 0.16)
    top = _rtri(w - 0.012, d - 0.012, 0.16)
    loft(base, base, 0.0, 0.012, "grey", name="side_band")
    loft(base, top, 0.012, h - 0.006, WAY, name="speaker_body")
    inner = _rtri(w - 0.05, d - 0.05, 0.16)
    loft(inner, inner, h - 0.0065, h, "dark", name="grille")
    yf = min(p[1] for p in base)
    box((0.09, 0.004, 0.006), (0, yf + 0.004, h - 0.024), "green", 0.001, rot=(-0.3, 0, 0), name="led_bar")
    for x in (-0.03, 0, 0.03):
        cyl(0.008, 0.003, (x, yf + 0.04, h - 0.0015), "white", "Z", 10, name="key")


def stapler_set(w, d, h):
    # stapler and hole punch: 'way' (black) stapler with steel base, grey punch with black lever and steel paper guide, red staple pack
    # stapler along X at the front-left
    sx0, sx1 = -w / 2, 0.035
    sy = -0.028
    L = sx1 - sx0
    box((L, 0.04, 0.012), ((sx0 + sx1) / 2, sy, 0.006), "steel", 0.004, name="stapler_base")
    box((L - 0.004, 0.034, 0.024), ((sx0 + sx1) / 2 + 0.002, sy, 0.03), WAY, 0.008, rot=(0, 0.05, 0), name="stapler_arm")
    cyl(0.008, 0.042, (sx1 - 0.012, sy, 0.02), WAY, "Y", 12, name="stapler_hinge")
    # hole punch on the right
    px0, px1 = 0.045, w / 2
    pc = (px0 + px1) / 2
    pw = px1 - px0
    box((pw, 0.108, 0.022), (pc, 0.006, 0.011), "grey", 0.006, name="punch_body")
    for x in (pc - 0.018, pc + 0.018):
        cyl(0.008, 0.036, (x, 0.012, 0.036), "steel", "Z", 12, name="punch_post")
    bar((pc, 0.05, 0.035), (pc, -0.045, h - 0.0042), pw - 0.006, 0.012, WAY, name="punch_lever", bevel=0.006)
    box((pw - 0.01, 0.006, 0.014), (pc, -d / 2 + 0.003, 0.018), "steel", 0.002, name="paper_guide")
    box((0.06, 0.024, 0.016), (-0.05, 0.035, 0.008), "red", 0.003, name="staple_pack")
    box((0.04, 0.003, 0.01), (-0.05, 0.022, 0.008), "white", 0.001, name="staple_label")


def dispatch_scale(w, d, h):
    # parcel scale: 'way' (black) base with front console, teal display, white keys, steel weigh platform, kraft parcel with pine tape and cream label
    box((w, d, 0.03), (0, 0, 0.015), WAY, 0.008, name="scale_base")
    box((w, 0.06, 0.022), (0, -d / 2 + 0.03, 0.03 + 0.011), WAY, 0.006, rot=(0.0, 0, 0), name="scale_console")
    box((0.1, 0.004, 0.016), (-0.05, -d / 2 + 0.002, 0.038), "teal", 0.001, name="display")
    for k in range(3):
        cyl(0.007, 0.004, (0.04 + k * 0.03, -d / 2 + 0.03, 0.052 + 0.002), "white", "Z", 10, name="key")
    box((w - 0.02, d - 0.08, 0.008), (0, 0.035, 0.034), "steel", 0.003, name="weigh_platform")
    ph = h - 0.038 - 0.0035
    box((0.2, 0.16, ph), (0.0, 0.035, 0.038 + ph / 2), "kraft", 0.004, rot=(0, 0, 0.08), name="parcel")
    box((0.205, 0.04, ph + 0.003), (0.0, 0.035, 0.038 + ph / 2), "pine", 0.001, rot=(0, 0, 0.08), name="parcel_tape")
    box((0.06, 0.04, 0.003), (-0.06, 0.0, h - 0.001), "cream", 0.001, rot=(0, 0, 0.08), name="parcel_label")


def globe_office(w, d, h):
    # office desk globe: 'way' (antique -> kraft) sphere with sage land, brass meridian, dark round stand and stem
    gr = w / 2 - 0.003
    mr = gr + 0.0025
    zc = h - mr - 0.004
    tilt = math.radians(23)
    sphere(gr, (0, 0, zc), WAY, name="globe", rot=(0, tilt, 0))
    lands = [((0.3, -0.9, 0.3), 0.05), ((-0.5, -0.7, -0.2), 0.042), ((0.1, -0.8, -0.55), 0.038), ((0.8, -0.3, 0.45), 0.042),
             ((-0.2, -0.6, 0.7), 0.034), ((-0.9, 0.2, 0.1), 0.05), ((0.6, 0.6, -0.3), 0.046), ((-0.3, 0.8, 0.4), 0.042)]
    for (x, y, z), r in lands:
        v = Vector((x, y, z)).normalized()
        p = Vector((0, 0, zc)) + v * (gr - 0.005)
        o = sphere(r, p, "sage", scale=(1.0, 0.7, 0.12), name="land")
        _orient(o, v)
    torus(mr, 0.003, (0, 0, zc), "brass", rot=(math.pi / 2, tilt, 0), name="meridian", seg=32)
    cyl(0.008, 0.02, (math.sin(tilt) * (gr + 0.006), 0, zc + math.cos(tilt) * (gr + 0.006)), "brass", "Z", 8, rot=(0, tilt, 0), name="pivot")
    cyl(0.085, 0.02, (0, 0, 0.01), "dark", "Z", 24, bevel=0.006, name="stand_base")
    cyl(0.025, 0.016, (0, 0, 0.028), "dark", "Z", 14, bevel=0.004, name="stand_collar")
    s0 = 0.036
    s1 = zc - gr + 0.006
    cyl(0.01, s1 - s0, (0, 0, (s0 + s1) / 2), "brass", "Z", 10, name="stand_stem")


def desk_calendar(w, d, h):
    # tent desk calendar: card A-frame, 'way' (blue) header strip, cream month page with dark date grid and red marked date, steel rings
    t = 0.004
    ang = math.atan((d / 2 - 0.0015) / (h - 0.004))
    L = (h - 0.004) / math.cos(ang)
    for s in (-1, 1):
        c = (0, s * (d / 2 - 0.0015) / 2, (h - 0.004) / 2)
        box((w, t, L), c, "card", 0.001, rot=(s * ang, 0, 0), name="calendar_board")
    # front page on the -Y face
    fy0 = -(d / 2 - 0.004) / 2
    n = (0, -math.cos(ang), math.sin(ang) * 0 - 0)
    def on_front(u, v, off):
        # u across X, v along the slope from the bottom (0) to top (L)
        y = -(d / 2 - 0.0015) + v * math.sin(ang) - off * math.cos(ang)
        z = v * math.cos(ang) + off * math.sin(ang)
        return (u, y, z)
    box((w - 0.012, 0.002, L - 0.03), on_front(0, (L - 0.03) / 2 + 0.006, t / 2 + 0.001), "cream", 0.0005, rot=(-ang, 0, 0), name="page")
    box((w - 0.012, 0.003, 0.026), on_front(0, L - 0.037, t / 2 + 0.002), WAY, 0.0008, rot=(-ang, 0, 0), name="calendar_header")
    for r in range(4):
        for c in range(7):
            col = "red" if (r, c) == (1, 4) else "dark"
            box((0.012, 0.0016, 0.008), on_front(-0.069 + c * 0.023, 0.02 + (3 - r) * 0.018, t / 2 + 0.002), col, 0.0, rot=(-ang, 0, 0), name="date_cell")
    for x in (-0.06, -0.02, 0.02, 0.06):
        torus(0.006, 0.0016, on_front(x, L - 0.006, t / 2 + 0.001), "steel", rot=(0, math.pi / 2, 0), name="ring", seg=12)


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
