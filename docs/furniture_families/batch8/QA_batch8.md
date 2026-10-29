# QA: batch8

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_loo_roll.glb | 79 | 0.120 x 0.120 x 0.330 | 0.12 x 0.12 x 0.33 | 0.0000 | 0.000 / 0.000 | 4 | yes | 3520 | n/a | PASS |
| hh_cat_medicine_cabinet.glb | 117 | 0.400 x 0.140 x 0.500 | 0.40 x 0.14 x 0.50 | 0.0000 | 0.000 / 0.000 | 6 | yes | 2560 | n/a | PASS |
| hh_cat_bath_caddy.glb | 237 | 0.700 x 0.160 x 0.100 | 0.70 x 0.16 x 0.10 | 0.0000 | 0.000 / 0.000 | 7 | yes | 4528 | n/a | PASS |
| hh_cat_string_lights.glb | 216 | 0.900 x 0.060 x 0.200 | 0.90 x 0.06 x 0.20 | 0.0000 | 0.000 / 0.000 | 6 | yes | 5900 | n/a | PASS |
| hh_cat_console.glb | 93 | 0.300 x 0.240 x 0.080 | 0.30 x 0.24 x 0.08 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2192 | n/a | PASS |
| hh_cat_chess_set.glb | 332 | 0.340 x 0.340 x 0.080 | 0.34 x 0.34 x 0.08 | 0.0000 | 0.000 / 0.000 | 5 | yes | 14664 | n/a | PASS |
| hh_cat_trophy.glb | 85 | 0.140 x 0.140 x 0.300 | 0.14 x 0.14 x 0.30 | 0.0000 | 0.000 / 0.000 | 4 | yes | 2780 | n/a | PASS |
| hh_cat_old_lamp.glb | 106 | 0.260 x 0.260 x 0.500 | 0.26 x 0.26 x 0.50 | 0.0000 | 0.000 / 0.000 | 5 | yes | 5440 | n/a | PASS |
| hh_cat_model_ship.glb | 185 | 0.500 x 0.140 x 0.450 | 0.50 x 0.14 x 0.45 | 0.0000 | 0.000 / 0.000 | 6 | yes | 3074 | n/a | PASS |
| hh_cat_bucket.glb | 93 | 0.300 x 0.300 x 0.300 | 0.30 x 0.30 x 0.30 | 0.0000 | 0.000 / 0.000 | 3 | yes | 3492 | n/a | PASS |

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_loo_roll.glb`: way=EAE6DC, kraft=C9A070, dark=2B2622, card=E7DCC6
- `hh_cat_medicine_cabinet.glb`: way=C68B59, white=EAE6DC, red=B6453F, glass=BFD6DA, steel=C9CED3, teal=4F8A8B
- `hh_cat_bath_caddy.glb`: way=C68B59, dark=2B2622, blue=4A6FA5, white=EAE6DC, sage=8FA882, steel=C9CED3, mustard=E6B655
- `hh_cat_string_lights.glb`: steel=C9CED3, dark=2B2622, way=E6B655, red=B6453F, green=5E7B52, blue=4A6FA5
- `hh_cat_console.glb`: way=1E1B19, dark=2B2622, blue=4A6FA5, white=EAE6DC, grey=8E8276, green=5E7B52, red=B6453F
- `hh_cat_chess_set.glb`: way=C68B59, pine=D9B98A, walnut=6B4A3A, cream=F4F1EA, dark=2B2622
- `hh_cat_trophy.glb`: walnut=6B4A3A, brass=C9A24E, dark=2B2622, way=D9765F
- `hh_cat_old_lamp.glb`: brass=C9A24E, way=4A6FA5, white=EAE6DC, glass=BFD6DA, dark=2B2622
- `hh_cat_model_ship.glb`: way=C68B59, pine=D9B98A, dark=2B2622, walnut=6B4A3A, cream=F4F1EA, red=B6453F
- `hh_cat_bucket.glb`: way=4A6FA5, steel=C9CED3, dark=2B2622
