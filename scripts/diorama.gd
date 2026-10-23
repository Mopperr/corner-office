extends Node3D

const PlaceLib = preload("res://scripts/placement.gd")

signal open_computer
signal request_drive
signal request_results
signal request_rebuild

var cam: Camera3D
var items_root := Node3D.new()
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
var show_focus := Vector3.ZERO
var show_cam := Vector3.ZERO
var show_basis := Basis.IDENTITY
var show_ready := false
var drift_t := 0.0
var settling := false


func _ready() -> void:
	items_root.name = "Items"
	add_child(items_root)
	_world()
	if backdrop:
		_build_showroom()
		return
	_build_venue()
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
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("5C534A")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("C2B09A")
	world.ambient_light_energy = 0.18
	world.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.tonemap_exposure = 0.78
	world.tonemap_white = 6.0
	var renderer := RenderingServer.get_current_rendering_method()
	if renderer == "gl_compatibility" or renderer == "forward_plus":
		world.ssao_enabled = true
		world.ssao_radius = 1.15
		world.ssao_intensity = 1.8
		world.ssao_power = 1.45
		world.ssao_detail = 0.55
		world.ssao_horizon = 0.12
		world.ssao_sharpness = 0.45
		world.ssao_light_affect = 0.35
	env.environment = world
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 28, 0)
	sun.light_color = Color("FFE2C2")
	sun.light_energy = 0.42
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 48.0
	add_child(sun)
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
	_build_rect(float(venue.get("x", 0)), float(venue.get("z", 0)), float(venue.get("w", 6)), float(venue.get("d", 8)), true)
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		_fill_floor(float(nook["x"]), float(nook["z"]), float(nook["w"]), float(nook["d"]))
		_build_nook_walls(nook)
		var beam := Props.mesh_box(Vector3(float(nook["w"]), 0.08, 0.12), UIKit.WOOD)
		beam.position = Vector3(float(nook["x"]) + float(nook["w"]) * 0.5, 1.5, float(nook["z"]) + 0.2)
		add_child(beam)
	_frame_camera()
	_dress()


func _frame_camera() -> void:
	if cam == null or venue.is_empty() or GameState.mode == "truck":
		return
	var points := _room_points()
	if points.is_empty():
		return
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	var offset := Vector3(1.0, 1.08, 1.0).normalized() * 18.0
	cam.position = center + offset
	cam.look_at(center, Vector3.UP)
	var xf := cam.global_transform
	var min_x := 10000.0
	var max_x := -10000.0
	var min_y := 10000.0
	var max_y := -10000.0
	var inv := xf.affine_inverse()
	for point in points:
		var local: Vector3 = inv * point
		min_x = minf(min_x, local.x)
		max_x = maxf(max_x, local.x)
		min_y = minf(min_y, local.y)
		max_y = maxf(max_y, local.y)
	var shift := Vector3((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, 0.0)
	cam.global_position += xf.basis * shift
	var view := get_viewport().get_visible_rect().size
	var aspect := 16.0 / 9.0
	if view.y > 1.0:
		aspect = view.x / view.y
	var height := (max_y - min_y) * 1.16
	var width_need := (max_x - min_x) * 1.16 / aspect
	cam.size = maxf(height, width_need)
	if backdrop:
		cam.size *= 0.78
		var slide := cam.size * aspect * 0.2
		cam.global_position -= cam.global_transform.basis.x * slide
		show_focus = center + xf.basis * shift
		show_cam = cam.global_position
		show_basis = cam.global_transform.basis
		show_ready = true


func _room_points() -> Array:
	var points: Array = []
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	for px in [x, x + w]:
		for pz in [z, z + d]:
			points.append(Vector3(px, 0.0, pz))
	# Visible shell only: west wall and the opening wall. East and north stay cut away.
	for pz in [z, z + d]:
		points.append(Vector3(x, 2.7, pz))
	for px in [x, x + w]:
		points.append(Vector3(px, 2.4, z))
	if str(venue.get("opening", "")) == "garage":
		points.append(Vector3(x + 1.2, 0.0, z - 2.3))
		points.append(Vector3(x + w - 1.2, 0.0, z - 2.3))
		points.append(Vector3(x + w * 0.5, 2.3, z - 0.2))
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		var nx := float(nook["x"])
		var nz := float(nook["z"])
		var nw := float(nook["w"])
		var nd := float(nook["d"])
		points.append(Vector3(nx, 1.5, nz))
		points.append(Vector3(nx + nw, 0.0, nz + nd))
	return points


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
	# 1 m scraps when a side is odd
	if int(w) % 2 == 1 or int(d) % 2 == 1:
		var zz := z + 0.5
		while zz < z + d:
			var xx := x + 0.5
			while xx < x + w:
				var covered := fmod(xx - x, 2.0) < 1.5 and fmod(zz - z, 2.0) < 1.5 and xx + 0.5 <= x + w - 0.2 and zz + 0.5 <= z + d - 0.2 and int(w) % 2 == 0 and int(d) % 2 == 0
				if not covered:
					var small := Props.model(_piece("floor1"))
					if small and _needs_1m(x, z, w, d, xx, zz):
						small.position = Vector3(xx, 0, zz)
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
	glow.position = Vector3(opening_center, 1.6, z + 0.45)
	glow.light_color = Color("FFC98A")
	glow.light_energy = 0.32
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
	Props.prepare(node)
	add_child(node)
	return node


func _dress() -> void:
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
		_place_model("cafe_counter", Vector3(3.2, 0, 4.7))
		_place_model("mug_rack", Vector3(0.12, 1.35, 3.2), 90)
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
		_place_model("ceiling_beam", Vector3(2.0, 2.7, 3.2))
		_place_model("ceiling_beam", Vector3(5.2, 2.7, 3.2))
		_place_model("ceiling_beam", Vector3(2.0, 2.7, 7.2))
		_place_model("ceiling_beam", Vector3(5.2, 2.7, 7.2))
		_place_model("skylight_frame", Vector3(4.0, 2.88, 5.0))
		_place_model("radiator", Vector3(0.55, 0, 6.4), 90)
		_place_model("flour_sack_rug", Vector3(4.2, 0, 6.2))
		for step in 3:
			_place_model("stair_step", Vector3(-0.2 - float(step) * 0.3, float(step) * 0.22, 4.6), 90)
	if bool(venue.get("pastry", false)):
		var bun := _place_model("pastry_basket", Vector3(1.5, 0, 1.3))
		if bun:
			bun.name = "Pastry"
			Props.add_picker(bun, Vector3(0.44, 0.23, 0.44))
			bun.set_meta("pastry", true)


func _build_truck_stage() -> void:
	venue = {"name": "Corner Movers", "x": -2, "z": -2, "w": 8, "d": 6, "music": "music_office_build"}
	var ground := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(14, 0.1, 10)
	ground.mesh = plane
	ground.material_override = Props.mat(Color("7A5C40"))
	ground.position = Vector3(0, -0.05, 0)
	add_child(ground)
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
	cam.size = 7.5
	cam.position = Vector3(-6.2, 3.4, 4.4)
	cam.look_at(Vector3(-0.6, 1.1, 0), Vector3.UP)
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
	if backdrop:
		_drift_camera(delta)
		return
	if toast_time > 0.0:
		toast_time -= delta
		if toast:
			toast.visible = toast_time > 0.0
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
	if hint:
		hint.text = _hint_text()


func _on_cat_clip(anim_name: StringName) -> void:
	if str(anim_name) == "stretch" and cat_rig:
		Props.play_clip(cat_rig, "idle", true)


func _build_showroom() -> void:
	venue = ItemDB.venues().get("garage", {}).duplicate(true)
	venue["id"] = "garage"
	_build_rect(float(venue.get("x", 0)), float(venue.get("z", 0)), float(venue.get("w", 6)), float(venue.get("d", 8)), true)
	_dress()
	_set_garage_y(float(Tuning.get_value("garage_door_open_y", 2.1)))
	for rec in ItemDB.starter_layout():
		var copy: Dictionary = rec.duplicate(true)
		_spawn_record(copy, str(copy.get("item", "")), false)
	var tall := _place_model("plant_tall", Vector3(5.2, 0, 2.2))
	if tall:
		tall.rotation.y = 0.4
	_place_model("plant_small", Vector3(1.35, 0, 6.3))
	var box_a := Props.make("box_closed")
	box_a.position = Vector3(4.35, 0, 5.55)
	add_child(box_a)
	var box_b := Props.make("box_closed")
	box_b.position = Vector3(4.35, 0.36, 5.55)
	box_b.rotation.y = 0.18
	add_child(box_b)
	_frame_camera()


func _drift_camera(delta: float) -> void:
	if cam == null or not show_ready:
		return
	drift_t += delta
	var yaw := sin(drift_t * 0.18) * 0.07
	var spin := Basis(Vector3.UP, yaw)
	cam.global_position = show_focus + spin * (show_cam - show_focus)
	cam.global_transform.basis = spin * show_basis


func _update_ghost(delta: float) -> void:
	if held_uid == "":
		if ghost:
			ghost.visible = false
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
			var dup: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
			dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			if not valid:
				dup.albedo_color = dup.albedo_color.lerp(UIKit.LOSS, 0.65)
			dup.albedo_color.a = 0.5
			mesh_instance.set_surface_override_material(i, dup)


func _unhandled_input(event: InputEvent) -> void:
	if backdrop:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			_toggle_snap()
			return
		if event.keycode == KEY_R:
			if held_uid != "":
				var key := event as InputEventKey
				var fine := key.shift_pressed or Input.is_key_pressed(KEY_SHIFT)
				held_rot = fmod(held_rot + Tuning.rotate_step(fine) + 360.0, 360.0)
				AudioDirector.play_sfx("sfx_ui_click")
		elif event.keycode == KEY_ESCAPE and held_uid != "":
			_drop_hold()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click()


func _toggle_snap() -> void:
	SaveManager.snap_to_grid = not SaveManager.snap_to_grid
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
	query.exclude = _ghost_rids()
	query.exclude.append_array(_cutaway_rids())
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
		held_uid = uid
		held_source = "office"
		held_rot = float(rec2.get("rot", 0))
		rec2["state"] = "hand"
		AudioDirector.play_sfx("sfx_item_pick_up")
		_refresh_items()
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
	settling = true
	var source := held_source
	var uid := held_uid
	var on_wall := str(spot.get("wall", "")) != ""
	if source == "decor":
		GameState.place_decor_from_queue(spot, uid)
		AudioDirector.play_sfx("sfx_item_snap", true)
		held_uid = ""
		held_source = ""
		if on_wall:
			_refresh_items()
			_squash_last()
		else:
			await _settle_uid(uid)
			_squash_uid(uid)
		settling = false
		SaveManager.save_game()
		return
	var rec := GameState.find_office_item(uid) if source == "office" else GameState.job_item(uid)
	if rec.is_empty():
		held_uid = ""
		held_source = ""
		settling = false
		return
	rec["x"] = spot["pos"].x
	rec["y"] = spot["pos"].y
	rec["z"] = spot["pos"].z
	rec["rot"] = spot["rot"]
	rec["wall"] = spot.get("wall", "")
	rec["state"] = "placed"
	rec["settle"] = not on_wall
	if source == "office":
		GameState.note_first_place()
	AudioDirector.play_sfx("sfx_item_snap", true)
	AudioDirector.play_sfx("sfx_box_set_down", true)
	held_uid = ""
	held_source = ""
	if on_wall:
		_refresh_items()
		_squash_uid(uid)
	else:
		await _settle_uid(uid)
		_squash_uid(uid)
	if source == "office":
		_maybe_live()
	else:
		_maybe_job_done()
	settling = false
	SaveManager.save_game()


func _settle_uid(uid: String) -> void:
	_refresh_items()
	var body := nodes_by_uid.get(uid, null) as RigidBody3D
	if body == null:
		return
	var calm := 0
	for i in 90:
		if not is_inside_tree():
			return
		await get_tree().physics_frame
		if not is_instance_valid(body) or body.freeze:
			return
		var speed := body.linear_velocity.length()
		if (body.sleeping or speed < 0.05) and i > 5:
			calm += 1
			if calm >= 3:
				break
		else:
			calm = 0
	if not is_instance_valid(body):
		return
	PlaceLib.finish_settle(body)
	var rec := _record_for(uid)
	if not rec.is_empty():
		rec["x"] = body.position.x
		rec["y"] = body.position.y
		rec["z"] = body.position.z
		rec["settle"] = false


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
	var packed := str(item.get("item", ""))
	if packed == "cafe_mug":
		AudioDirector.play_sfx("sfx_l02_cup_clink")
	elif packed == "mystery_part":
		AudioDirector.play_sfx("sfx_l04_parts_rattle")
	_refresh_items()
	_refresh_hud_buttons()


func _truck_click(uid: String) -> void:
	if not uid.begins_with("slot:"):
		return
	if selected_box < 0:
		_toast("Pick a sealed box first.")
		return
	var slot := int(uid.trim_prefix("slot:"))
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
		AudioDirector.play_sfx("sfx_footstep_office")
		AudioDirector.play_sfx("sfx_box_set_down", true)
		_refresh_items()
		_refresh_hud_buttons()
		return
	if held_uid == "":
		var item := GameState.job_item(uid)
		if item.is_empty():
			return
		if not bool(carried.get(int(item.get("box", -1)), false)):
			_toast("Carry that box in from the truck first.")
			return
		if str(item.get("state", "")) == "placed":
			held_uid = uid
			held_source = "job"
			held_rot = float(item.get("rot", 0))
			item["state"] = "hand"
			AudioDirector.play_sfx("sfx_item_pick_up")
			_refresh_items()
			return
		if str(item.get("state", "")) == "boxed":
			item["state"] = "loose"
			AudioDirector.play_sfx("sfx_box_open")
			AudioDirector.play_sfx("sfx_paper_rustle")
			var box := GameState.job_box(int(item.get("box", -1)))
			if not box.is_empty() and bool(box.get("has_cat", false)) and not bool(GameState.job.get("cat_opened", false)):
				_open_cat(int(box.get("id", -1)))
			_refresh_items()
		return
	_try_place_held()


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
		var offset := float(def.get("back_offset", -1.0))
		if offset < 0.0:
			offset = float(Tuning.get_value("wall_mount_offset_m", 0.12))
		var normal: Vector3 = point["normal"]
		pos = Vector3(point["x"], point["y"], point["z"]) + normal * offset
		var valid := _inside(pos.x, pos.z, -0.02) and not _blocked(pos, rot, def) and not _too_tall(pos, def)
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
	spot["valid"] = bool(spot["valid"]) and _inside(placed.x, placed.z, 0.25) and not _too_tall(placed, def)
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


func _inside(px: float, pz: float, margin: float) -> bool:
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	if px >= x + margin and px <= x + w - margin and pz >= z + margin and pz <= z + d - margin:
		return true
	if venue.has("nook"):
		var nook: Dictionary = venue["nook"]
		if px >= float(nook["x"]) + margin and px <= float(nook["x"]) + float(nook["w"]) - margin and pz >= float(nook["z"]) + margin and pz <= float(nook["z"]) + float(nook["d"]) - margin:
			return true
	return false


func _too_tall(pos: Vector3, def: Dictionary) -> bool:
	if not venue.has("nook"):
		return false
	var nook: Dictionary = venue["nook"]
	var inside := pos.x >= float(nook["x"]) and pos.x <= float(nook["x"]) + float(nook["w"]) and pos.z >= float(nook["z"]) and pos.z <= float(nook["z"]) + float(nook["d"])
	return inside and float(def.get("h", 0)) > float(nook.get("max_h", 1.5))


func _blocked(pos: Vector3, rot: float, def: Dictionary) -> bool:
	var mine := _footprint(pos, rot, def)
	var records: Array = GameState.office_items if held_source != "job" else GameState.job.get("items", [])
	for rec in records:
		if str(rec.get("uid", "")) == held_uid:
			continue
		if str(rec.get("state", "")) != "placed":
			continue
		var other_def := ItemDB.get_item(str(rec.get("item", rec.get("item_id", ""))))
		var other := _footprint(Vector3(float(rec.get("x", 0)), 0, float(rec.get("z", 0))), float(rec.get("rot", 0)), other_def)
		if mine.intersects(other, true):
			return true
	return false


func _footprint(pos: Vector3, rot: float, def: Dictionary) -> Rect2:
	var w := float(def.get("w", 0.4))
	var d := float(def.get("d", 0.4))
	var rad := deg_to_rad(rot)
	var hw := w * 0.5
	var hd := d * 0.5
	var corners: Array[Vector2] = [
		Vector2(-hw, -hd), Vector2(hw, -hd), Vector2(hw, hd), Vector2(-hw, hd)
	]
	var min_v := Vector2(9999, 9999)
	var max_v := Vector2(-9999, -9999)
	for corner in corners:
		var turned := Vector2(corner.x * cos(rad) - corner.y * sin(rad), corner.x * sin(rad) + corner.y * cos(rad))
		var world := Vector2(pos.x, pos.z) + turned
		min_v.x = minf(min_v.x, world.x)
		min_v.y = minf(min_v.y, world.y)
		max_v.x = maxf(max_v.x, world.x)
		max_v.y = maxf(max_v.y, world.y)
	return Rect2(min_v, max_v - min_v)


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
	if held_source == "office":
		var rec := GameState.find_office_item(held_uid)
		if not rec.is_empty() and str(rec.get("state", "")) == "hand":
			rec["state"] = "boxed" if GameState.office_phase != "live" else "placed"
	elif held_source == "job":
		var item := GameState.job_item(held_uid)
		if not item.is_empty():
			item["state"] = "loose"
	held_uid = ""
	held_source = ""
	if ghost:
		ghost.visible = false
	_refresh_items()


func _refresh_items() -> void:
	for child in items_root.get_children():
		child.queue_free()
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
			if str(item.get("state", "")) == "loose" or str(item.get("state", "")) == "placed":
				_spawn_record(item, str(item.get("item_id", "")), int(item.get("damage", 0)) > 0)
		_spawn_carry_boxes()


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
		if str(rec.get("state", "")) == "placed":
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
	var mount := str(def.get("mount", "floor"))
	var wall := str(rec.get("wall", ""))
	var placed := str(rec.get("state", "")) == "placed"
	var physical := not backdrop and placed and wall == "" and mount != "hang" and mount != "wall_floor"
	var root: Node3D
	if physical:
		var size := Vector3(float(def.get("w", 0.4)), float(def.get("h", 0.3)), float(def.get("d", 0.4)))
		var at := Vector3(float(rec.get("x", 0)), float(rec.get("y", 0)), float(rec.get("z", 0)))
		root = PlaceLib.make_body(size, at, float(rec.get("rot", 0)), bool(rec.get("settle", false)))
	else:
		root = Node3D.new()
		root.position = Vector3(float(rec.get("x", 0)), float(rec.get("y", 0)), float(rec.get("z", 0)))
		root.rotation.y = deg_to_rad(float(rec.get("rot", 0)))
	root.set_meta("uid", rec.get("uid", ""))
	var visual := Props.make(str(def.get("model", "box_closed")))
	if physical:
		var collision := visual.get_node_or_null("PropCollision")
		if collision:
			collision.free()
	root.add_child(visual)
	if bool(def.get("light", false)):
		Props.attach_lamp_light(visual)
	if str(def.get("animate", "")) != "":
		Props.play_clip(visual, str(def.get("animate", "")), true)
	if str(item_id) == "train_reward" or str(def.get("model", "")) == "train_layout_board":
		Props.play_clip(visual, "loop", true)
	if not physical:
		Props.add_picker(root, Vector3(float(def.get("w", 0.4)), float(def.get("h", 0.3)), float(def.get("d", 0.4))))
	if cracked:
		var crack := Props.mesh_box(Vector3(0.08, 0.08, 0.08), UIKit.LOSS)
		crack.position = Vector3(0, float(def.get("h", 0.4)) + 0.08, 0)
		root.add_child(crack)
	items_root.add_child(root)
	nodes_by_uid[str(rec.get("uid", ""))] = root


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
		if bool(carried.get(int(box.get("id", -1)), false)):
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
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = 16
	top.offset_top = 12
	top.offset_right = 436
	top.offset_bottom = 86
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	layer.add_child(top)
	status = UIKit.label("", 16, UIKit.DARK)
	status.set_anchors_preset(Control.PRESET_FULL_RECT)
	status.offset_left = 12
	status.offset_top = 8
	status.offset_right = -12
	status.offset_bottom = -8
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(status)
	var hint_bar := Panel.new()
	hint_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_bar.offset_left = 16
	hint_bar.offset_top = -104
	hint_bar.offset_right = -16
	hint_bar.offset_bottom = -12
	hint_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	layer.add_child(hint_bar)
	hint = UIKit.label("", 16, UIKit.DARK)
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.offset_left = 14
	hint.offset_top = 8
	hint.offset_right = -14
	hint.offset_bottom = -8
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_bar.add_child(hint)
	toast = UIKit.label("", 20, UIKit.CREAM_CARD, "title")
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.offset_left = -430
	toast.offset_top = 96
	toast.offset_right = 430
	toast.offset_bottom = 166
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.visible = false
	layer.add_child(toast)
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
	if GameState.mode == "office" and GameState.office_phase == "live":
		_act_button(layer, "Jobs", Vector2(1100, y), func(): _open_jobs())
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
			_act_button(layer, "Mend %s (%d taps)" % [item.get("name", "item"), taps], Vector2(860, y), func():
				var done := GameState.tap_repair(uid)
				AudioDirector.play_sfx("sfx_repair")
				if done:
					AudioDirector.play_sfx("sfx_success_chime")
					_toast("Good as new!")
				_refresh_items()
				_refresh_hud_buttons()
			)
			y += 52
			_act_button(layer, "Keep %s (−$%d from tips)" % [item.get("name", "item"), cost], Vector2(860, y), func():
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
	var box := GameState.job_box(selected_box)
	if not box.is_empty() and bool(box.get("has_cat", false)):
		AudioDirector.play_sfx("sfx_cat_meow")
		_toast("That box just meowed. Open it?")
		_act_button(_hud_layer(), "Open the meowing box", Vector2(860, 520), func():
			_open_cat(selected_box)
			_refresh_hud_buttons()
		)
		AudioDirector.play_sfx("sfx_l02_box_wiggle")
		_wiggle_toast()
	selected_box = -1
	_refresh_hud_buttons()


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
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -390
	panel.offset_top = -280
	panel.offset_right = 390
	panel.offset_bottom = 280
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 18))
	layer.add_child(panel)
	var title := UIKit.label("Clipboard", 32, UIKit.DARK, "title")
	title.position = Vector2(20, 12)
	panel.add_child(title)
	var close := UIKit.button("Close", UIKit.DARK)
	close.position = Vector2(620, 12)
	close.size = Vector2(130, 44)
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
		], 16, UIKit.DARK)
		card.position = Vector2(20, y)
		card.size = Vector2(520, 110)
		panel.add_child(card)
		var id := str(decorated.get("id", ""))
		var go := UIKit.button("Take job", UIKit.TERRA)
		go.position = Vector2(560, y + 20)
		go.size = Vector2(180, 48)
		go.pressed.connect(_start_listed_job.bind(id))
		panel.add_child(go)
		y += 120
	if not any:
		var empty := UIKit.label("Marge hasn't pinned a job yet. Finish unpacking the garage first.", 18, UIKit.DARK)
		empty.position = Vector2(20, 80)
		empty.size = Vector2(700, 80)
		panel.add_child(empty)


func _act_button(layer: CanvasLayer, text: String, at: Vector2, callback: Callable) -> void:
	if layer == null:
		return
	var btn := UIKit.button(text, UIKit.TERRA if "Finish" in text or "Drive" in text else UIKit.SAGE)
	btn.name = "ActButton"
	if at.x < 400.0:
		btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		btn.offset_left = 16
		btn.offset_right = 276
	else:
		btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn.offset_left = -256
		btn.offset_right = -16
	btn.offset_top = at.y
	btn.offset_bottom = at.y + 48
	btn.pressed.connect(callback)
	layer.add_child(btn)


func _hud_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer:
			return child
	return null


func _hint_text() -> String:
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


func _toast(message: String) -> void:
	if toast == null:
		return
	toast.text = message
	toast.visible = true
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
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -140
	panel.offset_right = 260
	panel.offset_bottom = 140
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.CARD, 18))
	layer.add_child(panel)
	var title := UIKit.label("TropicalForest box", 26, UIKit.DARK, "title")
	title.position = Vector2(20, 12)
	panel.add_child(title)
	var left := int(order.get("bubbles_left", 0))
	var blurb := UIKit.label("Pop the bubble wrap. Packing peanuts drift out. %d left." % left, 16, UIKit.DARK)
	blurb.position = Vector2(20, 56)
	blurb.size = Vector2(480, 48)
	panel.add_child(blurb)
	var pop := UIKit.button("Pop a bubble", UIKit.BLUE)
	pop.position = Vector2(20, 120)
	pop.size = Vector2(220, 48)
	pop.pressed.connect(_pop_bubble)
	panel.add_child(pop)
	if str(order.get("status", "")) == "door" or left == int(Catalog.forest.get("bubbles", 5)):
		var back := UIKit.button("Return sealed", UIKit.TERRA)
		back.position = Vector2(260, 120)
		back.size = Vector2(220, 48)
		back.pressed.connect(_return_sealed)
		panel.add_child(back)
	var close := UIKit.button("Later", UIKit.DARK)
	close.position = Vector2(20, 190)
	close.size = Vector2(160, 44)
	close.pressed.connect(func():
		var node := layer.get_node_or_null("Unbox")
		if node:
			node.queue_free()
	)
	panel.add_child(close)


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


func _squash_last() -> void:
	if GameState.office_items.is_empty():
		return
	_squash_uid(str(GameState.office_items.back().get("uid", "")))


func _squash(node: Node3D) -> void:
	if node == null:
		return
	node.scale = Vector3.ONE
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3(1.15, 0.9, 1.15), 0.07)
	tw.tween_property(node, "scale", Vector3(0.95, 1.06, 0.95), 0.08)
	tw.tween_property(node, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)


func _wiggle_toast() -> void:
	if toast:
		var tw := create_tween()
		tw.tween_property(toast, "position:x", toast.position.x + 8, 0.05)
		tw.tween_property(toast, "position:x", toast.position.x - 8, 0.08)
		tw.tween_property(toast, "position:x", toast.position.x, 0.05)
