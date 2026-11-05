# Household furniture families (hh_cat_*.glb) for PR #21

Created by Andrew's Helpers (Grok Bots)

## What this is
This folder holds 202 procedural, low-poly household furniture "family" models. They are in `assets/models/hh_cat_<family_id>.glb`, one per row of `families.csv`. All of them were built in Blender from Python primitives (the scripts are in `tools/furniture_families/`). No AI imagery or textures were used.

This is an add-only change: no existing file is touched, and no `hh_cat_*` path exists at base 5209513.

## Checks (re-run 28 Oct 2026, 22:17 IST, on all 202 files)
Each file was checked with `furniture_verify.json`, the packer's re-check. Every file passed all of these:
- It is a valid glTF 2.0 binary.
- Its size is under 1 MB.
- It has a material named `way`.
- It has 7 materials or fewer.
- It has no textures or images.
- It contains no copper. Copper is B87333, and the check rejects any base colour within an sRGB distance of 40 of it.
- It has a flat matte finish.

Result: **202 of 202 pass, with 0 excluded.** Batches 1 to 10 also have their own Art and Design validation and QA reports in `batchN/`.

**Still pending:** Art has not yet cross-validated Design's half of batch 10. Those 10 families are axe_logs, desk_lamp, monitor, keyboard_mouse, printer, paper_tray, pen_pot, laptop, desk_phone and desk_tidy. Design's own QA_batch10 passes 10 of 10, and the packer re-check passes all 10.

## Build conventions
- Each model is built at real size in metres, using the w/d/h in `families.csv`.
- The origin is at the bottom centre.
- The front faces −Y in Blender, which becomes +Z after glTF import in Godot.
- Every material is flat matte, roughness 0.82, with no textures.
- The colours come only from the 23-colour palette in FAMILIES.md.
- The single tintable material is called **`way`**. It is baked with the family's first colourway.

## Hook for Props.make (Claude to wire, about 10 lines)
For an item whose model is `proc:<id>`, find its family in `families.csv`. If `res://assets/models/hh_cat_<family_id>.glb` exists:
1. Instance it.
2. Scale it by the item's (w, d, h) divided by the family base size from the csv.
3. Duplicate the `way` material and set albedo to the item's colourway hex. Use the palette name, or the alias tables below.
4. Otherwise, fall back to the current primitive build.

The item ids stay `proc:*`, so check_items and smoke behave as before.

```gdscript
var fam := FAMILY_OF.get(id, "")            # from families.csv
var p := "res://assets/models/hh_cat_%s.glb" % fam
if fam != "" and ResourceLoader.exists(p):
    var n: Node3D = (load(p) as PackedScene).instantiate()
    n.scale = Vector3(item.w / base.w, item.h / base.h, item.d / base.d)
    _tint_material(n, "way", COLOURWAY_HEX[item.colourway])   # duplicate the material first
    return n
# else: existing primitive path
```

## Colourway mapping (names that are not palette keys)
- painted white → white EAE6DC
- painted sage → sage 8FA882
- tan / wicker → kraft C9A070
- leather → walnut 6B4A3A
- gilt → brass C9A24E
- tin / silver / galvanised / wire / aluminium → steel C9CED3
- canvas → card E7DCC6
- navy → night 3E3A4F
- linen → cream F4F1EA
- antique → kraft C9A070
- cast iron → black 1E1B19
- carbon → black 1E1B19
- brown → walnut 6B4A3A
- off → dark 2B2622
- on → blue 4A6FA5
- spreadsheet → white EAE6DC
- bronze → terracotta D9765F
- classic → black 1E1B19
- milk crate → red B6453F
- mixed → mustard E6B655
- velvet rose → rose E8B4A8
- velvet → plum 6E4B6E
- warm → mustard E6B655
- gold → brass C9A24E
- tarnished / faded → grey 8E8276
- glazed blue → blue 4A6FA5
- glazed sage → sage 8FA882
- plastic black → black 1E1B19

**Copper:** copper B87333 is not allowed and appears in no GLB. Where the csv lists a copper colourway (bird_cage, candle_holder, clothes_rail, saucepan, towel_rail_bath), the game tints `way` itself. Boss decision, 28 Oct 2026: alias **copper → brass C9A24E**.

## Texture-hook part names
`props.gd` `dress_household` (`PART_TEXTURES`, L139 at 5209513) textures meshes by part name, after lower-casing and stripping trailing digits and dots. The mappings are:
- cushion / pillow / mattress / duvet / towel → fabric_linen
- throw_cushion → velvet
- saddle / strap / trunk → leather
- rug / mat → rug_kilim
- top → oak_floor
- splashback → kitchen_tile
- tray → brushed_steel
- box → cardboard
- soil → concrete

`seat` only becomes cloth for SOFT_PIECES ids, so `seat` in hh_ files is harmless.

### Renamed by Design (28 Oct, to avoid the wrong texture)
These files were rebuilt. Bbox, geometry, materials and `way` are unchanged, and QA was re-run.
- tree_box: `soil` → `planter_soil`, and `trunk` → `tree_trunk`
- planter_box: `soil` → `planter_soil`
- bath_plant: `soil` → `planter_soil`
- flower_pot_v: `soil` → `planter_soil`
- clothes_rail: `box` → `storage_box`
- tall_bookcase: `box` → `storage_box`
- whiteboard: `tray` → `pen_ledge`
- gramophone: `top` → `case_top`
- model_ship: `top` → `mast_top`

### Hook names still present (intentional, so the texture applies)
31 files still use hook names:
- armchair_v (cushion)
- bar_stool (seat)
- bath_mat (mat)
- bean_bag (seat)
- bedroom_chair (cushion, seat)
- bookshelf_v (top)
- broken_chair (seat)
- child_bike (saddle)
- coffee_table_v (top)
- cot (mattress, pillow)
- cushion_set (cushion)
- dollhouse (rug)
- dressing_stool (cushion)
- footstool (cushion)
- guitar (saddle)
- high_chair (cushion, seat)
- kitchen_trolley (top, towel)
- ottoman (cushion)
- plant_pot_v (soil)
- rocking_chair (cushion, seat)
- round_rug (rug)
- school_desk (seat)
- shoe_rack (top)
- side_table_v (top)
- sideboard (top)
- skis (strap)
- suitcase_stack (strap)
- tall_bookcase (top)
- towel_pile (towel)
- towel_rail (towel)
- wine_rack (top)

**Rename suggestions, if a texture looks wrong in game:**
- plant_pot_v `soil` → `planter_soil` (to match the other pots)
- dollhouse `rug` → `doll_rug`. The kilim texture would be very large on a tiny rug.
- guitar `saddle` → `bridge_saddle`. props.gd maps saddle to leather, and a guitar bridge saddle is bone, not leather. Leather is fine for the child_bike saddle and the skis and suitcase_stack straps.
- kitchen_trolley `towel` is intended. Its `top` is intended as oak.

## Contents
- `assets/models/hh_cat_*.glb`: 202 models.
- `docs/furniture_families/`:
  - FAMILIES.md, families.csv, contact_sheet.png (183 KB) and furniture_verify.json.
  - `batchN/`: the per-batch README, VALIDATION and QA reports.
- `tools/furniture_families/batchN/`: the Blender build and validate scripts. They are for reference only and are not used at runtime.

Per-batch contact sheets (about 0.5 MB each) were left out to keep the bundle small.

