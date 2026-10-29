# QA: batch10

Script: `batch1/_build/design/qa_batch1.py` (read-only). Tolerances: size 5%, min y 5 mm, centre 3 cm, roughness 0.82+-0.05, colour +-3/255 of palette.

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_axe_logs.glb | 94 | 0.400 x 0.400 x 0.400 | 0.40 x 0.40 x 0.40 | 0.0000 | 0.000 / 0.000 | 5 | yes | 3672 | n/a | PASS |
| hh_cat_desk_lamp.glb | 82 | 0.200 x 0.200 x 0.420 | 0.20 x 0.20 x 0.42 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1960 | n/a | PASS |
| hh_cat_monitor.glb | 35 | 0.550 x 0.200 x 0.420 | 0.55 x 0.20 x 0.42 | 0.0000 | 0.000 / 0.000 | 4 | yes | 592 | n/a | PASS |
| hh_cat_keyboard_mouse.glb | 502 | 0.460 x 0.200 x 0.030 | 0.46 x 0.20 x 0.03 | 0.0000 | 0.000 / 0.000 | 2 | yes | 9792 | n/a | PASS |
| hh_cat_printer.glb | 61 | 0.450 x 0.380 x 0.200 | 0.45 x 0.38 x 0.20 | 0.0000 | 0.000 / 0.000 | 6 | yes | 1004 | n/a | PASS |
| hh_cat_paper_tray.glb | 79 | 0.340 x 0.260 x 0.200 | 0.34 x 0.26 x 0.20 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1352 | n/a | PASS |
| hh_cat_pen_pot.glb | 46 | 0.090 x 0.090 x 0.140 | 0.09 x 0.09 x 0.14 | 0.0000 | 0.000 / 0.000 | 7 | yes | 1540 | n/a | PASS |
| hh_cat_laptop.glb | 375 | 0.340 x 0.240 x 0.220 | 0.34 x 0.24 x 0.22 | 0.0000 | 0.000 / 0.000 | 6 | yes | 7068 | n/a | PASS |
| hh_cat_desk_phone.glb | 185 | 0.220 x 0.180 x 0.100 | 0.22 x 0.18 x 0.10 | 0.0000 | 0.000 / 0.000 | 4 | yes | 2924 | n/a | PASS |
| hh_cat_desk_tidy.glb | 70 | 0.240 x 0.120 x 0.080 | 0.24 x 0.12 x 0.08 | 0.0000 | 0.000 / 0.000 | 7 | yes | 1796 | n/a | PASS |

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_axe_logs.glb`: dark=2B2622, way=C68B59, walnut=6B4A3A, steel=C9CED3, pine=D9B98A
- `hh_cat_desk_lamp.glb`: way=1E1B19, dark=2B2622, steel=C9CED3, cream=F4F1EA
- `hh_cat_monitor.glb`: black=1E1B19, way=2B2622, white=EAE6DC, grey=8E8276
- `hh_cat_keyboard_mouse.glb`: dark=2B2622, way=1E1B19
- `hh_cat_printer.glb`: way=1E1B19, steel=C9CED3, dark=2B2622, grey=8E8276, white=EAE6DC, sage=8FA882
- `hh_cat_paper_tray.glb`: way=1E1B19, white=EAE6DC, steel=C9CED3, cream=F4F1EA, dark=2B2622
- `hh_cat_pen_pot.glb`: way=4A6FA5, dark=2B2622, red=B6453F, white=EAE6DC, mustard=E6B655, pine=D9B98A, steel=C9CED3
- `hh_cat_laptop.glb`: way=1E1B19, dark=2B2622, black=1E1B19, grey=8E8276, blue=4A6FA5, white=EAE6DC
- `hh_cat_desk_phone.glb`: way=1E1B19, dark=2B2622, grey=8E8276, sage=8FA882
- `hh_cat_desk_tidy.glb`: way=1E1B19, blue=4A6FA5, red=B6453F, dark=2B2622, mustard=E6B655, steel=C9CED3, cream=F4F1EA
