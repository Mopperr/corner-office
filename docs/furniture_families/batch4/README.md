# Corner Office catalogue families - batch4 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `batch4_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-4 families: board_games, child_bike, barbecue, deck_chair, teapot, chopping_board, biscuit_tin, book_stack, broken_chair, hat_stand_loft. The other 10 (poster, towel_rail, pram, skis, mannequin, planter_box, bowl_set, casserole, cookbooks, bath_plant) are Design Specialist's, documented in `README_design.md`, `QA_batch4.md` and `batch4_contact_design.png`. None of my 10 is starred (no existing `hh_` model), so all are new `hh_cat_` files.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch4_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug` or `mat`, so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| board_games | 0.400 x 0.280 x 0.200 | 0.40 x 0.28 x 0.20 | 109 | blue 4A6FA5 | game_lid, counter | PASS | Stack of four board-game boxes: bottom lid is `way`, the others mustard, sage and red, each on a cream base, with cream lid labels at the front; a die with pips, counters and a pawn on top. Parts are `game_lid` / `game_base` (deliberately not `box`/`tray`, so no texture hook fires). |
| child_bike | 0.900 x 0.300 x 0.600 | 0.90 x 0.30 x 0.60 | 128 | blue 4A6FA5 | frame, chain_guard | PASS | Child's bike in side view along X (front wheel at +X, so the -Y front shows the side): `way` frame tubes and chain guard, dark tyres, grips, saddle and pedals, steel rims, spokes, fork and bars, mustard bell, red rear reflector. Saddle part is `saddle` (leather texture hook, intentional, it is a saddle). Front check n/a (side-on piece). |
| barbecue | 0.600 x 0.600 x 0.900 | 0.60 x 0.60 x 0.90 | 81 | black 1E1B19 | bowl, lid | PASS | Kettle barbecue: `way` bowl and domed lid (black), steel lid rim, vent, three legs, ash pan; two dark wheels; oak lid handle. Round piece, front check n/a. |
| deck_chair | 0.600 x 0.800 x 0.850 | 0.60 x 0.80 x 0.85 | 53 | blue 4A6FA5 | sling | PASS | Folding deck chair facing -Y: oak back rails, front legs, rear struts and cross bars, brass pivot bolts; sagging canvas sling in seven stripes alternating `way` and cream (part `sling`, not `seat`/`cushion`). |
| teapot | 0.240 x 0.160 x 0.180 | 0.24 x 0.16 x 0.18 | 61 | blue 4A6FA5 | body, lid, spout, handle | PASS | Round teapot: `way` lathed body, lid, spout (to -X) and handle (to +X); cream knob and belly band; two small mustard flowers on the -Y face. |
| chopping_board | 0.360 x 0.260 x 0.030 | 0.36 x 0.26 x 0.03 | 95 | black 1E1B19 | board, board_handle | PASS | Chopping board with handle hole (boolean cut) at +X, on four dark feet; terracotta carrot coins, green cucumber slices, a steel/walnut knife. CSV first colour-way is black, so the plain build is a black board (it tints in game). Part is `board` (not `top`). Front check n/a (flat piece). |
| biscuit_tin | 0.220 x 0.220 x 0.120 | 0.22 x 0.22 x 0.12 | 130 | blue 4A6FA5 | tin_body, lid | PASS | Round biscuit tin: `way` drum (`tin_body`) and lid, cream bands and dot ring, mustard/red/cream rosette on the lid. Round piece, front check n/a. |
| book_stack | 0.200 x 0.150 x 0.200 | 0.20 x 0.15 x 0.20 | 110 | blue 4A6FA5 | cover, spine | PASS | Five books lying flat with spines toward -Y: covers and spines `way` (bottom book), red, green, mustard and night; cream page blocks; brass spine bands and titles. |
| broken_chair | 0.450 x 0.450 x 0.900 | 0.45 x 0.45 x 0.90 | 74 | oak C68B59 | seat, back_post, leg, broken_leg, stretcher, back_rail, back_slat | PASS | Old kitchen chair, `way` (oak) throughout: one front leg snapped to a stub with pale pine splinters, the broken piece lying on the floor, one back slat hanging askew from a nail, steel nails, a dark crack. Back toward +Y. |
| hat_stand_loft | 0.400 x 0.400 x 1.600 | 0.40 x 0.40 x 1.60 | 144 | oak C68B59 | pole, pole_collar, foot, finial_base | PASS | Old hat stand: `way` (oak) pole, collar, four curved feet and finial, dark foot pads, four brass hooks, a grey felt hat with dark band on top, a red scarf with cream stripes on a hook. Round piece, front check n/a. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is barbecue +2.6% in width (all others 2.4% or less, see `_build/art/fit_log.json`). Nothing is over 3%. None of the 10 were skipped. First colour-ways are all palette colours (blue, black, oak), so no mapping was needed.
