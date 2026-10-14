# Corner Office Audio Changelog

## Research notes (2026-10-14 polish pass)

Cozy packing / organization games (Unpacking, A Little to the Left) and farming cozies (Stardew):

- **Tactile packing (Unpacking / Jeff van Dyck GDC 2022):** Pickups are short and punchy (one-frame anim → laggy if SFX is slow). Placement uses material×surface libraries, many variants, and “sweeteners.” Softest material wins when two collide. Room tone + outdoor beds sit under detailed foley.
- **Lo-fi / cozy music variety (Stardew, A Little to the Left OSTs):** Longer beds with sectional changes beat short identical loops; organic textures (soft crackle, acoustic color) and calm melodic hooks. Cheap anti-repetition: drop drums on alternate sections, melody density changes, light filter moves.
- **Loudness practice:** No single game standard. Practical targets used here:
  - Packing one-shots (cozy): peak about **−10 to −12 dBFS** (softer than action SFX); true peak ≤ −1 dBTP.
  - UI ticks: quieter still (~−14 to −18 peak).
  - Ambience loops: consistent **mean ~−30 to −34 dB**, peak ~−12 to −16 so beds sit under SFX.
  - Music beds: leave headroom (peak ~−3); keep below punchy gameplay SFX in the mix bus.

## 2026-10-14 — polish pass started, then paused for Boss priority

- Backups folder created: `src/backup_pre_polish/`
- Measured slice packing SFX: `sfx_item_snap` peak −5 dB (too hot); `sfx_box_set_down` / `sfx_cardboard_bump` peak −6 dB.
- Ambience mean spread −49.2 to −27.8 dB (fire crackle too quiet).
- **Paused** mid-polish for Boss truck backdoor/ramp + trading UI batch (below). Polish resumes after that batch.


## 2026-10-14 — Boss priority: truck backdoor/ramp + trading UI (batch 6)

Paused polish. Added:

**Truck:** `sfx_truck_backdoor_open`, `sfx_truck_backdoor_close`, `sfx_truck_ramp_out`, `sfx_truck_ramp_in` (CC0 shutter + metal drawer/grind/cabinet).
**Trading CRT:** `sfx_trade_buy`, `sfx_trade_sell`, `sfx_trade_profit_chime`, `sfx_trade_loss_thud`, `sfx_price_tick_up`, `sfx_price_tick_down` (original; ticks −18 dB for spam).

Regen: `src/gen_truck_trade.py`. Credits + level_audio_map updated.

## 2026-10-14 — polish pass (resumed after batch 6)

Research-backed targets: packing one-shots peak ~−11 dBFS (Unpacking-style short/soft); ambience mean toward ~−32 dB with peak ≤ −12; music light filter rides for cheap loop variety.

### Packing SFX (backups in `src/backup_pre_polish/`)
- `sfx_item_snap.wav`: peak −5 → **−11**; warmer LP (~2.8 kHz), shorter tail
- `sfx_box_set_down.wav`: peak −6 → **−11**; LP ~900 Hz
- `sfx_cardboard_bump.wav`: peak −6 → **−11**; LP ~1.2 kHz

### Ambience loudness (quiet outliers boosted + soft-limited)
Restored from backup then re-boosted: `amb_fire_crackle_loop`, `amb_l02_cafe_loop`, `amb_l03_rain_loop`, `amb_l04_shop_clock_loop`, `amb_l06_skylight_rain_loop` toward mean ~−32 dB, peak capped ~−12 dBFS.

### Music (cheap anti-repetition)
- `music_office_build.ogg`, `music_main_menu.ogg`: slow warm↔bright LP ride (~32 s) + mild mid duck (~16 s). Same paths; backups saved.

No credit source changes for polish (processing only).

## 2026-10-14 — shop mini-game audio (batch 7, post-slice)

Coffee counter / lemonade stand after Bakery Loft. Spec: WAV 44.1k/16 mono peaking ~−10…−12 (−13/−15 chirps); music OGG ~−3 peak; amb mean ~−32.

Added SFX: coffee_grinder, espresso_pull, milk_steam, cup_set_down, ice_clink, lemon_squeeze, pour, tip_jar_coin, customer_bell, customer_happy_chirp, customer_unhappy_chirp.
Added loops: `music_shop_stand.ogg`, `amb_outdoor_stand_loop.ogg`.
Regen: `src/gen_stand.py`. Credits + level_audio_map updated.
