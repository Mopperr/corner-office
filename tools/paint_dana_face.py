#!/usr/bin/env python3
"""Paint Dana's face: a livelier version of the team's painted texture.

Procedural only (Pillow), no image generation. Same 1024x1024 layout as
dana_matched_dana_face.png so it drops onto the same UVs: eyes centred on
y 540, mouth on y 800. Bigger, brighter eyes with a catchlight and lashes,
lifted brows, a wider smile with a glint of teeth, warm blush, a few
freckles, and the skin tone kept at the team's value.

Writes assets/characters/dana/face/dana_face_v3.png
"""
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SKIN = (232, 194, 160)
BROW = (54, 38, 30)
IRIS = (120, 74, 36)
IRIS_DARK = (78, 46, 20)
WHITE = (250, 246, 240)
LASH = (40, 28, 24)
LIP = (196, 96, 112)
LIP_DARK = (150, 64, 86)
BLUSH = (246, 176, 170)
FRECKLE = (168, 118, 88)


def ellipse(draw, cx, cy, rx, ry, fill, outline=None, width=0):
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill, outline=outline, width=width)


def main():
    img = Image.new("RGB", (SIZE, SIZE), SKIN)
    # Blush, soft.
    blush = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blush)
    for cx in (300, 724):
        ellipse(bd, cx, 690, 96, 62, BLUSH + (105,))
    blush = blush.filter(ImageFilter.GaussianBlur(34))
    img.paste(blush, (0, 0), blush)
    d = ImageDraw.Draw(img)
    # Brows: lifted, tapered arcs.
    for sx in (-1, 1):
        cx = 512 + sx * 170
        pts = []
        for i in range(0, 21):
            t = i / 20.0
            x = cx + (t - 0.5) * 230 * sx
            y = 352 - 44 * (1 - (2 * t - 1) ** 2) + (18 if sx * (t - 0.5) > 0 else 0) * abs(t - 0.5) * 2
            pts.append((x, y))
        d.line(pts, fill=BROW, width=11, joint="curve")
    # Eyes: big and bright.
    for sx in (-1, 1):
        cx = 512 + sx * 172
        cy = 548
        ellipse(d, cx, cy, 92, 74, WHITE)
        # upper lid shadow
        shade = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shade)
        ellipse(sd, cx, cy - 36, 92, 44, (120, 90, 80, 60))
        shade = shade.filter(ImageFilter.GaussianBlur(12))
        img.paste(shade, (0, 0), shade)
        d = ImageDraw.Draw(img)
        ellipse(d, cx + sx * 6, cy + 4, 56, 58, IRIS)
        ellipse(d, cx + sx * 6, cy + 10, 48, 46, IRIS_DARK)
        ellipse(d, cx + sx * 6, cy + 6, 26, 28, (18, 12, 10))
        # catchlights
        ellipse(d, cx + sx * 6 - 18, cy - 20, 18, 16, WHITE)
        ellipse(d, cx + sx * 6 + 22, cy + 26, 8, 7, WHITE)
        # lid line and lashes
        lid = [(cx - 94, cy - 10)]
        for i in range(1, 20):
            t = i / 20.0
            lid.append((cx - 94 + t * 188, cy - 10 - 70 * (1 - (2 * t - 1) ** 2)))
        lid.append((cx + 94, cy - 10))
        d.line(lid, fill=LASH, width=12, joint="curve")
        for k in range(4):
            ox = cx + sx * (44 + k * 14)
            oy = cy - 60 + k * 14
            d.line([(ox, oy), (ox + sx * 26, oy - 26)], fill=LASH, width=7)
        # lower lid, faint
        d.arc([cx - 90, cy - 50, cx + 90, cy + 74], 20, 160, fill=(150, 110, 96), width=4)
    # Freckles across the nose and cheeks.
    for (fx, fy) in ((430, 650), (452, 668), (470, 640), (560, 646), (584, 664), (606, 642), (520, 690), (500, 710), (540, 706)):
        ellipse(d, fx, fy, 5, 5, FRECKLE)
    # Nose: two soft dots.
    nose = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    nd = ImageDraw.Draw(nose)
    for nx in (478, 546):
        ellipse(nd, nx, 712, 10, 8, (150, 100, 80, 110))
    nose = nose.filter(ImageFilter.GaussianBlur(5))
    img.paste(nose, (0, 0), nose)
    d = ImageDraw.Draw(img)
    # Mouth: a wide smile with a lower lip and a glint of teeth.
    smile = []
    for i in range(0, 31):
        t = i / 30.0
        x = 372 + t * 280
        y = 790 + 58 * (1 - (2 * t - 1) ** 2)
        smile.append((x, y))
    d.line(smile, fill=LIP_DARK, width=10, joint="curve")
    lower = [(p[0], p[1] + 2) for p in smile]
    poly = smile + [(x, y + 26 * (1 - ((x - 512) / 140.0) ** 2)) for (x, y) in reversed(lower)]
    d.polygon(poly, fill=LIP)
    teeth = [(x, y + 1) for (x, y) in smile[8:23]] + [(x, y + 9) for (x, y) in reversed(smile[8:23])]
    d.polygon(teeth, fill=(250, 246, 238))
    d.line(smile, fill=LIP_DARK, width=6, joint="curve")
    out = "assets/characters/dana/face/dana_face_v3.png"
    img.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
