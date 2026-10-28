# Batch 9 – design share (10 families)

Created by Andrew's Helpers (Grok Bots)

Families: picture_stack, gramophone, dartboard, bird_cage, vinyl_crate, sewing_machine, tool_box_v, paint_cans, flower_pot_v, spades. These are the first 10 rows of batch 9 in families.csv (file order). Art Specialist builds the other 10, and none of Art's files (README.md, FINAL_art.md, VALIDATION.*, batch9_contact_art.png, `_build/`, Art's glbs) were touched. Add-only; nothing pushed.

## Spec
Every model is built to the same spec:
- Units and placement: real metres at the plain variant's w/d/h from families.csv; origin at bottom centre; front toward -Y in Blender (glTF Y-up, so GLB x=w, y=h, z=d).
- Hang items: dartboard is the only `mount = hang` family in this share. It uses the same rule as the earlier hang items: origin at bottom centre, face at -Y, wall side (bracket) flush at +Y. The other nine are `small`.
- Build: procedural, with no textures.
- Materials: flat matte, roughness 0.82; palette colours only; at most 7 per file.
- Colour-way: the `way` material is the first colour-way.
- Size: each file is under 1 MB.

## Colour-ways
| family | colour-ways (CSV) | `way` colour | what is `way` |
|---|---|---|---|
| picture_stack | gilt; oak; pine; walnut | **gilt → brass** C9A24E | the three frames and inner lips |
| gramophone | oak; pine; walnut | oak C68B59 | case, plinth and case_top |
| dartboard | classic; faded | **classic → black** 1E1B19 | board body, number ring and the dark segments |
| bird_cage | black; brass; copper; steel | black 1E1B19 | base tray, bars, hoops, dome, cap, ring and door |
| vinyl_crate | milk crate; oak; pine; walnut | **milk crate → red** B6453F | posts, slats and base of the crate |
| sewing_machine | black; cream; sage | black 1E1B19 | cast body: bed, pillar, arm and head |
| tool_box_v | black; blue; green; red; steel | black 1E1B19 | body, lid and lid rib |
| paint_cans | blue; cream; mustard; night; rose; sage; terracotta | blue 4A6FA5 | the paint: colour bands, open-tin paint, drips, spill, brush tip |
| flower_pot_v | cream; glazed blue; glazed sage; plastic black; terracotta | cream F4F1EA | the three pots and the saucer |
| spades | oak; pine; steel; walnut | oak C68B59 | shafts and D-handles of both tools |

Mappings (new ones are defined in `build_families_design_b9.py`):
- **First colour-ways not in the palette:**
  - **classic → black** (dartboard). A classic board is black and cream with red/green rings; `way` is the black part.
  - **milk crate → red** (vinyl_crate). The classic plastic milk-crate colour. The crate is slatted, so it reads as both a plastic crate and a wooden one (oak/pine/walnut variants).
  - **gilt → brass** (picture_stack), the existing alias.
- **Later colour-ways (not baked; the game tints `way`):** faded → grey, glazed blue → blue, glazed sage → sage, plastic black → black.
- **Not mapped:** bird_cage **copper** has no alias, because copper is not in the palette (same as before). It needs a decision (terracotta is the nearest palette colour, brass the nearest metal).

- copper → brass (C9A24E) (bird_cage) (Boss decision, 28 Oct 2026: alias added in the build scripts from batch 10 onward; documentation only, no GLB rebuilt — the baked `way` colour does not use copper.)
- **Existing aliases are unchanged**, including the b8 ones (mixed/warm → mustard, bronze → terracotta, gold → brass, silver → steel, tarnished → grey, galvanised → steel).

## Design notes
- **picture_stack:** "Stack of pictures". Three gilt frames leaning back 8°, largest at the back. The back one is a landscape (sky, hills, sun) and the middle one a still life (vase with blooms), both on cream mounts. The front one faces the wall, so you see its kraft backing with steel eyes and hanging wire.
- **gramophone:** an oak case with dark front panels. On top: a felt platter, black record with a red centre, steel spindle, and a brass tone arm with a steel soundbox. A brass elbow rises from the arm base into a big hollow brass horn (open bell with a rolled rim) pointing forward and up. Steel crank with a walnut knob on the right side.
- **dartboard:** hang. A 20-segment board in black and cream with red/green double and treble rings, green outer bull and red bull. It has a steel wire spider and rings, steel number marks in the black number ring, and a dark wall bracket. **No darts:** the CSV depth is 0.05 m (the board only), and darts sticking 10+ cm out would break that.
- **bird_cage:** sits on a surface (mount `small`, not hung). A round, domed black cage on a base tray with a kraft floor. It has 20 chunky bars (r 3.5 mm), three hoops, 10 dome arcs, a cap and a hanging ring, a front door with a catch, a kraft perch, a white food cup and a green/mustard budgie on the perch.
- **vinyl_crate:** "Record crate". A slatted red crate with corner posts, three slat rows per side, base and end hand holes. It holds 12 record sleeves standing face-front and slightly fanned (blue, cream, mustard, teal). The front sleeve has a circle design, and a black record peeks out of one sleeve.
- **sewing_machine:** a vintage hand machine. A walnut base board, black cast body (bed + C-shaped arm/pillar profile + head), brass decals and bed trim, a steel needle plate, needle bar, needle, presser foot and tension knob. A steel hand wheel with a dark hub, and a red thread spool on its pin with the thread run to the head.
- **tool_box_v:** plain variant (the large variant is not built). A black steel box with a ribbed lid, steel seam, two front catches and corner trims. A folding steel handle with a dark grip, and a hammer (oak handle, steel head) and red screwdriver lying on the lid.
- **paint_cans:** a big sealed steel tin with a cream wrap, blue colour band and a wire bail. An open tin full of blue paint with drips and a small spill, its lid leaning on the side. A small tin with a blue band, and a brush (oak handle, steel ferrule, dark bristles with a blue tip) resting on the open tin.
- **flower_pot_v:** "Flower pots", plain variant (the large variant is not built). A big cream pot on a saucer with dark soil, a leaf rosette and seven rose flowers with mustard centres. A small cream pot with a leafy plant, and an empty small pot lying on its side.
- **spades:** "Spade and fork" standing side by side. The spade is in front: a steel blade with a tread and socket. The fork is behind and to the left: four steel tines, bar and socket. Both have oak shafts and D-handles with dark grips, and they are tied together with kraft twine.

## Fixes after review
- **Sizes:**
  - picture_stack: the frames were moved closer together and the lean reduced from 9° to 8°, because the depth was 0.229.
  - gramophone: the horn was moved back and made shorter and less tilted, because the depth was 0.514.
  - vinyl_crate: the sleeves were made taller and more upright, because the height was 0.339.
  - paint_cans: the lid now leans flat on the tin's side, the brush lies front-to-back on the rim and the big tin is taller, because the size was 0.43 × 0.254 × 0.17.
  - spades: the tools were spread wider and further apart, because the size was 0.177 × 0.08.
- **Materials:** bird_cage (8) and vinyl_crate (9) were over the limit of 7. The beak is now mustard and the perch kraft, and the sleeve colours were cut to four, which brings them to 6 each.
- **Contact-sheet fixes:**
  - spades: the fork was hidden behind the spade, so it was moved to the left, where the three-quarter camera sees it.
  - flower_pot_v: bigger leaves, and seven larger flowers.

## QA

| file | KB | bbox w x d x h (m) | CSV w x d x h | min y | centre x / z | mats | way | tris | front | result |
|---|---|---|---|---|---|---|---|---|---|---|
| hh_cat_picture_stack.glb | 150 | 0.500 x 0.200 x 0.600 | 0.50 x 0.20 x 0.60 | 0.0000 | 0.000 / 0.000 | 7 | yes | 2764 | n/a | PASS |
| hh_cat_gramophone.glb | 143 | 0.400 x 0.400 x 0.600 | 0.40 x 0.40 x 0.60 | 0.0000 | 0.000 / 0.000 | 7 | yes | 4480 | n/a | PASS |
| hh_cat_dartboard.glb | 380 | 0.450 x 0.050 x 0.450 | 0.45 x 0.05 x 0.45 | 0.0000 | 0.000 / 0.000 | 6 | yes | 9312 | n/a | PASS |
| hh_cat_bird_cage.glb | 241 | 0.350 x 0.350 x 0.550 | 0.35 x 0.35 x 0.55 | 0.0000 | 0.000 / 0.000 | 6 | yes | 7404 | n/a | PASS |
| hh_cat_vinyl_crate.glb | 198 | 0.400 x 0.360 x 0.360 | 0.40 x 0.36 x 0.36 | 0.0000 | 0.000 / 0.000 | 6 | yes | 3796 | n/a | PASS |
| hh_cat_sewing_machine.glb | 94 | 0.420 x 0.200 x 0.300 | 0.42 x 0.20 x 0.30 | 0.0000 | 0.000 / 0.000 | 7 | yes | 1672 | n/a | PASS |
| hh_cat_tool_box_v.glb | 95 | 0.450 x 0.220 x 0.220 | 0.45 x 0.22 x 0.22 | 0.0000 | 0.000 / 0.000 | 5 | yes | 1748 | ok | PASS |
| hh_cat_paint_cans.glb | 145 | 0.400 x 0.220 x 0.200 | 0.40 x 0.22 x 0.20 | 0.0000 | 0.000 / 0.000 | 5 | yes | 3704 | n/a | PASS |
| hh_cat_flower_pot_v.glb | 356 | 0.300 x 0.300 x 0.260 | 0.30 x 0.30 x 0.26 | 0.0000 | 0.000 / 0.000 | 5 | yes | 21528 | n/a | PASS |
| hh_cat_spades.glb | 83 | 0.200 x 0.100 x 1.100 | 0.20 x 0.10 x 1.10 | 0.0000 | 0.000 / 0.000 | 4 | yes | 1540 | n/a | PASS |

**10 / 10 pass.**

## Problems

None.

## Materials (sRGB hex)

- `hh_cat_picture_stack.glb`: way=C9A24E, cream=F4F1EA, blue=4A6FA5, green=5E7B52, mustard=E6B655, kraft=C9A070, steel=C9CED3
- `hh_cat_gramophone.glb`: way=C68B59, dark=2B2622, black=1E1B19, red=B6453F, steel=C9CED3, brass=C9A24E, walnut=6B4A3A
- `hh_cat_dartboard.glb`: way=1E1B19, dark=2B2622, red=B6453F, cream=F4F1EA, green=5E7B52, steel=C9CED3
- `hh_cat_bird_cage.glb`: way=1E1B19, kraft=C9A070, white=EAE6DC, green=5E7B52, mustard=E6B655, dark=2B2622
- `hh_cat_vinyl_crate.glb`: way=B6453F, black=1E1B19, blue=4A6FA5, cream=F4F1EA, mustard=E6B655, teal=4F8A8B
- `hh_cat_sewing_machine.glb`: walnut=6B4A3A, way=1E1B19, brass=C9A24E, steel=C9CED3, dark=2B2622, red=B6453F, oak=C68B59
- `hh_cat_tool_box_v.glb`: way=1E1B19, steel=C9CED3, dark=2B2622, oak=C68B59, red=B6453F
- `hh_cat_paint_cans.glb`: steel=C9CED3, cream=F4F1EA, way=4A6FA5, dark=2B2622, oak=C68B59
- `hh_cat_flower_pot_v.glb`: way=F4F1EA, dark=2B2622, green=5E7B52, rose=E8B4A8, mustard=E6B655
- `hh_cat_spades.glb`: steel=C9CED3, way=C68B59, dark=2B2622, kraft=C9A070

## Part rename (28 Oct 2026, Boss-approved, props.gd texture hooks)
- flower_pot_v: `soil` → `planter_soil` (the soil in both filled pots; was the `soil → concrete` hook).
- gramophone: `top` → `case_top` (the oak case top; was the `top → oak_floor` hook).
- The game's `props.gd` applies textures by part name (`PART_TEXTURES`; name lower-cased, trailing digits/dots stripped), so these names picked up the wrong texture. The new names are not hooks.
- Only the renamed GLBs were rebuilt. Diffed against the pre-rename backups: bounding box, per-part geometry, materials and the `way` colour are identical; only the node names changed. QA re-run: 10 / 10 pass.

## Rebuild
```
cd /workspace/game/pr21-new/families/batch1/_build/design
B=~/opt/blender-4.2.3-linux-x64/blender
$B -b -P build_families_design_b9.py
$B -b -P render_design.py -- batch9
python3 contact_sheet_design.py batch9
cd ../../.. && python3 batch1/_build/design/qa_batch1.py batch9 batch9/QA_batch9.md picture_stack gramophone dartboard bird_cage vinyl_crate sewing_machine tool_box_v paint_cans flower_pot_v spades
```
