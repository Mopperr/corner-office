# Corner Office catalogue families - batch7 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch7_contact_art.png`, `_build/art/`) covers 10 of the 20 batch-7 families: labelled_box, tent_bag, push_mower, compost_bin, step_ladder, metal_shelving, pegboard, fishing_rods, generator, coat_rack_office. The other 10 (cake_stand, egg_box, bread_board, salt_pepper, cutlery_tray, bath_scales, toiletries, candle_holder, aquarium, typewriter) are Design Specialist's, documented in `README_design.md`, `QA_batch7.md` and `batch7_contact_design.png`. One art family is starred: pegboard (CSV existing_glb_same_name = `pegboard`), built as a new `hh_cat_pegboard.glb`; the existing GLB is untouched.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch7_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug`, `mat`, `seat` or any other hook name (checked by validate.py), so none of these 10 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| labelled_box | 0.450 x 0.350 x 0.300 | 0.45 x 0.35 x 0.30 | 28 | kraft C9A070 | carton, flap | PASS | Cardboard storage carton: `way` (kraft) `carton` and lid flaps, pine parcel tape, cream front label with dark marker lines, dark hand holes. Named `carton`, not `box`, so no texture hook. |
| tent_bag | 0.700 x 0.250 x 0.250 | 0.70 x 0.25 x 0.25 | 73 | blue 4A6FA5 | sack, cinch, cinch_neck | PASS | Tent in a stuff sack lying along X: `way` sack, dark end cap and compression bands, cinched drawstring end with mustard toggle, dark carry handle, cream front logo. |
| push_mower | 0.500 x 0.900 x 0.900 | 0.50 x 0.90 x 0.90 | 135 | black 1E1B19 | deck, engine_cover | PASS | Petrol push mower facing -Y: `way` (black) deck, dark engine, wheels and front bumper, mustard fuel cap, steel handle with dark grip, grey grass bag at the back. |
| compost_bin | 0.600 x 0.600 x 0.800 | 0.60 x 0.60 x 0.80 | 65 | black 1E1B19 | bin_body, lid, rib, hatch | PASS | Dalek-style compost bin: tapered `way` body with ribs and domed lid, grey handle and framed access hatch at the front, green leaf badge. |
| step_ladder | 0.500 x 0.700 x 1.200 | 0.50 x 0.70 x 1.20 | 114 | steel C9CED3 | stile, rear_leg, tread, rear_rung | PASS | Three-tread step ladder: `way` (aluminium, mapped to palette steel C9CED3) stiles, treads and rear legs, grey tread grips, red tool-shelf cap, dark feet, hinges and spreaders. |
| metal_shelving | 0.900 x 0.400 x 1.800 | 0.90 x 0.40 x 1.80 | 311 | black 1E1B19 | post, front_lip, back_lip, side_lip | PASS | Five-shelf garage racking: `way` (black) angle posts and shelf lips, pine boards, kraft cartons, red and blue paint tins, blue crate, kraft and steel rolls. |
| pegboard | 0.800 x 0.040 x 0.600 | 0.80 x 0.04 x 0.60 | 420 | kraft C9A070 | board | PASS | STARRED (existing `pegboard`); new `hh_cat_pegboard.glb`. Wall pegboard: `way` (kraft) board with dark hole grid on walnut battens (back toward +Y), steel hooks holding hammer, screwdrivers, spanners, pliers, mustard tape measure and a cable coil. |
| fishing_rods | 0.150 x 0.120 x 1.600 | 0.15 x 0.12 x 1.60 | 120 | black 1E1B19 | blank | PASS | Three fishing rods in a walnut stand: `way` (carbon, mapped to palette black 1E1B19) tapered blanks with steel guides, kraft cork handles, steel reels facing -Y, red rod band. |
| generator | 0.600 x 0.450 x 0.500 | 0.60 x 0.45 x 0.50 | 111 | black 1E1B19 | fuel_tank, alternator | PASS | Portable petrol generator: steel tube frame, `way` (black) fuel tank and alternator housing, dark engine, grey recoil starter, cream front control panel with dark sockets and red switch. |
| coat_rack_office | 0.600 x 0.100 x 0.200 | 0.60 x 0.10 x 0.20 | 196 | oak C68B59 | backboard | PASS | Wall coat rack: `way` (oak) backboard (back toward +Y), five dark double hooks, steel screws, red scarf with cream stripes on one hook. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is pegboard -2.4% in depth (a 4 cm deep wall piece); all others 1.5% or less, see `_build/art/fit_log.json`. None of the 10 were skipped. Colour mapping: step_ladder first colour-way `aluminium` -> palette steel C9CED3; fishing_rods `carbon` -> palette black 1E1B19. All other first colour-ways are palette names.
