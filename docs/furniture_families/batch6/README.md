# Corner Office catalogue families - batch6 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `batch6_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-6 families: laundry_bag, record_player, magazine_pile, locker, parasol, office_chair, spice_jars, coffee_grinder, scales, soap_dispenser. The other 10 (whiteboard, cork_board, fruit_bowl, blender, toothbrush_set, soap_dish, hair_dryer, jewellery_box, hangers, dollhouse) are Design Specialist's, documented in `README_design.md`, `QA_batch6.md` and `batch6_contact_design.png`. No batch-6 art family is starred; all 10 are new.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch6_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug` or `mat`, so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| laundry_bag | 0.400 x 0.400 x 0.500 | 0.40 x 0.40 x 0.50 | 56 | blue 4A6FA5 | laundry_bag | PASS | Stuffed drawstring laundry bag (`laundry_bag`): `way` sack with a cream drawstring `tie` (deliberately not `strap`, so no leather texture), clothes poking out of the top, cream front label. |
| record_player | 0.420 x 0.340 x 0.140 | 0.42 x 0.34 x 0.14 | 114 | oak C68B59 | plinth | PASS | Turntable facing -Y: `way` (oak) plinth, dark deck, dark platter with record and red label, steel tone-arm, cream speed knobs, dark feet. |
| magazine_pile | 0.300 x 0.240 x 0.100 | 0.30 x 0.24 x 0.10 | 48 | blue 4A6FA5 | cover, spine | PASS | Untidy pile of eight magazines, cream page blocks between colour covers; top cover `way` with masthead, cover photo and cover lines. Front check n/a (pile is roughly symmetric). |
| locker | 0.400 x 0.500 x 1.800 | 0.40 x 0.50 x 1.80 | 116 | blue 4A6FA5 | carcass, door | PASS | Tall steel locker: `way` carcass and door, dark louvres, steel handle, lock and hinges, cream number plate, dark feet. |
| parasol | 0.400 x 0.400 x 2.000 | 0.40 x 0.40 x 2.00 | 89 | blue 4A6FA5 | canopy | PASS | Furled garden parasol: `way` canopy wrapped round the oak pole, cream `tie`, steel hub, finial and crank, dark weighted `parasol_base` (not `base`). Round piece, front check n/a. |
| office_chair | 0.600 x 0.600 x 1.000 | 0.60 x 0.60 x 1.00 | 114 | black 1E1B19 | chair_seat, backrest | PASS | Swivel office chair facing -Y: `way` (black) `chair_seat` and backrest, dark five-star base, casters, arms and back spine, steel gas lift. |
| spice_jars | 0.240 x 0.070 x 0.100 | 0.24 x 0.07 x 0.10 | 130 | blue 4A6FA5 | lid | PASS | Oak spice rack with four glass jars of spice (terracotta, mustard, red, oak), `way` screw lids, cream labels facing -Y. |
| coffee_grinder | 0.120 x 0.120 x 0.220 | 0.12 x 0.12 x 0.22 | 53 | oak C68B59 | grinder_body, body_cap | PASS | Box coffee grinder: `way` (oak) `grinder_body` with front drawer and brass knob, brass bowl, steel crank with walnut handle. |
| scales | 0.200 x 0.200 x 0.160 | 0.20 x 0.20 x 0.16 | 62 | blue 4A6FA5 | scale_body, scale_foot | PASS | Kitchen scales: `way` `scale_body` with cream front dial, red needle, white weighing bowl, dark feet. |
| soap_dispenser | 0.140 x 0.080 x 0.160 | 0.14 x 0.08 x 0.16 | 38 | blue 4A6FA5 | bottle | PASS | Pump soap dispenser: `way` bottle, cream label with sage motif, white pump head and nozzle. Front check n/a (round body). |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is record_player -2.8% in height; all others 2.3% or less, see `_build/art/fit_log.json`. None of the 10 were skipped. No colour mapping was needed: all first colour-ways are palette colours (blue, oak, black).
