# FINAL art validation - batch6 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | way | front | contact sheet (recognisable) | result |
|---|---|---|---|---|---|---|---|
| hh_cat_whiteboard.glb | 0.900 x 0.040 x 0.600 | 0.00% | 77 | C9CED3 | PASS | board, writing, marker tray | **PASS** |
| hh_cat_cork_board.glb | 0.600 x 0.030 x 0.450 | 0.00% | 72 | C68B59 | PASS | framed cork board with pinned notes | **PASS** |
| hh_cat_fruit_bowl.glb | 0.280 x 0.280 x 0.140 | 0.00% | 70 | 4A6FA5 | n/a | bowl with fruit and banana | **PASS** |
| hh_cat_blender.glb | 0.160 x 0.160 x 0.400 | 0.00% | 85 | 4A6FA5 | PASS | jug blender on base with dial | **PASS** |
| hh_cat_toothbrush_set.glb | 0.080 x 0.080 x 0.200 | 0.00% | 68 | 4A6FA5 | n/a | cup with brushes and tube | **PASS** |
| hh_cat_soap_dish.glb | 0.120 x 0.090 x 0.050 | 0.00% | 45 | 4A6FA5 | n/a | dish with soap bar | **PASS** |
| hh_cat_hair_dryer.glb | 0.220 x 0.080 x 0.200 | 0.00% | 62 | 4A6FA5 | n/a | hair dryer with cord | **PASS** |
| hh_cat_jewellery_box.glb | 0.200 x 0.140 x 0.100 | 0.00% | 136 | C68B59 | PASS | open box, mirror lid, rings, pearls | **PASS** |
| hh_cat_hangers.glb | 0.420 x 0.060 x 0.240 | 0.00% | 111 | C68B59 | n/a | bundle of hangers | **PASS** |
| hh_cat_dollhouse.glb | 0.600 x 0.350 x 0.600 | 0.00% | 121 | 4A6FA5 | PASS | open-front dollhouse with rooms | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` (new wrapper; `validate_design.py` and `validate.py` untouched) with `validate_design_config_b3_6.json` (lists, front markers, Design's first-colour-way aliases canvas->card, aluminium->steel; plus navy->night, linen->cream, velvet rose->rose, velvet->plum, wire->steel for later ways).
- Checks per file: valid glTF 2 GLB, bbox within 3% of CSV, origin bottom-centre, front at -Y (Blender) / +Z (glTF), `way` material = first colour-way (+-2/255), no copper, <1 MB, <=7 materials, no textures, flat matte (roughness 0.82 +-0.05, metallic 0).
- Files fixed: none (no originals backed up to `families/_design_originals/`). Missing files: none.
- Contact sheet `batch6_contact_design.png` reviewed: all 10 recognisable.
- Front-marker config note: first marker `ink` sat 4 mm behind bbox centre because the marker tray projects forward; marker set to `marker` (front): PASS. No file change.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Full detail: `VALIDATION_design.md` / `.json`.
