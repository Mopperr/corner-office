# QA: batch3

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

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

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

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
