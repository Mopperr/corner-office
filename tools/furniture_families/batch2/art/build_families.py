"""Build Corner Office catalogue-family GLBs (batch 2), add-only.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py -- [family_id ...]

Same approach and style as tools/build_household.py: bevelled boxes,
18-segment cylinders, 16x10 spheres, flat matte Principled colour, no textures.
Each family is built at the plain variant's real size (metres, from
families.csv), origin at the bottom centre, front toward -Y in Blender
(+Z in Godot after export_yup). The part that changes colour per colour-way
uses a material named exactly 'way' (first colour-way in the CSV); wood and
metal parts use fixed palette materials. Output: ../../hh_cat_<family_id>.glb
Scope: the 10 families in MINE (the other 10 of batch 2 are Design Specialist's).
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
MINE = ["tv_small", "kitchen_shelf", "glass_cabinet", "fireplace_set", "wall_clock", "crate_stack", "picture_frame", "round_rug", "kitchen_clock", "drinks_trolley"]
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
WAY_ALIAS = {"painted white": "white", "painted sage": "sage", "tan": "kraft", "wicker": "kraft", "off": "dark"}
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

def tv_small(w, d, h):
    # small flat-screen TV on a pedestal foot; the screen (off = dark) is 'way'
    box((0.34, d, 0.025), (0, 0, 0.0125), "grey", 0.01, name="stand_foot")
    box((0.08, 0.04, 0.06), (0, 0.01, 0.05), "grey", 0.008, name="stand_neck")
    bz0, bh = 0.075, h - 0.075
    box((w, 0.06, bh), (0, 0.0, bz0 + bh / 2), "black", 0.014, name="body")
    box((w * 0.6, 0.05, bh * 0.7), (0, 0.05, bz0 + bh * 0.5), "black", 0.02, name="back_cover")
    sh = bh - 0.075
    box((w - 0.05, 0.01, sh), (0, -0.032, bz0 + 0.05 + sh / 2), WAY, 0.004, name="screen")
    for i, (x, z, L) in enumerate(((-w * 0.3, bz0 + bh * 0.72, 0.14), (-w * 0.22, bz0 + bh * 0.62, 0.07))):
        box((L, 0.004, 0.018), (x, -0.038, z), "glass", 0.0, rot=(0, 0.6, 0), name="screen_glare")
    cyl(0.007, 0.008, (w / 2 - 0.05, -0.031, bz0 + 0.026), "red", "Y", 10, name="power_led")
    box((0.07, 0.004, 0.012), (0, -0.031, bz0 + 0.026), "steel", 0.0, name="logo")


def kitchen_shelf(w, d, h):
    # wall shelf: back board (against +Y), shelf on brackets, rail of hanging mugs
    box((w, 0.022, h), (0, d / 2 - 0.011, h / 2), WAY, 0.006, name="back_board")
    sz = 0.15
    box((w, d - 0.02, 0.025), (0, -0.01, sz), WAY, 0.006, name="shelf")
    box((w, 0.07, 0.022), (0, d / 2 - 0.035 - 0.022, h - 0.011), WAY, 0.006, name="cap_board")
    for x in (-w / 2 + 0.07, w / 2 - 0.07):
        splay_leg((x, -d / 2 + 0.05, sz - 0.02), (x, d / 2 - 0.03, 0.03), 0.022, WAY, name="bracket")
    # hook rail under the shelf, mugs hanging
    cyl(0.007, w - 0.2, (0, -0.03, sz - 0.035), "steel", "X", 10, name="rail")
    for x in (-(w - 0.2) / 2, (w - 0.2) / 2):
        box((0.012, d / 2, 0.012), (x, -0.03 + d / 4 - 0.01, sz - 0.035), "steel", 0.003, name="rail_bracket")
    for i, c in enumerate(("cream", "terracotta", "sage")):
        x = -0.17 + i * 0.17
        torus(0.012, 0.0035, (x, -0.03, sz - 0.045), "steel", rot=(0, math.pi / 2, 0), name="hook", seg=10)
        cyl(0.034, 0.07, (x, -0.03, sz - 0.1), c, "Z", 16, bevel=0.006, name="mug")
        torus(0.02, 0.006, (x + 0.036, -0.03, sz - 0.1), c, rot=(math.pi / 2, 0, 0), name="mug_handle", seg=12)
    # jars on the shelf
    top = sz + 0.0125
    for i, (x, hh) in enumerate(((-0.28, 0.1), (-0.19, 0.08), (0.2, 0.09))):
        cyl(0.035, hh, (x, -0.02, top + hh / 2), "glass", "Z", 16, bevel=0.005, name="jar")
        cyl(0.037, 0.016, (x, -0.02, top + hh + 0.008), "mustard", "Z", 16, bevel=0.004, name="jar_lid")
    # leaning plate and a small jug
    cyl(0.055, 0.012, (0.0, 0.04, top + 0.058), "cream", "Y", 18, rot=(math.pi / 2 - 0.2, 0, 0), name="plate")
    cyl(0.03, 0.07, (0.3, -0.03, top + 0.035), "terracotta", "Z", 14, r2=0.024, bevel=0.005, name="jug")


def glass_cabinet(w, d, h):
    # display cabinet: wooden carcass ('way'), glazed upper doors, cupboard below
    box((w - 0.04, d - 0.04, 0.08), (0, 0, 0.04), WAY, 0.008, name="plinth")
    for s in (-1, 1):
        box((0.03, d - 0.02, h - 0.13), (s * (w / 2 - 0.035), 0, 0.08 + (h - 0.13) / 2), WAY, 0.006, name="side")
    box((w, d, 0.05), (0, 0, h - 0.025), WAY, 0.01, name="cornice")
    box((w - 0.1, 0.015, h - 0.13), (0, d / 2 - 0.02, 0.08 + (h - 0.13) / 2), "cream", 0.0, name="back_panel")
    # lower cupboard
    lz0, lh = 0.08, 0.4
    dw = (w - 0.1) / 2 - 0.004
    for s in (-1, 1):
        box((dw, 0.025, lh - 0.01), (s * (dw / 2 + 0.004), -d / 2 + 0.035, lz0 + lh / 2), WAY, 0.006, name="door")
        box((dw - 0.07, 0.006, lh - 0.08), (s * (dw / 2 + 0.004), -d / 2 + 0.021, lz0 + lh / 2), WAY, 0.003, name="door_panel")
        sphere(0.013, (s * 0.04, -d / 2 + 0.014, lz0 + lh * 0.72), "brass", name="knob")
    box((w - 0.07, d - 0.04, 0.03), (0, 0, lz0 + lh + 0.015), WAY, 0.006, name="divider")
    # glass shelves and glazed doors
    uz0, uz1 = lz0 + lh + 0.03, h - 0.05
    for z in (uz0 + (uz1 - uz0) * 0.36, uz0 + (uz1 - uz0) * 0.7):
        box((w - 0.1, d - 0.1, 0.012), (0, 0.01, z), "glass", 0.003, name="glass_shelf")
    for s in (-1, 1):
        cx = s * (dw / 2 + 0.004)
        uh = uz1 - uz0 - 0.01
        zc = uz0 + 0.005 + uh / 2
        fy = -d / 2 + 0.03
        for x in (cx - dw / 2 + 0.0175, cx + dw / 2 - 0.0175):
            box((0.035, 0.025, uh), (x, fy, zc), WAY, 0.005, name="door_frame")
        for z in (zc - uh / 2 + 0.0175, zc + uh / 2 - 0.0175, zc):
            box((dw, 0.025, 0.035 if z != zc else 0.02), (cx, fy, z), WAY, 0.005, name="door_frame")
        for k, (dx, dz, L) in enumerate(((-0.06, 0.18, 0.22), (0.02, 0.1, 0.12), (-0.04, -0.22, 0.16))):
            box((0.018, 0.004, L), (cx + dx, fy - 0.004, zc + dz), "glass", 0.0, rot=(0, 0.55, 0), name="door_glint")
        sphere(0.011, (s * 0.03, fy - 0.016, zc), "brass", name="knob")
    # contents: plates on the lower shelf area, glasses and a jug above
    for i in range(3):
        cyl(0.085, 0.014, (-0.2 + i * 0.07, d / 2 - 0.08, uz0 + 0.09), "cream", "Y", 18, rot=(math.pi / 2 - 0.15, 0, 0), name="plate")
    cyl(0.05, 0.14, (0.18, 0.02, uz0 + 0.07), "terracotta", "Z", 16, r2=0.035, bevel=0.006, name="jug")
    z1 = uz0 + (uz1 - uz0) * 0.36 + 0.006
    for i in range(5):
        cyl(0.026, 0.1, (-0.24 + i * 0.12, 0.0, z1 + 0.05), "glass", "Z", 12, r2=0.032, bevel=0.003, name="glass")
    z2 = uz0 + (uz1 - uz0) * 0.7 + 0.006
    for i in range(3):
        cyl(0.045, 0.06, (-0.15 + i * 0.15, 0.02, z2 + 0.03), "cream" if i != 1 else "mustard", "Z", 16, bevel=0.006, name="cup")


def fireplace_set(w, d, h):
    # companion set: round base, post with a ring handle, four tools on hooks
    r = w / 2
    cyl(r, 0.022, (0, 0, 0.011), WAY, "Z", 18, bevel=0.006, name="base")
    cyl(0.012, h - 0.11, (0, 0, 0.022 + (h - 0.11) / 2), WAY, "Z", 12, name="post")
    torus(0.032, 0.008, (0, 0, h - 0.04), "brass", rot=(math.pi / 2, 0, 0), name="handle_ring", seg=18)
    hz = h - 0.14
    cyl(0.006, 0.13, (0, 0, hz), WAY, "X", 8, name="hook_bar")
    cyl(0.006, 0.13, (0, 0, hz), WAY, "Y", 8, name="hook_bar")
    tz0 = 0.04
    for k, (x, y) in enumerate(((0.06, 0), (-0.06, 0), (0, 0.06), (0, -0.06))):
        sl = hz - tz0 - 0.02
        cyl(0.005, sl, (x, y, tz0 + sl / 2 + 0.03), WAY, "Z", 8, name="tool_shaft")
        sphere(0.013, (x, y, hz + 0.0), "brass", scale=(1, 1, 1.5), name="tool_handle")
        if k == 0:  # poker
            cyl(0.008, 0.06, (x, y, tz0 + 0.0), WAY, "Z", 8, r2=0.002, name="poker_tip")
            box((0.03, 0.008, 0.008), (x + 0.014, y, tz0 + 0.03), WAY, 0.002, name="poker_hook")
        elif k == 1:  # shovel
            box((0.008, 0.07, 0.07), (x - 0.004, y, tz0 + 0.0), WAY, 0.004, name="shovel_blade")
        elif k == 2:  # brush
            cyl(0.024, 0.08, (x, y, tz0 + 0.0), "dark", "Z", 14, bevel=0.006, name="brush_bristles")
            cyl(0.026, 0.015, (x, y, tz0 + 0.045), "brass", "Z", 14, name="brush_collar")
        else:  # tongs
            for s in (-1, 1):
                box((0.006, 0.006, 0.08), (x + s * 0.01, y, tz0 + 0.02), WAY, 0.002, rot=(0, s * 0.15, 0), name="tongs_arm")
                box((0.018, 0.008, 0.025), (x + s * 0.016, y, tz0 - 0.015), WAY, 0.003, name="tongs_paddle")


def _clock_hands(cx, cz, y, specs, name_prefix="hand"):
    for ang, L, wd, col, nm in specs:
        t = math.radians(ang)
        box((wd, 0.004, L), (cx + math.sin(t) * (L / 2 - 0.012), y, cz + math.cos(t) * (L / 2 - 0.012)), col, 0.0, rot=(0, t, 0), name=nm)


def wall_clock(w, d, h):
    # classic round wall clock: 'way' case and bezel, cream dial, 10:10
    R = w / 2
    cz = h / 2
    cyl(R - 0.004, 0.042, (0, 0.009, cz), WAY, "Y", 36, bevel=0.012, name="case")
    torus(R - 0.016, 0.010, (0, -0.013, cz), WAY, rot=(math.pi / 2, 0, 0), name="bezel", seg=36)
    cyl(R - 0.024, 0.006, (0, -0.014, cz), "cream", "Y", 36, name="face")
    for i in range(12):
        t = math.radians(i * 30)
        big = i % 3 == 0
        L = 0.032 if big else 0.018
        rr = R - 0.05 - L / 2 + 0.01
        box((0.012 if big else 0.007, 0.004, L), (math.sin(t) * rr, -0.018, cz + math.cos(t) * rr), "dark", 0.0, rot=(0, t, 0), name="tick")
    _clock_hands(0, cz, -0.021, ((305, 0.085, 0.013, "dark", "hour_hand"), (60, 0.125, 0.009, "dark", "minute_hand")))
    _clock_hands(0, cz, -0.024, ((200, 0.13, 0.004, "red", "second_hand"),))
    cyl(0.013, 0.008, (0, -0.024, cz), "brass", "Y", 14, name="centre_cap")


def crate_stack(w, d, h):
    # three slatted wooden crates; apples in the top one
    n = 3
    ch = (h - 0.02) / n
    for k in range(n):
        z0 = k * ch
        cw, cd = w, d
        box((cw - 0.02, cd - 0.02, 0.015), (0, 0, z0 + 0.0075), WAY, 0.003, name="crate_base")
        for sx in (-1, 1):
            for sy in (-1, 1):
                box((0.03, 0.03, ch - 0.004), (sx * (cw / 2 - 0.015), sy * (cd / 2 - 0.015), z0 + ch / 2), WAY, 0.004, name="crate_post")
        for j in range(3):
            z = z0 + 0.03 + j * (ch - 0.05) / 2.2
            for sy in (-1, 1):
                box((cw - 0.03, 0.014, 0.045), (0, sy * (cd / 2 - 0.009), z), WAY, 0.004, name="crate_slat")
            if j < 2:
                for sx in (-1, 1):
                    box((0.014, cd - 0.03, 0.045), (sx * (cw / 2 - 0.009), 0, z), WAY, 0.004, name="crate_slat")
        for sx in (-1, 1):
            box((0.016, cd - 0.03, 0.05), (sx * (cw / 2 - 0.009), 0, z0 + ch - 0.035), WAY, 0.004, name="crate_handle_rail")
            box((0.01, 0.1, 0.02), (sx * (cw / 2 - 0.004), 0, z0 + ch - 0.035), "dark", 0.002, name="handle_slot")
        box((0.12, 0.004, 0.03), (0.08, -cd / 2 - 0.0, z0 + 0.03 + (ch - 0.05) / 2.2), "dark", 0.0, name="stencil")
    zt = (n - 1) * ch + 0.015
    i = 0
    for x in (-0.15, -0.05, 0.05, 0.15):
        for y in (-0.07, 0.05):
            sphere(0.045, (x + (0.01 if y > 0 else 0), y, zt + ch - 0.045 - 0.015 + 0.012 * (i % 2)), "red" if i % 3 else "green", scale=(1, 1, 0.92), name="apple")
            i += 1


def picture_frame(w, d, h):
    # framed landscape: 'way' frame, cream mount, sky / hills / sun
    fb = 0.045
    box((w, d, fb), (0, 0, fb / 2), WAY, 0.006, name="frame_rail")
    box((w, d, fb), (0, 0, h - fb / 2), WAY, 0.006, name="frame_rail")
    for s in (-1, 1):
        box((fb, d, h - 2 * fb + 0.002), (s * (w / 2 - fb / 2), 0, h / 2), WAY, 0.006, name="frame_stile")
    box((w - 2 * fb + 0.004, 0.012, h - 2 * fb + 0.004), (0, 0.0, h / 2), "cream", 0.0, name="mount")
    pw, ph = w - 0.17, h - 0.17
    z0 = (h - ph) / 2
    fy = -0.0065
    box((pw, 0.003, ph), (0, fy - 0.0015, h / 2), "blue", 0.0, name="picture_sky")
    cyl(0.032, 0.003, (pw / 2 - 0.06, fy - 0.004, z0 + ph - 0.07), "mustard", "Y", 18, name="picture_sun")
    for x, rr, col in ((-pw / 2 + 0.07, 0.07, "sage"), (pw / 2 - 0.06, 0.06, "green")):
        cyl(rr, 0.003, (x, fy - 0.005, z0 + 0.07), col, "Y", 18, name="picture_hill")
    box((pw, 0.003, 0.07), (0, fy - 0.0065, z0 + 0.035), "green", 0.0, name="picture_field")
    for x, s in ((-0.03, 1.0), (0.0, 0.8)):
        sphere(0.025 * s, (x, fy - 0.004, z0 + ph - 0.12), "cream", scale=(1.6, 0.15, 0.8), name="picture_cloud")


def round_rug(w, d, h):
    # layered round rug: 'way' field and border band, cream rings, mustard dots
    R = w / 2
    base = h - 0.012
    cyl(R, base, (0, 0, base / 2), WAY, "Z", 48, bevel=0.006, name="rug")
    t = 0.003
    layers = [(R - 0.07, "cream", "rug_ring"), (R - 0.11, WAY, "rug_field"), (R * 0.42, "terracotta", "rug_ring"),
              (R * 0.3, "cream", "rug_ring"), (R * 0.12, "mustard", "rug_centre")]
    for i, (rr, col, nm) in enumerate(layers):
        cyl(rr, t, (0, 0, base + t * (i + 0.5) - 0.0005 * i), col, "Z", 48 if rr > 0.3 else 24, name=nm)
    for i in range(16):
        a = i * 2 * math.pi / 16
        cyl(0.018, t, (math.cos(a) * (R * 0.62), math.sin(a) * (R * 0.62), base + t * 2.5), "mustard", "Z", 10, name="rug_dot")


def kitchen_clock(w, d, h):
    # rounded-square kitchen clock with fork and spoon hands
    rc = 0.055
    cz = h / 2
    cy = 0.007
    D = 0.036
    box((w - 2 * rc, D, h), (0, cy, cz), WAY, 0.008, name="case")
    box((w, D, h - 2 * rc), (0, cy, cz), WAY, 0.008, name="case")
    for sx in (-1, 1):
        for sz in (-1, 1):
            cyl(rc, D, (sx * (w / 2 - rc), cy, cz + sz * (h / 2 - rc)), WAY, "Y", 18, bevel=0.008, name="case")
    fi = 0.028
    fr = rc - 0.02
    fy = cy - D / 2 - 0.002
    fw, fh = w - 2 * fi, h - 2 * fi
    box((fw - 2 * fr, 0.004, fh), (0, fy, cz), "cream", 0.0, name="face")
    box((fw, 0.004, fh - 2 * fr), (0, fy, cz), "cream", 0.0, name="face")
    for sx in (-1, 1):
        for sz in (-1, 1):
            cyl(fr, 0.004, (sx * (fw / 2 - fr), fy, cz + sz * (fh / 2 - fr)), "cream", "Y", 14, name="face")
    for i in range(12):
        t = math.radians(i * 30)
        rr = 0.098
        big = i % 3 == 0
        cyl(0.011 if big else 0.006, 0.004, (math.sin(t) * rr, fy - 0.003, cz + math.cos(t) * rr), "red" if big else "dark", "Y", 12, name="dot")
    hy = fy - 0.006
    # fork = hour hand (pointing to 10), spoon = minute hand (pointing to 2)
    for ang, L, tool in ((300, 0.075, "fork"), (60, 0.105, "spoon")):
        t = math.radians(ang)
        ux, uz = math.sin(t), math.cos(t)
        box((0.007, 0.004, L), (ux * (L / 2 - 0.008), hy, cz + uz * (L / 2 - 0.008)), "steel", 0.0, rot=(0, t, 0), name=tool + "_hand")
        tip = L - 0.008
        if tool == "fork":
            box((0.022, 0.004, 0.012), (ux * tip, hy, cz + uz * tip), "steel", 0.0, rot=(0, t, 0), name="fork_head")
            for o in (-0.008, 0.0, 0.008):
                px = ux * (tip + 0.014) + uz * o
                pz = uz * (tip + 0.014) - ux * o
                box((0.004, 0.004, 0.02), (px, hy, cz + pz), "steel", 0.0, rot=(0, t, 0), name="fork_tine")
        else:
            o = sphere(0.016, (ux * (tip + 0.012), hy, cz + uz * (tip + 0.012)), "steel", scale=(0.7, 0.25, 1.0), name="spoon_bowl")
            o.rotation_euler = (0, t, 0)
    cyl(0.011, 0.006, (0, hy - 0.004, cz), "red", "Y", 14, name="centre_cap")


def drinks_trolley(w, d, h):
    # two-deck bar cart: 'way' tube frame, glass decks, big wheels at -X, handle at +X
    px, py = w / 2 - 0.1, d / 2 - 0.045
    wr = 0.09
    pr = 0.012
    for x in (-px, px):
        for y in (-py, py):
            zb = wr if x < 0 else 0.03
            cyl(pr, h - 0.015 - zb, (x, y, zb + (h - 0.015 - zb) / 2), WAY, "Z", 12, name="post")
    for y in (-py, py):
        cyl(wr, 0.03, (-px, y + (0.03 if y > 0 else -0.03), wr), "dark", "Y", 18, bevel=0.008, name="wheel")
        cyl(0.025, 0.036, (-px, y + (0.03 if y > 0 else -0.03), wr), "brass", "Y", 12, name="wheel_hub")
        sphere(0.022, (px, y, 0.022), "brass", scale=(1, 1, 0.9), name="foot")
        # side handle bar ends sweep out past the posts at +X
        cyl(0.01, 0.084, (px + 0.042, y, h - 0.04), WAY, "X", 10, name="handle_arm")
    cyl(0.015, 2 * py + 0.02, (px + 0.082, 0, h - 0.04), "brass", "Y", 14, name="handle_grip")
    decks = (0.17, 0.44)
    for z in decks:
        box((2 * px + 0.02, 2 * py + 0.02, 0.012), (0, 0, z), "glass", 0.003, name="deck_glass")
        for y in (-py, py):
            cyl(0.01, 2 * px, (0, y, z + 0.012), WAY, "X", 10, name="deck_rail")
        for x in (-px, px):
            cyl(0.01, 2 * py, (x, 0, z + 0.012), WAY, "Y", 10, name="deck_rail")
    top = decks[1] + 0.006
    # bottles: wine bottle (green), spirits (glass + brass cap)
    for i, (x, col) in enumerate(((-0.17, "green"), (-0.09, "green"))):
        cyl(0.033, 0.16, (x, 0.04, top + 0.08), col, "Z", 16, bevel=0.006, name="bottle")
        cyl(0.033, 0.035, (x, 0.04, top + 0.1775), col, "Z", 16, r2=0.013, name="bottle_shoulder")
        cyl(0.012, 0.05, (x, 0.04, top + 0.22), col, "Z", 10, name="bottle_neck")
        cyl(0.013, 0.015, (x, 0.04, top + 0.2475), "brass", "Z", 10, name="bottle_cap")
    sphere(0.06, (0.03, 0.0, top + 0.06), "glass", name="decanter")
    cyl(0.018, 0.04, (0.03, 0.0, top + 0.13), "glass", "Z", 12, name="decanter_neck")
    sphere(0.02, (0.03, 0.0, top + 0.16), "brass", name="decanter_stopper")
    for i in range(3):
        cyl(0.025, 0.07, (0.12 + i * 0.055, -0.08, top + 0.035), "glass", "Z", 12, r2=0.03, bevel=0.003, name="glass")
    cyl(0.04, 0.13, (0.13, 0.07, top + 0.065), "steel", "Z", 16, r2=0.034, bevel=0.006, name="shaker")
    # lower deck: ice bucket and lying bottle
    low = decks[0] + 0.006
    cyl(0.07, 0.12, (-0.1, 0.0, low + 0.06), "steel", "Z", 18, r2=0.08, bevel=0.008, name="ice_bucket")
    cyl(0.032, 0.2, (0.12, 0.02, low + 0.032), "green", "X", 16, bevel=0.006, name="bottle")
    cyl(0.012, 0.06, (0.25, 0.02, low + 0.032), "green", "X", 10, name="bottle_neck")


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
