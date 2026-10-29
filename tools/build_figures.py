"""Build the people's body parts as GLB models with Blender's Python module.

    pip install bpy
    python3 tools/build_figures.py

Every part hangs from its joint: the origin is the pivot (top of the thigh,
the shoulder, the neck) and the part extends down -Z in Blender, which the
exporter turns into -Y in Godot, where scripts/figure.gd parents it under
the matching pivot node and recolours its meshes by name:

    skin, cloth, cloth2, trouser, trouser2, hair, shoe, eye, accent

The sizes match the primitives figure.gd used before, so the walk cycle,
the sit, the carry and the action poses read the same.
"""
import math
import os

import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "models")

ROLE_COLORS = {
    "skin": "E7C9A8", "cloth": "D9765F", "cloth2": "B85C48", "trouser": "3E3A4F", "trouser2": "35314A",
    "hair": "4A3626", "shoe": "2B2622", "eye": "2B2622", "accent": "E6B655", "mouth": "B86A5C",
}
_materials = {}


def mat(role):
    if role in _materials:
        return _materials[role]
    m = bpy.data.materials.new(role)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    hex_color = ROLE_COLORS[role]
    r, g, b = (int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (r, g, b)]
    bsdf.inputs["Base Color"].default_value = (*lin, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    _materials[role] = m
    return m


def _finish(o, role, name, bevel=0.0):
    o.name = name
    o.data.materials.append(mat(role))
    if bevel > 0:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    shade = o.modifiers.new("smooth", "SMOOTH") if False else None
    return o


def box(size, at, role, name, bevel=0.01, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=at, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, role, name, min(bevel, min(size) * 0.3))


def cyl(r, h, at, role, name, axis="Z", verts=16, r2=None, rot=None, bevel=0.0):
    rotation = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}[axis]
    if rot is not None:
        rotation = rot
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=at, rotation=rotation)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=h, location=at, rotation=rotation)
    o = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    return _finish(o, role, name, bevel)


def sphere(r, at, role, name, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=r, location=at)
    o = bpy.context.active_object
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    bpy.ops.object.shade_smooth()
    return _finish(o, role, name)


# -------------------------------------------------------------------- heads
# The head's origin is its centre (figure.gd places it at the neck height it
# already uses). The face looks down -Y in Blender, +Z in Godot.

def _face(r):
    sphere(r, (0, 0, 0), "skin", "skin_head", (1.0, 0.96, 1.06))
    for x in (-0.055, 0.055):
        sphere(0.02, (x * r / 0.15, -r * 0.86, r * 0.12), "eye", "eye")
        box((0.05, 0.012, 0.012), (x * r / 0.15, -r * 0.9, r * 0.32), "hair", "brow", 0.0, rot=(0, -0.2 if x < 0 else 0.2, 0))
    box((0.03, 0.035, 0.035), (0, -r * 0.98, -r * 0.02), "skin", "skin_nose", 0.008)
    box((0.045, 0.01, 0.012), (0, -r * 0.92, -r * 0.3), "mouth", "mouth", 0.0)
    for x in (-1, 1):
        sphere(0.028, (x * r * 0.98, 0, 0), "skin", "skin_ear", (0.5, 1, 1))


def head_short(r=0.15):
    _face(r)
    sphere(r * 1.04, (0, r * 0.06, r * 0.18), "hair", "hair", (1, 1, 0.78))
    box((r * 1.4, r * 0.5, r * 0.35), (0, -r * 0.75, r * 0.72), "hair", "hair_fringe", 0.02)


def head_bob(r=0.15):
    _face(r)
    sphere(r * 1.08, (0, r * 0.08, r * 0.1), "hair", "hair", (1, 1, 0.9))
    box((r * 2.1, r * 1.3, r * 1.1), (0, r * 0.3, -r * 0.35), "hair", "hair_sides", 0.04)
    box((r * 1.5, r * 0.5, r * 0.3), (0, -r * 0.78, r * 0.74), "hair", "hair_fringe", 0.02)


def head_ponytail(r=0.15):
    _face(r)
    sphere(r * 1.04, (0, r * 0.06, r * 0.18), "hair", "hair", (1, 1, 0.8))
    cyl(r * 0.28, r * 1.6, (0, r * 0.95, -r * 0.5), "hair", "hair_tail", "Z", 12, r2=r * 0.12, rot=(0.35, 0, 0))
    box((r * 0.8, r * 0.3, r * 0.3), (0, r * 0.85, r * 0.25), "accent", "accent_band", 0.02)


def head_bun(r=0.15):
    _face(r)
    sphere(r * 1.03, (0, r * 0.05, r * 0.16), "hair", "hair", (1, 1, 0.8))
    sphere(r * 0.42, (0, r * 0.55, r * 0.95), "hair", "hair_bun")


def head_bald(r=0.15):
    _face(r)
    box((r * 2.0, r * 1.2, r * 0.5), (0, r * 0.4, -r * 0.2), "hair", "hair_ring", 0.04)


def head_curly(r=0.15):
    _face(r)
    for i in range(9):
        a = i * 2 * math.pi / 9
        sphere(r * 0.42, (math.cos(a) * r * 0.85, math.sin(a) * r * 0.85 + r * 0.15, r * 0.55), "hair", "hair_curl")
    sphere(r * 0.6, (0, r * 0.1, r * 0.95), "hair", "hair_top")


def head_cap(r=0.15):
    _face(r)
    sphere(r * 1.02, (0, r * 0.05, r * 0.16), "hair", "hair", (1, 1, 0.75))
    sphere(r * 1.08, (0, r * 0.05, r * 0.3), "accent", "accent_cap", (1, 1, 0.62))
    box((r * 1.4, r * 0.9, r * 0.1), (0, -r * 1.1, r * 0.45), "accent", "accent_peak", 0.01)


# ------------------------------------------------------------------- torsos
# Origin at the hips; the body rises +Z to the shoulders at 0.46.

def _body():
    box((0.38, 0.23, 0.44), (0, 0, 0.23), "cloth", "cloth_body", 0.06)
    cyl(0.055, 0.09, (0, 0, 0.47), "skin", "skin_neck", "Z", 12)


def torso_tee():
    _body()
    box((0.14, 0.012, 0.08), (0, -0.12, 0.12), "cloth2", "cloth2_print", 0.01)


def torso_shirt():
    _body()
    box((0.2, 0.06, 0.07), (0, -0.09, 0.44), "cloth2", "cloth2_collar", 0.012)
    for z in (0.12, 0.22, 0.32):
        sphere(0.012, (0, -0.118, z), "accent", "accent_button")


def torso_jacket():
    _body()
    for x in (-0.11, 0.11):
        box((0.14, 0.03, 0.4), (x, -0.11, 0.22), "cloth2", "cloth2_lapel", 0.02)
    box((0.1, 0.02, 0.36), (0, -0.115, 0.2), "accent", "accent_inner", 0.01)


def torso_apron():
    _body()
    box((0.22, 0.02, 0.36), (0, -0.12, 0.2), "cloth2", "cloth2_bib", 0.02)
    box((0.04, 0.012, 0.16), (0, -0.126, 0.39), "cloth2", "cloth2_strap", 0.0)
    box((0.12, 0.012, 0.08), (0, -0.13, 0.14), "accent", "accent_pocket", 0.01)


# -------------------------------------------------------------------- limbs

def thigh():
    cyl(0.072, 0.28, (0, 0, -0.14), "trouser", "trouser_thigh", "Z", 14, r2=0.062, bevel=0.0)
    sphere(0.066, (0, 0, -0.28), "trouser", "trouser_knee")


def shin():
    cyl(0.06, 0.24, (0, 0, -0.12), "trouser2", "trouser2_shin", "Z", 14, r2=0.05)
    box((0.11, 0.2, 0.06), (0, -0.04, -0.24), "shoe", "shoe", 0.015)
    box((0.11, 0.08, 0.03), (0, -0.1, -0.255), "shoe", "shoe_toe", 0.01)


def upper_arm():
    sphere(0.06, (0, 0, 0), "cloth", "cloth_shoulder")
    cyl(0.052, 0.24, (0, 0, -0.12), "cloth2", "cloth2_sleeve", "Z", 12, r2=0.045)


def fore_arm():
    cyl(0.045, 0.2, (0, 0, -0.1), "skin", "skin_forearm", "Z", 12, r2=0.04)
    sphere(0.05, (0, 0, -0.22), "skin", "skin_hand", (1, 0.8, 1.1))


PARTS = {
    "fig_head_short": head_short, "fig_head_bob": head_bob, "fig_head_ponytail": head_ponytail,
    "fig_head_bun": head_bun, "fig_head_bald": head_bald, "fig_head_curly": head_curly, "fig_head_cap": head_cap,
    "fig_torso_tee": torso_tee, "fig_torso_shirt": torso_shirt, "fig_torso_jacket": torso_jacket, "fig_torso_apron": torso_apron,
    "fig_thigh": thigh, "fig_shin": shin, "fig_upper_arm": upper_arm, "fig_fore_arm": fore_arm,
}


def main():
    for name, fn in PARTS.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        _materials.clear()
        fn()
        bpy.ops.object.select_all(action="SELECT")
        path = os.path.join(OUT, name + ".glb")
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
        print("built", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
