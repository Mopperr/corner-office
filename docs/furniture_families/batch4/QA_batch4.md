# QA: batch4

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

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

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

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
