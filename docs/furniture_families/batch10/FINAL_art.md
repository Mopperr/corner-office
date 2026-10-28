# FINAL - batch10 art share (12 families)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch10_contact_art.png`, `_build/art/`) covers 12 of the 22 batch-10 families: coffee_machine_v, mug_tree, folder_stack, desk_fan, office_kettle, reception_sign, projector, office_speaker, stapler_set, dispatch_scale, globe_office, desk_calendar. The other 10 (axe_logs, desk_lamp, monitor, keyboard_mouse, printer, paper_tray, pen_pot, laptop, desk_phone, desk_tidy) are Design Specialist's, documented in `README_design.md`, `QA_batch10.md` and `batch10_contact_design.png`. STARRED: coffee_machine_v corresponds to the existing `coffee_machine` model and is built as a new `hh_cat_coffee_machine_v.glb`. It does not replace the existing file.

| file | w x d x h (m) | max dev vs CSV | stretch to fit | KB | mats | way | front | recognisable as | result |
|---|---|---|---|---|---|---|---|---|---|
| hh_cat_coffee_machine_v.glb | 0.300 x 0.350 x 0.380 | 0.00% | +0.0% | 78 | 5 | 1E1B19 | n/a | espresso machine | **PASS** |
| hh_cat_mug_tree.glb | 0.220 x 0.220 x 0.340 | 0.00% | +0.0% | 57 | 5 | C68B59 | n/a | mug tree with mugs | **PASS** |
| hh_cat_folder_stack.glb | 0.300 x 0.340 x 0.220 | 0.00% | +1.4% | 143 | 7 | 4A6FA5 | n/a | stack of ring binders | **PASS** |
| hh_cat_desk_fan.glb | 0.300 x 0.140 x 0.380 | 0.00% | +0.8% | 117 | 4 | 1E1B19 | n/a | desk fan | **PASS** |
| hh_cat_office_kettle.glb | 0.200 x 0.160 x 0.240 | 0.00% | +1.6% | 59 | 4 | 4A6FA5 | n/a | kettle on base | **PASS** |
| hh_cat_reception_sign.glb | 0.400 x 0.080 x 0.200 | 0.00% | -0.6% | 352 | 4 | 1E1B19 | n/a | RECEPTION desk sign (legible) | **PASS** |
| hh_cat_projector.glb | 0.300 x 0.240 x 0.100 | 0.00% | +0.2% | 58 | 7 | 1E1B19 | n/a | projector | **PASS** |
| hh_cat_office_speaker.glb | 0.200 x 0.200 x 0.060 | 0.00% | +0.0% | 25 | 5 | 1E1B19 | n/a | conference speakerphone | **PASS** |
| hh_cat_stapler_set.glb | 0.240 x 0.120 x 0.080 | 0.00% | +0.1% | 50 | 5 | 1E1B19 | n/a | stapler + hole punch (punch lever reads thin) | **PASS** |
| hh_cat_dispatch_scale.glb | 0.300 x 0.300 x 0.120 | 0.00% | -0.4% | 48 | 7 | 1E1B19 | n/a | parcel scale with parcel | **PASS** |
| hh_cat_globe_office.glb | 0.260 x 0.260 x 0.360 | 0.00% | +2.0% | 90 | 4 | C9A070 | n/a | desk globe | **PASS** |
| hh_cat_desk_calendar.glb | 0.180 x 0.100 x 0.140 | 0.00% | +0.5% | 68 | 6 | 4A6FA5 | n/a | tent desk calendar | **PASS** |

Validation: **ALL PASS** (12/12 pass, see `VALIDATION.md`). Checks: GLB structure, size within 3%, bottom-centre origin, front -Y (or back +Y for wall pieces), `way` = first colour-way, 3-7 matte untextured materials, no copper, no texture-hook part names, < 1 MB.

## Deviations and notes

- STARRED: coffee_machine_v (existing `coffee_machine`) is built as a new hh_cat_ file.
- globe_office: 'antique' is mapped to kraft C9A070.
- This batch has 12 art families (22 rows; Design has the first 10). The contact sheet is titled 'art share 12/22'.
- reception_sign is 351 KB (about 70 bevelled letter-run boxes). This is the largest file and is still well under 1 MB.
- Design's README_design.md / QA_batch10.md / batch10_contact_design.png were not present when this was written. The scope note names them as Design's.

Contact sheet: `batch10_contact_art.png`. Scripts: `_build/art/` (build_families.py, validate.py, render_contact.py, contact_sheet.py, make_readme.py, make_final.py).
Add-only; nothing committed or pushed. Design Specialist's files and batch1/batch2 build scripts untouched.
