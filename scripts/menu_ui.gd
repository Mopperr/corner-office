extends Control

const Graphics = preload("res://scripts/settings_manager.gd")
const UIKit = preload("res://scripts/ui_kit.gd")
const Controls = preload("res://scripts/control_map.gd")

signal new_game(character)
signal continue_game

var panel: Control
var _listen := ""
var _sheet_title := ""
var _sheet_lines: PackedStringArray = PackedStringArray()
var _sheet_page := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_mode = 1
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AudioDirector.play_music("music_main_menu")
	_home()


func _unhandled_input(event: InputEvent) -> void:
	if _listen == "":
		return
	if event == null or not event.pressed or event.is_echo():
		return
	if event is InputEventKey:
		Controls.set_key(_listen, (event as InputEventKey).keycode)
	elif event is InputEventJoypadButton:
		Controls.set_joy(_listen, (event as InputEventJoypadButton).button_index)
	else:
		return
	_listen = ""
	SaveManager.save_settings()
	get_viewport().set_input_as_handled()
	_controls()


func _home() -> void:
	_listen = ""
	_clear()
	var center := UIKit.center_screen(self, "HomeCenter")
	var card := Panel.new()
	card.name = "HomeCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(880, 640)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 22))
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "HomeColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := UIKit.ribbon("Corner Office", UIKit.TERRA, 72)
	title.custom_minimum_size = Vector2(720, 104)
	title.rotation_degrees = -1.5
	title.pivot_offset = Vector2(360, 52)
	# The title sways a degree either way, slowly, like a hung sign.
	var sway := title.create_tween().set_loops()
	sway.tween_property(title, "rotation_degrees", 1.2, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(title, "rotation_degrees", -1.5, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	column.add_child(title)
	var sub := UIKit.label("Pack the old office. Make the new one yours.", 32, UIKit.DARK, "body", false)
	sub.custom_minimum_size = Vector2(720, 48)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	var buttons: Array = []
	buttons.append(_menu_button(column, "New game", UIKit.TERRA, _choose))
	var cont := _menu_button(column, "Continue", UIKit.SAGE, func(): emit_signal("continue_game"))
	cont.disabled = not SaveManager.has_save()
	buttons.append(cont)
	buttons.append(_menu_button(column, "How to play", UIKit.BLUE, _how))
	buttons.append(_menu_button(column, "Settings", UIKit.WOOD, _settings))
	buttons.append(_menu_button(column, "Credits", UIKit.MUSTARD, _credits, UIKit.DARK))
	buttons.append(_menu_button(column, "Quit", UIKit.DARK, func(): UIKit.request_quit(get_tree())))
	UIKit.link_focus(buttons)
	UIKit.pop_in(card)


func _menu_button(column: VBoxContainer, text: String, fill: Color, on_press: Callable, fg: Color = UIKit.CREAM_CARD) -> Button:
	var btn := UIKit.button(text, fill, fg)
	btn.custom_minimum_size = Vector2(720, 56)
	btn.pressed.connect(on_press)
	column.add_child(btn)
	return btn


# The two perks whose full wording runs past a row; the whole text is in the
# record and on the intro card.
const SHORT_PERK := {
	"dana": "The Market chart shows yesterday's price as a dotted line.",
	"sol": "The Cat Cafe job from day one; Biscuit always leaves a pawprint photo.",
}


func _choose() -> void:
	# Who runs Corner Office: five rows, a face, a line, a perk and a start.
	_listen = ""
	_clear()
	var center := UIKit.center_screen(self, "ChooseCenter")
	var card := Panel.new()
	card.name = "ChooseCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(1240, 720)
	card.size = Vector2(1240, 720)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 16)
	column.add_child(head)
	var title := UIKit.ribbon("Who's moving in?", UIKit.TERRA, 36)
	title.custom_minimum_size = Vector2(420, 46)
	head.add_child(title)
	var lead := UIKit.label("Five people, one garage, five perks.", 18, UIKit.WOOD, "small", false)
	lead.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lead.custom_minimum_size = Vector2(540, 46)
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lead.clip_text = true
	head.add_child(lead)
	# Back lives in the head row, so the five rows get the height.
	var back := UIKit.button("Back", UIKit.DARK)
	back.custom_minimum_size = Vector2(160, 44)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_home)
	head.add_child(back)
	var buttons: Array = []
	var fills := {"dana": UIKit.TERRA, "sol": Color("4F8A8B"), "hank": UIKit.WOOD, "milo": UIKit.MUSTARD, "bea": UIKit.SAGE}
	for who in GameState.playable_characters():
		var id := str(who["id"])
		var tile := PanelContainer.new()
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.custom_minimum_size = Vector2(1200, 0)
		var tile_style := UIKit.style(Color("F8F3E8"), 12, 3, fills.get(id, UIKit.TERRA))
		tile_style.content_margin_top = 5
		tile_style.content_margin_bottom = 5
		tile_style.content_margin_left = 12
		tile_style.content_margin_right = 12
		tile.add_theme_stylebox_override("panel", tile_style)
		column.add_child(tile)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 14)
		tile.add_child(row)
		# Every row gets the same initial on a disc, Dana included.
		var face: Control = UIKit.avatar(str(who["name"]).left(1), fills.get(id, UIKit.TERRA), 56)
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(face)
		var who_col := VBoxContainer.new()
		who_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		who_col.add_theme_constant_override("separation", 2)
		who_col.custom_minimum_size = Vector2(980, 0)
		who_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(who_col)
		var head_row := HBoxContainer.new()
		head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head_row.add_theme_constant_override("separation", 16)
		who_col.add_child(head_row)
		var name_tag := UIKit.label(str(who["name"]), 22, UIKit.DARK, "title", false)
		name_tag.custom_minimum_size = Vector2(260, 30)
		head_row.add_child(name_tag)
		var perk := UIKit.label("Perk: %s" % who["perk"], 18, fills.get(id, UIKit.TERRA), "title", false)
		perk.custom_minimum_size = Vector2(300, 30)
		head_row.add_child(perk)
		var start := UIKit.label("$%d to start" % int(who["money"]), 18, UIKit.WOOD, "small", false)
		start.custom_minimum_size = Vector2(140, 30)
		start.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head_row.add_child(start)
		var pitch := UIKit.label(str(who["pitch"]), 16, UIKit.DARK, "small", false)
		pitch.custom_minimum_size = Vector2(980, 0)
		pitch.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		who_col.add_child(pitch)
		var perk_desc := UIKit.label(str(SHORT_PERK.get(id, who["perk_desc"])), 16, UIKit.WOOD, "small", false)
		perk_desc.custom_minimum_size = Vector2(980, 0)
		perk_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		who_col.add_child(perk_desc)
		var pick := UIKit.button("Play", fills.get(id, UIKit.TERRA), UIKit.DARK if id in ["milo", "bea"] else UIKit.CREAM_CARD)
		pick.name = "Pick_" + id
		pick.custom_minimum_size = Vector2(112, 46)
		pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pick.pressed.connect(func(): _intro(id))
		row.add_child(pick)
		buttons.append(pick)
	buttons.append(back)
	UIKit.link_focus(buttons)
	UIKit.pop_in(card)


func _intro(character: String) -> void:
	_listen = ""
	_clear()
	var center := UIKit.center_screen(self, "IntroCenter")
	var card := Panel.new()
	card.name = "Intro"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(1080, 780)
	card.size = Vector2(1080, 780)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)
	var row_box := HBoxContainer.new()
	row_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_theme_constant_override("separation", 24)
	margin.add_child(row_box)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_box.add_child(column)
	# Dana herself, box in hand, from the team's painted select card.
	var select_path := "res://assets/characters/dana/portraits/dana_select_full@1x.png"
	if character == "dana" and ResourceLoader.exists(select_path):
		var pic := TextureRect.new()
		pic.name = "DanaSelect"
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.texture = load(select_path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(200, 480)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row_box.add_child(pic)
	var text := _read_text("res://data/narrative/intro.md")
	text = text.replace("# Intro", "").strip_edges()
	if character != "dana":
		# Their own story in place of Dana's.
		var rec: Dictionary = {}
		for who in GameState.playable_characters():
			if str(who["id"]) == character:
				rec = who
		if not rec.is_empty():
			text = "You are %s. %s\n\n%s\n\nThe garage is yours for now. $%d in the jar, %s on your side, and a lot of potential.\n\nNobody's rushing you. Put the kettle on." % [rec["name"], rec["pitch"], rec["backstory"], int(rec["money"]), rec["perk"]]
	for para in text.split("\n\n"):
		var bit := para.strip_edges()
		if bit == "":
			continue
		var row := UIKit.label(bit, 22, UIKit.DARK)
		row.custom_minimum_size = Vector2(770, 36)
		column.add_child(row)
	var go := UIKit.button("Put the kettle on", UIKit.TERRA)
	go.custom_minimum_size = Vector2(360, 56)
	go.pressed.connect(func(): emit_signal("new_game", character))
	column.add_child(go)
	UIKit.link_focus([go])


func _how() -> void:
	var lines: PackedStringArray = []
	var copy := _json_file("res://data/narrative/how_to_play.json")
	for tip in copy.get("tips", []):
		var title := str(tip.get("title", ""))
		var body := str(tip.get("body", ""))
		if title == "":
			continue
		lines.append(title)
		for bit in _wrap_lines(body, 42):
			lines.append(bit)
		lines.append("")
	if lines.is_empty():
		lines.append("Click an item to pack it, then click a floor, desk, or box to place it.")
	_open_sheet("How to play", lines)


func _settings() -> void:
	_listen = ""
	_clear()
	var center := UIKit.center_screen(self, "SettingsCenter")
	var card := _page_card(center, "SettingsCard", Vector2(920, 720))
	var column := _page_column(card)
	var buttons: Array = []
	var back := _menu_button(column, "Back", UIKit.DARK, _home)
	back.custom_minimum_size = Vector2(200, 56)
	buttons.append(back)
	var title := UIKit.label("Settings", 48, UIKit.DARK, "title", false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var music := _slider_row(column, "Music", SaveManager.music_linear, func(v):
		SaveManager.music_linear = v
		AudioDirector.apply_volumes()
		SaveManager.save_settings()
	)
	buttons.append(music)
	var effects := _slider_row(column, "Effects", SaveManager.sfx_linear, func(v):
		SaveManager.sfx_linear = v
		AudioDirector.apply_volumes()
		SaveManager.save_settings()
		AudioDirector.play_sfx("sfx_ui_click")
	)
	buttons.append(effects)
	var snap := CheckBox.new()
	snap.text = "Snap to 0.25 m grid"
	snap.button_pressed = SaveManager.snap_to_grid
	snap.focus_mode = Control.FOCUS_ALL
	snap.custom_minimum_size = Vector2(720, 56)
	snap.add_theme_font_override("font", UIKit.body_font())
	snap.add_theme_font_size_override("font_size", UIKit.font_px(28))
	snap.add_theme_color_override("font_color", UIKit.DARK)
	snap.add_theme_color_override("font_hover_color", UIKit.DARK)
	snap.add_theme_color_override("font_focus_color", UIKit.DARK)
	snap.add_theme_stylebox_override("normal", UIKit.style(UIKit.CREAM, 12, 2, UIKit.DARK))
	snap.add_theme_stylebox_override("hover", UIKit.style(UIKit.CREAM_CARD, 12, 3, UIKit.WOOD))
	snap.add_theme_stylebox_override("focus", UIKit.style(UIKit.CREAM_CARD, 12, 4, UIKit.MUSTARD))
	snap.add_theme_stylebox_override("pressed", UIKit.style(UIKit.CREAM, 12, 2, UIKit.DARK))
	snap.toggled.connect(func(on):
		SaveManager.snap_to_grid = on
		SaveManager.save_settings()
	)
	column.add_child(snap)
	buttons.append(snap)
	var quality_row := HBoxContainer.new()
	quality_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quality_row.add_theme_constant_override("separation", 16)
	column.add_child(quality_row)
	var quality_label := UIKit.label("Quality", 28, UIKit.DARK, "title", false)
	quality_label.custom_minimum_size = Vector2(220, 56)
	quality_row.add_child(quality_label)
	var quality := OptionButton.new()
	quality.focus_mode = Control.FOCUS_ALL
	quality.custom_minimum_size = Vector2(420, 56)
	quality.add_theme_font_override("font", UIKit.body_font())
	quality.add_theme_font_size_override("font_size", UIKit.font_px(28))
	quality.add_theme_color_override("font_color", UIKit.DARK)
	quality.add_theme_color_override("font_hover_color", UIKit.DARK)
	quality.add_theme_color_override("font_focus_color", UIKit.DARK)
	quality.add_theme_stylebox_override("normal", UIKit.style(UIKit.CREAM, 12, 2, UIKit.DARK))
	quality.add_theme_stylebox_override("hover", UIKit.style(UIKit.CREAM_CARD, 12, 3, UIKit.WOOD))
	quality.add_theme_stylebox_override("focus", UIKit.style(UIKit.CREAM_CARD, 12, 4, UIKit.MUSTARD))
	quality.add_theme_stylebox_override("pressed", UIKit.style(UIKit.CREAM, 12, 2, UIKit.DARK))
	quality.add_item("Low")
	quality.add_item("Medium")
	quality.add_item("High")
	var tiers := ["low", "medium", "high"]
	var selected := tiers.find(SaveManager.graphics_quality)
	quality.selected = selected if selected >= 0 else 1
	quality.item_selected.connect(func(index: int):
		SaveManager.graphics_quality = tiers[index]
		SaveManager.save_settings()
		Graphics.apply_tier(get_tree(), SaveManager.graphics_quality)
	)
	quality_row.add_child(quality)
	buttons.append(quality)
	buttons.append(_menu_button(column, "Controls", UIKit.BLUE, _controls))
	UIKit.link_focus(buttons)


func _slider_row(column: VBoxContainer, caption: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var caption_label := UIKit.label(caption, 28, UIKit.DARK, "title", false)
	caption_label.custom_minimum_size = Vector2(220, 56)
	row.add_child(caption_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value * 100.0
	slider.focus_mode = Control.FOCUS_ALL
	slider.custom_minimum_size = Vector2(460, 56)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v): on_change.call(float(v) / 100.0))
	row.add_child(slider)
	return slider


func _controls() -> void:
	_clear()
	var center := UIKit.center_screen(self, "RemapCenter")
	var card := _page_card(center, "RemapCard", Vector2(920, 720))
	var column := _page_column(card)
	column.add_theme_constant_override("separation", 4)
	var buttons: Array = []
	var back := _menu_button(column, "Back", UIKit.DARK, _settings)
	back.custom_minimum_size = Vector2(200, 48)
	buttons.append(back)
	var title := UIKit.label("Controls", 36, UIKit.DARK, "title", false)
	title.name = "RemapTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var hint := UIKit.label("Click a row, then press a key or a gamepad button.", 36, UIKit.DARK)
	hint.custom_minimum_size = Vector2(760, 48)
	column.add_child(hint)
	var focus_row: Button = null
	# Two columns, so ten bindings still fit a 1280x800 window.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	var rows: Array = []
	var pair: Array = []
	for spec in Controls.specs():
		var id := str(spec.get("id", ""))
		var caption := str(spec.get("label", id))
		var shown := "Press a key or button" if _listen == id else "%s    %s" % [caption, Controls.describe(id)]
		var row := UIKit.button(shown, UIKit.SAGE if _listen != id else UIKit.MUSTARD, UIKit.CREAM_CARD if _listen != id else UIKit.DARK)
		row.custom_minimum_size = Vector2(376, 48)
		row.pressed.connect(_arm_remap.bind(id))
		row.set_meta("action", id)
		grid.add_child(row)
		pair.append(row)
		if pair.size() == 2:
			rows.append(pair)
			pair = []
		if _listen == id:
			focus_row = row
	if not pair.is_empty():
		rows.append(pair)
	var grid_rows: Array = [[back]]
	grid_rows.append_array(rows)
	UIKit.link_grid(grid_rows)
	if focus_row != null:
		focus_row.grab_focus()


func _arm_remap(id: String) -> void:
	_listen = id
	_controls()


func _credits() -> void:
	AudioDirector.play_music("music_credits_reprise")
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
	lines.append("")
	lines.append("Fonts: Fredoka, Nunito, and VT323, SIL Open Font License.")
	var audio := _read_text("res://assets/audio/credits.md")
	if audio != "":
		for bit in _wrap_lines(audio, 42):
			lines.append(bit)
	_open_sheet(headline, lines)


func _open_sheet(title_text: String, lines: PackedStringArray) -> void:
	_sheet_title = title_text
	_sheet_lines = lines
	_sheet_page = 0
	_show_sheet()


func _show_sheet() -> void:
	_listen = ""
	_clear()
	var center := UIKit.center_screen(self, "SheetCenter")
	var card := _page_card(center, "SheetCard", Vector2(1180, 760))
	var column := _page_column(card)
	var buttons: Array = []
	var back := _menu_button(column, "Back", UIKit.DARK, _home)
	back.custom_minimum_size = Vector2(200, 56)
	buttons.append(back)
	var title := UIKit.label(_sheet_title, 36, UIKit.DARK, "title", false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(title)
	var start := _sheet_page * 7
	var shown := 0
	while start + shown < _sheet_lines.size() and shown < 7:
		var line := _sheet_lines[start + shown]
		var row := UIKit.label(line if line != "" else " ", 36, UIKit.DARK, "body", false)
		var wide := minf(1040.0, maxf(180.0, float(line.length()) * 22.0))
		row.custom_minimum_size = Vector2(wide, 44)
		column.add_child(row)
		shown += 1
	if _sheet_lines.size() > 7:
		var more := _menu_button(column, "Next page", UIKit.BLUE, _next_sheet)
		buttons.append(more)
	UIKit.link_focus(buttons)


func _next_sheet() -> void:
	var pages := maxi(1, int(ceil(float(_sheet_lines.size()) / 7.0)))
	_sheet_page = (_sheet_page + 1) % pages
	_show_sheet()


func _page_card(center: CenterContainer, card_name: String, min_size: Vector2) -> Panel:
	var card := Panel.new()
	card.name = card_name
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = min_size
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	center.add_child(card)
	return card


func _page_column(card: Panel) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column


func _clear() -> void:
	for child in get_children():
		child.queue_free()


func _wrap_lines(text: String, width: int) -> PackedStringArray:
	var lines := PackedStringArray()
	for raw in text.split("\n"):
		var words := raw.strip_edges().split(" ", false)
		if words.is_empty():
			lines.append("")
			continue
		var line := ""
		for word in words:
			var next := word if line == "" else "%s %s" % [line, word]
			if next.length() > width and line != "":
				lines.append(line)
				line = word
			else:
				line = next
		if line != "":
			lines.append(line)
	return lines


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
