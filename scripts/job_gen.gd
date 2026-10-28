extends RefCounted
const Homes = preload("res://scripts/homes.gd")
# Generates the day's job board: who is moving, where, what they own, which
# twist the job carries, and a route through the town to drive. Everything
# is seeded from the save's seed and the day, so a board is the same after a
# reload and different on every new game.

const CLIENTS: Array = [
	{"name": "Ada Lindqvist", "party": ["adult"], "mood": "warm", "trade": "potter", "venue": "cafe", "line": "The kiln pieces are wrapped. The rest is just mugs."},
	{"name": "Benji Osei", "party": ["adult"], "mood": "fussy", "trade": "record collector", "venue": "train", "line": "Crates of vinyl. Heavy, and I will know if one is scuffed."},
	{"name": "Carmen Ruiz", "party": ["adult"], "mood": "warm", "trade": "florist", "venue": "park", "line": "Plants first, please. They do not like the dark."},
	{"name": "Dev Patel", "party": ["adult"], "mood": "fussy", "trade": "tailor", "venue": "cafe", "line": "The dress forms are awkward, not fragile. Mostly."},
	{"name": "Esme Hart", "party": ["adult"], "mood": "warm", "trade": "baker", "venue": "bakery", "line": "Everything smells of cinnamon. You will too, by the end."},
	{"name": "Farouk Haddad", "party": ["elder"], "mood": "fussy", "trade": "watchmaker", "venue": "train", "line": "Small boxes, big consequences. Pad the clocks."},
	{"name": "Greta Voss", "party": ["elder"], "mood": "warm", "trade": "retired teacher", "venue": "park", "line": "Forty years of books. Keep the sets together or I will cry."},
	{"name": "Hiro Tanaka", "party": ["adult"], "mood": "rude", "trade": "barista", "venue": "cafe", "line": "The machine rides alone. It is the only thing I own that matters."},
	{"name": "Ines Moreau", "party": ["adult"], "mood": "warm", "trade": "illustrator", "venue": "bakery", "line": "Frames, pencils, one lamp I am very attached to."},
	{"name": "Jonah Blake", "party": ["adult"], "mood": "fussy", "trade": "model maker", "venue": "train", "line": "There is a bag of parts I never sorted. Good luck."},
	{"name": "Kay Nakamura", "party": ["adult"], "mood": "warm", "trade": "yoga teacher", "venue": "park", "line": "Cushions, plants, and a kettle. The calmest move you will do."},
	{"name": "Lou Ferreira", "party": ["adult"], "mood": "rude", "trade": "mechanic", "venue": "cafe", "line": "Toolboxes. Heavy ones. Bottom of the truck, please."},
	{"name": "Mira Solano", "party": ["adult"], "mood": "fussy", "trade": "ceramicist", "venue": "studio", "line": "Bowls, glazes, and a wheel I will carry myself."},
	{"name": "Noor Rahimi", "party": ["adult"], "mood": "fussy", "trade": "architect", "venue": "studio", "line": "Rolled drawings and one very good lamp."},
	{"name": "Otto Brandt", "party": ["elder"], "mood": "fussy", "trade": "clockmaker", "venue": "flat", "line": "Everything ticks. Please do not let it stop."},
	{"name": "Pia Kowalski", "party": ["adult"], "mood": "warm", "trade": "nurse", "venue": "flat", "line": "Night shifts. Boxes are labelled, mostly truthfully."},
	{"name": "Quinn Adeyemi", "party": ["adult"], "mood": "rude", "trade": "DJ", "venue": "train", "line": "Crates. Do not stack the crates. They are crates."},
	{"name": "Rosa Leclerc", "party": ["adult"], "mood": "warm", "trade": "pastry chef", "venue": "bakery", "line": "Trays and tins and a mixer older than me."},
	{"name": "Sami Khoury", "party": ["adult"], "mood": "warm", "trade": "bookseller", "venue": "flat", "line": "Forty boxes of books. Twenty are poetry. Be gentle."},
	{"name": "Tove Lund", "party": ["adult"], "mood": "rude", "trade": "sailor", "venue": "park", "line": "Rope, lamps, and a bench from the boat."},
	{"name": "Uma Chandra", "party": ["adult"], "mood": "fussy", "trade": "violin teacher", "venue": "studio", "line": "The metronome rides on the seat beside you."},
	{"name": "Viggo Hansen", "party": ["adult"], "mood": "warm", "trade": "carpenter", "venue": "cafe", "line": "Tools in the red box. Coffee in the blue tin."},
	{"name": "Wren Okafor", "party": ["adult"], "mood": "fussy", "trade": "photographer", "venue": "studio", "line": "Frames face each other. Lamps face the wall."},
	{"name": "Yusuf Demir", "party": ["elder"], "mood": "warm", "trade": "chess coach", "venue": "park", "line": "Boards, clocks, and a kettle. Nothing dramatic."},
]

# What a house move carries, by the room it belongs in; big pieces are capped.
const HOME_MAX_BIG := 4

const TWISTS: Array = ["cat", "sets", "mystery", "ducks", "fragile", "heavy", "plain"]

# Household items the generator can hand out, with how many of each a move can carry.
const POOL: Dictionary = {
	"cafe_mug": 6, "cushion": 4, "menu_board": 1, "espresso": 1, "cafe_plant": 3, "cafe_fern": 2, "bowl": 3,
	"clock_small": 6, "tool_box": 4, "village_kit": 2, "station_clock": 1, "picnic_basket": 2, "bread_crate": 3,
	"plant_fern": 2, "plant_cactus": 3, "poster_motivational": 2, "beanbag_mustard": 1,
	"beanbag_sage": 1, "clock_wall": 1, "bookshelf_wood": 1, "kettle": 1, "string_lights": 1, "picture_abstract": 2,
	"picture_stripes": 2, "coffee_machine": 1, "filing_cabinet": 1, "lamp_banker": 1, "lamp_moody": 1,
	"keyboard_typewriter": 1, "rotary_phone": 1, "cat_tree": 1, "lemonade_pitcher": 1, "cup_stack": 2,
	"globe": 1, "trophy": 2, "record_player": 1, "radio": 1, "teapot": 2, "vase": 2, "lantern": 2,
	"cash_register": 1, "kitchen_scale": 1, "birdcage": 1, "easel": 1, "skateboard": 1,
}

# Wall pieces are capped per job: a small room only has a few hooks.
const HANG: Array = ["menu_board", "station_clock", "poster_motivational", "clock_wall", "string_lights", "picture_abstract", "picture_stripes"]
const WALL_FLOOR: Array = ["bookshelf_wood"]
const MAX_HANG := 2

const DRIVE_ENDS: Array = [
	["cafe", "cafe_new"], ["train", "train_new"], ["park_shed", "boathouse"], ["garage", "bakery"],
	["forest", "corner"], ["warehouse", "glass"], ["cafe_new", "train"], ["bakery", "park_shed"], ["corner", "garage"],
	["forest", "glass"], ["garage", "corner"], ["warehouse", "park_shed"], ["bakery", "train_new"], ["glass", "forest"],
]

const STREETS: Array = ["Larch Street", "Mill Lane", "Harbour Road", "Elm Row", "Station Hill", "Copper Lane", "Quay Street"]


static var _clients_cache: Array = []


static func clients() -> Array:
	# The trade clients above, plus every household with a story in data/stories.json.
	if _clients_cache.is_empty():
		_clients_cache = CLIENTS.duplicate(true)
		for story in stories():
			_clients_cache.append({
				"name": str(story.get("client", "")), "title": str(story.get("title", "")), "trade": str(story.get("trade", "")),
				"venue": str(story.get("venue", "")), "line": str(story.get("line", "")), "party": story.get("party", ["adult"]),
				"mood": str(story.get("mood", "warm")), "story": str(story.get("id", "")), "why": str(story.get("why", "")),
			})
	return _clients_cache


static var _stories_cache: Array = []


static func stories() -> Array:
	if _stories_cache.is_empty():
		var file := FileAccess.open("res://data/stories.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				_stories_cache = parsed.get("stories", [])
	return _stories_cache


static func story(id: String) -> Dictionary:
	for entry in stories():
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func board(seed: int, day: int, rep: int, jobs_done: int, count := 3) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [seed, day])
	var jobs: Array = []
	var drives: Dictionary = {}
	var used_clients: Array = []
	var pool: Array = clients()
	for n in count:
		var client: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var guard := 0
		while used_clients.has(client.get("name", "")) and guard < 12:
			client = pool[rng.randi_range(0, pool.size() - 1)]
			guard += 1
		used_clients.append(client.get("name", ""))
		var id := "gen_d%d_%d" % [day, n]
		var drive_id := "gen_drive_d%d_%d" % [day, n]
		var twist := str(TWISTS[rng.randi_range(0, TWISTS.size() - 1)])
		var venue := str(client.get("venue", "cafe"))
		var home: Dictionary = ItemDB.venues().get(venue, {})
		var is_home := bool(home.get("home", false))
		if twist == "ducks":
			if is_home:
				twist = "plain"
			else:
				venue = "park"
		var size := 8 + rng.randi_range(0, 6) + mini(jobs_done, 8)
		size = clampi(size, 8, 22)
		var recipe := _recipe_home(rng, size, twist, home) if is_home else _recipe(rng, size, twist)
		var drive := _drive(rng, drive_id, twist)
		drives[drive_id] = drive
		var pay := 90 + size * 4 + int(float(drive.get("length_m", 150)) * 0.25) + rep * 12
		pay = clampi(pay, 100, 320)
		var job := {
			"id": id,
			"generated": true,
			"venue": venue,
			"drive": drive_id,
			"unlock": "tutorial_done",
			"title": str(client.get("title", "%s's %s move" % [str(client.get("name", "Someone")).split(" ")[0], client.get("trade", "")])),
			"home": is_home,
			"client": client.get("name", ""),
			"party": client.get("party", ["adult"]),
			"mood": client.get("mood", ""),
			"story": client.get("story", ""),
			"why": client.get("why", ""),
			"brief": "%s%s %d pieces to %s. %s" % [(str(client.get("why", "")) + " ") if str(client.get("why", "")) != "" else "", client.get("line", ""), size, drive.get("title", "the new place"), _twist_line(twist)],
			"mentor_note": _mentor_line(twist, rng),
			"narrative_base": pay,
			"recipe": recipe,
			"twist": twist,
			"day": day,
		}
		if twist == "cat":
			job["cat"] = true
		if twist == "mystery":
			job["mystery"] = true
		if twist == "ducks":
			job["duck_friend"] = true
		jobs.append(job)
	return {"jobs": jobs, "drives": drives}


static func _recipe(rng: RandomNumberGenerator, size: int, twist: String) -> Array:
	var ids: Array = POOL.keys()
	var recipe: Array = []
	var total := 0
	var guard := 0
	var set_names := ["clocks", "books", "tools", "frames"]
	var set_index := 0
	var hung := 0
	var wall_floor := 0
	while total < size and guard < 60:
		guard += 1
		var item := str(ids[rng.randi_range(0, ids.size() - 1)])
		var already := false
		for group in recipe:
			if str(group.get("item", "")) == item:
				already = true
		if already:
			continue
		if WALL_FLOOR.has(item):
			if wall_floor >= 1:
				continue
			wall_floor += 1
		var cap := int(POOL.get(item, 1))
		if HANG.has(item):
			cap = mini(cap, MAX_HANG - hung)
			if cap <= 0:
				continue
		var count := clampi(rng.randi_range(1, cap), 1, size - total)
		if HANG.has(item):
			hung += count
		var group := {"item": item, "count": count}
		if twist == "sets" and count >= 2 and set_index < set_names.size():
			group["set"] = set_names[set_index]
			set_index += 1
		recipe.append(group)
		total += count
	if twist == "mystery":
		_add_to_recipe(recipe, "mystery_part", 3)
	if twist == "fragile":
		_add_to_recipe(recipe, "bowl", 2)
	if twist == "heavy":
		_add_to_recipe(recipe, "tool_box", 2)
		_add_to_recipe(recipe, "filing_cabinet", 1)
	return recipe


static func _recipe_home(rng: RandomNumberGenerator, size: int, twist: String, home: Dictionary) -> Array:
	# A household: pieces for the rooms this house has, a few big ones that
	# ride wrapped on the truck, and the usual twist on top.
	var tags: Array = []
	for floor_def in home.get("floors", []):
		for room in floor_def.get("rooms", []):
			var tag := str(Homes.KIND_TAG.get(Homes.kind(str(room.get("id", ""))), ""))
			if tag != "" and not tags.has(tag):
				tags.append(tag)
	var pool: Array = []
	for item_id in ItemDB.content_items.keys():
		var def: Dictionary = ItemDB.content_items[item_id]
		if tags.has(str(def.get("room", ""))):
			pool.append(str(item_id))
	pool.sort()
	var recipe: Array = []
	var total := 0
	var big := 0
	var guard := 0
	while total < size and guard < 80 and not pool.is_empty():
		guard += 1
		var item := str(pool[rng.randi_range(0, pool.size() - 1)])
		var def: Dictionary = ItemDB.get_item(item)
		var already := false
		for group in recipe:
			if str(group.get("item", "")) == item:
				already = true
		if already:
			continue
		if bool(def.get("nobox", false)):
			if big >= HOME_MAX_BIG:
				continue
			big += 1
		var cap := 2 if item in ["kitchen_chair", "pillow_stack", "flower_pots", "paint_tins", "garden_chair", "bedside_table"] else 1
		var count := clampi(rng.randi_range(1, cap), 1, size - total)
		recipe.append({"item": item, "count": count})
		total += count
	# A few of the old favourites so the sets and twists still work.
	if twist == "sets":
		_add_to_recipe(recipe, "clock_small", 2)
		recipe[recipe.size() - 1]["set"] = "clocks"
	if twist == "mystery":
		_add_to_recipe(recipe, "mystery_part", 3)
	if twist == "fragile":
		_add_to_recipe(recipe, "bowl", 2)
	if twist == "heavy":
		_add_to_recipe(recipe, "tool_box", 2)
	if twist == "cat":
		_add_to_recipe(recipe, "cushion", 1)
	return recipe


static func _add_to_recipe(recipe: Array, item: String, count: int) -> void:
	# Merge into an existing group so two pieces never share a number.
	for group in recipe:
		if str(group.get("item", "")) == item:
			group["count"] = int(group.get("count", 0)) + count
			return
	recipe.append({"item": item, "count": count})


static func _drive(rng: RandomNumberGenerator, id: String, twist: String) -> Dictionary:
	var ends: Array = DRIVE_ENDS[rng.randi_range(0, DRIVE_ENDS.size() - 1)]
	if twist == "ducks":
		ends = ["park_shed", "boathouse"]
	var weather := "clear"
	var roll := rng.randf()
	if roll < 0.3:
		weather = "rain"
	elif twist == "ducks":
		weather = "park"
	var hazards: Array = []
	var count := rng.randi_range(3, 6)
	for i in count:
		var along := clampf(0.12 + float(i) / float(count) * 0.76 + rng.randf_range(-0.04, 0.04), 0.08, 0.92)
		var kinds: Array = ["cone", "bump", "puddle" if weather == "rain" else "gravel"]
		var kind := str(kinds[rng.randi_range(0, kinds.size() - 1)])
		var hazard := {"type": kind, "along": along, "lane": rng.randi_range(-1, 1)}
		match kind:
			"bump":
				hazard["w"] = 170
				hazard["h"] = 36
			"puddle":
				hazard["r"] = rng.randi_range(48, 64)
			"gravel":
				hazard["w"] = 260
				hazard["h"] = 80
		hazards.append(hazard)
	hazards.append({"type": "ducks", "along": 0.84, "w": 220, "h": 160, "auto_stop": twist != "ducks", "honk": twist == "ducks"})
	var street := str(STREETS[rng.randi_range(0, STREETS.size() - 1)])
	var title := ("Rain on %s" if weather == "rain" else "%s, clear") % street
	return {
		"id": id,
		"title": title,
		"weather": weather,
		"music": "music_driving_rain" if weather == "rain" else "music_driving",
		"ambience": "amb_l03_rain_loop" if weather == "rain" else ("amb_l05_park_birds_loop" if weather == "park" else ""),
		"pickup": ends[0],
		"dropoff": ends[1],
		"alley": rng.randf() < 0.5,
		"hazards": hazards,
		"scenery": "pond" if weather == "park" else "town",
		"length_m": 120 + rng.randi_range(0, 160),
	}


static func _twist_line(twist: String) -> String:
	match twist:
		"cat":
			return "Something in one of the boxes is alive and smug."
		"sets":
			return "The labelled sets want to ride together."
		"mystery":
			return "There is a bag of parts nobody ever sorted."
		"ducks":
			return "The route runs past the pond. Honk, and the ducks hurry."
		"fragile":
			return "The glassware is unforgiving. Pad it."
		"heavy":
			return "Heavy boxes. Low in the truck, and lift with your knees."
	return "A plain move, which is its own kind of nice."


static func _mentor_line(twist: String, rng: RandomNumberGenerator) -> String:
	var lines: Array = [
		"Heavy on the bottom, fragile in the padding, and the rest sorts itself.",
		"Take the long way if the alley looks rough. Nobody is timing you.",
		"Sets ride together like a convoy. If one peels off, you still get paid.",
		"Rain makes the stop longer. Brake early and the boxes thank you.",
		"The till can wait. The customer in your truck cannot.",
	]
	if twist == "cat":
		return "If a box meows, open it before the drive. Trust me."
	return str(lines[rng.randi_range(0, lines.size() - 1)])
