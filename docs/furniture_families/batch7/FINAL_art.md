# FINAL - batch7 art share (10 families)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch7_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-7 families: labelled_box, tent_bag, push_mower, compost_bin, step_ladder, metal_shelving, pegboard, fishing_rods, generator, coat_rack_office. The other 10 (cake_stand, egg_box, bread_board, salt_pepper, cutlery_tray, bath_scales, toiletries, candle_holder, aquarium, typewriter) are Design Specialist's, documented in `README_design.md`, `QA_batch7.md` and `batch7_contact_design.png`. One art family is starred: pegboard (CSV existing_glb_same_name = `pegboard`), built as a new `hh_cat_pegboard.glb`; the existing GLB is untouched.

| file | w x d x h (m) | max dev vs CSV | stretch to fit | KB | mats | way | front | recognisable as | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_labelled_box.glb | 0.450 x 0.350 x 0.300 | 0.00% | +0.7% | 28 | 4 | C9A070 | n/a | taped carton with label | **PASS** |
| hh_cat_tent_bag.glb | 0.700 x 0.250 x 0.250 | 0.00% | +1.5% | 73 | 4 | 4A6FA5 | n/a | stuff sack with bands and toggle | **PASS** |
| hh_cat_push_mower.glb | 0.500 x 0.900 x 0.900 | 0.00% | +0.1% | 135 | 5 | 1E1B19 | n/a | petrol lawnmower with bag | **PASS** |
| hh_cat_compost_bin.glb | 0.600 x 0.600 x 0.800 | 0.00% | -0.5% | 65 | 3 | 1E1B19 | n/a | dalek compost bin with hatch | **PASS** |
| hh_cat_step_ladder.glb | 0.500 x 0.700 x 1.200 | 0.00% | -0.5% | 114 | 4 | C9CED3 | n/a | 3-step aluminium ladder | **PASS** |
| hh_cat_metal_shelving.glb | 0.900 x 0.400 x 1.800 | 0.00% | -0.5% | 311 | 7 | 1E1B19 | n/a | garage racking with boxes and tins | **PASS** |
| hh_cat_pegboard.glb | 0.800 x 0.040 x 0.600 | 0.00% | -2.4% | 420 | 6 | C9A070 | n/a | tool pegboard | **PASS** |
| hh_cat_fishing_rods.glb | 0.150 x 0.120 x 1.600 | 0.00% | +0.0% | 120 | 6 | 1E1B19 | n/a | rods in a stand (slender) | **PASS** |
| hh_cat_generator.glb | 0.600 x 0.450 x 0.500 | 0.00% | +0.2% | 111 | 6 | 1E1B19 | n/a | framed petrol generator | **PASS** |
| hh_cat_coat_rack_office.glb | 0.600 x 0.100 x 0.200 | 0.00% | +1.0% | 196 | 5 | C68B59 | n/a | hook rail with scarf | **PASS** |

Validation: **ALL PASS** (10/10 pass, see `VALIDATION.md`). Checks: GLB structure, size within 3%, bottom-centre origin, front -Y (or back +Y for wall pieces), `way` = first colour-way, 3-7 matte untextured materials, no copper, no texture-hook part names, < 1 MB.

## Deviations and notes

- step_ladder way = `aluminium` mapped to palette steel C9CED3.
- fishing_rods way = `carbon` mapped to palette black 1E1B19.
- pegboard is starred (existing `pegboard` GLB); built as new hh_cat_pegboard.glb, existing file untouched.
- pegboard 420 KB (165 modelled holes) and metal_shelving 311 KB: the largest files, both well under 1 MB.
- fishing_rods reads slender on the contact sheet by nature (0.15 m wide, 1.6 m tall).

Contact sheet: `batch7_contact_art.png`. Scripts: `_build/art/` (build_families.py, validate.py, render_contact.py, contact_sheet.py, make_readme.py, make_final.py).
Add-only; nothing committed or pushed. Design Specialist's files and batch1/batch2 build scripts untouched.
