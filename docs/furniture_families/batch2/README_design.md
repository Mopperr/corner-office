# Corner Office catalogue families, batch2: Design Specialist share

Created by Andrew's Helpers (Grok Bots)

Ten `hh_cat_<family_id>.glb` files for the PR #21 catalogue hook (see `../FAMILIES.md` (a)). Add-only: no repo touched, nothing pushed. Art Specialist's files in this folder were not edited.

Spec: plain variant's w x d x h from `../families.csv` in metres; origin at bottom centre; front toward -Y in Blender (+Z in Godot, exported Y-up); bevelled boxes, 18-segment cylinders, 16x10 spheres; flat matte Principled colour (roughness 0.82, metallic 0, no textures); palette colours only (FAMILIES.md (b)); the recolourable surface uses a material named exactly `way`; meshes named body/seat/cushion/top/leg/etc.

Builders: new, in `batch1/_build/design/build_families_design.py` (helpers box/cyl/sphere/torus/legs4/fit_and_centre imported read-only from Art's `batch1/_build/art/build_families.py`).
Colour-way on `way` = first colour-way in families.csv (as Art does): bean_bag blue, coffee_table_v glass (the top is `way`; frame fixed oak), cot oak, clothes_rail black (frame), bedroom_chair oak, footstool blue, picture_v black (frame), wall_mirror black (frame), tall_bookcase oak (carcass), trunk_v leather.
Colour-way names that are not palette keys are mapped: leather -> walnut 6B4A3A, gilt -> brass C9A24E, tin -> steel C9CED3 (plus Art's painted white -> white, painted sage -> sage, tan/wicker -> kraft). Copper is never used (clothes_rail has a copper colour-way in the CSV; the game tints `way` itself).

- copper → brass (C9A24E) (clothes_rail) (Boss decision, 28 Oct 2026: alias added in the build scripts from batch 10 onward; documentation only, no GLB rebuilt — the baked `way` colour does not use copper.)
picture_v and wall_mirror are hang-mount: same origin rule (bottom centre), face at -Y, back flush toward +Y (wall). Materials capped at 7 per GLB (hh_ GLBs keep up to 7 in game).

## Files, sizes and QA (10 / 10 pass.)

GLB axes: w = x, h = y, d = z.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_bean_bag.glb | 35 | 0.800 x 0.800 x 0.500 | 0.80 x 0.80 x 0.50 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1728 | n/a | PASS |
| hh_cat_coffee_table_v.glb | 72 | 1.000 x 0.550 x 0.420 | 1.00 x 0.55 x 0.42 | 0.0000 | 0.000 / 0.000 | 6 | yes | 1292 | n/a | PASS |
| hh_cat_cot.glb | 222 | 1.200 x 0.650 x 0.900 | 1.20 x 0.65 x 0.90 | 0.0000 | 0.000 / 0.000 | 4 | yes | 5040 | n/a | PASS |
| hh_cat_clothes_rail.glb | 193 | 1.000 x 0.450 x 1.500 | 1.00 x 0.45 x 1.50 | 0.0000 | 0.000 / 0.000 | 7 | yes | 3996 | n/a | PASS |
| hh_cat_bedroom_chair.glb | 80 | 0.500 x 0.500 x 0.850 | 0.50 x 0.50 x 0.85 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1512 | n/a | PASS |
| hh_cat_footstool.glb | 73 | 0.500 x 0.400 x 0.380 | 0.50 x 0.40 x 0.38 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2504 | n/a | PASS |
| hh_cat_picture_v.glb | 36 | 0.600 x 0.040 x 0.450 | 0.60 x 0.04 x 0.45 | 0.0000 | 0.000 / 0.000 | 7 | yes | 560 | n/a | PASS |
| hh_cat_wall_mirror.glb | 29 | 0.700 x 0.040 x 0.500 | 0.70 x 0.04 x 0.50 | 0.0000 | 0.000 / 0.000 | 3 | yes | 468 | n/a | PASS |
| hh_cat_tall_bookcase.glb | 512 | 0.900 x 0.320 x 1.900 | 0.90 x 0.32 x 1.90 | 0.0000 | 0.000 / 0.000 | 7 | yes | 9800 | n/a | PASS |
| hh_cat_trunk_v.glb | 87 | 0.900 x 0.500 x 0.500 | 0.90 x 0.50 x 0.50 | 0.0000 | 0.000 / 0.000 | 4 | yes | 2048 | ok | PASS |


Full QA: `batch1/_build/design/QA_batch2.md` (script `batch1/_build/design/qa_batch1.py`). Contact sheet: `batch2_contact_design.png`.

## Part rename (28 Oct 2026, Boss-approved, props.gd texture hooks)
- clothes_rail: `box` → `storage_box` (the three coloured storage boxes on the base shelf; was the `box → cardboard` hook).
- tall_bookcase: `box` → `storage_box` (the mustard storage box on the bottom shelf; was the `box → cardboard` hook).
- The game's `props.gd` applies textures by part name (`PART_TEXTURES`; name lower-cased, trailing digits/dots stripped), so these names picked up the wrong texture. The new names are not hooks.
- Only the renamed GLBs were rebuilt. Diffed against the pre-rename backups: bounding box, per-part geometry, materials and the `way` colour are identical; only the node names changed. QA re-run: 10 / 10 pass.
- `tall_bookcase` still has a part `top` (its top board, `top → oak_floor`); not renamed, as it is a real top.

## Rebuild

```
cd batch1/_build/design
~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design.py -- batch2
~/opt/blender-4.2.3-linux-x64/blender -b -P render_design.py -- batch2
python3 contact_sheet_design.py batch2
python3 qa_batch1.py /workspace/game/pr21-new/families/batch2 QA_batch2.md
```
