"""Verification for the L07-L15 sprites (read-only on the repo).
1) per-file stats: size, @2x == nearest(@1x), alpha vs shipped sprite, avg luminance (checker's sprite_stats method),
   C vs the backdrops named in the level JSONs, night beam-edge C (L13 tint/edge_glow), no #6B4A3A outline ring.
2) runs the real, unmodified level_layouts/tools/check_level_layout.py on /tmp copies of the level/route JSONs
   (baseline copy + a copy whose art_sprites_1x point at pr21-new/sprites_L07_L15/...).
Writes ../_build/verify.json."""
import os, sys, json, shutil, copy, importlib.util
import numpy as np
from PIL import Image
G = "/workspace/game"; ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REL = os.path.relpath(ROOT, G)
spec = importlib.util.spec_from_file_location("chk", G + "/level_layouts/tools/check_level_layout.py")
chk = importlib.util.module_from_spec(spec); sys.argv = ["x"]; spec.loader.exec_module(chk)
lum, C = chk.lum, chk.C
outs = json.load(open(ROOT + "/_build/outputs.json"))
def stats(path):
    try: w, h, c = chk.sprite_stats(path)
    except ZeroDivisionError:      # all pixels alpha<=128 (overlay): alpha-weighted mean instead
        a = np.array(Image.open(G + "/" + path).convert("RGBA")).astype(float); wt = a[..., 3:4] / 255
        h, w = a.shape[:2]; c = list((a[..., :3] * wt).sum((0, 1)) / wt.sum() / 255)
    return w, h, c, lum(c)
bk = {"road_L13_night": lum(stats("assets/ui/driving/road_L13_night@1x.png")[2]),
      "road_L15_cliff": lum(stats("assets/ui/driving/road_L15_cliff@1x.png")[2]),
      "sand_tile": lum(stats("assets/ui/driving/sand_tile@1x.png")[2])}
NIGHT = {"tint": 0.45, "edge_glow": 1.3}
VS = {"parked_car": ["road_L13_night"], "night_cat": ["road_L13_night"], "neon_sign_open": ["road_L13_night"], "neon_sign_open_low": ["road_L13_night"],
      "windsock_sprite": ["road_L15_cliff", "sand_tile"], "gull": ["road_L15_cliff", "sand_tile"], "lighthouse_sprite": ["road_L15_cliff", "sand_tile"],
      "dune": ["road_L15_cliff", "sand_tile"], "sandwich": ["road_L15_cliff", "sand_tile"]}
rows = []
for o in outs:
    rel1 = REL + "/" + o["file"]; name = os.path.basename(o["file"]).replace("@1x.png", "")
    a = np.array(Image.open(G + "/" + rel1).convert("RGBA")); b = np.array(Image.open(G + "/" + rel1.replace("@1x.png", ".png")).convert("RGBA"))
    two = b.shape[:2] == (a.shape[0] * 2, a.shape[1] * 2) and (b == a.repeat(2, 0).repeat(2, 1)).all()
    w, h, c, L = stats(rel1)
    row = dict(entry=o["entry"], name=name, file=rel1, size_1x=[w, h], size_2x=[b.shape[1], b.shape[0]], x2_nearest_exact=bool(two),
               avg_hex="#%02X%02X%02X" % tuple(int(v * 255) for v in c), lum=round(L, 3))
    shipped = G + "/assets/ui/driving/%s@1x.png" % name
    if os.path.exists(shipped):
        s = np.array(Image.open(shipped).convert("RGBA")); sw, sh, sc, sL = stats("assets/ui/driving/%s@1x.png" % name)
        row["shipped"] = dict(size=[sw, sh], lum=round(sL, 3))
        row["alpha_identical_to_shipped"] = bool(s.shape == a.shape and ((s[..., 3] > 128) == (a[..., 3] > 128)).all())
    op = a[..., 3] > 128
    row["outline_6B4A3A_px"] = int(((np.abs(a[..., :3].astype(int) - [0x6B, 0x4A, 0x3A]).max(-1) <= 2) & op).sum())
    vs = {}
    for k in VS.get(name, []):
        lb = bk[k]; v = {"C": C(L, lb)}
        if k == "road_L13_night":
            e = 1 - NIGHT["tint"] / 2; g = NIGHT["edge_glow"]; v["C_beam_edge"] = C(min(1, L * e * g), lb * e)
        if "shipped" in row: v["C_shipped"] = C(row["shipped"]["lum"], lb)
        vs[k] = v
    if vs: row["vs"] = vs
    rows.append(row)
# lane checks like check_drive
lane = Image.open(G + "/" + REL + "/assets/ui/driving/road_L8_market_lane@1x.png").convert("RGB"); W, H = lane.size
mid = [lane.getpixel((x, y)) for x in range(W // 4, 3 * W // 4) for y in range(H) if not abs(x - W // 2) < 4]
edge = [lane.getpixel((x, y)) for x in list(range(0, W // 10)) + list(range(W - W // 10, W)) for y in range(H)]
cm = [sum(p[i] for p in mid) / len(mid) / 255 for i in range(3)]; ce = [sum(p[i] for p in edge) / len(edge) / 255 for i in range(3)]
arr = np.array(lane).astype(int)
lane_info = dict(centre_hex="#%02X%02X%02X" % tuple(int(v * 255) for v in cm), edge_hex="#%02X%02X%02X" % tuple(int(v * 255) for v in ce),
                 C_lane_vs_edge=C(lum(cm), lum(ce)), wrap_vs_internal_joint_max_delta=int(max(np.abs(arr[127, :16] - arr[31, :16]).max(), np.abs(arr[0, :16] - arr[32, :16]).max(), np.abs(arr[127, 112:] - arr[31, 112:]).max(), np.abs(arr[0, 112:] - arr[32, 112:]).max())), 
                 centre_band_max_dev=int(np.abs(arr[:, 60:68] - arr[:, 30:38].mean((0, 1))).max()))
shade = np.array(Image.open(G + "/" + REL + "/assets/ui/driving/hill_crest_shade@1x.png").convert("RGBA")).astype(int)
hill = dict(alpha_max=int(shade[..., 3].max()), alpha_min=int(shade[..., 3].min()), period4_rows_identical=bool(all((shade[y] == shade[(y + 4) % 128]).all() for y in range(128))),
            edge_alpha_left=int(shade[:, 0, 3].max()), edge_alpha_right=int(shade[:, -1, 3].max()))
# ---- real checker on /tmp copies
TMP = "/tmp/pr21_sprite_check"; shutil.rmtree(TMP, ignore_errors=True); os.makedirs(TMP + "/baseline"); os.makedirs(TMP + "/new")
PH = {"meteor": "assets/ui/vfx/vfx_meteor_streak@1x.png", "wind_streak": "assets/ui/vfx/vfx_wind_streak_lane@1x.png",
      "sandwich": "assets/ui/driving/sandwich@1x.png", "hill_shading": "assets/ui/driving/hill_crest_shade@1x.png",
      "hospital": "assets/ui/driving/hospital_front@1x.png", "happy_fish_icon": "assets/ui/icons/gerald_happy_fish@1x.png",
      "flagger": "assets/ui/driving/flagger_sheet@1x.png", "steel_plate": "assets/ui/driving/steel_plate@1x.png",
      "jackhammer": "assets/ui/driving/jackhammer_worker_sheet@1x.png"}
redirected = {}
def redirect(o, fname):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == "art_sprites_1x" and isinstance(v, dict):
                for sk, sv in list(v.items()):
                    if not isinstance(sv, str): continue
                    if sv.startswith("PLACEHOLDER") and sk in PH:
                        v[sk] = REL + "/" + PH[sk]; redirected.setdefault(fname, []).append(sk + " (placeholder)")
                    else:
                        p = sv.split()[0]
                        if os.path.exists(G + "/" + REL + "/" + p):
                            v[sk] = REL + "/" + p; redirected.setdefault(fname, []).append(sk)
            else: redirect(v, fname)
    elif isinstance(o, list):
        for v in o: redirect(v, fname)
files = ["level_layouts/L08_market.json", "level_layouts/L13_midnight.json", "level_layouts/L15_coast.json", "drive_routes/l13_midnightneon.json",
         "drive_routes/l15_windycoast.json", "drive_routes/l7_hospitalhill.json", "drive_routes/l9_construction.json",
         "drive_routes/l3_drizzle.json", "drive_routes/l3_goldenhour.json", "drive_routes/l5_duckpond.json"]
checker = {}
for f in files:
    d = json.load(open(G + "/" + f)); fn = os.path.basename(f)
    json.dump(d, open(TMP + "/baseline/" + fn, "w")); d2 = copy.deepcopy(d); redirect(d2, fn); json.dump(d2, open(TMP + "/new/" + fn, "w"))
    res = {}
    for tag in ("baseline", "new"):
        chk.main([TMP + "/" + tag + "/" + fn])
        rep = json.load(open(TMP + "/" + tag + "/" + fn.replace(".json", "_check.json")))
        res[tag] = dict(hard_fail=rep.get("hard_fail"), warn=rep.get("warn"), placeholders=len(rep.get("placeholders", [])),
                        hazards=[dict(sprite=h.get("sprite"), px=h.get("px_1x"), lum=h.get("lum_asbuilt"), vs=h.get("vs"), C_vs_lane=h.get("C_vs_lane_asbuilt"), passed=h.get("pass")) for h in rep.get("hazards", [])],
                        lane=rep.get("lane"))
    res["redirected_keys"] = redirected.get(fn, [])
    checker[fn] = res
out = dict(backdrop_lum={k: round(v, 3) for k, v in bk.items()}, night=NIGHT, sprites=rows, lane=lane_info, hill_crest_shade=hill, checker=checker)
json.dump(out, open(ROOT + "/_build/verify.json", "w"), indent=1, default=str)
for r in rows: print(r["entry"], r["name"], r["size_1x"], r["lum"], r.get("vs"), "2x" if r["x2_nearest_exact"] else "2x-BAD", "alpha=" + str(r.get("alpha_identical_to_shipped")), "ol=%d" % r["outline_6B4A3A_px"])
print("lane", lane_info); print("hill", hill); print("bk", out["backdrop_lum"])
