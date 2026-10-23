extends Control


func _ready() -> void:
	Catalog.ensure()
	if get_parent() is Control:
		size = (get_parent() as Control).size
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var title := UIKit.label("Shop Manager", 28, UIKit.DARK, "title")
	title.position = Vector2(12, 8)
	add_child(title)
	if not GameState.tutorial_done:
		var wait := UIKit.label("Unpack the garage first. The till can wait on the counter.", 18, UIKit.DARK)
		wait.position = Vector2(16, 70)
		wait.size = Vector2(900, 60)
		add_child(wait)
		return
	var vibe := GameState.vibe_score()
	var open := GameState.shop_open()
	var summary := UIKit.label(
		"Vibe %d.  Today $%d from %d visitors.\n%s" % [
			vibe,
			GameState.shop_today,
			GameState.shop_visitors_today,
			"The door is a shop door." if open else "Place a coffee machine, bookshelf, fern, or cabinet. Visitors show up. Nothing fails if you don't.",
		],
		18, UIKit.DARK
	)
	summary.position = Vector2(16, 52)
	summary.size = Vector2(620, 70)
	add_child(summary)
	var fixes := GameState.shop_fixtures()
	var fy := 130.0
	if fixes.is_empty():
		var none := UIKit.label("No shop fixtures out yet.", 18, UIKit.BLUE)
		none.position = Vector2(16, fy)
		add_child(none)
	else:
		for fix in fixes:
			var row := UIKit.label(str(fix.get("label", fix.get("item", ""))), 18, UIKit.SAGE, "title")
			row.position = Vector2(16, fy)
			add_child(row)
			fy += 28
	var menu_title := UIKit.label("Menu  ·  prices follow the mood", 18, UIKit.DARK, "title")
	menu_title.position = Vector2(640, 52)
	add_child(menu_title)
	var my := 88.0
	for dish in Catalog.menu():
		var price := int(round(float(dish.get("price", 1)) * GameState.menu_markup))
		var line := UIKit.label("%s   $%d" % [dish.get("name", ""), price], 18, UIKit.DARK)
		line.position = Vector2(640, my)
		line.size = Vector2(360, 28)
		add_child(line)
		my += 32
	var mx := 640.0
	for markup in Catalog.shop.get("markups", [1.0]):
		var value := float(markup)
		var label := "Cozy" if value < 0.9 else ("Fair" if value < 1.1 else "Splurge")
		var btn := UIKit.button(label, UIKit.MUSTARD if absf(GameState.menu_markup - value) < 0.05 else UIKit.BLUE, UIKit.DARK if absf(GameState.menu_markup - value) < 0.05 else UIKit.CREAM_CARD)
		btn.position = Vector2(mx, 360)
		btn.size = Vector2(120, 44)
		btn.pressed.connect(_set_markup.bind(value))
		add_child(btn)
		mx += 128
	var barista: Dictionary = Catalog.shop.get("barista", {})
	var note := str(barista.get("blurb", ""))
	if GameState._barista_on():
		note = "Biscuit is on the till. Visitors linger."
	var cat := UIKit.label(note, 18, UIKit.DARK)
	cat.position = Vector2(16, 400)
	cat.size = Vector2(600, 48)
	add_child(cat)


func _set_markup(value: float) -> void:
	GameState.set_markup(value)
	AudioDirector.play_sfx("sfx_ui_click")
	SaveManager.save_game()
	_build()
