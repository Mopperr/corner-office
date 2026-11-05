# Wren v2: differences vs the concept sheet

Reference: the Wren concept sheet (front, side and face). It was used as visual reference only; no pixels were copied.
Build: `_build_v2_rocco_wren/` (`./run.sh wren`). Everything is procedural.

## Kept from v1
- The skeleton has 23 Godot-humanoid bones with the same names (checked against the v1 glb).
- Clips: idle 73, walk 33 and sit 73 keys at 30 fps.
- Y-up, facing +Z, with the origin at the feet. Uses `Wren_Body` and M_Face, with AO baked to vertex colours.
- The prop `Wren_Notebook` is parented to RightHand.
- Height 1.68 m, seat 0.476 m, hip 0.857 m, all the same as v1.

## Pass 1: what was changed to match the concept
- **Hair:** copper-auburn (#A0471D) chin-to-shoulder wavy bob, with a side part and a side-swept fringe toward her left temple. It is built from 30 wavy locks with curls at jaw level.
- **Face:** freckles across the nose and cheeks, brown eyes with lashes, soft rose lips with a small smile, and cheek and nose blush.
- **Sweater:** long, loose cream chunky knit (#EEDFC4). It has vertical knit ribs, a ribbed hem, ribbed cuffs and knit lines on the sleeves. The sleeve knit is skinned to the arms, which fixed the stray strands at the hips.
- **Scarf:** sage (#8C9F72) scarf with a thick triple wrap at the neck. One long ribbed tail hangs down her left front, with a fringe.
- **Trousers:** brown corduroys with vertical wales, a rolled cuff, a high waistband, a button and a fly seam.
- **Boots:** brown lace-up ankle boots with a dark sole.
- **Props:** a sage notebook (0.09 × 0.14 m) with an elastic band and pages, held in her right hand. It has a black pen with a gold ring and clip, and a folded napkin with three "haiku" ink lines tucked into the top. There is an ink smudge on her right index finger.

## Pass 1: still different (honest list)
- The concept's front tuck of the sweater over the visible waistband is not modelled. The hem stays level, with the waistband and button just below it.
- The pelvis volume pokes forward slightly under the hem and reads as a small apron at the crotch.
- Only one scarf end is visible in the concept, so the second end is treated as tucked in or behind.
- The napkin is not drawn in the concept figure; it is tucked into the notebook as described in the brief. The pen's nib orientation is a guess.
- The hair is a little helmet-like and covers more cheek than the concept. The hairline edge is jagged where the face region is clipped.
- The face looks blocky and lumpy, with a big round nose blob and blush. Pass 2 addresses this.
- The tris are 64.8k triangulated in the glb (v1 54.8k). Meta `tris` uses the v1 polygon convention: 56,446 vs v1 52,309.


---

# Wren — P3 (smoothing pass + rig-drift fix), 2026-10-28

- **Rig**: skeleton/rest pose now taken from v1 `_build/config.py` (RIG LOCK) → `check_v2.py` = **ALL PASS, rest pose diff 0.00e+00 m** (the pre-P3 v2 drifted up to 1.1 cm on spine and above).
  Bone names, hierarchy, clip names, frame ranges and all non-arm keys identical to v1. Arm keys (L/R UpperArm, R LowerArm) differ — notebook held at chest per concept; this is the only change check_v2 allows.
- **Mesh only**: built with `work/p3/src/build_wren_p3.py` (private copy) + `recipes_wren_p3.py` + `p3_hooks.py`; Art's `v2/_build/smooth_head.py` reused unedited via smooth_rw.
  - clean boolean hairline (no jagged voxel cut), extra curl volume on crown/sides
  - knit ribs / scarf ribs / cord wales projected onto the smoothed garment surface (no floating bars); off-surface tube ends dropped
  - notebook cover now visible sage green (was eaten by remesh → white pages showed)
  - constant UV on untextured parts + per-vertex AO → 3.40 MB (was 9.85 MB)
- 87,385 tris (budget ~90k), glb 3,401,092 B.
- Files: wren.glb, wren_render.png (v1 camera), wren_compare.png, wren_face.png (face close-up), wren_check.txt. Previous files in `backup_before_p3/`.
- Remaining vs concept: hair still reads as one sculpted mass (not individual curls), ears covered (concept shows her left ear); trouser rolled cuff reads as a puffy lower-leg band, not a crisp turn-up; small crotch "apron" fold; hand around notebook is a simple mitten; sleeve-cuff ribs slightly fin-like; eyes larger/more cartoon than concept.
