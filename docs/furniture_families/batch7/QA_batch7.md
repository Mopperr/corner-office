# QA: batch7

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_cake_stand.glb | 216 | 0.300 x 0.300 x 0.180 | 0.30 x 0.30 x 0.18 | 0.0000 | 0.000 / 0.000 | 6 | yes | 10184 | n/a | PASS |
| hh_cat_egg_box.glb | 125 | 0.200 x 0.140 x 0.120 | 0.20 x 0.14 x 0.12 | 0.0000 | 0.000 / 0.000 | 3 | yes | 4872 | n/a | PASS |
| hh_cat_bread_board.glb | 121 | 0.300 x 0.180 x 0.120 | 0.30 x 0.18 x 0.12 | 0.0000 | 0.000 / 0.000 | 5 | yes | 4752 | n/a | PASS |
| hh_cat_salt_pepper.glb | 99 | 0.100 x 0.050 x 0.100 | 0.10 x 0.05 x 0.10 | 0.0000 | 0.000 / 0.000 | 4 | yes | 5728 | n/a | PASS |
| hh_cat_cutlery_tray.glb | 172 | 0.340 x 0.260 x 0.050 | 0.34 x 0.26 x 0.05 | 0.0000 | 0.000 / 0.000 | 3 | yes | 4128 | n/a | PASS |
| hh_cat_bath_scales.glb | 69 | 0.300 x 0.300 x 0.040 | 0.30 x 0.30 x 0.04 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1372 | n/a | PASS |
| hh_cat_toiletries.glb | 199 | 0.260 x 0.180 x 0.200 | 0.26 x 0.18 x 0.20 | 0.0000 | 0.000 / 0.000 | 7 | yes | 4092 | n/a | PASS |
| hh_cat_candle_holder.glb | 67 | 0.200 x 0.100 x 0.260 | 0.20 x 0.10 x 0.26 | 0.0000 | 0.000 / 0.000 | 3 | yes | 3440 | n/a | PASS |
| hh_cat_aquarium.glb | 748 | 0.600 x 0.300 x 0.400 | 0.60 x 0.30 x 0.40 | 0.0000 | 0.000 / 0.000 | 7 | yes | 18000 | n/a | PASS |
| hh_cat_typewriter.glb | 438 | 0.360 x 0.340 x 0.220 | 0.36 x 0.34 x 0.22 | 0.0000 | 0.000 / 0.000 | 5 | yes | 15864 | n/a | PASS |

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_cake_stand.glb`: way=F4F1EA, brass=C9A24E, mustard=E6B655, white=EAE6DC, red=B6453F, rose=E8B4A8
- `hh_cat_egg_box.glb`: way=8FA882, cream=F4F1EA, kraft=C9A070
- `hh_cat_bread_board.glb`: way=C68B59, dark=2B2622, kraft=C9A070, cream=F4F1EA, steel=C9CED3
- `hh_cat_salt_pepper.glb`: way=F4F1EA, steel=C9CED3, dark=2B2622, grey=8E8276
- `hh_cat_cutlery_tray.glb`: way=C68B59, steel=C9CED3, dark=2B2622
- `hh_cat_bath_scales.glb`: grey=8E8276, way=1E1B19, steel=C9CED3, dark=2B2622, glass=BFD6DA
- `hh_cat_toiletries.glb`: way=8FA882, white=EAE6DC, steel=C9CED3, teal=4F8A8B, dark=2B2622, rose=E8B4A8, cream=F4F1EA
- `hh_cat_candle_holder.glb`: way=1E1B19, cream=F4F1EA, dark=2B2622
- `hh_cat_aquarium.glb`: way=1E1B19, glass=BFD6DA, kraft=C9A070, grey=8E8276, green=5E7B52, mustard=E6B655, terracotta=D9765F
- `hh_cat_typewriter.glb`: way=1E1B19, dark=2B2622, steel=C9CED3, cream=F4F1EA, white=EAE6DC
