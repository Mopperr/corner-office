# Customer voice manifest — `sfx/vo_customers/`

Wordless babble sets for the 8 regulars (customer sheets: `assets/concepts/customers/README.md`).
All files: WAV, 44.1 kHz, 16-bit PCM, mono, one-shots (Godot sidecar `edit/loop_mode=1`, Disabled).
Loudness (2026-10-23, QA PR#20 pass, `normalize_pr20.py`): integrated −21 LUFS base; okay −21.5, unhappy −22; Theo −21.5, Wren −22, Rocco −20.5 (clamped −20.5…−22). Final range −22.0…−20.5 LUFS I, true peak ≤ −4.6 dBTP, no limiting.
License / attribution: **Created by Andrew's Helpers (Grok Bots)**. Generator: `assets/audio/src/gen_customer_voices.py` + `voice_engine.py` (deterministic seeds). To regenerate: run the generator, then `normalize_pr20.py`.

Naming: `sfx_vo_<name>_<variant>_NN.wav`. **16 clips per character, 128 total**: greet ×3, happy ×4 (most frequent), okay ×3, unhappy ×3 (soft, never sulky, ends on a hopeful lift), goodbye ×3. Takes 01 (and happy 02) are v1. The other takes are new. Each one uses a different phrase shape and a seeded performance variation (f0 ±0.6 st, tempo ×0.94–1.06, breath/jitter ±10–15 %), so they do not repeat. Suggested code: pick a random take within the variant without repeating the last one. Optional `pitch_scale` jitter 0.97–1.03.

## Characters

| name | customer_id | f0 Hz | formant scale | tempo syl/s | breath | range | voice notes |
|---|---|---|---|---|---|---|---|
| steve | `steve` | 138 | 1.03 | 5.2 | 0.12 | 0.75 | earnest, polite to a fault; clean mid voice, tidy even rhythm, small range |
| lorna | `lamp_lady` | 203 | 1.12 | 5.0 | 0.16 | 1.5 | sunny optimist; warm sing-song, wide melodic glides, bright laugh |
| kit | `keyclackr` | 162 | 1.08 | 8.0 | 0.1 | 1.0 | fast talker, bright and clicky, little stumbles (repeats a syllable) |
| dottie | `dottie` | 196 | 1.1 | 4.0 | 0.3 | 1.2 | grandmotherly crossing guard; tremulous, breathy, slower, warm chuckle, a little creak |
| theo | `theo` | 126 | 0.99 | 4.2 | 0.32 | 0.6 | night-shift nurse; low, soft, breathy, small range, grateful sighs, dry |
| pippa | `pippa` | 288 | 1.32 | 6.5 | 0.13 | 1.9 | 9-year-old lemonade critic; high, bouncy, big range, "ooh!" and giggles |
| rocco | `rocco` | 104 | 0.9 | 7.2 | 0.08 | 1.4 | chatty mail carrier; low chesty voice, quick, never grumpy, big hearty laugh |
| wren | `wren` | 182 | 1.09 | 3.6 | 0.4 | 0.5 | quiet poet; very breathy and soft, slow, tiny range, thoughtful "hm" |


## Variants

- **greet** — rise-fall hello (customer arrives); t1 "hey-ya", t2 "hel-lo!", t3 drawn "hiii!" + tag
- **happy** — bright, higher, laughs (great order); t1/t2 babble+laugh, t3 "yay!"+giggle, t4 "mm! oh!" run
- **okay** — acknowledgement (fine order); t1 "mm-hm"/"uh-huh"/"hm", t2 "yeah", t3 "o-kay"
- **unhappy** — gentle soft, never sulky - ends on a hopeful lift; t1 "aww... mm", t2 "oh... hm?", t3 "aw, mm-hm"
- **goodbye** — t1 descending "bye-bye", t2 "see-ya!", t3 rising-settling "bye-bye" (+hum for Theo/Wren/Dottie)

## Files

| file | variant | take | dur s | LUFS I | target | Mmax | TP dBTP | peak dBFS |
|---|---|---|---|---|---|---|---|---|
| sfx_vo_steve_greet_01.wav | greet | 1 | 0.851 | -21.0 | -21 | -19.2 | -5.8 | -5.83 |
| sfx_vo_steve_happy_01.wav | happy | 1 | 1.03 | -21.0 | -21 | -19.0 | -8.0 | -7.96 |
| sfx_vo_steve_happy_02.wav | happy | 2 | 1.24 | -21.0 | -21 | -18.0 | -6.9 | -6.9 |
| sfx_vo_steve_okay_01.wav | okay | 1 | 0.696 | -21.5 | -21.5 | -19.1 | -11.0 | -10.96 |
| sfx_vo_steve_unhappy_01.wav | unhappy | 1 | 1.342 | -22.0 | -22.0 | -18.2 | -7.2 | -7.21 |
| sfx_vo_steve_goodbye_01.wav | goodbye | 1 | 0.733 | -21.0 | -21 | -18.7 | -6.6 | -6.57 |
| sfx_vo_steve_greet_02.wav | greet | 2 (new) | 0.687 | -21.0 | -21 | -18.2 | -9.2 | -9.22 |
| sfx_vo_steve_greet_03.wav | greet | 3 (new) | 0.676 | -21.0 | -21 | -18.6 | -6.9 | -6.9 |
| sfx_vo_steve_happy_03.wav | happy | 3 (new) | 1.074 | -21.0 | -21 | -18.5 | -8.9 | -8.86 |
| sfx_vo_steve_happy_04.wav | happy | 4 (new) | 0.949 | -21.0 | -21 | -17.9 | -7.1 | -7.05 |
| sfx_vo_steve_okay_02.wav | okay | 2 (new) | 0.537 | -21.5 | -21.5 | -19.7 | -6.4 | -6.42 |
| sfx_vo_steve_okay_03.wav | okay | 3 (new) | 0.668 | -21.5 | -21.5 | -19.3 | -8.5 | -8.55 |
| sfx_vo_steve_unhappy_02.wav | unhappy | 2 (new) | 0.867 | -22.0 | -22.0 | -20.0 | -8.2 | -8.17 |
| sfx_vo_steve_unhappy_03.wav | unhappy | 3 (new) | 1.015 | -22.0 | -22.0 | -19.3 | -7.4 | -7.36 |
| sfx_vo_steve_goodbye_02.wav | goodbye | 2 (new) | 0.731 | -21.0 | -21 | -18.5 | -6.3 | -6.3 |
| sfx_vo_steve_goodbye_03.wav | goodbye | 3 (new) | 0.651 | -21.0 | -21 | -18.5 | -5.5 | -5.51 |
| sfx_vo_lorna_greet_01.wav | greet | 1 | 0.91 | -21.0 | -21 | -19.0 | -9.3 | -9.35 |
| sfx_vo_lorna_happy_01.wav | happy | 1 | 1.521 | -21.0 | -21 | -18.9 | -8.1 | -8.1 |
| sfx_vo_lorna_happy_02.wav | happy | 2 | 1.33 | -21.0 | -21 | -18.8 | -8.3 | -8.3 |
| sfx_vo_lorna_okay_01.wav | okay | 1 | 0.746 | -21.5 | -21.5 | -19.2 | -12.4 | -12.39 |
| sfx_vo_lorna_unhappy_01.wav | unhappy | 1 | 1.316 | -22.0 | -22.0 | -18.3 | -7.4 | -7.45 |
| sfx_vo_lorna_goodbye_01.wav | goodbye | 1 | 0.839 | -21.0 | -21 | -18.4 | -6.5 | -6.47 |
| sfx_vo_lorna_greet_02.wav | greet | 2 (new) | 0.655 | -21.0 | -21 | -18.3 | -8.2 | -8.21 |
| sfx_vo_lorna_greet_03.wav | greet | 3 (new) | 0.682 | -21.0 | -21 | -18.5 | -6.7 | -6.71 |
| sfx_vo_lorna_happy_03.wav | happy | 3 (new) | 1.511 | -21.0 | -21 | -17.9 | -6.7 | -6.7 |
| sfx_vo_lorna_happy_04.wav | happy | 4 (new) | 0.975 | -21.0 | -21 | -18.3 | -6.3 | -6.32 |
| sfx_vo_lorna_okay_02.wav | okay | 2 (new) | 0.52 | -21.5 | -21.5 | -19.8 | -7.2 | -7.2 |
| sfx_vo_lorna_okay_03.wav | okay | 3 (new) | 0.695 | -21.5 | -21.5 | -19.0 | -8.8 | -8.82 |
| sfx_vo_lorna_unhappy_02.wav | unhappy | 2 (new) | 0.874 | -22.0 | -22.0 | -18.7 | -8.2 | -8.2 |
| sfx_vo_lorna_unhappy_03.wav | unhappy | 3 (new) | 0.939 | -22.0 | -22.0 | -18.2 | -5.8 | -5.83 |
| sfx_vo_lorna_goodbye_02.wav | goodbye | 2 (new) | 0.75 | -21.0 | -21 | -18.5 | -7.2 | -7.22 |
| sfx_vo_lorna_goodbye_03.wav | goodbye | 3 (new) | 0.689 | -21.0 | -21 | -18.3 | -5.9 | -5.89 |
| sfx_vo_kit_greet_01.wav | greet | 1 | 0.692 | -21.0 | -21 | -18.6 | -6.7 | -6.7 |
| sfx_vo_kit_happy_01.wav | happy | 1 | 0.646 | -21.0 | -21 | -18.6 | -5.9 | -5.91 |
| sfx_vo_kit_happy_02.wav | happy | 2 | 1.074 | -21.0 | -21 | -17.8 | -7.5 | -7.5 |
| sfx_vo_kit_okay_01.wav | okay | 1 | 0.649 | -21.5 | -21.5 | -19.1 | -8.6 | -8.63 |
| sfx_vo_kit_unhappy_01.wav | unhappy | 1 | 1.364 | -22.0 | -22.0 | -18.2 | -7.6 | -7.61 |
| sfx_vo_kit_goodbye_01.wav | goodbye | 1 | 0.548 | -21.0 | -21 | -18.6 | -4.6 | -4.57 |
| sfx_vo_kit_greet_02.wav | greet | 2 (new) | 0.543 | -21.0 | -21 | -19.2 | -7.1 | -7.05 |
| sfx_vo_kit_greet_03.wav | greet | 3 (new) | 0.731 | -21.0 | -21 | -18.3 | -6.9 | -6.85 |
| sfx_vo_kit_happy_03.wav | happy | 3 (new) | 1.073 | -21.0 | -21 | -17.6 | -8.5 | -8.54 |
| sfx_vo_kit_happy_04.wav | happy | 4 (new) | 0.745 | -21.0 | -21 | -17.8 | -5.8 | -5.8 |
| sfx_vo_kit_okay_02.wav | okay | 2 (new) | 0.535 | -21.5 | -21.5 | -19.7 | -6.3 | -6.29 |
| sfx_vo_kit_okay_03.wav | okay | 3 (new) | 0.707 | -21.5 | -21.5 | -19.1 | -8.3 | -8.32 |
| sfx_vo_kit_unhappy_02.wav | unhappy | 2 (new) | 0.843 | -22.0 | -22.0 | -19.6 | -7.2 | -7.2 |
| sfx_vo_kit_unhappy_03.wav | unhappy | 3 (new) | 0.944 | -22.0 | -22.0 | -18.9 | -7.4 | -7.38 |
| sfx_vo_kit_goodbye_02.wav | goodbye | 2 (new) | 0.562 | -21.0 | -21 | -18.6 | -6.0 | -6.0 |
| sfx_vo_kit_goodbye_03.wav | goodbye | 3 (new) | 0.543 | -21.0 | -21 | -19.3 | -6.0 | -6.0 |
| sfx_vo_dottie_greet_01.wav | greet | 1 | 0.796 | -21.0 | -21 | -18.6 | -5.5 | -5.45 |
| sfx_vo_dottie_happy_01.wav | happy | 1 | 1.314 | -21.0 | -21 | -17.6 | -7.0 | -7.0 |
| sfx_vo_dottie_happy_02.wav | happy | 2 | 1.578 | -21.0 | -21 | -17.2 | -8.9 | -8.93 |
| sfx_vo_dottie_okay_01.wav | okay | 1 | 0.719 | -21.5 | -21.5 | -19.2 | -11.0 | -10.98 |
| sfx_vo_dottie_unhappy_01.wav | unhappy | 1 | 1.382 | -22.0 | -22.0 | -18.1 | -7.6 | -7.62 |
| sfx_vo_dottie_goodbye_01.wav | goodbye | 1 | 0.873 | -21.0 | -21 | -18.6 | -8.0 | -7.99 |
| sfx_vo_dottie_greet_02.wav | greet | 2 (new) | 0.789 | -21.0 | -21 | -18.2 | -7.9 | -7.87 |
| sfx_vo_dottie_greet_03.wav | greet | 3 (new) | 0.823 | -21.0 | -21 | -18.3 | -7.7 | -7.66 |
| sfx_vo_dottie_happy_03.wav | happy | 3 (new) | 1.756 | -21.0 | -21 | -17.8 | -7.8 | -7.77 |
| sfx_vo_dottie_happy_04.wav | happy | 4 (new) | 1.136 | -21.0 | -21 | -17.9 | -7.2 | -7.2 |
| sfx_vo_dottie_okay_02.wav | okay | 2 (new) | 0.535 | -21.5 | -21.5 | -19.7 | -7.1 | -7.09 |
| sfx_vo_dottie_okay_03.wav | okay | 3 (new) | 0.7 | -21.5 | -21.5 | -18.9 | -9.7 | -9.66 |
| sfx_vo_dottie_unhappy_02.wav | unhappy | 2 (new) | 0.862 | -22.0 | -22.0 | -18.9 | -7.3 | -7.25 |
| sfx_vo_dottie_unhappy_03.wav | unhappy | 3 (new) | 0.954 | -22.0 | -22.0 | -18.4 | -7.6 | -7.58 |
| sfx_vo_dottie_goodbye_02.wav | goodbye | 2 (new) | 0.87 | -21.0 | -21 | -18.3 | -5.9 | -5.88 |
| sfx_vo_dottie_goodbye_03.wav | goodbye | 3 (new) | 0.96 | -21.0 | -21 | -18.3 | -7.4 | -7.37 |
| sfx_vo_theo_greet_01.wav | greet | 1 | 1.007 | -21.5 | -21.5 | -18.9 | -7.5 | -7.51 |
| sfx_vo_theo_happy_01.wav | happy | 1 | 0.95 | -21.5 | -21.5 | -18.8 | -7.4 | -7.43 |
| sfx_vo_theo_happy_02.wav | happy | 2 | 1.694 | -21.5 | -21.5 | -18.8 | -7.5 | -7.54 |
| sfx_vo_theo_okay_01.wav | okay | 1 | 0.732 | -22.0 | -22.0 | -20.0 | -12.0 | -11.98 |
| sfx_vo_theo_unhappy_01.wav | unhappy | 1 | 1.31 | -22.0 | -22.0 | -18.2 | -6.5 | -6.54 |
| sfx_vo_theo_goodbye_01.wav | goodbye | 1 | 0.853 | -21.5 | -21.5 | -19.6 | -6.9 | -6.91 |
| sfx_vo_theo_greet_02.wav | greet | 2 (new) | 0.798 | -21.5 | -21.5 | -18.7 | -10.1 | -10.13 |
| sfx_vo_theo_greet_03.wav | greet | 3 (new) | 0.81 | -21.5 | -21.5 | -18.9 | -7.1 | -7.14 |
| sfx_vo_theo_happy_03.wav | happy | 3 (new) | 1.302 | -21.5 | -21.5 | -19.1 | -8.4 | -8.46 |
| sfx_vo_theo_happy_04.wav | happy | 4 (new) | 1.181 | -21.5 | -21.5 | -19.0 | -7.1 | -7.06 |
| sfx_vo_theo_okay_02.wav | okay | 2 (new) | 0.521 | -22.0 | -22.0 | -20.2 | -6.0 | -6.0 |
| sfx_vo_theo_okay_03.wav | okay | 3 (new) | 0.701 | -22.0 | -22.0 | -19.6 | -8.1 | -8.15 |
| sfx_vo_theo_unhappy_02.wav | unhappy | 2 (new) | 0.859 | -22.0 | -22.0 | -19.3 | -6.3 | -6.28 |
| sfx_vo_theo_unhappy_03.wav | unhappy | 3 (new) | 0.991 | -22.0 | -22.0 | -19.3 | -6.7 | -6.75 |
| sfx_vo_theo_goodbye_02.wav | goodbye | 2 (new) | 0.845 | -21.5 | -21.5 | -19.5 | -7.4 | -7.4 |
| sfx_vo_theo_goodbye_03.wav | goodbye | 3 (new) | 0.958 | -21.5 | -21.5 | -18.8 | -6.5 | -6.5 |
| sfx_vo_pippa_greet_01.wav | greet | 1 | 0.592 | -21.0 | -21 | -18.5 | -7.2 | -7.25 |
| sfx_vo_pippa_happy_01.wav | happy | 1 | 1.011 | -21.0 | -21 | -17.7 | -6.9 | -6.88 |
| sfx_vo_pippa_happy_02.wav | happy | 2 | 1.135 | -21.0 | -21 | -18.6 | -6.8 | -6.82 |
| sfx_vo_pippa_okay_01.wav | okay | 1 | 0.687 | -21.5 | -21.5 | -19.1 | -11.9 | -11.92 |
| sfx_vo_pippa_unhappy_01.wav | unhappy | 1 | 1.292 | -22.0 | -22.0 | -18.1 | -8.5 | -8.5 |
| sfx_vo_pippa_goodbye_01.wav | goodbye | 1 | 0.686 | -21.0 | -21 | -18.5 | -7.4 | -7.35 |
| sfx_vo_pippa_greet_02.wav | greet | 2 (new) | 0.591 | -21.0 | -21 | -18.6 | -5.2 | -5.24 |
| sfx_vo_pippa_greet_03.wav | greet | 3 (new) | 0.635 | -21.0 | -21 | -18.6 | -5.4 | -5.37 |
| sfx_vo_pippa_happy_03.wav | happy | 3 (new) | 1.266 | -21.0 | -21 | -18.6 | -6.8 | -6.82 |
| sfx_vo_pippa_happy_04.wav | happy | 4 (new) | 1.012 | -21.0 | -21 | -19.0 | -10.2 | -10.19 |
| sfx_vo_pippa_okay_02.wav | okay | 2 (new) | 0.526 | -21.5 | -21.5 | -19.7 | -6.4 | -6.42 |
| sfx_vo_pippa_okay_03.wav | okay | 3 (new) | 0.675 | -21.5 | -21.5 | -19.0 | -9.0 | -9.02 |
| sfx_vo_pippa_unhappy_02.wav | unhappy | 2 (new) | 0.848 | -22.0 | -22.0 | -19.0 | -8.1 | -8.1 |
| sfx_vo_pippa_unhappy_03.wav | unhappy | 3 (new) | 0.978 | -22.0 | -22.0 | -18.5 | -7.9 | -7.9 |
| sfx_vo_pippa_goodbye_02.wav | goodbye | 2 (new) | 0.635 | -21.0 | -21 | -18.6 | -5.9 | -5.95 |
| sfx_vo_pippa_goodbye_03.wav | goodbye | 3 (new) | 0.571 | -21.0 | -21 | -18.6 | -5.8 | -5.8 |
| sfx_vo_rocco_greet_01.wav | greet | 1 | 0.689 | -20.5 | -20.5 | -18.3 | -6.0 | -5.98 |
| sfx_vo_rocco_happy_01.wav | happy | 1 | 1.139 | -20.5 | -20.5 | -18.0 | -6.3 | -6.3 |
| sfx_vo_rocco_happy_02.wav | happy | 2 | 1.145 | -20.5 | -20.5 | -17.6 | -7.0 | -7.0 |
| sfx_vo_rocco_okay_01.wav | okay | 1 | 0.626 | -21.0 | -21.0 | -18.6 | -7.2 | -7.2 |
| sfx_vo_rocco_unhappy_01.wav | unhappy | 1 | 1.358 | -21.5 | -21.5 | -17.5 | -6.0 | -5.96 |
| sfx_vo_rocco_goodbye_01.wav | goodbye | 1 | 0.651 | -20.5 | -20.5 | -17.8 | -5.8 | -5.8 |
| sfx_vo_rocco_greet_02.wav | greet | 2 (new) | 0.555 | -20.5 | -20.5 | -18.1 | -6.8 | -6.8 |
| sfx_vo_rocco_greet_03.wav | greet | 3 (new) | 0.567 | -20.5 | -20.5 | -18.1 | -6.1 | -6.14 |
| sfx_vo_rocco_happy_03.wav | happy | 3 (new) | 1.261 | -20.5 | -20.5 | -17.6 | -6.9 | -6.94 |
| sfx_vo_rocco_happy_04.wav | happy | 4 (new) | 0.817 | -20.5 | -20.5 | -18.5 | -6.5 | -6.52 |
| sfx_vo_rocco_okay_02.wav | okay | 2 (new) | 0.519 | -21.0 | -21.0 | -19.3 | -5.6 | -5.64 |
| sfx_vo_rocco_okay_03.wav | okay | 3 (new) | 0.67 | -21.0 | -21.0 | -18.8 | -7.2 | -7.22 |
| sfx_vo_rocco_unhappy_02.wav | unhappy | 2 (new) | 0.87 | -21.5 | -21.5 | -18.5 | -6.2 | -6.2 |
| sfx_vo_rocco_unhappy_03.wav | unhappy | 3 (new) | 0.983 | -21.5 | -21.5 | -18.4 | -5.8 | -5.82 |
| sfx_vo_rocco_goodbye_02.wav | goodbye | 2 (new) | 0.596 | -20.5 | -20.5 | -18.1 | -5.8 | -5.8 |
| sfx_vo_rocco_goodbye_03.wav | goodbye | 3 (new) | 0.564 | -20.5 | -20.5 | -18.1 | -5.0 | -5.03 |
| sfx_vo_wren_greet_01.wav | greet | 1 | 1.167 | -22.0 | -22.0 | -20.4 | -11.3 | -11.35 |
| sfx_vo_wren_happy_01.wav | happy | 1 | 1.308 | -22.0 | -22.0 | -20.2 | -9.7 | -9.7 |
| sfx_vo_wren_happy_02.wav | happy | 2 | 1.931 | -22.0 | -22.0 | -19.5 | -9.3 | -9.33 |
| sfx_vo_wren_okay_01.wav | okay | 1 | 0.649 | -22.0 | -22.0 | -19.4 | -10.2 | -10.24 |
| sfx_vo_wren_unhappy_01.wav | unhappy | 1 | 1.284 | -22.0 | -22.0 | -18.2 | -6.4 | -6.39 |
| sfx_vo_wren_goodbye_01.wav | goodbye | 1 | 0.934 | -22.0 | -22.0 | -20.1 | -6.9 | -6.87 |
| sfx_vo_wren_greet_02.wav | greet | 2 (new) | 0.882 | -22.0 | -22.0 | -19.7 | -10.6 | -10.61 |
| sfx_vo_wren_greet_03.wav | greet | 3 (new) | 0.918 | -22.0 | -22.0 | -19.5 | -8.4 | -8.38 |
| sfx_vo_wren_happy_03.wav | happy | 3 (new) | 1.292 | -22.0 | -22.0 | -19.2 | -9.8 | -9.86 |
| sfx_vo_wren_happy_04.wav | happy | 4 (new) | 1.026 | -22.0 | -22.0 | -18.8 | -7.3 | -7.31 |
| sfx_vo_wren_okay_02.wav | okay | 2 (new) | 0.543 | -22.0 | -22.0 | -20.2 | -7.9 | -7.89 |
| sfx_vo_wren_okay_03.wav | okay | 3 (new) | 0.9 | -22.0 | -22.0 | -19.4 | -8.7 | -8.68 |
| sfx_vo_wren_unhappy_02.wav | unhappy | 2 (new) | 0.854 | -22.0 | -22.0 | -18.8 | -7.9 | -7.9 |
| sfx_vo_wren_unhappy_03.wav | unhappy | 3 (new) | 0.941 | -22.0 | -22.0 | -18.2 | -6.8 | -6.75 |
| sfx_vo_wren_goodbye_02.wav | goodbye | 2 (new) | 0.944 | -22.0 | -22.0 | -18.9 | -7.3 | -7.31 |
| sfx_vo_wren_goodbye_03.wav | goodbye | 3 (new) | 1.039 | -22.0 | -22.0 | -19.5 | -8.4 | -8.37 |
