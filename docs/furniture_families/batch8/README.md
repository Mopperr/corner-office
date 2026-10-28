# Corner Office catalogue families - batch8 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch8_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-8 families: wellies, wheelbarrow_v, watering_v, office_bin, office_shelf, desk_v, office_clock, safe, notice_board, umbrella_stand. The other 10 (loo_roll, medicine_cabinet, bath_caddy, string_lights, console, chess_set, trophy, old_lamp, model_ship, bucket) are Design Specialist's, documented in `README_design.md`, `QA_batch8.md` and `batch8_contact_design.png`. Three art families are starred: wheelbarrow_v (existing `hh_wheelbarrow`), watering_v (existing `hh_watering_can`) and desk_v (existing `desk`). Each is built as a new `hh_cat_` file and the existing GLBs are untouched.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch8_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug`, `mat`, `seat` or any other hook name (checked by validate.py), so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| wellies | 0.300 x 0.300 x 0.360 | 0.30 x 0.30 x 0.36 | 105 | black 1E1B19 | boot_foot, boot_toe, boot_shaft | PASS | Pair of wellington boots, toes to -Y: `way` (black) shafts and feet, dark soles and openings, cream top rims, red side badges, pull tabs. |
| wheelbarrow_v | 0.650 x 1.200 x 0.600 | 0.65 x 1.20 x 0.60 | 73 | black 1E1B19 | tub | PASS | STARRED (existing `hh_wheelbarrow`); new `hh_cat_wheelbarrow_v.glb`. Builder's wheelbarrow, wheel to -Y: `way` (black) `tub` with grey inside, dark tyre on grey rim, steel frame, hub, legs and brace, red grips. |
| watering_v | 0.400 x 0.200 x 0.300 | 0.40 x 0.20 x 0.30 | 69 | blue 4A6FA5 | can_body, filler_neck, can_handle, spout | PASS | STARRED (existing `hh_watering_can`); new `hh_cat_watering_v.glb`. Classic watering can, spout to -X: `way` (blue) round body, spout and loop handle, steel rose, dark filler cap, cream front label with a blue drop. |
| office_bin | 0.280 x 0.280 x 0.320 | 0.28 x 0.28 x 0.32 | 49 | black 1E1B19 | bin_body | PASS | Office waste-paper bin: tapered hollow `way` (black) bin, dark rim and foot band, crumpled white and cream paper. Round piece, front check n/a. |
| office_shelf | 0.800 x 0.350 x 1.800 | 0.80 x 0.35 x 1.80 | 304 | grey 8E8276 | side_panel, shelf_cap, plinth, shelf, shelf_lip, plant_pot | PASS | Tall office bookcase: `way` (grey) carcass with `shelf_cap` (not `top`) and front shelf lips, card back, rows of blue and red lever-arch binders with card labels, books, a paper stack and a sage plant in a grey pot. |
| desk_v | 1.400 x 0.700 x 0.750 | 1.40 x 0.70 x 0.75 | 88 | oak C68B59 | desk_surface | PASS | STARRED (existing `desk`); new `hh_cat_desk_v.glb`. Office desk: `way` (oak) `desk_surface` (not `top`), grey three-drawer pedestal with steel handles, steel legs and rail on the left, grey modesty panel, dark cable grommet. |
| office_clock | 0.300 x 0.040 x 0.300 | 0.30 x 0.04 x 0.30 | 74 | black 1E1B19 | clock_case, rim | PASS | Office wall clock: `way` (black) case and front rim, white face with dark ticks and hands, red second hand and boss; back plate toward +Y. |
| safe | 0.450 x 0.450 x 0.550 | 0.45 x 0.45 x 0.55 | 112 | black 1E1B19 | safe_body, door | PASS | Office safe: `way` (black) body and door, steel combination dial with ticks and three-spoke handle, brass maker's plate, dark hinges and feet. |
| notice_board | 0.900 x 0.040 x 0.600 | 0.90 x 0.04 x 0.60 | 86 | oak C68B59 | frame | PASS | Office notice board: `way` (oak) frame, kraft cork panel with cream, white, mustard and blue notes, red pins; kraft back panel toward +Y. |
| umbrella_stand | 0.220 x 0.220 x 0.850 | 0.22 x 0.22 x 0.85 | 66 | black 1E1B19 | stand | PASS | Umbrella stand: `way` (black) cylinder with brass bands holding a red and a blue furled umbrella with walnut crook handles. Round piece, front check n/a. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is watering_v -1.9% in depth; all others 1.3% or less, see `_build/art/fit_log.json`. None of the 10 were skipped. No colour mapping was needed: all first colour-ways are palette names.
