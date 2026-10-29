"""Design copy of Art's render_contact.py. Render each hh_cat_*.glb (3/4 front view, neutral light) to _build/design/renders/<batch>/.

    ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py -- [family_id ...]
Then run: python3 contact_sheet.py
"""
import glob
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
B1 = os.path.dirname(os.path.dirname(HERE))
FAM = os.path.dirname(B1)

RD = os.path.join(HERE, "renders")
os.makedirs(RD, exist_ok=True)


def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x = sc.render.resolution_y = 480
    sc.eevee.taa_render_samples = 32
    sc.view_settings.view_transform = "Standard"
    w = bpy.data.worlds.new("W")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.62, 0.62, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    for name, rot, e in (("key", (50, 0, -40), 3.2), ("fill", (60, 0, 140), 1.0)):
        ld = bpy.data.lights.new(name, "SUN")
        ld.energy = e
        ld.angle = math.radians(15)
        o = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(o)
        o.rotation_euler = [math.radians(a) for a in rot]
    # floor
    bpy.ops.mesh.primitive_plane_add(size=20)
    fl = bpy.context.active_object
    m = bpy.data.materials.new("floor")
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.55, 0.55, 0.55, 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    fl.data.materials.append(m)
    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    co = bpy.data.objects.new("cam", cam)
    sc.collection.objects.link(co)
    sc.camera = co
    return co


def render(path, view="front34"):
    co = setup()
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.name != "Plane"]
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (mn + mx) / 2
    size = max((mx - mn).length, 0.2)
    az = {"front34": -35, "front": 0, "side": -90, "back34": 145}[view]
    el = 22 if view != "front" else 8
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    co.location = ctr + dirv * 6
    co.rotation_euler = (-dirv).to_track_quat("-Z", "Y").to_euler()
    co.data.ortho_scale = size * 1.08
    co.data.clip_end = 50
    bpy.context.scene.render.filepath = os.path.join(RD, os.path.basename(path)[:-4] + ("" if view == "front34" else "_" + view) + ".png")
    bpy.ops.render.render(write_still=True)


argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
batch = argv[0]
views = [a[5:] for a in argv[1:] if a.startswith("view=")] or ["front34"]
ids = [a for a in argv[1:] if not a.startswith("view=")]
src = os.path.join(FAM, batch)
RD = os.path.join(HERE, "renders", batch)
os.makedirs(RD, exist_ok=True)
sys.path.insert(0, HERE)
import build_families_design as _b  # family lists only
fams = {"batch1": _b.BATCH1, "batch2": _b.BATCH2, "batch4": ["poster", "towel_rail", "pram", "skis", "mannequin", "planter_box", "bowl_set", "casserole", "cookbooks", "bath_plant"], "batch5": ["school_desk", "sawhorse", "tray", "towel_rail_bath", "office_poster", "sideboard", "cushion_set", "tree_box", "utensil_jar", "stand_mixer"], "batch6": ["whiteboard", "cork_board", "fruit_bowl", "blender", "toothbrush_set", "soap_dish", "hair_dryer", "jewellery_box", "hangers", "dollhouse"], "batch7": ["cake_stand", "egg_box", "bread_board", "salt_pepper", "cutlery_tray", "bath_scales", "toiletries", "candle_holder", "aquarium", "typewriter"], "batch8": ["loo_roll", "medicine_cabinet", "bath_caddy", "string_lights", "console", "chess_set", "trophy", "old_lamp", "model_ship", "bucket"], "batch9": ["picture_stack", "gramophone", "dartboard", "bird_cage", "vinyl_crate", "sewing_machine", "tool_box_v", "paint_cans", "flower_pot_v", "spades"], "batch10": ["axe_logs", "desk_lamp", "monitor", "keyboard_mouse", "printer", "paper_tray", "pen_pot", "laptop", "desk_phone", "desk_tidy"]}.get(batch) or ["keyboard_piano", "log_basket", "suitcase_stack", "mirror_oval", "mug", "plate_stack", "saucepan", "jug", "storage_jar", "towel_pile"]
for fid in (ids or fams):
    for v in views:
        render(os.path.join(src, "hh_cat_%s.glb" % fid), v)
        print("RENDERED", fid, v)
