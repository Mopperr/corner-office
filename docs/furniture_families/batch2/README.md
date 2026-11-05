# Corner Office catalogue families - batch2 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.*`, `batch2_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-2 families: tv_small, kitchen_shelf, glass_cabinet, fireplace_set, wall_clock, crate_stack, picture_frame, round_rug, kitchen_clock, drinks_trolley. The other 10 batch-2 families are Design Specialist's and are not covered here.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. At most 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch2_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box` or `tray`.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| tv_small | 0.700 x 0.180 x 0.450 | 0.70 x 0.18 x 0.45 | 36 | dark 2B2622 | screen | PASS | Flat-screen TV on a pedestal stand; recolourable `way` is the screen. CSV first colour-way is "off" (switched-off screen), mapped to palette dark 2B2622. |
| kitchen_shelf | 0.800 x 0.220 x 0.300 | 0.80 x 0.22 x 0.30 | 156 | oak C68B59 | back_board, shelf, cap_board, bracket | PASS | Wall shelf with brackets, mug rail with three hanging mugs, jars, plate and jug. Wall-hung: origin bottom centre, back board at +Y Blender. |
| glass_cabinet | 0.800 x 0.400 x 1.400 | 0.80 x 0.40 x 1.40 | 237 | oak C68B59 | plinth, side, cornice, door, door_panel, divider, door_frame | PASS | Glazed display cabinet: glass upper doors with shelves of plates, jug, glasses and cups; solid lower doors; brass knobs. |
| fireplace_set | 0.200 x 0.200 x 0.600 | 0.20 x 0.20 x 0.60 | 103 | black 1E1B19 | base, post, hook_bar, tool_shaft, poker_tip, poker_hook, shovel_blade, tongs_arm, tongs_paddle | PASS | Companion set: stand with poker, shovel, brush and tongs, brass ring handle. Symmetric-ish; front check n/a. |
| wall_clock | 0.360 x 0.060 x 0.360 | 0.36 x 0.06 x 0.36 | 61 | black 1E1B19 | case, bezel | PASS | Starred family (an hh_ wall clock exists, untouched); delivered as new hh_cat_wall_clock. Round case, cream face, hands at 10:10, red second hand. Wall-hung: origin bottom centre, face to -Y Blender. |
| crate_stack | 0.500 x 0.350 x 0.600 | 0.50 x 0.35 x 0.60 | 368 | oak C68B59 | crate_base, crate_post, crate_slat, crate_handle_rail | PASS | Three slatted fruit crates stacked, handle slots and stencils on the front, apples on top. Part names avoid `box`. |
| picture_frame | 0.400 x 0.030 x 0.500 | 0.40 x 0.03 x 0.50 | 50 | brass C9A24E | frame_rail, frame_stile | PASS | Brass frame, cream mount, simple landscape picture built from geometry (no textures). Wall-hung. |
| round_rug | 1.200 x 1.200 x 0.030 | 1.20 x 1.20 x 0.03 | 89 | blue 4A6FA5 | rug, rug_field | PASS | Round rug with concentric rings and dots. Main part is named `rug`, so Props applies the kilim texture tinted by the colour-way (intended). |
| kitchen_clock | 0.300 x 0.050 x 0.300 | 0.30 x 0.05 x 0.30 | 108 | blue 4A6FA5 | case | PASS | Rounded-square kitchen clock with fork and spoon hands. Wall-hung. |
| drinks_trolley | 0.700 x 0.400 x 0.750 | 0.70 x 0.40 x 0.75 | 183 | black 1E1B19 | post, handle_arm, deck_rail | PASS | Two glass decks on a black frame with brass handle and feet, wheels, bottles, decanter, glasses, shaker and ice bucket. |

Starred families: bath_mat is built as a new add-only `hh_cat_bath_mat.glb`; the existing `hh_` model is untouched. None of the 10 were skipped.
