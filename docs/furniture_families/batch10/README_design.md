# Batch 10 – design share (10 families)

Created by Andrew's Helpers (Grok Bots)

Families: axe_logs, desk_lamp, monitor, keyboard_mouse, printer, paper_tray, pen_pot, laptop, desk_phone, desk_tidy. These are the first 10 rows of batch 10 in families.csv (file order). Art Specialist builds the other 12, and none of Art's files (README.md, FINAL_art.md, VALIDATION.*, batch10_contact_art.png, `_build/`, Art's glbs) were touched. Add-only; nothing pushed.

## Spec
Every model is built to the same spec:
- Units and placement: real metres at the plain variant's w/d/h from families.csv; origin at bottom centre; front toward -Y in Blender (glTF Y-up, so GLB x=w, y=h, z=d).
- Hang items: none. All ten are `mount = small`.
- Build: procedural, with no textures. Screens (monitor, laptop) and displays (printer, desk_phone) are flat matte palette colours: no emissive, no textures.
- Materials: flat matte, roughness 0.82; palette colours only; at most 7 per file.
- Colour-way: the `way` material is the first colour-way.
- Size: each file is under 1 MB.
- Part names avoid the texture hooks in the game's `props.gd` (`PART_TEXTURES`: trunk, top, tray, box, soil, mat, strap, cushion, ...), e.g. the chopping block is `block_*`, the trays are `letter_tray`, the lamp base is `foot`.

## Colour-ways
| family | colour-ways (CSV) | `way` colour | what is `way` |
|---|---|---|---|
| axe_logs | oak; walnut | oak C68B59 | end grain of the block face and the logs |
| desk_lamp | black; blue; mustard; night; rose; sage; steel; terracotta | black 1E1B19 | foot, post, arms, knuckles and shade (one-colour lamp) |
| monitor | off; on; spreadsheet | **off → dark** 2B2622 | the screen (bezel and stand stay black) |
| keyboard_mouse | black; grey; white | black 1E1B19 | all key caps and the mouse |
| printer | black; grey; white | black 1E1B19 | body, scanner lid and paper drawer |
| paper_tray | black; sage; steel | black 1E1B19 | the three letter trays (floors, sides, backs, lips) |
| pen_pot | blue; mustard; night; rose; sage; steel; terracotta | blue 4A6FA5 | the pot and its rim |
| laptop | black; sage; silver | black 1E1B19 | deck and lid |
| desk_phone | black; cream; grey | black 1E1B19 | body and handset |
| desk_tidy | black; oak; pine; walnut | black 1E1B19 | floor, walls, dividers and the round cup |

Mappings (new ones are defined in `build_families_design_b10.py`):
- **First colour-way not in the palette:** **off → dark** (monitor). A switched-off screen is near-black; dark 2B2622 keeps it distinct from the black 1E1B19 bezel. This matches Art's alias.
- **Later colour-ways (not baked; the game tints `way`):** **on → blue** and **spreadsheet → white** (monitor screen states), and silver → steel (laptop, the existing b8 alias).
- copper → brass (C9A24E) (Boss decision, 28 Oct 2026: alias added to the build scripts from this batch onward; no batch-10 family uses copper).
- **Existing aliases are unchanged** (gilt/gold → brass, leather/wood → walnut/oak, b8 and b9 aliases).

## Design notes
- **axe_logs:** "Axe and logs". A chopping block (dark bark, oak end grain with walnut growth rings and a crack) with an axe sunk in its face: steel blade and eye, pine handle with a knob. A round log and two split half-logs lie on the ground at the front left.
- **desk_lamp:** an angled (anglepoise-style) one-colour lamp: weighted round foot with a switch, twin-rod lower and upper arms with steel springs and knuckles, a dark tension knob, and an open cone shade with a cream bulb, aimed forward and down.
- **monitor:** plain variant (second and wide are not built). A black bezel with the `way` screen, a rounded back hump, an angled neck and a flat foot plate, with a small white power light and grey logo.
- **keyboard_mouse:** a tenkeyless keyboard with the real layout: Esc + F1–F12 row, number row, QWERTY rows with Tab/Caps/Shift/Enter widths, a 6.25u space bar row, the nav cluster and arrow keys (87 `way` key caps on a dark sloped plate). A `way` mouse with a dark split line and wheel, and dark cables to the back edge. 502 KB.
- **printer:** a black office printer: body, scanner lid with a steel hinge line, a dark output slot with a pulled-out grey output shelf and a printed white sheet, a front paper drawer with a grip, and an angled control panel with a sage display, grey buttons and a sage power button.
- **paper_tray:** "Paper trays". Three stacked black letter trays on steel risers, each with sides that dip toward the open front, a back wall and a front lip. White and cream paper stacks, and a loose printed sheet on the top tray.
- **pen_pot:** a hollow blue pot with a rolled rim holding a dark pen with a red cap, a white pen with a dark cap, a mustard pencil with a pine tip, a steel ruler and scissors with red loops.
- **laptop:** plain variant (old and open are not built; plain is shown open). A black deck with 61 dark keys and a grey trackpad, the lid open about 100° with a dark bezel and a flat matte blue screen showing a white window with grey lines, three white icons and a dark task bar.
- **desk_phone:** a sloped black body, a handset on a dark cradle on the left, a 3×4 grey keypad and four function keys on the slope, a sage display, and a dark coiled cord.
- **desk_tidy:** a black organiser with a tall back pen bay holding four pens (blue, red, dark), a front notes slot with a mustard sticky-note pad and a cream card, a clips compartment with four steel clips, and a round cup with a mustard pencil.

## Fixes after review
- **Sizes (first build):**
  - axe_logs: 0.43 × 0.44 × 0.46, so the handle was shortened and the logs moved in and shortened.
  - desk_lamp: depth 0.27, so the arms were moved back over the foot and the foot widened to 0.2.
  - printer: depth 0.405 and height 0.188, so the output shelf and sheet are shorter and the body taller.
  - pen_pot: 0.081 × 0.074, so the pot is wider and the pencil leans forward.
  - paper_tray, desk_phone, monitor, keyboard_mouse: small height/depth trims (tier spacing, body slope, foot plate, mouse wheel).
- **Materials:** pen_pot had 8 (a separate blue pen cap duplicating `way`); the cap is now dark, giving 7.
- **Contact sheet:** the split logs read as flat planks lying face-up, so they now lie flat side down with the bark arch on top and semicircular end grain; the axe head was made larger and raised so the blade shows above the block face.
- A builder bug (side panels positioned via the wrong object) was caught on the first build and fixed before review.

## QA

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

## Rebuild
```
cd batch1/_build/design
B=~/opt/blender-4.2.3-linux-x64/blender
$B -b -P build_families_design_b10.py              # all 10 (or list family ids)
$B -b -P render_design.py -- batch10 && python3 contact_sheet_design.py batch10
cd ../../.. && python3 batch1/_build/design/qa_batch1.py batch10 batch10/QA_batch10.md axe_logs desk_lamp monitor keyboard_mouse printer paper_tray pen_pot laptop desk_phone desk_tidy
```
