# Theo — v1 vs concept, and v2 fixes

Script: `_build/build_theo_v2.py` (new copy; shared/original scripts untouched). Skeleton, bone names, idle/walk/sit clip names, frame ranges and keys identical to v1, except the right arm/hand key values (see Clip changes and `theo_check.txt`: ALL PASS).

| Area | v1 | Concept | v2 |
|---|---|---|---|
| Hair | curly pompadour | straight, messy, forehead fringe | crown + back + sides, 9 fringe locks following skull, 14 soft tufts, side flicks |
| Face shape | round, bulging cheeks | slim oval | cranium 0.95, jaw 0.90, cheek 0.85, ear 1.1, neck 0.92 |
| Eyes / brows | big round eyes, thin brows | sleepy half-lidded eyes, thick straight brows | lid 0.52, eye_scale 0.95, brow width 0.021 low arch, soft smile + light smile folds |
| Shoulders / sleeves | puffy shoulder balls | flat, short hemmed sleeves above elbow | flat-shouldered short sleeve ending 60% down upper arm, trim hem band; green long-sleeve under-layer |
| Neckline | small V + green blob | deep V with trim, green tee showing | deep V scrub top with #56667C piping on V and hem; green under-layer visible |
| Pockets / pens | none | chest pocket with 2 pens, hip pocket | chest pocket + 2 pens (silver clips) + lower hip pocket |
| Trousers | — | straight wide scrub trousers | trouser2 straight leg, flat hem at ankle |
| Sneakers | small | chunky white sneakers | chunky 1.14, taller sole |
| Thermos | plain cylinder | tapered travel mug, flip lid | tapered body, lid with flip tab, dark base band |

## Clip changes (v2 arm/hand keys)
Allowed by the clip-change request: only keyframe values on the arm/hand bones were changed. Clip names (idle, walk, sit), frame ranges, key counts and frame times, the channel set, and the bone names, hierarchy and rest pose are all identical to v1. Non-arm bone keys are identical too (max diff 0). `check_v2.py` checks all of this and lists the changed arm bones as INFO. Held props are still parented to the hand bone, or for Pippa's board to UpperChest, so they follow the clips. Clearance was measured over every frame of idle, walk and sit with `_build/v2_gpe/pose_probe.py`.

**Bones changed:** RightUpperArm, RightLowerArm and RightHand in idle, walk and sit. The left arm is unchanged.

**Pose parameters** (right side, the same in all three clips; `build_theo_v2.py` `HOLD`):

| Key | v1 (`V1`) | v2 (`HOLD`) |
|---|---|---|
| arm_fwd | 14 (+0.2 × swing) | 0 (+0.2 × swing): upper arm hangs |
| arm_out | style 7 | style 7 + 6 |
| elbow | 80 | 85: forearm level and forward |
| arm_twist | 22 | 15 |
| wrist | 0 | -20 (keeps the mug upright) |

**Results** at idle frame 0. Concept: mug centre about 1.11 m, in front of the right hip, forearm level.

| | v1 | v2 |
|---|---|---|
| Right palm | (-0.13, -0.37, 1.16) m | (-0.20, -0.30, 1.10) m |
| Thermos | z 1.04–1.30 m, chest height | z 0.98–1.23 m, centre about 1.10 m, waist height, upright |

**Clearance:**

| Check | idle | walk | sit |
|---|---|---|---|
| Forearm vs torso | +0.009 | +0.009 | +0.029 (v1 +0.006 / +0.002 / +0.030) |
| Thermos vs torso | 0.163 | 0.140 | 0.178 |
| Thermos vs thighs/head | 0.178 | 0.147 | 0.061 (v1 0.086) |

No clipping.

**Renders:** `theo_compare.png` and `theo_face.png` were re-rendered with the same cameras (face hz 1.66, so the face is unaffected).

## Remaining mismatches (locked by keeping the v1 skeleton)
- The thermos is now at waist height, as in the concept. The rig's shoulder and elbow sit about 5 cm higher than the concept's, so the mug is held about 4 cm further out to the side (palm x -0.20 vs about -0.11).

## P3 smoothing / face pass (2026-10-28)
Built with Art's shared `_build/smooth_head.py` (unedited, loaded by import) via `work/p3/src/build_theo_p3.py`. Mesh and textures only; rig, clips and the HOLD arm keys are unchanged (check_v2 ALL PASS).

**Fixed**
- Helmet hair → a full tousled volume: a scalp shell with 22 tapered locks radiating from the crown, a crown fill and temple puffs (wider than the face, as in the concept). It is boolean-cut to a hairline arch and to ear windows. A separate fringe of 9 locks falls onto the upper forehead, with pointed tips at varied heights, swept slightly toward his left.
- Thin-line smile → a wider, softer closed-lip upturned smile: smile 0.040, mouth_w 0.115, filled lower lip #C07A66, smile folds.
- Ears barely showing → ears are clearly visible in front and side views. smooth_head ear=1.4, plus an extra flared outer-rim shell (EarsP3), and the hair is cut away around both ears.
- Bulging cheeks → a slimmer oval face: cheek 0.55, jaw_w 0.84, chin_w 0.85.
- Grey skin → the skin is sampled from the concept (#E2A676; concept #E0A678), so it is not darker or oranger. The baked AO is lifted (0.25 + 0.75·ao) so the face no longer reads grey.

**Remaining mismatches**
- The palm sits about 4 cm too far out. This is locked by the kept skeleton and HOLD keys (see above).
- The hair is still a stylised solid mass. Strands only read as broad locks and grooves; it lacks the concept's fine flyaway strands. A few remesh lumps remain at the fringe tips and the temples.
- The concept's sleepy half-lids are painted, not modelled. The nose is a soft blob (the smooth_head nose floor is 0.75).
- The neck still reads a little long or thick next to the concept. Its length is set by the rig.


---

# Theo P3 notes (smoothing + face pass)
- Backup of all pre-P3 files: `backup_before_p3/`.
- Working dir: `work/p3/`.
  - `src/` holds copies of `_build/v2_gpe` scripts plus `build_theo_p3.py`. No shared script was edited.
  - `smooth_head.py` is imported from `_build/` unchanged.
  - `it.sh <tag>` paints, builds and renders face close-ups at yaw 0/-18/-70, then makes the strip `it_<tag>.png` (concept face on the left).
- Iterations:
  - a1: ears, face and skin pass.
  - a2–a3: boolean-cut scalp shell, plus fringe.
  - a4–a5: crown locks, temple puffs, ear rim, crown fill.
  - a6–a8: fewer, thicker fringe locks; coarser voxel to cut decimation drips; temple wisps removed.
  - Final = a8.
- Key parameters:
  - SKIN #E2A676
  - C: jaw_w 0.84, cheek 0.55, chin_w 0.85, nose 0.95, ear 1.4, brow_ridge 0.45
  - face: smile 0.040, mouth_w 0.115, lip_fill, lid 0.50
  - AO lift 0.25 + 0.75·ao
- Hair groups:
  - HairShell: voxel 0.0042, cap 7000 tris. Boolean cut by `cut_hair()`, which removes the face below the hairline arch (0.15 hh centre, 0.04 hh at the temples) and both ear windows.
  - HairFringe: 9 locks, about 4000 tris.
  - EarsP3: about 840 tris, M_Skin.
- Result: 87,736 tris, glb 3.67 MB. check_v2 ALL PASS against the v1 `customers3d/theo.glb`; only the kept HOLD arm keys differ (INFO).
- Renders:
  - `theo_render.png`: `render.py single` (v1 camera, yaw -64).
  - `theo_compare.png`: concept, then the model front and side at yaw 0/-90, with a face row.
  - `theo_face.png`: concept face, then the model face at yaw 0/-18, hz 1.66.
