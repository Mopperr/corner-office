extends Control

const Tuning = preload("res://scripts/tuning.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

signal closed

var shown := 0
var lines: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(_center_card)
	AudioDirector.play_music("music_office_build")
	var pay: Dictionary = GameState.payout
	lines = [
		"Base pay  $%d" % int(pay.get("base", 0)),
		"Box tip  $%d" % int(pay.get("box_tip", 0)),
	]
	var room_score := float(pay.get("room_score", -1.0))
	if room_score >= 0.0:
		lines.append("Room setup %d/100 +$%d" % [int(round(room_score)), int(pay.get("room_tip", 0))])
	if int(pay.get("shortcut", 0)) > 0:
		lines.append("Shortcut  +$%d" % int(pay.get("shortcut", 0)))
	if int(pay.get("bonuses", 0)) > 0:
		var extra := "Bonuses  $%d" % int(pay.get("bonuses", 0))
		if bool(pay.get("cat", false)):
			extra += "   Cat"
		if bool(pay.get("duck", false)):
			extra += "   Duck Friend"
		lines.append(extra)
	if int(pay.get("honks", 0)) > 0:
		lines.append("Friendly honks  +$%d" % int(pay.get("honk_pay", 0)))
	if int(pay.get("split_loss", 0)) > 0:
		lines.append("Split sets  −$%d" % int(pay.get("split_loss", 0)))
	if int(pay.get("cut", 0)) > 0:
		lines.append("Kept damage  −$%d from tips" % int(pay.get("cut", 0)))
	else:
		lines.append("Damage cut  $0")
	lines.append("Tips you keep  $%d" % int(pay.get("net_tips", 0)))
	lines.append("You take home  $%d" % int(pay.get("total", 0)))
	var stamps := []
	if str(pay.get("stamp", "")) != "":
		stamps.append(pay.get("stamp"))
	if bool(pay.get("all_fine", false)):
		stamps.append("Careful Hands")
	if bool(pay.get("cat", false)):
		stamps.append("Cat")
	if bool(pay.get("duck", false)):
		stamps.append("Duck Friend")
	if float(pay.get("room_score", -1.0)) >= float(Tuning.get_value("stacking.room_complete", 90.0)):
		stamps.append("ROOM COMPLETE")
	if not stamps.is_empty():
		var packed := PackedStringArray()
		for stamp in stamps:
			packed.append(str(stamp))
		lines.append("Stamps: " + ", ".join(packed))
	lines.append("Rep stars +%d   (rank %d)" % [int(pay.get("stars", 1)), GameState.rep_rank()])
	var condition := int(pay.get("condition", 100))
	var def: Dictionary = GameState.job.get("def", {})
	var client := str(def.get("client", "the client"))
	if condition >= 90:
		lines.append("%s walks the room twice and says nothing, which is the good kind of nothing." % client)
	elif condition >= 70:
		lines.append("%s finds the scuff, shrugs, and puts the kettle on." % client)
	else:
		lines.append("%s says 'well' in a way that means several things." % client)
	lines.append("Jobs done: %d.  Jar: $%d." % [GameState.jobs_done, GameState.money])
	_build()
	_center_card()
	_reveal()


func _center_card() -> void:
	var card := get_node_or_null("Card") as Control
	if card == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 8.0 or vp.y < 8.0:
		vp = Vector2(1280, 720)
	layout_mode = 0
	position = Vector2.ZERO
	size = vp
	var card_size := Vector2(860, 680)
	if vp.y < card_size.y + 16.0:
		card_size.y = maxf(360.0, vp.y - 16.0)
	if vp.x < card_size.x + 16.0:
		card_size.x = maxf(480.0, vp.x - 16.0)
	card.layout_mode = 1
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_left = -card_size.x * 0.5
	card.offset_top = -card_size.y * 0.5
	card.offset_right = card_size.x * 0.5
	card.offset_bottom = card_size.y * 0.5
	card.position = (vp - card_size) * 0.5
	card.size = card_size


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NIGHT, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	UIKit.fill(dim, 0, 0, 0, 0)
	var card := Panel.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(860, 680)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	add_child(card)
	var title := UIKit.label(str(GameState.payout.get("title", "Job done")), 40, UIKit.DARK, "title", false)
	title.position = Vector2(36, 20)
	title.size = Vector2(780, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var stars := int(GameState.payout.get("stars", 1))
	var star_row := UIKit.label("★".repeat(clampi(stars, 0, 3)) + "☆".repeat(3 - clampi(stars, 0, 3)), 44, UIKit.MUSTARD, "title", false)
	star_row.position = Vector2(36, 76)
	star_row.size = Vector2(780, 56)
	star_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(star_row)
	var y := 136.0
	var step := 40.0
	for i in lines.size():
		var is_story := i >= lines.size() - 2
		var row := UIKit.label(lines[i], 24 if is_story else 30, UIKit.BLUE if is_story else UIKit.DARK, "small" if is_story else "body", is_story)
		row.position = Vector2(40, y)
		row.size = Vector2(780, 44 if not is_story else 80)
		if not is_story:
			row.custom_minimum_size = Vector2(minf(760.0, maxf(180.0, float(str(lines[i]).length()) * 17.0)), 40)
		else:
			row.custom_minimum_size = Vector2(760, 0)
			row.max_lines_visible = 2
		row.modulate.a = 0.0
		row.name = "Line%d" % i
		card.add_child(row)
		y += step if not is_story else 64
	var btn := UIKit.button("Back to the office", UIKit.SAGE)
	btn.position = Vector2(250, 604)
	btn.size = Vector2(360, 56)
	btn.custom_minimum_size = Vector2(360, 56)
	btn.pressed.connect(func():
		GameState.job = {}
		GameState.payout = {}
		GameState.set_mode("office")
		SaveManager.save_game()
		emit_signal("closed")
	)
	card.add_child(btn)
	UIKit.link_focus([btn])


func _reveal() -> void:
	var card := get_child(1)
	for i in lines.size():
		var row := card.get_node_or_null("Line%d" % i)
		if row == null:
			continue
		var tw := create_tween()
		tw.tween_interval(0.28 * float(i))
		tw.tween_property(row, "modulate:a", 1.0, 0.25)
		if i == lines.size() - 2:
			tw.tween_callback(func(): AudioDirector.play_sfx("sfx_cash_gain"))
