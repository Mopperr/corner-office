extends Node3D
# The drive, seen from behind the truck. The town comes from city.gd (laid out
# in drive pixels, 32 to the metre) and is built here out of plain meshes:
# blocks of buildings, two-lane roads, a park with the pond, an alley, shop
# signs, and a loading bay at the curb of every place. The truck is the real
# mover_truck model; the chase camera hangs behind it and leans into the
# turns. Load the boxes at the client's curb, follow the arrow and the
# minimap, park in the bay at the other end, and unload. Box condition is the
# only score. You cannot fail a drive.
#
# The simulation stays in 2D pixels (pos, heading, vel) so the hazard and
# condition rules, and the tests that poke them, are unchanged.

const Tuning = preload("res://scripts/tuning.gd")
const UIKit = preload("res://scripts/ui_kit.gd")
const Crime = preload("res://scripts/crime.gd")
const Controls = preload("res://scripts/control_map.gd")
const City = preload("res://scripts/city.gd")
const Props = preload("res://scripts/props.gd")
const Outdoors = preload("res://scripts/outdoors.gd")
const Graphics = preload("res://scripts/settings_manager.gd")
const Homes = preload("res://scripts/homes.gd")

signal finished(result: Dictionary)

const PX := 32.0
# The truck's footprint in drive pixels: the model body is 4.5 m long and 2.1 m wide.
const FRAME_W := 148.0
const FRAME_H := 72.0
const ART_X := 2.0
const ART_Y := 1.0
const ART_W := 145.0
const ART_H := 71.0
const TRUCK_RADIUS := 38.0
const CAR_RADIUS := 34.0

const ASPHALT := Color("4F4B4E")
const LANE_LINE := Color("E8DFC8")
const KERB := Color("C9C2B5")
const PAVEMENT := Color("BDB5A8")
const GRASS := Color("8FB573")

var course: Dictionary = {}
var city = null
var pos := Vector2.ZERO
var heading := 0.0
var vel := Vector2.ZERO
var speed := 0.0
var condition := 100
var alley := false
var honks := 0
var honk_cool := 0.0
var duck_friend := false
var near_miss := false
var wobble_done := false
# Turnouts: a pull-in you can stop in for a moment (the L15 lighthouse); a
# reward is taken once per drive and goes out with the result.
var turnouts: Array = []
var turnout_hold := 0.0
var photos: Dictionary = {}
var hazard_cd: Dictionary = {}
var touching: Dictionary = {}
var contact_ready: Dictionary = {}
var duck_hold := 0.0
var laps := 0
var in_finish := false
var truck: Node3D
var cam: Camera3D
var meter: ProgressBar
var meter_label: Label
var stamp_label: Label
var kerb_signs := 0
var hint: Label
var time_alive := 0.0
var rain: CPUParticles3D
var wiper := 0.0
var rev_cd := 0.0
var brake_cd := 0.0
var radio_button: Button
const STATIONS: Array = [
	{"name": "Corner FM", "track": "music_driving", "ident": "All the hits from the corner."},
	{"name": "Rainy Nights", "track": "music_driving_rain", "ident": "Slow songs for wet roads."},
	{"name": "The Home Hour", "track": "music_act1_home", "ident": "Something for the drive home."},
	{"name": "Morning Show", "track": "music_act2_morning", "ident": "Up and at it."},
	{"name": "Trading Floor", "track": "music_computer_trading", "ident": "Numbers, with a beat."},
	{"name": "Build Hour", "track": "music_office_build", "ident": "Hammer along."},
	{"name": "Menu Lounge", "track": "music_main_menu", "ident": "Easy listening for parked trucks."},
	{"name": "Downtown", "track": "music_act4_downtown", "ident": "Big-city songs for a small town."},
	{"name": "The Record Store", "track": "music_record_store", "ident": "Crates of vinyl, one needle."},
	{"name": "Parade Band", "track": "music_parade_band", "ident": "Brass, drums, and a tuba that is late."},
	{"name": "Radio off", "track": "", "ident": "Just the engine."},
]
var jogger_cd := 0.0
var shake := 0.0
var running := true
var preview := false

# Town state.
var state := "load"
var pickup: Dictionary = {}
var dropoff: Dictionary = {}
var route := PackedVector2Array()
var route_index := 1
var hazards: Array = []
var cars: Array = []
var walkers: Array = []
var wave_t := 0.0
var at_dropoff := false
var patrols: Array = []
var spin := 0.0
var arrest_t := 0.0
var siren_t := 0.0
var busted := false
const TRUCK_MASS := 2.6
const CAR_MASS := 1.0
const COP_MASS := 1.6
const ARREST_SECONDS := 3.0
var spotted := 0
var spot_meter := 0.0
var spot_cool := 0.0
var patrol_flash := 0.0
var spot_label: Label
var backed_in := false
var in_bay := false
var reverse_beep := 0.0
var reverse_lights: Array = []
var box_count := 4
var box_anim: Array = []
var anim_t := 0.0
var hud_root: Control
var act_button: Button
var minimap: Control
var pulse := 0.0
var skid := 0.0
var world: Node3D
var arrow: Node3D
var route_dots: Array = []
var box_nodes: Array = []
var bay_nodes: Dictionary = {}
var cam_look := Vector3.ZERO
var objective: Label
var chips_slot: Control
var _chips_key := ""
var distance_label: Label
var speed_label: Label
var meter_fill: StyleBoxFlat
# The ridden road: the truck keeps to its lane along the route on its own.
# The player works the throttle, the brake and the horn; at the far end the
# truck stops just past the bay and backs into it.
const LANE_OFFSET := 48.0
const CORNER_R := 96.0
const PAST_BAY := 150.0
var lane := PackedVector2Array()
var lane_cum := PackedFloat32Array()
var lane_total := 0.0
var along := 0.0
var back_path := PackedVector2Array()
var back_t := 0.0
var at_end := false
var jolt := Vector2.ZERO
var roll := 0.0
# The chapters' small moments on the road: a line in the hint card and a
# thing in the world, once each.
var set_line := ""
var set_line_t := 0.0
var set_done: Dictionary = {}
var stray_cat: Node3D
# A long haul's first leg: a straight interstate out of town, scenery by
# region, no bays to back into; the new town's streets come after it.
var haul: Dictionary = {}
var highway := false
var highway_px := 0.0
# The interstate's cross-section, in metres: three lanes a carriageway,
# a shoulder outside each, a grass median with a barrier between them.
const HW_LANE := 3.7
const HW_LANES := 3
const HW_SHOULDER := 2.6
const HW_MEDIAN := 6.0
const HW_ROAD_PX := 1120.0


func _ready() -> void:
	if preview:
		course = {"title": "Garage run", "weather": "clear"}
		_hud()
		running = false
		return
	var drive_id := str(GameState.job.get("def", {}).get("drive", "rainy_afternoon"))
	course = JobDB.get_drive(drive_id)
	if course.is_empty():
		course = JobDB.get_drive("rainy_afternoon")
	condition = int(Tuning.get_value("box_condition.start", 100))
	haul = course.get("haul", {})
	highway = not haul.is_empty() and not bool(GameState.job.get("highway_done", false))
	if not highway and GameState.job.has("highway_condition"):
		# The second leg picks the boxes up the way the interstate left them.
		condition = clampi(int(GameState.job.get("highway_condition", condition)), 0, 100)
	if highway:
		highway_px = float(course.get("highway_m", 600)) * PX
		city = City.new()
		city.setup({"cols": 1, "rows": 0, "block": [highway_px, 100], "road": HW_ROAD_PX, "sidewalk": 0, "park": [-1, -1], "places": [], "shops": [], "kinds": {}, "alleys": []})
		var lane_y := _hw_lane_z(HW_LANES - 1, 1.0) * PX
		pickup = {"id": "onramp", "name": "the on-ramp", "bay": Rect2(140, lane_y - 20.0, 60, 40), "heading": 0.0}
		dropoff = {"id": "exit", "name": str(haul.get("city", "the exit")), "bay": Rect2(highway_px + 60, lane_y - 20.0, 60, 40), "heading": 0.0}
	else:
		city = City.load_default()
		pickup = city.place(str(course.get("pickup", "garage")))
		dropoff = city.place(str(course.get("dropoff", "cafe")))
	if pickup.is_empty():
		pickup = city.place("garage")
	if dropoff.is_empty():
		dropoff = city.place("cafe")
	pos = (pickup.get("bay", Rect2()) as Rect2).get_center()
	heading = float(pickup.get("heading", 0.0))
	route = city.route(pos, (dropoff.get("bay", Rect2()) as Rect2).get_center())
	route_index = 1
	if route.size() > 1:
		# Park facing the way out, squared to the road.
		var first := (route[1] - pos).angle()
		heading = round(first / (PI * 0.5)) * PI * 0.5
	box_count = maxi(1, GameState.job.get("boxes", []).size())
	if highway:
		# The route runs down the truck's own lane: the outer lane of the
		# eastbound carriageway, straight to the exit.
		var lane_y := _hw_lane_z(HW_LANES - 1, 1.0) * PX
		route = PackedVector2Array([Vector2(140.0, lane_y - LANE_OFFSET), Vector2(highway_px + 60.0, lane_y - LANE_OFFSET)])
		pos = route[0]
	_resolve_hazards()
	_resolve_turnouts()
	_build_lane()
	_lights()
	world = Node3D.new()
	world.name = "Town"
	add_child(world)
	if highway:
		_build_highway()
	else:
		_build_town()
	_build_truck()
	if highway:
		_spawn_highway_traffic()
	else:
		_spawn_traffic()
	cam = Camera3D.new()
	cam.name = "ChaseCamera"
	cam.fov = 62.0
	cam.near = 0.2
	cam.far = 260.0
	add_child(cam)
	cam.current = true
	_snap_camera()
	_hud()
	if not haul.is_empty():
		# A haul's legs start rolling: the boxes went in back in town, and
		# the on-ramp has no kerb to load from.
		state = "drive"
	UIKit.show_level_beat(self, GameState.present_current_slice_level(), true)
	var weather := str(course.get("weather", "clear"))
	var air := str(course.get("ambience", ""))
	if air == "" and str(course.get("weather", "clear")) == "night":
		air = "amb_l13_night_loop"
	# The road has its own tunes: the wet drive its own, the night its own,
	# and the clear days alternate between two.
	var road_track := str(course.get("music", "music_driving"))
	if weather == "rain":
		road_track = "music_rain_on_the_cab"
	elif weather == "night":
		road_track = "music_evening_shift"
	elif GameState.jobs_done % 2 == 0:
		road_track = "music_open_road"
	AudioDirector.play_bed(road_track, air)
	_radio_apply(false)
	if weather == "rain" or weather == "snow":
		_make_rain(weather == "snow")
	if str(course.get("id", "")) == "duck_pond":
		AudioDirector.start_loop("sfx_l05_fountain_loop")
	AudioDirector.start_loop("sfx_truck_idle_loop")
	_set_action("Load up")


func _exit_tree() -> void:
	AudioDirector.stop_level()


# ---------------------------------------------------------------- scale

static func to_world(p: Vector2, y := 0.0) -> Vector3:
	return Vector3(p.x / PX, y, p.y / PX)


static func rect_center(rect: Rect2, y := 0.0) -> Vector3:
	return to_world(rect.get_center(), y)


func _forward() -> Vector3:
	return Vector3(cos(heading), 0.0, sin(heading))


# ---------------------------------------------------------------- setup

func _resolve_turnouts() -> void:
	turnouts.clear()
	for raw in course.get("turnouts", []):
		var spec: Dictionary = raw
		var spot: Dictionary = city.point_along(route, float(spec.get("along", 0.5)))
		var dir: Vector2 = spot.get("dir", Vector2.RIGHT)
		var side := Vector2(-dir.y, dir.x)
		var at: Vector2 = spot.get("pos", Vector2.ZERO) + side * float(spec.get("lane", 0)) * city.road * 0.25
		var size := Vector2(float(spec.get("w", 160)), float(spec.get("h", 120)))
		turnouts.append({"id": str(spec.get("id", "")), "rect": Rect2(at - size * 0.5, size), "stop_s": float(spec.get("stop_s", 2.0)), "reward": str(spec.get("reward", ""))})


func _check_lighthouse_photo(delta: float) -> void:
	# Stop inside a turnout for its few seconds and the photo is taken, once.
	var inside := false
	for spot in turnouts:
		var reward := str(spot.get("reward", ""))
		if reward == "" or photos.has(reward):
			continue
		if (spot["rect"] as Rect2).has_point(pos) or (spot["rect"] as Rect2).get_center().distance_to(pos) < 130.0:
			inside = true
			if absf(speed) < 14.0:
				turnout_hold += delta
				if turnout_hold >= float(spot.get("stop_s", 2.0)):
					photos[reward] = true
					turnout_hold = 0.0
					AudioDirector.play_sfx("sfx_notification_soft")
			else:
				turnout_hold = 0.0
	if not inside:
		turnout_hold = 0.0


func _resolve_hazards() -> void:
	hazards.clear()
	for raw in course.get("hazards", []):
		var hazard: Dictionary = (raw as Dictionary).duplicate(true)
		if not hazard.has("x") and hazard.has("along"):
			var spot: Dictionary = city.point_along(route, float(hazard.get("along", 0.5)))
			var dir: Vector2 = spot.get("dir", Vector2.RIGHT)
			var side := Vector2(-dir.y, dir.x)
			var lane_step: float = city.road * 0.25 if not highway else HW_LANE * PX * 0.25
			var at: Vector2 = spot.get("pos", Vector2.ZERO) + side * float(hazard.get("lane", 0)) * lane_step
			hazard["x"] = at.x
			hazard["y"] = at.y
			if str(hazard.get("type", "")) == "bump" and absf(dir.x) > absf(dir.y):
				# A speed bump lies across the road.
				var w := float(hazard.get("w", 170))
				var h := float(hazard.get("h", 36))
				hazard["w"] = h
				hazard["h"] = w
		hazards.append(hazard)
	if bool(course.get("alley", false)):
		for cut in city.alleys:
			var middle: Vector2 = (cut as Rect2).get_center()
			hazards.append({"type": "wobble", "x": middle.x, "y": middle.y, "on": "alley"})


func _lights() -> void:
	var weather := str(course.get("weather", "clear"))
	var env := WorldEnvironment.new()
	env.name = "World"
	var environment := Graphics.load_environment(SaveManager.graphics_quality)
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	if weather == "night":
		sky_material.sky_top_color = Color("0E1424")
		sky_material.sky_horizon_color = Color("2A3350")
		sky_material.ground_bottom_color = Color("101218")
		sky_material.ground_horizon_color = Color("23262E")
	elif weather == "rain":
		sky_material.sky_top_color = Color("6C7384")
		sky_material.sky_horizon_color = Color("A5A7B0")
		sky_material.ground_bottom_color = Color("4F4B4E")
		sky_material.ground_horizon_color = Color("8E8A8C")
	elif weather == "snow":
		sky_material.sky_top_color = Color("B9C3CC")
		sky_material.sky_horizon_color = Color("E6EAEE")
		sky_material.ground_bottom_color = Color("D9DEE3")
		sky_material.ground_horizon_color = Color("EEF1F3")
	else:
		sky_material.sky_top_color = Color("79B4E6")
		sky_material.sky_horizon_color = Color("EAF2F6")
		sky_material.ground_bottom_color = Color("8FB573")
		sky_material.ground_horizon_color = Color("D2CBBE")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.fog_enabled = true
	environment.fog_light_color = Color("D7E3EA") if weather != "rain" else Color("9A9DA6")
	environment.fog_density = 0.0025 if weather != "rain" else 0.009
	if weather == "night":
		environment.fog_light_color = Color("141A2A")
		environment.fog_density = 0.009
		environment.ambient_light_color = Color("3A4466")
		environment.ambient_light_energy = 0.35
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, 40, 0)
	sun.light_color = Color("FFE8CC") if weather != "rain" else Color("CFD2DA")
	sun.light_energy = 1.2 if weather != "rain" else 0.72
	if weather == "night":
		# Moonlight: low, blue, and the headlights do the rest.
		sun.light_color = Color("8FA3D6")
		sun.light_energy = 0.22
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -140, 0)
	fill.light_color = Color("A9C4D4")
	fill.light_energy = 0.25
	fill.shadow_enabled = false
	add_child(fill)


func _slab(size: Vector3, at: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	# `at.y` is the bottom of the slab.
	var slab := Props.mesh_box(size, color)
	slab.position = at + Vector3(0, size.y * 0.5, 0)
	(parent if parent else world).add_child(slab)
	return slab


func _build_town() -> void:
	var bounds: Rect2 = city.bounds
	var size := to_world(bounds.size)
	# Ground, then sidewalks, roads and lane paint on top.
	_slab(Vector3(size.x + 80, 0.1, size.z + 80), Vector3(size.x * 0.5, -0.1, size.z * 0.5), GRASS if str(course.get("weather", "clear")) != "snow" else Color("EEF1F3"))
	_slab(Vector3(size.x, 0.02, size.z), Vector3(size.x * 0.5, -0.02, size.z * 0.5), PAVEMENT)
	for rect in city.roads:
		var r: Rect2 = rect
		_slab(Vector3(r.size.x / PX, 0.02, r.size.y / PX), rect_center(r, -0.01), ASPHALT)
	for rect in city.roads:
		var r: Rect2 = rect
		if r.size.x > r.size.y:
			var z := (r.position.y + r.size.y * 0.5) / PX
			var x := (r.position.x + 40.0) / PX
			while x < (r.end.x - 40.0) / PX:
				_slab(Vector3(1.6, 0.01, 0.18), Vector3(x + 0.8, 0.0, z), LANE_LINE)
				x += 3.0
			# Edge lines along the kerbs.
			_slab(Vector3(r.size.x / PX, 0.01, 0.12), Vector3((r.position.x + r.size.x * 0.5) / PX, 0.0, (r.position.y + 14.0) / PX), Color(LANE_LINE, 0.8))
			_slab(Vector3(r.size.x / PX, 0.01, 0.12), Vector3((r.position.x + r.size.x * 0.5) / PX, 0.0, (r.end.y - 14.0) / PX), Color(LANE_LINE, 0.8))
		else:
			var x2 := (r.position.x + r.size.x * 0.5) / PX
			var z2 := (r.position.y + 40.0) / PX
			while z2 < (r.end.y - 40.0) / PX:
				_slab(Vector3(0.18, 0.01, 1.6), Vector3(x2, 0.0, z2 + 0.8), LANE_LINE)
				z2 += 3.0
			_slab(Vector3(0.12, 0.01, r.size.y / PX), Vector3((r.position.x + 14.0) / PX, 0.0, (r.position.y + r.size.y * 0.5) / PX), Color(LANE_LINE, 0.8))
			_slab(Vector3(0.12, 0.01, r.size.y / PX), Vector3((r.end.x - 14.0) / PX, 0.0, (r.position.y + r.size.y * 0.5) / PX), Color(LANE_LINE, 0.8))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "")) + "town")
	_build_crossings()
	for c in city.cols:
		for r in city.rows:
			var rect: Rect2 = city.block_rect(c, r)
			if Vector2i(c, r) == city.park_block:
				_build_park(rect)
				continue
			if city.is_park(Vector2i(c, r)):
				_build_green(rect)
				continue
			# Raised kerb around the block.
			_slab(Vector3(rect.size.x / PX, 0.12, rect.size.y / PX), rect_center(rect, 0.0), KERB)
	_front_spans = _front_footprints()
	for entry in city.buildings:
		_build_building(entry, rng)
	_build_fronts()
	_build_hills(size)
	for cut in city.alleys:
		var cut_rect: Rect2 = cut
		_slab(Vector3(cut_rect.size.x / PX, 0.03, cut_rect.size.y / PX), rect_center(cut_rect, 0.0), Color("6B4A3A"))
		var alley_sign := _sign_text("Alley", rect_center(Rect2(cut_rect.position, Vector2(minf(cut_rect.size.x, 72.0), 40)), 3.2), Color("F4E9D8"))
		alley_sign.font_size = 90
	# The two kerbside fronts carry their own name board; a second sign at
	# the same door would read twice.
	var front_doors: Array = []
	for front in [pickup, dropoff]:
		var front_def := _front_venue(front)
		if not front.is_empty() and not (Homes.is_home(front_def) and str(front_def.get("kind", "house")) != "shop"):
			front_doors.append(front.get("door", Vector2.ZERO))
	for shop in city.shops:
		if not _near_front(shop.get("door", Vector2.ZERO), front_doors):
			_build_sign(shop, Color("C68B59"))
	for id in city.places.keys():
		var place: Dictionary = city.places[id]
		if not _near_front(place.get("door", Vector2.ZERO), front_doors):
			_build_sign(place, place.get("color", Color("C68B59")))
	_build_bay(pickup, "LOAD")
	_build_bay(dropoff, "UNLOAD")
	for spot in city.curb_spots(rng):
		var kind := str(spot.get("kind", ""))
		var at: Vector3 = to_world(spot.get("at", Vector2.ZERO), 0.12)
		match kind:
			"lamppost":
				var post := Props.mesh_cylinder(0.08, 4.0, Color("4E4A48"))
				post.position = at
				world.add_child(post)
				var head := Props.mesh_box(Vector3(0.5, 0.25, 0.5), Color("FFE3A8"))
				head.position = at + Vector3(0, 4.0, 0)
				world.add_child(head)
			"mailbox":
				var box := Props.mesh_box(Vector3(0.4, 1.1, 0.4), Color("D86F5B"))
				box.position = at
				world.add_child(box)
			"umbrella":
				var pole := Props.mesh_cylinder(0.04, 2.2, Color("4E4A48"))
				pole.position = at
				world.add_child(pole)
				var top := Outdoors._cone(1.2, 0.5, Color("D9765F"))
				top.position = at + Vector3(0, 2.2, 0)
				world.add_child(top)
			"parked_car":
				# Never on or beside a bay: the truck parks there, and a car
				# through its side reads as one vehicle.
				if _near_bay(spot.get("at", Vector2.ZERO), 260.0):
					continue
				var parked := _make_car(Color("C9D2C0"))
				parked.position = to_world(spot.get("at", Vector2.ZERO), 0.0)
				world.add_child(parked)
	for hazard in hazards:
		_build_hazard(hazard)
	_dress_sidewalks(rng)
	_spawn_walkers(rng)


func _dress_sidewalks(rng: RandomNumberGenerator) -> void:
	# Trees every few metres along the kerb, planters by the doors, a bus stop on a few corners, a van or two.
	var doors: Array = []
	for id in city.places.keys():
		doors.append(to_world((city.places[id] as Dictionary).get("door", Vector2.ZERO)))
	for shop in city.shops:
		doors.append(to_world((shop as Dictionary).get("door", Vector2.ZERO)))
	var bays: Array = [pickup.get("bay", Rect2()), dropoff.get("bay", Rect2())]
	for c in city.cols:
		for r in city.rows:
			if city.is_park(Vector2i(c, r)):
				continue
			var houses_block: bool = city.block_kind(Vector2i(c, r)) == "houses"
			var rect: Rect2 = city.block_rect(c, r)
			var edge: float = city.sidewalk * 0.5
			var ring: Array = [
				[Vector2(rect.position.x + edge, rect.position.y + edge), Vector2(rect.end.x - edge, rect.position.y + edge)],
				[Vector2(rect.end.x - edge, rect.position.y + edge), Vector2(rect.end.x - edge, rect.end.y - edge)],
				[Vector2(rect.end.x - edge, rect.end.y - edge), Vector2(rect.position.x + edge, rect.end.y - edge)],
				[Vector2(rect.position.x + edge, rect.end.y - edge), Vector2(rect.position.x + edge, rect.position.y + edge)],
			]
			for seg in ring:
				var a: Vector2 = seg[0]
				var b: Vector2 = seg[1]
				var length := a.distance_to(b)
				var step := 9.0 * PX
				var d := step * 0.5 + rng.randf_range(-40.0, 40.0)
				while d < length - step * 0.4:
					var at := a.lerp(b, d / length)
					var near_door := false
					for door in doors:
						if (door as Vector3).distance_to(to_world(at)) < 3.2:
							near_door = true
					for bay in bays:
						if (bay as Rect2).grow(70).has_point(at):
							near_door = true
					if not near_door:
						if rng.randf() < 0.75:
							Outdoors._tree(world, to_world(at, 0.12), rng.randf_range(0.7, 0.95))
						else:
							var planter := Props.mesh_box(Vector3(0.9, 0.5, 0.9), Color("A9774C"))
							planter.position = to_world(at, 0.12)
							world.add_child(planter)
							Outdoors._bush(world, to_world(at, 0.5), 0.45)
					d += step
			# A bus stop on the south-west corner of every other block (not on a street of houses).
			if (c + r) % 2 == 0 and not houses_block and not _near_bay(Vector2(rect.position.x + edge * 2.5, rect.end.y - edge), 200.0):
				var corner := Vector2(rect.position.x + edge * 2.5, rect.end.y - edge)
				var pole := Props.mesh_cylinder(0.05, 2.6, Color("4E4A48"))
				pole.position = to_world(corner, 0.12)
				world.add_child(pole)
				var plate := Props.mesh_box(Vector3(0.7, 0.45, 0.06), UIKit.BLUE)
				plate.position = to_world(corner, 2.3) + Vector3(0, 0.2, 0)
				world.add_child(plate)
				var roof := Props.mesh_box(Vector3(3.0, 0.12, 1.4), Color("D9D2C4"))
				roof.position = to_world(corner, 2.4) + Vector3(2.0, 0.06, 0)
				world.add_child(roof)
				for dx in [0.6, 3.4]:
					var post := Props.mesh_cylinder(0.05, 2.4, Color("4E4A48"))
					post.position = to_world(corner, 0.12) + Vector3(dx, 0, 0)
					world.add_child(post)
				Outdoors._bench(world, to_world(corner).x + 2.0, to_world(corner).z + 0.1)
			# A parked van on one long side.
			if rng.randf() < 0.4 and not houses_block:
				var van := _make_car(Color("D9D2C4"))
				var body := van.get_child(0) as MeshInstance3D
				if body:
					(body.mesh as BoxMesh).size = Vector3(4.6, 1.6, 1.9)
					body.position.y = 0.9
				var van_at := Vector2(rect.position.x + rect.size.x * rng.randf_range(0.2, 0.5), rect.position.y - city.road * 0.25)
				if _near_bay(van_at, 260.0):
					van.queue_free()
				else:
					van.position = to_world(van_at)
					world.add_child(van)


func _make_walker(color: Color) -> Node3D:
	var person := Node3D.new()
	var legs := Props.mesh_cylinder(0.16, 0.8, Color("3E3A4F"))
	person.add_child(legs)
	var body := Props.mesh_cylinder(0.24, 0.7, color)
	body.position.y = 0.8
	person.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.19
	sphere.height = 0.38
	head.mesh = sphere
	head.material_override = Props.mat(Color("E7C9A8"))
	head.position.y = 1.72
	person.add_child(head)
	var arm := Props.mesh_cylinder(0.06, 0.6, color.darkened(0.1))
	arm.name = "Arm"
	arm.position = Vector3(0, 1.1, 0.3)
	person.add_child(arm)
	return person


func _spawn_walkers(rng: RandomNumberGenerator) -> void:
	var count := int(Tuning.get_value("drive.walkers", 16))
	var palette := [Color("D9765F"), Color("8FAF7E"), Color("7FA3B8"), Color("E6B655"), Color("C68B59"), Color("D4C1D8")]
	for i in count:
		var c := rng.randi_range(0, city.cols - 1)
		var r := rng.randi_range(0, city.rows - 1)
		if city.is_park(Vector2i(c, r)):
			continue
		var rect: Rect2 = city.block_rect(c, r).grow(-city.sidewalk * 0.5)
		var loop := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		var seg := rng.randi_range(0, 3)
		var at: Vector2 = loop[seg].lerp(loop[(seg + 1) % 4], rng.randf())
		var node := _make_walker(palette[i % palette.size()])
		node.name = "Walker"
		node.position = to_world(at, 0.12)
		world.add_child(node)
		walkers.append({"loop": loop, "seg": seg, "pos": at, "speed": rng.randf_range(0.9, 1.4) * PX, "node": node, "wait": 0.0, "wave": 0.0, "phase": rng.randf() * TAU, "dir": 1 if rng.randf() < 0.5 else -1})


func _walkers(delta: float) -> void:
	var truck_center := _art_center()
	for w in walkers:
		var loop: PackedVector2Array = w["loop"]
		var seg: int = w["seg"]
		var next := (seg + int(w["dir"]) + 4) % 4
		var target: Vector2 = loop[next]
		var at: Vector2 = w["pos"]
		var dir := (target - at).normalized()
		var node: Node3D = w["node"]
		var near := at.distance_to(truck_center) < 150.0
		# Step back from the kerb and wait while the truck passes.
		if near:
			w["wait"] = 0.6
		if float(w["wait"]) > 0.0:
			w["wait"] = float(w["wait"]) - delta
		else:
			at += dir * float(w["speed"]) * delta
			if at.distance_to(target) < 4.0:
				w["seg"] = next
		w["pos"] = at
		node.position = to_world(at, 0.12)
		var moving := float(w["wait"]) <= 0.0
		node.position.y += absf(sin(time_alive * 9.0 + float(w["phase"]))) * (0.06 if moving else 0.0)
		node.rotation.y = -dir.angle() + PI * 0.5
		var arm := node.get_node_or_null("Arm") as Node3D
		if arm:
			if float(w["wave"]) > 0.0:
				w["wave"] = float(w["wave"]) - delta
				arm.rotation.x = -PI * 0.75 + sin(time_alive * 14.0) * 0.4
			else:
				arm.rotation.x = lerpf(arm.rotation.x, 0.0, delta * 6.0)


func _wave_nearby() -> void:
	var truck_center := _art_center()
	for w in walkers:
		if (w["pos"] as Vector2).distance_to(truck_center) < 320.0:
			w["wave"] = 1.4


const FACADES: Array = ["E2B88F", "D98A6B", "F1E6D2", "C9B9A8", "B9CBD6", "E6CDA3", "B98C72", "EFC7B3", "A9C6A2", "F0D7A5"]
# Names over the shopfronts along the route, so the town reads as a town.
const SHOP_NAMES: Array = ["Launderette", "Bakery", "Records", "Hardware", "Florist", "Barber", "Books", "Chemist", "Deli", "Tailor", "Bikes", "Pet Shop", "Frames", "Noodles", "Greengrocer", "Keys Cut", "Wool", "Café", "Toys", "Pizza", "Dry Cleaner", "Post Office", "Antiques", "Guitars"]


func _build_building(entry: Dictionary, rng: RandomNumberGenerator) -> void:
	# A block is a row of separate buildings, not one slab: different widths,
	# heights, colours and roofs, with real windows, shop glazing, a plinth and a cornice.
	if str(entry.get("kind", "town")) == "houses":
		_build_house_row(entry, rng)
		return
	var rect: Rect2 = entry.get("rect", Rect2())
	var along_x := rect.size.x >= rect.size.y
	var length := (rect.size.x if along_x else rect.size.y) / PX
	var depth := (rect.size.y if along_x else rect.size.x) / PX
	var cursor := 0.0
	var index := 0
	while length - cursor > 4.0:
		var want := rng.randf_range(5.0, 9.0)
		if length - cursor - want < 4.0:
			want = length - cursor
		var first := index == 0
		var last := absf(cursor + want - length) < 0.01
		var origin := Vector3(rect.position.x / PX, 0.12, rect.position.y / PX)
		var parcel_pos := origin + (Vector3(cursor, 0, 0) if along_x else Vector3(0, 0, cursor))
		var parcel_size := Vector3(want, 0, depth) if along_x else Vector3(depth, 0, want)
		# The place the truck leaves from and the one it pulls up at are
		# built from their own blueprints; the row leaves them their plot.
		var parcel_rect := Rect2(parcel_pos.x * PX, parcel_pos.z * PX, parcel_size.x * PX, parcel_size.z * PX)
		var taken := false
		for span in _front_spans:
			if (span as Rect2).intersects(parcel_rect):
				taken = true
		if not taken:
			_build_parcel(parcel_pos, parcel_size, rng, along_x, first, last)
		cursor += want
		index += 1


func _build_parcel(at: Vector3, footprint: Vector3, rng: RandomNumberGenerator, along_x: bool, first: bool, last: bool) -> void:
	var floors := rng.randi_range(2, 5)
	var floor_h := 3.2
	var height := floors * floor_h
	var color := Color(str(FACADES[rng.randi_range(0, FACADES.size() - 1)]))
	var trim := color.lightened(0.28)
	var center := at + Vector3(footprint.x * 0.5, 0, footprint.z * 0.5)
	var body := _slab(Vector3(footprint.x, height, footprint.z), at + Vector3(footprint.x * 0.5, 0, footprint.z * 0.5), color)
	body.name = "Building"
	# The wall gets a texture to go with its colour: brick on the warm
	# fronts, plaster on the pale ones, concrete on the tall ones.
	var tex := "brick_painted" if color.r > color.b + 0.15 else "plaster"
	if floors >= 5:
		tex = "concrete"
	body.material_override = Props.tex_mat(tex, color, 0.55 if tex == "brick_painted" else 0.35, 0.9)
	# Plinth, string courses between floors, and a cornice under the roof.
	_slab(Vector3(footprint.x + 0.12, 0.7, footprint.z + 0.12), center, color.darkened(0.3))
	for f in range(1, floors):
		_slab(Vector3(footprint.x + 0.08, 0.14, footprint.z + 0.08), center + Vector3(0, f * floor_h - 0.07, 0), trim)
	_slab(Vector3(footprint.x + 0.36, 0.32, footprint.z + 0.36), center + Vector3(0, height - 0.32, 0), trim)
	_slab(Vector3(footprint.x + 0.2, 0.18, footprint.z + 0.2), center + Vector3(0, height - 0.6, 0), trim.darkened(0.08))
	# Pilasters up the street corners, so one building reads apart from the next.
	for corner in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var post := Props.mesh_box(Vector3(0.36, height - 0.4, 0.36), trim.darkened(0.04))
		post.position = center + Vector3(corner.x * (footprint.x * 0.5 - 0.1), (height - 0.4) * 0.5 + 0.7, corner.z * (footprint.z * 0.5 - 0.1))
		world.add_child(post)
	# One corner building in a while turns a rounded tower to the junction.
	if (first or last) and rng.randf() < 0.3:
		var tower := Props.mesh_cylinder(1.5, height + 0.5, color.darkened(0.06))
		var tx := footprint.x * 0.5 - 1.2
		if first:
			tx = -footprint.x * 0.5 + 1.2
		var tz := footprint.z * 0.5 - 1.2
		if along_x:
			tz = -footprint.z * 0.5 + 1.2
		tower.position = center + Vector3(tx, 0, tz)
		world.add_child(tower)
		var cap := Outdoors._cone(1.7, 1.4, Color("6E6A66"))
		cap.position = tower.position + Vector3(0, height + 0.5, 0)
		world.add_child(cap)
	# Windows: one multimesh of frames and one of glass per building.
	var faces: Array = []
	if along_x:
		faces.append({"origin": at, "dir": Vector3(1, 0, 0), "normal": Vector3(0, 0, -1), "len": footprint.x, "street": true})
		faces.append({"origin": at + Vector3(footprint.x, 0, footprint.z), "dir": Vector3(-1, 0, 0), "normal": Vector3(0, 0, 1), "len": footprint.x, "street": true})
		if first:
			faces.append({"origin": at + Vector3(0, 0, footprint.z), "dir": Vector3(0, 0, -1), "normal": Vector3(-1, 0, 0), "len": footprint.z, "street": true})
		if last:
			faces.append({"origin": at + Vector3(footprint.x, 0, 0), "dir": Vector3(0, 0, 1), "normal": Vector3(1, 0, 0), "len": footprint.z, "street": true})
	else:
		faces.append({"origin": at + Vector3(0, 0, footprint.z), "dir": Vector3(0, 0, -1), "normal": Vector3(-1, 0, 0), "len": footprint.z, "street": true})
		faces.append({"origin": at + Vector3(footprint.x, 0, 0), "dir": Vector3(0, 0, 1), "normal": Vector3(1, 0, 0), "len": footprint.z, "street": true})
		if first:
			faces.append({"origin": at, "dir": Vector3(1, 0, 0), "normal": Vector3(0, 0, -1), "len": footprint.x, "street": true})
		if last:
			faces.append({"origin": at + Vector3(footprint.x, 0, footprint.z), "dir": Vector3(-1, 0, 0), "normal": Vector3(0, 0, 1), "len": footprint.x, "street": true})
	var frames: Array = []
	var panes: Array = []
	var sills: Array = []
	var glass_color := Color("4A5F6E") if rng.randf() < 0.6 else Color("5C6B5A")
	var awning_color: Color = [Color("D9765F"), Color("7FA3B8"), Color("8FAF7E"), Color("E6B655")][rng.randi_range(0, 3)]
	var awnings := rng.randf() < 0.55
	var named := false
	for face in faces:
		var origin: Vector3 = face["origin"]
		var dir: Vector3 = face["dir"]
		var normal: Vector3 = face["normal"]
		var face_len := float(face["len"])
		var cols := maxi(1, int(floor((face_len - 0.8) / 2.3)))
		var gap := face_len / float(cols)
		for f in floors:
			if f == 0:
				# Shop glazing along the street, with a door bay left clear.
				var band := Props.mesh_box(Vector3(maxf(face_len - 1.2, 1.0), 2.1, 0.08), glass_color)
				band.position = origin + dir * (face_len * 0.5) + normal * 0.05 + Vector3(0, 1.25, 0)
				band.rotation.y = atan2(dir.x, -dir.z) if absf(dir.x) > 0.5 else atan2(dir.x, -dir.z)
				band.rotation.y = -atan2(dir.z, dir.x)
				world.add_child(band)
				if awnings and bool(face.get("street", false)):
					# A striped awning over the shopfront.
					var awning := Props.mesh_box(Vector3(maxf(face_len - 1.6, 1.0), 0.1, 1.1), awning_color)
					awning.position = origin + dir * (face_len * 0.5) + normal * 0.6 + Vector3(0, 2.45, 0)
					awning.rotation.y = -atan2(dir.z, dir.x)
					awning.rotation.x = 0.18
					world.add_child(awning)
					var valance := Props.mesh_box(Vector3(maxf(face_len - 1.6, 1.0), 0.22, 0.04), awning_color.lightened(0.35))
					valance.position = origin + dir * (face_len * 0.5) + normal * 1.12 + Vector3(0, 2.3, 0)
					valance.rotation.y = -atan2(dir.z, dir.x)
					world.add_child(valance)
					# A name board over the awning, the first street face only.
					if not named:
						named = true
						var board := Props.mesh_box(Vector3(minf(face_len - 1.8, 4.2), 0.7, 0.1), color.darkened(0.45))
						board.position = origin + dir * (face_len * 0.5) + normal * 0.08 + Vector3(0, 3.15, 0)
						board.rotation.y = -atan2(dir.z, dir.x)
						world.add_child(board)
						var label := _sign_text(str(SHOP_NAMES[rng.randi_range(0, SHOP_NAMES.size() - 1)]), origin + dir * (face_len * 0.5) + normal * 0.16 + Vector3(0, 3.15, 0), Color("F4E9D8"))
						label.font_size = 56
						# Painted on the board: it faces the street, not the camera.
						label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
						label.rotation.y = atan2(normal.x, normal.z)
						label.visibility_range_end = 40.0
				var mullion_count := maxi(1, int(face_len / 1.6))
				for m in range(1, mullion_count):
					var mullion := Props.mesh_box(Vector3(0.08, 2.1, 0.12), trim)
					mullion.position = origin + dir * (0.6 + (face_len - 1.2) * float(m) / float(mullion_count)) + normal * 0.06 + Vector3(0, 0.0, 0)
					mullion.rotation.y = -atan2(dir.z, dir.x)
					world.add_child(mullion)
				continue
			for ccol in cols:
				var along := gap * (float(ccol) + 0.5)
				var y := f * floor_h + 1.0
				var pos := origin + dir * along + normal * 0.04 + Vector3(0, y, 0)
				var basis := Basis(Vector3.UP, -atan2(dir.z, dir.x))
				frames.append(Transform3D(basis, pos))
				panes.append(Transform3D(basis, pos + normal * 0.03))
				sills.append(Transform3D(basis, pos + normal * 0.08 + Vector3(0, -0.84, 0)))
			# A balcony on one upper floor, now and then.
			if f >= 1 and rng.randf() < 0.25:
				var rail := Props.mesh_box(Vector3(minf(face_len * 0.6, 4.0), 0.9, 0.08), trim)
				rail.position = origin + dir * (face_len * 0.5) + normal * 0.95 + Vector3(0, f * floor_h + 0.45, 0)
				rail.rotation.y = -atan2(dir.z, dir.x)
				world.add_child(rail)
				var deck := Props.mesh_box(Vector3(minf(face_len * 0.6, 4.0), 0.12, 1.0), color.darkened(0.2))
				deck.position = origin + dir * (face_len * 0.5) + normal * 0.5 + Vector3(0, f * floor_h - 0.06, 0)
				deck.rotation.y = -atan2(dir.z, dir.x)
				world.add_child(deck)
	_multimesh(Vector3(1.3, 1.6, 0.08), trim, frames)
	if str(course.get("weather", "clear")) == "night":
		# After dark about a third of the windows are lit, warm or television blue.
		var dark: Array = []
		var warm: Array = []
		var cool: Array = []
		for pane in panes:
			var roll := rng.randf()
			if roll < 0.28:
				warm.append(pane)
			elif roll < 0.36:
				cool.append(pane)
			else:
				dark.append(pane)
		_multimesh(Vector3(1.05, 1.35, 0.08), Color("1B2630"), dark)
		_multimesh(Vector3(1.05, 1.35, 0.08), Color("FFE7B0"), warm, 1.6)
		_multimesh(Vector3(1.05, 1.35, 0.08), Color("9FD0FF"), cool, 1.2)
	else:
		_multimesh(Vector3(1.05, 1.35, 0.08), glass_color, panes)
	_multimesh(Vector3(1.5, 0.08, 0.22), trim.darkened(0.1), sills)
	# The tall ones step back at the top, with a terrace and a hedge round it.
	if floors >= 4 and rng.randf() < 0.5:
		var top := _slab(Vector3(footprint.x * 0.7, floor_h, footprint.z * 0.7), center + Vector3(0, height, 0), color.lightened(0.06))
		top.name = "Setback"
		_slab(Vector3(footprint.x * 0.7 + 0.3, 0.3, footprint.z * 0.7 + 0.3), center + Vector3(0, height + floor_h - 0.3, 0), trim)
		for corner in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
			Outdoors._bush(world, center + Vector3(corner.x * (footprint.x * 0.5 - 0.5), height, corner.z * (footprint.z * 0.5 - 0.5)), 0.4)
		height += floor_h
		center = center
	# Roof: a parapet with clutter, or a gable.
	if rng.randf() < 0.35:
		var roof := MeshInstance3D.new()
		var prism := PrismMesh.new()
		var ridge_along_x := footprint.x >= footprint.z
		var span := footprint.z if ridge_along_x else footprint.x
		prism.size = Vector3((footprint.x if ridge_along_x else footprint.z) + 0.5, span * 0.42, span + 0.5)
		prism.left_to_right = 0.5
		roof.mesh = prism
		roof.material_override = Props.mat(Color("7A4F2A") if rng.randf() < 0.5 else Color("6E6A66"))
		roof.position = center + Vector3(0, height + prism.size.y * 0.5 - 0.1, 0)
		if not ridge_along_x:
			roof.rotation.y = PI * 0.5
		world.add_child(roof)
		var stack := Props.mesh_box(Vector3(0.6, 1.1, 0.6), color.darkened(0.25))
		var stack_x := footprint.x * 0.3 if ridge_along_x else 0.0
		var stack_z := 0.0 if ridge_along_x else footprint.z * 0.3
		stack.position = center + Vector3(stack_x, height + prism.size.y * 0.55, stack_z)
		world.add_child(stack)
	else:
		_slab(Vector3(footprint.x, 0.6, 0.25), center + Vector3(0, height, -footprint.z * 0.5 + 0.12), color.darkened(0.12))
		_slab(Vector3(footprint.x, 0.6, 0.25), center + Vector3(0, height, footprint.z * 0.5 - 0.12), color.darkened(0.12))
		_slab(Vector3(0.25, 0.6, footprint.z), center + Vector3(0, height, 0) + Vector3(-footprint.x * 0.5 + 0.12, 0, 0), color.darkened(0.12))
		_slab(Vector3(0.25, 0.6, footprint.z), center + Vector3(0, height, 0) + Vector3(footprint.x * 0.5 - 0.12, 0, 0), color.darkened(0.12))
		for i in rng.randi_range(1, 3):
			var spot := at + Vector3(rng.randf_range(1.0, footprint.x - 1.0), height, rng.randf_range(1.0, footprint.z - 1.0))
			if rng.randf() < 0.5:
				_slab(Vector3(1.2, 0.8, 1.0), spot, Color("9C9A94"))
			else:
				var tank := Props.mesh_cylinder(0.6, 1.3, Color("7A5C40"))
				tank.position = spot + Vector3(0, 0.3, 0)
				world.add_child(tank)
				for leg in [Vector3(0.4, 0, 0.4), Vector3(-0.4, 0, -0.4), Vector3(0.4, 0, -0.4), Vector3(-0.4, 0, 0.4)]:
					var post := Props.mesh_cylinder(0.05, 0.3, Color("4E4A48"))
					post.position = spot + leg
					world.add_child(post)


func _multimesh(size: Vector3, color: Color, transforms: Array, glow := 0.0) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = size
	mm.mesh = box
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	var material := Props.mat(color)
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	node.material_override = material
	world.add_child(node)


func _build_park(rect: Rect2) -> void:
	_slab(Vector3(rect.size.x / PX, 0.08, rect.size.y / PX), rect_center(rect, 0.0), GRASS)
	var water: Dictionary = city.pond()
	var center: Vector3 = to_world(water.get("center", rect.get_center()), 0.08)
	var radius := float(water.get("radius", 100)) / PX
	var rim := Outdoors._disc(radius + 0.5, Color("B9A98C"))
	rim.position = center + Vector3(0, 0.02, 0)
	world.add_child(rim)
	var pond := Outdoors._disc(radius, Color("7FA3B8"))
	pond.name = "pond"
	pond.position = center + Vector3(0, 0.04, 0)
	world.add_child(pond)
	var fountain := Props.mesh_cylinder(0.6, 1.6, Color("D9D2C4"))
	fountain.name = "fountain"
	fountain.position = center
	world.add_child(fountain)
	var spray := Outdoors._cone(0.5, 1.2, Color("CFE3EE"))
	spray.position = center + Vector3(0, 1.6, 0)
	world.add_child(spray)
	var park_rng := RandomNumberGenerator.new()
	park_rng.seed = 7
	var names := ["willow", "willow", "willow", "willow"]
	for i in 4:
		var angle := i * PI * 0.5 + 0.6
		var at := center + Vector3(cos(angle), 0, sin(angle)) * (radius + 3.0)
		var tree := Node3D.new()
		tree.name = names[i]
		tree.position = Vector3(at.x, 0.08, at.z)
		world.add_child(tree)
		Outdoors._tree(tree, Vector3.ZERO, park_rng.randf_range(1.6, 2.2))
	for i in 6:
		var at := Vector3(rect.position.x / PX + park_rng.randf_range(1.0, rect.size.x / PX - 1.0), 0.08, rect.position.y / PX + park_rng.randf_range(1.0, rect.size.y / PX - 1.0))
		if at.distance_to(center) < radius + 2.5:
			continue
		Outdoors._tree(world, at, park_rng.randf_range(0.9, 1.4))
	for spot in [Vector3(rect.position.x / PX + 2.5, 0.08, rect.end.y / PX - 2.2), Vector3(rect.end.x / PX - 2.5, 0.08, rect.position.y / PX + 2.8)]:
		Outdoors._bench(world, spot.x, spot.z)
	var sign := _slab(Vector3(1.6, 1.0, 0.1), center + Vector3(0, 0.6, -radius - 1.4), Color("D86F5B"))
	sign.name = "bridge_closed"
	var label := _sign_text("Bridge closed", center + Vector3(0, 1.4, -radius - 1.45), Color("F4E9D8"))
	label.font_size = 60
	var ducklings := Node3D.new()
	ducklings.name = "duckling"
	ducklings.position = center + Vector3(radius * 0.6, 0.1, 1.0)
	world.add_child(ducklings)
	for i in 3:
		var d := _duck(ducklings, Vector3(i * 0.45, 0, (i % 2) * 0.3), 0.55)
		d.name = "duckling_%d" % i


func _build_green(rect: Rect2) -> void:
	# A small park: lawn, gravel paths crossing to a bandstand, benches,
	# flowerbeds, and trees round the edge.
	var green := Node3D.new()
	green.name = "Green"
	world.add_child(green)
	_slab(Vector3(rect.size.x / PX, 0.08, rect.size.y / PX), rect_center(rect, 0.0), GRASS, green)
	var center := rect_center(rect, 0.08)
	var w := rect.size.x / PX
	var d := rect.size.y / PX
	_slab(Vector3(w - 1.0, 0.02, 1.6), center, Color("C9B99A"), green)
	_slab(Vector3(1.6, 0.02, d - 1.0), center, Color("C9B99A"), green)
	# Alternate greens get a playground instead of the bandstand.
	var playground := int(round((rect.position.y - city.road) / (city.block.y + city.road))) % 2 == 1
	if not playground:
		var stand := Node3D.new()
		stand.name = "Bandstand"
		stand.position = center
		green.add_child(stand)
		var base := Props.mesh_cylinder(2.6, 0.4, Color("D9D2C4"))
		stand.add_child(base)
		for i in 6:
			var post := Props.mesh_cylinder(0.08, 2.8, Color("F4ECDD"))
			post.position = Vector3(cos(i * PI / 3.0) * 2.1, 0.4, sin(i * PI / 3.0) * 2.1)
			stand.add_child(post)
		var roof := Outdoors._cone(3.0, 1.4, Color("6B8E7A"))
		roof.position = Vector3(0, 3.2, 0)
		stand.add_child(roof)
		var finial := Props.mesh_cylinder(0.06, 0.6, Color("E6B655"))
		finial.position = Vector3(0, 4.6, 0)
		stand.add_child(finial)
	else:
		# Swings, a slide and a sandpit.
		var play := Node3D.new()
		play.name = "Playground"
		play.position = center
		green.add_child(play)
		var sand := Outdoors._disc(2.4, Color("E3D2A8"))
		sand.position = Vector3(0, 0.02, 0)
		play.add_child(sand)
		for x in [-2.0, 2.0]:
			var post := Props.mesh_cylinder(0.06, 2.4, Color("D9765F"))
			post.position = Vector3(x, 0, -3.0)
			play.add_child(post)
		var bar := Props.mesh_cylinder(0.05, 4.2, Color("D9765F"))
		bar.rotation.z = PI * 0.5
		bar.position = Vector3(0, 2.4, -3.0)
		play.add_child(bar)
		for x in [-0.8, 0.8]:
			for dx in [-0.2, 0.2]:
				var rope := Props.mesh_cylinder(0.015, 1.7, Color("4E4A48"))
				rope.position = Vector3(x + dx, 0.6, -3.0)
				play.add_child(rope)
			var seat := Props.mesh_box(Vector3(0.5, 0.05, 0.2), Color("4E4A48"))
			seat.position = Vector3(x, 0.6, -3.0)
			play.add_child(seat)
		var ladder_side := Props.mesh_box(Vector3(0.6, 2.0, 0.1), Color("7FA3B8"))
		ladder_side.position = Vector3(3.0, 1.0, 1.2)
		play.add_child(ladder_side)
		var slide := Props.mesh_box(Vector3(0.6, 0.08, 3.2), Color("E6B655"))
		slide.position = Vector3(3.0, 1.0, 2.9)
		slide.rotation.x = 0.55
		play.add_child(slide)
	var park_rng := RandomNumberGenerator.new()
	park_rng.seed = 11
	for corner in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		var bed := Outdoors._disc(1.3, Color("7E9B5E"))
		bed.position = center + Vector3(corner.x * (w * 0.5 - 3.2), 0.03, corner.z * (d * 0.5 - 3.2))
		green.add_child(bed)
		for k in 7:
			var flower := Props.mesh_box(Vector3(0.18, 0.18, 0.18), [Color("D9765F"), Color("E6B655"), Color("D4C1D8"), Color("F4ECDD")][k % 4])
			flower.position = bed.position + Vector3(cos(k * 0.9) * 0.8, 0.22, sin(k * 0.9) * 0.8)
			green.add_child(flower)
		Outdoors._bench(green, bed.position.x - corner.x * 2.4, bed.position.z)
	for i in 10:
		var along := float(i) / 10.0 * TAU
		var at := center + Vector3(cos(along) * (w * 0.5 - 1.4), 0.0, sin(along) * (d * 0.5 - 1.4))
		if absf(at.x - center.x) < 1.4 or absf(at.z - center.z) < 1.4:
			continue
		Outdoors._tree(green, at, park_rng.randf_range(0.9, 1.5))
	var post := Props.mesh_cylinder(0.08, 4.0, Color("4E4A48"))
	post.position = center + Vector3(3.6, 0.08, 3.6)
	green.add_child(post)
	var head := Props.mesh_box(Vector3(0.5, 0.25, 0.5), Color("FFE3A8"))
	head.position = post.position + Vector3(0, 4.0, 0)
	green.add_child(head)


var _front_spans: Array = []


func _front_venue(place: Dictionary) -> Dictionary:
	# The blueprint behind a kerb: the job's venue for both ends of the
	# move, the family's house at the far end of a house move.
	var venue_id := str(GameState.job.get("def", {}).get("venue", ""))
	if venue_id == "":
		venue_id = str(place.get("id", "")).trim_suffix("_new")
	var venues: Dictionary = ItemDB.venues()
	if not venues.has(venue_id):
		for key in venues.keys():
			if str(place.get("id", "")).begins_with(str(key)):
				venue_id = str(key)
	return venues.get(venue_id, {})


func _front_footprints() -> Array:
	# The plots the two blueprint fronts take, in drive pixels.
	var out: Array = []
	for place in [pickup, dropoff]:
		if place.is_empty():
			continue
		var venue_def := _front_venue(place)
		if venue_def.is_empty():
			continue
		var w := float(venue_def.get("w", 6)) * PX
		var d := float(venue_def.get("d", 6)) * PX
		var home := Homes.is_home(venue_def) and str(venue_def.get("kind", "house")) != "shop"
		var setback := (3.6 if home else 0.0) * PX
		var door: Vector2 = place.get("door", Vector2.ZERO)
		var rect: Rect2 = place.get("rect", Rect2())
		var side := str(place.get("side", "N"))
		var pad: float = city.sidewalk
		match side:
			"N":
				out.append(Rect2(door.x - w * 0.5 - 20.0, rect.position.y + pad, w + 40.0, setback + d + 20.0))
			"S":
				out.append(Rect2(door.x - w * 0.5 - 20.0, rect.end.y - pad - setback - d - 20.0, w + 40.0, setback + d + 20.0))
			"W":
				out.append(Rect2(rect.position.x + pad, door.y - w * 0.5 - 20.0, setback + d + 20.0, w + 40.0))
			_:
				out.append(Rect2(rect.end.x - pad - setback - d - 20.0, door.y - w * 0.5 - 20.0, setback + d + 20.0, w + 40.0))
	return out


func _build_fronts() -> void:
	var i := 0
	for place in [pickup, dropoff]:
		if not place.is_empty():
			_build_front(place, _front_venue(place), i)
		i += 1


func _build_front(place: Dictionary, venue_def: Dictionary, which: int) -> void:
	# The building at the kerb, raised from the same rooms the unpack scene
	# uses: its width and depth, the door where the blueprint puts it, a
	# window for each front room, a storey per floor, and a garden or a
	# shopfront by what it is. The truck pulls up at this door.
	if venue_def.is_empty():
		return
	var home := Homes.is_home(venue_def) and str(venue_def.get("kind", "house")) != "shop"
	var w := float(venue_def.get("w", 6))
	var d := float(venue_def.get("d", 6))
	var floors: Array = Homes.floors(venue_def)
	var storeys := maxi(1, floors.size())
	var storey_h := 3.0
	var h := storeys * storey_h
	var setback := 3.6 if home else 0.0
	var side := str(place.get("side", "N"))
	var inward := _inward3(side)
	var door_w: Vector3 = to_world(place.get("door", Vector2.ZERO), 0.12)
	var root := Node3D.new()
	root.name = "Front_" + str(place.get("id", ""))
	root.position = door_w + inward * (city.sidewalk / PX + setback + d * 0.5)
	root.rotation.y = atan2(inward.x, inward.z)
	world.add_child(root)
	var style := str(venue_def.get("style", ""))
	var wall_color: Color = place.get("color", Color("D8B4A0")) if place.get("color") is Color else Color(str(place.get("color", "D8B4A0")))
	if home:
		wall_color = {"brick": Color("B8694F"), "render": Color("EDE3CF"), "timber": Color("C9A66B"), "stone": Color("B9B2A4")}.get(style, Color("D8B4A0"))
		if which == 0:
			wall_color = wall_color.darkened(0.08)
	var trim := wall_color.lightened(0.35)
	var body := Props.mesh_box(Vector3(w, h, d), wall_color)
	body.name = "FrontBody"
	body.position = Vector3(0, h * 0.5, 0)
	root.add_child(body)
	var plinth := Props.mesh_box(Vector3(w + 0.1, 0.4, d + 0.1), wall_color.darkened(0.3))
	plinth.position = Vector3(0, 0.2, 0)
	root.add_child(plinth)
	# The front face is local -Z. Door first, where the blueprint has it.
	var door_dx := 0.0
	if not home and float(venue_def.get("open_w", 2)) >= 2.9 and w >= 6.0:
		door_dx = 3.5 - w * 0.5
	var front_z := -d * 0.5
	var door_color := wall_color.darkened(0.45) if home else Color("3E3A4F")
	var door := Props.mesh_box(Vector3(1.0, 2.1, 0.1), door_color)
	door.position = Vector3(door_dx, 1.05, front_z - 0.04)
	root.add_child(door)
	var step := Props.mesh_box(Vector3(1.4, 0.12, 0.6), Color("C9C2B5"))
	step.position = Vector3(door_dx, 0.06, front_z - 0.3)
	root.add_child(step)
	# Windows: one per front room on each floor; shops get glazing instead.
	var glass := Color("9FC4D6")
	if home:
		for index in storeys:
			var rooms: Array = Homes.rooms(venue_def, index)
			for room in rooms:
				if float(room.get("z", 0)) > 0.05:
					continue
				var cx := float(room.get("x", 0)) + float(room.get("w", 2)) * 0.5 - w * 0.5
				if index == 0 and absf(cx - door_dx) < 1.0:
					cx += 1.2 if cx >= door_dx else -1.2
				var win := Props.mesh_box(Vector3(1.1, 1.2, 0.08), glass)
				win.position = Vector3(cx, index * storey_h + 1.6, front_z - 0.03)
				root.add_child(win)
				var sill := Props.mesh_box(Vector3(1.3, 0.1, 0.2), trim)
				sill.position = Vector3(cx, index * storey_h + 0.95, front_z - 0.1)
				root.add_child(sill)
		# A pitched roof and a chimney.
		var roof := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(w + 0.6, 1.8, d + 0.6)
		prism.left_to_right = 0.5
		roof.mesh = prism
		roof.material_override = Props.mat({"brick": Color("6E4A3A"), "render": Color("6E6A66"), "timber": Color("5A3B2A")}.get(style, Color("7A6A5A")))
		roof.position = Vector3(0, h + 0.9, 0)
		root.add_child(roof)
		var stack := Props.mesh_box(Vector3(0.5, 1.1, 0.5), wall_color.darkened(0.3))
		stack.position = Vector3(w * 0.3, h + 1.2, 0)
		root.add_child(stack)
		# Front garden: lawn, a path to the door, hedges at the kerb with a gate.
		var lawn := Props.mesh_box(Vector3(w + 1.0, 0.06, setback), Color("9CC07E"))
		lawn.position = Vector3(0, 0.03, front_z - setback * 0.5)
		root.add_child(lawn)
		var path := Props.mesh_box(Vector3(0.9, 0.08, setback), Color("C9B99A"))
		path.position = Vector3(door_dx, 0.05, front_z - setback * 0.5)
		root.add_child(path)
		for sgn in [-1.0, 1.0]:
			var hedge_w := (w + 1.0) * 0.5 - 0.7
			var hedge := Props.mesh_box(Vector3(hedge_w, 0.8, 0.5), Color("5F8F55"))
			hedge.position = Vector3(door_dx + sgn * (0.7 + hedge_w * 0.5), 0.4, front_z - setback + 0.25)
			root.add_child(hedge)
		Outdoors._tree(root, Vector3(-w * 0.5 + 0.6, 0.0, front_z - setback + 1.0), 0.8)
	else:
		for sgn in [-1.0, 1.0]:
			var pane_w := w * 0.5 - 1.2
			var pane := Props.mesh_box(Vector3(pane_w, 2.0, 0.08), glass)
			pane.position = Vector3(door_dx + sgn * (0.9 + pane_w * 0.5), 1.35, front_z - 0.03)
			root.add_child(pane)
		if storeys > 1 or d >= 7.0:
			for k in 3:
				var cx := -w * 0.5 + w * (0.5 + k) / 3.0
				var win := Props.mesh_box(Vector3(1.0, 1.1, 0.08), glass)
				win.position = Vector3(cx, storey_h + 1.5, front_z - 0.03)
				root.add_child(win)
			if storeys == 1:
				h = storey_h * 2.0
				body.mesh = BoxMesh.new()
				(body.mesh as BoxMesh).size = Vector3(w, h, d)
				body.position.y = h * 0.5
		var awning := Props.mesh_box(Vector3(w * 0.8, 0.14, 1.0), wall_color.darkened(0.1))
		awning.position = Vector3(0, 2.75, front_z - 0.5)
		root.add_child(awning)
		var parapet := Props.mesh_box(Vector3(w + 0.3, 0.5, d + 0.3), trim)
		parapet.position = Vector3(0, h + 0.1, 0)
		root.add_child(parapet)
		var board := Props.mesh_box(Vector3(w * 0.7, 0.8, 0.12), Color("3E3A4F"))
		board.position = Vector3(0, 3.5, front_z - 0.1)
		root.add_child(board)
		var label := _sign_text(str(place.get("name", "")), Vector3.ZERO, Color("F4E9D8"))
		label.reparent(root)
		label.position = Vector3(0, 3.5, front_z - 0.2)
		label.rotation = Vector3.ZERO
		label.rotation.y = PI
		label.font_size = 64
	# Side windows so the shell reads from the chase camera too.
	for sgn in [-1.0, 1.0]:
		for index in storeys:
			var win := Props.mesh_box(Vector3(0.08, 1.1, 1.0), glass)
			win.position = Vector3(sgn * (w * 0.5 + 0.03), index * storey_h + 1.6, 0.0)
			root.add_child(win)


func _build_crossings() -> void:
	# Zebra stripes across each road where it meets a junction, on all
	# four arms, in one multimesh for the whole town.
	var stripes: Array = []
	var road_w: float = float(city.road) / PX
	var stripe := Vector3(0.5, 0.012, 0.0)
	for i in city.cols + 1:
		for j in city.rows + 1:
			var node: Vector2 = city.node_at(i, j)
			var center := to_world(node, 0.0)
			# Arms along x (the crossing runs across the vertical road) and along z.
			for sgn: float in [-1.0, 1.0]:
				var arm_x := center + Vector3(sgn * (road_w * 0.5 + 1.3), 0.0, 0.0)
				if i + int(sgn) < 0 or i + int(sgn) > city.cols:
					continue
				var k: float = -road_w * 0.5 + 0.9
				while k < road_w * 0.5 - 0.6:
					stripes.append(Transform3D(Basis(Vector3.UP, PI * 0.5), arm_x + Vector3(0.0, 0.006, k)))
					k += 1.2
			for sgn: float in [-1.0, 1.0]:
				var arm_z := center + Vector3(0.0, 0.0, sgn * (road_w * 0.5 + 1.3))
				if j + int(sgn) < 0 or j + int(sgn) > city.rows:
					continue
				var k: float = -road_w * 0.5 + 0.9
				while k < road_w * 0.5 - 0.6:
					stripes.append(Transform3D(Basis.IDENTITY, arm_z + Vector3(k, 0.006, 0.0)))
					k += 1.2
	_multimesh(Vector3(0.55, 0.012, 1.6), Color(LANE_LINE, 0.95), stripes)


func _build_hills(size: Vector3) -> void:
	# A ring of hills past the last street, so the road has a horizon.
	var hills := Node3D.new()
	hills.name = "Hills"
	world.add_child(hills)
	var cx := size.x * 0.5
	var cz := size.z * 0.5
	var ring := maxf(size.x, size.z) * 0.95
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 18:
		var angle := TAU * float(i) / 18.0 + rng.randf_range(-0.08, 0.08)
		var dist := ring + rng.randf_range(10.0, 40.0)
		var hill := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		var radius := rng.randf_range(34.0, 60.0)
		mesh.radius = radius
		mesh.height = radius * rng.randf_range(0.5, 0.8)
		hill.mesh = mesh
		var night := str(course.get("weather", "clear")) == "night"
		hill.material_override = Props.mat(Color("8FB573").darkened(0.1 + 0.25 * rng.randf()) if not night else Color("1E2A30"))
		hill.position = Vector3(cx + cos(angle) * dist, -mesh.height * 0.35, cz + sin(angle) * dist)
		hills.add_child(hill)


func _complete_highway() -> void:
	# The interstate is done: the boxes' condition and the honks carry to
	# the second leg, which the app starts as a fresh course in the town.
	if not running:
		return
	running = false
	state = "done"
	GameState.job["highway_done"] = true
	GameState.job["highway_condition"] = condition
	GameState.job["highway_honks"] = honks
	AudioDirector.play_sfx("sfx_success_chime")
	emit_signal("finished", {"highway": true, "condition": condition, "alley": false, "honks": honks, "backed_in": false, "spotted": spotted, "busted": false, "duck_friend": false, "near_miss": near_miss, "time": time_alive})


func _hw_center_z() -> float:
	return HW_ROAD_PX / PX * 0.5


func _hw_lane_z(lane: int, side: float) -> float:
	# The centre of lane `lane` (0 nearest the median) on the side given:
	# +1 is the eastbound carriageway (the truck's), -1 westbound.
	return _hw_center_z() + side * (HW_MEDIAN * 0.5 + HW_LANE * (float(lane) + 0.5))


func _build_highway() -> void:
	# A real interstate: two carriageways of three lanes with a shoulder
	# each, a grass median with a barrier down it, lane dashes, yellow
	# edge lines on the median side and white on the outside, overhead
	# gantries, a tree line by region, fields and water beyond, billboards
	# and mile markers, an overpass halfway, the city's water tower and a
	# welcome sign at the far end.
	var region: Dictionary = Regions.region(str(haul.get("region", "midlands")))
	var night := str(course.get("weather", "clear")) == "night"
	var snow := str(course.get("weather", "clear")) == "snow"
	# The sun behind the truck, so the signs ahead are lit faces, not shadow.
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.look_at_from_position(Vector3(-30, 40, 14), Vector3.ZERO, Vector3.UP)
	var length := highway_px / PX + 60.0
	var ground := Color(str(region.get("ground", "7FA85C")))
	if snow:
		ground = Color("EEF1F3")
	elif night:
		ground = ground.darkened(0.55)
	var field := Color(str(region.get("field", "B9B66A")))
	if night:
		field = field.darkened(0.55)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "")) + "highway")
	var cz := _hw_center_z()
	var carriage := HW_LANE * float(HW_LANES)
	var half := HW_MEDIAN * 0.5 + carriage + HW_SHOULDER
	var yellow := Color("E6C14E") if not night else Color("8E7A3A")
	var white := LANE_LINE if not night else LANE_LINE.darkened(0.35)
	_slab(Vector3(length + 400.0, 0.1, 520.0), Vector3(length * 0.5, -0.1, cz), ground)
	# Each carriageway with its shoulder.
	for side: float in [-1.0, 1.0]:
		var inner := cz + side * HW_MEDIAN * 0.5
		var mid := inner + side * (carriage + HW_SHOULDER) * 0.5
		_slab(Vector3(length + 40.0, 0.02, carriage + HW_SHOULDER), Vector3(length * 0.5, -0.02, mid), ASPHALT)
		# The shoulder a shade lighter, with a rumble strip at the lane edge.
		var shoulder_mid := inner + side * (carriage + HW_SHOULDER * 0.5)
		_slab(Vector3(length + 40.0, 0.021, HW_SHOULDER), Vector3(length * 0.5, -0.02, shoulder_mid), ASPHALT.lightened(0.1))
		# Edge lines: yellow by the median, white by the shoulder.
		_slab(Vector3(length + 40.0, 0.01, 0.15), Vector3(length * 0.5, 0.0, inner + side * 0.25), yellow)
		_slab(Vector3(length + 40.0, 0.01, 0.15), Vector3(length * 0.5, 0.0, inner + side * (carriage - 0.1)), white)
		# Lane dashes between the lanes.
		var dashes: Array = []
		for lane in range(1, HW_LANES):
			var z := inner + side * HW_LANE * float(lane)
			var x := 0.0
			while x < length:
				dashes.append(Transform3D(Basis.IDENTITY, Vector3(x + 1.5, 0.0, z)))
				x += 9.0
		_multimesh(Vector3(3.0, 0.01, 0.15), white, dashes)
	# The median: grass, and a concrete barrier down the middle.
	_slab(Vector3(length + 40.0, 0.03, HW_MEDIAN - 0.4), Vector3(length * 0.5, -0.03, cz), ground.darkened(0.06))
	_slab(Vector3(length + 40.0, 0.8, 0.5), Vector3(length * 0.5, 0.0, cz), Color("B5B2AA") if not night else Color("4A4846"))
	_slab(Vector3(length + 40.0, 0.12, 0.62), Vector3(length * 0.5, 0.78, cz), Color("C6C3BB") if not night else Color("55534F"))
	# Reflector posts along the barrier.
	var reflectors: Array = []
	var rx := 0.0
	while rx < length:
		reflectors.append(Transform3D(Basis.IDENTITY, Vector3(rx, 1.05, cz)))
		rx += 12.0
	_multimesh(Vector3(0.08, 0.3, 0.08), Color("FFE7B0"), reflectors, 1.4 if night else 0.0)
	# Guardrails on both outer verges.
	var posts: Array = []
	for side: float in [-1.0, 1.0]:
		var z: float = cz + side * (half + 1.0)
		var x := 0.0
		while x < length:
			posts.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.35, z)))
			x += 4.0
		_slab(Vector3(length + 40.0, 0.3, 0.08), Vector3(length * 0.5, 0.5, z), Color("B5BBC0"))
	_multimesh(Vector3(0.12, 0.7, 0.12), Color("8A8F94"), posts)
	# Fields and water beyond the verge, in strips so the land changes as it goes by.
	var x := -60.0
	while x < length + 60.0:
		var w := rng.randf_range(40.0, 110.0)
		for side: float in [-1.0, 1.0]:
			var roll := rng.randf()
			var z0: float = cz + side * (half + rng.randf_range(16.0, 32.0))
			var depth := rng.randf_range(30.0, 90.0)
			if bool(region.get("water", false)) and roll < 0.22:
				_slab(Vector3(w, 0.03, depth), Vector3(x + w * 0.5, -0.05, z0 + side * depth * 0.5), Color("7FA3B8") if not night else Color("27384A"))
			elif roll < 0.6:
				_slab(Vector3(w, 0.03, depth), Vector3(x + w * 0.5, -0.04, z0 + side * depth * 0.5), field.lightened(rng.randf_range(-0.08, 0.1)))
		x += w
	# The tree line: pines (a trunk and two stacked cones) or palmettos (a
	# trunk and a fan of leaves), in multimeshes so a mile of them is cheap.
	var trunks: Array = []
	var canopies: Array = []
	var crowns: Array = []
	var fans: Array = []
	var kind := str(region.get("trees", "pine"))
	x = 0.0
	while x < length:
		for side: float in [-1.0, 1.0]:
			if rng.randf() < 0.75:
				var z: float = cz + side * (half + rng.randf_range(7.0, 28.0))
				var at := Vector3(x + rng.randf_range(-3.0, 3.0), 0.0, z)
				var sc := rng.randf_range(0.8, 1.4)
				if kind == "palmetto":
					trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1, sc, 1)), at + Vector3(0, 2.6 * sc, 0)))
					for leaf in 6:
						var yaw := TAU * float(leaf) / 6.0 + rng.randf_range(-0.2, 0.2)
						var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -0.5)
						fans.append(Transform3D(basis, at + Vector3(0, 5.2 * sc, 0) + Vector3(cos(yaw), 0, sin(yaw)) * 0.9))
				else:
					trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1, sc, 1)), at + Vector3(0, 2.0 * sc, 0)))
					canopies.append(Transform3D(Basis.IDENTITY.scaled(Vector3(sc, sc, sc)), at + Vector3(0, 5.0 * sc, 0)))
					crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(sc * 0.7, sc, sc * 0.7)), at + Vector3(0, 7.6 * sc, 0)))
		x += 9.0
	var leaf_color := Color("3F6B3A") if not night else Color("1A2E20")
	if snow:
		leaf_color = Color("5E7F62")
	_multimesh_mesh(_cyl_mesh(0.22, 4.0 if kind != "palmetto" else 5.2), Color("5A4330"), trunks)
	if kind == "palmetto":
		_multimesh_mesh(_box_mesh(Vector3(0.5, 0.08, 2.6)), Color("4F8A4A") if not night else Color("1F3A24"), fans)
	else:
		_multimesh_mesh(_cone_mesh(2.3, 4.0), leaf_color, canopies)
		_multimesh_mesh(_cone_mesh(1.7, 3.2), leaf_color.lightened(0.08), crowns)
	# Hills behind the trees in the upstate and out of state.
	if bool(region.get("hills", false)):
		var hills := Node3D.new()
		hills.name = "Hills"
		world.add_child(hills)
		x = -40.0
		while x < length + 40.0:
			for side: float in [-1.0, 1.0]:
				var hill := MeshInstance3D.new()
				var mesh := SphereMesh.new()
				var radius := rng.randf_range(40.0, 70.0)
				mesh.radius = radius
				mesh.height = radius * rng.randf_range(0.5, 0.8)
				hill.mesh = mesh
				hill.material_override = Props.mat(Color("8FB573").darkened(0.15 + 0.25 * rng.randf()) if not night else Color("1E2A30"))
				hill.position = Vector3(x + rng.randf_range(-20.0, 20.0), -mesh.height * 0.35, cz + side * (half + 110.0 + rng.randf_range(0.0, 60.0)))
				hills.add_child(hill)
			x += 90.0
	# Overhead gantries every so often: the city and its miles, an exit, a lane sign.
	var city_name := str(haul.get("city", ""))
	var miles := int(haul.get("miles", 0))
	x = 120.0
	var g := 0
	while x < length - 120.0:
		var text := "%s  %d" % [city_name, int(ceil(float(miles) * (1.0 - x / length)))]
		if g % 3 == 1:
			text = "EXIT %d  ·  %s" % [rng.randi_range(20, 180), ["Gas · Food", "Rest Area", "Weigh Station", "Scenic Overlook"][rng.randi_range(0, 3)]]
		elif g % 3 == 2:
			text = "%s  %d  ·  Keep Right" % [city_name, int(ceil(float(miles) * (1.0 - x / length)))]
		_build_gantry(x, cz, half, text, night)
		x += rng.randf_range(220.0, 300.0)
		g += 1
	# Billboards on the verges, alternating sides.
	var copy: Array = Regions.billboards()
	x = 60.0
	var n := 0
	while x < length - 90.0:
		var side := -1.0 if n % 2 == 0 else 1.0
		_build_billboard(Vector3(x, 0, cz + side * (half + 10.0)), side, str(copy[rng.randi_range(0, copy.size() - 1)]), night)
		x += rng.randf_range(130.0, 190.0)
		n += 1
	# Mile markers: a small green post every so often, counting down.
	var markers: Array = []
	x = 30.0
	while x < length - 30.0:
		markers.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.7, cz + half + 2.6)))
		x += 48.0
	_multimesh(Vector3(0.25, 1.4, 0.06), Color("2E7D4F"), markers)
	# An overpass halfway: piers on the verges and the median, a deck across all of it.
	var mid := length * 0.5
	for pz in [cz - half - 2.4, cz, cz + half + 2.4]:
		_slab(Vector3(2.2, 6.0, 1.6), Vector3(mid, 0.0, pz), Color("9C9A94"))
	_slab(Vector3(2.8, 1.1, half * 2.0 + 10.0), Vector3(mid, 6.0, cz), Color("8E8C86"))
	_slab(Vector3(2.9, 0.9, 0.2), Vector3(mid, 7.1, cz - half - 4.9), Color("B5BBC0"))
	_slab(Vector3(2.9, 0.9, 0.2), Vector3(mid, 7.1, cz + half + 4.9), Color("B5BBC0"))
	# The water tower with the city's name, and the welcome sign at the end.
	var tower_at := Vector3(length - 40.0, 0.0, cz - half - 24.0)
	var tank := Props.mesh_cylinder(4.0, 5.0, Color("D8D2C4") if not night else Color("5A5852"))
	tank.position = tower_at + Vector3(0, 16.0, 0)
	world.add_child(tank)
	var cap := Outdoors._cone(4.2, 2.4, Color("C2634F"))
	cap.position = tower_at + Vector3(0, 18.5, 0)
	world.add_child(cap)
	for leg in [Vector3(2.6, 0, 2.6), Vector3(-2.6, 0, -2.6), Vector3(2.6, 0, -2.6), Vector3(-2.6, 0, 2.6)]:
		var post := Props.mesh_cylinder(0.18, 14.0, Color("8A8F94"))
		post.position = tower_at + leg + Vector3(0, 7.0, 0)
		world.add_child(post)
	var tower_label := _sign_text(city_name.to_upper(), tower_at + Vector3(0, 16.0, 4.1), Color("3E3A4F"))
	tower_label.font_size = 72
	tower_label.visibility_range_end = 140.0
	tower_label.visibility_range_end_margin = 20.0
	var welcome := "Welcome to %s" % city_name
	if str(haul.get("state", "SC")) != "SC":
		welcome = "Welcome to %s" % _state_name(str(haul.get("state", "")))
		# The state line comes before the city: a second sign at two thirds.
		_build_billboard(Vector3(length * 0.66, 0, cz + half + 10.0), 1.0, "Leaving South Carolina · Y'all come back", night)
	var board := Props.mesh_box(Vector3(0.16, 1.6, 7.0), Color("2E5E3E"))
	board.position = Vector3(length - 14.0, 2.6, cz + half + 4.0)
	world.add_child(board)
	for dz in [-2.8, 2.8]:
		var post := Props.mesh_cylinder(0.1, 2.0, Color("8A8F94"))
		post.position = board.position + Vector3(0, -1.8, dz)
		world.add_child(post)
	var welcome_label := _sign_text(welcome, board.position + Vector3(-0.2, 0, 0), Color("F4E9D8"))
	welcome_label.font_size = 56
	welcome_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	welcome_label.rotation.y = -PI * 0.5
	welcome_label.visibility_range_begin = 0.0
	welcome_label.visibility_range_end = 90.0


func _build_gantry(x: float, cz: float, half: float, text: String, night: bool) -> void:
	# An overhead sign across the eastbound carriageway: two posts on
	# the verge and the median, a truss, a green board with the words.
	var inner := cz + HW_MEDIAN * 0.5
	var outer := cz + half + 1.6
	for pz in [inner - 0.6, outer]:
		var post := Props.mesh_box(Vector3(0.4, 7.2, 0.4), Color("8A8F94"))
		post.position = Vector3(x, 3.6, pz)
		world.add_child(post)
	var span := outer - (inner - 0.6)
	var truss := Props.mesh_box(Vector3(0.5, 0.5, span + 0.4), Color("8A8F94"))
	truss.position = Vector3(x, 7.0, (inner - 0.6 + outer) * 0.5)
	world.add_child(truss)
	var board := Props.mesh_box(Vector3(0.16, 2.6, 10.0), Color("2E6B45") if not night else Color("1E3A2A"))
	board.position = Vector3(x, 6.0, inner + HW_LANE * 1.5)
	world.add_child(board)
	var rim := Props.mesh_box(Vector3(0.1, 2.9, 10.3), Color("F4E9D8") if not night else Color("8A9A8E"))
	rim.position = board.position + Vector3(0.06, 0.0, 0.0)
	world.add_child(rim)
	var label := _sign_text(text, board.position + Vector3(-0.14, 0.0, 0.0), Color("F4E9D8"))
	label.font_size = 190
	label.outline_size = 0
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.rotation.y = -PI * 0.5
	label.visibility_range_begin = 0.0
	label.visibility_range_end = 120.0
	label.visibility_range_end_margin = 16.0


func _make_rig(color: Color) -> Node3D:
	# A tractor and a box trailer, the big thing in the slow lane.
	var rig := Node3D.new()
	var cab := Props.mesh_box(Vector3(2.4, 2.4, 2.4), color)
	cab.position = Vector3(4.6, 1.5, 0)
	rig.add_child(cab)
	var glass := Props.mesh_box(Vector3(0.1, 0.9, 2.0), Color("9FC4D6"))
	glass.position = Vector3(5.85, 2.1, 0)
	rig.add_child(glass)
	var trailer := Props.mesh_box(Vector3(9.0, 2.8, 2.5), Color("F4E9D8"))
	trailer.position = Vector3(-1.2, 2.1, 0)
	rig.add_child(trailer)
	var chassis := Props.mesh_box(Vector3(10.0, 0.4, 1.6), Color("2E2A2C"))
	chassis.position = Vector3(0.0, 0.55, 0)
	rig.add_child(chassis)
	for dx in [4.6, -3.6, -5.0, 1.0]:
		for dz in [-1.05, 1.05]:
			var wheel := Props.mesh_cylinder(0.5, 0.4, Color("2E2A2C"))
			wheel.rotation.x = PI * 0.5
			wheel.position = Vector3(dx, 0.5, dz)
			rig.add_child(wheel)
	return rig


func _car_lights(node: Node3D, rig: bool) -> void:
	# Headlights and tail lights after dark: small lit boxes, no light nodes.
	var front_x := 5.9 if rig else 2.05
	var back_x := -5.7 if rig else -2.05
	var y := 1.1 if rig else 0.65
	var head := Props.mat(Color("FFF2C8"))
	head.emission_enabled = true
	head.emission = Color("FFF2C8")
	head.emission_energy_multiplier = 3.0
	var tail := Props.mat(Color("FF3B2F"))
	tail.emission_enabled = true
	tail.emission = Color("FF3B2F")
	tail.emission_energy_multiplier = 2.2
	for dz in [-0.7, 0.7]:
		var lamp := Props.mesh_box(Vector3(0.1, 0.22, 0.34), Color("FFF2C8"))
		lamp.material_override = head
		lamp.position = Vector3(front_x, y, dz)
		node.add_child(lamp)
		var rear := Props.mesh_box(Vector3(0.1, 0.18, 0.34), Color("FF3B2F"))
		rear.material_override = tail
		rear.position = Vector3(back_x, y, dz)
		node.add_child(rear)


func _spawn_highway_traffic() -> void:
	# Six lanes of traffic: a loop per lane pair runs east in one
	# carriageway and comes back west in the other, turning round past the
	# ends out of sight. The inner lanes run faster; the outer lane
	# carries the rigs. Cars in the truck's lane are a touch quicker than
	# the truck, so the ride is never parked behind one for long.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "highway")))
	var length_px := highway_px + 60.0 * PX
	var truck_max := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var palette := [Color("F2E5B8"), Color("9FC4D6"), Color("D9765F"), Color("C9D2C0"), Color("E6B655"), Color("7A5C40"), Color("3E3A4F"), Color("B9CBD6")]
	var per_lane := clampi(int(length_px / PX / 90.0), 3, 9)
	var n := 0
	for lane in HW_LANES:
		var ze := _hw_lane_z(lane, 1.0) * PX
		var zw := _hw_lane_z(lane, -1.0) * PX
		var loop := PackedVector2Array([Vector2(-80.0 * PX, ze), Vector2(length_px + 80.0 * PX, ze), Vector2(length_px + 80.0 * PX, zw), Vector2(-80.0 * PX, zw)])
		var factor: float = [1.25, 1.1, 1.02][lane]
		for i in per_lane * 2:
			var east := i < per_lane
			var seg := 0 if east else 2
			var start: Vector2 = loop[seg].lerp(loop[seg + 1], rng.randf())
			if east and absf(start.x - pos.x) < 260.0:
				start.x += 320.0
			var rig := lane == HW_LANES - 1 and rng.randf() < 0.4
			var node := _make_rig(palette[rng.randi_range(0, palette.size() - 1)]) if rig else _make_car(palette[n % palette.size()])
			node.name = "Rig" if rig else "Car"
			node.position = to_world(start)
			world.add_child(node)
			if str(course.get("weather", "clear")) == "night":
				_car_lights(node, rig)
			var cruise: float = truck_max * factor * rng.randf_range(0.92, 1.06)
			if rig:
				cruise = truck_max * 0.9 * rng.randf_range(0.95, 1.05)
			cars.append({"loop": loop, "seg": seg, "pos": start, "speed": cruise, "cruise": cruise, "node": node, "heading": 0.0 if east else PI, "horn": 0.0, "vel": Vector2.ZERO, "mode": "drive", "knock_t": 0.0, "spin": 0.0, "mass": (CAR_MASS * 6.0) if rig else CAR_MASS})
			n += 1


func _build_billboard(at: Vector3, side: float, text: String, night: bool) -> void:
	var face_color := Color("F4E9D8") if not night else Color("3A3A48")
	var panel := Props.mesh_box(Vector3(0.2, 3.2, 9.0), face_color)
	panel.position = at + Vector3(0, 7.2, 0)
	world.add_child(panel)
	# The frame sits behind the face, so the face and its text meet the truck.
	var frame := Props.mesh_box(Vector3(0.1, 3.5, 9.3), Color("4E4A48"))
	frame.position = at + Vector3(0.12, 7.2, 0)
	world.add_child(frame)
	var post := Props.mesh_cylinder(0.3, 5.6, Color("4E4A48"))
	post.position = at + Vector3(0, 2.8, 0)
	world.add_child(post)
	# The text on the side the truck comes from, whichever verge the board stands on.
	var label := _sign_text(text, at + Vector3(-0.16, 6.9, 0), Color("3E3A4F") if not night else Color("FFE7B0"))
	label.font_size = 112
	label.outline_size = 0
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.rotation.y = -PI * 0.5
	label.visibility_range_begin = 0.0
	label.visibility_range_end = 110.0
	label.visibility_range_end_margin = 16.0
	if night:
		# Lit from below after dark.
		var lamp := Props.mesh_box(Vector3(0.3, 0.2, 2.0), Color("FFE7B0"))
		lamp.position = at + Vector3(-side * 0.6, 5.3, 0)
		var glow := Props.mat(Color("FFE7B0"))
		glow.emission_enabled = true
		glow.emission = Color("FFE7B0")
		glow.emission_energy_multiplier = 1.6
		lamp.material_override = glow
		world.add_child(lamp)


func _state_name(code: String) -> String:
	match code:
		"GA":
			return "Georgia"
		"NC":
			return "North Carolina"
		"TN":
			return "Tennessee"
		"FL":
			return "Florida"
	return "South Carolina"


func _box_mesh(size: Vector3) -> Mesh:
	var box := BoxMesh.new()
	box.size = size
	return box


func _cyl_mesh(radius: float, height: float) -> Mesh:
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.8
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 8
	return cyl


func _cone_mesh(radius: float, height: float) -> Mesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 8
	return cone


func _multimesh_mesh(mesh: Mesh, color: Color, transforms: Array) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = Props.mat(color)
	world.add_child(node)


func _build_house_row(entry: Dictionary, rng: RandomNumberGenerator) -> void:
	# A street of houses: pitched roofs, chimneys, a front garden with a
	# hedge and a path on each street side, back gardens with a shed between.
	var rect: Rect2 = entry.get("rect", Rect2())
	var along_x := rect.size.x >= rect.size.y
	var origin := Vector3(rect.position.x / PX, 0.12, rect.position.y / PX)
	var length := (rect.size.x if along_x else rect.size.y) / PX
	var depth := (rect.size.y if along_x else rect.size.x) / PX
	var row := Node3D.new()
	row.name = "Houses"
	world.add_child(row)
	# The block's own lawn, so the gardens read green from the kerb.
	_slab(Vector3(rect.size.x / PX, 0.1, rect.size.y / PX), rect_center(rect, 0.02), Color("9CC07E"), row)
	var plot := 8.0
	var garden := 4.0
	var house_d := 6.0
	var cursor := 0.6
	var i := 0
	while length - cursor >= plot * 0.8:
		var w := minf(plot - 1.4, length - cursor - 0.6)
		for side in [-1.0, 1.0]:
			# Two rows of houses, each facing its own street across a front garden.
			var h := 5.4 + rng.randf_range(-0.4, 0.8)
			var color: Color = Outdoors.HOUSES[(i + (1 if side > 0.0 else 0)) % Outdoors.HOUSES.size()]
			var roof_color: Color = [Color("8A5A44"), Color("6E6A66"), Color("5A3B2A"), Color("7A6A5A")][rng.randi_range(0, 3)]
			var across := depth - garden - house_d * 0.5
			if side < 0.0:
				across = garden + house_d * 0.5
			var house := Node3D.new()
			house.name = "House_%d" % row.get_child_count()
			var local := Vector3(across, 0, cursor + w * 0.5)
			if along_x:
				local = Vector3(cursor + w * 0.5, 0, across)
			house.position = origin + local
			row.add_child(house)
			if not along_x:
				house.rotation.y = PI * 0.5
			var body := Props.mesh_box(Vector3(w, h, house_d), color)
			body.position = Vector3(0, h * 0.5, 0)
			house.add_child(body)
			var roof := MeshInstance3D.new()
			var prism := PrismMesh.new()
			prism.size = Vector3(w + 0.5, 2.2, house_d + 0.6)
			prism.left_to_right = 0.5
			roof.mesh = prism
			roof.material_override = Props.mat(roof_color)
			roof.position = Vector3(0, h + 1.1, 0)
			house.add_child(roof)
			var stack := Props.mesh_box(Vector3(0.5, 1.2, 0.5), color.darkened(0.3))
			stack.position = Vector3(w * 0.3, h + 1.4, 0.0)
			house.add_child(stack)
			# Door and windows on the garden side.
			var out := 1.0
			if side < 0.0:
				out = -1.0
			var front_z := out * house_d * 0.5
			var door := Props.mesh_box(Vector3(0.9, 2.0, 0.08), roof_color.darkened(0.2))
			door.position = Vector3(-w * 0.25, 1.0, front_z + out * 0.05)
			house.add_child(door)
			var step := Props.mesh_box(Vector3(1.2, 0.14, 0.5), Color("C9C2B5"))
			step.position = Vector3(-w * 0.25, 0.07, front_z + out * 0.3)
			house.add_child(step)
			var window_spots: Array = [Vector2(w * 0.22, 1.4), Vector2(w * 0.22, 4.0), Vector2(-w * 0.25, 4.0)]
			for spot in window_spots:
				var frame := Props.mesh_box(Vector3(1.1, 1.2, 0.08), Color("F4ECDD"))
				frame.position = Vector3(spot.x, spot.y, front_z + out * 0.04)
				house.add_child(frame)
				var pane := Props.mesh_box(Vector3(0.9, 1.0, 0.06), Color("5C7F8E"))
				pane.position = frame.position + Vector3(0, 0, out * 0.03)
				house.add_child(pane)
			# The front garden: hedge along the pavement, a path to the door, a tree.
			var hedge := Props.mesh_box(Vector3(w + 0.8, 0.8, 0.5), Color("5E8A4A"))
			hedge.position = Vector3(0, 0.4, front_z + out * (garden - 0.4))
			house.add_child(hedge)
			var path := Props.mesh_box(Vector3(1.0, 0.03, garden - 0.6), Color("C9B99A"))
			path.position = Vector3(-w * 0.25, 0.03, front_z + out * (garden * 0.5 - 0.2))
			house.add_child(path)
			var tree_local := Vector3(w * 0.3, 0, out * (house_d * 0.5 + garden * 0.55))
			var tree_at := house.position + (tree_local if along_x else Vector3(tree_local.z, 0, tree_local.x))
			if rng.randf() < 0.6:
				Outdoors._tree(row, tree_at, rng.randf_range(0.6, 0.9))
			else:
				Outdoors._bush(row, tree_at, 0.5)
			# A fence between plots.
			var fence := Props.mesh_box(Vector3(0.06, 0.9, house_d + garden), Color("A9774C"))
			fence.position = Vector3(w * 0.5 + 0.6, 0.45, out * garden * 0.5)
			house.add_child(fence)
		# Between the back gardens: a shed or a tree.
		var mid_local := Vector3(depth * 0.5, 0, cursor + w * 0.5)
		if along_x:
			mid_local = Vector3(cursor + w * 0.5, 0, depth * 0.5)
		var mid := origin + mid_local
		if rng.randf() < 0.5:
			var shed := Props.mesh_box(Vector3(1.6, 1.8, 1.2), Color("7A6A5A"))
			shed.position = mid + Vector3(1.6, 0.9, 0.5)
			row.add_child(shed)
			var shed_roof := Props.mesh_box(Vector3(1.9, 0.12, 1.5), Color("5A3B2A"))
			shed_roof.position = mid + Vector3(1.6, 1.86, 0.5)
			row.add_child(shed_roof)
		else:
			Outdoors._tree(row, mid + Vector3(-1.2, 0, 0.4), rng.randf_range(0.9, 1.3))
		cursor += plot
		i += 1


func _duck(parent: Node3D, at: Vector3, scale := 1.0) -> Node3D:
	var duck := Node3D.new()
	duck.position = at
	parent.add_child(duck)
	var body := Props.mesh_box(Vector3(0.5, 0.3, 0.32) * scale, Color("F2E5B8"))
	duck.add_child(body)
	var head := Props.mesh_box(Vector3(0.2, 0.22, 0.2) * scale, Color("5E8F4A"))
	head.position = Vector3(0.25 * scale, 0.3 * scale, 0)
	duck.add_child(head)
	var bill := Props.mesh_box(Vector3(0.14, 0.06, 0.1) * scale, Color("E6B655"))
	bill.position = Vector3(0.4 * scale, 0.36 * scale, 0)
	duck.add_child(bill)
	return duck


func _build_sign(place: Dictionary, color: Color) -> void:
	var door: Vector3 = to_world(place.get("door", Vector2.ZERO), 0.12)
	var side := str(place.get("side", "N"))
	var inward := _inward3(side)
	var along := Vector3(-inward.z, 0, inward.x)
	# An awning over the door and the name above it.
	var awning := Props.mesh_box(Vector3(2.4, 0.16, 0.8), color)
	awning.position = door + Vector3(0, 2.5, 0) + inward * 0.3
	awning.rotation.y = atan2(-along.z, along.x)
	world.add_child(awning)
	var frame := Props.mesh_box(Vector3(1.4, 2.2, 0.12), color.darkened(0.35))
	frame.position = door + inward * 0.12
	frame.rotation.y = atan2(-along.z, along.x)
	world.add_child(frame)
	var text := str(place.get("name", ""))
	if text != "":
		# Neighbours' names take turns at two heights, so none sit on top of another.
		var lift := 3.2 if kerb_signs % 2 == 0 else 4.05
		kerb_signs += 1
		var label := _sign_text(text, door + inward * 0.3 + Vector3(0, lift, 0), Color("3E3A4F"))
		label.font_size = 64
		# Gone before the truck is alongside, when it would fill the windscreen.
		label.visibility_range_begin = 10.0
		label.visibility_range_begin_margin = 3.0
		label.visibility_range_end = 38.0


func _near_front(door: Vector2, front_doors: Array) -> bool:
	for at in front_doors:
		if door.distance_to(at) < 4.0 * PX:
			return true
	return false


func _sign_text(text: String, at: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = UIKit.title_font()
	label.font_size = 64
	label.pixel_size = 0.006
	label.modulate = color
	label.outline_modulate = Color(1, 1, 1, 0.9)
	label.outline_size = 10
	# Readable from the street, gone before it fills the windscreen, gone again before it piles up on the skyline.
	label.visibility_range_begin = 5.0
	label.visibility_range_begin_margin = 2.0
	label.visibility_range_end = 55.0
	label.visibility_range_end_margin = 8.0
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	# Signs always face the camera, so they never read backwards from the far side.
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.position = at
	world.add_child(label)
	return label


func _inward3(side: String) -> Vector3:
	match side:
		"N":
			return Vector3(0, 0, 1)
		"S":
			return Vector3(0, 0, -1)
		"W":
			return Vector3(1, 0, 0)
	return Vector3(-1, 0, 0)


func _build_bay(place: Dictionary, caption: String) -> void:
	var bay: Rect2 = place.get("bay", Rect2())
	if bay.size == Vector2.ZERO:
		return
	var root := Node3D.new()
	root.name = "Bay_" + caption
	world.add_child(root)
	var pad := Props.mesh_box(Vector3(bay.size.x / PX, 0.02, bay.size.y / PX), UIKit.MUSTARD)
	pad.position = rect_center(bay, 0.0)
	var material := pad.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(UIKit.MUSTARD, 0.45)
	root.add_child(pad)
	var frame := Props.mesh_box(Vector3(bay.size.x / PX + 0.2, 0.05, bay.size.y / PX + 0.2), UIKit.MUSTARD)
	frame.position = rect_center(bay, 0.0) - Vector3(0, 0.03, 0)
	root.add_child(frame)
	var label := _sign_text(caption, rect_center(bay, 1.6), Color("3E3A4F"))
	label.font_size = 96
	label.visibility_range_begin = 0.0
	label.visibility_range_begin_margin = 0.0
	label.reparent(root)
	bay_nodes[caption] = root


func _build_hazard(hazard: Dictionary) -> void:
	var kind := str(hazard.get("type", ""))
	var at := to_world(Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0))), 0.0)
	match kind:
		"cone":
			var cone := Outdoors._cone(0.28, 0.75, Color("E8743B"))
			cone.name = "cone"
			cone.position = at
			world.add_child(cone)
			var stripe := Props.mesh_box(Vector3(0.36, 0.08, 0.36), Color("F4E9D8"))
			stripe.position = at + Vector3(0, 0.38, 0)
			world.add_child(stripe)
		"puddle":
			var puddle := Outdoors._disc(float(hazard.get("r", 56)) / PX, Color("7FA3B8"))
			puddle.name = "puddle"
			puddle.position = at + Vector3(0, 0.012, 0)
			world.add_child(puddle)
		"bump":
			var bump := Props.mesh_box(Vector3(float(hazard.get("w", 170)) / PX, 0.14, float(hazard.get("h", 36)) / PX), Color("E6B655"))
			bump.name = "speed_bump"
			bump.position = at
			world.add_child(bump)
		"gravel":
			var gravel := Props.mesh_box(Vector3(float(hazard.get("w", 280)) / PX, 0.05, float(hazard.get("h", 80)) / PX), Color("9C8469"))
			gravel.name = "gravel"
			gravel.position = at
			world.add_child(gravel)
		"ducks":
			var ducks := Node3D.new()
			ducks.name = "duck"
			ducks.position = at
			world.add_child(ducks)
			for i in 4:
				_duck(ducks, Vector3(-1.2 + i * 0.8, 0.0, (i % 2) * 0.6 - 0.3), 1.0)


func _build_truck() -> void:
	truck = Props.model("mover_truck")
	if truck == null:
		truck = Props.mesh_box(Vector3(4.5, 2.6, 2.1), Color("F4E9D8"))
	truck.name = "Truck"
	add_child(truck)
	truck.position = to_world(pos)
	truck.rotation.y = -heading
	if str(course.get("weather", "clear")) == "night":
		for side in [-0.6, 0.6]:
			var beam := SpotLight3D.new()
			beam.name = "Headlight"
			beam.position = Vector3(2.3, 0.9, side)
			beam.rotation_degrees = Vector3(-6, -90, 0)
			beam.light_color = Color("FFF1C9")
			beam.light_energy = 3.2
			beam.spot_range = 26.0
			beam.spot_angle = 28.0
			beam.shadow_enabled = false
			truck.add_child(beam)
			var lamp := Props.mesh_box(Vector3(0.08, 0.18, 0.26), Color("FFF6DC"))
			var glow := Props.mat(Color("FFF6DC"))
			glow.emission_enabled = true
			glow.emission = Color("FFF1C9")
			glow.emission_energy_multiplier = 3.0
			lamp.material_override = glow
			lamp.position = Vector3(2.3, 0.75, side)
			truck.add_child(lamp)
	# Reversing lights on the tail, lit while backing up.
	for side in [-0.7, 0.7]:
		var lamp := Props.mesh_box(Vector3(0.08, 0.14, 0.2), Color("FFF6DC"))
		var glow := Props.mat(Color("FFF6DC"))
		glow.emission_enabled = true
		glow.emission = Color("FFF1C9")
		glow.emission_energy_multiplier = 2.5
		lamp.material_override = glow
		lamp.position = Vector3(-2.35, 0.55, side)
		lamp.visible = false
		truck.add_child(lamp)
		reverse_lights.append(lamp)
	arrow = null


func _make_car(color: Color) -> Node3D:
	var car := Node3D.new()
	var body := Props.mesh_box(Vector3(4.0, 0.9, 1.8), color)
	body.position.y = 0.4
	car.add_child(body)
	var cabin := Props.mesh_box(Vector3(2.0, 0.7, 1.6), color.darkened(0.15))
	cabin.position = Vector3(-0.2, 1.3, 0)
	car.add_child(cabin)
	var glass := Props.mesh_box(Vector3(0.1, 0.5, 1.4), Color("9FC4D6"))
	glass.position = Vector3(0.85, 1.35, 0)
	car.add_child(glass)
	for dx in [-1.3, 1.3]:
		for dz in [-0.95, 0.95]:
			var wheel := Props.mesh_cylinder(0.36, 0.3, Color("2E2A2C"))
			wheel.rotation.x = PI * 0.5
			wheel.position = Vector3(dx, 0.36, dz)
			car.add_child(wheel)
	return car


func _spawn_traffic() -> void:
	var loops: Array = city.traffic_loops()
	var count := int(Tuning.get_value("drive.traffic_cars", 10))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "drive")))
	var mps := float(Tuning.get_value("drive.traffic_mps", 2.4)) * PX
	var palette := [Color("F2E5B8"), Color("9FC4D6"), Color("D9765F"), Color("C9D2C0"), Color("E6B655"), Color("7A5C40")]
	for i in count:
		var loop: PackedVector2Array = loops[rng.randi_range(0, loops.size() - 1)]
		var seg := rng.randi_range(0, loop.size() - 1)
		var start: Vector2 = loop[seg].lerp(loop[(seg + 1) % loop.size()], rng.randf())
		if start.distance_to(pos) < 420.0:
			start = loop[(seg + 2) % loop.size()]
			seg = (seg + 2) % loop.size()
		var node := _make_car(palette[i % palette.size()])
		node.name = "Car"
		node.position = to_world(start)
		world.add_child(node)
		cars.append({"loop": loop, "seg": seg, "pos": start, "speed": mps * rng.randf_range(0.8, 1.1), "cruise": mps, "node": node, "heading": 0.0, "horn": 0.0, "vel": Vector2.ZERO, "mode": "drive", "knock_t": 0.0, "spin": 0.0, "mass": CAR_MASS})
	# Patrol cars with a light bar. They notice a truck that is fast, in the
	# alley, or off the road in front of them. Every patrol is out at night;
	# by day one cruises once the heat is up.
	Crime.ensure()
	var patrol_count := 0
	if str(course.get("weather", "clear")) == "night":
		patrol_count = int(course.get("patrols", int((Crime.data.get("patrols", {}) as Dictionary).get("count", 2))))
	elif Crime.heat() >= 6:
		patrol_count = 1
	if patrol_count > 0:
		for i in patrol_count:
			var loop: PackedVector2Array = loops[(i * 3 + 1) % loops.size()]
			var seg := (i * 2) % loop.size()
			var start: Vector2 = loop[seg].lerp(loop[(seg + 1) % loop.size()], 0.4)
			var node := _make_car(Color("2E3340"))
			node.name = "Patrol"
			var bar := Props.mesh_box(Vector3(0.9, 0.16, 0.5), Color("DD3344"))
			bar.name = "LightBar"
			var bar_glow := Props.mat(Color("DD3344"))
			bar_glow.emission_enabled = true
			bar_glow.emission = Color("FF3344")
			bar_glow.emission_energy_multiplier = 2.5
			bar.material_override = bar_glow
			bar.position = Vector3(-0.2, 1.75, 0)
			node.add_child(bar)
			var bar_light := OmniLight3D.new()
			bar_light.name = "BarLight"
			bar_light.position = Vector3(-0.2, 2.2, 0)
			bar_light.light_color = Color("FF3344")
			bar_light.light_energy = 2.0
			bar_light.omni_range = 9.0
			bar_light.shadow_enabled = false
			node.add_child(bar_light)
			node.position = to_world(start)
			world.add_child(node)
			var car := {"loop": loop, "seg": seg, "pos": start, "speed": mps * 0.9, "cruise": mps * 0.9, "node": node, "heading": 0.0, "horn": 99999.0, "patrol": true, "vel": Vector2.ZERO, "mode": "drive", "knock_t": 0.0, "spin": 0.0, "mass": COP_MASS, "alert": 0, "escape_t": 0.0, "pursuit_t": 0.0, "pit_cool": 0.0}
			cars.append(car)
			patrols.append(car)


func _build_route_marks() -> void:
	for dot in route_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	route_dots.clear()
	if route.size() < 2:
		return
	var marks := Node3D.new()
	marks.name = "RouteDots"
	world.add_child(marks)
	for i in range(1, route.size()):
		var a := route[i - 1]
		var b := route[i]
		var steps := int(a.distance_to(b) / 48.0)
		for k in range(1, steps):
			var dot := Outdoors._disc(0.3, Color(UIKit.TERRA, 0.95))
			dot.position = to_world(a.lerp(b, float(k) / float(steps)), 0.03)
			dot.set_meta("leg", i)
			marks.add_child(dot)
			route_dots.append(dot)
	# A pillar of light over the bay at the far end, seen over the roofs.
	var bay: Rect2 = dropoff.get("bay", Rect2())
	if bay.size != Vector2.ZERO:
		var beacon := Props.mesh_box(Vector3(0.7, 26.0, 0.7), UIKit.MUSTARD)
		beacon.name = "Beacon"
		var glow := beacon.material_override as StandardMaterial3D
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.albedo_color = Color(UIKit.MUSTARD, 0.35)
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.emission_enabled = true
		glow.emission = UIKit.MUSTARD
		glow.emission_energy_multiplier = 1.2
		beacon.position = rect_center(bay, 13.0)
		marks.add_child(beacon)
		route_dots.append(beacon)
		beacon.set_meta("leg", 999)


func _make_rain(snow := false) -> void:
	rain = CPUParticles3D.new()
	rain.amount = 500 if not snow else 320
	rain.lifetime = 1.4 if not snow else 3.2
	rain.preprocess = 1.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(18, 1, 18)
	rain.direction = Vector3(0.1, -1, 0)
	rain.spread = 4
	rain.gravity = Vector3(0, -2, 0)
	rain.initial_velocity_min = 9.0 if not snow else 1.6
	rain.initial_velocity_max = 12.0 if not snow else 2.6
	rain.scale_amount_min = 0.03 if not snow else 0.05
	rain.scale_amount_max = 0.05 if not snow else 0.09
	rain.mesh = BoxMesh.new()
	(rain.mesh as BoxMesh).size = Vector3(0.6, 6.0, 0.6) if not snow else Vector3(0.9, 0.9, 0.9)
	rain.material_override = Props.mat(Color(0.8, 0.86, 0.95, 0.5) if not snow else Color(0.98, 0.98, 1.0, 0.85))
	(rain.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_child(rain)


# ---------------------------------------------------------------- hud

func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_root = Control.new()
	hud_root.name = "DriveHud"
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	UIKit.fill(hud_root, 0, 0, 0, 0)
	var card := Panel.new()
	card.name = "ConditionCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	hud_root.add_child(card)
	UIKit.pin_top_left(card, 16, 16, 560, 176)
	var title := UIKit.label("Box condition", 28, UIKit.DARK, "title", false)
	title.position = Vector2(20, 12)
	title.custom_minimum_size = Vector2(320, 44)
	card.add_child(title)
	meter = ProgressBar.new()
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.position = Vector2(20, 72)
	meter.size = Vector2(360, 36)
	meter.custom_minimum_size = Vector2(360, 36)
	meter.max_value = 100
	meter.value = 100
	meter.show_percentage = false
	var track := UIKit.style(Color(UIKit.DARK, 0.12), 18)
	track.shadow_size = 0
	meter.add_theme_stylebox_override("background", track)
	meter_fill = UIKit.style(UIKit.SAGE, 18)
	meter_fill.shadow_size = 0
	meter.add_theme_stylebox_override("fill", meter_fill)
	card.add_child(meter)
	meter_label = UIKit.label("100", 36, UIKit.DARK, "body", false)
	meter_label.position = Vector2(400, 16)
	meter_label.custom_minimum_size = Vector2(120, 44)
	card.add_child(meter_label)
	speed_label = UIKit.label("0 km/h", 28, UIKit.WOOD, "small", false)
	speed_label.name = "SpeedLabel"
	speed_label.position = Vector2(400, 70)
	speed_label.custom_minimum_size = Vector2(150, 40)
	card.add_child(speed_label)
	# The ride's verdict ("Smooth Ride") under the speed, so it never runs off the card.
	stamp_label = UIKit.label("", 22, UIKit.DARK, "small", false)
	stamp_label.name = "StampLabel"
	stamp_label.position = Vector2(400, 110)
	stamp_label.custom_minimum_size = Vector2(150, 36)
	card.add_child(stamp_label)
	if str(course.get("weather", "clear")) == "night":
		spot_label = UIKit.label("Patrols out. Keep it slow.", 24, UIKit.LOSS, "small", false)
		spot_label.name = "SpotLabel"
		spot_label.position = Vector2(20, 118)
		spot_label.custom_minimum_size = Vector2(370, 36)
		card.add_child(spot_label)
	var hint_bar := Panel.new()
	hint_bar.name = "DriveHint"
	hint_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	hud_root.add_child(hint_bar)
	UIKit.pin_bottom(hint_bar, 16, -156, -16, -12)
	var bar_row := HBoxContainer.new()
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_row.add_theme_constant_override("separation", 24)
	hint_bar.add_child(bar_row)
	UIKit.fill(bar_row, 20, 12, 440, 12)
	var bar_text := VBoxContainer.new()
	bar_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_text.add_theme_constant_override("separation", 2)
	bar_row.add_child(bar_text)
	objective = UIKit.label("", 30, UIKit.TERRA, "title", false)
	objective.name = "Objective"
	bar_text.add_child(objective)
	hint = UIKit.label("", 26, UIKit.DARK, "small")
	hint.max_lines_visible = 2
	hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bar_text.add_child(hint)
	chips_slot = VBoxContainer.new()
	chips_slot.name = "ChipsSlot"
	chips_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips_slot.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_row.add_child(chips_slot)
	var name_bar := Panel.new()
	name_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.NIGHT, 14))
	hud_root.add_child(name_bar)
	# The app's Pause button owns the top-right corner; the title sits to its left.
	UIKit.pin_top_right(name_bar, -640, 16, -172, 84)
	var bar_title := str(course.get("title", "Drive"))
	if not haul.is_empty():
		bar_title = ("%s to %s" % [haul.get("via", "The interstate"), haul.get("city", "")]) if highway else ("%s, %s" % [haul.get("city", ""), haul.get("state", "")])
	var name_label := UIKit.label(bar_title, 28, UIKit.CREAM_CARD, "title", false)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_bar.add_child(name_label)
	UIKit.fill(name_label, 12, 8, 12, 8)
	# The radio is a small dial under the title; the road itself is the map.
	radio_button = UIKit.button("♪ Radio", UIKit.NIGHT)
	radio_button.name = "RadioButton"
	radio_button.custom_minimum_size = Vector2(300, 52)
	radio_button.pressed.connect(_radio_next)
	hud_root.add_child(radio_button)
	UIKit.pin_top_right(radio_button, -332, 96, -16, 148)
	radio_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	UIKit.link_focus([radio_button])
	minimap = null
	distance_label = UIKit.label("", 24, UIKit.CREAM_CARD, "small", false)
	distance_label.name = "DistanceLabel"
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_root.add_child(distance_label)
	UIKit.pin_top_right(distance_label, -332, 156, -16, 196)


func _set_action(text: String) -> void:
	if hud_root == null:
		return
	if act_button != null and is_instance_valid(act_button):
		act_button.queue_free()
		act_button = null
	if text == "":
		if radio_button:
			UIKit.link_focus([radio_button])
		return
	act_button = UIKit.button(text, UIKit.TERRA)
	act_button.name = "ActButton"
	act_button.custom_minimum_size = Vector2(380, 64)
	act_button.pressed.connect(_interact)
	hud_root.add_child(act_button)
	act_button.layout_mode = 1
	act_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	act_button.offset_left = -412
	act_button.offset_right = -32
	act_button.offset_top = -124
	act_button.offset_bottom = -60
	UIKit.link_focus([act_button, radio_button] if radio_button else [act_button])


func _hint_text() -> String:
	var weather := str(course.get("weather", "clear"))
	var dest := str(dropoff.get("name", "the new place"))
	var line := ""
	match state:
		"load":
			line = "The boxes are on the curb. Pull them into the bed."
		"drive":
			if highway and not at_end:
				line = "Hold the throttle and let the miles go by. Ease off for the bumps; a box rides a hundred miles the way it rides one."
			elif at_dropoff:
				line = "Pulled up at the kerb. Hand the boxes over."
			elif at_end:
				line = "Pulled up at the kerb."
			elif along < 60.0 and speed < 5.0:
				line = "Hold the throttle to pull away. The truck keeps its lane."
			else:
				var cue := _hazard_ahead()
				if not cue.is_empty():
					line = "%s ahead. Ease off and the boxes ride easy." % _hazard_word(str(cue.get("kind", "")))
				elif _in_turnout_zone():
					line = "The turnout. Stop here a moment for the photo."
				else:
					line = "The truck keeps its lane. Brake for what's on the road; honk for the people on the kerb."
				if str(course.get("id", "")) == "duck_pond":
					line += " Honk and the ducks hurry."
		"unload":
			line = "Unloading at %s." % dest
		_:
			line = "Done."
	if speed_label:
		speed_label.text = "%d km/h" % int(round(absf(speed) / PX * 3.6 * 3.2))
	if objective:
		match state:
			"load":
				objective.text = "Load up at %s" % pickup.get("name", "the curb")
			"drive":
				if highway:
					objective.text = "%s · %s" % [haul.get("via", "the interstate"), str(haul.get("city", ""))]
				else:
					objective.text = "At the kerb" if (at_dropoff or at_end) else "To %s%s" % [dest, _turn_cue()]
			"unload":
				objective.text = "Unloading"
			_:
				objective.text = "Delivered"
	_sync_chips()
	if weather == "rain" and state == "load":
		line += " Rain makes the stop longer."
	return line


func _say(line: String, seconds: float) -> void:
	set_line = line
	set_line_t = seconds


func _set_pieces(delta: float) -> void:
	# What the chapter promised: the gull on the coast, the cat and the
	# meteor at night, the confetti on the parade (on the horn).
	var id := str(course.get("id", ""))
	var frac := along / maxf(lane_total, 1.0)
	match id:
		"windy_coast":
			if frac > 0.45 and not set_done.has("gull"):
				set_done["gull"] = true
				_gull_swoop()
		"neon_night":
			if frac > 0.2 and not set_done.has("cat"):
				set_done["cat"] = true
				_stray_cat_appears()
			if frac > 0.6 and not set_done.has("meteor"):
				set_done["meteor"] = true
				_meteor()
			if stray_cat != null and is_instance_valid(stray_cat):
				var behind := to_world(pos) - _forward() * 3.2 + Vector3(0.9, 0.0, 0.0)
				stray_cat.position = stray_cat.position.lerp(behind, clampf(delta * 2.5, 0.0, 1.0))
				stray_cat.position.y = 0.12 + absf(sin(time_alive * 10.0)) * 0.05
				stray_cat.rotation.y = -heading
		"parade_detour":
			if frac > 0.1 and not set_done.has("parade"):
				set_done["parade"] = true
				_say("Parade day. Honk along.", 4.0)
				_confetti()
		"lodge_snow":
			if frac > 0.05 and not set_done.has("chains"):
				set_done["chains"] = true
				_say("Chains on. Calm as cocoa.", 4.0)


func _confetti() -> void:
	var burst := CPUParticles3D.new()
	burst.amount = 160
	burst.lifetime = 2.4
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	burst.emission_box_extents = Vector3(6, 1, 6)
	burst.direction = Vector3(0, 1, 0)
	burst.spread = 60
	burst.gravity = Vector3(0, -1.4, 0)
	burst.initial_velocity_min = 2.0
	burst.initial_velocity_max = 5.0
	burst.scale_amount_min = 0.06
	burst.scale_amount_max = 0.12
	burst.mesh = BoxMesh.new()
	(burst.mesh as BoxMesh).size = Vector3(1, 0.2, 1)
	burst.color_ramp = Gradient.new()
	burst.color_ramp.set_color(0, Color("E6B655"))
	burst.color_ramp.set_color(1, Color("D9765F"))
	burst.position = to_world(pos) + Vector3(0, 4.5, 0)
	add_child(burst)
	burst.emitting = true
	AudioDirector.play_sfx("sfx_applause")
	get_tree().create_timer(3.0).timeout.connect(burst.queue_free)


func _gull_swoop() -> void:
	# A gull crosses low over the cab and leaves with the sandwich.
	var gull := Node3D.new()
	gull.name = "Gull"
	var body := Props.mesh_box(Vector3(0.5, 0.14, 0.2), Color("F4F1EA"))
	gull.add_child(body)
	for side in [-1.0, 1.0]:
		var wing := Props.mesh_box(Vector3(0.18, 0.03, 0.7), Color("E4E0D6"))
		wing.position = Vector3(0, 0.05, side * 0.4)
		wing.name = "WingL" if side < 0.0 else "WingR"
		gull.add_child(wing)
	var beak := Props.mesh_box(Vector3(0.12, 0.05, 0.06), Color("E6B655"))
	beak.position = Vector3(0.3, 0.02, 0)
	gull.add_child(beak)
	add_child(gull)
	var forward := _forward()
	var side_v := Vector3(-forward.z, 0, forward.x)
	var start := to_world(pos) + forward * 14.0 + side_v * 6.0 + Vector3(0, 7.0, 0)
	var dip := to_world(pos) + forward * 4.0 + Vector3(0, 3.2, 0)
	var away := to_world(pos) - forward * 10.0 - side_v * 8.0 + Vector3(0, 9.0, 0)
	gull.position = start
	gull.look_at(dip, Vector3.UP)
	var tw := create_tween()
	tw.tween_property(gull, "position", dip, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		AudioDirector.play_sfx("sfx_l15_gull_call")
		_say("A gull. That was the sandwich.", 4.0)
		if is_instance_valid(gull):
			gull.look_at(away, Vector3.UP)
	)
	tw.tween_property(gull, "position", away, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(gull.queue_free)


func _stray_cat_appears() -> void:
	var cat := Node3D.new()
	cat.name = "StrayCat"
	var body := Props.mesh_box(Vector3(0.5, 0.22, 0.2), Color("E07A5F"))
	body.position.y = 0.11
	cat.add_child(body)
	var head := Props.mesh_box(Vector3(0.2, 0.18, 0.18), Color("E07A5F"))
	head.position = Vector3(0.3, 0.24, 0)
	cat.add_child(head)
	for side in [-0.06, 0.06]:
		var ear := Props.mesh_box(Vector3(0.05, 0.07, 0.04), Color("D06A50"))
		ear.position = Vector3(0.33, 0.36, side)
		cat.add_child(ear)
		var eye := Props.mesh_box(Vector3(0.02, 0.03, 0.03), Color("FFF1D6"))
		eye.position = Vector3(0.41, 0.26, side)
		cat.add_child(eye)
	var tail := Props.mesh_box(Vector3(0.3, 0.04, 0.04), Color("D06A50"))
	tail.position = Vector3(-0.36, 0.3, 0)
	tail.rotation.z = 0.6
	cat.add_child(tail)
	cat.position = to_world(pos) - _forward() * 4.0
	world.add_child(cat)
	stray_cat = cat
	AudioDirector.play_sfx("sfx_cat_meow")
	_say("A stray cat is trotting behind the truck.", 4.0)


func _meteor() -> void:
	var streak := Props.mesh_box(Vector3(3.0, 0.08, 0.08), Color("FFF1D6"))
	var glow := Props.mat(Color("FFF1D6"))
	glow.emission_enabled = true
	glow.emission = Color("FFE9B0")
	glow.emission_energy_multiplier = 3.0
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak.material_override = glow
	var forward := _forward()
	var side_v := Vector3(-forward.z, 0, forward.x)
	var from := to_world(pos) + forward * 40.0 + side_v * 18.0 + Vector3(0, 30.0, 0)
	var to := to_world(pos) + forward * 48.0 - side_v * 10.0 + Vector3(0, 14.0, 0)
	streak.position = from
	streak.look_at(to, Vector3.UP)
	streak.rotate_object_local(Vector3.UP, PI * 0.5)
	add_child(streak)
	var tw := create_tween()
	tw.tween_property(streak, "position", to, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(streak.queue_free)
	_say("A meteor. Make a wish. Or don't need one.", 4.0)


func _hazard_word(kind: String) -> String:
	match kind:
		"cone":
			return "Cones"
		"bump":
			return "A speed bump"
		"puddle":
			return "A puddle"
		"gravel":
			return "Loose gravel"
		"ducks":
			return "Ducks on the road"
	return "Something"


func _in_turnout_zone() -> bool:
	for spot in turnouts:
		if (spot["rect"] as Rect2).get_center().distance_to(pos) < 130.0 and not photos.has(str(spot.get("reward", ""))):
			return true
	return false


func _turn_cue() -> String:
	# The next turn and how far off it is: "left in 24 m", "straight on",
	# "the bay in 12 m". Read off the route ahead of the truck.
	var cue := _hazard_ahead()
	if not cue.is_empty() and float(cue["dist"]) < 40.0 * PX:
		return "  ·  %s in %d m" % [_hazard_word(str(cue.get("kind", ""))).to_lower(), int(round(float(cue["dist"]) / PX))]
	if route.size() < 2:
		return ""
	var idx := clampi(route_index, 1, route.size() - 1)
	var node := route[idx]
	var dist := pos.distance_to(node) / PX
	if idx >= route.size() - 1:
		return "  ·  the bay in %d m" % int(round(dist))
	var dir1 := (node - pos).normalized()
	var dir2 := (route[idx + 1] - node).normalized()
	var cross := dir1.x * dir2.y - dir1.y * dir2.x
	var word := "straight on"
	if cross > 0.5:
		word = "right"
	elif cross < -0.5:
		word = "left"
	elif dir1.dot(dir2) < -0.5:
		word = "turn around"
	return "  ·  %s in %d m" % [word, int(round(dist))]


func _sync_chips() -> void:
	if chips_slot == null:
		return
	var items: Array = []
	if state == "load":
		items = [[Controls.describe_key("interact"), "load up"]]
	elif state == "drive" and at_dropoff:
		items = [[Controls.describe_key("interact"), "unload"]]
	elif state == "drive":
		items = [[Controls.describe_key("drive_forward"), "go"], [Controls.describe_key("drive_back"), "brake"], [Controls.describe_key("horn"), "honk"]]
	var key := JSON.stringify(items)
	if key == _chips_key:
		return
	_chips_key = key
	for child in chips_slot.get_children():
		child.queue_free()
	chips_slot.add_child(UIKit.chips(items))


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if not running:
		return
	time_alive += delta
	pulse += delta
	if rev_cd > 0.0:
		rev_cd -= delta
	var weather := str(course.get("weather", "clear"))
	if weather == "rain":
		wiper += delta
		if wiper >= 2.8:
			wiper = 0.0
			AudioDirector.play_sfx("sfx_l03_wiper")
	if state == "load" or state == "unload":
		_animate_boxes(delta)
	else:
		_drive(delta, weather)
		honk_cool = maxf(0.0, honk_cool - delta)
		_patrols(delta)
		var reversing := speed < -3.0
		for lamp in reverse_lights:
			if is_instance_valid(lamp):
				(lamp as Node3D).visible = reversing
		if reversing and in_bay:
			reverse_beep -= delta
			if reverse_beep <= 0.0:
				reverse_beep = 0.7
				AudioDirector.play_sfx("sfx_notification_soft")
		else:
			reverse_beep = 0.0
		_traffic(delta)
		_hazards()
		_set_pieces(delta)
		_check_alley()
		_check_lighthouse_photo(delta)
		_check_dropoff()
	_walkers(delta)
	_place_truck(delta)
	_update_camera(delta)
	_update_marks()
	if rain:
		rain.global_position = truck.global_position + Vector3(0, 12, 0)
	meter.value = condition
	if meter_fill:
		meter_fill.bg_color = UIKit.SAGE if condition >= 70 else (UIKit.MUSTARD if condition >= 50 else UIKit.TERRA)
	var stamp := Tuning.tip_stamp(condition)
	meter_label.text = str(condition)
	if stamp_label:
		stamp_label.text = stamp
	hint.text = _hint_text()
	if set_line_t > 0.0:
		set_line_t -= delta
		hint.text = set_line
	if distance_label:
		var left := _route_left()
		if highway:
			var miles_left := int(ceil(float(haul.get("miles", 0)) * clampf(left / maxf(lane_total, 1.0), 0.0, 1.0)))
			distance_label.text = "%d mi to %s" % [miles_left, str(haul.get("city", ""))] if state == "drive" and not at_end else ""
		else:
			distance_label.text = "%d m to go" % int(round(left / PX)) if state == "drive" and not at_end else ""
	if minimap:
		minimap.queue_redraw()


func _route_left() -> float:
	if lane_total > 0.0:
		return maxf(0.0, lane_total - along)
	if route.size() < 2:
		return 0.0
	var idx := clampi(route_index, 1, route.size() - 1)
	var total := pos.distance_to(route[idx])
	for i in range(idx + 1, route.size()):
		total += route[i - 1].distance_to(route[i])
	return total


func _place_truck(delta: float) -> void:
	var side := Vector2(-sin(heading), cos(heading))
	truck.position = to_world(pos + side * jolt.x)
	truck.rotation.y = -heading
	# Lean into corners and rock on a hit.
	var lean := clampf(-skid / 160.0, -0.08, 0.08) + roll
	truck.rotation.x = lerpf(truck.rotation.x, lean, delta * 6.0)
	jolt = jolt.move_toward(Vector2.ZERO, 40.0 * delta)
	if shake > 0.0 and SaveManager.shake:
		shake -= delta
		truck.position += Vector3(randf_range(-0.05, 0.05), 0.0, randf_range(-0.05, 0.05))
		truck.rotation.z = randf_range(-0.03, 0.03)
	else:
		truck.rotation.z = lerpf(truck.rotation.z, 0.0, delta * 8.0)


func _update_camera(delta: float) -> void:
	# A chase camera low behind the cab, close enough that the truck fills
	# a good part of the frame; it drops back and widens a little with speed
	# and looks further up the road the faster you go.
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var pace := clampf(absf(speed) / max_speed, 0.0, 1.0)
	var forward := _forward()
	var truck_at := to_world(pos)
	var back := 7.6 + 2.4 * pace
	var goal := truck_at - forward * back + Vector3(0, 3.3 + 0.6 * pace, 0)
	# Look up the road itself, so a bend is in view before the truck takes it.
	var ahead2 := _lane_point(along + (4.0 + 9.0 * pace) * PX)
	var look := to_world(ahead2) + Vector3(0, 1.3, 0)
	if at_end or state != "drive":
		# At a kerb the camera stands out on the road, so the building the
		# truck is parked against never swallows it.
		var place: Dictionary = dropoff if (at_end or state == "unload") else pickup
		var inward := _inward3(str(place.get("side", "N")))
		goal = truck_at - forward * 6.0 - inward * 3.4 + Vector3(0, 3.8, 0)
		look = truck_at + forward * 2.0 + Vector3(0, 1.2, 0)
	else:
		goal = _camera_clear(goal, truck_at)
	var k := clampf(delta * 3.2, 0.0, 1.0)
	cam.position = cam.position.lerp(goal, k)
	cam_look = cam_look.lerp(look, clampf(delta * 4.5, 0.0, 1.0))
	cam.look_at(cam_look, Vector3.UP)
	cam.fov = lerpf(cam.fov, 60.0 + 12.0 * pace, clampf(delta * 3.0, 0.0, 1.0))
	# A touch of bank through a bend.
	var bank := clampf(-_lane_curvature(along) * pace * 0.9, -0.06, 0.06)
	cam.rotate_object_local(Vector3.FORWARD, lerpf(0.0, bank, 1.0))


func _snap_camera() -> void:
	var forward := _forward()
	var truck_at := to_world(pos)
	cam.position = truck_at - forward * 7.6 + Vector3(0, 3.3, 0)
	cam_look = truck_at + forward * 4.0 + Vector3(0, 1.3, 0)
	if at_end or state != "drive":
		var place: Dictionary = dropoff if (at_end or state == "unload") else pickup
		var inward := _inward3(str(place.get("side", "N")))
		cam.position = truck_at - forward * 6.0 - inward * 3.4 + Vector3(0, 3.8, 0)
		cam_look = truck_at + forward * 2.0 + Vector3(0, 1.2, 0)
	# The same clearance the live camera gets, so a snap never lands in a wall.
	if world != null:
		cam.position = _camera_clear(cam.position, truck_at)
	cam.look_at(cam_look, Vector3.UP)


func _camera_clear(goal: Vector3, truck_at: Vector3) -> Vector3:
	# A camera point inside a building slides toward the truck until it is
	# out in the street again.
	var px := Vector2(goal.x * PX, goal.z * PX)
	# Over one of the two kerbside fronts (pulling away from the one just
	# packed, or arriving at the next) the camera steps out onto the road,
	# the way the parked camera stands, rather than climbing onto the truck.
	for place in [pickup, dropoff]:
		if place.is_empty():
			continue
		for span in _front_spans:
			if (span as Rect2).grow(16.0).has_point(px):
				var out := -_inward3(str(place.get("side", "N")))
				var door: Vector3 = to_world(place.get("door", Vector2.ZERO), 0.0)
				if door.distance_to(goal) < 24.0:
					for step in 4:
						goal += out * 1.6
						px = Vector2(goal.x * PX, goal.z * PX)
						if not (span as Rect2).grow(16.0).has_point(px):
							break
	for i in 6:
		var inside := false
		for entry in city.buildings:
			if (entry.get("rect", Rect2()) as Rect2).has_point(px):
				inside = true
		for span in _front_spans:
			if (span as Rect2).grow(16.0).has_point(px):
				inside = true
		if not inside:
			break
		goal = goal.lerp(truck_at + Vector3(0, 3.0, 0), 0.25)
		px = Vector2(goal.x * PX, goal.z * PX)
	return goal


func _update_marks() -> void:
	if state == "drive" and route.size() > 1:
		var goal := route[mini(route_index, route.size() - 1)]
		if route_index < route.size() - 1 and pos.distance_to(goal) < 90.0:
			route_index += 1
	for dot in route_dots:
		if is_instance_valid(dot):
			dot.visible = state == "drive" and int(dot.get_meta("leg", 0)) >= route_index
	for caption in bay_nodes.keys():
		var node: Node3D = bay_nodes[caption]
		var active: bool = (caption == "LOAD" and state == "load") or (caption == "UNLOAD" and state == "drive")
		node.position.y = (0.05 + 0.05 * sin(pulse * 4.0)) if active else 0.0


func _drive(delta: float, weather: String) -> void:
	var accel := float(Tuning.get_value("drive.accel_mps2", 3.0)) * PX
	var brake := float(Tuning.get_value("drive.brake_mps2", 4.5)) * PX
	if weather == "rain" or weather == "snow":
		brake *= 1.0 - float(Tuning.get_value("drive.rain_brake_penalty", 0.15))
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var reverse_max := float(Tuning.get_value("drive.reverse_mps", 1.8)) * PX
	var handbrake: bool = Controls.held("handbrake")
	var throttle: float = Controls.axis("drive_back", "drive_forward")
	var forward := Vector2.RIGHT.rotated(heading)
	speed = vel.dot(forward)
	# The engine note climbs with speed and leans in under the throttle; a
	# hard stop from pace squeals.
	AudioDirector.set_loop_pitch("sfx_truck_idle_loop", _engine_pitch(speed) + (0.08 if throttle > 0.0 else 0.0))
	AudioDirector.set_loop_volume("sfx_truck_idle_loop", float(Tuning.get_value("audio.truck_idle_db", -10)) + (4.0 if throttle > 0.0 else 0.0) + clampf(absf(speed) / max_speed, 0.0, 1.0) * 3.0)
	brake_cd = maxf(0.0, brake_cd - delta)
	if brake_cd <= 0.0 and absf(speed) > max_speed * 0.45 and ((throttle < 0.0 and speed > 0.0) or handbrake):
		brake_cd = 1.6
		AudioDirector.play_sfx("sfx_l19_bus_brakes")
	if throttle > 0.0 and speed < max_speed * 0.25 and rev_cd <= 0.0 and not at_end:
		AudioDirector.play_sfx("sfx_truck_rev")
		rev_cd = 1.6
	if lane.size() < 2:
		return
	if at_end:
		# Pulled up at the kerb beside the bay. The engine idles.
		speed = 0.0
		vel = Vector2.ZERO
		return
	var cap := max_speed
	# Traffic ahead in our lane sets the pace: ease off and sit behind it.
	var lead := _lead_car(forward)
	if not lead.is_empty():
		var gap := float(lead.get("gap", 999.0))
		var lead_speed := maxf(0.0, float(lead.get("speed", 0.0)))
		var follow_cap := lead_speed + maxf(0.0, gap - FOLLOW_GAP) * 2.5
		cap = minf(cap, follow_cap)
	if duck_hold > 0.0:
		duck_hold -= delta
		cap = minf(cap, 18.0)
	# The truck eases itself to a stop at the end of the lane, past the bay.
	var remaining := lane_total - along
	cap = minf(cap, sqrt(maxf(0.0, 2.0 * brake * 0.8 * remaining)) + (6.0 if remaining > 8.0 else 0.0))
	# Bends: a lorry does not take a corner flat out.
	var bend := absf(_lane_curvature(along + 40.0))
	if bend > 0.004:
		cap = minf(cap, max_speed * 0.55)
	if handbrake:
		speed = move_toward(speed, 0.0, brake * 1.2 * delta)
	elif throttle > 0.0:
		if speed < cap:
			# Punchy off the line, tapering as it winds up: a gear-step feel.
			speed += accel * delta * throttle * (1.35 - 0.6 * clampf(speed / max_speed, 0.0, 1.0))
	elif throttle < 0.0:
		var before := speed
		speed = move_toward(speed, 0.0, brake * delta)
		_maybe_hard_brake(weather, before, delta)
	else:
		speed = move_toward(speed, 0.0, accel * 0.35 * delta)
	if speed > cap:
		speed = move_toward(speed, cap, brake * 1.5 * delta)
	speed = maxf(0.0, speed)
	along = minf(lane_total, along + speed * delta)
	var here2 := _lane_point(along)
	var ahead := _lane_point(minf(lane_total, along + 12.0))
	if ahead.distance_to(here2) > 0.01:
		heading = lerp_angle(heading, (ahead - here2).angle(), clampf(delta * 8.0, 0.0, 1.0))
	pos = here2
	forward = Vector2.RIGHT.rotated(heading)
	vel = forward * speed
	skid = _lane_curvature(along) * speed * 14.0
	roll = clampf(_lane_curvature(along) * speed * 0.0025, -0.05, 0.05)
	if absf(spin) > 0.001:
		spin = move_toward(spin, 0.0, 4.5 * delta)
	if along >= lane_total - 0.5:
		at_end = true
		speed = 0.0
		vel = Vector2.ZERO
		back_t = 0.0
		AudioDirector.play_sfx("sfx_notification_soft")
		if highway:
			_complete_highway()
			return
	var edge := int(Tuning.get_value("box_condition.collision", 10))
	_contact("offroad", false, edge)


# ---------------------------------------------------------------- the lane

func _build_lane() -> void:
	# The route runs down the middle of the road; the truck's lane is the
	# right-hand one. Corners are rounded, the start is the bay itself, and
	# the end is a stop a little past the far bay, from which the truck
	# backs in along a short arc.
	lane = PackedVector2Array()
	back_path = PackedVector2Array()
	along = 0.0
	at_end = false
	back_t = 0.0
	if route.size() < 2:
		lane_total = 0.0
		return
	var raw := PackedVector2Array()
	var bay_in: Rect2 = pickup.get("bay", Rect2())
	var start: Vector2 = bay_in.get_center() if bay_in.size != Vector2.ZERO else route[0]
	raw.append(start)
	var dir0 := (route[1] - route[0]).normalized()
	raw.append(start + dir0 * 70.0)
	for i in range(1, route.size()):
		var a := route[i - 1]
		var b := route[i]
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		if i == 1:
			raw.append(a + dir * 150.0 + side * LANE_OFFSET)
		else:
			raw.append(a + side * LANE_OFFSET)
		if i == route.size() - 1:
			# Abeam the far bay in the lane, then the stop past it.
			var bay_out: Rect2 = dropoff.get("bay", Rect2())
			var goal: Vector2 = bay_out.get_center() if bay_out.size != Vector2.ZERO else b
			# The lane ends at the kerb beside the bay: pulling up there is
			# the arrival. No backing in.
			var abeam := a + dir * maxf(0.0, (goal - a).dot(dir)) + side * LANE_OFFSET
			raw.append(abeam)
		else:
			raw.append(b + side * LANE_OFFSET)
	# Where two offset segments meet at a corner, the lane bends through the
	# corner instead of crossing itself.
	var cleaned := PackedVector2Array()
	for p in raw:
		if cleaned.is_empty() or cleaned[cleaned.size() - 1].distance_to(p) > 4.0:
			cleaned.append(p)
	lane = _round_corners(cleaned, CORNER_R)
	lane_cum = PackedFloat32Array()
	var run := 0.0
	lane_cum.append(0.0)
	for i in range(1, lane.size()):
		run += lane[i - 1].distance_to(lane[i])
		lane_cum.append(run)
	lane_total = run
	pos = lane[0]
	heading = dir0.angle()
	route_index = 1


func _round_corners(points: PackedVector2Array, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.size() < 3:
		return points
	out.append(points[0])
	for i in range(1, points.size() - 1):
		var prev := points[i - 1]
		var here := points[i]
		var next := points[i + 1]
		var din := (here - prev).normalized()
		var dout := (next - here).normalized()
		if din.dot(dout) > 0.96:
			out.append(here)
			continue
		var r := minf(radius, minf(prev.distance_to(here), here.distance_to(next)) * 0.45)
		var a := here - din * r
		var b := here + dout * r
		var steps := 6
		for k in range(0, steps + 1):
			var t := float(k) / float(steps)
			out.append(a.lerp(here, t).lerp(here.lerp(b, t), t))
	out.append(points[points.size() - 1])
	return out


func _lane_point(dist: float) -> Vector2:
	if lane.size() == 0:
		return pos
	if lane.size() == 1 or dist <= 0.0:
		return lane[0]
	if dist >= lane_total:
		return lane[lane.size() - 1]
	var lo := 0
	var hi := lane.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if lane_cum[mid] <= dist:
			lo = mid
		else:
			hi = mid
	var seg := lane_cum[hi] - lane_cum[lo]
	var t := 0.0 if seg <= 0.0 else (dist - lane_cum[lo]) / seg
	return lane[lo].lerp(lane[hi], t)


func _lane_curvature(dist: float) -> float:
	# Signed turn per pixel around a point on the lane: positive bends right.
	var a := _lane_point(dist - 24.0)
	var b := _lane_point(dist)
	var c := _lane_point(dist + 24.0)
	var d1 := (b - a)
	var d2 := (c - b)
	if d1.length() < 0.01 or d2.length() < 0.01:
		return 0.0
	return d1.normalized().angle_to(d2.normalized()) / 48.0


func _path_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


func _bezier(points: PackedVector2Array, t: float) -> Vector2:
	if points.size() < 3:
		return points[0] if points.size() > 0 else pos
	var p0 := points[0]
	var p1 := points[1]
	var p2 := points[2]
	var u := 1.0 - t
	return p0 * (u * u) + p1 * (2.0 * u * t) + p2 * (t * t)


func _hazard_ahead() -> Dictionary:
	# The nearest hazard in the truck's lane up the road, by distance along it.
	var best: Dictionary = {}
	var forward := Vector2.RIGHT.rotated(heading)
	for hazard in hazards:
		var kind := str(hazard.get("type", ""))
		if kind == "wobble":
			continue
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		var rel := at - pos
		var d := rel.dot(forward)
		if d <= 0.0 or d > 80.0 * PX:
			continue
		if absf(rel.cross(forward)) > city.road * 0.5:
			continue
		if int(hazard.get("lane", 0)) < 0 and kind != "bump":
			continue
		if best.is_empty() or d < float(best["dist"]):
			best = {"kind": kind, "dist": d, "hazard": hazard}
	return best


func _near_bay(p: Vector2, reach: float) -> bool:
	# Within `reach` px of either bay's centre, where the truck parks and
	# the boxes stack: nothing static is placed there.
	for place in [pickup, dropoff]:
		var bay: Rect2 = place.get("bay", Rect2())
		if bay.size != Vector2.ZERO and bay.get_center().distance_to(p) < reach:
			return true
	return false


func _in_bay(p: Vector2) -> bool:
	return (pickup.get("bay", Rect2()) as Rect2).grow(12).has_point(p) or (dropoff.get("bay", Rect2()) as Rect2).grow(12).has_point(p)


func _collide_buildings() -> void:
	var center := _art_center()
	for entry in city.buildings:
		var rect: Rect2 = entry.get("rect", Rect2())
		if not rect.grow(TRUCK_RADIUS).has_point(center):
			continue
		var closest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
		var away := center - closest
		var dist := away.length()
		if dist >= TRUCK_RADIUS:
			continue
		var normal := away.normalized() if dist > 0.001 else Vector2.UP
		_bounce(normal, TRUCK_RADIUS - dist, "wall")
	var water: Dictionary = city.pond()
	var pond_center: Vector2 = water.get("center", Vector2.ZERO)
	var pond_r := float(water.get("radius", 0.0)) + TRUCK_RADIUS
	if center.distance_to(pond_center) < pond_r:
		var normal := (center - pond_center).normalized()
		_bounce(normal, pond_r - center.distance_to(pond_center), "pond")


func _bounce(normal: Vector2, depth: float, kind: String) -> void:
	var into := -vel.dot(normal)
	pos += normal * (depth + 1.0)
	if into > 0.0:
		vel += normal * into * 1.2
		vel *= 0.62
		if into > 1.2 * PX:
			_apply_hit(kind, int(Tuning.get_value("box_condition.collision", 10)), 600)
			if kind == "pond":
				AudioDirector.play_sfx("sfx_l03_puddle_splash")


const FOLLOW_GAP := 92.0


func _patrols(delta: float) -> void:
	if patrols.is_empty():
		return
	patrol_flash += delta
	var red := fmod(patrol_flash, 0.6) < 0.3
	for car in patrols:
		var node: Node3D = car["node"]
		var bar := node.get_node_or_null("LightBar") as MeshInstance3D
		var light := node.get_node_or_null("BarLight") as OmniLight3D
		var tint := Color("FF3344") if red else Color("3B6CFF")
		if bar and bar.material_override is StandardMaterial3D:
			(bar.material_override as StandardMaterial3D).emission = tint
		if light:
			light.light_color = tint
	spot_cool = maxf(0.0, spot_cool - delta)
	var spec: Dictionary = Crime.data.get("patrols", {}) if not Crime.data.is_empty() else {}
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var naughty: bool = absf(speed) > max_speed * float(spec.get("speed_fraction", 0.72)) or (not city.on_road(pos) and not _in_bay(pos)) or _in_alley_now()
	var watched := false
	var truck_center := _art_center()
	for car in patrols:
		var dir := Vector2.RIGHT.rotated(float(car["heading"]))
		var rel: Vector2 = truck_center - (car["pos"] as Vector2)
		if rel.dot(dir) > 0.0 and rel.length() < 240.0 and absf(rel.cross(dir)) < 110.0:
			watched = true
	if spot_label == null and hud_root != null:
		var card := hud_root.get_node_or_null("ConditionCard")
		if card:
			spot_label = UIKit.label("Patrols out. Keep it slow.", 24, UIKit.LOSS, "small", false)
			spot_label.name = "SpotLabel"
			spot_label.position = Vector2(20, 118)
			spot_label.custom_minimum_size = Vector2(370, 36)
			card.add_child(spot_label)
	if watched and naughty and spot_cool <= 0.0:
		spot_meter += delta
		if spot_meter >= float(spec.get("spot_seconds", 2.0)):
			spot_meter = 0.0
			spot_cool = 4.0
			spotted += 1
			AudioDirector.play_sfx("sfx_truck_horn")
			_apply_hit("patrol", int(Tuning.get_value("box_condition.collision", 10)) / 2, 1500)
			# Twice is enough: the nearest watching patrol gives chase.
			for car in patrols:
				var dir := Vector2.RIGHT.rotated(float(car["heading"]))
				var rel: Vector2 = truck_center - (car["pos"] as Vector2)
				if rel.dot(dir) > 0.0 and rel.length() < 240.0 and absf(rel.cross(dir)) < 110.0:
					car["alert"] = int(car.get("alert", 0)) + 1
					if int(car["alert"]) >= (1 if int(course.get("patrols", 0)) >= 4 else 2) and str(car.get("mode", "")) != "pursuit":
						_start_pursuit(car)
	else:
		spot_meter = maxf(0.0, spot_meter - delta * 0.7)
	var chasing := _pursuers().size() > 0
	if spot_label and not chasing:
		if watched:
			spot_label.text = "Patrol watching  %d%%" % int(round(spot_meter / maxf(0.1, float(spec.get("spot_seconds", 2.0))) * 100.0))
		else:
			spot_label.text = "Spotted %d time%s" % [spotted, "" if spotted == 1 else "s"] if spotted > 0 else "Patrols out. Keep it slow."
	_cops(delta)


func _pursuers() -> Array:
	var out: Array = []
	for car in patrols:
		if str(car.get("mode", "")) == "pursuit":
			out.append(car)
	return out


func _start_pursuit(car: Dictionary) -> void:
	car["mode"] = "pursuit"
	car["pursuit_t"] = 0.0
	car["escape_t"] = 0.0
	car["pit_cool"] = 1.5
	AudioDirector.play_sfx("sfx_truck_horn")
	if spot_label:
		spot_label.text = "PATROL IN PURSUIT. Don't stop."


func _cops(delta: float) -> void:
	# A patrol in pursuit chases the truck, lines up on a rear quarter and
	# shoves it into a spin. Stop with one on your bumper and you are boxed
	# in; keep ahead long enough and they lose you.
	var chasers := _pursuers()
	if chasers.is_empty():
		arrest_t = 0.0
		return
	var truck_center := _art_center()
	var forward := Vector2.RIGHT.rotated(heading)
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	siren_t -= delta
	if siren_t <= 0.0:
		siren_t = 1.5
		AudioDirector.play_sfx("sfx_truck_horn")
	var nearest := INF
	for car in chasers:
		car["pursuit_t"] = float(car["pursuit_t"]) + delta
		car["pit_cool"] = maxf(0.0, float(car["pit_cool"]) - delta)
		var at: Vector2 = car["pos"]
		var rel := truck_center - at
		var dist := rel.length()
		nearest = minf(nearest, dist)
		# Aim behind the truck; when close and the truck is moving, aim for a rear quarter.
		var goal := truck_center - forward * 40.0
		var side_sign := 1.0 if rel.cross(forward) >= 0.0 else -1.0
		var side := Vector2(-forward.y, forward.x) * side_sign
		var pitting := dist < 150.0 and absf(speed) > 60.0 and float(car["pit_cool"]) <= 0.0
		if pitting:
			goal = truck_center - forward * 30.0 + side * 42.0
		var want := (goal - at).angle()
		var h := float(car["heading"])
		car["heading"] = h + clampf(wrapf(want - h, -PI, PI), -2.6 * delta, 2.6 * delta)
		var dir := Vector2.RIGHT.rotated(float(car["heading"]))
		var chase_speed := max_speed * 1.08 if dist > 70.0 else maxf(absf(speed) * 0.95, 30.0)
		var cv: Vector2 = car["vel"]
		cv = cv.move_toward(dir * chase_speed, 420.0 * delta)
		car["vel"] = cv
		at += cv * delta
		# Stay on the road: walls stop a patrol car too.
		for entry in city.buildings:
			var rect: Rect2 = entry.get("rect", Rect2())
			if rect.grow(CAR_RADIUS).has_point(at):
				var closest := Vector2(clampf(at.x, rect.position.x, rect.end.x), clampf(at.y, rect.position.y, rect.end.y))
				var away := at - closest
				if away.length() > 0.001:
					at = closest + away.normalized() * CAR_RADIUS
		car["pos"] = at
		car["speed"] = cv.length()
		var node: Node3D = car["node"]
		node.position = to_world(at)
		node.rotation.y = -float(car["heading"])
		# The PIT: on the rear quarter at speed, shove the truck sideways.
		if pitting and at.distance_to(goal) < 34.0:
			car["pit_cool"] = 4.0
			vel *= 0.6
			jolt.x = -side_sign * 0.9
			spin += -side_sign * 2.4
			_apply_hit("patrol", 8, 500)
			AudioDirector.play_sfx("sfx_cone_hit")
		_collide_truck_car(car)
		# Give up after a long chase, or once the truck is well away.
		if dist > 900.0:
			car["escape_t"] = float(car["escape_t"]) + delta
		else:
			car["escape_t"] = 0.0
		if float(car["escape_t"]) > 6.0 or float(car["pursuit_t"]) > 60.0:
			car["mode"] = "drive"
			car["alert"] = 0
			car["seg"] = _nearest_loop_vertex(car["loop"], at)
			if spot_label:
				spot_label.text = "Lost them."
	# Boxed in: stopped with a patrol on the bumper.
	if nearest < 130.0 and absf(speed) < 25.0 and vel.length() < 30.0:
		arrest_t += delta
		if spot_label:
			spot_label.text = "Pull away! Boxed in %d" % int(ceil(ARREST_SECONDS - arrest_t))
		if arrest_t >= ARREST_SECONDS:
			_arrested()
	else:
		arrest_t = maxf(0.0, arrest_t - delta * 0.5)
		if spot_label and not _pursuers().is_empty():
			spot_label.text = "PATROL IN PURSUIT. Don't stop."


func _arrested() -> void:
	if not running or busted:
		return
	busted = true
	running = false
	state = "busted"
	_set_action("")
	if objective:
		objective.text = "Busted"
	if hint:
		hint.text = "Boxed in. The boxes go in the van."
	AudioDirector.play_sfx("sfx_truck_horn")
	emit_signal("finished", {"busted": true, "condition": condition, "alley": alley, "honks": honks, "spotted": spotted, "backed_in": false, "duck_friend": false, "near_miss": near_miss, "time": 0.0})


func _in_alley_now() -> bool:
	for cut in city.alleys:
		if (cut as Rect2).grow(-6).has_point(pos):
			return true
	return false


func _lead_car(forward: Vector2) -> Dictionary:
	# The nearest car in front of the truck, in its lane, going its way.
	var truck_center := _art_center()
	var best: Dictionary = {}
	for car in cars:
		var rel: Vector2 = (car["pos"] as Vector2) - truck_center
		var along := rel.dot(forward)
		var side := absf(rel.cross(forward))
		if along <= 0.0 or along > 190.0 or side > 48.0:
			continue
		var car_dir := Vector2.RIGHT.rotated(float(car["heading"]))
		if car_dir.dot(forward) < 0.3:
			continue
		if best.is_empty() or along < float(best["gap"]):
			best = {"gap": along, "speed": float(car["speed"]), "car": car}
	return best


func _traffic(delta: float) -> void:
	var truck_center := _art_center()
	for car in cars:
		var mode := str(car.get("mode", "drive"))
		if mode == "pursuit":
			continue
		if mode == "knocked":
			# Shoved: it slides and spins, then finds its way back to its lane.
			var kv: Vector2 = car["vel"]
			var kat: Vector2 = car["pos"]
			kat += kv * delta
			car["vel"] = kv * maxf(0.0, 1.0 - 2.2 * delta)
			car["heading"] = float(car["heading"]) + float(car["spin"]) * delta
			car["spin"] = float(car["spin"]) * maxf(0.0, 1.0 - 2.0 * delta)
			car["knock_t"] = float(car["knock_t"]) - delta
			car["pos"] = kat
			car["speed"] = 0.0
			var knode: Node3D = car["node"]
			knode.position = to_world(kat)
			knode.rotation.y = -float(car["heading"])
			if float(car["knock_t"]) <= 0.0 and (car["vel"] as Vector2).length() < 25.0:
				car["mode"] = "drive"
				car["seg"] = _nearest_loop_vertex(car["loop"], kat)
			_collide_truck_car(car)
			continue
		var loop: PackedVector2Array = car["loop"]
		var seg: int = car["seg"]
		var target: Vector2 = loop[(seg + 1) % loop.size()]
		var at: Vector2 = car["pos"]
		var dir := (target - at).normalized()
		car["heading"] = dir.angle()
		# Ease off when the truck sits in the way, and lean on the horn.
		var to_truck := truck_center - at
		var ahead := to_truck.dot(dir) > 0.0 and to_truck.length() < 170.0 and absf(to_truck.cross(dir)) < 70.0
		var wanted: float = 0.0 if ahead else car["cruise"]
		# A car with the truck on its tail picks up its pace: the ride is
		# never parked behind a dawdler, with no wheel to pass it.
		var behind := to_truck.dot(dir) < 0.0 and to_truck.length() < 260.0 and absf(to_truck.cross(dir)) < 70.0
		if behind and not ahead and not bool(car.get("patrol", false)):
			wanted = maxf(wanted, float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX * 0.95)
		# Keep a car's length behind the car in front, so traffic moves as a line.
		for other in cars:
			if other == car:
				continue
			var rel: Vector2 = (other["pos"] as Vector2) - at
			var along := rel.dot(dir)
			if along > 0.0 and along < 110.0 and absf(rel.cross(dir)) < 40.0:
				wanted = minf(wanted, maxf(0.0, float(other["speed"]) + (along - 70.0) * 2.0))
		car["speed"] = move_toward(float(car["speed"]), wanted, 160.0 * delta)
		if ahead:
			car["horn"] = float(car["horn"]) - delta
			if float(car["horn"]) <= 0.0:
				car["horn"] = 2.5
				AudioDirector.play_sfx("sfx_truck_horn")
		at += dir * float(car["speed"]) * delta
		if at.distance_to(target) < 6.0:
			car["seg"] = (seg + 1) % loop.size()
		car["pos"] = at
		car["vel"] = dir * float(car["speed"])
		var node: Node3D = car["node"]
		node.position = to_world(at)
		node.rotation.y = -float(car["heading"])
		_collide_truck_car(car)
	_collide_cars()


func _nearest_loop_vertex(loop: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_d := INF
	for i in loop.size():
		var d := loop[i].distance_to(at)
		if d < best_d:
			best_d = d
			best = i
	# Head for the vertex after the nearest one, so the car rejoins moving forward.
	return best


func _collide_truck_car(car: Dictionary) -> void:
	# Two bodies, momentum and a little bounce. The truck is heavy, so it
	# shoves cars aside; a car hit hard slides, spins, and loses its lane.
	var truck_center := _art_center()
	var at: Vector2 = car["pos"]
	var min_dist := TRUCK_RADIUS + CAR_RADIUS - 8.0
	var dist := at.distance_to(truck_center)
	if dist >= min_dist:
		return
	var normal := (truck_center - at).normalized() if dist > 0.001 else Vector2.RIGHT.rotated(heading)
	var mt := TRUCK_MASS
	var mc := float(car.get("mass", CAR_MASS))
	var overlap := min_dist - dist + 1.0
	pos += normal * overlap * (mc / (mt + mc))
	car["pos"] = at - normal * overlap * (mt / (mt + mc))
	var car_vel: Vector2 = car.get("vel", Vector2.ZERO)
	var rel := (vel - car_vel).dot(normal)
	if rel >= 0.0:
		return
	var e := 0.3
	var j := -(1.0 + e) * rel / (1.0 / mt + 1.0 / mc)
	vel += normal * (j / mt)
	car["vel"] = car_vel - normal * (j / mc)
	var side := (car["vel"] as Vector2).normalized().cross(normal)
	if str(car.get("mode", "drive")) != "pursuit":
		car["mode"] = "knocked"
		car["knock_t"] = 1.4
		car["spin"] = clampf(j / 160.0, 0.6, 3.2) * (1.0 if side >= 0.0 else -1.0)
	else:
		car["vel"] = (car["vel"] as Vector2) * 0.6
	var closing := -rel
	if closing > 0.9 * PX:
		var amount := clampi(int(round(closing / PX * 2.5)), 4, 14)
		_apply_hit("car", amount, 900)
		spin += clampf(j / 420.0, -1.6, 1.6) * (1.0 if side >= 0.0 else -1.0)


func _collide_cars() -> void:
	# Cars keep out of each other too; a knocked car shoves the one it slides into.
	for i in cars.size():
		for k in range(i + 1, cars.size()):
			var a: Dictionary = cars[i]
			var b: Dictionary = cars[k]
			var pa: Vector2 = a["pos"]
			var pb: Vector2 = b["pos"]
			var d := pa.distance_to(pb)
			var min_d := CAR_RADIUS * 2.0 - 10.0
			if d >= min_d or d < 0.001:
				continue
			var n := (pb - pa) / d
			var push := (min_d - d) * 0.5
			a["pos"] = pa - n * push
			b["pos"] = pb + n * push
			var a_knocked := str(a.get("mode", "")) == "knocked"
			var b_knocked := str(b.get("mode", "")) == "knocked"
			if a_knocked and not b_knocked and str(b.get("mode", "")) == "drive":
				b["mode"] = "knocked"
				b["knock_t"] = 1.0
				b["vel"] = (a["vel"] as Vector2) * 0.5
				b["spin"] = 0.8
			elif b_knocked and not a_knocked and str(a.get("mode", "")) == "drive":
				a["mode"] = "knocked"
				a["knock_t"] = 1.0
				a["vel"] = (b["vel"] as Vector2) * 0.5
				a["spin"] = -0.8
			for car in [a, b]:
				var node: Node3D = car["node"]
				node.position = to_world(car["pos"])


func _check_alley() -> void:
	if not bool(course.get("alley", false)) or alley:
		return
	for cut in city.alleys:
		if (cut as Rect2).grow(-10).has_point(pos):
			# Only the cut through the block counts, not its mouth on the road.
			for road_rect in city.roads:
				if (road_rect as Rect2).has_point(pos):
					return
			alley = true
			AudioDirector.play_sfx("sfx_notification_soft")
			return


func _check_dropoff() -> void:
	# Pulled up at the kerb beside the bay, stopped: that is parked. The
	# bay rect is grown to reach the lane the truck stops in.
	var bay: Rect2 = dropoff.get("bay", Rect2())
	var inside := bay.grow(LANE_OFFSET + 40.0).has_point(_art_center())
	backed_in = inside and at_end
	in_bay = inside
	var parked := inside and at_end and absf(speed) < 14.0 and vel.length() < 20.0
	if parked != at_dropoff:
		at_dropoff = parked
		if at_dropoff:
			AudioDirector.play_sfx("sfx_notification_soft")
			_set_action("Unload")
		else:
			_set_action("")


func _station() -> int:
	return clampi(int(GameState.stats.get("radio", 0)), 0, STATIONS.size() - 1)


func _radio_apply(announce: bool) -> void:
	var st: Dictionary = STATIONS[_station()]
	var track := str(st.get("track", ""))
	if track == "":
		AudioDirector.stop_music()
	else:
		AudioDirector.play_music(track)
	if radio_button:
		radio_button.text = "♪ %s" % st.get("name", "Radio")
	if announce:
		AudioDirector.play_sfx("sfx_l01_cb_static")
		if hint:
			hint.text = "%s: %s" % [st.get("name", "Radio"), st.get("ident", "")]


func _radio_next() -> void:
	GameState.stats["radio"] = (_station() + 1) % STATIONS.size()
	_radio_apply(true)


func _engine_pitch(at_speed: float) -> float:
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	return 0.85 + clampf(absf(at_speed) / maxf(1.0, max_speed), 0.0, 1.25) * 0.95


func _unhandled_input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_R:
		_radio_next()
		return
	if Controls.event_pressed(event, "horn"):
		_count_honk()
		AudioDirector.play_sfx("sfx_truck_horn")
		_wave_nearby()
		if str(course.get("id", "")) == "parade_detour" and state == "drive":
			_confetti()
		if _near_honk_ducks():
			duck_hold = 1.6
			AudioDirector.play_sfx("sfx_ducks_quack")
			AudioDirector.play_sfx("sfx_l05_duckling_peep")
	if Controls.event_pressed(event, "interact"):
		_interact()


func _interact() -> void:
	if state == "load":
		_begin_load()
	elif state == "drive" and at_dropoff:
		_begin_unload()


# ---------------------------------------------------------------- loading

func _begin_load() -> void:
	state = "load"
	_set_action("")
	_start_box_anim(true)
	AudioDirector.play_sfx("sfx_truck_ramp_in")
	AudioDirector.play_sfx("sfx_box_set_down")


func _begin_unload() -> void:
	state = "unload"
	at_dropoff = false
	_set_action("")
	vel = Vector2.ZERO
	speed = 0.0
	_start_box_anim(false)
	AudioDirector.play_sfx("sfx_truck_ramp_out")
	AudioDirector.play_sfx("sfx_box_set_down")


func _start_box_anim(loading: bool) -> void:
	box_anim.clear()
	for node in box_nodes:
		if is_instance_valid(node):
			node.queue_free()
	box_nodes.clear()
	anim_t = 0.0
	var place: Dictionary = pickup if loading else dropoff
	var door: Vector2 = place.get("door", pos)
	var side := str(place.get("side", "N"))
	var inward := _inward3(side)
	var curb := to_world(door, 0.0) - inward * 1.2
	var along := Vector3(-inward.z, 0, inward.x)
	var forward := _forward()
	var right := Vector3(-forward.z, 0, forward.x)
	for i in box_count:
		var stack := curb + along * (-float(box_count) * 0.35 + i * 0.7) + Vector3(0, 0.25, 0)
		var bed := to_world(pos, 1.0) - forward * (1.2 - float(i % 4) * 0.6) + right * (-0.5 + float(int(i / 4)) * 1.0)
		box_anim.append({"from": stack if loading else bed, "to": bed if loading else stack, "delay": i * 0.28, "done": false})
		var box := Props.mesh_box(Vector3(0.5, 0.5, 0.5), Color("C68B59"))
		box.position = stack if loading else bed
		add_child(box)
		box_nodes.append(box)
	box_anim.append({"loading": loading})


func _animate_boxes(delta: float) -> void:
	anim_t += delta
	var all_done := true
	var loading := true
	var index := 0
	for entry in box_anim:
		if entry.has("loading"):
			loading = bool(entry["loading"])
			continue
		var t := clampf((anim_t - float(entry["delay"])) / 0.5, 0.0, 1.0)
		if index < box_nodes.size() and is_instance_valid(box_nodes[index]):
			var lift := sin(t * PI) * 0.8
			box_nodes[index].position = (entry["from"] as Vector3).lerp(entry["to"], t) + Vector3(0, lift, 0)
		index += 1
		if t >= 1.0 and not bool(entry["done"]):
			entry["done"] = true
			AudioDirector.play_sfx("sfx_box_set_down", true)
		if t < 1.0:
			all_done = false
	if not all_done or box_anim.is_empty():
		return
	if anim_t < float(box_count) * 0.28 + 0.9:
		return
	box_anim.clear()
	if loading:
		# The boxes ride inside; the model's own cargo stays hidden behind the door.
		for node in box_nodes:
			if is_instance_valid(node):
				node.queue_free()
		box_nodes.clear()
		state = "drive"
		AudioDirector.play_sfx("sfx_truck_rev")
		AudioDirector.play_sfx("sfx_success_chime")
	else:
		_complete()


# ---------------------------------------------------------------- condition

func bump_points(speed_px: float) -> int:
	var slow := float(Tuning.get_value("box_condition.bump_min", 3))
	var fast := float(Tuning.get_value("box_condition.bump_max", 8))
	var meters := speed_px / PX
	var span := clampf(meters / 4.5, 0.0, 1.0)
	return int(round(lerpf(slow, fast, span)))


func _maybe_hard_brake(weather: String, before: float, delta: float) -> void:
	if weather != "rain" and weather != "snow":
		return
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	if before > max_speed * 0.55 and speed < before - 40.0 * delta:
		_apply_hit("brake", randi_range(int(Tuning.get_value("box_condition.hard_brake_min", 2)), int(Tuning.get_value("box_condition.hard_brake_max", 4))), 700)


func _contact(kind: String, overlapping: bool, amount: int) -> void:
	var was := bool(touching.get(kind, false))
	if not overlapping:
		if was:
			touching[kind] = false
			contact_ready[kind] = Time.get_ticks_msec() + 700
		return
	if was:
		return
	touching[kind] = true
	if contact_ready.has(kind) and Time.get_ticks_msec() < int(contact_ready[kind]):
		return
	if amount > 0:
		_apply_hit(kind, amount)
	elif kind == "gravel":
		AudioDirector.play_sfx("sfx_l05_gravel_crunch")


func _apply_hit(kind: String, amount: int, cooldown := 0) -> void:
	if amount <= 0:
		return
	var now := Time.get_ticks_msec()
	if cooldown > 0 and hazard_cd.has(kind) and now - int(hazard_cd[kind]) < cooldown:
		return
	if cooldown > 0:
		hazard_cd[kind] = now
	if GameState.perk("road_legs"):
		amount = maxi(1, amount - 1)
	condition = maxi(0, condition - amount)
	shake = 0.25
	if kind == "cone":
		AudioDirector.play_sfx("sfx_cone_hit")
	elif kind == "gravel":
		AudioDirector.play_sfx("sfx_l05_gravel_crunch")
		AudioDirector.play_sfx("sfx_box_rattle")
		AudioDirector.play_sfx("sfx_cardboard_bump")
	elif kind == "puddle":
		AudioDirector.play_sfx("sfx_l03_puddle_splash")
		AudioDirector.play_sfx("sfx_box_rattle")
	elif kind == "bump" or kind == "wobble":
		AudioDirector.play_sfx("sfx_speed_bump")
		AudioDirector.play_sfx("sfx_cardboard_bump")
		AudioDirector.play_sfx("sfx_box_rattle")
		if str(course.get("id", "")) == "theatre_rain":
			# The piano in the back plays itself on every bump.
			AudioDirector.play_sfx("sfx_success_chime")
			_say("The piano played itself. Again.", 3.0)
	else:
		AudioDirector.play_sfx("sfx_cardboard_bump")
		AudioDirector.play_sfx("sfx_box_rattle")


func _on_road(p: Vector2) -> bool:
	return city != null and city.on_road(p)


func _hazards() -> void:
	var active: Dictionary = {}
	var pond := str(course.get("id", "")) == "duck_pond"
	var list: Array = hazards if not hazards.is_empty() else course.get("hazards", [])
	for hazard in list:
		var kind := str(hazard.get("type", ""))
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		if kind == "wobble":
			if alley and not wobble_done and _hits_circle(at, 90.0):
				wobble_done = true
				_apply_hit("wobble", int(Tuning.get_value("box_condition.alley_wobble", 6)))
			continue
		if kind == "ducks":
			var zone := Rect2(at.x - float(hazard.get("w", 180)) * 0.5, at.y - float(hazard.get("h", 140)) * 0.5, float(hazard.get("w", 180)), float(hazard.get("h", 140)))
			if _hits_rect(zone):
				if bool(hazard.get("auto_stop", false)):
					# The ducks cross once: a short wait, then the road is theirs no more.
					if not bool(hazard.get("crossed", false)):
						hazard["crossed"] = true
						duck_hold = 2.2
					if not hazard_cd.has("quack"):
						hazard_cd["quack"] = Time.get_ticks_msec()
						AudioDirector.play_sfx("sfx_ducks_quack")
				elif pond:
					if not hazard_cd.has("peep"):
						hazard_cd["peep"] = Time.get_ticks_msec()
						AudioDirector.play_sfx("sfx_ducks_quack")
						AudioDirector.play_sfx("sfx_l05_duckling_peep")
					if speed > 70.0:
						near_miss = true
						duck_friend = false
				elif speed > 70.0:
					near_miss = true
					duck_friend = false
					active["ducks"] = int(Tuning.get_value("box_condition.bump_min", 3))
			continue
		var radius := float(hazard.get("r", 0))
		var hit := false
		if radius > 0.0:
			hit = _hits_circle(at, radius)
		else:
			var zone2 := Rect2(at.x - float(hazard.get("w", 40)) * 0.5, at.y - float(hazard.get("h", 40)) * 0.5, float(hazard.get("w", 40)), float(hazard.get("h", 40)))
			hit = _hits_rect(zone2)
		if not hit:
			continue
		if kind == "cone":
			# Roadworks: crawl past and the cones only scrape; take them at
			# pace and they go under the wheels.
			var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
			active["cone"] = int(Tuning.get_value("box_condition.collision", 10)) if absf(speed) > max_speed * 0.35 else 0
		elif kind == "gravel":
			active["gravel"] = 0 if pond else int(Tuning.get_value("box_condition.bump_min", 3))
		elif kind == "bump":
			active["bump"] = bump_points(absf(speed))
		else:
			var fast := absf(speed) > PX * 3.0
			active[kind] = int(Tuning.get_value("box_condition.bump_max", 8)) if fast else int(Tuning.get_value("box_condition.bump_min", 3))
	var kinds: Array = ["cone", "gravel", "bump", "puddle", "ducks"]
	for kind in active.keys():
		if not kinds.has(kind):
			kinds.append(str(kind))
	for kind in kinds:
		_contact(str(kind), active.has(kind), int(active.get(kind, 0)))


func _count_honk() -> void:
	# A friendly honk near someone on the pavement is worth a little at the end.
	if honk_cool > 0.0 or honks >= 5:
		return
	var truck_center := _art_center()
	for w in walkers:
		if (w["pos"] as Vector2).distance_to(truck_center) < 320.0:
			honks += 1
			honk_cool = 2.0
			return


func _near_honk_ducks() -> bool:
	for hazard in hazards:
		if str(hazard.get("type", "")) != "ducks" or not bool(hazard.get("honk", false)):
			continue
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		if pos.distance_to(at) < 280.0:
			return true
	return false


func _complete() -> void:
	if not running:
		return
	running = false
	state = "done"
	if bool(GameState.job.get("def", {}).get("duck_friend", false)):
		duck_friend = not near_miss
	var result := {
		"condition": condition,
		"alley": alley,
		"honks": honks,
		"backed_in": backed_in,
		"spotted": spotted,
		"busted": false,
		"duck_friend": duck_friend and not near_miss and bool(GameState.job.get("def", {}).get("duck_friend", false)),
		"near_miss": near_miss,
		"time": time_alive,
		"lighthouse_photo": photos.has("lighthouse_photo"),
	}
	AudioDirector.play_sfx("sfx_success_chime")
	emit_signal("finished", result)


# ---------------------------------------------------------------- minimap

func _draw_minimap() -> void:
	if city == null or minimap == null:
		return
	var size := minimap.size
	var bounds: Rect2 = city.bounds
	var k := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var offset := (size - bounds.size * k) * 0.5
	# Tarmac under everything, then each block with its pavement edge, so the
	# roads read as roads: parks green with trees, streets of houses as rows
	# of little roofs, the town blocks as their buildings.
	var night := str(course.get("weather", "clear")) == "night"
	minimap.draw_rect(Rect2(offset, bounds.size * k), Color("5E5A5C") if night else Color("8E8A86"))
	var map_rng := RandomNumberGenerator.new()
	map_rng.seed = 7
	for c in city.cols:
		for r in city.rows:
			var rect: Rect2 = city.block_rect(c, r)
			var box := Rect2(offset + rect.position * k, rect.size * k)
			var kind: String = city.block_kind(Vector2i(c, r))
			minimap.draw_rect(box, Color("D9D2C4"))
			var inner := box.grow(-maxf(1.5, city.sidewalk * k * 0.6))
			if kind == "park" or kind == "green":
				minimap.draw_rect(inner, Color("A9CB92"))
				for i in 7:
					var tree := inner.position + Vector2(map_rng.randf(), map_rng.randf()) * inner.size
					minimap.draw_circle(tree, 2.4, Color("6E9F5A"))
			elif kind == "houses":
				minimap.draw_rect(inner, Color("DCE6CB"))
				var along_x := inner.size.x >= inner.size.y
				var n := 5
				for i in n:
					var t := (float(i) + 0.5) / float(n)
					for side in [0.28, 0.72]:
						var at := inner.position + (Vector2(t, side) if along_x else Vector2(side, t)) * inner.size
						minimap.draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 6)), Color("C9A27E"))
			else:
				minimap.draw_rect(inner, Color("E9E1CF"))
	# Lane lines down the middle of every road.
	var dash := Color("F6EEDC", 0.8)
	for c in range(city.cols - 1):
		var a: Rect2 = city.block_rect(c, 0)
		var b: Rect2 = city.block_rect(c + 1, 0)
		var x := offset.x + (a.end.x + b.position.x) * 0.5 * k
		var y := offset.y
		while y < offset.y + bounds.size.y * k:
			minimap.draw_line(Vector2(x, y), Vector2(x, y + 5.0), dash, 1.0)
			y += 10.0
	for r in range(city.rows - 1):
		var a2: Rect2 = city.block_rect(0, r)
		var b2: Rect2 = city.block_rect(0, r + 1)
		var yy := offset.y + (a2.end.y + b2.position.y) * 0.5 * k
		var xx := offset.x
		while xx < offset.x + bounds.size.x * k:
			minimap.draw_line(Vector2(xx, yy), Vector2(xx + 5.0, yy), dash, 1.0)
			xx += 10.0
	# Buildings in their own colours; the house parcels already drew as gardens.
	for entry in city.buildings:
		if str(entry.get("kind", "town")) == "houses":
			continue
		var brect: Rect2 = entry.get("rect", Rect2())
		var bcol: Color = entry.get("color", Color("CFC3AE"))
		minimap.draw_rect(Rect2(offset + brect.position * k, brect.size * k).grow(-1.0), bcol.darkened(0.08))
	var water: Dictionary = city.pond()
	minimap.draw_circle(offset + (water.get("center", Vector2.ZERO) as Vector2) * k, float(water.get("radius", 100)) * k, Color("9FC4D6"))
	for cut in city.alleys:
		minimap.draw_rect(Rect2(offset + (cut as Rect2).position * k, (cut as Rect2).size * k), Color("8E6E5A"))
	# The shops and places as small dots, home as a house.
	var small_font := UIKit.body_bold()
	for id in city.places.keys():
		var place: Dictionary = city.places[id]
		var door: Vector2 = offset + (place.get("door", Vector2.ZERO) as Vector2) * k
		if str(id) == "garage":
			minimap.draw_colored_polygon(PackedVector2Array([door + Vector2(0, -7), door + Vector2(6, -1), door + Vector2(6, 5), door + Vector2(-6, 5), door + Vector2(-6, -1)]), UIKit.TERRA)
			minimap.draw_string(small_font, door + Vector2(8, 4), "HOME", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UIKit.DARK)
		else:
			minimap.draw_circle(door, 2.2, Color(UIKit.WOOD, 0.9))
	for shop in city.shops:
		var sdoor: Vector2 = offset + ((shop as Dictionary).get("door", Vector2.ZERO) as Vector2) * k
		minimap.draw_circle(sdoor, 1.8, Color(UIKit.BLUE, 0.8))
	# The route as a dotted line from where the truck is.
	if route.size() > 1 and state == "drive":
		var points := PackedVector2Array()
		points.append(pos)
		for i in range(clampi(route_index, 1, route.size() - 1), route.size()):
			points.append(route[i])
		var carry := 0.0
		for i in range(points.size() - 1):
			var a3 := points[i]
			var b3 := points[i + 1]
			var seg_len := a3.distance_to(b3)
			var t := carry
			while t < seg_len:
				var p := offset + a3.lerp(b3, t / maxf(seg_len, 0.001)) * k
				minimap.draw_circle(p, 2.6, Color("F6EEDC"))
				minimap.draw_circle(p, 1.8, UIKit.TERRA)
				t += 14.0
			carry = t - seg_len
	for car in cars:
		if bool(car.get("patrol", false)):
			var flash := fmod(patrol_flash, 0.6) < 0.3
			var size_r := 4.5 if str(car.get("mode", "")) == "pursuit" else 3.2
			minimap.draw_circle(offset + (car["pos"] as Vector2) * k, size_r, Color("FF3344") if flash else Color("3B6CFF"))
		else:
			minimap.draw_circle(offset + (car["pos"] as Vector2) * k, 2.0, Color(UIKit.DARK, 0.45))
	# Pins: a blue dot where the boxes came from, a green flag where they go.
	var pick: Rect2 = pickup.get("bay", Rect2())
	var drop: Rect2 = dropoff.get("bay", Rect2())
	var pick_at := offset + pick.get_center() * k
	minimap.draw_circle(pick_at, 6.0, Color("F6EEDC"))
	minimap.draw_circle(pick_at, 4.5, UIKit.BLUE)
	var drop_at := offset + drop.get_center() * k
	minimap.draw_circle(drop_at, 7.0, Color("F6EEDC"))
	minimap.draw_circle(drop_at, 5.5, UIKit.GREEN)
	minimap.draw_line(drop_at, drop_at + Vector2(0, -16), UIKit.DARK, 2.0)
	minimap.draw_colored_polygon(PackedVector2Array([drop_at + Vector2(0, -16), drop_at + Vector2(12, -12), drop_at + Vector2(0, -8)]), UIKit.GREEN)
	var font := UIKit.body_bold()
	var pick_name := str(pickup.get("name", "Load")).split(" ")[0]
	var drop_name := str(dropoff.get("name", "Drop")).split(" ")[0]
	minimap.draw_string(font, pick_at + Vector2(8, 5), "LOAD · %s" % pick_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.DARK)
	minimap.draw_string(font, drop_at + Vector2(8, 5), "DROP · %s" % drop_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.DARK)
	# The next turn on the route, ringed.
	if route.size() > 1 and state == "drive" and route_index < route.size():
		var turn: Vector2 = offset + route[route_index] * k
		minimap.draw_arc(turn, 6.0, 0.0, TAU, 20, UIKit.TERRA, 2.0, true)
	# A scale bar: fifty metres.
	var bar_len := 50.0 * PX * k
	var bar_at := offset + Vector2(6.0, bounds.size.y * k - 8.0)
	minimap.draw_line(bar_at, bar_at + Vector2(bar_len, 0), UIKit.DARK, 2.0)
	minimap.draw_line(bar_at, bar_at + Vector2(0, -4), UIKit.DARK, 2.0)
	minimap.draw_line(bar_at + Vector2(bar_len, 0), bar_at + Vector2(bar_len, -4), UIKit.DARK, 2.0)
	minimap.draw_string(font, bar_at + Vector2(bar_len + 4, 3), "50 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UIKit.DARK)
	# The truck as a wedge pointing where it faces, with a soft shadow.
	var at := offset + pos * k
	var fwd := Vector2.RIGHT.rotated(heading)
	var side := Vector2(-fwd.y, fwd.x)
	var wedge := PackedVector2Array([at + fwd * 9.0, at - fwd * 5.0 + side * 5.5, at - fwd * 5.0 - side * 5.5])
	minimap.draw_colored_polygon(PackedVector2Array([wedge[0] + Vector2(1, 2), wedge[1] + Vector2(1, 2), wedge[2] + Vector2(1, 2)]), Color(UIKit.DARK, 0.25))
	minimap.draw_colored_polygon(wedge, UIKit.TERRA)
	minimap.draw_polyline(PackedVector2Array([wedge[0], wedge[1], wedge[2], wedge[0]]), UIKit.DARK, 1.5, true)
	# A compass rose in the corner.
	var corner := offset + Vector2(bounds.size.x * k - 14.0, 14.0)
	minimap.draw_circle(corner, 10.0, Color("F6EEDC"))
	minimap.draw_colored_polygon(PackedVector2Array([corner + Vector2(0, -8), corner + Vector2(4, 2), corner + Vector2(-4, 2)]), UIKit.DARK)


func _hazard_art(kind: String) -> String:
	match kind:
		"cone":
			return "cone"
		"bump":
			return "speed_bump"
		"puddle":
			return "puddle"
		"ducks":
			return "duck"
	return ""


# ---------------------------------------------------------------- geometry

func _rect(value) -> Rect2:
	if typeof(value) != TYPE_ARRAY or value.size() < 4:
		return Rect2()
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))


func _art_center() -> Vector2:
	var local := Vector2(ART_X + ART_W * 0.5 - FRAME_W * 0.5, ART_Y + ART_H * 0.5 - FRAME_H * 0.5)
	return pos + local.rotated(heading)


func _truck_corners() -> Array[Vector2]:
	var center := _art_center()
	var forward := Vector2.RIGHT.rotated(heading)
	var side := Vector2.DOWN.rotated(heading)
	var hx := ART_W * 0.5
	var hy := ART_H * 0.5
	return [
		center + forward * hx + side * hy,
		center + forward * hx - side * hy,
		center - forward * hx + side * hy,
		center - forward * hx - side * hy,
	]


func _hits_circle(at: Vector2, radius: float) -> bool:
	var local := (at - _art_center()).rotated(-heading)
	var dx := maxf(absf(local.x) - ART_W * 0.5, 0.0)
	var dy := maxf(absf(local.y) - ART_H * 0.5, 0.0)
	return dx * dx + dy * dy <= radius * radius


func _hits_rect(zone: Rect2) -> bool:
	if zone.has_point(_art_center()):
		return true
	for corner in _truck_corners():
		if zone.has_point(corner):
			return true
	for corner in [zone.position, Vector2(zone.end.x, zone.position.y), zone.end, Vector2(zone.position.x, zone.end.y)]:
		if _hits_circle(corner, 0.0):
			return true
	return false
