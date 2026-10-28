"""Writes ../README.md and ../VALIDATION.md from outputs.json + verify.json."""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
O = json.load(open(ROOT + "/_build/outputs.json")); V = json.load(open(ROOT + "/_build/verify.json"))
SV = {r["file"].split("sprites_L07_L15/")[1]: r for r in V["sprites"]}
md = ["# L07-L15 sprite requests (ART_REQUESTS.md #1-#17)", "", "Created by Andrew's Helpers (Grok Bots)", "",
      "Procedural pixel art (Pillow + numpy), no AI generation, no downloads. Add-only: nothing in `/workspace/game/assets` was touched; "
      "files here mirror the asset paths, so `pr21-new/sprites_L07_L15/assets/ui/...` drops onto `assets/ui/...`.", "",
      "Each sprite ships as `name@1x.png` (base, 32 px/m) and `name.png` (exact 2x nearest-neighbour), the same convention as "
      "`assets/src/build_pass9_sprites.py`. Light comes from the upper left: every surface has a light-side highlight and a cooler "
      "shadow-side tone. There are no dark outlines; the old `#6B4A3A` outline pixels became the shaded edge of their surface.", "",
      "Regenerate: `python3 _build/make_sprites.py && python3 _build/make_contact.py && python3 _build/verify.py && python3 _build/make_docs.py`", "",
      "| # | file (@1x; `.png` = 2x) | @1x size | hexes | frames | notes |", "|---|---|---|---|---|---|"]
for o in O:
    md.append("| %s | `%s` | %dx%d | %s | %s | %s |" % (o["entry"], o["file"], o["size_1x"][0], o["size_1x"][1], ", ".join(o["hexes"]), o["frames"], o["note"]))
md += ["", "New sheet metadata (same format as `assets/ui/vfx/sheets.json`, frame size at 2x): `assets/ui/sheets_L07_L15.json`.", "",
       "Contact sheet: `contact_sheet.png` (all @1x at 3x nearest; top on mid-grey, bottom on night-blue). Numbers: `VALIDATION.md`."]
open(ROOT + "/README.md", "w").write("\n".join(md) + "\n")
v = ["# VALIDATION: L07-L15 sprites", "", "Created by Andrew's Helpers (Grok Bots). Produced by `_build/verify.py`; raw data in `_build/verify.json`.", "",
     "Luminance = sRGB relative luminance of the mean RGB of pixels with alpha > 128 (the checker's `sprite_stats` method). "
     "C = (L_light + 0.05) / (L_dark + 0.05). Backdrops: " + ", ".join("%s %.3f" % kv for kv in V["backdrop_lum"].items()) +
     ". Night beam edge (L13: tint 0.45, edge_glow 1.3): C(min(1, L*e*g), Lb*e), e = 1 - tint/2, computed from the as-built luminance.", "",
     "| # | sprite | @1x | @2x exact nearest | alpha = shipped | old outline px | avg hex | lum | C now (shipped) | C beam edge |", "|---|---|---|---|---|---|---|---|---|---|"]
for r in V["sprites"]:
    cs = "; ".join("%s %.2f%s" % (k.replace("road_", "").replace("_tile", ""), x["C"], " (%.2f)" % x["C_shipped"] if "C_shipped" in x else "") for k, x in (r.get("vs") or {}).items()) or "-"
    be = "; ".join("%.2f" % x["C_beam_edge"] for x in (r.get("vs") or {}).values() if "C_beam_edge" in x) or "-"
    al = {True: "yes", False: "no (redrawn)", None: "new"}[r.get("alpha_identical_to_shipped")]
    v.append("| %s | %s | %dx%d | %s | %s | %d | %s | %.3f | %s | %s |" % (r["entry"], r["name"], r["size_1x"][0], r["size_1x"][1], "yes" if r["x2_nearest_exact"] else "NO", al, r["outline_6B4A3A_px"], r["avg_hex"], r["lum"], cs, be))
L = V["lane"]; Hc = V["hill_crest_shade"]
v += ["", "`#6B4A3A` px count: the flagger's 60 are the wooden sign pole (darkwood from `flagger_sign.glb`), not an outline.", "",
      "## Lane (#8), measured the way `check_drive` does", "",
      "- Centre sample (x 32..95, skipping |x-64|<4) `%s`, edge sample (outer 12 columns) `%s`, **lane vs edge C = %.2f** (shipped tile 1.45, target 4.70)." % (L["centre_hex"], L["edge_hex"], L["C_lane_vs_edge"]),
      "- No centre line: centre band max deviation from the lane fill = %d levels (grain only)." % L["centre_band_max_dev"],
      "- Tiles vertically: all vertical detail repeats every 32 px; wrap seam (row 127 -> 0) vs an internal kerb joint (31 -> 32), max delta %d levels." % L["wrap_vs_internal_joint_max_delta"], "",
      "## Hill crest shade (#12)", "", "- Alpha %d..%d, left/right edge alpha %d/%d (fades to 0, so tile edges in X are invisible); rows repeat with period 4 (Bayer) -> tiles vertically: %s." % (Hc["alpha_min"], Hc["alpha_max"], Hc["edge_alpha_left"], Hc["edge_alpha_right"], Hc["period4_rows_identical"]), "",
      "## Real checker on temp copies", "", "`level_layouts/tools/check_level_layout.py` was imported and run unmodified on copies in `/tmp/pr21_sprite_check/{baseline,new}/`. "
      "The `new` copies have their `art_sprites_1x` paths pointed at `pr21-new/sprites_L07_L15/...` (placeholders filled where a new file exists). No repo JSON was changed.", "",
      "| file | redirected keys | baseline hard_fail / warn | new hard_fail / warn |", "|---|---|---|---|"]
for f, r in V["checker"].items():
    b, n = r["baseline"], r["new"]
    fmt = lambda x: "%s / %s" % (", ".join(x["hard_fail"]) or "none", "; ".join(x["warn"]) or "none")
    v.append("| %s | %s | %s | %s |" % (f, ", ".join(r["redirected_keys"]) or "-", fmt(b), fmt(n)))
v += ["", "Notes:", "- L08: the `lane sprite as-built still has the centre dash` warning is a fixed string in `check_drive` (always appended), so it stays until the checker is updated; the measured lane-vs-edge C now passes (4.71, `pass_asbuilt: true`). The checker was not modified.",
      "- L3/L5 `rewards_not_add_only` hard fails are pre-existing and identical in the baseline copy; they are unrelated to sprites.",
      "- `fix_hex`-based C_fixed / C_beam_edge in the checker are unchanged by design; the as-built columns above are what improved."]
open(ROOT + "/VALIDATION.md", "w").write("\n".join(v) + "\n")
