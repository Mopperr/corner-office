extends Control

const Catalog = preload("res://scripts/catalog.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

var query := ""
var category := "furniture"
var selected := ""


func _ready() -> void:
	Catalog.ensure()
	if get_parent() is Control:
		size = (get_parent() as Control).size
	if size.x < 400.0:
		size = Vector2(1348, 804)
	var cats := Catalog.categories()
	if not cats.is_empty():
		category = str(cats[0].get("id", "furniture"))
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	# Columns: categories (8..300), listings (320..1000), detail (1020..1840).
	var title := UIKit.label("TropicalForest", 28, UIKit.DARK, "title", false)
	title.position = Vector2(8, 4)
	add_child(title)
	var search := LineEdit.new()
	search.placeholder_text = "Search the canopy"
	search.text = query
	search.position = Vector2(260, 8)
	search.size = Vector2(300, 56)
	search.custom_minimum_size = Vector2(300, 56)
	search.focus_mode = Control.FOCUS_ALL
	search.add_theme_font_override("font", UIKit.body_font())
	search.add_theme_font_size_override("font_size", UIKit.small_px(24))
	search.text_submitted.connect(func(value: String):
		query = value
		_build()
	)
	add_child(search)
	var go := UIKit.button("Search", UIKit.BLUE)
	go.position = Vector2(570, 8)
	go.size = Vector2(130, 56)
	go.custom_minimum_size = Vector2(130, 56)
	go.pressed.connect(func():
		query = search.text
		_build()
	)
	add_child(go)
	var deal := UIKit.label(_deal_line(), 24, UIKit.TERRA, "small")
	deal.position = Vector2(712, 4)
	deal.size = Vector2(494, 72)
	deal.max_lines_visible = 2
	add_child(deal)
	var y := 80.0
	for cat in Catalog.categories():
		var id := str(cat.get("id", ""))
		var open := Catalog.category_open(id, GameState.office_id)
		var btn := UIKit.button(str(cat.get("name", id)), UIKit.SAGE if id == category else UIKit.BLUE)
		btn.position = Vector2(8, y)
		btn.size = Vector2(240, 56)
		btn.custom_minimum_size = Vector2(240, 56)
		btn.disabled = not open
		if not open:
			btn.text = "%s  · later" % str(cat.get("name", id))
		btn.pressed.connect(_pick_category.bind(id))
		add_child(btn)
		y += 62
	var prime := UIKit.button("Toucan Prime" if not GameState.prime else "Prime member", UIKit.MUSTARD, UIKit.DARK)
	prime.position = Vector2(8, y + 10)
	prime.size = Vector2(240, 56)
	prime.custom_minimum_size = Vector2(240, 56)
	prime.disabled = GameState.prime
	prime.pressed.connect(_prime)
	add_child(prime)
	_list()
	_detail()


func _pick_category(id: String) -> void:
	category = id
	selected = ""
	_build()


func _deal_line() -> String:
	var names: PackedStringArray = PackedStringArray()
	for id in Catalog.deal_skus(GameState.day):
		names.append(Catalog.display_name(str(id)))
	if names.is_empty():
		return "Today's deal is taking a nap."
	return "Lightning deal, no rush: %s. It simply waits until tomorrow." % ", ".join(names)


func _list() -> void:
	var rows: Array = Catalog.search(category, query, GameState.office_id)
	var y := 80.0
	if rows.is_empty():
		var empty := UIKit.label("Nothing in this aisle yet.", 24, UIKit.DARK, "small")
		empty.position = Vector2(260, 90)
		empty.size = Vector2(440, 40)
		add_child(empty)
		return
	for entry in rows:
		var id := str(entry.get("id", ""))
		if selected == "":
			selected = id
		var btn := Button.new()
		btn.text = "%s   $%d   %s" % [Catalog.display_name(id), Catalog.price_of(id, GameState.day), _stars(float(entry.get("stars", 4)))]
		btn.position = Vector2(260, y)
		btn.focus_mode = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(440, 56)
		btn.size = Vector2(440, 56)
		btn.clip_text = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_override("font", UIKit.body_font())
		btn.add_theme_font_size_override("font_size", UIKit.small_px(24))
		var fill := UIKit.MUSTARD if id == selected else Color("F7F1E4")
		btn.add_theme_color_override("font_color", UIKit.DARK)
		btn.add_theme_color_override("font_hover_color", UIKit.DARK)
		btn.add_theme_color_override("font_focus_color", UIKit.DARK)
		btn.add_theme_stylebox_override("normal", UIKit.style(fill, 8))
		btn.add_theme_stylebox_override("hover", UIKit.style(fill.lightened(0.08), 8, 3, UIKit.CREAM_CARD))
		btn.add_theme_stylebox_override("focus", UIKit.style(fill.lightened(0.08), 8, 4, UIKit.MUSTARD))
		btn.pressed.connect(_pick_item.bind(id))
		add_child(btn)
		y += 62
		if y > size.y - 70.0:
			break


func _pick_item(id: String) -> void:
	selected = id
	_build()


func _detail() -> void:
	if selected == "":
		return
	var entry := Catalog.sku(selected)
	if entry.is_empty():
		return
	var panel := PanelContainer.new()
	panel.position = Vector2(712, 84)
	panel.size = Vector2(maxf(494.0, size.x - 724.0), maxf(456.0, size.y - 96.0))
	panel.custom_minimum_size = panel.size
	var box := UIKit.style(Color("F7F1E4"), 12)
	box.shadow_size = 0
	for side in ["left", "right", "top", "bottom"]:
		box.set("content_margin_" + side, 16)
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var name := UIKit.label(Catalog.display_name(selected), 28, UIKit.DARK, "title", false)
	name.custom_minimum_size = Vector2(460, 40)
	name.clip_text = true
	column.add_child(name)
	var price := Catalog.price_of(selected, GameState.day)
	var list := Catalog.list_price(selected)
	var price_text := "$%d" % price
	if price < list:
		price_text = "$%d  was $%d" % [price, list]
	column.add_child(UIKit.label("%s   %s" % [price_text, _stars(float(entry.get("stars", 4)))], 24, UIKit.TERRA, "title", false))
	var flavor := UIKit.label(ItemDB.flavor(str(entry.get("item", ""))), 24, UIKit.DARK, "small")
	flavor.custom_minimum_size = Vector2(460, 0)
	flavor.max_lines_visible = 2
	column.add_child(flavor)
	var shown := 0
	for review in entry.get("reviews", []):
		if shown >= 2:
			break
		shown += 1
		var line := UIKit.label("%s  %s: %s" % [_stars(float(review.get("stars", 5))), review.get("who", ""), review.get("text", "")], 24, UIKit.DARK, "small")
		line.custom_minimum_size = Vector2(460, 0)
		line.max_lines_visible = 2
		column.add_child(line)
	var also_bits: PackedStringArray = PackedStringArray()
	for other in entry.get("also", []):
		also_bits.append(Catalog.display_name(str(other)))
	if also_bits.size() > 0:
		var also := UIKit.label("Customers also bought  " + ", ".join(also_bits), 24, UIKit.BLUE, "small")
		also.custom_minimum_size = Vector2(460, 0)
		also.max_lines_visible = 1
		column.add_child(also)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	var wished := selected in GameState.wishlist
	var wish := UIKit.button("Wished" if wished else "Wish", UIKit.BLUE)
	wish.custom_minimum_size = Vector2(120, 56)
	wish.pressed.connect(_wish)
	buttons.add_child(wish)
	var standard := UIKit.button("Standard", UIKit.SAGE)
	standard.custom_minimum_size = Vector2(160, 56)
	standard.pressed.connect(_buy.bind("standard"))
	buttons.add_child(standard)
	var fee := int(Catalog.shipping("express").get("fee", 4))
	if GameState.prime:
		fee = 0
	var express := UIKit.button("Express $%d" % fee, UIKit.TERRA)
	express.custom_minimum_size = Vector2(160, 56)
	express.pressed.connect(_buy.bind("express"))
	buttons.add_child(express)


func _stars(value: float) -> String:
	var full := clampi(int(round(value)), 1, 5)
	var marks := ""
	for _i in full:
		marks += "★"
	return marks


func _wish() -> void:
	GameState.toggle_wishlist(selected)
	AudioDirector.play_sfx("sfx_ui_click")
	_build()


func _buy(tier: String) -> void:
	var err := GameState.order_forest(selected, tier)
	if err != "":
		_toast(err, UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_buy_click")
	_toast("Order tucked into a box.", UIKit.GREEN)
	SaveManager.save_game()


func _prime() -> void:
	var err := GameState.buy_prime()
	if err != "":
		_toast(err, UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_cash_gain")
	_toast("Toucan Prime. Express naps for free.", UIKit.GREEN)
	SaveManager.save_game()
	_build()


func _toast(text: String, color: Color) -> void:
	var old := get_node_or_null("Toast")
	if old != null:
		old.queue_free()
	var note := UIKit.label(text, 26, color, "title", false)
	note.name = "Toast"
	note.position = Vector2(260, 500)
	note.custom_minimum_size = Vector2(440, 40)
	add_child(note)
