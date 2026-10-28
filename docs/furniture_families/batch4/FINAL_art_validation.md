# FINAL art validation - batch4 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | way | front | contact sheet (recognisable) | result |
|---|---|---|---|---|---|---|---|
| hh_cat_poster.glb | 0.500 x 0.020 x 0.700 | 0.00% | 36 | 4A6FA5 | PASS | framed print, sun/hills, title | **PASS** |
| hh_cat_towel_rail.glb | 0.400 x 0.080 x 0.260 | 0.00% | 57 | 4A6FA5 | PASS | wall rail with draped striped towel | **PASS** |
| hh_cat_pram.glb | 0.900 x 0.500 x 1.000 | 0.00% | 163 | 4A6FA5 | n/a | hooded pram, wheels, handle | **PASS** |
| hh_cat_skis.glb | 0.200 x 0.120 x 1.700 | 0.00% | 112 | 4A6FA5 | n/a | pair of upright skis, bindings | **PASS** |
| hh_cat_mannequin.glb | 0.420 x 0.300 x 1.500 | 0.00% | 66 | 4A6FA5 | n/a | dress form on tripod | **PASS** |
| hh_cat_planter_box.glb | 0.800 x 0.350 x 0.400 | 0.00% | 180 | 1E1B19 | n/a | planter with plants/flowers | **PASS** |
| hh_cat_bowl_set.glb | 0.220 x 0.220 x 0.120 | 0.00% | 53 | 4A6FA5 | n/a | nested bowls | **PASS** |
| hh_cat_casserole.glb | 0.300 x 0.240 x 0.160 | 0.00% | 49 | 4A6FA5 | n/a | lidded casserole with handles | **PASS** |
| hh_cat_cookbooks.glb | 0.240 x 0.200 x 0.140 | 0.00% | 78 | 4A6FA5 | PASS | stack of books with spine labels | **PASS** |
| hh_cat_bath_plant.glb | 0.260 x 0.260 x 0.340 | 0.00% | 86 | 4A6FA5 | n/a | potted spiky plant | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` (new wrapper; `validate_design.py` and `validate.py` untouched) with `validate_design_config_b3_6.json` (lists, front markers, Design's first-colour-way aliases canvas->card, aluminium->steel; plus navy->night, linen->cream, velvet rose->rose, velvet->plum, wire->steel for later ways).
- Checks per file: valid glTF 2 GLB, bbox within 3% of CSV, origin bottom-centre, front at -Y (Blender) / +Z (glTF), `way` material = first colour-way (+-2/255), no copper, <1 MB, <=7 materials, no textures, flat matte (roughness 0.82 +-0.05, metallic 0).
- Files fixed: none (no originals backed up to `families/_design_originals/`). Missing files: none.
- Contact sheet `batch4_contact_design.png` reviewed: all 10 recognisable.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Full detail: `VALIDATION_design.md` / `.json`.
