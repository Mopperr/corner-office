extends Control
# The town map. Roads, the pond, a few green patches, and a pin for every
# place in data/map.json. A pin shows where Dana is, which clients have a
# job ready, and which offices are bought, for sale, or still to come.

signal closed
signal job_requested(job_id)

const UIKit = preload("res://scripts/ui_kit.gd")
const Tuning = preload("res://scripts/tuning.gd")

const CARD := Vector2(1760, 940)
const MAP_ORIGIN := Vector2(30, 86)
const PAPER := Color("EFE3CC")
const PAPER_EDGE := Color("D9C8A6")
const GRID := Color("E4D7BD")
const GREEN := Color("C9DDB0")
const GREEN_DARK := Color("B5CC9B")
const TREE := Color("8FB573")
const TREE_LIGHT := Color("A9C98A")
const WATER := Color("A9CCDD")
const ROAD := Color("F6EEDC")
const ROAD_EDGE := Color("D8C9A8")
const ROAD_LINE := Color("D9A866")
const RAIL := Color("8E8276")
const HOUSES: Array = [Color("E7C9A8"), Color("D8B4A0"), Color("C9D2C0"), Color("E3D5B8"), Color("BFC8D4"), Color("D4C1D8"), Color("E8B4A8")]

var data: Dictionary = {}
var fit := 1.0
var info_w := 480.0
var board: Control
var info: VBoxContainer
var selected := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = _read("res://data/map.json")
	_build()
	AudioDirector.play_sfx("sfx_paper_rustle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE or key.keycode == KEY_M:
			_close()
			get_viewport().set_input_as_handled()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NIGHT, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	UIKit.fill(dim, 0, 0, 0, 0)
	var card := Panel.new()
	card.name = "MapCard"
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 22))
	add_child(card)
	# Fit the card to the window and scale the board inside it, so a small
	# window still shows the whole town.
	var view := get_viewport_rect().size
	if view.x < 8.0:
		view = Vector2(1920, 1080)
	var card_size := Vector2(minf(CARD.x, view.x - 40.0), minf(CARD.y, view.y - 40.0))
	UIKit.pin_center(card, card_size)
	var title := UIKit.label("Corner Town", 40, UIKit.DARK, "title", false)
	title.position = Vector2(30, 18)
	title.size = Vector2(500, 56)
	card.add_child(title)
	var sub := UIKit.label("Click a pin to read about a place, take a job, or move in.", 24, UIKit.WOOD, "small", false)
	sub.position = Vector2(300, 30)
	sub.size = Vector2(card_size.x - 520.0, 40)
	card.add_child(sub)
	var close := UIKit.button("Close", UIKit.DARK)
	close.position = Vector2(card_size.x - 190, 18)
	close.size = Vector2(160, 56)
	close.custom_minimum_size = Vector2(160, 56)
	close.pressed.connect(_close)
	card.add_child(close)
	board = Control.new()
	board.name = "Board"
	board.position = MAP_ORIGIN
	var size: Array = data.get("size", [1700, 820])
	# Positions scale with the window; the pins keep their full size so they stay easy to hit.
	fit = minf((card_size.x - 60.0) / float(size[0]), (card_size.y - 110.0) / float(size[1]))
	board.size = Vector2(float(size[0]) * fit, float(size[1]) * fit)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.draw.connect(_draw_board)
	card.add_child(board)
	var paper := Panel.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_theme_stylebox_override("panel", UIKit.style(PAPER, 18, 6, PAPER_EDGE))
	paper.position = Vector2.ZERO
	paper.size = board.size
	board.add_child(paper)
	paper.show_behind_parent = true
	var pins: Array = []
	for place in data.get("places", []):
		pins.append(_pin(place))
	_legend()
	info = VBoxContainer.new()
	info.name = "Info"
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 8)
	# Top-left: the only corner with no pins under it.
	info.position = _at(Vector2(40, 60))
	info_w = clampf(560.0 * fit, 300.0, 560.0)
	info.size = Vector2(info_w, 250)
	board.add_child(info)
	var focus: Array = [close]
	focus.append_array(pins)
	UIKit.link_focus(focus)
	_show_info("")


func _at(p: Vector2) -> Vector2:
	return p * fit


func _legend() -> void:
	var row := HBoxContainer.new()
	row.name = "Legend"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 18)
	row.position = Vector2(18.0, board.size.y - 44.0)
	board.add_child(row)
	for item in [[UIKit.SAGE, "You are here"], [UIKit.TERRA, "Job ready"], [UIKit.MUSTARD, "For sale"], [UIKit.BLUE, "Done"], [Color("B9B2A6"), "Later"]]:
		var dot := Panel.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(22, 22)
		var box := UIKit.style(item[0], 11)
		box.shadow_size = 0
		dot.add_theme_stylebox_override("panel", box)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var text := UIKit.label(str(item[1]), 24, UIKit.DARK, "small", false)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(text)


func _draw_board() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var size: Array = data.get("size", [1700, 820])
	var w := float(size[0])
	var h := float(size[1])
	# Faint survey grid on the paper.
	var step := 100.0
	var gx := step
	while gx < w:
		board.draw_line(_at(Vector2(gx, 20)), _at(Vector2(gx, h - 20)), GRID, 1.0)
		gx += step
	var gy := step
	while gy < h:
		board.draw_line(_at(Vector2(20, gy)), _at(Vector2(w - 20, gy)), GRID, 1.0)
		gy += step
	# Parks: layered green with a scatter of trees.
	for blob in data.get("green", []):
		var c := Vector2(float(blob.get("x", 0)), float(blob.get("y", 0)))
		var r := float(blob.get("r", 40))
		board.draw_circle(_at(c), r * fit, GREEN_DARK)
		board.draw_circle(_at(c + Vector2(-r * 0.12, -r * 0.12)), r * 0.86 * fit, GREEN)
		for i in int(r / 14.0):
			var angle := rng.randf() * TAU
			var dist := rng.randf_range(0.1, 0.85) * r
			_tree(c + Vector2(cos(angle), sin(angle)) * dist, rng.randf_range(9.0, 15.0))
	# Water: the pond, ripples, and the ducks.
	for pool in data.get("water", []):
		var c := Vector2(float(pool.get("x", 0)), float(pool.get("y", 0)))
		var r := float(pool.get("r", 40))
		board.draw_circle(_at(c), (r + 10.0) * fit, Color("D8CDB2"))
		board.draw_circle(_at(c), r * fit, WATER)
		board.draw_circle(_at(c + Vector2(-r * 0.2, -r * 0.2)), r * 0.55 * fit, WATER.lightened(0.08))
		for i in 3:
			var ripple := c + Vector2(rng.randf_range(-r * 0.5, r * 0.5), rng.randf_range(-r * 0.5, r * 0.5))
			board.draw_arc(_at(ripple), 12.0 * fit, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.55), 2.0)
		for i in 3:
			_duck(c + Vector2(r * 0.3 + i * 22.0, r * 0.2 + (i % 2) * 18.0))
		for i in 6:
			var angle := rng.randf_range(0.0, TAU)
			_reed(c + Vector2(cos(angle), sin(angle)) * (r + 4.0))
	# Rail: a sleepered track.
	for track in data.get("rail", []):
		var pts := PackedVector2Array()
		for p in track:
			pts.append(_at(Vector2(float(p[0]), float(p[1]))))
		board.draw_polyline(pts, RAIL, 6.0 * fit, true)
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var n := (b - a).normalized().orthogonal() * 7.0 * fit
			var count := int(a.distance_to(b) / (16.0 * fit))
			for k in range(1, count):
				var m := a.lerp(b, float(k) / float(count))
				board.draw_line(m - n, m + n, RAIL, 2.0)
	# Roads: casing, fill, dashed centre line, round joints.
	var roads: Array = data.get("roads", [])
	for road in roads:
		var points := PackedVector2Array()
		for p in road:
			points.append(_at(Vector2(float(p[0]), float(p[1]))))
		board.draw_polyline(points, ROAD_EDGE, 40.0 * fit, true)
		for p in points:
			board.draw_circle(p, 20.0 * fit, ROAD_EDGE)
	for road in roads:
		var points := PackedVector2Array()
		for p in road:
			points.append(_at(Vector2(float(p[0]), float(p[1]))))
		board.draw_polyline(points, ROAD, 32.0 * fit, true)
		for p in points:
			board.draw_circle(p, 16.0 * fit, ROAD)
	for road in roads:
		for i in range(road.size() - 1):
			var a := _at(Vector2(float(road[i][0]), float(road[i][1])))
			var b := _at(Vector2(float(road[i + 1][0]), float(road[i + 1][1])))
			var count := int(a.distance_to(b) / (18.0 * fit))
			for k in range(count):
				if k % 2 == 1:
					continue
				board.draw_line(a.lerp(b, float(k) / float(count)), a.lerp(b, float(k + 1) / float(count)), ROAD_LINE, 2.0)
	# Houses along the roads, skipping the pins, the water and the parks.
	for road in roads:
		for i in range(road.size() - 1):
			var a := Vector2(float(road[i][0]), float(road[i][1]))
			var b := Vector2(float(road[i + 1][0]), float(road[i + 1][1]))
			var dir := (b - a).normalized()
			var side := dir.orthogonal()
			var count := int(a.distance_to(b) / 64.0)
			for k in range(1, count):
				var m := a.lerp(b, float(k) / float(count))
				for sgn in [-1.0, 1.0]:
					if rng.randf() < 0.3:
						continue
					var at: Vector2 = m + side * float(sgn) * 42.0
					if not _clear(at):
						continue
					_house(at, rng, absf(dir.x) > absf(dir.y))
	# The route from home to the chosen place, with a little truck halfway.
	var home := _place_for_office(GameState.office_id)
	var target := _place(selected)
	if not home.is_empty() and not target.is_empty() and str(target.get("id", "")) != str(home.get("id", "")):
		var from := _at(Vector2(float(home.get("x", 0)), float(home.get("y", 0))))
		var to := _at(Vector2(float(target.get("x", 0)), float(target.get("y", 0))))
		var steps := int(from.distance_to(to) / 16.0)
		for i in range(1, steps):
			board.draw_circle(from.lerp(to, float(i) / float(steps)), 3.5, Color(UIKit.TERRA, 0.8))
		_truck(from.lerp(to, 0.5), (to - from).normalized())
	_compass(Vector2(w - 70.0, 70.0))


func _clear(at: Vector2) -> bool:
	for place in data.get("places", []):
		if at.distance_to(Vector2(float(place.get("x", 0)), float(place.get("y", 0)))) < 120.0:
			return false
	for pool in data.get("water", []):
		if at.distance_to(Vector2(float(pool.get("x", 0)), float(pool.get("y", 0)))) < float(pool.get("r", 40)) + 30.0:
			return false
	for blob in data.get("green", []):
		if at.distance_to(Vector2(float(blob.get("x", 0)), float(blob.get("y", 0)))) < float(blob.get("r", 40)) + 16.0:
			return false
	return at.x > 40.0 and at.y > 40.0 and at.x < float(data.get("size", [1700, 820])[0]) - 40.0 and at.y < float(data.get("size", [1700, 820])[1]) - 60.0


func _house(at: Vector2, rng: RandomNumberGenerator, along_x: bool) -> void:
	var bw := rng.randf_range(26.0, 40.0)
	var bh := rng.randf_range(20.0, 30.0)
	if not along_x:
		var t := bw
		bw = bh
		bh = t
	var color: Color = HOUSES[rng.randi_range(0, HOUSES.size() - 1)]
	var top_left := _at(at - Vector2(bw, bh) * 0.5)
	var box := Rect2(top_left, Vector2(bw, bh) * fit)
	board.draw_rect(Rect2(box.position + Vector2(3, 3) * fit, box.size), Color(0, 0, 0, 0.12))
	board.draw_rect(box, color)
	var roof := color.darkened(0.25)
	if along_x:
		board.draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * 0.42)), roof)
	else:
		board.draw_rect(Rect2(box.position, Vector2(box.size.x * 0.42, box.size.y)), roof)
	# A door or a window.
	var pane := Vector2(5, 6) * fit
	board.draw_rect(Rect2(box.get_center() - pane * 0.5 + Vector2(0, box.size.y * 0.16), pane), Color(1, 1, 1, 0.6))


func _tree(at: Vector2, r: float) -> void:
	var p := _at(at)
	board.draw_circle(p + Vector2(2, 3) * fit, r * fit, Color(0, 0, 0, 0.1))
	board.draw_circle(p, r * fit, TREE)
	board.draw_circle(p + Vector2(-r * 0.3, -r * 0.3) * fit, r * 0.5 * fit, TREE_LIGHT)


func _duck(at: Vector2) -> void:
	var p := _at(at)
	board.draw_circle(p, 6.0 * fit, UIKit.MUSTARD)
	board.draw_circle(p + Vector2(5, -4) * fit, 3.6 * fit, UIKit.MUSTARD)
	board.draw_circle(p + Vector2(9, -4) * fit, 1.6 * fit, UIKit.TERRA)


func _reed(at: Vector2) -> void:
	var p := _at(at)
	for i in 3:
		board.draw_line(p + Vector2(i * 4 - 4, 0) * fit, p + Vector2(i * 4 - 6, -14 + i * 2) * fit, GREEN_DARK, 2.0)


func _truck(at: Vector2, dir: Vector2) -> void:
	var flip := -1.0 if dir.x < 0.0 else 1.0
	var body := Rect2(at + Vector2(-16, -10), Vector2(24, 16))
	board.draw_rect(body, UIKit.TERRA)
	board.draw_rect(Rect2(at + Vector2(8 * flip - (0 if flip > 0 else 10), -6), Vector2(10, 12)), UIKit.CREAM_CARD)
	board.draw_circle(at + Vector2(-10, 7), 4.0, UIKit.DARK)
	board.draw_circle(at + Vector2(6, 7), 4.0, UIKit.DARK)


func _compass(at: Vector2) -> void:
	var p := _at(at)
	var r := 28.0 * fit
	board.draw_circle(p, r + 4.0, PAPER_EDGE)
	board.draw_circle(p, r, PAPER)
	board.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r * 0.9), p + Vector2(-r * 0.22, 0), p + Vector2(r * 0.22, 0)]), UIKit.TERRA)
	board.draw_colored_polygon(PackedVector2Array([p + Vector2(0, r * 0.9), p + Vector2(-r * 0.22, 0), p + Vector2(r * 0.22, 0)]), UIKit.DARK)
	board.draw_line(p + Vector2(-r * 0.8, 0), p + Vector2(r * 0.8, 0), UIKit.DARK, 2.0)
	board.draw_string(UIKit.title_font(), p + Vector2(-7, -r - 8), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, UIKit.DARK)


func _pin(place: Dictionary) -> Button:
	var id := str(place.get("id", ""))
	var state := _state(place)
	var fill: Color = UIKit.WOOD
	var fg: Color = UIKit.CREAM_CARD
	match state:
		"here":
			fill = UIKit.SAGE
		"job":
			fill = UIKit.TERRA
		"buy":
			fill = UIKit.MUSTARD
			fg = UIKit.DARK
		"locked", "later":
			fill = Color("B9B2A6")
		"done":
			fill = UIKit.BLUE
		"shop":
			fill = UIKit.WOOD
	var at := _at(Vector2(float(place.get("x", 0)), float(place.get("y", 0))))
	# A round badge with a little picture of the place, and the name on a chip under it.
	var badge := Panel.new()
	badge.name = "Badge_" + id
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = Vector2(60, 60)
	badge.position = Vector2(at.x - 30.0, clampf(at.y - 74.0, 0.0, board.size.y - 60.0))
	var style := UIKit.style(fill, 30, 4, UIKit.CREAM_CARD)
	style.shadow_size = 6
	style.shadow_color = Color(0, 0, 0, 0.18)
	badge.add_theme_stylebox_override("panel", style)
	board.add_child(badge)
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(30, 30)
	icon.draw.connect(_draw_icon.bind(icon, str(place.get("icon", place.get("kind", ""))), fg))
	badge.add_child(icon)
	var btn := UIKit.button(str(place.get("name", id)), fill, fg)
	btn.name = "Pin_" + id
	btn.custom_minimum_size = Vector2(200, 48)
	btn.size = Vector2(200, 48)
	btn.pressed.connect(func(): _show_info(id))
	board.add_child(btn)
	var width := maxf(200.0, btn.get_combined_minimum_size().x)
	btn.size.x = width
	btn.position = Vector2(clampf(at.x - width * 0.5, 0.0, board.size.x - width), clampf(at.y - 14.0, 0.0, board.size.y - 48.0))
	return btn


func _draw_icon(icon: Control, kind: String, color: Color) -> void:
	match kind:
		"office", "house":
			icon.draw_colored_polygon(PackedVector2Array([Vector2(-14, -2), Vector2(0, -15), Vector2(14, -2)]), color)
			icon.draw_rect(Rect2(-10, -2, 20, 15), color)
			icon.draw_rect(Rect2(-3, 5, 6, 8), Color(0, 0, 0, 0.25))
		"cafe":
			icon.draw_rect(Rect2(-10, -8, 16, 16), color)
			icon.draw_arc(Vector2(8, 0), 5.0, -PI * 0.5, PI * 0.5, 8, color, 3.0)
			icon.draw_line(Vector2(-6, -12), Vector2(-4, -16), color, 2.0)
			icon.draw_line(Vector2(0, -12), Vector2(2, -16), color, 2.0)
		"train":
			icon.draw_rect(Rect2(-14, -8, 24, 14), color)
			icon.draw_rect(Rect2(10, -2, 6, 8), color)
			icon.draw_circle(Vector2(-8, 10), 3.5, color)
			icon.draw_circle(Vector2(2, 10), 3.5, color)
			icon.draw_rect(Rect2(-10, -14, 6, 6), color)
		"duck", "park":
			icon.draw_circle(Vector2(-2, 4), 9.0, color)
			icon.draw_circle(Vector2(7, -5), 5.5, color)
			icon.draw_colored_polygon(PackedVector2Array([Vector2(11, -5), Vector2(17, -3), Vector2(11, -1)]), UIKit.TERRA)
		"shop", "bag":
			icon.draw_rect(Rect2(-11, -6, 22, 18), color)
			icon.draw_arc(Vector2(0, -6), 7.0, PI, TAU, 10, color, 3.0)
		"loft":
			icon.draw_rect(Rect2(-12, -4, 24, 16), color)
			icon.draw_colored_polygon(PackedVector2Array([Vector2(-14, -4), Vector2(0, -14), Vector2(14, -4)]), color)
			icon.draw_rect(Rect2(-8, 0, 5, 5), Color(0, 0, 0, 0.25))
			icon.draw_rect(Rect2(3, 0, 5, 5), Color(0, 0, 0, 0.25))
		"glass":
			icon.draw_rect(Rect2(-12, -14, 24, 28), color)
			for row in 3:
				for col in 2:
					icon.draw_rect(Rect2(-9 + col * 10, -11 + row * 9, 7, 6), Color(0, 0, 0, 0.22))
		_:
			icon.draw_circle(Vector2.ZERO, 8.0, color)


func _state(place: Dictionary) -> String:
	var kind := str(place.get("kind", ""))
	if kind == "office":
		var office_id := str(place.get("office", ""))
		if GameState.office_id == office_id:
			return "here"
		var row := _office_row(office_id)
		if not bool(row.get("playable", false)):
			return "later"
		return "buy" if GameState.office_gate_met(office_id) else "locked"
	if kind == "client":
		var job := JobDB.get_job(str(place.get("job", "")))
		if not job.is_empty() and GameState.job_available(job) and GameState.mode == "office" and GameState.office_phase == "live":
			return "job"
		if bool(GameState.jobs_cleared.get(str(place.get("job", "")), false)):
			return "done"
		return "locked"
	return "shop"


func _show_info(id: String) -> void:
	selected = id
	if board:
		board.queue_redraw()
	for child in info.get_children():
		child.queue_free()
	var place := _place(id)
	if place.is_empty():
		var hint := UIKit.label("Dana's corner of town. Roads lead from the office to every client.", 24, UIKit.DARK, "small")
		hint.custom_minimum_size = Vector2(info_w - 20.0, 0)
		info.add_child(hint)
		_board_rows()
		return
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 10)
	info.add_child(head)
	head.add_child(UIKit.avatar(str(place.get("name", "?")).left(1), UIKit.TERRA, 40))
	var name_row := UIKit.label(str(place.get("name", "")), 28, UIKit.TERRA, "title", false)
	name_row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(name_row)
	var blurb := UIKit.label(str(place.get("blurb", "")), 24, UIKit.DARK, "small")
	blurb.custom_minimum_size = Vector2(info_w - 20.0, 0)
	info.add_child(blurb)
	var state := _state(place)
	var status := ""
	match state:
		"here":
			status = "You are here."
		"job":
			var job := JobDB.get_job(str(place.get("job", "")))
			status = "Job ready. Base pay $%d." % JobDB.base_pay(job)
		"done":
			status = "Done before. Marge can line it up again once the garage is tidy."
		"buy":
			status = "For sale. $%d, and the gate is met." % int(_office_row(str(place.get("office", ""))).get("cost", 0))
		"locked":
			if str(place.get("kind", "")) == "office":
				var row := _office_row(str(place.get("office", "")))
				status = "Needs $%d earned, %d jobs, Rep %d. You have $%d, %d, Rep %d." % [
					int(row.get("earned", 0)), int(row.get("jobs", 0)), int(row.get("rep", 0)),
					GameState.total_earned, GameState.jobs_done, GameState.rep_rank()]
			else:
				status = "No job pinned here yet."
		"later":
			status = "Not open in this slice."
		_:
			status = ""
	if status != "":
		var line := UIKit.label(status, 24, UIKit.DARK, "small")
		line.custom_minimum_size = Vector2(info_w - 20.0, 0)
		info.add_child(line)
	if state == "job":
		var go := UIKit.button("Take job", UIKit.TERRA)
		go.custom_minimum_size = Vector2(240, 52)
		go.pressed.connect(func():
			emit_signal("job_requested", str(place.get("job", "")))
			_close()
		)
		info.add_child(go)
	elif state == "buy":
		var buy := UIKit.button("Move in", UIKit.SAGE)
		buy.custom_minimum_size = Vector2(240, 52)
		buy.pressed.connect(func():
			var err := GameState.try_buy_office(str(place.get("office", "")))
			if err != "":
				var line := UIKit.label(err, 18, UIKit.LOSS)
				info.add_child(line)
				return
			AudioDirector.play_sfx("sfx_success_chime")
			SaveManager.save_game()
			_close()
		)
		info.add_child(buy)


func _board_rows() -> void:
	# Today's generated moves, so the map is a way to pick a job too.
	if GameState.mode != "office" or GameState.office_phase != "live":
		return
	var shown := 0
	for job in GameState.generated_jobs:
		var decorated := JobDB.get_job(str(job.get("id", "")))
		if decorated.is_empty() or not GameState.job_available(decorated):
			continue
		if shown == 0:
			info.add_child(UIKit.label("Today's board", 24, UIKit.TERRA, "title", false))
		shown += 1
		if shown > 2:
			break
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var text := UIKit.label("%s  $%d" % [decorated.get("title", ""), JobDB.base_pay(decorated)], 24, UIKit.DARK, "small", false)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.custom_minimum_size = Vector2(info_w - 180.0, 0)
		text.clip_text = true
		row.add_child(text)
		var go := UIKit.button("Take", UIKit.TERRA)
		go.custom_minimum_size = Vector2(120, 48)
		var id := str(decorated.get("id", ""))
		go.pressed.connect(func():
			emit_signal("job_requested", id)
			_close()
		)
		row.add_child(go)
		info.add_child(row)


func _place(id: String) -> Dictionary:
	for place in data.get("places", []):
		if str(place.get("id", "")) == id:
			return place
	return {}


func _place_for_office(office_id: String) -> Dictionary:
	for place in data.get("places", []):
		if str(place.get("office", "")) == office_id:
			return place
	return {}


func _office_row(office_id: String) -> Dictionary:
	for row in Tuning.get_value("offices", []):
		if str(row.get("id", "")) == office_id:
			return row
	return {}


func _close() -> void:
	AudioDirector.play_sfx("sfx_ui_click")
	emit_signal("closed")
	queue_free()


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
