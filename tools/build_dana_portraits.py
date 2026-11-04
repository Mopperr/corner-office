#!/usr/bin/env python3
"""Cut Dana's rendered portraits into the HUD's icons and expression cards.

Usage: build_dana_portraits.py <renders dir>  where <dir>/<expr>/figure_dana_portrait.png
exist for neutral, happy, proud and surprised (from tests/figure_peek.tscn with
CO_DANA_FACE set per expression). Writes assets/characters/dana/portraits/
expressions/dana_portrait_<expr>.png (640x640) and icons/dana_portrait_circle_<n>.png.
Procedural (Pillow), replaces the team's painted set with renders of the same face.
"""
import sys
from PIL import Image, ImageDraw

BASE = "assets/characters/dana/portraits"
FACE_CENTRE = (618, 285)
FACE_SIZE = 560
CREAM = (244, 233, 216, 255)


def square(path):
    im = Image.open(path).convert("RGBA")
    cx, cy = FACE_CENTRE
    half = FACE_SIZE // 2
    box = (cx - half, max(0, cy - half), cx + half, max(0, cy - half) + FACE_SIZE)
    crop = im.crop(box)
    return crop.resize((640, 640), Image.LANCZOS)


def circle(img, size):
    im = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size * 4 - 1, size * 4 - 1], fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def main():
    src = sys.argv[1]
    faces = {}
    for expr in ["neutral", "happy", "proud", "surprised"]:
        faces[expr] = square(f"{src}/{expr}/figure_dana_portrait.png")
        faces[expr].save(f"{BASE}/expressions/dana_portrait_{expr}.png")
    faces["neutral"].save(f"{BASE}/expressions/dana_portrait_base.png")
    faces["happy"].save(f"{BASE}/dana_portrait.png")
    faces["happy"].resize((320, 320), Image.LANCZOS).save(f"{BASE}/dana_portrait@1x.png")
    for n in (64, 128, 256, 512):
        circle(faces["happy"], n).save(f"{BASE}/icons/dana_portrait_circle_{n}.png")
        circle(faces["neutral"], n).save(f"{BASE}/icons/dana_icon_{n}.png")
    print("portraits built")


if __name__ == "__main__":
    main()
