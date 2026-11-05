"""Design Specialist builder, batch 10 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b10.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only),
scaled() from b3, rod()/lathe()/prism_xz() from b4, xform()/M_at() from b6, ell()/prism_yz() from b7,
loft() from b8.  Output: families/batch10/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender), hang items wall at +Y,
flat matte rough 0.82, palette only, material 'way' = first colour-way. Screens are flat matte
palette colours (no emissive, no textures).
Part names avoid the texture hooks in the game's props.gd PART_TEXTURES (trunk, top, tray, box,
soil, mat, strap, ...), so no part here picks up a texture by accident.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_families_design as D  # noqa: E402
import build_families_design_b3 as D3  # noqa: E402
import build_families_design_b4 as D4  # noqa: E402
import build_families_design_b6 as D6  # noqa: E402
import build_families_design_b7 as D7  # noqa: E402  (registers wood -> oak)
import build_families_design_b8 as D8  # noqa: E402  (registers the b8 aliases)
import build_families_design_b9 as D9  # noqa: E402,F401  (registers the b9 aliases)

art = D.art
box, cyl, sphere, torus, arc_bar = art.box, art.cyl, art.sphere, art.torus, art.arc_bar
scaled, rod, lathe, prism_xz = D3.scaled, D4.rod, D4.lathe, D4.prism_xz
snapshot, objs_since, xform, M_at = D6.snapshot, D6.objs_since, D6.xform, D6.M_at
ell, prism_yz, loft = D7.ell, D7.prism_yz, D8.loft
WAY = art.WAY
# Off-palette first colour-ways in batch 10: monitor "off" -> dark (same as Art's alias).
# Later colour-ways (not baked; the game tints `way`): on -> blue, spreadsheet -> white,
# silver -> steel (b8 alias).
# Boss decision (28 Oct 2026): copper -> brass C9A24E from batch 10 onward (copper B87333 is not allowed).
D.ALIAS.update({"off": "dark", "on": "blue", "spreadsheet": "white", "copper": "brass"})

BATCH10 = ["axe_logs", "desk_lamp", "monitor", "keyboard_mouse", "printer", "paper_tray", "pen_pot",
           "laptop", "desk_phone", "desk_tidy"]
B10 = {}


def reg(f):
    B10[f.__name__] = f
    return f


def R(a):
    return math.radians(a)


# ------------------------------------------------------------------ shed
def _log(r, L, at, rotz, split=False):
    """Log lying along local X: dark bark, `way` end grain with walnut rings. split = half log, flat face up."""
    o0 = snapshot()
    if split:
        # half log lying on its flat face: bark arch on top, semicircular end grain with a walnut ring
        n = 10
        arch = [(r * math.cos(math.pi * k / n), r * math.sin(math.pi * k / n)) for k in range(n + 1)]
        prism_yz(arch, -L / 2, L / 2, "dark", name="bark")
        for sx in (-1, 1):
            prism_yz([(0.94 * a, 0.94 * b) for a, b in arch], sx * L / 2 - 0.003, sx * L / 2 + 0.003, WAY,
                     name="end_grain")
            torus(r * 0.3, 0.0015, (sx * (L / 2 + 0.0035), 0, r * 0.4), "walnut", rot=(0, R(90), 0), name="ring",
                  seg=16)
    else:
        cyl(r, L, (0, 0, r), "dark", "X", 16, name="bark")
        for s in (-1, 1):
            cyl(r - 0.006, 0.004, (s * L / 2, 0, r), WAY, "X", 16, name="end_grain")
            torus(r * 0.5, 0.0015, (s * (L / 2 + 0.002), 0, r), "walnut", rot=(0, R(90), 0), name="ring", seg=16)
    xform(objs_since(o0), M_at(at, (0, 0, rotz)))


@reg
def axe_logs(w, d, h):
    # "Axe and logs": a chopping block (dark bark, `way` end grain with walnut growth rings) with an axe
    # sunk in its face (steel head, pine handle), a round log and two split logs on the ground.
    bx, by, rb, hb = 0.06, 0.05, 0.14, 0.23
    cyl(rb, hb - 0.004, (bx, by, (hb - 0.004) / 2), "dark", "Z", 24, name="block_bark")
    cyl(rb - 0.008, 0.006, (bx, by, hb - 0.003), WAY, "Z", 24, name="block_face")
    for rr in (0.03, 0.065, 0.1):
        torus(rr, 0.0018, (bx, by, hb), "walnut", name="ring", seg=24)
    rod((bx + 0.02, by - 0.02, hb + 0.0005), (bx + 0.09, by + 0.01, hb + 0.0005), 0.0015, "walnut", name="crack",
        verts=4)
    # axe: local blade edge toward -X, handle along +Z; sunk into the block face
    o0 = snapshot()
    prism_xz([(-0.095, -0.045), (0.0, -0.024), (0.0, 0.024), (-0.095, 0.05)], -0.007, 0.007, "steel",
             name="axe_blade")
    box((0.035, 0.032, 0.05), (0.012, 0, 0), "steel", 0.005, name="axe_eye")
    rod((0.012, 0, -0.02), (0.012, 0, 0.215), 0.014, "pine", name="axe_handle")
    cyl(0.017, 0.03, (0.012, 0, 0.205), "pine", "Z", 12, bevel=0.005, name="axe_knob")
    xform(objs_since(o0), M_at((bx + 0.0, by + 0.0, hb + 0.045), (0, R(-58), R(-25))))
    # logs on the ground, front left
    _log(0.045, 0.26, (-0.02, -0.15, 0), R(8))
    _log(0.055, 0.24, (-0.15, 0.03, 0), R(80), split=True)
    _log(0.05, 0.17, (-0.1, -0.075, 0.0), R(40), split=True)


# ------------------------------------------------------------------ office
@reg
def desk_lamp(w, d, h):
    # angled desk lamp (one colour): `way` weighted foot, twin-rod lower and upper arms with steel
    # springs, knuckles, and an open cone shade with a cream bulb, aimed forward and down.
    cyl(0.1, 0.022, (0, 0.0, 0.011), WAY, "Z", 32, bevel=0.006, name="foot")
    cyl(0.02, 0.025, (0, 0.05, 0.034), WAY, "Z", 16, name="pivot_post")
    cyl(0.012, 0.012, (0.06, -0.045, 0.026), "dark", "Z", 12, bevel=0.003, name="switch")
    P0, P1, P2 = (0, 0.05, 0.05), (0, 0.08, 0.26), (0, 0.04, 0.37)
    for s in (-1, 1):
        rod((s * 0.011, P0[1], P0[2]), (s * 0.011, P1[1], P1[2]), 0.0045, WAY, name="lower_arm", verts=8)
        rod((s * 0.011, P1[1], P1[2]), (s * 0.011, P2[1], P2[2]), 0.0045, WAY, name="upper_arm", verts=8)
    rod((0.0, 0.065, 0.07), (0.0, 0.09, 0.2), 0.006, "steel", name="spring", verts=8)
    rod((0.0, 0.07, 0.27), (0.0, 0.05, 0.33), 0.006, "steel", name="spring", verts=8)
    for P in (P0, P1, P2):
        cyl(0.012, 0.034, P, WAY, "X", 14, bevel=0.003, name="knuckle")
    cyl(0.01, 0.04, (0.022, P1[1], P1[2]), "dark", "X", 12, name="knob")
    o0 = snapshot()
    prof = [(0.0, 0.0), (0.024, 0.0), (0.03, -0.035), (0.065, -0.11), (0.061, -0.11), (0.026, -0.037),
            (0.0, -0.006)]
    lathe(prof, WAY, segs=28, name="shade")
    sphere(0.022, (0, 0, -0.055), "cream", name="bulb")
    xform(objs_since(o0), M_at((0, P2[1] - 0.02, P2[2] + 0.015), (R(-38), 0, 0)))


@reg
def monitor(w, d, h):
    # flat-screen monitor: black bezel and back, `way` screen (off -> dark), black neck and foot,
    # white power light.
    sw, sh = w, 0.33
    zc = h - sh / 2 - 0.004
    yb = -0.035
    box((sw, 0.02, sh), (0, yb, zc), "black", 0.006, name="bezel")
    box((sw - 0.02, 0.004, sh - 0.035), (0, yb - 0.0105, zc + 0.006), WAY, 0.0, name="screen")
    box((0.28, 0.035, 0.2), (0, yb + 0.025, zc - 0.01), "black", 0.02, name="back_hump")
    box((0.06, 0.022, 0.2), (0, 0.02, 0.12), "black", 0.008, name="neck", rot=(R(-10), 0, 0))
    box((0.24, d, 0.012), (0, 0.0, 0.006), "black", 0.005, name="foot_plate")
    box((0.04, 0.03, 0.03), (0, 0.035, 0.022), "black", 0.006, name="neck_join")
    cyl(0.003, 0.003, (sw / 2 - 0.03, yb - 0.0105, zc - sh / 2 + 0.009), "white", "Y", 8, name="power_light")
    box((0.05, 0.002, 0.006), (0, yb - 0.0105, zc - sh / 2 + 0.009), "grey", 0.0, name="logo")


def _keys(rows, u, x0, y0, z0, cap, hk, col, name="key"):
    """rows: list of (y_offset_u, [widths_u...]) laid left to right from x0."""
    for yo, widths in rows:
        x = x0
        for wu in widths:
            if wu > 0:
                box((wu * u - (u - cap), cap, hk), (x + wu * u / 2, y0 - yo * u, z0 + hk / 2), col, 0.0015,
                    name=name)
            x += abs(wu) * u


@reg
def keyboard_mouse(w, d, h):
    # tenkeyless keyboard with real key layout (function row, 5 main rows, nav cluster, arrows) as
    # `way` key caps on a dark plate, plus a `way` mouse with a dark wheel and a dark cable.
    u, cap, hk = 0.019, 0.0155, 0.007
    kx0 = -w / 2 + 0.008
    kw = 18.25 * u + 0.016
    ky = -0.025
    kd = 6.5 * u + 0.012
    plate = prism_yz([(-kd / 2, 0.0), (kd / 2, 0.0), (kd / 2, 0.019), (-kd / 2, 0.012)], kx0, kx0 + kw, "dark",
                     name="key_plate")
    plate.location = (0, ky, 0)
    # rows top (back) to bottom (front); y offsets in u from the back row
    main = [
        (0, [1, -1, 1, 1, 1, 1, -0.5, 1, 1, 1, 1, -0.5, 1, 1, 1, 1, -0.25, 1, 1, 1]),
        (1.25, [1] * 13 + [2, -0.25, 1, 1, 1]),
        (2.25, [1.5] + [1] * 12 + [1.5, -0.25, 1, 1, 1]),
        (3.25, [1.75] + [1] * 11 + [2.25]),
        (4.25, [2.25] + [1] * 10 + [2.75, -1.25, 1]),
        (5.25, [1.25, 1.25, 1.25, 6.25, 1.25, 1.25, 1.25, 1.25, -0.25, 1, 1, 1]),
    ]
    ybk = ky + kd / 2 - 0.006 - u / 2
    for yo, widths in main:
        x = kx0 + 0.008
        zrow = 0.012 + 0.007 * (1 - (yo / 5.25))  # plate slopes up toward the back
        for wu in widths:
            if wu > 0:
                box((wu * u - (u - cap), cap, hk), (x + wu * u / 2, ybk - yo * u, zrow + hk / 2), WAY, 0.0015,
                    name="key")
            x += abs(wu) * u
    # mouse to the right
    mx, my = w / 2 - 0.033, -0.035
    ell((0.031, 0.052, 0.0145), (mx, my, 0.0145), WAY, name="mouse")
    box((0.0015, 0.04, 0.004), (mx, my - 0.02, 0.0275), "dark", 0.0, name="mouse_split")
    cyl(0.0045, 0.006, (mx, my - 0.024, 0.025), "dark", "X", 12, name="mouse_wheel")
    rod((mx, my + 0.05, 0.004), (mx - 0.01, d / 2 - 0.004, 0.004), 0.0028, "dark", name="cable", verts=6)
    rod((-0.05, ky + kd / 2, 0.006), (-0.07, d / 2 - 0.004, 0.004), 0.0028, "dark", name="cable", verts=6)


@reg
def printer(w, d, h):
    # office inkjet/laser printer: `way` body, scanner lid with steel hinge line, dark output slot with a
    # white printed sheet on the pulled-out output shelf, paper drawer below, control panel with a sage
    # display and grey buttons.
    bd = 0.32
    yb = d / 2 - bd / 2
    bh = 0.162
    box((w, bd, bh), (0, yb, bh / 2), WAY, 0.012, name="body")
    box((w - 0.01, bd - 0.07, 0.035), (0, yb + 0.03, bh + 0.0175), WAY, 0.008, name="scanner_lid")
    box((w - 0.04, 0.004, 0.004), (0, yb + bd / 2 - 0.035, bh + 0.036), "steel", 0.0, name="hinge_line")
    box((w - 0.03, 0.006, 0.006), (0, yb - bd / 2 + 0.035 + 0.002, bh + 0.003), "dark", 0.0, name="lid_seam")
    # output slot and shelf
    box((0.32, 0.02, 0.022), (0, yb - bd / 2 + 0.008, 0.11), "dark", 0.002, name="output_slot")
    box((0.3, 0.055, 0.005), (0, yb - bd / 2 - 0.026, 0.095), "grey", 0.002, rot=(R(-4), 0, 0), name="output_shelf")
    box((0.21, 0.1, 0.003), (0, yb - bd / 2 - 0.006, 0.101), "white", 0.0, rot=(R(-4), 0, 0), name="sheet")
    for k in range(5):
        box((0.15 - 0.02 * (k % 2), 0.004, 0.0006), (-0.01, yb - bd / 2 - 0.04 + k * 0.012, 0.104), "dark", 0.0,
            rot=(R(-4), 0, 0), name="print_line")
    # paper drawer
    box((0.36, 0.01, 0.055), (0, yb - bd / 2 - 0.004, 0.035), WAY, 0.004, name="paper_drawer")
    box((0.1, 0.006, 0.012), (0, yb - bd / 2 - 0.011, 0.045), "dark", 0.003, name="drawer_grip")
    # control panel, front right, angled
    o0 = snapshot()
    box((0.11, 0.05, 0.01), (0, 0, 0), "dark", 0.004, name="panel")
    box((0.05, 0.03, 0.004), (-0.025, 0.0, 0.006), "sage", 0.0, name="display")
    for k, x in enumerate((0.015, 0.032)):
        cyl(0.0065, 0.005, (x, -0.008 + 0.016 * k, 0.006), "grey", "Z", 12, name="button")
    cyl(0.009, 0.005, (0.045, 0.0, 0.006), "sage", "Z", 14, name="power_button")
    xform(objs_since(o0), M_at((w / 2 - 0.075, yb - bd / 2 + 0.03, bh + 0.005), (R(25), 0, 0)))


@reg
def paper_tray(w, d, h):
    # "Paper trays": three stacked `way` letter trays on steel risers, each with side walls dipping
    # toward the open front, a back wall and a front lip; white and cream paper stacks in them.
    tw, td = w - 0.01, d - 0.02
    yt = 0.0
    tier = 0.072
    for k in range(3):
        z = k * tier
        box((tw, td, 0.004), (0, yt, z + 0.002), WAY, 0.002, name="letter_tray")
        for s in (-1, 1):
            o = prism_yz([(-td / 2, 0.0), (td / 2, 0.0), (td / 2, 0.05), (-td / 2 + 0.06, 0.05), (-td / 2, 0.02)],
                     -0.002, 0.002, WAY, name="tray_side")
            o.location = (s * (tw / 2 - 0.002), yt, z)
        box((tw, 0.004, 0.05), (0, yt + td / 2 - 0.002, z + 0.025), WAY, 0.002, name="tray_back")
        box((tw - 0.08, 0.004, 0.016), (0, yt - td / 2 + 0.002, z + 0.008), WAY, 0.002, name="tray_lip")
        if k:
            for sx in (-1, 1):
                for sy in (-1, 1):
                    cyl(0.005, tier - 0.004, (sx * (tw / 2 - 0.02), yt + sy * (td / 2 - 0.03), z - tier / 2 + 0.002),
                        "steel", "Z", 8, name="riser")
        # paper
        n = (6, 4, 8)[k]
        col = ("white", "cream", "white")[k]
        box((0.215, 0.215 if td > 0.215 else td - 0.03, 0.0015 * n + 0.002),
            (0.01 * (k - 1), yt + 0.005, z + 0.004 + (0.0015 * n + 0.002) / 2), col, 0.0, name="paper",
            rot=(0, 0, R(3 * (k - 1))))
    # loose sheet on the top tray, sticking out the front
    box((0.21, 0.24, 0.002), (-0.02, yt - 0.025, 2 * tier + 0.02), "cream", 0.0, rot=(R(4), 0, R(-6)),
        name="sheet")
    box((0.14, 0.004, 0.0008), (-0.02, yt - 0.03, 2 * tier + 0.0215), "dark", 0.0, rot=(R(4), 0, R(-6)), name="text")


@reg
def pen_pot(w, d, h):
    # pen pot: hollow `way` pot with a rolled rim, holding two pens (dark/red caps), a mustard pencil,
    # a steel ruler and scissors with red handles, all leaning a little.
    r, ph = 0.041, 0.095
    lathe([(r, 0.0), (r, ph), (r - 0.004, ph), (r - 0.004, 0.006), (0.0, 0.006)], WAY, segs=28, name="pot",
          at=(0, 0, 0))
    torus(r - 0.002, 0.0028, (0, 0, ph), WAY, name="rim", seg=28)
    # contents start inside, lean outward
    rod((0.012, 0.01, 0.01), (0.022, 0.022, h - 0.004), 0.004, "dark", name="pen", verts=8)
    cyl(0.0045, 0.022, (0.0215, 0.0215, h - 0.016), "red", "Z", 8, name="pen_cap", rot=(R(-6), R(5), 0))
    rod((-0.012, 0.012, 0.01), (-0.02, 0.025, h - 0.012), 0.004, "white", name="pen", verts=8)
    cyl(0.0045, 0.02, (-0.0195, 0.024, h - 0.022), "dark", "Z", 8, name="pen_cap", rot=(R(6), R(-4), 0))
    rod((0.0, -0.014, 0.01), (0.008, -0.04, h - 0.02), 0.0038, "mustard", name="pencil", verts=6)
    o0 = snapshot()
    cyl(0.0038, 0.012, (0, 0, 0.006), "pine", "Z", 6, r2=0.0005, name="pencil_tip")
    xform(objs_since(o0), M_at((0.008, -0.04, h - 0.02), (R(12), R(4), 0)))
    box((0.025, 0.002, 0.13), (-0.016, -0.004, 0.068), "steel", 0.0005, rot=(R(-3), R(-7), R(30)), name="ruler")
    # scissors: blades down in the pot, loops up
    o0 = snapshot()
    box((0.008, 0.003, 0.07), (0, 0, 0.035), "steel", 0.001, name="blade")
    for s in (-1, 1):
        torus(0.011, 0.0028, (s * 0.011, 0, 0.082), "red", rot=(R(90), 0, 0), name="scissor_loop", seg=14)
    xform(objs_since(o0), M_at((0.02, -0.006, 0.02), (0, R(8), R(-50))))


@reg
def laptop(w, d, h):
    # open laptop: `way` base and lid, dark keys in a grid, grey trackpad, dark bezel and a flat matte
    # screen (blue desktop, white window, dark task bar).
    bd = 0.2
    yb = -d / 2 + bd / 2
    box((w, bd, 0.015), (0, yb, 0.0075), WAY, 0.004, name="deck")
    box((w - 0.04, 0.09, 0.001), (0, yb + 0.025, 0.0155), "dark", 0.0, name="key_well")
    u = 0.0215
    for r in range(5):
        n = 13 if r < 4 else 9
        for c in range(n):
            kw = 0.017 if r < 4 else (0.11 if c == 4 else 0.017)
            if r == 4:
                x = -0.13 + c * 0.024 + (0.05 if c > 4 else 0) + (0.047 if c == 4 else 0)
            else:
                x = -0.13 + c * u
            box((kw, 0.016, 0.0018), (x, yb + 0.064 - r * 0.019, 0.0162), "black", 0.0004, name="key")
    box((0.1, 0.06, 0.0012), (0, yb - 0.06, 0.0154), "grey", 0.001, name="trackpad")
    # lid hinged at the back edge, leaning back
    o0 = snapshot()
    lh = 0.205
    box((w, 0.007, lh), (0, 0.0035, lh / 2), WAY, 0.004, name="lid")
    box((w - 0.014, 0.002, lh - 0.016), (0, -0.0005, lh / 2 + 0.002), "dark", 0.0, name="bezel")
    sx0, sz0, sww, shh = -(w - 0.03) / 2, 0.014, w - 0.03, lh - 0.032
    box((sww, 0.002, shh), (0, -0.0015, sz0 + shh / 2), "blue", 0.0, name="screen")
    box((sww, 0.002, 0.012), (0, -0.0025, sz0 + 0.006), "dark", 0.0, name="task_bar")
    box((0.17, 0.002, 0.11), (-0.03, -0.0025, sz0 + 0.035 + 0.055), "white", 0.0, name="window")
    box((0.17, 0.002, 0.012), (-0.03, -0.0035, sz0 + 0.035 + 0.104), "grey", 0.0, name="window_bar")
    for k in range(4):
        box((0.12 - 0.02 * (k % 2), 0.002, 0.004), (-0.045, -0.0035, sz0 + 0.05 + 0.018 * k), "grey", 0.0,
            name="window_line")
    for k in range(3):
        box((0.018, 0.002, 0.016), (sx0 + 0.272, -0.0025, sz0 + 0.03 + 0.026 * k), "white", 0.0, name="icon")
    xform(objs_since(o0), M_at((0, yb + bd / 2 - 0.006, 0.012), (R(-10), 0, 0)))


@reg
def desk_phone(w, d, h):
    # office desk phone: `way` sloped body, handset on its cradle (left), grey 12-key keypad and
    # function keys on the slope, sage display, dark coiled cord.
    pts = [(-d / 2, 0.0), (d / 2, 0.0), (d / 2, 0.055), (d / 2 - 0.02, 0.062), (-d / 2 + 0.01, 0.026),
           (-d / 2, 0.019)]
    prism_yz(pts, -w / 2, w / 2, WAY, name="phone_body")
    slope = math.atan2(0.062 - 0.026, (d / 2 - 0.02) - (-d / 2 + 0.01))

    def zs(y):
        return 0.026 + (y - (-d / 2 + 0.01)) * math.tan(slope)
    # cradle and handset on the left
    hx = -w / 2 + 0.042
    box((0.07, d - 0.03, 0.006), (hx, 0.005, zs(0.005) + 0.002), "dark", 0.002, rot=(slope, 0, 0), name="cradle")
    o0 = snapshot()
    box((0.05, 0.17, 0.022), (0, 0, 0.011), WAY, 0.009, name="handset")
    for s in (-1, 1):
        box((0.056, 0.045, 0.032), (0, s * 0.065, 0.006), WAY, 0.012, name="handset_end")
    xform(objs_since(o0), M_at((hx, 0.0, zs(0.0) + 0.016), (slope, 0, 0)))
    # keypad: 3 x 4 keys on the slope
    kx0 = 0.0
    for r in range(4):
        for c in range(3):
            y = -0.055 + 0.022 * (3 - r) * 0.9
            box((0.016, 0.014, 0.005), (kx0 + c * 0.022, y, zs(y) + 0.002), "grey", 0.002, rot=(slope, 0, 0),
                name="phone_key")
    for k in range(4):
        y = -0.055 + 0.019 * k
        box((0.014, 0.01, 0.004), (0.08, y, zs(y) + 0.002), "grey", 0.002, rot=(slope, 0, 0), name="func_key")
    y = 0.05
    box((0.09, 0.03, 0.003), (0.03, y, zs(y) + 0.001), "sage", 0.0, rot=(slope, 0, 0), name="display")
    # coiled cord from the handset's front end down the left side
    pts3 = []
    n = 60
    for k in range(n + 1):
        t = k / n
        cx, cy, cz = -w / 2 + 0.004, -d / 2 + 0.03 + 0.08 * t, 0.012 + 0.0 * t
        a = 2 * math.pi * 9 * t
        pts3.append((cx - 0.006 * (1 - math.cos(a)) * 0.5, cy, cz + 0.006 * math.sin(a)))
    for p1, p2 in zip(pts3, pts3[1:]):
        rod(p1, p2, 0.0016, "dark", name="cord", verts=4)
    rod((hx - 0.02, -0.075, zs(-0.075) + 0.01), pts3[0], 0.0016, "dark", name="cord", verts=4)


@reg
def desk_tidy(w, d, h):
    # desk organiser: `way` base, walls and dividers forming a tall back pen bay, a front slot for
    # notes and a round cup; holds pens, a mustard sticky-note pad, steel clips and a phone-card slot.
    t = 0.005
    box((w, d, 0.006), (0, 0, 0.003), WAY, 0.002, name="tidy_floor")
    bh = 0.07
    box((w, t, bh), (0, d / 2 - t / 2, bh / 2), WAY, 0.002, name="tidy_wall")
    for s in (-1, 1):
        o = prism_yz([(-d / 2, 0.0), (d / 2, 0.0), (d / 2, bh), (0.0, bh), (-d / 2, 0.035)], -t / 2, t / 2, WAY,
                 name="tidy_side")
        o.location = (s * (w / 2 - t / 2), 0, 0)
    box((w, t, 0.035), (0, -d / 2 + t / 2, 0.0175), WAY, 0.002, name="tidy_front")
    box((w - 0.07, t, bh - 0.01), (-0.035, 0.0, (bh - 0.01) / 2), WAY, 0.002, name="divider")
    box((t, d / 2, 0.035), (-0.03, -d / 4, 0.0175), WAY, 0.002, name="divider")
    # round cup at the right end
    cx, cy = w / 2 - 0.036, 0.0
    lathe([(0.028, 0.0), (0.028, h - 0.004), (0.025, h - 0.004), (0.025, 0.006), (0.0, 0.006)], WAY, segs=24,
          name="tidy_cup", at=(cx, cy, 0))
    # pens in the back bay
    for k, (x, c, a) in enumerate(((-0.08, "blue", 6), (-0.055, "red", -5), (-0.025, "dark", 3), (0.01, "blue", -7))):
        rod((x, 0.03, 0.006), (x + math.sin(R(a)) * 0.07, 0.03 - 0.008, h - 0.002), 0.004, c, name="pen", verts=8)
    rod((cx - 0.004, cy, 0.006), (cx + 0.008, cy + 0.006, h - 0.002), 0.0038, "mustard", name="pencil", verts=6)
    # sticky-note pad front left, clips front right compartment
    box((0.05, 0.034, 0.03), (-0.075, -0.03, 0.021), "mustard", 0.002, rot=(0, 0, R(4)), name="sticky_notes")
    for k in range(4):
        torus(0.008, 0.0012, (0.0 + 0.012 * (k % 2), -0.035 + 0.01 * (k // 2), 0.008 + 0.002 * k), "steel",
              rot=(0, 0, R(30 * k)), name="clip", seg=10)
    box((0.05, 0.003, 0.03), (0.02, -0.018, 0.024), "cream", 0.001, rot=(R(-15), 0, 0), name="card")


def main(argv):
    out = os.path.join(D.FAM, "batch10")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B10)
    rows = art.read_csv()
    for fid in (argv or BATCH10):
        assert fid in BATCH10, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
