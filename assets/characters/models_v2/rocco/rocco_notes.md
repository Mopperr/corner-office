# Rocco: v1 vs concept, and v2 fixes

Build: `_build_v2_rocco_wren/` (copied scripts; shared `_build/` untouched). `SMOOTH=1 HEADVOX_F=0.048 RW_SCALE=0.85`. Procedural only; concept art used as reference, no pixels copied.
Skeleton, bone names, hierarchy, rest pose, clip names, frame ranges, key counts/times and all non-arm keys are identical to v1. Only the UpperArm key values differ; see `rocco_check.txt` (check_v2.py: ALL PASS).

| Area | v1 | Concept | v2 (pass 2) |
|---|---|---|---|
| Beard | big round volume | short full beard on jaw/chin, moustache | shell grown off the head surface (offset + solidify + remesh), separate moustache |
| Head | ellipsoid union, creased | wide, jowly, bulbous nose, big ears | smooth_head metaball forms -> voxel remesh -> subsurf -> laplacian |
| Skin | #B27243 | warm tan | #C68558 |
| Shirt | plain | chambray short sleeve, collar, placket, pocket, rolled cuffs | all present, cloth remesh + subsurf |
| Shorts/socks/shoes | basic | brown shorts, striped crew socks, canvas sneakers | all present |
| Satchel | simple | tan cross-body, flap, buckle, mail sticking out | all present; strap is a non-remeshed sweep |
| Watch | none | left wrist | steel case on leather band |

## Clip changes (v2 arm keys)
The bones changed are LeftUpperArm and RightUpperArm in idle, walk and sit (max diff 0.060). These are arm_out offsets, R +7° and L -1°, so the arms clear the wider shirt and satchel. All other keys are identical (max diff 0).

## How the rig drift was fixed
- Pass 1 and early pass 2 called `skeleton()` with my own proportions, `P(1.72, 4.8, 0.47, 0.112, 0.062, ua=0.19, la=0.165, hand=0.066, foot=0.158)`. That moved the joints, giving a rest-pose diff of 1.79e-01.
- `build.py` now loads the shared `_build/config.py` read-only and uses v1 `CHARS["rocco"]["p"]` for `skeleton()`. This gives the exact v1 J/Pm/info.
- The recipe style had `stride=19`; v1 uses `stride=20`. That caused the walk non-arm key diff of 8.6e-03. It now uses the v1 style exactly.
- Body shape changes are mesh-only.

## Still different (honest)
- Locking the v1 joints keeps the v1 proportions: about 6.1 heads tall with v1 arm lengths and shoulder width. The concept is about 4.8 heads with a bigger head and shorter limbs, which cannot be matched without moving joints.
- The concept's head juts forward. Ours is upright because of the v1 Head bone.
- The beard shell has a ragged, stringy edge at the sideburns and lower rim, and reads as a solid dark band. The concept's soft stubble cannot be reproduced with a solid mesh plus vertex colour.
- The nose is much smaller and flatter than the concept's big bulbous nose, and is partly hidden by the moustache.
- The ears read small. The hair is a single smoothed cap with jagged fringe locks rather than tight curls.
- Tris: 86,112 triangulated in the glb (the checker counts 86,192 including the helper Icosphere). Meta `tris` is 47,602 in the polygon convention. v1 is 68,746.
- smooth_head.py sha256 starts 09b9fdbf2f59 and was used read-only.
