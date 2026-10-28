# Kit (keyclackr): v2 concept-match and smoothing pass

Builder: `customers3d/_build/build_keyclackr_v2.py`. This is my own script; no shared scripts were edited.
Scratch work is in `/workspace/game/v2tmp/kit/`.
The pre-smoothing pass-1 backup is in `/workspace/game/v2tmp/kit/backup_pass1/`.

## Differences before this pass (v1 and Art v2 vs the concept)
- **Face:** blocky, primitive-built head with hard planes. Eyes small and flat. No proper grin. Brows thin.
- **Hair:** a smooth helmet (v1). Art's v2 was spiky blocks, missing the concept's messy fringe and top volume.
- **Hoodie:**
  - Too tight; no puffy sleeves or cuff bunching.
  - Hood collar too thin.
  - No V crossover.
  - Drawstrings missing or too short, with no aglets.
  - Kangaroo pocket missing or flat.
- **Wrist braces:** missing. The concept has dark fingerless braces.
- **Joggers:** straight tubes. The concept has a relaxed fit, a taper and knee folds, and ribbed ankle cuffs that bunch above the shoe.
- **Shoes:** too slim. The concept has chunky cream sneakers with a thick sole.
- **Backpack:** a generic box. The concept has a dark rounded pack with padded straps and chest buckles.
- **Keyboard:** not attached and not visible. In the concept, a cream/mustard mechanical keyboard is strapped to the pack.

## Fixes
- **Smoothing pass (Boss/Andrew steering).**
  - `charkit.Group.build` is monkeypatched locally in my script. Each group is voxel-remeshed and smoothed as before.
  - Then a SUBSURF modifier at level 1 (quality 3) is APPLIED.
  - Then an optional bevel is applied, followed by smooth shading and the UV re-projection.
  - All of this happens inside build(), BEFORE assemble() weights the mesh. Skinning and weights are therefore computed on the final subdivided mesh, and the export is plain skinned geometry with no live modifiers.
- **Head sculpt.** The shared Body2.head was replaced locally by a rounded sculpt:
  - cranium and back skull
  - soft cheeks and cheekbones
  - jawline and chin
  - brow ridge
  - nose bridge, tip and nostril wings
  - lip muzzle
  - upper eyelids
  - ears
  
  It uses a fine voxel size with 12 smooth iterations, plus subsurf.
- **Face texture.** Repainted at 1024 px with concept colours:
  - warm brown skin
  - dark brown irises
  - thick dark brows
  - wide open grin with teeth
  - soft blush
  - smile folds
  
  A Gaussian blur (0.9) was added so it reads smooth.
- **Hair.** Messy black hair built from tapered locks: 8 fringe locks swept to his right, 28 top clumps and 6 side clumps. It is subdivided and smooth.
- **Hoodie.**
  - Relaxed torso with a hem band.
  - Thick hood collar with a V crossover and back hood volume.
  - Trapezoid kangaroo pocket with slits.
  - Grey-blue drawstrings with metal aglets.
  - Puffy sleeves with bunch rings and cuffs.
- **Braces.** Dark fingerless braces run from the forearm over the palm.
- **Joggers.** Tapered legs with bunch rings, a knee fold and ankle cuff bands.
- **Shoes.** Chunky cream sneakers with a thick sole rim and laces.
- **Backpack.**
  - Rounded dark-navy pack with a front pocket, top handle and zips.
  - Padded straps that follow the shoulders.
  - Chest buckles.
- **Keyboard.** A 5×15 mechanical keyboard (cream, mustard and dark keys, beveled keycaps) is strapped with bungees to the back of the pack, keys facing out to his right. It is rigid on the Chest bone, so it moves with him in every clip.
- **Hard edges.** Every group is subdivided or beveled. The only exception is the neck: subsurf is off there because it caused shading streaks, but it is voxel-smoothed.

## Clip changes
None. Style and arm pose are identical to v1, and no arm or hand keys were changed (`keyclackr_check.txt`: ALL PASS).

## Remaining mismatches
- **Keyboard in front view.** The concept's front and side views disagree on where the keyboard sits. I matched the side view and the game camera, so the keyboard does not peek out at +X in the front view the way it does in the concept front view.
- **Hair.** Spikier and less swept than the concept's soft messy strands. Real hair cards would be needed to match it exactly.
- **Grin.** Painted rather than modelled, so it reads a bit cartoonish compared with the concept's natural smile. The hair also casts a strong shadow on the forehead in the close-up lighting.
- **Neck.** Slightly long and thin compared with the concept.
- **File size.** The glb is 12.3 MB (79k polys, about 155k tris) vs v1's 6.1 MB, because of the subdivision. It can be reduced by lowering `bfac` in `install_smoothing()`.
- **Art's earlier v2 glb.** It was overwritten by my pass-1 build before the backup instruction arrived. Art's renders are kept as `v2tmp/kit/art_*.png`, and Art's `_build/v2_*.py` scripts can regenerate it.

## Pass 3 (final, shipped): Art Specialist's shared smooth_head pipeline
The previous output is backed up in `v2/keyclackr/backup_pass2/`.

**Head and smoothing**
- The head and neck now come from `v2/_build/smooth_head.py`, loaded by path and not edited: metaball forms, lids and lips placed on the painted face, then remesh, subsurf and Laplacian smoothing.
- The pipeline's clothing hook is installed: cloth budget 0.11, subsurf L1 applied before weighting, bevel on hard parts.
- My own head sculpt and hook are no longer used.

**Concept fixes**
- **Skin:** `#C27948`, the median colour sampled from the concept face (was `#A8693F`).
- **Smile:** smaller (smile 0.03, mouth_w 0.112), showing only a little teeth.
- **Hair:** rebuilt as soft rounded locks that lie on the scalp, with a fringe resting on the forehead. Sides were shortened to try to clear the ears.
- **Neck:** the hood rim was raised and thickened to shorten the visible neck.

**Size and triangle count**
- Hidden and small parts are decimated to per-group caps.
- Untextured parts get a constant UV, and AO is averaged per vertex, so the glb no longer splits vertices.
- Result: **88,072 triangles, 3.34 MB** (v1: 53,824 tris, 6.06 MB).

**Not checked (per the 'ship now' instruction)**
- The front and side views were not re-rendered.
- `keyclackr_compare.png` now shows the concept against the game-camera render only.

**Remaining mismatches after pass 3**
- **Ears:** not clearly visible in the close-up. The hair sides and crown still cover most of them.
- **Hair:** reads a bit like a rounded cap compared with the concept's loose tousled strands.
- **Shadow:** the fringe still casts a soft shadow line at the hairline.
