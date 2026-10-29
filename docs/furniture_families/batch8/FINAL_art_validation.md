# FINAL art validation - batch8 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | mats | way | front | contact sheet | texture hooks (note) | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_loo_roll.glb | 0.120 x 0.120 x 0.330 | 0.00% | 78 | 4 | EAE6DC | PASS | three stacked rolls, tail | - | **PASS** |
| hh_cat_medicine_cabinet.glb | 0.400 x 0.140 x 0.500 | 0.00% | 116 | 6 | C68B59 | PASS | mirror door, red cross, shelf | - | **PASS** |
| hh_cat_bath_caddy.glb | 0.700 x 0.160 x 0.100 | 0.00% | 237 | 7 | C68B59 | n/a | slatted rack with book, bottles, sponge | - | **PASS** |
| hh_cat_string_lights.glb | 0.900 x 0.060 x 0.200 | 0.00% | 216 | 6 | E6B655 | PASS | festoon of coloured bulbs | - | **PASS** |
| hh_cat_console.glb | 0.300 x 0.240 x 0.080 | 0.00% | 93 | 7 | 1E1B19 | PASS | games console with pad | - | **PASS** |
| hh_cat_chess_set.glb | 0.340 x 0.340 x 0.080 | 0.00% | 332 | 5 | C68B59 | n/a | board with pieces | - | **PASS** |
| hh_cat_trophy.glb | 0.140 x 0.140 x 0.300 | 0.00% | 85 | 4 | D9765F | PASS | cup on plinth with plaque (bronze->terracotta) | - | **PASS** |
| hh_cat_old_lamp.glb | 0.260 x 0.260 x 0.500 | 0.00% | 106 | 5 | 4A6FA5 | n/a | oil lamp with chimney (shade reads a bit bowl-like; borderline but OK) | - | **PASS** |
| hh_cat_model_ship.glb | 0.500 x 0.140 x 0.450 | 0.00% | 184 | 6 | C68B59 | n/a | galleon on stand | top->oak_floor | **PASS** |
| hh_cat_bucket.glb | 0.300 x 0.300 x 0.300 | 0.00% | 92 | 3 | 4A6FA5 | n/a | bucket with handle | - | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` + `validate_design_config_b3_6.json` (extended for batch7-10; `validate_design.py`/`validate.py` untouched). Same checks as batch1-6.
- Colour aliases used for first colour-ways (Design's): wood->oak, mixed->mustard, bronze->terracotta, classic->black, milk crate->red, gilt->brass; later ways: warm->mustard, gold->brass, silver->steel, tarnished->grey, galvanised->steel, faded->grey, glazed blue/sage->blue/sage, plastic black->black.
- Texture hooks: names matching Props `PART_TEXTURES` (scan: `batch1/_build/art/texture_hook_scan.py`), notes only.
- Files fixed: none. Per Boss, Design's GLBs are not edited; issues are reported to Design. Missing files: none.
- Contact sheet `batch8_contact_design.png` reviewed: all 10 recognisable.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Detail: `VALIDATION_design.md` / `.json`.
