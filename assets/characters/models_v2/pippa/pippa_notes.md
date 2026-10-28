# Pippa — v1 vs concept, and v2 fixes

Script: `_build/build_pippa_v2.py` (new copy; shared/original scripts untouched). Skeleton, bone names, idle/walk/sit clip names, frame ranges and keys identical to v1, except the arm/hand key values (see Clip changes and `pippa_check.txt`: ALL PASS). Palette from the sheet: skin #7A4A2A, hair #24170C, tee #E6B655, overall #6F7A50, sneakers #D9765F, clipboard #C68B59, socks #F4E9D8, stickers #8FAF7E/#E8B4A8/#7FA3B8.

| Area | v1 | Concept | v2 |
|---|---|---|---|
| Hair puffs | lumpy, set back and low | two big round fuzzy puffs high on the sides | smooth base ball + 170 fine fuzz bumps per puff, centred higher/wider, joined to the cap |
| Hair cap | bumpy cap | smooth close cap, centre part | two smooth half-ellipsoids (faint centre crease), no bumps |
| Face | bulging cheeks, open toothy grin, small eyes | round face, wide closed smile, big brown eyes, thick brows | cheek 0.92, closed filled smile (mouth_w 0.125), eye_scale 1.22, brow width 0.028, warmer iris #4A2A14, blush 0.22 |
| Head / neck | head reaches 1.33 m, no visible neck | skull top ~1.30, chin ~1.03, short visible neck | skull_top 1.305, tee crew neck lowered |
| Glasses | thin wire, 3 dot stickers | big round thick gold frames, sticker chips along upper-outer rims | lens r 0.135hh, wire 0.017hh, 5 flat sticker chips per lens in the 4 sheet colours |
| Earrings | — | tiny gold stud | gold studs |
| Tee | puffy sleeves with green leaf-like blobs (overall shoulder caps) | fitted short sleeves | plain fitted short sleeves; overall built without shoulder caps |
| Overall | tube straps, long straight tube skirt below the knee | flat straps, bib, gold buttons, A-line skirt above the knee | flat ribbon straps over the shoulders, bib, flat gold buttons, A-line skirt hem 0.43 m (knee 0.32) |
| Socks | to the knee | cream socks to mid-shin with a fold | sock top 0.185 m + folded cuff band |
| Sneakers | terracotta | terracotta, white sole/laces | same colours, chunkier (1.16) |
| Clipboard | blue paper lines, held high under the chin | wooden board, big silver clip, gold stars + silver star + frog, no lines, held at chest/waist | rounded board, large clip with ring, 3 gold 5-point stars + 1 silver, frog sticker (eyes + spots), lines removed, held in a crossed-arm hug (see Clip changes) |

## Clip changes (v2 arm/hand keys + board placement)
Allowed by the clip-change request: only keyframe values on the arm/hand bones were changed. Clip names (idle, walk, sit), frame ranges, key counts and frame times, the channel set, and the bone names, hierarchy and rest pose are all identical to v1. Non-arm bone keys are identical too (max diff 0). `check_v2.py` checks all of this and lists the changed arm bones as INFO. Held props are still parented to the hand bone, or for Pippa's board to UpperChest, so they follow the clips. Clearance was measured over every frame of idle, walk and sit with `_build/v2_gpe/pose_probe.py`.

**Bones changed:** Left/Right UpperArm, LowerArm and Hand in idle, walk and sit.

**Pose parameters** (the same in all three clips; `build_pippa_v2.py` `HUG`): a crossed-arm hug. The right forearm crosses lower and the left forearm crosses on top, as in the concept. Hands are at the opposite board edges.

| Key | v1 (`V1`, both sides) | v2 Right | v2 Left |
|---|---|---|---|
| arm_fwd | 28 (+0.1 × swing) | 50 (+0.05 × swing) | 71 (+0.05 × swing) |
| arm_out | 8 | -4 | 0 |
| elbow | 92 | 75 | 75 |
| arm_twist | 40 | 100 | 100 |
| wrist | 0 | 25 | 25 |

**Board:** prop transform only; no bone, weight or clip change. It is still parented to UpperChest. `BOARD_ADJ`:
- dy +0.04: 4 cm closer to the chest
- dz +0.05
- tilt -18° → -4°, near upright

The board moved from (0, -0.161, 0.767) to (0, -0.121, 0.817) m, so it sits inside the hug, against the chest.

**Results** at idle frame 0:
- v1 palms were at (±0.04, -0.25, 0.88): pinching the top edge.
- v2 palms: left (-0.09, -0.22, 0.90), right (+0.10, -0.17, 0.83). These are crossed: each hand is on the opposite side, wrapped at the board edges.

**Clearance** over all frames:

| Check (m) | idle | walk | sit |
|---|---|---|---|
| Forearm in front of the board face (≥0 means no contact, 3 cm axis margin) | R +0.007, L +0.059 | R +0.005, L +0.057 | R +0.011, L +0.061 |
| Forearm vs forearm where they cross (≥0) | +0.008 | +0.002 | +0.008 |
| Forearms vs torso | R +0.033, L +0.084 | ≥ +0.031 | ≥ +0.036 |
| Hands vs torso | ≥ 0.05 | ≥ 0.05 | ≥ 0.05 |
| Arms vs thighs/head | ≥ 0.135 | ≥ 0.135 | ≥ 0.135 |

No clipping in idle, walk or sit.

**Renders:** `pippa_compare.png` and `pippa_face.png` were re-rendered with the same cameras (face hz 1.18). The board's top clip shows at the bottom of the face crop.

## Remaining mismatches (locked by keeping the v1 skeleton)
- **Hug height.** The concept crosses the arms over the lower half of the board (around the waist). The rig's elbows can't go below about 0.85 m (shoulder 0.98 m), and lower elbows collide with the board's side edges. So the forearms cross the board's upper-middle (0.83–0.90 m), and the board was raised 5 cm to keep it hugged.
- **Hands.** They show a little past the board edges and point slightly forward/down instead of lying flat on the board.

## Face pass (partial, stopped on request 20:21 UTC+2)
- Skin #7A4A2A -> #A85C32 (face texture + M_Skin): lighter/warmer, toward the concept's sampled mid-face browns; not darker.
- Ears shown like the concept: hair cap raised (centre z .07hh -> .12hh, radii .405/.445/.445 -> .400/.445/.425 hh), back-of-head ellipsoid pulled behind the ears (y .13 -> .17hh, radii .385/.33 -> .37/.30 hh), ear_s 1.12 -> 1.3.
- Mesh/texture only; skeleton, clips and arm keys same as the clip-fix build. check_v2 ALL PASS.
- Not done: hairline edge still slightly ragged; no glb size reduction.

## P3 smoothing + face pass (2026-10-28)
Build: work/p3/src/build_pippa_p3.py (private copy), using v2/_build/smooth_head.py read-only (sha256 09b9fdbf…a00a, unmodified).
Rig/clips unchanged: check_v2 ALL PASS; arm/hand key diffs are identical to the pre-P3 v2 (the hug + board fix is kept).
Tris 84,864 (was 69,280), glb 3.60 MB (was 8.06 MB).

Fixed in P3
- Smoothing: smooth_head applied to the head, neck and clothing (metaball head with registered lids and lips, cloth subsurf, bevels).
- Hairline: an exact boolean cut along an arched hairline replaces the ragged edge, so the edge is now clean and even.
- Ears: real ear forms (a flared shell plus a root blend) stick out at eye-to-nose height as in the concept. The studs are moved onto the lobes.
- Smile: wider mouth (mouth_w 0.185) with a fuller rounded lower lip, a darker lip line and a soft highlight.
- Cheeks: the bulges are gone (cheek 0.80 on the smooth head). The face is wider and rounder (jaw_w 1.06, chin_w 1.2).
- Skin: #A35C36, sampled from the concept forehead and nose (#B26233 and #AF6637), balanced toward the cheeks. It is no longer dark or orange.
- Brows: thicker and more arched. Stickers: flatter on the frame rim.

Still different
- No centre hair part. The hair is untextured to keep the glb small.
- The hug still sits on the upper middle of the board, and the hands still extend past its edges. The rig locks this; clips were not touched in P3.
- The pose is a crossed-arm forearm hug, not the concept's hands-cupped hug.
- The puffs are smooth noise blobs, not fuzzy coils.
- The glasses stickers are bead-like and not painted patches.
- The lens rim casts a light shadow on the cheek in the 3/4 view.


---

# Pippa P3 notes
- Work dir: work/p3/. Backup of the pre-P3 state: backup_before_p3/.
- Scripts: work/p3/src/ holds private copies.
  - build_pippa_p3.py: P3 knobs, hair_cut, shared_smooth, TRI_CAP, ears/studs and the lip overlay.
  - build_v2.py: OUTDIR and a real tri count.
  - make_sheets_pippa_p3.py.
  - No shared script was edited. v2/_build/smooth_head.py is loaded read-only.
- Rebuild:
  - `cd work/p3/src && python3 build_pippa_p3.py` paints tex/pippa_face.png.
  - `OUTDIR=<dir> blender -b -P build_pippa_p3.py` builds the model.
- Iterations:
  - r1: smoothing plus the hairline cut. 113.9k tris (over budget); ears hidden; thin smile.
  - r2: lower budgets and TRI_CAPs, giving 84.8k tris. Wider mouth, ear forms added, but the ears were still inside the skull.
  - r3 (final): ears moved out and enlarged, fuller lower lip, mouth_w 0.185.
- Renders:
  - work/p3/r3_{face,face34,front,side,single}.png
  - pippa_render.png = `render.py single` (default yaw -64, same camera as v1).
- check: pippa_check.txt shows ALL PASS. Arm key diffs are identical to the pre-P3 v2.
