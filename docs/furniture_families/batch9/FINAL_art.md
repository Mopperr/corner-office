# FINAL - batch9 art share (10 families)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch9_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-9 families: hose_v, seed_trays, bird_feeder, lantern, cool_box, kayak, water_cooler, shredder, heater, office_trolley. The other 10 (picture_stack, gramophone, dartboard, bird_cage, vinyl_crate, sewing_machine, tool_box_v, paint_cans, flower_pot_v, spades) are Design Specialist's, documented in `README_design.md`, `QA_batch9.md` and `batch9_contact_design.png`. No batch-9 art family is starred; all 10 are new.

| file | w x d x h (m) | max dev vs CSV | stretch to fit | KB | mats | way | front | recognisable as | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_hose_v.glb | 0.400 x 0.400 x 0.140 | 0.00% | +0.0% | 49 | 4 | 1E1B19 | n/a | coiled hose with spray gun | **PASS** |
| hh_cat_seed_trays.glb | 0.400 x 0.240 x 0.100 | 0.00% | -0.2% | 413 | 5 | 1E1B19 | n/a | seedling tray | **PASS** |
| hh_cat_bird_feeder.glb | 0.200 x 0.200 x 0.500 | 0.00% | +0.1% | 74 | 4 | 5E7B52 | n/a | tube bird feeder | **PASS** |
| hh_cat_lantern.glb | 0.160 x 0.160 x 0.300 | 0.00% | -1.2% | 62 | 5 | 1E1B19 | n/a | hurricane lantern | **PASS** |
| hh_cat_cool_box.glb | 0.500 x 0.320 x 0.360 | 0.00% | -1.2% | 55 | 4 | 4A6FA5 | n/a | cool box | **PASS** |
| hh_cat_kayak.glb | 2.400 x 0.600 x 0.350 | 0.00% | +0.3% | 53 | 5 | 4A6FA5 | n/a | kayak | **PASS** |
| hh_cat_water_cooler.glb | 0.350 x 0.350 x 1.200 | 0.00% | +0.9% | 55 | 6 | 1E1B19 | n/a | water cooler | **PASS** |
| hh_cat_shredder.glb | 0.360 x 0.260 x 0.500 | 0.00% | -1.1% | 37 | 7 | 1E1B19 | n/a | paper shredder | **PASS** |
| hh_cat_heater.glb | 0.500 x 0.200 x 0.600 | 0.00% | +0.0% | 105 | 5 | 1E1B19 | n/a | oil-filled radiator | **PASS** |
| hh_cat_office_trolley.glb | 0.600 x 0.400 x 0.800 | 0.00% | +0.7% | 138 | 7 | 1E1B19 | n/a | post trolley with parcels | **PASS** |

Validation: **ALL PASS** (10/10 pass, see `VALIDATION.md`). Checks: GLB structure, size within 3%, bottom-centre origin, front -Y (or back +Y for wall pieces), `way` = first colour-way, 3-7 matte untextured materials, no copper, no texture-hook part names, < 1 MB.

## Deviations and notes

- No colour mapping needed; no starred families.
- seed_trays 413 KB (24 modelled cells with seedlings), still well under 1 MB.
- kayak reads small on the contact sheet (2.4 m long, 0.35 m high) but is to CSV size.
- Design's README_design.md / QA_batch9.md / batch9_contact_design.png were not present yet (Design's batch-9 GLBs were); the scope note names them as Design's.

Contact sheet: `batch9_contact_art.png`. Scripts: `_build/art/` (build_families.py, validate.py, render_contact.py, contact_sheet.py, make_readme.py, make_final.py).
Add-only; nothing committed or pushed. Design Specialist's files and batch1/batch2 build scripts untouched.
