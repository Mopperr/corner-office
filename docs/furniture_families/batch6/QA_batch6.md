# QA: batch6

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

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

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

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
