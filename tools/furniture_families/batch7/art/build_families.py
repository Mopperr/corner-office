"""Build Corner Office catalogue-family GLBs (batch 7), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 7 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch7
MINE = ["labelled_box", "tent_bag", "push_mower", "compost_bin", "step_ladder", "metal_shelving", "pegboard", "fishing_rods", "generator", "coat_rack_office"]
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
def labelled_box(w, d, h):
    # cardboard storage carton: 'way' (kraft) carton and lid flaps, pine parcel tape, cream label with dark marker writing, hand holes
    cw, cd, ch = w - 0.004, d - 0.008, h - 0.006
    box((cw, cd, ch), (0, 0, ch / 2), WAY, 0.006, name="carton")
    for s in (-1, 1):
        box((cw - 0.004, cd / 2 - 0.003, 0.006), (0, s * (cd / 4 + 0.0005), h - 0.003), WAY, 0.002, name="flap")
    box((0.06, cd + 0.002, 0.0016), (0, 0, h - 0.0002), "pine", 0.0, name="tape")
    for s in (-1, 1):
        box((0.06, 0.0016, 0.09), (0, s * (cd / 2 + 0.0008), h - 0.045), "pine", 0.0, name="tape")
    fy = -cd / 2
    box((0.2, 0.002, 0.12), (0.03, fy - 0.001, h * 0.48), "cream", 0.0, name="label")
    for k, L in enumerate((0.15, 0.11, 0.13)):
        box((L, 0.002, 0.014), (0.03 - (0.15 - L) / 2, fy - 0.003, h * 0.48 + 0.035 - k * 0.032), "dark", 0.0, name="writing")
    for s in (-1, 1):
        box((0.002, 0.11, 0.032), (s * (w / 2 - 0.001), 0, h * 0.72), "dark", 0.0, name="hand_hole")


def tent_bag(w, d, h):
    # tent in a stuff sack: 'way' sack lying along X, cinched drawstring end with toggle, dark end cap and compression bands, carry handle, cream logo
    R = d / 2 - 0.007
    zc = h / 2
    x0, x1 = -w / 2 + 0.01, w / 2 - 0.07
    cyl(R, x1 - x0, ((x0 + x1) / 2, 0, zc), WAY, "X", 20, bevel=0.01, name="sack")
    cyl(R - 0.004, 0.01, (x0 - 0.005, 0, zc), "dark", "X", 20, bevel=0.003, name="end_cap")
    cyl(R, 0.045, (x1 + 0.0225, 0, zc), WAY, "X", 20, r2=0.045, name="cinch", rot=(0, math.pi / 2, 0))
    cyl(0.03, 0.012, (x1 + 0.051, 0, zc), WAY, "X", 12, name="cinch_neck")
    rod((x1 + 0.055, 0, zc), (w / 2 - 0.012, 0.0, zc - 0.02), 0.004, "dark", name="cord")
    sphere(0.012, (w / 2 - 0.012, 0, zc - 0.022), "mustard", scale=(1, 1, 1.3), name="toggle")
    for x in (-0.17, 0.12):
        torus(R + 0.0015, 0.0055, (x, 0, zc), "dark", rot=(0, math.pi / 2, 0), name="band")
    box((0.22, 0.04, 0.008), (-0.025, 0, h - 0.009), "dark", 0.003, name="handle")
    for x in (-0.13, 0.08):
        box((0.02, 0.042, 0.012), (x, 0, h - 0.012), "dark", 0.003, name="handle")
    box((0.11, 0.004, 0.045), (-0.03, -R - 0.0005, zc + 0.01), "cream", 0.001, name="logo")
    box((0.07, 0.003, 0.012), (-0.03, -R - 0.002, zc + 0.012), "mustard", 0.0, name="logo_mark")


def push_mower(w, d, h):
    # petrol push mower facing -Y: 'way' deck, dark engine and wheels, steel handle, grey grass bag, mustard fuel cap
    box((0.42, 0.48, 0.12), (0, -0.2, 0.11), WAY, 0.03, name="deck")
    box((0.4, 0.012, 0.04), (0, -d / 2 + 0.006, 0.08), "dark", 0.004, name="bumper")
    cyl(0.11, 0.1, (0, -0.22, 0.22), "dark", "Z", 18, bevel=0.012, name="engine")
    cyl(0.085, 0.05, (0, -0.22, 0.29), WAY, "Z", 18, bevel=0.012, name="engine_cover")
    cyl(0.018, 0.02, (0.06, -0.3, 0.32), "mustard", "Z", 10, bevel=0.004, name="fuel_cap")
    cyl(0.03, 0.03, (-0.06, -0.17, 0.33), "steel", "Z", 10, bevel=0.005, name="air_filter")
    for y in (-0.35, 0.0):
        for s in (-1, 1):
            cyl(0.09, 0.045, (s * (w / 2 - 0.0225), y, 0.09), "dark", "X", 18, bevel=0.01, name="wheel")
            cyl(0.04, 0.05, (s * (w / 2 - 0.025), y, 0.09), "steel", "X", 12, name="hub")
    box((0.36, 0.3, 0.26), (0, 0.2, 0.25), "grey", 0.03, name="grass_bag")
    box((0.37, 0.02, 0.27), (0, 0.06, 0.25), "dark", 0.006, name="bag_frame")
    gy, gz = d / 2 - 0.018, h - 0.018
    for s in (-1, 1):
        rod((s * 0.2, 0.02, 0.17), (s * 0.2, gy, gz), 0.014, "steel", name="handle_bar")
    rod((-0.2, gy, gz), (0.2, gy, gz), 0.014, "steel", name="handle_bar")
    cyl(0.018, 0.28, (0, gy, gz), "dark", "X", 12, name="grip")
    rod((-0.19, gy - 0.05, gz - 0.06), (0.19, gy - 0.05, gz - 0.06), 0.008, "dark", name="bail_bar")
    rod((0.14, 0.2, 0.5), (0.14, 0.12, 0.42), 0.004, "dark", name="pull_cord")


def compost_bin(w, d, h):
    # dalek-style compost bin: 'way' tapered body with ribs and domed lid, grey hatch frame, green leaf badge
    R0 = w / 2
    def r_at(z):
        return R0 - 0.003 - 0.045 * (z - 0.02) / 0.68
    lathe([(0, 0), (R0, 0), (R0, 0.02), (r_at(0.7), 0.7), (0, 0.7)], WAY, name="bin_body", segs=24, smooth=False)
    lathe([(r_at(0.7) + 0.008, 0.69), (r_at(0.7) + 0.008, 0.715), (r_at(0.7) - 0.02, 0.745), (0.15, 0.775), (0, 0.782)], WAY, name="lid", segs=24, smooth=False)
    box((0.14, 0.035, 0.018), (0, 0, h - 0.009), "grey", 0.006, name="lid_handle")
    for z in (0.22, 0.42, 0.6):
        torus(r_at(z) - 0.001, 0.007, (0, 0, z), WAY, name="rib", seg=24)
    t = -math.atan(0.045 / 0.68)
    zc = 0.15
    ry = -r_at(zc)
    box((0.27, 0.012, 0.21), (0, ry - 0.001, zc), "grey", 0.004, rot=(t, 0, 0), name="hatch_frame")
    box((0.23, 0.012, 0.17), (0, ry - 0.003, zc), WAY, 0.004, rot=(t, 0, 0), name="hatch")
    box((0.07, 0.008, 0.022), (0, ry - 0.008, zc + 0.05), "grey", 0.003, rot=(t, 0, 0), name="hatch_pull")
    zl = 0.5
    o = sphere(0.035, (0, -r_at(zl) - 0.001, zl), "green", scale=(1, 0.1, 1.5), name="leaf_badge", rot=(0, 0.5, 0))


def step_ladder(w, d, h):
    # aluminium step ladder: 'way' (aluminium steel) stiles, treads and rear legs, dark feet and hinges, red tool shelf cap, grey tread grips
    fb, ft = -d / 2 + 0.03, -0.07   # front stile y at bottom / top
    rb, rt = d / 2 - 0.03, 0.07
    z0, z1 = 0.03, h - 0.08
    sx = w / 2 - 0.025
    for s in (-1, 1):
        bar((s * sx, fb, z0), (s * sx, ft, z1), 0.03, 0.07, WAY, name="stile")
        bar((s * (sx - 0.01), rb, z0), (s * (sx - 0.01), rt, z1 - 0.02), 0.03, 0.045, WAY, name="rear_leg")
        box((0.05, 0.06, 0.03), (s * sx, -d / 2 + 0.03, 0.015), "dark", 0.006, name="foot")
        box((0.045, 0.05, 0.03), (s * (sx - 0.01), d / 2 - 0.025, 0.015), "dark", 0.006, name="foot")
        bar((s * (sx + 0.005), fb + (ft - fb) * 0.45, z0 + (z1 - z0) * 0.45), (s * (sx + 0.005), rb + (rt - rb) * 0.45, z0 + (z1 - z0) * 0.45), 0.01, 0.02, "dark", name="spreader")
        cyl(0.016, 0.03, (s * (sx + 0.01), 0.0, z1 - 0.005), "dark", "X", 12, name="hinge")
    for k in range(3):
        f = (k + 1) / 4.0
        z = z0 + (z1 - z0) * f
        y = fb + (ft - fb) * f
        box((2 * sx - 0.03, 0.11, 0.025), (0, y - 0.01, z), WAY, 0.004, name="tread")
        for g in (-1, 0, 1):
            box((2 * sx - 0.06, 0.012, 0.003), (0, y - 0.01 + g * 0.03, z + 0.0135), "grey", 0.0, name="tread_grip")
    for f in (0.3, 0.65):
        z = z0 + (z1 - z0) * f
        y = rb + (rt - rb) * f
        bar((-(sx - 0.01), y, z), ((sx - 0.01), y, z), 0.02, 0.025, WAY, name="rear_rung")
    box((w - 0.02, 0.22, 0.07), (0, 0.0, h - 0.035), "red", 0.02, name="tool_shelf")
    box((w - 0.08, 0.15, 0.012), (0, -0.01, h - 0.002), "dark", 0.004, name="shelf_well")


def metal_shelving(w, d, h):
    # five-shelf metal racking: 'way' angle posts and shelf lips, pine boards, kraft cartons, red and blue paint tins, steel feet
    t = 0.004
    a = 0.038
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * (w / 2 - a / 2), sy * (d / 2 - a / 2)
            box((a, t, h - 0.012), (x, sy * (d / 2 - t / 2), 0.012 + (h - 0.012) / 2), WAY, 0.001, name="post")
            box((t, a, h - 0.012), (sx * (w / 2 - t / 2), y, 0.012 + (h - 0.012) / 2), WAY, 0.001, name="post")
            box((a, a, 0.012), (x, y, 0.006), "steel", 0.003, name="foot")
            for z in (0.25, 0.65, 1.05, 1.45):
                cyl(0.004, 0.003, (sx * (w / 2 - 0.019), sy * (d / 2 + 0.0005) if sy < 0 else sy * (d / 2 - 0.0035), z), "steel", "Y", 8, name="bolt")
    zs = (0.12, 0.52, 0.92, 1.32, h - 0.05)
    for z in zs:
        box((w - 0.03, d - 0.03, 0.018), (0, 0, z), "pine", 0.003, name="shelf_board")
        box((w - 0.012, 0.012, 0.04), (0, -d / 2 + 0.008, z - 0.002), WAY, 0.002, name="front_lip")
        box((w - 0.012, 0.012, 0.04), (0, d / 2 - 0.008, z - 0.002), WAY, 0.002, name="back_lip")
        for s in (-1, 1):
            box((0.012, d - 0.012, 0.04), (s * (w / 2 - 0.008), 0, z - 0.002), WAY, 0.002, name="side_lip")
    s0 = zs[0] + 0.009
    box((0.36, 0.3, 0.24), (-0.2, 0.01, s0 + 0.12), "kraft", 0.006, name="carton")
    box((0.3, 0.28, 0.2), (0.21, 0.02, s0 + 0.1), "kraft", 0.006, name="carton")
    box((0.06, 0.282, 0.0016), (0.21, 0.02, s0 + 0.2), "pine", 0.0, name="parcel_tape")
    s1 = zs[1] + 0.009
    for i, (x, col) in enumerate(((-0.3, "red"), (-0.13, "red"), (0.04, "blue"))):
        cyl(0.075, 0.16, (x, 0.0, s1 + 0.08), col, "Z", 18, bevel=0.006, name="paint_tin")
        cyl(0.07, 0.006, (x, 0.0, s1 + 0.163), "steel", "Z", 18, name="tin_lid")
        box((0.08, 0.002, 0.07), (x, -0.0755, s1 + 0.08), "cream", 0.0, name="tin_label")
    box((0.22, 0.3, 0.17), (0.28, 0.0, s1 + 0.085), "blue", 0.01, name="storage_crate")
    s2 = zs[2] + 0.009
    box((0.4, 0.3, 0.26), (-0.18, 0.0, s2 + 0.13), "kraft", 0.006, name="carton")
    s3 = zs[3] + 0.009
    for k in range(3):
        cyl(0.05, 0.3, (0.12 + k * 0.105, 0.0, s3 + 0.05), "steel" if k == 1 else "kraft", "Y", 14, name="roll")


def pegboard(w, d, h):
    # wall pegboard: 'way' (kraft) perforated board on walnut battens, steel hooks with hammer, screwdrivers, spanners and a mustard tape measure; back toward +Y
    for z in (0.08, h - 0.08):
        box((w - 0.04, 0.006, 0.05), (0, d / 2 - 0.003, z), "walnut", 0.002, name="batten")
    box((w, 0.008, h), (0, d / 2 - 0.01, h / 2), WAY, 0.002, name="board")
    fy = d / 2 - 0.014
    for i in range(15):
        for j in range(11):
            cyl(0.0045, 0.002, (-0.35 + i * 0.05, fy - 0.0005, 0.05 + j * 0.05), "dark", "Y", 8, name="hole")
    def hook(x, z):
        rod((x, fy, z), (x, fy - 0.025, z), 0.003, "steel", name="hook", verts=6)
    # hammer
    hook(-0.3, 0.45)
    box((0.026, 0.018, 0.22), (-0.3, fy - 0.012, 0.31), "walnut", 0.006, name="hammer_handle")
    box((0.11, 0.022, 0.032), (-0.3, fy - 0.012, 0.43), "steel", 0.006, name="hammer_head")
    # screwdrivers
    for x, col in ((-0.17, "red"), (-0.1, "mustard"), (-0.03, "red")):
        hook(x, 0.47)
        cyl(0.013, 0.09, (x, fy - 0.014, 0.43), col, "Z", 10, bevel=0.004, name="screwdriver")
        cyl(0.003, 0.13, (x, fy - 0.014, 0.32), "steel", "Z", 6, name="screwdriver_shaft")
    # spanners
    for k, L in enumerate((0.16, 0.19, 0.22)):
        x = 0.07 + k * 0.045
        hook(x, 0.47)
        box((0.018, 0.006, L), (x, fy - 0.012, 0.47 - L / 2), "steel", 0.002, name="spanner")
        torus(0.014, 0.005, (x, fy - 0.012, 0.47 - L), "steel", rot=(math.pi / 2, 0, 0), name="spanner")
    # tape measure and pliers
    hook(0.3, 0.42)
    cyl(0.045, 0.024, (0.3, fy - 0.014, 0.37), "mustard", "Y", 18, bevel=0.006, name="tape_measure")
    cyl(0.015, 0.026, (0.3, fy - 0.014, 0.37), "dark", "Y", 10, name="tape_measure")
    hook(0.25, 0.22)
    for s in (-1, 1):
        rod((0.25, fy - 0.012, 0.21), (0.25 + s * 0.03, fy - 0.012, 0.09), 0.007, "red", name="pliers")
    box((0.03, 0.008, 0.05), (0.25, fy - 0.012, 0.215), "steel", 0.003, name="pliers")
    hook(-0.2, 0.2)
    torus(0.045, 0.006, (-0.2, fy - 0.012, 0.15), "dark", rot=(math.pi / 2, 0, 0), name="cable_coil")


def fishing_rods(w, d, h):
    # three fishing rods on a walnut rod stand: 'way' (carbon black) blanks, kraft cork handles, steel reels to the front, red rod band
    box((w, d, 0.03), (0, 0, 0.015), "walnut", 0.008, name="rod_stand")
    rods = ((-0.042, 0.015, h), (0.0, 0.03, h - 0.06), (0.042, 0.015, h - 0.12))
    for x, y, top in rods:
        cyl(0.011, 0.02, (x, y, 0.04), "dark", "Z", 10, name="butt_cap")
        cyl(0.013, 0.3, (x, y, 0.2), "kraft", "Z", 12, bevel=0.003, name="cork_handle")
        cyl(0.0115, 0.06, (x, y, 0.38), "steel", "Z", 10, name="reel_seat")
        cyl(0.009, top - 0.41, (x, y, 0.41 + (top - 0.41) / 2), WAY, "Z", 8, r2=0.0022, name="blank")
        for k in range(5):
            z = 0.6 + k * (top - 0.7) / 5
            torus(0.006, 0.0015, (x, y - 0.009, z), "steel", rot=(math.pi / 2, 0, 0), name="guide", seg=8)
        rod((x, y - 0.01, 0.38), (x, y - 0.03, 0.38), 0.004, "steel", name="reel_foot")
        cyl(0.022, 0.026, (x, y - 0.03 - 0.0, 0.36), "steel", "X", 14, bevel=0.004, name="reel")
        cyl(0.012, 0.006, (x + 0.016, y - 0.03, 0.36), "dark", "X", 10, name="reel_handle")
    box((0.115, 0.06, 0.025), (0, 0.022, 0.62), "red", 0.008, name="rod_band")


def generator(w, d, h):
    # portable petrol generator: steel tube frame, 'way' fuel tank and housing, dark engine and recoil, cream control panel with red switch and dark sockets
    r = 0.015
    xr, yr = w / 2 - r, d / 2 - r
    zb, zt = 0.045, h - r
    for sy in (-1, 1):
        rod((-xr, sy * yr, zb), (xr, sy * yr, zb), r, "steel", name="frame")
        rod((-xr, sy * yr, zt), (xr, sy * yr, zt), r, "steel", name="frame")
        for sx in (-1, 1):
            rod((sx * xr, sy * yr, zb), (sx * xr, sy * yr, zt), r, "steel", name="frame")
            box((0.05, 0.05, 0.03), (sx * (xr - 0.03), sy * (yr - 0.01), 0.015), "dark", 0.006, name="foot")
    for sx in (-1, 1):
        rod((sx * xr, -yr, zb), (sx * xr, yr, zb), r, "steel", name="frame")
    box((0.3, 0.3, 0.24), (-0.1, 0.02, 0.18), "dark", 0.02, name="engine")
    box((0.5, 0.34, 0.13), (0, 0, 0.385), WAY, 0.04, name="fuel_tank")
    cyl(0.03, 0.025, (-0.12, 0.05, 0.46), "steel", "Z", 14, bevel=0.005, name="fuel_cap")
    box((0.2, 0.3, 0.22), (0.15, 0.02, 0.17), WAY, 0.02, name="alternator")
    fy = -yr + 0.02
    box((0.2, 0.012, 0.15), (0.15, -0.13, 0.17), "cream", 0.003, name="control_panel")
    for x in (0.1, 0.17):
        cyl(0.018, 0.01, (x, -0.141, 0.14), "dark", "Y", 12, name="socket")
    box((0.03, 0.012, 0.02), (0.22, -0.141, 0.21), "red", 0.003, name="switch")
    cyl(0.07, 0.02, (-0.1, -0.135, 0.18), "grey", "Y", 18, bevel=0.005, name="recoil")
    box((0.05, 0.02, 0.016), (-0.1, -0.15, 0.2), "dark", 0.004, name="recoil_pull")
    cyl(0.04, 0.2, (-0.05, 0.16, 0.12), "steel", "X", 14, bevel=0.006, name="muffler")


def coat_rack_office(w, d, h):
    # wall coat rack: 'way' (oak) backboard, five black double hooks, steel screws, red scarf on one hook; back toward +Y
    by = d / 2 - 0.0125
    box((w, 0.025, h), (0, by, h / 2), WAY, 0.006, name="backboard")
    fy = by - 0.0125
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        cyl(0.007, 0.003, (x, fy - 0.001, h / 2), "steel", "Y", 10, name="screw")
    for x in (-0.24, -0.12, 0.0, 0.12, 0.24):
        box((0.026, 0.006, 0.07), (x, fy - 0.003, 0.115), "dark", 0.002, name="hook_plate")
        arc_bar([(fy - 0.004, 0.135), (fy - 0.03, 0.15), (-0.035, 0.172)], 0.009, 0.01, "dark", name="hook", plane="YZ", offset=x)
        sphere(0.007, (x, -0.035, 0.176), "dark", name="hook")
        arc_bar([(fy - 0.004, 0.095), (fy - 0.035, 0.065), (-0.04, 0.05), (-0.042, 0.075)], 0.009, 0.01, "dark", name="hook", plane="YZ", offset=x)
        sphere(0.007, (x, -0.042, 0.08), "dark", name="hook")
    x = 0.12
    box((0.07, 0.012, 0.012), (x, -0.036, 0.048), "red", 0.004, name="scarf")
    box((0.06, 0.01, 0.045), (x - 0.012, -0.04, 0.025), "red", 0.004, rot=(0, 0.1, 0), name="scarf")
    box((0.055, 0.01, 0.04), (x + 0.014, -0.032, 0.022), "red", 0.004, rot=(0, -0.12, 0), name="scarf")
    for k in range(3):
        box((0.06, 0.002, 0.004), (x - 0.012, -0.0455, 0.012 + k * 0.012), "cream", 0.0, name="scarf_stripe")


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
