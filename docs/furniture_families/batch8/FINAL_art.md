# FINAL - batch8 art share (10 families)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch8_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-8 families: wellies, wheelbarrow_v, watering_v, office_bin, office_shelf, desk_v, office_clock, safe, notice_board, umbrella_stand. The other 10 (loo_roll, medicine_cabinet, bath_caddy, string_lights, console, chess_set, trophy, old_lamp, model_ship, bucket) are Design Specialist's, documented in `README_design.md`, `QA_batch8.md` and `batch8_contact_design.png`. Three art families are starred: wheelbarrow_v (existing `hh_wheelbarrow`), watering_v (existing `hh_watering_can`) and desk_v (existing `desk`). Each is built as a new `hh_cat_` file and the existing GLBs are untouched.

| file | w x d x h (m) | max dev vs CSV | stretch to fit | KB | mats | way | front | recognisable as | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_wellies.glb | 0.300 x 0.300 x 0.360 | 0.00% | -0.4% | 105 | 4 | 1E1B19 | n/a | pair of wellies | **PASS** |
| hh_cat_wheelbarrow_v.glb | 0.650 x 1.200 x 0.600 | 0.00% | +0.9% | 73 | 5 | 1E1B19 | n/a | wheelbarrow | **PASS** |
| hh_cat_watering_v.glb | 0.400 x 0.200 x 0.300 | 0.00% | -1.9% | 69 | 5 | 4A6FA5 | n/a | watering can | **PASS** |
| hh_cat_office_bin.glb | 0.280 x 0.280 x 0.320 | 0.00% | +1.3% | 49 | 4 | 1E1B19 | n/a | waste bin with paper | **PASS** |
| hh_cat_office_shelf.glb | 0.800 x 0.350 x 1.800 | 0.00% | +0.0% | 304 | 6 | 8E8276 | n/a | bookcase with binders | **PASS** |
| hh_cat_desk_v.glb | 1.400 x 0.700 x 0.750 | 0.00% | +0.0% | 88 | 4 | C68B59 | n/a | pedestal office desk | **PASS** |
| hh_cat_office_clock.glb | 0.300 x 0.040 x 0.300 | 0.00% | +0.0% | 74 | 4 | 1E1B19 | n/a | wall clock | **PASS** |
| hh_cat_safe.glb | 0.450 x 0.450 x 0.550 | 0.00% | -0.2% | 112 | 4 | 1E1B19 | n/a | combination safe | **PASS** |
| hh_cat_notice_board.glb | 0.900 x 0.040 x 0.600 | 0.00% | -0.0% | 86 | 7 | C68B59 | n/a | cork board with notes | **PASS** |
| hh_cat_umbrella_stand.glb | 0.220 x 0.220 x 0.850 | 0.00% | +0.1% | 66 | 6 | 1E1B19 | n/a | stand with two umbrellas | **PASS** |

Validation: **ALL PASS** (10/10 pass, see `VALIDATION.md`). Checks: GLB structure, size within 3%, bottom-centre origin, front -Y (or back +Y for wall pieces), `way` = first colour-way, 3-7 matte untextured materials, no copper, no texture-hook part names, < 1 MB.

## Deviations and notes

- Three starred families (wheelbarrow_v -> hh_wheelbarrow, watering_v -> hh_watering_can, desk_v -> desk) are built as new hh_cat_ files; the existing GLBs are untouched.
- No colour mapping needed.

Contact sheet: `batch8_contact_art.png`. Scripts: `_build/art/` (build_families.py, validate.py, render_contact.py, contact_sheet.py, make_readme.py, make_final.py).
Add-only; nothing committed or pushed. Design Specialist's files and batch1/batch2 build scripts untouched.
