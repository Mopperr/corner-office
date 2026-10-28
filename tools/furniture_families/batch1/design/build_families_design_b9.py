"""Design Specialist builder, batch 9 (add-only).

    ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b9.py -- [family_id ...]

Reuses build() from build_families_design.py (Art's helpers imported read-only),
scaled() from b3, rod()/lathe()/prism_xz() from b4, xform()/M_at() from b6, ell()/prism_yz() from b7,
loft() from b8.  Output: families/batch9/.
Spec: plain variant w/d/h (m), origin bottom centre, front -Y (Blender), hang items wall at +Y,
flat matte rough 0.82, palette only, material 'way' = first colour-way.
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

art = D.art
box, cyl, sphere, torus, arc_bar = art.box, art.cyl, art.sphere, art.torus, art.arc_bar
scaled, rod, lathe, prism_xz = D3.scaled, D4.rod, D4.lathe, D4.prism_xz
snapshot, objs_since, xform, M_at = D6.snapshot, D6.objs_since, D6.xform, D6.M_at
ell, prism_yz, loft = D7.ell, D7.prism_yz, D8.loft
WAY = art.WAY
# Off-palette first colour-ways in batch 9: dartboard "classic" -> black, vinyl_crate "milk crate" -> red,
# picture_stack "gilt" -> brass (existing alias). Later colour-ways (not baked): faded -> grey,
# glazed blue -> blue, glazed sage -> sage, plastic black -> black. bird_cage "copper" has no alias
# (copper is not in the palette).
D.ALIAS.update({"classic": "black", "faded": "grey", "milk crate": "red", "glazed blue": "blue",
                "glazed sage": "sage", "plastic black": "black"})

BATCH9 = ["picture_stack", "gramophone", "dartboard", "bird_cage", "vinyl_crate", "sewing_machine",
          "tool_box_v", "paint_cans", "flower_pot_v", "spades"]
B9 = {}


def reg(f):
    B9[f.__name__] = f
    return f


def R(a):
    return math.radians(a)


# ------------------------------------------------------------------ loft
def _frame(fw, fh, t, bar, pic):
    """Frame standing in the XZ plane, front face y=0, back y=t, bottom z=0. pic(x0,x1,z0,z1,y) paints."""
    box((fw, t, bar), (0, t / 2, bar / 2), WAY, 0.004, name="frame")
    box((fw, t, bar), (0, t / 2, fh - bar / 2), WAY, 0.004, name="frame")
    for s in (-1, 1):
        box((bar, t, fh - 2 * bar), (s * (fw / 2 - bar / 2), t / 2, fh / 2), WAY, 0.004, name="frame")
    # inner lip
    il = 0.008
    for z in (bar + il / 2, fh - bar - il / 2):
        box((fw - 2 * bar, 0.006, il), (0, 0.006, z), WAY, 0.002, name="lip")
    for s in (-1, 1):
        box((il, 0.006, fh - 2 * bar), (s * (fw / 2 - bar - il / 2), 0.006, fh / 2), WAY, 0.002, name="lip")
    box((fw - 2 * bar, 0.004, fh - 2 * bar), (0, t * 0.55, fh / 2), "cream", 0.0, name="mount")
    m = 0.028
    pic(-fw / 2 + bar + m, fw / 2 - bar - m, bar + m, fh - bar - m, t * 0.55 - 0.003)


def _landscape(x0, x1, z0, z1, y):
    box((x1 - x0, 0.002, z1 - z0), ((x0 + x1) / 2, y, (z0 + z1) / 2), "blue", 0.0, name="sky")
    hz = z0 + (z1 - z0) * 0.45
    pts = [(x0, z0), (x1, z0), (x1, hz - 0.03), (x0 + (x1 - x0) * 0.7, hz + 0.04),
           (x0 + (x1 - x0) * 0.35, hz - 0.01), (x0, hz + 0.03)]
    prism_xz(pts, y - 0.003, y - 0.001, "green", name="hill")
    pts2 = [(x0, z0), (x1, z0), (x1, z0 + 0.04), (x0 + (x1 - x0) * 0.4, z0 + 0.07), (x0, z0 + 0.03)]
    prism_xz(pts2, y - 0.004, y - 0.002, "green", name="field")
    cyl(0.03, 0.002, (x0 + (x1 - x0) * 0.75, y - 0.003, z1 - 0.07), "mustard", "Y", 18, name="sun")


def _still_life(x0, x1, z0, z1, y):
    box((x1 - x0, 0.002, z1 - z0), ((x0 + x1) / 2, y, (z0 + z1) / 2), "mustard", 0.0, name="ground")
    box((x1 - x0, 0.002, (z1 - z0) * 0.3), ((x0 + x1) / 2, y - 0.001, z0 + (z1 - z0) * 0.15), "green", 0.0,
        name="table")
    cx = (x0 + x1) / 2
    zb = z0 + (z1 - z0) * 0.3
    pts = [(cx - 0.03, zb), (cx + 0.03, zb), (cx + 0.045, zb + 0.06), (cx + 0.015, zb + 0.11),
           (cx - 0.015, zb + 0.11), (cx - 0.045, zb + 0.06)]
    prism_xz(pts, y - 0.004, y - 0.002, "blue", name="vase")
    for dx, dz in ((-0.03, 0.15), (0.0, 0.17), (0.03, 0.15)):
        cyl(0.022, 0.002, (cx + dx, y - 0.004, zb + dz), "cream", "Y", 14, name="bloom")


@reg
def picture_stack(w, d, h):
    # "Stack of pictures": three framed pictures leaning back in a stack; front one faces the wall
    # (kraft backing + hanging wire) as they are found in a loft. `way` = frame (gilt -> brass).
    tilt = R(-8)
    t = 0.03
    specs = [  # fw, fh, y, x, pic, facing_back
        (0.50, 0.58, 0.025, 0.0, _landscape, False),
        (0.40, 0.46, -0.02, -0.035, _still_life, False),
        (0.34, 0.30, -0.06, 0.04, None, True),
    ]
    for fw, fh, y, x, pic, back in specs:
        o0 = snapshot()
        if back:
            # seen from behind: backing board toward the viewer, frame edge behind
            box((fw, t, 0.035), (0, t / 2, 0.0175), WAY, 0.004, name="frame")
            box((fw, t, 0.035), (0, t / 2, fh - 0.0175), WAY, 0.004, name="frame")
            for s in (-1, 1):
                box((0.035, t, fh - 0.07), (s * (fw / 2 - 0.0175), t / 2, fh / 2), WAY, 0.004, name="frame")
            box((fw - 0.03, 0.005, fh - 0.03), (0, 0.0, fh / 2), "kraft", 0.0, name="backing")
            for s in (-1, 1):
                box((0.012, 0.006, 0.018), (s * fw * 0.32, -0.004, fh * 0.72), "steel", 0.002, name="eye")
            pts = [(-fw * 0.32, fh * 0.72), (-fw * 0.12, fh * 0.80), (0, fh * 0.82), (fw * 0.12, fh * 0.80),
                   (fw * 0.32, fh * 0.72)]
            arc_bar(pts, 0.003, 0.003, "steel", name="wire", bevel=0.0, plane="XZ", offset=-0.007)
        else:
            _frame(fw, fh, t, 0.04, pic)
        xform(objs_since(o0), M_at((x, y, 0), (tilt, 0, 0)))


@reg
def gramophone(w, d, h):
    # horn gramophone: `way` wooden case with moulding, felt platter, black record, brass tone arm and
    # big open brass horn turned toward the front; steel crank on the side.
    bw, bh = 0.30, 0.13
    yb = 0.03
    box((bw, bw, 0.02), (0, yb, 0.01), WAY, 0.004, name="plinth")
    box((bw - 0.02, bw - 0.02, bh - 0.035), (0, yb, 0.02 + (bh - 0.035) / 2), WAY, 0.006, name="case")
    box((bw, bw, 0.015), (0, yb, bh - 0.0075), WAY, 0.004, name="case_top")
    for s in (-1, 1):
        box((0.12, 0.006, 0.05), (s * 0.065, yb - (bw - 0.02) / 2 - 0.002, 0.07), "dark", 0.003, name="panel")
    cyl(0.125, 0.012, (0, yb - 0.01, bh + 0.006), "dark", "Z", 36, name="platter")
    cyl(0.12, 0.004, (0, yb - 0.01, bh + 0.014), "black", "Z", 36, name="record")
    cyl(0.04, 0.0045, (0, yb - 0.01, bh + 0.0145), "red", "Z", 24, name="centre")
    cyl(0.005, 0.02, (0, yb - 0.01, bh + 0.02), "steel", "Z", 8, name="spindle")
    # tone arm: column at back right, arm reaching across, soundbox on the record
    ax, ay = 0.11, yb + 0.11
    cyl(0.018, 0.035, (ax, ay, bh + 0.0175), "brass", "Z", 16, name="arm_base")
    rod((ax, ay, bh + 0.03), (0.05, yb - 0.06, bh + 0.045), 0.009, "brass", name="tone_arm")
    cyl(0.028, 0.014, (0.05, yb - 0.065, bh + 0.04), "steel", "Y", 18, name="soundbox", bevel=0.003)
    rod((0.05, yb - 0.065, bh + 0.03), (0.05, yb - 0.065, bh + 0.018), 0.002, "steel", name="needle")
    # horn: elbow rises from the arm base then flares forward-up
    o0 = snapshot()
    n = 14
    L, RB = 0.30, 0.16
    prof = []
    for k in range(n + 1):
        z = L * k / n
        prof.append((0.016 * math.exp(math.log(RB / 0.016) * (z / L) ** 1.6), z))
    inner = [(r - 0.004, z) for r, z in reversed(prof)]
    lathe(prof + [(prof[-1][0] + 0.004, L + 0.004)] + inner, "brass", segs=28, name="horn")
    torus(RB, 0.006, (0, 0, L), "brass", name="bell_rim", seg=28)
    xform(objs_since(o0), M_at((0.0, 0.11, bh + 0.16), (R(50), 0, 0)))
    rod((ax, ay, bh + 0.03), (ax * 0.4, ay + 0.0, bh + 0.12), 0.016, "brass", name="elbow")
    rod((ax * 0.4, ay, bh + 0.12), (0.0, 0.11, bh + 0.16), 0.016, "brass", name="elbow")
    sphere(0.019, (ax * 0.4, ay, bh + 0.12), "brass", name="joint")
    sphere(0.019, (0.0, 0.11, bh + 0.16), "brass", name="joint")
    # crank on the right side
    cyl(0.012, 0.02, (bw / 2 + 0.01, yb, 0.07), "steel", "X", 12, name="crank_boss")
    rod((bw / 2 + 0.02, yb, 0.07), (bw / 2 + 0.03, yb + 0.0, 0.07), 0.005, "steel", name="crank")
    box((0.008, 0.012, 0.06), (bw / 2 + 0.034, yb, 0.05), "steel", 0.003, name="crank_arm")
    cyl(0.009, 0.03, (bw / 2 + 0.05, yb, 0.026), "walnut", "X", 12, name="crank_knob", bevel=0.003)


# ------------------------------------------------------------------ hang: dartboard
def _sector(r0, r1, a0, a1, y0, y1, col, name):
    n = max(2, int(abs(a1 - a0) / R(6)) + 1)
    outer = [(r1 * math.cos(a0 + (a1 - a0) * k / n), r1 * math.sin(a0 + (a1 - a0) * k / n)) for k in range(n + 1)]
    inner = [(r0 * math.cos(a0 + (a1 - a0) * k / n), r0 * math.sin(a0 + (a1 - a0) * k / n)) for k in range(n + 1)]
    return prism_xz(outer + list(reversed(inner)), y0, y1, col, name=name)


@reg
def dartboard(w, d, h):
    # "classic" bristle board (wall at +Y): `way` = black surround + dark segments (classic -> black),
    # cream segments, red/green double and treble rings, bull, steel wire spider and number marks,
    # wall bracket. Darts are left out: the CSV depth (0.05 m) is the board only.
    Rb = w / 2
    yf = -d / 2 + 0.004                           # front face of the playing surface
    cyl(Rb, 0.036, (0, -d / 2 + 0.004 + 0.018, Rb), WAY, "Y", 48, bevel=0.004, name="board")
    box((0.16, d - 0.04, 0.16), (0, d / 2 - (d - 0.04) / 2, Rb), "dark", 0.004, name="bracket")
    ys = (yf - 0.003, yf + 0.001)
    rings = [(0.016, 0.099, None), (0.099, 0.107, "tre"), (0.107, 0.162, None), (0.162, 0.170, "dbl")]
    for k in range(20):
        a0 = R(90 - 9 + 18 * k)
        a1 = a0 + R(18)
        odd = k % 2
        for r0, r1, kind in rings:
            if kind:
                col = "red" if odd == 0 else "green"
            else:
                col = WAY if odd == 0 else "cream"
            o = _sector(r0, r1, a0, a1, *ys, col, "seg")
            o.location = (0, 0, Rb)
    cyl(0.016, 0.004, (0, yf - 0.001, Rb), "green", "Y", 24, name="outer_bull")
    cyl(0.0064, 0.005, (0, yf - 0.0015, Rb), "red", "Y", 16, name="bull")
    yw = yf - 0.0035
    for r in (0.016, 0.099, 0.107, 0.162, 0.170):
        torus(r, 0.0012, (0, yw, Rb), "steel", rot=(R(90), 0, 0), name="wire", seg=40)
    for k in range(20):
        a = R(90 - 9 + 18 * k)
        p1 = (0.016 * math.cos(a), yw, Rb + 0.016 * math.sin(a))
        p2 = (0.17 * math.cos(a), yw, Rb + 0.17 * math.sin(a))
        rod(p1, p2, 0.0012, "steel", name="spider", verts=4)
        b = a + R(9)
        # number mark: a short steel bar standing radially in the number ring
        cx, cz = 0.196 * math.cos(b), 0.196 * math.sin(b)
        box((0.014, 0.003, 0.018), (cx, yf - 0.001, Rb + cz), "steel", 0.001, rot=(0, -(b - R(90)), 0),
            name="number")
    torus(0.185, 0.0015, (0, yw, Rb), "steel", rot=(R(90), 0, 0), name="number_ring", seg=40)


# ------------------------------------------------------------------ bird cage
@reg
def bird_cage(w, d, h):
    # round domed cage on its own base tray (small mount, sits on a surface): chunky `way` bars,
    # rings, dome arcs, hanging ring on top, front door, wooden perch, food cup and a budgie.
    Rc = 0.15
    cyl(w / 2, 0.03, (0, 0, 0.015), WAY, "Z", 36, bevel=0.006, name="base")
    cyl(w / 2 - 0.02, 0.008, (0, 0, 0.034), "kraft", "Z", 36, name="floor")
    zt, zd = 0.36, 0.47
    for z in (0.04, 0.2, zt):
        torus(Rc, 0.005, (0, 0, z), WAY, name="hoop", seg=36)
    nb = 20
    for k in range(nb):
        a = 2 * math.pi * k / nb
        cyl(0.0035, zt - 0.04, (Rc * math.cos(a), Rc * math.sin(a), (zt + 0.04) / 2), WAY, "Z", 6, name="bar")
    for k in range(nb // 2):
        o0 = snapshot()
        pts = [(Rc * math.cos(math.pi * j / 16), zt + (zd - zt) * math.sin(math.pi * j / 16)) for j in range(17)]
        arc_bar(pts, 0.006, 0.006, WAY, name="dome_bar", bevel=0.0, plane="XZ")
        xform(objs_since(o0), M_at((0, 0, 0), (0, 0, math.pi * k / (nb // 2))))
    cyl(0.03, 0.02, (0, 0, zd + 0.005), WAY, "Z", 20, bevel=0.004, name="cap")
    torus(0.03, 0.0065, (0, 0, h - 0.0365), WAY, rot=(R(90), 0, 0), name="ring", seg=24)
    # door on the front
    yd = -Rc - 0.004
    for x in (-0.05, 0.05):
        box((0.008, 0.008, 0.16), (x, yd, 0.12), WAY, 0.002, name="door")
    for z in (0.04, 0.2):
        box((0.108, 0.008, 0.008), (0, yd, z), WAY, 0.002, name="door")
    box((0.03, 0.01, 0.012), (0.0, yd - 0.004, 0.13), WAY, 0.003, name="door_catch")
    # perch and cup
    rod((-Rc + 0.004, 0.02, 0.15), (Rc - 0.004, 0.02, 0.15), 0.007, "kraft", name="perch")
    lathe([(0.018, 0.0), (0.024, 0.03), (0.02, 0.03), (0.014, 0.006), (0.0, 0.006)], "white", segs=16,
                name="cup", at=(0.09, 0.07, 0.038))
    # budgie on the perch, facing front-left
    o0 = snapshot()
    ell((0.026, 0.024, 0.036), (0, 0, 0.035), "green", name="bird_body", rot=(R(-15), 0, 0))
    sphere(0.02, (0, -0.008, 0.075), "mustard", name="bird_head")
    ell((0.006, 0.008, 0.006), (0, -0.028, 0.072), "mustard", name="beak")
    for s in (-1, 1):
        sphere(0.004, (s * 0.016, -0.016, 0.08), "dark", name="eye")
        ell((0.008, 0.022, 0.03), (s * 0.022, 0.006, 0.035), "green", name="wing", rot=(R(-20), 0, 0))
    prism_yz([(0.015, 0.025), (0.06, -0.025), (0.06, -0.035), (0.015, 0.012)], -0.012, 0.012, "green",
             name="tail")
    xform(objs_since(o0), M_at((-0.02, 0.02, 0.152), (0, 0, R(-20))))


# ------------------------------------------------------------------ record crate
@reg
def vinyl_crate(w, d, h):
    # "Record crate": slatted crate (`way`, milk crate -> red) with corner posts, hand holes in the
    # ends, filled with record sleeves standing face-front; one record peeks out of its sleeve.
    ch = 0.27
    t = 0.014
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((0.03, 0.03, ch), (sx * (w / 2 - 0.015), sy * (d / 2 - 0.015), ch / 2), WAY, 0.004, name="post")
    box((w - 0.01, d - 0.01, 0.014), (0, 0, 0.007), WAY, 0.003, name="base")
    for z0, z1 in ((0.01, 0.09), (0.11, 0.19), (0.21, ch)):
        zc, hz = (z0 + z1) / 2, z1 - z0
        for sy in (-1, 1):
            box((w - 0.03, t, hz), (0, sy * (d / 2 - t / 2), zc), WAY, 0.003, name="slat")
        for sx in (-1, 1):
            box((t, d - 0.03, hz), (sx * (w / 2 - t / 2), 0, zc), WAY, 0.003, name="slat")
    for sx in (-1, 1):
        box((0.004, 0.11, 0.03), (sx * (w / 2 + 0.0005), 0, ch - 0.035), "black", 0.002, name="hand_hole")
    cols = ["blue", "cream", "mustard", "teal", "cream", "blue", "mustard", "teal", "cream", "blue",
            "mustard", "teal"]
    sw = min(w - 0.05, h - 0.012)
    ys = [-(d / 2 - 0.035) + k * 0.023 for k in range(len(cols))]
    for k, (y, c) in enumerate(zip(ys, cols)):
        tilt = R(-7 + 2 * (k % 3))
        box((sw, 0.006, sw), (0, y, 0.014 + sw / 2 - 0.004), c, 0.002, rot=(tilt, 0, R((k % 2) * 1.5 - 0.75)),
                name="sleeve")
    # front sleeve design + peeking record
    o0 = snapshot()
    cyl(0.09, 0.002, (0, -0.0045, 0), "mustard", "Y", 32, name="sleeve_disc")
    cyl(0.03, 0.002, (0, -0.0055, 0), "cream", "Y", 20, name="sleeve_dot")
    xform(objs_since(o0), M_at((0, ys[0], 0.014 + sw / 2 - 0.004), (R(-7), 0, 0)))
    o0 = snapshot()
    cyl(0.14, 0.003, (0, 0, 0), "black", "Y", 40, name="record")
    cyl(0.045, 0.0035, (0, 0, 0), "cream", "Y", 24, name="record_centre")
    xform(objs_since(o0), M_at((0.05, ys[5] + 0.004, 0.18), (R(-10), 0, 0)))


# ------------------------------------------------------------------ sewing machine
@reg
def sewing_machine(w, d, h):
    # vintage hand machine: walnut base board, `way` cast body (bed, pillar, arm, head) with brass
    # decals, steel needle plate, needle bar and presser foot, steel hand wheel, red thread spool.
    box((w, d, 0.03), (0, 0, 0.015), "walnut", 0.006, name="base_board")
    box((0.36, 0.16, 0.035), (0, 0, 0.0475), WAY, 0.008, name="bed")
    pts = [(0.17, 0.065), (0.17, 0.2), (0.155, 0.235), (0.12, 0.25), (-0.13, 0.25), (-0.165, 0.235),
           (-0.175, 0.2), (-0.175, 0.13), (-0.115, 0.13), (-0.115, 0.185), (0.075, 0.185), (0.085, 0.065)]
    prism_xz(pts, -0.045, 0.045, WAY, name="arm")
    box((0.06, 0.09, 0.06), (-0.145, 0, 0.215), WAY, 0.01, name="head")
    box((0.15, 0.09, 0.002), (0, -0.049, 0.06), "brass", 0.0, name="bed_trim")
    for x in (-0.06, 0.0, 0.05):
        box((0.035, 0.002, 0.014), (x, -0.046, 0.22), "brass", 0.0, name="decal")
    box((0.17, 0.002, 0.004), (-0.01, -0.046, 0.2), "brass", 0.0, name="decal_line")
    box((0.17, 0.002, 0.004), (-0.01, -0.046, 0.24), "brass", 0.0, name="decal_line")
    box((0.06, 0.06, 0.003), (-0.145, -0.02, 0.066), "steel", 0.001, name="needle_plate")
    cyl(0.005, 0.07, (-0.155, -0.02, 0.15), "steel", "Z", 8, name="needle_bar")
    rod((-0.155, -0.02, 0.115), (-0.155, -0.02, 0.075), 0.0015, "steel", name="needle")
    cyl(0.004, 0.06, (-0.135, -0.02, 0.135), "steel", "Z", 8, name="presser_bar")
    box((0.02, 0.03, 0.006), (-0.135, -0.025, 0.07), "steel", 0.002, name="presser_foot")
    cyl(0.012, 0.02, (-0.145, -0.05, 0.215), "steel", "Y", 14, name="tension_knob", bevel=0.003)
    # hand wheel
    cyl(0.065, 0.025, (0.19, 0.0, 0.17), "steel", "X", 32, bevel=0.004, name="hand_wheel")
    cyl(0.04, 0.027, (0.19, 0.0, 0.17), "dark", "X", 24, name="wheel_hub")
    cyl(0.01, 0.04, (0.205, 0.0, 0.17), "steel", "X", 12, name="wheel_axle")
    # spool on top
    cyl(0.003, 0.05, (0.02, 0.0, 0.27), "steel", "Z", 6, name="spool_pin")
    cyl(0.014, 0.03, (0.02, 0.0, 0.268), "red", "Z", 18, name="spool")
    for z in (0.252, 0.284):
        cyl(0.017, 0.004, (0.02, 0.0, z), "oak", "Z", 18, name="spool_end")
    rod((0.02, -0.014, 0.265), (-0.13, -0.046, 0.215), 0.0012, "red", name="thread", verts=4)


# ------------------------------------------------------------------ shed
@reg
def tool_box_v(w, d, h):
    # steel tool box (`way`): body with ribbed lid, front catches, folding handle with dark grip,
    # and a hammer and screwdriver lying on the lid.
    bh = 0.14
    box((w, d - 0.01, bh), (0, 0, bh / 2), WAY, 0.006, name="body")
    box((w + 0.004, d - 0.004, 0.035), (0, 0, bh + 0.0175), WAY, 0.006, name="lid")
    box((w - 0.04, d - 0.03, 0.006), (0, 0, bh + 0.038), WAY, 0.003, name="lid_rib")
    box((w + 0.006, d - 0.002, 0.008), (0, 0, bh - 0.002), "steel", 0.002, name="seam")
    for sx in (-1, 1):
        box((0.04, 0.01, 0.05), (sx * 0.14, -(d - 0.01) / 2 - 0.004, bh - 0.01), "steel", 0.003, name="latch")
        box((0.03, 0.02, 0.025), (sx * 0.1, 0, bh + 0.045), "steel", 0.003, name="handle_mount")
        rod((sx * 0.1, 0, bh + 0.05), (sx * 0.09, 0, h - 0.01), 0.005, "steel", name="handle_wire")
    cyl(0.012, 0.18, (0, 0, h - 0.012), "dark", "X", 14, bevel=0.004, name="grip")
    for sx in (-1, 1):
        box((0.02, 0.006, 0.08), (sx * (w / 2 - 0.05), -(d - 0.01) / 2 - 0.001, 0.06), "steel", 0.002, name="trim")
    zt = bh + 0.041
    # hammer on the lid, front-left
    o0 = snapshot()
    cyl(0.011, 0.2, (0, 0, 0.011), "oak", "X", 12, bevel=0.003, name="hammer_handle")
    box((0.022, 0.09, 0.022), (-0.1, 0.0, 0.016), "steel", 0.004, name="hammer_head")
    xform(objs_since(o0), M_at((0.04, -0.055, zt), (0, 0, R(8))))
    o0 = snapshot()
    cyl(0.012, 0.08, (0, 0, 0.012), "red", "X", 12, bevel=0.004, name="driver_handle")
    cyl(0.003, 0.1, (0.09, 0, 0.012), "steel", "X", 8, name="driver_shaft")
    xform(objs_since(o0), M_at((-0.09, 0.06, zt), (0, 0, R(-6))))


@reg
def paint_cans(w, d, h):
    # three steel paint tins with `way` paint: a big sealed tin with wire bail and colour band, an open
    # tin showing the paint with drips, a small tin; a brush resting across the open tin.
    # big tin (left back)
    xa, ya, ra, ha = -0.11, 0.015, 0.09, 0.19
    cyl(ra, ha, (xa, ya, ha / 2), "steel", "Z", 32, bevel=0.003, name="tin")
    torus(ra - 0.003, 0.004, (xa, ya, ha - 0.003), "steel", name="rim", seg=32)
    cyl(ra + 0.002, 0.07, (xa, ya, 0.08), "cream", "Z", 32, name="wrap")
    cyl(ra + 0.003, 0.035, (xa, ya, 0.08), WAY, "Z", 32, name="colour_band")
    o0 = snapshot()
    pts = [(-ra * math.cos(math.pi * k / 16), (ra * 0.9) * math.sin(math.pi * k / 16)) for k in range(17)]
    arc_bar(pts, 0.004, 0.004, "steel", name="bail", bevel=0.0, plane="XZ")
    xform(objs_since(o0), M_at((xa, ya, ha - 0.04), (R(-75), 0, 0)))
    for s in (-1, 1):
        cyl(0.008, 0.006, (xa + s * ra, ya, ha - 0.04), "steel", "X", 10, name="lug")
    # open tin (right)
    xb, yb, rb, hb = 0.1, -0.01, 0.082, 0.14
    lathe([(rb, 0.0), (rb, hb), (rb - 0.004, hb), (rb - 0.004, hb - 0.02), (0.0, hb - 0.02)], "steel", segs=32,
          name="open_tin", at=(xb, yb, 0))
    cyl(rb - 0.004, 0.004, (xb, yb, hb - 0.018), WAY, "Z", 32, name="paint")
    torus(rb, 0.003, (xb, yb, hb - 0.001), WAY, name="paint_rim", seg=32)
    for a, L in ((-100, 0.05), (-70, 0.08), (-125, 0.035), (200, 0.06)):
        aa = R(a)
        cx, cy = xb + rb * math.cos(aa), yb + rb * math.sin(aa)
        box((0.012, 0.005, L), (cx, cy, hb - L / 2), WAY, 0.002, rot=(0, 0, aa + math.pi / 2), name="drip")
    cyl(0.02, 0.006, (xb + 0.01, yb - 0.04, 0.003), WAY, "Z", 16, name="spill")
    # lid of the open tin leaning on it
    cyl(rb + 0.002, 0.006, (xb + rb + 0.012, yb, rb + 0.004), "steel", "X", 28,
        rot=(0, R(90 - 8), 0), name="lid")
    # small tin front-left
    cyl(0.05, 0.08, (-0.12, -0.065, 0.04), "steel", "Z", 24, bevel=0.002, name="small_tin")
    cyl(0.051, 0.03, (-0.12, -0.065, 0.04), WAY, "Z", 24, name="small_band")
    # brush across the open tin
    o0 = snapshot()
    box((0.07, 0.012, 0.05), (0, 0, 0), "dark", 0.003, name="bristles")
    box((0.07, 0.012, 0.012), (0, 0, -0.024), WAY, 0.002, name="bristle_tip")
    box((0.06, 0.016, 0.03), (0, 0, 0.038), "steel", 0.003, name="ferrule")
    box((0.035, 0.018, 0.1), (0, 0, 0.1), "oak", 0.008, name="brush_handle")
    xform(objs_since(o0), M_at((xb, yb - 0.07, hb + 0.008), (R(-90), 0, R(12))))


def _pot(r, ph, at, col, name="pot"):
    prof = [(r * 0.68, 0.0), (r * 0.9, ph * 0.82), (r, ph * 0.82), (r, ph), (r - 0.007, ph),
            (r * 0.85, ph * 0.84), (r * 0.62, 0.012), (0.0, 0.012)]
    return lathe(prof, col, segs=28, name=name, at=at)


@reg
def flower_pot_v(w, d, h):
    # "Flower pots": a big `way` pot on its saucer with a flowering plant, a small pot with a leafy
    # plant, and an empty small pot lying on its side. Dark soil, green leaves, rose flowers.
    xa, ya, ra, ha = -0.045, 0.04, 0.105, 0.15
    cyl(ra * 0.85, 0.012, (xa, ya, 0.006), WAY, "Z", 28, bevel=0.003, name="saucer")
    _pot(ra, ha, (xa, ya, 0.008), WAY, "pot")
    cyl(ra - 0.01, 0.006, (xa, ya, 0.008 + ha - 0.018), "dark", "Z", 24, name="planter_soil")
    import random
    rnd = random.Random(9)
    zt = 0.008 + ha - 0.016
    for k in range(16):
        a = 2 * math.pi * k / 16 + rnd.uniform(-0.2, 0.2)
        L = rnd.uniform(0.06, 0.09)
        ell((0.018, L * 0.5, 0.005), (xa + math.cos(a) * L * 0.45, ya + math.sin(a) * L * 0.45, zt + 0.015),
            "green", name="leaf", rot=(R(-35), 0, a - math.pi / 2))
    tips = []
    for k in range(7):
        a = 2 * math.pi * k / 6 + 0.3
        rr = 0.05 if k else 0.0
        top = (xa + rr * math.cos(a), ya + rr * math.sin(a), h - 0.02 - (0.025 if k % 2 else 0.0))
        rod((xa + rr * 0.3 * math.cos(a), ya + rr * 0.3 * math.sin(a), zt), top, 0.0025, "green", name="stem",
            verts=5)
        tips.append(top)
    for (x, y, z) in tips:
        for j in range(5):
            b = 2 * math.pi * j / 5
            ell((0.016, 0.01, 0.005), (x + 0.013 * math.cos(b), y + 0.013 * math.sin(b), z), "rose",
                name="petal", rot=(0, 0, b))
        sphere(0.008, (x, y, z + 0.003), "mustard", name="flower_centre")
    # small pot, front right, with a leafy plant
    xb, yb, rb, hb = 0.09, -0.08, 0.055, 0.085
    _pot(rb, hb, (xb, yb, 0), WAY, "pot_small")
    cyl(rb - 0.008, 0.005, (xb, yb, hb - 0.012), "dark", "Z", 20, name="planter_soil")
    for k in range(9):
        a = 2 * math.pi * k / 9
        ell((0.013, 0.03, 0.005), (xb + math.cos(a) * 0.02, yb + math.sin(a) * 0.016, hb + 0.012), "green",
            name="leaf", rot=(R(-50), 0, a - math.pi / 2))
    ell((0.009, 0.02, 0.004), (xb, yb, hb + 0.03), "green", name="leaf", rot=(R(80), 0, 0))
    # empty pot on its side, front left
    o0 = snapshot()
    _pot(0.045, 0.07, (0, 0, 0), WAY, "pot_empty")
    xform(objs_since(o0), M_at((-0.075, -0.1, 0.045), (0, R(90), R(-30))))


def _tool_handle(x, y, top, col_grip):
    # shaft + D-handle, shaft top at top-0.12
    zs = top - 0.13
    for s in (-1, 1):
        rod((x, y, zs), (x + s * 0.045, y, top - 0.015), 0.009, WAY, name="d_handle")
    cyl(0.013, 0.1, (x, y, top - 0.015), col_grip, "X", 12, bevel=0.004, name="grip")
    return zs


@reg
def spades(w, d, h):
    # "Spade and fork" standing side by side: `way` ash-style shafts with D-handles, steel spade blade
    # with tread and socket, steel four-tine fork, tied together with kraft twine.
    # spade (front)
    xs, ys = 0.028, -0.033
    blade_w = 0.15
    box((blade_w, 0.006, 0.26), (xs, ys, 0.13 + 0.004), "steel", 0.004, name="blade")
    box((blade_w, 0.024, 0.008), (xs, ys, 0.264), "steel", 0.003, name="tread")
    prism_xz([(-0.06, 0.26), (0.06, 0.26), (0.02, 0.36), (-0.02, 0.36)], ys - 0.01, ys + 0.01, "steel",
             name="socket")
    rod((xs, ys, 0.34), (xs, ys, 0.98), 0.016, WAY, name="shaft")
    o0 = snapshot()
    _tool_handle(0, 0, 0.0, "dark")
    xform(objs_since(o0), M_at((xs, ys, h - 0.012), (0, 0, 0)))
    # fork (behind)
    xf, yf = -0.038, 0.032
    for k in range(4):
        x = xf - 0.054 + 0.036 * k
        box((0.012, 0.012, 0.26), (x, yf, 0.13), "steel", 0.004, name="tine")
    box((0.125, 0.016, 0.03), (xf, yf, 0.27), "steel", 0.006, name="fork_bar")
    prism_xz([(-0.05, 0.28), (0.05, 0.28), (0.018, 0.37), (-0.018, 0.37)], yf - 0.01, yf + 0.01, "steel",
             name="socket")
    rod((xf, yf, 0.35), (xf, yf, 0.97), 0.016, WAY, name="shaft")
    o0 = snapshot()
    _tool_handle(0, 0, 0.0, "dark")
    xform(objs_since(o0), M_at((xf, yf, h - 0.024), (0, 0, 0)))
    # twine tying the shafts
    for z in (0.6, 0.62):
        box((0.06, 0.07, 0.008), ((xs + xf) / 2, (ys + yf) / 2, z), "kraft", 0.003, name="twine")


def main(argv):
    out = os.path.join(D.FAM, "batch9")
    os.makedirs(out, exist_ok=True)
    D.BUILDERS2.update(B9)
    rows = art.read_csv()
    for fid in (argv or BATCH9):
        assert fid in BATCH9, fid
        D.build(fid, rows[fid], out)


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
