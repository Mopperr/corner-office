# QA: batch9

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_picture_stack.glb | 150 | 0.500 x 0.200 x 0.600 | 0.50 x 0.20 x 0.60 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2764 | n/a | PASS |
| hh_cat_gramophone.glb | 143 | 0.400 x 0.400 x 0.600 | 0.40 x 0.40 x 0.60 | 0.0000 | 0.000 / 0.000 | 7 | yes | 4480 | n/a | PASS |
| hh_cat_dartboard.glb | 380 | 0.450 x 0.050 x 0.450 | 0.45 x 0.05 x 0.45 | 0.0000 | 0.000 / 0.000 | 6 | yes | 9312 | n/a | PASS |
| hh_cat_bird_cage.glb | 241 | 0.350 x 0.350 x 0.550 | 0.35 x 0.35 x 0.55 | 0.0000 | 0.000 / 0.000 | 6 | yes | 7404 | n/a | PASS |
| hh_cat_vinyl_crate.glb | 198 | 0.400 x 0.360 x 0.360 | 0.40 x 0.36 x 0.36 | 0.0000 | 0.000 / 0.000 | 6 | yes | 3796 | n/a | PASS |
| hh_cat_sewing_machine.glb | 94 | 0.420 x 0.200 x 0.300 | 0.42 x 0.20 x 0.30 | 0.0000 | 0.000 / 0.000 | 7 | yes | 1672 | n/a | PASS |
| hh_cat_tool_box_v.glb | 95 | 0.450 x 0.220 x 0.220 | 0.45 x 0.22 x 0.22 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1748 | ok | PASS |
| hh_cat_paint_cans.glb | 145 | 0.400 x 0.220 x 0.200 | 0.40 x 0.22 x 0.20 | 0.0000 | 0.000 / 0.000 | 5 | yes | 3704 | n/a | PASS |
| hh_cat_flower_pot_v.glb | 356 | 0.300 x 0.300 x 0.260 | 0.30 x 0.30 x 0.26 | 0.0000 | 0.000 / 0.000 | 5 | yes | 21528 | n/a | PASS |
| hh_cat_spades.glb | 83 | 0.200 x 0.100 x 1.100 | 0.20 x 0.10 x 1.10 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1540 | n/a | PASS |

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_picture_stack.glb`: way=C9A24E, cream=F4F1EA, blue=4A6FA5, green=5E7B52, mustard=E6B655, kraft=C9A070, steel=C9CED3
- `hh_cat_gramophone.glb`: way=C68B59, dark=2B2622, black=1E1B19, red=B6453F, steel=C9CED3, brass=C9A24E, walnut=6B4A3A
- `hh_cat_dartboard.glb`: way=1E1B19, dark=2B2622, red=B6453F, cream=F4F1EA, green=5E7B52, steel=C9CED3
- `hh_cat_bird_cage.glb`: way=1E1B19, kraft=C9A070, white=EAE6DC, green=5E7B52, mustard=E6B655, dark=2B2622
- `hh_cat_vinyl_crate.glb`: way=B6453F, black=1E1B19, blue=4A6FA5, cream=F4F1EA, mustard=E6B655, teal=4F8A8B
- `hh_cat_sewing_machine.glb`: walnut=6B4A3A, way=1E1B19, brass=C9A24E, steel=C9CED3, dark=2B2622, red=B6453F, oak=C68B59
- `hh_cat_tool_box_v.glb`: way=1E1B19, steel=C9CED3, dark=2B2622, oak=C68B59, red=B6453F
- `hh_cat_paint_cans.glb`: steel=C9CED3, cream=F4F1EA, way=4A6FA5, dark=2B2622, oak=C68B59
- `hh_cat_flower_pot_v.glb`: way=F4F1EA, dark=2B2622, green=5E7B52, rose=E8B4A8, mustard=E6B655
- `hh_cat_spades.glb`: steel=C9CED3, way=C68B59, dark=2B2622, kraft=C9A070
