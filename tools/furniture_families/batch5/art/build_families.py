"""Build Corner Office catalogue-family GLBs (batch 5), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 5 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch5
MINE = ["radio_kitchen", "bath_shelf", "candles", "slippers", "sewing_box", "globe_v", "filing_cabinet", "office_plant", "low_cabinet", "garden_bench"]
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
WAY_ALIAS = {"painted white": "white", "painted sage": "sage", "tan": "kraft", "wicker": "kraft", "off": "dark", "brown": "walnut", "antique": "kraft", "cast iron": "black"}
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


def radio_kitchen(w, d, h):
    # retro kitchen radio: 'way' cabinet, cream grille with dark slots, dial window, cream knobs, carry handle
    bh = h - 0.03
    box((w, d - 0.014, bh - 0.008), (0, 0.007, 0.008 + (bh - 0.008) / 2), WAY, 0.014, name="radio_body")
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        box((0.03, 0.05, 0.008), (x, 0.0, 0.004), "dark", 0.002, name="foot")
    fy = -d / 2 + 0.012
    box((0.11, 0.004, 0.08), (-0.05, fy, 0.008 + bh / 2), "cream", 0.004, name="grille")
    for k in range(6):
        box((0.09, 0.003, 0.004), (-0.05, fy - 0.0025, 0.008 + bh / 2 - 0.03 + k * 0.012), "dark", 0.0, name="grille_slot")
    box((0.08, 0.004, 0.03), (0.065, fy, 0.008 + bh / 2 + 0.018), "glass", 0.003, name="dial_window")
    for k in range(5):
        box((0.0015, 0.003, 0.01), (0.035 + k * 0.015, fy - 0.0025, 0.008 + bh / 2 + 0.018), "dark", 0.0, name="dial_tick")
    box((0.002, 0.003, 0.024), (0.07, fy - 0.003, 0.008 + bh / 2 + 0.018), "red", 0.0, name="dial_needle")
    for x in (0.045, 0.085):
        cyl(0.012, 0.012, (x, fy - 0.006, 0.008 + bh / 2 - 0.022), "cream", "Y", 14, bevel=0.003, name="knob")
    pts = [(-0.07, bh - 0.006), (-0.065, h - 0.008), (0.0, h - 0.006), (0.065, h - 0.008), (0.07, bh - 0.006)]
    arc_bar([(x, z) for x, z in pts], 0.012, 0.016, "dark", name="handle", plane="XZ", offset=0.01, bevel=0.004)


def bath_shelf(w, d, h):
    # wall-hung bath shelf: 'way' glass plate on steel brackets with a front gallery rail; bottles on it; back toward +Y
    sz = 0.13
    pt = 0.012
    box((w, d - 0.01, pt), (0, -0.005, sz), WAY, 0.003, name="shelf")
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        box((0.03, 0.008, sz + 0.03), (x, d / 2 - 0.004, (sz + 0.03) / 2), "steel", 0.003, name="wall_plate")
        arc_bar([(d / 2 - 0.008, sz - 0.08), (d / 2 - 0.06, sz - 0.03), (-d / 2 + 0.03, sz - pt / 2)], 0.01, 0.012, "steel", name="bracket", plane="YZ", offset=x, bevel=0.002)
        cyl(0.004, 0.04, (x, -d / 2 + 0.008, sz + 0.02), "steel", "Z", 8, name="rail_post")
    cyl(0.005, w - 0.12, (0, -d / 2 + 0.008, sz + 0.04), "steel", "X", 10, name="rail")
    z0 = sz + pt / 2
    for x, r, bh, col, cap in ((-0.18, 0.026, 0.09, "sage", "cream"), (-0.12, 0.022, 0.07, "blue", "dark"), (0.1, 0.03, 0.06, "cream", "steel"), (0.17, 0.02, h - z0 - 0.02, "rose", "cream")):
        cyl(r, bh, (x, 0.01, z0 + bh / 2), col, "Z", 16, bevel=0.006, name="bottle")
        cyl(r * 0.45, 0.02 if bh > 0.065 else 0.012, (x, 0.01, z0 + bh + (0.01 if bh > 0.065 else 0.006)), cap, "Z", 12, bevel=0.002, name="cap")
    sphere(0.03, (0.0, 0.0, z0 + 0.015), "cream", scale=(1.2, 0.8, 0.5), name="soap_bar")


def candles(w, d, h):
    # three pillar candles in 'way' on an oval brass dish, dark wicks, mustard flames
    cyl(0.1, 0.012, (0, 0, 0.006), "brass", "Z", 24, bevel=0.004, name="dish")
    _mats  # noqa
    o = [ob for ob in bpy.context.scene.objects if ob.name.startswith("dish")][-1]
    o.scale = (w / 0.2, d / 0.2, 1)
    for x, y, r, ch in ((-0.055, 0.005, 0.032, 0.085), (0.015, -0.01, 0.028, 0.06), (0.068, 0.01, 0.024, 0.045)):
        cyl(r, ch, (x, y, 0.012 + ch / 2), WAY, "Z", 18, bevel=0.005, name="candle")
        cyl(r - 0.006, 0.002, (x, y, 0.012 + ch), "cream", "Z", 16, name="candle_pool")
        cyl(0.0018, 0.008, (x, y, 0.012 + ch + 0.004), "dark", "Z", 6, name="wick")
        sphere(0.0065, (x, y, 0.012 + ch + 0.013), "mustard", scale=(1, 1, 1.9), name="flame")


def slippers(w, d, h):
    # pair of mule slippers side by side, toes toward -X... toes to -X; 'way' uppers, cream soles and pom-poms
    L = w - 0.01
    for y, dx, rz in ((-0.026, 0.005, 0.03), (0.028, -0.005, -0.03)):
        c, s = math.cos(rz), math.sin(rz)
        def P(x, yy, z):
            return (x * c - yy * s + dx, x * s + yy * c + y, z)
        sphere(0.5, P(0, 0, 0.011), "kraft", scale=(L, 0.063, 0.022), rot=(0, 0, rz), name="sole")
        sphere(0.5, P(0, 0, 0.017), "cream", scale=(L - 0.01, 0.055, 0.014), rot=(0, 0, rz), name="footbed")
        sphere(0.5, P(-0.04, 0, 0.016), WAY, scale=(0.17, 0.064, 0.064), rot=(0, 0, rz), name="upper")
        sphere(0.5, P(-0.03, 0, 0.022), "dark", scale=(0.05, 0.04, 0.05), rot=(0, 0, rz), name="foot_opening") if False else None
        sphere(0.5, P(0.035, 0, 0.022), "cream", scale=(0.03, 0.05, 0.004), rot=(0, 0, rz), name="lining")
        sphere(0.014, P(-0.075, 0, 0.048), "cream", name="pompom")


def sewing_box(w, d, h):
    # sewing box: 'way' case and lid, cream lid band, brass clasp and corners; pincushion and thread spools on the lid
    bh = 0.13
    lh = 0.035
    box((w - 0.008, d - 0.008, bh), (0, 0, bh / 2), WAY, 0.01, name="sewing_case")
    box((w, d, lh), (0, 0, bh + lh / 2), WAY, 0.01, name="lid")
    box((w + 0.001, d + 0.001, 0.008), (0, 0, bh + 0.012), "cream", 0.002, name="lid_band")
    box((0.03, 0.006, 0.04), (0, -d / 2 + 0.001, bh - 0.005), "brass", 0.002, name="clasp")
    for x in (-w / 2 + 0.06, w / 2 - 0.06):
        cyl(0.006, 0.04, (x, d / 2 - 0.002, bh), "brass", "X", 8, name="hinge")
    for x in (-1, 1):
        for y in (-1, 1):
            box((0.02, 0.02, 0.01), (x * (w / 2 - 0.012), y * (d / 2 - 0.012), 0.005), "brass", 0.003, name="foot")
    zt = bh + lh
    sphere(0.035, (-0.07, 0.01, zt + 0.012), "red", scale=(1, 1, 0.55), name="pincushion")
    for k, (dx, dy) in enumerate(((-0.01, 0.0), (0.012, 0.008), (0.0, -0.012))):
        cyl(0.0012, 0.02, (-0.07 + dx, 0.01 + dy, zt + 0.026), "steel", "Z", 5, rot=(dx * 20, dy * 20, 0), name="pin")
        sphere(0.0035, (-0.07 + dx * 1.2, 0.01 + dy * 1.2, zt + 0.036), ("mustard", "cream", "red")[k], name="pin_head")
    for x, y, col in ((0.03, -0.03, "mustard"), (0.075, 0.02, "red"), (0.11, -0.04, "cream")):
        cyl(0.017, 0.03, (x, y, zt + 0.015), col, "Z", 14, bevel=0.003, name="thread")
        for z in (zt + 0.002, zt + 0.028):
            cyl(0.02, 0.004, (x, y, z), "pine", "Z", 14, name="spool_end")
    box((0.09, 0.012, 0.004), (0.0, 0.06, zt + 0.002), "mustard", 0.0, rot=(0, 0, 0.3), name="tape_measure")


def globe_v(w, d, h):
    # antique desk globe: 'way' (antique kraft) sphere with sage land patches, brass meridian, walnut stand
    gr = 0.155
    mr = 0.157
    zc = h - mr - 0.006
    tilt = math.radians(23)
    sphere(gr, (0, 0, zc), WAY, name="globe", rot=(0, tilt, 0))
    lands = [((0.3, -0.9, 0.3), 0.06), ((-0.5, -0.7, -0.2), 0.05), ((0.1, -0.8, -0.55), 0.045), ((0.8, -0.3, 0.45), 0.05),
             ((-0.2, -0.6, 0.7), 0.04), ((-0.9, 0.2, 0.1), 0.06), ((0.6, 0.6, -0.3), 0.055), ((-0.3, 0.8, 0.4), 0.05)]
    for (x, y, z), r in lands:
        v = Vector((x, y, z)).normalized()
        p = Vector((0, 0, zc)) + v * (gr - 0.006)
        o = sphere(r, p, "sage", scale=(1.0, 0.7, 0.12), name="land")
        _orient(o, v)
    torus(mr, 0.0035, (0, 0, zc), "brass", rot=(math.pi / 2, tilt, 0), name="meridian", seg=32)
    cyl(0.01, 0.03, (math.sin(tilt) * (gr + 0.01), 0, zc + math.cos(tilt) * (gr + 0.01)), "brass", "Z", 8, rot=(0, tilt, 0), name="pivot")
    cyl(0.1, 0.025, (0, 0, 0.0125), "walnut", "Z", 24, bevel=0.006, name="stand_base")
    cyl(0.03, 0.02, (0, 0, 0.035), "walnut", "Z", 14, bevel=0.005, name="stand_collar")
    cyl(0.012, zc - mr + 0.004 - 0.04, (0, 0, 0.04 + (zc - mr + 0.004 - 0.04) / 2), "walnut", "Z", 10, name="stand_stem")


def filing_cabinet(w, d, h):
    # four-drawer steel filing cabinet: 'way' carcass and drawer fronts, steel handles and label frames, cream cards
    pl = 0.05
    box((w, d - 0.04, h), (0, 0.02, h / 2), WAY, 0.006, name="carcass")
    box((w - 0.04, 0.006, pl - 0.01), (0, -d / 2 + 0.045, pl / 2), "dark", 0.0, name="plinth")
    n = 4
    gap = 0.008
    dh = (h - pl - 0.02 - gap * (n - 1)) / n
    fy = -d / 2 + 0.033
    for i in range(n):
        zc = pl + dh / 2 + i * (dh + gap)
        box((w - 0.03, 0.014, dh), (0, fy, zc), WAY, 0.005, name="drawer")
        box((0.13, 0.018, 0.022), (0, fy - 0.014, zc + dh * 0.12), "steel", 0.006, name="handle")
        box((0.08, 0.004, 0.035), (0, fy - 0.007, zc + dh * 0.32), "steel", 0.001, name="label_frame")
        box((0.07, 0.003, 0.026), (0, fy - 0.009, zc + dh * 0.32), "cream", 0.0, name="label_card")
    cyl(0.01, 0.008, (w / 2 - 0.05, -d / 2 + 0.024, h - 0.03), "steel", "Y", 12, name="lock")
    box((w - 0.002, d - 0.008, 0.01), (0, 0.004, h - 0.005), "dark", 0.003, name="lid_trim")


def office_plant(w, d, h):
    # snake plant in a 'way' pot: dark potting mix, upright pointed green / sage blades
    pr = w / 2 - 0.004
    ph = 0.3
    cyl(pr - 0.035, ph, (0, 0, ph / 2), WAY, "Z", 24, r2=pr, bevel=0.01, name="pot")
    cyl(pr + 0.004, 0.03, (0, 0, ph - 0.015), "cream", "Z", 24, bevel=0.006, name="pot_rim")
    cyl(pr - 0.012, 0.01, (0, 0, ph - 0.02), "dark", "Z", 24, name="potting_mix")
    blades = [(0.0, 0.0, 0.5, 0.0, 0.0), (0.05, 0.02, 0.42, 1.2, 0.12), (-0.05, 0.03, 0.46, 2.3, -0.12), (0.02, -0.06, 0.38, 3.3, 0.18),
              (-0.04, -0.04, 0.44, 4.2, -0.16), (0.06, -0.03, 0.34, 5.2, 0.22), (-0.07, 0.0, 0.32, 0.6, -0.25), (0.03, 0.07, 0.36, 2.9, 0.2),
              (-0.02, 0.05, 0.4, 1.8, -0.08), (0.07, 0.04, 0.3, 0.3, 0.26), (-0.06, -0.07, 0.3, 3.9, 0.24), (0.0, -0.02, 0.47, 4.8, 0.06)]
    for i, (x, y, bl, rz, tx) in enumerate(blades):
        hw = 0.014 + 0.003 * (i % 3)
        L = min(bl + 0.03, h - ph + 0.03)
        pts = [(-hw, 0), (-hw * 1.1, L * 0.3), (-hw * 0.9, L * 0.65), (0, L), (hw * 0.9, L * 0.65), (hw * 1.1, L * 0.3), (hw, 0)]
        o = extrude_xz(pts, 0.006, 0, "green" if i % 2 == 0 else "sage", name="leaf", bevel=0.0)
        o.location = (x, y, ph - 0.03)
        o.rotation_euler = (0, tx, rz)


def low_cabinet(w, d, h):
    # low two-door cabinet: 'way' carcass and doors, overhanging cabinet top, brass knobs, walnut tapered legs
    lg = 0.1
    tt = 0.025
    box((w - 0.02, d - 0.03, h - lg - tt), (0, 0.01, lg + (h - lg - tt) / 2), WAY, 0.008, name="carcass")
    box((w, d, tt), (0, 0, h - tt / 2), WAY, 0.008, name="cabinet_top")
    dw = (w - 0.04 - 0.006) / 2
    dz = lg + 0.02 + (h - lg - tt - 0.04) / 2
    dhh = h - lg - tt - 0.04
    for s in (-1, 1):
        box((dw, 0.016, dhh), (s * (dw / 2 + 0.003), -d / 2 + 0.025, dz), WAY, 0.006, name="door")
        sphere(0.014, (s * 0.03, -d / 2 + 0.012, dz + 0.05), "brass", scale=(1, 0.8, 1), name="knob")
        box((dw - 0.06, 0.004, dhh - 0.06), (s * (dw / 2 + 0.003), -d / 2 + 0.016, dz), WAY, 0.002, name="door_panel")
    box((0.006, 0.01, dhh), (0, -d / 2 + 0.03, dz), "dark", 0.0, name="door_gap")
    for x in (-1, 1):
        for y in (-1, 1):
            cyl(0.022, lg, (x * (w / 2 - 0.05), y * (d / 2 - 0.05), lg / 2), "walnut", "Z", 12, r2=0.016, bevel=0.003, rot=(0, 0, 0), name="leg")


def garden_bench(w, d, h):
    # garden bench: 'way' (cast iron) scrolled ends, oak seat and back slats; front toward -Y
    sz = 0.44
    ex = w / 2 - 0.03
    t = 0.04
    for x in (-ex, ex):
        arc_bar([(-d / 2 + 0.04, 0.0), (-d / 2 + 0.06, 0.3), (-d / 2 + 0.05, 0.62)], t, t, WAY, name="front_leg", plane="YZ", offset=x, bevel=0.006)
        arc_bar([(d / 2 - 0.02, 0.0), (d / 2 - 0.08, 0.25), (d / 2 - 0.1, sz), (d / 2 - 0.06, 0.65), (d / 2 - 0.02, h - 0.01)], t, t, WAY, name="back_leg", plane="YZ", offset=x, bevel=0.006)
        arc_bar([(-d / 2 + 0.02, 0.6), (-d / 2 + 0.15, 0.64), (0.05, 0.62), (d / 2 - 0.07, 0.66)], 0.035, 0.06, WAY, name="armrest", plane="YZ", offset=x, bevel=0.008)
        arc_bar([(-d / 2 + 0.06, sz - 0.04), (0.0, sz - 0.06), (d / 2 - 0.1, sz - 0.03)], 0.03, t * 0.9, WAY, name="seat_rail", plane="YZ", offset=x, bevel=0.004)
        torus(0.035, 0.009, (x, -d / 2 + 0.05, 0.62), WAY, rot=(0, math.pi / 2, 0), name="scroll", seg=14)
        torus(0.045, 0.01, (x, -d / 2 + 0.11, sz - 0.12), WAY, rot=(0, math.pi / 2, 0), name="scroll", seg=14)
        torus(0.04, 0.009, (x, d / 2 - 0.06, 0.73), WAY, rot=(0, math.pi / 2, 0), name="scroll", seg=14)
    sw = 2 * ex + 0.03
    for i in range(5):
        y = -d / 2 + 0.07 + i * 0.06
        box((sw, 0.05, 0.025), (0, y, sz - 0.02), "oak", 0.006, name="seat_slat")
        for x in (-ex, ex):
            cyl(0.006, 0.004, (x, y, sz - 0.0055), "steel", "Z", 8, name="bolt")
    for i in range(3):
        z = 0.56 + i * 0.1
        y = d / 2 - 0.085 + (z - 0.56) * 0.25
        box((2 * ex - t, 0.022, 0.07), (0, y, z), "oak", 0.006, rot=(-0.2, 0, 0), name="back_slat")
    box((2 * ex - t, 0.022, 0.025), (0, d / 2 - 0.035, h - 0.04), "oak", 0.006, rot=(-0.2, 0, 0), name="back_slat")


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
