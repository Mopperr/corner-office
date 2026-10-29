# Corner Office catalogue families - batch10 (art share)

Created by Andrew's Helpers (Grok Bots)

This folder is shared. The art share (this README, `VALIDATION.md` / `VALIDATION.json`, `FINAL_art.md`, `batch10_contact_art.png`, `_build/art/`) covers 12 of the 22 batch-10 families: coffee_machine_v, mug_tree, folder_stack, desk_fan, office_kettle, reception_sign, projector, office_speaker, stapler_set, dispatch_scale, globe_office, desk_calendar. The other 10 (axe_logs, desk_lamp, monitor, keyboard_mouse, printer, paper_tray, pen_pot, laptop, desk_phone, desk_tidy) are Design Specialist's, documented in `README_design.md`, `QA_batch10.md` and `batch10_contact_design.png`. STARRED: coffee_machine_v corresponds to the existing `coffee_machine` model and is built as a new `hh_cat_coffee_machine_v.glb`. It does not replace the existing file.

## Spec

- One GLB per family: `hh_cat_<family_id>.glb` (new, add-only; no existing `hh_` model is touched).
- Real size in metres = the plain variant's `typical_w/d/h` from `families.csv` (w = X, d = depth, h = height).
- Origin at the bottom centre of the bounding box; front faces -Y in Blender, which is +Z in Godot/glTF (Y-up export).
- Flat matte Principled materials (roughness 0.82, metallic 0), no textures, no UVs. Chunky bevelled low-poly style matching `build_household.py` (bevel 4-15 mm, 18-segment cylinders).
- Palette: the 23 CSV/FAMILIES.md colours only; never copper B87333. 3 to 7 materials per GLB (Props caps hh_ props at 7).
- The recolourable part(s) use a material named exactly `way`, set to the family's first CSV colour-way. Everything else uses fixed palette materials named after the palette key (e.g. `steel`, `cream`).
- Every GLB is under 1 MB. Built procedurally in Blender 4.2.3 headless; scripts in `_build/art/` (`build_families.py`, `render_contact.py`, `contact_sheet.py`, `validate.py`, `make_readme.py`).
- Contact sheet: `batch10_contact_art.png`. Validation: `VALIDATION.md` / `VALIDATION.json`.
- Mesh-name texture hooks in Props (`PART_TEXTURES`): parts named `top` get oak_floor, `cushion`/`towel` linen, `mat`/`rug` kilim, `soil` concrete, all tinted by the part colour. Names were chosen so this only hits parts where that look fits; no part is named `box`, `tray`, `top`, `cushion`, `towel`, `rug`, `mat`, `seat` or any other hook name (checked by validate.py), so none of these 12 pick up a triplanar texture.

Rebuild: `cd _build/art && ~/opt/blender-4.2.3-linux-x64/blender -b -P build_families.py && ~/opt/blender-4.2.3-linux-x64/blender -b -P render_contact.py && python3 contact_sheet.py && python3 validate.py && python3 make_readme.py`

## Families

| family_id | actual w x d x h (m) | CSV w x d x h (m) | KB | `way` colour | `way` part(s) | validation | notes |
|---|---|---|---|---|---|---|---|
| coffee_machine_v | 0.300 x 0.350 x 0.380 | 0.30 x 0.35 x 0.38 | 78 | black 1E1B19 | machine_base, machine_body, group_head | PASS | STARRED (existing `coffee_machine`). Espresso machine: `way` (black) base, body and group head. Steel portafilter with a dark handle toward -Y, steel drip grate, cup warmer and steam wand, glass water tank on the back, cream cup. |
| mug_tree | 0.220 x 0.220 x 0.340 | 0.22 x 0.22 x 0.34 | 57 | oak C68B59 | mug_tree_base, mug_tree_post, post_knob, peg | PASS | Mug tree: `way` (oak) base disc, post, knob and four angled pegs. Cream, terracotta, sage and blue mugs hang on the pegs. Round piece, so the front check is n/a. |
| folder_stack | 0.300 x 0.340 x 0.220 | 0.30 x 0.34 x 0.22 | 143 | blue 4A6FA5 | folder_cover, folder_spine | PASS | Stack of five ring binders lying flat and slightly askew. Covers and spines in `way` (blue), red, mustard, sage and grey, white paper block, cream spine labels facing -Y. |
| desk_fan | 0.300 x 0.140 x 0.380 | 0.30 x 0.14 x 0.38 | 117 | black 1E1B19 | fan_base, fan_stem, motor_housing, guard_front, guard_ring, guard_wire | PASS | Desk fan: `way` (black) oval base, stem, motor housing and wire guard (front ring `guard_front`, rear ring, 12 spokes). Three steel blades, steel badge, white speed knob. |
| office_kettle | 0.200 x 0.160 x 0.240 | 0.20 x 0.16 x 0.24 | 59 | blue 4A6FA5 | kettle_body, kettle_lid, spout | PASS | Cordless kettle: dark power base, `way` (blue) body and lid, glass water window at the front. Dark handle on +X with a white switch, spout on -X. |
| reception_sign | 0.400 x 0.080 x 0.200 | 0.40 x 0.08 x 0.20 | 352 | black 1E1B19 | plaque | PASS | Desk sign: `way` (black) plaque leaning back in a walnut base. 'RECEPTION' is spelled in brass pixel letters (3x5 bitmap font, one box per horizontal run). Steel corner standoffs, brass inlay strip on the base. |
| projector | 0.300 x 0.240 x 0.100 | 0.30 x 0.24 x 0.10 | 58 | black 1E1B19 | projector_body | PASS | Office projector: `way` (black) rounded body on dark feet, grey top panel, dark lens barrel with steel focus ring and glass lens at the front-left, dark vents, white buttons and a green power LED. |
| office_speaker | 0.200 x 0.200 x 0.060 | 0.20 x 0.20 x 0.06 | 25 | black 1E1B19 | speaker_body | PASS | Conference speakerphone: rounded-triangle `way` (black) body on a grey band, dark grille top, green LED bar on the front edge, white keys. |
| stapler_set | 0.240 x 0.120 x 0.080 | 0.24 x 0.12 x 0.08 | 50 | black 1E1B19 | stapler_arm, stapler_hinge, punch_lever | PASS | Stapler and hole punch: `way` (black) stapler arm on a steel base, grey punch with a black lever, steel posts and steel paper guide at the front, red staple pack (`staple_pack`, not `box`). |
| dispatch_scale | 0.300 x 0.300 x 0.120 | 0.30 x 0.30 x 0.12 | 48 | black 1E1B19 | scale_base, scale_console | PASS | Parcel scale: `way` (black) base and front console, teal display, white keys, steel weigh platform, kraft parcel with pine tape and a cream label. |
| globe_office | 0.260 x 0.260 x 0.360 | 0.26 x 0.26 x 0.36 | 90 | kraft C9A070 | globe | PASS | Desk globe: `way` sphere tilted 23 degrees with sage land patches, brass meridian, pivot and stem, dark round stand. The first colour-way is 'antique', which is not a palette name, so it is mapped to kraft C9A070. |
| desk_calendar | 0.180 x 0.100 x 0.140 | 0.18 x 0.10 x 0.14 | 68 | blue 4A6FA5 | calendar_header | PASS | Tent desk calendar: card A-frame, cream month page on the -Y face with a `way` (blue) header strip, dark date grid with one red marked date, steel rings along the top. |

Fit: every model was designed close to the CSV size. The largest stretch to the exact size is globe_office (+2.0% in depth, -1.9% in width); all others are 1.6% or less. See `_build/art/fit_log.json`. None of the 12 were skipped. Colour mapping: globe_office antique -> kraft C9A070.
