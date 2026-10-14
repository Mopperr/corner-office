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
const SCREEN := Color("243832")


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


static func button(text: String, fill: Color = SAGE, fg: Color = CREAM_CARD) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_override("font", title_font())
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style(fill, 18))
	btn.add_theme_stylebox_override("hover", style(fill.lightened(0.08), 18))
	btn.add_theme_stylebox_override("pressed", style(fill.darkened(0.08), 18))
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
	btn.custom_minimum_size = Vector2(92, 84)
	btn.add_theme_font_override("font", crt_font())
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", CREAM_CARD)
	btn.add_theme_color_override("font_hover_color", MUSTARD)
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		btn.icon = tex
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 48)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_stylebox_override("normal", style(Color(0, 0, 0, 0), 10))
	btn.add_theme_stylebox_override("hover", style(Color(CREAM_CARD, 0.12), 10))
	btn.add_theme_stylebox_override("pressed", style(Color(CREAM_CARD, 0.2), 10))
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.mouse_entered.connect(func(): AudioDirector.play_sfx("sfx_ui_hover"))
	btn.pressed.connect(func(): AudioDirector.play_sfx("sfx_ui_click"))
	return btn


static func label(text: String, size := 18, color: Color = DARK, font_kind := "body") -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", int(float(size) * SaveManager.text_scale))
	node.add_theme_color_override("font_color", color)
	match font_kind:
		"title":
			node.add_theme_font_override("font", title_font())
		"crt":
			node.add_theme_font_override("font", crt_font())
		_:
			node.add_theme_font_override("font", body_font())
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


static func show_level_beat(host: Node, beat: Dictionary) -> void:
	if host == null or beat.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 16
	host.add_child(layer)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -490
	panel.offset_top = -300
	panel.offset_right = 490
	panel.offset_bottom = -100
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style(CREAM_CARD, 16))
	layer.add_child(panel)
	var title := label("%s" % beat.get("level_name", ""), 22, TERRA, "title")
	title.position = Vector2(18, 12)
	title.size = Vector2(940, 32)
	panel.add_child(title)
	var arrival := label(str(beat.get("arrival", "")), 16, DARK)
	arrival.position = Vector2(18, 48)
	arrival.size = Vector2(940, 64)
	panel.add_child(arrival)
	var moment := label(str(beat.get("moment", "")), 16, DARK)
	moment.position = Vector2(18, 114)
	moment.size = Vector2(940, 70)
	panel.add_child(moment)
	var tw := host.create_tween()
	tw.tween_interval(8.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)
