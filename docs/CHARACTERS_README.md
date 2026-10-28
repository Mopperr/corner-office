# Characters for PR #21 (add-only, team batch 4)

Created by Andrew's Helpers (Grok Bots)

Everything here is a **new file in a new path**. No existing file was edited or deleted, and no `.gd`, `.tscn`, `.import` or existing `.json` was touched. Nothing is wired into code; it all stays inert until you hook it up. Godot will create `.import` sidecars for the new PNG/WAV/GLB files on first import (none are shipped here, on purpose).

## Licence
All files are original work made for Corner Office by the team's agents (Blender Python, Pillow/numpy, procedural audio, written text). Released to the project as **original / CC0**. No third-party assets. The only image-generator content is the concept sheets under `docs/concepts_internal/`, which must not ship (see below).

## Final vs concept

| Status | What | Path |
|---|---|---|
| **Final (ship-ready art, not wired)** | Dana's chosen portrait, variation B (dana_v3_b), expressions, icons | `assets/characters/dana/portraits/` |
| **Final (source model, static)** | Dana 3D model, 47 meshes, **no skeleton, no animations** | `assets/characters/dana/model/dana.glb` |
| **Final (texture set)** | Dana face atlas + 6 face expressions, hair, cloth normal maps for the rigged-character pipeline | `assets/characters/textures/` |
| **Final (built, simple anim)** | 7 named NPC models, each with `walk` and `idle` node animations (no skin) | `assets/characters/npcs/` |
| **Final (audio)** | 128 wordless voice clips, 16 per customer, plus manifest | `assets/characters/customers/voices/` |
| **Final (text/data)** | 8 customer bios, order lines, banter, idle thoughts, reviews, Wren haiku, event lines, customer events, Marge idle lines | `assets/characters/customers/narrative/`, `assets/characters/narrative/` |
| **Design spec (text)** | heights, builds, palettes (hex), outfits, props for the 8 customers | `assets/characters/customers/customers_spec.json` |
| **Upgrade (same name exists in your build)** | newer versions, NOT overwriting yours | `assets/characters/upgrades/` |
| **Concept, INTERNAL ONLY, do not ship** | 8 customer sheets + lineup (built from image-generator turnarounds) | `docs/concepts_internal/customers/` (has `.gdignore`, so Godot ignores and never exports it) |
| **Source scripts** | how everything was made | `tools/characters_src/` |

## The characters

### Dana Reyes (player)
- Portrait set = variation B, which Andrew picked (Oct 14). `dana_portrait.png` is byte-identical to `dana_v3_b.png`. Hand-painted in Python (Pillow+numpy), reproducible with `tools/characters_src/dana_paint/portrait.py b` (`EXPR=happy` etc. for expressions).
- `dana_select_full.png` (900x1400) full-body select card, `@1x` halves.
- Expressions: base, neutral, happy, surprised, tired, proud (640 px). Icons 64-512, circle crops 64-512.
- `dana.glb`: static Blender-built model (Y-up, origin bottom centre). Your build draws people with `scripts/figure.gd` from `fig_*` parts, so this is an option to swap in, not a drop-in.

### The 8 café regulars (customers)
Bios in `customers/narrative/customers.json`; looks in `customers_spec.json`. **No 3D models exist for these 8 yet.** `tools/characters_src/rig/build_characters.py` (rigged, shared humanoid skeleton, 14 clips, face atlas) was written for them but its output folder was empty, so it has never produced a model. The easiest route in your build is probably to dress `figure.gd` people with each customer's palette, height and prop from `customers_spec.json`.

| id | Name | Height | Look (short) | Voice files |
|---|---|---|---|---|
| steve | Steve (StaplerSteve88) | 1.76 m | sage cardigan, lanyard, stapler in holster | sfx_vo_steve_* |
| lamp_lady | Lorna (Lamp_Lady) | 1.64 m | mustard sundress, straw sunhat, tote with lamp | sfx_vo_lorna_* |
| keyclackr | Kit (KeyClackr) | 1.74 m | dusty-blue hoodie, wrist braces, backpack + keyboard | sfx_vo_kit_* |
| dottie | Dottie Ruiz | 1.55 m | terracotta blouse, mustard vest, crossing-guard paddle | sfx_vo_dottie_* |
| theo | Theo Nakamura | 1.80 m | dusty-blue scrubs, thermos (night-shift nurse) | sfx_vo_theo_* |
| pippa | Pippa Mensah | 1.33 m | 9-year-old lemonade critic | sfx_vo_pippa_* |
| rocco | Rocco Delgado | 1.72 m | stocky mail carrier | sfx_vo_rocco_* |
| wren | Wren Albright | 1.68 m | slender quiet poet (haiku) | sfx_vo_wren_* |

Voices: WAV 44.1 kHz 16-bit mono one-shots, -22 to -20.5 LUFS. Per character: greet x3, happy x4, okay x3, unhappy x3, goodbye x3. Pick a random take within the variant, avoid repeating the last one. Set them as non-looping. Made with `tools/characters_src/voices/gen_customer_voices.py` + `voice_engine.py`, then `normalize_pr20.py`. Synthetic babble, no words; nobody has listened to them on speakers yet.

### Named NPCs (3D, `assets/characters/npcs/`)
| file | who | level |
|---|---|---|
| npc_delbert.glb | Delbert Finch, retired clockmaker (cameo) | L7 (cast.md also places him at L4) |
| npc_vendor.glb | market vendor | L8 |
| npc_architect.glb | the architect with a rolled plan (likely Imogen Vance-Okoro) | L9 |
| npc_flagger.glb | road-works flagger with sign | L9 |
| npc_helper.glb | office helper carrying a box | L16 |
| npc_band.glb | parade band member (festival) | L18 |
| npc_rival.glb | rival broker with clipboard (likely Sterling Crane) | L19 |
Built by `tools/characters_src/npcs/build_props_9.py` and `build_L07_L09.py` (Blender 4.2). Each has `walk` and `idle` clips.

### Marge "Mile Marker" Holloway (mentor)
Text only: `narrative/marge_idle.json/.md`, `marge_stacking_reactions.json`.

## Upgrades (same names as files in your build; yours were left untouched)
| ours | yours | note |
|---|---|---|
| upgrades/models/cat_biscuit.glb | assets/models/cat_biscuit.glb | newer Biscuit the cat (stretch + idle). Your people and Pickle are code-built; this is only if you want the model. |
| upgrades/data_narrative/cast.md | data/narrative/cast.md | newer cast: 11 client jobs in level order, customers, event cast |
| upgrades/data_narrative/character_arcs.json/.md | data/narrative/character_arcs.* | newer arcs, adds `if_l5_cut` fallbacks |
`player_characters.json/.md` were identical to yours, so they're not included.

## Concept sheets (INTERNAL, not for shipping)
`docs/concepts_internal/customers/*_sheet.png` and `customers_lineup.png` were composited from turnarounds made with an AI image generator. They are design reference for modelling only. Don't ship them, use them in marketing, or trace them into shipped art without the image-generator wording in the Steam AI disclosure. The raw generated JPGs and cutouts were left out on purpose. `.gdignore` keeps Godot from importing or exporting this folder.

## Source scripts
`tools/characters_src/` holds the generators. They were written against the team's box layout (`/workspace/game/assets/...`), so paths at the top of each script need adjusting before re-running in this repo.

## File list
- `assets/characters/customers/customers_spec.json` (4 KB)
- `assets/characters/customers/narrative/banter.json` (33 KB)
- `assets/characters/customers/narrative/banter.md` (11 KB)
- `assets/characters/customers/narrative/bark_style_notes.md` (4 KB)
- `assets/characters/customers/narrative/customer_event_lines.json` (51 KB)
- `assets/characters/customers/narrative/customer_event_lines.md` (32 KB)
- `assets/characters/customers/narrative/customers.json` (21 KB)
- `assets/characters/customers/narrative/customers.md` (12 KB)
- `assets/characters/customers/narrative/idle_thoughts.json` (5 KB)
- `assets/characters/customers/narrative/idle_thoughts.md` (2 KB)
- `assets/characters/customers/narrative/order_lines.json` (10 KB)
- `assets/characters/customers/narrative/order_lines.md` (6 KB)
- `assets/characters/customers/narrative/reviews.json` (19 KB)
- `assets/characters/customers/narrative/reviews.md` (15 KB)
- `assets/characters/customers/narrative/wren_haiku.json` (4 KB)
- `assets/characters/customers/narrative/wren_haiku.md` (5 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_goodbye_01.wav` (75 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_goodbye_02.wav` (75 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_goodbye_03.wav` (82 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_greet_01.wav` (68 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_greet_02.wav` (68 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_greet_03.wav` (70 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_happy_01.wav` (113 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_happy_02.wav` (135 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_happy_03.wav` (151 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_happy_04.wav` (97 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_okay_01.wav` (61 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_okay_02.wav` (46 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_okay_03.wav` (60 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_unhappy_01.wav` (119 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_unhappy_02.wav` (74 KB)
- `assets/characters/customers/voices/sfx_vo_dottie_unhappy_03.wav` (82 KB)
- `assets/characters/customers/voices/sfx_vo_kit_goodbye_01.wav` (47 KB)
- `assets/characters/customers/voices/sfx_vo_kit_goodbye_02.wav` (48 KB)
- `assets/characters/customers/voices/sfx_vo_kit_goodbye_03.wav` (46 KB)
- `assets/characters/customers/voices/sfx_vo_kit_greet_01.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_kit_greet_02.wav` (46 KB)
- `assets/characters/customers/voices/sfx_vo_kit_greet_03.wav` (62 KB)
- `assets/characters/customers/voices/sfx_vo_kit_happy_01.wav` (55 KB)
- `assets/characters/customers/voices/sfx_vo_kit_happy_02.wav` (92 KB)
- `assets/characters/customers/voices/sfx_vo_kit_happy_03.wav` (92 KB)
- `assets/characters/customers/voices/sfx_vo_kit_happy_04.wav` (64 KB)
- `assets/characters/customers/voices/sfx_vo_kit_okay_01.wav` (55 KB)
- `assets/characters/customers/voices/sfx_vo_kit_okay_02.wav` (46 KB)
- `assets/characters/customers/voices/sfx_vo_kit_okay_03.wav` (60 KB)
- `assets/characters/customers/voices/sfx_vo_kit_unhappy_01.wav` (117 KB)
- `assets/characters/customers/voices/sfx_vo_kit_unhappy_02.wav` (72 KB)
- `assets/characters/customers/voices/sfx_vo_kit_unhappy_03.wav` (81 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_goodbye_01.wav` (72 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_goodbye_02.wav` (64 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_goodbye_03.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_greet_01.wav` (78 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_greet_02.wav` (56 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_greet_03.wav` (58 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_happy_01.wav` (131 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_happy_02.wav` (114 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_happy_03.wav` (130 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_happy_04.wav` (84 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_okay_01.wav` (64 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_okay_02.wav` (44 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_okay_03.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_unhappy_01.wav` (113 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_unhappy_02.wav` (75 KB)
- `assets/characters/customers/voices/sfx_vo_lorna_unhappy_03.wav` (80 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_goodbye_01.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_goodbye_02.wav` (54 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_goodbye_03.wav` (49 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_greet_01.wav` (51 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_greet_02.wav` (50 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_greet_03.wav` (54 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_happy_01.wav` (87 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_happy_02.wav` (97 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_happy_03.wav` (109 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_happy_04.wav` (87 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_okay_01.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_okay_02.wav` (45 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_okay_03.wav` (58 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_unhappy_01.wav` (111 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_unhappy_02.wav` (73 KB)
- `assets/characters/customers/voices/sfx_vo_pippa_unhappy_03.wav` (84 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_goodbye_01.wav` (56 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_goodbye_02.wav` (51 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_goodbye_03.wav` (48 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_greet_01.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_greet_02.wav` (47 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_greet_03.wav` (48 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_happy_01.wav` (98 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_happy_02.wav` (98 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_happy_03.wav` (108 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_happy_04.wav` (70 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_okay_01.wav` (53 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_okay_02.wav` (44 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_okay_03.wav` (57 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_unhappy_01.wav` (116 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_unhappy_02.wav` (75 KB)
- `assets/characters/customers/voices/sfx_vo_rocco_unhappy_03.wav` (84 KB)
- `assets/characters/customers/voices/sfx_vo_steve_goodbye_01.wav` (63 KB)
- `assets/characters/customers/voices/sfx_vo_steve_goodbye_02.wav` (62 KB)
- `assets/characters/customers/voices/sfx_vo_steve_goodbye_03.wav` (56 KB)
- `assets/characters/customers/voices/sfx_vo_steve_greet_01.wav` (73 KB)
- `assets/characters/customers/voices/sfx_vo_steve_greet_02.wav` (59 KB)
- `assets/characters/customers/voices/sfx_vo_steve_greet_03.wav` (58 KB)
- `assets/characters/customers/voices/sfx_vo_steve_happy_01.wav` (88 KB)
- `assets/characters/customers/voices/sfx_vo_steve_happy_02.wav` (106 KB)
- `assets/characters/customers/voices/sfx_vo_steve_happy_03.wav` (92 KB)
- `assets/characters/customers/voices/sfx_vo_steve_happy_04.wav` (81 KB)
- `assets/characters/customers/voices/sfx_vo_steve_okay_01.wav` (60 KB)
- `assets/characters/customers/voices/sfx_vo_steve_okay_02.wav` (46 KB)
- `assets/characters/customers/voices/sfx_vo_steve_okay_03.wav` (57 KB)
- `assets/characters/customers/voices/sfx_vo_steve_unhappy_01.wav` (115 KB)
- `assets/characters/customers/voices/sfx_vo_steve_unhappy_02.wav` (74 KB)
- `assets/characters/customers/voices/sfx_vo_steve_unhappy_03.wav` (87 KB)
- `assets/characters/customers/voices/sfx_vo_theo_goodbye_01.wav` (73 KB)
- `assets/characters/customers/voices/sfx_vo_theo_goodbye_02.wav` (72 KB)
- `assets/characters/customers/voices/sfx_vo_theo_goodbye_03.wav` (82 KB)
- `assets/characters/customers/voices/sfx_vo_theo_greet_01.wav` (86 KB)
- `assets/characters/customers/voices/sfx_vo_theo_greet_02.wav` (68 KB)
- `assets/characters/customers/voices/sfx_vo_theo_greet_03.wav` (69 KB)
- `assets/characters/customers/voices/sfx_vo_theo_happy_01.wav` (81 KB)
- `assets/characters/customers/voices/sfx_vo_theo_happy_02.wav` (145 KB)
- `assets/characters/customers/voices/sfx_vo_theo_happy_03.wav` (112 KB)
- `assets/characters/customers/voices/sfx_vo_theo_happy_04.wav` (101 KB)
- `assets/characters/customers/voices/sfx_vo_theo_okay_01.wav` (63 KB)
- `assets/characters/customers/voices/sfx_vo_theo_okay_02.wav` (44 KB)
- `assets/characters/customers/voices/sfx_vo_theo_okay_03.wav` (60 KB)
- `assets/characters/customers/voices/sfx_vo_theo_unhappy_01.wav` (112 KB)
- `assets/characters/customers/voices/sfx_vo_theo_unhappy_02.wav` (74 KB)
- `assets/characters/customers/voices/sfx_vo_theo_unhappy_03.wav` (85 KB)
- `assets/characters/customers/voices/sfx_vo_wren_goodbye_01.wav` (80 KB)
- `assets/characters/customers/voices/sfx_vo_wren_goodbye_02.wav` (81 KB)
- `assets/characters/customers/voices/sfx_vo_wren_goodbye_03.wav` (89 KB)
- `assets/characters/customers/voices/sfx_vo_wren_greet_01.wav` (100 KB)
- `assets/characters/customers/voices/sfx_vo_wren_greet_02.wav` (76 KB)
- `assets/characters/customers/voices/sfx_vo_wren_greet_03.wav` (79 KB)
- `assets/characters/customers/voices/sfx_vo_wren_happy_01.wav` (112 KB)
- `assets/characters/customers/voices/sfx_vo_wren_happy_02.wav` (166 KB)
- `assets/characters/customers/voices/sfx_vo_wren_happy_03.wav` (111 KB)
- `assets/characters/customers/voices/sfx_vo_wren_happy_04.wav` (88 KB)
- `assets/characters/customers/voices/sfx_vo_wren_okay_01.wav` (55 KB)
- `assets/characters/customers/voices/sfx_vo_wren_okay_02.wav` (46 KB)
- `assets/characters/customers/voices/sfx_vo_wren_okay_03.wav` (77 KB)
- `assets/characters/customers/voices/sfx_vo_wren_unhappy_01.wav` (110 KB)
- `assets/characters/customers/voices/sfx_vo_wren_unhappy_02.wav` (73 KB)
- `assets/characters/customers/voices/sfx_vo_wren_unhappy_03.wav` (81 KB)
- `assets/characters/customers/voices/voice_manifest.json` (71 KB)
- `assets/characters/customers/voices/voice_manifest.md` (14 KB)
- `assets/characters/dana/model/dana.glb` (3090 KB)
- `assets/characters/dana/portraits/dana_portrait.png` (147 KB)
- `assets/characters/dana/portraits/dana_portrait@1x.png` (55 KB)
- `assets/characters/dana/portraits/dana_select_full.png` (158 KB)
- `assets/characters/dana/portraits/dana_select_full@1x.png` (67 KB)
- `assets/characters/dana/portraits/expressions/dana_portrait_base.png` (147 KB)
- `assets/characters/dana/portraits/expressions/dana_portrait_happy.png` (148 KB)
- `assets/characters/dana/portraits/expressions/dana_portrait_neutral.png` (146 KB)
- `assets/characters/dana/portraits/expressions/dana_portrait_proud.png` (147 KB)
- `assets/characters/dana/portraits/expressions/dana_portrait_surprised.png` (147 KB)
- `assets/characters/dana/portraits/expressions/dana_portrait_tired.png` (146 KB)
- `assets/characters/dana/portraits/icons/dana_icon_128.png` (13 KB)
- `assets/characters/dana/portraits/icons/dana_icon_256.png` (38 KB)
- `assets/characters/dana/portraits/icons/dana_icon_512.png` (111 KB)
- `assets/characters/dana/portraits/icons/dana_icon_64.png` (4 KB)
- `assets/characters/dana/portraits/icons/dana_portrait_circle_128.png` (19 KB)
- `assets/characters/dana/portraits/icons/dana_portrait_circle_256.png` (53 KB)
- `assets/characters/dana/portraits/icons/dana_portrait_circle_512.png` (139 KB)
- `assets/characters/dana/portraits/icons/dana_portrait_circle_64.png` (7 KB)
- `assets/characters/narrative/customer_events.json` (63 KB)
- `assets/characters/narrative/customer_events.md` (35 KB)
- `assets/characters/narrative/marge_idle.json` (3 KB)
- `assets/characters/narrative/marge_idle.md` (2 KB)
- `assets/characters/narrative/marge_stacking_reactions.json` (1 KB)
- `assets/characters/npcs/npc_architect.glb` (1446 KB)
- `assets/characters/npcs/npc_band.glb` (1040 KB)
- `assets/characters/npcs/npc_delbert.glb` (231 KB)
- `assets/characters/npcs/npc_flagger.glb` (1343 KB)
- `assets/characters/npcs/npc_helper.glb` (1289 KB)
- `assets/characters/npcs/npc_rival.glb` (661 KB)
- `assets/characters/npcs/npc_vendor.glb` (1003 KB)
- `assets/characters/textures/cord_n.png` (106 KB)
- `assets/characters/textures/dana_face/dana_face_base.png` (68 KB)
- `assets/characters/textures/dana_face/dana_face_blink.png` (48 KB)
- `assets/characters/textures/dana_face/dana_face_happy.png` (68 KB)
- `assets/characters/textures/dana_face/dana_face_neutral.png` (65 KB)
- `assets/characters/textures/dana_face/dana_face_proud.png` (66 KB)
- `assets/characters/textures/dana_face/dana_face_surprised.png` (67 KB)
- `assets/characters/textures/dana_face/dana_face_tired.png` (63 KB)
- `assets/characters/textures/dana_face_atlas.png` (251 KB)
- `assets/characters/textures/dana_face_atlas7.png` (355 KB)
- `assets/characters/textures/hair_dana.png` (35 KB)
- `assets/characters/textures/hair_n.png` (138 KB)
- `assets/characters/textures/hair_streak.png` (26 KB)
- `assets/characters/textures/jersey_n.png` (201 KB)
- `assets/characters/textures/knit_rib_n.png` (176 KB)
- `assets/characters/textures/leather_n.png` (415 KB)
- `assets/characters/textures/skin_n.png` (416 KB)
- `assets/characters/textures/twill_n.png` (327 KB)
- `assets/characters/upgrades/data_narrative/cast.md` (2 KB)
- `assets/characters/upgrades/data_narrative/character_arcs.json` (63 KB)
- `assets/characters/upgrades/data_narrative/character_arcs.md` (5 KB)
- `assets/characters/upgrades/models/cat_biscuit.glb` (1199 KB)
- `docs/concepts_internal/.gdignore` (0 KB)
- `docs/concepts_internal/customers/CONCEPT_SHEETS_README.md` (10 KB)
- `docs/concepts_internal/customers/customers_lineup.png` (808 KB)
- `docs/concepts_internal/customers/dottie_sheet.png` (594 KB)
- `docs/concepts_internal/customers/keyclackr_sheet.png` (563 KB)
- `docs/concepts_internal/customers/lamp_lady_sheet.png` (783 KB)
- `docs/concepts_internal/customers/pippa_sheet.png` (460 KB)
- `docs/concepts_internal/customers/rocco_sheet.png` (686 KB)
- `docs/concepts_internal/customers/steve_sheet.png` (555 KB)
- `docs/concepts_internal/customers/theo_sheet.png` (442 KB)
- `docs/concepts_internal/customers/wren_sheet.png` (570 KB)
- `tools/characters_src/dana_paint/fullbody.py` (7 KB)
- `tools/characters_src/dana_paint/fullbody_v3.py` (5 KB)
- `tools/characters_src/dana_paint/painter.py` (20 KB)
- `tools/characters_src/dana_paint/painter_v3.py` (16 KB)
- `tools/characters_src/dana_paint/portrait.py` (0 KB)
- `tools/characters_src/dana_paint/portrait_v3.py` (0 KB)
- `tools/characters_src/narrative/_build.py` (25 KB)
- `tools/characters_src/narrative/_event_cast.py` (11 KB)
- `tools/characters_src/narrative/_event_lines.py` (34 KB)
- `tools/characters_src/narrative/_ext_drinks.py` (23 KB)
- `tools/characters_src/narrative/_haiku.py` (6 KB)
- `tools/characters_src/narrative/_polish.py` (9 KB)
- `tools/characters_src/npcs/build_L07_L09.py` (13 KB)
- `tools/characters_src/npcs/build_props_9.py` (22 KB)
- `tools/characters_src/rig/animlib.py` (17 KB)
- `tools/characters_src/rig/author_clips.py` (4 KB)
- `tools/characters_src/rig/body.py` (12 KB)
- `tools/characters_src/rig/build_characters.py` (21 KB)
- `tools/characters_src/rig/build_dana.py` (7 KB)
- `tools/characters_src/rig/build_dana_face_atlas.py` (0 KB)
- `tools/characters_src/rig/charlib.py` (20 KB)
- `tools/characters_src/rig/clips.py` (26 KB)
- `tools/characters_src/rig/face_atlas.py` (3 KB)
- `tools/characters_src/rig/hair.py` (9 KB)
- `tools/characters_src/rig/make_textures.py` (2 KB)
- `tools/characters_src/rig/preview.py` (9 KB)
- `tools/characters_src/rig/render_lib.py` (2 KB)
- `tools/characters_src/voices/gen_customer_voices.py` (15 KB)
- `tools/characters_src/voices/normalize_pr20.py` (4 KB)
- `tools/characters_src/voices/voice_engine.py` (7 KB)
