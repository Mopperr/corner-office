# QA: batch1

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

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

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_floor_lamp_v.glb`: dark=2B2622, brass=C9A24E, cream=F4F1EA, way=4A6FA5
- `hh_cat_kitchen_trolley.glb`: steel=C9CED3, black=1E1B19, way=C68B59, terracotta=D9765F, glass=BFD6DA, kraft=C9A070, mustard=E6B655
- `hh_cat_high_chair.glb`: way=C68B59, mustard=E6B655, cream=F4F1EA
- `hh_cat_laundry_hamper.glb`: way=F4F1EA, oak=C68B59, kraft=C9A070
- `hh_cat_bath_bin.glb`: way=F4F1EA, dark=2B2622, steel=C9CED3
- `hh_cat_side_table_v.glb`: way=C68B59
- `hh_cat_dressing_stool.glb`: way=4A6FA5, cream=F4F1EA, white=EAE6DC
- `hh_cat_armchair_v.glb`: way=4A6FA5, cream=F4F1EA, walnut=6B4A3A
- `hh_cat_coat_stand.glb`: way=C9A24E, dark=2B2622, night=3E3A4F, mustard=E6B655, red=B6453F, cream=F4F1EA, sage=8FA882
- `hh_cat_rocking_chair.glb`: way=C68B59, cream=F4F1EA
