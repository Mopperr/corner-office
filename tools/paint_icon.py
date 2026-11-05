#!/usr/bin/env python3
"""Paint the game's icon: a kraft moving box with a tape cross and a mustard
sticky note, a sage sprig poking out of the top, on a terracotta tile.
Drawn large and downsampled, so every size from 16 to 256 stays crisp.

    python3 tools/paint_icon.py        # writes icon.png (256) and icon.ico

Procedural only, in the UI kit's palette."""
from PIL import Image, ImageDraw, ImageFilter
import math, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 1024
TERRA = (217, 118, 95)
TERRA_DEEP = (196, 100, 80)
CREAM = (255, 248, 236)
KRAFT = (214, 165, 112)
KRAFT_SIDE = (176, 126, 82)
KRAFT_TOP = (232, 192, 142)
DARK = (107, 74, 58)
MUSTARD = (230, 182, 85)
SAGE = (143, 175, 126)
SAGE_DEEP = (110, 142, 96)
TAPE = (244, 233, 216)


def rounded(draw, box, r, fill):
    draw.rounded_rectangle(box, radius=r, fill=fill)


def poly(draw, pts, fill):
    draw.polygon([(x, y) for x, y in pts], fill=fill)


def main():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # The tile: terracotta with a deeper lower-right so it reads as lit from the top left.
    rounded(d, (0, 0, S - 1, S - 1), 220, TERRA)
    shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.polygon([(S, 0), (S, S), (0, S)], fill=TERRA_DEEP + (255,))
    shade = shade.filter(ImageFilter.GaussianBlur(140))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), radius=220, fill=255)
    img.paste(Image.alpha_composite(img, shade), (0, 0), mask)
    d = ImageDraw.Draw(img)
    # A soft shadow under the box.
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((220, 770, 880, 910), fill=(90, 40, 30, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, sh)
    d = ImageDraw.Draw(img)
    # The box, three faces: front, right side, top; a little low and left of centre.
    fx0, fy0, fx1, fy1 = 230, 430, 670, 830
    dx, dy = 150, -110
    front = [(fx0, fy0), (fx1, fy0), (fx1, fy1), (fx0, fy1)]
    side = [(fx1, fy0), (fx1 + dx, fy0 + dy), (fx1 + dx, fy1 + dy), (fx1, fy1)]
    top = [(fx0, fy0), (fx0 + dx, fy0 + dy), (fx1 + dx, fy0 + dy), (fx1, fy0)]
    poly(d, side, KRAFT_SIDE)
    poly(d, top, KRAFT_TOP)
    poly(d, front, KRAFT)
    # The flap seam on top and a tape strip across it, running down the front.
    mid_top = [(fx0 + dx * 0.5 + 120, fy0 + dy * 0.5 - 10)]
    tape_w = 62
    cx = (fx0 + fx1) * 0.5
    poly(d, [(cx - tape_w / 2, fy0), (cx - tape_w / 2 + dx, fy0 + dy), (cx + tape_w / 2 + dx, fy0 + dy), (cx + tape_w / 2, fy0)], TAPE)
    d.rectangle((cx - tape_w / 2, fy0, cx + tape_w / 2, fy1), fill=TAPE)
    # Flap line across the top, so it reads as a sealed box.
    d.line([(fx0 + 10, fy0 + dy * 0.5 + 55 - 55 * 0 ), (fx1 + 10, fy0 + dy * 0.5 + 55 - 55 * 0)], fill=(196, 150, 104), width=10)
    # Box edges.
    d.line(front + [front[0]], fill=DARK, width=14, joint="curve")
    d.line(side + [side[0]], fill=DARK, width=14, joint="curve")
    d.line(top + [top[0]], fill=DARK, width=14, joint="curve")
    # The sticky note, a little askew, with two scribbled lines.
    note = Image.new("RGBA", (300, 300), (0, 0, 0, 0))
    nd = ImageDraw.Draw(note)
    nd.rectangle((40, 40, 260, 260), fill=MUSTARD)
    nd.line([(80, 120), (220, 120)], fill=DARK, width=18)
    nd.line([(80, 180), (180, 180)], fill=DARK, width=18)
    note = note.rotate(-7, resample=Image.BICUBIC)
    img.alpha_composite(note, (305, 520))
    d = ImageDraw.Draw(img)
    # A sage sprig out of the top, behind the tape: a stem and three leaves.
    stem = [(590, 340), (605, 260), (630, 180)]
    d.line(stem, fill=SAGE_DEEP, width=22, joint="curve")
    for (x, y, ang, flip) in [(595, 300, -40, 1), (615, 225, 25, -1), (632, 160, -15, 1)]:
        leaf = Image.new("RGBA", (260, 160), (0, 0, 0, 0))
        ld = ImageDraw.Draw(leaf)
        ld.ellipse((20, 40, 240, 120), fill=SAGE)
        ld.line([(30, 80), (230, 80)], fill=SAGE_DEEP, width=8)
        leaf = leaf.rotate(ang, resample=Image.BICUBIC, expand=True)
        if flip < 0:
            leaf = leaf.transpose(Image.FLIP_LEFT_RIGHT)
        img.alpha_composite(leaf, (x - leaf.width // 2 + (70 if flip > 0 else -70), y - leaf.height // 2))
    # Outputs.
    big = img.resize((256, 256), Image.LANCZOS)
    big.save(os.path.join(ROOT, "icon.png"))
    big.save(os.path.join(ROOT, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    img.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "docs", "icon_512.png"))
    print("icon.png, icon.ico, docs/icon_512.png")


if __name__ == "__main__":
    main()
