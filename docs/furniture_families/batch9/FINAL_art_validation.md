# FINAL art validation - batch9 (Design Specialist's 10)

Created by Andrew's Helpers (Grok Bots)

| file | w x d x h (m) | max dev | KB | mats | way | front | contact sheet | texture hooks (note) | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_picture_stack.glb | 0.500 x 0.200 x 0.600 | 0.00% | 149 | 7 | C9A24E | PASS | leaning frames, rear one seen from behind (intended) | - | **PASS** |
| hh_cat_gramophone.glb | 0.400 x 0.400 x 0.600 | 0.00% | 142 | 7 | C68B59 | n/a | horn, platter, case | top->oak_floor | **PASS** |
| hh_cat_dartboard.glb | 0.450 x 0.050 x 0.450 | 0.00% | 380 | 6 | 1E1B19 | PASS | dartboard | - | **PASS** |
| hh_cat_bird_cage.glb | 0.350 x 0.350 x 0.550 | 0.00% | 241 | 6 | 1E1B19 | PASS | domed cage with bird | - | **PASS** |
| hh_cat_vinyl_crate.glb | 0.400 x 0.360 x 0.360 | 0.00% | 198 | 6 | B6453F | n/a | red crate of records | - | **PASS** |
| hh_cat_sewing_machine.glb | 0.420 x 0.200 x 0.300 | 0.00% | 93 | 7 | 1E1B19 | n/a | vintage machine on board | - | **PASS** |
| hh_cat_tool_box_v.glb | 0.450 x 0.220 x 0.220 | 0.00% | 95 | 5 | 1E1B19 | PASS | toolbox with hammer, screwdriver | - | **PASS** |
| hh_cat_paint_cans.glb | 0.400 x 0.220 x 0.200 | 0.00% | 145 | 5 | 4A6FA5 | n/a | tins, open tin, brush | - | **PASS** |
| hh_cat_flower_pot_v.glb | 0.300 x 0.300 x 0.260 | 0.00% | 356 | 5 | F4F1EA | n/a | pots, flowers, saucer | soil->concrete | **PASS** |
| hh_cat_spades.glb | 0.200 x 0.100 x 1.100 | 0.00% | 83 | 4 | C68B59 | n/a | spade and fork, side by side | - | **PASS** |

- Validator: `batch1/_build/art/validate_design_b3_6.py` + `validate_design_config_b3_6.json` (extended for batch7-10; `validate_design.py`/`validate.py` untouched).
- First colour-way aliases (Design's): classic->black (dartboard), milk crate->red (vinyl_crate), gilt->brass (picture_stack); later ways faded->grey, glazed blue/sage->blue/sage, plastic black->black.
- Texture hooks: names matching Props `PART_TEXTURES`, notes only.
- Files fixed by Art: none (per Boss, Design's GLBs are not edited). Missing files: none.
- History: first run (GLBs of 21:52-21:54 UTC+2) failed bird_cage (8 materials) and vinyl_crate (9 materials). Design rewrote them at 21:57:30 UTC+2 (bird_cage 6, vinyl_crate 6 materials); re-run at 21:58:55 UTC+2: all pass.
- picture_stack front marker: `backing` faces the viewer on purpose (rear frame seen from behind, per Design's build); marker set to `backing` front. Config only.
- Contact sheet `batch9_contact_design.png` reviewed: all 10 recognisable.

Overall: **ALL PASS** (10/10 pass, 0 fixed, 0 fail). Detail: `VALIDATION_design.md` / `.json`.
