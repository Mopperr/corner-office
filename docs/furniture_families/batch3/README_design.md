# Corner Office catalogue families, batch3: Design Specialist share

Created by Andrew's Helpers (Grok Bots)

Ten `hh_cat_<family_id>.glb` files (first half of batch 3 by vis_rank in `../families.csv`): keyboard_piano, log_basket, suitcase_stack, mirror_oval, mug, plate_stack, saucepan, jug, storage_jar, towel_pile. Art Specialist's ten batch-3 families and files in this folder (README.md, VALIDATION.*, batch3_contact_art.png, _build/, their glbs) were not touched. Add-only; nothing pushed.

Spec: plain variant's w x d x h from families.csv in metres; origin at bottom centre; front toward -Y in Blender (+Z in Godot, exported Y-up); procedural bevelled boxes, 18-segment cylinders (24/32 for plates and the oval mirror), spheres, tori; flat matte Principled (roughness 0.82, metallic 0, no textures); palette colours only (FAMILIES.md (b)); recolourable surface = material named exactly `way`; at most 7 materials; each file < 1 MB.

## Colour-way on `way` (first colour-way in the CSV) and mappings

| family | first colour-way | `way` colour | what is `way` |
|---|---|---|---|
| keyboard_piano | black | black 1E1B19 | case and control panel |
| log_basket | canvas (not a palette key) | **card E7DCC6** | basket body |
| suitcase_stack | blue | blue 4A6FA5 | bottom case (middle mustard, top sage fixed) |
| mirror_oval | brass | brass C9A24E | oval frame |
| mug | blue | blue 4A6FA5 | body + handle |
| plate_stack | blue | blue 4A6FA5 | plates (white well on top plate) |
| saucepan | black | black 1E1B19 | pan body (steel lid, dark handle) |
| jug | blue | blue 4A6FA5 | body, spout, handle |
| storage_jar | blue | blue 4A6FA5 | jar body (oak lid, cream label) |
| towel_pile | blue | blue 4A6FA5 | towels 1 and 3 (cream, sage fixed) |

Mapping rules as batches 1-2 (painted white -> white, painted sage -> sage, tan/wicker -> kraft, leather -> walnut, gilt -> brass, tin -> steel) plus new: **canvas -> card E7DCC6**. Off-palette colour-ways that exist later in the CSV lists but are not first (so not baked): saucepan copper (copper B87333 is not allowed; the game tints `way`), log_basket wicker (-> kraft), suitcase_stack tan (-> kraft).

- copper → brass (C9A24E) (saucepan) (Boss decision, 28 Oct 2026: alias added in the build scripts from batch 10 onward; documentation only, no GLB rebuilt — the baked `way` colour does not use copper.)

## Design notes
- keyboard_piano: 36 white + 25 black keys as real geometry (5 octaves), end cheeks, raised back panel with speaker grilles, display, buttons, 2 knobs. 434 KB, 8.3k tris.
- suitcase_stack: 3 stacked cases (blue/mustard/sage), straps, handle, brass latches and corner caps on the -Y front.
- mirror_oval: hang-mount; bottom-centre origin like the others, glass face at -Y, back plate and hook toward +Y (wall).
- mug, saucepan, jug: to fit the square CSV footprint the handle (and the jug's spout) sit on a diagonal (handle front-right, +X/-Y); the open tops show tea (mug) and milk (jug).
- plate_stack: 5 plates with feet, flared rims and a white well on the top plate.
- Contact-sheet fixes: plates read as all-white -> rims made `way`; mug/jug tops read as closed lids -> liquid discs on top; saucepan/jug handles were foreshortened behind the body -> moved to the front-right; knob parts renamed so the QA front-only hint doesn't fire on centred knobs.

## Files, sizes and QA (10 / 10 pass)

GLB axes: w = x, h = y, d = z. Front check: `ok` where a front-only part (latch, label) exists; n/a otherwise.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_keyboard_piano.glb | 434 | 1.300 x 0.350 x 0.120 | 1.30 x 0.35 x 0.12 | 0.0000 | 0.000 / 0.000 | 5 | yes | 8344 | n/a | PASS |
| hh_cat_log_basket.glb | 95 | 0.450 x 0.350 x 0.400 | 0.45 x 0.35 x 0.40 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2208 | n/a | PASS |
| hh_cat_suitcase_stack.glb | 186 | 0.700 x 0.450 x 0.600 | 0.70 x 0.45 x 0.60 | 0.0000 | 0.000 / 0.000 | 6 | yes | 3564 | ok | PASS |
| hh_cat_mirror_oval.glb | 30 | 0.400 x 0.040 x 0.600 | 0.40 x 0.04 x 0.60 | 0.0000 | 0.000 / 0.000 | 4 | yes | 892 | n/a | PASS |
| hh_cat_mug.glb | 28 | 0.090 x 0.090 x 0.100 | 0.09 x 0.09 x 0.10 | 0.0000 | 0.000 / 0.000 | 3 | yes | 924 | n/a | PASS |
| hh_cat_plate_stack.glb | 71 | 0.260 x 0.260 x 0.090 | 0.26 x 0.26 x 0.09 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1856 | n/a | PASS |
| hh_cat_saucepan.glb | 51 | 0.220 x 0.220 x 0.140 | 0.22 x 0.22 x 0.14 | 0.0000 | 0.000 / 0.000 | 3 | yes | 1528 | n/a | PASS |
| hh_cat_jug.glb | 37 | 0.140 x 0.140 x 0.220 | 0.14 x 0.14 x 0.22 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1100 | n/a | PASS |
| hh_cat_storage_jar.glb | 36 | 0.140 x 0.140 x 0.240 | 0.14 x 0.14 x 0.24 | 0.0000 | 0.000 / 0.000 | 4 | yes | 844 | ok | PASS |
| hh_cat_towel_pile.glb | 78 | 0.400 x 0.300 x 0.240 | 0.40 x 0.30 x 0.24 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1472 | n/a | PASS |


Materials (sRGB hex):

- `hh_cat_keyboard_piano.glb`: way=1E1B19, white=EAE6DC, dark=2B2622, grey=8E8276, teal=4F8A8B
- `hh_cat_log_basket.glb`: way=E7DCC6, walnut=6B4A3A, pine=D9B98A
- `hh_cat_suitcase_stack.glb`: way=4A6FA5, dark=2B2622, walnut=6B4A3A, brass=C9A24E, mustard=E6B655, sage=8FA882
- `hh_cat_mirror_oval.glb`: dark=2B2622, way=C9A24E, glass=BFD6DA, white=EAE6DC
- `hh_cat_mug.glb`: way=4A6FA5, cream=F4F1EA, dark=2B2622
- `hh_cat_plate_stack.glb`: way=4A6FA5, white=EAE6DC
- `hh_cat_saucepan.glb`: way=1E1B19, steel=C9CED3, dark=2B2622
- `hh_cat_jug.glb`: way=4A6FA5, cream=F4F1EA
- `hh_cat_storage_jar.glb`: way=4A6FA5, oak=C68B59, cream=F4F1EA, dark=2B2622
- `hh_cat_towel_pile.glb`: way=4A6FA5, white=EAE6DC, cream=F4F1EA, sage=8FA882

Full QA: `QA_batch3.md` (script `batch1/_build/design/qa_batch1.py`). Contact sheet: `batch3_contact_design.png`.

## Rebuild

```
cd batch1/_build/design
~/opt/blender-4.2.3-linux-x64/blender -b -P build_families_design_b3.py
~/opt/blender-4.2.3-linux-x64/blender -b -P render_design.py -- batch3
python3 contact_sheet_design.py batch3
python3 qa_batch1.py /workspace/game/pr21-new/families/batch3 /workspace/game/pr21-new/families/batch3/QA_batch3.md keyboard_piano log_basket suitcase_stack mirror_oval mug plate_stack saucepan jug storage_jar towel_pile
```
