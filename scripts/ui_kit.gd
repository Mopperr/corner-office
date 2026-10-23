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


static func show_level_beat(host: Node, beat: Dictionary) -> void:
	if host == null or beat.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 16
	host.add_child(layer)
	var panel := Panel.new()
	panel.name = "LevelBeat"
	panel.custom_minimum_size = Vector2(1100, 250)
	panel.size = Vector2(1100, 250)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style(CREAM_CARD, 16))
	layer.add_child(panel)
	panel.layout_mode = 1
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
	# Hint bar occupies the bottom of the screen. Keep the beat and its shadow above that.
	panel.offset_left = -550
	panel.offset_right = 550
	panel.offset_top = -446
	panel.offset_bottom = -196
	var title := label("%s" % beat.get("level_name", ""), 40, TERRA, "title", false)
	title.name = "LevelTitle"
	title.position = Vector2(28, 16)
	title.size = Vector2(1040, 56)
	title.custom_minimum_size = Vector2(520, 56)
	panel.add_child(title)
	var arrival := label(str(beat.get("arrival", "")), BODY_FONT, DARK)
	arrival.position = Vector2(28, 80)
	arrival.size = Vector2(1040, 72)
	arrival.custom_minimum_size = Vector2(1040, 48)
	panel.add_child(arrival)
	var moment := label(str(beat.get("moment", "")), BODY_FONT, DARK)
	moment.position = Vector2(28, 156)
	moment.size = Vector2(1040, 72)
	moment.custom_minimum_size = Vector2(1040, 48)
	panel.add_child(moment)
	var tw := host.create_tween()
	tw.tween_interval(8.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)
