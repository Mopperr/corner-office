# Corner Office catalogue families, batch5: Design Specialist share

Created by Andrew's Helpers (Grok Bots)

Ten `hh_cat_<family_id>.glb` files (vis_rank 81-90 in `../families.csv`): school_desk, sawhorse, tray, towel_rail_bath, office_poster, sideboard, cushion_set, tree_box, utensil_jar, stand_mixer. Art Specialist's ten batch-5 families and files in this folder (_build/, their glbs, batch5_contact_art.png, any README.md) were not touched. Add-only; nothing pushed.

Spec: plain variant's w x d x h from families.csv in metres; origin at bottom centre; front toward -Y in Blender (+Z in Godot, exported Y-up); procedural bevelled boxes, cylinders, spheres, tori, lathes (jar, mixer head and bowl) and a bulging pillow mesh (cushions); flat matte Principled (roughness 0.82, metallic 0, no textures); palette colours only (FAMILIES.md (b)); recolourable surface = material named exactly `way`; at most 7 materials; each file < 1 MB.

## Colour-way on `way` (first colour-way in the CSV) and mappings

| family | first colour-way | `way` colour | what is `way` |
|---|---|---|---|
| school_desk | oak | oak C68B59 | book box, lift lid, pen tray, bench seat and back rail |
| sawhorse | oak | oak C68B59 | beam, legs, braces, stretcher |
| tray | oak | oak C68B59 | base, rims, handle ends |
| towel_rail_bath | black | black 1E1B19 | bar, end caps, arms, wall plates |
| office_poster | black | black 1E1B19 | frame |
| sideboard | oak | oak C68B59 | carcass, top, doors, drawers (walnut legs, brass handles fixed) |
| cushion_set | blue | blue 4A6FA5 | back-left cushion (mustard and cream cushions fixed) |
| tree_box | green | green 5E7B52 | planter box (hedge is a separate fixed `green`/`sage` material) |
| utensil_jar | blue | blue 4A6FA5 | jar |
| stand_mixer | blue | blue 4A6FA5 | base, column, head (steel bowl, beater, hub) |

Every first colour-way in batch 5 is a palette key, so no mapping was needed for anything baked. Later (not baked; the game tints `way`) colour-ways use the existing aliases: painted white -> white, painted sage -> sage (school_desk, tray, sideboard). One later colour-way has no palette match: towel_rail_bath **copper** (copper B87333 is not allowed); I added no alias for it. If one is wanted, brass C9A24E is the nearest allowed metal.

- copper → brass (C9A24E) (towel_rail_bath) (Boss decision, 28 Oct 2026: alias added in the build scripts from batch 10 onward; documentation only, no GLB rebuilt — the baked `way` colour does not use copper.)

## Design notes
- school_desk: classic combined pupil desk. Lift lid hinged at the back (brass hinges), propped open 14 degrees to show the dark inside of the book box; fixed pen tray with groove and brass inkwell (the CSV cylinder); bench seat and low back rail in front (-Y); dark cast-iron side frames with floor runners.
- sawhorse: 0.09 m beam, 4 splayed legs (A-frame at each end), cross braces, a long stretcher with struts, steel brackets.
- tray: base, low rims, raised ends with real cut-out handle slots; a white plate and a terracotta napkin on it. **No cup**: the CSV height (0.05 m) is too low for one.
- towel_rail_bath: hang-mount, wall at +Y; round bar on two stand-off arms with tall wall plates and steel screws; origin bottom centre like the other hang items.
- office_poster: hang-mount, glass/print face at -Y; `way` frame, cream mount, title, bar chart (blue/teal/mustard), mustard trend line and caption lines (plain variant; map/motivational not built).
- sideboard: left door, 3 drawers, right door, brass handles, top with overhang, tapered walnut legs, shadow gap.
- cushion_set: 3 upright cushions leaning back (blue `way`, mustard, smaller cream in front), pinched seams and centre buttons.
- tree_box: long planked planter (seams, corner posts), soil, low clipped hedge (rounded block plus irregular sage/green clumps) on short trunks.
- utensil_jar: blue crock with cream rim and bands, wooden spoon, steel whisk (3 wire loops), dark spatula, steel ladle.
- stand_mixer: foot plate, rear column, lathed tilt head facing -Y with steel hub cap and speed lever, steel bowl with handle on a clamp plate, flat beater into the bowl.
- Fixes from the first build and contact sheet:
  - sideboard: handles stuck out (depth 0.471), so the carcass and fronts were moved back.
  - cushion_set: too wide and too short (0.485 x 0.281), so the cushions were resized.
  - tree_box: the hedge overhung the box ends (1.237), so it was shortened. Uniform hedge balls looked like cabbages, so the clumps now vary.
  - utensil_jar: a flat cream label stuck out sideways, so it was replaced by wrap-around bands. The spatula blade was hidden behind the spoon, so it was moved.

## Files, sizes and QA (10 / 10 pass)

GLB axes: w = x, h = y, d = z. No front-only parts in this batch (front column n/a).

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_school_desk.glb | 80 | 0.600 x 0.450 x 0.700 | 0.60 x 0.45 x 0.70 | 0.0000 | 0.000 / 0.000 | 3 | yes | 1480 | n/a | PASS |
| hh_cat_sawhorse.glb | 81 | 0.900 x 0.500 x 0.750 | 0.90 x 0.50 x 0.75 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1472 | n/a | PASS |
| hh_cat_tray.glb | 89 | 0.400 x 0.280 x 0.050 | 0.40 x 0.28 x 0.05 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1684 | n/a | PASS |
| hh_cat_towel_rail_bath.glb | 42 | 0.600 x 0.100 x 0.120 | 0.60 x 0.10 x 0.12 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1132 | n/a | PASS |
| hh_cat_office_poster.glb | 46 | 0.500 x 0.030 x 0.700 | 0.50 x 0.03 x 0.70 | 0.0000 | 0.000 / 0.000 | 7 | yes | 660 | n/a | PASS |
| hh_cat_sideboard.glb | 101 | 1.400 x 0.450 x 0.800 | 1.40 x 0.45 x 0.80 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1868 | n/a | PASS |
| hh_cat_cushion_set.glb | 57 | 0.400 x 0.200 x 0.300 | 0.40 x 0.20 x 0.30 | 0.0000 | 0.000 / 0.000 | 4 | yes | 3216 | n/a | PASS |
| hh_cat_tree_box.glb | 144 | 1.200 x 0.350 x 0.350 | 1.20 x 0.35 x 0.35 | 0.0000 | 0.000 / 0.000 | 5 | yes | 5268 | n/a | PASS |
| hh_cat_utensil_jar.glb | 69 | 0.120 x 0.120 x 0.300 | 0.12 x 0.12 x 0.30 | 0.0000 | 0.000 / 0.000 | 5 | yes | 3156 | n/a | PASS |
| hh_cat_stand_mixer.glb | 86 | 0.220 x 0.340 x 0.340 | 0.22 x 0.34 x 0.34 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2176 | n/a | PASS |

Materials (sRGB hex):

- `hh_cat_school_desk.glb`: way=C68B59, dark=2B2622, brass=C9A24E
- `hh_cat_sawhorse.glb`: way=C68B59, steel=C9CED3
- `hh_cat_tray.glb`: way=C68B59, white=EAE6DC, cream=F4F1EA, terracotta=D9765F
- `hh_cat_towel_rail_bath.glb`: way=1E1B19, steel=C9CED3
- `hh_cat_office_poster.glb`: way=1E1B19, cream=F4F1EA, night=3E3A4F, grey=8E8276, blue=4A6FA5, teal=4F8A8B, mustard=E6B655
- `hh_cat_sideboard.glb`: way=C68B59, walnut=6B4A3A, brass=C9A24E, dark=2B2622
- `hh_cat_cushion_set.glb`: way=4A6FA5, dark=2B2622, mustard=E6B655, cream=F4F1EA
- `hh_cat_tree_box.glb`: way=5E7B52, dark=2B2622, walnut=6B4A3A, green=5E7B52, sage=8FA882
- `hh_cat_utensil_jar.glb`: way=4A6FA5, cream=F4F1EA, dark=2B2622, oak=C68B59, steel=C9CED3
- `hh_cat_stand_mixer.glb`: way=4A6FA5, steel=C9CED3, dark=2B2622

Full QA: `QA_batch5.md` (script `batch1/_build/design/qa_batch1.py`). Contact sheet: `batch5_contact_design.png`.

## Part rename (28 Oct 2026, from Art's validation)
- tree_box: mesh part `trunk` was renamed to `tree_trunk` (the hedge's three short walnut trunks). The game's `props.gd` applies textures by part name (`PART_TEXTURES`, name lower-cased with trailing digits/dots stripped), and `trunk` is a texture hook (trunk → leather). The change is in `build_families_design_b5.py`; only `hh_cat_tree_box.glb` was rebuilt.
- Checked against the previous GLB: bounding box, per-part geometry and materials are identical; only the three node names changed. QA re-run: PASS.
- tree_box: `soil` → `planter_soil` (28 Oct 2026, Boss-approved; was the `soil → concrete` hook). Only tree_box rebuilt; diffed against the backup: bbox, geometry, materials and `way` identical. QA re-run: 10 / 10 pass.
- Not renamed: sideboard has `top` (a real tabletop, `top → oak_floor`); cushion_set has `cushion` (intended, fabric_linen).

## Rebuild

```
cd batch1/_build/design
~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b5.py
~/opt/blender-4.2.3-linux-x64/blender -b -P render_design.py -- batch5
python3 contact_sheet_design.py batch5
python3 qa_batch1.py /workspace/game/pr21-new/families/batch5 /workspace/game/pr21-new/families/batch5/QA_batch5.md school_desk sawhorse tray towel_rail_bath office_poster sideboard cushion_set tree_box utensil_jar stand_mixer
```
