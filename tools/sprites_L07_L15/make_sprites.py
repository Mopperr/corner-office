"""Corner Office - L07-L15 sprite requests (level_layouts/ART_REQUESTS.md #1-#17).

Created by Andrew's Helpers (Grok Bots).  Procedural only (Pillow + numpy), add-only.

    python3 make_sprites.py          # regenerates everything under ../assets/

Reads the shipped @1x sprites in /workspace/game/assets (read-only) for silhouettes, draws every
sprite at @1x, and writes <name>@1x.png plus <name>.png = 2x nearest-neighbour, the same
convention as assets/src/build_pass9_sprites.py.  Light comes from the upper left; each surface
gets a light-side highlight and a shadow-side tone, no dark outlines.
"""
import os, json, math, random
import numpy as np
from PIL import Image

G = "/workspace/game"
SRC = G + "/assets/ui"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = ROOT + "/assets/ui"
R = random.Random(1507)
LOG = []          # (entry, rel path @1x, size, hexes, frames, note)
SHEETS = {}

# ---------------------------------------------------------------- colour helpers
def hx(h):
    h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)
def mix(a, b, t): return a * (1 - t) + b * t
WARM = hx("FFF4E0")      # warm key light
COOL = hx("3E3A4F")      # night palette, used to cool shadows
def tones(base):
    b = hx(base) if isinstance(base, str) else base
    return [mix(b * 0.62, COOL, 0.22),   # 0 deep shadow
            mix(b * 0.80, COOL, 0.12),   # 1 shadow side
            b,                           # 2 base (exact requested hex)
            mix(b, WARM, 0.20),          # 3 light side
            mix(b, WARM, 0.42)]          # 4 highlight
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.47

def canvas(w, h): return np.zeros((h, w, 4), float)
def load(rel):
    return np.array(Image.open(SRC + "/" + rel).convert("RGBA")).astype(float)
def put(img, mask, rgb, a=255):
    img[mask, :3] = rgb; img[mask, 3] = a

def light_term(mask, L=(-0.6, -0.8), rim=0.55, grad=0.75, axis=None):
    """Per-pixel lighting value in about [-1.3, 1.3] for a region: a soft gradient across the
    region toward the light plus a rim term (lit edges facing the light, shadowed edges away)."""
    H, W = mask.shape; ys, xs = np.nonzero(mask)
    v = np.zeros(mask.shape)
    if len(xs) == 0: return v
    cx, cy = xs.mean(), ys.mean()
    lx, ly = L
    if axis == "x": ly = 0; lx = -1
    if axis == "y": lx = 0; ly = -1
    n = math.hypot(lx, ly) or 1; lx, ly = lx / n, ly / n
    Y, X = np.mgrid[0:H, 0:W]
    d = (X - cx) * lx + (Y - cy) * ly
    ext = max(1.0, np.abs(d[mask]).max())
    v = grad * d / ext
    pad = np.pad(mask, 1)
    def nb(dx, dy): return pad[1 + dy:H + 1 + dy, 1 + dx:W + 1 + dx]
    sx, sy = int(round(lx)), int(round(ly))
    towards = ~nb(sx, sy) if axis != "y" else ~nb(0, -1)
    away = ~nb(-sx, -sy) if axis != "y" else ~nb(0, 1)
    if axis == "x": towards, away = ~nb(-1, 0), ~nb(1, 0)
    v = v + rim * towards - rim * away
    return v

def shade(img, mask, base, L=(-0.6, -0.8), rim=0.55, grad=0.75, axis=None, bias=0.0, dither=0.12, a=255):
    t = tones(base)
    v = light_term(mask, L, rim, grad, axis) + bias
    H, W = mask.shape
    Y, X = np.mgrid[0:H, 0:W]
    v = v + dither * BAYER[Y % 4, X % 4]
    idx = np.digitize(v, [-0.72, -0.28, 0.30, 0.72])
    for i in range(5):
        m = mask & (idx == i)
        put(img, m, t[i], a)
    return img

def save(img, rel, entry, hexes, frames="1", note=""):
    im = Image.fromarray(np.clip(np.round(img), 0, 255).astype(np.uint8), "RGBA")
    p = OUT + "/" + rel
    os.makedirs(os.path.dirname(p), exist_ok=True)
    base = p[:-4]
    if base.endswith("@1x"): base = base[:-3]
    im.save(base + "@1x.png")
    im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(base + ".png")
    LOG.append(dict(entry=entry, file="assets/ui/" + rel.replace(".png", "") .replace("@1x", "") + "@1x.png",
                    size_1x=list(im.size), size_2x=[im.width * 2, im.height * 2], hexes=hexes, frames=frames, note=note))
    return im

def sheet(frames, rel, entry, hexes, note=""):
    w, h = frames[0].shape[1], frames[0].shape[0]
    s = np.concatenate(frames, axis=1)
    save(s, rel, entry, hexes, frames="%d frames of %dx%d @1x (%dx%d @2x), left to right" % (len(frames), w, h, w * 2, h * 2), note=note)
    SHEETS[os.path.basename(rel).replace("@1x.png", "").replace(".png", "")] = dict(frame=[w * 2, h * 2], frames=len(frames), frame_1x=[w, h])

def colour_mask(img, hexes, tol=6):
    m = np.zeros(img.shape[:2], bool)
    for h in hexes:
        m |= (np.abs(img[..., :3] - hx(h)).max(-1) <= tol) & (img[..., 3] > 128)
    return m

def absorb(labels, src_label, iters=4):
    """Give pixels labelled src_label (old dark outline) the label of their most common labelled
    neighbour, so the outline becomes the shaded edge of the surface it belonged to."""
    lab = labels.copy()
    H, W = lab.shape
    for _ in range(iters):
        todo = np.argwhere(lab == src_label)
        if not len(todo): break
        new = lab.copy()
        for y, x in todo:
            c = {}
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < H and 0 <= xx < W and lab[yy, xx] > 0 and lab[yy, xx] != src_label:
                        c[lab[yy, xx]] = c.get(lab[yy, xx], 0) + 1
            if c: new[y, x] = max(c, key=c.get)
        lab = new
    return lab

# tiny 3x5 pixel font (no anti-aliasing)
FONT = {
 "A": ["010", "101", "111", "101", "101"], "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"],
 "L": ["100", "100", "100", "100", "111"], "O": ["111", "101", "101", "101", "111"], "P": ["110", "101", "110", "100", "100"],
 "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"], "W": ["10001", "10001", "10101", "10101", "01010"],
 "E": ["111", "100", "110", "100", "111"], "N": ["101", "111", "111", "111", "101"],
}
def text_mask(shape, s, x0, y0, sp=1):
    m = np.zeros(shape, bool); x = x0
    for ch in s:
        g = FONT[ch]
        for j, row in enumerate(g):
            for i, c in enumerate(row):
                if c == "1" and 0 <= y0 + j < shape[0] and 0 <= x + i < shape[1]: m[y0 + j, x + i] = True
        x += len(g[0]) + sp
    return m

def ellipse(shape, cx, cy, rx, ry):
    Y, X = np.mgrid[0:shape[0], 0:shape[1]]
    return ((X + 0.5 - cx) / rx) ** 2 + ((Y + 0.5 - cy) / ry) ** 2 <= 1.0
def rect(shape, x0, y0, x1, y1):
    m = np.zeros(shape, bool); m[max(0, y0):y1 + 1, max(0, x0):x1 + 1] = True; return m
def poly(shape, pts):
    from PIL import ImageDraw
    im = Image.new("L", (shape[1], shape[0]), 0); ImageDraw.Draw(im).polygon(pts, fill=1)
    return np.array(im).astype(bool)
def line_mask(shape, pts, w=1):
    from PIL import ImageDraw
    im = Image.new("L", (shape[1], shape[0]), 0); ImageDraw.Draw(im).line(pts, fill=1, width=w)
    return np.array(im).astype(bool)

# =================================================================== #1 parked_car -> cream E8DCC4
def parked_car():
    o = load("driving/parked_car@1x.png"); H, W = o.shape[:2]
    lab = np.zeros((H, W), int)
    lab[colour_mask(o, ["3A4F6B"])] = 1; lab[colour_mask(o, ["5B7A8C"])] = 2
    lab[colour_mask(o, ["3E3A4F"])] = 3; lab[colour_mask(o, ["6B4A3A"])] = 9
    lab = absorb(lab, 9)
    img = canvas(W, H)
    body = lab == 1; win = lab == 2; tyre = lab == 3
    shade(img, body, "E8DCC4", L=(-0.5, -0.85), rim=0.6)
    # roof panel between the windows: slightly brighter, soft crease lines
    roof = body & rect((H, W), 41, 12, 54, 35)
    shade(img, roof, "E8DCC4", L=(-0.5, -0.85), rim=0.0, grad=0.5, bias=0.25)
    # bonnet/boot creases (shadow-side tone, 1 px) and door seam
    for x in (13, 82):
        m = body & rect((H, W), x, 15, x, 32); put(img, m, tones("E8DCC4")[1])
    # windows: tinted glass with sky reflections (diagonal streaks)
    shade(img, win, "7E95A3", L=(-0.5, -0.85), rim=0.45, grad=0.6)
    Y, X = np.mgrid[0:H, 0:W]
    streak = win & (((X + Y) % 13 == 0) | ((X + Y) % 13 == 1)) & (Y < 30)
    put(img, streak, mix(hx("7E95A3"), hx("D6E6EA"), 0.6))
    # tyres: rubber with a lit shoulder
    shade(img, tyre, "3E3A4F", L=(-0.5, -0.85), rim=0.5, grad=0.5)
    # head/tail lights: warm cream at the ends of the body
    for (x, ys) in ((9, (16, 31)), (86, (16, 31))):
        for y in ys:
            for yy in (y, y + 1):
                if body[yy, x]: put(img, np.eye(1, 1, dtype=bool) if False else (np.arange(H)[:, None] == yy) & (np.arange(W)[None, :] == x), hx("FFF1D6") if x == 9 else hx("D9765F"))
    assert ((img[..., 3] > 128) == (o[..., 3] > 128)).all()
    save(img, "driving/parked_car@1x.png", 1, ["#E8DCC4 body", "#7E95A3 glass", "#3E3A4F tyres", "#FFF1D6/#D9765F lamps"],
         note="silhouette/alpha identical to shipped sprite; NOTE the shipped parked_car is shared by L3/L5/L7 day routes")
    save(img, "driving/parked_car_cream@1x.png", 1, ["identical pixels to parked_car"],
         note="same pixels under an L13-only name, in case the day routes (L3/L5/L7) should keep the blue car")

# =================================================================== #2 night_cat -> E07A5F
def night_cat():
    o = load("driving/night_cat@1x.png"); H, W = o.shape[:2]
    body = colour_mask(o, ["3E3A4F", "6B4A3A"]); eye = colour_mask(o, ["E6B655"])
    img = canvas(W, H)
    shade(img, body, "E07A5F", L=(-0.4, -0.9), rim=0.55, grad=0.7)
    # soft tabby stripes across the back in the shadow-side tone
    for x in (8, 11, 14):
        m = body & rect((H, W), x, 4, x, 7); put(img, m, tones("E07A5F")[1])
    put(img, eye, hx("FFF1D6"))                   # eye-shine (2 px)
    # tiny darker socket pixel under each eye so the shine pops
    for y, x in np.argwhere(eye):
        if y + 1 < H and body[y + 1, x]: img[y + 1, x, :3] = tones("E07A5F")[0]
    assert ((img[..., 3] > 128) == (o[..., 3] > 128)).all()
    save(img, "driving/night_cat@1x.png", 2, ["#E07A5F body", "#FFF1D6 eye-shine"], note="same silhouette; eye-shine kept (2 px)")

# =================================================================== #3 neon_sign_open (+ low tier)
def neon(tube_hex, rel, entry, note):
    o = load("driving/neon_sign_open@1x.png"); H, W = o.shape[:2]
    a = o[..., 3] > 128
    frame = colour_mask(o, ["6B4A3A"]); border = colour_mask(o, ["6DBF73"])
    letters = a & (o[..., 0] > 0x80) & (o[..., 1] < 0x90) & ~frame
    board = a & ~frame & ~border & ~letters
    img = canvas(W, H)
    shade(img, board, "3E3A4F", L=(0, -1), rim=0.3, grad=0.35, axis="y")
    shade(img, frame, "625C78", L=(-0.5, -0.85), rim=0.5, grad=0.6)   # metal casing (lighter than board, not an outline)
    tube = hx(tube_hex); core = mix(tube, hx("FFFFFF") if tube_hex == "FFF1D6" else hx("FFF1D6"), 0.55)
    tubes = border | letters
    # glow halo on the board (2 px falloff) - x1.5 glow is engine side, this is the painted bloom
    from scipy.ndimage import binary_dilation
    g1 = binary_dilation(tubes, iterations=1) & board
    g2 = binary_dilation(tubes, iterations=2) & board & ~g1
    img[g1, :3] = mix(img[g1, :3], tube, 0.50); img[g2, :3] = mix(img[g2, :3], tube, 0.26)
    put(img, tubes, tube)
    # hot core: top-left pixel of each stroke run (light side), shadow side lower edge of border tube
    pad = np.pad(tubes, 1)
    top_edge = tubes & ~pad[0:H, 1:W + 1]
    put(img, top_edge & letters, core)
    put(img, border & ~pad[0:H, 1:W + 1], core)
    put(img, border & ~pad[2:H + 2, 1:W + 1], mix(tube, COOL, 0.25))
    assert ((img[..., 3] > 128) == a).all()
    save(img, rel, entry, ["#%s tubes" % tube_hex, "#3E3A4F board", "#625C78 casing"], note=note)

# =================================================================== #4 windsock -> C0392B + cream stripes
def windsock():
    o = load("driving/windsock_sprite@1x.png"); H, W = o.shape[:2]
    lab = np.zeros((H, W), int)
    lab[colour_mask(o, ["9FB3BF"])] = 1; lab[colour_mask(o, ["E6B655"])] = 2; lab[colour_mask(o, ["6B4A3A"])] = 9
    lab = absorb(lab, 9)
    img = canvas(W, H)
    pole = lab == 1; sock = lab == 2
    shade(img, pole, "737F88", axis="x", rim=0.6, grad=0.5, dither=0)       # weathered galvanised steel
    Y, X = np.mgrid[0:H, 0:W]
    xs = X[sock]; x0, x1 = xs.min(), xs.max(); span = x1 - x0 + 1
    band = ((X - x0) * 5 // span)                                  # 5 bands: red cream red cream red
    red = sock & (band % 2 == 0); cream = sock & (band % 2 == 1)
    shade(img, red, "C0392B", L=(0, -1), axis="y", rim=0.5, grad=0.8)
    shade(img, cream, "F4E9D8", L=(0, -1), axis="y", rim=0.5, grad=0.8)
    assert ((img[..., 3] > 128) == (o[..., 3] > 128)).all()
    save(img, "driving/windsock_sprite@1x.png", 4, ["#C0392B sock", "#F4E9D8 cream stripes", "#737F88 pole"],
         note="pole darkened from #9FB3BF to weathered steel #737F88 so the whole sprite reads darker than road/sand (see VALIDATION)")

# =================================================================== #5 gull (redraw 32x20)
def gull():
    W, H = 32, 20; img = canvas(W, H); S = (H, W)
    # wings: gentle gull-wing 'M' seen from above, body along the centre
    wingL = poly(S, [(15, 9), (10, 5), (4, 3), (0, 4), (3, 6), (9, 9), (14, 12)])
    wingR = poly(S, [(17, 9), (22, 5), (28, 3), (31, 4), (29, 6), (23, 9), (18, 12)])
    body = ellipse(S, 16, 11, 2.6, 6.2)
    head = ellipse(S, 16, 5.0, 2.0, 2.2)
    tail = poly(S, [(14, 15), (18, 15), (17.5, 19), (14.5, 19)])
    tips = (wingL & (np.mgrid[0:H, 0:W][1] <= 4)) | (wingR & (np.mgrid[0:H, 0:W][1] >= 27))
    wings = (wingL | wingR) & ~tips
    shade(img, wings, "646D78", L=(-0.4, -0.9), rim=0.55, grad=0.6)
    shade(img, tips, "3E3A4F", L=(-0.4, -0.9), rim=0.4, grad=0.4)
    shade(img, body | tail, "E9E5DC", L=(-0.6, -0.8), rim=0.5, grad=0.6)
    shade(img, head, "FBF7EF", L=(-0.6, -0.8), rim=0.4, grad=0.5)
    put(img, rect(S, 16, 2, 16, 2), hx("E6B655"))                  # beak
    put(img, rect(S, 15, 4, 15, 4), hx("3E3A4F"))                  # eye
    save(img, "driving/gull@1x.png", 5, ["#E9E5DC/#FBF7EF white body", "#646D78 grey mantle", "#3E3A4F wing tips", "#E6B655 beak"],
         note="redrawn 32x20 (was 20x12); top-down flying gull, avg lum tuned to ~0.29 like the old sprite")

# =================================================================== #6 lighthouse -> C9714F + cream bands
def lighthouse():
    o = load("driving/lighthouse_sprite@1x.png"); H, W = o.shape[:2]
    a = o[..., 3] > 128
    Y, X = np.mgrid[0:H, 0:W]
    lantern = a & (Y <= 11)
    glass = colour_mask(o, ["BFDDEA"])
    tower = a & (Y >= 12)
    img = canvas(W, H)
    # lantern room: dark terracotta housing, glass with lamp glow
    shade(img, lantern & ~glass, "A85A3E", L=(-0.6, -0.8), rim=0.5)
    shade(img, glass, "BFDDEA", L=(-0.6, -0.8), rim=0.3, grad=0.4)
    lamp = glass & ellipse((H, W), 32.5, 8.0, 3.2, 2.4)
    put(img, lamp, hx("FFF1D6"))
    # tower: terracotta with two cream bands, cylinder shading (lit left)
    ty = Y[tower]; t0, t1 = ty.min(), ty.max()
    bandA = tower & (Y >= t0 + 21) & (Y <= t0 + 25)
    bandB = tower & (Y >= t0 + 47) & (Y <= t0 + 51)
    gallery = tower & (Y <= t0 + 1)
    terr = tower & ~bandA & ~bandB & ~gallery
    shade(img, terr, "C9714F", axis="x", rim=0.6, grad=0.85)
    shade(img, bandA | bandB, "F4E9D8", axis="x", rim=0.6, grad=0.85)
    shade(img, gallery, "8E8276", axis="x", rim=0.4, grad=0.6)
    # door + two small windows (shadow tone, not outlines)
    put(img, tower & rect((H, W), 30, t1 - 9, 34, t1), tones("C9714F")[0])
    for wy in (t0 + 10, t0 + 36): put(img, tower & rect((H, W), 31, wy, 33, wy + 3), mix(hx("BFDDEA"), COOL, 0.35))
    # base: soft AO band
    put(img, tower & (Y == t1), tones("C9714F")[0])
    assert ((img[..., 3] > 128) == a).all()
    save(img, "driving/lighthouse_sprite@1x.png", 6, ["#C9714F tower", "#F4E9D8 cream bands", "#A85A3E lantern", "#BFDDEA/#FFF1D6 lamp"],
         note="alpha identical; was cream tower + one terracotta band")

# =================================================================== #7 dune -> A8783F + sage tufts
def dune():
    o = load("driving/dune@1x.png"); H, W = o.shape[:2]
    a = o[..., 3] > 128
    grass0 = colour_mask(o, ["8FAF7E"])
    body = a & ~grass0
    img = canvas(W, H)
    Y, X = np.mgrid[0:H, 0:W]
    shade(img, body, "A8783F", L=(-0.75, -0.65), rim=0.5, grad=0.8)
    # wind ripples on the lit slope (light-side tone, 1 px, curved)
    t = tones("A8783F")
    for k in range(3):
        m = body & (np.abs(Y - (0.5 * X + 14 + 7 * k) + 0.012 * (X - 40) ** 2) < 0.5) & (X < 55)
        put(img, m, t[3])
    # sage grass tufts (blades with a light tip, darker root)
    tuftpix = np.zeros((H, W), bool)
    def tuft(cx, cy):
        for dx, h in ((-2, 3), (-1, 4), (0, 5), (1, 4), (2, 3)):
            for j in range(h):
                xx = cx + dx + (1 if (j > 2 and dx > 0) else (-1 if (j > 2 and dx < 0) else 0)); yy = cy - j
                if 0 <= xx < W and 0 <= yy < H and (a[yy, xx] or j > 0):
                    if body[yy, xx] or not a[yy, xx]:
                        pass
                    if a[yy, xx] or j >= 1:
                        if a[yy, xx]:
                            tuftpix[yy, xx] = True
                            img[yy, xx, :3] = hx("6E8F62") if j == 0 else (hx("A9C49A") if j == h - 1 else hx("8FAF7E")); img[yy, xx, 3] = 255
    # tufts sit just inside the silhouette near the crest and slopes
    for cx in (22, 47, 63, 80):
        col = np.nonzero(a[:, cx])[0]
        if len(col): tuft(cx, col.min() + 5)
    shade(img, grass0, "8FAF7E", rim=0.3, grad=0.4)
    assert ((img[..., 3] > 128) == a).all()
    save(img, "driving/dune@1x.png", 7, ["#A8783F body/shadow", "#8FAF7E sage tufts (#6E8F62 roots, #A9C49A tips)"],
         note="alpha identical; tufts drawn inside the silhouette")

# =================================================================== #8 road_L8_market_lane (128x128, tiles vertically)
def market_lane():
    T = 128; img = canvas(T, T); S = (T, T)
    Y, X = np.mgrid[0:T, 0:T]
    lane = rect(S, 16, 0, 111, T - 1)
    curbL = rect(S, 0, 0, 15, T - 1); curbR = rect(S, 112, 0, 127, T - 1)
    rng = np.random.RandomState(8)
    put(img, lane, hx("E6D8C3"))
    # very light grain (+-1 level, tiles because it is per-pixel noise) and gutter AO next to the curbs
    n = rng.randint(-1, 2, S)
    img[lane, :3] += n[lane][:, None]
    for x, t in ((16, 0.10), (17, 0.05), (111, 0.10), (110, 0.05)):
        m = lane & (X == x); img[m, :3] = mix(img[m, :3], hx("6B5A4A"), t)
    # curb: dark kerb stones, 32 px joints (128 / 4 -> seamless), lit top face toward the lane on the left curb
    c = tones("6B5A4A")
    put(img, curbL | curbR, c[2])
    put(img, curbL & (X >= 13), c[3]); put(img, curbL & (X == 15), c[4])        # left kerb lip catches the light
    put(img, curbR & (X <= 114), c[1]); put(img, curbR & (X == 112), c[0])      # right kerb lip on the shadow side
    put(img, (curbL | curbR) & (Y % 32 == 31), c[1])                           # stone joints
    put(img, curbL & (Y % 32 == 0) & (X < 13), c[3])
    img[(curbL | curbR), :3] += n[(curbL | curbR)][:, None]
    save(img, "driving/road_L8_market_lane@1x.png", 8, ["#E6D8C3 lane", "#6B5A4A curb"],
         note="lane x16-111 (same 3 m road as the shipped tile), curb x0-15 and x112-127 where the sage verge was; no centre line; tiles top-to-bottom (all vertical detail repeats every 32 px)")

# =================================================================== #9 meteor streak (vfx, one-shot)
def meteor():
    FW, FH, N = 128, 64, 6
    frames = []
    head_c = hx("FFF1D6"); glow = hx("F2B35E"); tail = hx("BFDDEA")
    for f in range(N):
        img = canvas(FW, FH)
        p = f / (N - 1)
        hxp, hyp = 118 - 100 * p, 6 + 46 * p                      # head travels upper-right -> lower-left
        L = [10, 26, 40, 44, 30, 12][f]                          # tail grows then burns out
        fade = [1.0, 1.0, 1.0, 0.9, 0.6, 0.25][f]
        dx, dy = 100 / math.hypot(100, 46), 46 / math.hypot(100, 46)
        for i in range(int(L)):
            t = i / max(1, L)
            x, y = hxp + dx * i, hyp - dy * i
            xi, yi = int(round(x)), int(round(y))
            if 0 <= xi < FW and 0 <= yi < FH:
                col = mix(mix(head_c, glow, min(1, t * 2)), tail, max(0, t * 2 - 1))
                alpha = 255 * fade * (1 - t) ** 1.3
                if alpha > img[yi, xi, 3]: img[yi, xi, :3] = col; img[yi, xi, 3] = alpha
                if t < 0.35 and 0 <= yi - 1:                      # 2 px thick near the head
                    if alpha * 0.6 > img[yi - 1, xi, 3]: img[yi - 1, xi, :3] = col; img[yi - 1, xi, 3] = alpha * 0.6
        hxi, hyi = int(round(hxp)), int(round(hyp))
        for (ox, oy, al) in ((0, 0, 1.0), (-1, 0, .55), (0, 1, .55), (1, 0, .35), (0, -1, .35), (-1, 1, .3)):
            x, y = hxi + ox, hyi + oy
            if 0 <= x < FW and 0 <= y < FH and f < N - 1:
                img[y, x, :3] = head_c if (ox, oy) == (0, 0) else mix(head_c, glow, 0.4); img[y, x, 3] = max(img[y, x, 3], 255 * al * fade)
        frames.append(img)
    sheet(frames, "vfx/vfx_meteor_streak@1x.png", 9, ["#FFF1D6 head", "#F2B35E warm glow", "#BFDDEA cool tail end"],
          note="one-shot (no loop), play ~12 fps; head moves upper-right to lower-left inside the frame and burns out in frame 6")

# =================================================================== #10 wind streak across the lane (white, loop)
def wind_streak():
    FW, FH, N = 128, 64, 6
    lanes = [(10, 0.0, 34), (26, 0.33, 46), (41, 0.66, 28), (54, 0.15, 38)]
    frames = []
    for f in range(N):
        img = canvas(FW, FH)
        for (y, ph, ln) in lanes:
            p = (f / N + ph) % 1.0
            x0 = -ln + p * (FW + ln)
            for i in range(ln):
                t = i / ln
                x = int(x0 + i); yy = y + int(round(1.5 * math.sin(t * math.pi * 1.2 + ph * 6)))
                if 0 <= x < FW:
                    al = 255 * (math.sin(t * math.pi) ** 0.8) * 0.85
                    img[yy, x, :3] = 255; img[yy, x, 3] = max(img[yy, x, 3], al)
                    if 0.35 < t < 0.8 and yy + 1 < FH:      # soft lower edge (light grey-white, semi-transparent)
                        img[yy + 1, x, :3] = hx("E8EEF2"); img[yy + 1, x, 3] = max(img[yy + 1, x, 3], al * 0.35)
            # curl at the lead end, like the shipped vfx_wind_streak
            cx = int(x0 + ln)
            for (ox, oy) in ((0, -1), (1, -2), (2, -1), (1, 0)):
                if 0 <= cx + ox < FW and 0 <= y + oy < FH and ph < 0.5:
                    img[y + oy, cx + ox, :3] = 255; img[y + oy, cx + ox, 3] = 150
        frames.append(img)
    sheet(frames, "vfx/vfx_wind_streak_lane@1x.png", 10, ["#FFFFFF streaks (alpha 0-217)", "#E8EEF2 soft underside"],
          note="seamless 6-frame loop (each streak wraps), 128 px wide so it spans the 96 px lane; flows left to right (flip_h for the other wind direction)")

# =================================================================== #11 sandwich
def sandwich():
    W, H = 20, 16; S = (H, W); img = canvas(W, H)
    Y, X = np.mgrid[0:H, 0:W]
    # triangle-cut sandwich, side-on 3/4: top slice, fillings, bottom slice
    top = poly(S, [(1, 8), (10, 1), (19, 8), (18, 9), (2, 9)])
    lettuce = poly(S, [(1, 9), (19, 9), (19, 11), (1, 11)]) & ~top
    tomato = rect(S, 3, 10, 16, 10) & ((X % 5) < 3)
    cheese = poly(S, [(2, 11), (18, 11), (18, 12), (2, 12)])
    bottom = poly(S, [(1, 12), (19, 12), (19, 14), (1, 14)])
    shade(img, bottom, "E6C48E", L=(-0.6, -0.8), rim=0.5)
    shade(img, cheese, "E6B655", rim=0.3, grad=0.4)
    shade(img, lettuce, "8FAF7E", rim=0.4, grad=0.5)
    shade(img, tomato, "D9765F", rim=0.3, grad=0.4)
    crust = top & ~poly(S, [(3, 8), (10, 2.6), (17, 8)])
    shade(img, top & ~crust, "F4E3C1", L=(-0.6, -0.8), rim=0.3, grad=0.6)
    shade(img, crust, "C68B59", L=(-0.6, -0.8), rim=0.5, grad=0.6)
    # lettuce frill dips below the slice edge
    for x in range(2, 19, 3): put(img, rect(S, x, 11, x, 11), hx("A9C49A"))
    save(img, "driving/sandwich@1x.png", 11, ["#F4E3C1 bread", "#C68B59 crust", "#8FAF7E lettuce", "#D9765F tomato", "#E6B655 cheese"],
         note="20x16 @1x (0.6 x 0.5 m at 32 px/m, enlarged so the 16 px readability minimum holds while a gull carries it)")

# =================================================================== #12 hill crest shade overlay
def hill_shade():
    T = 128; img = canvas(T, T)
    Y, X = np.mgrid[0:T, 0:T]
    u = X / (T - 1)                               # along the drive (west->east); crest at u=0.5
    light = np.clip(1 - np.abs(u - 0.32) / 0.22, 0, 1)
    dark = np.clip(1 - np.abs(u - 0.70) / 0.24, 0, 1)
    a_l = 70 * light ** 1.2; a_d = 92 * dark ** 1.2
    # band quantisation with Bayer dither -> pixel-art steps; Bayer is 4x4 so it tiles in 128
    q = lambda a: np.floor(a / 18 + BAYER[Y % 4, X % 4] + 0.5) * 18
    al = np.clip(q(a_l), 0, 255); ad = np.clip(q(a_d), 0, 255)
    use_l = al >= ad
    img[..., :3] = np.where(use_l[..., None], hx("FFF1D6"), hx("3E3A4F"))
    img[..., 3] = np.where(use_l, al, ad)
    # crest line: one soft light column
    img[:, 64, :3] = hx("FFF1D6"); img[:, 64, 3] = np.maximum(img[:, 64, 3], 40)
    save(img, "driving/hill_crest_shade@1x.png", 12, ["#FFF1D6 lit band (alpha<=72)", "#3E3A4F shade band (alpha<=90)"],
         note="128x128 overlay, multiply/normal blend over the road; bands run across X (uphill lit on the left, crest at x=64, far side shaded on the right), constant in Y so it tiles vertically; flip_h for the other direction")

# =================================================================== #13 hospital front
def hospital():
    W, H = 160, 96; S = (H, W); img = canvas(W, H)
    Y, X = np.mgrid[0:H, 0:W]
    wall = rect(S, 4, 14, 155, 95)
    parapet = rect(S, 2, 10, 157, 15)
    shade(img, wall, "F4E9D8", L=(-0.6, -0.8), rim=0.4, grad=0.22, dither=0.05)
    shade(img, parapet, "A8C9B8", L=(-0.6, -0.8), rim=0.5, grad=0.5)
    # base plinth + mint stripe
    shade(img, rect(S, 4, 88, 155, 95), "A8ADB4", L=(-0.6, -0.8), rim=0.4, grad=0.4)
    shade(img, rect(S, 4, 30, 155, 32), "A8C9B8", rim=0.3, grad=0.4)
    # windows: 2 rows, sky reflection, sill shadow
    for row, wy in enumerate((19, 37)):
        for wx in list(range(10, 58, 16)) + list(range(106, 152, 16)):
            g = rect(S, wx, wy, wx + 10, wy + 8)
            shade(img, g, "7FA3B8", L=(-0.6, -0.8), rim=0.5, grad=0.6)
            put(img, g & ((X - wx + Y - wy) % 9 == 2), mix(hx("7FA3B8"), hx("D6E6EA"), 0.65))
            put(img, rect(S, wx, wy + 9, wx + 10, wy + 9), tones("F4E9D8")[1])
    # entrance: canopy + sliding glass doors
    canopy = rect(S, 58, 54, 101, 58)
    shade(img, canopy, "A8C9B8", L=(0, -1), axis="y", rim=0.6, grad=0.6)
    put(img, rect(S, 58, 59, 101, 59), tones("F4E9D8")[0])                # canopy shadow on wall
    doors = rect(S, 64, 61, 95, 87)
    shade(img, doors, "8FB3C4", L=(-0.6, -0.8), rim=0.5, grad=0.6)
    put(img, rect(S, 79, 61, 80, 87), hx("A8ADB4"))
    put(img, doors & ((X + Y) % 11 == 3) & (Y < 80), mix(hx("8FB3C4"), hx("F4E9D8"), 0.6))
    # sign: terracotta-red square with cream cross + HOSPITAL lettering
    sq = rect(S, 70, 34, 89, 51)
    shade(img, sq, "C0392B", L=(-0.6, -0.8), rim=0.5, grad=0.5)
    cross = (rect(S, 78, 37, 81, 48) | rect(S, 73, 41, 86, 44))
    shade(img, cross, "FFF1D6", rim=0.3, grad=0.3)
    put(img, text_mask(S, "HOSPITAL", 64, 21, 1), hx("4F7A5A"))
    # planters with sage shrubs either side of the door
    for px in (48, 104):
        shade(img, rect(S, px, 80, px + 9, 87), "C9714F", L=(-0.6, -0.8), rim=0.5)
        shade(img, ellipse(S, px + 5, 77, 6, 5) & (Y < 81), "8FAF7E", L=(-0.6, -0.8), rim=0.5, grad=0.6)
    save(img, "driving/hospital_front@1x.png", 13, ["#F4E9D8 walls", "#A8C9B8 mint trim (L7)", "#7FA3B8/#8FB3C4 glass", "#C0392B sign + #FFF1D6 cross", "#4F7A5A lettering"],
         note="160x96 @1x, front elevation like shopfront/diner (128x96 / 128x64); 5 m wide at 32 px/m")

# =================================================================== #14 Gerald fish icons
def gerald(mood):
    W = H = 64; S = (H, W); img = canvas(W, H)
    Y, X = np.mgrid[0:H, 0:W]
    # bowl water disc behind (soft blue, part-transparent), Gerald orange #F28C28 (L7-5 review)
    water = ellipse(S, 32, 34, 27, 25)
    shade(img, water, "BFDDEA", L=(-0.6, -0.8), rim=0.5, grad=0.5, a=235)
    put(img, water & (Y > 52) & ((X + Y) % 3 == 0), hx("A9C9D6"), 235)    # sandy bottom hint
    tilt = 0 if mood == "happy" else 1
    body = ellipse(S, 30, 34 + tilt, 15, 10)
    tail = poly(S, [(44, 34 + tilt), (57, 24 + 3 * tilt), (54, 34 + tilt), (57, 44 - tilt)])
    fin_t = poly(S, [(24, 25 + tilt), (34, 19 + tilt), (38, 26 + tilt)])
    fin_b = poly(S, [(28, 43 + tilt), (34, 49 + tilt), (36, 42 + tilt)])
    shade(img, tail | fin_t | fin_b, "D9765F", L=(-0.6, -0.8), rim=0.5, grad=0.6)
    shade(img, body, "F28C28", L=(-0.6, -0.8), rim=0.6, grad=0.8)
    # belly highlight and scale arcs (shadow-side tone, not outlines)
    put(img, body & ellipse(S, 28, 39 + tilt, 9, 3.5), mix(hx("F28C28"), hx("FFF1D6"), 0.45))
    for sx in (31, 36):
        put(img, body & (np.abs(np.hypot(X - sx, Y - (33 + tilt)) - 3.5) < 0.5) & (X > sx), tones("F28C28")[1])
    # eye
    ex, ey = 21, 31 + tilt
    put(img, ellipse(S, ex, ey, 3.2, 3.2), hx("FFF8EC"))
    py = ey + (0 if mood == "happy" else -1)
    put(img, ellipse(S, ex - 0.5, py + 0.3, 1.7, 1.9), hx("2B2622"))
    put(img, rect(S, ex - 2, py - 1, ex - 2, py - 1), hx("FFFFFF"))
    if mood == "happy":
        smile = line_mask(S, [(15, 37), (17, 39), (20, 39)]); put(img, smile & body, tones("F28C28")[0])
        put(img, ellipse(S, 23, 37, 1.6, 1.0) & body, hx("E8B4A8"))          # cheek
        bub = [(12, 18, 2.6), (8, 10, 1.8), (15, 7, 1.3)]
        for bx, by, r in bub:
            ring = ellipse(S, bx, by, r + 0.6, r + 0.6) & ~ellipse(S, bx, by, r - 0.5, r - 0.5)
            put(img, ring, hx("FFFFFF"), 220); put(img, rect(S, int(bx - r / 2), int(by - r / 2), int(bx - r / 2), int(by - r / 2)), hx("FFFFFF"))
        for (sx, sy) in ((48, 12), (54, 18)):                                  # sparkles
            put(img, rect(S, sx - 2, sy, sx + 2, sy) | rect(S, sx, sy - 2, sx, sy + 2), hx("E6B655"))
            put(img, rect(S, sx, sy, sx, sy), hx("FFF1D6"))
    else:
        frown = line_mask(S, [(15, 40), (17, 38), (20, 39)]); put(img, frown & body, tones("F28C28")[0])
        brow = line_mask(S, [(18, 26), (23, 27)]); put(img, brow, tones("F28C28")[0])
        drop = ellipse(S, 13, 22, 1.8, 2.4) | poly(S, [(12, 21), (13, 17), (14.5, 21)])
        shade(img, drop, "7FA3B8", rim=0.4, grad=0.5); put(img, rect(S, 12, 21, 12, 21), hx("FFFFFF"))
        # sloshing water line
        wave = water & (np.abs(Y - (14 + 2.5 * np.sin(X / 5.0))) < 0.8)
        put(img, wave, hx("FFFFFF"), 230)
        put(img, water & (Y < 14 + 2.5 * np.sin(X / 5.0)), mix(hx("BFDDEA"), hx("FFFFFF"), 0.5), 120)
    save(img, "icons/gerald_%s_fish@1x.png" % mood, 14, ["#F28C28 Gerald (L7-5 review hex)", "#D9765F fins", "#BFDDEA water"] +
         (["#E6B655 sparkles", "#E8B4A8 cheek"] if mood == "happy" else ["#7FA3B8 sweat drop"]),
         note="64x64 @1x / 128x128 like icon_*.png; the placeholder names gerald_%s_fish.png = the 128 px file" % mood)

# =================================================================== #15 flagger 2-frame STOP / SLOW
def person(img, S, x0, vest="E6B655", pose=0):
    """32x48 frame, worker facing the camera, colours from npc_flagger.glb (mustard vest, skin E8B4A8,
    blue 7FA3B8 trousers, night boots/hat brim)."""
    legs = rect(S, x0 + 12, 32, x0 + 14, 45) | rect(S, x0 + 17, 32, x0 + 19, 45)
    shade(img, legs, "7FA3B8", rim=0.5, grad=0.5)
    shade(img, rect(S, x0 + 11, 45, x0 + 14, 47) | rect(S, x0 + 17, 45, x0 + 20, 47), "3E3A4F", rim=0.4, grad=0.4)
    torso = rect(S, x0 + 11, 19, x0 + 20, 32) & ~rect(S, x0 + 11, 19, x0 + 11, 19) & ~rect(S, x0 + 20, 19, x0 + 20, 19)
    shade(img, torso, vest, rim=0.55, grad=0.6)
    put(img, rect(S, x0 + 11, 27, x0 + 20, 28), hx("F4E9D8"))             # reflective band
    put(img, rect(S, x0 + 15, 20, x0 + 16, 26), tones(vest)[1])            # zip shadow
    head = ellipse(S, x0 + 15.5, 14.5, 3.6, 4.0)
    shade(img, head, "E8B4A8", rim=0.5, grad=0.6)
    hat = (ellipse(S, x0 + 15.5, 11.5, 4.4, 3.2) & (np.mgrid[0:S[0], 0:S[1]][0] <= 11)) | rect(S, x0 + 10, 11, x0 + 21, 12)
    shade(img, hat, "E6B655", L=(-0.6, -0.8), rim=0.6, grad=0.6)
    put(img, rect(S, x0 + 14, 15, x0 + 14, 15) | rect(S, x0 + 17, 15, x0 + 17, 15), hx("3E3A4F"))
    return img

def flagger():
    FW, FH = 32, 48; frames = []
    for word, face, ink in (("STOP", "D9765F", "FFF1D6"), ("SLOW", "E6B655", "3E3A4F")):
        S = (FH, FW); img = canvas(FW, FH)
        person(img, S, 6)
        # left arm holding the pole, sign raised to the upper left of the head
        shade(img, rect(S, 8, 9, 8, 40), "6B4A3A", axis="x", rim=0.5, grad=0.4, dither=0)   # pole
        shade(img, rect(S, 9, 21, 16, 22), "E8B4A8", rim=0.4, grad=0.4)                     # arm to the pole
        octa = poly(S, [(3, 0), (14, 0), (17, 3), (17, 7), (14, 10), (3, 10), (0, 7), (0, 3)])
        shade(img, octa, face, L=(-0.6, -0.8), rim=0.55, grad=0.6)
        tw = sum(len(FONT[c][0]) + 1 for c in word) - 1
        put(img, text_mask(S, word, (18 - tw) // 2, 3, 1), hx(ink))
        # right arm down / waving slightly on SLOW
        if word == "STOP": shade(img, rect(S, 27, 20, 28, 30), "E6B655", rim=0.4)
        else: shade(img, poly(S, [(27, 20), (29, 20), (31, 25), (29, 27)]), "E6B655", rim=0.4)
        frames.append(img)
    sheet(frames, "driving/flagger_sheet@1x.png", 15, ["#D9765F STOP face + #FFF1D6 text", "#E6B655 SLOW face + #3E3A4F text",
          "#E6B655 vest/hat", "#E8B4A8 skin", "#7FA3B8 trousers", "#6B4A3A pole"],
          note="frame 0 = STOP, frame 1 = SLOW; 32x48 like jogger; colours from npc_flagger.glb / flagger_sign.glb; sign text in a 3x5 pixel font on an 18x11 octagon held up on a pole")

# =================================================================== #16 steel plate 77x58
def steel_plate():
    W, H = 77, 58; S = (H, W); img = canvas(W, H)
    Y, X = np.mgrid[0:H, 0:W]
    plate = rect(S, 0, 0, W - 1, H - 1) & ~(rect(S, 0, 0, 0, 0) | rect(S, W - 1, 0, W - 1, 0) | rect(S, 0, H - 1, 0, H - 1) | rect(S, W - 1, H - 1, W - 1, H - 1))
    shade(img, plate, "A8ADB4", L=(-0.6, -0.8), rim=0.7, grad=0.3, dither=0.05)
    # diamond tread: short diagonal lugs alternating direction, light side + shadow pixel
    t = tones("A8ADB4")
    for gy in range(4, H - 3, 5):
        for gx in range(4 + (gy // 5 % 2) * 3, W - 4, 6):
            d = 1 if ((gx // 6 + gy // 5) % 2) else -1
            img[gy, gx, :3] = t[4]; img[gy + 1, gx + d, :3] = t[3]; img[gy + 2, gx + 2 * d, :3] = t[1]; img[gy + 2, gx + 2 * d + d, :3] = t[0]
    # wear: soft darker tyre-track bands and a little grime near the edges
    for cx in (22, 55):
        m = plate & (np.abs(X - cx) < 6)
        img[m, :3] = mix(img[m, :3], hx("8E8276"), 0.18)
    # bolts in the corners
    for bx, by in ((4, 4), (W - 5, 4), (4, H - 5), (W - 5, H - 5)):
        put(img, ellipse(S, bx + 0.5, by + 0.5, 1.7, 1.7), t[1]); put(img, rect(S, bx, by, bx, by), t[4])
    save(img, "driving/steel_plate@1x.png", 16, ["#A8ADB4 chrome-grey steel (L7 chrome palette)", "#8E8276 wear"],
         note="exact 77x58 @1x = 2.4 x 1.8 m at 32 px/m, top-down; diamond tread, bevel light top-left")

# =================================================================== #17 jackhammer worker 4-frame loop + dust
def jackhammer():
    FW, FH = 40, 48; frames = []
    for f in range(4):
        S = (FH, FW); img = canvas(FW, FH)
        bob = [0, 1, 0, 1][f]
        sub = canvas(32, 48); person(sub, (48, 32), 0)
        if bob:
            sub[1:] = sub[:-1].copy(); sub[0] = 0
            sub[46:48] = 0; person_feet = rect((48, 32), 11, 45, 14, 47) | rect((48, 32), 17, 45, 20, 47)
            shade(sub, person_feet, "3E3A4F", rim=0.4, grad=0.4)
        img[:, 0:32] = np.where(sub[..., 3:4] > 0, sub, img[:, 0:32])
        # jackhammer: handle bar at the hands, body down to the ground in front-right of the worker
        jy = bob
        shade(img, rect(S, 18, 26 + jy, 27, 27 + jy), "3E3A4F", rim=0.4, grad=0.4)        # handle
        shade(img, rect(S, 20, 22 + jy, 21, 26 + jy) | rect(S, 25, 22 + jy, 26, 26 + jy), "E8B4A8", rim=0.3)  # forearms
        shade(img, rect(S, 21, 28 + jy, 25, 38 + jy), "C0392B", rim=0.55, grad=0.6)       # tool body (stamp red)
        shade(img, rect(S, 22, 39 + jy, 24, 45 + jy) | rect(S, 23, 46, 23, 47), "A8ADB4", axis="x", rim=0.5)  # chisel
        # dust puff at the chisel, grows and fades over the loop
        r = [1.5, 3.0, 4.2, 2.4][f]; al = [200, 190, 140, 170][f]
        for (dx, dy, k) in ((-3, 0, 1.0), (4, -1, 0.8), (1, -3, 0.7), (-6, -2, 0.5), (8, -3, 0.45)):
            rr = r * k
            if rr < 0.8: continue
            m = ellipse(S, 23 + dx * r / 3, 46 + dy * r / 3, rr, rr * 0.75) & (img[..., 3] == 0)
            put(img, m, hx("D9B98A"), al)
            put(img, m & ellipse(S, 22 + dx * r / 3, 45 + dy * r / 3, rr * 0.6, rr * 0.45), hx("EADBB8"), al)
        frames.append(img)
    sheet(frames, "driving/jackhammer_worker_sheet@1x.png", 17, ["#E6B655 vest/hat", "#C0392B jackhammer", "#A8ADB4 chisel",
          "#D9B98A/#EADBB8 dust (semi-transparent)"],
          note="4-frame loop at ~10 fps; worker bobs 1 px on frames 1/3, dust puff grows f0->f2 and settles f3; 40x48 frames (32 px worker + 8 px for the puff)")

def main():
    parked_car(); night_cat()
    neon("E07A5F", "driving/neon_sign_open@1x.png", 3, "OPEN lettering + border tube in L13 terracotta neon; painted 2 px bloom on the board")
    neon("FFF1D6", "driving/neon_sign_open_low@1x.png", 3, "low tier: cream tubes")
    windsock(); gull(); lighthouse(); dune(); market_lane()
    meteor(); wind_streak(); sandwich(); hill_shade(); hospital(); gerald("happy"); gerald("worried")
    flagger(); steel_plate(); jackhammer()
    json.dump(SHEETS, open(OUT + "/sheets_L07_L15.json", "w"), indent=1)
    json.dump(LOG, open(ROOT + "/_build/outputs.json", "w"), indent=1)
    for l in LOG: print(l["entry"], l["file"], l["size_1x"], l["frames"])

if __name__ == "__main__":
    main()
