# Corner Office catalogue families, batch4: Design Specialist share

Created by Andrew's Helpers (Grok Bots)

Ten `hh_cat_<family_id>.glb` files (vis_rank 61-70 in `../families.csv`): poster, towel_rail, pram, skis, mannequin, planter_box, bowl_set, casserole, cookbooks, bath_plant. Art Specialist's ten batch-4 families and files in this folder (_build/, their glbs, and any README.md / batch4_contact_art.png) were not touched. Add-only; nothing pushed.

Spec: plain variant's w x d x h from families.csv in metres; origin at bottom centre; front toward -Y in Blender (+Z in Godot, exported Y-up); procedural bevelled boxes, cylinders, spheres, tori, arcs and a lathe (mannequin); flat matte Principled (roughness 0.82, metallic 0, no textures); palette colours only (FAMILIES.md (b)); recolourable surface = material named exactly `way`; at most 7 materials; each file < 1 MB.

## Colour-way on `way` (first colour-way in the CSV) and mappings

| family | first colour-way | `way` colour | what is `way` |
|---|---|---|---|
| poster | blue | blue 4A6FA5 | print background (frame dark, mount cream, scene mustard/sage/terracotta/night fixed) |
| towel_rail | blue | blue 4A6FA5 | towel |
| pram | blue | blue 4A6FA5 | bassinet body and hood |
| skis | blue | blue 4A6FA5 | both skis |
| mannequin | blue | blue 4A6FA5 | dress-form torso and neck |
| planter_box | black | black 1E1B19 | box posts and planks |
| bowl_set | blue | blue 4A6FA5 | 3 nested bowls |
| casserole | blue | blue 4A6FA5 | dish body, handles and lid |
| cookbooks | blue | blue 4A6FA5 | bottom book (mustard, terracotta, sage fixed) |
| bath_plant | blue | blue 4A6FA5 | pot |

Every first colour-way in batch 4 is a palette key, so no mapping was needed for anything baked. Off-palette colour-ways later in the CSV lists (not baked; the game tints `way`), new mappings added to the shared alias table: **navy -> night 3E3A4F** (pram), **linen -> cream F4F1EA** (mannequin). Earlier rules unchanged (painted white -> white, painted sage -> sage, tan/wicker -> kraft, leather -> walnut, gilt -> brass, tin -> steel, canvas -> card).

## Design notes
- poster, towel_rail: hang-mount; bottom-centre origin like the other hang items, face at -Y, wall side at +Y (towel_rail brackets touch the +Y face).
- pram: bassinet with dark opening, cream padded trim and a half-length cream blanket; quarter-round hood with closed sides over the handle end, open toward -X; steel push handle with dark grip, steel chassis, 4 dark wheels with steel hubs.
- skis: a pair standing upright (CSV h 1.7 m), tips curled toward the front, toe bindings with mustard levers, steel heel pieces, 2 dark straps holding the pair.
- mannequin: smooth lathed dress-form torso (oval cross-section) on a brass pole, walnut hub and 3 walnut splay legs, walnut neck cap.
- planter_box: black slatted box, walnut soil, green/sage plant clumps with rose and mustard flowers.
- bowl_set: 3 nested bowls with feet, cream rims and cream insides. casserole: dish, cream rim, loop handles along x, dome lid, cream knob. cookbooks: 4 slightly offset books with coloured covers, cream pages and spine labels at the front. bath_plant: tapered pot, soil, upright and arching leaves.
- Fixes from the first build/contact sheet: towel_rail depth 0.067 -> rail moved to fill 0.08; ski tip curl reduced (depth was 0.132); planter plants lowered (height was 0.433); mannequin torso was lumpy stacked spheres with a dark waist band -> one smooth lathed body; pram hood read as a thin flat lid and a white slab covered the whole bassinet -> closed-sided hood, open bassinet with rim trim and a half blanket.

## Files, sizes and QA (10 / 10 pass)

GLB axes: w = x, h = y, d = z. Front check: `ok` where a front-only part (label) exists; n/a otherwise.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_poster.glb | 37 | 0.500 x 0.020 x 0.700 | 0.50 x 0.02 x 0.70 | 0.0000 | 0.000 / 0.000 | 7 | yes | 596 | n/a | PASS |
| hh_cat_towel_rail.glb | 58 | 0.400 x 0.080 x 0.260 | 0.40 x 0.08 x 0.26 | 0.0000 | 0.000 / 0.000 | 3 | yes | 1448 | n/a | PASS |
| hh_cat_pram.glb | 163 | 0.900 x 0.500 x 1.000 | 0.90 x 0.50 x 1.00 | 0.0000 | 0.000 / 0.000 | 4 | yes | 4264 | n/a | PASS |
| hh_cat_skis.glb | 113 | 0.200 x 0.120 x 1.700 | 0.20 x 0.12 x 1.70 | 0.0000 | 0.000 / 0.000 | 5 | yes | 2056 | n/a | PASS |
| hh_cat_mannequin.glb | 66 | 0.420 x 0.300 x 1.500 | 0.42 x 0.30 x 1.50 | 0.0000 | 0.000 / 0.000 | 3 | yes | 1760 | n/a | PASS |
| hh_cat_planter_box.glb | 180 | 0.800 x 0.350 x 0.400 | 0.80 x 0.35 x 0.40 | 0.0000 | 0.000 / 0.000 | 6 | yes | 4980 | n/a | PASS |
| hh_cat_bowl_set.glb | 54 | 0.220 x 0.220 x 0.120 | 0.22 x 0.22 x 0.12 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1980 | n/a | PASS |
| hh_cat_casserole.glb | 50 | 0.300 x 0.240 x 0.160 | 0.30 x 0.24 x 0.16 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1528 | n/a | PASS |
| hh_cat_cookbooks.glb | 79 | 0.240 x 0.200 x 0.140 | 0.24 x 0.20 x 0.14 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1392 | ok | PASS |
| hh_cat_bath_plant.glb | 87 | 0.260 x 0.260 x 0.340 | 0.26 x 0.26 x 0.34 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1676 | n/a | PASS |

Materials (sRGB hex):

- `hh_cat_poster.glb`: dark=2B2622, cream=F4F1EA, way=4A6FA5, mustard=E6B655, sage=8FA882, terracotta=D9765F, night=3E3A4F
- `hh_cat_towel_rail.glb`: steel=C9CED3, way=4A6FA5, cream=F4F1EA
- `hh_cat_pram.glb`: way=4A6FA5, dark=2B2622, cream=F4F1EA, steel=C9CED3
- `hh_cat_skis.glb`: way=4A6FA5, white=EAE6DC, dark=2B2622, mustard=E6B655, steel=C9CED3
- `hh_cat_mannequin.glb`: way=4A6FA5, walnut=6B4A3A, brass=C9A24E
- `hh_cat_planter_box.glb`: walnut=6B4A3A, way=1E1B19, green=5E7B52, sage=8FA882, rose=E8B4A8, mustard=E6B655
- `hh_cat_bowl_set.glb`: way=4A6FA5, cream=F4F1EA
- `hh_cat_casserole.glb`: way=4A6FA5, cream=F4F1EA
- `hh_cat_cookbooks.glb`: way=4A6FA5, cream=F4F1EA, mustard=E6B655, terracotta=D9765F, sage=8FA882
- `hh_cat_bath_plant.glb`: way=4A6FA5, walnut=6B4A3A, sage=8FA882, green=5E7B52

Full QA: `QA_batch4.md` (script `batch1/_build/design/qa_batch1.py`). Contact sheet: `batch4_contact_design.png`.

## Part rename (28 Oct 2026, Boss-approved, props.gd texture hooks)
- planter_box: `soil` → `planter_soil` (the soil surface; was the `soil → concrete` hook).
- bath_plant: `soil` → `planter_soil` (the soil disc in the pot; was the `soil → concrete` hook).
- The game's `props.gd` applies textures by part name (`PART_TEXTURES`; name lower-cased, trailing digits/dots stripped), so these names picked up the wrong texture. The new names are not hooks.
- Only the renamed GLBs were rebuilt. Diffed against the pre-rename backups: bounding box, per-part geometry, materials and the `way` colour are identical; only the node names changed. QA re-run: 10 / 10 pass.
- Build-script fix: `bath_plant` in `build_families_design_b4.py` was missing its `pts = []` reset in the arching-leaf loop (NameError on rebuild). The line was restored; the rebuilt GLB is identical to the shipped one.

## Rebuild

```
cd batch1/_build/design
~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b4.py
~/opt/blender-4.2.3-linux-x64/blender -b -P render_design.py -- batch4
python3 contact_sheet_design.py batch4
python3 qa_batch1.py /workspace/game/pr21-new/families/batch4 /workspace/game/pr21-new/families/batch4/QA_batch4.md poster towel_rail pram skis mannequin planter_box bowl_set casserole cookbooks bath_plant
```
