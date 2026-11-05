# Batch 7 – design share (10 families)

Created by Andrew's Helpers (Grok Bots)

Families: cake_stand, egg_box, bread_board, salt_pepper, cutlery_tray, bath_scales, toiletries, candle_holder, aquarium, typewriter. These are the first 10 rows of batch 7 in families.csv. Art Specialist builds the other 10, and none of Art's files (README.md, batch7_contact_art.png, Art's glbs) were touched. Add-only; nothing pushed.

## Spec
Every model is built to the same spec:
- Units and placement: real metres at the plain variant's w/d/h from families.csv; origin at bottom centre; front toward -Y in Blender (glTF Y-up, so GLB x=w, y=h, z=d).
- Build: procedural, with no textures.
- Materials: flat matte, roughness 0.82; palette colours only; at most 7 per file.
- Colour-way: the `way` material is the first colour-way.
- Size: each file is under 1 MB.

## Colour-ways
| family | colour-ways (CSV) | `way` colour | what is `way` |
|---|---|---|---|
| cake_stand | cream; glass; rose | cream | foot, plates |
| egg_box | sage; wicker; wire | sage | crate, cups, handle |
| bread_board | oak; pine; walnut | oak | board |
| salt_pepper | cream; steel; wood | cream | shaker bodies, salt band |
| cutlery_tray | oak; pine; walnut | oak | tray walls and dividers |
| bath_scales | black; glass; sage; white | black | scale body, pad ribs |
| toiletries | sage; wicker; wire | sage | basket |
| candle_holder | black; brass; copper; steel | black | candlesticks |
| aquarium | black; white | black | base, lid, frame, fish eyes |
| typewriter | black; cream; red; sage | black | body, carriage |

Mappings:
- Every first colour-way is a palette key, so none needed mapping.
- Later colour-ways use the existing aliases wicker→kraft and wire→steel.
- **New alias wood→oak** is defined in build_families_design_b7.py.
- copper (a later candle_holder colour-way) is not an allowed colour, so it has no alias; brass is the nearest allowed colour.

- copper → brass (C9A24E) (candle_holder) (Boss decision, 28 Oct 2026: alias added in the build scripts from batch 10 onward; documentation only, no GLB rebuilt — the baked `way` colour does not use copper.)

## Design notes and fixes
- **egg_box:** the CSV display name is "Egg basket", so this is a sage egg crate with moulded cups, 6 eggs (cream and kraft) and a carry handle. It reads as both a carton and a basket.
- **toiletries:** a woven "Toiletries basket" holding a pump bottle, shampoo, tube, jar and cotton tub.
- **candle_holder:** a pair of turned candlesticks ("Candlesticks" in the CSV) with candles, drips and wicks.
- **aquarium:** the front glass pane is left out on purpose. The matte glass material is opaque, so a front pane would hide the gravel, plants, rocks and 5 fish. The back and side panes, frame and lid are modelled. There is no separate water volume.
- **typewriter:** the keys are geometry (41 caps on stems, plus a space bar). It also has type bars, ribbon spools, a platen with knobs, a return lever, a paper bail and a paper sheet with typed lines. The CSV lists an existing `typewriter` glb; this new file is hh_cat_typewriter.glb and does not replace it.
- **Size fixes after the first build:**
  - bread_board: moved the knife and slices.
  - salt_pepper: bands set inside the body radius.
  - cutlery_tray: shorter serving spoon.
  - candle_holder: base radius set to 0.05.
  - typewriter: body extended to the back; paper rest lowered.
- **Contact-sheet fixes:**
  - cutlery_tray: lower dividers and chunkier cutlery.
  - aquarium: bigger, lower fish and fuller plants.
  - aquarium: fewer pebbles and flat eyes, which brought the file from 834 KB to 748 KB.

## QA
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


## Rebuild
```
cd /workspace/game/pr21-new/families/batch1/_build/design
B=~/opt/blender-4.2.3-linux-x64/blender
$B -b -P build_families_design_b7.py
$B -b -P render_design.py -- batch7
python3 contact_sheet_design.py batch7
cd ../../.. && python3 batch1/_build/design/qa_batch1.py batch7 batch7/QA_batch7.md cake_stand egg_box bread_board salt_pepper cutlery_tray bath_scales toiletries candle_holder aquarium typewriter
```
