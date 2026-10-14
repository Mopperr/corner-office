# Corner Office

A cozy PC game about packing an old office, trading odd goods on a beige computer, and moving other people's things. The first playable slice is Dana's Garage Startup, the Whisker & Bean cafe job, a rainy drive, Grandpa's Train Shop, a duck-pond loop, and the Bakery Loft unlock.

## Run

Install [Godot 4.7](https://godotengine.org/) or newer (the project was made with 4.7.2). Open this folder in the Godot editor, or from a terminal:

```bash
godot --path . 
```

The main scene is `res://scenes/main.tscn`. Headless logic check:

```bash
godot --headless --path . res://tests/smoke.tscn
```

`SMOKE_OK` means the pay formula, starter desk, save roundtrip, truck-door clips, and loop-import settings passed.

## Controls

- **Click** an item to pick it up. **Click** the floor or a wall to place it.
- **R** rotates 90°. **Shift+R** rotates 15°.
- Wall pieces sit 0.11 m off the wall. A soft thunk means the snap landed.
- Click the beige computer to open HomeDesk: Market, Shop, Email, Listings.
- **Esc** or **Pause** saves and can return to the menu.
- On a drive, **WASD** or the arrow keys drive. **H** honks. You cannot fail a drive.

## How the slice plays

1. New game, pick Dana, read the intro, unpack the garage.
2. Place the twelve starter pieces (the mug and sticky notes sit on the desk).
3. Open the computer and trade office goods. Prices move when you press Next day.
4. The clipboard offers the cafe job after the garage is unpacked.
5. Pack, pad fragile items, load the truck (heavy boxes on the mustard floor slots), then drive.
6. The truck's back door swings open and shut in Godot (`open` / `close`, about +105° on Y). The model itself has no animation.
7. Unpack, repair a scuff or keep it, and read the pay lines. Base pay is always paid in full. Damage only comes out of the tip.
8. Repeat jobs and trade until the Bakery Loft gates are met ($1,500 earned, 3 jobs, Rep 1), then move in from Listings.

## Project map

- `scenes/main.tscn` boots `scripts/app.gd`.
- Autoloads: `ItemDB`, `JobDB`, `GameState`, `SaveManager`, `AudioDirector`.
- `data/tuning.json` holds the locked numbers (damage, snap, tips, office gates, audio gains).
- `data/content.json` is characters, items, venues, and jobs. `data/drives.json` is the three routes.
- `data/narrative/` is the intro, cast, emails, and item flavor.
- `assets/models/` is the diorama kit. Props get a box collider at runtime because the glTF files have none.
- `assets/ui/driving/mover_truck_topdown_sheet@1x.png` is the drive sprite (facing +X, 32 px per meter). The unsuffixed sheet is 2× and is scaled by 0.5 if the @1x file is missing. Hazard tests use the opaque truck, not the padded frame.
- `assets/audio/music/` and the `*loop*` / `*ambience*` clips import with loop on. Drop extra beds in `assets/audio/ambience/` (`.ogg` or `.wav`); those import with loop enabled too.
- `export_presets.cfg` has Linux, Windows, and macOS presets. Windows uses `res://icon.ico`.

Saves go to `user://corner_office_save.json`. Volume sliders live in `user://settings.cfg`.

## Credits

Fonts: Fredoka (titles), Nunito (body), VT323 (the computer). See `assets/fonts/OFL.txt`.
Audio credits are on the Credits screen and in `assets/audio/credits.md`.

## Steam next steps

1. Install the matching Godot export templates and export the three presets into `export/`.
2. Create a Steamworks app, set the price to $10, and upload one depot per OS.
3. Point Steam's launch options at the exported binary. Keep the Godot console wrapper off for the store build if you do not want a terminal window.
4. Add a Steam depot build script, a capsule set, and the store copy in `docs/store_page.md`.
5. Achievements, cloud saves, and the later offices can wait until the slice is in players' hands.
