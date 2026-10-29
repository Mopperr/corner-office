# Corner Office catalogue families - batch9 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch9_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-9 families: hose_v, seed_trays, bird_feeder, lantern, cool_box, kayak, water_cooler, shredder, heater, office_trolley. The other 10 (picture_stack, gramophone, dartboard, bird_cage, vinyl_crate, sewing_machine, tool_box_v, paint_cans, flower_pot_v, spades) are Design Specialist's, documented in `README_design.md`, `QA_batch9.md` and `batch9_contact_design.png`. No batch-9 art family is starred; all 10 are new.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch9_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug`, `mat`, `seat` or any other hook name (checked by validate.py), so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| hose_v | 0.400 x 0.400 x 0.140 | 0.40 x 0.40 x 0.14 | 49 | black 1E1B19 | hose_coil, hose_end | PASS | Coiled garden hose: three-turn `way` (black) coil, mustard spray gun with dark grip and brass nozzle resting on top toward -Y, brass connectors. |
| seed_trays | 0.400 x 0.240 x 0.100 | 0.40 x 0.24 x 0.10 | 413 | black 1E1B19 | seed_flat, cell_wall | PASS | Seed tray of 6x4 cells: `way` (black) `seed_flat` (not `tray`), walnut `compost` plugs (not `soil`), green and sage seedlings, white plant labels at the front. |
| bird_feeder | 0.200 x 0.200 x 0.500 | 0.20 x 0.20 x 0.50 | 74 | green 5E7B52 | seed_dish, dish_rim, feeder_foot, feed_port, roof, roof_collar | PASS | Tube bird feeder: `way` (green) roof, collar, feed ports and seed dish, kraft seed column with steel bands, glass upper tube, steel perches and hanging loop. Round piece, front check n/a. |
| lantern | 0.160 x 0.160 x 0.300 | 0.16 x 0.16 x 0.30 | 62 | black 1E1B19 | fount, lantern_cap, chimney | PASS | Hurricane lantern: `way` (black) fount and cap, glass globe with mustard flame, steel guard and bail handle, brass wick knob at the front. |
| cool_box | 0.500 x 0.320 x 0.360 | 0.50 x 0.32 x 0.36 | 55 | blue 4A6FA5 | cooler_body | PASS | Picnic cool box: `way` (blue) body, white `lid` and front latch, grey swing handle, white logo, dark drain plug. |
| kayak | 2.400 x 0.600 x 0.350 | 2.40 x 0.60 x 0.35 | 53 | blue 4A6FA5 | hull | PASS | Sit-on-top kayak lying along X: `way` (blue) hull, dark cockpit, coaming and deck bungees, mustard seat back and pad (`kayak_seat_back` / `kayak_pad`, not `seat`), grey end toggles, white hull stripe. Front check n/a (long symmetric hull). |
| water_cooler | 0.350 x 0.350 x 1.200 | 0.35 x 0.35 x 1.20 | 55 | black 1E1B19 | cooler_cabinet | PASS | Office water cooler: `way` (black) cabinet, glass bottle on top, red and blue taps in a dark recess at the front, steel drip grate. |
| shredder | 0.360 x 0.260 x 0.500 | 0.36 x 0.26 x 0.50 | 37 | black 1E1B19 | shredder_bin | PASS | Office paper shredder: `way` (black) bin with glass front window showing white shreds, grey cutting head, white sheet in the slot, green and red buttons. |
| heater | 0.500 x 0.200 x 0.600 | 0.50 x 0.20 x 0.60 | 105 | black 1E1B19 | fin, fin_rail, control_box | PASS | Oil-filled radiator: nine `way` (black) fins and rails, side control box with white thermostat knob at the front and red power light, steel feet with dark castors. |
| office_trolley | 0.600 x 0.400 x 0.800 | 0.60 x 0.40 x 0.80 | 138 | black 1E1B19 | post, deck, front_lip, back_lip, side_lip, handle_post, push_handle | PASS | Office post trolley: `way` (black) posts, two lipped decks and push handle with grey grip, dark castors, white paper reams with red and blue wraps, kraft parcels. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is lantern / cool_box -1.2%; all others 0.9% or less, see `_build/art/fit_log.json`. None of the 10 were skipped. No colour mapping was needed: all first colour-ways are palette names.
