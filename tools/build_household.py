"""Build the household furniture as GLB models with Blender's Python module.

    pip install bpy
    python3 tools/build_household.py            # every item
    python3 tools/build_household.py sofa piano # just these

Each item is built to the width, depth and height it has in data/content.json
(metres), standing on the floor with its origin at the bottom centre and its
front toward -Y in Blender, which the glTF exporter turns into +Z in Godot.
The result lands in assets/models/hh_<id>.glb; Godot imports it on the next
--import run and Props.make() picks it up by name.
"""
import json
import math
import os
import sys

import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "models")

# The game's palette, roughly: warm woods, chalky paint, a little steel.
PINE = "C9A27E"
OAK = "8E6E5A"
WALNUT = "5A3B2A"
WHITE = "F4F0E8"
CREAM = "F4ECDD"
STEEL = "B8BCC0"
DARK = "2E2A28"
SLATE = "4A5A6A"
TERRA = "D9765F"
SAGE = "8FAF7E"
BLUE = "7FA3B8"
MUSTARD = "E6B655"
LILAC = "D4C1D8"
LINEN = "E9DFCB"
GLASS = "8FB3C4"
BRASS = "C9A34E"
GREEN = "5E8A4A"
RED = "B9433A"
WICKER = "C9A26A"
RUBBER = "3A3634"

_materials = {}


def mat(hex_color, rough=0.82, metal=0.0):
    key = (hex_color, rough, metal)
    if key in _materials:
        return _materials[key]
    m = bpy.data.materials.new("m_" + hex_color)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    r, g, b = (int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    # sRGB in the data, linear for the shader.
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (r, g, b)]
    bsdf.inputs["Base Color"].default_value = (*lin, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    _materials[key] = m
    return m


def _finish(obj, color, bevel, name):
    obj.name = name
    obj.data.materials.append(mat(color))
    if bevel > 0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
    return obj


def box(size, at, color, bevel=0.008, rot=(0, 0, 0), name="box"):
    """A block: size (x, y, z), centre at, rotation in radians."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=at, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, color, min(bevel, min(size) * 0.3), name)


def cyl(r, h, at, color, axis="Z", verts=18, rot=None, bevel=0.0, name="cyl", r2=None):
    rotation = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}[axis]
    if rot is not None:
        rotation = rot
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=at, rotation=rotation)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=h, location=at, rotation=rotation)
    o = bpy.context.active_object
    return _finish(o, color, bevel, name)


def sphere(r, at, color, scale=(1, 1, 1), name="sphere"):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=r, location=at)
    o = bpy.context.active_object
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, color, 0.0, name)


def legs(w, d, h, color, t=0.04, inset=0.05, z0=0.0):
    for x in (-w / 2 + inset + t / 2, w / 2 - inset - t / 2):
        for y in (-d / 2 + inset + t / 2, d / 2 - inset - t / 2):
            box((t, t, h), (x, y, z0 + h / 2), color, 0.004, name="leg")


def cabinet(w, d, h, color, trim, doors=2, plinth=0.06, handles=True):
    box((w, d, h - plinth), (0, 0, plinth + (h - plinth) / 2), color, 0.015, name="body")
    box((w - 0.04, d - 0.04, plinth), (0, 0, plinth / 2), trim, 0.004, name="plinth")
    if doors:
        dw = (w - 0.04) / doors
        for i in range(doors):
            x = -w / 2 + 0.02 + dw * (i + 0.5)
            box((dw - 0.02, 0.015, h - plinth - 0.08), (x, -d / 2 - 0.005, plinth + (h - plinth) / 2), color, 0.006, name="door")
            if handles:
                hx = x + (dw * 0.32 if i < doors / 2 else -dw * 0.32) if doors > 1 else x + dw * 0.3
                cyl(0.008, 0.12, (hx, -d / 2 - 0.03, plinth + (h - plinth) / 2), trim, "Z", 10, name="handle")


# ------------------------------------------------------------------ kitchen

def fridge_home(w, d, h):
    box((w, d, h), (0, 0, h / 2), WHITE, 0.02, name="body")
    box((w - 0.03, 0.004, 0.012), (0, -d / 2 - 0.004, h * 0.68), STEEL, 0.0, name="seam")
    for z in (h * 0.78, h * 0.4):
        cyl(0.01, 0.2, (w * 0.32, -d / 2 - 0.02, z), STEEL, "Z", 10, name="handle")
    for i, c in enumerate((TERRA, SAGE, MUSTARD)):
        box((0.04, 0.006, 0.04), (-w * 0.2 + i * 0.09, -d / 2 - 0.004, h * 0.55 - i * 0.06), c, 0.0, name="magnet")
    box((w, d, 0.05), (0, 0, 0.025), DARK, 0.004, name="kick")


def cooker(w, d, h):
    box((w, d, h - 0.03), (0, 0, (h - 0.03) / 2), WHITE, 0.015, name="body")
    box((w, d, 0.03), (0, 0, h - 0.015), DARK, 0.004, name="hob")
    for x, y in ((-0.15, -0.14), (0.15, -0.14), (-0.15, 0.14), (0.15, 0.14)):
        cyl(0.07, 0.012, (x * w / 0.6, y * d / 0.6, h + 0.004), STEEL, name="ring")
    box((w - 0.1, 0.01, h * 0.42), (0, -d / 2 - 0.005, h * 0.42), DARK, 0.006, name="oven_door")
    cyl(0.01, w - 0.16, (0, -d / 2 - 0.03, h * 0.66), STEEL, "X", 10, name="handle")
    for i in range(4):
        cyl(0.014, 0.02, (-w * 0.3 + i * w * 0.2, -d / 2 - 0.01, h * 0.82), STEEL, "Y", 10, name="knob")
    box((w - 0.04, 0.03, 0.12), (0, d / 2 - 0.015, h + 0.06), WHITE, 0.01, name="splashback")


def microwave(w, d, h):
    box((w, d, h), (0, 0, h / 2), STEEL, 0.012, name="body")
    box((w * 0.62, 0.01, h * 0.7), (-w * 0.14, -d / 2 - 0.005, h / 2), DARK, 0.006, name="door")
    box((w * 0.5, 0.004, h * 0.5), (-w * 0.14, -d / 2 - 0.012, h / 2), GLASS, 0.0, name="window")
    for i in range(3):
        box((0.04, 0.006, 0.02), (w * 0.3, -d / 2 - 0.004, h * 0.7 - i * 0.045), DARK, 0.0, name="button")


def toaster(w, d, h):
    box((w, d, h), (0, 0, h / 2), STEEL, 0.03, name="body")
    for y in (-d * 0.2, d * 0.2):
        box((w * 0.7, 0.025, 0.01), (0, y, h), DARK, 0.0, name="slot")
    box((0.03, 0.02, 0.012), (w / 2 + 0.01, 0, h * 0.4), DARK, 0.0, name="lever")


def knife_block(w, d, h):
    box((w, d, h), (0, 0, h / 2), OAK, 0.012, rot=(0.12, 0, 0), name="block")
    for i in range(3):
        box((0.018, 0.012, 0.11), (-w * 0.25 + i * w * 0.25, -0.01, h + 0.04), DARK, 0.003, rot=(0.12, 0, 0), name="knife")


def spice_rack(w, d, h):
    box((w, 0.02, h), (0, d / 2 - 0.01, h / 2), PINE, 0.004, name="back")
    for z in (0.02, h * 0.52):
        box((w, d, 0.018), (0, 0, z), PINE, 0.003, name="shelf")
        for i in range(5):
            cyl(0.02, 0.08, (-w / 2 + 0.06 + i * (w - 0.12) / 4, -0.01, z + 0.05), GLASS, name="jar")
            cyl(0.021, 0.015, (-w / 2 + 0.06 + i * (w - 0.12) / 4, -0.01, z + 0.097), [TERRA, SAGE, MUSTARD, RED, OAK][i], name="lid")


def pot_stack(w, d, h):
    r = w / 2
    for i, (rr, hh) in enumerate(((r, 0.12), (r * 0.8, 0.1), (r * 0.62, 0.08))):
        z = [0, 0.12, 0.22][i]
        cyl(rr, hh, (0, 0, z + hh / 2), STEEL, name="pot")
        cyl(0.008, rr * 0.5, (rr + rr * 0.25, 0, z + hh * 0.7), DARK, "X", 8, name="pot_handle")
    cyl(r * 0.64, 0.012, (0, 0, 0.306), STEEL, name="lid")
    sphere(0.015, (0, 0, 0.325), DARK, name="lid_knob")


def bread_bin(w, d, h):
    box((w, d, h), (0, 0, h / 2), CREAM, 0.03, name="body")
    box((w - 0.03, 0.012, h * 0.7), (0, -d / 2 - 0.004, h * 0.55), PINE, 0.006, rot=(0.35, 0, 0), name="lid")
    cyl(0.008, 0.08, (0, -d / 2 - 0.02, h * 0.3), DARK, "X", 8, name="handle")
    box((w * 0.3, 0.004, 0.03), (0, -d / 2 - 0.012, h * 0.72), DARK, 0.0, name="label")


def kitchen_table(w, d, h):
    box((w, d, 0.04), (0, 0, h - 0.02), PINE, 0.008, name="top")
    box((w - 0.16, d - 0.16, 0.08), (0, 0, h - 0.08), OAK, 0.004, name="apron")
    legs(w, d, h - 0.04, OAK, 0.05, 0.04)


def kitchen_chair(w, d, h):
    seat_h = h * 0.5
    box((w, d, 0.035), (0, 0, seat_h), PINE, 0.012, name="seat")
    legs(w, d, seat_h, OAK, 0.032, 0.03)
    for x in (-w / 2 + 0.04, w / 2 - 0.04):
        box((0.03, 0.03, h - seat_h), (x, d / 2 - 0.03, seat_h + (h - seat_h) / 2), OAK, 0.004, name="post")
    for z in (h - 0.06, h * 0.78):
        box((w - 0.08, 0.025, 0.05), (0, d / 2 - 0.03, z), PINE, 0.006, name="slat")


def dish_rack(w, d, h):
    box((w, d, 0.015), (0, 0, 0.008), STEEL, 0.002, name="tray")
    for i in range(6):
        x = -w / 2 + 0.05 + i * (w - 0.1) / 5
        cyl(0.004, h, (x, -d * 0.2, h / 2), STEEL, "Z", 6, name="wire")
        cyl(0.004, h, (x, d * 0.2, h / 2), STEEL, "Z", 6, name="wire")
    for i in range(3):
        cyl(0.085, 0.008, (-w * 0.25 + i * w * 0.25, 0, 0.1), CREAM, "Y", 16, name="plate")


# ----------------------------------------------------------------- bathroom

def bathtub(w, d, h):
    box((w, d, h), (0, 0, h / 2), WHITE, 0.06, name="tub")
    box((w - 0.16, d - 0.16, 0.02), (0, 0, h - 0.01), GLASS, 0.0, name="water")
    for x in (-w * 0.4, w * 0.4):
        for y in (-d * 0.35, d * 0.35):
            sphere(0.045, (x, y, 0.03), BRASS, name="foot")
    cyl(0.012, 0.16, (w * 0.42, 0, h + 0.06), STEEL, "Z", 10, name="tap")
    cyl(0.012, 0.1, (w * 0.42, -0.05, h + 0.14), STEEL, "Y", 10, name="spout")


def toilet(w, d, h):
    box((w * 0.7, d * 0.5, h * 0.5), (0, 0.02, h * 0.25), WHITE, 0.03, name="base")
    box((w, d * 0.72, h * 0.14), (0, -d * 0.1, h * 0.5), WHITE, 0.04, name="bowl")
    box((w * 0.92, d * 0.64, 0.02), (0, -d * 0.1, h * 0.58), CREAM, 0.008, name="lid")
    box((w * 0.9, d * 0.3, h * 0.44), (0, d * 0.35, h * 0.78), WHITE, 0.02, name="tank")
    box((0.03, 0.02, 0.012), (w * 0.3, d * 0.35, h + 0.006), STEEL, 0.0, name="button")


def pedestal_sink(w, d, h):
    cyl(0.07, h * 0.7, (0, 0.04, h * 0.35), WHITE, "Z", 14, r2=0.09, name="pedestal")
    box((w, d, h * 0.2), (0, 0, h * 0.8), WHITE, 0.04, name="basin")
    box((w - 0.1, d - 0.1, 0.01), (0, -0.01, h * 0.9), GLASS, 0.0, name="water")
    cyl(0.012, 0.14, (0, d / 2 - 0.06, h + 0.04), STEEL, "Z", 10, name="tap")


def mirror_cabinet(w, d, h):
    box((w, d, h), (0, 0, h / 2), WHITE, 0.01, name="body")
    box((w - 0.04, 0.006, h - 0.04), (0, -d / 2 - 0.003, h / 2), GLASS, 0.0, name="mirror")
    box((w, 0.01, 0.02), (0, -d / 2, 0.01), STEEL, 0.0, name="trim")


def towel_stack(w, d, h):
    for i, c in enumerate((BLUE, CREAM, SAGE)):
        box((w, d, h / 3 - 0.01), (0, 0, h / 6 + i * h / 3), c, 0.03, name="towel")


def bath_mat(w, d, h):
    box((w, d, h), (0, 0, h / 2), BLUE, 0.01, name="mat")
    box((w - 0.08, d - 0.08, 0.006), (0, 0, h + 0.003), LILAC, 0.0, name="pattern")


def laundry_basket(w, d, h):
    cyl(w / 2, h - 0.04, (0, 0, (h - 0.04) / 2), WICKER, "Z", 18, r2=w / 2 - 0.03, name="basket")
    cyl(w / 2 + 0.01, 0.03, (0, 0, h - 0.055), OAK, "Z", 18, name="rim")
    cyl(w / 2 - 0.01, 0.025, (0, 0, h - 0.012), WICKER, "Z", 18, name="lid")
    box((0.06, 0.02, 0.03), (0, 0, h + 0.01), OAK, 0.004, name="knob")


def shower_caddy(w, d, h):
    for z in (0.02, h * 0.55):
        box((w, d, 0.015), (0, 0, z), STEEL, 0.002, name="shelf")
    cyl(0.006, h, (-w / 2 + 0.01, d / 2 - 0.01, h / 2), STEEL, "Z", 8, name="rail")
    cyl(0.006, h, (w / 2 - 0.01, d / 2 - 0.01, h / 2), STEEL, "Z", 8, name="rail")
    for i, c in enumerate((SAGE, TERRA, BLUE)):
        cyl(0.02, 0.14, (-w * 0.3 + i * w * 0.3, -0.01, 0.1), c, "Z", 10, name="bottle")


def toothbrush_cup(w, d, h):
    cyl(w / 2, h * 0.6, (0, 0, h * 0.3), CREAM, "Z", 14, name="cup")
    for a, c in ((0.2, TERRA), (-0.25, BLUE)):
        cyl(0.006, h * 0.8, (a * 0.1, 0, h * 0.55), c, "Z", 8, rot=(a, 0, 0), name="brush")


# ------------------------------------------------------------------ bedroom

def _bed(w, d, h, pillows):
    base_h = h * 0.3
    box((w, d, base_h), (0, 0, base_h / 2), OAK, 0.012, name="frame")
    box((w - 0.06, d - 0.06, h * 0.22), (0, 0, base_h + h * 0.11), CREAM, 0.03, name="mattress")
    box((w - 0.1, d * 0.62, h * 0.12), (0, -d * 0.15, base_h + h * 0.22 + h * 0.06), BLUE, 0.03, name="duvet")
    box((w - 0.1, 0.06, h * 0.1), (0, d * 0.16, base_h + h * 0.22 + h * 0.08), LINEN, 0.02, name="fold")
    box((w, 0.05, h), (0, d / 2 - 0.025, h / 2), OAK, 0.012, name="headboard")
    pw = (w - 0.2) / pillows
    for i in range(pillows):
        box((pw - 0.06, d * 0.2, 0.08), (-w / 2 + 0.1 + pw * (i + 0.5), d * 0.34, base_h + h * 0.22 + 0.04), WHITE, 0.03, name="pillow")


def bed_single(w, d, h):
    _bed(w, d, h, 1)


def bed_double(w, d, h):
    _bed(w, d, h, 2)


def wardrobe(w, d, h):
    cabinet(w, d, h - 0.04, OAK, WALNUT, doors=2)
    box((w + 0.03, d + 0.03, 0.04), (0, 0, h - 0.02), WALNUT, 0.006, name="crown")


def chest_drawers(w, d, h):
    box((w, d, h - 0.08), (0, 0, 0.08 + (h - 0.08) / 2), PINE, 0.012, name="body")
    legs(w, d, 0.08, OAK, 0.04, 0.03)
    dh = (h - 0.12) / 3
    for i in range(3):
        z = 0.1 + dh * (i + 0.5)
        box((w - 0.06, 0.015, dh - 0.03), (0, -d / 2 - 0.005, z), PINE, 0.006, name="drawer")
        cyl(0.012, 0.012, (0, -d / 2 - 0.018, z), WALNUT, "Y", 10, name="knob")


def bedside_table(w, d, h):
    box((w, d, 0.03), (0, 0, h - 0.015), PINE, 0.006, name="top")
    box((w - 0.04, d - 0.04, h * 0.3), (0, 0, h - 0.03 - h * 0.15), PINE, 0.008, name="drawer_box")
    cyl(0.01, 0.01, (0, -d / 2 + 0.015, h - 0.03 - h * 0.15), WALNUT, "Y", 10, name="knob")
    legs(w, d, h - 0.03 - h * 0.3, OAK, 0.03, 0.03)
    box((0.12, 0.09, 0.03), (0.08, 0, h + 0.015), TERRA, 0.004, name="book")


def pillow_stack(w, d, h):
    for i, c in enumerate((WHITE, LINEN, WHITE)):
        box((w, d, h / 3 - 0.01), (0, 0, h / 6 + i * h / 3), c, 0.035, name="pillow")


def alarm_clock(w, d, h):
    cyl(w / 2, d * 0.7, (0, 0, h * 0.55), RED, "Y", 20, name="body")
    cyl(w / 2 - 0.015, 0.005, (0, -d * 0.36, h * 0.55), CREAM, "Y", 20, name="face")
    for x in (-w * 0.3, w * 0.3):
        sphere(0.02, (x, 0, h * 0.9), STEEL, name="bell")
    for x in (-w * 0.3, w * 0.3):
        cyl(0.005, h * 0.25, (x, 0, h * 0.12), STEEL, "Z", 8, name="foot")


def standing_mirror(w, d, h):
    cyl(w / 2, 0.02, (0, 0, h * 0.55), BRASS, "Y", 20, name="frame")
    cyl(w / 2 - 0.03, 0.01, (0, -0.012, h * 0.55), GLASS, "Y", 20, name="glass")
    for y in (-d / 2 + 0.03, d / 2 - 0.03):
        box((w * 0.6, 0.03, 0.03), (0, y, 0.015), WALNUT, 0.004, name="foot")
    cyl(0.012, h * 0.3, (0, 0, h * 0.15), WALNUT, "Z", 10, name="stem")


def bedroom_rug(w, d, h):
    box((w, d, h), (0, 0, h / 2), TERRA, 0.008, name="rug")
    for i in range(3):
        box((w - 0.12 - i * 0.24, 0.03, 0.004), (0, -d / 2 + 0.1 + i * 0.1, h + 0.002), MUSTARD, 0.0, name="stripe")
        box((w - 0.12 - i * 0.24, 0.03, 0.004), (0, d / 2 - 0.1 - i * 0.1, h + 0.002), MUSTARD, 0.0, name="stripe")


# ------------------------------------------------------------- living room

def _seat(w, d, h, fabric, seats):
    box((w, d, h * 0.4), (0, 0, h * 0.2), fabric, 0.03, name="base")
    box((w, d * 0.3, h), (0, d / 2 - d * 0.15, h / 2), fabric, 0.03, name="back")
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        box((0.16, d, h * 0.62), (x, 0, h * 0.31), fabric, 0.03, name="arm")
    sw = (w - 0.34) / seats
    for i in range(seats):
        box((sw - 0.03, d * 0.62, 0.1), (-w / 2 + 0.17 + sw * (i + 0.5), -d * 0.12, h * 0.4 + 0.05), fabric, 0.03, name="cushion")
    legs(w, d, 0.05, WALNUT, 0.04, 0.05)


def sofa(w, d, h):
    _seat(w, d, h, SAGE, 2)
    box((0.3, 0.3, 0.1), (-w * 0.3, 0.05, h * 0.55), MUSTARD, 0.03, rot=(0.3, 0, 0), name="throw_cushion")


def armchair(w, d, h):
    _seat(w, d, h, TERRA, 1)


def coffee_table(w, d, h):
    box((w, d, 0.03), (0, 0, h - 0.015), WALNUT, 0.006, name="top")
    box((w - 0.2, d - 0.2, 0.02), (0, 0, h * 0.35), OAK, 0.004, name="shelf")
    legs(w, d, h - 0.03, WALNUT, 0.035, 0.04)
    for i, c in enumerate((BLUE, CREAM)):
        box((0.22, 0.16, 0.02), (-0.1 + i * 0.03, 0.05, h + 0.01 + i * 0.02), c, 0.003, name="magazine")


def television(w, d, h):
    box((w, 0.04, h * 0.78), (0, 0, h * 0.61), DARK, 0.006, name="screen_body")
    box((w - 0.03, 0.004, h * 0.72), (0, -0.022, h * 0.61), SLATE, 0.0, name="screen")
    box((0.08, 0.06, h * 0.2), (0, 0.01, h * 0.12), DARK, 0.004, name="neck")
    box((w * 0.5, d, 0.015), (0, 0, 0.008), DARK, 0.004, name="foot")


def tv_stand(w, d, h):
    cabinet(w, d, h, WALNUT, OAK, doors=2, plinth=0.08)


def floor_lamp(w, d, h):
    cyl(w / 2 * 0.6, 0.02, (0, 0, 0.01), DARK, "Z", 18, name="base")
    cyl(0.012, h * 0.78, (0, 0, h * 0.4), BRASS, "Z", 10, name="pole")
    cyl(w / 2, h * 0.2, (0, 0, h - h * 0.1), LINEN, "Z", 18, r2=w / 2 * 0.7, name="shade")


def piano(w, d, h):
    box((w, d * 0.6, h), (0, d * 0.2, h / 2), WALNUT, 0.012, name="body")
    box((w, d * 0.4, 0.06), (0, -d * 0.3, h * 0.6), WALNUT, 0.008, name="key_shelf")
    box((w - 0.16, d * 0.3, 0.02), (0, -d * 0.3, h * 0.64), WHITE, 0.003, name="keys")
    for i in range(14):
        box((0.018, d * 0.18, 0.012), (-w / 2 + 0.12 + i * (w - 0.24) / 13, -d * 0.25, h * 0.66), DARK, 0.0, name="black_key")
    box((w, 0.02, 0.1), (0, -d * 0.1, h * 0.85), WALNUT, 0.006, rot=(0.5, 0, 0), name="music_rest")
    for x in (-w * 0.4, w * 0.4):
        box((0.06, d * 0.4, h * 0.55), (x, -d * 0.3, h * 0.28), WALNUT, 0.006, name="leg")
    for x in (-0.06, 0.0, 0.06):
        box((0.02, 0.06, 0.01), (x, -d / 2 + 0.02, 0.03), BRASS, 0.0, name="pedal")


def magazine_rack(w, d, h):
    for y in (-d / 2 + 0.01, d / 2 - 0.01):
        box((w, 0.015, h), (0, y, h / 2), OAK, 0.004, rot=(0.25 if y < 0 else -0.25, 0, 0), name="side")
    box((w, d, 0.02), (0, 0, 0.01), OAK, 0.003, name="base")
    for i, c in enumerate((TERRA, BLUE, MUSTARD)):
        box((w - 0.08, 0.02, h * 0.8), (0, -0.05 + i * 0.05, h * 0.45), c, 0.003, rot=(0.1 * i, 0, 0), name="magazine")


def side_table(w, d, h):
    cyl(w / 2, 0.025, (0, 0, h - 0.012), PINE, "Z", 20, name="top")
    for i in range(3):
        a = i * 2 * math.pi / 3
        cyl(0.015, h - 0.03, (math.cos(a) * w * 0.3, math.sin(a) * w * 0.3, (h - 0.03) / 2), OAK, "Z", 8, rot=(math.sin(a) * 0.12, -math.cos(a) * 0.12, 0), name="leg")


# --------------------------------------------------------------------- loft

def old_suitcase(w, d, h):
    box((w, d, h), (0, 0, h / 2), WICKER, 0.02, name="case")
    box((w + 0.004, d + 0.004, 0.01), (0, 0, h * 0.5), OAK, 0.0, name="seam")
    box((0.12, 0.02, 0.03), (0, -d / 2 - 0.01, h + 0.01), OAK, 0.006, name="handle")
    for x in (-w * 0.3, w * 0.3):
        box((0.03, 0.01, 0.025), (x, -d / 2 - 0.004, h * 0.5), BRASS, 0.0, name="clasp")
    for i, c in enumerate((TERRA, BLUE, MUSTARD)):
        box((0.06, 0.004, 0.04), (-w * 0.25 + i * 0.1, -d / 2 - 0.003, h * 0.3 + i * 0.03), c, 0.0, name="sticker")


def travel_trunk(w, d, h):
    box((w, d, h), (0, 0, h / 2), WALNUT, 0.015, name="trunk")
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for z in (0.03, h - 0.03):
            box((0.06, d + 0.006, 0.06), (x, 0, z), BRASS, 0.004, name="corner")
    for x in (-w * 0.25, w * 0.25):
        box((0.05, d + 0.004, h + 0.004), (x, 0, h / 2), OAK, 0.0, name="strap")
    box((0.1, 0.03, 0.05), (0, -d / 2 - 0.01, h * 0.5), BRASS, 0.004, name="lock")


def rocking_horse(w, d, h):
    box((w * 0.5, d * 0.6, h * 0.3), (0, 0, h * 0.55), CREAM, 0.03, name="body")
    box((0.2, d * 0.5, 0.22), (w * 0.3, 0, h * 0.78), CREAM, 0.03, rot=(0, -0.4, 0), name="head")
    box((0.08, d * 0.3, 0.12), (w * 0.36, 0, h * 0.68), CREAM, 0.02, name="neck")
    box((0.1, 0.04, 0.3), (w * 0.3, 0, h * 0.95), TERRA, 0.01, rot=(0, -0.4, 0), name="mane")
    for x in (-w * 0.18, w * 0.18):
        for y in (-d * 0.2, d * 0.2):
            box((0.05, 0.05, h * 0.3), (x, y, h * 0.3), CREAM, 0.006, name="leg")
    for y in (-d * 0.35, d * 0.35):
        box((w, 0.04, 0.05), (0, y, 0.06), OAK, 0.008, rot=(0, 0.0, 0), name="rocker")
    box((w * 0.3, d * 0.5, 0.03), (0, 0, h * 0.72), OAK, 0.006, name="saddle")


def christmas_box(w, d, h):
    box((w, d, h * 0.8), (0, 0, h * 0.4), RED, 0.012, name="box")
    box((w + 0.02, d + 0.02, h * 0.2), (0, 0, h * 0.9), GREEN, 0.01, name="lid")
    for i in range(6):
        a = i * 1.1
        sphere(0.02, (math.cos(a) * w * 0.3, math.sin(a) * d * 0.3, h + 0.02), [MUSTARD, TERRA, BLUE][i % 3], name="bauble")


def old_mirror(w, d, h):
    box((w, d, h), (0, 0, h / 2), BRASS, 0.012, name="frame")
    box((w - 0.08, 0.006, h - 0.08), (0, -d / 2 - 0.003, h / 2), GLASS, 0.0, name="glass")


def dressmaker_dummy(w, d, h):
    cyl(w * 0.55, 0.02, (0, 0, 0.01), WALNUT, "Z", 16, name="base")
    for i in range(3):
        a = i * 2 * math.pi / 3
        box((w * 0.5, 0.03, 0.02), (math.cos(a) * w * 0.25, math.sin(a) * w * 0.25, 0.02), WALNUT, 0.003, rot=(0, 0, a), name="foot")
    cyl(0.012, h * 0.45, (0, 0, h * 0.25), STEEL, "Z", 10, name="pole")
    cyl(w * 0.4, h * 0.42, (0, 0, h * 0.67), LINEN, "Z", 18, r2=w * 0.5, bevel=0.02, name="torso")
    sphere(0.05, (0, 0, h * 0.92), WALNUT, name="top")


def telescope(w, d, h):
    for i in range(3):
        a = i * 2 * math.pi / 3 + 0.5
        cyl(0.012, h * 0.75, (math.cos(a) * w * 0.3, math.sin(a) * w * 0.3, h * 0.36), WALNUT, "Z", 8, rot=(math.sin(a) * 0.38, -math.cos(a) * 0.38, 0), name="tripod_leg")
    cyl(0.04, h * 0.6, (0, -0.1, h * 0.86), BRASS, "Z", 14, rot=(1.1, 0, 0), r2=0.055, name="tube")
    cyl(0.02, 0.06, (0, 0.2, h * 0.7), DARK, "Z", 10, rot=(1.1, 0, 0), name="eyepiece")


def record_box(w, d, h):
    box((w, d, h), (0, 0, h / 2), PINE, 0.008, name="crate")
    box((w - 0.03, d - 0.03, 0.02), (0, 0, h * 0.5), DARK, 0.0, name="hollow")
    for i in range(6):
        box((0.004, d - 0.08, h - 0.04), (-w * 0.3 + i * w * 0.12, 0, h * 0.6), [DARK, TERRA, BLUE, DARK, MUSTARD, DARK][i], 0.0, rot=(0, 0.05, 0), name="record")


# --------------------------------------------------------------------- shed

def lawnmower(w, d, h):
    box((w, d * 0.5, h * 0.3), (0, -d * 0.15, h * 0.25), GREEN, 0.025, name="deck")
    box((w * 0.8, d * 0.3, h * 0.28), (0, d * 0.18, h * 0.28), DARK, 0.02, name="grass_box")
    for x in (-w * 0.45, w * 0.45):
        for y in (-d * 0.3, 0.0):
            cyl(0.07, 0.04, (x, y, 0.07), RUBBER, "X", 14, name="wheel")
    for x in (-w * 0.3, w * 0.3):
        cyl(0.012, d * 0.9, (x, d * 0.3, h * 0.6), STEEL, "Y", 8, rot=(-0.9, 0, 0), name="handle_bar")
    cyl(0.014, w * 0.64, (0, d * 0.62, h * 0.93), RUBBER, "X", 8, name="grip")


def bicycle_home(w, d, h):
    r = h * 0.33
    for x in (-w * 0.3, w * 0.3):
        cyl(r, 0.03, (x, 0, r), RUBBER, "Y", 24, name="tyre")
        cyl(r - 0.03, 0.035, (x, 0, r), STEEL, "Y", 24, name="rim")
    cyl(0.015, w * 0.52, (-w * 0.02, 0, r + 0.02), TERRA, "X", 8, name="down_tube")
    cyl(0.015, h * 0.5, (w * 0.05, 0, r + h * 0.2), TERRA, "Z", 8, rot=(0, 0.3, 0), name="seat_tube")
    cyl(0.015, w * 0.4, (0.05, 0, r + h * 0.42), TERRA, "X", 8, rot=(0, 0.25, 0), name="top_tube")
    cyl(0.015, h * 0.45, (w * 0.3, 0, r + h * 0.22), TERRA, "Z", 8, rot=(0, -0.25, 0), name="fork")
    box((0.2, 0.08, 0.04), (-w * 0.1, 0, h * 0.92), DARK, 0.01, name="saddle")
    cyl(0.012, d * 1.4, (w * 0.3, 0, h * 0.9), STEEL, "Y", 8, name="handlebar")


def watering_can(w, d, h):
    cyl(d / 2, h * 0.75, (-w * 0.15, 0, h * 0.37), GREEN, "Z", 16, name="can")
    cyl(0.015, w * 0.55, (w * 0.2, 0, h * 0.6), GREEN, "X", 8, rot=(0, -0.6, 0), name="spout")
    cyl(0.03, 0.03, (w * 0.42, 0, h * 0.85), STEEL, "X", 12, rot=(0, -0.6, 0), name="rose")
    cyl(0.01, d * 0.9, (-w * 0.15, 0, h * 0.82), GREEN, "Y", 8, name="handle")


def flower_pots(w, d, h):
    for i in range(3):
        cyl(w * 0.4 - i * 0.008, h * 0.4, (0, 0, h * 0.2 + i * h * 0.3), TERRA, "Z", 14, r2=w * 0.5 - i * 0.008, name="pot")
        cyl(w * 0.52 - i * 0.008, 0.02, (0, 0, h * 0.4 + i * h * 0.3), TERRA, "Z", 14, name="rim")


def garden_chair(w, d, h):
    seat_h = h * 0.45
    box((w, d, 0.02), (0, 0, seat_h), MUSTARD, 0.006, name="seat")
    box((w, 0.02, h * 0.45), (0, d / 2 - 0.04, seat_h + h * 0.24), MUSTARD, 0.006, rot=(-0.15, 0, 0), name="back")
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        box((0.025, 0.025, h * 0.5), (x, -d * 0.2, seat_h / 2), STEEL, 0.003, rot=(0.35, 0, 0), name="leg")
        box((0.025, 0.025, h * 0.5), (x, d * 0.2, seat_h / 2), STEEL, 0.003, rot=(-0.35, 0, 0), name="leg")


def wheelbarrow(w, d, h):
    box((w, d * 0.6, h * 0.5), (0, 0.05, h * 0.5), GREEN, 0.03, name="tray")
    box((w - 0.06, d * 0.55, 0.02), (0, 0.05, h * 0.74), OAK, 0.0, name="soil")
    cyl(0.14, 0.05, (0, -d * 0.42, 0.14), RUBBER, "X", 16, name="wheel")
    for x in (-w * 0.35, w * 0.35):
        cyl(0.014, d * 1.0, (x, 0.12, h * 0.3), STEEL, "Y", 8, rot=(-0.25, 0, 0), name="handle")
        cyl(0.012, h * 0.25, (x, d * 0.3, h * 0.12), STEEL, "Z", 8, name="leg")


def paint_tins(w, d, h):
    for i, c in enumerate((TERRA, BLUE, CREAM)):
        x = -w * 0.3 + i * w * 0.3
        z = 0 if i < 2 else h * 0.45
        xx = x if i < 2 else -w * 0.15
        cyl(0.065, h * 0.45, (xx, 0, z + h * 0.225), STEEL, "Z", 16, name="tin")
        cyl(0.066, 0.012, (xx, 0, z + h * 0.45), c, "Z", 16, name="lid")


def ladder(w, d, h):
    for x in (-w / 2 + 0.025, w / 2 - 0.025):
        box((0.05, d, h), (x, 0, h / 2), PINE, 0.006, name="rail")
    n = 7
    for i in range(n):
        cyl(0.018, w - 0.05, (0, 0, 0.18 + i * (h - 0.36) / (n - 1)), OAK, "X", 10, name="rung")


def rake(w, d, h):
    cyl(0.012, h * 0.85, (0, 0, h * 0.5), PINE, "Z", 10, rot=(0.1, 0, 0), name="handle")
    box((w, d * 0.3, 0.03), (0, -0.04, 0.05), STEEL, 0.004, name="head")
    for i in range(8):
        cyl(0.004, 0.06, (-w / 2 + 0.02 + i * (w - 0.04) / 7, -0.06, 0.03), STEEL, "Z", 6, rot=(0.6, 0, 0), name="tine")


def hose_reel(w, d, h):
    for y in (-d * 0.3, d * 0.3):
        cyl(0.012, h * 0.9, (0, y, h * 0.45), STEEL, "Z", 8, name="stand")
    cyl(0.01, d * 0.6, (0, 0, h * 0.72), STEEL, "Y", 8, name="axle")
    cyl(w / 2, d * 0.5, (0, 0, h * 0.72), GREEN, "Y", 20, name="hose")
    cyl(w / 2 + 0.01, 0.015, (0, -d * 0.26, h * 0.72), STEEL, "Y", 20, name="flange")
    cyl(w / 2 + 0.01, 0.015, (0, d * 0.26, h * 0.72), STEEL, "Y", 20, name="flange")
    cyl(0.01, 0.12, (w * 0.35, d * 0.3, h * 0.72), DARK, "Y", 8, name="crank")


BUILDERS = {name: fn for name, fn in globals().items() if callable(fn) and not name.startswith("_") and name not in ("mat", "box", "cyl", "sphere", "legs", "cabinet")}


def build(item_id, dims):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _materials.clear()
    BUILDERS[item_id](dims["w"], dims["d"], dims["h"])
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(OUT, "hh_%s.glb" % item_id)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    return path


def main(argv):
    content = json.load(open(os.path.join(ROOT, "data", "content.json")))["items"]
    wanted = [a for a in argv if a in BUILDERS] or [k for k in content if content[k].get("room") and k in BUILDERS]
    missing = [k for k in content if content[k].get("room") and k not in BUILDERS]
    if missing:
        print("no builder for:", ", ".join(missing))
    for item_id in wanted:
        d = content[item_id]
        path = build(item_id, {"w": float(d["w"]), "d": float(d["d"]), "h": float(d["h"])})
        print("built", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
