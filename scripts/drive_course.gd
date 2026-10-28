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
var meter_fill: StyleBoxFlat


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
	_resolve_hazards()
	_resolve_turnouts()
	_lights()
	world = Node3D.new()
	world.name = "Town"
	add_child(world)
	_build_town()
	_build_truck()
	_spawn_traffic()
	_build_route_marks()
	cam = Camera3D.new()
	cam.name = "ChaseCamera"
	cam.fov = 68.0
	cam.near = 0.2
	cam.far = 260.0
	add_child(cam)
	cam.current = true
	_snap_camera()
	_hud()
	UIKit.show_level_beat(self, GameState.present_current_slice_level(), true)
	var weather := str(course.get("weather", "clear"))
	var air := str(course.get("ambience", ""))
	if air == "" and str(course.get("weather", "clear")) == "night":
		air = "amb_l13_night_loop"
	AudioDirector.play_bed(str(course.get("music", "music_driving")), air)
	_radio_apply(false)
	if weather == "rain":
		_make_rain()
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
		if (spot["rect"] as Rect2).has_point(pos):
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
			var at: Vector2 = spot.get("pos", Vector2.ZERO) + side * float(hazard.get("lane", 0)) * city.road * 0.25
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
	else:
		sky_material.sky_top_color = Color("8FBDE0")
		sky_material.sky_horizon_color = Color("E6EEF2")
		sky_material.ground_bottom_color = Color("8FB573")
		sky_material.ground_horizon_color = Color("C9C2B5")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.fog_enabled = true
	environment.fog_light_color = Color("C9D3DA") if weather != "rain" else Color("8E919B")
	environment.fog_density = 0.004 if weather != "rain" else 0.011
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
	sun.light_color = Color("FFE3C0") if weather != "rain" else Color("C9CCD6")
	sun.light_energy = 0.95 if weather != "rain" else 0.6
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
	_slab(Vector3(size.x + 80, 0.1, size.z + 80), Vector3(size.x * 0.5, -0.1, size.z * 0.5), GRASS)
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
				_slab(Vector3(1.5, 0.01, 0.12), Vector3(x + 0.75, 0.0, z), LANE_LINE)
				x += 3.0
		else:
			var x2 := (r.position.x + r.size.x * 0.5) / PX
			var z2 := (r.position.y + 40.0) / PX
			while z2 < (r.end.y - 40.0) / PX:
				_slab(Vector3(0.12, 0.01, 1.5), Vector3(x2, 0.0, z2 + 0.75), LANE_LINE)
				z2 += 3.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "")) + "town")
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
	for entry in city.buildings:
		_build_building(entry, rng)
	for cut in city.alleys:
		var cut_rect: Rect2 = cut
		_slab(Vector3(cut_rect.size.x / PX, 0.03, cut_rect.size.y / PX), rect_center(cut_rect, 0.0), Color("6B4A3A"))
		var alley_sign := _sign_text("Alley", rect_center(Rect2(cut_rect.position, Vector2(minf(cut_rect.size.x, 72.0), 40)), 3.2), Color("F4E9D8"))
		alley_sign.font_size = 90
	for shop in city.shops:
		_build_sign(shop, Color("C68B59"))
	for id in city.places.keys():
		var place: Dictionary = city.places[id]
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
			if (c + r) % 2 == 0 and not houses_block:
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
				van.position = to_world(Vector2(rect.position.x + rect.size.x * rng.randf_range(0.2, 0.5), rect.position.y - city.road * 0.25))
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


const FACADES: Array = ["C9A27E", "B5705A", "E3D9C6", "9C8F85", "A8B5BE", "D6B894", "8E6E5A", "D8B4A0"]


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


func _multimesh(size: Vector3, color: Color, transforms: Array) -> void:
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
	node.material_override = Props.mat(color)
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
		var label := _sign_text(text, door + inward * 0.3 + Vector3(0, 3.3, 0), Color("3E3A4F"))
		label.font_size = 72


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
	arrow = Outdoors._cone(0.45, 0.9, UIKit.TERRA)
	arrow.name = "RouteArrow"
	arrow.rotation.x = PI * 0.5
	add_child(arrow)


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
		var steps := int(a.distance_to(b) / 64.0)
		for k in range(1, steps):
			var dot := Outdoors._disc(0.22, Color(UIKit.TERRA, 0.9))
			dot.position = to_world(a.lerp(b, float(k) / float(steps)), 0.03)
			dot.set_meta("leg", i)
			marks.add_child(dot)
			route_dots.append(dot)


func _make_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 500
	rain.lifetime = 1.4
	rain.preprocess = 1.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(18, 1, 18)
	rain.direction = Vector3(0.1, -1, 0)
	rain.spread = 4
	rain.gravity = Vector3(0, -2, 0)
	rain.initial_velocity_min = 9.0
	rain.initial_velocity_max = 12.0
	rain.scale_amount_min = 0.03
	rain.scale_amount_max = 0.05
	rain.mesh = BoxMesh.new()
	(rain.mesh as BoxMesh).size = Vector3(0.6, 6.0, 0.6)
	rain.material_override = Props.mat(Color(0.8, 0.86, 0.95, 0.5))
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
	if str(course.get("weather", "clear")) == "night":
		spot_label = UIKit.label("Patrols out. Keep it slow near them.", 24, UIKit.LOSS, "small", false)
		spot_label.name = "SpotLabel"
		spot_label.position = Vector2(20, 118)
		spot_label.custom_minimum_size = Vector2(500, 36)
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
	UIKit.pin_top_right(name_bar, -520, 16, -16, 84)
	var name_label := UIKit.label(str(course.get("title", "Drive")), 28, UIKit.CREAM_CARD, "title", false)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_bar.add_child(name_label)
	UIKit.fill(name_label, 12, 8, 12, 8)
	radio_button = UIKit.button("♪ Radio", UIKit.NIGHT)
	radio_button.name = "RadioButton"
	radio_button.custom_minimum_size = Vector2(300, 52)
	radio_button.pressed.connect(_radio_next)
	hud_root.add_child(radio_button)
	UIKit.pin_top_right(radio_button, -332, 476, -16, 528)
	radio_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	UIKit.link_focus([radio_button])
	# Minimap under the title: the whole town, the route, the truck.
	var map_card := Panel.new()
	map_card.name = "Minimap"
	map_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_card.add_theme_stylebox_override("panel", UIKit.style(Color(UIKit.CREAM_CARD, 0.94), 16))
	hud_root.add_child(map_card)
	UIKit.pin_top_right(map_card, -456, 96, -16, 456)
	minimap = Control.new()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_card.add_child(minimap)
	UIKit.fill(minimap, 12, 12, 12, 52)
	minimap.draw.connect(_draw_minimap)
	distance_label = UIKit.label("", 24, UIKit.DARK, "small", false)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_card.add_child(distance_label)
	distance_label.layout_mode = 1
	distance_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	distance_label.offset_top = -44
	distance_label.offset_bottom = -8
	distance_label.offset_left = 12
	distance_label.offset_right = -12


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
			if at_dropoff:
				line = "Backed into the bay. Hand the boxes over."
			elif in_bay and not backed_in:
				line = "Nose-first won't do. Pull out and back the truck into the bay."
			else:
				line = "Follow the arrow and the dots. Back into the bay at the end."
				if bool(course.get("alley", false)):
					line += " The alley is shorter, but bumpy."
				elif str(course.get("id", "")) == "duck_pond":
					line += " Honk and the ducks hurry."
		"unload":
			line = "Unloading at %s." % dest
		_:
			line = "Done."
	if objective:
		match state:
			"load":
				objective.text = "Load up at %s" % pickup.get("name", "the curb")
			"drive":
				objective.text = "Backed in" if at_dropoff else ("Back into the bay" if in_bay else "Deliver to %s" % dest)
			"unload":
				objective.text = "Unloading"
			_:
				objective.text = "Delivered"
	_sync_chips()
	if weather == "rain" and state == "load":
		line += " Rain makes the stop longer."
	return line


func _sync_chips() -> void:
	if chips_slot == null:
		return
	var items: Array = []
	if state == "load":
		items = [[Controls.describe_key("interact"), "load up"]]
	elif state == "drive" and at_dropoff:
		items = [[Controls.describe_key("interact"), "unload"]]
	elif state == "drive":
		items = [["W A S D", "drive"], [Controls.describe_key("handbrake"), "handbrake"], [Controls.describe_key("horn"), "honk"]]
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
	meter_label.text = "%d  %s" % [condition, stamp]
	hint.text = _hint_text()
	if distance_label:
		var left := _route_left()
		distance_label.text = "%d m to go" % int(round(left / PX)) if state == "drive" else "Boxes on the curb"
	if minimap:
		minimap.queue_redraw()


func _route_left() -> float:
	if route.size() < 2:
		return 0.0
	var idx := clampi(route_index, 1, route.size() - 1)
	var total := pos.distance_to(route[idx])
	for i in range(idx + 1, route.size()):
		total += route[i - 1].distance_to(route[i])
	return total


func _place_truck(delta: float) -> void:
	truck.position = to_world(pos)
	truck.rotation.y = -heading
	# Lean into corners and rock on a hit.
	var lean := clampf(-skid / 160.0, -0.08, 0.08)
	truck.rotation.x = lerpf(truck.rotation.x, lean, delta * 6.0)
	if shake > 0.0 and SaveManager.shake:
		shake -= delta
		truck.position += Vector3(randf_range(-0.05, 0.05), 0.0, randf_range(-0.05, 0.05))
		truck.rotation.z = randf_range(-0.03, 0.03)
	else:
		truck.rotation.z = lerpf(truck.rotation.z, 0.0, delta * 8.0)


func _update_camera(delta: float) -> void:
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var forward := _forward()
	var truck_at := to_world(pos)
	var back := 11.5 + 3.0 * clampf(absf(speed) / max_speed, 0.0, 1.0)
	var goal := truck_at - forward * back + Vector3(0, 6.4, 0)
	var look := truck_at + forward * (5.0 + 7.0 * clampf(speed / max_speed, -0.3, 1.0)) + Vector3(0, 1.0, 0)
	var k := clampf(delta * 4.5, 0.0, 1.0)
	cam.position = cam.position.lerp(goal, k)
	cam_look = cam_look.lerp(look, clampf(delta * 6.0, 0.0, 1.0))
	cam.look_at(cam_look, Vector3.UP)


func _snap_camera() -> void:
	var forward := _forward()
	var truck_at := to_world(pos)
	cam.position = truck_at - forward * 11.5 + Vector3(0, 6.4, 0)
	cam_look = truck_at + forward * 5.0 + Vector3(0, 1.0, 0)
	cam.look_at(cam_look, Vector3.UP)


func _update_marks() -> void:
	if arrow == null:
		return
	if state != "drive" or route.size() < 2:
		arrow.visible = false
	else:
		arrow.visible = true
		var goal := route[mini(route_index, route.size() - 1)]
		if route_index < route.size() - 1 and pos.distance_to(goal) < 90.0:
			route_index += 1
			goal = route[route_index]
		var dir := (goal - pos).normalized()
		arrow.position = to_world(pos, 3.8 + sin(pulse * 3.0) * 0.15) + Vector3(dir.x, 0, dir.y) * 1.5
		# The cone's axis is +Y; look_at points -Z at the target, then +Y is swung onto -Z.
		arrow.look_at(arrow.position + Vector3(dir.x, 0, dir.y), Vector3.UP)
		arrow.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
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
	if weather == "rain":
		brake *= 1.0 - float(Tuning.get_value("drive.rain_brake_penalty", 0.15))
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var reverse_max := float(Tuning.get_value("drive.reverse_mps", 1.8)) * PX
	var turn := float(Tuning.get_value("drive.turn_rate", 2.2))
	var grip := float(Tuning.get_value("drive.grip", 8.0))
	if weather == "rain":
		grip = float(Tuning.get_value("drive.grip_rain", 4.5))
	var handbrake: bool = Controls.held("handbrake")
	if handbrake:
		grip = float(Tuning.get_value("drive.grip_handbrake", 1.5))
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
	if throttle > 0.0 and speed < max_speed * 0.25 and rev_cd <= 0.0:
		AudioDirector.play_sfx("sfx_truck_rev")
		rev_cd = 1.6
	var off_road: bool = not city.on_road(pos) and not _in_bay(pos)
	var cap := max_speed * (0.45 if off_road else 1.0)
	# Traffic ahead in our lane sets the pace: ease off and sit behind it.
	var lead := _lead_car(forward)
	if not lead.is_empty():
		var gap := float(lead.get("gap", 999.0))
		var lead_speed := maxf(0.0, float(lead.get("speed", 0.0)))
		var follow_cap := lead_speed + maxf(0.0, gap - FOLLOW_GAP) * 2.5
		cap = minf(cap, follow_cap)
		if speed > cap:
			vel = vel.move_toward(forward * cap, brake * 1.5 * delta)
	if duck_hold > 0.0:
		duck_hold -= delta
		cap = minf(cap, 18.0)
	if handbrake:
		vel = vel.move_toward(Vector2.ZERO, brake * 1.2 * delta)
	elif throttle > 0.0:
		if speed < -5.0:
			var before := speed
			vel = vel.move_toward(Vector2.ZERO, brake * delta)
			_maybe_hard_brake(weather, absf(before), delta)
		elif speed < cap:
			# Punchy off the line, tapering as it winds up: a gear-step feel.
			vel += forward * accel * delta * throttle * (1.35 - 0.6 * clampf(speed / max_speed, 0.0, 1.0))
	elif throttle < 0.0:
		if speed > 5.0:
			var before2 := speed
			vel = vel.move_toward(Vector2.ZERO, brake * delta)
			_maybe_hard_brake(weather, before2, delta)
		elif speed > -reverse_max:
			vel -= forward * accel * 0.7 * delta
	else:
		vel = vel.move_toward(Vector2.ZERO, accel * 0.45 * delta)
	# Tyres: bleed off the sideways part of the motion. Less in rain, hardly at all on the handbrake.
	var lateral := vel - forward * vel.dot(forward)
	vel -= lateral * clampf(grip * delta, 0.0, 1.0)
	skid = lateral.length() * (1.0 if lateral.cross(forward) > 0.0 else -1.0)
	if vel.length() > cap:
		vel = vel.normalized() * cap
	speed = vel.dot(forward)
	var steer: float = Controls.axis("steer_left", "steer_right")
	if absf(speed) > 10.0:
		var sign := 1.0 if speed >= 0.0 else -1.0
		heading += steer * turn * delta * clampf(absf(speed) / max_speed, 0.35, 1.0) * sign
	if absf(spin) > 0.001:
		heading += spin * delta
		spin = move_toward(spin, 0.0, 4.5 * delta)
	pos += vel * delta
	_collide_buildings()
	var inside: Rect2 = (city.bounds as Rect2).grow(-60.0)
	pos = Vector2(clampf(pos.x, inside.position.x, inside.end.x), clampf(pos.y, inside.position.y, inside.end.y))
	var edge := int(Tuning.get_value("box_condition.collision", 10))
	_contact("offroad", off_road and absf(speed) > 80.0, edge)


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
		vel += normal * into * 1.3
		vel *= 0.55
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
			spot_label = UIKit.label("Patrols out. Keep it slow near them.", 24, UIKit.LOSS, "small", false)
			spot_label.name = "SpotLabel"
			spot_label.position = Vector2(20, 118)
			spot_label.custom_minimum_size = Vector2(500, 36)
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
			spot_label.text = "Spotted %d time%s" % [spotted, "" if spotted == 1 else "s"] if spotted > 0 else "Patrols out. Keep it slow near them."
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
			vel += side * -120.0
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
			alley = true
			AudioDirector.play_sfx("sfx_notification_soft")
			return


func _check_dropoff() -> void:
	var bay: Rect2 = dropoff.get("bay", Rect2())
	var inside := bay.has_point(_art_center())
	# A borrowed truck is backed into the bay: coming in nose-first does not
	# count until you reverse. Reversing anywhere inside the bay sets it.
	if inside and speed < -3.0:
		backed_in = true
	if not inside:
		backed_in = false
	in_bay = inside
	var parked := inside and backed_in and absf(speed) < 14.0 and vel.length() < 20.0
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
	if weather != "rain":
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
					duck_hold = 1.4
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
			active["cone"] = int(Tuning.get_value("box_condition.collision", 10))
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
