"""Contact sheet: every @1x output at 3x nearest, on mid-grey (top) and night-blue (bottom)."""
import json, os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
outs = json.load(open(ROOT + "/_build/outputs.json"))
ims = [(o["file"].split("/")[-1].replace("@1x.png", ""), Image.open(ROOT + "/" + o["file"]).convert("RGBA")) for o in outs]
S = 3; PAD = 10; MAXW = 1500
def layout():
    rows, row, x, h = [], [], PAD, 0
    for n, im in ims:
        w = im.width * S
        if x + w + PAD > MAXW and row: rows.append((row, h)); row, x, h = [], PAD, 0
        row.append((n, im, x)); x += w + PAD; h = max(h, im.height * S + 14)
    rows.append((row, h)); return rows
rows = layout(); H = sum(h + PAD for _, h in rows) + PAD
sheet = Image.new("RGBA", (MAXW, H * 2), (0, 0, 0, 255))
for k, bg in enumerate([(128, 128, 128, 255), (31, 38, 64, 255)]):
    panel = Image.new("RGBA", (MAXW, H), bg); d = ImageDraw.Draw(panel); y = PAD
    for row, h in rows:
        for n, im, x in row:
            big = im.resize((im.width * S, im.height * S), Image.NEAREST)
            panel.alpha_composite(big, (x, y + 12)); d.text((x, y), n, fill=(240, 240, 240, 255))
        y += h + PAD
    sheet.paste(panel, (0, H * k))
sheet.convert("RGB").save(ROOT + "/contact_sheet.png")
print(sheet.size)
