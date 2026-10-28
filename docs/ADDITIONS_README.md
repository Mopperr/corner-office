# Team additions for PR #21 (add-only)

Branch `team/additions-for-pr21`, based on `claude/make-slice-playable` at `5feefc9`.
Every change here is a new file or an appended entry. No script, scene, test, project setting, existing asset or existing data entry was edited.

## What was added

| What | Count | Where |
|---|---|---|
| Ambience loops (.ogg plus .import) | 16 | `assets/audio/ambience/` |
| Music loops (.ogg plus .import, all `loop=true`) | 9 | `assets/audio/music/` |
| SFX (.wav plus .import) | 52 | `assets/audio/sfx/` |
| Emails appended | 2 (`job_train`, `ty_train`) | `data/narrative/emails.json` |
| This file | 1 | `docs/ADDITIONS_README.md` |

That's 77 audio files plus 77 .import sidecars (154 files), 1 appended data file and this README.
Each audio file uses a filename that doesn't exist in PR #21, and none of the 77 .import UIDs matches an existing UID.

### Emails
- `job_train` fires on `job_catcafe_complete` and introduces the train job.
- `ty_train` fires on `job_train_complete` and is the thank-you.
- Both use triggers that `game_state.gd` already fires. Before this, nothing arrived around the train job.
- The sender is "Grandpa Ellis", the `job_train` client in content.json. (The team's draft used another name.)
- The two entries were appended after the last entry. Every existing email, including `tut_welcome`, is unchanged.

## Silent until referenced
- **Ambience and music:** none of the new loops plays until a venue or drive names it under `"ambience"` / `"music"` in `data/content.json` or `data/drives.json`. AudioDirector preloads every ambience file at startup, so they add a little memory.
  - Example: `music_shop_stand` for `lemonade_stand`. That's a data edit and needs Andrew's OK.
- **SFX:** none of the new SFX plays until code calls `play_sfx("<name>")`. Per-name gains in tuning.json don't cover them yet.
  - Examples: grinder, espresso pull, ice clink, pour and tip jar would suit the Make it card.

## Deliberately NOT included (and why)
- **Team versions of the 116 same-named audio files that differ:** left alone because tuning.json gains are set for Claude's versions.
- **Non-looping tracks** (`music_social_15s`, `music_steam_trailer`, `music_steam_trailer_v0`): smoke fails any file in music/ that doesn't loop.
- **Customer voices (vo_customers):** PR #21 has no VO playback, so they'd need code.
- **Wren's haiku, per-customer lines, reviews:** no system in PR #21 to hold them without code.
- **Drink-quality VFX:** would need code hooked to make_card's `finished` signal.
- **The team's shop, customers, drink menu and prototypes:** these conflict with PR #21's own shop.json and yard_shop.
- **Levels L07–L15 and drive routes:** need venue_dressing.gd code.
- **Models (new and newer):** scale, origin and collision changes could break the placement, desk-height and truck tests.
- **Market resale fix (buyer_premium 1.35):** an economy decision for Andrew. Part of it is a code change.
- **Anything tonal** (crime/Busted, the robber/fire narrative, the $250M ending): these wait on Andrew's direction.
  - Note: a few of the added files are robber/alarm/fire-themed (`amb_robber_night_office`, `amb_fire_*`, `music_robber_sting`, `sfx_robber_footsteps`, `sfx_security_alarm`, `sfx_lock_jimmy`, `sfx_smoke_alarm`, `sfx_match_strike`). They're inert, so you can ignore or delete them.

## Verification
On a fresh clone of 5feefc9 with these additions, the box ran Godot 4.7.2 headless `--import` and then `tests/run_smoke.sh`.
- Result: **SMOKE_OK**, with the same 6 pre-existing `client_party.gd` look_at "Node not inside tree" errors as the base. The import left no .import file changed (Oct 28, 2026).
- Not run: `run_playthrough.sh` and `run_venues.sh`.

## Full file list
### ambience
- amb_fire_crackle_loop.ogg
- amb_fire_morning_after.ogg
- amb_l07_clinic_hum_loop.ogg
- amb_l07_waiting_room_loop.ogg
- amb_l08_busker_accordion_loop.ogg
- amb_l08_market_busker_loop.ogg
- amb_l08_market_loop.ogg
- amb_l09_studio_loop.ogg
- amb_l10_library_loop.ogg
- amb_l13_night_loop.ogg
- amb_l14_greenhouse_loop.ogg
- amb_l15_coastal_loop.ogg
- amb_l19_office_loop.ogg
- amb_l20_lodge_loop.ogg
- amb_outdoor_stand_loop.ogg
- amb_robber_night_office.ogg
### music
- music_act3_loft.ogg
- music_act4_downtown.ogg
- music_credits_reprise.ogg
- music_curtain_call.ogg
- music_finale.ogg
- music_parade_band.ogg
- music_record_store.ogg
- music_robber_sting.ogg
- music_shop_stand.ogg
### sfx
- sfx_box_scrape.wav
- sfx_cart_unfold.wav
- sfx_cocoa_dust.wav
- sfx_coffee_grinder.wav
- sfx_cup_set_down.wav
- sfx_customer_bell.wav
- sfx_customer_happy_chirp.wav
- sfx_customer_leave_wave.wav
- sfx_customer_unhappy_chirp.wav
- sfx_door_creak.wav
- sfx_drip_brew.wav
- sfx_empty_room_whoosh.wav
- sfx_espresso_pull.wav
- sfx_ice_clink.wav
- sfx_items_grab.wav
- sfx_lemon_squeeze.wav
- sfx_lock_jimmy.wav
- sfx_magnifier_sizzle.wav
- sfx_match_strike.wav
- sfx_milk_foam.wav
- sfx_milk_steam.wav
- sfx_muddle.wav
- sfx_pour.wav
- sfx_price_tick_down.wav
- sfx_price_tick_up.wav
- sfx_robber_footsteps.wav
- sfx_security_alarm.wav
- sfx_sip_straw.wav
- sfx_smoke_alarm.wav
- sfx_spoon_stir.wav
- sfx_straw_drop.wav
- sfx_sugar_pour.wav
- sfx_syrup_drizzle.wav
- sfx_tea_steep.wav
- sfx_tip_jar_coin.wav
- sfx_trade_buy.wav
- sfx_trade_loss_thud.wav
- sfx_trade_profit_chime.wav
- sfx_trade_sell.wav
- sfx_truck_backdoor_close.wav
- sfx_truck_backdoor_open.wav
- sfx_truck_ramp_in.wav
- sfx_truck_ramp_out.wav
- sfx_vo_architect_mutter.wav
- sfx_vo_dentist_hum.wav
- sfx_vo_grandpa_chuckle.wav
- sfx_vo_helper_hum.wav
- sfx_vo_new_owner_laugh.wav
- sfx_vo_rival_hmm.wav
- sfx_vo_shh.wav
- sfx_whip_topping.wav
- sfx_xray_lightbox_hum.wav

## Second batch (add-only): 10 SFX, 18 textures

Added on top of bd0bb2d. No `.gd`, `.json`, `.tscn`, `.import` or existing asset file was touched; Godot creates the `.import` files on first import. Nothing here is referenced by code yet, so every file is silent/unused until wired in.

**Honest notes:**
- Nothing in this batch has been listened to or looked at in-game by a human yet. Checks were technical only (sample rate, channels, bit depth, duration, peak, leading silence, PNG size, seam match).
- `sfx_shove_grunt`, `sfx_gasp_small` and `sfx_angry_mutter` are synthetic formant-synthesis vocal-like sounds, not recordings of people. They may sound a bit robotic.
- `music_courtroom_sting.ogg` (5.4 s, requested for assets/audio/music/) is **held back from this commit**: `tests/smoke.gd` requires every `.ogg` in assets/audio/music/ to have `loop=true` in its `.import`, and a one-shot sting must not loop (and `.import` files must not be hand-made here), so adding it fails the smoke test (`music loop music_courtroom_sting.ogg`). It is available separately; note its instrument samples are FluidR3_GM (MIT), **not CC0**.
- SFX are peak-normalised to -3 dBFS as specced, so loudness varies (about -12.6 to -24.5 LUFS); expect per-sound volume trims in-engine.

### sfx (assets/audio/sfx/, 16-bit 44.1 kHz mono WAV, peak -3 dBFS, no leading silence)
- `sfx_glass_smash.wav`: 0.98 s: a small ceramic/glass piece breaking on a wooden floor. Made by procedural synthesis (numpy/scipy: floor thump, ceramic ring, shard resonances, bounces). Licence: original, CC0.
- `sfx_crockery_crack.wav`: 0.33 s: a single quieter crack for a chipped piece (peak-normalised like the rest, so turn it down in-engine). Made by procedural synthesis. Licence: original, CC0.
- `sfx_shove_grunt.wav`: 0.55 s: angry wordless effort grunt. Made by SYNTHETIC formant synthesis (Klatt-style voice synth), not a recording of a person. Licence: original, CC0.
- `sfx_body_fall.wav`: 1.04 s: a person landing on their back on a floor, soft thud and cloth rustle. Made by procedural synthesis. Licence: original, CC0.
- `sfx_gasp_small.wav`: 0.44 s: short surprised gasp. Made by SYNTHETIC formant synthesis, not a recording of a person. Licence: original, CC0.
- `sfx_angry_mutter.wav`: 2.60 s: wordless grumbling, no real language. Made by SYNTHETIC formant synthesis (random babble syllables), not a recording of a person. Licence: original, CC0.
- `sfx_gavel.wav`: 0.39 s: one gavel strike on a sound block. Made by procedural synthesis. Licence: original, CC0.
- `sfx_letter_open.wav`: 0.82 s: an envelope tearing open. Made by procedural synthesis (paper-fibre crackle grains). Licence: original, CC0.
- `sfx_coins_award.wav`: 1.66 s: short pleasant pour of coins. Made by procedural synthesis (inharmonic metal partials). Licence: original, CC0.
- `sfx_level_up_hands.wav`: 0.95 s: warm two-note chime, G5 then C6. Made by procedural additive bell synthesis. Licence: original, CC0.

### textures (new folder assets/textures/, 512x512 RGB PNG, seamless/tileable)
All made by a seeded procedural Python generator (numpy, scipy, Pillow): periodic noise, wrap-mode blurs, grids and vector shapes, in the `scripts/ui_kit.gd` palette desaturated 15%. No photographs, no image generator, no text or logos.
- `tex_oak_floor.png`: warm oak strip floor, staggered joints. Made procedurally (Python). Licence: original, CC0.
- `tex_pine_planks.png`: pale pine boards with soft knots. Made procedurally (Python). Licence: original, CC0.
- `tex_terrazzo.png`: cream terrazzo with palette chips. Made procedurally (Python). Licence: original, CC0.
- `tex_kitchen_tile.png`: sage subway tile, cream grout. Made procedurally (Python). Licence: original, CC0.
- `tex_bathroom_tile.png`: pale blue square tile. Made procedurally (Python). Licence: original, CC0.
- `tex_carpet_wool.png`: sage-grey wool loop carpet. Made procedurally (Python). Licence: original, CC0.
- `tex_rug_kilim.png`: kilim weave, stepped diamonds and zigzag bands. Made procedurally (Python). Licence: original, CC0.
- `tex_fabric_linen.png`: oatmeal linen plain weave. Made procedurally (Python). Licence: original, CC0.
- `tex_velvet.png`: muted terracotta-rose velvet. Made procedurally (Python). Licence: original, CC0.
- `tex_leather.png`: brown pebbled leather. Made procedurally (Python). Licence: original, CC0.
- `tex_marble.png`: cream marble with sage-grey veins. Made procedurally (Python). Licence: original, CC0.
- `tex_brick_painted.png`: cream-painted brick with worn terracotta patches. Made procedurally (Python). Licence: original, CC0.
- `tex_plaster.png`: cream hand-troweled plaster. Made procedurally (Python). Licence: original, CC0.
- `tex_wallpaper_floral.png`: sage floral wallpaper, terracotta and cream flowers. Made procedurally (Python). Licence: original, CC0.
- `tex_wallpaper_stripe.png`: cream wallpaper with sage bands and terracotta pinstripe. Made procedurally (Python). Licence: original, CC0.
- `tex_cardboard.png`: kraft cardboard with faint corrugation. Made procedurally (Python). Licence: original, CC0.
- `tex_brushed_steel.png`: warm blue-grey brushed steel. Made procedurally (Python). Licence: original, CC0.
- `tex_concrete.png`: warm grey concrete with pores and specks. Made procedurally (Python). Licence: original, CC0.

## Third batch (add-only): courtroom sting + credits

- `assets/audio/stings/music_courtroom_sting.ogg`: the 5.4 s dry, slightly comic "here comes the judge" sting (C major, 100 BPM, OGG Vorbis 44.1 kHz stereo). It's in the new `stings/` folder, not `music/`, so the smoke test's music-loop rule doesn't apply to it. It's a one-shot meant to be played by a sting player, and nothing references it yet, so it's silent until wired in. Made from an original MIDI composition rendered with FluidR3_GM soundfont samples. Licence: original composition; the instrument samples are **MIT-licensed (FluidR3_GM by Frank Wen), not CC0**. Nobody has listened to it yet.
- `assets/audio/credits_team_additions.md`: the FluidR3_GM credit with the full MIT licence text, copied verbatim. It's a new file because `assets/audio/credits.md` already exists on Claude's branch and was left unedited. Licence: original text (credit notice) plus the quoted MIT licence.

Created by Andrew's Helpers (Grok Bots)
