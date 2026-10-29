# Batch 8 – design share (10 families)

Created by Andrew's Helpers (Grok Bots)

Families: loo_roll, medicine_cabinet, bath_caddy, string_lights, console, chess_set, trophy, old_lamp, model_ship, bucket. These are the first 10 rows of batch 8 in families.csv. Art Specialist builds the other 10, and none of Art's files (README.md, batch8_contact_art.png, `_build/`, Art's glbs) were touched. Add-only; nothing pushed.

## Spec
Every model is built to the same spec:
- Units and placement: real metres at the plain variant's w/d/h from families.csv; origin at bottom centre; front toward -Y in Blender (glTF Y-up, so GLB x=w, y=h, z=d).
- Hang items: medicine_cabinet and string_lights are `mount = hang`. They use the same rule as the earlier hang items: origin at bottom centre, face at -Y, wall side flush at +Y.
- Build: procedural, with no textures.
- Materials: flat matte, roughness 0.82; palette colours only; at most 7 per file.
- Colour-way: the `way` material is the first colour-way.
- Size: each file is under 1 MB.

## Colour-ways
| family | colour-ways (CSV) | `way` colour | what is `way` |
|---|---|---|---|
| loo_roll | white | white EAE6DC | the three rolls and the hanging tail |
| medicine_cabinet | oak; steel; white | oak C68B59 | carcass, crown and mirror-door frame |
| bath_caddy | oak; pine; walnut | oak C68B59 | rails, slats and end bars |
| string_lights | mixed; warm | **mixed → mustard** E6B655 | the three yellow bulbs (others are red, green and blue) |
| console | black; grey; white | black 1E1B19 | console body |
| chess_set | oak; pine; walnut | oak C68B59 | board frame |
| trophy | bronze; gold; silver | **bronze → terracotta** D9765F | cup, handles and lid |
| old_lamp | blue; mustard; rose; sage; tarnished; terracotta | blue 4A6FA5 | glazed font and tulip shade |
| model_ship | oak; pine; walnut | oak C68B59 | hull, stern castle and rudder |
| bucket | blue; galvanised; mustard; night; rose; sage; terracotta | blue 4A6FA5 | bucket, rim, ribs and lugs |

Mappings (new ones are defined in `build_families_design_b8.py`):
- **First colour-ways not in the palette:**
  - **mixed → mustard** (string_lights). "Mixed" means multicoloured bulbs. The tintable `way` bulbs are mustard, and the other bulbs are fixed red, green and blue.
  - **bronze → terracotta** (trophy). Terracotta D9765F is the nearest palette colour to bronze; brass is kept for gold.
- **Later colour-ways (not baked; the game tints `way`):** warm → mustard, gold → brass, silver → steel, tarnished → grey, galvanised → steel (the same as Art's table).
- **Existing aliases are unchanged:** painted white → white, painted sage → sage, tan/wicker → kraft, leather → walnut, gilt → brass, tin → steel, canvas → card, navy → night, linen → cream, aluminium → steel, velvet rose → rose, velvet → plum, wire → steel, wood → oak.

## Design notes
- **loo_roll:** the plain variant of "Loo roll stack" is three rolls with rounded edges. The top roll shows its kraft core, its wound layers and a perforated tail hanging down the front. The tower variant is not built.
- **medicine_cabinet:** hang. It has an oak carcass and a crown with a white plaque and red cross. The door has a mirror (glass with white glints), a steel knob and steel hinges. An open shelf below holds a teal bottle, a pill pot, a cup with toothbrushes and a tub.
- **bath_caddy:** a slatted rack that spans the tub, with dark rubber grips underneath at the rim positions. On it are an open book (blue cover, pages with text lines), a sage bottle, a white pump bottle and a mustard sponge.
- **string_lights:** hang. A chunky festoon of nine globe bulbs (0.06 m wide, 0.08 m tall) on dark sockets, along a dark cable. The cable swags between three steel wall hooks.
- **console:** the CSV display name is **"Games console"** (0.30 × 0.24 × 0.08 m), so this is a games console, not a hall table. It has a black body with top vents, a disc slot, USB ports, a power button and a blue LED strip, plus a grey controller on top with sticks, a d-pad and four coloured buttons.
- **chess_set:** an oak frame with pine and walnut squares. It has all 32 turned pieces in cream and dark, with knights as profile heads, after the opening 1. e4 e5. Each piece is a 12-segment lathe, which keeps the file at 332 KB.
- **trophy:** a loving cup with two handles and a domed lid with a finial. It stands on a two-step walnut plinth with an engraved brass plaque.
- **old_lamp:** an oil lamp with a brass foot, a blue font with white bands, a brass burner and wick knob, and a brass gallery. It has an open blue tulip shade (hollow) and a tall glass chimney.
- **model_ship:** a three-masted ship with a lofted hull, pine deck, dark wale and gun ports, stern castle, rudder and bowsprit. It sits on a walnut cradle stand. Rigging is simple to keep the file small (185 KB): billowed cream sails on yards, a jib, a spanker, red pennants, and dark shrouds and stays. The large variant is not built.
- **bucket:** a hollow tapered bucket with a rolled rim, two ribs and lugs. The steel wire handle has a dark grip and rests tilted toward the front.

## Fixes after review
- **Sizes:**
  - loo_roll: the tail was moved closer to the roll, because the depth was 0.13.
  - string_lights: bigger bulbs, because the depth was 0.056.
  - trophy: the plinth was widened to full size, because the depth was 0.113.
  - bath_caddy: the book was made smaller and turned less.
- **Contact-sheet fixes:**
  - string_lights: taller bulbs.
  - bucket: thicker handle wire.
  - old_lamp: the closed shade read as a disc, so it was rebuilt as an open tulip.

## QA
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


## Part rename (28 Oct 2026, from Art's validation)
- model_ship: mesh part `top` was renamed to `mast_top` (the three small walnut mast tops (fighting tops)). The game's `props.gd` applies textures by part name (`PART_TEXTURES`, name lower-cased with trailing digits/dots stripped), and `top` is a texture hook (top → oak_floor). The change is in `build_families_design_b8.py`; only `hh_cat_model_ship.glb` was rebuilt.
- Checked against the previous GLB: bounding box, per-part geometry and materials are identical; only the three node names changed. QA re-run: PASS.

## Rebuild
```
cd /workspace/game/pr21-new/families/batch1/_build/design
B=~/opt/blender-4.2.3-linux-x64/blender
$B -b -P build_families_design_b8.py
$B -b -P render_design.py -- batch8
python3 contact_sheet_design.py batch8
cd ../../.. && python3 batch1/_build/design/qa_batch1.py batch8 batch8/QA_batch8.md loo_roll medicine_cabinet bath_caddy string_lights console chess_set trophy old_lamp model_ship bucket
```
