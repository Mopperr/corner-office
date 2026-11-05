# QA: batch2

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

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

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_bean_bag.glb`: way=4A6FA5, cream=F4F1EA
- `hh_cat_coffee_table_v.glb`: oak=C68B59, way=BFD6DA, blue=4A6FA5, mustard=E6B655, rose=E8B4A8, kraft=C9A070
- `hh_cat_cot.glb`: way=C68B59, cream=F4F1EA, rose=E8B4A8, white=EAE6DC
- `hh_cat_clothes_rail.glb`: way=1E1B19, oak=C68B59, mustard=E6B655, sage=8FA882, terracotta=D9765F, steel=C9CED3, cream=F4F1EA
- `hh_cat_bedroom_chair.glb`: way=C68B59, rose=E8B4A8
- `hh_cat_footstool.glb`: way=4A6FA5, cream=F4F1EA, walnut=6B4A3A
- `hh_cat_picture_v.glb`: way=1E1B19, cream=F4F1EA, blue=4A6FA5, green=5E7B52, sage=8FA882, mustard=E6B655, terracotta=D9765F
- `hh_cat_wall_mirror.glb`: way=1E1B19, glass=BFD6DA, white=EAE6DC
- `hh_cat_tall_bookcase.glb`: way=C68B59, blue=4A6FA5, mustard=E6B655, terracotta=D9765F, sage=8FA882, night=3E3A4F, cream=F4F1EA
- `hh_cat_trunk_v.glb`: way=6B4A3A, oak=C68B59, brass=C9A24E, dark=2B2622
