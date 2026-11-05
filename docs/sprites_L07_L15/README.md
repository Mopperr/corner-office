# L07-L15 sprite requests (ART_REQUESTS.md #1-#17)

Created by Andrew's Helpers (Grok Bots)

Procedural pixel art (Pillow + numpy), no AI generation, no downloads. Add-only: nothing in `/workspace/game/assets` was touched; files here mirror the asset paths, so `pr21-new/sprites_L07_L15/assets/ui/...` drops onto `assets/ui/...`.

Each sprite ships as `name@1x.png` (base, 32 px/m) and `name.png` (exact 2x nearest-neighbour), the same convention as `assets/src/build_pass9_sprites.py`. Light comes from the upper left: every surface has a light-side highlight and a cooler shadow-side tone. There are no dark outlines; the old `#6B4A3A` outline pixels became the shaded edge of their surface.

Regenerate: `python3 _build/make_sprites.py && python3 _build/make_contact.py && python3 _build/verify.py && python3 _build/make_docs.py`

| # | file (@1x; `.png` = 2x) | @1x size | hexes | frames | notes |
|---|---|---|---|---|---|
| 1 | `assets/ui/driving/parked_car@1x.png` | 96x48 | #E8DCC4 body, #7E95A3 glass, #3E3A4F tyres, #FFF1D6/#D9765F lamps | 1 | silhouette/alpha identical to shipped sprite; NOTE the shipped parked_car is shared by L3/L5/L7 day routes |
| 1 | `assets/ui/driving/parked_car_cream@1x.png` | 96x48 | identical pixels to parked_car | 1 | same pixels under an L13-only name, in case the day routes (L3/L5/L7) should keep the blue car |
| 2 | `assets/ui/driving/night_cat@1x.png` | 24x16 | #E07A5F body, #FFF1D6 eye-shine | 1 | same silhouette; eye-shine kept (2 px) |
| 3 | `assets/ui/driving/neon_sign_open@1x.png` | 64x32 | #E07A5F tubes, #3E3A4F board, #625C78 casing | 1 | OPEN lettering + border tube in L13 terracotta neon; painted 2 px bloom on the board |
| 3 | `assets/ui/driving/neon_sign_open_low@1x.png` | 64x32 | #FFF1D6 tubes, #3E3A4F board, #625C78 casing | 1 | low tier: cream tubes |
| 4 | `assets/ui/driving/windsock_sprite@1x.png` | 32x64 | #C0392B sock, #F4E9D8 cream stripes, #737F88 pole | 1 | pole darkened from #9FB3BF to weathered steel #737F88 so the whole sprite reads darker than road/sand (see VALIDATION) |
| 5 | `assets/ui/driving/gull@1x.png` | 32x20 | #E9E5DC/#FBF7EF white body, #646D78 grey mantle, #3E3A4F wing tips, #E6B655 beak | 1 | redrawn 32x20 (was 20x12); top-down flying gull, avg lum tuned to ~0.29 like the old sprite |
| 6 | `assets/ui/driving/lighthouse_sprite@1x.png` | 64x96 | #C9714F tower, #F4E9D8 cream bands, #A85A3E lantern, #BFDDEA/#FFF1D6 lamp | 1 | alpha identical; was cream tower + one terracotta band |
| 7 | `assets/ui/driving/dune@1x.png` | 96x48 | #A8783F body/shadow, #8FAF7E sage tufts (#6E8F62 roots, #A9C49A tips) | 1 | alpha identical; tufts drawn inside the silhouette |
| 8 | `assets/ui/driving/road_L8_market_lane@1x.png` | 128x128 | #E6D8C3 lane, #6B5A4A curb | 1 | lane x16-111 (same 3 m road as the shipped tile), curb x0-15 and x112-127 where the sage verge was; no centre line; tiles top-to-bottom (all vertical detail repeats every 32 px) |
| 9 | `assets/ui/vfx/vfx_meteor_streak@1x.png` | 768x64 | #FFF1D6 head, #F2B35E warm glow, #BFDDEA cool tail end | 6 frames of 128x64 @1x (256x128 @2x), left to right | one-shot (no loop), play ~12 fps; head moves upper-right to lower-left inside the frame and burns out in frame 6 |
| 10 | `assets/ui/vfx/vfx_wind_streak_lane@1x.png` | 768x64 | #FFFFFF streaks (alpha 0-217), #E8EEF2 soft underside | 6 frames of 128x64 @1x (256x128 @2x), left to right | seamless 6-frame loop (each streak wraps), 128 px wide so it spans the 96 px lane; flows left to right (flip_h for the other wind direction) |
| 11 | `assets/ui/driving/sandwich@1x.png` | 20x16 | #F4E3C1 bread, #C68B59 crust, #8FAF7E lettuce, #D9765F tomato, #E6B655 cheese | 1 | 20x16 @1x (0.6 x 0.5 m at 32 px/m, enlarged so the 16 px readability minimum holds while a gull carries it) |
| 12 | `assets/ui/driving/hill_crest_shade@1x.png` | 128x128 | #FFF1D6 lit band (alpha<=72), #3E3A4F shade band (alpha<=90) | 1 | 128x128 overlay, multiply/normal blend over the road; bands run across X (uphill lit on the left, crest at x=64, far side shaded on the right), constant in Y so it tiles vertically; flip_h for the other direction |
| 13 | `assets/ui/driving/hospital_front@1x.png` | 160x96 | #F4E9D8 walls, #A8C9B8 mint trim (L7), #7FA3B8/#8FB3C4 glass, #C0392B sign + #FFF1D6 cross, #4F7A5A lettering | 1 | 160x96 @1x, front elevation like shopfront/diner (128x96 / 128x64); 5 m wide at 32 px/m |
| 14 | `assets/ui/icons/gerald_happy_fish@1x.png` | 64x64 | #F28C28 Gerald (L7-5 review hex), #D9765F fins, #BFDDEA water, #E6B655 sparkles, #E8B4A8 cheek | 1 | 64x64 @1x / 128x128 like icon_*.png; the placeholder names gerald_happy_fish.png = the 128 px file |
| 14 | `assets/ui/icons/gerald_worried_fish@1x.png` | 64x64 | #F28C28 Gerald (L7-5 review hex), #D9765F fins, #BFDDEA water, #7FA3B8 sweat drop | 1 | 64x64 @1x / 128x128 like icon_*.png; the placeholder names gerald_worried_fish.png = the 128 px file |
| 15 | `assets/ui/driving/flagger_sheet@1x.png` | 64x48 | #D9765F STOP face + #FFF1D6 text, #E6B655 SLOW face + #3E3A4F text, #E6B655 vest/hat, #E8B4A8 skin, #7FA3B8 trousers, #6B4A3A pole | 2 frames of 32x48 @1x (64x96 @2x), left to right | frame 0 = STOP, frame 1 = SLOW; 32x48 like jogger; colours from npc_flagger.glb / flagger_sign.glb; sign text in a 3x5 pixel font on an 18x11 octagon held up on a pole |
| 16 | `assets/ui/driving/steel_plate@1x.png` | 77x58 | #A8ADB4 chrome-grey steel (L7 chrome palette), #8E8276 wear | 1 | exact 77x58 @1x = 2.4 x 1.8 m at 32 px/m, top-down; diamond tread, bevel light top-left |
| 17 | `assets/ui/driving/jackhammer_worker_sheet@1x.png` | 160x48 | #E6B655 vest/hat, #C0392B jackhammer, #A8ADB4 chisel, #D9B98A/#EADBB8 dust (semi-transparent) | 4 frames of 40x48 @1x (80x96 @2x), left to right | 4-frame loop at ~10 fps; worker bobs 1 px on frames 1/3, dust puff grows f0->f2 and settles f3; 40x48 frames (32 px worker + 8 px for the puff) |

New sheet metadata (same format as `assets/ui/vfx/sheets.json`, frame size at 2x): `assets/ui/sheets_L07_L15.json`.

Contact sheet: `contact_sheet.png` (all @1x at 3x nearest; top on mid-grey, bottom on night-blue). Numbers: `VALIDATION.md`.

## Packaging note for PR #21 (added when bundling, Oct 28 2026)

Created by Andrew's Helpers (Grok Bots)

- This branch is add-only. `assets/ui/driving/parked_car.png` and `parked_car@1x.png` already exist in PR #21,
  so the recoloured versions of those two files are **left out**. The same pixels ship as
  `parked_car_cream.png` / `parked_car_cream@1x.png` (an L13-only name). Whether L13 uses `parked_car_cream`
  (and the L3/L5/L7 day routes keep the shipped car) is **Andrew's decision**.
- `vfx_wind_streak_lane` is a new sprite name; Andrew to confirm the name.
- The L08 "centre dash" checker warning clears only once the checker is updated for the new lane tile
  (the new `road_L8_market_lane` has no centre line on purpose).
- Build scripts are in `tools/sprites_L07_L15/` (paths inside them point at the team's box layout).
