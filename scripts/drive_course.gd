extends Node2D

signal finished(result: Dictionary)

const PX := 32.0
# @1x frame is 148x72. Opaque art sits inside a clear margin; hit tests use that art, not the canvas.
const FRAME_W := 148.0
const FRAME_H := 72.0
const ART_X := 2.0
const ART_Y := 1.0
const ART_W := 145.0
const ART_H := 71.0

var course: Dictionary = {}
var pos := Vector2.ZERO
var heading := 0.0
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


func _ready() -> void:
	var drive_id := str(GameState.job.get("def", {}).get("drive", "rainy_afternoon"))
	course = JobDB.get_drive(drive_id)
	if course.is_empty():
		course = JobDB.get_drive("rainy_afternoon")
	condition = int(Tuning.get_value("box_condition.start", 100))
	var start: Array = course.get("start", [360, 520])
	pos = Vector2(float(start[0]), float(start[1]))
	heading = float(course.get("heading", 0))
	cam = Camera2D.new()
	cam.position = pos
	cam.zoom = Vector2(1.15, 1.15)
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
	truck.z_index = 8
	add_child(truck)
	_dress_road()
	_hud()
	UIKit.show_level_beat(self, GameState.present_current_slice_level())
	var weather := str(course.get("weather", "clear"))
	AudioDirector.play_bed(str(course.get("music", "music_driving")), str(course.get("ambience", "")))
	if weather == "rain":
		_make_rain()
	if str(course.get("id", "")) == "duck_pond":
		AudioDirector.start_loop("sfx_l05_fountain_loop")
	AudioDirector.start_loop("sfx_truck_idle_loop")
	queue_redraw()


func _exit_tree() -> void:
	AudioDirector.stop_level()


func _make_rain() -> void:
	rain = CPUParticles2D.new()
	rain.amount = 80
	rain.lifetime = 1.1
	rain.preprocess = 1.0
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(700, 420)
	rain.direction = Vector2(0.2, 1)
	rain.spread = 12
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 280
	rain.initial_velocity_max = 420
	rain.color = Color(0.75, 0.82, 0.9, 0.35)
	cam.add_child(rain)


func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var card := Panel.new()
	card.position = Vector2(16, 16)
	card.size = Vector2(360, 92)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 16))
	layer.add_child(card)
	var title := UIKit.label("Box condition", 22, UIKit.DARK, "title", false)
	title.position = Vector2(16, 8)
	card.add_child(title)
	meter = ProgressBar.new()
	meter.position = Vector2(16, 48)
	meter.size = Vector2(320, 22)
	meter.max_value = 100
	meter.value = 100
	meter.show_percentage = false
	layer.add_child(meter)
	meter_label = UIKit.label("100", 18, UIKit.DARK)
	meter_label.position = Vector2(250, 10)
	card.add_child(meter_label)
	hint = UIKit.label("", 16, UIKit.CREAM_CARD)
	hint.position = Vector2(16, 640)
	hint.size = Vector2(1100, 70)
	layer.add_child(hint)
	var name_label := UIKit.label(str(course.get("title", "Drive")), 28, UIKit.CREAM_CARD, "title")
	name_label.position = Vector2(400, 18)
	layer.add_child(name_label)


func _process(delta: float) -> void:
	if not running:
		return
	time_alive += delta
	var accel := float(Tuning.get_value("drive.accel_mps2", 2.4)) * PX
	var brake := float(Tuning.get_value("drive.brake_mps2", 3.2)) * PX
	if str(course.get("weather", "")) == "rain":
		brake *= 1.0 - float(Tuning.get_value("drive.rain_brake_penalty", 0.15))
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 4.0)) * PX
	var turn := float(Tuning.get_value("drive.turn_rate", 1.7))
	var throttle := _axis(KEY_S, KEY_DOWN, KEY_W, KEY_UP)
	var weather := str(course.get("weather", "clear"))
	if rev_cd > 0.0:
		rev_cd -= delta
	if throttle > 0.0 and speed < max_speed * 0.25 and rev_cd <= 0.0:
		AudioDirector.play_sfx("sfx_truck_rev")
		rev_cd = 1.6
	if weather == "rain":
		wiper += delta
		if wiper >= 2.8:
			wiper = 0.0
			AudioDirector.play_sfx("sfx_l03_wiper")
	if str(course.get("id", "")) == "duck_pond":
		if jogger_cd > 0.0:
			jogger_cd -= delta
		if pos.distance_to(Vector2(1500, 180)) < 220.0 and jogger_cd <= 0.0:
			AudioDirector.play_sfx("sfx_l05_jogger_steps")
			jogger_cd = 0.55
	if throttle > 0.0:
		speed = minf(max_speed, speed + accel * delta * throttle)
	elif throttle < 0.0:
		var before := speed
		speed = maxf(0.0, speed + brake * delta * throttle)
		_maybe_hard_brake(weather, before, delta)
	else:
		speed = maxf(0.0, speed - accel * 0.35 * delta)
	var steer := _axis(KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT)
	if abs(speed) > 12.0:
		heading += steer * turn * delta * clampf(speed / max_speed, 0.35, 1.0)
	if duck_hold > 0.0:
		duck_hold -= delta
		speed = minf(speed, 18.0)
	pos += Vector2.RIGHT.rotated(heading) * speed * delta
	_check_alley()
	var off_road := not _on_road(pos)
	if off_road:
		pos = pos.move_toward(_closest_road(pos), 220.0 * delta)
	var edge := int(Tuning.get_value("box_condition.collision", 10))
	_contact("offroad", off_road and speed > 80.0, edge)
	_hazards()
	_finish_check()
	truck.position = pos
	truck.rotation = heading
	if speed > 20.0:
		truck.frame = int(time_alive * (2.0 + speed / 80.0)) % 4
	else:
		truck.frame = 0
	if shake > 0.0 and SaveManager.shake:
		shake -= delta
		truck.position += Vector2(randf_range(-3, 3), randf_range(-2, 2))
	cam.position = pos
	meter.value = condition
	var stamp := Tuning.tip_stamp(condition)
	meter_label.text = "%d  %s" % [condition, stamp]
	hint.text = "WASD to drive. %s  Condition %d. No rush, you can't fail this run." % [
		"Rain makes the stop a little longer." if weather == "rain" else "Clear road.",
		condition,
	]
	if course.get("alley") != null:
		hint.text += "  The alley is shorter and bumpier."
	if bool(course.get("loop", false)):
		hint.text += "  Honk (H) and the ducks hurry. Laps %d/%d." % [laps, int(course.get("laps", 2))]
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		AudioDirector.play_sfx("sfx_truck_horn")
		if _near_honk_ducks():
			duck_hold = 1.6
			AudioDirector.play_sfx("sfx_ducks_quack")
			AudioDirector.play_sfx("sfx_l05_duckling_peep")


func _physics_process(_delta: float) -> void:
	pass


func bump_points(speed_px: float) -> int:
	var slow := float(Tuning.get_value("box_condition.bump_min", 3))
	var fast := float(Tuning.get_value("box_condition.bump_max", 8))
	var meters := speed_px / PX
	var span := clampf(meters / 4.5, 0.0, 1.0)
	return int(round(lerpf(slow, fast, span)))


func _maybe_hard_brake(weather: String, before: float, delta: float) -> void:
	if weather != "rain":
		return
	var max_speed := float(Tuning.get_value("drive.max_speed_mps", 4.0)) * PX
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


func _on_road(p: Vector2) -> bool:
	for rect in course.get("roads", []):
		if _rect(rect).grow(18).has_point(p):
			return true
	var alley = course.get("alley")
	if typeof(alley) == TYPE_DICTIONARY:
		var a: Array = alley.get("a", [0, 0])
		var b: Array = alley.get("b", [0, 0])
		if _dist_seg(p, Vector2(float(a[0]), float(a[1])), Vector2(float(b[0]), float(b[1]))) < float(alley.get("width", 100)):
			return true
	return false


func _closest_road(p: Vector2) -> Vector2:
	var best := p
	var best_d := 99999.0
	for rect in course.get("roads", []):
		var r := _rect(rect)
		var c := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
		var dist := p.distance_to(c)
		if dist < best_d:
			best_d = dist
			best = c
	return best


func _hazards() -> void:
	var active: Dictionary = {}
	var pond := str(course.get("id", "")) == "duck_pond"
	for hazard in course.get("hazards", []):
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
			active["bump"] = bump_points(speed)
		else:
			var fast := speed > PX * 3.0
			active[kind] = int(Tuning.get_value("box_condition.bump_max", 8)) if fast else int(Tuning.get_value("box_condition.bump_min", 3))
	var kinds: Array = ["cone", "gravel", "bump", "puddle", "ducks"]
	for kind in active.keys():
		if not kinds.has(kind):
			kinds.append(str(kind))
	for kind in kinds:
		_contact(str(kind), active.has(kind), int(active.get(kind, 0)))


func _near_honk_ducks() -> bool:
	for hazard in course.get("hazards", []):
		if str(hazard.get("type", "")) != "ducks":
			continue
		if not bool(hazard.get("honk", false)):
			continue
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		if pos.distance_to(at) < 280.0:
			return true
	return false


func _finish_check() -> void:
	var rect := _rect(course.get("finish", [0, 0, 10, 10]))
	var inside := rect.has_point(pos)
	if inside and not in_finish:
		in_finish = true
		if bool(course.get("loop", false)):
			laps += 1
			AudioDirector.play_sfx("sfx_notification_soft")
			if laps >= int(course.get("laps", 2)):
				_complete()
		else:
			_complete()
	elif not inside:
		in_finish = false


func _complete() -> void:
	if not running:
		return
	running = false
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


func _rect(value) -> Rect2:
	if typeof(value) != TYPE_ARRAY or value.size() < 4:
		return Rect2()
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _draw() -> void:
	var grass := Color("8FAF7E")
	if str(course.get("weather", "")) == "rain":
		grass = Color("6E8F78")
	draw_rect(Rect2(-400, -400, 8000, 8000), grass if str(course.get("scenery", "")) == "pond" else Color("C4B89A"))
	if str(course.get("weather", "")) == "rain":
		draw_rect(Rect2(-400, -400, 8000, 8000), Color("3E3A4F", 0.18))
	for rect in course.get("roads", []):
		var r := _rect(rect)
		draw_rect(r, Color("C68B59"))
		draw_rect(r.grow(-18), Color("D7B48A"))
	var alley = course.get("alley")
	if typeof(alley) == TYPE_DICTIONARY:
		var a: Array = alley["a"]
		var b: Array = alley["b"]
		draw_line(Vector2(float(a[0]), float(a[1])), Vector2(float(b[0]), float(b[1])), Color("6B4A3A"), float(alley.get("width", 100)))
		draw_string(UIKit.title_font(), Vector2(float(a[0]) + 20, float(a[1]) - 30), "Alley shortcut", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIKit.CREAM_CARD)
	for hazard in course.get("hazards", []):
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		var kind := str(hazard.get("type", ""))
		if _hazard_art(kind) != "":
			continue
		var color := UIKit.TERRA if kind == "cone" else UIKit.BLUE if kind == "puddle" or kind == "ducks" else UIKit.MUSTARD
		draw_circle(at, 18 if kind != "ducks" else 28, color)
	var finish := _rect(course.get("finish", [0, 0, 1, 1]))
	draw_rect(finish, Color(UIKit.GREEN, 0.85))
	_building(Vector2(80, 300), "Old office")
	_building(finish.position + Vector2(-20, -150), "New office")
	if str(course.get("scenery", "")) == "pond":
		draw_circle(Vector2(1600, 1200), 220, Color("7FA3B8"))
		draw_circle(Vector2(1680, 1160), 16, UIKit.MUSTARD)


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


func _dress_road() -> void:
	for hazard in course.get("hazards", []):
		var kind := str(hazard.get("type", ""))
		var art := _hazard_art(kind)
		if art == "":
			continue
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		_road_sprite(art, at)
		if kind == "ducks":
			_road_sprite("duckling", at + Vector2(36, 22))
	var scenery := "pond" if str(course.get("scenery", "")) == "pond" else "town"
	for spot in _road_scenery(scenery):
		_road_sprite(str(spot["name"]), spot["at"])


func _road_scenery(kind: String) -> Array:
	if kind == "pond":
		return [
			{"name": "fountain", "at": Vector2(1600, 1120)},
			{"name": "willow", "at": Vector2(1180, 860)},
			{"name": "willow", "at": Vector2(2050, 1480)},
			{"name": "bench", "at": Vector2(980, 860)},
			{"name": "bench", "at": Vector2(1860, 1680)},
			{"name": "jogger", "at": Vector2(1500, 180)},
			{"name": "bridge_closed", "at": Vector2(520, 160)},
			{"name": "duckling", "at": Vector2(1720, 1240)},
		]
	return [
		{"name": "shopfront", "at": Vector2(640, 250)},
		{"name": "shopfront", "at": Vector2(1500, 760)},
		{"name": "shopfront", "at": Vector2(3600, 3480)},
		{"name": "parked_car", "at": Vector2(480, 700)},
		{"name": "parked_car", "at": Vector2(2500, 980)},
		{"name": "lamppost", "at": Vector2(360, 340)},
		{"name": "lamppost", "at": Vector2(1680, 340)},
		{"name": "lamppost", "at": Vector2(2140, 1800)},
		{"name": "lamppost", "at": Vector2(2140, 3000)},
		{"name": "umbrella", "at": Vector2(980, 720)},
		{"name": "umbrella", "at": Vector2(1760, 720)},
		{"name": "mailbox", "at": Vector2(1180, 720)},
	]


func _road_sprite(art_name: String, at: Vector2) -> void:
	var path := "res://assets/ui/driving/%s@1x.png" % art_name
	var sprite_scale := 1.0
	if not ResourceLoader.exists(path):
		path = "res://assets/ui/driving/%s.png" % art_name
		sprite_scale = 0.5
	if not ResourceLoader.exists(path):
		return
	var sprite := Sprite2D.new()
	sprite.name = art_name
	sprite.texture = load(path)
	sprite.centered = true
	sprite.position = at
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	add_child(sprite)


func _building(at: Vector2, caption: String) -> void:
	draw_rect(Rect2(at, Vector2(180, 120)), UIKit.CREAM)
	draw_rect(Rect2(at + Vector2(0, -30), Vector2(180, 36)), UIKit.TERRA)
	draw_string(UIKit.body_font(), at + Vector2(16, 70), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.DARK)


func _check_alley() -> void:
	var alley_def = course.get("alley")
	if typeof(alley_def) != TYPE_DICTIONARY:
		return
	var a: Array = alley_def.get("a", [0, 0])
	var b: Array = alley_def.get("b", [0, 0])
	var width := float(alley_def.get("width", 100))
	if _dist_seg(pos, Vector2(float(a[0]), float(a[1])), Vector2(float(b[0]), float(b[1]))) < width * 0.45:
		if not alley and pos.distance_to(Vector2(float(a[0]), float(a[1]))) > 70.0:
			alley = true
			AudioDirector.play_sfx("sfx_notification_soft")


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


func _axis(neg_a: Key, neg_b: Key, pos_a: Key, pos_b: Key) -> float:
	var value := 0.0
	if Input.is_key_pressed(neg_a) or Input.is_key_pressed(neg_b):
		value -= 1.0
	if Input.is_key_pressed(pos_a) or Input.is_key_pressed(pos_b):
		value += 1.0
	return value
