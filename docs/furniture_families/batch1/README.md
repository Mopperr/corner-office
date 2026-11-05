# Corner Office catalogue families - batch1 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.*`, `batch1_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-1 families: bin_kitchen, bath_mat, wine_rack, suitcase, toy_box, ottoman, bar_stool, shoe_rack, bookshelf_v, plant_pot_v. The other 10 (floor_lamp_v, kitchen_trolley, high_chair, laundry_hamper, bath_bin, side_table_v, dressing_stool, armchair_v, coat_stand, rocking_chair) are Design Specialist's and are not covered here.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. At most 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch1_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box` or `tray`.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| bin_kitchen | 0.320 x 0.320 x 0.620 | 0.32 x 0.32 x 0.62 | 37 | black 1E1B19 | body | PASS | Pedal bin with flip lid, grip and label plate; pedal on the front. |
| bath_mat | 0.600 x 0.400 x 0.030 | 0.60 x 0.40 x 0.03 | 57 | blue 4A6FA5 | mat, mat_ridge | PASS | Starred family (an hh_ bath mat exists, untouched); delivered as new hh_cat_bath_mat. Ridged mat with cream trim. Part `mat` picks up the kilim texture in Props. |
| wine_rack | 0.500 x 0.260 x 0.600 | 0.50 x 0.26 x 0.60 | 204 | oak C68B59 | post, rail, top | PASS | Oak frame, 3x3 bottles with necks to the front. `top` gets the oak texture. |
| suitcase | 0.500 x 0.200 x 0.700 | 0.50 x 0.20 x 0.70 | 91 | blue 4A6FA5 | body, body_rib | PASS | Hard-shell case with ribs, telescopic handle, wheels at back, luggage tag on front. |
| toy_box | 0.700 x 0.400 x 0.420 | 0.70 x 0.40 x 0.42 | 69 | blue 4A6FA5 | chest, lid | PASS | Chest (body named `chest`, not `box`, to avoid the cardboard hook) with padded lid, rope handles and ABC blocks on the front. |
| ottoman | 0.900 x 0.450 x 0.450 | 0.90 x 0.45 x 0.45 | 81 | blue 4A6FA5 | body, cushion | PASS | Long button-tufted bench ottoman on walnut feet. `cushion` gets linen. |
| bar_stool | 0.360 x 0.360 x 0.720 | 0.36 x 0.36 x 0.72 | 63 | blue 4A6FA5 | seat | PASS | Round upholstered seat, chrome pole, foot ring and base; symmetric. |
| shoe_rack | 0.700 x 0.300 x 0.360 | 0.70 x 0.30 x 0.36 | 256 | oak C68B59 | side, slat, top | PASS | Two slatted shelves of shoes, toes to the front. `top` gets the oak texture. |
| bookshelf_v | 0.800 x 0.300 x 1.200 | 0.80 x 0.30 x 1.20 | 327 | oak C68B59 | side, top, plinth, back, shelf | PASS | 3-shelf bookcase with ~49 books and an ornament; back panel at +Y Blender. Largest file (~330 KB). |
| plant_pot_v | 0.400 x 0.400 x 0.900 | 0.40 x 0.40 x 0.90 | 162 | blue 4A6FA5 | pot, pot_rim | PASS | Pot is `way`; rubber-plant style leaves fill the 0.40 x 0.40 x 0.90 envelope. `soil` gets concrete. |

Starred families: bath_mat is built as a new add-only `hh_cat_bath_mat.glb`; the existing `hh_` model is untouched. None of the 10 were skipped.
