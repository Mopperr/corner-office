# VALIDATION: L07-L15 sprites

Created by Andrew's Helpers (Grok Bots). Produced by `_build/verify.py`; raw data in `_build/verify.json`.

Luminance = sRGB relative luminance of the mean RGB of pixels with alpha > 128 (the checker's `sprite_stats` method). C = (L_light + 0.05) / (L_dark + 0.05). Backdrops: road_L13_night 0.071, road_L15_cliff 0.577, sand_tile 0.713. Night beam edge (L13: tint 0.45, edge_glow 1.3): C(min(1, L*e*g), Lb*e), e = 1 - tint/2, computed from the as-built luminance.

| # | sprite | @1x | @2x exact nearest | alpha = shipped | old outline px | avg hex | lum | C now (shipped) | C beam edge |
|---|---|---|---|---|---|---|---|---|---|
| 1 | parked_car | 96x48 | yes | yes | 0 | #9D9E9C | 0.343 | L13_night 3.25 (1.23) | 3.77 |
| 1 | parked_car_cream | 96x48 | yes | new | 0 | #9D9E9C | 0.343 | - | - |
| 2 | night_cat | 24x16 | yes | yes | 0 | #CF7860 | 0.277 | L13_night 2.70 (1.19) | 3.13 |
| 3 | neon_sign_open | 64x32 | yes | yes | 0 | #855E60 | 0.140 | L13_night 1.57 (1.19) | 1.82 |
| 3 | neon_sign_open_low | 64x32 | yes | new | 0 | #90898B | 0.258 | L13_night 2.55 | 2.95 |
| 4 | windsock_sprite | 32x64 | yes | yes | 0 | #93807F | 0.233 | L15_cliff 2.21 (1.39); sand 2.69 (1.70) | - |
| 5 | gull | 32x20 | yes | no (redrawn) | 0 | #929294 | 0.290 | L15_cliff 1.84 (1.87); sand 2.24 (2.28) | - |
| 6 | lighthouse_sprite | 64x96 | yes | yes | 0 | #B87C63 | 0.256 | L15_cliff 2.05 (1.10); sand 2.49 (1.33) | - |
| 7 | dune | 96x48 | yes | yes | 0 | #A27A47 | 0.222 | L15_cliff 2.30 (1.12); sand 2.80 (1.08) | - |
| 8 | road_L8_market_lane | 128x128 | yes | yes | 0 | #C7B8A5 | 0.494 | - | - |
| 9 | vfx_meteor_streak | 768x64 | yes | new | 0 | #FADBAD | 0.746 | - | - |
| 10 | vfx_wind_streak_lane | 768x64 | yes | new | 0 | #FFFFFF | 1.000 | - | - |
| 11 | sandwich | 20x16 | yes | new | 0 | #BFA880 | 0.408 | L15_cliff 1.37; sand 1.67 | - |
| 12 | hill_crest_shade | 128x128 | yes | new | 0 | #8E8687 | 0.248 | - | - |
| 13 | hospital_front | 160x96 | yes | new | 0 | #CBCBC1 | 0.594 | - | - |
| 14 | gerald_happy_fish | 64x64 | yes | new | 0 | #C2BCB1 | 0.507 | - | - |
| 14 | gerald_worried_fish | 64x64 | yes | new | 0 | #BFB9AE | 0.492 | - | - |
| 15 | flagger_sheet | 64x48 | yes | new | 60 | #B49570 | 0.326 | - | - |
| 16 | steel_plate | 77x58 | yes | new | 0 | #A4A7AD | 0.389 | - | - |
| 17 | jackhammer_worker_sheet | 160x48 | yes | new | 0 | #B09275 | 0.312 | - | - |

`#6B4A3A` px count: the flagger's 60 are the wooden sign pole (darkwood from `flagger_sign.glb`), not an outline.

## Lane (#8), measured the way `check_drive` does

- Centre sample (x 32..95, skipping |x-64|<4) `#E5D7C2`, edge sample (outer 12 columns) `#6A594A`, **lane vs edge C = 4.71** (shipped tile 1.45, target 4.70).
- No centre line: centre band max deviation from the lane fill = 1 levels (grain only).
- Tiles vertically: all vertical detail repeats every 32 px; wrap seam (row 127 -> 0) vs an internal kerb joint (31 -> 32), max delta 2 levels.

## Hill crest shade (#12)

- Alpha 0..90, left/right edge alpha 0/0 (fades to 0, so tile edges in X are invisible); rows repeat with period 4 (Bayer) -> tiles vertically: True.

## Real checker on temp copies

`level_layouts/tools/check_level_layout.py` was imported and run unmodified on copies in `/tmp/pr21_sprite_check/{baseline,new}/`. The `new` copies have their `art_sprites_1x` paths pointed at `pr21-new/sprites_L07_L15/...` (placeholders filled where a new file exists). No repo JSON was changed.

| file | redirected keys | baseline hard_fail / warn | new hard_fail / warn |
|---|---|---|---|
| L08_market.json | lane | none / lane sprite as-built still has the centre dash; Art redraw to plain cream + dark curb pending | none / lane sprite as-built still has the centre dash; Art redraw to plain cream + dark curb pending |
| L13_midnight.json | cat, neon, parked_car, meteor (placeholder) | none / Art recolour needed: parked_car -> #E8DCC4 (as-built fails); Art recolour needed: cat -> #E07A5F (as-built fails) | none / none |
| L15_coast.json | gull, windsock, lighthouse, dune, wind_streak (placeholder), sandwich (placeholder) | none / Art recolour needed: windsock -> #C0392B (as-built fails); route_contrast:gull | none / none |
| l13_midnightneon.json | cat, neon, parked_car, meteor (placeholder) | none / Art recolour needed: parked_car -> #E8DCC4 (as-built fails); Art recolour needed: cat -> #E07A5F (as-built fails) | none / none |
| l15_windycoast.json | gull, windsock, lighthouse, dune, wind_streak (placeholder), sandwich (placeholder) | none / Art recolour needed: windsock -> #C0392B (as-built fails); route_contrast:gull | none / none |
| l7_hospitalhill.json | parked_car, hill_shading (placeholder), hospital (placeholder), happy_fish_icon (placeholder) | none / none | none / none |
| l9_construction.json | flagger (placeholder), steel_plate (placeholder), jackhammer (placeholder) | none / none | none / none |
| l3_drizzle.json | parked_car | rewards_not_add_only:smooth_ride,shortcut_bonus / none | rewards_not_add_only:smooth_ride,shortcut_bonus / none |
| l3_goldenhour.json | parked_car | rewards_not_add_only:smooth_ride,shortcut_bonus / none | rewards_not_add_only:smooth_ride,shortcut_bonus / none |
| l5_duckpond.json | - | rewards_not_add_only:duck_friend,smooth_ride / none | rewards_not_add_only:duck_friend,smooth_ride / none |

Notes:
- L08: the `lane sprite as-built still has the centre dash` warning is a fixed string in `check_drive` (always appended), so it stays until the checker is updated; the measured lane-vs-edge C now passes (4.71, `pass_asbuilt: true`). The checker was not modified.
- L3/L5 `rewards_not_add_only` hard fails are pre-existing and identical in the baseline copy; they are unrelated to sprites.
- `fix_hex`-based C_fixed / C_beam_edge in the checker are unchanged by design; the as-built columns above are what improved.
