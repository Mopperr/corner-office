# Corner Office

A cozy PC game about packing an old office, trading odd goods on a beige computer, and moving other people's things. The first playable slice is Dana's Garage Startup, the Whisker & Bean cafe job, a rainy drive, Grandpa's Train Shop, a duck-pond loop, and the Bakery Loft unlock.

## Run

Install [Godot 4.7](https://godotengine.org/) or newer (the project was made with 4.7.2). Open this folder in the Godot editor, or from a terminal:

```bash
godot --path . 
```

The project uses the Forward+ renderer and Jolt Physics. The UI base is 1920×1080 with stretch aspect `expand`, and body text stays at least 18px so it remains readable on a 1280×800 Deck. The main menu looks into the garage through an orthographic camera (yaw 45°, pitch -30°, size 7.2). If `game/menu_room_loft.json` is present, that shot is the Bakery Loft instead. It drifts once every 24 seconds, and that drift stays off when the system asks for reduced motion. The main scene is `res://scenes/main.tscn`. Headless logic check (import the class cache first, or a fresh run sits there until Godot finishes that scan):

```bash
godot --headless --path . --import --quit
godot --headless --path . --quit-after 240 res://tests/smoke.tscn
```

`tests/run_venues.sh` builds every job venue and every rung of the shop ladder headless and checks each comes up dressed (`VENUES_OK`); with `CO_SHOTS` set and a renderer it takes a picture of each. `tests/run_smoke.sh` runs those two steps and checks for `SMOKE_OK` (it also checks that the job board is deterministic, playable, and saved, and that goals pay out). `tests/run_playthrough.sh` then plays the whole slice the way a player would (menu, garage, computer, map, the three jobs through pack, truck, drive, unpack and results, the Goals tab, one generated job from the board, the Bakery Loft move, and a save roundtrip after each step) and checks for `PLAYTHROUGH_OK`. It takes about seven minutes because the drives are real. CI runs both.

`SMOKE_OK` means the pay formula, starter desk, save roundtrip, truck-door clips, and loop-import settings passed. With a display, `CO_SHOTS=/some/dir godot --path . res://tests/playthrough.tscn` also saves a screenshot after each step.

## Controls

- **Click** an item to pick it up. **Click** the floor, a desk, or the top of another item to place it. A red ghost means it would float or overlap.
- **R** rotates 90°. **Shift+R** or the **mouse wheel** rotates 15° while you hold something. **G** toggles the 0.25 m grid. Free placement is the default, and the choice is saved with the volume sliders.
- **Q** / **E** (or the Rotate view button) swing the camera round the room a quarter turn at a time; the two walls nearest the camera cut away so you can always see in. The **mouse wheel** zooms when your hands are empty.
- A footprint shadow follows the ghost and shows exactly where the item will land: sage when it will sit, soft red when it would float or overlap. Landing puffs a little dust.
- The card under the status bar is the room checklist: every goal for the room, ticked as you meet it, with the live Room setup score that feeds the tip.
- Items rest on the floor or on whatever is under them, then settle and freeze so a stack stays put.
- Wall pieces sit 0.12 m off the wall. A soft thunk means the placement landed.
- Click the beige computer to open HomeDesk: Market, Shop, Email, Listings.
- **Map** (or **M**) opens the town map: where you are, which clients have a job pinned, and which offices are for sale. You can take a job or move in from there.
- **Esc** or **Pause** saves and can return to the menu.
- On a drive, **WASD** or the arrow keys drive, **Space** is the handbrake, **H** honks, and **E** loads or unloads at a bay (the HUD has buttons for both). You cannot fail a drive.

## How the slice plays

1. New game starts as Dana Reyes, a laid-off office worker in the Garage Startup with $120. Read the intro, then unpack the garage. There is no character select.
2. Place the twelve starter pieces (the mug and sticky notes sit on the desk), or press **Place it all for me** and let them find their own spots. The moment the garage is live the clipboard opens itself with the first job on it, so the first drive is minutes away. The HUD's status line keeps a small ledger: the jar, and today's change (`today +$12`) beside it.
3. Open the computer. Trade office goods, or open TropicalForest to order decor. In a wide window the computer keeps a right-hand column of ads, Marge's tip, the drive weather and the day's biggest price mover. Prices move when you press Next day, and a night card sums the day up first: money in and out, jobs, the shop's takings and who was served by hand, trading, decor on the way, goals ticked off, and a teaser for tomorrow's board.
4. The clipboard offers the cafe job after the garage is unpacked. Beside Marge's three story jobs, **Today's board** lists two to four generated moves (`scripts/job_gen.gd`): one of twenty-five clients with their own line, a venue (cafe, train shop, park, bakery, the Corner Studio, or the flat over the bakery), eight to twenty-two pieces drawn from the catalogue, a twist (cat, sets, mystery bag, ducks, fragile, heavy, or plain), and a drive between two real places in town with its own weather and hazards. The board is seeded from the save and the day, so it survives a reload and changes every morning (press Next day on the computer). The map lists the same board. The clipboard's **Goals** tab holds the contracts in `data/contracts.json`: finish jobs, serve customers by hand, buy decor, take the alley. Each one pays cash and Rep when it ticks over, and Marge mails about it.
5. Pack, pad fragile items, load the truck (heavy boxes on the mustard floor slots), then drive. The truck takes eight boxes, so that is the box limit; tap a loaded pad with nothing selected to take that box back off.
6. The drive is a 3D town seen from a chase camera behind the truck (`data/city.json` lays it out; `drive_course.gd` builds it from meshes): blocks of buildings with window bands and awnings, two-lane roads with traffic, a park with the pond, and two alleys you can cut through (`data/city.json` lists them under `alleys`). Honk (**H**) near someone on the pavement and they wave; each friendly honk, up to five a drive, adds a little to the pay and counts toward a goal. The truck starts parked in the client's loading bay. Load up (the boxes hop in off the curb), follow the floating arrow, the dots on the road and the minimap to the bay at the other end, park inside it, and unload. Walls, cars, cones, puddles, bumps, gravel and a hard brake in the rain all cost box condition. Traffic is solid: a car ahead in your lane sets your pace and you sit a car's length behind it, cars keep their own spacing, a car behind you brakes and leans on the horn, and driving into one is a fender bender, not a pass-through. The simulation itself is 2D (drive pixels, 32 to the metre), so the condition rules and tests are unchanged.
7. The truck's back door swings open and shut in Godot (`open` / `close`, about +105° on Y). The model itself has no animation. None of the models carry animation data, so Biscuit (breathing, the occasional long stretch) and the shop customers (walking bob, swinging arms, a glance around while they wait) are animated in code; rigged art would replace that.
8. Unpack: carry each box in from the truck, click it to tip it out, then place what was inside. Repair a scuff or keep it, and read the pay lines. Base pay is always paid in full. Damage only comes out of the tip.
9. Repeat jobs, trade, and let the shop earn until the Bakery Loft gates are met ($1,500 earned, 3 jobs, Rep 1), then move in from Listings. The board keeps generating after that, so there is always a job to take.

**Unpacking a box.** Click a carried box and a card shows what is inside, with three ways out: **Take** puts a piece in your hand to place where you like, **Set here** drops it on the nearest free spot behind the box, and **Tip it out** spills the lot on the floor. **Put it all away for me** empties the box in one go, and the HUD's **Unpack it all for me** does every carried box. Packing has the same escape hatch: **Pack the rest for me** boxes, pads and tapes everything that is still loose, and the garage tutorial has **Box it all for me**. Carried boxes line up across the screen so no box ever hides another, and **Stack the boxes** piles the ones still packed into towers of three to clear the floor; click a tower and the top box opens (a lower box sends you to the top). The box card names each piece, says where it goes (floor, wall, on things) and gives it a line of its own.

**The workbench** (`scripts/workshop.gd`, `scripts/workshop_ui.gd`, `data/workshop.json`). Click the bench in the garage or press **Workbench**. *Make* lists recipes that con against your skill the old DAoC way (grey, green, blue, yellow, orange, red): a red make can fail and eat half the materials, yellow and orange teach most, grey teaches nothing. Each success rolls a quality and can bump the skill; 3% are masterpieces. Made things sell to whoever is asking that day (a craft buyer with a tag and a minimum quality pays extra), to the market, or go into the room as decor with **Keep**. *Fix up* takes a worn trade good to restored, then mint, for the market buyers who ask for one ("Only if it's mint, mind"). *Shelf* sells materials. *Journal* keeps the skill and a line about where every sold piece ended up.

**The back room** (`scripts/crime.gd`, `data/crime.json`), a tab on the clipboard. Sal runs three short trees bought with street cred: fencing (goods to Sal above market), night moves (a no-questions board job at up to 2.6x), and knock-offs (made things sold as the real thing). Everything adds heat; heat fades daily; past the line there is a visit (fine, confiscation, a Rep slip), and the third visit is a police raid: half the goods gone, a bigger fine, the shop shut for a day, and Marge's email. When a day ends with an empty jar and nothing earned, Sal writes first.

**The ladder in the yard** (`scripts/yard_shop.gd`). As the shop climbs the ladder on the Till, the lawn beside the garage grows the business: a coffee cart with an umbrella, then the building described below as a sandwich bar, a shawarma grill, a café with string lights, and a restaurant on a deck under a pergola with white cloths and lanterns. Customers queue at the counter in the window. The Till's menu follows the rung. About half the customers have a small ask when you click them (extra ice, a warm bun, "is the cat in?"), listed in `data/shop.json` under `asks`; a card offers two replies. Saying yes lifts the tip, saying no trims it, and the customer answers back in a bubble either way. Then you make the order: the **Make it** card (`scripts/make_card.gd`) shows the cup or plate, the recipe in order, and a tray of ingredients with two red herrings. Each right tap adds a layer; a wrong one shakes the cup and costs a little tip. A clean make pays 1.3x the hand tip, one slip pays the plain hand tip, more pays less, and **Let the till do it** hands the order over at the till's half tip. Recipes and ingredients live in `data/shop.json`.

**Ambient life.** Every setting has a three-bay parking lot off the road (`Outdoors._parking`). Cars pull in from the street, park nose-in, and someone steps out and walks to the door: a customer if the shop is taking orders, otherwise a neighbour who wanders in, flops on the beanbag, leans in to a plant, or stops at a shelf. When they are done they walk back to the car and it drives off. Everyone thinks out loud in a thought bubble over their head, drawn from `data/chatter.json` (arriving, waiting, served, browsing by kind, leaving, and passers-by). Passers-by walk the pavement beyond the road (one with a dog). Biscuit breathes and stretches in code.

**The yard.** From the sandwich bar up, the business is a small building: slab, walls, a serving window with the counter and the day's wares in it, a door, shelves of jars and a kitchen inside (toaster, grill with a turning spit, coffee machine and grinder, a pass with heat lamps), a striped awning, a sign on the parapet, a menu board and planters, with tables and chairs out front. The roof covers only the kitchen so the camera looks in over the counter.

The garage itself is dressed by `scripts/garage_dressing.gd`: a workbench with paint tins, a toolbox and the radio (you can set things on it), a pegboard of tools, a cork board, rafters with string lights and a pendant over the bench, a bike, archive boxes, a broom, a bin, a door mat, planters on the drive, and warm light through the window. All of it is scenery; only the bench blocks.

## TropicalForest and the shop

TropicalForest is a computer app: categories, search, silly reviews, a wishlist, and a daily deal that simply waits until the next in-game day. Standard shipping is free and arrives tomorrow. Express is same-day for a small fee. Toucan Prime, once the jar has earned enough, makes express free.

A courier walks up to the door and rings. Click the box, pop the bubble wrap, and place the item on a free surface. A sealed box can be returned. A placed Forest item can be returned for most of the price or resold to the market. The catalog is `data/forest.json`. It points at the decor models already in the game. Coffee & Kitchen and Seasonal open with the Bakery Loft. Mystery boxes and the occasional freebie are in that same file.

The Shop Manager app (Till) wakes up after the garage is unpacked. It earns only when a fixture from `data/shop.json` is placed: a coffee machine, kettle, lemonade pitcher, cup stack, bookshelf, filing cabinet, fern, or menu board. While the sign is OPEN, an A-board stands by the door and customers walk in from the drive, queue at the counter, and hold their order over their head (a mug, a lemonade glass, a bun). **Click a customer to serve them yourself** for the whole tip; leave them and after a few seconds the till rings them up at half tip. Nobody leaves unserved and nothing fails. Vibe, from plants, lights, and decor, changes how many people come and how they tip. Prices are Cozy, Fair, or Splurge; the Till shows the last sales, who was served by hand, and the OPEN / CLOSED sign. After the cat-cafe job, a cat bed or cushion puts Biscuit on the till. Marge emails a daily summary. Regulars sometimes ask for a TropicalForest item. Add visitors, dishes, or fixtures in `data/shop.json`.

## Project map

- `scenes/main.tscn` boots `scripts/app.gd`.
- `scripts/outdoors.gd` builds the yard around every room (ground, driveway, road, trees, fence or lamp posts, neighbours) from plain meshes with no collision. `scripts/map_ui.gd` is the town map, with its pins in `data/map.json`.
- Autoloads: `ItemDB`, `JobDB`, `GameState`, `SaveManager`, `AudioDirector`.
- `data/tuning.json` holds the locked numbers (damage, snap, tips, office gates, audio gains).
- `data/content.json` is characters, items, venues, and jobs. `data/drives.json` names each drive's pickup and drop-off bay, weather, and hazards (placed by fraction `along` the computed route); `data/city.json` is the town itself and `scripts/city.gd` builds it, routes through it, and runs the traffic loops. `data/forest.json` is the TropicalForest catalog. `data/shop.json` is fixtures, the menu, visitors, and Vibe.
- `data/narrative/` is the intro, cast, emails, item flavor, `player_characters.json`, `character_arcs.json`, `how_to_play.json`, and `credits.json`. Dana (phase `slice`) is the only starter, through Garage Startup to the Bakery Loft. When one of her L1–L6 beats loads, Marge's email lands in the inbox and a short note shows the arrival and personal moment. Sol, Hank, Milo, and Bea arcs are in that file and stay hidden. There is no character select yet.
- `assets/models/` is the diorama kit. A placed prop keeps at most two materials. Props get a box collider at runtime because the glTF files have none. Structural walls are 0.24 m thick (the inner face is 0.12 m, including the garage, whose visual shell is 0.26 m). Rugs and floor tiles are pickable and do not block physics. `npc_*` models get a capsule.
- `assets/ui/driving/mover_truck_topdown_sheet@1x.png` is still the truck placeholder (facing +X, 32 px per meter) until the dedicated top-down truck sprite arrives. The unsuffixed sheet is 2× and is scaled by 0.5 if the @1x file is missing. Hazard tests use the opaque truck, not the padded frame.
- L3 and L5 use the `@1x` driving sprites in `assets/ui/driving/` at 32 px per meter (cones, puddles, ducks, shopfronts, the pond fountain, and the bridge-closed sign). `assets/level-art-manifest.md` maps the L1–L6 props. The Bakery Loft uses the `bakery_loft_*` walls and floors.
- `assets/audio/music/` and the `*loop*` / `*ambience*` clips import with loop on. Drop extra beds in `assets/audio/ambience/` (`.ogg` or `.wav`); those import with loop enabled too.
- Act 1 (L1–L6) follows `assets/audio/level_audio_map.md`: each level plays its music and ambience loop, plus its own sound effects. Rain, skylight rain, the shop clock, and the cafe bed are about +8 dB. Voice lines are still stubs and stay silent.
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
