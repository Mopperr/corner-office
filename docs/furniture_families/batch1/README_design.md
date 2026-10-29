# Corner Office catalogue families, batch1: Design Specialist share

Created by Andrew's Helpers (Grok Bots)

Ten `hh_cat_<family_id>.glb` files for the PR #21 catalogue hook (see `../FAMILIES.md` (a)). Add-only: no repo touched, nothing pushed. Art Specialist's files in this folder were not edited.

Spec: plain variant's w x d x h from `../families.csv` in metres; origin at bottom centre; front toward -Y in Blender (+Z in Godot, exported Y-up); bevelled boxes, 18-segment cylinders, 16x10 spheres; flat matte Principled colour (roughness 0.82, metallic 0, no textures); palette colours only (FAMILIES.md (b)); the recolourable surface uses a material named exactly `way`; meshes named body/seat/cushion/top/leg/etc.

Builders: Art Specialist's draft builders for these 10 families in `_build/art/build_families.py` (imported read-only, not modified), with one design fix:
- `dressing_stool`: the draft's single stretcher floated mid-air at y=0 between the legs; replaced by an H-stretcher that meets the splayed legs (override in `build_families_design.py`).
Colour-way on `way` = first colour-way in families.csv (as Art does): floor_lamp_v blue, kitchen_trolley oak, high_chair oak, laundry_hamper cream, bath_bin cream, side_table_v oak, dressing_stool blue, armchair_v blue, coat_stand brass, rocking_chair oak.

## Files, sizes and QA (10 / 10 pass.)

GLB axes: w = x, h = y, d = z.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_floor_lamp_v.glb | 47 | 0.400 x 0.400 x 1.600 | 0.40 x 0.40 x 1.60 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1216 | ok | PASS |
| hh_cat_kitchen_trolley.glb | 142 | 0.700 x 0.450 x 0.850 | 0.70 x 0.45 x 0.85 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2708 | n/a | PASS |
| hh_cat_high_chair.glb | 111 | 0.500 x 0.550 x 0.950 | 0.50 x 0.55 x 0.95 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2052 | ok | PASS |
| hh_cat_laundry_hamper.glb | 67 | 0.420 x 0.420 x 0.600 | 0.42 x 0.42 x 0.60 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2932 | n/a | PASS |
| hh_cat_bath_bin.glb | 36 | 0.200 x 0.200 x 0.280 | 0.20 x 0.20 x 0.28 | 0.0000 | 0.000 / 0.000 | 3 | yes | 852 | ok | PASS |
| hh_cat_side_table_v.glb | 48 | 0.450 x 0.450 x 0.550 | 0.45 x 0.45 x 0.55 | 0.0000 | 0.000 / 0.000 | 1 | yes | 912 | n/a | PASS |
| hh_cat_dressing_stool.glb | 81 | 0.440 x 0.340 x 0.460 | 0.44 x 0.34 x 0.46 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2072 | n/a | PASS |
| hh_cat_armchair_v.glb | 109 | 0.850 x 0.850 x 0.900 | 0.85 x 0.85 x 0.90 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2088 | n/a | PASS |
| hh_cat_coat_stand.glb | 227 | 0.400 x 0.400 x 1.700 | 0.40 x 0.40 x 1.70 | 0.0000 | 0.000 / 0.000 | 7 | yes | 6348 | n/a | PASS |
| hh_cat_rocking_chair.glb | 145 | 0.600 x 0.800 x 1.000 | 0.60 x 0.80 x 1.00 | 0.0000 | 0.000 / 0.000 | 2 | yes | 2808 | n/a | PASS |


Full QA: `batch1/_build/design/QA_batch1.md` (script `batch1/_build/design/qa_batch1.py`). Contact sheet: `batch1_contact_design.png`.

## Rebuild

```
cd batch1/_build/design
~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design.py -- batch1
~/opt/blender-4.2.3-linux-x64/blender -b -P render_design.py -- batch1
python3 contact_sheet_design.py batch1
python3 qa_batch1.py /workspace/game/pr21-new/families/batch1 QA_batch1.md
```
