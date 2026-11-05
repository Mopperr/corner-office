# Corner Office catalogue families, batch6: Design Specialist share

Created by Andrew's Helpers (Grok Bots)

Ten `hh_cat_<family_id>.glb` files (vis_rank 101-110 in `../families.csv`): whiteboard, cork_board, fruit_bowl, blender, toothbrush_set, soap_dish, hair_dryer, jewellery_box, hangers, dollhouse. I did not touch Art Specialist's ten batch-6 families or any of their files in this folder (_build/, their glbs, batch6_contact_art.png, any README.md). Add-only; nothing pushed.

Spec: plain variant's w x d x h from families.csv in metres; origin at bottom centre; front toward -Y in Blender (+Z in Godot, exported Y-up); built procedurally from bevelled boxes, cylinders, spheres, tori, arc bars, prisms and lathes (bowl, jug, cup, dish, dryer barrel); flat matte Principled (roughness 0.82, metallic 0, no textures); palette colours only (FAMILIES.md (b)); the recolourable surface is the material named exactly `way`; at most 7 materials; each file < 1 MB.

## Colour-way on `way` (first colour-way in the CSV) and mappings

| family | first colour-way | `way` colour | what is `way` |
|---|---|---|---|
| whiteboard | aluminium | **steel C9CED3** (mapped) | frame and marker tray |
| cork_board | oak | oak C68B59 | frame |
| fruit_bowl | blue | blue 4A6FA5 | bowl (cream rim fixed) |
| blender | blue | blue 4A6FA5 | motor base |
| toothbrush_set | blue | blue 4A6FA5 | cup |
| soap_dish | blue | blue 4A6FA5 | dish |
| hair_dryer | blue | blue 4A6FA5 | barrel and handle |
| jewellery_box | oak | oak C68B59 | box body and lid |
| hangers | oak | oak C68B59 | the three wooden shoulder bars |
| dollhouse | blue | blue 4A6FA5 | plinth, side walls, window bars |

Mappings:
- **whiteboard: aluminium is not in the palette.** I mapped it to steel C9CED3 (the nearest allowed metal) and added the alias `aluminium -> steel`.
- Later colour-ways aren't baked (the game tints `way`); the new aliases are in `build_families_design_b6.py`: jewellery_box **velvet rose -> rose E8B4A8**, hangers **velvet -> plum 6E4B6E** (I assumed velvet hangers are a deep plum flock) and **wire -> steel C9CED3**. Existing aliases cover the rest: painted white -> white (jewellery_box), black/oak/pine/walnut/mustard/rose/sage/terracotta are palette keys.

## Design notes
- whiteboard: hang-mount, wall at +Y, writing face at -Y; origin at bottom centre like the other hang items (the marker tray sits on the bottom edge and projects toward -Y within the 0.04 m depth). It has a white surface, a steel frame, three markers with caps (blue, red, dark), a dark eraser, and blue/red writing with a red zigzag "chart".
- cork_board: hang-mount, same origin rule. It has an oak frame, a kraft cork panel, and six slightly rotated notes (mustard, cream, rose, sage), with ruled lines on the cream notes and red push-pins.
- fruit_bowl: lathed blue bowl with a cream rim, apples (red, green), orange (terracotta), lemon (mustard), dark stems and a mustard banana.
- blender: blue motor base with a dark control panel, steel dial and cream buttons; dark collar; glass jug with a handle, a mustard smoothie inside and a steel blade; dark lid with a cap.
- toothbrush_set: blue tumbler with a cream rim, three leaning brushes (cream, sage, terracotta handles, white bristles), and a white paste tube with a terracotta cap.
- soap_dish: oval lathed blue dish with drainage ridges, a cream soap bar with a rose stamp.
- hair_dryer: blue barrel facing +X, a dark nozzle, a dark rear vent with steel rings, a raked handle with cream/dark switches, and a dark cord stub.
- jewellery_box: shallow open-top box at the front with rose velvet lining, a divider, ring slots (plum) with brass rings, a red gem, a white pearl necklace and a red brooch with a brass clasp. The lid is hinged at the back, opened 128 degrees, with rose lining and a glass mirror on its inside face.
- hangers: three oak coat hangers, slightly fanned, each with a steel trouser bar, a steel hook and a brass collar.
- dollhouse: open-front house on a plinth with blue side walls and white windows, a cream back wall, three oak floors (two storeys plus attic), cream partitions, white front trim, a red pitched roof, a cream back gable and a red chimney. Tiny furniture: kitchen and table, sage sofa on a rose rug, bed, bath and basin, attic toy box and ball.
- Fixes from the first build and the contact sheets:
  - jewellery_box: I rewrote the lid and mirror so they rotate as one about the back hinge (the mirror had been floating).
  - Several sizes were off, so I adjusted them:
    - cork_board was 0.032 deep because the pins stuck out, so I made the pins smaller.
    - blender was 0.149 deep, so I widened the base and pulled the handle in.
    - toothbrush_set was too narrow, so I widened the cup.
    - soap_dish was too short, so I made the soap bar taller.
    - hair_dryer was too short and too thin, so I lengthened the nozzle and set the barrel radius to d/2.
    - hangers were too shallow and too short, so I spread the hangers further apart and raised the hooks.
  - dollhouse: the roof slabs were rotated the wrong way and formed a V. I flipped the pitch sign and now it reads as a proper gable roof.
  - QA failures, now fixed:
    - cork_board and jewellery_box each had 8 materials. I made the pins and the gem red to get down to 7.
    - toothbrush_set had a separate `blue` cap with the same hex as `way`. I recoloured the cap terracotta.

## Files, sizes and QA (10 / 10 pass)

GLB axes: w = x, h = y, d = z. No front-only parts in this batch (front column n/a).

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_whiteboard.glb | 78 | 0.900 x 0.040 x 0.600 | 0.90 x 0.04 x 0.60 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1356 | n/a | PASS |
| hh_cat_cork_board.glb | 73 | 0.600 x 0.030 x 0.450 | 0.60 x 0.03 x 0.45 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2316 | n/a | PASS |
| hh_cat_fruit_bowl.glb | 71 | 0.280 x 0.280 x 0.140 | 0.28 x 0.28 x 0.14 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2968 | n/a | PASS |
| hh_cat_blender.glb | 86 | 0.160 x 0.160 x 0.400 | 0.16 x 0.16 x 0.40 | 0.0000 | 0.000 / 0.000 | 6 | yes | 1820 | n/a | PASS |
| hh_cat_toothbrush_set.glb | 69 | 0.080 x 0.080 x 0.200 | 0.08 x 0.08 x 0.20 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1636 | n/a | PASS |
| hh_cat_soap_dish.glb | 46 | 0.120 x 0.090 x 0.050 | 0.12 x 0.09 x 0.05 | 0.0000 | 0.000 / 0.000 | 3 | yes | 1104 | n/a | PASS |
| hh_cat_hair_dryer.glb | 63 | 0.220 x 0.080 x 0.200 | 0.22 x 0.08 x 0.20 | 0.0000 | 0.000 / 0.000 | 4 | yes | 2228 | n/a | PASS |
| hh_cat_jewellery_box.glb | 137 | 0.200 x 0.140 x 0.100 | 0.20 x 0.14 x 0.10 | 0.0000 | 0.000 / 0.000 | 7 | yes | 5580 | n/a | PASS |
| hh_cat_hangers.glb | 112 | 0.420 x 0.060 x 0.240 | 0.42 x 0.06 x 0.24 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2244 | n/a | PASS |
| hh_cat_dollhouse.glb | 122 | 0.600 x 0.350 x 0.600 | 0.60 x 0.35 x 0.60 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2264 | n/a | PASS |

Materials (sRGB hex):

- `hh_cat_whiteboard.glb`: white=EAE6DC, way=C9CED3, blue=4A6FA5, red=B6453F, dark=2B2622
- `hh_cat_cork_board.glb`: way=C68B59, kraft=C9A070, mustard=E6B655, red=B6453F, cream=F4F1EA, rose=E8B4A8, sage=8FA882
- `hh_cat_fruit_bowl.glb`: way=4A6FA5, cream=F4F1EA, red=B6453F, dark=2B2622, mustard=E6B655, terracotta=D9765F, green=5E7B52
- `hh_cat_blender.glb`: way=4A6FA5, dark=2B2622, steel=C9CED3, cream=F4F1EA, glass=BFD6DA, mustard=E6B655
- `hh_cat_toothbrush_set.glb`: way=4A6FA5, cream=F4F1EA, white=EAE6DC, sage=8FA882, terracotta=D9765F
- `hh_cat_soap_dish.glb`: way=4A6FA5, cream=F4F1EA, rose=E8B4A8
- `hh_cat_hair_dryer.glb`: way=4A6FA5, dark=2B2622, steel=C9CED3, cream=F4F1EA
- `hh_cat_jewellery_box.glb`: way=C68B59, rose=E8B4A8, plum=6E4B6E, brass=C9A24E, red=B6453F, white=EAE6DC, glass=BFD6DA
- `hh_cat_hangers.glb`: way=C68B59, steel=C9CED3, brass=C9A24E
- `hh_cat_dollhouse.glb`: way=4A6FA5, cream=F4F1EA, white=EAE6DC, oak=C68B59, red=B6453F, sage=8FA882, rose=E8B4A8

Full QA: `QA_batch6.md` (script `batch1/_build/design/qa_batch1.py`). Contact sheet: `batch6_contact_design.png`.

## Part rename (28 Oct 2026, Boss-approved, props.gd texture hooks)
- whiteboard: `tray` → `pen_ledge` (the four pen-ledge pieces (ledge, lip and two end caps); was the `tray → brushed_steel` hook).
- The game's `props.gd` applies textures by part name (`PART_TEXTURES`; name lower-cased, trailing digits/dots stripped), so these names picked up the wrong texture. The new names are not hooks.
- Only the renamed GLBs were rebuilt. Diffed against the pre-rename backups: bounding box, per-part geometry, materials and the `way` colour are identical; only the node names changed. QA re-run: 10 / 10 pass.

## Rebuild

```
cd batch1/_build/design
~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b6.py
~/opt/blender-4.2.3-linux-x64/blender -b -P render_design.py -- batch6
python3 contact_sheet_design.py batch6
cd ../../.. && python3 batch1/_build/design/qa_batch1.py batch6 batch6/QA_batch6.md whiteboard cork_board fruit_bowl blender toothbrush_set soap_dish hair_dryer jewellery_box hangers dollhouse
```
