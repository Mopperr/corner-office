# FINAL art validation - batch3 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | way | front | contact sheet (recognisable) | result |
|---|---|---|---|---|---|---|---|
| hh_cat_keyboard_piano.glb | 1.300 x 0.350 x 0.120 | 0.00% | 433 | 1E1B19 | PASS | reads clearly: black/white keys, display, speakers | **PASS** |
| hh_cat_log_basket.glb | 0.450 x 0.350 x 0.400 | 0.00% | 94 | E7DCC6 | n/a | reads as log box (card/canvas body, stacked logs) | **PASS** |
| hh_cat_suitcase_stack.glb | 0.700 x 0.450 x 0.600 | 0.00% | 186 | 4A6FA5 | PASS | three stacked cases, straps, handles | **PASS** |
| hh_cat_mirror_oval.glb | 0.400 x 0.040 x 0.600 | 0.00% | 30 | C9A24E | PASS | brass oval frame, glint | **PASS** |
| hh_cat_mug.glb | 0.090 x 0.090 x 0.100 | 0.00% | 28 | 4A6FA5 | n/a | striped mug with coffee | **PASS** |
| hh_cat_plate_stack.glb | 0.260 x 0.260 x 0.090 | 0.00% | 71 | 4A6FA5 | n/a | stack of rimmed plates | **PASS** |
| hh_cat_saucepan.glb | 0.220 x 0.220 x 0.140 | 0.00% | 50 | 1E1B19 | n/a | pan, lid, knob, handle | **PASS** |
| hh_cat_jug.glb | 0.140 x 0.140 x 0.220 | 0.00% | 37 | 4A6FA5 | n/a | tall enamel jug, spout, handle | **PASS** |
| hh_cat_storage_jar.glb | 0.140 x 0.140 x 0.240 | 0.00% | 36 | 4A6FA5 | PASS | jar, lid, label | **PASS** |
| hh_cat_towel_pile.glb | 0.400 x 0.300 x 0.240 | 0.00% | 77 | 4A6FA5 | n/a | folded towel stack | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` (new wrapper; `validate_design.py` and `validate.py` untouched) with `validate_design_config_b3_6.json` (lists, front markers, Design's first-colour-way aliases canvas->card, aluminium->steel; plus navy->night, linen->cream, velvet rose->rose, velvet->plum, wire->steel for later ways).
- Checks per file: valid glTF 2 GLB, bbox within 3% of CSV, origin bottom-centre, front at -Y (Blender) / +Z (glTF), `way` material = first colour-way (+-2/255), no copper, <1 MB, <=7 materials, no textures, flat matte (roughness 0.82 +-0.05, metallic 0).
- Files fixed: none (no originals backed up to `families/_design_originals/`). Missing files: none.
- Contact sheet `batch3_contact_design.png` reviewed: all 10 recognisable.
- Note: keyboard_piano is 433 KB (largest of the 40, still under 1 MB); log_basket reads more as a canvas log box than a woven basket, which matches its canvas colour-way.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Full detail: `VALIDATION_design.md` / `.json`.
