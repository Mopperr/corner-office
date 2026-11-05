"""Design Specialist builder, batch 3 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b3.py -- [family_id ...]

Reuses build() and helpers from build_families_design.py (which imports Art's
helpers read-only). Output: families/batch3/hh_cat_<id>.glb.
Same spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender),
flat matte rough 0.82, palette only, recolourable material 'way' = first colour-way.
"""
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402

art = D.art
box, cyl, sphere, torus = art.box, art.cyl, art.sphere, art.torus
WAY = art.WAY
D.ALIAS["canvas"] = "card"  # canvas is not a palette key -> card E7DCC6

BATCH3 = ["keyboard_piano", "log_basket", "suitcase_stack", "mirror_oval", "mug",
          "plate_stack", "saucepan", "jug", "storage_jar", "towel_pile"]
B3 = {}


def reg(f):
    B3[f.__name__] = f
    return f


def scaled(o, s):
    """Bake rotation, then scale the mesh in world axes about the object origin."""
    from mathutils import Matrix
    o.data.transform(o.matrix_basis.to_3x3().to_4x4())
    o.rotation_euler = (0, 0, 0)
    o.data.transform(Matrix.Diagonal((s[0], s[1], s[2], 1.0)))
    o.data.update()
    return o


def radial(r, ang):
    return r * math.cos(ang), r * math.sin(ang)


@reg
def keyboard_piano(w, d, h):
    # 5-octave portable keyboard: 36 white keys + 25 black keys as geometry
    base_h = 0.055
    box((w, d, base_h), (0, 0, base_h / 2), WAY, 0.012, name="body")
    n_white = 36
    kw = 0.0305
    keys_w = n_white * kw
    kd = 0.15
    ky = -d / 2 + 0.012 + kd / 2
    x0 = -keys_w / 2
    for i in range(n_white):
        box((kw - 0.002, kd, 0.022), (x0 + (i + 0.5) * kw, ky, base_h + 0.011), "white", 0.003, name="key_white")
    for i in range(n_white - 1):
        if i % 7 in (0, 1, 3, 4, 5):  # C# D# . F# G# A#
            box((0.017, 0.092, 0.018), (x0 + (i + 1) * kw, ky + (kd - 0.092) / 2, base_h + 0.022 + 0.009),
                "dark", 0.003, name="key_black")
    cheek_w = (w - keys_w) / 2
    for s in (-1, 1):  # end cheeks beside the keys
        box((cheek_w - 0.004, kd + 0.012, 0.034), (s * (keys_w / 2 + cheek_w / 2), ky - 0.006, base_h + 0.017), WAY, 0.01, name="cheek")
    # raised control panel at the back
    pd = d - kd - 0.012
    py = d / 2 - pd / 2
    box((w, pd, h - base_h - 0.004), (0, py, base_h + (h - base_h - 0.004) / 2), WAY, 0.012, name="panel")
    for s in (-1, 1):  # speaker grilles
        box((0.2, pd * 0.62, 0.004), (s * (w / 2 - 0.15), py + 0.005, h - 0.002), "grey", 0.002, name="speaker")
    box((0.16, pd * 0.42, 0.004), (0, py, h - 0.002), "teal", 0.002, name="display")
    for i in range(8):  # buttons
        box((0.022, 0.018, 0.004), (-0.36 + i * 0.03 + (0.6 if i > 3 else 0.12) - 0.12, py - 0.03, h - 0.002), "white", 0.002, name="button")
    for s in (-1, 1):
        cyl(0.012, 0.01, (s * 0.2, py + 0.02, h - 0.004), "white", name="knob")


@reg
def log_basket(w, d, h):
    # canvas tote basket with leather rim + rope handles, a pile of logs
    bw, bd, bh, t = w - 0.03, d, h * 0.66, 0.016
    box((bw, bd, 0.02), (0, 0, 0.01), WAY, 0.006, name="body")
    for s in (-1, 1):
        box((bw, t, bh), (0, s * (bd / 2 - t / 2), bh / 2), WAY, 0.006, name="body")
        box((t, bd, bh), (s * (bw / 2 - t / 2), 0, bh / 2), WAY, 0.006, name="body")
    for s in (-1, 1):  # leather rim band
        box((bw + 0.004, t + 0.004, 0.03), (0, s * (bd / 2 - t / 2), bh - 0.015), "walnut", 0.004, name="rim")
        box((t + 0.004, bd + 0.004, 0.03), (s * (bw / 2 - t / 2), 0, bh - 0.015), "walnut", 0.004, name="rim")
        torus(0.045, 0.009, (s * (bw / 2 + 0.0), 0, bh), "walnut", rot=(0, math.pi / 2, 0), name="handle")
    L = bw - 0.05
    logs = [(-0.1, bh - 0.02, 0.05), (0.0, bh - 0.01, 0.052), (0.1, bh - 0.02, 0.048),
            (-0.055, bh + 0.065, 0.05), (0.05, bh + 0.065, 0.049)]
    top = max(z + r for _, z, r in logs)
    k = (h - 0.0) / top
    for i, (y, z, r) in enumerate(logs):
        z = z if z + r <= h else h - r
        cyl(r, L - (i % 2) * 0.03, ((i % 2) * 0.01, y * (bd / 0.35), z), "walnut", "X", 12, name="log")
        for s in (-1, 1):  # end grain
            cyl(r * 0.82, 0.004, (s * ((L - (i % 2) * 0.03) / 2 + 0.002) + (i % 2) * 0.01, y * (bd / 0.35), z), "pine", "X", 12, name="log_end")


@reg
def suitcase_stack(w, d, h):
    cases = [(w, d - 0.03, 0.24, WAY), (w * 0.84, d * 0.86, 0.2, "mustard"), (w * 0.66, d * 0.72, h - 0.44, "sage")]
    z = 0.0
    for i, (cw, cd, ch, col) in enumerate(cases):
        xo = (0.02, -0.03, 0.015)[i]
        box((cw, cd, ch), (xo, 0, z + ch / 2), col, 0.02, name="case")
        box((cw + 0.004, cd + 0.004, 0.008), (xo, 0, z + ch / 2), "dark", 0.002, name="zip")  # seam
        for s in (-1, 1):  # two leather straps over the front
            box((0.035, 0.006, ch - 0.02), (xo + s * cw * 0.28, -cd / 2 - 0.002, z + ch / 2), "walnut", 0.002, name="strap")
        box((0.12, 0.014, 0.022), (xo, -cd / 2 - 0.012, z + ch * 0.62), "walnut", 0.006, name="handle")
        for s in (-1, 1):
            box((0.02, 0.012, 0.03), (xo + s * 0.07, -cd / 2 - 0.006, z + ch * 0.62), "brass", 0.003, name="handle_mount")
            box((0.03, 0.01, 0.02), (xo + s * 0.12, -cd / 2 - 0.004, z + ch * 0.82), "brass", 0.003, name="latch")
        for sx in (-1, 1):  # corner caps
            box((0.04, cd + 0.006, 0.04), (xo + sx * (cw / 2 - 0.018), 0, z + 0.02), "brass", 0.006, name="corner")
        z += ch


@reg
def mirror_oval(w, d, h):
    k = h / w  # oval stretch on z
    R = w / 2
    o = cyl(R - 0.01, 0.02, (0, 0.01, 0), "dark", "Y", 32, name="back")
    scaled(o, (1, 1, k))
    o = torus(R - 0.02, 0.02, (0, -0.0, 0), WAY, rot=(math.pi / 2, 0, 0), name="frame", seg=32)
    scaled(o, (1, 1.0, k))
    o = cyl(R - 0.032, 0.006, (0, -0.006, 0), "glass", "Y", 32, name="glass")
    scaled(o, (1, 1, k))
    for dx, dz, L in ((-0.06, 0.06, 0.22), (-0.02, 0.1, 0.12)):
        box((0.018, 0.002, L), (dx, -0.0098, dz), "white", 0.0, rot=(0, math.radians(-28), 0), name="glint")
    box((0.05, 0.01, 0.02), (0, 0.016, h * 0.38), "dark", 0.002, name="hanger")  # wall hook plate, behind
    for o in bpy.context.scene.objects:  # lift so the bottom sits at z=0
        o.location.z += h / 2


@reg
def mug(w, d, h):
    r = 0.04
    cyl(r, h - 0.003, (0, 0, (h - 0.003) / 2), WAY, verts=18, bevel=0.004, name="body")
    torus(r - 0.0035, 0.0035, (0, 0, h - 0.0035), "cream", name="rim")
    cyl(r - 0.006, 0.003, (0, 0, h - 0.0045), "dark", name="coffee")  # tea showing in the open top
    cyl(r + 0.0008, 0.012, (0, 0, h * 0.56), "cream", name="stripe")
    ang = math.radians(-45)  # handle to the front-right (+X, -Y), side-on to a 3/4 camera
    cx, cy = radial(0.041, ang)
    torus(0.022, 0.0075, (cx, cy, h * 0.5), WAY, rot=(math.pi / 2, 0, ang), name="handle")


@reg
def plate_stack(w, d, h):
    R = w / 2
    n, step = 5, 0.0172
    for i in range(n):
        z = i * step
        cyl(R * 0.6, 0.004, (0, 0, z + 0.002), WAY, verts=24, name="plate")
        cyl(R * 0.66, step - 0.006, (0, 0, z + 0.004 + (step - 0.006) / 2), WAY, verts=24, r2=R, name="plate")
        cyl(R, 0.003, (0, 0, z + step - 0.0005), WAY, verts=24, name="plate_rim")
    top = n * step + 0.001
    cyl(R * 0.6, 0.002, (0, 0, top), "white", verts=24, name="plate_well")
    torus(R * 0.6, 0.0015, (0, 0, top), WAY, seg=24, name="plate_ring")


@reg
def saucepan(w, d, h):
    r = 0.09
    cyl(r, 0.095, (0, 0, 0.0475), WAY, verts=24, bevel=0.004, name="body")
    torus(r, 0.004, (0, 0, 0.095), "steel", seg=24, name="rim")
    sphere(r - 0.002, (0, 0, 0.096), "steel", scale=(1, 1, 0.3), name="lid")
    cyl(0.006, 0.012, (0, 0, 0.125), "dark", name="knob")
    sphere(0.017, (0, 0, 0.134), "dark", scale=(1.2, 1.2, 0.45), name="knob")
    ang = math.radians(-45)  # long handle out to the front-right (+X, -Y)
    rr = 0.137
    cx, cy = radial(rr, ang)
    box((0.1, 0.022, 0.016), (cx, cy, 0.083), "dark", 0.006, rot=(0, math.radians(-8), ang), name="handle")
    cx, cy = radial(0.084, ang)
    box((0.03, 0.02, 0.028), (cx, cy, 0.075), "steel", 0.004, rot=(0, 0, ang), name="handle_mount")


@reg
def jug(w, d, h):
    rb = 0.062
    cyl(rb, 0.15, (0, 0, 0.075), WAY, verts=18, bevel=0.005, r2=0.05, name="body")
    cyl(0.05, h - 0.15, (0, 0, 0.15 + (h - 0.15) / 2), WAY, verts=18, r2=0.06, name="neck")
    torus(0.058, 0.004, (0, 0, h - 0.004), WAY, name="rim")
    cyl(rb * 0.92, 0.014, (0, 0, 0.09), "cream", verts=18, r2=rb * 0.87, name="band")
    cyl(0.053, 0.002, (0, 0, h + 0.0002), "cream", name="inside")  # milk in the open top
    sp = math.radians(135)  # spout back-left (-X, +Y), handle front-right: side-on to a 3/4 view
    cx, cy = radial(0.06, sp)
    box((0.05, 0.03, 0.01), (cx, cy, h - 0.009), WAY, 0.003, rot=(0, math.radians(-16), sp), name="spout")
    ha = math.radians(-45)  # handle front-right
    cx, cy = radial(0.036, ha)
    torus(0.045, 0.009, (cx, cy, 0.125), WAY, rot=(math.pi / 2, 0, ha), name="handle")


@reg
def storage_jar(w, d, h):
    r = 0.067
    cyl(r, 0.185, (0, 0, 0.0925), WAY, verts=18, bevel=0.006, name="body")
    cyl(r + 0.003, 0.034, (0, 0, 0.185 + 0.017), "oak", verts=18, bevel=0.004, name="lid")
    sphere(0.018, (0, 0, h - 0.014), "oak", scale=(1, 1, 0.8), name="knob")
    box((0.07, 0.006, 0.05), (0, -r + 0.001, 0.1), "cream", 0.004, name="label")
    for i, L in enumerate((0.044, 0.03)):
        box((L, 0.003, 0.006), (0, -r - 0.003, 0.108 - i * 0.015), "dark", 0.0, name="label")


@reg
def towel_pile(w, d, h):
    cols = [WAY, "cream", WAY, "sage"]
    n = len(cols)
    th = h / n
    for i, c in enumerate(cols):
        xo = (0.008, -0.01, 0.006, -0.004)[i]
        tw = w - 0.02 - (i == 3) * 0.02
        z = i * th
        box((tw, d - 0.03, th - 0.004), (xo, 0.01, z + th / 2), c, 0.02, name="towel")
        cyl(th / 2 - 0.001, tw, (xo, -d / 2 + 0.02, z + th / 2), c, "X", 12, name="towel_fold")
        for s in (-1, 1):  # woven border stripe
            box((0.012, d - 0.026, th - 0.002), (xo + s * (tw / 2 - 0.05), 0.01, z + th / 2), "white", 0.004, name="stripe")


def main(argv):
    out = os.path.join(D.FAM, "batch3")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B3)
    rows = art.read_csv()
    for fid in (argv or BATCH3):
        assert fid in BATCH3, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
