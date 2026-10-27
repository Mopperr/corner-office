class_name UIKit
extends RefCounted

const CREAM := Color("F4E9D8")
const CREAM_CARD := Color("FFF8EC")
const WOOD := Color("C68B59")
const DARK := Color("6B4A3A")
const CARD := Color("D9A86C")
const SAGE := Color("8FAF7E")
const TERRA := Color("D9765F")
const MUSTARD := Color("E6B655")
const BLUE := Color("7FA3B8")
const NIGHT := Color("3E3A4F")
const GREEN := Color("6DBF73")
const LOSS := Color("E0675C")
const PINK := Color("E8B4A8")
# Invalid ghosts use this soft red. LOSS is the trading color only.
const SOFT_RED := Color("E8B4A8")
const SCREEN := Color("243832")
# Nothing on a menu is smaller than 28px. Paragraphs and row copy use 36px.
const MIN_FONT := 28
const BODY_FONT := 36
# Secondary copy (key captions, chat lines, card footers) may go down to 27px:
# that is 18px on a 1280x800 Deck, the floor the README promises.
const SMALL_FONT := 27

static var quit_enabled := true


static func font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return ThemeDB.fallback_font


static func title_font() -> Font:
	return font("res://assets/fonts/Fredoka-SemiBold.ttf")


static func body_font() -> Font:
	return font("res://assets/fonts/Nunito-SemiBold.ttf")


static func body_bold() -> Font:
	return font("res://assets/fonts/Nunito-Bold.ttf")


static func crt_font() -> Font:
	return font("res://assets/fonts/VT323-Regular.ttf")


static func style(color: Color, radius := 14, border := -1, border_color: Color = DARK) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	if border >= 0:
		box.border_width_left = border
		box.border_width_right = border
		box.border_width_top = border
		box.border_width_bottom = border
		box.border_color = border_color
	box.shadow_color = Color(NIGHT, 0.18)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 3)
	return box


static func request_quit(tree: SceneTree) -> void:
	if quit_enabled and tree != null:
		tree.quit()


static func button(text: String, fill: Color = SAGE, fg: Color = CREAM_CARD) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_ALL
	btn.custom_minimum_size = Vector2(48, 56)
	btn.add_theme_font_override("font", title_font())
	btn.add_theme_font_size_override("font_size", font_px(28))
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style(fill, 18))
	btn.add_theme_stylebox_override("hover", style(fill.lightened(0.08), 18, 3, CREAM_CARD))
	btn.add_theme_stylebox_override("pressed", style(fill.darkened(0.08), 18))
	btn.add_theme_stylebox_override("focus", style(fill.lightened(0.12), 18, 4, MUSTARD))
	btn.add_theme_stylebox_override("disabled", style(Color(fill, 0.45), 18))
	btn.add_theme_color_override("font_disabled_color", Color(fg, 0.7))
	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		AudioDirector.play_sfx("sfx_ui_hover")
	)
	btn.pressed.connect(func(): AudioDirector.play_sfx("sfx_ui_click"))
	return btn


static func icon_button(icon_path: String, caption: String) -> Button:
	var btn := Button.new()
	btn.text = caption
	btn.focus_mode = Control.FOCUS_ALL
	btn.custom_minimum_size = Vector2(104, 96)
	btn.add_theme_font_override("font", crt_font())
	btn.add_theme_font_size_override("font_size", font_px(28))
	btn.add_theme_color_override("font_color", CREAM_CARD)
	btn.add_theme_color_override("font_hover_color", MUSTARD)
	btn.add_theme_color_override("font_focus_color", MUSTARD)
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		btn.icon = tex
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 48)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var solid := Color("1B2A24")
	btn.add_theme_stylebox_override("normal", style(solid, 10, 2, BLUE))
	btn.add_theme_stylebox_override("hover", style(solid.lightened(0.12), 10, 3, CREAM_CARD))
	btn.add_theme_stylebox_override("pressed", style(solid.darkened(0.08), 10))
	btn.add_theme_stylebox_override("focus", style(solid.lightened(0.16), 10, 4, MUSTARD))
	btn.add_theme_stylebox_override("disabled", style(Color(solid, 0.45), 10))
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.mouse_entered.connect(func(): AudioDirector.play_sfx("sfx_ui_hover"))
	btn.pressed.connect(func(): AudioDirector.play_sfx("sfx_ui_click"))
	return btn


static func font_px(size: int) -> int:
	var scaled := int(round(float(maxi(size, MIN_FONT)) * SaveManager.text_scale))
	return maxi(MIN_FONT, scaled)


static func body_px(size: int) -> int:
	return font_px(maxi(size, BODY_FONT))


static func small_px(size: int) -> int:
	var scaled := int(round(float(maxi(size, SMALL_FONT)) * SaveManager.text_scale))
	return maxi(SMALL_FONT, scaled)


static func install_theme(node: Node) -> void:
	if node == null:
		return
	var theme := Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = BODY_FONT
	node.theme = theme


static func label(text: String, size := 36, color: Color = DARK, font_kind := "body", wrap := true) -> Label:
	var node := Label.new()
	node.text = text
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var px := body_px(size)
	var do_wrap := wrap
	match font_kind:
		"title":
			node.add_theme_font_override("font", title_font())
			px = font_px(size)
			do_wrap = false
		"crt":
			node.add_theme_font_override("font", crt_font())
			px = font_px(size)
		"small":
			node.add_theme_font_override("font", body_font())
			px = small_px(size)
			node.set_meta("small_text", true)
		_:
			node.add_theme_font_override("font", body_font())
			px = body_px(size)
	node.add_theme_font_size_override("font_size", px)
	node.add_theme_color_override("font_color", color)
	if do_wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		node.autowrap_mode = TextServer.AUTOWRAP_OFF
		node.max_lines_visible = 1
		var min_w := maxf(180.0, float(text.length()) * float(px) * 0.56)
		node.custom_minimum_size = Vector2(min_w, float(px) + 16.0)
	return node


static func center_screen(parent: Node, center_name := "Center") -> CenterContainer:
	var center := CenterContainer.new()
	center.name = center_name
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	center.layout_mode = 1
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return center


static func fill(node: Control, left := 0.0, top := 0.0, right := 0.0, bottom := 0.0) -> void:
	node.layout_mode = 1
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.offset_left = left
	node.offset_top = top
	node.offset_right = -absf(right) if right > 0.0 else right
	node.offset_bottom = -absf(bottom) if bottom > 0.0 else bottom
	if right < 0.0:
		node.offset_right = right
	if bottom < 0.0:
		node.offset_bottom = bottom


static func pin_center(node: Control, size: Vector2) -> void:
	node.custom_minimum_size = size
	node.size = size
	node.layout_mode = 1
	node.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	node.offset_left = -size.x * 0.5
	node.offset_top = -size.y * 0.5
	node.offset_right = size.x * 0.5
	node.offset_bottom = size.y * 0.5


static func pin_top_left(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.layout_mode = 1
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


static func pin_top_right(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.layout_mode = 1
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


static func pin_bottom(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.layout_mode = 1
	node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


static func pin_center_top(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.layout_mode = 1
	node.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


static func link_focus(controls: Array) -> void:
	var rows: Array = []
	for item in controls:
		rows.append([item])
	link_grid(rows)


static func link_grid(rows: Array) -> void:
	var flat: Array[Control] = []
	var live_rows: Array = []
	for row in rows:
		var live: Array[Control] = []
		for item in row:
			if item is Control and (item as Control).focus_mode != Control.FOCUS_NONE:
				live.append(item)
				flat.append(item)
		if not live.is_empty():
			live_rows.append(live)
	if flat.is_empty():
		return
	for r in live_rows.size():
		var live: Array[Control] = live_rows[r]
		for i in live.size():
			var node := live[i]
			var prev := live[(i - 1 + live.size()) % live.size()]
			var nxt := live[(i + 1) % live.size()]
			var above_row: Array[Control] = live_rows[(r - 1 + live_rows.size()) % live_rows.size()]
			var below_row: Array[Control] = live_rows[(r + 1) % live_rows.size()]
			var above := above_row[mini(i, above_row.size() - 1)]
			var below := below_row[mini(i, below_row.size() - 1)]
			node.focus_neighbor_left = node.get_path_to(prev)
			node.focus_neighbor_right = node.get_path_to(nxt)
			node.focus_neighbor_top = node.get_path_to(above)
			node.focus_neighbor_bottom = node.get_path_to(below)
			node.focus_previous = node.get_path_to(prev)
			node.focus_next = node.get_path_to(nxt)
	var first := flat[0]
	for node in flat:
		if node is BaseButton and (node as BaseButton).disabled:
			continue
		if node.visible:
			first = node
			break
	var tree := first.get_tree()
	var focus_id := first.get_instance_id()
	if tree != null:
		tree.process_frame.connect(func():
			var node := instance_from_id(focus_id) as Control
			if node != null and is_instance_valid(node) and node.is_inside_tree():
				node.grab_focus()
		, CONNECT_ONE_SHOT)
	else:
		first.grab_focus()


static func chip(key: String, caption: String) -> HBoxContainer:
	# A key cap and what it does: [R] rotate.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	var cap := Label.new()
	cap.text = key
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_theme_font_override("font", title_font())
	cap.add_theme_font_size_override("font_size", small_px(24))
	cap.set_meta("small_text", true)
	cap.add_theme_color_override("font_color", CREAM_CARD)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var box := style(DARK, 8)
	box.shadow_size = 0
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	cap.add_theme_stylebox_override("normal", box)
	cap.custom_minimum_size = Vector2(44, 36)
	row.add_child(cap)
	var text := label(caption, 24, DARK, "small", false)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text)
	return row


static func chips(items: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Chips"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 18)
	for item in items:
		if item is Array and (item as Array).size() >= 2:
			row.add_child(chip(str(item[0]), str(item[1])))
	return row


static func avatar(initial: String, color: Color, size := 44) -> Panel:
	var disc := Panel.new()
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.custom_minimum_size = Vector2(size, size)
	var box := style(color, int(size / 2))
	box.shadow_size = 0
	disc.add_theme_stylebox_override("panel", box)
	var letter := Label.new()
	letter.text = initial
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter.add_theme_font_override("font", title_font())
	letter.add_theme_font_size_override("font_size", small_px(24))
	letter.set_meta("small_text", true)
	letter.add_theme_color_override("font_color", CREAM_CARD)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disc.add_child(letter)
	letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return disc


static func show_level_beat(host: Node, beat: Dictionary, at_top := false) -> void:
	if host == null or beat.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 16
	host.add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "LevelBeat"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style(CREAM_CARD, 16))
	layer.add_child(panel)
	panel.layout_mode = 1
	# Sits just above the hint bar. The container grows with the text, so paragraphs never overlap.
	# Anchors first: setting a preset afterwards would rewrite the offsets.
	if at_top:
		# The drive keeps the truck in the middle of the screen, so the card goes up top.
		panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
		panel.grow_vertical = Control.GROW_DIRECTION_END
	else:
		panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -520
	panel.offset_right = 520
	if at_top:
		panel.offset_top = 130
		panel.offset_bottom = 130
	else:
		panel.offset_bottom = -196
		panel.offset_top = -196
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var strip := HBoxContainer.new()
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_constant_override("separation", 18)
	margin.add_child(strip)
	var accent := ColorRect.new()
	accent.color = TERRA
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.custom_minimum_size = Vector2(8, 0)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.add_child(accent)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_child(column)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 12)
	column.add_child(head)
	head.add_child(avatar("D", TERRA, 40))
	var title := label("%s" % beat.get("level_name", ""), 32, TERRA, "title", false)
	title.name = "LevelTitle"
	title.custom_minimum_size = Vector2(420, 44)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var tag := label(str(beat.get("level_id", beat.get("level", ""))), 24, BLUE, "small", false)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(tag)
	var arrival := str(beat.get("arrival", "")).strip_edges()
	if arrival != "":
		var row := label(arrival, 28, DARK, "small")
		row.custom_minimum_size = Vector2(960, 0)
		column.add_child(row)
	var moment := str(beat.get("moment", "")).strip_edges()
	if moment != "":
		var row2 := label(moment, 28, BLUE, "small")
		row2.custom_minimum_size = Vector2(960, 0)
		column.add_child(row2)
	passthrough(panel)
	var tw := host.create_tween()
	tw.tween_interval(8.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)


static func passthrough(node: Node) -> void:
	# Informational UI never eats a click meant for the room behind it.
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		passthrough(child)
