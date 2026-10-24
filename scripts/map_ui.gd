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
	var title := UIKit.label("Town map", 40, UIKit.DARK, "title", false)
	title.position = Vector2(30, 18)
	title.size = Vector2(500, 56)
	card.add_child(title)
	var sub := UIKit.label("Click a pin. Green: you are here. Terracotta: job ready. Mustard: for sale.", 18, UIKit.DARK)
	sub.position = Vector2(280, 30)
	sub.size = Vector2(card_size.x - 500.0, 40)
	sub.max_lines_visible = 1
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
	paper.add_theme_stylebox_override("panel", UIKit.style(Color("EFE3CC"), 18))
	paper.position = Vector2.ZERO
	paper.size = board.size
	board.add_child(paper)
	paper.show_behind_parent = true
	var pins: Array = []
	for place in data.get("places", []):
		pins.append(_pin(place))
	info = VBoxContainer.new()
	info.name = "Info"
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 8)
	info.position = _at(Vector2(1180, 560))
	info_w = clampf(board.size.x - info.position.x - 10.0, 260.0, 500.0)
	info.size = Vector2(info_w, 250)
	board.add_child(info)
	var focus: Array = [close]
	focus.append_array(pins)
	UIKit.link_focus(focus)
	_show_info("")


func _at(p: Vector2) -> Vector2:
	return p * fit


func _draw_board() -> void:
	for blob in data.get("green", []):
		board.draw_circle(_at(Vector2(float(blob.get("x", 0)), float(blob.get("y", 0)))), float(blob.get("r", 40)) * fit, Color("C9DDB0"))
	for pool in data.get("water", []):
		board.draw_circle(_at(Vector2(float(pool.get("x", 0)), float(pool.get("y", 0)))), float(pool.get("r", 40)) * fit, Color("A9CCDD"))
	for road in data.get("roads", []):
		var points := PackedVector2Array()
		for p in road:
			points.append(_at(Vector2(float(p[0]), float(p[1]))))
		board.draw_polyline(points, Color("D8C9A8"), 34.0 * fit, true)
		board.draw_polyline(points, Color("F6EEDC"), 4.0 * fit, true)
	# Drive routes from the current office to each client, dotted.
	var home := _place_for_office(GameState.office_id)
	if not home.is_empty():
		var from := _at(Vector2(float(home.get("x", 0)), float(home.get("y", 0))))
		for place in data.get("places", []):
			if str(place.get("kind", "")) != "client":
				continue
			var to := _at(Vector2(float(place.get("x", 0)), float(place.get("y", 0))))
			var steps := int(from.distance_to(to) / 18.0)
			for i in range(1, steps):
				var t := float(i) / float(steps)
				board.draw_circle(from.lerp(to, t), 3.0, Color(UIKit.TERRA, 0.45))


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
	var btn := UIKit.button(str(place.get("name", id)), fill, fg)
	btn.name = "Pin_" + id
	btn.custom_minimum_size = Vector2(240, 52)
	btn.size = Vector2(240, 52)
	var at := _at(Vector2(float(place.get("x", 0)), float(place.get("y", 0))))
	btn.pressed.connect(func(): _show_info(id))
	board.add_child(btn)
	var width := maxf(240.0, btn.get_combined_minimum_size().x)
	btn.size.x = width
	btn.position = Vector2(clampf(at.x - width * 0.5, 0.0, board.size.x - width), clampf(at.y - 26.0, 0.0, board.size.y - 52.0))
	var dot := ColorRect.new()
	dot.color = UIKit.DARK
	dot.size = Vector2(14, 14)
	dot.position = Vector2(at.x - 7, minf(at.y + 30, board.size.y - 14))
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(dot)
	return btn


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
	for child in info.get_children():
		child.queue_free()
	var place := _place(id)
	if place.is_empty():
		var hint := UIKit.label("Dana's corner of town. Roads lead from the office to every client.", 18, UIKit.DARK)
		hint.custom_minimum_size = Vector2(info_w - 20.0, 0)
		info.add_child(hint)
		_board_rows()
		return
	var name_row := UIKit.label(str(place.get("name", "")), 28, UIKit.TERRA, "title", false)
	info.add_child(name_row)
	var blurb := UIKit.label(str(place.get("blurb", "")), 18, UIKit.DARK)
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
		var line := UIKit.label(status, 18, UIKit.DARK)
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
		if shown > 3:
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
