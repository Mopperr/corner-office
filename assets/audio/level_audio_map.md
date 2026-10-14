# Corner Office — Level Audio Map

Maps each of the 22 levels to music, ambience, and level-specific SFX.
Shared packing/truck/UI SFX live under `sfx/` and apply to every job (see Shared set).
All music and ambience are seamless OGG Vorbis loops; turn **Loop** on in Godot import.
SFX are WAV 44.1 kHz 16-bit mono unless noted as a loop.

**Nov 15 vertical slice:** L1–L6.

## Shared set (all jobs / drives / offices)
- **Music (UI / shared beds):** `music/music_main_menu.ogg`, `music/music_office_build.ogg` (generic decorate), `music/music_computer_trading.ogg`, `music/music_driving.ogg`, `music/music_driving_rain.ogg`, `music/music_rainy_office.ogg`
- **Packing / cardboard:** `sfx_tape_rip`, `sfx_tape_apply`, `sfx_box_fold`, `sfx_box_open`, `sfx_box_set_down`, `sfx_box_rattle`, `sfx_cardboard_bump`, `sfx_item_pick_up`, `sfx_item_snap`, `sfx_invalid_placement`, `sfx_repair`, `sfx_paper_rustle`
- **Truck / drive:** `sfx_truck_idle_loop`, `sfx_truck_rev`, `sfx_truck_horn`, `sfx_truck_door`, `sfx_cone_hit`, `sfx_speed_bump`, `sfx_reverse_beep`, `sfx_ducks_quack`
- **UI / economy:** `sfx_ui_click`, `sfx_ui_hover`, `sfx_buy_click`, `sfx_sell_click`, `sfx_cash_gain`, `sfx_email_ping`, `sfx_notification_soft`, `sfx_success_chime`, `sfx_job_complete`, `sfx_crt_power_on`, `sfx_keyboard_typing`, `sfx_drawer_open`, `sfx_drawer_close`, `sfx_footstep_office`
- **Animals (shared):** `sfx_cat_meow`, `sfx_cat_purr_loop`

---

## ACT 1 — Nov 15 slice

### L1 Starter Space (player office)
| Role | File |
|---|---|
| Music | `music/music_act1_home.ogg` |
| Ambience | `ambience/amb_l01_garage_loop.ogg` (Dana default; Sol uses L2 cafe ambience) |
| SFX | `sfx_l01_garage_door_roll`, `sfx_l01_fridge_hum_loop`, `sfx_l01_marker_squeak` |
| Variant SFX | Sol: `sfx_l01_refill_pour` + cafe ambience. Hank: `sfx_l01_bulb_buzz_loop`, `sfx_l01_cb_static` (+ garage door). Milo: `sfx_l01_kettle_whistle`, `sfx_l01_snore`, `sfx_l01_campus_bell`. Bea: `sfx_l01_knitting_clicks`, `sfx_cat_purr_loop`, fridge hum |

### L2 Cat Cafe Owner
| Role | File |
|---|---|
| Music | shared packing bed (`music_office_build` or silent under ambience) |
| Ambience | `ambience/amb_l02_cafe_loop.ogg` |
| Drive | L3 |
| SFX | `sfx_cat_meow`, `sfx_cat_purr_loop`, `sfx_l02_box_wiggle`, `sfx_l02_espresso_hiss`, `sfx_l02_cup_clink`, `sfx_l02_door_wind_chime` + shared packing |

### L3 Rainy Afternoon (drive)
| Role | File |
|---|---|
| Music | `music/music_driving_rain.ogg` |
| Ambience | `ambience/amb_l03_rain_loop.ogg` (layer under music) |
| SFX | `sfx_l03_wiper`, `sfx_l03_puddle_splash`, `sfx_truck_idle_loop`, `sfx_truck_rev`, `sfx_cone_hit`, `sfx_speed_bump`, `sfx_ducks_quack`, `sfx_box_rattle` |

### L4 Grandpa's Model Train Shop
| Role | File |
|---|---|
| Ambience | `ambience/amb_l04_shop_clock_loop.ogg` |
| Drive | Sunny Main Street → `music_driving.ogg` |
| SFX | `sfx_l04_toy_whistle`, `sfx_l04_track_click`, `sfx_l04_cuckoo`, `sfx_l04_parts_rattle` + shared packing |

### L5 Duck Pond Detour (drive)
| Role | File |
|---|---|
| Music | `music/music_driving.ogg` |
| Ambience | `ambience/amb_l05_park_birds_loop.ogg` |
| SFX | `sfx_l05_duckling_peep`, `sfx_ducks_quack`, `sfx_truck_horn` (honk), `sfx_l05_gravel_crunch`, `sfx_l05_fountain_loop`, `sfx_l05_jogger_steps`, `sfx_box_rattle` |

### L6 Bakery Loft (player office)
| Role | File |
|---|---|
| Music | `music/music_act2_morning.ogg` |
| Ambience | `ambience/amb_l06_skylight_rain_loop.ogg` (rainy mornings) |
| SFX | `sfx_l06_oven_beep_muffled`, `sfx_l06_bakery_bell`, `sfx_l06_stair_creak`, `sfx_l06_pigeon_coo` |

---

## ACT 2 — 1.0

### L7 Retiring Dentist
| Role | File |
|---|---|
| Ambience | `ambience/amb_l07_clinic_hum_loop.ogg` |
| SFX | `sfx_l07_drill_whine`, `sfx_l07_aquarium_bubbles_loop`, `sfx_l07_fish_splash`, `sfx_l07_glass_clink` |

### L8 Farmers Market Morning (drive)
| Role | File |
|---|---|
| Music | `music/music_driving.ogg` |
| Ambience | `ambience/amb_l08_market_loop.ogg` |
| SFX | `sfx_l08_apple_roll`, `sfx_l08_cabbage_thunk`, `sfx_l08_accordion_sting`, `sfx_reverse_beep`, `sfx_box_rattle` |

### L9 Chaotic Architect
| Role | File |
|---|---|
| Ambience | `ambience/amb_l09_studio_loop.ogg` |
| SFX | `sfx_paper_rustle`, `sfx_l09_tube_pop`, `sfx_l09_pencil_scribble`, `sfx_l09_jackhammer_distant` (drive) |

### L10 Library Move
| Role | File |
|---|---|
| Ambience | `ambience/amb_l10_library_loop.ogg` |
| SFX | `sfx_l10_book_thump`, `sfx_l10_page_flip`, `sfx_l10_card_drawer_slide`, `sfx_l10_stamp_thunk`, `sfx_l10_shelf_chime`, `sfx_l10_cobble_rattle` (drive) |

---

## ACT 3 — 1.0

### L11 Brick Warehouse Loft
| Role | File |
|---|---|
| Music | `music/music_act3_loft.ogg` |
| SFX | `sfx_l11_elevator_clank`, `sfx_l11_elevator_gate`, `sfx_l11_radiator_tick`, `sfx_l11_footstep_echo`, `sfx_l11_train_passing` |

### L12 Indie Record Store
| Role | File |
|---|---|
| Music | `music/music_record_store.ogg` (diegetic in-store) |
| Drive | L13 |
| SFX | `sfx_l12_vinyl_crackle_loop`, `sfx_l12_needle_drop`, `sfx_l12_crate_shuffle`, `sfx_neon_buzz_loop`, `sfx_l12_shop_door_bell` |

### L13 Midnight Neon (drive)
| Role | File |
|---|---|
| Music | `music/music_driving.ogg` (quieter mix recommended) |
| Ambience | `ambience/amb_l13_night_loop.ogg` |
| SFX | `sfx_neon_buzz_loop`, `sfx_cat_meow`, `sfx_l13_dog_bark_distant`, `sfx_truck_idle_loop`, `sfx_cone_hit` |

### L14 Florist's Greenhouse
| Role | File |
|---|---|
| Ambience | `ambience/amb_l14_greenhouse_loop.ogg` |
| Drive | L15 |
| SFX | `sfx_l14_watering_trickle`, `sfx_l14_mister`, `sfx_l14_bee_buzz`, `sfx_l14_leaf_rustle`, `sfx_l14_door_creak` |

### L15 Windy Coast (drive)
| Role | File |
|---|---|
| Music | `music/music_driving.ogg` |
| Ambience | `ambience/amb_l15_coastal_loop.ogg` |
| SFX | `sfx_l15_gull_call`, `sfx_l15_wind_gust`, `sfx_l15_flag_snap`, `sfx_l15_foghorn`, `sfx_box_rattle` |

---

## ACT 4 — 1.0

### L16 Glass Co-Working Suite
| Role | File |
|---|---|
| Music | `music/music_act4_downtown.ogg` |
| Ambience | `ambience/amb_l19_office_loop.ogg` (soft office bed; reuse OK) |
| SFX | `sfx_l16_elevator_ding`, `sfx_keyboard_typing`, `sfx_l16_coffee_gurgle`, `sfx_l16_glass_door_swoosh` |

### L17 Theater Prop Department
| Role | File |
|---|---|
| Music | `music/music_curtain_call.ogg` (on completion / curtain call) |
| Drive | L18 |
| SFX | `sfx_l17_piano_bump`, `sfx_l17_rubber_chicken`, `sfx_l17_curtain_swish`, `sfx_applause`, `sfx_l17_rack_wheels` |

### L18 Parade Detour (drive)
| Role | File |
|---|---|
| Music | `music/music_parade_band.ogg` (diegetic) |
| SFX | `sfx_l18_confetti_pop`, `sfx_l18_balloon_pop`, `sfx_l18_crowd_cheer`, `sfx_applause` |

### L19 Rival Broker's Office
| Role | File |
|---|---|
| Ambience | `ambience/amb_l19_office_loop.ogg` |
| SFX | `sfx_l19_server_hum_loop`, `sfx_l19_trophy_clink`, `sfx_footstep_office`, `sfx_l19_car_honk`, `sfx_l19_bus_brakes` |

### L20 Snowy Mountain Lodge
| Role | File |
|---|---|
| Ambience | `ambience/amb_l20_lodge_loop.ogg` |
| SFX | `sfx_l20_fire_crackle_loop`, `sfx_l20_cocoa_pour`, `sfx_l20_snow_crunch`, `sfx_l20_chain_jingle`, `sfx_l20_deer_snort` |

---

## ACT 5 — 1.0

### L21 The Corner Office (finale)
| Role | File |
|---|---|
| Music | `music/music_finale.ogg` |
| SFX | `sfx_l21_city_hum_loop`, `sfx_l21_terrace_wind_loop`, `sfx_l21_champagne_pop`, `sfx_l21_ceremony_bell` |

### L22 The Last Delivery (epilogue)
| Role | File |
|---|---|
| Music | `music/music_credits_reprise.ogg` (credits) + `music_act1_home.ogg` (garage echo) |
| Drive | golden-hour L3 reprise → `music_driving.ogg` + soft `amb_l03_rain_loop` if raining |
| SFX | `sfx_l01_garage_door_roll`, soft rain (`amb_l03_rain_loop` / `sfx_rain_ambience_loop`), `sfx_job_complete` |

---

## Counts
| Kind | Spec | Delivered |
|---|---|---|
| Music tracks (level) | 9 | 9 (`act1_home`, `act2_morning`, `act3_loft`, `act4_downtown`, `finale`, `credits_reprise`, `record_store`, `curtain_call`, `parade_band`) + 6 shared/UI beds |
| Ambience loops | 13 | 13 named in summary + 2 office extras (`amb_l01_garage`, `amb_l06_skylight_rain`) = 15 |
| Level / shared SFX | shared library + per-level | 125 WAV files in `sfx/` |

## Gaps / stubs
- **Voice / dialogue SFX not recorded:** grandpa chuckle, snooty "hmm", helper humming, new owner's laugh, "shh", dentist humming, muttering architect. Use silence or UI clicks until VO pass.
- **L3 rain on roof** = ambience bed; no separate one-shot.
- **L9 architect muttering / L19 snooty grunts** = VO stubs.
- **L16 helper humming** = VO stub.
- **L4 grandpa chuckle** = VO stub.

---

## Overnight robber event (post-slice, not Nov 15)
Soft cozy-crime: if security spend is too low, robbers take 1–3 decor items overnight (money/Rep stay). Tone is "oh no," not horror.

| Beat | File |
|---|---|
| Night bed (loop, duck under sting) | `ambience/amb_robber_night_office.ogg` |
| Break-in / morning-after reveal (loop) | `music/music_robber_sting.ogg` (34.3 s, mastered at -6 dBFS peak) |
| Break-in | `sfx_lock_jimmy` → `sfx_door_creak` → `sfx_robber_footsteps` |
| Taking items (per item, 1–3×) | `sfx_items_grab`, `sfx_box_scrape` (vary pitch ±5%) |
| Partial security fails | `sfx_security_alarm` (soft; loop or play 1–2×) |
| Morning reveal | `sfx_empty_room_whoosh` + sting |

All of these files are for this event only. Loop flag goes on the sting and the ambience.

---

## Forgotten-fire event (post-slice)
Matches + magnifier only (never smoking). Cozy "oops," not scary.

| Beat | File |
|---|---|
| Ignition | `sfx_match_strike` then `sfx_magnifier_sizzle` |
| Fire bed (loop) | `ambience/amb_fire_crackle_loop.ogg` (26 s seamless; same CC0 family as lodge crackle) |
| Smoke alarm (gentle) | `sfx_smoke_alarm` (play 1–3× or short loop; not piercing) |
| Morning after (loop) | `ambience/amb_fire_morning_after.ogg` (27.5 s soft residual) |

## Steam trailer (marketing, not in-game loop)
| Role | File |
|---|---|
| Trailer cue | `music/music_steam_trailer.ogg` (~74 s, **do not** set Loop in Godot; linear build → warm hook → clean fade-out) |

---

## Truck loading (shared drive / job unload)
| Role | File |
|---|---|
| Back door open / close | `sfx_truck_backdoor_open`, `sfx_truck_backdoor_close` (roll-up shutter CC0) |
| Ramp out / in | `sfx_truck_ramp_out`, `sfx_truck_ramp_in` (metal slide CC0) |
| Cab door (existing) | `sfx_truck_door` |

## Trading computer UI
| Role | File |
|---|---|
| Buy / sell confirm | `sfx_trade_buy`, `sfx_trade_sell` |
| Profit / loss feedback | `sfx_trade_profit_chime`, `sfx_trade_loss_thud` (gentle) |
| Live price ticks (spam) | `sfx_price_tick_up`, `sfx_price_tick_down` (~−18 dB peak) |
| Chart bed | `music/music_computer_trading.ogg` |

---

## Shop mini-game — Coffee counter / Lemonade stand (post-slice, after L6)
Soft-fail only. Loop music + outdoor amb for lemonade cart; indoor coffee may duck outdoor amb and keep music.

| Role | File |
|---|---|
| Music (loop) | `music/music_shop_stand.ogg` (~156 s) |
| Outdoor stand amb (loop) | `ambience/amb_outdoor_stand_loop.ogg` |
| Coffee make | `sfx_coffee_grinder` → `sfx_espresso_pull` → `sfx_milk_steam` → `sfx_pour` → `sfx_cup_set_down` |
| Lemonade make | `sfx_lemon_squeeze` → `sfx_ice_clink` → `sfx_pour` → `sfx_cup_set_down` |
| Customer arrive | `sfx_customer_bell` |
| Success / tip | `sfx_customer_happy_chirp`, `sfx_tip_jar_coin` |
| Soft fail (wrong drink) | `sfx_customer_unhappy_chirp` (gentle; never mean) |
