"""Build Corner Office catalogue-family GLBs (batch 3), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 3 are Design Specialist's).
"""
import csv
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch3
MINE = ["mirror_round", "rubber_duck", "bedside_lamp", "blanket", "teddy", "hat_box", "speaker", "vase", "table_lamp", "guitar"]
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


def mirror_round(w, d, h):
    # round wall mirror: 'way' (brass) ring frame, glass face to -Y, dark backing at +Y
    R = w / 2
    cz = h / 2
    torus(R - d / 2, d / 2, (0, 0, cz), WAY, rot=(math.pi / 2, 0, 0), name="frame", seg=36)
    cyl(R - d * 0.6, d * 0.5, (0, d * 0.22, cz), "dark", "Y", 36, name="backing")
    cyl(R - d * 0.75, 0.004, (0, -0.004, cz), "glass", "Y", 36, name="mirror")
    for x, z, L in ((-0.07, 0.07, 0.16), (-0.02, 0.1, 0.07), (0.08, -0.09, 0.08)):
        box((L, 0.002, 0.014), (x, -0.007, cz + z), "white", 0.0, rot=(0, -0.75, 0), name="mirror_glint")
    cyl(0.012, 0.01, (0, 0.0, h - 0.012), WAY, "Y", 12, name="hanging_loop")


def rubber_duck(w, d, h):
    # classic bath duck in profile along X (beak to -X); 'way' body, head and wings
    sphere(0.04, (0.005, 0, 0.03), WAY, scale=(1.125, 1.0, 0.75), name="body")
    sphere(0.016, (0.034, 0, 0.05), WAY, scale=(1.0, 0.9, 0.75), name="tail", rot=(0, -0.6, 0))
    sphere(0.026, (-0.02, 0, 0.072), WAY, name="head")
    sphere(0.011, (-0.04, 0, 0.066), "terracotta", scale=(1.0, 1.15, 0.5), name="beak")
    for s in (-1, 1):
        sphere(0.02, (0.012, s * 0.034, 0.034), WAY, scale=(1.35, 0.3, 0.8), name="wing", rot=(0, -0.3, 0))
        sphere(0.0075, (-0.028, s * 0.019, 0.08), "white", scale=(1, 0.6, 1), name="eye")
        sphere(0.004, (-0.031, s * 0.0225, 0.081), "dark", scale=(1, 0.6, 1), name="pupil")


def _lamp_base_bits(foot_r, z_top, cord_y):
    # brass socket stub and a dark cord trailing out the back
    cyl(0.016, 0.03, (0, 0, z_top + 0.015), "brass", "Z", 12, bevel=0.003, name="socket")
    cyl(0.004, cord_y, (0, foot_r * 0.6 + cord_y / 2, 0.006), "dark", "Y", 8, name="cord")


def bedside_lamp(w, d, h):
    # small gourd lamp: 'way' ceramic base, cream tapered shade with brass trims
    cyl(0.06, 0.018, (0, 0, 0.009), WAY, "Z", 18, bevel=0.006, name="foot")
    lathe([(0, 0.016), (0.05, 0.016), (0.07, 0.05), (0.075, 0.09), (0.062, 0.13), (0.035, 0.155),
           (0.02, 0.175), (0.024, 0.19), (0, 0.19)], WAY, name="body")
    _lamp_base_bits(0.06, 0.19, 0.03)
    sb, st = 0.215, h
    cyl(w / 2, st - sb, (0, 0, (sb + st) / 2), "cream", "Z", 24, r2=w / 2 * 0.68, bevel=0.006, name="shade")
    torus(w / 2 - 0.003, 0.004, (0, 0, sb + 0.003), "brass", name="shade_trim", seg=24)
    torus(w / 2 * 0.68 - 0.003, 0.004, (0, 0, st - 0.004), "brass", name="shade_trim", seg=24)
    cyl(0.003, 0.05, (0.04, -0.03, sb - 0.025), "brass", "Z", 6, name="pull_chain")
    sphere(0.006, (0.04, -0.03, sb - 0.052), "brass", name="pull_bead")


def table_lamp(w, d, h):
    # living-room lamp: oak foot, 'way' ceramic column, cream drum shade
    cyl(0.1, 0.03, (0, 0, 0.015), "oak", "Z", 24, bevel=0.008, name="foot")
    lathe([(0, 0.03), (0.06, 0.03), (0.07, 0.06), (0.072, 0.1), (0.065, 0.17), (0.05, 0.22),
           (0.03, 0.245), (0.03, 0.26), (0, 0.26)], WAY, name="body")
    torus(0.068, 0.006, (0, 0, 0.095), "brass", name="body_band", seg=24)
    _lamp_base_bits(0.1, 0.26, 0.04)
    sb = 0.3
    cyl(w / 2, h - sb, (0, 0, (sb + h) / 2), "cream", "Z", 32, bevel=0.008, name="shade")
    for z in (sb + 0.006, h - 0.006):
        torus(w / 2 - 0.004, 0.005, (0, 0, z), "oak", name="shade_trim", seg=32)
    box((0.012, 0.02, 0.025), (0.035, -0.05, 0.045), "dark", 0.003, name="switch")


def blanket(w, d, h):
    # folded blanket: three soft layers, cream stripes wrapping the fold, kraft label
    n = 3
    lh = h / n
    for i in range(n):
        k = i * 0.012
        bw, bd = w - k, d - k
        z = lh * i + lh / 2
        box((bw, bd, lh * 0.98), (0, 0, z), WAY, lh * 0.45, name="blanket")
        for x in (-bw / 2 + 0.07, -bw / 2 + 0.1, bw / 2 - 0.085):
            box((0.018 if x < 0 else 0.03, bd + 0.003, lh * 0.98 + 0.003), (x, 0, z), "cream", lh * 0.45, name="stripe")
    box((0.05, 0.004, 0.025), (0.08, -(d - 0.024) / 2 - 0.002, lh * 2.5), "kraft", 0.002, name="label")


def teddy(w, d, h):
    # sitting teddy bear facing -Y; 'way' fur, cream muzzle/pads/tummy, red bow
    sphere(0.07, (0, 0.012, 0.095), WAY, scale=(1.0, 0.86, 1.1), name="body")
    sphere(0.034, (0, -0.042, 0.088), "cream", scale=(0.95, 0.45, 1.05), name="tummy")
    sphere(0.062, (0, 0.006, 0.215), WAY, name="head")
    sphere(0.03, (0, -0.048, 0.198), "cream", scale=(1.0, 0.8, 0.75), name="muzzle")
    sphere(0.011, (0, -0.072, 0.209), "dark", scale=(1.2, 0.8, 0.8), name="nose")
    for s in (-1, 1):
        sphere(0.0075, (s * 0.024, -0.05, 0.234), "dark", name="eye")
        sphere(0.026, (s * 0.046, 0.008, 0.268), WAY, scale=(1, 0.7, 1), name="ear")
        sphere(0.015, (s * 0.046, -0.006, 0.266), "cream", scale=(1, 0.4, 1), name="ear_inner")
        sphere(0.028, (s * 0.074, -0.012, 0.12), WAY, scale=(0.8, 0.8, 1.6), name="arm", rot=(0.35, -s * 0.3, 0))
        sphere(0.034, (s * 0.045, -0.035, 0.034), WAY, scale=(0.95, 1.45, 0.95), name="leg")
        sphere(0.024, (s * 0.045, -0.079, 0.036), "cream", scale=(1, 0.3, 1.1), name="foot_pad")
        cyl(0.013, 0.03, (s * 0.017, -0.05, 0.16), "red", "X", 10, r2=0.004, rot=(0, -s * math.pi / 2, 0), name="bow")
    sphere(0.007, (0, -0.055, 0.16), "red", name="bow_knot")


def hat_box(w, d, h):
    # round hat box: 'way' drum and lid, cream stripes and lid band, cream cord handle
    R = w / 2
    bh = 0.142
    cyl(R - 0.006, bh, (0, 0, bh / 2), WAY, "Z", 32, bevel=0.006, name="hatbox_body")
    for i in range(16):
        a = 2 * math.pi * (i + 0.5) / 16
        box((0.018, 0.004, bh - 0.012), ((R - 0.0045) * math.cos(a), (R - 0.0045) * math.sin(a), bh / 2), "cream", 0.0,
            rot=(0, 0, a + math.pi / 2), name="stripe")
    lt = 0.034
    cyl(R, lt, (0, 0, bh - 0.008 + lt / 2), WAY, "Z", 32, bevel=0.008, name="lid")
    cyl(R + 0.0005, 0.012, (0, 0, bh - 0.008 + lt / 2), "cream", "Z", 32, name="lid_band")
    zt = bh - 0.008 + lt
    arc = [(-0.06 + 0.12 * t / 8, zt + 0.004 + (h - zt - 0.01) * math.sin(math.pi * t / 8)) for t in range(9)]
    arc_bar([(u, v) for u, v in arc], 0.008, 0.008, "cream", name="handle_cord", plane="XZ", offset=0.0)
    for x in (-0.06, 0.06):
        cyl(0.012, 0.006, (x, 0, zt + 0.003), "brass", "Z", 12, name="cord_grommet")
    box((0.06, 0.004, 0.035), (0, -R + 0.006 - 0.0025, bh * 0.55), "brass", 0.002, name="label")
    box((0.048, 0.004, 0.024), (0, -R + 0.006 - 0.004, bh * 0.55), "cream", 0.0, name="label_card")


def speaker(w, d, h):
    # bookshelf speaker: 'way' cabinet, grey baffle, woofer + tweeter + port on the front (-Y)
    fz = 0.012
    cd = d - 0.016
    box((w, cd, h - fz), (0, 0.008, fz + (h - fz) / 2), WAY, 0.012, name="cabinet")
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for y in (-cd / 2 + 0.03, cd / 2 - 0.02):
            cyl(0.012, fz, (x, y, fz / 2), "dark", "Z", 10, name="foot")
    fy = 0.008 - cd / 2
    box((w - 0.03, 0.006, h - fz - 0.03), (0, fy - 0.002, fz + (h - fz) / 2), "grey", 0.004, name="baffle")
    wz, tz = fz + 0.14, fz + 0.31
    cyl(0.078, 0.008, (0, fy - 0.006, wz), "dark", "Y", 24, name="woofer")
    torus(0.068, 0.008, (0, fy - 0.008, wz), "dark", rot=(math.pi / 2, 0, 0), name="woofer_surround", seg=24)
    cyl(0.06, 0.006, (0, fy - 0.006, wz), "dark", "Y", 24, r2=0.025, name="woofer_cone")
    sphere(0.022, (0, fy - 0.009, wz), "steel", scale=(1, 0.45, 1), name="dust_cap")
    cyl(0.036, 0.006, (0, fy - 0.006, tz), "dark", "Y", 18, name="tweeter_plate")
    torus(0.028, 0.004, (0, fy - 0.009, tz), "steel", rot=(math.pi / 2, 0, 0), name="tweeter_ring", seg=18)
    sphere(0.016, (0, fy - 0.009, tz), "steel", scale=(1, 0.55, 1), name="tweeter")
    cyl(0.02, 0.008, (0, fy - 0.006, fz + 0.04), "black" if WAY != "black" else "dark", "Y", 16, name="port")
    cyl(0.012, 0.01, (0, fy - 0.006, fz + 0.04), "black", "Y", 12, name="port_hole")
    cyl(0.005, 0.004, (w / 2 - 0.035, fy - 0.007, fz + 0.04), "brass", "Y", 8, name="led")


def _vase_r(prof, z):
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        if z0 <= z <= z1 and z1 > z0:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return prof[-1][0]


def vase(w, d, h):
    # lathed ceramic vase: 'way' glaze, cream belly band and mustard neck line, cream dots
    R = w / 2
    outer = [(0.042, 0.0), (0.046, 0.012), (0.06, 0.05), (R, 0.11), (0.066, 0.15), (0.05, 0.2), (0.031, 0.238),
             (0.028, 0.258), (0.035, 0.288), (0.04, h)]
    prof = [(0, 0.0)] + outer + [(0.034, h - 0.002), (0.024, h - 0.03), (0, h - 0.03)]
    lathe(prof, WAY, name="body", segs=24)
    for z0, z1, col, nm in ((0.098, 0.124, "cream", "band"), (0.232, 0.24, "mustard", "neck_line"), (0.008, 0.014, "cream", "foot_line")):
        zs = [z0 + (z1 - z0) * t / 3 for t in range(4)]
        ring = [(0, z0)] + [(_vase_r(outer, z) + 0.0015, z) for z in zs] + [(0, z1)]
        lathe(ring, col, name=nm, segs=24)
    for i in range(8):
        a = 2 * math.pi * (i + 0.5) / 8
        z = 0.165
        rr = _vase_r(outer, z) + 0.001
        sphere(0.008, (rr * math.cos(a), rr * math.sin(a), z), "cream", scale=(1, 1, 1), name="dot")


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


def guitar(w, d, h):
    # acoustic guitar standing upright, soundboard to -Y; 'way' body, oak neck, steel strings
    by, bd = 0.012, 0.103
    lr, ur = w / 2, 0.152
    lz, uz = lr, 0.42
    # figure-of-eight outline (lower bout, waist, upper bout), smoothed, extruded along Y
    top = uz + ur
    N = 40
    zs = [top * i / N for i in range(N + 1)]
    def hw(z):
        a = math.sqrt(max(lr * lr - (z - lz) ** 2, 0.0))
        b = math.sqrt(max(ur * ur - (z - uz) ** 2, 0.0))
        return max(a, b, 0.125 if 0.15 < z < 0.5 else 0.0)
    xs = [hw(z) for z in zs]
    for _ in range(3):
        xs = [xs[0]] + [(xs[i - 1] + 2 * xs[i] + xs[i + 1]) / 4 for i in range(1, N)] + [xs[N]]
    xs[0] = xs[N] = 0.0
    xs = [min(x, lr) for x in xs]
    outline = [(x, z) for x, z in zip(xs, zs)][:-1] + [(0.0, top)] + [(-x, z) for x, z in reversed(list(zip(xs, zs)))][1:-1]
    extrude_xz(outline, bd, by, WAY, name="body", bevel=0.012)
    fy = by - bd / 2
    cyl(0.046, 0.004, (0, fy - 0.001, 0.37), "dark", "Y", 24, name="soundhole")
    torus(0.054, 0.0045, (0, fy - 0.002, 0.37), "cream", rot=(math.pi / 2, 0, 0), name="rosette", seg=24)
    box((0.13, 0.012, 0.03), (0, fy - 0.006, 0.17), "dark", 0.004, name="bridge")
    box((0.08, 0.006, 0.005), (0, fy - 0.014, 0.175), "cream", 0.0, name="saddle")
    sphere(0.05, (0.065, fy - 0.0015, 0.31), "dark", scale=(0.7, 0.05, 1.0), name="pickguard", rot=(0, 0.4, 0))
    n0, n1 = uz + ur - 0.02, 0.87
    box((0.05, 0.03, n1 - n0), (0, by - 0.01, (n0 + n1) / 2), "oak", 0.008, name="neck")
    box((0.046, 0.006, n1 - n0 + 0.13), (0, fy - 0.003, (n0 - 0.13 + n1) / 2), "dark", 0.0, name="fretboard")
    for i in range(10):
        z = n1 - 0.02 - (n1 - n0 + 0.1) * (1 - 0.93 ** i) / (1 - 0.93 ** 10)
        box((0.046, 0.003, 0.003), (0, fy - 0.0065, z), "steel", 0.0, name="fret")
    for z in (n1 - 0.09, n1 - 0.2, n1 - 0.29):
        cyl(0.004, 0.002, (0, fy - 0.0065, z), "cream", "Y", 8, name="fret_dot")
    box((0.05, 0.007, 0.006), (0, fy - 0.004, n1 + 0.002), "cream", 0.0, name="nut")
    box((0.085, 0.025, h - n1), (0, by - 0.012, (n1 + h) / 2), "oak", 0.008, name="headstock")
    for s in (-1, 1):
        for k in range(3):
            z = n1 + 0.03 + k * 0.035
            cyl(0.008, 0.012, (s * (0.0425 + 0.006), by - 0.012, z), "steel", "X", 10, name="tuning_peg")
            cyl(0.005, 0.004, (s * 0.022, fy - 0.003 + 0.005, z), "steel", "Y", 8, name="string_post")
    for i in range(6):
        x = -0.02 + i * 0.008
        L = n1 - 0.17
        box((0.0018, 0.0018, L), (x * 1.0, fy - 0.009, 0.17 + L / 2), "steel", 0.0, name="string")
    cyl(0.007, 0.01, (0, by, 0.004), "cream", "Z", 10, name="strap_button")



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
