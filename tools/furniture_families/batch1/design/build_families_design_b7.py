"""Design Specialist builder, batch 7 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b7.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only),
scaled() from b3, rod()/lathe()/prism_xz() from b4 and xform()/M_at() + aliases from b6.
Output: families/batch7/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender),
flat matte rough 0.82, palette only, material 'way' = first colour-way.
"""
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402
import build_families_design_b3 as D3  # noqa: E402
import build_families_design_b4 as D4  # noqa: E402
import build_families_design_b6 as D6  # noqa: E402  (also registers aluminium/velvet/wire aliases)

art = D.art
box, cyl, sphere, torus, arc_bar = art.box, art.cyl, art.sphere, art.torus, art.arc_bar
scaled, rod, lathe, prism_xz = D3.scaled, D4.rod, D4.lathe, D4.prism_xz
snapshot, objs_since, xform, M_at = D6.snapshot, D6.objs_since, D6.xform, D6.M_at
WAY = art.WAY
# All batch-7 first colour-ways are palette keys. Later ones: wicker -> kraft, wire -> steel (existing),
# wood -> oak (new). copper (candle_holder) is not allowed and gets no alias.
D.ALIAS.update({"wood": "oak"})

BATCH7 = ["cake_stand", "egg_box", "bread_board", "salt_pepper", "cutlery_tray", "bath_scales",
          "toiletries", "candle_holder", "aquarium", "typewriter"]
B7 = {}


def reg(f):
    B7[f.__name__] = f
    return f


def ell(r3, at, color, name="part", rot=(0, 0, 0)):
    """Ellipsoid with semi-axes r3 (world axes after rot is baked)."""
    o = sphere(1.0, at, color, name=name, rot=rot)
    return scaled(o, r3)


def prism_yz(pts, x0, x1, color, name="part"):
    """Side profile [(y, z)] extruded along X from x0 to x1 (x0 = -x1)."""
    o = prism_xz(pts, x0, x1, color, name=name)
    o.rotation_euler = (0, 0, math.pi / 2)
    return o


# ------------------------------------------------------------------ kitchen
@reg
def cake_stand(w, d, h):
    # two-tier stand: `way` (cream) foot + plates on a brass rod; cupcakes below, iced cake on top
    R = w / 2
    lathe([(0.055, 0.0), (0.055, 0.006), (0.03, 0.012), (0.016, 0.026), (0.012, 0.03), (0.001, 0.03)], WAY, segs=28, name="foot")
    cyl(R - 0.003, 0.008, (0, 0, 0.034), WAY, verts=40, name="plate")
    torus(R - 0.004, 0.004, (0, 0, 0.039), WAY, seg=48, name="plate_rim")
    rod((0, 0, 0.03), (0, 0, 0.112), 0.006, "brass", name="rod")
    torus(0.008, 0.003, (0, 0, 0.11), "brass", seg=16, name="rod_collar")
    cyl(0.09, 0.006, (0, 0, 0.113), WAY, verts=36, name="plate")
    torus(0.088, 0.0035, (0, 0, 0.117), WAY, seg=40, name="plate_rim")
    for k in range(4):  # cupcakes on the lower tier
        a = math.radians(45 + 90 * k)
        x, y = 0.1 * math.cos(a), 0.1 * math.sin(a)
        lathe([(0.02, 0.0), (0.026, 0.024), (0.001, 0.024)], "mustard", segs=16, name="cupcake_case", at=(x, y, 0.038))
        ell((0.025, 0.025, 0.017), (x, y, 0.064), "white", name="icing")
        sphere(0.006, (x, y, 0.083), "red", name="cherry")
    # iced cake on the top tier
    cyl(0.062, 0.042, (0, 0, 0.116 + 0.021), "rose", verts=36, name="cake")
    cyl(0.064, 0.008, (0, 0, 0.116 + 0.042 + 0.004), "white", verts=36, bevel=0.003, name="icing")
    for k in range(10):  # icing drips
        a = 2 * math.pi * k / 10
        ell((0.007, 0.007, 0.011), (0.063 * math.cos(a), 0.063 * math.sin(a), 0.152), "white", name="icing")
    for k in range(5):
        a = 2 * math.pi * k / 5 + 0.3
        sphere(0.0065, (0.042 * math.cos(a), 0.042 * math.sin(a), 0.172), "red", name="cherry")
    sphere(0.008, (0, 0, 0.172), "red", name="cherry")


@reg
def egg_box(w, d, h):
    # egg basket/crate: `way` (sage) tray with six egg cups, six eggs (white and brown), carry handle
    bh = 0.034
    box((w, d, bh * 0.55), (0, 0, bh * 0.275), WAY, 0.006, name="base")
    for s in (-1, 1):
        box((w, 0.006, bh), (0, s * (d / 2 - 0.003), bh / 2), WAY, 0.002, name="wall")
        box((0.006, d, bh), (s * (w / 2 - 0.003), 0, bh / 2), WAY, 0.002, name="wall")
    cols = ["cream", "kraft", "cream", "kraft", "cream", "kraft"]
    k = 0
    for iy, y in enumerate((-0.032, 0.032)):
        for ix, x in enumerate((-0.062, 0.0, 0.062)):
            torus(0.022, 0.005, (x, y, bh * 0.55), WAY, seg=20, name="cup")
            ell((0.022, 0.022, 0.029), (x, y, bh * 0.55 + 0.022), cols[(ix + iy) % 2], name="egg",
                rot=(math.radians(6 * (ix - 1)), math.radians(5 * (1 - 2 * iy)), 0))
            k += 1
    # carry handle across the width (posts at the short ends)
    pts = [(-(w / 2 - 0.012) * math.cos(t), bh + (h - bh - 0.006) * math.sin(t)) for t in
           [math.pi * i / 16 for i in range(17)]]
    arc_bar(pts, 0.007, 0.014, WAY, name="handle", bevel=0.002, plane="XZ")
    for s in (-1, 1):
        box((0.018, 0.026, 0.02), (s * (w / 2 - 0.012), 0, bh), WAY, 0.003, name="handle_mount")


@reg
def bread_board(w, d, h):
    # `way` board with juice groove, crusty loaf (kraft) with cut slices (cream crumb), bread knife
    bt = 0.02
    box((w, d, bt), (0, 0, bt / 2), WAY, 0.004, name="board")
    for s in (-1, 1):
        box((w - 0.03, 0.004, 0.0012), (0, s * (d / 2 - 0.012), bt), "dark", 0.0, name="groove")
        box((0.004, d - 0.024, 0.0012), (s * (w / 2 - 0.015), 0, bt), "dark", 0.0, name="groove")
    lx = -0.035
    ell((0.095, 0.06, 0.05), (lx, 0.012, bt + 0.05), "kraft", name="loaf")
    box((0.005, 0.1, 0.075), (lx + 0.088, 0.012, bt + 0.035), "kraft", 0.0, name="loaf")  # cut end crust ring
    ell((0.002, 0.052, 0.043), (lx + 0.091, 0.012, bt + 0.048), "cream", name="crumb")
    for i, dx in enumerate((-0.05, -0.015, 0.02)):  # scores on the crust
        ell((0.007, 0.042, 0.004), (lx + dx, 0.012, bt + 0.098), "cream", name="score", rot=(0, 0, math.radians(-30)))
    for i in range(2):  # two cut slices lying fanned out
        x, y, z = 0.09, 0.03 - i * 0.03, bt + 0.006 + i * 0.012
        box((0.075, 0.095, 0.012), (x, y, z), "kraft", 0.012, rot=(0, 0, math.radians(8 - 14 * i)), name="slice")
        box((0.067, 0.087, 0.0124), (x, y, z + 0.0005), "cream", 0.009, rot=(0, 0, math.radians(8 - 14 * i)), name="slice_crumb")
    # bread knife along the front edge
    y = -d / 2 + 0.022
    box((0.17, 0.022, 0.002), (0.04, y, bt + 0.004), "steel", 0.0, name="knife_blade")
    for k in range(9):
        sphere(0.0035, (-0.035 + k * 0.017, y - 0.011, bt + 0.004), "steel", (1, 1, 0.3), name="serration")
    box((0.09, 0.02, 0.014), (-0.09, y, bt + 0.007), "dark", 0.006, name="knife_handle")


@reg
def salt_pepper(w, d, h):
    # pair of `way` (cream) round shakers with steel domed caps; salt has more holes, pepper has a grey band
    r = d / 2
    for s, name in ((-1, "salt"), (1, "pepper")):
        x = s * (w / 2 - r)
        lathe([(r - 0.004, 0.0), (r - 0.001, 0.004), (r, 0.03), (r - 0.004, 0.058), (r - 0.008, 0.068),
               (r - 0.009, 0.072)], WAY, segs=28, name=name, at=(x, 0, 0))
        lathe([(r - 0.007, 0.068), (r - 0.006, 0.08), (r - 0.009, 0.092), (r - 0.016, 0.098), (0.001, h)],
              "steel", segs=28, name="cap", at=(x, 0, 0))
        holes = [(0, 0)] + ([(0.0055 * math.cos(a), 0.0055 * math.sin(a)) for a in
                             [2 * math.pi * k / 6 for k in range(6)]] if name == "salt" else
                            [(0.005 * math.cos(a), 0.005 * math.sin(a)) for a in (0.5, 2.6, 4.7)])
        for hx, hy in holes:
            sphere(0.0016, (x + hx, hy, h - 0.0015 - (0.0025 if hx or hy else 0)), "dark", (1, 1, 0.5), name="hole")
        if name == "pepper":
            torus(r - 0.002, 0.0018, (x, 0, 0.03), "grey", seg=28, name="band")
            torus(r - 0.002, 0.0018, (x, 0, 0.022), "grey", seg=28, name="band")
        else:
            torus(r - 0.002, 0.0018, (x, 0, 0.026), WAY, seg=28, name="band")


def _fork(x, y, z, L, color="steel"):
    box((0.012, L * 0.62, 0.005), (x, y - L * 0.19, z), color, 0.0015, name="fork")
    box((0.022, L * 0.12, 0.004), (x, y + L * 0.17, z), color, 0.001, name="fork")
    for t in (-1.5, -0.5, 0.5, 1.5):
        box((0.003, L * 0.2, 0.0035), (x + t * 0.0055, y + L * 0.38, z), color, 0.0, name="tine")


def _knife(x, y, z, L):
    box((0.014, L * 0.45, 0.007), (x, y - L * 0.27, z + 0.001), "steel", 0.002, name="knife")
    box((0.018, L * 0.55, 0.003), (x + 0.002, y + L * 0.22, z), "steel", 0.001, name="knife")


def _spoon(x, y, z, L):
    box((0.012, L * 0.66, 0.005), (x, y - L * 0.17, z), "steel", 0.0015, name="spoon")
    ell((0.019 * L / 0.2, 0.028 * L / 0.2, 0.006), (x, y + L * 0.32, z), "steel", name="spoon")


@reg
def cutlery_tray(w, d, h):
    # `way` drawer insert: 4 long compartments at the front, one cross compartment at the back
    t = 0.008
    box((w, d, 0.006), (0, 0, 0.003), WAY, 0.002, name="base")
    for s in (-1, 1):
        box((w, t, h), (0, s * (d / 2 - t / 2), h / 2), WAY, 0.002, name="wall")
        box((t, d, h), (s * (w / 2 - t / 2), 0, h / 2), WAY, 0.002, name="wall")
    yb = d / 2 - 0.075                    # cross divider
    box((w - 2 * t, 0.006, h * 0.6), (0, yb, h * 0.3), WAY, 0.001, name="divider")
    inner = w - 2 * t
    xs = [-w / 2 + t + inner * (i + 0.5) / 4 for i in range(4)]
    for i in (1, 2, 3):
        box((0.006, yb + d / 2 - t, h * 0.6), (-w / 2 + t + inner * i / 4, (yb - d / 2 + t) / 2, h * 0.3), WAY, 0.001, name="divider")
    yc = (yb - d / 2 + t) / 2
    L = 0.17
    for k in range(2):
        z = 0.008 + k * 0.003
        _fork(xs[0] - 0.012 + k * 0.022, yc + k * 0.004, z, L)
        _knife(xs[1] - 0.012 + k * 0.022, yc - k * 0.004, z, L * 1.05)
        _spoon(xs[2] - 0.012 + k * 0.022, yc + k * 0.004, z, L)
        _spoon(xs[3] - 0.01 + k * 0.02, yc - 0.02 + k * 0.006, z, L * 0.72)
    # back compartment: serving spoon and a dark-handled spatula lying along X
    yk = (yb + d / 2 - t) / 2
    o0 = snapshot()
    _spoon(0, 0, 0.0, 0.2)
    xform(objs_since(o0), M_at((-0.05, yk, 0.009), (0, 0, math.radians(-90))))
    box((0.1, 0.014, 0.008), (0.1, yk + 0.006, 0.011), "dark", 0.003, name="spatula_handle")
    box((0.06, 0.03, 0.002), (0.02, yk + 0.006, 0.009), "steel", 0.002, name="spatula")


# ------------------------------------------------------------------ bathroom
SEG7 = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
        "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcfgd"}


def seg7(ch, x, y, z, s, color, name="digit"):
    """Seven-segment digit lying flat (top view), reading from the front (-Y)."""
    L, t = s, s * 0.22
    pos = {"a": (0, L, 1), "g": (0, 0, 1), "d": (0, -L, 1),
           "f": (-L / 2, L / 2, 0), "b": (L / 2, L / 2, 0), "e": (-L / 2, -L / 2, 0), "c": (L / 2, -L / 2, 0)}
    for k in SEG7[ch]:
        dx, dy, horiz = pos[k]
        size = (L * 0.8, t, 0.0008) if horiz else (t, L * 0.8, 0.0008)
        box(size, (x + dx, y + dy, z), color, 0.0, name=name)


@reg
def bath_scales(w, d, h):
    # `way` (black) platform on feet, steel edge band, grey foot pads, glass LCD with "68.4"
    fh = 0.005
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl(0.012, fh, (sx * (w / 2 - 0.04), sy * (d / 2 - 0.04), fh / 2), "grey", verts=14, name="foot")
    bh = h - fh - 0.004
    box((w, d, bh), (0, 0, fh + bh / 2), WAY, 0.018, name="body")
    box((w - 0.004, d - 0.004, 0.006), (0, 0, fh + bh * 0.35), "steel", 0.0, name="edge_band")
    zt = fh + bh
    for s in (-1, 1):  # foot pads
        ell((0.045, 0.075, 0.002), (s * 0.065, 0.035, zt + 0.0), "grey", name="foot_pad")
        for k in range(5):
            box((0.05, 0.003, 0.0012), (s * 0.065, -0.01 + k * 0.022, zt + 0.0021), WAY, 0.0, name="pad_rib")
    yd = -d / 2 + 0.05
    box((0.11, 0.045, 0.0024), (0, yd, zt + 0.0012), "dark", 0.001, name="display_bezel")
    box((0.098, 0.035, 0.0024), (0, yd, zt + 0.0016), "glass", 0.0, name="display")
    s = 0.01
    for i, ch in enumerate("684"):
        x = -0.03 + i * 0.022 + (0.006 if i == 2 else 0)
        seg7(ch, x, yd, zt + 0.003, s, "dark")
    box((0.003, 0.003, 0.0008), (0.017, yd - s, zt + 0.003), "dark", 0.0, name="digit")  # decimal point
    box((0.012, 0.004, 0.0008), (0.04, yd - 0.006, zt + 0.003), "dark", 0.0, name="digit")  # "kg" tick


@reg
def toiletries(w, d, h):
    # `way` (sage) woven basket with pump bottle, shampoo bottle, tube and a jar
    bh = 0.09
    t = 0.008
    box((w, d, 0.01), (0, 0, 0.005), WAY, 0.003, name="basket")
    for s in (-1, 1):
        box((w, t, bh), (0, s * (d / 2 - t / 2), bh / 2), WAY, 0.003, name="basket")
        box((t, d, bh), (s * (w / 2 - t / 2), 0, bh / 2), WAY, 0.003, name="basket")
    for z in (0.025, 0.05, 0.075):  # weave ribs
        for s in (-1, 1):
            box((w - 0.004, t + 0.004, 0.008), (0, s * (d / 2 - t / 2), z), WAY, 0.003, name="weave")
            box((t + 0.004, d - 0.004, 0.008), (s * (w / 2 - t / 2), 0, z), WAY, 0.003, name="weave")
    for s in (-1, 1):
        box((w + 0.0, 0.012, 0.01), (0, s * (d / 2 - 0.006), bh), WAY, 0.004, name="rim")
        box((0.012, d, 0.01), (s * (w / 2 - 0.006), 0, bh), WAY, 0.004, name="rim")
    z0 = 0.01
    # pump bottle (back left)
    x, y = -0.07, 0.03
    lathe([(0.03, 0.0), (0.033, 0.01), (0.033, 0.12), (0.026, 0.135), (0.012, 0.142), (0.001, 0.142)], "white",
          segs=24, name="pump_bottle", at=(x, y, z0))
    cyl(0.011, 0.016, (x, y, z0 + 0.15), "steel", verts=16, name="pump")
    cyl(0.004, 0.025, (x, y, z0 + 0.17), "steel", verts=10, name="pump")
    box((0.016, 0.03, 0.012), (x, y - 0.01, h - 0.006), "steel", 0.004, name="pump_head")
    # shampoo bottle (back right)
    x, y = 0.045, 0.03
    box((0.07, 0.042, 0.14), (x, y, z0 + 0.07), "teal", 0.016, name="shampoo")
    cyl(0.014, 0.022, (x, y, z0 + 0.151), "dark", verts=16, bevel=0.003, name="shampoo_cap")
    box((0.04, 0.0015, 0.05), (x, y - 0.0215, z0 + 0.075), "white", 0.0, name="shampoo_sticker")
    # tube standing on its cap (front left)
    x, y = -0.03, -0.045
    cyl(0.012, 0.016, (x, y, z0 + 0.008), "white", verts=16, name="tube_cap")
    lathe([(0.012, 0.016), (0.02, 0.04), (0.022, 0.09), (0.024, 0.12)], "rose", yscale=0.45, segs=20,
          name="tube", at=(x, y, z0))
    box((0.05, 0.006, 0.012), (x, y, z0 + 0.124), "rose", 0.002, name="tube_crimp")
    # small jar (front right)
    x, y = 0.075, -0.045
    cyl(0.03, 0.045, (x, y, z0 + 0.0225), "cream", verts=24, bevel=0.004, name="jar")
    cyl(0.031, 0.014, (x, y, z0 + 0.052), "white", verts=24, bevel=0.003, name="jar_lid")
    # round soap/cotton pads tub behind (middle)
    cyl(0.018, 0.1, (0.105, 0.045, z0 + 0.05), "cream", verts=18, name="cotton_tub")
    cyl(0.019, 0.008, (0.105, 0.045, z0 + 0.104), "teal", verts=18, name="cotton_lid")


# ------------------------------------------------------------------ living
def _candlestick(x, top, candle_h, drip_a):
    prof = [(0.049, 0.0), (0.05, 0.006), (0.04, 0.012), (0.02, 0.02), (0.012, 0.03), (0.011, 0.04),
            (0.017, 0.046), (0.011, 0.052), (0.009, top * 0.55), (0.014, top * 0.6), (0.009, top * 0.66),
            (0.008, top - 0.022), (0.022, top - 0.012), (0.024, top - 0.006), (0.016, top), (0.001, top)]
    lathe(prof, WAY, segs=28, name="candlestick", at=(x, 0, 0))
    cyl(0.011, candle_h, (x, 0, top + candle_h / 2), "cream", verts=20, name="candle")
    lathe([(0.0115, 0), (0.0115, 0.004), (0.006, 0.008), (0.001, 0.009)], "cream", segs=20, name="candle",
          at=(x, 0, top + candle_h - 0.004))
    for a, L in ((drip_a, 0.03), (drip_a + 2.2, 0.018)):
        ell((0.003, 0.003, L / 2), (x + 0.0115 * math.cos(a), 0.0115 * math.sin(a), top + candle_h - L / 2 - 0.002),
            "cream", name="drip")
    rod((x, 0, top + candle_h + 0.003), (x + 0.001, 0, top + candle_h + 0.012), 0.0012, "dark", name="wick", verts=6)


@reg
def candlesticks_unused(w, d, h):
    pass


@reg
def candle_holder(w, d, h):
    # pair of turned `way` (black) candlesticks with cream dinner candles, one taller than the other
    r = d / 2
    _candlestick(-(w / 2 - r), 0.12, h - 0.12 - 0.012, -2.0)
    _candlestick(w / 2 - r, 0.09, 0.115, 2.4)


B7.pop("candlesticks_unused")


def _fish(x, y, z, L, color, face=1, tilt=0.0):
    o0 = snapshot()
    ell((L / 2, L * 0.16, L * 0.26), (0, 0, 0), color, name="fish")
    prism_xz([(-L * 0.42, 0), (-L * 0.75, L * 0.2), (-L * 0.75, -L * 0.2)], -0.0015, 0.0015, color, name="fish_tail")
    prism_xz([(-L * 0.1, L * 0.2), (L * 0.1, L * 0.24), (-L * 0.15, L * 0.36)], -0.001, 0.001, color, name="fish_fin")
    for s in (-1, 1):
        cyl(L * 0.045, 0.002, (L * 0.3, s * L * 0.14, L * 0.05), WAY, "Y", 8, name="fish_eye")
    xform(objs_since(o0), M_at((x, y, z), (0, tilt, 0 if face > 0 else math.pi)))


def _plant(x, y, z0, H, n, spread, seed):
    import random
    rnd = random.Random(seed)
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi)
        lean = rnd.uniform(0.3, 1.0) * spread
        hh = H * rnd.uniform(0.6, 1.0)
        pts = [(lean * (t ** 1.6), hh * t) for t in [k / 8 for k in range(9)]]
        o0 = snapshot()
        arc_bar(pts, 0.004, 0.018 - 0.005 * rnd.random(), "green", name="plant", bevel=0.001, plane="XZ")
        xform(objs_since(o0), M_at((x, y, z0), (0, 0, a)))


@reg
def aquarium(w, d, h):
    # `way` (black) base, lid and corner posts; glass back + side panes, front pane left open so the
    # inside reads (opaque matte materials only); kraft gravel, grey rocks, green plants, fish
    bt, lt, p = 0.03, 0.035, 0.012
    box((w, d, bt), (0, 0, bt / 2), WAY, 0.004, name="base")
    box((w, d, lt), (0, 0, h - lt / 2), WAY, 0.004, name="lid")
    box((w * 0.3, 0.05, 0.006), (w * 0.12, -0.03, h + 0.0), WAY, 0.002, name="lid_hatch")
    zi, zt = bt, h - lt
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((p, p, zt - zi), (sx * (w / 2 - p / 2), sy * (d / 2 - p / 2), (zi + zt) / 2), WAY, 0.002, name="post")
    box((w - 2 * p, 0.006, zt - zi), (0, d / 2 - 0.004, (zi + zt) / 2), "glass", 0.0, name="glass_back")
    for s in (-1, 1):
        box((0.006, d - 2 * p, zt - zi), (s * (w / 2 - 0.004), 0, (zi + zt) / 2), "glass", 0.0, name="glass_side")
    box((w - 2 * p, 0.008, 0.012), (0, -d / 2 + 0.004, zi + 0.006), WAY, 0.0, name="front_rail")
    box((w - 2 * p, 0.008, 0.012), (0, -d / 2 + 0.004, zt - 0.006), WAY, 0.0, name="front_rail")
    # gravel bed sloping up toward the back
    prism_yz([(-d / 2 + 0.01, zi), (d / 2 - 0.01, zi), (d / 2 - 0.01, zi + 0.05), (-d / 2 + 0.01, zi + 0.022)],
             -(w / 2 - 0.008), w / 2 - 0.008, "kraft", name="gravel")
    import random
    rnd = random.Random(7)
    for i in range(14):
        x, y = rnd.uniform(-w / 2 + 0.03, w / 2 - 0.03), rnd.uniform(-d / 2 + 0.03, d / 2 - 0.03)
        zg = zi + 0.022 + (y + d / 2 - 0.01) / (d - 0.02) * 0.028
        ell((0.007, 0.006, 0.004), (x, y, zg), "grey" if i % 3 else "kraft", name="pebble")
    ell((0.06, 0.045, 0.045), (0.14, 0.06, zi + 0.05), "grey", name="rock", rot=(0, 0.2, 0.4))
    ell((0.035, 0.03, 0.03), (0.2, 0.0, zi + 0.04), "grey", name="rock")
    _plant(-0.2, 0.07, zi + 0.04, 0.27, 13, 0.07, 1)
    _plant(-0.06, 0.09, zi + 0.045, 0.22, 10, 0.06, 2)
    _plant(0.22, 0.09, zi + 0.045, 0.26, 11, 0.06, 3)
    _plant(0.06, -0.02, zi + 0.035, 0.1, 5, 0.03, 4)
    _fish(-0.08, -0.02, 0.23, 0.09, "mustard", 1, 0.1)
    _fish(0.1, 0.0, 0.27, 0.08, "terracotta", -1, -0.1)
    _fish(0.0, -0.06, 0.16, 0.065, "terracotta", 1, 0.0)
    _fish(-0.18, -0.03, 0.29, 0.06, "mustard", -1, 0.0)
    _fish(0.19, -0.05, 0.19, 0.065, "mustard", 1, 0.15)


@reg
def typewriter(w, d, h):
    # `way` (black) body sloping down to the front, 41 round keys on stems (keys as geometry), space bar,
    # type-bar basket, ribbon spools, carriage with platen and knobs, a sheet of paper with typed lines
    bw = w - 0.04
    prism_yz([(-d / 2, 0.0), (d / 2 - 0.006, 0.0), (d / 2 - 0.006, 0.12), (0.03, 0.135), (-0.05, 0.085),
              (-d / 2, 0.035)], -bw / 2, bw / 2, WAY, name="body")
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl(0.012, 0.006, (sx * (bw / 2 - 0.03), sy * (d / 2 - 0.05), -0.003), "dark", verts=12, name="foot")

    def zs(y):  # key-bed surface height
        return 0.035 + (y + d / 2) * (0.05 / (d / 2 - 0.05))
    rows = (11, 11, 10, 9)
    for i, n in enumerate(rows):
        y = -d / 2 + 0.018 + i * 0.027
        zc = zs(y) + 0.012 + i * 0.003
        for k in range(n):
            x = (k - (n - 1) / 2) * 0.024 + (0.006 if i % 2 else 0)
            rod((x, y + 0.004, zs(y + 0.004) - 0.002), (x, y, zc - 0.002), 0.0018, "steel", name="key_stem", verts=6)
            cyl(0.0088, 0.004, (x, y, zc), "cream", verts=16, name="key")
            torus(0.0088, 0.0012, (x, y, zc), "steel", seg=16, name="key_ring")
    box((0.17, 0.012, 0.006), (0, -d / 2 + 0.002, zs(-d / 2) + 0.012), "steel", 0.002, name="space_bar")
    for s in (-1, 1):
        rod((s * 0.07, -d / 2 + 0.002, zs(-d / 2) + 0.009), (s * 0.07, -d / 2 + 0.03, zs(-d / 2 + 0.03) - 0.001),
            0.002, "steel", name="space_arm", verts=6)
    # type-bar basket: dark half-dish with fanned steel type bars
    yb, zb = 0.0, 0.118
    box((0.2, 0.06, 0.004), (0, yb, zb - 0.004), "dark", 0.0, name="basket")
    for k in range(17):
        a = math.radians(-80 + k * 10)
        rod((0.09 * math.sin(a), yb - 0.01 + 0.02 * abs(math.cos(a)) * 0, zb),
            (0.012 * math.sin(a), yb + 0.035, zb + 0.008), 0.0014, "steel", name="type_bar", verts=5)
    for s in (-1, 1):  # ribbon spools
        cyl(0.03, 0.01, (s * 0.115, 0.03, 0.14), "steel", verts=24, name="spool")
        cyl(0.022, 0.012, (s * 0.115, 0.03, 0.141), "dark", verts=24, name="ribbon")
    # carriage + platen
    yp, zp, rp = d / 2 - 0.065, 0.165, 0.024
    box((bw + 0.01, 0.06, 0.02), (0, yp + 0.01, 0.135), WAY, 0.004, name="carriage")
    cyl(rp, bw - 0.02, (0, yp, zp), "dark", "X", 28, name="platen")
    for s in (-1, 1):
        cyl(0.016, 0.022, (s * (w / 2 - 0.011), yp, zp), "steel", "X", 20, bevel=0.003, name="platen_knob")
        cyl(0.005, 0.02, (s * (bw / 2 - 0.0), yp, zp), "steel", "X", 10, name="platen_axle")
    rod((-bw / 2 + 0.01, yp - 0.02, zp + 0.01), (-bw / 2 - 0.005, yp - 0.07, zp + 0.035), 0.0035, "steel", name="return_lever")
    box((bw - 0.06, 0.006, 0.006), (0, yp - rp - 0.002, zp - 0.004), "steel", 0.002, name="paper_bail")
    # paper: rises from behind the platen, leaning back; typed lines on its front face
    tilt = math.radians(-12)
    ph = h - zp + 0.024
    o0 = snapshot()
    box((0.21, 0.0016, ph), (0, 0, ph / 2), "white", 0.0, name="paper")
    for k in range(5):
        L = 0.15 if k != 4 else 0.08
        box((L, 0.0008, 0.0035), (-0.02 + (L - 0.15) / 2 if k == 4 else -0.02 + (L - 0.15) / 2, -0.0012,
                                  ph - 0.012 - k * 0.0085), "dark", 0.0, name="typed_line")
    xform(objs_since(o0), M_at((0, yp + 0.012, zp - 0.03), (tilt, 0, 0)))
    box((0.24, 0.004, 0.04), (0, yp + 0.04, zp + 0.012), "steel", 0.002, rot=(math.radians(-20), 0, 0), name="paper_rest")


def main(argv):
    out = os.path.join(D.FAM, "batch7")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B7)
    rows = art.read_csv()
    for fid in (argv or BATCH7):
        assert fid in BATCH7, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
