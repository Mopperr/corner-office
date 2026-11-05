"""Assemble _build/renders/*.png into ../../batch10_contact_art.png with labels."""
import glob, os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(os.path.dirname(HERE))  # .../batch10
MINE = ["coffee_machine_v", "mug_tree", "folder_stack", "desk_fan", "office_kettle", "reception_sign", "projector", "office_speaker", "stapler_set", "dispatch_scale", "globe_office", "desk_calendar"]
suffix = sys.argv[1] if len(sys.argv) > 1 else ""
dest = sys.argv[2] if len(sys.argv) > 2 else os.path.join(OUT, "batch10_contact_art.png")
files = [os.path.join(HERE, "renders", "hh_cat_%s%s.png" % (i, suffix)) for i in MINE]
cols = 5
T = 300
LB = 34
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * T, rows * (T + LB) + 40), (235, 232, 226))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 17)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
except OSError:
    font = small = ImageFont.load_default()
d.text((10, 10), "Corner Office catalogue families - batch 10, art share 12/22 (hh_cat_*.glb, plain variant, first colour-way on 'way')", fill=(40, 36, 34), font=small)
for i, f in enumerate(files):
    im = Image.open(f).convert("RGB").resize((T, T), Image.LANCZOS)
    x, y = (i % cols) * T, 40 + (i // cols) * (T + LB)
    sheet.paste(im, (x, y))
    name = os.path.basename(f)[7:-4].replace(suffix, "")
    d.text((x + 8, y + T + 7), name, fill=(40, 36, 34), font=font)
sheet.save(dest)
print(dest, sheet.size)
