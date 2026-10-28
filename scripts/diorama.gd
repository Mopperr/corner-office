extends Node3D

const PlaceLib = preload("res://scripts/placement.gd")
const MenuLayout = preload("res://scripts/menu_layout.gd")
const SupportMath = preload("res://scripts/stacking/support.gd")
const StackItemLib = preload("res://scripts/stacking/stack_item.gd")
const StackRoomLib = preload("res://scripts/stacking/stack_room.gd")
const Graphics = preload("res://scripts/settings_manager.gd")
const Tuning = preload("res://scripts/tuning.gd")
const Catalog = preload("res://scripts/catalog.gd")
const UIKit = preload("res://scripts/ui_kit.gd")
const Props = preload("res://scripts/props.gd")
const Controls = preload("res://scripts/control_map.gd")
const StackGoals = preload("res://scripts/stack_goals.gd")
const ShopLayout = preload("res://scripts/shop_layout.gd")
const Outdoors = preload("res://scripts/outdoors.gd")
const GarageDressing = preload("res://scripts/garage_dressing.gd")
const Workshop = preload("res://scripts/workshop.gd")
const Crime = preload("res://scripts/crime.gd")
const YardShop = preload("res://scripts/yard_shop.gd")
const VenueDressing = preload("res://scripts/venue_dressing.gd")
const ClientPartyLib = preload("res://scripts/client_party.gd")

const MENU_YAW_DEG := 45.0
const MENU_PITCH_DEG := -30.0
const MENU_ORTHO_SIZE := 7.2
const MENU_DRIFT_SEC := 24.0

static var _motion_cached := false
static var _motion_reduced := false

signal open_computer
signal open_map
signal request_drive
signal request_results
signal request_rebuild

var cam: Camera3D
var items_root: Node3D
var venue: Dictionary = {}
var nodes_by_uid: Dictionary = {}
var held_uid := ""
var held_source := ""
var held_rot := 0.0
var ghost: Node3D
var garage_door: Node3D
var slats: Array = []
var truck_root: Node3D
var cargo_boxes: Node3D
var back_door: Node3D
var door_player: AnimationPlayer
var truck_door_open := false
var selected_box := -1
var hint: Label
var status: Label
var cat_rig: Node3D
var cat_player: AnimationPlayer
var cat_base_y := 0.0
var cat_time := 0.0
var cat_stretching := false
var stretch_in := 4.0
var toast: Label
var toast_time := 0.0
var floor_slots := 4
var slot_count := 8
var carried: Dictionary = {}
var delivery_root: Node3D
var visitor_wait := 5.0
var customers: Array = []
var customer_serial := 0
var shop_sign: Node3D
var yard_shop: Node3D
var street: Array = []
var browser: Dictionary = {}
var browser_wait := 18.0
var ambient_time := 0.0
var cars: Array = []
var car_wait := 12.0
var chatter: Dictionary = {}
var parking_used: Dictionary = {}
var courier_seen: Dictionary = {}
var unbox_uid := ""
var hover_root: Node3D
var backdrop := false
var menu_look := Vector3(3.15, 0.9, 2.85)
var show_focus := Vector3.ZERO
var show_cam := Vector3.ZERO
var show_basis := Basis.IDENTITY
var show_ready := false
var drift_t := 0.0
var settling := false
var stack_room
var _settle_uid := ""
var hud_only := false
var _goal_pip := 0.0
var view_quadrant := 0
var view_zoom := 1.0
var footprint: MeshInstance3D
var goals_panel: Control
var goals_column: VBoxContainer
var _goals_key := ""
var objective: Label
var chips_slot: Control
var _chips_key := ""
var toast_name: Label
var toast_bar: Control
var _markers_key := ""


func _ready() -> void:
	if hud_only:
		_build_hud()
		return
	items_root = Node3D.new()
	items_root.name = "Items"
	add_child(items_root)
	_world()
	if backdrop:
		_build_showroom()
		return
	_build_venue()
	for box_id in GameState.job.get("carried", []):
		carried[int(box_id)] = true
	_refresh_items()
	_build_hud()
	UIKit.show_level_beat(self, GameState.present_current_slice_level())
	if garage_door:
		var tw := create_tween()
		tw.tween_method(_set_garage_y, 0.0, float(Tuning.get_value("garage_door_open_y", 2.1)), 1.15)
		AudioDirector.play_sfx("sfx_l01_garage_door_roll")
	_music()
	if GameState.mode == "truck":
		AudioDirector.start_loop("sfx_truck_idle_loop")
		_open_truck_door(true)
	if not GameState.held_cleared.is_connected(_on_held_cleared):
		GameState.held_cleared.connect(_on_held_cleared)


func _on_held_cleared() -> void:
	held_uid = ""
	held_source = ""
	if ghost:
		ghost.visible = false
	_refresh_items()
	_maybe_live()
	_maybe_job_done()


func _exit_tree() -> void:
	AudioDirector.stop_level()


func _music() -> void:
	var track := str(venue.get("music", "music_office_build"))
	var bed := str(venue.get("ambience", ""))
	AudioDirector.play_bed(track, bed)
	_level_cues()


func _level_cues() -> void:
	var id := str(venue.get("id", ""))
	if id == "garage" and GameState.mode != "truck":
		AudioDirector.start_loop("sfx_l01_fridge_hum_loop")
		AudioDirector.play_sfx("sfx_l01_marker_squeak")
	elif id == "cafe":
		AudioDirector.start_loop("sfx_cat_purr_loop")
		AudioDirector.play_sfx("sfx_l02_door_wind_chime")
		AudioDirector.play_sfx("sfx_l02_espresso_hiss")
		AudioDirector.play_sfx("sfx_l02_cup_clink")
	elif id == "train":
		AudioDirector.play_sfx("sfx_l04_cuckoo")
		AudioDirector.play_sfx("sfx_l04_track_click")
	elif id == "bakery":
		AudioDirector.play_sfx("sfx_l06_bakery_bell")
		AudioDirector.play_sfx("sfx_l06_stair_creak")
		AudioDirector.play_sfx("sfx_l06_pigeon_coo")


func _world() -> void:
	var env := WorldEnvironment.new()
	env.name = "World"
	var world: Environment = Graphics.load_environment(SaveManager.graphics_quality).duplicate()
	if backdrop:
		world.background_color = UIKit.CREAM
	env.environment = world
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_color = Color("FFE3C0")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.light_angular_distance = 1.75
	sun.shadow_blur = 1.5
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 25.0
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-35, -145, 0)
	fill.light_color = Color("A9C4D4")
	fill.light_energy = 0.2
	fill.light_specular = 0.0
	fill.shadow_enabled = false
	add_child(fill)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.current = true
	add_child(cam)
	if not get_viewport().size_changed.is_connected(_frame_camera):
		get_viewport().size_changed.connect(_frame_camera)


func _venue_id() -> String:
	match GameState.mode:
		"job_pack", "job_unpack":
			return str(GameState.job.get("def", {}).get("venue", "cafe"))
		"truck":
			return "garage"
		_:
			return GameState.office_id if ItemDB.venues().has(GameState.office_id) else "garage"


var theme: Dictionary = {}


func _build_venue() -> void:
	var id := _venue_id()
	venue = ItemDB.venues().get(id, ItemDB.venues().get("garage", {})).duplicate(true)
	venue["id"] = id
	theme = Catalog.theme(str(venue.get("theme", id)))
	home_floor = int(GameState.job.get("floor", 0)) if _is_home() else 0
	Props.lamp_scale = float(Catalog.day_phase_mults(GameState.day_phase()).get("lamps", 1.0))
	if GameState.mode == "truck":
		_build_truck_stage()
		return
	_build_shell()
	_theme_lights()
	_spawn_player()
	_spawn_party()
	_ensure_stack_room()
	_frame_camera()
	_dress()
	Outdoors.build(self, venue)
	_sync_yard_shop()
	_spawn_street()
	_spawn_pet()


func _spawn_pet() -> void:
	# Pickle, once adopted: trots after Dana round the office and the jobs.
	var LifeLib = load("res://scripts/life.gd")
	if backdrop or player == null or str(LifeLib.pet()) != "dog" or not (GameState.mode in ["office", "job_pack", "job_unpack"]):
		return
	var dog := _make_dog(Color("B98A5A"))
	dog.name = "Pickle"
	dog.position = player.position + Vector3(-0.7, 0.0, 0.35)
	add_child(dog)
	street.append({"node": dog, "dir": 1.0, "speed": 1.0, "phase": randf() * TAU, "pause": 0.0, "cx": 0.0, "dog": true, "owner": player, "pet": true})


func _wall_color() -> Color:
	return Color(str(theme.get("wall", "8E8276")))


func _trim_color() -> Color:
	return Color(str(theme.get("trim", "7A5C40")))


func _floor_color() -> Color:
	return Color(str(theme.get("floor", "8E8276")))


func _theme_lights() -> void:
	# The room's own light: a dimmer, tinted sun, a key light through the
	# window wall, and a low mood glow in the room's accent. Lamps get
	# brighter and the sun warmer as the day goes on.
	var phase := Catalog.day_phase_mults(GameState.day_phase())
	var sun := find_child("Sun", true, false) as DirectionalLight3D
	if sun:
		sun.light_color = Color(str(theme.get("sun", "FFE3C0"))).lerp(Color(str(phase.get("sun_tint", "FFE3C0"))), 0.5)
		sun.light_energy = float(theme.get("sun_energy", 0.6)) * float(phase.get("sun", 1.0))
	var fill := find_child("Fill", true, false) as DirectionalLight3D
	if fill:
		fill.light_color = Color(str(theme.get("fill", "A9C4D4")))
		fill.light_energy = float(theme.get("fill_energy", 0.16))
	var world := find_child("World", true, false) as WorldEnvironment
	if world and world.environment and not backdrop:
		world.environment.ambient_light_color = Color(str(theme.get("ambient", "EAD9C6")))
		world.environment.ambient_light_energy = float(theme.get("ambient_energy", 0.22)) * float(phase.get("ambient", 1.0))
	if backdrop:
		return
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	var key := SpotLight3D.new()
	key.name = "RoomKey"
	key.position = Vector3(x + 0.35, 2.45, z + 2.0)
	key.light_color = Color(str(theme.get("key", "FFD2A1")))
	key.light_energy = float(theme.get("key_energy", 1.3))
	key.spot_range = w + 5.0
	key.spot_angle = 62.0
	key.spot_angle_attenuation = 0.8
	key.shadow_enabled = true
	key.shadow_blur = 2.0
	add_child(key)
	key.look_at(Vector3(x + w * 0.55, 0.0, z + d * 0.5))
	var mood := OmniLight3D.new()
	mood.name = "RoomMood"
	mood.position = Vector3(x + w * 0.5, 1.4, z + d * 0.5)
	mood.light_color = Color(str(theme.get("mood", "FFB36B")))
	mood.light_energy = float(theme.get("mood_energy", 0.25)) * float(phase.get("mood", 1.0))
	mood.omni_range = maxf(w, d) * 0.9
	mood.shadow_enabled = false
	add_child(mood)


func _frame_camera() -> void:
	if backdrop:
		_frame_menu_camera()
		return
	if cam == null or venue.is_empty() or GameState.mode == "truck":
		return
	var origin := Vector3(float(venue.get("x", 0.0)), 0.0, float(venue.get("z", 0.0)))
	var width := float(venue.get("w", 6.0))
	var depth := float(venue.get("d", 8.0))
	# The look-at leans a little toward the camera, so the near edge of the
	# floor clears the hint bar at the bottom of the screen.
	var center := origin + Vector3(width * 0.5 + 0.4, 0.9, depth * 0.5 + 0.4)
	cam.attributes = null
	cam.size = maxf(width, depth) * 1.12 * view_zoom
	cam.position = center + Vector3(8.2, 9.0, 8.0).rotated(Vector3.UP, view_quadrant * PI * 0.5)
	cam.look_at(center, Vector3.UP)


func _side_of(along_x: bool, fixed: float) -> String:
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	if along_x:
		return "N" if absf(fixed - z) < 0.01 else "S"
	return "W" if absf(fixed - x) < 0.01 else "E"


func _hidden_sides() -> Array:
	# The two walls nearest the camera are cut away so you can see in.
	# The camera offset (8.2, 9, 8) turns +90 deg about Y each step: (+x,+z) -> (+x,-z) -> (-x,-z) -> (-x,+z).
	match posmod(view_quadrant, 4):
		1:
			return ["N", "E"]
		2:
			return ["N", "W"]
		3:
			return ["S", "W"]
	return ["S", "E"]


func rotate_view(steps: int) -> void:
	if backdrop or venue.is_empty() or GameState.mode == "truck":
		return
	view_quadrant = posmod(view_quadrant + steps, 4)
	var hidden := _hidden_sides()
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	for node in get_children():
		if not (node is Node3D):
			continue
		var hide := false
		if node.has_meta("shell_side"):
			hide = str(node.get_meta("shell_side")) in hidden
		elif node.has_meta("shell_corner"):
			var at: Vector2 = node.get_meta("corner_at")
			var sides: Array = ["N" if absf(at.y - z) < 0.01 else "S", "W" if absf(at.x - x) < 0.01 else "E"]
			hide = sides[0] in hidden and sides[1] in hidden
		else:
			continue
		(node as Node3D).visible = not hide
		if hide:
			node.add_to_group("cutaway_shell")
		elif node.is_in_group("cutaway_shell"):
			node.remove_from_group("cutaway_shell")
	var origin := Vector3(x, 0.0, z)
	var center := origin + Vector3(w * 0.5 + 0.4, 0.9, d * 0.5 + 0.4)
	var goal := center + Vector3(8.2, 9.0, 8.0).rotated(Vector3.UP, view_quadrant * PI * 0.5)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float):
		cam.position = cam.position.lerp(goal, t)
		cam.look_at(center, Vector3.UP)
	, 0.0, 1.0, 0.35)
	AudioDirector.play_sfx("sfx_ui_click")
	_markers_key = ""


func zoom_view(delta_zoom: float) -> void:
	if backdrop or venue.is_empty() or GameState.mode == "truck":
		return
	view_zoom = clampf(view_zoom + delta_zoom, 0.6, 1.4)
	_frame_camera()


func _fill_floor(x: float, z: float, w: float, d: float) -> void:
	var cz := z + 1.0
	while cz < z + d - 0.01:
		var cx := x + 1.0
		while cx < x + w - 0.01:
			var tile := Props.model(_piece("floor2"))
			if tile:
				tile.position = Vector3(cx, 0, cz)
				Props.restyle_architecture(tile, _floor_color(), _trim_color())
				Props.prepare(tile)
				add_child(tile)
			cx += 2.0
		cz += 2.0
	# 1 m scraps along an odd edge. The 2 m tiles already cover the rest, so those cells are not instantiated.
	if int(w) % 2 == 1 or int(d) % 2 == 1:
		var zz := z + 0.5
		while zz < z + d:
			var xx := x + 0.5
			while xx < x + w:
				if _needs_1m(x, z, w, d, xx, zz):
					var small := Props.model(_piece("floor1"))
					if small:
						small.position = Vector3(xx, 0, zz)
						small.set_meta("floor_scrap", true)
						Props.restyle_architecture(small, _floor_color(), _trim_color())
						Props.prepare(small)
						add_child(small)
				xx += 1.0
			zz += 1.0
	var body := StaticBody3D.new()
	body.name = "FloorBody"
	body.collision_layer = Props.LAYER_BLOCKING
	body.collision_mask = Props.LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, 0.08, d)
	box.margin = 0.001
	shape.shape = box
	shape.position = Vector3(x + w * 0.5, -0.04, z + d * 0.5)
	body.add_child(shape)
	add_child(body)


func _needs_1m(x: float, z: float, w: float, d: float, xx: float, zz: float) -> bool:
	var local_x := xx - x
	var local_z := zz - z
	var on_2 := int(round(w)) % 2 == 0 and int(round(d)) % 2 == 0
	if on_2:
		return false
	if local_x > w - 1.0 or local_z > d - 1.0:
		return true
	return false


func _build_rect(x: float, z: float, w: float, d: float, with_opening: bool) -> void:
	_fill_floor(x, z, w, d)
	_corner(Vector3(x, 0, z), 0, true)
	_corner(Vector3(x + w, 0, z), 180, false)
	_corner(Vector3(x + w, 0, z + d), 90, false, true)
	_corner(Vector3(x, 0, z + d), 0, false, true)
	var open_w := float(venue.get("open_w", 2))
	var opening_center := x + w * 0.5
	if abs(open_w - 3.0) < 0.1 and w >= 6.0:
		opening_center = x + 3.5
	var open_a := opening_center - open_w * 0.5
	var open_b := opening_center + open_w * 0.5
	if with_opening:
		_fill_run(x + 1.0, open_a, z, true, false, false)
		_fill_run(open_b, x + w - 1.0, z, true, false, false)
		_place_opening(opening_center, z)
	else:
		_fill_run(x + 1.0, x + w - 1.0, z, true, false, false)
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		_fill_run(z + 1.0, float(nook["z"]), x, false, false, true)
		_fill_run(float(nook["z"]) + float(nook["d"]), z + d - 1.0, x, false, false, false)
	else:
		_fill_run(z + 1.0, z + d - 1.0, x, false, false, true)
	_fill_run(x + 1.0, x + w - 1.0, z + d, true, true, false)
	_fill_run(z + 1.0, z + d - 1.0, x + w, false, true, false)
	var glow := OmniLight3D.new()
	glow.name = "DoorGlow"
	glow.position = Vector3(opening_center, 1.6, z + 0.45)
	glow.light_color = Color("FFC98A")
	glow.light_energy = 0.9
	glow.omni_range = 6.0
	glow.shadow_enabled = true
	glow.shadow_blur = 2.0
	add_child(glow)


func _build_nook_walls(nook: Dictionary) -> void:
	var x := float(nook["x"])
	var z := float(nook["z"])
	var w := float(nook["w"])
	var d := float(nook["d"])
	_corner(Vector3(x, 0, z), 0, true)
	_corner(Vector3(x, 0, z + d), 0, false)
	_fill_run(x + 1.0, x + w - 0.2, z, true, false, false)
	_fill_run(x + 1.0, x + w - 0.2, z + d, true, false, false)
	_fill_run(z + 1.0, z + d - 1.0, x, false, false, false)


func _corner(at: Vector3, rot: float, mirror_z: bool, cutaway := false) -> void:
	var node := Props.model(_piece("corner"))
	if node == null:
		return
	node.position = at
	node.rotation.y = deg_to_rad(rot)
	if mirror_z:
		node.scale.z = -1
	if cutaway:
		node.visible = false
		node.add_to_group("cutaway_shell")
	node.set_meta("shell_corner", true)
	node.set_meta("corner_at", Vector2(at.x, at.z))
	Props.restyle_architecture(node, _wall_color(), _trim_color())
	Props.prepare(node)
	add_child(node)


func _fill_run(a: float, b: float, fixed: float, along_x: bool, hidden: bool, windows: bool) -> void:
	if b - a < 0.8:
		return
	var cursor := a
	var window_used := false
	while b - cursor >= 0.9:
		var length := 2.0 if b - cursor >= 1.9 else 1.0
		var center := cursor + length * 0.5
		var use_window := windows and bool(venue.get("windows", false)) and length >= 2.0 and not window_used and not hidden
		var scene_name := _piece("window") if use_window else (_piece("wall2") if length >= 2.0 else _piece("wall1"))
		if use_window:
			window_used = true
		var node := Props.model(scene_name)
		if node:
			if along_x:
				node.position = Vector3(center, 0, fixed)
			else:
				node.position = Vector3(fixed, 0, center)
				node.rotation.y = deg_to_rad(90)
			node.visible = not hidden
			if hidden:
				node.add_to_group("cutaway_shell")
			node.set_meta("shell_side", _side_of(along_x, fixed))
			Props.restyle_architecture(node, _wall_color(), _trim_color())
			Props.prepare(node)
			add_child(node)
		cursor += length


func _place_opening(center_x: float, z: float) -> void:
	var kind := str(venue.get("opening", "door"))
	if kind == "garage":
		var garage := Props.model("wall_garage_3m")
		if garage == null:
			return
		garage.position = Vector3(center_x, 0, z)
		garage.set_meta("shell_side", "N")
		Props.restyle_architecture(garage, _wall_color(), _trim_color())
		Props.prepare(garage)
		add_child(garage)
		garage_door = garage.find_child("GarageDoor", true, false)
		for i in 8:
			var slat := garage.find_child("Slat_%d" % i, true, false)
			if slat:
				slats.append(slat)
		_set_garage_y(0.0)
	else:
		var door := Props.model(_piece("door"))
		if door == null:
			return
		door.position = Vector3(center_x, 0, z)
		door.set_meta("shell_side", "N")
		Props.restyle_architecture(door, _wall_color(), _trim_color())
		Props.prepare(door)
		add_child(door)
		var leaf := door.find_child("DoorLeaf", true, false)
		if leaf:
			leaf.rotation.y = deg_to_rad(float(Tuning.get_value("shop_door_open_deg", -80)))


func _set_garage_y(y: float) -> void:
	if garage_door == null:
		return
	garage_door.position.y = y
	var hide_at := float(Tuning.get_value("garage_slat_hide_y", 2.55))
	for slat in slats:
		if slat is Node3D:
			slat.visible = garage_door.position.y + slat.position.y < hide_at


func _piece(role: String) -> String:
	if str(venue.get("kit", "")) == "bakery_loft":
		match role:
			"floor2":
				return "bakery_loft_floor_2m"
			"floor1":
				return "bakery_loft_floor_1m"
			"corner":
				return "bakery_loft_wall_corner"
			"wall2":
				return "bakery_loft_wall_2m"
			"wall1":
				return "bakery_loft_wall_1m"
			"window":
				return "wall_window_2m"
			"door":
				return "wall_door_2m"
	match role:
		"floor2":
			return "floor_tile_2m"
		"floor1":
			return "floor_tile_1m"
		"corner":
			return "wall_corner"
		"wall2":
			return "wall_straight_2m"
		"wall1":
			return "wall_straight_1m"
		"window":
			return "wall_window_2m"
		"door":
			return "wall_door_2m"
	return "wall_straight_1m"


func _place_model(model_name: String, at: Vector3, rot_deg := 0.0) -> Node3D:
	var node := Props.model(model_name)
	if node == null:
		return null
	node.position = at
	node.rotation.y = deg_to_rad(rot_deg)
	Props.cap_prop_materials(node, 2)
	Props.prepare(node)
	add_child(node)
	return node


func _dress() -> void:
	var layout_name := str(venue.get("shop_layout", ""))
	if layout_name != "":
		ShopLayout.place(self, layout_name)
		return
	var id := str(venue.get("id", ""))
	if id == "garage":
		_place_model("driveway_apron_2m", Vector3(2.5, 0, -1.02))
		_place_model("driveway_apron_2m", Vector3(4.5, 0, -1.02))
		_place_model("job_clipboard", Vector3(0.55, 0.94, 5.7), 80)
		GarageDressing.build(self, venue)
	if bool(venue.get("stain", false)):
		for spot in [Vector3(2.4, 0.0, 1.3), Vector3(4.2, 0.0, 1.8)]:
			_place_model("floor_oil_stain_1m", spot)
	if id == "cafe":
		_mark_goal(_place_model("cafe_counter", Vector3(3.2, 0, 4.7)), "cafe_counter", 0.95, 2.05, 0.75)
		_mark_goal(_place_model("mug_rack", Vector3(0.12, 1.35, 3.2), 90), "mug_rack", 0.6, 0.7, 0.185)
		_place_model("hanging_plant", Vector3(2.0, 2.15, 2.2))
		_place_model("hanging_plant", Vector3(4.6, 2.15, 3.4))
		_place_model("padding_roll", Vector3(1.4, 0, 1.15))
	if bool(venue.get("cat", false)):
		cat_rig = _place_model("cat_biscuit", Vector3(4.3, 0, 1.6))
		if cat_rig:
			Props.play_clip(cat_rig, "idle", true)
			cat_player = cat_rig.find_child("AnimationPlayer", true, false) as AnimationPlayer
			cat_base_y = cat_rig.position.y
	if id == "train" or bool(venue.get("train", false)):
		var board := _place_model("train_layout_board", Vector3(5.6, 0, 2.4))
		if board:
			Props.play_clip(board, "loop", true)
		_place_model("display_case", Vector3(1.6, 0, 5.15))
		_place_model("parts_drawer_unit", Vector3(3.3, 0, 5.15))
		_place_model("cuckoo_clock", Vector3(0.12, 1.55, 2.2), 90)
	if id == "bakery":
		# No ceiling beams: the loft keeps its skylight and a pool of morning light under it.
		var frame := _place_model("skylight_frame", Vector3(4.0, 2.88, 5.0))
		if frame:
			frame.name = "SkylightFrame"
		var sky := OmniLight3D.new()
		sky.name = "SkylightGlow"
		sky.position = Vector3(4.0, 2.6, 5.0)
		sky.light_color = Color("FFF1D6")
		sky.light_energy = 1.1
		sky.omni_range = 5.0
		sky.shadow_enabled = false
		add_child(sky)
		var radiator := _place_model("radiator", Vector3(0.55, 0, 6.4), 90)
		if radiator:
			radiator.name = "Radiator"
			radiator.set_meta("goal_item", "radiator")
			radiator.set_meta("goal_h", 0.5)
		_dress_beam_nook()
		_place_model("flour_sack_rug", Vector3(4.2, 0, 6.2))
		for step in 3:
			var stair := _place_model("stair_step", Vector3(-0.2 - float(step) * 0.3, float(step) * 0.22, 4.6), 90)
			_mark_goal(stair, "stair_step", 0.22, 1.0, 0.3)
			if stair:
				stair.name = "StairStep%d" % step
	if bool(venue.get("studio", false)):
		_place_model("hanging_plant", Vector3(2.2, 2.15, 2.0))
		_place_model("padding_roll", Vector3(5.8, 0, 1.2))
		_place_model("folding_table", Vector3(5.6, 0, 4.6), 90)
	if bool(venue.get("flat", false)):
		var heater := _place_model("radiator", Vector3(0.55, 0, 3.6), 90)
		if heater:
			heater.name = "FlatRadiator"
		_place_model("wall_clock", Vector3(0.12, 1.7, 5.4), 90)
	if id != "garage" and layout_name == "":
		VenueDressing.build(self, venue)
	if bool(venue.get("pastry", false)):
		var bun := _place_model("pastry_basket", Vector3(1.5, 0, 1.3))
		if bun:
			bun.name = "Pastry"
			Props.add_picker(bun, Vector3(0.44, 0.23, 0.44))
			bun.set_meta("pastry", true)
			bun.set_meta("goal_item", "pastry_basket")
			bun.set_meta("goal_h", 0.23)


func _mark_goal(node: Node3D, item_id: String, height: float, width := 0.4, depth := 0.4) -> void:
	if node == null:
		return
	node.set_meta("goal_item", item_id)
	node.set_meta("goal_model", item_id)
	node.set_meta("goal_h", height)
	node.set_meta("goal_w", width)
	node.set_meta("goal_d", depth)


func _tag_beam(node: Node3D) -> void:
	if node == null:
		return
	node.add_to_group("cutaway_beam")
	node.set_meta("goal_item", "beam")
	node.set_meta("goal_model", "ceiling_beam")
	node.set_meta("goal_h", 0.29)


func _dress_beam_nook() -> void:
	var nook: Dictionary = venue.get("nook", {})
	if nook.is_empty():
		return
	var shelf_at := Vector3(float(nook["x"]) + float(nook["w"]) * 0.62, 0.0, float(nook["z"]) + 2.1)
	var shelf := _place_model("shelf", shelf_at, 0.0)
	if shelf:
		shelf.name = "GoalShelf"
		shelf.set_meta("goal_item", "shelf")
		shelf.set_meta("goal_h", 1.6)
	var fern := _place_model("plant_tall", shelf_at + Vector3(0.0, 1.6, 0.2), 15.0)
	if fern:
		fern.name = "GoalFern"
		fern.set_meta("goal_item", "plant_fern")
		fern.set_meta("goal_model", "plant_tall")
		fern.set_meta("goal_h", 1.14)
	_fade_beams_in_front(fern)


func _fade_beams_in_front(fern: Node3D) -> void:
	if fern == null:
		return
	var dir := Vector2(1, 1).normalized()
	var fern_xz := Vector2(fern.position.x, fern.position.z)
	for node in get_tree().get_nodes_in_group("cutaway_beam"):
		if not (node is Node3D) or not is_instance_valid(node):
			continue
		var beam := node as Node3D
		var beam_xz := Vector2(beam.position.x, beam.position.z)
		if beam_xz.dot(dir) <= fern_xz.dot(dir) + 0.15:
			continue
		var span := fern_xz - beam_xz
		if absf(span.x) > 1.6 or absf(span.y) > 1.6:
			continue
		_fade_beam(beam, 0.3)


func _fade_beam(node: Node, alpha: float) -> void:
	var meshes: Array = []
	if node is MeshInstance3D:
		meshes.append(node)
	meshes.append_array(node.find_children("*", "MeshInstance3D", true, false))
	for mesh in meshes:
		var mesh_instance := mesh as MeshInstance3D
		if mesh_instance == null:
			continue
		var source: Material = mesh_instance.material_override
		if source == null and mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
			source = mesh_instance.mesh.surface_get_material(0)
		var faded := StandardMaterial3D.new()
		if source is StandardMaterial3D:
			faded = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
		faded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		faded.albedo_color.a = alpha
		mesh_instance.material_override = faded


func _build_truck_stage() -> void:
	venue = {"id": "street", "name": "Corner Movers", "x": -2, "z": -2, "w": 8, "d": 6, "open_w": 2, "music": "music_office_build"}
	var yard := Outdoors.build(self, venue)
	# The truck parks on the driveway apron.
	var apron := Props.mesh_box(Vector3(8, 0.03, 6), Outdoors.PAVEMENT)
	apron.position = Vector3(2, -0.03, 1)
	yard.add_child(apron)
	_build_facade()
	truck_root = Props.model("mover_truck")
	if truck_root:
		add_child(truck_root)
		back_door = truck_root.find_child("BackDoor", true, false) as Node3D
		cargo_boxes = truck_root.find_child("CargoBoxes", true, false) as Node3D
		_arm_truck_door()
		for decal_name in ["LogoDecal_L", "LogoDecal_R"]:
			var decal := truck_root.find_child(decal_name, true, false)
			if decal:
				var dir := -1.0 if decal_name.ends_with("L") else 1.0
				decal.position.z += dir * float(Tuning.get_value("logo_decal_nudge_m", 0.012))
		_sync_cargo()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.2
	# From behind and above, so the open door shows every pad in the bed.
	cam.position = Vector3(-7.4, 4.6, 3.0)
	cam.look_at(Vector3(-0.9, 1.0, 0.1), Vector3.UP)
	var sun := OmniLight3D.new()
	sun.position = Vector3(-2, 3, 2)
	sun.light_energy = 0.4
	sun.omni_range = 10
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	add_child(sun)


func _build_facade() -> void:
	# The place the boxes come from stands behind the truck: its front wall,
	# a door, two windows, the name over the door, and the boxes on the step.
	var def: Dictionary = GameState.job.get("def", {})
	var place: Dictionary = ItemDB.venues().get(str(def.get("venue", "cafe")), {})
	var look: Dictionary = Catalog.theme(str(place.get("theme", str(def.get("venue", "cafe")))))
	var facade := Node3D.new()
	facade.name = "Facade"
	add_child(facade)
	var wall := Props.mesh_box(Vector3(9.0, 3.0, 0.3), Color(str(look.get("wall", "9A8C7E"))))
	wall.position = Vector3(2.0, 1.5, -2.45)
	facade.add_child(wall)
	var trim := Props.mesh_box(Vector3(9.0, 0.16, 0.36), Color(str(look.get("trim", "7A5C40"))))
	trim.position = Vector3(2.0, 3.0, -2.45)
	facade.add_child(trim)
	var door := Props.mesh_box(Vector3(1.0, 2.2, 0.1), Color(str(look.get("trim", "7A5C40"))))
	door.position = Vector3(2.0, 1.1, -2.26)
	facade.add_child(door)
	var knob := Props.mesh_cylinder(0.03, 0.04, UIKit.MUSTARD)
	knob.rotation.x = PI * 0.5
	knob.position = Vector3(2.35, 1.05, -2.2)
	facade.add_child(knob)
	for wx in [-0.6, 4.6]:
		var pane := Props.mesh_box(Vector3(1.2, 1.1, 0.08), Color("DCE9EE"))
		pane.position = Vector3(wx, 1.6, -2.26)
		facade.add_child(pane)
		var sill := Props.mesh_box(Vector3(1.3, 0.08, 0.2), Color(str(look.get("trim", "7A5C40"))))
		sill.position = Vector3(wx, 1.02, -2.2)
		facade.add_child(sill)
	var sign := Label3D.new()
	sign.text = str(place.get("name", def.get("title", "The job")))
	sign.font_size = 110
	sign.pixel_size = 0.004
	sign.modulate = UIKit.CREAM_CARD
	sign.outline_modulate = Color(str(look.get("trim", "7A5C40")))
	sign.outline_size = 14
	sign.position = Vector3(2.0, 2.55, -2.2)
	facade.add_child(sign)
	var step := Props.mesh_box(Vector3(1.6, 0.1, 0.8), Outdoors.PAVEMENT.darkened(0.1))
	step.position = Vector3(2.0, 0.05, -1.9)
	facade.add_child(step)
	# The boxes still to go, piled by the door; the pile shrinks as the bed fills.
	var pile := Node3D.new()
	pile.name = "BoxPile"
	pile.position = Vector3(0.4, 0.0, -1.5)
	facade.add_child(pile)
	_sync_pile()


func _sync_pile() -> void:
	var pile := find_child("BoxPile", true, false) as Node3D
	if pile == null:
		return
	for child in pile.get_children():
		child.free()
	var waiting := 0
	for box in GameState.job.get("boxes", []):
		if bool(box.get("sealed", false)) and int(box.get("slot", -1)) < 0:
			waiting += 1
	var big_ids: Array = []
	for box in GameState.job.get("boxes", []):
		if str(box.get("big", "")) != "" and int(box.get("slot", -1)) < 0:
			big_ids.append(str(box["big"]))
	var shown_big := 0
	for big_uid in big_ids:
		var big_item := GameState.job_item(big_uid)
		var piece := Props.make(str(ItemDB.get_item(str(big_item.get("item_id", ""))).get("model", "box_closed")))
		var pc := piece.get_node_or_null("PropCollision")
		if pc:
			pc.free()
		piece.scale = Vector3(0.6, 0.6, 0.6)
		piece.position = Vector3(-1.1 - float(shown_big) * 0.9, 0.0, 0.2)
		pile.add_child(piece)
		shown_big += 1
	for i in waiting - big_ids.size():
		var crate := Props.make("box_closed")
		var collision := crate.get_node_or_null("PropCollision")
		if collision:
			collision.free()
		crate.position = Vector3(float(i % 3) * 0.55, float(int(i / 3)) * 0.42, float(int(i / 6)) * 0.5)
		crate.rotation.y = 0.15 * float(i % 2)
		pile.add_child(crate)


func _begin_drive() -> void:
	_open_truck_door(false)
	await get_tree().create_timer(0.6).timeout
	_sync_cargo()
	emit_signal("request_drive")


func _arm_truck_door() -> void:
	if back_door == null or truck_root == null:
		return
	door_player = AnimationPlayer.new()
	door_player.name = "DoorPlayer"
	door_player.root_node = NodePath("..")
	truck_root.add_child(door_player)
	var library := AnimationLibrary.new()
	var rel := str(truck_root.get_path_to(back_door))
	var open_y := deg_to_rad(float(Tuning.get_value("truck_door_open_deg", 105)))
	library.add_animation("open", _door_clip(rel, 0.0, open_y))
	library.add_animation("close", _door_clip(rel, open_y, 0.0))
	door_player.add_animation_library("", library)


func _door_clip(rel: String, from_y: float, to_y: float) -> Animation:
	var anim := Animation.new()
	anim.length = 0.55
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("%s:rotation:y" % rel))
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	anim.track_insert_key(track, 0.0, from_y)
	anim.track_insert_key(track, 0.55, to_y)
	return anim


func _open_truck_door(open: bool) -> void:
	if back_door == null:
		return
	truck_door_open = open
	if door_player == null:
		_arm_truck_door()
	if door_player != null and door_player.has_animation("open"):
		door_player.play("open" if open else "close")
	else:
		var target := deg_to_rad(float(Tuning.get_value("truck_door_open_deg", 105))) if open else 0.0
		var tw := create_tween()
		tw.tween_property(back_door, "rotation:y", target, 0.55)
	AudioDirector.play_sfx("sfx_truck_backdoor_open" if open else "sfx_truck_backdoor_close")
	_sync_cargo()


func _sync_cargo() -> void:
	if cargo_boxes == null:
		return
	var loaded := 0
	for box in GameState.job.get("boxes", []):
		if int(box.get("slot", -1)) >= 0:
			loaded += 1
	cargo_boxes.visible = loaded > 0 and not truck_door_open


func _process(delta: float) -> void:
	if hud_only:
		return
	if backdrop:
		_drift_camera(delta)
		return
	if toast_time > 0.0:
		toast_time -= delta
		if toast:
			toast.visible = toast_time > 0.0
			if toast_bar:
				toast_bar.visible = toast.visible
	if cat_player and is_instance_valid(cat_player):
		stretch_in -= delta
		if stretch_in <= 0.0 and cat_player.current_animation != "stretch":
			Props.play_clip(cat_rig, "stretch", false)
			stretch_in = randf_range(6.0, 11.0)
			if not cat_player.animation_finished.is_connected(_on_cat_clip):
				cat_player.animation_finished.connect(_on_cat_clip)
	elif cat_rig and is_instance_valid(cat_rig) and cat_rig.visible:
		_cat_idle(delta)
	_update_ghost(delta)
	_update_hover()
	_sync_deliveries()
	_tick_visitors(delta)
	_tick_street(delta)
	_tick_browser(delta)
	_tick_cars(delta)
	_tick_bubbles(delta)
	_tick_player(delta)
	if _goal_pip > 0.0:
		_goal_pip = maxf(0.0, _goal_pip - delta)
		if _goal_pip <= 0.0:
			_markers_key = ""
	_sync_goal_markers()
	_sync_goals_panel()
	if hint:
		hint.text = _hint_text()


func _sync_goals_panel() -> void:
	# The checklist for this room: every goal, ticked as it is met.
	if goals_panel == null or backdrop or venue.is_empty():
		return
	var show := (GameState.mode == "office" and GameState.office_phase != "pack") or GameState.mode == "job_unpack"
	if not show:
		goals_panel.visible = false
		return
	var items := _goal_items()
	# The card only matters while there is placing to do; a live shop keeps the corner clear.
	var placing := (GameState.mode == "office" and GameState.office_phase == "place") or GameState.mode == "job_unpack"
	if not placing:
		if goals_panel.visible:
			goals_panel.visible = false
			_goals_key = ""
		return
	var lines: Array = []
	var met_count := 0
	for goal in StackGoals.all_goals():
		if str(goal.get("venue", "")) != str(venue.get("id", "")):
			continue
		var met := bool(StackGoals.evaluate(goal, items, GameState.latched_goals).get("met", false))
		if met:
			met_count += 1
		lines.append([met, str(goal.get("hint", ""))])
	var setup: float = stack_room.score() if stack_room else -1.0
	var key := "%s|%d" % [str(lines), int(setup)]
	if key == _goals_key:
		return
	_goals_key = key
	for child in goals_column.get_children():
		goals_column.remove_child(child)
		child.queue_free()
	var head_row := HBoxContainer.new()
	head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.add_theme_constant_override("separation", 12)
	goals_column.add_child(head_row)
	var head := UIKit.label("Room score", 28, UIKit.TERRA, "title", false)
	head.custom_minimum_size = Vector2(200, 40)
	head_row.add_child(head)
	var score_tag := UIKit.label("%d / 100" % int(round(maxf(setup, 0.0))), 28, UIKit.DARK, "title", false)
	score_tag.custom_minimum_size = Vector2(150, 40)
	head_row.add_child(score_tag)
	var why := UIKit.label("Tidy placing pays: a higher score means a bigger tip when you finish.", 27, UIKit.WOOD, "small")
	why.custom_minimum_size = Vector2(520, 0)
	goals_column.add_child(why)
	if not lines.is_empty():
		var sub := UIKit.label("Bonus goals  %d of %d done" % [met_count, lines.size()], 27, UIKit.BLUE, "small", false)
		goals_column.add_child(sub)
	for pair in lines:
		var done: bool = pair[0]
		var row := UIKit.label("%s  %s" % ["✓" if done else "○", pair[1]], 27, UIKit.SAGE.darkened(0.3) if done else UIKit.DARK, "small")
		row.custom_minimum_size = Vector2(520, 0)
		goals_column.add_child(row)
	goals_panel.visible = true


func _cat_idle(delta: float) -> void:
	# The model has no clips, so Biscuit breathes, settles, and now and then
	# stretches long and low, all in code.
	cat_time += delta
	stretch_in -= delta
	if not cat_stretching:
		var breath := 1.0 + sin(cat_time * 2.4) * 0.025
		cat_rig.scale = Vector3(1.0, breath, 1.0)
		cat_rig.rotation.z = sin(cat_time * 0.7) * 0.015
		if stretch_in <= 0.0:
			cat_stretching = true
			stretch_in = randf_range(6.0, 11.0)
			var tw := create_tween()
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(cat_rig, "scale", Vector3(1.0, 0.82, 1.22), 0.55)
			tw.parallel().tween_property(cat_rig, "position:y", cat_base_y + 0.03, 0.55)
			tw.tween_interval(0.5)
			tw.tween_property(cat_rig, "scale", Vector3.ONE, 0.6)
			tw.parallel().tween_property(cat_rig, "position:y", cat_base_y, 0.6)
			tw.tween_callback(func(): cat_stretching = false)
			if randf() < 0.3:
				AudioDirector.play_sfx("sfx_cat_meow")


func _on_cat_clip(anim_name: StringName) -> void:
	if str(anim_name) == "stretch" and cat_rig:
		Props.play_clip(cat_rig, "idle", true)


func _build_shell() -> void:
	_build_rect(float(venue.get("x", 0)), float(venue.get("z", 0)), float(venue.get("w", 6)), float(venue.get("d", 8)), true)
	if _is_home():
		_build_interior()
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		_fill_floor(float(nook["x"]), float(nook["z"]), float(nook["w"]), float(nook["d"]))
		_build_nook_walls(nook)
		# A slim painted picture rail along the back of the nook, not a beam.
		var beam := Props.mesh_box(Vector3(float(nook["w"]) * 0.55, 0.06, 0.08), UIKit.CREAM_CARD)
		beam.name = "NookBeam"
		# Back of the nook, above the shelf line. The camera looks from +x +z, so this
		# beam sits behind the fern instead of across its face.
		beam.position = Vector3(float(nook["x"]) + float(nook["w"]) * 0.28, 2.35, float(nook["z"]) + 0.35)
		beam.add_to_group("cutaway_beam")
		beam.set_meta("goal_item", "beam")
		beam.set_meta("goal_model", "ceiling_beam")
		beam.set_meta("goal_h", 0.1)
		add_child(beam)


func _build_showroom() -> void:
	var layout: Dictionary = MenuLayout.load_layout()
	if not layout.is_empty():
		_build_loft_showroom(layout)
		return
	venue = ItemDB.venues().get("garage", {}).duplicate(true)
	venue["id"] = "garage"
	menu_look = Vector3(3.15, 0.9, 2.85)
	_build_shell()
	_dress()
	_set_garage_y(float(Tuning.get_value("garage_door_open_y", 2.1)))
	_place_model("rug", Vector3(3.5, 0.0, 2.75))
	for rec in _menu_props():
		_spawn_record(rec, str(rec.get("item", "")), false)
	_menu_box_stack()
	_menu_lights()
	Outdoors.build(self, venue)
	_frame_camera()


func _build_loft_showroom(layout: Dictionary) -> void:
	venue = ItemDB.venues().get("bakery", {}).duplicate(true)
	venue["id"] = "bakery"
	if layout.has("w"):
		venue["w"] = float(layout["w"])
	if layout.has("d"):
		venue["d"] = float(layout["d"])
	_build_shell()
	_dress()
	for rec in MenuLayout.records(layout):
		_place_layout_record(rec)
	_pin_menu_skylight()
	_menu_box_stack()
	var look = MenuLayout.look_target(layout)
	if look is Vector3:
		menu_look = look
	else:
		menu_look = Vector3(float(venue.get("w", 8.0)) * 0.5, 0.9, float(venue.get("d", 10.0)) * 0.45)
	_menu_lights()
	_frame_camera()


func _place_layout_record(rec: Dictionary) -> void:
	var item_id := str(rec.get("item", ""))
	var def := ItemDB.get_item(item_id) if item_id != "" else {}
	if item_id != "" and (def.has("model") or def.has("w") or def.has("mount")):
		_spawn_record(rec, item_id, false)
		return
	var model_name := str(rec.get("model", item_id))
	if model_name == "":
		return
	_place_model(model_name, Vector3(float(rec.get("x", 0.0)), float(rec.get("y", 0.0)), float(rec.get("z", 0.0))), float(rec.get("rot", 0.0)))


func _menu_props() -> Array:
	return [
		{"uid": "menu_desk", "item": "desk_main", "x": 3.35, "y": 0.0, "z": 2.35, "rot": 12, "state": "placed"},
		{"uid": "menu_notes", "item": "sticky_note_stack", "x": 3.18, "y": 0.76, "z": 2.52, "rot": -12, "state": "placed"},
		{"uid": "menu_lamp", "item": "desk_lamp", "x": 3.78, "y": 0.76, "z": 2.52, "rot": 24, "state": "placed"},
		{"uid": "menu_crt", "item": "place_crt", "x": 3.58, "y": 0.76, "z": 2.12, "rot": 8, "state": "placed"},
		{"uid": "menu_keys", "item": "place_keyboard", "x": 3.32, "y": 0.76, "z": 2.02, "rot": 12, "state": "placed"},
		{"uid": "menu_chair", "item": "office_chair", "x": 3.15, "y": 0.0, "z": 3.4, "rot": 168, "state": "placed"},
		{"uid": "menu_bean", "item": "starter_beanbag", "x": 4.9, "y": 0.0, "z": 3.55, "rot": 28, "state": "placed"},
		{"uid": "menu_fern", "item": "plant_fern", "x": 5.15, "y": 0.0, "z": 1.55, "rot": 20, "state": "placed"},
		{"uid": "menu_cactus", "item": "plant_cactus", "x": 2.4, "y": 0.0, "z": 3.2, "rot": 0, "state": "placed"},
		{"uid": "menu_fridge", "item": "mini_fridge", "x": 5.25, "y": 0.0, "z": 5.35, "rot": 180, "state": "placed"},
		{"uid": "menu_board", "item": "whiteboard", "x": 0.12, "y": 1.15, "z": 3.3, "rot": 90, "wall": "hang", "state": "placed"},
		{"uid": "menu_shelf", "item": "shelf", "x": 0.12, "y": 0.0, "z": 5.1, "rot": 90, "wall": "wall_floor", "state": "placed"},
	]


func _pin_menu_skylight() -> void:
	for node in find_children("*", "Node3D", true, false):
		var named := str(node.name).to_lower()
		if "skylight" in named and node is Node3D and node.name != "Skylight":
			(node as Node3D).position.y = 2.55


func _menu_box_stack() -> void:
	var box := Props.make("box_closed")
	box.name = "BoxClosed"
	box.position = Vector3(4.7, 0.0, 1.45)
	add_child(box)
	var mug := Props.make("mug_worlds_okayest")
	mug.name = "BoxMug"
	mug.position = Vector3(4.7, 0.36, 1.45)
	mug.rotation.y = deg_to_rad(18.0)
	add_child(mug)
	var founder := Props.make("box_closed")
	founder.name = "FounderBox"
	founder.position = Vector3(5.32, 0.0, 1.45)
	founder.rotation.y = 0.35
	add_child(founder)


func _menu_lights() -> void:
	var sky := SpotLight3D.new()
	sky.name = "Skylight"
	sky.position = Vector3(3.35, 2.55, 3.7)
	sky.light_color = Color("FFE3B0")
	sky.light_energy = 1.2
	sky.spot_range = 7.0
	sky.spot_angle = 38.0
	sky.shadow_enabled = true
	add_child(sky)
	sky.look_at(Vector3(3.35, 0.76, 2.35))
	var key := OmniLight3D.new()
	key.name = "MenuKey"
	key.position = Vector3(4.9, 2.55, 4.35)
	key.light_color = Color("FFE2C2")
	key.light_energy = 0.28
	key.omni_range = 8.0
	key.shadow_enabled = true
	key.shadow_blur = 2.0
	add_child(key)
	var fill := OmniLight3D.new()
	fill.name = "MenuFill"
	fill.position = Vector3(1.6, 1.7, 1.35)
	fill.light_color = Color("FFD0A8")
	fill.light_energy = 0.14
	fill.omni_range = 6.5
	fill.shadow_enabled = false
	add_child(fill)


func _frame_menu_camera() -> void:
	if cam == null:
		return
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.attributes = Graphics.menu_dof()
	cam.size = MENU_ORTHO_SIZE
	var look := menu_look
	cam.position = look
	cam.rotation = Vector3(deg_to_rad(MENU_PITCH_DEG), deg_to_rad(MENU_YAW_DEG), 0.0)
	var dist := 18.0
	cam.position = look + cam.global_transform.basis.z * dist
	var slide := MENU_ORTHO_SIZE * _view_aspect() * 0.2
	cam.position -= cam.global_transform.basis.x * slide
	show_focus = look - cam.global_transform.basis.x * slide
	show_cam = cam.global_position
	show_basis = cam.global_transform.basis
	show_ready = true


func _view_aspect() -> float:
	var view := get_viewport().get_visible_rect().size
	if view.y > 1.0:
		return view.x / view.y
	return 16.0 / 9.0


static func prefers_reduced_motion() -> bool:
	var forced := OS.get_environment("CORNER_OFFICE_REDUCED_MOTION").strip_edges().to_lower()
	if forced == "1" or forced == "true" or forced == "on":
		return true
	if forced == "0" or forced == "false" or forced == "off":
		return false
	if _motion_cached:
		return _motion_reduced
	_motion_reduced = _query_os_reduced_motion()
	_motion_cached = true
	return _motion_reduced


static func _query_os_reduced_motion() -> bool:
	match OS.get_name():
		"Windows":
			return _reg_animate_off(_run_quiet("reg", PackedStringArray(["query", "HKCU\\Control Panel\\Desktop\\WindowMetrics", "/v", "MinAnimate"])))
		"macOS":
			return _run_quiet("defaults", PackedStringArray(["read", "com.apple.universalaccess", "reduceMotion"])) == "1"
		_:
			if FileAccess.file_exists("/usr/bin/gsettings"):
				var gnome := _run_quiet("/usr/bin/gsettings", PackedStringArray(["get", "org.gnome.desktop.interface", "enable-animations"]))
				if gnome.to_lower().contains("false"):
					return true
			if _gtk_animations_off():
				return true
			for bin in ["/usr/bin/kreadconfig6", "/usr/bin/kreadconfig5"]:
				if not FileAccess.file_exists(bin):
					continue
				var factor := _run_quiet(bin, PackedStringArray(["--file", "kdeglobals", "--group", "KDE", "--key", "AnimationDurationFactor"]))
				if factor == "0" or factor == "0.0":
					return true
	return false


static func _reg_animate_off(text: String) -> bool:
	for line in text.split("\n"):
		if not ("MinAnimate" in line):
			continue
		var bits := line.split(" ", false)
		return bits.size() > 0 and bits[bits.size() - 1] == "0"
	return false


static func _gtk_animations_off() -> bool:
	var home := OS.get_environment("HOME")
	for path in ["%s/.config/gtk-3.0/settings.ini" % home, "%s/.config/gtk-4.0/settings.ini" % home]:
		if not FileAccess.file_exists(path):
			continue
		var text := FileAccess.get_file_as_string(path).to_lower().replace(" ", "")
		if "gtk-enable-animations=0" in text:
			return true
	return false


static func _run_quiet(program: String, args: PackedStringArray) -> String:
	if program.begins_with("/") and not FileAccess.file_exists(program):
		return ""
	var output: Array = []
	if OS.execute(program, args, output, true) != 0:
		return ""
	var lines: PackedStringArray = []
	for row in output:
		lines.append(str(row))
	return "\n".join(lines).strip_edges()


func _drift_camera(delta: float) -> void:
	if cam == null or not show_ready:
		return
	if prefers_reduced_motion():
		drift_t = 0.0
		cam.global_position = show_cam
		cam.global_transform.basis = show_basis
		return
	drift_t += delta
	var yaw := sin(drift_t * TAU / MENU_DRIFT_SEC) * deg_to_rad(3.0)
	var spin := Basis(Vector3.UP, yaw)
	cam.global_position = show_focus + spin * (show_cam - show_focus)
	cam.global_transform.basis = spin * show_basis


func _update_ghost(delta: float) -> void:
	if held_uid == "":
		if ghost:
			ghost.visible = false
		_hide_footprint()
		return
	var hit: Variant = _aim_point()
	if hit == null:
		return
	var spot: Dictionary = _snap_point(hit)
	if ghost == null:
		_make_ghost()
	ghost.visible = true
	var target: Vector3 = spot["pos"]
	ghost.global_position = ghost.global_position.lerp(target, clampf(delta * 14.0, 0.0, 1.0))
	ghost.rotation.y = deg_to_rad(float(spot["rot"]))
	_paint_ghost(bool(spot["valid"]))
	_update_footprint(spot)
	var held_name := str(_held_def().get("model", "")) + str(_held_def().get("name", ""))
	if "stapler" in held_name.to_lower():
		Props.set_hover_outline(ghost, true)


func _update_footprint(spot: Dictionary) -> void:
	var def := _held_def()
	if footprint == null or not is_instance_valid(footprint):
		footprint = MeshInstance3D.new()
		footprint.name = "Footprint"
		footprint.mesh = BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = true
		footprint.material_override = material
		add_child(footprint)
	var w := float(def.get("w", 0.4))
	var d := float(def.get("d", 0.4))
	var on_wall := str(spot.get("wall", "")) != ""
	(footprint.mesh as BoxMesh).size = Vector3(w + 0.06, 0.012, (0.06 if on_wall else d) + 0.06)
	var target: Vector3 = spot["pos"]
	footprint.visible = held_uid != ""
	footprint.global_position = Vector3(target.x, target.y + 0.008, target.z)
	footprint.rotation.y = deg_to_rad(float(spot["rot"]))
	var valid := bool(spot.get("valid", false))
	(footprint.material_override as StandardMaterial3D).albedo_color = Color(UIKit.SAGE, 0.45) if valid else Color(UIKit.SOFT_RED, 0.5)


func _hide_footprint() -> void:
	if footprint != null and is_instance_valid(footprint):
		footprint.visible = false


func _make_ghost() -> void:
	if ghost:
		ghost.queue_free()
	var def := _held_def()
	ghost = Props.make(str(def.get("model", "box_closed")))
	var collision := ghost.get_node_or_null("PropCollision")
	if collision:
		collision.free()
	add_child(ghost)


func _update_hover() -> void:
	if held_uid != "":
		_set_hover(null)
		return
	var uid := _pick_uid()
	var next: Node3D = null
	if nodes_by_uid.has(uid):
		next = nodes_by_uid[uid] as Node3D
	elif uid != "":
		for child in items_root.get_children():
			if child is Node3D and str(child.get_meta("uid", "")) == uid:
				next = child
				break
	_set_hover(next)


func _set_hover(next: Node3D) -> void:
	if hover_root == next:
		return
	if hover_root != null and is_instance_valid(hover_root):
		Props.set_hover_outline(hover_root, false)
	hover_root = next
	if hover_root != null:
		Props.set_hover_outline(hover_root, true)


func _paint_ghost(valid: bool) -> void:
	if ghost == null:
		return
	for node in ghost.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var base: Material = mesh.surface_get_material(i)
			var dup := ghost_material(base, valid)
			Props.keep_material(mesh_instance, i, dup)


func _unhandled_input(event: InputEvent) -> void:
	if backdrop:
		return
	if Controls.event_pressed(event, "snap"):
		_toggle_snap()
		return
	if Controls.event_pressed(event, "rotate"):
		if held_uid != "":
			var fine := false
			if event is InputEventKey:
				var key := event as InputEventKey
				fine = key.shift_pressed or Input.is_key_pressed(KEY_SHIFT)
			held_rot = fmod(held_rot + Tuning.rotate_step(fine) + 360.0, 360.0)
			AudioDirector.play_sfx("sfx_ui_click")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and held_uid != "":
		_drop_hold()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M and GameState.mode == "office" and held_uid == "":
		emit_signal("open_map")
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_Q or event.keycode == KEY_E):
		rotate_view(-1 if event.keycode == KEY_Q else 1)
		return
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var up: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
		if held_uid != "":
			held_rot = fmod(held_rot + (Tuning.rotate_step(true) if up else -Tuning.rotate_step(true)) + 360.0, 360.0)
			AudioDirector.play_sfx("sfx_ui_click")
		else:
			zoom_view(-0.1 if up else 0.1)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click()


func _toggle_snap() -> void:
	SaveManager.snap_to_grid = not SaveManager.snap_to_grid
	if stack_room:
		stack_room.snap_assist = SaveManager.snap_to_grid
	SaveManager.save_settings()
	_toast("Grid snap on." if SaveManager.snap_to_grid else "Free placement.")
	_refresh_hud_buttons()


func _click() -> void:
	if settling or _over_ui():
		if OS.get_environment("CO_DEBUG") != "":
			print("  click swallowed: settling=%s over_ui=%s hovered=%s" % [settling, _over_ui(), get_viewport().gui_get_hovered_control()])
		return
	var item_uid := _pick_uid()
	var aim = _aim_point()
	if aim is Vector3:
		_player_go(aim)
	if item_uid.begins_with("delivery:") and GameState.mode == "office" and GameState.office_phase == "live":
		_delivery_click(item_uid.trim_prefix("delivery:"))
		return
	if item_uid.begins_with("client:") and party != null:
		party.react("talk", {}, true, item_uid)
		return
	if item_uid.begins_with("visitor:") and GameState.mode == "office":
		var visitor_uid := item_uid.trim_prefix("visitor:")
		if not _open_ask(visitor_uid):
			_open_make(visitor_uid)
		return
	if item_uid == "pastry":
		_pastry()
		return
	match GameState.mode:
		"office":
			_office_click(item_uid)
		"job_pack":
			_pack_click(item_uid)
		"truck":
			_truck_click(item_uid)
		"job_unpack":
			_unpack_click(item_uid)


func _over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and not (hovered is ColorRect and hovered.mouse_filter == Control.MOUSE_FILTER_IGNORE)


func _pick_uid() -> String:
	var space := get_world_3d().direct_space_state
	var from := cam.project_ray_origin(get_viewport().get_mouse_position())
	var to := from + cam.project_ray_normal(get_viewport().get_mouse_position()) * 80.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = Props.MASK_QUERY
	query.exclude = _cutaway_rids()
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return ""
	var node: Node = hit.collider
	while node:
		if node.has_meta("pastry"):
			return "pastry"
		if node.has_meta("uid"):
			return str(node.get_meta("uid"))
		if node.has_meta("slot"):
			return "slot:%d" % int(node.get_meta("slot"))
		node = node.get_parent()
	return ""


func _aim_point() -> Variant:
	if cam == null:
		return null
	var space := get_world_3d().direct_space_state
	if space == null:
		return _floor_point()
	var from := cam.project_ray_origin(get_viewport().get_mouse_position())
	var to := from + cam.project_ray_normal(get_viewport().get_mouse_position()) * 80.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = Props.MASK_QUERY
	# `query.exclude` hands back a copy, so build the list first and assign it once.
	var skip: Array[RID] = _ghost_rids()
	skip.append_array(_cutaway_rids())
	query.exclude = skip
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		return hit.position
	return _floor_point()


func _cutaway_rids() -> Array[RID]:
	var ids: Array[RID] = []
	for node in get_tree().get_nodes_in_group("cutaway_shell"):
		if node is CollisionObject3D:
			ids.append((node as CollisionObject3D).get_rid())
		for child in node.find_children("*", "CollisionObject3D", true, false):
			ids.append((child as CollisionObject3D).get_rid())
	return ids


func _ghost_rids() -> Array[RID]:
	var ids: Array[RID] = []
	if ghost == null:
		return ids
	if ghost is CollisionObject3D:
		ids.append((ghost as CollisionObject3D).get_rid())
	for node in ghost.find_children("*", "CollisionObject3D", true, false):
		ids.append((node as CollisionObject3D).get_rid())
	return ids


func _floor_point() -> Variant:
	var from := cam.project_ray_origin(get_viewport().get_mouse_position())
	var dir := cam.project_ray_normal(get_viewport().get_mouse_position())
	if abs(dir.y) < 0.0001:
		return null
	var t := (0.0 - from.y) / dir.y
	if t < 0.0:
		return null
	return from + dir * t


func _office_click(uid: String) -> void:
	if GameState.office_phase == "pack":
		var rec := GameState.find_office_item(uid)
		if rec.is_empty() or str(rec.get("state", "")) != "placed":
			return
		rec["state"] = "boxed"
		AudioDirector.play_sfx("sfx_item_pick_up")
		AudioDirector.play_sfx("sfx_box_fold", true)
		_refresh_items()
		_check_pack_done()
		return
	if held_uid == "":
		if uid == "":
			return
		if uid == "workbench" and GameState.office_phase == "live":
			_open_workshop()
			return
		var rec2 := GameState.find_office_item(uid)
		if rec2.is_empty():
			return
		if bool(ItemDB.get_item(str(rec2.get("item", ""))).get("computer", false)) and GameState.office_phase == "live" and str(rec2.get("state", "")) == "placed":
			AudioDirector.play_sfx("sfx_crt_power_on")
			AudioDirector.play_sfx("sfx_keyboard_typing")
			emit_signal("open_computer")
			return
		if bool(ItemDB.get_item(str(rec2.get("item", ""))).get("drawer", false)) and GameState.office_phase == "live":
			rec2["drawer_open"] = not bool(rec2.get("drawer_open", false))
			AudioDirector.play_sfx("sfx_drawer_open" if rec2["drawer_open"] else "sfx_drawer_close")
			return
		_take_to_hand(rec2, "office")
		return
	_try_place_held()


func _check_pack_done() -> void:
	for item in GameState.office_items:
		if str(item.get("state", "")) != "boxed":
			return
	GameState.office_phase = "place"
	_toast("Everything's boxed. Click a box, then click where it should live.")
	_refresh_hud_buttons()


func _try_place_held() -> void:
	var hit = _aim_point()
	if hit == null:
		return
	var spot: Dictionary = _snap_point(hit)
	if not bool(spot["valid"]):
		AudioDirector.play_sfx("sfx_invalid_placement")
		_shake(ghost if ghost else self)
		return
	var source := held_source
	var uid := held_uid
	var on_wall := str(spot.get("wall", "")) != ""
	if ghost != null and is_instance_valid(ghost):
		arrive_from[uid] = ghost.global_position + Vector3(0, 0.25, 0)
	if source == "decor":
		GameState.place_decor_from_queue(spot, uid)
		var decor := GameState.find_office_item(uid)
		if not decor.is_empty() and not on_wall:
			decor["state"] = "settling"
		AudioDirector.play_sfx("sfx_item_snap", true)
		held_uid = ""
		held_source = ""
		_commit_place(uid, source, on_wall)
		return
	var rec := GameState.find_office_item(uid) if source == "office" else GameState.job_item(uid)
	if rec.is_empty():
		held_uid = ""
		held_source = ""
		return
	_remember_safe(rec)
	rec["x"] = spot["pos"].x
	rec["y"] = spot["pos"].y
	rec["z"] = spot["pos"].z
	rec["rot"] = spot["rot"]
	rec["wall"] = spot.get("wall", "")
	rec["state"] = "placed" if on_wall else "settling"
	rec["settle"] = false
	if _is_home():
		rec["floor"] = home_floor
	if source == "office":
		GameState.note_first_place()
	AudioDirector.play_sfx("sfx_item_snap", true)
	AudioDirector.play_sfx("sfx_box_set_down", true)
	held_uid = ""
	held_source = ""
	_last_placed_uid = uid
	_commit_place(uid, source, on_wall)


func _commit_place(uid: String, source: String, on_wall: bool) -> void:
	if stack_room:
		stack_room.snap_assist = SaveManager.snap_to_grid
	if on_wall:
		_refresh_items()
		_squash_uid(uid)
		_after_place(source)
		settling = false
		SaveManager.save_game()
		return
	settling = true
	_settle_uid = uid
	_refresh_items()


func _after_place(source: String) -> void:
	if source == "office" or source == "decor":
		_maybe_live()
	elif source == "job":
		_unhide_loose()
		_party_on_place()
		_maybe_job_done()


func _take_to_hand(rec: Dictionary, source: String) -> void:
	var uid := str(rec.get("uid", ""))
	_release_dependents(uid)
	held_uid = uid
	held_source = source
	held_rot = float(rec.get("rot", 0))
	rec["state"] = "hand"
	AudioDirector.play_sfx("sfx_item_pick_up")
	_refresh_items()


func _release_dependents(uid: String) -> void:
	if stack_room == null:
		return
	var deps: Array = stack_room.release(uid)
	for dep_id in deps:
		var dep := _record_for(str(dep_id))
		if dep.is_empty():
			continue
		var node: Node = nodes_by_uid.get(str(dep_id))
		if _is_stack_item(node):
			var body := node as Node3D
			dep["x"] = body.global_position.x
			dep["y"] = body.global_position.y
			dep["z"] = body.global_position.z
			dep["rot"] = fposmod(rad_to_deg(body.rotation.y), 360.0)
			if bool(node.get("safe_ready")):
				var safe: Vector3 = node.get("safe_spot")
				dep["safe_x"] = safe.x
				dep["safe_y"] = safe.y
				dep["safe_z"] = safe.z
				dep["safe_rot"] = rad_to_deg(float(node.get("safe_yaw")))
		dep["state"] = "settling"


func _remember_safe(rec: Dictionary) -> void:
	var px := float(rec.get("x", 0.0))
	var pz := float(rec.get("z", 0.0))
	if not _in_room_world(px, pz):
		return
	rec["safe_x"] = px
	rec["safe_y"] = float(rec.get("y", 0.0))
	rec["safe_z"] = pz
	rec["safe_rot"] = float(rec.get("rot", 0.0))


func _on_item_evaluated(id: String, result: Dictionary) -> void:
	var rec := _record_for(id)
	var node: Node = nodes_by_uid.get(id)
	if not rec.is_empty() and _is_stack_item(node) and is_instance_valid(node):
		var body := node as Node3D
		rec["x"] = body.global_position.x
		rec["y"] = body.global_position.y
		rec["z"] = body.global_position.z
		rec["rot"] = fposmod(rad_to_deg(body.rotation.y), 360.0)
		rec["state"] = "placed"
		rec["stack_level"] = int(result.get("stack_level", 0))
		rec["settle"] = false
		if bool(node.get("safe_ready")):
			var safe: Vector3 = node.get("safe_spot")
			rec["safe_x"] = safe.x
			rec["safe_y"] = safe.y
			rec["safe_z"] = safe.z
			rec["safe_rot"] = rad_to_deg(float(node.get("safe_yaw")))
	_squash_uid(id)
	if GameState.mode == "job_unpack":
		if stack_room:
			GameState.job["room_score"] = stack_room.score()
		_maybe_job_done()
	elif GameState.mode == "office":
		_maybe_live()
	if id == _settle_uid:
		settling = false
		_settle_uid = ""
	_check_goals()
	SaveManager.save_game()


func _record_for(uid: String) -> Dictionary:
	var office := GameState.find_office_item(uid)
	if not office.is_empty():
		return office
	return GameState.job_item(uid)


func _maybe_live() -> void:
	if GameState.office_phase == "live":
		return
	for item in GameState.office_items:
		if str(item.get("state", "")) != "placed":
			return
	GameState.office_phase = "live"
	GameState.mark_tutorial_live()
	_toast("Clipboard's pinned by the bench. Your first job is on it. Go on.", "Marge")
	_refresh_hud_buttons()
	SaveManager.save_game()
	# The first job is in the player's hand within minutes: open the board.
	call_deferred("_open_jobs")


func _pack_click(uid: String) -> void:
	if uid == "":
		return
	if uid.begins_with("boxpack:"):
		var pick := int(uid.trim_prefix("boxpack:"))
		if bool(GameState.job_box(pick).get("sealed", false)):
			_toast("Box %d is sealed. Pick an open one, or start a new box." % (pick + 1))
		else:
			selected_box = pick
			_toast("Using box %d." % (pick + 1))
			AudioDirector.play_sfx("sfx_box_fold", true)
		_refresh_items()
		_refresh_hud_buttons()
		return
	var item := GameState.job_item(uid)
	if item.is_empty() or str(item.get("state", "")) != "loose":
		return
	if bool(item.get("nobox", false)):
		if GameState.job.get("boxes", []).size() >= slot_count:
			_toast("The truck only takes %d pieces and boxes." % slot_count)
			AudioDirector.play_sfx("sfx_invalid_placement")
			return
		var wrap_err := GameState.wrap_big(uid)
		if wrap_err != "":
			_toast(wrap_err)
			return
		AudioDirector.play_sfx("sfx_paper_rustle")
		AudioDirector.play_sfx("sfx_tape_rip")
		_toast("Too big for a box. Blanket round it, straight onto the truck.")
		_refresh_items()
		_refresh_hud_buttons()
		return
	var box_id := selected_box
	if box_id < 0 or GameState.job_box(box_id).is_empty() or bool(GameState.job_box(box_id).get("sealed", false)):
		box_id = GameState.ensure_open_box()
		selected_box = box_id
	var err := GameState.pack_into(uid, box_id)
	if err != "":
		_toast(err)
		AudioDirector.play_sfx("sfx_invalid_placement")
		return
	AudioDirector.play_sfx("sfx_item_pick_up")
	AudioDirector.play_sfx("sfx_box_fold", true)
	var packed := str(item.get("item_id", ""))
	if packed == "cafe_mug":
		AudioDirector.play_sfx("sfx_l02_cup_clink")
	elif packed == "mystery_part":
		AudioDirector.play_sfx("sfx_l04_parts_rattle")
	_refresh_items()
	_refresh_hud_buttons()


func _truck_click(uid: String) -> void:
	if not uid.begins_with("slot:"):
		return
	var slot := int(uid.trim_prefix("slot:"))
	if selected_box < 0:
		if GameState.slot_taken(slot):
			# Take it back off the truck and hold it.
			for box in GameState.job.get("boxes", []):
				if int(box.get("slot", -1)) == slot:
					box["slot"] = -1
					selected_box = int(box.get("id", -1))
			AudioDirector.play_sfx("sfx_item_pick_up")
			_toast("Box %d is back in your hands. Tap another pad." % (selected_box + 1))
			_refresh_items()
			_sync_cargo()
			_refresh_hud_buttons()
			return
		_toast("Pick a sealed box first.")
		return
	var err := GameState.load_box_into(selected_box, slot, floor_slots)
	if err != "":
		_toast(err)
		AudioDirector.play_sfx("sfx_invalid_placement")
		return
	selected_box = -1
	_refresh_hud_buttons()
	_sync_pile()
	# Dana carries it from the pile to the bed; the box lands on the pad when she gets there.
	if player != null and is_instance_valid(player) and truck_root != null:
		truck_pending = true
		player_carrying = true
		var local := _slot_pos(slot)
		var bed := truck_root.to_global(Vector3(local.x - 1.35, 0.0, local.z))
		player_target = bed
		player_moving = true
		player_on_arrive = func():
			truck_pending = false
			player_carrying = false
			AudioDirector.play_sfx("sfx_box_set_down", true)
			_refresh_items()
			_sync_cargo()
			_refresh_hud_buttons()
			player_target = Vector3(1.6, 0.0, -0.9)
			player_moving = true
		return
	AudioDirector.play_sfx("sfx_box_set_down", true)
	_refresh_items()
	_sync_cargo()
	_refresh_hud_buttons()


func _unpack_click(uid: String) -> void:
	if uid == "stairs" and _is_home():
		_use_stairs()
		return
	if uid.begins_with("owner:"):
		_open_owner_card(uid)
		return
	if uid.begins_with("boxcarry:"):
		var box_id := int(uid.trim_prefix("boxcarry:"))
		carried[box_id] = true
		if str(GameState.job_box(box_id).get("big", "")) != "":
			# A wrapped piece: the blanket comes off and it stands where the box row would be.
			var big := GameState.job_item(str(GameState.job_box(box_id)["big"]))
			_loosen(big, box_id, 0)
			AudioDirector.play_sfx("sfx_paper_rustle")
		var saved: Array = GameState.job.get("carried", [])
		if not saved.has(box_id):
			saved.append(box_id)
		GameState.job["carried"] = saved
		SaveManager.save_game()
		AudioDirector.play_sfx("sfx_footstep_office")
		AudioDirector.play_sfx("sfx_box_set_down", true)
		_refresh_items()
		_refresh_hud_buttons()
		return
	if uid.begins_with("boxopen:"):
		var open_id := int(uid.trim_prefix("boxopen:"))
		var open_box := GameState.job_box(open_id)
		if int(open_box.get("tower", -1)) >= 0:
			var top_id := _tower_top(int(open_box.get("tower", 0)))
			if top_id != open_id and top_id >= 0:
				_toast("Top box first. That's box %d." % (top_id + 1))
				open_id = top_id
		_open_box_modal(open_id)
		return
	if held_uid == "":
		var item := GameState.job_item(uid)
		if item.is_empty():
			return
		if not bool(carried.get(int(item.get("box", -1)), false)):
			_toast("Carry that box in from the truck first.")
			return
		var job_state := str(item.get("state", ""))
		if job_state == "placed" or job_state == "loose":
			_take_to_hand(item, "job")
		return
	_try_place_held()


func _open_carried_box(box_id: int) -> void:
	# Tip the box out: its items turn loose on the floor behind where it sat.
	_party_react("tipped", {})
	var n := 0
	for item in GameState.job.get("items", []):
		if int(item.get("box", -1)) != box_id or str(item.get("state", "")) != "boxed":
			continue
		item["state"] = "loose"
		var at := _spill_spot(box_id, n)
		item["x"] = at.x
		item["z"] = at.z
		item["y"] = 0.0
		n += 1
	AudioDirector.play_sfx("sfx_box_open")
	AudioDirector.play_sfx("sfx_paper_rustle")
	var box := GameState.job_box(box_id)
	if not box.is_empty() and bool(box.get("has_cat", false)) and not bool(GameState.job.get("cat_opened", false)):
		_open_cat(box_id)
	_refresh_items()
	_refresh_hud_buttons()


func _box_contents(box_id: int) -> Array:
	var out: Array = []
	for item in GameState.job.get("items", []):
		if int(item.get("box", -1)) == box_id and str(item.get("state", "")) == "boxed":
			out.append(item)
	return out


func _open_box_modal(box_id: int) -> void:
	# What's in the box, and three ways to get it out: take one in hand, set
	# one down right here, or tip the lot out and sort it on the floor.
	var contents := _box_contents(box_id)
	if OS.get_environment("CO_DEBUG") != "":
		print("  open box modal %d: %d inside, settling=%s held=%s" % [box_id, contents.size(), settling, held_uid])
	if contents.is_empty() or str(GameState.job_box(box_id).get("big", "")) != "":
		_open_carried_box(box_id)
		return
	var layer := _hud_layer()
	var old := layer.get_node_or_null("BoxModal")
	if old != null:
		layer.remove_child(old)
		old.queue_free()
	var panel := Panel.new()
	panel.name = "BoxModal"
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 18))
	layer.add_child(panel)
	var card_size := Vector2(900, 620)
	UIKit.pin_center(panel, card_size)
	var box := GameState.job_box(box_id)
	var title := UIKit.label("Box %d" % (box_id + 1), 40, UIKit.DARK, "title", false)
	title.position = Vector2(24, 16)
	panel.add_child(title)
	var tags: Array = []
	if int(box.get("tower", -1)) >= 0:
		var below := int(box.get("level", 0))
		tags.append("top of a stack of %d" % (below + 1) if below > 0 else "bottom of a stack")
	if bool(box.get("padded", false)):
		tags.append("padded")
	if bool(box.get("has_cat", false)) and not bool(GameState.job.get("cat_opened", false)):
		tags.append("something is purring")
	var sub := UIKit.label("%d piece%s inside%s" % [contents.size(), "" if contents.size() == 1 else "s", ("  ·  " + ", ".join(tags)) if not tags.is_empty() else ""], 24, UIKit.WOOD, "small", false)
	sub.position = Vector2(200, 30)
	panel.add_child(sub)
	var close := UIKit.button("Close", UIKit.DARK)
	close.position = Vector2(card_size.x - 184, 16)
	close.size = Vector2(160, 56)
	close.custom_minimum_size = Vector2(160, 56)
	close.pressed.connect(panel.queue_free)
	panel.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 84)
	scroll.size = Vector2(card_size.x - 48, card_size.y - 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	rows.custom_minimum_size = Vector2(card_size.x - 72, 0)
	scroll.add_child(rows)
	for item in contents:
		rows.add_child(_box_row(item, box_id, card_size.x - 72))
	var foot := HBoxContainer.new()
	foot.position = Vector2(24, card_size.y - 76)
	foot.add_theme_constant_override("separation", 12)
	panel.add_child(foot)
	var tip := UIKit.button("Tip it out", UIKit.TERRA)
	tip.custom_minimum_size = Vector2(200, 56)
	tip.pressed.connect(func():
		panel.queue_free()
		_open_carried_box(box_id)
	)
	foot.add_child(tip)
	var auto := UIKit.button("Put it all away for me", UIKit.SAGE)
	auto.disabled = auto_busy
	auto.custom_minimum_size = Vector2(320, 56)
	auto.pressed.connect(func():
		panel.queue_free()
		_auto_unpack_box(box_id)
	)
	foot.add_child(auto)
	var hint := UIKit.label("Take: carry it to a spot. Set here: next to the box.", 24, UIKit.WOOD, "small", false)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(hint)
	var focus_buttons: Array = [close]
	for child in rows.get_children():
		for kid in child.get_children():
			if kid is Button:
				focus_buttons.append(kid)
	focus_buttons.append(tip)
	focus_buttons.append(auto)
	UIKit.link_focus(focus_buttons)
	AudioDirector.play_sfx("sfx_paper_rustle")


func _box_row(item: Dictionary, box_id: int, width: float) -> PanelContainer:
	var card := PanelContainer.new()
	var box := UIKit.style(Color("F6EEDC"), 12)
	box.shadow_size = 0
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(width, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name := UIKit.label(str(item.get("name", "")), 28, UIKit.DARK, "title", false)
	name.custom_minimum_size = Vector2(320, 36)
	name.clip_text = true
	text.add_child(name)
	var bits: Array = []
	for flag in ["fragile", "heavy", "bulky"]:
		if bool(item.get(flag, false)):
			bits.append(flag)
	var mount := str(item.get("mount", "floor"))
	bits.append({"hang": "goes on a wall", "wall_floor": "stands by a wall", "small": "sits on things"}.get(mount, "stands on the floor"))
	if int(item.get("damage", 0)) > 0:
		bits.append("scuffed")
	text.add_child(UIKit.label(", ".join(bits), 24, UIKit.WOOD, "small", false))
	var flavor := str(ItemDB.get_item(str(item.get("item_id", ""))).get("flavor", ""))
	if flavor != "":
		var note := UIKit.label(flavor, 24, UIKit.BLUE, "small", false)
		note.custom_minimum_size = Vector2(480, 0)
		note.clip_text = true
		text.add_child(note)
	var uid := str(item.get("uid", ""))
	var take := UIKit.button("Take", UIKit.TERRA)
	take.custom_minimum_size = Vector2(130, 52)
	take.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	take.pressed.connect(func():
		var modal := _hud_layer().get_node_or_null("BoxModal")
		if modal:
			modal.queue_free()
		_take_from_box(uid, box_id)
	)
	row.add_child(take)
	var here := UIKit.button("Set here", UIKit.SAGE)
	here.custom_minimum_size = Vector2(150, 52)
	here.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	here.pressed.connect(func():
		_set_from_box(uid, box_id)
		_open_box_modal(box_id)
	)
	row.add_child(here)
	return card


func _loosen(item: Dictionary, box_id: int, index: int) -> void:
	item["state"] = "loose"
	arrive_from[str(item.get("uid", ""))] = _open_box_spot(box_id) + Vector3(0, 0.35, 0)
	var at := _spill_spot(box_id, index)
	item["x"] = at.x
	item["z"] = at.z
	item["y"] = 0.0
	if _is_home():
		item["floor"] = home_floor
	if int(item.get("damage", 0)) > 0:
		_party_react("scuff", {"item": str(item.get("name", "piece")).to_lower()})
	var box := GameState.job_box(box_id)
	if not box.is_empty() and bool(box.get("has_cat", false)) and not bool(GameState.job.get("cat_opened", false)):
		_open_cat(box_id)


func _take_from_box(uid: String, box_id: int) -> void:
	var item := GameState.job_item(uid)
	if item.is_empty():
		return
	_loosen(item, box_id, 0)
	AudioDirector.play_sfx("sfx_box_open")
	_refresh_items()
	_take_to_hand(item, "job")
	_refresh_hud_buttons()
	_toast("Click where it should live. R turns it.")


func _set_from_box(uid: String, box_id: int) -> void:
	var item := GameState.job_item(uid)
	if item.is_empty():
		return
	_loosen(item, box_id, 0)
	_refresh_items()
	if not _auto_place_item(item):
		_toast("No room next to the box for that. Take it instead.")
	else:
		AudioDirector.play_sfx("sfx_item_snap", true)
	_refresh_items()
	_unhide_loose()
	_refresh_hud_buttons()
	_maybe_job_done()


func _auto_unpack_box(box_id: int) -> void:
	# Dana puts the lot away herself, piece by piece: to the box, a piece out,
	# across the room, down. See the auto queue below.
	_auto_unpack([box_id])


# ------------------------------------------------------------ the auto queue
# "Unpack it all" and "Pack the rest" are not instant: Dana walks to each
# box or piece, lifts it, carries it over and sets it down, one step at a
# time. Her hands are only as good as her handling level, so a low-level
# helper drops the odd piece: it chips, the owner sees, and after enough of
# them the owner comes over and shoves her. Then there is the small claims
# court. See GameState.handling_level, roll_break and sue_owner.

var auto_queue: Array = []
var auto_busy := false
var auto_mode := ""
var auto_hold := false
var auto_missed := 0
var auto_handled := 0
var auto_box_opened := -1
var break_bias := 0.0
var break_force := 0
var auto_fast := OS.get_environment("CO_FAST_DRIVE") != ""


func _auto_pace() -> float:
	return 0.06 if auto_fast else 0.35


func _auto_unpack(box_ids: Array) -> void:
	if auto_busy:
		return
	var steps: Array = []
	for box_id in box_ids:
		for item in _box_contents(int(box_id)):
			steps.append({"kind": "unpack", "box": int(box_id), "uid": str(item.get("uid", ""))})
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) == "loose":
			steps.append({"kind": "lift", "uid": str(item.get("uid", ""))})
	if steps.is_empty():
		_toast("Nothing left to put away.")
		return
	_auto_start(steps, "job_unpack")
	_toast("Right. I'll do the lot. Shout if you want anything moved.")


func _auto_start(steps: Array, mode: String) -> void:
	auto_queue = steps
	auto_busy = true
	auto_hold = false
	auto_mode = mode
	auto_missed = 0
	auto_handled = 0
	auto_box_opened = -1
	_refresh_hud_buttons()
	_auto_next()


func _auto_next() -> void:
	if not auto_busy or auto_hold:
		return
	if not is_inside_tree() or GameState.mode != auto_mode or auto_queue.is_empty():
		_auto_finish()
		return
	var step: Dictionary = auto_queue.pop_front()
	match str(step.get("kind", "")):
		"unpack":
			_auto_walk(_open_box_spot(int(step["box"])), _auto_take_out.bind(step))
		"carry":
			var spot: Dictionary = step["spot"]
			_auto_walk(Vector3(float(spot["x"]), 0.0, float(spot["z"])), _auto_set_down.bind(step))
		"lift":
			var item := GameState.job_item(str(step["uid"]))
			if item.is_empty() or str(item.get("state", "")) != "loose":
				_auto_after()
				return
			_auto_walk(Vector3(float(item.get("x", 0.0)), 0.0, float(item.get("z", 0.0))), _auto_lift.bind(step))
		"pack_pick":
			var item := GameState.job_item(str(step["uid"]))
			if item.is_empty() or str(item.get("state", "")) != "loose":
				_auto_after()
				return
			_auto_walk(Vector3(float(item.get("x", 0.0)), 0.0, float(item.get("z", 0.0))), _auto_pack_pick.bind(step))
		"pack_drop":
			_auto_walk(_pack_box_spot(GameState.ensure_open_box()), _auto_pack_drop.bind(step))
		_:
			_auto_after()


func _auto_walk(at: Vector3, then: Callable) -> void:
	_player_go(at)
	if player != null and is_instance_valid(player) and player_moving:
		player_on_arrive = then
	else:
		get_tree().create_timer(_auto_pace()).timeout.connect(then)


func _auto_after() -> void:
	# A beat between steps so each lift and set-down reads.
	if not is_inside_tree():
		return
	get_tree().create_timer(_auto_pace()).timeout.connect(_auto_next)


func _auto_take_out(step: Dictionary) -> void:
	# At the box: one piece out, find it a home, carry it over.
	var box_id := int(step["box"])
	var item := GameState.job_item(str(step["uid"]))
	if item.is_empty() or str(item.get("state", "")) != "boxed":
		_auto_after()
		return
	if auto_box_opened != box_id:
		auto_box_opened = box_id
		AudioDirector.play_sfx("sfx_box_open")
	_loosen(item, box_id, GameState.box_item_count(box_id))
	_refresh_items()
	_auto_lift(step)


func _auto_lift(step: Dictionary) -> void:
	# A loose piece into Dana's arms, with its spot already picked.
	var item := GameState.job_item(str(step["uid"]))
	if item.is_empty() or str(item.get("state", "")) != "loose":
		_auto_after()
		return
	if not _auto_place_item(item):
		auto_missed += 1
		_refresh_items()
		_unhide_loose()
		_auto_after()
		return
	var spot := {"x": item["x"], "y": item["y"], "z": item["z"], "rot": item.get("rot", 0.0), "wall": item.get("wall", ""), "floor": item.get("floor", home_floor)}
	item["state"] = "hand"
	player_carrying = true
	AudioDirector.play_sfx("sfx_item_pick_up", true)
	_refresh_items()
	auto_queue.push_front({"kind": "carry", "uid": str(step["uid"]), "spot": spot})
	_auto_after()


func _auto_set_down(step: Dictionary) -> void:
	# Across the room: the piece lands where it was going, unless it slips.
	var item := GameState.job_item(str(step["uid"]))
	player_carrying = false
	if item.is_empty():
		_auto_after()
		return
	var spot: Dictionary = step["spot"]
	for key in ["x", "y", "z", "rot", "wall", "floor"]:
		item[key] = spot[key]
	item["state"] = "placed"
	item["settle"] = false
	var uid := str(step["uid"])
	if player != null and is_instance_valid(player):
		arrive_from[uid] = player.position + Vector3(0, 0.8, 0)
	_last_placed_uid = uid
	auto_handled += 1
	_note_handled()
	var broke := _auto_roll_break(item)
	AudioDirector.play_sfx("sfx_item_snap", true)
	_refresh_items()
	_unhide_loose()
	if broke:
		_break_piece(item, Vector3(float(item["x"]), float(item["y"]), float(item["z"])))
	else:
		_party_on_place()
	_maybe_job_done()
	_auto_after()


func _auto_roll_break(item: Dictionary) -> bool:
	if break_force > 0:
		break_force -= 1
		return GameState.roll_break(item, 1.0)
	return GameState.roll_break(item, break_bias)


func _note_handled() -> void:
	var level := GameState.note_handled()
	if level >= 0:
		_toast("Handling level %d. Steadier hands." % level, "Dana")
		AudioDirector.play_sfx("sfx_level_up_hands")


func _auto_finish() -> void:
	var was := auto_mode
	auto_queue.clear()
	auto_busy = false
	auto_hold = false
	player_carrying = false
	if not is_inside_tree():
		return
	if was == "job_pack":
		_pack_finish()
	elif was == "job_unpack":
		_refresh_items()
		_unhide_loose()
		if auto_missed > 0:
			_toast("%d piece%s wouldn't fit anywhere tidy. They're on the floor." % [auto_missed, "" if auto_missed == 1 else "s"])
		elif auto_handled > 0:
			_toast("All put away. Nudge anything you'd rather have elsewhere.")
		_maybe_job_done()
	_refresh_hud_buttons()


# Packing: Dana goes to each loose piece, lifts it, carries it to the open
# box and sets it in. Big pieces are wrapped where they stand.

func _pack_box_spot(box_id: int) -> Vector3:
	var i := 0
	for box in GameState.job.get("boxes", []):
		if int(box.get("id", -1)) == box_id:
			break
		i += 1
	return Vector3(float(venue.get("x", 0)) + 0.8 + float(i) * 0.6, 0.0, float(venue.get("z", 0)) + 0.8)


func _auto_pack_pick(step: Dictionary) -> void:
	var item := GameState.job_item(str(step["uid"]))
	if item.is_empty() or str(item.get("state", "")) != "loose":
		_auto_after()
		return
	if bool(item.get("nobox", false)):
		if GameState.job.get("boxes", []).size() >= slot_count:
			auto_missed += 1
		elif GameState.wrap_big(str(item.get("uid", ""))) == "":
			auto_handled += 1
			_note_handled()
			AudioDirector.play_sfx("sfx_tape_rip", true)
			_refresh_items()
		_auto_after()
		return
	player_carrying = true
	item["state"] = "hand"
	AudioDirector.play_sfx("sfx_item_pick_up", true)
	_refresh_items()
	auto_queue.push_front({"kind": "pack_drop", "uid": str(step["uid"])})
	_auto_after()


func _auto_pack_drop(step: Dictionary) -> void:
	var item := GameState.job_item(str(step["uid"]))
	player_carrying = false
	if item.is_empty():
		_auto_after()
		return
	item["state"] = "loose"
	var uid := str(step["uid"])
	var box_id := GameState.ensure_open_box()
	if GameState.job.get("boxes", []).size() > slot_count:
		auto_missed += 1
		_refresh_items()
		_auto_after()
		return
	var err := GameState.pack_into(uid, box_id)
	if err != "":
		GameState.seal_box(box_id)
		box_id = GameState.make_box()
		err = GameState.pack_into(uid, box_id)
	if err != "":
		auto_missed += 1
		_refresh_items()
		_auto_after()
		return
	auto_handled += 1
	_note_handled()
	selected_box = box_id
	var broke := _auto_roll_break(item)
	AudioDirector.play_sfx("sfx_box_set_down", true)
	if GameState.box_item_count(box_id) >= 5:
		GameState.seal_box(box_id)
		AudioDirector.play_sfx("sfx_tape_rip", true)
	_refresh_items()
	if broke:
		_break_piece(item, _pack_box_spot(box_id) + Vector3(0, 0.3, 0))
	_auto_after()


func _pack_finish() -> void:
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", 0))
		if GameState.box_needs_padding(id):
			box["padded"] = true
		if not bool(box.get("sealed", false)) and GameState.box_item_count(id) > 0:
			GameState.seal_box(id)
	selected_box = -1
	AudioDirector.play_sfx("sfx_tape_rip")
	_refresh_items()
	var left: Array = []
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "boxed":
			left.append("%s:%s" % [str(item.get("uid", "")), str(item.get("state", ""))])
	print("auto pack: %d handled, %d missed, %d boxes of %d, not boxed: %s" % [auto_handled, auto_missed, GameState.job.get("boxes", []).size(), slot_count, ", ".join(left)])
	if auto_missed > 0:
		_toast("%d piece%s wouldn't go in. The truck only takes so many boxes." % [auto_missed, "" if auto_missed == 1 else "s"])
	else:
		_toast("Boxed, padded and sealed. Truck next.")


# Breakages: a piece slips, shards fly, the owner sees.

func _break_piece(item: Dictionary, at: Vector3) -> void:
	var label := str(item.get("name", "piece"))
	AudioDirector.play_sfx("sfx_glass_smash" if bool(item.get("fragile", false)) else "sfx_crockery_crack", true)
	AudioDirector.play_sfx("sfx_gasp_small")
	_shards(at)
	if player != null and is_instance_valid(player):
		_act(player, "flinch", 1.3)
	_toast("That was the %s. That's chipped now." % label.to_lower(), "Dana")
	_refresh_hud_buttons()
	if party == null or not is_instance_valid(party):
		return
	party.react("broken", {"item": label.to_lower()}, true)
	AudioDirector.play_sfx("sfx_angry_mutter", true)
	party.temper += 1
	if party.temper >= GameState.temper_limit() and not bool(GameState.job.get("attacked", false)):
		_owner_attack()


func _shards(at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	for i in 7:
		var bit := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.06, 0.02, 0.05)
		bit.mesh = mesh
		bit.material_override = Props.mat(Color("E9E2D3") if i % 2 == 0 else Color("B8AC98"))
		bit.position = Vector3(0, 0.3, 0)
		root.add_child(bit)
		var ang := float(i) * TAU / 7.0 + 0.3
		var land := Vector3(cos(ang) * (0.25 + 0.08 * float(i % 3)), 0.01, sin(ang) * (0.25 + 0.08 * float(i % 3)))
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(bit, "position", land, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(bit, "rotation", Vector3(randf() * 3.0, randf() * 3.0, randf() * 3.0), 0.45)
	_dust(at)
	get_tree().create_timer(3.0).timeout.connect(root.queue_free)


func _owner_attack() -> void:
	# The owner has had enough: over to Dana, two hands, and down she goes.
	if party == null or not is_instance_valid(party) or player == null or not is_instance_valid(player):
		return
	var who: Node3D = party.speaker("attack")
	for person in party.members:
		if is_instance_valid(person) and not bool(person.get_meta("kid", false)):
			who = person
			break
	if who == null:
		return
	GameState.job["attacked"] = true
	GameState.bump_stat("attacked")
	auto_hold = true
	party.react("attack", {}, true, str(who.get_meta("uid", "")))
	var to := player.position - who.position
	to.y = 0.0
	var stand := player.position - to.normalized() * 0.7
	var seconds := maxf(0.4, to.length() / 2.2)
	who.set_meta("walking", true)
	var tw := create_tween()
	tw.tween_property(who, "position", stand, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_owner_shove.bind(who))


func _owner_shove(who: Node3D) -> void:
	if not is_instance_valid(who) or player == null or not is_instance_valid(player):
		auto_hold = false
		_auto_next()
		return
	who.set_meta("walking", false)
	who.look_at(player.position, Vector3.UP)
	who.rotate_y(PI)
	_act(who, "shove", 1.6)
	AudioDirector.play_sfx("sfx_shove_grunt")
	get_tree().create_timer(0.45).timeout.connect(_dana_down)
	get_tree().create_timer(2.0).timeout.connect(_owner_return.bind(who))


func _owner_return(who: Node3D) -> void:
	# Back to the door, still fuming, so the room is clickable again.
	if not is_instance_valid(who):
		return
	var home: Vector3 = who.get_meta("home_pos", who.position)
	var seconds := maxf(0.3, who.position.distance_to(home) / 2.0)
	who.set_meta("walking", true)
	var tw := create_tween()
	tw.tween_property(who, "position", home, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		if is_instance_valid(who):
			who.set_meta("walking", false)
			who.rotation.y = float(who.get_meta("home_yaw", who.rotation.y))
	)


func _dana_down() -> void:
	if player == null or not is_instance_valid(player):
		return
	player.set_meta("down", true)
	player.set_meta("action", "")
	AudioDirector.play_sfx("sfx_body_fall")
	_dust(player.position)
	_toast("Hey! HEY. There are witnesses, you know.", "Dana")
	get_tree().create_timer(2.2).timeout.connect(func():
		if player != null and is_instance_valid(player):
			player.set_meta("down", false)
		_open_sue_card()
	)


func _open_sue_card() -> void:
	# After the shove: small claims, or let it go. The more Dana sues, the
	# likelier the next one comes back as a fraud claim ten times over.
	var layer := _hud_layer()
	if layer == null:
		auto_hold = false
		_auto_next()
		return
	var old := layer.get_node_or_null("SueCard")
	if old != null:
		layer.remove_child(old)
		old.free()
	AudioDirector.play_sfx("sfx_gavel")
	var card := PanelContainer.new()
	card.name = "SueCard"
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16, 4, UIKit.NIGHT))
	layer.add_child(card)
	card.layout_mode = 1
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_left = -380
	card.offset_right = 380
	card.offset_top = -140
	card.offset_bottom = 140
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	column.add_child(head)
	head.add_child(UIKit.ribbon("Shoved", UIKit.NIGHT, 30))
	var client := str(GameState.job.get("def", {}).get("client", "The client"))
	var title := UIKit.label("%s put two hands on you" % client, 30, UIKit.DARK, "title", false)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var suits := int(GameState.stats.get("lawsuits", 0))
	var line := "In front of witnesses. Small claims would pay $%d to $%d for that." % [int(Tuning.get_value("handling.sue_min", 1000)), int(Tuning.get_value("handling.sue_max", 2000))]
	if suits == 1:
		line += " You have sued once before. A second file looks like a habit."
	elif suits > 1:
		line += " You have sued %d people. Courts notice a mover who keeps dropping things and keeps getting shoved. Fraud claims come back ten times over." % suits
	var blurb := UIKit.label(line, 25, UIKit.DARK, "small")
	blurb.custom_minimum_size = Vector2(700, 0)
	column.add_child(blurb)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	column.add_child(foot)
	var close := func():
		if is_instance_valid(card):
			layer.remove_child(card)
			card.queue_free()
		auto_hold = false
		_refresh_hud_buttons()
		_auto_next()
	var leave := UIKit.button("Let it go", UIKit.SAGE)
	leave.name = "SueLeave"
	leave.custom_minimum_size = Vector2(200, 54)
	leave.pressed.connect(func():
		_toast("Fine. Let's just finish and go.", "Dana")
		close.call()
	)
	foot.add_child(leave)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	var sue := UIKit.button("Sue them", UIKit.NIGHT)
	sue.name = "SueFile"
	sue.custom_minimum_size = Vector2(220, 54)
	sue.pressed.connect(func():
		var result: Dictionary = GameState.sue_owner()
		if result.has("error"):
			_toast(str(result["error"]), "Dana")
		elif bool(result.get("countered", false)):
			AudioDirector.play_sfx("sfx_letter_open")
			AudioDirector.play_sfx("sfx_trade_loss_thud")
			_toast("Counter-sued. Fraud, they said. $%d and two rep stars gone. There's a letter." % int(result.get("penalty", 0)), "Dana")
		else:
			AudioDirector.play_sfx("sfx_coins_award")
			_toast("Small claims says $%d. Lovely." % int(result.get("amount", 0)), "Dana")
		close.call()
	)
	foot.add_child(sue)


func _place_office_all() -> void:
	# Tired of the tutorial: the starter pieces find their own spots.
	var pending: Array = []
	for rec in GameState.office_items:
		if str(rec.get("state", "")) != "placed":
			pending.append(rec)
	# Furniture first, then wall pieces, then the desk-top bits, so small things have a desk to land on.
	pending.sort_custom(func(a, b):
		var order := {"floor": 0, "wall_floor": 1, "hang": 2, "small": 3}
		var ma := str(ItemDB.get_item(str(a.get("item", ""))).get("mount", "floor"))
		var mb := str(ItemDB.get_item(str(b.get("item", ""))).get("mount", "floor"))
		return int(order.get(ma, 0)) < int(order.get(mb, 0))
	)
	var missed := 0
	for rec in pending:
		rec["state"] = "loose"
		if not rec.has("x"):
			rec["x"] = float(venue.get("x", 0)) + 2.0
			rec["z"] = float(venue.get("z", 0)) + 2.0
		if not _auto_place_item(rec, "office"):
			missed += 1
		_refresh_items()
	GameState.note_first_place()
	AudioDirector.play_sfx("sfx_item_snap", true)
	_refresh_items()
	_refresh_hud_buttons()
	if missed > 0:
		_toast("%d piece%s wouldn't fit anywhere tidy. Set those by hand." % [missed, "" if missed == 1 else "s"])
	_maybe_live()


func _auto_place_item(item: Dictionary, source := "job") -> bool:
	# Try spots spiralling out from where the piece lies, using the same
	# snap rules a click would, so nothing lands inside a wall or another piece.
	var uid := str(item.get("uid", ""))
	arrive_from[uid] = Vector3(float(item.get("x", 0.0)), float(item.get("y", 0.0)) + 0.3, float(item.get("z", 0.0)))
	var was_held := held_uid
	var was_source := held_source
	var was_rot := held_rot
	held_uid = uid
	held_source = source
	held_rot = float(item.get("rot", 0.0))
	item["state"] = "hand"
	var mount := str(item.get("mount", "floor"))
	var candidates: Array = []
	if mount == "hang" or mount == "wall_floor":
		for point in _wall_points():
			if str(point["kind"]) != mount:
				continue
			candidates.append(Vector3(float(point["x"]), float(point["y"]), float(point["z"])) + (point["normal"] as Vector3) * 0.3)
	else:
		var origin := Vector3(float(item.get("x", 1.0)), 0.0, float(item.get("z", 1.0)))
		var x0 := float(venue.get("x", 0))
		var z0 := float(venue.get("z", 0))
		var w := float(venue.get("w", 6))
		var d := float(venue.get("d", 8))
		var ring := 0.0
		while ring < maxf(w, d):
			var step := 0.5
			# Only spots no nearer the camera than where the piece lies (x + z no
			# larger), so nothing ends up between the carried boxes and the camera.
			var limit := origin.x + origin.z + 0.01
			var ax := origin.x - ring
			while ax <= origin.x + ring + 0.01:
				for az in [origin.z - ring, origin.z + ring]:
					if ax + float(az) <= limit and ax > x0 + 0.5 and ax < x0 + w - 0.5 and float(az) > z0 + 0.5 and float(az) < z0 + d - 0.5:
						candidates.append(Vector3(ax, 0.0, float(az)))
				ax += step
			var az2 := origin.z - ring + step
			while az2 < origin.z + ring - 0.01:
				for ax2 in [origin.x - ring, origin.x + ring]:
					if float(ax2) + az2 <= limit and float(ax2) > x0 + 0.5 and float(ax2) < x0 + w - 0.5 and az2 > z0 + 0.5 and az2 < z0 + d - 0.5:
						candidates.append(Vector3(float(ax2), 0.0, az2))
				az2 += step
			ring += step
	var placed := false
	for hit in candidates:
		var spot: Dictionary = _snap_point(hit)
		if not bool(spot["valid"]):
			continue
		var on_wall := str(spot.get("wall", "")) != ""
		item["x"] = spot["pos"].x
		item["y"] = spot["pos"].y
		item["z"] = spot["pos"].z
		item["rot"] = spot["rot"]
		item["wall"] = spot.get("wall", "")
		item["state"] = "placed"
		item["settle"] = false
		if _is_home():
			item["floor"] = home_floor
		placed = true
		break
	if not placed:
		item["state"] = "loose"
	held_uid = was_held
	held_source = was_source
	held_rot = was_rot
	return placed


func _pack_rest() -> void:
	# Tired of packing: Dana boxes everything still loose herself, piece by
	# piece, pads the fragile boxes, seals the lot, and the truck is next.
	if auto_busy:
		return
	var steps: Array = []
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) == "loose":
			steps.append({"kind": "pack_pick", "uid": str(item.get("uid", ""))})
	if steps.is_empty():
		_pack_finish()
		_refresh_hud_buttons()
		return
	_auto_start(steps, "job_pack")
	_toast("Leave it with me. Fragile ones get a wrap.")
	AudioDirector.play_sfx("sfx_box_fold", true)
	_refresh_items()
	_refresh_hud_buttons()
	if GameState.all_sealed():
		_toast("Boxed, padded, taped. Load the truck when you're ready.")
	else:
		_toast("The truck only takes %d boxes. Some pieces will have to wait." % slot_count)


func _stack_boxes() -> void:
	# Pile the carried, still-packed boxes into towers of three, in id order,
	# so the floor behind them is clear for the pieces that come out.
	_party_react("stacked", {})
	AudioDirector.play_sfx("sfx_box_scrape", true)
	var packed: Array = []
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", -1))
		if bool(carried.get(id, false)) and _box_still_packed(id):
			packed.append(box)
	var n := 0
	for box in packed:
		box["tower"] = int(n / 3)
		box["level"] = n % 3
		n += 1
	AudioDirector.play_sfx("sfx_box_set_down", true)
	_refresh_items()
	_refresh_hud_buttons()
	SaveManager.save_game()


func _normalize_towers() -> void:
	# A box that has been emptied leaves its tower; the boxes above settle down.
	var towers := {}
	for box in GameState.job.get("boxes", []):
		var tower := int(box.get("tower", -1))
		if tower < 0:
			continue
		var id := int(box.get("id", -1))
		if not (bool(carried.get(id, false)) and _box_still_packed(id)):
			box.erase("tower")
			box.erase("level")
			continue
		if not towers.has(tower):
			towers[tower] = []
		towers[tower].append(box)
	for tower in towers.keys():
		var column: Array = towers[tower]
		column.sort_custom(func(a, b): return int(a.get("level", 0)) < int(b.get("level", 0)))
		for level in column.size():
			column[level]["level"] = level


func _tower_top(tower: int) -> int:
	var top_id := -1
	var top_level := -1
	for box in GameState.job.get("boxes", []):
		if int(box.get("tower", -1)) == tower and int(box.get("level", 0)) > top_level:
			top_level = int(box.get("level", 0))
			top_id = int(box.get("id", -1))
	return top_id


func _stackable_count() -> int:
	var count := 0
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", -1))
		if bool(carried.get(id, false)) and _box_still_packed(id) and int(box.get("tower", -1)) < 0:
			count += 1
	return count


func _open_box_spot(box_id: int) -> Vector3:
	var index := 0
	var level := 0
	for box in GameState.job.get("boxes", []):
		if int(box.get("id", -1)) == box_id:
			if int(box.get("tower", -1)) >= 0:
				index = int(box.get("tower", 0))
				level = int(box.get("level", 0))
			break
		index += 1
	# Carried boxes line up across the screen (the diagonal the camera sees as
	# level), so every box sits at the same height on screen and what comes
	# out of them lands behind the row, never in front of the next box.
	# A venue with tall furniture along its near wall sets box_row deeper.
	var depth := float(venue.get("box_row", 1.6))
	return Vector3(float(venue.get("x", 0)) + 1.7 + float(index) * 0.45, float(level) * 0.44, float(venue.get("z", 0)) + float(venue.get("d", 8)) - depth - float(index) * 0.45)


func _spill_spot(box_id: int, n: int) -> Vector3:
	# Behind the box (away from the camera), fanned out level with the row.
	# A spot outside the room or on top of something already lying there is
	# skipped, so no two pieces share a square.
	var spot := _open_box_spot(box_id)
	spot.y = 0.0
	var x0 := float(venue.get("x", 0))
	var z0 := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	var taken: Array = []
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) in ["loose", "placed", "settling"]:
			taken.append(Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0))))
	for box in GameState.job.get("boxes", []):
		var b := _open_box_spot(int(box.get("id", 0)))
		taken.append(Vector2(b.x, b.z))
	for k in range(n, n + 30):
		var col := float(k % 3)
		var row := float(int(k / 3))
		var at := spot + Vector3(-1.1 + col * 0.5 - row * 0.55, 0.0, -1.1 - col * 0.5 - row * 0.55)
		if at.x < x0 + 0.5 or at.x > x0 + w - 0.5 or at.z < z0 + 0.5 or at.z > z0 + d - 0.5:
			continue
		if _spot_free(at, taken) and not _spot_blocked(at) and not _spot_hidden(at):
			return at
	# The pattern ran out of room: sweep the free squares that still sit
	# behind the box row, nearest the camera first, so a tall piece in front
	# never hides what comes out of a box.
	var squares: Array = []
	var cz := z0 + 0.8
	while cz < z0 + d - 0.5:
		var cx := x0 + 0.8
		while cx < x0 + w - 0.5:
			var at2 := Vector3(cx, 0.0, cz)
			if at2.x + at2.z < spot.x + spot.z - 0.3:
				squares.append(at2)
			cx += 0.6
		cz += 0.6
	squares.sort_custom(func(a, b): return (a.x + a.z) > (b.x + b.z))
	for at2 in squares:
		if _spot_free(at2, taken) and not _spot_blocked(at2) and not _spot_hidden(at2):
			return at2
	for at2 in squares:
		if _spot_free(at2, taken) and not _spot_blocked(at2):
			return at2
	return Vector3(x0 + w * 0.5, 0.0, z0 + d * 0.5)


func _unhide_loose() -> void:
	# A piece set down in front of a loose one can hide it from the camera;
	# move the hidden one to a square that can be seen. Pieces placed this
	# frame are not in the physics world yet, so the rays wait a step.
	if GameState.mode != "job_unpack":
		return
	var tree := get_tree()
	if tree != null:
		await tree.physics_frame
		await tree.physics_frame
	if not is_inside_tree() or GameState.mode != "job_unpack" or held_uid != "":
		return
	var moved := false
	var k := 0
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "loose":
			continue
		if _is_home() and int(item.get("floor", 0)) != home_floor:
			continue
		var at := Vector3(float(item.get("x", 0.0)), 0.0, float(item.get("z", 0.0)))
		if not _spot_hidden(at):
			continue
		var box_id := maxi(0, int(item.get("box", 0)))
		var fresh := _spill_spot(box_id, 12 + k)
		k += 1
		if not _spot_hidden(fresh):
			item["x"] = fresh.x
			item["z"] = fresh.z
			item["y"] = 0.0
			arrive_from[str(item.get("uid", ""))] = at + Vector3(0, 0.3, 0)
			moved = true
	if moved:
		_refresh_items()


func _spot_hidden(at: Vector3) -> bool:
	# A square the camera cannot see (a tall piece stands in the way) is no
	# place to put something the player has to click.
	if cam == null:
		return false
	var world := get_world_3d()
	if world == null or world.direct_space_state == null:
		return false
	var target := at + Vector3(0, 0.15, 0)
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, target)
	query.collision_mask = Props.MASK_QUERY
	query.exclude = _cutaway_rids()
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	return (hit["position"] as Vector3).distance_to(target) > 0.35


func _spot_blocked(at: Vector3) -> bool:
	# Anything solid standing on this square (a café table, the counter, a
	# placed piece) means a tipped-out piece would land inside it.
	var world := get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	if space == null:
		return false
	# Both layers: modelled pieces often carry only a pick body, no blocking one.
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 2.4, at.z), Vector3(at.x, 0.06, at.z))
	query.collision_mask = Props.MASK_QUERY
	query.exclude = _cutaway_rids()
	return not space.intersect_ray(query).is_empty()


func _spot_free(at: Vector3, taken: Array) -> bool:
	for p in taken:
		if (p as Vector2).distance_to(Vector2(at.x, at.z)) < 0.45:
			return false
	return true


func _box_still_packed(box_id: int) -> bool:
	for item in GameState.job.get("items", []):
		if int(item.get("box", -1)) == box_id and str(item.get("state", "")) == "boxed":
			return true
	return false


func _open_cat(box_id: int) -> void:
	if not GameState.open_cat(box_id):
		return
	AudioDirector.play_sfx("sfx_cat_meow")
	AudioDirector.play_sfx("sfx_success_chime")
	_confetti()
	_party_react("cat", {})
	_toast("Biscuit! There's a photo for the museum shelf, and a little tip.")
	if cat_rig:
		cat_rig.visible = true
		Props.play_clip(cat_rig, "stretch", false)


func _maybe_job_done() -> void:
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "placed":
			return
	_tally_rooms()
	_refresh_hud_buttons()


func _snap_point(hit: Vector3) -> Dictionary:
	var def := _held_def()
	var mount := str(def.get("mount", "floor"))
	var rot := held_rot
	var pos := Vector3(hit.x, float(Tuning.get_value("floor_y", 0.0)), hit.z)
	if mount == "hang" or mount == "wall_floor":
		var point := _nearest_wall(hit, mount)
		if point.is_empty():
			return {"valid": false, "pos": pos, "rot": rot, "wall": ""}
		rot = float(point["rot"])
		var offset := float(Tuning.get_value("wall_mount_offset_m", 0.12))
		var authored := float(def.get("back_offset", -1.0))
		if authored > offset:
			offset = authored
		var normal: Vector3 = point["normal"]
		pos = Vector3(point["x"], point["y"], point["z"]) + normal * offset
		# Floor placement uses the 0.25 m room margin. Wall mounts sit on that boundary, so the margin does not apply.
		var valid := _in_room_world(pos.x, pos.z) and not _too_tall(pos, def)
		return {"valid": valid, "pos": pos, "rot": rot, "wall": mount}
	var records: Array = GameState.office_items if held_source != "job" else GameState.job.get("items", [])
	var others: Array = []
	for rec in records:
		if str(rec.get("uid", "")) == held_uid:
			continue
		if str(rec.get("state", "")) != "placed":
			continue
		others.append(rec)
	var room := Rect2(float(venue.get("x", 0)), float(venue.get("z", 0)), float(venue.get("w", 6)), float(venue.get("d", 8)))
	var extra: Array = []
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		extra.append(Rect2(float(nook["x"]), float(nook["z"]), float(nook["w"]), float(nook["d"])))
	if _is_home():
		for owner in _owner_items_here():
			others.append(owner)
	var spot := PlaceLib.resolve(hit.x, hit.z, hit.y, rot, def, others, room, SaveManager.snap_to_grid, extra)
	var placed: Vector3 = spot["pos"]
	spot["valid"] = bool(spot["valid"]) and _in_room_world(placed.x, placed.z) and not _too_tall(placed, def)
	if bool(spot["valid"]) and _is_home():
		var foot := Homes.footprint(placed, float(spot["rot"]), float(def.get("w", 0.4)), float(def.get("d", 0.4)))
		if Homes.crosses_wall(venue, home_floor, foot):
			spot["valid"] = false
	return spot


func _nearest_wall(hit: Vector3, kind: String) -> Dictionary:
	var best := {}
	var best_d := 1.4
	for point in _wall_points():
		if str(point["kind"]) != kind and not (kind == "hang" and point["kind"] == "hang"):
			continue
		if kind == "wall_floor" and str(point["kind"]) != "wall_floor":
			continue
		var dist := Vector2(hit.x, hit.z).distance_to(Vector2(point["x"], point["z"]))
		if dist < best_d:
			best_d = dist
			best = point
	return best


func _wall_points() -> Array:
	var points: Array = []
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var d := float(venue.get("d", 6))
	var cursor := z + 1.5
	while cursor < z + d - 0.8:
		points.append({"kind": "wall_floor", "x": x, "y": 0.0, "z": cursor, "rot": 90.0, "normal": Vector3(1, 0, 0)})
		points.append({"kind": "hang", "x": x, "y": 1.15, "z": cursor, "rot": 90.0, "normal": Vector3(1, 0, 0)})
		cursor += 1.5
	points.append({"kind": "hang", "x": x + 1.4, "y": 1.2, "z": z, "rot": 0.0, "normal": Vector3(0, 0, 1)})
	return points


# ---------------------------------------------------------------- the player
# Dana is on screen: she walks to whatever you click and does the thing.
# Click-to-act stays as it is; she is the body that goes with it.

var player: Node3D
var player_target: Vector3 = Vector3.ZERO
var player_moving := false
var player_time := 0.0
var player_start: Vector3 = Vector3.ZERO
var player_on_arrive: Callable = Callable()
var player_carrying := false
var truck_pending := false
var arrive_from: Dictionary = {}
const PLAYER_SPEED := 2.4


func _spawn_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	if backdrop or not (GameState.mode in ["office", "job_pack", "job_unpack", "truck"]):
		return
	player = Figure.build(UIKit.TERRA, Color("2B2622"), "adult", Color("3E3A4F"), Figure.SKIN, {"head": "ponytail", "torso": "tee"})
	player.name = "Player"
	var scarf := Props.mesh_cylinder(0.22, 0.06, UIKit.MUSTARD)
	scarf.position = Vector3(0, 1.02, 0)
	player.get_node("Figure").add_child(scarf)
	var door := _door_world()
	player.position = door + Vector3(0.6, 0.0, 1.3)
	if GameState.mode == "truck":
		player.position = Vector3(1.6, 0.0, -0.9)
	player.rotation.y = PI
	player_start = player.position
	player_target = player.position
	player_moving = false
	add_child(player)


func _player_go(at: Vector3) -> void:
	# Stand just behind the spot (away from the camera) so Dana never hides what you clicked.
	if player == null or not is_instance_valid(player):
		return
	var spot := Vector3(at.x - 0.55, 0.0, at.z - 0.55)
	var x0 := float(venue.get("x", 0))
	var z0 := float(venue.get("z", 0))
	spot.x = clampf(spot.x, x0 + 0.4, x0 + float(venue.get("w", 6)) - 0.4)
	spot.z = clampf(spot.z, z0 + 0.4, z0 + float(venue.get("d", 8)) - 0.4)
	player_target = spot
	player_moving = player.position.distance_to(spot) > 0.15
	if not player_moving:
		_act(player, "reach", 0.7)


func _tick_player(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	player_time += delta
	player.set_meta("carry", held_uid != "" or (selected_box >= 0 and GameState.mode == "job_pack") or player_carrying)
	if player_moving:
		var to := player_target - player.position
		to.y = 0.0
		var step := PLAYER_SPEED * delta * (4.0 if auto_busy and auto_fast else 1.0)
		if to.length() <= step:
			player.position = player_target
			player_moving = false
			_act(player, "reach", 0.7)
			AudioDirector.play_sfx("sfx_footstep_office")
			if player_on_arrive.is_valid():
				var cb := player_on_arrive
				player_on_arrive = Callable()
				cb.call()
		else:
			player.position += to.normalized() * step
	_animate_person(player, player_time, player_moving, delta)


func _in_room_world(px: float, pz: float) -> bool:
	var origin := Vector2(float(venue.get("x", 0)), float(venue.get("z", 0)))
	var size := Vector2(float(venue.get("w", 6)), float(venue.get("d", 8)))
	if SupportMath.in_room(Vector2(px, pz) - origin, size):
		return true
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		var nook_origin := Vector2(float(nook["x"]), float(nook["z"]))
		var nook_size := Vector2(float(nook["w"]), float(nook["d"]))
		if SupportMath.in_room(Vector2(px, pz) - nook_origin, nook_size):
			return true
	return false


# ------------------------------------------------------------------ homes
# A house is a footprint split into rooms per floor. One floor shows at a
# time, blueprint style: waist-high walls, a name on every floor, the stairs
# to click. The client's own pieces stand in the rooms, and a light-fingered
# mover can pocket the small ones.

const Homes = preload("res://scripts/homes.gd")
var home_floor := 0


func _is_home() -> bool:
	return Homes.is_home(venue)


# ------------------------------------------------------------ the client
# The person or family you are moving stands by the door and talks:
# a greeting, idle chatter, and a word about every scuff, tipped box and
# piece set down in the wrong room. See scripts/client_party.gd.

var party: Node3D = null


func _spawn_party() -> void:
	if party != null and is_instance_valid(party):
		party.queue_free()
	party = null
	if backdrop or not (GameState.mode in ["job_pack", "job_unpack"]) or GameState.job.is_empty():
		return
	var def: Dictionary = GameState.job.get("def", {})
	party = ClientPartyLib.new()
	add_child(party)
	party.setup(self, def, _door_world(), Vector3(0, 0, 1))
	party.react("greet", {}, true)


func _party_react(event: String, fills: Dictionary, force := false) -> void:
	if party != null and is_instance_valid(party):
		party.react(event, fills, force)


func _party_on_place() -> void:
	# The last piece placed: the right room gets a nod, the wrong one a remark,
	# and the story moves on as the room fills.
	if party == null or not is_instance_valid(party):
		return
	var done := 0
	var total := 0
	for item in GameState.job.get("items", []):
		total += 1
		if str(item.get("state", "")) in ["placed", "settling"]:
			done += 1
	party.on_progress(done, total)
	if party.cooldown > 2.5:
		_last_placed_uid = ""
		return
	var latest: Dictionary = {}
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) in ["placed", "settling"] and str(item.get("uid", "")) == _last_placed_uid:
			latest = item
	if latest.is_empty():
		party.react("placed", {})
		return
	var tag := str(latest.get("room", ""))
	if _is_home() and tag != "" and Homes.has_tag(venue, tag):
		var room := Homes.room_at(venue, int(latest.get("floor", 0)), float(latest.get("x", 0)), float(latest.get("z", 0)))
		if Homes.tag_of_kind(Homes.kind(str(room.get("id", "")))) == tag:
			party.react("placed_good", {"item": str(latest.get("name", "piece")).to_lower()})
		else:
			party.react("wrong_room", {"item": str(latest.get("name", "piece")).to_lower(), "room": str(room.get("name", "hall")).to_lower()}, true)
		return
	party.react("placed", {"item": str(latest.get("name", "piece")).to_lower()})


var _last_placed_uid := ""


func _build_interior() -> void:
	var old := get_node_or_null("Interior")
	if old != null:
		remove_child(old)
		old.free()
	Homes.build(self, venue, home_floor, _wall_color(), _trim_color(), _floor_color(), GameState.mode != "job_pack")


func _set_floor(index: int) -> void:
	var count := Homes.floors(venue).size()
	if not _is_home() or index < 0 or index >= count or index == home_floor:
		return
	home_floor = index
	GameState.job["floor"] = index
	_build_interior()
	_refresh_items()
	_refresh_hud_buttons()
	_spawn_player()
	for entry in street:
		if bool(entry.get("pet", false)):
			entry["owner"] = player
			var dog: Node3D = entry.get("node")
			if dog != null and is_instance_valid(dog) and player != null:
				dog.position = player.position + Vector3(-0.7, 0.0, 0.35)
	if held_uid != "":
		_toast("Up the stairs with it. Put it down where it belongs.", "Dana")
	else:
		_toast("%s." % Homes.floor_name(venue, index), "Dana")
	AudioDirector.play_sfx("sfx_footstep_office")
	SaveManager.save_game()


func _use_stairs() -> void:
	var count := Homes.floors(venue).size()
	if home_floor < count - 1:
		_set_floor(home_floor + 1)
	elif home_floor > 0:
		_set_floor(home_floor - 1)


func _owner_items_here() -> Array:
	var out: Array = []
	for rec in GameState.job.get("owner_items", []):
		if int(rec.get("floor", 0)) == home_floor and str(rec.get("state", "placed")) == "placed":
			out.append(rec)
	return out


func _spawn_owner_items() -> void:
	# The client's own furniture, already in the rooms when you arrive.
	if not _is_home():
		return
	for rec in _owner_items_here():
		var def := ItemDB.get_item(str(rec.get("item_id", "")))
		var root := Node3D.new()
		root.name = "Owner_" + str(rec.get("uid", "")).replace(":", "_")
		root.position = Vector3(float(rec.get("x", 0)), 0.0, float(rec.get("z", 0)))
		root.rotation.y = deg_to_rad(float(rec.get("rot", 0)))
		root.set_meta("uid", str(rec.get("uid", "")))
		root.set_meta("owner_item", true)
		var visual := Props.make(str(def.get("model", "box_closed")))
		root.add_child(visual)
		Props.prepare(visual)
		Props.add_picker(root, Vector3(float(def.get("w", 0.4)), float(def.get("h", 0.3)), float(def.get("d", 0.4))))
		items_root.add_child(root)
		nodes_by_uid[str(rec.get("uid", ""))] = root


func _tally_rooms() -> void:
	# How many pieces ended up in the kind of room they belong in.
	if not _is_home():
		return
	var right := 0
	var total := 0
	var wrong: Array = []
	for item in GameState.job.get("items", []):
		var tag := str(item.get("room", ""))
		if tag == "" or not Homes.has_tag(venue, tag) or str(item.get("state", "")) != "placed":
			continue
		total += 1
		var room := Homes.room_at(venue, int(item.get("floor", 0)), float(item.get("x", 0)), float(item.get("z", 0)))
		if Homes.tag_of_kind(Homes.kind(str(room.get("id", "")))) == tag:
			right += 1
		else:
			wrong.append("%s in the %s" % [str(item.get("name", "piece")), str(room.get("name", "hall")).to_lower()])
	GameState.job["rooms_right"] = right
	GameState.job["rooms_total"] = total
	GameState.job["rooms_wrong"] = wrong


func _open_owner_card(uid: String) -> void:
	# Something of the client's. Leave it, or pocket it for Sal.
	var rec: Dictionary = {}
	for entry in GameState.job.get("owner_items", []):
		if str(entry.get("uid", "")) == uid:
			rec = entry
	if rec.is_empty():
		return
	var layer := _hud_layer()
	var old := layer.get_node_or_null("OwnerCard")
	if old != null:
		layer.remove_child(old)
		old.free()
	var card := PanelContainer.new()
	card.name = "OwnerCard"
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16, 4, UIKit.NIGHT))
	layer.add_child(card)
	card.layout_mode = 1
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_left = -360
	card.offset_right = 360
	card.offset_top = -120
	card.offset_bottom = 120
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	column.add_child(head)
	head.add_child(UIKit.ribbon("Theirs", UIKit.NIGHT, 30))
	var title := UIKit.label(str(rec.get("name", "Something")), 30, UIKit.DARK, "title", false)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var can := bool(rec.get("pocketable", true))
	var line := "Sal would give about $%d for it. Nobody is looking. Probably." % int(rec.get("value", 10)) if can else "Too big to walk out with under a blanket."
	var blurb := UIKit.label(line, 25, UIKit.DARK, "small")
	blurb.custom_minimum_size = Vector2(660, 0)
	column.add_child(blurb)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	column.add_child(foot)
	var leave := UIKit.button("Leave it", UIKit.SAGE)
	leave.name = "OwnerLeave"
	leave.custom_minimum_size = Vector2(200, 54)
	leave.pressed.connect(func():
		layer.remove_child(card)
		card.queue_free()
	)
	foot.add_child(leave)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	var pocket := UIKit.button("Pocket it", UIKit.NIGHT)
	pocket.name = "OwnerPocket"
	pocket.custom_minimum_size = Vector2(220, 54)
	pocket.disabled = not can
	pocket.pressed.connect(func():
		layer.remove_child(card)
		card.queue_free()
		var result: Dictionary = GameState.pocket_owner_item(uid)
		if result.has("error"):
			_toast(str(result["error"]), "Dana")
			return
		AudioDirector.play_sfx("sfx_paper_rustle")
		if bool(result.get("noticed", false)):
			AudioDirector.play_sfx("sfx_invalid_placement")
			_toast("They saw that go into the bag. That will cost you.", "Dana")
			_party_react("caught", {}, true)
		else:
			_toast("Into the bag. Nobody saw. Heat +%d." % int(result.get("heat", 1)), "Dana")
		_refresh_items()
	)
	foot.add_child(pocket)
	UIKit.link_focus([leave, pocket])
	leave.grab_focus()


func _ensure_stack_room() -> void:
	if backdrop or stack_room != null:
		return
	stack_room = StackRoomLib.new()
	stack_room.name = "StackRoom"
	add_child(stack_room)
	var extras: Array = []
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		extras.append(Rect2(float(nook["x"]), float(nook["z"]), float(nook["w"]), float(nook["d"])))
	stack_room.configure(Vector2(float(venue.get("x", 0)), float(venue.get("z", 0))), Vector2(float(venue.get("w", 6)), float(venue.get("d", 8))), extras)
	stack_room.snap_assist = SaveManager.snap_to_grid
	if not stack_room.item_evaluated.is_connected(_on_item_evaluated):
		stack_room.item_evaluated.connect(_on_item_evaluated)


func _too_tall(pos: Vector3, def: Dictionary) -> bool:
	if not venue.has("nook"):
		return false
	var nook: Dictionary = venue["nook"]
	var inside := pos.x >= float(nook["x"]) and pos.x <= float(nook["x"]) + float(nook["w"]) and pos.z >= float(nook["z"]) and pos.z <= float(nook["z"]) + float(nook["d"])
	return inside and float(def.get("h", 0)) > float(nook.get("max_h", 1.5))


func _held_def() -> Dictionary:
	if held_source == "decor":
		for entry in GameState.decor_queue:
			if str(entry.get("uid", "")) == held_uid:
				return ItemDB.get_item(str(entry.get("item", "")))
		return {}
	if held_source == "job":
		var item := GameState.job_item(held_uid)
		return ItemDB.get_item(str(item.get("item_id", "")))
	var rec := GameState.find_office_item(held_uid)
	return ItemDB.get_item(str(rec.get("item", "")))


func _drop_hold() -> void:
	_restore_held_record()
	held_uid = ""
	held_source = ""
	if ghost:
		ghost.visible = false
	_refresh_items()
	_maybe_live()
	_maybe_job_done()


func _restore_held_record() -> void:
	if held_source == "office":
		var rec := GameState.find_office_item(held_uid)
		if not rec.is_empty() and str(rec.get("state", "")) == "hand":
			rec["state"] = "placed"
	elif held_source == "job":
		var item := GameState.job_item(held_uid)
		if not item.is_empty() and str(item.get("state", "")) == "hand":
			item["state"] = "placed"


func _refresh_items() -> void:
	if stack_room:
		stack_room.prepare_refresh()
	var old: Array = items_root.get_children()
	for child in old:
		child.free()
	nodes_by_uid.clear()
	if GameState.mode == "office":
		_spawn_office()
	elif GameState.mode == "job_pack":
		_layout_loose()
		for item in GameState.job.get("items", []):
			if str(item.get("state", "")) == "loose":
				_spawn_record(item, str(item.get("item_id", "")), false)
		_spawn_pack_boxes()
	elif GameState.mode == "truck":
		_spawn_truck_slots()
	elif GameState.mode == "job_unpack":
		for item in GameState.job.get("items", []):
			var job_state := str(item.get("state", ""))
			if _is_home() and int(item.get("floor", 0)) != home_floor:
				continue
			if job_state == "loose" or job_state == "placed" or job_state == "settling":
				_spawn_record(item, str(item.get("item_id", "")), int(item.get("damage", 0)) > 0)
		_spawn_owner_items()
		if not _is_home() or home_floor == 0:
			_spawn_carry_boxes()
	if stack_room:
		stack_room.evaluate_frozen()
		stack_room.flush_drops()


func _layout_loose() -> void:
	# Big pieces in the front rows, small ones behind, with a clear strip
	# along the back wall for the boxes. Everything sits on the floor.
	var loose: Array = []
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) == "loose":
			loose.append(item)
	loose.sort_custom(func(a, b):
		var da := ItemDB.get_item(str(a.get("item_id", "")))
		var db := ItemDB.get_item(str(b.get("item_id", "")))
		var fa := float(da.get("w", 0.3)) * float(da.get("d", 0.3)) + (1.0 if bool(a.get("bulky", false)) or bool(a.get("heavy", false)) else 0.0)
		var fb := float(db.get("w", 0.3)) * float(db.get("d", 0.3)) + (1.0 if bool(b.get("bulky", false)) or bool(b.get("heavy", false)) else 0.0)
		return fa > fb
	)
	var w := float(venue.get("w", 6))
	var cols := maxi(3, int((w - 1.6) / 0.85))
	var i := 0
	for item in loose:
		item["x"] = float(venue.get("x", 0)) + 1.0 + float(i % cols) * 0.85
		item["z"] = float(venue.get("z", 0)) + 2.2 + float(int(i / cols)) * 0.85
		item["y"] = 0.0
		i += 1


func _spawn_pack_boxes() -> void:
	# The boxes you are filling stand in a row along the back wall: open
	# while they take pieces, closed once sealed, the one in use ringed.
	var i := 0
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", 0))
		var node := Node3D.new()
		node.position = Vector3(float(venue.get("x", 0)) + 0.8 + float(i) * 0.6, 0.0, float(venue.get("z", 0)) + 0.8)
		node.set_meta("uid", "boxpack:%d" % id)
		var sealed := bool(box.get("sealed", false))
		node.add_child(Props.make("box_closed" if sealed else "box_open"))
		if id == selected_box and not sealed:
			var ring := Props.mesh_cylinder(0.36, 0.02, UIKit.MUSTARD)
			ring.position.y = 0.01
			node.add_child(ring)
		var count := GameState.box_item_count(id)
		if count > 0:
			var tag := Label3D.new()
			tag.text = "%d" % count
			tag.font_size = 64
			tag.modulate = UIKit.DARK
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.position = Vector3(0, 0.62, 0)
			tag.no_depth_test = true
			node.add_child(tag)
		Props.add_picker(node, Vector3(0.5, 0.45, 0.45))
		items_root.add_child(node)
		i += 1


func _spawn_office() -> void:
	var boxed := 0
	for rec in GameState.office_items:
		if str(rec.get("uid", "")) == held_uid:
			continue
		var office_state := str(rec.get("state", ""))
		if office_state == "placed" or office_state == "settling":
			_spawn_record(rec, str(rec.get("item", "")), int(rec.get("damage", 0)) > 0)
		elif str(rec.get("state", "")) == "boxed":
			var box := Node3D.new()
			box.position = Vector3(1.2 + float(boxed % 6) * 0.7, 0, 1.15 + float(int(boxed / 6)) * 0.55)
			box.set_meta("uid", rec["uid"])
			var visual := Props.make("box_closed")
			box.add_child(visual)
			Props.add_picker(box, Vector3(0.5, 0.4, 0.45))
			items_root.add_child(box)
			boxed += 1


func _arrive(root: Node3D, from_world: Vector3) -> void:
	# A piece does not pop into place: it rises from where it was, arcs over,
	# and lands with a little squash and a puff of dust.
	if root == null or settling:
		return
	var visual: Node3D = null
	for child in root.get_children():
		if child is Node3D and not (child is CollisionShape3D) and not (child is StaticBody3D) and str(child.name) not in ["Picker", "PropCollision"]:
			visual = child
			break
	if visual == null:
		return
	var start := root.to_local(from_world)
	if start.length() < 0.05:
		return
	visual.position = start
	visual.scale = Vector3(0.8, 0.8, 0.8)
	var mid := start * 0.5 + Vector3(0, 0.45, 0)
	var tw := create_tween()
	tw.tween_property(visual, "position", mid, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "position", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(visual, "scale", Vector3(1.08, 0.92, 1.08), 0.24)
	tw.tween_property(visual, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Bound, not captured: the piece's node may be rebuilt before the tween ends.
	tw.tween_callback(_dust.bind(root.global_position))


func _spawn_record(rec: Dictionary, item_id: String, cracked: bool) -> void:
	var def := ItemDB.get_item(item_id)
	var state := str(rec.get("state", ""))
	var placed := state == "placed" or state == "settling"
	var use_stack := not backdrop and placed and stack_room != null
	var root: Node3D
	if use_stack:
		root = _spawn_stack_item(rec, item_id, def, state)
		if cracked:
			var crack := Props.mesh_box(Vector3(0.08, 0.08, 0.08), UIKit.LOSS)
			crack.position = Vector3(0, float(def.get("h", 0.4)) + 0.08, 0)
			root.add_child(crack)
	else:
		root = Node3D.new()
		root.position = Vector3(float(rec.get("x", 0)), float(rec.get("y", 0)), float(rec.get("z", 0)))
		root.rotation.y = deg_to_rad(float(rec.get("rot", 0)))
		root.set_meta("uid", rec.get("uid", ""))
		var loose_visual := Props.make(str(def.get("model", "box_closed")))
		root.add_child(loose_visual)
		if bool(def.get("light", false)):
			Props.attach_lamp_light(loose_visual)
		if str(def.get("animate", "")) != "":
			Props.play_clip(loose_visual, str(def.get("animate", "")), true)
		if str(item_id) == "train_reward" or str(def.get("model", "")) == "train_layout_board":
			Props.play_clip(loose_visual, "loop", true)
		Props.add_picker(root, Vector3(float(def.get("w", 0.4)), float(def.get("h", 0.3)), float(def.get("d", 0.4))))
		if cracked:
			var loose_crack := Props.mesh_box(Vector3(0.08, 0.08, 0.08), UIKit.LOSS)
			loose_crack.position = Vector3(0, float(def.get("h", 0.4)) + 0.08, 0)
			root.add_child(loose_crack)
		items_root.add_child(root)
	nodes_by_uid[str(rec.get("uid", ""))] = root
	var arriving := str(rec.get("uid", ""))
	if arrive_from.has(arriving):
		var from: Vector3 = arrive_from[arriving]
		arrive_from.erase(arriving)
		_arrive(root, from)


func _is_stack_item(node: Node) -> bool:
	return node != null and node.get_script() == StackItemLib


func _spawn_stack_item(rec: Dictionary, item_id: String, def: Dictionary, state: String):
	var visual := Props.make(str(def.get("model", "box_closed")))
	var item = StackItemLib.new()
	var aliases := PackedStringArray([item_id, str(def.get("model", "")), str(def.get("name", "")), str(rec.get("item", ""))])
	item.item_id = str(rec.get("uid", ""))
	item.furniture = _furniture_name(aliases)
	item.setup(item_id, Vector3(float(def.get("w", 0.4)), float(def.get("h", 0.3)), float(def.get("d", 0.4))), visual, aliases)
	item.set_meta("uid", rec.get("uid", ""))
	if bool(def.get("light", false)):
		Props.attach_lamp_light(visual)
	if str(def.get("animate", "")) != "":
		Props.play_clip(visual, str(def.get("animate", "")), true)
	if str(item_id) == "train_reward" or str(def.get("model", "")) == "train_layout_board":
		Props.play_clip(visual, "loop", true)
	var pos := Vector3(float(rec.get("x", 0)), float(rec.get("y", 0)), float(rec.get("z", 0)))
	var yaw := deg_to_rad(float(rec.get("rot", 0)))
	if rec.has("safe_x"):
		item.note_safe(Vector3(float(rec["safe_x"]), float(rec.get("safe_y", 0.0)), float(rec.get("safe_z", 0.0))), deg_to_rad(float(rec.get("safe_rot", 0.0))))
	items_root.add_child(item)
	stack_room.adopt(item)
	var wall := str(rec.get("wall", ""))
	if state == "settling" and wall == "":
		stack_room.queue_drop(item, pos, yaw)
	else:
		if wall != "":
			item.side = wall
		item.spawn_frozen(pos, yaw)
		if wall != "":
			stack_room.results[item.item_id] = {"supported": true, "stack_level": 1, "in_room": true, "wall": wall, "mounted": true, "reset": false}
		if item.furniture:
			var top: float = item.rest_bottom() + item.size.y
			stack_room.add_furniture(item.item_id, Vector2(pos.x, pos.z), Vector2(item.size.x, item.size.z), top, float(rec.get("rot", 0.0)), 0)
	return item


func _furniture_name(tokens: PackedStringArray) -> bool:
	for token in tokens:
		var text := str(token).to_lower()
		if "desk" in text or "shelf" in text or "counter" in text:
			return true
	return false


func _spawn_truck_slots() -> void:
	for i in slot_count:
		var local := _slot_pos(i)
		var pad := Node3D.new()
		pad.position = local
		pad.set_meta("slot", i)
		var color := UIKit.MUSTARD if i < floor_slots else UIKit.BLUE
		var marker := Props.mesh_box(Vector3(0.42, 0.04, 0.36), color)
		pad.add_child(marker)
		Props.add_picker(pad, Vector3(0.46, 0.3, 0.4))
		if truck_root:
			truck_root.add_child(pad)
		else:
			items_root.add_child(pad)
		for box in GameState.job.get("boxes", []):
			if int(box.get("slot", -1)) == i:
				if str(box.get("big", "")) != "":
					var big := GameState.job_item(str(box["big"]))
					var piece := Props.make(str(ItemDB.get_item(str(big.get("item_id", ""))).get("model", "box_closed")))
					piece.scale = Vector3(0.45, 0.45, 0.45)
					piece.position = Vector3(0, 0.02, 0)
					pad.add_child(piece)
					var blanket := Props.mesh_box(Vector3(0.4, 0.06, 0.34), UIKit.BLUE)
					blanket.position = Vector3(0, 0.03, 0)
					pad.add_child(blanket)
					continue
				var visual_name := "box_closed_damaged" if int(GameState.job.get("condition", 100)) < int(Tuning.get_value("damage.mesh_swap_below", 70)) else "box_closed"
				var box_node := Props.make(visual_name)
				box_node.position = Vector3(0, 0.2, 0)
				pad.add_child(box_node)


func _spawn_carry_boxes() -> void:
	_normalize_towers()
	var index := 0
	for box in GameState.job.get("boxes", []):
		var box_id := int(box.get("id", -1))
		if bool(carried.get(box_id, false)):
			if _box_still_packed(box_id):
				var opened := Node3D.new()
				opened.position = _open_box_spot(box_id)
				opened.set_meta("uid", "boxopen:%d" % box_id)
				opened.add_child(Props.make("box_closed"))
				Props.add_picker(opened, Vector3(0.5, 0.45, 0.45))
				items_root.add_child(opened)
			continue
		if not bool(box.get("sealed", false)):
			continue
		var node := Node3D.new()
		node.position = Vector3(float(venue.get("x", 0)) + float(venue.get("w", 6)) - 0.2, 0.2, 1.0 + index * 0.55)
		node.set_meta("uid", "boxcarry:%d" % int(box.get("id", 0)))
		var damaged := int(GameState.job.get("condition", 100)) < int(Tuning.get_value("damage.mesh_swap_below", 70))
		node.add_child(Props.make("box_closed_damaged" if damaged else "box_closed"))
		Props.add_picker(node, Vector3(0.5, 0.45, 0.45))
		items_root.add_child(node)
		index += 1


func _slot_pos(i: int) -> Vector3:
	var col := i % 2
	var row := int(i / 2) % 2
	var layer := 0 if i < floor_slots else 1
	if i >= floor_slots:
		col = (i - floor_slots) % 2
		row = int((i - floor_slots) / 2)
	return Vector3(-1.25 + float(row) * 0.55, 0.78 + float(layer) * 0.42, -0.32 + float(col) * 0.64)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var top := Panel.new()
	top.name = "StatusCard"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16, 4, UIKit.TERRA))
	layer.add_child(top)
	UIKit.pin_top_left(top, 16, 12, 760, 112)
	status = UIKit.label("", 30, UIKit.DARK, "small")
	status.name = "Status"
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(status)
	UIKit.fill(status, 16, 8, 16, 8)
	var hint_bar := Panel.new()
	hint_bar.name = "HintBar"
	hint_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16, 4, UIKit.WOOD))
	layer.add_child(hint_bar)
	UIKit.pin_bottom(hint_bar, 16, -150, -16, -12)
	# Left: what to do now, and one line of how. Right: the keys that matter in this mode.
	var bar_row := HBoxContainer.new()
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_row.add_theme_constant_override("separation", 24)
	hint_bar.add_child(bar_row)
	UIKit.fill(bar_row, 20, 12, 20, 12)
	var bar_text := VBoxContainer.new()
	bar_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_text.add_theme_constant_override("separation", 2)
	bar_row.add_child(bar_text)
	objective = UIKit.label("", 30, UIKit.TERRA, "title", false)
	objective.name = "Objective"
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_text.add_child(objective)
	hint = UIKit.label("", 28, UIKit.DARK, "small")
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.max_lines_visible = 2
	hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar_text.add_child(hint)
	chips_slot = VBoxContainer.new()
	chips_slot.name = "ChipsSlot"
	chips_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips_slot.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_row.add_child(chips_slot)
	status.max_lines_visible = 2
	# The checklist grows with its text, so nothing spills out of the card.
	var goals_box := PanelContainer.new()
	goals_box.name = "GoalsCard"
	goals_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goals_box.add_theme_stylebox_override("panel", UIKit.style(Color(UIKit.CREAM_CARD, 0.94), 14, 4, UIKit.SAGE))
	layer.add_child(goals_box)
	goals_box.layout_mode = 1
	goals_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	goals_box.position = Vector2(16, 226)
	goals_box.custom_minimum_size = Vector2(560, 0)
	var goals_margin := MarginContainer.new()
	goals_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		goals_margin.add_theme_constant_override("margin_" + side, 14)
	goals_margin.add_theme_constant_override("margin_top", 8)
	goals_margin.add_theme_constant_override("margin_bottom", 10)
	goals_box.add_child(goals_margin)
	goals_column = VBoxContainer.new()
	goals_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goals_column.add_theme_constant_override("separation", 2)
	goals_margin.add_child(goals_column)
	goals_panel = goals_box
	goals_panel.visible = false
	# Toasts read as a chat bubble: who said it, then what.
	toast_bar = PanelContainer.new()
	toast_bar.name = "ToastBar"
	toast_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_bar.visible = false
	toast_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 24, 4, UIKit.BLUE))
	layer.add_child(toast_bar)
	toast_bar.layout_mode = 1
	toast_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_bar.grow_vertical = Control.GROW_DIRECTION_END
	toast_bar.offset_left = -480
	toast_bar.offset_right = 480
	toast_bar.offset_top = 124
	toast_bar.offset_bottom = 124
	var bubble := HBoxContainer.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_constant_override("separation", 14)
	toast_bar.add_child(bubble)
	var face := UIKit.avatar("M", UIKit.TERRA, 48)
	face.name = "ToastFace"
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.add_child(face)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	bubble.add_child(words)
	toast_name = UIKit.label("Marge", 24, UIKit.TERRA, "title", false)
	toast_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(toast_name)
	toast = UIKit.label("", 28, UIKit.DARK, "small")
	toast.max_lines_visible = 2
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.custom_minimum_size = Vector2(860, 0)
	words.add_child(toast)
	_refresh_hud_buttons()
	GameState.toast_requested.connect(func(message: String): _toast(message, "Marge"))


func _refresh_hud_buttons() -> void:
	var layer := _hud_layer()
	if layer == null:
		return
	for child in layer.get_children():
		# Godot renames a second "ActButton" to "@Button@n", so the mark is a meta.
		if child.has_meta("act_button") or str(child.name).begins_with("Act"):
			layer.remove_child(child)
			child.queue_free()
	var y := 100.0
	if GameState.mode == "office" or GameState.mode == "job_unpack":
		var snap_label := "Grid snap on" if SaveManager.snap_to_grid else "Free place"
		_act_button(layer, snap_label, Vector2(16, y), _toggle_snap)
		# Left column, under the snap toggle: the right-hand corner is where the
		# boxed pieces of a bigger room end up, and a button there eats clicks.
		_act_button(layer, "Rotate view", Vector2(16, y + 58), func(): rotate_view(1))
		if _is_home() and GameState.mode == "job_unpack" and Homes.floors(venue).size() > 1:
			# Low in the left column, under the hint card: the stairs buttons.
			var fy := 556.0
			if home_floor > 0:
				_act_button(layer, "Down to %s" % Homes.floor_name(venue, home_floor - 1).to_lower(), Vector2(16, fy), func(): _set_floor(home_floor - 1))
				fy -= 58
			if home_floor < Homes.floors(venue).size() - 1:
				_act_button(layer, "Up to %s" % Homes.floor_name(venue, home_floor + 1).to_lower(), Vector2(16, fy), func(): _set_floor(home_floor + 1))
	if GameState.mode == "office" and GameState.office_phase == "place":
		_act_button(layer, "Place it all for me", Vector2(1100, y), _place_office_all)
	if GameState.mode == "office" and GameState.office_phase == "pack":
		_act_button(layer, "Box it all for me", Vector2(1100, y), func():
			for item in GameState.office_items:
				if str(item.get("state", "")) == "placed":
					item["state"] = "boxed"
			AudioDirector.play_sfx("sfx_box_fold", true)
			_refresh_items()
			_check_pack_done()
		)
	if GameState.mode == "office" and GameState.office_phase == "live":
		_act_button(layer, "Jobs", Vector2(1100, y), func(): _open_jobs())
		y += 58
		_act_button(layer, "Workbench", Vector2(1100, y), _open_workshop)
		y += 58
		_act_button(layer, "Map", Vector2(1100, y), func(): emit_signal("open_map"))
		y += 58
		_act_button(layer, "Computer", Vector2(1100, y), func():
			AudioDirector.play_sfx("sfx_crt_power_on")
			emit_signal("open_computer")
		)
		if not GameState.decor_queue.is_empty():
			y += 58
			_act_button(layer, "Place decor", Vector2(1100, y), func():
				var entry: Dictionary = GameState.decor_queue[0]
				held_uid = str(entry.get("uid", ""))
				held_source = "decor"
				held_rot = 0
				AudioDirector.play_sfx("sfx_item_pick_up")
			)
		if held_source == "office":
			var held := GameState.find_office_item(held_uid)
			if str(held.get("source", "")) == "forest":
				y += 58
				_act_button(layer, "Return", Vector2(1100, y), _return_held)
				y += 58
				_act_button(layer, "Resell", Vector2(1100, y), _resell_held)
		if not GameState.door_orders().is_empty():
			y += 58
			_act_button(layer, "Door boxes", Vector2(1100, y), func():
				_toast("A TropicalForest box is by the door. Click it, pop the bubbles, then place what was inside.")
			)
	if GameState.mode == "job_pack":
		_act_button(layer, "New box", Vector2(1060, 100), func():
			if GameState.job.get("boxes", []).size() >= slot_count:
				_toast("The truck only takes %d boxes. Fill the ones you have." % slot_count)
				AudioDirector.play_sfx("sfx_invalid_placement")
				return
			selected_box = GameState.make_box()
			AudioDirector.play_sfx("sfx_box_fold", true)
			_refresh_hud_buttons()
		)
		_act_button(layer, "Add padding", Vector2(1060, 158), func(): _pad_selected())
		_act_button(layer, "Seal box", Vector2(1060, 216), func(): _seal_selected())
		if not GameState.all_sealed() and not auto_busy:
			_act_button(layer, "Pack the rest for me", Vector2(1060, 290), _pack_rest)
		if GameState.all_sealed():
			_act_button(layer, "Load the truck", Vector2(1060, 290), func():
				GameState.set_mode("truck")
				SaveManager.save_game()
				emit_signal("request_rebuild")
			)
		_box_list(layer)
	if GameState.mode == "truck":
		_truck_list(layer)
		if GameState.all_loaded():
			_act_button(layer, "Drive", Vector2(1060, 100), _begin_drive)
	if GameState.mode == "job_unpack":
		_unpack_actions(layer)


func _unpack_actions(layer: CanvasLayer) -> void:
	var all_in := true
	for box in GameState.job.get("boxes", []):
		if bool(box.get("sealed", false)) and not bool(carried.get(int(box.get("id", -1)), false)):
			all_in = false
	var y := 100.0
	if bool(GameState.job.get("def", {}).get("mystery", false)) and not bool(GameState.job.get("mystery_sorted", false)):
		_act_button(layer, "Sort mystery parts", Vector2(980, y), func():
			GameState.sort_mystery()
			AudioDirector.play_sfx("sfx_paper_rustle")
			AudioDirector.play_sfx("sfx_l04_toy_whistle")
			AudioDirector.play_sfx("sfx_success_chime")
			_toast("The parts make a tiny train. It's yours.")
			_refresh_hud_buttons()
		)
		y += 58
	for item in GameState.job.get("items", []):
		if int(item.get("damage", 0)) > 0:
			var uid := str(item.get("uid", ""))
			var level := int(item.get("damage", 0))
			var taps := Tuning.repair_taps(level)
			var cost := int(round(float(JobDB.base_pay(GameState.job.get("def", {}))) * (0.05 if level == 1 else 0.10)))
			_act_button(layer, mend_caption(str(item.get("name", "item")), taps), Vector2(860, y), func():
				var done := GameState.tap_repair(uid)
				AudioDirector.play_sfx("sfx_repair")
				if done:
					AudioDirector.play_sfx("sfx_success_chime")
					_toast("Good as new!")
				_refresh_items()
				_refresh_hud_buttons()
			)
			y += 52
			_act_button(layer, "Keep it (−$%d tip)" % cost, Vector2(860, y), func():
				_toast("We'll leave the scar. The base pay is safe.")
			)
			y += 52
	var ready := true
	var waiting := 0
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "placed":
			ready = false
		if str(item.get("state", "")) in ["boxed", "loose"] and bool(carried.get(int(item.get("box", -1)), false)):
			waiting += 1
	if _stackable_count() >= 2:
		_act_button(layer, "Stack the boxes", Vector2(860, y), _stack_boxes)
		y += 52
	if waiting > 0 and not auto_busy:
		_act_button(layer, "Unpack it all for me", Vector2(860, y), func():
			var ids: Array = []
			for box in GameState.job.get("boxes", []):
				var id := int(box.get("id", 0))
				if bool(carried.get(id, false)):
					ids.append(id)
			_auto_unpack(ids)
		)
	if ready and all_in:
		_act_button(layer, "Finish job", Vector2(1060, 620), func():
			GameState.finish_job()
			GameState.set_mode("results")
			SaveManager.save_game()
			AudioDirector.play_sfx("sfx_job_complete")
			emit_signal("request_results")
		)


func _start_listed_job(id: String) -> void:
	GameState.start_job(id)
	SaveManager.save_game()
	AudioDirector.play_sfx("sfx_notification_soft")
	emit_signal("request_rebuild")


func _pad_selected() -> void:
	if selected_box < 0:
		selected_box = GameState.ensure_open_box()
	var box := GameState.job_box(selected_box)
	if box.is_empty() or bool(box.get("sealed", false)):
		return
	if not GameState.box_needs_padding(selected_box):
		_toast("Nothing fragile in that one.")
		return
	box["padded"] = true
	AudioDirector.play_sfx("sfx_tape_apply")
	_toast("Padded. The bumps will be kinder.")
	_refresh_hud_buttons()


func _seal_selected() -> void:
	if selected_box < 0:
		_toast("Pack something into a box first.")
		return
	if not GameState.seal_box(selected_box):
		_toast("That box is empty.")
		return
	AudioDirector.play_sfx("sfx_tape_rip")
	AudioDirector.play_sfx("sfx_box_fold", true)
	var sealed_id := selected_box
	var box := GameState.job_box(sealed_id)
	selected_box = -1
	_refresh_hud_buttons()
	if not box.is_empty() and bool(box.get("has_cat", false)) and not bool(GameState.job.get("cat_opened", false)):
		AudioDirector.play_sfx("sfx_cat_meow")
		_toast("That box just meowed. Open it?")
		# Added after the refresh, or the refresh would sweep it away with the rest.
		_act_button(_hud_layer(), "Open the meowing box", Vector2(860, 520), func():
			_open_cat(sealed_id)
			_refresh_hud_buttons()
		)
		AudioDirector.play_sfx("sfx_l02_box_wiggle")
		_wiggle_toast()


func _box_list(layer: CanvasLayer) -> void:
	var y := 360.0
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", 0))
		var label := "Box %d" % (id + 1)
		if str(box.get("big", "")) != "":
			label = "%s · wrapped" % GameState.job_item(str(box["big"])).get("name", "Big piece")
		elif bool(box.get("sealed", false)):
			label += " sealed"
		if bool(box.get("padded", false)):
			label += " · padded"
		if bool(box.get("has_cat", false)):
			label += " · meow"
		label += " (%d)" % GameState.box_item_count(id)
		var capture := id
		_act_button(layer, label, Vector2(16, y), func():
			selected_box = capture
			_toast("Using box %d." % (capture + 1))
		)
		y += 52


func _truck_list(layer: CanvasLayer) -> void:
	var y := 160.0
	for box in GameState.job.get("boxes", []):
		if not bool(box.get("sealed", false)):
			continue
		var id := int(box.get("id", 0))
		var heavy := GameState.box_has_heavy(id)
		var text := "Box %d%s" % [id + 1, " · heavy" if heavy else ""]
		if str(box.get("big", "")) != "":
			text = "%s%s" % [GameState.job_item(str(box["big"])).get("name", "Big piece"), " · heavy" if heavy else ""]
		if int(box.get("slot", -1)) >= 0:
			text += " loaded"
		var capture := id
		_act_button(layer, text, Vector2(16, y), func():
			selected_box = capture
			_toast("Now tap a colored pad in the truck. Mustard pads are the floor.")
		)
		y += 52


func _open_jobs(tab := "jobs") -> void:
	var layer := _hud_layer()
	var old := layer.get_node_or_null("ActJobs")
	if old != null:
		old.queue_free()
	var panel := Panel.new()
	panel.name = "ActJobs"
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 18))
	layer.add_child(panel)
	var card_size := Vector2(1100, 720)
	UIKit.pin_center(panel, card_size)
	var title := UIKit.ribbon("Clipboard", UIKit.TERRA, 40)
	title.position = Vector2(24, 14)
	panel.add_child(title)
	var day_tag := UIKit.label("Day %d  ·  Rep %d  ·  %d jobs done" % [GameState.day, GameState.rep_rank(), GameState.jobs_done], 24, UIKit.WOOD, "small", false)
	day_tag.position = Vector2(300, 30)
	panel.add_child(day_tag)
	var close := UIKit.button("Close", UIKit.DARK)
	close.position = Vector2(card_size.x - 184, 16)
	close.size = Vector2(160, 56)
	close.custom_minimum_size = Vector2(160, 56)
	close.pressed.connect(panel.queue_free)
	panel.add_child(close)
	var jobs_tab := UIKit.button("Jobs", UIKit.TERRA if tab == "jobs" else UIKit.WOOD)
	jobs_tab.position = Vector2(24, 80)
	jobs_tab.size = Vector2(170, 52)
	jobs_tab.custom_minimum_size = Vector2(170, 52)
	jobs_tab.pressed.connect(_open_jobs.bind("jobs"))
	panel.add_child(jobs_tab)
	var goals_tab := UIKit.button("Goals", UIKit.TERRA if tab == "goals" else UIKit.WOOD)
	goals_tab.position = Vector2(204, 80)
	goals_tab.size = Vector2(170, 52)
	goals_tab.custom_minimum_size = Vector2(170, 52)
	goals_tab.pressed.connect(_open_jobs.bind("goals"))
	panel.add_child(goals_tab)
	var back_tab := UIKit.button("Back room", UIKit.TERRA if tab == "backroom" else UIKit.NIGHT)
	back_tab.position = Vector2(384, 80)
	back_tab.size = Vector2(190, 52)
	back_tab.custom_minimum_size = Vector2(190, 52)
	back_tab.pressed.connect(_open_jobs.bind("backroom"))
	panel.add_child(back_tab)
	var scroll := ScrollContainer.new()
	scroll.name = "Rows"
	scroll.position = Vector2(24, 144)
	scroll.size = Vector2(card_size.x - 48, card_size.y - 168)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	rows.custom_minimum_size = Vector2(card_size.x - 72, 0)
	scroll.add_child(rows)
	if tab == "goals":
		_fill_goals(rows, card_size.x - 72)
	elif tab == "backroom":
		_fill_backroom(rows, card_size.x - 72)
	else:
		_fill_jobs(rows, card_size.x - 72)
	var focus_buttons: Array = [close, jobs_tab, goals_tab, back_tab]
	for child in rows.get_children():
		for kid in child.get_children():
			if kid is Button:
				focus_buttons.append(kid)
	UIKit.link_focus(focus_buttons)


func _open_workshop() -> void:
	var layer := _hud_layer()
	if layer == null:
		return
	var old := layer.get_node_or_null("WorkshopCard")
	if old != null:
		old.queue_free()
	var card: Panel = preload("res://scripts/workshop_ui.gd").new()
	layer.add_child(card)
	AudioDirector.play_sfx("sfx_paper_rustle")


func _fill_jobs(rows: VBoxContainer, width: float) -> void:
	var any := false
	var story: Array = []
	var board: Array = []
	for job in JobDB.all_jobs():
		var decorated := JobDB.get_job(str(job.get("id", "")))
		if not GameState.job_available(decorated):
			continue
		any = true
		if bool(decorated.get("generated", false)):
			board.append(decorated)
		else:
			story.append(decorated)
	if not any:
		var empty := UIKit.label("Marge hasn't pinned a job yet. Finish unpacking the garage first.", 36, UIKit.DARK)
		empty.custom_minimum_size = Vector2(width - 20.0, 0)
		rows.add_child(empty)
		return
	if not story.is_empty():
		rows.add_child(UIKit.label("Marge's jobs", 28, UIKit.TERRA, "title", false))
		for decorated in story:
			rows.add_child(_job_card(decorated, width, false))
	if not board.is_empty():
		rows.add_child(UIKit.label("Today's board  ·  new every morning", 28, UIKit.TERRA, "title", false))
		for decorated in board:
			rows.add_child(_job_card(decorated, width, true))


func _job_card(decorated: Dictionary, width: float, from_board: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var box := UIKit.style(Color("F6EEDC"), 14)
	box.shadow_size = 0
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(width, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	text.add_child(head)
	var name_label := UIKit.label(str(decorated.get("title", "")), 28, UIKit.DARK, "title", false)
	head.add_child(name_label)
	var pay := JobDB.base_pay(decorated)
	var pay_label := UIKit.label("$%d base" % pay, 24, UIKit.SAGE, "small", false)
	pay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(pay_label)
	var twist := str(decorated.get("twist", ""))
	if from_board and twist != "" and twist != "plain":
		var tag := UIKit.label(twist.capitalize(), 24, UIKit.TERRA, "small", false)
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(tag)
	var client := UIKit.label(str(decorated.get("client", "")), 24, UIKit.WOOD, "small", false)
	text.add_child(client)
	var brief := UIKit.label(str(decorated.get("brief", "")), 24, UIKit.DARK, "small")
	brief.custom_minimum_size = Vector2(width - 300.0, 0)
	text.add_child(brief)
	var note := UIKit.label("Marge: %s" % decorated.get("mentor_note", ""), 24, UIKit.BLUE, "small")
	note.custom_minimum_size = Vector2(width - 300.0, 0)
	text.add_child(note)
	var go := UIKit.button("Take job", UIKit.TERRA)
	go.size = Vector2(200, 56)
	go.custom_minimum_size = Vector2(200, 56)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(_start_listed_job.bind(str(decorated.get("id", ""))))
	row.add_child(go)
	return card


func _fill_backroom(rows: VBoxContainer, width: float) -> void:
	# Sal's lock-up: three short trees of off-the-books work, bought with cred.
	var contact: Dictionary = Crime.data.get("contact", {}) if not Crime.data.is_empty() else {}
	Crime.ensure()
	contact = Crime.data.get("contact", {})
	var intro := _goal_card_shell(width, Color("E7E0D4"))
	var col := intro.get_child(0) as VBoxContainer
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	head.add_child(UIKit.avatar("S", UIKit.NIGHT, 40))
	var title := UIKit.label("%s  ·  cred %d  ·  heat %d / %d" % [contact.get("name", "Sal"), Crime.cred(), Crime.heat(), int(Crime.data.get("heat_visit", 10))], 28, UIKit.DARK, "title", false)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var blurb := UIKit.label("%s %s" % [contact.get("intro", ""), contact.get("line_high", "") if Crime.heat() >= int(Crime.data.get("heat_visit", 10)) * 0.7 else contact.get("line_low", "")], 24, UIKit.DARK, "small")
	blurb.custom_minimum_size = Vector2(width - 40, 0)
	col.add_child(blurb)
	rows.add_child(intro)
	for branch in Crime.branches():
		var branch_id := str(branch.get("id", ""))
		rows.add_child(UIKit.label("%s  ·  %s" % [branch.get("name", ""), branch.get("blurb", "")], 24, UIKit.TERRA, "small", false))
		for row in Crime.nodes():
			if str(row.get("branch", "")) != branch_id:
				continue
			rows.add_child(_crime_card(row, width))
	var log: Array = Crime.state().get("log", [])
	if not log.is_empty():
		rows.add_child(UIKit.label("Lately", 28, UIKit.TERRA, "title", false))
		var shown := 0
		for entry in log:
			if shown >= 5:
				break
			shown += 1
			var card := _goal_card_shell(width, Color("F6EEDC"))
			var line := UIKit.label("Day %d  ·  %s" % [int(entry.get("day", 0)), entry.get("line", "")], 24, UIKit.DARK, "small")
			line.custom_minimum_size = Vector2(width - 40, 0)
			(card.get_child(0) as VBoxContainer).add_child(line)
			rows.add_child(card)


func _goal_card_shell(width: float, tint: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var box := UIKit.style(tint, 14)
	box.shadow_size = 0
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(width, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	return card


func _crime_card(row: Dictionary, width: float) -> PanelContainer:
	var id := str(row.get("id", ""))
	var held := Crime.unlocked(id)
	var open := Crime.available(row)
	var card := _goal_card_shell(width, Color("E4EBD6") if held else (Color("F6EEDC") if open else Color("EDE7DD")))
	var col := card.get_child(0) as VBoxContainer
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	col.add_child(line)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	text.add_child(head)
	head.add_child(UIKit.label("%s%s" % ["✓ " if held else "", row.get("name", id)], 28, UIKit.DARK if open else Color("9A9388"), "title", false))
	var meta := UIKit.label("tier %d  ·  %s  ·  heat +%d, cred +%d" % [int(row.get("tier", 1)), ("yours" if held else ("%d cred" % int(row.get("cred_cost", 0)))), int(row.get("heat", 0)), int(row.get("cred", 0))], 24, UIKit.WOOD, "small", false)
	meta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(meta)
	var blurb := UIKit.label(str(row.get("blurb", "")), 24, UIKit.DARK, "small")
	blurb.custom_minimum_size = Vector2(width - 360, 0)
	text.add_child(blurb)
	if not held:
		var buy := UIKit.button("Unlock", UIKit.NIGHT)
		buy.name = "Unlock_" + id
		buy.custom_minimum_size = Vector2(150, 52)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.disabled = not open
		buy.pressed.connect(func():
			var err := Crime.unlock(id)
			if err != "":
				_toast(err, "Sal")
				AudioDirector.play_sfx("sfx_invalid_placement")
				return
			AudioDirector.play_sfx("sfx_cash_gain")
			SaveManager.save_game()
			_open_jobs("backroom")
		)
		line.add_child(buy)
		return card
	var action := str(row.get("action", ""))
	if action == "fence" or action == "fence_bulk":
		var count := 5 if action == "fence_bulk" else 1
		var any := false
		for good in ItemDB.trade_goods():
			var good_id := str(good.get("id", ""))
			if int(GameState.goods.get(good_id, 0)) < count:
				continue
			any = true
			var sell := UIKit.button("Fence %s%s" % [good.get("name", good_id), (" x%d" % count) if count > 1 else ""], UIKit.TERRA)
			sell.name = "Fence_%s_%d" % [good_id, count]
			sell.custom_minimum_size = Vector2(240, 52)
			sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sell.pressed.connect(func():
				var offer: Dictionary = Crime.fence_offer(good_id, count)
				if offer.has("error"):
					_toast(str(offer["error"]), "Sal")
					return
				_open_haggle(offer)
			)
			line.add_child(sell)
			break
		if not any:
			text.add_child(UIKit.label("Buy a trade good at the market first.", 24, UIKit.BLUE, "small", false))
		if action == "fence" and not Crime.loot().is_empty():
			var bag := UIKit.button("Sell the bag ($%d)" % Crime.loot_value(), UIKit.NIGHT)
			bag.name = "SellLoot"
			bag.custom_minimum_size = Vector2(240, 52)
			bag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bag.pressed.connect(func():
				var result: Dictionary = Crime.sell_loot()
				if result.has("error"):
					_toast(str(result["error"]), "Sal")
					return
				AudioDirector.play_sfx("sfx_cash_gain")
				_toast("Sal takes the bag. $%d, no questions." % int(result.get("paid", 0)), "Sal")
				SaveManager.save_game()
				_open_jobs("backroom")
			)
			line.add_child(bag)
	elif action == "fence_graded":
		text.add_child(UIKit.label("Restored and mint goods on the workbench's Fix up tab can go to Sal instead.", 24, UIKit.BLUE, "small", false))
	elif action == "lie_low":
		var low := UIKit.button("Close up early", UIKit.NIGHT)
		low.name = "LieLow"
		low.custom_minimum_size = Vector2(240, 52)
		low.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		low.pressed.connect(func():
			var result: Dictionary = Crime.lie_low()
			if result.has("error"):
				_toast(str(result["error"]), "Sal")
				return
			AudioDirector.play_sfx("sfx_l01_garage_door_roll")
			SaveManager.save_game()
			_open_jobs("backroom")
			_toast("Shutters down. Heat %d." % Crime.heat(), "Sal")
		)
		line.add_child(low)
	elif action == "bribe":
		var word := UIKit.button("A quiet word ($%d)" % int(row.get("cost", 120)), UIKit.NIGHT)
		word.name = "Bribe"
		word.custom_minimum_size = Vector2(280, 52)
		word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		word.pressed.connect(func():
			var result: Dictionary = Crime.bribe()
			if result.has("error"):
				_toast(str(result["error"]), "Sal")
				return
			AudioDirector.play_sfx("sfx_cash_gain")
			SaveManager.save_game()
			_open_jobs("backroom")
			_toast("A file went missing. Visits on record: %d." % int(result.get("visits", 0)), "Sal")
		)
		line.add_child(word)
	elif action == "night_job":
		if Crime.night_job_available():
			var go := UIKit.button("Take tonight's move", UIKit.TERRA)
			go.name = "NightJob"
			go.custom_minimum_size = Vector2(280, 52)
			go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			go.pressed.connect(func():
				var err := Crime.take_night_job()
				if err != "":
					_toast(err, "Sal")
					return
				SaveManager.save_game()
				AudioDirector.play_sfx("sfx_notification_soft")
				emit_signal("request_rebuild")
			)
			line.add_child(go)
		else:
			text.add_child(UIKit.label("One a night. Back tomorrow.", 24, UIKit.BLUE, "small", false))
	elif action == "knockoff":
		var any_made := false
		for recipe in Workshop.recipes():
			var recipe_id := str(recipe.get("id", ""))
			if Workshop.made_count(recipe_id) <= 0:
				continue
			any_made = true
			var sell := UIKit.button("Pass off %s" % recipe.get("name", recipe_id), UIKit.TERRA)
			sell.name = "Knockoff_" + recipe_id
			sell.custom_minimum_size = Vector2(260, 52)
			sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sell.pressed.connect(func():
				var result: Dictionary = Crime.knockoff(recipe_id)
				if result.has("error"):
					_toast(str(result["error"]), "Sal")
					return
				if bool(result.get("caught", false)):
					AudioDirector.play_sfx("sfx_invalid_placement")
					SaveManager.save_game()
					_open_jobs("backroom")
					_toast(str(result.get("line", "Caught.")), "Marge")
					return
				AudioDirector.play_sfx("sfx_cash_gain")
				SaveManager.save_game()
				_open_jobs("backroom")
				_toast("$%d. Heat %d." % [int(result.get("pay", 0)), Crime.heat()], "Sal")
			)
			line.add_child(sell)
			break
		if not any_made:
			text.add_child(UIKit.label("Make something on the workbench first.", 24, UIKit.BLUE, "small", false))
	return card


func _fill_goals(rows: VBoxContainer, width: float) -> void:
	var open_rows: Array = []
	var done_rows: Array = []
	for contract in GameState.contracts():
		if GameState.contracts_done.has(str(contract.get("id", ""))):
			done_rows.append(contract)
		else:
			open_rows.append(contract)
	var intro := UIKit.label("Marge pins a goal, you tick it off, the jar fills. Rewards land in the mail.", 24, UIKit.DARK, "small")
	intro.custom_minimum_size = Vector2(width - 20.0, 0)
	rows.add_child(intro)
	for contract in open_rows:
		rows.add_child(_goal_card(contract, width, false))
	if not done_rows.is_empty():
		rows.add_child(UIKit.label("On the wall", 28, UIKit.TERRA, "title", false))
		for contract in done_rows:
			rows.add_child(_goal_card(contract, width, true))


func _goal_card(contract: Dictionary, width: float, done: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var box := UIKit.style(Color("E4EBD6") if done else Color("F6EEDC"), 14)
	box.shadow_size = 0
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(width, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	text.add_child(head)
	head.add_child(UIKit.label(("✓ " if done else "") + str(contract.get("title", "")), 28, UIKit.DARK, "title", false))
	var reward := "$%d" % int(contract.get("money", 0))
	if int(contract.get("rep", 0)) > 0:
		reward += "  +%d Rep" % int(contract.get("rep", 0))
	var reward_label := UIKit.label(reward, 24, UIKit.SAGE, "small", false)
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(reward_label)
	var have := mini(GameState.contract_progress(contract), int(contract.get("need", 1)))
	var blurb := UIKit.label("%s  ·  %d / %d" % [contract.get("blurb", ""), have, int(contract.get("need", 1))], 24, UIKit.DARK, "small")
	blurb.custom_minimum_size = Vector2(width - 260.0, 0)
	text.add_child(blurb)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width - 60.0, 14)
	bar.show_percentage = false
	bar.max_value = float(maxi(1, int(contract.get("need", 1))))
	bar.value = float(have)
	var back := UIKit.style(Color("D8C9A8"), 7)
	back.shadow_size = 0
	var front := UIKit.style(UIKit.SAGE, 7)
	front.shadow_size = 0
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", front)
	text.add_child(bar)
	return card


func _act_button(layer: CanvasLayer, text: String, at: Vector2, callback: Callable) -> void:
	if layer == null:
		return
	var fills := {"Jobs": UIKit.TERRA, "Map": UIKit.BLUE, "Computer": UIKit.NIGHT, "Workbench": UIKit.WOOD, "Pause": UIKit.DARK, "Rotate view": UIKit.CARD}
	var fill: Color = fills.get(text, UIKit.TERRA if "Finish" in text or "Drive" in text else UIKit.SAGE)
	var btn := UIKit.button(text, fill, UIKit.DARK if fill == UIKit.CARD else UIKit.CREAM_CARD)
	btn.name = "ActButton"
	btn.set_meta("act_button", true)
	btn.custom_minimum_size = Vector2(280, 56)
	btn.pressed.connect(callback)
	layer.add_child(btn)
	var height := 56.0
	var top := at.y
	var vp_h := btn.get_viewport_rect().size.y
	if vp_h < 8.0:
		vp_h = 800.0
	if top + height > vp_h - 180.0:
		top = maxf(124.0, vp_h - 180.0 - height)
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if at.x < 400.0:
		UIKit.pin_top_left(btn, 16, top, 340, top + height)
		btn.grow_horizontal = Control.GROW_DIRECTION_END
	else:
		UIKit.pin_top_right(btn, -356, top, -16, top + height)
		btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_wire_hud_focus(layer)


func _wire_hud_focus(layer: CanvasLayer) -> void:
	var buttons: Array = []
	for child in layer.get_children():
		if child is Button:
			buttons.append(child)
	if not buttons.is_empty():
		UIKit.link_focus(buttons)


func _hud_layer() -> CanvasLayer:
	# The HUD layer by name: a level postcard adds a CanvasLayer of its own,
	# and taking the first one found used to leave action buttons behind in it.
	var named := get_node_or_null("HUD")
	if named is CanvasLayer:
		return named
	for child in get_children():
		if child is CanvasLayer:
			return child
	return null


func _hint_text() -> String:
	var line := _mode_hint()
	var goal := _goal_hint()
	if objective:
		objective.text = goal if goal != "" else _mode_objective()
	_sync_chips()
	return line


func _mode_objective() -> String:
	match GameState.mode:
		"office":
			if GameState.office_phase == "pack":
				return "Pack up the old office"
			if GameState.office_phase == "place":
				return "Set up %s" % venue.get("name", "the room")
			return "Make it yours"
		"job_pack":
			var left := 0
			for item in GameState.job.get("items", []):
				if str(item.get("state", "")) == "loose":
					left += 1
			return "Pack %d pieces" % GameState.job.get("items", []).size() if left == GameState.job.get("items", []).size() else "%d piece%s left to box" % [left, "" if left == 1 else "s"]
		"truck":
			return "Load the truck"
		"job_unpack":
			return "Unpack and place"
	return ""


func _mode_chips() -> Array:
	match GameState.mode:
		"office":
			if GameState.office_phase == "pack":
				return [["Click", "box it"]]
			if GameState.office_phase == "place":
				return [["Click", "place"], ["R", "rotate"], ["G", "grid"], ["Q E", "turn view"]]
			return [["R", "rotate"], ["G", "grid"], ["Q E", "turn view"], ["M", "map"]]
		"job_pack":
			return [["Click", "box it"], ["Esc", "pause"]]
		"truck":
			return [["Click", "pad"], ["Click", "take back"]]
		"job_unpack":
			return [["Click", "carry, open"], ["R", "rotate"], ["Q E", "turn view"]]
	return []


func _sync_chips() -> void:
	if chips_slot == null:
		return
	var items := _mode_chips()
	var key := JSON.stringify(items)
	if key == _chips_key:
		return
	_chips_key = key
	for child in chips_slot.get_children():
		child.queue_free()
	chips_slot.add_child(UIKit.chips(items))


func _goal_hint() -> String:
	if backdrop or venue.is_empty():
		return ""
	var placing := (GameState.mode == "office" and GameState.office_phase == "place") or GameState.mode == "job_unpack"
	if not placing:
		return ""
	var goal: Dictionary = StackGoals.active(str(venue.get("id", "")), GameState.character, _goal_items(), GameState.latched_goals)
	return str(goal.get("hint", ""))


func _mode_hint() -> String:
	var money := "$%d" % GameState.money
	var rep := "Rep %d" % GameState.rep_rank()
	var today := GameState.money - int(GameState.day_log.get("money_start", GameState.money))
	var ledger := "today %s$%d" % ["+" if today >= 0 else "−", absi(today)]
	var head := "%s   %s\n%s   %s" % [venue.get("name", "Office"), money, ledger, rep]
	if status:
		if GameState.mode == "office" and GameState.office_phase == "live":
			head += "   Vibe %d" % GameState.vibe_score()
		status.text = head
	match GameState.mode:
		"office":
			if GameState.office_phase == "pack":
				return "Click each piece and it goes in a box."
			if GameState.office_phase == "place":
				return "Click a box, then the floor, a desk, or a stack. Shift+R turns 15°. Wall pieces snap to the wall."
			var extra := ""
			if not GameState.door_orders().is_empty():
				extra = " A courier box is by the door."
			if GameState.shop_open():
				extra += " Visitors wander in."
			return "Pick things up and set them on the floor or on each other. The wheel zooms, or turns what you hold." + extra
		"job_pack":
			return "Fragile likes padding. Heavy rides alone, on the bottom. New box when one is full."
		"truck":
			return "Pick a box, then a pad in the bed. Mustard pads are the floor, and heavy goes there."
		"job_unpack":
			return "Click a box in the truck to carry it in. Click it again to see what's inside, then set each piece on the floor, a desk or a shelf. Stack the boxes to clear the floor."
	return ""


func _goal_items() -> Array:
	var items: Array = []
	for rec in GameState.office_items:
		var office_state := str(rec.get("state", ""))
		if office_state == "placed" or office_state == "settling":
			items.append(_goal_from_record(rec, str(rec.get("item", ""))))
	for rec in GameState.job.get("items", []):
		var job_state := str(rec.get("state", ""))
		if job_state == "placed" or job_state == "settling" or job_state == "loose":
			items.append(_goal_from_record(rec, str(rec.get("item_id", rec.get("item", "")))))
	_collect_goal_nodes(self, items)
	return items


func _goal_from_record(rec: Dictionary, item_id: String) -> Dictionary:
	var def := ItemDB.get_item(item_id)
	return {
		"uid": str(rec.get("uid", "")),
		"item": item_id,
		"model": str(def.get("model", rec.get("model", ""))),
		"x": float(rec.get("x", 0.0)),
		"y": float(rec.get("y", 0.0)),
		"z": float(rec.get("z", 0.0)),
		"rot": float(rec.get("rot", 0.0)),
		"w": float(def.get("w", rec.get("w", 0.3))),
		"d": float(def.get("d", rec.get("d", 0.3))),
		"h": float(def.get("h", rec.get("h", 0.3))),
		"tag": str(rec.get("set", rec.get("tag", ""))),
		"turned": bool(rec.get("goal_turned", false)),
	}


func _collect_goal_nodes(node: Node, items: Array) -> void:
	if node != self and node.has_meta("goal_item") and str(node.name) != "GoalFern":
		var item_id := str(node.get_meta("goal_item"))
		var def := ItemDB.get_item(item_id)
		var pos := Vector3.ZERO
		var rot := 0.0
		if node is Node3D:
			pos = (node as Node3D).global_position
			rot = rad_to_deg((node as Node3D).rotation.y)
		items.append({
			"uid": "dress_%s" % node.name,
			"item": item_id,
			"model": str(node.get_meta("goal_model", def.get("model", item_id))),
			"x": pos.x,
			"y": pos.y,
			"z": pos.z,
			"rot": rot,
			"w": float(node.get_meta("goal_w", def.get("w", 0.4))),
			"d": float(node.get_meta("goal_d", def.get("d", 0.4))),
			"h": float(node.get_meta("goal_h", def.get("h", 0.4))),
			"tag": "",
			"turned": false,
		})
	for child in node.get_children():
		_collect_goal_nodes(child, items)


func _check_goals() -> void:
	if backdrop or venue.is_empty():
		return
	var items := _goal_items()
	for goal in StackGoals.all_goals():
		if str(goal.get("venue", "")) != str(venue.get("id", "")):
			continue
		var goal_id := str(goal.get("id", ""))
		var result: Dictionary = StackGoals.evaluate(goal, items, GameState.latched_goals)
		var met := bool(result.get("met", false))
		if met and not bool(GameState.goal_marked.get(goal_id, false)):
			GameState.goal_marked[goal_id] = true
			if bool(result.get("latch", false)):
				GameState.latched_goals[goal_id] = true
				_toast(str(goal.get("hint", "")))
			var yaw_uid := str(result.get("yaw_uid", ""))
			if yaw_uid != "" and float(result.get("yaw_add", 0.0)) != 0.0:
				_turn_goal_item(yaw_uid, float(result.get("yaw_add", 0.0)))
			if float(result.get("pip", 0.0)) > 0.0:
				_goal_pip = float(result.get("pip", 0.0))
			_markers_key = ""
		elif not met and not bool(goal.get("latch", false)):
			GameState.goal_marked.erase(goal_id)


func _turn_goal_item(uid: String, add: float) -> void:
	var rec := _record_for(uid)
	if rec.is_empty() or bool(rec.get("goal_turned", false)):
		return
	rec["rot"] = fposmod(float(rec.get("rot", 0.0)) + add, 360.0)
	rec["goal_turned"] = true
	var node: Node = nodes_by_uid.get(uid)
	if node is Node3D:
		(node as Node3D).rotation.y = deg_to_rad(float(rec.get("rot", 0.0)))


func _sync_goal_markers() -> void:
	if backdrop or venue.is_empty():
		return
	var items := _goal_items()
	var goal: Dictionary = StackGoals.active(str(venue.get("id", "")), GameState.character, items, GameState.latched_goals)
	var key := "%s|%s|%s" % [goal.get("id", ""), held_uid, str(_goal_pip > 0.0)]
	if key == _markers_key:
		return
	_markers_key = key
	var old := get_node_or_null("GoalMarkers")
	if old:
		old.free()
	if goal.is_empty():
		return
	if StackGoals.shows_when_held(goal) and not _holding_goal(goal) and _goal_pip <= 0.0:
		return
	var pose: Dictionary = StackGoals.marker_pose(goal, items)
	if pose.is_empty():
		return
	var root := Node3D.new()
	root.name = "GoalMarkers"
	add_child(root)
	if str(pose.get("kind", "")) == "ring":
		_add_goal_ring(root, pose)
		return
	var model_name := str(pose.get("model", ""))
	if model_name == "":
		return
	var ghost := Props.make(model_name)
	var collision := ghost.get_node_or_null("PropCollision")
	if collision:
		collision.free()
	ghost.position = Vector3(float(pose.get("x", 0.0)), float(pose.get("y", 0.0)), float(pose.get("z", 0.0)))
	ghost.rotation.y = deg_to_rad(float(pose.get("rot", 0.0)))
	for mesh in ghost.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh as MeshInstance3D
		var source: Material = mesh_instance.material_override
		if source == null and mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
			source = mesh_instance.mesh.surface_get_material(0)
		mesh_instance.material_override = ghost_material(source, true)
	root.add_child(ghost)


func _holding_goal(goal: Dictionary) -> bool:
	if held_uid == "":
		return false
	var def := _held_def()
	var model := str(def.get("model", ""))
	var wanted := ItemDB.get_item(str(goal.get("item", "")))
	if model != "" and model == str(wanted.get("model", "")):
		return true
	for extra in goal.get("also", []):
		var alt := ItemDB.get_item(str(extra))
		if model != "" and model == str(alt.get("model", extra)):
			return true
	return "mug" in model and "mug" in str(goal.get("item", ""))


func _add_goal_ring(root: Node3D, pose: Dictionary) -> void:
	var radius := float(pose.get("radius", 1.0))
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var steps := 40
	var inner := radius * 0.86
	for i in steps + 1:
		var angle := TAU * float(i) / float(steps)
		var c := cos(angle)
		var s := sin(angle)
		mesh.surface_add_vertex(Vector3(c * inner, 0.0, s * inner))
		mesh.surface_add_vertex(Vector3(c * radius, 0.0, s * radius))
	mesh.surface_end()
	var ring := MeshInstance3D.new()
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(UIKit.MUSTARD, 0.55)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = material
	ring.position = Vector3(float(pose.get("x", 0.0)), float(pose.get("y", 0.03)), float(pose.get("z", 0.0)))
	root.add_child(ring)


func _toast(message: String, who := "Dana") -> void:
	if toast == null:
		return
	if toast_name:
		toast_name.text = who
		var face := toast_name.get_parent().get_parent().get_node_or_null("ToastFace")
		if face:
			var letter := face.get_child(0) as Label
			if letter:
				letter.text = who.left(1)
			face.add_theme_stylebox_override("panel", UIKit.style(UIKit.TERRA if who == "Marge" else UIKit.SAGE, 24))
	toast.text = message
	toast.visible = true
	if toast_bar:
		toast_bar.visible = true
	toast_time = 3.4


func _sync_deliveries() -> void:
	if GameState.mode != "office" or GameState.office_phase != "live":
		return
	if delivery_root == null:
		delivery_root = Node3D.new()
		delivery_root.name = "Deliveries"
		add_child(delivery_root)
	var live := {}
	var index := 0
	for order in GameState.door_orders():
		var uid := str(order.get("uid", ""))
		live[uid] = true
		if delivery_root.get_node_or_null(uid) == null:
			var box := Props.make("box_closed")
			box.name = uid
			var at := Vector3(float(venue.get("x", 0)) + 1.15 + float(index) * 0.7, 0, float(venue.get("z", 0)) + 0.9)
			box.position = at
			box.set_meta("uid", "delivery:" + uid)
			Props.add_picker(box, Vector3(0.5, 0.42, 0.45))
			delivery_root.add_child(box)
			_courier(at)
		index += 1
	for child in delivery_root.get_children():
		if not live.has(str(child.name)):
			child.queue_free()


func _courier(at: Vector3) -> void:
	var key := "%s" % at
	if courier_seen.has(key):
		return
	courier_seen[key] = true
	var person := Node3D.new()
	person.position = Vector3(at.x, 0, at.z - 2.4)
	var body := Props.mesh_cylinder(0.22, 0.9, UIKit.TERRA)
	person.add_child(body)
	var head := Props.mesh_box(Vector3(0.28, 0.28, 0.28), UIKit.CREAM)
	head.position = Vector3(0, 1.05, 0)
	person.add_child(head)
	add_child(person)
	AudioDirector.play_sfx("sfx_notification_soft")
	var tw := create_tween()
	tw.tween_property(person, "position", Vector3(at.x, 0, at.z - 0.7), 0.9)
	tw.tween_interval(0.35)
	tw.tween_property(person, "position", Vector3(at.x, 0, at.z - 2.8), 0.9)
	tw.tween_callback(person.queue_free)
	_toast("Courier at the door.")


func _delivery_click(uid: String) -> void:
	var order := GameState.delivery_by_uid(uid)
	if order.is_empty():
		return
	if str(order.get("status", "")) == "door":
		GameState.start_unbox(uid)
		AudioDirector.play_sfx("sfx_tape_rip")
		AudioDirector.play_sfx("sfx_paper_rustle")
	unbox_uid = uid
	_show_unbox()


func _show_unbox() -> void:
	var layer := _hud_layer()
	if layer == null:
		return
	var old := layer.get_node_or_null("Unbox")
	if old:
		old.queue_free()
	var order := GameState.delivery_by_uid(unbox_uid)
	if order.is_empty():
		return
	var panel := Panel.new()
	panel.name = "Unbox"
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 18))
	layer.add_child(panel)
	UIKit.pin_center(panel, Vector2(760, 420))
	var title := UIKit.label("TropicalForest box", 36, UIKit.DARK, "title", false)
	title.position = Vector2(24, 16)
	panel.add_child(title)
	var left := int(order.get("bubbles_left", 0))
	var blurb := UIKit.label("Pop the bubble wrap. Packing peanuts drift out. %d left." % left, 36, UIKit.DARK)
	blurb.position = Vector2(24, 72)
	blurb.size = Vector2(700, 80)
	blurb.custom_minimum_size = Vector2(700, 48)
	panel.add_child(blurb)
	var buttons: Array = []
	var pop := UIKit.button("Pop a bubble", UIKit.BLUE)
	pop.position = Vector2(24, 180)
	pop.size = Vector2(240, 56)
	pop.custom_minimum_size = Vector2(240, 56)
	pop.pressed.connect(_pop_bubble)
	panel.add_child(pop)
	buttons.append(pop)
	if str(order.get("status", "")) == "door" or left == int(Catalog.forest.get("bubbles", 5)):
		var back := UIKit.button("Return sealed", UIKit.TERRA)
		back.position = Vector2(280, 180)
		back.size = Vector2(240, 56)
		back.custom_minimum_size = Vector2(240, 56)
		back.pressed.connect(_return_sealed)
		panel.add_child(back)
		buttons.append(back)
	var close := UIKit.button("Later", UIKit.DARK)
	close.position = Vector2(24, 260)
	close.size = Vector2(200, 56)
	close.custom_minimum_size = Vector2(200, 56)
	close.pressed.connect(func():
		var node := layer.get_node_or_null("Unbox")
		if node:
			node.queue_free()
	)
	panel.add_child(close)
	buttons.append(close)
	UIKit.link_focus(buttons)


func _pop_bubble() -> void:
	var left := GameState.pop_bubble(unbox_uid)
	AudioDirector.play_sfx("sfx_ui_click")
	if left > 0:
		_show_unbox()
		return
	AudioDirector.play_sfx("sfx_box_open")
	var placed := GameState.finish_unbox(unbox_uid)
	var layer := _hud_layer()
	if layer:
		var node := layer.get_node_or_null("Unbox")
		if node:
			node.queue_free()
	unbox_uid = ""
	if placed.is_empty():
		return
	held_uid = str(placed.get("uid", ""))
	held_source = "decor"
	held_rot = 0
	_toast("It's out. Click the floor to snap it in.")
	_refresh_items()
	SaveManager.save_game()


func _return_sealed() -> void:
	var err := GameState.return_delivery(unbox_uid)
	if err != "":
		_toast(err)
		return
	AudioDirector.play_sfx("sfx_cash_gain")
	unbox_uid = ""
	var layer := _hud_layer()
	if layer:
		var node := layer.get_node_or_null("Unbox")
		if node:
			node.queue_free()
	_sync_deliveries()
	SaveManager.save_game()


func _return_held() -> void:
	var err := GameState.return_office_item(held_uid)
	if err != "":
		_toast(err)
		return
	held_uid = ""
	held_source = ""
	AudioDirector.play_sfx("sfx_cash_gain")
	_toast("Sent back. Most of the money came home.")
	_refresh_items()
	SaveManager.save_game()


func _resell_held() -> void:
	var err := GameState.resell_office_item(held_uid)
	if err != "":
		_toast(err)
		return
	held_uid = ""
	held_source = ""
	AudioDirector.play_sfx("sfx_sell_click")
	AudioDirector.play_sfx("sfx_cash_gain")
	_toast("The market took it.")
	_refresh_items()
	SaveManager.save_game()


func _tick_visitors(delta: float) -> void:
	_sync_shop_sign()
	for entry in customers:
		_tick_customer(entry, delta)
	if GameState.mode != "office" or GameState.office_phase != "live" or not GameState.shop_accepting():
		return
	visitor_wait -= delta
	if visitor_wait > 0.0:
		return
	var vibe := GameState.vibe_score()
	var base := Catalog.shop_number("tick_seconds", 16)
	var haste := Catalog.shop_number("vibe_haste", 0.08)
	visitor_wait = maxf(6.0, base - float(vibe) * haste)
	var waiting := 0
	for entry in customers:
		if str(entry.get("stage", "")) != "leaving":
			waiting += 1
	if waiting < int(Catalog.shop_number("queue_max", 3)):
		_spawn_customer()


func _spawn_street() -> void:
	# Passers-by on the pavement beyond the road: the town going about its day.
	for entry in street:
		var old: Node3D = entry.get("node")
		if old and is_instance_valid(old):
			old.queue_free()
	street.clear()
	if GameState.mode == "truck" or venue.is_empty():
		return
	var cx := float(venue.get("x", 0)) + float(venue.get("w", 6)) * 0.5
	var z := float(venue.get("z", 0)) - 4.2
	var palette := [Color("D9765F"), Color("8FAF7E"), Color("7FA3B8"), Color("E6B655"), Color("C68B59"), Color("D4C1D8")]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("street:%s:%d" % [venue.get("id", ""), GameState.day])
	for i in 4:
		var person := _make_person(palette[(i + GameState.day) % palette.size()], Color("4A3626") if i % 2 == 0 else Color("2B2622"))
		person.name = "Passerby%d" % i
		var x := cx - 12.0 + rng.randf() * 24.0
		var dir := 1.0 if rng.randf() < 0.5 else -1.0
		person.position = Vector3(x, 0.0, z + rng.randf_range(-0.3, 0.3))
		person.rotation.y = PI * 0.5 if dir > 0.0 else -PI * 0.5
		add_child(person)
		street.append({"node": person, "dir": dir, "speed": rng.randf_range(0.7, 1.1), "phase": rng.randf() * TAU, "pause": 0.0, "cx": cx})
		if i == 1:
			var dog := _make_dog(Color("B98A5A"))
			dog.position = person.position + Vector3(-dir * 0.7, 0.0, 0.35)
			add_child(dog)
			street.append({"node": dog, "dir": dir, "speed": rng.randf_range(0.7, 1.1), "phase": rng.randf() * TAU, "pause": 0.0, "cx": cx, "dog": true, "owner": person})


func _make_dog(color: Color) -> Node3D:
	var dog := Node3D.new()
	var figure := Node3D.new()
	figure.name = "Figure"
	dog.add_child(figure)
	var body := Props.mesh_box(Vector3(0.22, 0.2, 0.5), color)
	body.position.y = 0.2
	figure.add_child(body)
	var head := Props.mesh_box(Vector3(0.18, 0.18, 0.22), color)
	head.position = Vector3(0, 0.36, 0.3)
	figure.add_child(head)
	var tail := Props.mesh_box(Vector3(0.04, 0.04, 0.2), color.darkened(0.2))
	tail.name = "Tail"
	tail.position = Vector3(0, 0.36, -0.3)
	figure.add_child(tail)
	for leg in [Vector3(-0.08, 0, 0.18), Vector3(0.08, 0, 0.18), Vector3(-0.08, 0, -0.18), Vector3(0.08, 0, -0.18)]:
		var post := Props.mesh_cylinder(0.03, 0.2, color.darkened(0.15))
		post.position = leg
		figure.add_child(post)
	return dog


func _tick_street(delta: float) -> void:
	ambient_time += delta
	for entry in street:
		var node: Node3D = entry.get("node")
		if node == null or not is_instance_valid(node):
			continue
		var dir := float(entry.get("dir", 1.0))
		if bool(entry.get("dog", false)):
			var owner: Node3D = entry.get("owner")
			if owner and is_instance_valid(owner):
				var goal := owner.position + Vector3(-float(entry.get("dir", 1.0)) * 0.7, 0.0, 0.35)
				node.position = node.position.lerp(goal, minf(1.0, delta * 3.0))
				node.rotation.y = owner.rotation.y
				var figure := node.get_node_or_null("Figure") as Node3D
				if figure:
					figure.position.y = absf(sin(ambient_time * 12.0 + float(entry.get("phase", 0.0)))) * 0.04
					var tail := figure.get_node_or_null("Tail") as Node3D
					if tail:
						tail.rotation.y = sin(ambient_time * 10.0) * 0.6
			continue
		entry["pause"] = maxf(0.0, float(entry.get("pause", 0.0)) - delta)
		var walking := float(entry["pause"]) <= 0.0
		if walking:
			node.position.x += dir * float(entry.get("speed", 0.9)) * delta
			var cx := float(entry.get("cx", 0.0))
			if node.position.x > cx + 13.0 or node.position.x < cx - 13.0:
				entry["dir"] = -dir
				node.rotation.y = PI * 0.5 if -dir > 0.0 else -PI * 0.5
			if randf() < delta * 0.03:
				entry["pause"] = randf_range(1.5, 4.0)
				if randf() < 0.5:
					_bubble(node, _chat("passing"))
		_animate_person(node, ambient_time + float(entry.get("phase", 0.0)), walking, delta)


func _browse_targets() -> Array:
	# Placed things worth a look: a seat, a shelf, a plant, a picture.
	var out: Array = []
	for rec in GameState.office_items:
		if str(rec.get("state", "")) != "placed":
			continue
		var item_id := str(rec.get("item", ""))
		var kind := ""
		if "beanbag" in item_id or "cushion" in item_id or item_id == "office_chair":
			kind = "sit"
		elif "shelf" in item_id or "bookshelf" in item_id or "picture" in item_id or "poster" in item_id or item_id == "whiteboard":
			kind = "look"
		elif "plant" in item_id or "fern" in item_id or "cactus" in item_id:
			kind = "sniff"
		elif "cat" in item_id or "lamp" in item_id or "clock" in item_id:
			kind = "look"
		if kind == "":
			continue
		var node: Node = nodes_by_uid.get(str(rec.get("uid", "")))
		if node is Node3D:
			out.append({"uid": str(rec.get("uid", "")), "node": node, "kind": kind, "item": item_id})
	return out


func _spawn_browser(from_car: Node3D = null) -> bool:
	if not browser.is_empty() or GameState.mode != "office" or GameState.office_phase != "live" or backdrop:
		return false
	var targets := _browse_targets()
	if targets.is_empty():
		return false
	var pick: Dictionary = targets[randi() % targets.size()]
	var target: Node3D = pick["node"]
	var names := ["Ravi", "Lou", "Mrs. Okafor", "the postie", "a neighbour", "Sam from next door"]
	var who := str(names[randi() % names.size()])
	var person := _make_person([UIKit.PINK, UIKit.BLUE, UIKit.SAGE, UIKit.MUSTARD][randi() % 4], Color("6E4A2F"))
	person.name = "Browser"
	var door := _door_world()
	person.position = door + Vector3(0.6, 0.0, -3.2)
	if from_car != null:
		person.position = from_car.position + Vector3(1.1, 0.0, 0.2)
	add_child(person)
	_bubble(person, _chat("arriving"))
	AudioDirector.play_sfx("sfx_customer_bell", true)
	var at := target.global_position
	var stand := at + (door - at).normalized() * 0.75
	stand.y = 0.0
	if str(pick["kind"]) == "sit":
		stand = at + Vector3(0, 0, 0.05)
	browser = {"node": person, "stage": "walking", "kind": pick["kind"], "item": pick["item"], "t": 0.0, "who": who, "timer": 0.0, "target": target, "car": from_car}
	var tw := create_tween()
	tw.tween_property(person, "position", door + Vector3(0.3, 0.0, 0.4), 1.4)
	tw.tween_property(person, "position", stand, 1.6)
	tw.tween_callback(func():
		if browser.is_empty() or not is_instance_valid(person):
			return
		browser["stage"] = "busy"
		browser["timer"] = randf_range(5.0, 8.0)
		person.look_at(Vector3(at.x, person.position.y, at.z), Vector3.UP)
		person.rotation.y += PI
		var figure := person.get_node_or_null("Figure") as Node3D
		_bubble(person, _chat_browsing(str(browser["kind"])))
		match str(browser["kind"]):
			"sit":
				if figure:
					figure.position.y = -0.22
					figure.rotation.x = -0.25
				_toast("%s flops on the %s. 'Don't mind me.'" % [who.capitalize(), ItemDB.display_name(str(browser["item"])).to_lower()], "Visitor")
			"sniff":
				_toast("%s leans in to the %s. 'Real? It's real.'" % [who.capitalize(), ItemDB.display_name(str(browser["item"])).to_lower()], "Visitor")
			_:
				_toast("%s stops at the %s. 'Huh. Nice.'" % [who.capitalize(), ItemDB.display_name(str(browser["item"])).to_lower()], "Visitor")
	)
	return true


func _tick_browser(delta: float) -> void:
	if GameState.mode == "office" and GameState.office_phase == "live" and not backdrop:
		browser_wait -= delta
		if browser_wait <= 0.0:
			browser_wait = randf_range(35.0, 60.0)
			_spawn_browser()
	if browser.is_empty():
		return
	var node: Node3D = browser.get("node")
	if node == null or not is_instance_valid(node):
		browser = {}
		return
	browser["t"] = float(browser.get("t", 0.0)) + delta
	var stage := str(browser.get("stage", ""))
	if stage == "busy":
		browser["timer"] = float(browser.get("timer", 0.0)) - delta
		var figure := node.get_node_or_null("Figure") as Node3D
		node.set_meta("sit", str(browser.get("kind", "")) == "sit")
		if figure and str(browser.get("kind", "")) != "sit":
			var head := figure.get_node_or_null("Head") as Node3D
			if head:
				head.position.y = 1.18 + sin(float(browser["t"]) * 2.2) * 0.02
			figure.rotation.y = sin(float(browser["t"]) * 1.1) * 0.2
			if str(browser.get("kind", "")) == "sniff":
				figure.rotation.x = 0.18
		if float(browser["timer"]) <= 0.0:
			browser["stage"] = "leaving"
			_act(node, "wave", 0.8)
			if figure:
				figure.position.y = 0.0
				figure.rotation.x = 0.0
			var door := _door_world()
			_bubble(node, _chat("leaving"))
			var car: Node3D = browser.get("car")
			var tw := create_tween()
			tw.tween_property(node, "position", door + Vector3(0.3, 0.0, 0.4), 1.6)
			if car != null and is_instance_valid(car):
				tw.tween_property(node, "position", car.position + Vector3(1.1, 0.0, 0.2), 1.5)
			else:
				tw.tween_property(node, "position", door + Vector3(0.6, 0.0, -3.4), 1.4)
			tw.tween_callback(func():
				if is_instance_valid(node):
					node.queue_free()
				if car != null and is_instance_valid(car):
					_depart_car(car)
				browser = {}
			)
	elif stage != "busy":
		_animate_person(node, float(browser["t"]), true, delta)


# ---------------------------------------------------------------- cars and bubbles

func _parking_lot() -> Node3D:
	var yard := get_node_or_null("Outdoors")
	if yard == null:
		return null
	return yard.get_node_or_null("Parking") as Node3D


func _free_slot() -> int:
	var lot := _parking_lot()
	if lot == null:
		return -1
	var slots: Array = lot.get_meta("slots", [])
	for i in slots.size():
		if not bool(parking_used.get(i, false)):
			return i
	return -1


func _make_car(color: Color) -> Node3D:
	var car := Node3D.new()
	var body := Props.mesh_box(Vector3(1.7, 0.6, 3.6), color)
	body.position.y = 0.3
	car.add_child(body)
	var cabin := Props.mesh_box(Vector3(1.5, 0.55, 1.8), color.darkened(0.15))
	cabin.position = Vector3(0, 0.9, 0.1)
	car.add_child(cabin)
	var glass := Props.mesh_box(Vector3(1.3, 0.4, 0.1), Color("9FC4D6"))
	glass.position = Vector3(0, 0.95, 1.0)
	car.add_child(glass)
	for dx in [-0.85, 0.85]:
		for dz in [-1.2, 1.2]:
			var wheel := Props.mesh_cylinder(0.3, 0.24, Color("2E2A2C"))
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(dx, 0.3, dz)
			car.add_child(wheel)
	for side in [-0.5, 0.5]:
		var lamp := Props.mesh_box(Vector3(0.22, 0.12, 0.06), Color("FFF1D2"))
		lamp.position = Vector3(side, 0.55, 1.82)
		car.add_child(lamp)
	return car


func _tick_cars(delta: float) -> void:
	if backdrop or venue.is_empty() or GameState.mode == "truck" or _parking_lot() == null:
		return
	var want_customer := GameState.mode == "office" and GameState.office_phase == "live" and GameState.shop_accepting() and customers.size() < int(Catalog.shop_number("queue_max", 3))
	var want_browser := GameState.mode == "office" and GameState.office_phase == "live" and browser.is_empty()
	car_wait -= delta
	if car_wait > 0.0 or not (want_customer or want_browser):
		return
	car_wait = randf_range(26.0, 48.0)
	_arrive_car(want_customer)


func _arrive_car(as_customer: bool) -> bool:
	var lot := _parking_lot()
	var slot := _free_slot()
	if lot == null or slot < 0:
		return false
	var slots: Array = lot.get_meta("slots", [])
	var target: Vector3 = slots[slot]
	var entry_point: Vector3 = lot.get_meta("entry", target + Vector3(0, 0, -2.6))
	var palette := [Color("D9765F"), Color("7FA3B8"), Color("E6B655"), Color("8FAF7E"), Color("D4C1D8"), Color("F4ECDD")]
	var car := _make_car(palette[randi() % palette.size()])
	car.name = "Car"
	car.set_meta("slot", slot)
	parking_used[slot] = true
	var road_z := float(venue.get("z", 0)) - 6.0
	var start := Vector3(float(venue.get("x", 0)) + float(venue.get("w", 6)) * 0.5 - 16.0, 0.0, road_z - 0.6)
	car.position = start
	car.rotation.y = -PI * 0.5
	add_child(car)
	cars.append({"node": car, "slot": slot})
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(car, "position", Vector3(entry_point.x, 0.0, road_z - 0.6), 2.6)
	tw.parallel().tween_property(car, "rotation:y", -PI * 0.5, 0.1)
	tw.tween_property(car, "rotation:y", PI, 0.5)
	tw.parallel().tween_property(car, "position", entry_point, 0.9)
	tw.tween_property(car, "position", target, 1.1)
	tw.tween_callback(func():
		if not is_instance_valid(car):
			return
		_dust(car.position + Vector3(0, 0.3, 1.6))
		# Door opens, someone steps out.
		var spawned := false
		if as_customer and GameState.shop_accepting():
			_spawn_customer(car)
			spawned = not customers.is_empty() and customers[customers.size() - 1].get("car") == car
		if not spawned:
			spawned = _spawn_browser(car)
		if not spawned:
			_depart_car(car)
	)
	return true


func _depart_car(car: Node3D) -> void:
	if car == null or not is_instance_valid(car):
		return
	var slot := int(car.get_meta("slot", -1))
	var lot := _parking_lot()
	var entry_point: Vector3 = lot.get_meta("entry", car.position) if lot else car.position + Vector3(0, 0, -2.6)
	var road_z := float(venue.get("z", 0)) - 6.0
	var away := Vector3(float(venue.get("x", 0)) + float(venue.get("w", 6)) * 0.5 + 16.0, 0.0, road_z - 0.6)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.6)
	tw.tween_property(car, "position", entry_point, 1.0)
	tw.tween_property(car, "rotation:y", PI * 0.5, 0.5)
	tw.parallel().tween_property(car, "position", Vector3(entry_point.x, 0.0, road_z - 0.6), 0.9)
	tw.tween_property(car, "position", away, 2.8)
	tw.tween_callback(func():
		for entry in cars:
			if entry.get("node") == car:
				cars.erase(entry)
				break
		if slot >= 0:
			parking_used[slot] = false
		if is_instance_valid(car):
			car.queue_free()
	)


func _chat(kind: String) -> String:
	if chatter.is_empty():
		var file := FileAccess.open("res://data/chatter.json", FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				chatter = parsed
	var pool: Array = chatter.get(kind, [])
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()])


func _chat_browsing(kind: String) -> String:
	_chat("arriving")
	var pools: Dictionary = chatter.get("browsing", {})
	var pool: Array = pools.get(kind, [])
	if pool.is_empty():
		return _chat("waiting")
	return str(pool[randi() % pool.size()])


func _bubble(node: Node3D, text: String, seconds := 4.0) -> void:
	# A thought over someone's head: a little cloud with the line in it.
	if node == null or not is_instance_valid(node) or text == "":
		return
	# The old bubble gives its name up at once, or the new one is renamed
	# "@Label3D@n" and neither the fade nor a test can find it.
	var old := node.get_node_or_null("Thought")
	if old != null:
		old.name = "ThoughtGone"
		old.queue_free()
	var old_dot := node.get_node_or_null("ThoughtDot")
	if old_dot != null:
		old_dot.name = "ThoughtDotGone"
		old_dot.queue_free()
	var label := Label3D.new()
	label.name = "Thought"
	label.text = text
	label.font = UIKit.body_font()
	label.font_size = 36
	label.pixel_size = 0.0042
	label.outline_size = 10
	label.outline_modulate = UIKit.CREAM_CARD
	label.modulate = UIKit.DARK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 420.0
	label.position = Vector3(0, 1.95, 0)
	label.set_meta("ttl", seconds)
	node.add_child(label)
	var dot := Props.mesh_cylinder(0.035, 0.01, UIKit.CREAM_CARD)
	dot.name = "ThoughtDot"
	dot.position = Vector3(0.1, 1.58, 0)
	dot.set_meta("ttl", seconds)
	node.add_child(dot)


func _tick_bubbles(delta: float) -> void:
	for label in get_tree().get_nodes_in_group("thought_bubbles"):
		pass
	for node in find_children("Thought", "Label3D", true, false):
		var ttl := float(node.get_meta("ttl", 0.0)) - delta
		node.set_meta("ttl", ttl)
		var dot := node.get_parent().get_node_or_null("ThoughtDot")
		if ttl <= 0.0:
			node.queue_free()
			if dot:
				dot.queue_free()
		elif ttl < 0.5:
			(node as Label3D).modulate.a = ttl / 0.5
			if dot:
				(dot as MeshInstance3D).transparency = 1.0 - ttl / 0.5


func _door_world() -> Vector3:
	var x := float(venue.get("x", 0))
	var w := float(venue.get("w", 6))
	var open_w := float(venue.get("open_w", 2))
	var door_x := x + 3.5 if (absf(open_w - 3.0) < 0.1 and w >= 6.0) else x + w * 0.5
	return Vector3(door_x, 0.0, float(venue.get("z", 0)))


func _counter_node() -> Node3D:
	# The fixture a customer walks up to: the stand in the yard once there is
	# one, else a counter piece first (the coffee machine, the pitcher), and
	# only then a shelf or the menu board.
	# Straight from the catalogue, so a fixture that is still settling counts too.
	var yard := _yard_counter()
	if yard != null:
		return yard
	var fixtures: Array = Catalog.fixtures()
	for want_counter in [true, false]:
		for fix in fixtures:
			if (str(fix.get("role", "")) == "counter") != want_counter:
				continue
			var item_id := str(fix.get("item", ""))
			for rec in GameState.office_items:
				var state := str(rec.get("state", ""))
				if (state == "placed" or state == "settling") and str(rec.get("item", "")) == item_id:
					var node: Node = nodes_by_uid.get(str(rec.get("uid", "")))
					if node is Node3D:
						return node
	return null


func _queue_spot(index: int) -> Vector3:
	var counter := _counter_node()
	var door := _door_world()
	if counter == null:
		return door + Vector3(0, 0, 1.5 + index * 0.7)
	var at := counter.global_position
	var toward := door - at
	toward.y = 0.0
	if toward.length() < 0.1:
		toward = Vector3(0, 0, -1)
	toward = toward.normalized()
	var spot := at + toward * (1.1 + index * 0.75)
	spot.y = 0.0
	return spot


const DISH_PROPS := {
	"lemonade": "glass", "iced_tea": "glass", "cold_brew": "coldbrew",
	"drip": "mug", "latte": "latte", "espresso_shot": "espresso", "tea": "teacup", "flat_white": "latte",
	"affogato": "affogato", "bun": "bun", "croissant": "croissant",
	"blt": "sandwich", "veggie_wrap": "wrap", "chicken_shawarma": "wrap", "falafel_wrap": "wrap",
	"soup_cup": "soup", "garlic_fries": "fries", "eggs_benedict": "eggs",
	"tasting_menu": "tasting", "steak_frites": "steak", "creme_brulee": "brulee",
	"used_book": "book", "pencil": "pencil", "cutting": "cutting",
}


func _order_prop(dish_id: String) -> Node3D:
	# Every dish on the ladder has its own little prop.
	var kind := str(DISH_PROPS.get(dish_id, ""))
	if kind == "":
		var tag := str(Catalog.menu_item(dish_id).get("tag", ""))
		kind = {"juice": "glass", "coffee": "mug", "snack": "bun", "sandwich": "sandwich", "grill": "wrap", "plate": "steak", "goods": "part", "plant": "cutting"}.get(tag, "mug")
	var prop := Props.make("proc:" + kind)
	var collision := prop.get_node_or_null("PropCollision")
	if collision:
		collision.free()
	return prop


func _spawn_customer(from_car: Node3D = null) -> void:
	var order: Dictionary = GameState.pick_order()
	if order.is_empty():
		return
	customer_serial += 1
	var uid := "c%d" % customer_serial
	var palette := [UIKit.BLUE, UIKit.SAGE, UIKit.TERRA, UIKit.MUSTARD, UIKit.WOOD]
	var color: Color = palette[customer_serial % palette.size()]
	var person := _make_person(color)
	person.name = "Customer_" + uid
	# The order floats over their head until it is in their hand.
	var bubble := Node3D.new()
	bubble.name = "Order"
	bubble.position = Vector3(0, 1.55, 0)
	person.add_child(bubble)
	var ring := Props.mesh_cylinder(0.17, 0.02, UIKit.CREAM_CARD)
	ring.rotation.x = PI * 0.5
	ring.position = Vector3(0, 0.08, 0.0)
	bubble.add_child(ring)
	var icon := _order_prop(str(order.get("dish", "")))
	icon.position = Vector3(0, 0.0, 0.03)
	icon.scale = Vector3(0.9, 0.9, 0.9)
	bubble.add_child(icon)
	person.set_meta("uid", "visitor:" + uid)
	Props.add_picker(person, Vector3(0.6, 1.4, 0.6))
	var start := _door_world() + Vector3(0, 0, -3.5)
	if from_car != null:
		start = from_car.position + Vector3(1.1, 0.0, 0.2)
	person.position = start
	add_child(person)
	var index := 0
	for entry in customers:
		if str(entry.get("stage", "")) != "leaving":
			index += 1
	var entry := {"uid": uid, "node": person, "order": order, "stage": "walking", "wait": 0.0, "index": index, "hover": 0.0, "car": from_car}
	var asks: Array = Catalog.asks()
	if not asks.is_empty() and randf() < 0.45:
		entry["ask"] = asks[randi() % asks.size()]
	customers.append(entry)
	var walk_in_seconds := 2.6
	get_tree().create_timer(walk_in_seconds + 0.4).timeout.connect(func():
		if is_instance_valid(person) and entry.has("ask") and not bool(entry.get("asked", false)):
			_act(person, "point", 2.4)
	)
	_bubble(person, _chat("arriving"))
	var who: Dictionary = order.get("who", {})
	if OS.get_environment("CO_DEBUG") != "":
		print("  spawn customer %s start=%s door=%s spot=%s counter=%s" % [uid, start, _door_world(), _queue_spot(index), _counter_node()])
	var tw := create_tween()
	tw.tween_property(person, "position", _door_world() + Vector3(0, 0, 0.3), 1.2)
	tw.tween_property(person, "position", _queue_spot(index), 1.0)
	tw.tween_callback(func():
		if is_instance_valid(person):
			entry["stage"] = "waiting"
			entry["wait"] = Catalog.shop_number("serve_seconds", 9)
			_bubble(person, _chat("waiting"))
			if index == 0:
				_toast(str(who.get("line", "Hello!")), str(who.get("name", "A neighbour")))
	)
	AudioDirector.play_sfx("sfx_l02_door_wind_chime")


const PERSON_KINDS := ["adult", "adult", "short", "tall", "kid", "elder"]


func _make_person(color: Color, hair: Color = Color("4A3626"), kind := "") -> Node3D:
	# A jointed figure (see figure.gd). Without a kind, one is picked so a
	# crowd has tall, short, young and old in it.
	if kind == "":
		kind = PERSON_KINDS[randi() % PERSON_KINDS.size()]
	var trousers: Color = [Color("3E3A4F"), Color("5A4A3A"), Color("4A5A6A"), Color("6B4A3A")][randi() % 4]
	return Figure.build(color, hair, kind, trousers)


func _act(node: Node3D, action: String, seconds: float) -> void:
	# A short pose on top of the walk or the idle: wave, sip, nod, shrug, point.
	if node == null or not is_instance_valid(node):
		return
	node.set_meta("action", action)
	node.set_meta("action_until", Time.get_ticks_msec() / 1000.0 + seconds)


func _animate_person(node: Node3D, t: float, walking: bool, delta: float) -> void:
	# Walking: a bob and a swing of the arms. Standing: a slow sway and a glance around.
	var figure := node.get_node_or_null("Figure") as Node3D
	if figure == null:
		return
	var action := str(node.get_meta("action", ""))
	if action != "" and Time.get_ticks_msec() / 1000.0 < float(node.get_meta("action_until", 0.0)):
		var arm_r := figure.get_node_or_null("ArmR") as Node3D
		var arm_l := figure.get_node_or_null("ArmL") as Node3D
		var head := figure.get_node_or_null("Head") as Node3D
		figure.position.y = 0.0
		figure.rotation.z = 0.0
		match action:
			"wave":
				if arm_r:
					arm_r.rotation.x = -2.7
					arm_r.rotation.z = sin(t * 14.0) * 0.35
			"sip":
				if arm_r:
					arm_r.rotation.x = -1.9
					arm_r.rotation.z = -0.5
				if head:
					head.rotation.x = -0.18 + sin(t * 3.0) * 0.03
			"nod":
				if head:
					head.position.y = 1.18 - absf(sin(t * 7.0)) * 0.05
			"shrug":
				if arm_r:
					arm_r.rotation.z = -0.9
				if arm_l:
					arm_l.rotation.z = 0.9
				if head:
					head.rotation.z = sin(t * 5.0) * 0.12
			"point":
				if arm_r:
					arm_r.rotation.x = -1.4
			"flinch":
				# Hands up, head down: that was not meant to happen.
				if arm_r and arm_l:
					arm_r.rotation.x = -2.8
					arm_l.rotation.x = -2.8
					arm_r.rotation.z = -0.3
					arm_l.rotation.z = 0.3
				if head:
					head.rotation.x = 0.35
			"shove":
				# Two arms straight out and a lean in: the owner has had enough.
				var push := 0.5 + 0.5 * sin(t * 9.0)
				if arm_r and arm_l:
					arm_r.rotation.x = -1.3 - push * 0.4
					arm_l.rotation.x = -1.3 - push * 0.4
				var body := figure.get_node_or_null("Torso") as Node3D
				if body:
					body.rotation.x = 0.1 + push * 0.2
			"reach":
				# Bending down to pick up or set down: both arms forward and low, a little stoop.
				if arm_r and arm_l:
					arm_r.rotation.x = -0.9
					arm_l.rotation.x = -0.9
				var torso := figure.get_node_or_null("Torso") as Node3D
				if torso:
					torso.rotation.x = 0.35 + sin(t * 6.0) * 0.05
			"clap":
				if arm_r and arm_l:
					var beat := absf(sin(t * 10.0))
					arm_r.rotation.x = -1.3
					arm_l.rotation.x = -1.3
					arm_r.rotation.z = -0.5 + beat * 0.45
					arm_l.rotation.z = 0.5 - beat * 0.45
		return
	elif action != "":
		node.set_meta("action", "")
		Figure.reset_pose(node)
	Figure.animate(node, t, walking, delta)


func _tick_customer(entry: Dictionary, delta: float) -> void:
	var node: Node3D = entry.get("node")
	if node == null or not is_instance_valid(node):
		return
	entry["hover"] = float(entry.get("hover", 0.0)) + delta
	var t := float(entry["hover"])
	var bubble := node.get_node_or_null("Order") as Node3D
	if bubble:
		bubble.position.y = 1.55 + sin(t * 3.0) * 0.04
		bubble.rotation.y += delta * 0.8
	_animate_person(node, t, str(entry.get("stage", "")) != "waiting", delta)
	if str(entry.get("stage", "")) == "waiting" and not bool(entry.get("making", false)):
		# They never leave unserved; after the wait the till just rings them up without the big tip.
		entry["wait"] = float(entry["wait"]) - delta
		if float(entry["wait"]) <= 0.0:
			_serve_customer(str(entry["uid"]), false)


func _open_ask(uid: String) -> bool:
	# A customer with a small ask: two replies, and the tip follows the answer.
	for entry in customers:
		if str(entry.get("uid", "")) != uid or str(entry.get("stage", "")) != "waiting":
			continue
		var ask: Dictionary = entry.get("ask", {})
		if ask.is_empty() or bool(entry.get("asked", false)):
			return false
		entry["asked"] = true
		var layer := _hud_layer()
		var old := layer.get_node_or_null("AskCard")
		if old != null:
			layer.remove_child(old)
			old.queue_free()
		var card := PanelContainer.new()
		card.name = "AskCard"
		card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16, 3, UIKit.TERRA))
		layer.add_child(card)
		card.layout_mode = 1
		card.set_anchors_preset(Control.PRESET_CENTER)
		card.grow_horizontal = Control.GROW_DIRECTION_BOTH
		card.grow_vertical = Control.GROW_DIRECTION_BOTH
		card.offset_left = -360
		card.offset_right = 360
		card.offset_top = -80
		card.offset_bottom = 80
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 18)
		card.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		margin.add_child(column)
		var who: Dictionary = (entry.get("order", {}) as Dictionary).get("who", {})
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		column.add_child(head)
		head.add_child(UIKit.avatar(str(who.get("name", "?")).left(1), UIKit.BLUE, 40))
		var text := UIKit.label("%s: \"%s\"" % [who.get("name", "A customer"), ask.get("text", "")], 28, UIKit.DARK, "title", false)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.custom_minimum_size = Vector2(620, 40)
		text.clip_text = true
		head.add_child(text)
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 12)
		column.add_child(buttons)
		var yes := UIKit.button(str(ask.get("yes", "Sure")), UIKit.SAGE)
		yes.name = "AskYes"
		yes.custom_minimum_size = Vector2(260, 56)
		yes.pressed.connect(func(): _answer_ask(uid, true, card))
		buttons.add_child(yes)
		var no := UIKit.button(str(ask.get("no", "Sorry")), UIKit.WOOD)
		no.name = "AskNo"
		no.custom_minimum_size = Vector2(260, 56)
		no.pressed.connect(func(): _answer_ask(uid, false, card))
		buttons.add_child(no)
		UIKit.link_focus([yes, no])
		AudioDirector.play_sfx("sfx_notification_soft")
		return true
	return false


func _answer_ask(uid: String, said_yes: bool, card: Node) -> void:
	if card != null and is_instance_valid(card):
		card.queue_free()
	for entry in customers:
		if str(entry.get("uid", "")) != uid:
			continue
		var ask: Dictionary = entry.get("ask", {})
		var order: Dictionary = entry.get("order", {})
		order["tip_mult"] = 1.35 if said_yes else 0.9
		entry["order"] = order
		var node: Node3D = entry.get("node")
		if node and is_instance_valid(node):
			_bubble(node, str(ask.get("yes_line" if said_yes else "no_line", "")), 5.0)
			_act(node, "nod" if said_yes else "shrug", 1.4)
		AudioDirector.play_sfx("sfx_customer_happy_chirp" if said_yes else "sfx_customer_unhappy_chirp", true)
		if said_yes:
			GameState.bump_stat("asks_granted")
		_open_make(uid)
		return


func _open_haggle(offer: Dictionary) -> void:
	# Sal names a price. Take it, or push your luck.
	var layer := _hud_layer()
	var old := layer.get_node_or_null("HaggleCard")
	if old != null:
		layer.remove_child(old)
		old.free()
	var card := PanelContainer.new()
	card.name = "HaggleCard"
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16, 4, UIKit.NIGHT))
	layer.add_child(card)
	card.layout_mode = 1
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_left = -380
	card.offset_right = 380
	card.offset_top = -120
	card.offset_bottom = 120
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	column.add_child(head)
	head.add_child(UIKit.avatar("S", UIKit.NIGHT, 40))
	var title := UIKit.label("Sal: \"$%d for %d x %s.\"" % [int(offer.get("offer", 0)), int(offer.get("count", 1)), ItemDB.display_name(str(offer.get("item", "")))], 28, UIKit.DARK, "title", false)
	title.name = "HaggleTitle"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(640, 40)
	head.add_child(title)
	var line := UIKit.label(str(offer.get("line", "")), 26, UIKit.BLUE, "small")
	line.name = "HaggleLine"
	line.custom_minimum_size = Vector2(700, 0)
	column.add_child(line)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	var take := UIKit.button("Take it", UIKit.SAGE)
	take.name = "HaggleTake"
	take.custom_minimum_size = Vector2(220, 56)
	take.pressed.connect(func():
		var result: Dictionary = Crime.fence_accept(offer)
		card.queue_free()
		if result.has("error"):
			_toast(str(result["error"]), "Sal")
			return
		AudioDirector.play_sfx("sfx_cash_gain")
		SaveManager.save_game()
		_open_jobs("backroom")
		_toast("$%d, cash. Heat %d." % [int(result.get("pay", 0)), Crime.heat()], "Sal")
	)
	buttons.add_child(take)
	var push := UIKit.button("Push for more", UIKit.TERRA)
	push.name = "HagglePush"
	push.custom_minimum_size = Vector2(260, 56)
	push.pressed.connect(func():
		Crime.haggle_push(offer)
		if bool(offer.get("walked", false)):
			card.queue_free()
			SaveManager.save_game()
			_open_jobs("backroom")
			_toast(str(offer.get("line", "No deal.")), "Sal")
			return
		title.text = "Sal: \"$%d for %d x %s.\"" % [int(offer.get("offer", 0)), int(offer.get("count", 1)), ItemDB.display_name(str(offer.get("item", "")))]
		line.text = str(offer.get("line", ""))
		AudioDirector.play_sfx("sfx_ui_click")
	)
	buttons.add_child(push)
	var leave := UIKit.button("Walk away", UIKit.WOOD)
	leave.name = "HaggleLeave"
	leave.custom_minimum_size = Vector2(200, 56)
	leave.pressed.connect(func(): card.queue_free())
	buttons.add_child(leave)
	UIKit.link_focus([take, push, leave])


func _open_make(uid: String) -> void:
	# Serving by hand means making the thing: a card with the cup or plate,
	# the recipe, and a tray of ingredients. The till can always take over.
	for entry in customers:
		if str(entry.get("uid", "")) != uid or str(entry.get("stage", "")) != "waiting":
			continue
		var order: Dictionary = entry.get("order", {})
		var dish := Catalog.menu_item(str(order.get("dish", "")))
		if (dish.get("recipe", []) as Array).is_empty():
			_serve_customer(uid, true)
			return
		var layer := _hud_layer()
		var old := layer.get_node_or_null("MakeCard")
		if old != null:
			layer.remove_child(old)
			old.free()
		entry["making"] = true
		var card := MakeCard.new()
		layer.add_child(card)
		var who: Dictionary = order.get("who", {})
		card.setup(dish, str(who.get("name", "a neighbour")), hash(uid) + GameState.day * 7)
		card.finished.connect(func(result: Dictionary):
			entry["making"] = false
			var o: Dictionary = entry.get("order", {})
			o["tip_mult"] = float(o.get("tip_mult", 1.0)) * float(result.get("tip_mult", 1.0))
			entry["order"] = o
			if bool(result.get("perfect", false)):
				GameState.bump_stat("perfect_makes")
				_toast("Perfect %s. Tip's up." % dish.get("name", "make"), "Till")
			elif bool(result.get("by_hand", false)) and int(result.get("slips", 0)) > 0:
				_toast("Served, with a wobble. Tip's a little lighter.", "Till")
			_serve_customer(uid, bool(result.get("by_hand", false)))
		)
		AudioDirector.play_sfx("sfx_drawer_open")
		return


func _serve_customer(uid: String, by_hand: bool) -> void:
	for entry in customers:
		if str(entry.get("uid", "")) != uid or str(entry.get("stage", "")) != "waiting":
			continue
		var node: Node3D = entry.get("node")
		var sale: Dictionary = GameState.serve_visitor(by_hand, entry.get("order", {}))
		if sale.is_empty():
			return
		entry["stage"] = "leaving"
		var dish_id := str(sale.get("dish_id", ""))
		if dish_id in ["lemonade", "iced_tea"]:
			AudioDirector.play_sfx("sfx_l01_refill_pour")
		elif dish_id == "bun":
			AudioDirector.play_sfx("sfx_paper_rustle")
		else:
			AudioDirector.play_sfx("sfx_l02_espresso_hiss")
			AudioDirector.play_sfx("sfx_l02_cup_clink")
		AudioDirector.play_sfx("sfx_cash_gain")
		if by_hand:
			_toast("%s: %s, served by you. +$%d (tip $%d)" % [sale.get("name", "Someone"), sale.get("dish", ""), int(sale.get("pay", 0)), int(sale.get("tip", 0))], "Till")
			_dust(node.global_position + Vector3(0, 0.6, 0))
		else:
			_toast("%s rang up their own %s. +$%d" % [sale.get("name", "Someone"), sale.get("dish", ""), int(sale.get("pay", 0))], "Till")
		# The order drops from the bubble into their hand, then they stroll out.
		var bubble := node.get_node_or_null("Order") as Node3D
		var tw := create_tween()
		if bubble:
			tw.tween_property(bubble, "position", Vector3(0.28, 0.75, 0.1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(bubble, "scale", Vector3(0.7, 0.7, 0.7), 0.35)
		tw.tween_interval(0.4)
		tw.tween_callback(func():
			if is_instance_valid(node):
				_act(node, "sip", 1.3)
		)
		tw.tween_interval(1.3)
		_bubble(node, _chat("served"))
		var car: Node3D = entry.get("car")
		tw.tween_property(node, "position", _door_world() + Vector3(0, 0, 0.3), 1.1)
		tw.tween_callback(func():
			if is_instance_valid(node):
				_act(node, "wave", 0.9)
		)
		tw.tween_interval(0.9)
		if car != null and is_instance_valid(car):
			tw.tween_property(node, "position", car.position + Vector3(1.1, 0.0, 0.2), 1.4)
		else:
			tw.tween_property(node, "position", _door_world() + Vector3(0, 0, -4.0), 1.3)
		tw.tween_callback(func():
			customers.erase(entry)
			if is_instance_valid(node):
				node.queue_free()
			if car != null and is_instance_valid(car):
				_depart_car(car)
			_reflow_queue()
		)
		_refresh_hud_buttons()
		return


func _reflow_queue() -> void:
	var index := 0
	for entry in customers:
		if str(entry.get("stage", "")) == "leaving":
			continue
		entry["index"] = index
		var node: Node3D = entry.get("node")
		if node and is_instance_valid(node) and str(entry.get("stage", "")) == "waiting":
			var tw := create_tween()
			tw.tween_property(node, "position", _queue_spot(index), 0.6)
		index += 1


func _sync_yard_shop() -> void:
	# The stand in the yard follows the shop's rung on the ladder.
	if backdrop or venue.is_empty() or GameState.mode != "office" or str(venue.get("id", "")) != GameState.office_id:
		return
	var tier := GameState.shop_tier
	if yard_shop != null and is_instance_valid(yard_shop):
		if str(yard_shop.get_meta("tier", "")) == tier:
			return
		yard_shop.queue_free()
		yard_shop = null
	yard_shop = YardShop.build(self, venue, tier)


func _yard_counter() -> Node3D:
	if yard_shop == null or not is_instance_valid(yard_shop):
		return null
	return yard_shop.get_node_or_null("YardCounter") as Node3D


func _sync_shop_sign() -> void:
	# An A-board by the door while the shop takes customers.
	if backdrop or venue.is_empty() or GameState.mode != "office":
		return
	_sync_yard_shop()
	var want := GameState.office_phase == "live" and GameState.shop_accepting()
	if want and (shop_sign == null or not is_instance_valid(shop_sign)):
		shop_sign = Props.make("proc:aframe")
		var collision := shop_sign.get_node_or_null("PropCollision")
		if collision:
			collision.free()
		shop_sign.name = "ShopSign"
		shop_sign.position = _door_world() + Vector3(2.0, 0.0, -2.8)
		if _yard_counter() != null:
			shop_sign.position = _yard_counter().global_position + Vector3(-1.6, 0.0, 1.6)
		add_child(shop_sign)
	elif not want and shop_sign != null and is_instance_valid(shop_sign):
		shop_sign.queue_free()
		shop_sign = null


func _pastry() -> void:
	if GameState.pastry_day == GameState.day:
		_toast("The plate's already empty. Tomorrow, maybe.")
		return
	GameState.pastry_day = GameState.day
	AudioDirector.play_sfx("sfx_l06_oven_beep_muffled")
	AudioDirector.play_sfx("sfx_success_chime")
	_toast("Still warm. A bakery morning, on the house.")


func _confetti() -> void:
	var bits := CPUParticles3D.new()
	bits.position = Vector3(2.5, 1.2, 2.0)
	bits.one_shot = true
	bits.explosiveness = 0.9
	bits.amount = 32
	bits.lifetime = 1.2
	bits.initial_velocity_min = 1.5
	bits.initial_velocity_max = 3.0
	bits.gravity = Vector3(0, -4, 0)
	bits.color = UIKit.MUSTARD
	add_child(bits)
	bits.emitting = true


func _shake(node: Node3D) -> void:
	if node == null or not SaveManager.shake:
		return
	var origin := node.position
	var tw := create_tween()
	tw.tween_property(node, "position", origin + Vector3(0.05, 0, 0), 0.04)
	tw.tween_property(node, "position", origin + Vector3(-0.05, 0, 0), 0.06)
	tw.tween_property(node, "position", origin, 0.05)


func _squash_uid(uid: String) -> void:
	var node: Node3D = nodes_by_uid.get(uid)
	_squash(node)
	if node != null and is_instance_valid(node):
		_dust(node.global_position)


func _dust(at: Vector3) -> void:
	var puff := CPUParticles3D.new()
	puff.position = at + Vector3(0, 0.03, 0)
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.amount = 14
	puff.lifetime = 0.55
	puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 0.18
	puff.direction = Vector3(0, 1, 0)
	puff.spread = 70.0
	puff.initial_velocity_min = 0.4
	puff.initial_velocity_max = 0.9
	puff.gravity = Vector3(0, -1.5, 0)
	puff.scale_amount_min = 0.05
	puff.scale_amount_max = 0.1
	puff.mesh = SphereMesh.new()
	(puff.mesh as SphereMesh).radius = 0.5
	(puff.mesh as SphereMesh).height = 1.0
	puff.material_override = Props.mat(Color("E7DCC6"))
	add_child(puff)
	puff.emitting = true
	get_tree().create_timer(1.2).timeout.connect(puff.queue_free)


func _squash_last() -> void:
	if GameState.office_items.is_empty():
		return
	_squash_uid(str(GameState.office_items.back().get("uid", "")))


const SQUASH_KEYS: Array = [
	{"scale": Vector3(1.15, 0.85, 1.15), "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT, "time": 0.08},
	{"scale": Vector3(0.95, 1.06, 0.95), "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT, "time": 0.09},
	{"scale": Vector3.ONE, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "time": 0.12},
]


static func mend_caption(item_name: String, taps: int) -> String:
	if taps <= 1:
		return "Mend %s" % item_name
	return "Mend %s ×%d" % [item_name, taps]


static func ghost_color(albedo: Color, valid: bool) -> Color:
	var color := albedo
	if not valid:
		color = albedo.lerp(UIKit.SOFT_RED, 0.65)
	color.a = 0.5
	return color


static func ghost_material(base: Material, valid: bool) -> StandardMaterial3D:
	var dup := StandardMaterial3D.new()
	if base is StandardMaterial3D:
		dup = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
	dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dup.albedo_color = ghost_color(dup.albedo_color, valid)
	return dup


static func _squash_target(node: Node3D) -> Node3D:
	if node == null:
		return null
	var visual := node.get_node_or_null("Visual")
	if visual is Node3D:
		return visual
	return node


func _squash(node: Node3D) -> void:
	var target := _squash_target(node)
	if target == null:
		return
	if node.has_meta("squash_tween"):
		var old: Tween = node.get_meta("squash_tween")
		if old != null and old.is_valid():
			old.kill()
	if target != node:
		node.scale = Vector3.ONE
	target.scale = Vector3.ONE
	var tw := create_tween()
	node.set_meta("squash_tween", tw)
	for key in SQUASH_KEYS:
		tw.tween_property(target, "scale", key["scale"], float(key["time"])).set_trans(int(key["trans"])).set_ease(int(key["ease"]))


func _wiggle_toast() -> void:
	if toast:
		var tw := create_tween()
		tw.tween_property(toast, "position:x", toast.position.x + 8, 0.05)
		tw.tween_property(toast, "position:x", toast.position.x - 8, 0.08)
		tw.tween_property(toast, "position:x", toast.position.x, 0.05)
