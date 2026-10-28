"""Design copy of Art's contact_sheet.py: python3 contact_sheet_design.py batch1|batch2"""
import os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
FAM = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
B1 = ["floor_lamp_v", "kitchen_trolley", "high_chair", "laundry_hamper", "bath_bin", "side_table_v", "dressing_stool", "armchair_v", "coat_stand", "rocking_chair"]
B2 = ["bean_bag", "coffee_table_v", "cot", "clothes_rail", "bedroom_chair", "footstool", "picture_v", "wall_mirror", "tall_bookcase", "trunk_v"]
batch = sys.argv[1]
B3 = ["keyboard_piano", "log_basket", "suitcase_stack", "mirror_oval", "mug", "plate_stack", "saucepan", "jug", "storage_jar", "towel_pile"]
B4 = ["poster", "towel_rail", "pram", "skis", "mannequin", "planter_box", "bowl_set", "casserole", "cookbooks", "bath_plant"]
B5 = ["school_desk", "sawhorse", "tray", "towel_rail_bath", "office_poster", "sideboard", "cushion_set", "tree_box", "utensil_jar", "stand_mixer"]
B6 = ["whiteboard", "cork_board", "fruit_bowl", "blender", "toothbrush_set", "soap_dish", "hair_dryer", "jewellery_box", "hangers", "dollhouse"]
B7 = ["cake_stand", "egg_box", "bread_board", "salt_pepper", "cutlery_tray", "bath_scales", "toiletries", "candle_holder", "aquarium", "typewriter"]
B8 = ["loo_roll", "medicine_cabinet", "bath_caddy", "string_lights", "console", "chess_set", "trophy", "old_lamp", "model_ship", "bucket"]
B9 = ["picture_stack", "gramophone", "dartboard", "bird_cage", "vinyl_crate", "sewing_machine", "tool_box_v", "paint_cans", "flower_pot_v", "spades"]
B10 = ["axe_logs", "desk_lamp", "monitor", "keyboard_mouse", "printer", "paper_tray", "pen_pot", "laptop", "desk_phone", "desk_tidy"]
ids = {"batch1": B1, "batch2": B2, "batch4": B4, "batch5": B5, "batch6": B6, "batch7": B7, "batch8": B8, "batch9": B9, "batch10": B10}.get(batch, B3)
suffix = sys.argv[2] if len(sys.argv) > 2 else ""
dest = os.path.join(FAM, batch, "%s_contact_design%s.png" % (batch, suffix))
files = [os.path.join(HERE, "renders", batch, "hh_cat_%s%s.png" % (i, suffix)) for i in ids]
cols, T, LB = 5, 300, 34
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * T, rows * (T + LB) + 40), (235, 232, 226))
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 17)
small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
d.text((10, 10), "Corner Office catalogue families - %s, design share 10 (hh_cat_*.glb, plain variant, first colour-way on 'way')" % batch, fill=(40, 36, 34), font=small)
for i, (fid, f) in enumerate(zip(ids, files)):
    im = Image.open(f).convert("RGB").resize((T, T), Image.LANCZOS)
    x, y = (i % cols) * T, 40 + (i // cols) * (T + LB)
    sheet.paste(im, (x, y))
    d.text((x + 8, y + T + 7), fid, fill=(40, 36, 34), font=font)
sheet.save(dest)
print(dest, sheet.size)
