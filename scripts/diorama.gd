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
var stretch_in := 4.0
var toast: Label
var toast_time := 0.0
var floor_slots := 4
var slot_count := 8
var carried: Dictionary = {}
var delivery_root: Node3D
var visitor_wait := 5.0
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
	var world := Graphics.load_environment(SaveManager.graphics_quality)
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


func _build_venue() -> void:
	var id := _venue_id()
	venue = ItemDB.venues().get(id, ItemDB.venues().get("garage", {})).duplicate(true)
	venue["id"] = id
	if GameState.mode == "truck":
		_build_truck_stage()
		return
	_build_shell()
	_ensure_stack_room()
	_frame_camera()
	_dress()
	Outdoors.build(self, venue)


func _frame_camera() -> void:
	if backdrop:
		_frame_menu_camera()
		return
	if cam == null or venue.is_empty() or GameState.mode == "truck":
		return
	var origin := Vector3(float(venue.get("x", 0.0)), 0.0, float(venue.get("z", 0.0)))
	var width := float(venue.get("w", 6.0))
	var depth := float(venue.get("d", 8.0))
	var center := origin + Vector3(width * 0.5, 0.9, depth * 0.5)
	cam.attributes = null
	cam.size = maxf(width, depth) * 1.3 * view_zoom
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
	var center := origin + Vector3(w * 0.5, 0.9, d * 0.5)
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
				Props.restyle_architecture(tile)
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
						Props.restyle_architecture(small)
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
	Props.restyle_architecture(node)
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
			Props.restyle_architecture(node)
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
		Props.restyle_architecture(garage)
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
		Props.restyle_architecture(door)
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
		_place_model("pegboard", Vector3(0.12, 1.15, 7.0), 90)
		_place_model("bike_hooks", Vector3(0.12, 1.55, 1.5), 90)
		_place_model("job_clipboard", Vector3(5.15, 0.85, 6.35))
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
	if id == "train" or bool(venue.get("train", false)):
		var board := _place_model("train_layout_board", Vector3(5.6, 0, 2.4))
		if board:
			Props.play_clip(board, "loop", true)
		_place_model("display_case", Vector3(1.6, 0, 5.15))
		_place_model("parts_drawer_unit", Vector3(3.3, 0, 5.15))
		_place_model("cuckoo_clock", Vector3(0.12, 1.55, 2.2), 90)
	if id == "bakery":
		_tag_beam(_place_model("ceiling_beam", Vector3(2.0, 2.7, 3.2)))
		_tag_beam(_place_model("ceiling_beam", Vector3(5.2, 2.7, 3.2)))
		_tag_beam(_place_model("ceiling_beam", Vector3(2.0, 2.7, 7.2)))
		_tag_beam(_place_model("ceiling_beam", Vector3(5.2, 2.7, 7.2)))
		var frame := _place_model("skylight_frame", Vector3(4.0, 2.88, 5.0))
		if frame:
			frame.name = "SkylightFrame"
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
	AudioDirector.play_sfx("sfx_truck_door")
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
			if toast.get_parent() is CanvasItem:
				(toast.get_parent() as CanvasItem).visible = toast.visible
	if cat_player and is_instance_valid(cat_player):
		stretch_in -= delta
		if stretch_in <= 0.0 and cat_player.current_animation != "stretch":
			Props.play_clip(cat_rig, "stretch", false)
			stretch_in = randf_range(6.0, 11.0)
			if not cat_player.animation_finished.is_connected(_on_cat_clip):
				cat_player.animation_finished.connect(_on_cat_clip)
	_update_ghost(delta)
	_update_hover()
	_sync_deliveries()
	_tick_visitors(delta)
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
	var lines: Array = []
	for goal in StackGoals.all_goals():
		if str(goal.get("venue", "")) != str(venue.get("id", "")):
			continue
		var met := bool(StackGoals.evaluate(goal, items, GameState.latched_goals).get("met", false))
		lines.append("%s  %s" % ["✓" if met else "○", goal.get("hint", "")])
	var setup: float = stack_room.score() if stack_room else -1.0
	var key := "%s|%d" % ["\n".join(PackedStringArray(lines)), int(setup)]
	if key == _goals_key:
		return
	_goals_key = key
	for child in goals_column.get_children():
		child.queue_free()
	var head := UIKit.label("Room setup  %d/100" % int(round(setup)) if setup >= 0.0 else "Room setup", 24, UIKit.TERRA, "title", false)
	goals_column.add_child(head)
	for line in lines:
		var row := UIKit.label(str(line), 17, UIKit.DARK)
		row.custom_minimum_size = Vector2(520, 0)
		goals_column.add_child(row)
	if lines.is_empty():
		var row := UIKit.label("Stacks that stand, things that touch, and a tidy floor all count.", 17, UIKit.DARK)
		row.custom_minimum_size = Vector2(520, 0)
		goals_column.add_child(row)
	goals_panel.visible = true


func _on_cat_clip(anim_name: StringName) -> void:
	if str(anim_name) == "stretch" and cat_rig:
		Props.play_clip(cat_rig, "idle", true)


func _build_shell() -> void:
	_build_rect(float(venue.get("x", 0)), float(venue.get("z", 0)), float(venue.get("w", 6)), float(venue.get("d", 8)), true)
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		_fill_floor(float(nook["x"]), float(nook["z"]), float(nook["w"]), float(nook["d"]))
		_build_nook_walls(nook)
		var beam := Props.mesh_box(Vector3(float(nook["w"]) * 0.55, 0.1, 0.14), UIKit.WOOD)
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
		return
	var item_uid := _pick_uid()
	if item_uid.begins_with("delivery:") and GameState.mode == "office" and GameState.office_phase == "live":
		_delivery_click(item_uid.trim_prefix("delivery:"))
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
	if source == "office":
		GameState.note_first_place()
	AudioDirector.play_sfx("sfx_item_snap", true)
	AudioDirector.play_sfx("sfx_box_set_down", true)
	held_uid = ""
	held_source = ""
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
	_toast("That's the corner. Trade, decorate, or borrow the truck.")
	_refresh_hud_buttons()
	SaveManager.save_game()


func _pack_click(uid: String) -> void:
	if uid == "":
		return
	var item := GameState.job_item(uid)
	if item.is_empty() or str(item.get("state", "")) != "loose":
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
	AudioDirector.play_sfx("sfx_box_set_down", true)
	selected_box = -1
	_refresh_items()
	_sync_cargo()
	_refresh_hud_buttons()


func _unpack_click(uid: String) -> void:
	if uid.begins_with("boxcarry:"):
		var box_id := int(uid.trim_prefix("boxcarry:"))
		carried[box_id] = true
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
		_open_carried_box(int(uid.trim_prefix("boxopen:")))
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
	# Tip the box out: its items turn loose on the floor around where it sat.
	var spot := _open_box_spot(box_id)
	var n := 0
	for item in GameState.job.get("items", []):
		if int(item.get("box", -1)) != box_id or str(item.get("state", "")) != "boxed":
			continue
		item["state"] = "loose"
		item["x"] = spot.x + 0.55 + float(n % 3) * 0.6
		item["z"] = spot.z - 0.3 + float(int(n / 3)) * 0.6
		item["y"] = 0.0
		n += 1
	AudioDirector.play_sfx("sfx_box_open")
	AudioDirector.play_sfx("sfx_paper_rustle")
	var box := GameState.job_box(box_id)
	if not box.is_empty() and bool(box.get("has_cat", false)) and not bool(GameState.job.get("cat_opened", false)):
		_open_cat(box_id)
	_refresh_items()
	_refresh_hud_buttons()


func _open_box_spot(box_id: int) -> Vector3:
	var index := 0
	for box in GameState.job.get("boxes", []):
		if int(box.get("id", -1)) == box_id:
			break
		index += 1
	return Vector3(float(venue.get("x", 0)) + 0.6, 0.0, float(venue.get("z", 0)) + 0.9 + float(index) * 0.7)


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
	_toast("Biscuit! There's a photo for the museum shelf, and a little tip.")
	if cat_rig:
		cat_rig.visible = true
		Props.play_clip(cat_rig, "stretch", false)


func _maybe_job_done() -> void:
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "placed":
			return
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
	var spot := PlaceLib.resolve(hit.x, hit.z, hit.y, rot, def, others, room, SaveManager.snap_to_grid, extra)
	var placed: Vector3 = spot["pos"]
	spot["valid"] = bool(spot["valid"]) and _in_room_world(placed.x, placed.z) and not _too_tall(placed, def)
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
	elif GameState.mode == "truck":
		_spawn_truck_slots()
	elif GameState.mode == "job_unpack":
		for item in GameState.job.get("items", []):
			var job_state := str(item.get("state", ""))
			if job_state == "loose" or job_state == "placed" or job_state == "settling":
				_spawn_record(item, str(item.get("item_id", "")), int(item.get("damage", 0)) > 0)
		_spawn_carry_boxes()
	if stack_room:
		stack_room.evaluate_frozen()
		stack_room.flush_drops()


func _layout_loose() -> void:
	var i := 0
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "loose":
			continue
		item["x"] = float(venue.get("x", 0)) + 1.1 + float(i % 5) * 0.85
		item["z"] = float(venue.get("z", 0)) + 1.5 + float(int(i / 5)) * 0.85
		item["y"] = 0.0
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
				var visual_name := "box_closed_damaged" if int(GameState.job.get("condition", 100)) < int(Tuning.get_value("damage.mesh_swap_below", 70)) else "box_closed"
				var box_node := Props.make(visual_name)
				box_node.position = Vector3(0, 0.2, 0)
				pad.add_child(box_node)


func _spawn_carry_boxes() -> void:
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
	add_child(layer)
	var top := Panel.new()
	top.name = "StatusCard"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	layer.add_child(top)
	UIKit.pin_top_left(top, 16, 12, 760, 112)
	status = UIKit.label("", 36, UIKit.DARK)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(status)
	UIKit.fill(status, 16, 12, 16, 12)
	var hint_bar := Panel.new()
	hint_bar.name = "HintBar"
	hint_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	layer.add_child(hint_bar)
	UIKit.pin_bottom(hint_bar, 16, -168, -16, -12)
	hint = UIKit.label("", 36, UIKit.DARK)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.max_lines_visible = 3
	hint_bar.add_child(hint)
	UIKit.fill(hint, 16, 12, 16, 12)
	status.max_lines_visible = 2
	# The checklist grows with its text, so nothing spills out of the card.
	var goals_box := PanelContainer.new()
	goals_box.name = "GoalsCard"
	goals_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goals_box.add_theme_stylebox_override("panel", UIKit.style(Color(UIKit.CREAM_CARD, 0.94), 14))
	layer.add_child(goals_box)
	goals_box.layout_mode = 1
	goals_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	goals_box.position = Vector2(16, 168)
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
	var toast_bar := Panel.new()
	toast_bar.name = "ToastBar"
	toast_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_bar.visible = false
	toast_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.NIGHT, 14))
	layer.add_child(toast_bar)
	UIKit.pin_center_top(toast_bar, -560, 124, 560, 216)
	toast = UIKit.label("", 32, UIKit.CREAM_CARD)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.max_lines_visible = 2
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_bar.add_child(toast)
	UIKit.fill(toast, 16, 8, 16, 8)
	_refresh_hud_buttons()
	GameState.toast_requested.connect(_toast)


func _refresh_hud_buttons() -> void:
	var layer := _hud_layer()
	if layer == null:
		return
	for child in layer.get_children():
		if str(child.name).begins_with("Act"):
			child.queue_free()
	var y := 100.0
	if GameState.mode == "office" or GameState.mode == "job_unpack":
		var snap_label := "Grid snap on" if SaveManager.snap_to_grid else "Free place"
		_act_button(layer, snap_label, Vector2(16, y), _toggle_snap)
		_act_button(layer, "Rotate view", Vector2(1100, 870), func(): rotate_view(1))
	if GameState.mode == "office" and GameState.office_phase == "live":
		_act_button(layer, "Jobs", Vector2(1100, y), func(): _open_jobs())
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
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) != "placed":
			ready = false
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
		if bool(box.get("sealed", false)):
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
		if int(box.get("slot", -1)) >= 0:
			text += " loaded"
		var capture := id
		_act_button(layer, text, Vector2(16, y), func():
			selected_box = capture
			_toast("Now tap a colored pad in the truck. Mustard pads are the floor.")
		)
		y += 52


func _open_jobs() -> void:
	var layer := _hud_layer()
	var panel := Panel.new()
	panel.name = "ActJobs"
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 18))
	layer.add_child(panel)
	UIKit.pin_center(panel, Vector2(960, 640))
	var title := UIKit.label("Clipboard", 40, UIKit.DARK, "title", false)
	title.position = Vector2(24, 16)
	panel.add_child(title)
	var close := UIKit.button("Close", UIKit.DARK)
	close.position = Vector2(760, 16)
	close.size = Vector2(160, 56)
	close.custom_minimum_size = Vector2(160, 56)
	close.pressed.connect(panel.queue_free)
	panel.add_child(close)
	var y := 70.0
	var any := false
	for job in JobDB.all_jobs():
		var decorated := JobDB.get_job(str(job.get("id", "")))
		if not GameState.job_available(decorated):
			continue
		any = true
		var pay := JobDB.base_pay(decorated)
		var card := UIKit.label("%s  ·  %s\nBase $%d. %s\nMarge: %s" % [
			decorated.get("title", ""),
			decorated.get("client", ""),
			pay,
			decorated.get("brief", ""),
			decorated.get("mentor_note", ""),
		], 18, UIKit.DARK)
		card.position = Vector2(20, y)
		card.size = Vector2(520, 110)
		panel.add_child(card)
		var id := str(decorated.get("id", ""))
		var go := UIKit.button("Take job", UIKit.TERRA)
		go.position = Vector2(720, y + 16)
		go.size = Vector2(200, 56)
		go.custom_minimum_size = Vector2(200, 56)
		go.pressed.connect(_start_listed_job.bind(id))
		panel.add_child(go)
		y += 140
		if y > 540:
			break
	if not any:
		var empty := UIKit.label("Marge hasn't pinned a job yet. Finish unpacking the garage first.", 36, UIKit.DARK)
		empty.position = Vector2(24, 96)
		empty.size = Vector2(880, 96)
		empty.custom_minimum_size = Vector2(700, 48)
		panel.add_child(empty)
	var focus_buttons: Array = []
	for child in panel.get_children():
		if child is Button:
			focus_buttons.append(child)
	UIKit.link_focus(focus_buttons)


func _act_button(layer: CanvasLayer, text: String, at: Vector2, callback: Callable) -> void:
	if layer == null:
		return
	var btn := UIKit.button(text, UIKit.TERRA if "Finish" in text or "Drive" in text else UIKit.SAGE)
	btn.name = "ActButton"
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
	if at.x < 400.0:
		UIKit.pin_top_left(btn, 16, top, 340, top + height)
	else:
		UIKit.pin_top_right(btn, -356, top, -16, top + height)
	_wire_hud_focus(layer)


func _wire_hud_focus(layer: CanvasLayer) -> void:
	var buttons: Array = []
	for child in layer.get_children():
		if child is Button:
			buttons.append(child)
	if not buttons.is_empty():
		UIKit.link_focus(buttons)


func _hud_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer:
			return child
	return null


func _hint_text() -> String:
	var line := _mode_hint()
	var goal := _goal_hint()
	if goal == "":
		return line
	return "%s\n%s" % [goal, line]


func _goal_hint() -> String:
	if backdrop or venue.is_empty():
		return ""
	var goal: Dictionary = StackGoals.active(str(venue.get("id", "")), GameState.character, _goal_items(), GameState.latched_goals)
	return str(goal.get("hint", ""))


func _mode_hint() -> String:
	var money := "$%d" % GameState.money
	var rep := "Rep %d" % GameState.rep_rank()
	var head := "%s   %s   %s" % [venue.get("name", "Office"), money, rep]
	if status:
		if GameState.mode == "office" and GameState.office_phase == "live":
			head += "   Vibe %d" % GameState.vibe_score()
		status.text = head
	match GameState.mode:
		"office":
			if GameState.office_phase == "pack":
				return "Pack the old office. Click each item. R is for later, when you place things. Shift+R turns 15°."
			if GameState.office_phase == "place":
				return "Click a box, then a floor, desk, or stack. R rotates 90°. Shift+R turns 15°. G toggles the grid. Wall pieces sit 0.12 m off the wall."
			var extra := ""
			if not GameState.door_orders().is_empty():
				extra = " A courier box is by the door."
			if GameState.shop_open():
				extra += " Vibe %d. Visitors wander in." % GameState.vibe_score()
			return "Pick something up and set it on the floor or another item. G toggles grid snap. Drawers click. The lamp keeps its glow." + extra
		"job_pack":
			return "Click an item to drop it in the open box. Fragile things like padding. Heavy things ride alone, on the bottom."
		"truck":
			return "Choose a box, then a pad in the bed. Mustard pads are the floor. The espresso machine stays down there."
		"job_unpack":
			return "Carry each box through the door, open it, and stack what's inside on a solid surface. Mend a scuff or keep it. Base pay still shows up."
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


func _toast(message: String) -> void:
	if toast == null:
		return
	toast.text = message
	toast.visible = true
	if toast.get_parent() is CanvasItem:
		(toast.get_parent() as CanvasItem).visible = true
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
	if GameState.mode != "office" or GameState.office_phase != "live" or not GameState.shop_open():
		return
	visitor_wait -= delta
	if visitor_wait > 0.0:
		return
	var vibe := GameState.vibe_score()
	var base := Catalog.shop_number("tick_seconds", 16)
	var haste := Catalog.shop_number("vibe_haste", 0.08)
	visitor_wait = maxf(6.0, base - float(vibe) * haste)
	_spawn_visitor()


func _spawn_visitor() -> void:
	var person := Node3D.new()
	var door := Vector3(float(venue.get("x", 0)) + float(venue.get("w", 6)) * 0.5, 0, float(venue.get("z", 0)) + 0.4)
	var counter := Vector3(float(venue.get("x", 0)) + float(venue.get("w", 6)) * 0.55, 0, float(venue.get("z", 0)) + float(venue.get("d", 8)) * 0.45)
	person.position = door
	var body := Props.mesh_cylinder(0.18, 0.85, UIKit.BLUE if randf() > 0.5 else UIKit.SAGE)
	person.add_child(body)
	var head := Props.mesh_box(Vector3(0.24, 0.24, 0.24), UIKit.CREAM)
	head.position = Vector3(0, 0.98, 0)
	person.add_child(head)
	add_child(person)
	var tw := create_tween()
	tw.tween_property(person, "position", counter, 1.3)
	tw.tween_callback(func():
		var visit := GameState.serve_visitor()
		if not visit.is_empty():
			_toast("%s bought a %s. +$%d" % [visit.get("name", "Someone"), visit.get("dish", "thing"), int(visit.get("pay", 0))])
			AudioDirector.play_sfx("sfx_cash_gain")
	)
	tw.tween_interval(0.4)
	tw.tween_property(person, "position", door + Vector3(0, 0, -1.5), 1.2)
	tw.tween_callback(person.queue_free)


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
	var word := "tap" if taps == 1 else "taps"
	return "Mend %s (%d %s)" % [item_name, taps, word]


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
