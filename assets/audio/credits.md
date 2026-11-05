# Corner Office - Audio Credits

Most audio is original, generated procedurally for Corner Office (Python/numpy/scipy, OGG via ffmpeg/libvorbis). Batch 2 (2026-10-14) adds CC0 / public-domain recordings, listed in the CC0 table below. CC0 needs no attribution and allows commercial use, including Steam sale. Authors are credited anyway as a courtesy. Raw CC0 source files are in src/cc0_raw/, cuts are made with src/process_cc0.py, and the replaced synth v1 files are in src/synth_v1_backup/.

Regenerate: `cd src && python3 gen_music.py && python3 gen_sfx.py` (needs numpy, scipy and ffmpeg).

| File | Source | License |
|---|---|---|
| music/music_computer_trading.ogg | Original, generated procedurally for Corner Office (src/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_driving.ogg | Original, generated procedurally for Corner Office (src/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_driving_rain.ogg | Original, generated procedurally for Corner Office (src/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_main_menu.ogg | Original, generated procedurally for Corner Office (src/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_office_build.ogg | Original, generated procedurally for Corner Office (src/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_box_by_box.ogg | Original, composed and rendered in code for Corner Office (tools/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_kettle_on.ogg | Original, composed and rendered in code for Corner Office (tools/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_open_road.ogg | Original, composed and rendered in code for Corner Office (tools/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_rain_on_the_cab.ogg | Original, composed and rendered in code for Corner Office (tools/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_evening_shift.ogg | Original, composed and rendered in code for Corner Office (tools/gen_music.py) | Original work, owned by the project, commercial use OK |
| music/music_two_more_boxes.ogg | Original, composed and rendered in code for Corner Office (tools/gen_music.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_job_complete.wav | Original, generated procedurally (src/gen_extra.py) | Original work, owned by the project, commercial use OK |
| music/music_rainy_office.ogg | Original, generated procedurally (src/gen_extra.py), 164.6 s seamless loop | Original work, owned by the project, commercial use OK |
| sfx/sfx_box_set_down.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_buy_click.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_cardboard_bump.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_cash_gain.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_cone_hit.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_crt_power_on.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_email_ping.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_invalid_placement.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_item_pick_up.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_item_snap.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_keyboard_typing.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_rain_ambience_loop.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_repair.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_sell_click.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_speed_bump.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_truck_door.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_truck_idle_loop.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_ui_click.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |
| sfx/sfx_ui_hover.wav | Original, generated procedurally for Corner Office (src/gen_sfx.py) | Original work, owned by the project, commercial use OK |

## CC0 recordings (batch 2)

Each file was converted to 44.1 kHz, 16-bit mono WAV, filtered, trimmed, faded, and peak-normalized to between -9 and -14 dBFS.

| File | Source recording | Author | Source URL | License | Fetched |
|---|---|---|---|---|---|
| sfx/sfx_cat_meow.wav | cat_softmew.wav (cut 0.30-1.15 s) | Kerzoven | https://opengameart.org/content/cat-purr-meow | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_ducks_quack.wav | "Ducks" #0276 (loudest 1.1 s window) | DenisChardonnet | https://bigsoundbank.com/ducks-s0276.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_tape_rip.wav | "Adhesive tape #3" #0299 (0-1.3 s) | DenisChardonnet | https://bigsoundbank.com/adhesive-tape-3-s0299.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_tape_apply.wav | "Adhesive tape #2" #0298 (0-0.9 s, softened) | DenisChardonnet | https://bigsoundbank.com/adhesive-tape-2-s0298.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_box_fold.wav | "Gift Package, Opening #1" #3533 (4.30-5.20 s) | Joseph SARDIN | https://bigsoundbank.com/gift-package-opening-1-s3533.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_box_open.wav | "Gift Package, Opening #1" #3533 (11.15-12.40 s) | Joseph SARDIN | https://bigsoundbank.com/gift-package-opening-1-s3533.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_paper_rustle.wav | "Paper" #0785 (2.50-3.15 s) | Joseph SARDIN | https://bigsoundbank.com/paper-s0785.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_drawer_open.wav | "Wooden drawer #1" #1267 (0.12-0.95 s) | Joseph SARDIN | https://bigsoundbank.com/wooden-drawer-1-s1267.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_drawer_close.wav | "Wooden drawer #1" #1267 (2.00-2.85 s) | Joseph SARDIN | https://bigsoundbank.com/wooden-drawer-1-s1267.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_footstep_office.wav | "Man Footsteps on the Wooden Floor" #0165 (one step, 4.80-5.12 s) | DavidGreck | https://bigsoundbank.com/man-footsteps-on-the-wooden-floor-s0165.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_success_chime.wav | "Chimes Dream #2" #2080 | Joseph SARDIN | https://bigsoundbank.com/chimes-dream-2-s2080.html | CC0 1.0 (public domain) | 2026-10-14 |
| sfx/sfx_notification_soft.wav | "Notification LaSoLisa #1" #2063 | Joseph SARDIN | https://bigsoundbank.com/notification-lasolisa-1-s2063.html | CC0 1.0 (public domain) | 2026-10-14 |

## Level audio batch 3 (2026-10-14)

### Music: original, made from scratch (src/gen_level_music.py)
- music/music_act1_home.ogg: original work, owned by the project, commercial use OK
- music/music_act2_morning.ogg: original work, owned by the project, commercial use OK
- music/music_act3_loft.ogg: original work, owned by the project, commercial use OK
- music/music_act4_downtown.ogg: original work, owned by the project, commercial use OK
- music/music_finale.ogg: original work, owned by the project, commercial use OK
- music/music_credits_reprise.ogg: original work, owned by the project, commercial use OK
- music/music_record_store.ogg: original work, owned by the project, commercial use OK
- music/music_curtain_call.ogg: original work, owned by the project, commercial use OK
- music/music_parade_band.ogg: original work, owned by the project, commercial use OK

### Ambience loops (src/gen_levels.py)

| File | CC0 source(s) | Author | URL | License | Notes | Fetched |
|---|---|---|---|---|---|---|
| ambience/amb_l01_garage_loop.ogg | #0222 | Joseph SARDIN | https://bigsoundbank.com/awakening-birds-s0222.html | CC0 1.0 | birds bed + synth room tone/distant mower | 2026-10-14 |
| ambience/amb_l02_cafe_loop.ogg | #2561 | Joseph SARDIN | https://bigsoundbank.com/coffee-shop-at-the-capucins-s2561.html | CC0 1.0 | 60 s crossfade loop | 2026-10-14 |
| ambience/amb_l03_rain_loop.ogg | #1290 | Joseph SARDIN | https://bigsoundbank.com/rain-on-puddle-s1290.html | CC0 1.0 | 60 s crossfade loop | 2026-10-14 |
| ambience/amb_l04_shop_clock_loop.ogg | #0007 | Joseph SARDIN | https://bigsoundbank.com/clock-s0007.html | CC0 1.0 | tiled exact clock ticks + synth room tone | 2026-10-14 |
| ambience/amb_l05_park_birds_loop.ogg | #0222 | Joseph SARDIN | https://bigsoundbank.com/awakening-birds-s0222.html | CC0 1.0 | 60 s crossfade loop | 2026-10-14 |
| ambience/amb_l06_skylight_rain_loop.ogg | #1290 | Joseph SARDIN | https://bigsoundbank.com/rain-on-puddle-s1290.html | CC0 1.0 | low-passed | 2026-10-14 |
| ambience/amb_l07_clinic_hum_loop.ogg | none | project | n/a | Original | original synth | 2026-10-14 |
| ambience/amb_l08_market_loop.ogg | #2728 | Joseph SARDIN | https://bigsoundbank.com/outdoor-market-1-s2728.html | CC0 1.0 | 60 s crossfade loop | 2026-10-14 |
| ambience/amb_l09_studio_loop.ogg | #1081 | Joseph SARDIN | https://bigsoundbank.com/parisian-paved-square-fountain-s1081.html | CC0 1.0 | distant traffic, low-passed + synth room tone/pencil | 2026-10-14 |
| ambience/amb_l10_library_loop.ogg | #0785 | Joseph SARDIN | https://bigsoundbank.com/paper-s0785.html | CC0 1.0 | sparse page touches + synth room tone | 2026-10-14 |
| ambience/amb_l13_night_loop.ogg | #1020 | Joseph SARDIN | https://bigsoundbank.com/field-cricket-s1020.html | CC0 1.0 | crickets + synth pad | 2026-10-14 |
| ambience/amb_l14_greenhouse_loop.ogg | #0222, #1000 | Joseph SARDIN, Joseph SARDIN | https://bigsoundbank.com/awakening-birds-s0222.html https://bigsoundbank.com/bumblebee-1-s1000.html | CC0 1.0 | birds + bee + synth air | 2026-10-14 |
| ambience/amb_l15_coastal_loop.ogg | #0265, #2573 | DenisChardonnet, Joseph SARDIN | https://bigsoundbank.com/beach-small-waves-s0265.html https://bigsoundbank.com/gulls-on-the-harbor-s2573.html | CC0 1.0 | waves + gulls | 2026-10-14 |
| ambience/amb_l19_office_loop.ogg | #2561 | Joseph SARDIN | https://bigsoundbank.com/coffee-shop-at-the-capucins-s2561.html | CC0 1.0 | low-passed chatter + synth HVAC/typing | 2026-10-14 |
| ambience/amb_l20_lodge_loop.ogg | #0987 | Joseph SARDIN | https://bigsoundbank.com/big-branching-fire-1-s0987.html | CC0 1.0 | fire + synth wind | 2026-10-14 |

### Level SFX made from CC0 recordings

| File | Author | URL | License | Fetched |
|---|---|---|---|---|
| sfx/sfx_cat_purr_loop.wav | Kerzoven | https://opengameart.org/content/cat-purr-meow (cat_purrsleepy_loop.wav) | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l02_box_wiggle.wav | Joseph SARDIN | https://bigsoundbank.com/newspaper-ball-s0670.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l06_stair_creak.wav | Joseph SARDIN | https://bigsoundbank.com/apartment-door-opening-1-s1702.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l10_page_flip.wav | Joseph SARDIN | https://bigsoundbank.com/paper-s0785.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l14_bee_buzz.wav | Joseph SARDIN | https://bigsoundbank.com/bumblebee-1-s1000.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l14_door_creak.wav | Joseph SARDIN | https://bigsoundbank.com/apartment-door-opening-2-s1703.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l15_gull_call.wav | Joseph SARDIN | https://bigsoundbank.com/gulls-on-the-harbor-s2573.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_applause.wav | Joseph SARDIN | https://bigsoundbank.com/applause-1-s1765.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l18_crowd_cheer.wav | Joseph SARDIN | https://bigsoundbank.com/applause-150-people-s0019.html | CC0 1.0 | 2026-10-14 |
| sfx/sfx_l20_fire_crackle_loop.wav | Joseph SARDIN | https://bigsoundbank.com/big-branching-fire-1-s0987.html | CC0 1.0 | 2026-10-14 |

### All other new level SFX (src/gen_levels.py)
All other `sfx_l01_*` to `sfx_l21_*` files, plus `sfx_truck_rev`, `sfx_truck_horn`, `sfx_box_rattle`, `sfx_reverse_beep`, `sfx_neon_buzz_loop` and `sfx_l21_city_hum_loop`, are original sounds made from scratch for Corner Office. They are owned by the project and cleared for commercial use.

### Team additions (Andrew's Helpers)
The sounds, airs, textures and the courtroom sting listed in `docs/ADDITIONS_README.md` are original work by the team, CC0, except that `stings/music_courtroom_sting.ogg` is rendered with the FluidR3_GM soundfont by Frank Wen (MIT). The full licence text is in `credits_team_additions.md` next to this file and must ship with the game.
