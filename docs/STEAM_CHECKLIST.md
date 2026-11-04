# Steam checklist

What stands between this branch and a $10 listing, in the order to do it.
Everything the game itself needs is in the tree; the rest is accounts,
assets and builds that only Andrew can make.

## In the tree (done)

- A game that runs from the menu to an ending: the slice, the ladder to L22,
  the last delivery and the credits, with the world open afterwards.
- Export presets for Linux, Windows and macOS (`export_presets.cfg`), the
  icon (`icon.png`, `icon.ico`), the project name and description.
- Settings a Steam player expects: music and effects volume, full screen,
  quality tiers, remappable controls, grid snap.
- Save and load, autosave, and a lossless save round trip checked on every
  step of the playthrough.
- Tests on CI: smoke, the full playthrough, the venue gallery.
- Credits that name the team (`data/narrative/credits.json`); every sound
  and track original (`assets/audio/credits.md`); fonts under the SIL OFL.

## Builds (Andrew, about an afternoon)

1. Install the Godot 4.7.2 export templates on a machine with the editor
   (Editor, Manage Export Templates, Download). The container here has the
   headless binary only, so no build was made from this branch.
2. `godot --headless --export-release "Windows Desktop" export/CornerOffice.exe`
   and the same for "Linux". macOS needs signing and notarisation to run
   outside the developer's own machine; it can wait for a later update.
3. Run each build once on a real GPU with Forward+ (the rendered checks
   here used the Compatibility renderer under software GL). Check the menu,
   a job end to end, a drive, the shop, and Settings.
4. Steamworks: create the app, upload the depots with SteamPipe, set the
   launch options per platform.

## The store page (half a day)

- Capsule art at Steam's sizes (header 460x215, small 231x87, main 616x353,
  vertical 374x448, library 600x900 and 920x430). The team's concept sheets
  in `docs/concepts_internal/` are reference only and must not ship or be
  used on the page; the capsules should be painted or rendered from the
  game's own look.
- Five to ten screenshots at 1920x1080 from a Forward+ build: the garage
  with the counter, a cafe mid-unpack, the drive at the kerb, the night
  drive, a house upstairs, the results card, the People sheet.
- A trailer of thirty to sixty seconds. The Movie Maker recording the
  playthrough makes (`docs/QA_REPORT.md`) is a source for it.
- Copy: `docs/store_page.md` has the short descriptions; the long one can
  open with the premise ("Nobody knows the name yet. Every job is somebody
  who will.") and `docs/WHY_EACH_LOOP.md` has the beats.
- Tags: Casual, Cozy, Simulation, Relaxing, Management, Singleplayer.

## Before pressing release

- Steam Input: the game is keyboard and mouse; the drive and the menus
  have pad bindings in `scripts/control_map.gd`, worth a pass on a real pad.
- A privacy line: the game stores a save file and a settings file in the
  user data folder and sends nothing anywhere.
- Decide on `docs/concepts_internal/`: it is `.gdignore`d so it never ships
  in a build, but it is in the repository; dropping it from the branch is
  the cleaner choice before the repository is shared.
- Price $10 (the design target was $20 of game); a launch discount of ten
  percent is customary.
