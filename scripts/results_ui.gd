extends Control

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
	var card_size := Vector2(720, 560)
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
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := Panel.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(720, 560)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	add_child(card)
	var title := UIKit.label(str(GameState.payout.get("title", "Job done")), 36, UIKit.DARK, "title")
	title.position = Vector2(28, 18)
	title.size = Vector2(640, 48)
	card.add_child(title)
	var y := 78.0
	var step := 34.0 if lines.size() > 9 else 40.0
	for i in lines.size():
		var row := UIKit.label(lines[i], 22, UIKit.DARK)
		row.position = Vector2(32, y)
		row.size = Vector2(640, 36)
		row.modulate.a = 0.0
		row.name = "Line%d" % i
		card.add_child(row)
		y += step
	var btn := UIKit.button("Back to the office", UIKit.SAGE)
	btn.position = Vector2(200, 500)
	btn.size = Vector2(280, 52)
	btn.pressed.connect(func():
		GameState.job = {}
		GameState.payout = {}
		GameState.set_mode("office")
		SaveManager.save_game()
		emit_signal("closed")
	)
	card.add_child(btn)


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
