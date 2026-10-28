# Corner Office catalogue families - batch3 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `batch3_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-3 families: mirror_round, rubber_duck, bedside_lamp, blanket, teddy, hat_box, speaker, vase, table_lamp, guitar. The other 10 (keyboard_piano, log_basket, suitcase_stack, mirror_oval, mug, plate_stack, saucepan, jug, storage_jar, towel_pile) are Design Specialist's, documented in `README_design.md`, `QA_batch3.md` and `batch3_contact_design.png`. None of the 20 batch-3 families is starred (no existing `hh_` model), so all are new `hh_cat_` files.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch3_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug` or `mat`, so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| mirror_round | 0.500 x 0.040 x 0.500 | 0.50 x 0.04 x 0.50 | 30 | brass C9A24E | frame, hanging_loop | PASS | Round wall mirror: `way` torus frame (brass), glass face with glints, dark backing at +Y, small hanging loop. Wall-hung: origin bottom centre, back toward +Y Blender. |
| rubber_duck | 0.100 x 0.080 x 0.100 | 0.10 x 0.08 x 0.10 | 57 | black 1E1B19 | body, tail, head, wing | PASS | Bath duck in profile along X (beak to -X, so the -Y front shows the side view), `way` body, head, tail and wings, terracotta beak, white/dark eyes. CSV first colour-way is black, so the plain build is a black duck (the CSV example id is yellow; it tints in game). Front check n/a (side-on piece). |
| bedside_lamp | 0.240 x 0.240 x 0.420 | 0.24 x 0.24 x 0.42 | 61 | blue 4A6FA5 | foot, body | PASS | Gourd lamp: `way` ceramic foot and body, brass socket, tapered cream shade with brass trims, pull chain, cord out the back. |
| blanket | 0.440 x 0.340 x 0.140 | 0.44 x 0.34 x 0.14 | 74 | blue 4A6FA5 | blanket | PASS | Folded blanket: three soft bevelled layers named `blanket` (deliberately not `towel`/`duvet`, so no linen texture is applied), cream stripes wrapping the fold, kraft label at the front. |
| teddy | 0.200 x 0.160 x 0.300 | 0.20 x 0.16 x 0.30 | 104 | walnut 6B4A3A | body, head, ear, arm, leg | PASS | Sitting teddy facing -Y: `way` body, head, ears, arms, legs; cream muzzle, tummy, ear insides and foot pads; dark eyes and nose; red bow. CSV first colour-way "brown" is not a palette colour, mapped to walnut 6B4A3A. Raw build 2.6% short in height, stretched to CSV size. |
| hat_box | 0.340 x 0.340 x 0.200 | 0.34 x 0.34 x 0.20 | 89 | blue 4A6FA5 | hatbox_body, lid | PASS | Round hat box: `way` drum (`hatbox_body`, not `box`) and lid, cream vertical stripes and lid band, cream cord handle with brass grommets, brass label at the front. |
| speaker | 0.220 x 0.220 x 0.400 | 0.22 x 0.22 x 0.40 | 66 | black 1E1B19 | cabinet | PASS | Bookshelf speaker: `way` cabinet, grey baffle, woofer with surround and dust cap, tweeter, bass port and LED on the front (-Y), small feet. |
| vase | 0.140 x 0.140 x 0.300 | 0.14 x 0.14 x 0.30 | 62 | blue 4A6FA5 | body | PASS | Lathed ceramic vase: `way` glaze, cream belly band and foot line, mustard neck line, cream dots, open neck. Round; front check n/a. |
| table_lamp | 0.300 x 0.300 x 0.500 | 0.30 x 0.30 x 0.50 | 80 | blue 4A6FA5 | body | PASS | Living-room lamp: oak foot, `way` ceramic column with brass band, cream drum shade with oak trims, inline switch at the front. |
| guitar | 0.400 x 0.120 x 1.000 | 0.40 x 0.12 x 1.00 | 136 | black 1E1B19 | body | PASS | Acoustic guitar standing upright, soundboard to -Y: `way` figure-of-eight body (extruded smoothed outline), soundhole with cream rosette, bridge and saddle, pickguard, oak neck and headstock, dark fretboard with frets and dots, six steel strings, tuning pegs. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is teddy +2.6% in height (all others under 2.1%, see `_build/art/fit_log.json`). Nothing is over 3%. None of the 10 were skipped.
