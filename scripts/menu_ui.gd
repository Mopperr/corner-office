extends Control

signal new_game(character)
signal continue_game

var panel: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioDirector.play_music("music_main_menu")
	_home()


func _home() -> void:
	_clear()
	var card := Panel.new()
	card.position = Vector2(48, 40)
	card.size = Vector2(640, 640)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 22))
	add_child(card)
	var title := UIKit.label("Corner Office", 72, UIKit.DARK, "title", false)
	title.position = Vector2(80, 70)
	title.size = Vector2(700, 90)
	title.custom_minimum_size = Vector2(700, 90)
	add_child(title)
	var sub := UIKit.label("Pack the old office. Make the new one yours.", 22, UIKit.DARK)
	sub.position = Vector2(84, 160)
	sub.size = Vector2(640, 40)
	add_child(sub)
	var column := VBoxContainer.new()
	column.position = Vector2(84, 230)
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var play := UIKit.button("New game", UIKit.TERRA)
	play.custom_minimum_size = Vector2(320, 54)
	play.pressed.connect(func(): _intro(GameState.slice_character_id()))
	column.add_child(play)
	var cont := UIKit.button("Continue", UIKit.SAGE)
	cont.custom_minimum_size = Vector2(320, 54)
	cont.disabled = not SaveManager.has_save()
	cont.pressed.connect(func(): emit_signal("continue_game"))
	column.add_child(cont)
	var how := UIKit.button("How to play", UIKit.BLUE)
	how.custom_minimum_size = Vector2(320, 54)
	how.pressed.connect(_how)
	column.add_child(how)
	var settings := UIKit.button("Settings", UIKit.WOOD, UIKit.CREAM_CARD)
	settings.custom_minimum_size = Vector2(320, 54)
	settings.pressed.connect(_settings)
	column.add_child(settings)
	var credits := UIKit.button("Credits", UIKit.MUSTARD, UIKit.DARK)
	credits.custom_minimum_size = Vector2(320, 54)
	credits.pressed.connect(_credits)
	column.add_child(credits)
	var quit := UIKit.button("Quit", UIKit.DARK)
	quit.custom_minimum_size = Vector2(320, 54)
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)


func _intro(character: String) -> void:
	_clear()
	var card := Panel.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -420
	card.offset_top = -260
	card.offset_right = 420
	card.offset_bottom = 260
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CARD, 20))
	add_child(card)
	var text := _read_text("res://data/narrative/intro.md")
	text = text.replace("# Intro", "").strip_edges()
	var body := UIKit.label(text, 22, UIKit.DARK)
	body.position = Vector2(36, 36)
	body.size = Vector2(760, 360)
	card.add_child(body)
	var go := UIKit.button("Put the kettle on", UIKit.TERRA)
	go.position = Vector2(280, 430)
	go.size = Vector2(280, 54)
	go.pressed.connect(func(): emit_signal("new_game", character))
	card.add_child(go)


func _how() -> void:
	var lines: PackedStringArray = []
	var copy := _json_file("res://data/narrative/how_to_play.json")
	for tip in copy.get("tips", []):
		var title := str(tip.get("title", ""))
		var body := str(tip.get("body", ""))
		if title == "":
			continue
		lines.append("%s\n%s" % [title, body])
	if lines.is_empty():
		lines.append("Click an item to pack it, then click a floor, desk, or box to place it.")
	_sheet("How to play", "\n\n".join(lines))


func _settings() -> void:
	_clear()
	_sheet_card()
	_back_button()
	var title := UIKit.label("Settings", 48, UIKit.DARK, "title")
	title.position = Vector2(80, 80)
	add_child(title)
	_slider("Music", SaveManager.music_linear, 180, func(v):
		SaveManager.music_linear = v
		AudioDirector.apply_volumes()
		SaveManager.save_settings()
	)
	_slider("Effects", SaveManager.sfx_linear, 280, func(v):
		SaveManager.sfx_linear = v
		AudioDirector.apply_volumes()
		SaveManager.save_settings()
		AudioDirector.play_sfx("sfx_ui_click")
	)
	var snap := CheckBox.new()
	snap.text = "Snap to 0.25 m grid"
	snap.button_pressed = SaveManager.snap_to_grid
	snap.position = Vector2(80, 380)
	snap.size = Vector2(420, 36)
	snap.add_theme_font_override("font", UIKit.body_font())
	snap.add_theme_font_size_override("font_size", 22)
	snap.add_theme_color_override("font_color", UIKit.DARK)
	snap.add_theme_color_override("font_hover_color", UIKit.DARK)
	snap.toggled.connect(func(on):
		SaveManager.snap_to_grid = on
		SaveManager.save_settings()
	)
	add_child(snap)


func _slider(caption: String, value: float, y: float, on_change: Callable) -> void:
	var label := UIKit.label(caption, 22, UIKit.DARK, "title")
	label.position = Vector2(80, y)
	add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value * 100.0
	slider.position = Vector2(280, y)
	slider.size = Vector2(420, 32)
	slider.value_changed.connect(func(v): on_change.call(float(v) / 100.0))
	add_child(slider)


func _credits() -> void:
	var lines: PackedStringArray = []
	var copy := _json_file("res://data/narrative/credits.json")
	var headline := str(copy.get("headline", "Created by Andrew's Helpers (Grok Bots)"))
	for person in copy.get("people", []):
		var who := str(person.get("name", ""))
		var role := str(person.get("role", ""))
		if who == "":
			continue
		if role == "":
			lines.append(who)
		else:
			lines.append("%s (%s)" % [who, role])
	var audio := _read_text("res://assets/audio/credits.md")
	var body := "\n".join(lines)
	body += "\n\nFonts: Fredoka, Nunito, and VT323, used under the SIL Open Font License. See assets/fonts/OFL.txt."
	if audio != "":
		body += "\n\n" + audio
	_sheet(headline, body)


func _sheet(title_text: String, body_text: String) -> void:
	_clear()
	_sheet_card()
	_back_button()
	var title := UIKit.label(title_text, 42, UIKit.DARK, "title")
	title.position = Vector2(80, 70)
	add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 140)
	scroll.size = Vector2(1080, 520)
	add_child(scroll)
	var body := UIKit.label(body_text, 16, UIKit.DARK)
	body.custom_minimum_size = Vector2(1040, 0)
	scroll.add_child(body)


func _sheet_card() -> void:
	var card := Panel.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 40
	card.offset_top = 12
	card.offset_right = -40
	card.offset_bottom = -12
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	add_child(card)


func _back_button() -> void:
	var back := UIKit.button("Back", UIKit.DARK)
	back.position = Vector2(80, 20)
	back.size = Vector2(120, 44)
	back.pressed.connect(_home)
	add_child(back)


func _clear() -> void:
	for child in get_children():
		child.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _json_file(path: String) -> Dictionary:
	var text := _read_text(path)
	if text == "":
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
