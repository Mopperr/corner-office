# FINAL art validation - batch7 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | mats | way | front | contact sheet | texture hooks (note) | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_cake_stand.glb | 0.300 x 0.300 x 0.180 | 0.00% | 215 | 6 | F4F1EA | n/a | tiered stand, cake, cupcakes | - | **PASS** |
| hh_cat_egg_box.glb | 0.200 x 0.140 x 0.120 | 0.00% | 124 | 3 | 8FA882 | n/a | basket with eggs and handle | - | **PASS** |
| hh_cat_bread_board.glb | 0.300 x 0.180 x 0.120 | 0.00% | 120 | 5 | C68B59 | n/a | board, loaf, slice, knife | - | **PASS** |
| hh_cat_salt_pepper.glb | 0.100 x 0.050 x 0.100 | 0.00% | 99 | 4 | F4F1EA | n/a | pair of shakers | - | **PASS** |
| hh_cat_cutlery_tray.glb | 0.340 x 0.260 x 0.050 | 0.00% | 171 | 3 | C68B59 | n/a | divided drawer tray with cutlery | - | **PASS** |
| hh_cat_bath_scales.glb | 0.300 x 0.300 x 0.040 | 0.00% | 68 | 5 | 1E1B19 | PASS | flat scale, foot pads, display | - | **PASS** |
| hh_cat_toiletries.glb | 0.260 x 0.180 x 0.200 | 0.00% | 199 | 7 | 8FA882 | n/a | wicker basket with bottles, tube | - | **PASS** |
| hh_cat_candle_holder.glb | 0.200 x 0.100 x 0.260 | 0.00% | 67 | 3 | 1E1B19 | n/a | two candlesticks with candles | - | **PASS** |
| hh_cat_aquarium.glb | 0.600 x 0.300 x 0.400 | 0.00% | 748 | 7 | 1E1B19 | PASS | tank, gravel, plants, fish (open front by design) | - | **PASS** |
| hh_cat_typewriter.glb | 0.360 x 0.340 x 0.220 | 0.00% | 438 | 5 | 1E1B19 | PASS | keys, carriage, paper | - | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` + `validate_design_config_b3_6.json` (extended for batch7-10; `validate_design.py`/`validate.py` untouched). Same checks as batch1-6.
- Colour aliases used for first colour-ways (Design's): wood->oak, mixed->mustard, bronze->terracotta, classic->black, milk crate->red, gilt->brass; later ways: warm->mustard, gold->brass, silver->steel, tarnished->grey, galvanised->steel, faded->grey, glazed blue/sage->blue/sage, plastic black->black.
- Texture hooks: names matching Props `PART_TEXTURES` (scan: `batch1/_build/art/texture_hook_scan.py`), notes only.
- Files fixed: none. Per Boss, Design's GLBs are not edited; issues are reported to Design. Missing files: none.
- Contact sheet `batch7_contact_design.png` reviewed: all 10 recognisable.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Detail: `VALIDATION_design.md` / `.json`.
