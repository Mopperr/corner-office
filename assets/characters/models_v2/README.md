# Character models v2 (8 regulars + Dana), add-only, final-so-far (Oct 28 2026)

Created by Andrew's Helpers (Grok Bots)

**Status: for review.** This replaces the earlier, outdated `team/characters-v2-for-pr21` bundle
(commit 52694a3). Nothing in the game loads these yet, and no existing file is edited or deleted. Wiring
them in (for example from `customers_spec.json`) is Claude's call.

Everything is procedural: Blender 4.2.3 geometry, voxel remesh and subdivision, FK clips, and faces
painted with Pillow. **No image generator was used for any file in this folder.** The concept sheets are
AI-generated and **internal-only**. They were used as visual reference only (no pixels copied into any
texture) and are **not included** here. Comparison sheets (`*_compare.png`, `*_vs_concept.png`,
`*_face_smooth_compare.png`) contain concept pixels, so they are left out on purpose.

## Files per character
`<id>/<id>.glb` (Dana: `dana/dana_matched.glb`), `<id>_meta.json` (height, seat height, hip height, clips,
prop bone), `<id>_render.png` (a render of our own model only), `<id>_notes.md` (the builder's notes:
differences from the concept and what is still different) and `<id>_check_v2.txt` (the automated
v1-vs-v2 rig and clip check, re-run on Oct 28 2026 ~22:12 Asia/Jerusalem for this bundle).
`SMOOTH_PIPELINE.md` documents the shared smoothing pipeline (Art's `smooth_head.py`).

Steve and Lorna have **no render** in this folder: their only renders on hand predate the smoothing pass,
so they would be misleading. Dana's render is the post-smoothing 3/4 render.

## Status table
Triangles counted from the glTF index buffers.

| id | name | glb | size | tris | state | rig/clip check vs v1 |
|---|---|---|---|---|---|---|
| dana | Dana (player) | dana_matched.glb | 6.97 MB | 89,656 | **Smoothed** | ALL PASS |
| steve | Steve | steve.glb | 6.81 MB | 83,468 | **Smoothed** | ALL PASS |
| lamp_lady | Lorna | lamp_lady.glb | 6.67 MB | 82,292 | **Smoothed** | ALL PASS |
| keyclackr | Kit | keyclackr.glb | 3.34 MB | 88,072 | **Smoothed** | ALL PASS (no clip changes) |
| dottie | Dottie | dottie.glb | 3.34 MB | 83,448 | **Smoothed** (P3) | ALL PASS (arm/hand keys changed on purpose) |
| theo | Theo | theo.glb | 3.67 MB | 87,736 | **Smoothed** (P3) | ALL PASS (arm/hand keys changed on purpose) |
| pippa | Pippa | pippa.glb | 3.60 MB | 84,784 | **Smoothed** (P3) | ALL PASS (arm keys changed on purpose) |
| wren | Wren | wren.glb | 3.40 MB | 87,305 | **Smoothed** (P3, rig-locked to v1) | ALL PASS (arm keys changed on purpose) |
| rocco | Rocco | rocco.glb | 9.57 MB | 86,112 | Smoothed head (pass 2, rig-locked to v1); **look does not match the concept**, see below | ALL PASS (upper-arm keys changed on purpose) |

"Smoothed" = subdivision, sculpted rounded head forms and a painted face texture, using Art's
`smooth_head.py` (see `SMOOTH_PIPELINE.md`).

## Rig and clips (same as v1)
- Godot `SkeletonProfileHumanoid` names, 23 bones: Root, Hips, Spine, Chest, UpperChest, Neck, Head,
  Left/Right Shoulder, UpperArm, LowerArm, Hand, Left/Right UpperLeg, LowerLeg, Foot, Toes.
  **Pippa uses the same bone names on a child-sized skeleton.**
- glTF animations `idle` (73 keys), `walk` (33 keys) and `sit` (73 keys) at 30 fps, in place, **no root
  motion**. Turn loop on for all three at import.
- Y-up, metres, origin at the bottom centre between the feet, model faces +Z (Godot "model front").
- One skinned body mesh `<Name>_Body` plus one rigid prop mesh on a bone (Dana has no prop). Each glb also
  carries a small helper mesh named `Icosphere` (it is in the v1 files too). The face is an embedded
  Pillow-painted texture.
- `check_v2.py` (Blender) compares each v2 glb with its v1 glb strictly: bone count/names, hierarchy, rest
  pose, clip names, frame ranges, channel sets, key counts and times, and key values on all non-arm bones.
  Key values may differ only on Left/Right UpperArm, LowerArm and Hand (the approved held-prop change).
- Minimal loader:
  ```gdscript
  var scene := load("res://assets/characters/models_v2/%s/%s.glb" % [id, id]) as PackedScene
  var npc := scene.instantiate()
  var ap := npc.find_child("AnimationPlayer", true, false) as AnimationPlayer
  ap.play("idle")
  ```
  (Dana's file is `dana/dana_matched.glb`.)

## Known mismatches with the concept (honest)
- **Dottie:** paddle elbow still higher than the concept (locked by the v1 shoulder height and clips).
- **Theo:** thermos palm still about 4 cm further out than the concept.
- **Pippa:** hug position on the board is still off (hands sit past the board edges).
- **Wren:** arm keys are intentionally changed so she holds the notebook at her chest. Hair still reads as
  one sculpted mass, ears covered.
- **Rocco:** the look does **not** match the concept. Locking the v1 joints keeps him about 6.1 heads tall
  (concept about 4.8), the beard edge is ragged, the nose is small and flat, and the hair is a smooth cap
  rather than curls. A proportion variant (`rocco_proportion.glb`) is being reworked; it is **not** included
  because, as of this bundle, it fails `check_v2` (rest pose moved by up to 0.116 m, idle key count/times
  and non-arm keys differ), and it was still being rebuilt. It may follow in a later bundle.
- **Dana, Steve, Lorna, Kit:** faces measured shorter than the concept, noses and mouths smaller; see each
  `<id>_notes.md`.
