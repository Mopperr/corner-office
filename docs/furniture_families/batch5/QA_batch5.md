# QA: batch5

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_school_desk.glb | 80 | 0.600 x 0.450 x 0.700 | 0.60 x 0.45 x 0.70 | 0.0000 | 0.000 / 0.000 | 3 | yes | 1480 | n/a | PASS |
| hh_cat_sawhorse.glb | 81 | 0.900 x 0.500 x 0.750 | 0.90 x 0.50 x 0.75 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1472 | n/a | PASS |
| hh_cat_tray.glb | 89 | 0.400 x 0.280 x 0.050 | 0.40 x 0.28 x 0.05 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1684 | n/a | PASS |
| hh_cat_towel_rail_bath.glb | 42 | 0.600 x 0.100 x 0.120 | 0.60 x 0.10 x 0.12 | 0.0000 | 0.000 / 0.000 | 2 | yes | 1132 | n/a | PASS |
| hh_cat_office_poster.glb | 46 | 0.500 x 0.030 x 0.700 | 0.50 x 0.03 x 0.70 | 0.0000 | 0.000 / 0.000 | 7 | yes | 660 | n/a | PASS |
| hh_cat_sideboard.glb | 101 | 1.400 x 0.450 x 0.800 | 1.40 x 0.45 x 0.80 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1868 | n/a | PASS |
| hh_cat_cushion_set.glb | 57 | 0.400 x 0.200 x 0.300 | 0.40 x 0.20 x 0.30 | 0.0000 | 0.000 / 0.000 | 4 | yes | 3216 | n/a | PASS |
| hh_cat_tree_box.glb | 144 | 1.200 x 0.350 x 0.350 | 1.20 x 0.35 x 0.35 | 0.0000 | 0.000 / 0.000 | 5 | yes | 5268 | n/a | PASS |
| hh_cat_utensil_jar.glb | 69 | 0.120 x 0.120 x 0.300 | 0.12 x 0.12 x 0.30 | 0.0000 | 0.000 / 0.000 | 5 | yes | 3156 | n/a | PASS |
| hh_cat_stand_mixer.glb | 86 | 0.220 x 0.340 x 0.340 | 0.22 x 0.34 x 0.34 | 0.0000 | 0.000 / 0.000 | 3 | yes | 2176 | n/a | PASS |

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_school_desk.glb`: way=C68B59, dark=2B2622, brass=C9A24E
- `hh_cat_sawhorse.glb`: way=C68B59, steel=C9CED3
- `hh_cat_tray.glb`: way=C68B59, white=EAE6DC, cream=F4F1EA, terracotta=D9765F
- `hh_cat_towel_rail_bath.glb`: way=1E1B19, steel=C9CED3
- `hh_cat_office_poster.glb`: way=1E1B19, cream=F4F1EA, night=3E3A4F, grey=8E8276, blue=4A6FA5, teal=4F8A8B, mustard=E6B655
- `hh_cat_sideboard.glb`: way=C68B59, walnut=6B4A3A, brass=C9A24E, dark=2B2622
- `hh_cat_cushion_set.glb`: way=4A6FA5, dark=2B2622, mustard=E6B655, cream=F4F1EA
- `hh_cat_tree_box.glb`: way=5E7B52, dark=2B2622, walnut=6B4A3A, green=5E7B52, sage=8FA882
- `hh_cat_utensil_jar.glb`: way=4A6FA5, cream=F4F1EA, dark=2B2622, oak=C68B59, steel=C9CED3
- `hh_cat_stand_mixer.glb`: way=4A6FA5, steel=C9CED3, dark=2B2622
