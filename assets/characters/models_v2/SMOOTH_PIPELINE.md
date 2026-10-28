# SMOOTH_PIPELINE: smooth heads, hands and clothing (no style change)

Purpose: fix "blocky, ugly" faces and hard-edged clothing **without restyling**. The concept sheets are still the
reference for faces, hair, clothes, colours and proportions. This pass only changes the geometry quality.
Procedural only: Blender plus Pillow. No image generators, and no tracing of concept PNGs.
Proven on Dana first (`v2/dana/dana_face_smooth_compare.png`).

## UPDATE 2026-10-28 20:20 (Asia/Jerusalem): neck fix, glasses offset, per-character settings  ← read this first
Tested on Steve (83.5k tris) and Lorna (82.3k tris) as well as Dana.
Final state, 20:22: `dana/dana_matched.glb` 89.7k (built 20:10, **before** the neck clamp and face_fwd went in; her neck already looked fine, and she has no glasses), `steve/steve.glb` 83.5k and `lamp_lady/lamp_lady.glb` 82.3k (both 20:16, with the neck clamp and face_fwd). All three: 23 bones, idle/walk/sit 73/33/73 keys.
Review-render helpers in `_build/v2_render.py` `set` mode: env `CLIP`/`FRAME` (pose a clip frame), `KEY_ANGLE` (sun softness) and `NOSHADOW=<material prefix>`. Pull the current `smooth_head.py`; the changes below are already in it.

### 1. Neck swelling fix (in `smooth_head.py`, automatic)
The metaball neck column is 6 overlapping balls. Their fields **add**, so the column swells to about 1.5–2× the intended radius (Steve's neck came out wider than his head, and Lorna's was a fat tube).
Fix: after remesh/subsurf/smooth, the neck verts are binned by z (bins of 0.01·k). In each bin, xy is scaled so the bin's max radius equals
`nr * (1.08 - 0.13*t)`, where `nr` = the old neck radius (`0.235*neck_w*hh`) and `t` = 0 at `nb-0.03k` and 1 at `chin+0.18hh`. It **only shrinks**, never grows.
Neck voxel is now its own option: `neck_voxel` (default 0.014 m·k). Use a coarser value on heavier characters to save tris.
If you build the neck yourself, copy that bin-rescale loop. Do not just lower the ball radii; the swelling depends on the overlap, not the size.

### 2. Glasses offset (`face_fwd`)
The sculpted face (lids, nose, cheeks) is about 0.03·hh further forward than the old ellipsoid head, so glasses built against the old head get their lower inner rims cut by the cheeks.
`smooth_head` now sets `B.face_fwd = OPTS["face_fwd"]*hh` (default 0.03). In your glasses / face-prop builder, subtract it from y (forward is -y):
`y = hc.y - <old offset> - getattr(B, "face_fwd", 0.0)`. Use the same for anything sitting on the face front (masks, moustaches if separate, nose rings).
Earrings, hats and hair caps are **not** affected (the x/y fit to the old cranium band keeps the sides and top in place).

### 3. Per-character budgets
`SH.OPTS` is a module dict that `install()` reads **live for each Group.build**. Reset it per character, or one character's settings leak into the next build in the same process:
```python
_SH_DEFAULT = dict(SH.OPTS)
SMOOTH_OPTS = {   # tested values → GLB triangle counts
  "dana":      {},                                                               # 89.6k  (defaults: cloth_budget_scale 0.13, head_voxel 0.010, neck_voxel 0.014)
  "steve":     dict(cloth_budget_scale=0.075, head_voxel=0.0115, neck_voxel=0.018),  # 83.5k  (jacket+shirt+tie+glasses)
  "lamp_lady": dict(cloth_budget_scale=0.06,  head_voxel=0.0118, neck_voxel=0.02),   # 82.3k  (long hair, hat, shawl, lamp prop)
}
def build(cid):
    SH.OPTS.clear(); SH.OPTS.update(_SH_DEFAULT); SH.OPTS.update(SMOOTH_OPTS.get(cid, {}))
```
Rule of thumb: start at the defaults, count tris from the GLB, then lower `cloth_budget_scale` first (it scales every remeshed garment), then raise `head_voxel` (0.010 → 0.012 max; above that the nose loses definition, and the nose floor `ns>=0.75` only partly covers it).
Characters with lots of props/hair: 0.06–0.08. Simple outfits: 0.10–0.13.

### 4. Triangle counting
`<id>_meta.json` "tris" in `_build/v2_build.py` now counts **real triangles** (`sum(len(p.vertices)-2)`), which matches the GLB index-buffer count. Old meta files counted polygons (about half).

## Files
| file | what |
|---|---|
| `v2/_build/smooth_head.py` | Reusable, standalone code: `install(charkit)` (global smoothing hook) and `smooth_head(B, face_png, F)` (sculpted head and neck). It imports only `bpy`, `mathutils` and `charkit`. |
| your character script | 3 lines to hook it in (below) |
| your face painter (`faces.py` / `v2_faces.py`) | Unchanged. The head keeps the same front-ortho face UV, so existing painted face PNGs line up. |

## Root cause (why faces were blocky)
1. `charkit.BUDGET_SCALE = 0.5` together with `Group(budget=6000)` decimated the head to about 3k faces after the voxel remesh. Decimation leaves facets and creases.
2. The head was a hard **union of ellipsoids** (cranium + jaw + cheeks + nose + brow). The voxel remesh keeps the creases and ledges where they meet ("blocks" at the cheeks, nose and brow).
3. There were no lids or lips in the geometry, so the painted eyes and mouth sat on a flat blob.

## What the pipeline does
### Head (`smooth_head.smooth_head`)
1. **Forms as metaball ellipsoids.** These are the same forms and character knobs (`B.C`: cranium_w/h, jaw_w, jaw_drop, chin_w, cheek, ear, nose, brow_ridge) as the old `Body.head`. Metaball fields blend, so the forms get soft fillets instead of creases. The forms are:
   - rounded cranium
   - oval jaw tapering into one chin form (no double chin)
   - soft cheeks
   - low brow ridge
   - nose bridge, tip and alae
   - ears with a negative bowl
2. **Feature pass registered to the painted texture.** A first metaball mesh is ray-cast from the front (BVH), then these features are added at the painted UV positions (`F` = the face dict: eye_v, eye_sep, eye_w, eye_scale, eye_hr, lid, mouth_v, mouth_w, smile):
   - eyeball bulge
   - soft negative socket
   - upper-lid roll (7 balls along the painted lash arc)
   - lower lid (5 balls)
   - upper and lower lip
   - negative mouth corners
   - philtrum
3. **Convert, voxel remesh (0.0062 m·k), SUBSURF level 1 (applied), Laplacian smooth (4 iterations, λ 0.5, volume preserve).**
4. **Fit to the old head envelope:**
   - z: chin bottom to top = H
   - x and y separately: the band at hc+0.2hh matches the old cranium ellipsoid (0.385cw, 0.43, 0.47ch)
   This means hair caps, hats, glasses and earrings built against the old head still fit.
5. Smooth shading, `charkit.face_uv(I, 0.42hh, chin-0.02hh, H)` (identical mapping), rigid on `Head`.
6. **Neck:** a 6-ball metaball column, remeshed and subsurfed, weighted by distance over `["Neck", "Head", "UpperChest"]` (same as before).

### Clothing, hands and hair (`smooth_head.install(charkit)`)
This monkeypatches `charkit.Group.build` **in-process only**; `charkit.py` is not edited.
- Groups with `remesh=True` are built at `BUDGET_SCALE 0.30` instead of 0.5, then get **SUBSURF level 1 applied**. That gives about 1.2× the old face count, rounded and with no facets.
- Groups whose names start with `skip_subsurf` (default `("Hair",)`) are not subdivided, so the strand silhouettes stay. They are still remeshed and smooth shaded.
- Groups with `remesh=False` (raw boxes, cylinders, buckles, buttons, badges) get a **BEVEL modifier applied**: width 2.5 mm, 2 segments, angle limit 40°. So every hard edge is rounded.
- Everything is smooth shaded. UVs survive subsurf (interpolated). `uvface` is re-run only if the UVs are missing.
- Subsurf and bevel are applied in `Group.build`, i.e. **before** `charkit.assemble` weights, joins and skins. The armature, weights and clips are unchanged.

## How to hook into a character script (3 lines)
```python
import sys, os
sys.path.insert(0, "/workspace/game/pr21-new/customers3d/v2/_build")
import charkit, smooth_head as SH
SH.install(charkit)                                    # BEFORE any Group is built (top of your build script)
# in the recipe, replace   B.head(face_png)   with:
SH.smooth_head(B, face_png, cfg["face"])               # cfg["face"] = that character's face dict (for lid/lip registration)
```
Or patch it globally (this is what `_build/v2_build.py` does):
```python
Body.head = lambda self, png: SH.smooth_head(self, png, getattr(self, "F", None))
B = Body(J, info, cfg["C"]); B.F = cfg["face"]
```
`smooth_head` needs these attributes on `B`: `hh` (head height incl. any head_scale), `hc` (head centre Vector), `I` (info with `H`, `nb`), `C` (char knobs incl. `skin`), `k` (= H/1.70).
If your `Body` has no `hh`/`hc`, set them the way `parts.Body.head` computes them: `hh = head_h*k`, `hc = V((0, 0.006, H-0.47*hh))`.
Options: `SH.OPTS` (head_voxel, head_subsurf, head_smooth, cloth_budget_scale, cloth_subsurf, bevel_width, bevel_segments, skip_subsurf), or `SH.install(charkit, {"cloth_budget_scale": 0.25})`.
To turn it off for an A/B comparison: `SMOOTH=0` env in v2_build.py.

## Parameters (Dana, 1.70 m)
- Head: head_voxel 0.010 m·k + subsurf 1 → about 13k quads = 26k tris. Neck: voxel 0.014 m·k + subsurf → about 7k tris.
- Clothing: `cloth_budget_scale` 0.13 + subsurf 1 → each garment piece is about 3–8k tris. Hair is not subdivided (8k).
- **Whole Dana GLB: 89.6k triangles** (counted from the glTF index buffers; `<id>_meta.json` "tris" counts polygons = 48.6k). Target 60–90k: lower `cloth_budget_scale` (0.10) or raise `head_voxel` (0.011) if a character with more props goes over.
- The first try used head_voxel 0.0062 + budget 0.30, which gave **213k tris** (head alone 67k). Always count triangles from the GLB.
- Metaball resolution: 0.012·hh for the base pass, 0.0096·hh for the final pass.

## Verify (always)
- `blender -b -P _build/v2_verify.py -- <glb>`: the same 23 bones, top height unchanged (Dana 1.70x), clips idle/walk/sit with 73/33/73 keys at 30 fps. The importer shows 0–57/0–25 because it runs at 24 fps; that is fine.
- Render `face`, `face34` and `34` (v2_render `set` mode now has `face34` and `faceside` shots). Check the face silhouette against the concept.

## Pitfalls
- **Metaball sizing:** surface extent = radius × size × **0.575** (stiffness 2, threshold 0.6, Blender 4.2.3). Other values: 0.395 at (1, 0.6), 0.684 at (2, 0.3), 0.76 at (4, 0.3). Fields **add**, so overlapping elements swell. That is why the head is fit-scaled afterwards. Do not skip the fit, or hats and hair will float or clip.
- **Hair covering the brows:** the new forehead is smooth (no brow "shelf" pushing through the hair). Fringes and sweeps that sat just above the brows now cover them. Raise fringe/sweep ellipsoids about 0.03–0.04·hh (Dana: centre-part sweeps z 0.26 → 0.30·hh, rot x 20 → 14).
- **Brow ridge too big:** this pokes skin "horns" through the hairline at the temples. Keep it ≤ (0.075, 0.035, 0.022·2·brow_ridge)·hh with stiffness 0.7.
- **Nostril negatives** read as pig-nose holes at this scale. Keep only the alae. Paint the nostril hint.
- **Face texture alignment:** lids and lips are placed with the same UV→world mapping as `face_uv`: `x=(u-0.5)·0.84hh`, `z=chin-0.02hh+v·1.02hh`. If you change `face_uv` arguments, change `face_features` too, or the lids will not sit on the painted lash line.
- **BUDGET_SCALE** is a module global. The hook sets it temporarily per group and restores it. Do not set it globally to 1.0, or tri counts explode.
- **Memory:** the box OOM-kills (exit 137) with 3 Cycles renders at once. Run at most 2 Blender jobs in parallel. Shell calls die at 13 min, so long jobs need `setsid nohup ... &`.
- **The Read tool caches images by path:** write each review render to a new filename.
- Do **not** subsurf after `assemble` (it would need re-weighting). The hook applies it inside `Group.build`.
