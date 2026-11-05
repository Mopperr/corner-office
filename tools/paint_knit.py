#!/usr/bin/env python3
"""A grey rib-knit texture to tint at load (Pillow, procedural).
Writes assets/characters/dana/face/rib_knit_grey.png (512x512, tiles)."""
from PIL import Image
import math

SIZE = 256
img = Image.new("RGB", (SIZE, SIZE))
px = img.load()
for y in range(SIZE):
    for x in range(SIZE):
        rib = 0.5 + 0.5 * math.cos(x / SIZE * 2 * math.pi * 16)
        stitch = 0.5 + 0.5 * math.cos(y / SIZE * 2 * math.pi * 32 + (1.5 if int(x / SIZE * 16) % 2 else 0.0))
        v = 170 + int(rib * 55) + int(stitch * 22)
        v = max(0, min(255, v))
        px[x, y] = (v, v, v)
img.save("assets/characters/dana/face/rib_knit_grey.png")
print("wrote knit")
