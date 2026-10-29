# Dottie: v1 vs concept, and what v2 changes

The concept is `assets/concepts/customers/dottie_sheet.png`. Model colours are the sheet's palette swatches unless a line says otherwise.
Build script: `_build/build_dottie_v2.py`. It is a copy of the v1 dottie recipe. Shared helpers are in `_build/v2_gpe/`, a private copy. No shared script was edited.

## Differences found (v1 → concept) and fixes in v2
| Area | v1 | Concept | v2 fix |
|---|---|---|---|
| Face | Glasses, small droopy eyes (lid 0.24, scale 0.9), thin brows, small mouth | No glasses. Big round dark-brown eyes, arched grey-brown brows, rosy cheeks, wide closed smile, forehead lines, smile folds | Glasses removed. eye_scale 1.12, lid 0.10, iris #4A2A18, brow #A39484 and thicker, wider smile (mouth_w 0.12), lip #C27466 filled, forehead lines and smile folds (new faces.py options), blush #E07A62 at 0.5 |
| Head size | Head about 0.28 m tall, small relative to body | Large head: chin about 1.17 m, dome about 1.55 m | Head mesh scaled ×1.17 (skull top 1.53, chin 1.20), wider jaw and cheeks. The head is rigid on the `Head` bone, so the bones did not change |
| Hair | Cloud of bumps, bun hidden | Silver hair combed back, side volume over the ear tops, round bun on top/back that shows above the dome from the front | Smooth crown with a higher hairline, a swept-back roll around the face, side volume and waves, and a large bun (r 0.078 m) with three wrap rolls. Its top is at 1.59 m |
| Hair colour | #E3DCD2, read as white | Warm silver-grey | #CDC2B5. This sits between the swatch #E3DCD2 and the painted mid-tone, because the swatch renders as pure white under the game lights |
| Earrings | Studs | Small gold hoops in the art (the text says studs; the art wins) | Small gold hoops |
| Blouse | Plain torso, cuffs | Terracotta collared button-up, pointed collar, skin V at the throat, buttons, rolled cuffs | Pointed collar wings, throat V, 7 buttons, rolled cuff bands |
| Vest | Hem high (0.64 m), shiny metal "rail" stripes, full rings | Long vest, hem about 0.585 m, open front, terracotta piping, flat grey bands at about 0.69/0.81 m and two vertical bands per side | Hem 0.585 m. Flat matte bands (#B9B0A8, a little darker than swatch #CFC6BE so they don't read white) follow the open front. Vertical bands front and back at x = ±0.125 m. Terracotta piping (#B5603A) on the front edges and hem |
| Body | Flat front to back (depth about 0.25 m) | Round, deep belly and bust (side depth about 0.4 m) | chest/waist/hip depth (ry) .13/.135/.135 → .165/.178/.17. Width a little bigger (.19/.19/.21) |
| Slacks | Slim, rounded hem | Straight slate slacks, cropped at about 0.12 m with turn-up cuffs | Straight legs (thigh .108, knee .094, hem .082), flat hem at 0.112 m with a 2.7 cm turn-up, ankle skin below |
| Shoes | Small generic shoes | Brown penny loafers | Wider loafer (#6B4A3A) with a dark penny strap and a darker sole |
| Paddle | Handle too long (overall about 0.51 m), border too thin | Octagon 0.25 m across × 0.03 m, total 0.42 m, handle Ø0.035 m, cream border | Octagon 0.25 m across flats, red-orange face #D9765F, cream rim #F4E9D8 at 0.026 m, wood handle #A86A3A Ø0.035 m, overall 0.42 m |

## Clip changes (v2 arm/hand keys)
Allowed by the clip-change request: only keyframe values on the arm/hand bones were changed. Clip names (idle, walk, sit), frame ranges, key counts and frame times, the channel set, and the bone names, hierarchy and rest pose are all identical to v1. Non-arm bone keys are identical too (max diff 0). `check_v2.py` checks all of this and lists the changed arm bones as INFO. Held props are still parented to the hand bone, or for Pippa's board to UpperChest, so they follow the clips. Clearance was measured over every frame of idle, walk and sit with `_build/v2_gpe/pose_probe.py`.

**Bones changed:** RightUpperArm, RightLowerArm and RightHand in idle, walk and sit. The left arm is unchanged.

**Pose parameters** (charkit `pose_frame` arm keys on the right side, the same in all three clips; `build_dottie_v2.py` `HOLD`):

| Key | v1 (`V1`) | v2 (`HOLD`) |
|---|---|---|
| arm_fwd | 18 (+0.15 × clip swing) | -5 (+0.15 × clip swing) |
| arm_out | style 12 + 4 | style 12 + 35 (upper arm out to the side) |
| elbow | 105 | 80 |
| arm_twist | -10 | 10 |
| wrist | -10 | -30 (keeps the paddle upright) |

**Results** at idle frame 0. v2 meets the concept target: hand about 0.89 m, octagon centre about 1.16 m, held out to the side.

| | v1 | v2 |
|---|---|---|
| Right palm | (-0.26, -0.27, 1.12) m, in front of the shoulder | (-0.36, -0.23, 0.96) m, out to her side |
| Elbow | 0.96 m | 1.03 m, out at x -0.34 |
| Paddle span | z 1.04–1.46 m, octagon centre about 1.31 m, beside the head | z 0.89–1.30 m, octagon centre about 1.16 m, chest height, vertical |

**Clearance:**
- Right forearm vs torso: idle +0.081, walk +0.083, sit +0.091 m (v1 -0.008).
- Paddle vs torso: at least 0.149 m.
- Paddle vs head and legs: at least 0.191 m.
- No clipping in idle, walk or sit (see `v2/dottie/dottie_render.png` and the walk/sit stills).

**Renders:**
- `dottie_face.png` was re-rendered with the same camera, hz 1.36 at -18°. The paddle no longer covers the left of the face.
- `dottie_compare.png` was regenerated.

## Mismatches left (deliberate: skeleton must stay identical)
- **Paddle arm pose.** Now matches the concept: out to the side, octagon centre about 1.16 m. The rig's shoulder is higher (1.19 m), so the elbow sits about 0.2 m higher than in the concept (1.03 m vs about 0.82 m) and the upper arm is lifted out more.

## Check
Result is in `dottie_check.txt`: ALL PASS. 23 bones with the same names, hierarchy and rest pose (difference 0). Clips idle, walk and sit have the same names, frame ranges, channel set (230), key counts and key times. Non-arm keys are identical. Only the RightUpperArm, RightLowerArm and RightHand key values differ (INFO, max quaternion component diff 0.277).

## P3 pass (smoothing + face to concept), Oct 28 2026
Build: `v2/dottie/work/p3/build_dottie_p3.py`. It is a copy of `_build/build_dottie_v2.py`. Shared `v2/_build/smooth_head.py` is loaded by path and is not edited. The previous files are in `backup_before_p3/`. Details are in `P3_NOTES.md`.

| Area | Before P3 | P3 fix |
|---|---|---|
| Head | Primitive head, lumpy | Shared smooth metaball head and neck, applied subsurf on cloth, and bevels |
| Skin | #C98A5E, rendered darker and oranger than the concept | #E9AE7E, sampled from the lit concept face (about 247,177,124). Renders at about (245,186,137), matching the concept nose and cheek tone |
| Cheeks | cheek 1.12, puffy | cheek 0.78, jaw_w 1.08 |
| Hair | Helmet roll around the face, plus a scalp strip | Crown cap set back (y 0.06, ry 0.46). 21 separate soft combed-back locks run from the hairline into the bun, with 4 side strands per side over the ear tops and nape tucks. A boolean hairline arch gives a clean edge. Bun and wraps kept |
| Ears | Hidden | Soft ear forms (shell, helix rim, lobe) sit just outside the wide face. Lobes and hoops show below the hair, as on the concept |
| Smile | Thin short line | Custom painted wide closed upturned smile: thin upper lip, fuller pink lower lip, dimpled corners. Sculpted lips use mouth_w 0.20 |
| Lines | Painter age lines read as whiskers | Painted arcing smile folds around the mouth corners, soft crow's feet and under-eye creases. Forehead lines kept |
| Brows/nose | Thin flat brows, small nose | Brows thicker and arched (#8A7A6C, w 0.026, arch 0.03). Nose 1.22 |
| Size | 67.9k tris, 7.5 MB | 83.4k tris, 3.34 MB (head and neck decimated with UVs kept, per-vertex AO, constant UV on untextured parts) |

Rig and clips are unchanged, and the arm/paddle HOLD pose is kept. check_v2 gives ALL PASS (INFO: only the RightUpperArm, RightLowerArm and RightHand key values differ, max 0.277, the same as before).

### Mismatches left after P3
- Hair is smooth soft locks. It does not have the concept's fine comb-strand texture. There is a soft contact shadow line along the hairline, and the temple wings are a little blobby.
- The face is still rounder and wider at the jaw than the concept, and the chin is smaller.
- The nose is smaller and less bulbous than the concept.
- The eyes are more cartoon-glossy, without the concept's under-eye bags.
- The ears are a little large and stick out slightly more than on the concept.
- The paddle arm pose is unchanged from v2: the elbow is higher than on the concept because of the rig.


---

# Dottie P3 notes (Oct 28 2026)
- **Work dir:** `v2/dottie/work/p3/`
  - `build_dottie_p3.py`: run with `python3` to paint, then `blender -b -P` to build into `out/`.
  - `iter.sh <tag>`: paint, build, face renders, and a comparison sheet in `renders/`.
  - `compose_p3.py`: compare and face sheets.
  - `tex/dottie_face.png`
  - `build_*.log`
- **Shared scripts:** `v2/_build/smooth_head.py` is used without edits, loaded by path. The integration follows Kit's `shared_smooth_head`: SH OPTS head_voxel 0.0105, neck 0.016, cloth_budget_scale 0.10. Decimate caps per prefix, constant UV on untextured parts, per-vertex AO, and caps on the Head (17k) and Neck (2.2k) sculpts.
- **Hairline cut:** the idea comes from Wren P3 `face_cut`. It was re-written in `hair_cut()`.
- **Mouth:** the painter mouth is moved off-texture (`mouth_v=-2`, painter only) and `paint_mouth()` paints the concept smile. The sculpted lips still use the real mouth_w/smile.
- **Ears:** the shared head's ears sit inside Dottie's wide face, so a separate `Ears` group (M_Skin, rigid Head) is added.
- **Iterations** (renders/cmp_i*.png):
  1. smooth head + skin + locks;
  2. mouth_v bug: lips at -2 broke the head;
  3. fixed;
  4. ears + hair cut + own folds;
  5. softer folds, lower hairline, smaller ears;
  6. and 7. fold shape;
  8. tri caps (114k → 83k).
- **Result:**
  - `dottie.glb` 3,340,720 B, 83,448 tris (counted from the glb).
  - check_v2: ALL PASS.
  - Face close-up: `dottie_face.png` (concept | front | -18°).
