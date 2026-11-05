# FINAL art validation - batch5 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | way | front | contact sheet (recognisable) | result |
|---|---|---|---|---|---|---|---|
| hh_cat_school_desk.glb | 0.600 x 0.450 x 0.700 | 0.00% | 79 | C68B59 | PASS | lift-lid desk with bench seat | **PASS** |
| hh_cat_sawhorse.glb | 0.900 x 0.500 x 0.750 | 0.00% | 80 | C68B59 | n/a | A-frame sawhorse | **PASS** |
| hh_cat_tray.glb | 0.400 x 0.280 x 0.050 | 0.00% | 89 | C68B59 | n/a | handled tray with plate and napkin | **PASS** |
| hh_cat_towel_rail_bath.glb | 0.600 x 0.100 x 0.120 | 0.00% | 41 | 1E1B19 | PASS | black wall bar | **PASS** |
| hh_cat_office_poster.glb | 0.500 x 0.030 x 0.700 | 0.00% | 45 | 1E1B19 | PASS | framed bar-chart poster | **PASS** |
| hh_cat_sideboard.glb | 1.400 x 0.450 x 0.800 | 0.00% | 100 | C68B59 | PASS | doors, drawers, splayed legs | **PASS** |
| hh_cat_cushion_set.glb | 0.400 x 0.200 x 0.300 | 0.00% | 56 | 4A6FA5 | n/a | three cushions | **PASS** |
| hh_cat_tree_box.glb | 1.200 x 0.350 x 0.350 | 0.00% | 140 | 5E7B52 | n/a | hedge planter box | **PASS** |
| hh_cat_utensil_jar.glb | 0.120 x 0.120 x 0.300 | 0.00% | 68 | 4A6FA5 | n/a | jar with spoon, whisk, spatula, ladle | **PASS** |
| hh_cat_stand_mixer.glb | 0.220 x 0.340 x 0.340 | 0.00% | 85 | 4A6FA5 | PASS | tilt-head mixer with bowl | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` (new wrapper; `validate_design.py` and `validate.py` untouched) with `validate_design_config_b3_6.json` (lists, front markers, Design's first-colour-way aliases canvas->card, aluminium->steel; plus navy->night, linen->cream, velvet rose->rose, velvet->plum, wire->steel for later ways).
- Checks per file: valid glTF 2 GLB, bbox within 3% of CSV, origin bottom-centre, front at -Y (Blender) / +Z (glTF), `way` material = first colour-way (+-2/255), no copper, <1 MB, <=7 materials, no textures, flat matte (roughness 0.82 +-0.05, metallic 0).
- Files fixed: none (no originals backed up to `families/_design_originals/`). Missing files: none.
- Contact sheet `batch5_contact_design.png` reviewed: all 10 recognisable.
- Front-marker config note: first marker `back_rail` was my mistake (it is the bench back rail, in front by design); marker set to `seat` (front): PASS. No file change.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Full detail: `VALIDATION_design.md` / `.json`.
