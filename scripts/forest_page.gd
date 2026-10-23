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
	var cats := Catalog.categories()
	if not cats.is_empty():
		category = str(cats[0].get("id", "furniture"))
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var title := UIKit.label("TropicalForest", 28, UIKit.DARK, "title")
	title.position = Vector2(8, 4)
	add_child(title)
	var deal := UIKit.label(_deal_line(), 18, UIKit.TERRA)
	deal.position = Vector2(280, 10)
	deal.size = Vector2(740, 40)
	add_child(deal)
	var search := LineEdit.new()
	search.placeholder_text = "Search the canopy"
	search.text = query
	search.position = Vector2(250, 48)
	search.size = Vector2(280, 48)
	search.custom_minimum_size = Vector2(280, 48)
	search.focus_mode = Control.FOCUS_ALL
	search.add_theme_font_override("font", UIKit.body_font())
	search.add_theme_font_size_override("font_size", UIKit.font_px(18))
	search.text_submitted.connect(func(value: String):
		query = value
		_build()
	)
	add_child(search)
	var go := UIKit.button("Search", UIKit.BLUE)
	go.position = Vector2(510, 48)
	go.size = Vector2(140, 56)
	go.custom_minimum_size = Vector2(140, 56)
	go.pressed.connect(func():
		query = search.text
		_build()
	)
	add_child(go)
	var y := 52.0
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
		y += 60
	var prime := UIKit.button("Toucan Prime" if not GameState.prime else "Prime member", UIKit.MUSTARD, UIKit.DARK)
	prime.position = Vector2(8, y)
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
	var y := 92.0
	if rows.is_empty():
		var empty := UIKit.label("Nothing in this aisle yet.", 18, UIKit.DARK)
		empty.position = Vector2(250, 100)
		add_child(empty)
		return
	for entry in rows:
		var id := str(entry.get("id", ""))
		if selected == "":
			selected = id
		var btn := Button.new()
		btn.text = "%s   $%d   %s" % [Catalog.display_name(id), Catalog.price_of(id, GameState.day), _stars(float(entry.get("stars", 4)))]
		btn.position = Vector2(250, y)
		btn.focus_mode = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(360, 56)
		btn.size = Vector2(360, 56)
		btn.add_theme_font_override("font", UIKit.body_font())
		btn.add_theme_font_size_override("font_size", UIKit.font_px(28))
		var fill := UIKit.MUSTARD if id == selected else Color("F7F1E4")
		btn.add_theme_color_override("font_color", UIKit.DARK)
		btn.add_theme_color_override("font_hover_color", UIKit.DARK)
		btn.add_theme_color_override("font_focus_color", UIKit.DARK)
		btn.add_theme_stylebox_override("normal", UIKit.style(fill, 8))
		btn.add_theme_stylebox_override("hover", UIKit.style(fill.lightened(0.08), 8, 3, UIKit.CREAM_CARD))
		btn.add_theme_stylebox_override("focus", UIKit.style(fill.lightened(0.08), 8, 4, UIKit.MUSTARD))
		btn.pressed.connect(_pick_item.bind(id))
		add_child(btn)
		y += 60
		if y > 420:
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
	var panel := Panel.new()
	panel.position = Vector2(640, 92)
	panel.size = Vector2(380, 350)
	panel.add_theme_stylebox_override("panel", UIKit.style(Color("F7F1E4"), 12))
	add_child(panel)
	var name := UIKit.label(Catalog.display_name(selected), 22, UIKit.DARK, "title")
	name.position = Vector2(12, 8)
	name.size = Vector2(360, 32)
	panel.add_child(name)
	var price := Catalog.price_of(selected, GameState.day)
	var list := Catalog.list_price(selected)
	var price_text := "$%d" % price
	if price < list:
		price_text = "$%d  was $%d" % [price, list]
	var meta := UIKit.label("%s   %s" % [price_text, _stars(float(entry.get("stars", 4)))], 18, UIKit.TERRA, "title")
	meta.position = Vector2(12, 40)
	panel.add_child(meta)
	var flavor := UIKit.label(ItemDB.flavor(str(entry.get("item", ""))), 18, UIKit.DARK)
	flavor.position = Vector2(12, 68)
	flavor.size = Vector2(360, 40)
	panel.add_child(flavor)
	var ry := 110.0
	for review in entry.get("reviews", []):
		var line := UIKit.label("%s  %s\n%s" % [_stars(float(review.get("stars", 5))), review.get("who", ""), review.get("text", "")], 18, UIKit.DARK)
		line.position = Vector2(12, ry)
		line.size = Vector2(360, 48)
		panel.add_child(line)
		ry += 52
	var also_bits: PackedStringArray = PackedStringArray()
	for other in entry.get("also", []):
		also_bits.append(Catalog.display_name(str(other)))
	if also_bits.size() > 0:
		var also := UIKit.label("Customers also bought  " + ", ".join(also_bits), 18, UIKit.BLUE)
		also.position = Vector2(12, 250)
		also.size = Vector2(360, 36)
		panel.add_child(also)
	var wished := selected in GameState.wishlist
	var wish := UIKit.button("Wishlisted" if wished else "Wishlist", UIKit.BLUE)
	wish.position = Vector2(12, 292)
	wish.size = Vector2(180, 56)
	wish.custom_minimum_size = Vector2(180, 56)
	wish.pressed.connect(_wish)
	panel.add_child(wish)
	var standard := UIKit.button("Standard  free", UIKit.SAGE)
	standard.position = Vector2(12, 342)
	standard.size = Vector2(180, 56)
	standard.custom_minimum_size = Vector2(180, 56)
	standard.pressed.connect(_buy.bind("standard"))
	panel.add_child(standard)
	var fee := int(Catalog.shipping("express").get("fee", 4))
	if GameState.prime:
		fee = 0
	var express := UIKit.button("Express  $%d" % fee, UIKit.TERRA)
	express.position = Vector2(196, 342)
	express.size = Vector2(180, 56)
	express.custom_minimum_size = Vector2(180, 56)
	express.pressed.connect(_buy.bind("express"))
	panel.add_child(express)


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
	var note := UIKit.label(text, 18, color, "title")
	note.position = Vector2(250, 8)
	add_child(note)
