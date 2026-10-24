extends Node2D
# The drive. A top-down town built by city.gd, a truck with weight to it,
# traffic that keeps to its lane, and a loading bay at both ends: load the
# boxes at the client's curb, follow the arrow, park in the bay at the other
# end, and unload. Box condition is the only score. You cannot fail a drive.

const Tuning = preload("res://scripts/tuning.gd")
const UIKit = preload("res://scripts/ui_kit.gd")
const Controls = preload("res://scripts/control_map.gd")
const City = preload("res://scripts/city.gd")

signal finished(result: Dictionary)

const PX := 32.0
# @1x frame is 148x72. Opaque art sits inside a clear margin; hit tests use that art, not the canvas.
const FRAME_W := 148.0
const FRAME_H := 72.0
const ART_X := 2.0
const ART_Y := 1.0
const ART_W := 145.0
const ART_H := 71.0
const TRUCK_RADIUS := 38.0
const CAR_RADIUS := 34.0

var course: Dictionary = {}
var city = null
var pos := Vector2.ZERO
var heading := 0.0
var vel := Vector2.ZERO
var speed := 0.0
var condition := 100
var alley := false
var duck_friend := false
var near_miss := false
var wobble_done := false
var hazard_cd: Dictionary = {}
var touching: Dictionary = {}
var contact_ready: Dictionary = {}
var duck_hold := 0.0
var laps := 0
var in_finish := false
var truck: Sprite2D
var cam: Camera2D
var meter: ProgressBar
var meter_label: Label
var hint: Label
var time_alive := 0.0
var rain: CPUParticles2D
var wiper := 0.0
var rev_cd := 0.0
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
var at_dropoff := false
var box_count := 4
var box_anim: Array = []
var anim_t := 0.0
var hud_root: Control
var act_button: Button
var minimap: Control
var pulse := 0.0
var skid := 0.0


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
	cam = Camera2D.new()
	cam.position = pos
	cam.zoom = Vector2(1.05, 1.05)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	add_child(cam)
	# The dedicated top-down truck sprite is still coming. This sheet is the placeholder.
	truck = Sprite2D.new()
	var sheet_path := "res://assets/ui/driving/mover_truck_topdown_sheet@1x.png"
	var sheet_scale := 1.0
	if not ResourceLoader.exists(sheet_path):
		sheet_path = "res://assets/ui/driving/mover_truck_topdown_sheet.png"
		sheet_scale = 0.5
	if ResourceLoader.exists(sheet_path):
		truck.texture = load(sheet_path)
		truck.hframes = 4
	truck.centered = true
	truck.scale = Vector2(sheet_scale, sheet_scale)
	truck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	truck.position = pos
	truck.rotation = heading
	truck.z_index = 8
	add_child(truck)
	_dress_town()
	_spawn_traffic()
	_hud()
	UIKit.show_level_beat(self, GameState.present_current_slice_level(), true)
	var weather := str(course.get("weather", "clear"))
	AudioDirector.play_bed(str(course.get("music", "music_driving")), str(course.get("ambience", "")))
	if weather == "rain":
		_make_rain()
	if str(course.get("id", "")) == "duck_pond":
		AudioDirector.start_loop("sfx_l05_fountain_loop")
	AudioDirector.start_loop("sfx_truck_idle_loop")
	_set_action("Load up")
	queue_redraw()


func _exit_tree() -> void:
	AudioDirector.stop_level()


# ---------------------------------------------------------------- setup

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
	if bool(course.get("alley", false)) and city.alley.size != Vector2.ZERO:
		var middle: Vector2 = city.alley.get_center()
		hazards.append({"type": "wobble", "x": middle.x, "y": middle.y, "on": "alley"})


func _spawn_traffic() -> void:
	var loops: Array = city.traffic_loops()
	var count := int(Tuning.get_value("drive.traffic_cars", 10))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "drive")))
	var mps := float(Tuning.get_value("drive.traffic_mps", 2.4)) * PX
	for i in count:
		var loop: PackedVector2Array = loops[rng.randi_range(0, loops.size() - 1)]
		var seg := rng.randi_range(0, loop.size() - 1)
		var sprite := _make_sprite("parked_car")
		if sprite == null:
			continue
		sprite.modulate = [Color("F2E5B8"), Color("9FC4D6"), Color("D9765F"), Color("C9D2C0"), Color("E6B655")][i % 5]
		sprite.z_index = 6
		var start: Vector2 = loop[seg].lerp(loop[(seg + 1) % loop.size()], rng.randf())
		# Keep the first few seconds clear around the truck.
		if start.distance_to(pos) < 420.0:
			start = loop[(seg + 2) % loop.size()]
			seg = (seg + 2) % loop.size()
		cars.append({"loop": loop, "seg": seg, "pos": start, "speed": mps * rng.randf_range(0.8, 1.1), "cruise": mps, "sprite": sprite, "heading": 0.0, "horn": 0.0})
		sprite.position = start


func _dress_town() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(course.get("id", "")) + "dress")
	for spot in city.curb_spots(rng):
		var sprite := _make_sprite(str(spot.get("kind", "")))
		if sprite:
			sprite.position = spot.get("at", Vector2.ZERO)
			sprite.z_index = 3
	for shop in city.shops:
		var sprite := _make_sprite("shopfront")
		if sprite:
			sprite.position = (shop.get("door", Vector2.ZERO) as Vector2) + _inward(str(shop.get("side", "N"))) * 60.0
			sprite.z_index = 3
	for id in city.places.keys():
		var place: Dictionary = city.places[id]
		if id == "forest" or id == "garage":
			continue
		var sprite := _make_sprite("shopfront")
		if sprite:
			sprite.position = (place.get("door", Vector2.ZERO) as Vector2) + _inward(str(place.get("side", "N"))) * 60.0
			sprite.z_index = 3
	# The park: a fountain in the pond, willows, benches, a closed bridge, a jogger, ducklings.
	var park: Rect2 = city.park_rect()
	var water: Dictionary = city.pond()
	var center: Vector2 = water.get("center", park.get_center())
	for spot in [
		{"name": "fountain", "at": center},
		{"name": "willow", "at": park.position + Vector2(90, 110)},
		{"name": "willow", "at": park.end - Vector2(120, 90)},
		{"name": "bench", "at": Vector2(park.position.x + 80, park.end.y - 70)},
		{"name": "bench", "at": Vector2(park.end.x - 80, park.position.y + 90)},
		{"name": "bridge_closed", "at": center + Vector2(0, -float(water.get("radius", 100)) - 40)},
		{"name": "jogger", "at": park.position + Vector2(park.size.x * 0.5, 40)},
		{"name": "duckling", "at": center + Vector2(float(water.get("radius", 100)) * 0.6, 30)},
	]:
		var sprite := _make_sprite(str(spot["name"]))
		if sprite:
			sprite.position = spot["at"]
			sprite.z_index = 3
	for hazard in hazards:
		var kind := str(hazard.get("type", ""))
		var art := _hazard_art(kind)
		if art == "":
			continue
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		var sprite := _make_sprite(art)
		if sprite:
			sprite.position = at
			sprite.z_index = 4
			if kind == "bump" and float(hazard.get("h", 0)) > float(hazard.get("w", 0)):
				sprite.rotation = PI * 0.5
		if kind == "ducks":
			var little := _make_sprite("duckling")
			if little:
				little.position = at + Vector2(36, 22)
				little.z_index = 4


func _inward(side: String) -> Vector2:
	match side:
		"N":
			return Vector2(0, 1)
		"S":
			return Vector2(0, -1)
		"W":
			return Vector2(1, 0)
	return Vector2(-1, 0)


func _make_sprite(art_name: String) -> Sprite2D:
	var path := "res://assets/ui/driving/%s@1x.png" % art_name
	var sprite_scale := 1.0
	if not ResourceLoader.exists(path):
		path = "res://assets/ui/driving/%s.png" % art_name
		sprite_scale = 0.5
	if not ResourceLoader.exists(path):
		return null
	var sprite := Sprite2D.new()
	sprite.name = art_name
	sprite.texture = load(path)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


func _make_rain() -> void:
	rain = CPUParticles2D.new()
	rain.amount = 80
	rain.lifetime = 1.1
	rain.preprocess = 1.0
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(760, 460)
	rain.direction = Vector2(0.2, 1)
	rain.spread = 12
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 280
	rain.initial_velocity_max = 420
	rain.color = Color(0.75, 0.82, 0.9, 0.35)
	cam.add_child(rain)


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
	card.add_child(meter)
	meter_label = UIKit.label("100", 36, UIKit.DARK, "body", false)
	meter_label.position = Vector2(400, 16)
	meter_label.custom_minimum_size = Vector2(120, 44)
	card.add_child(meter_label)
	var hint_bar := Panel.new()
	hint_bar.name = "DriveHint"
	hint_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	hud_root.add_child(hint_bar)
	UIKit.pin_bottom(hint_bar, 16, -156, -16, -16)
	hint = UIKit.label("", 30, UIKit.DARK)
	hint.max_lines_visible = 2
	hud_root.add_child(hint)
	UIKit.pin_bottom(hint, 32, -144, -420, -24)
	var name_bar := Panel.new()
	name_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.NIGHT, 14))
	hud_root.add_child(name_bar)
	UIKit.pin_top_right(name_bar, -520, 16, -16, 84)
	var name_label := UIKit.label(str(course.get("title", "Drive")), 28, UIKit.CREAM_CARD, "title", false)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_bar.add_child(name_label)
	UIKit.fill(name_label, 12, 8, 12, 8)
	# Minimap under the title: the whole town, the route, the truck.
	var map_card := Panel.new()
	map_card.name = "Minimap"
	map_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_card.add_theme_stylebox_override("panel", UIKit.style(Color(UIKit.CREAM_CARD, 0.92), 14))
	hud_root.add_child(map_card)
	UIKit.pin_top_right(map_card, -356, 96, -16, 330)
	minimap = Control.new()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_card.add_child(minimap)
	UIKit.fill(minimap, 12, 12, 12, 12)
	minimap.draw.connect(_draw_minimap)


func _set_action(text: String) -> void:
	if hud_root == null:
		return
	if act_button != null and is_instance_valid(act_button):
		act_button.queue_free()
		act_button = null
	if text == "":
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
	UIKit.link_focus([act_button])


func _hint_text() -> String:
	var weather := str(course.get("weather", "clear"))
	var dest := str(dropoff.get("name", "the new place"))
	var line := ""
	match state:
		"load":
			line = "Parked at %s. Press %s or Load up to pull the boxes in." % [pickup.get("name", "the curb"), Controls.describe_key("interact")]
		"drive":
			if at_dropoff:
				line = "This is the bay. Press %s or Unload." % Controls.describe_key("interact")
			else:
				line = "Deliver to %s. Follow the arrow." % dest
				if bool(course.get("alley", false)):
					line += " The alley is shorter and bumpier."
				elif str(course.get("id", "")) == "duck_pond":
					line += " Honk and the ducks hurry."
		"unload":
			line = "Unloading at %s." % dest
		_:
			line = "Done."
	var second := "WASD drives, %s brakes hard, %s honks. Condition %d." % [Controls.describe_key("handbrake"), Controls.describe_key("horn"), condition]
	if weather == "rain":
		second += " Rain makes the stop longer."
	return line + "\n" + second


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
		_traffic(delta)
		_hazards()
		_check_alley()
		_check_dropoff()
	truck.position = pos
	truck.rotation = heading
	if absf(speed) > 20.0:
		truck.frame = int(time_alive * (2.0 + absf(speed) / 80.0)) % 4
	else:
		truck.frame = 0
	if shake > 0.0 and SaveManager.shake:
		shake -= delta
		truck.position += Vector2(randf_range(-3, 3), randf_range(-2, 2))
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 5.5)) * PX
	var look := Vector2.RIGHT.rotated(heading) * clampf(speed / max_speed, -1.0, 1.0) * 110.0
	cam.position = pos + look
	var z := lerpf(1.05, 0.82, clampf(absf(speed) / max_speed, 0.0, 1.0))
	cam.zoom = cam.zoom.lerp(Vector2(z, z), delta * 2.0)
	meter.value = condition
	var stamp := Tuning.tip_stamp(condition)
	meter_label.text = "%d  %s" % [condition, stamp]
	hint.text = _hint_text()
	if minimap:
		minimap.queue_redraw()
	queue_redraw()


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
	var handbrake := Controls.held("handbrake")
	if handbrake:
		grip = float(Tuning.get_value("drive.grip_handbrake", 1.5))
	var throttle := Controls.axis("drive_back", "drive_forward")
	var forward := Vector2.RIGHT.rotated(heading)
	speed = vel.dot(forward)
	if throttle > 0.0 and speed < max_speed * 0.25 and rev_cd <= 0.0:
		AudioDirector.play_sfx("sfx_truck_rev")
		rev_cd = 1.6
	var off_road: bool = not city.on_road(pos) and not _in_bay(pos)
	var cap := max_speed * (0.45 if off_road else 1.0)
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
			vel += forward * accel * delta * throttle
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
	skid = lateral.length()
	if vel.length() > cap:
		vel = vel.normalized() * cap
	speed = vel.dot(forward)
	var steer := Controls.axis("steer_left", "steer_right")
	if absf(speed) > 10.0:
		var sign := 1.0 if speed >= 0.0 else -1.0
		heading += steer * turn * delta * clampf(absf(speed) / max_speed, 0.35, 1.0) * sign
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


func _traffic(delta: float) -> void:
	var truck_center := _art_center()
	var forward := Vector2.RIGHT.rotated(heading)
	for car in cars:
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
		var sprite: Sprite2D = car["sprite"]
		sprite.position = at
		sprite.rotation = float(car["heading"])
		# A fender bender: push the truck off the car and spend some condition.
		if at.distance_to(truck_center) < TRUCK_RADIUS + CAR_RADIUS - 8.0:
			var normal := (truck_center - at).normalized()
			pos += normal * 6.0
			vel = vel * 0.4 + normal * 40.0
			_apply_hit("car", int(Tuning.get_value("box_condition.collision", 10)), 1200)
	if forward == Vector2.ZERO:
		return


func _check_alley() -> void:
	if not bool(course.get("alley", false)) or city.alley.size == Vector2.ZERO:
		return
	if not alley and (city.alley as Rect2).grow(-10).has_point(pos):
		alley = true
		AudioDirector.play_sfx("sfx_notification_soft")


func _check_dropoff() -> void:
	var bay: Rect2 = dropoff.get("bay", Rect2())
	var parked := bay.has_point(_art_center()) and absf(speed) < 14.0 and vel.length() < 20.0
	if parked != at_dropoff:
		at_dropoff = parked
		if at_dropoff:
			AudioDirector.play_sfx("sfx_notification_soft")
			_set_action("Unload")
		else:
			_set_action("")


func _unhandled_input(event: InputEvent) -> void:
	if not running:
		return
	if Controls.event_pressed(event, "horn"):
		AudioDirector.play_sfx("sfx_truck_horn")
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
	AudioDirector.play_sfx("sfx_box_set_down")


func _begin_unload() -> void:
	state = "unload"
	at_dropoff = false
	_set_action("")
	vel = Vector2.ZERO
	speed = 0.0
	_start_box_anim(false)
	AudioDirector.play_sfx("sfx_box_set_down")


func _start_box_anim(loading: bool) -> void:
	box_anim.clear()
	anim_t = 0.0
	var place: Dictionary = pickup if loading else dropoff
	var door: Vector2 = place.get("door", pos)
	var curb := door + _inward(str(place.get("side", "N"))) * -40.0
	for i in box_count:
		var stack := curb + Vector2(-float(box_count) * 11.0 + i * 22.0, 0).rotated(float(place.get("heading", 0.0)))
		var bed := pos + Vector2(-30.0 + float(i % 4) * 16.0, -10.0 + float(int(i / 4)) * 16.0).rotated(heading)
		box_anim.append({"from": stack if loading else bed, "to": bed if loading else stack, "delay": i * 0.28, "done": false})
	box_anim.append({"loading": loading})


func _animate_boxes(delta: float) -> void:
	anim_t += delta
	var all_done := true
	var loading := true
	for entry in box_anim:
		if entry.has("loading"):
			loading = bool(entry["loading"])
			continue
		var t := clampf((anim_t - float(entry["delay"])) / 0.5, 0.0, 1.0)
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
		"duck_friend": duck_friend and not near_miss and bool(GameState.job.get("def", {}).get("duck_friend", false)),
		"near_miss": near_miss,
		"time": time_alive,
	}
	AudioDirector.play_sfx("sfx_success_chime")
	emit_signal("finished", result)


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if city == null:
		return
	var weather := str(course.get("weather", ""))
	var bounds: Rect2 = city.bounds
	var ground := Color("C4B89A")
	draw_rect(bounds.grow(600), ground)
	# Roads.
	for rect in city.roads:
		draw_rect(rect, Color("5E5A5C"))
	for rect in city.roads:
		var r: Rect2 = rect
		if r.size.x > r.size.y:
			var y := r.position.y + r.size.y * 0.5
			var x := r.position.x + 40.0
			while x < r.end.x - 40.0:
				draw_line(Vector2(x, y), Vector2(x + 48.0, y), Color("E8DFC8"), 4.0)
				x += 96.0
		else:
			var x2 := r.position.x + r.size.x * 0.5
			var y2 := r.position.y + 40.0
			while y2 < r.end.y - 40.0:
				draw_line(Vector2(x2, y2), Vector2(x2, y2 + 48.0), Color("E8DFC8"), 4.0)
				y2 += 96.0
	# Blocks: sidewalk, then the roofs.
	for c in city.cols:
		for r in city.rows:
			var rect: Rect2 = city.block_rect(c, r)
			if Vector2i(c, r) == city.park_block:
				draw_rect(rect, Color("8FAF7E"))
				draw_rect(rect.grow(-city.sidewalk * 0.5), Color("7FA06C"), false, 6.0)
				var water: Dictionary = city.pond()
				draw_circle(water.get("center", rect.get_center()), float(water.get("radius", 100)) + 10.0, Color("B9A98C"))
				draw_circle(water.get("center", rect.get_center()), float(water.get("radius", 100)), Color("7FA3B8"))
				continue
			draw_rect(rect, Color("D9D2C4"))
	for entry in city.buildings:
		var rect: Rect2 = entry.get("rect", Rect2())
		var color: Color = entry.get("color", Color("B9A58C"))
		draw_rect(rect.grow(4), color.darkened(0.25))
		draw_rect(rect, color)
		var inset := rect.grow(-18)
		draw_rect(inset, color.lightened(0.06))
		# A few roof boxes and vents.
		var vx := inset.position.x + 30
		while vx < inset.end.x - 40:
			draw_rect(Rect2(vx, inset.position.y + 24, 22, 22), color.darkened(0.18))
			vx += 110
	if city.alley.size != Vector2.ZERO:
		draw_rect(city.alley, Color("6B4A3A"))
		draw_string(UIKit.title_font(), city.alley.position + Vector2(-20, -12), "Alley", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.CREAM_CARD)
	# Shop signs and the two bays.
	for shop in city.shops:
		_sign(shop, Color("C68B59"))
	for id in city.places.keys():
		var place: Dictionary = city.places[id]
		_sign(place, place.get("color", Color("C68B59")))
	_bay(pickup, "LOAD", state == "load")
	_bay(dropoff, "UNLOAD", state == "drive")
	# The route, dotted on the road from where the truck is.
	if state == "drive" and route.size() > 1:
		var start := route_index
		var previous := pos
		for i in range(start, route.size()):
			var seg := route[i] - previous
			var steps := int(seg.length() / 44.0)
			for k in range(1, steps):
				draw_circle(previous + seg * (float(k) / float(steps)), 5.0, Color(UIKit.TERRA, 0.55))
			previous = route[i]
		var goal := route[mini(route_index, route.size() - 1)]
		var dir := (goal - pos).normalized()
		var tip := pos + dir * 120.0
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * 34.0 + side * 18.0, tip - dir * 34.0 - side * 18.0]), Color(UIKit.TERRA, 0.9))
	# Boxes being loaded or unloaded.
	for entry in box_anim:
		if entry.has("loading"):
			continue
		var t := clampf((anim_t - float(entry["delay"])) / 0.5, 0.0, 1.0)
		var at: Vector2 = (entry["from"] as Vector2).lerp(entry["to"], t)
		var lift := sin(t * PI) * 10.0
		draw_rect(Rect2(at + Vector2(-9, -9 - lift), Vector2(18, 18)), Color("C68B59"))
		draw_rect(Rect2(at + Vector2(-9, -9 - lift), Vector2(18, 18)), Color("7A4F2A"), false, 2.0)
	if weather == "rain":
		draw_rect(bounds.grow(600), Color("3E3A4F", 0.18))
	if skid > 60.0:
		draw_circle(pos, 6.0, Color(0, 0, 0, 0.12))


func _sign(place: Dictionary, color: Color) -> void:
	var door: Vector2 = place.get("door", Vector2.ZERO)
	var side := str(place.get("side", "N"))
	var inward := _inward(side)
	var along := Vector2(-inward.y, inward.x)
	var width := 150.0
	var strip := Rect2(door + inward * 2.0 - along * width * 0.5, Vector2.ZERO)
	strip = Rect2(strip.position, along * width + inward * 26.0)
	strip = strip.abs()
	draw_rect(strip, color)
	draw_rect(strip, color.darkened(0.3), false, 2.0)
	var text := str(place.get("name", ""))
	if text != "":
		draw_string(UIKit.body_font(), door + inward * 48.0 - Vector2(text.length() * 5.0, -6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.DARK)


func _bay(place: Dictionary, caption: String, active: bool) -> void:
	var bay: Rect2 = place.get("bay", Rect2())
	if bay.size == Vector2.ZERO:
		return
	var glow := 0.55 + 0.35 * sin(pulse * 4.0) if active else 0.4
	draw_rect(bay, Color(UIKit.MUSTARD, glow * 0.5))
	draw_rect(bay, Color(UIKit.MUSTARD, glow), false, 5.0)
	var step := 24.0
	var x := bay.position.x - bay.size.y
	while x < bay.end.x:
		var a := Vector2(clampf(x, bay.position.x, bay.end.x), bay.position.y + clampf(bay.position.x - x, 0.0, bay.size.y))
		var b := Vector2(clampf(x + bay.size.y, bay.position.x, bay.end.x), bay.end.y - clampf(x + bay.size.y - bay.end.x, 0.0, bay.size.y))
		draw_line(a, b, Color(UIKit.MUSTARD, glow * 0.6), 3.0)
		x += step
	draw_string(UIKit.title_font(), bay.position + Vector2(8, bay.size.y * 0.5 + 8), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.DARK)


func _draw_minimap() -> void:
	if city == null or minimap == null:
		return
	var size := minimap.size
	var bounds: Rect2 = city.bounds
	var k := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var offset := (size - bounds.size * k) * 0.5
	minimap.draw_rect(Rect2(offset, bounds.size * k), Color("CFC7B8"))
	for c in city.cols:
		for r in city.rows:
			var rect: Rect2 = city.block_rect(c, r)
			var color := Color("8FAF7E") if Vector2i(c, r) == city.park_block else Color("B9A58C")
			minimap.draw_rect(Rect2(offset + rect.position * k, rect.size * k), color)
	if route.size() > 1:
		var points := PackedVector2Array()
		for p in route:
			points.append(offset + p * k)
		minimap.draw_polyline(points, Color(UIKit.TERRA, 0.9), 2.0)
	var pick: Rect2 = pickup.get("bay", Rect2())
	var drop: Rect2 = dropoff.get("bay", Rect2())
	minimap.draw_circle(offset + pick.get_center() * k, 4.0, UIKit.BLUE)
	minimap.draw_circle(offset + drop.get_center() * k, 5.0, UIKit.GREEN)
	for car in cars:
		minimap.draw_circle(offset + (car["pos"] as Vector2) * k, 1.5, Color(UIKit.DARK, 0.5))
	minimap.draw_circle(offset + pos * k, 4.5, UIKit.TERRA)
	minimap.draw_circle(offset + pos * k, 4.5, UIKit.DARK, false, 1.0)


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
