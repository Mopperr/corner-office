# Corner Office — Level Art Manifest
Master tracker mapped from `corner-office-level-specs.md`.  
Status: **EXISTS** (filename under `assets/models/` or `assets/ui/`), **TODO**, or **DEFERRED**.  
Updated: batch 5 (L1 Dana + L2 + L4 + L6 mesh pass; L3/L5 driving sprites).

**Conventions:** 1 m grid, walls 3 m tall, floor tile tops at y=0, wall items origin on back face, Y-up `.glb`.

**Conflicts / notes**
- Spec puts Sol Cafe Corner, Hank Unit 14B, Milo Dorm, Bea Kitchen Table in **L1 Nov 15**. Coding Master Boss earlier called Cafe/14B/Dorm **post-slice**. **Art lead (this pass):** Dana garage only for L1; Sol/Hank/Milo/Bea variants marked **DEFERRED** (do not build yet).
- First unlock office is **Bakery Loft** (`bakery_loft_*`). “Shared Coworking” is description text only — no separate coworking asset set.
- Cafe Corner modular from batch 4 (`cafe_*`) exists and can be reused for L2 set dressing / Sol later.

---

## Summary counts (unique asset needs from Art lines)

| Level | Release | EXISTS (approx) | TODO | DEFERRED |
|---|---|---|---|---|
| L1 Dana Garage | Nov 15 | ~20 | 2 (animations/VFX) | — |
| L1 Sol/Hank/Milo/Bea | Nov 15 (spec) | partial reuse | — | **all remaining starter kits** |
| L2 Cat Cafe | Nov 15 | ~18 | 4 (idle cats×2, new cafe shell modular, VFX) | — |
| L3 Rainy Drive | Nov 15 | ~12 sprites + truck | 4 (alley kit, splash VFX, shopfront variants) | — |
| L4 Train Shop | Nov 15 | 8 | 3 (parts trays UI, door-angle preview mesh) | — |
| L5 Duck Pond | Nov 15 | ~8 sprites | 3 (pond mesh, bridge geo, dust VFX) | — |
| L6 Bakery Loft | Nov 15 | ~14 | 3 (stairwell kit, light shaft, door pastry spawn point) | — |
| L7–L22 | 1.0 | few reused | **majority TODO** | — |

---

## L1 — Starter Space (Dana: Garage Startup) — Nov 15
### Areas
| Need | Status | File / note |
|---|---|---|
| Garage interior walls/floors | EXISTS | `wall_straight_1m/2m`, `wall_corner`, `wall_window_2m`, `wall_door_2m`, `wall_garage_3m`, `floor_tile_1m/2m` |
| Driveway apron | EXISTS | `driveway_apron_2m.glb` (batch 5) |
### Props
| Need | Status | File / note |
|---|---|---|
| Folding table | EXISTS | `folding_table.glb` |
| Beanbag | EXISTS | `beanbag.glb` (mustard; mood says sage — optional recolour later) |
| Pegboard | EXISTS | `pegboard.glb` |
| Oil-stained floor | EXISTS | `floor_oil_stain_1m.glb` |
| Bike hooks | EXISTS | `bike_hooks.glb` |
| Mini fridge | EXISTS | `mini_fridge.glb` |
| Shelves (2) | EXISTS | `shelf.glb` |
| Desk lamp | EXISTS | `lamp.glb` / `brass_desk_lamp.glb` |
| Whiteboard | EXISTS | `whiteboard.glb` |
### Interactive
| Need | Status | File / note |
|---|---|---|
| Roll-up door | EXISTS | `wall_garage_3m.glb` (`GarageDoor`+`Slat_0..7`, hide Y≥2.55) |
| Evolving whiteboard | EXISTS | mesh `whiteboard.glb`; doodle states = TODO materials/decals |
| Retro computer | EXISTS | `crt_computer.glb` + `keyboard.glb` |
| Job clipboard | EXISTS | `job_clipboard.glb` |
### Dana starting items
| Need | Status | File |
|---|---|---|
| stapler_red | EXISTS (approx) | `stapler.glb` (terracotta; dedicated red variant TODO if needed) |
| mug_worlds_okayest | EXISTS | `mug_worlds_okayest.glb` + `ui/decals/mug_okayest_decal.png` |
| sticky_note_stack | EXISTS | `sticky_note_stack.glb` |

### L1 variants — DEFERRED (art lead)
| Variant | Status | Notes |
|---|---|---|
| Sol Cafe Corner | DEFERRED | Reuse `cafe_*` batch 4 + `cat_bed`, `plant_fern`, `lamp_moody` when un-deferred |
| Hank Unit 14B | DEFERRED | Need corrugated walls, bare bulb, camp chair, string_lights, road signs; reuse `cb_radio`, `thermos_dented` |
| Milo Dorm Corner | DEFERRED | Twin bed, posters, roommate half; reuse `beanbag`, `ramen_kettle`; need `poster_motivational` |
| Bea Kitchen Table HQ | DEFERRED | Round table, sink window, yarn; reuse `yarn_basket`; need `plant_cactus`, `kettle` |

---

## L2 — Cat Cafe Owner — Nov 15
| Need | Status | File / note |
|---|---|---|
| Old cafe counter / seating | EXISTS | `cafe_counter.glb`; seating via `cafe_cushion.glb` + chairs `chair.glb` |
| Cat corner | EXISTS | `cat_tree.glb`, `cat_bed.glb`, `cafe_cushion.glb` |
| New cafe shell | TODO | May reuse `cafe_wall_*` / `cafe_floor_*` (batch 4) — mark as reuse when wired |
| Espresso machine | EXISTS | `espresso_machine_pro.glb` (also `coffee_machine.glb`) |
| Mug rack | EXISTS | `mug_rack.glb` |
| Cat trees | EXISTS | `cat_tree.glb` |
| Cushions | EXISTS | `cafe_cushion.glb` |
| Chalk menu board | EXISTS | `chalk_menu_board.glb` |
| Hanging plants | EXISTS | `hanging_plant.glb` |
| Fragile mugs | EXISTS | reuse mug rack cups / `mug_worlds_okayest` as stand-in |
| Hiding cat (Biscuit) | EXISTS | `cat_biscuit.glb` (animation TODO) |
| Wiggling box | EXISTS | `box_closed.glb` + anim TODO |
| Padding roll | EXISTS | `padding_roll.glb` |
| Idle cats (×3) | TODO | need 2 more cat colour variants |
| Sage walls / terracotta tiles | EXISTS (partial) | `cafe_wall_*`, `cafe_floor_*`; terracotta tile floor TODO if distinct from cafe_floor |

---

## L3 — Rainy Afternoon (drive) — Nov 15
| Need | Status | File / note |
|---|---|---|
| Moving truck | EXISTS | `mover_truck.glb` |
| Cone | EXISTS | `ui/driving/cone.png` (+@1x) |
| Speed bump | EXISTS | `ui/driving/speed_bump.png` |
| Duck family | EXISTS | `ui/driving/duck.png`, `duckling.png` |
| Puddle decal | EXISTS | `ui/driving/puddle.png` |
| Lamppost | EXISTS | `ui/driving/lamppost.png` |
| Umbrella | EXISTS | `ui/driving/umbrella.png` |
| Parked car | EXISTS | `ui/driving/parked_car.png` |
| Mailbox | EXISTS | `ui/driving/mailbox.png` |
| Shopfront | EXISTS | `ui/driving/shopfront.png` |
| 3-block town grid / alley kit | TODO | tileable road + alley meshes or tilemap |
| Splash VFX / rain | TODO | VFX, not mesh |
| Shopfront colour variants | TODO | extra sprites |

---

## L4 — Grandpa's Model Train Shop — Nov 15
| Need | Status | File / note |
|---|---|---|
| Layout board (2 m) | EXISTS | `train_layout_board.glb` |
| Display cases | EXISTS | `display_case.glb` |
| Parts drawers | EXISTS | `parts_drawer_unit.glb` |
| Cuckoo clock | EXISTS | `cuckoo_clock.glb` |
| Toy train (reward) | EXISTS | `toy_train.glb` |
| Small-parts boxes | EXISTS | reuse `box_closed.glb` |
| Parts-sorting trays | TODO | small tray meshes / UI |
| Door-angle preview | TODO | ghost mesh / code |
| Shop wood panel walls | TODO | or tint bakery/garage walls |

---

## L5 — Duck Pond Detour (drive) — Nov 15
| Need | Status | File / note |
|---|---|---|
| Duck family (honk-reactive) | EXISTS | `ui/driving/duck.png`, `duckling.png` |
| Jogger | EXISTS | `ui/driving/jogger.png` |
| Fountain | EXISTS | `ui/driving/fountain.png` |
| Bench | EXISTS | `ui/driving/bench.png` |
| Willow | EXISTS | `ui/driving/willow.png` |
| Bridge Closed barrier | EXISTS | `ui/driving/bridge_closed.png` |
| Pond water mesh / plane | TODO | |
| Gravel dust VFX | TODO | |
| Park loop road tiles | TODO | shared with L3 road kit |

---

## L6 — Bakery Loft (player office) — Nov 15
Named `bakery_loft_*` (not coworking).
| Need | Status | File / note |
|---|---|---|
| Main office walls | EXISTS | `bakery_loft_wall_1m/2m`, `bakery_loft_wall_corner` |
| Terracotta floors | EXISTS | `bakery_loft_floor_1m/2m` (tops at y=0) |
| Break nook | TODO stub OK per spec | can reuse same walls/floors |
| Stairwell | PARTIAL | `stair_step.glb`; full stair kit TODO |
| Sloped ceiling beams | EXISTS | `ceiling_beam.glb` |
| Skylight | EXISTS | `skylight_frame.glb` |
| Radiator | EXISTS | `radiator.glb` |
| Flour-sack rug | EXISTS | `flour_sack_rug.glb` |
| Pastry basket (daily) | EXISTS | `pastry_basket.glb` |
| Skylight light shaft | TODO | light/VFX |
| Door / window for loft | TODO | reuse `wall_door_2m` / `wall_window_2m` with bakery materials, or new |

---

## L7–L22 — 1.0 (TODO overview; build after L1–6 polish)

| Lv | Title | Key art still TODO |
|---|---|---|
| L7 | Retiring Dentist | dentist chair, aquarium+Gerald, glass cabinets, tooth posters, 2-person carry rig |
| L8 | Farmers Market Morning | awning stalls, produce crates, rolling cabbage, vendor NPCs |
| L9 | Chaotic Architect | drafting table, tube bin, models, flagger NPC, sketch overlay |
| L10 | Library Move | tall shelves, rolling ladder, card catalog, reading chairs, color-chime shelves |
| L11 | Brick Warehouse Loft | brick walls, steel windows, beams, freight elevator, floor shims, mezzanine |
| L12 | Indie Record Store | record bins, neon sign, turntable, listening booth |
| L13 | Midnight Neon | neon signs, streetlights, diner, headlight mask, night cat |
| L14 | Florist Greenhouse | glass greenhouse, plant tables, watering cart, bonsai |
| L15 | Windy Coast | lighthouse, dunes, fences, windsocks, gulls |
| L16 | Glass Co-Working Suite | glass partitions, long table, espresso bar, helper NPC, city backdrop |
| L17 | Theater Props | castle flat, costume racks, piano, trunks, curtain, rubber chicken |
| L18 | Parade Detour | barricades, bunting, floats, band NPCs, balloons |
| L19 | Rival Broker | trophy case, marble desk, server rack, traffic props |
| L20 | Snowy Lodge | fireplace, quilts, ski rack, snowfall VFX, truck chains |
| L21 | Corner Office finale | window wall, skyline, executive desk, museum displays, champagne |
| L22 | Last Delivery | reuse L1+L3; founder boxes, note desk, credits camera dressing |

Reuse opportunities into 1.0: mover truck, boxes, plants, shelves, chairs, cafe/bakery modular walls, driving sprites (cones, ducks, cars).

---

## Batch 5 deliverables (this run)
- Script: `assets/src/build_props_5.py` → 32 `.glb` + previews; `models/stats_5.json`; `previews/contact_sheet_5.png`
- Driving sprites: `assets/src/build_driving_sprites.py` → `assets/ui/driving/*.png` (15 motifs × 2 resolutions)
- Stopped after **levels 1–6** mesh/sprite pass (clean boundary). L7–22 remain TODO in this manifest.
