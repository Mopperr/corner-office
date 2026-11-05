# Corner Office catalogue families - batch5 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `batch5_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-5 families: radio_kitchen, bath_shelf, candles, slippers, sewing_box, globe_v, filing_cabinet, office_plant, low_cabinet, garden_bench. The other 10 (school_desk, sawhorse, tray, towel_rail_bath, office_poster, sideboard, cushion_set, tree_box, utensil_jar, stand_mixer) are Design Specialist's, documented in `README_design.md`, `QA_batch5.md` and `batch5_contact_design.png`. filing_cabinet is starred (an existing `filing_cabinet` model exists), so per spec it is built as a new `hh_cat_filing_cabinet.glb` and the existing model is untouched; the other 9 are new.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch5_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug` or `mat`, so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| radio_kitchen | 0.240 x 0.100 x 0.140 | 0.24 x 0.10 x 0.14 | 73 | blue 4A6FA5 | radio_body | PASS | Retro kitchen radio: `way` cabinet (`radio_body`), cream grille with dark slots, glass dial window with ticks and red needle, two cream knobs, dark carry handle, dark feet. |
| bath_shelf | 0.600 x 0.140 x 0.240 | 0.60 x 0.14 x 0.24 | 109 | glass BFD6DA | shelf | PASS | Wall-hung bath shelf: `way` glass plate (CSV first colour-way is `glass`, a palette colour BFD6DA) on steel wall plates and brackets with a front gallery rail (`rail`, not towel); bottles, caps and a bar of soap on it. Origin bottom centre, back toward +Y Blender. |
| candles | 0.200 x 0.100 x 0.120 | 0.20 x 0.10 x 0.12 | 77 | blue 4A6FA5 | candle | PASS | Three pillar candles in `way` with cream melt pools, dark wicks and mustard flames on an oval brass dish. Round piece, front check n/a. |
| slippers | 0.260 x 0.120 x 0.080 | 0.26 x 0.12 x 0.08 | 53 | blue 4A6FA5 | upper | PASS | Pair of mule slippers side by side, toes to -X (so the -Y front shows them side-on): `way` uppers, kraft soles, cream footbeds, linings and pom-poms. Front check n/a (side-on piece). |
| sewing_box | 0.320 x 0.220 x 0.200 | 0.32 x 0.22 x 0.20 | 119 | blue 4A6FA5 | sewing_case, lid | PASS | Sewing box: `way` case (`sewing_case`, not `box`) and lid, cream lid band, brass clasp, hinges and feet; red pincushion with pins, three thread spools and a tape measure on the lid. |
| globe_v | 0.320 x 0.320 x 0.450 | 0.32 x 0.32 x 0.45 | 88 | kraft C9A070 | globe | PASS | Antique desk globe: CSV first colour-way `antique` is not a palette colour, mapped to kraft C9A070 for `way` (the sphere); sage land patches, tilted brass meridian, walnut stand. Round piece, front check n/a. Raw depth 2.98% under, stretched (under 3%). |
| filing_cabinet | 0.450 x 0.600 x 1.300 | 0.45 x 0.60 x 1.30 | 88 | black 1E1B19 | carcass, drawer | PASS | Four-drawer steel filing cabinet: `way` (black) carcass and drawer fronts, steel handles and label frames with cream cards, lock, dark plinth and lid trim. Starred family, built as a new `hh_cat_` file. |
| office_plant | 0.350 x 0.350 x 0.800 | 0.35 x 0.35 x 0.80 | 56 | blue 4A6FA5 | pot | PASS | Snake plant: `way` tapered pot with cream rim, dark `potting_mix` (deliberately not `soil`, so no concrete texture), twelve pointed green / sage blades. |
| low_cabinet | 0.900 x 0.450 x 0.750 | 0.90 x 0.45 x 0.75 | 79 | grey 8E8276 | carcass, cabinet_top, door, door_panel | PASS | Low two-door cabinet: `way` (grey) carcass, doors with raised panels and `cabinet_top` (deliberately not `top`, so no oak-floor texture), brass knobs, dark door gap, walnut tapered legs. |
| garden_bench | 1.300 x 0.500 x 0.850 | 1.30 x 0.50 x 0.85 | 153 | black 1E1B19 | front_leg, back_leg, armrest, seat_rail, scroll | PASS | Garden bench facing -Y: CSV first colour-way `cast iron` is not a palette colour, mapped to black 1E1B19 for `way` (the scrolled iron ends, arms and rails); oak seat and back slats. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is globe_v +3.0% in depth (2.98%, just under the 3% note threshold); all others 2.7% or less, see `_build/art/fit_log.json`. None of the 10 were skipped. Colour mappings: globe_v antique -> kraft, garden_bench cast iron -> black.
