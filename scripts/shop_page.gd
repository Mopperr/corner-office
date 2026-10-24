extends Control

const Catalog = preload("res://scripts/catalog.gd")
const UIKit = preload("res://scripts/ui_kit.gd")


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
		var wait := UIKit.label("Unpack the garage first. The till can wait on the counter.", 28, UIKit.DARK, "small")
		wait.position = Vector2(16, 70)
		wait.size = Vector2(900, 60)
		add_child(wait)
		return
	var vibe := GameState.vibe_score()
	var open := GameState.shop_open()
	var summary := UIKit.label(
		"Vibe %d.  Today $%d from %d visitors, %d served by hand.\n%s" % [
			vibe,
			GameState.shop_today,
			GameState.shop_visitors_today,
			GameState.shop_hand_served,
			"Click a customer to serve them yourself: the whole tip. Leave them and the till rings them up at half." if open else "Put a coffee machine, kettle, or lemonade pitcher on a counter and people wander in. Nothing fails if you don't.",
		],
		28, UIKit.DARK, "small"
	)
	summary.position = Vector2(16, 52)
	summary.size = Vector2(600, 110)
	add_child(summary)
	var sign := UIKit.button("Sign: CLOSED" if GameState.shop_closed else "Sign: OPEN", UIKit.TERRA if GameState.shop_closed else UIKit.SAGE)
	sign.position = Vector2(16, 170)
	sign.size = Vector2(220, 56)
	sign.custom_minimum_size = Vector2(220, 56)
	sign.pressed.connect(func():
		GameState.shop_closed = not GameState.shop_closed
		AudioDirector.play_sfx("sfx_ui_click")
		SaveManager.save_game()
		_build()
	)
	add_child(sign)
	var fixes := GameState.shop_fixtures()
	var fy := 240.0
	var fix_title := UIKit.label("On the counter", 24, UIKit.DARK, "title")
	fix_title.position = Vector2(16, fy)
	add_child(fix_title)
	fy += 36
	if fixes.is_empty():
		var none := UIKit.label("Nothing yet.", 28, UIKit.BLUE, "small")
		none.position = Vector2(16, fy)
		add_child(none)
		fy += 32
	else:
		for fix in fixes:
			var row := UIKit.label("• " + str(fix.get("label", fix.get("item", ""))), 28, UIKit.SAGE, "small")
			row.position = Vector2(16, fy)
			add_child(row)
			fy += 32
	var ledger_title := UIKit.label("Last sales", 24, UIKit.DARK, "title")
	ledger_title.position = Vector2(16, fy + 10)
	add_child(ledger_title)
	fy += 46
	if GameState.shop_ledger.is_empty():
		var none2 := UIKit.label("The till is quiet.", 28, UIKit.BLUE, "small")
		none2.position = Vector2(16, fy)
		add_child(none2)
	for sale in GameState.shop_ledger:
		var line := UIKit.label("%s  %s  $%d%s" % [sale.get("name", ""), sale.get("dish", ""), int(sale.get("pay", 0)), "  ✓ by hand" if bool(sale.get("hand", false)) else ""], 28, UIKit.DARK, "small")
		line.position = Vector2(16, fy)
		line.size = Vector2(600, 30)
		add_child(line)
		fy += 32
	var menu_title := UIKit.label("Menu  ·  prices follow the mood", 24, UIKit.DARK, "title")
	menu_title.position = Vector2(640, 52)
	add_child(menu_title)
	var my := 92.0
	for dish in Catalog.menu():
		var price := int(round(float(dish.get("price", 1)) * GameState.menu_markup))
		var line := UIKit.label("%s   $%d" % [dish.get("name", ""), price], 28, UIKit.DARK, "small")
		line.position = Vector2(640, my)
		line.size = Vector2(420, 30)
		add_child(line)
		my += 32
	var mx := 640.0
	for markup in Catalog.shop.get("markups", [1.0]):
		var value := float(markup)
		var label := "Cozy" if value < 0.9 else ("Fair" if value < 1.1 else "Splurge")
		var btn := UIKit.button(label, UIKit.MUSTARD if absf(GameState.menu_markup - value) < 0.05 else UIKit.BLUE, UIKit.DARK if absf(GameState.menu_markup - value) < 0.05 else UIKit.CREAM_CARD)
		btn.position = Vector2(mx, my + 16)
		btn.size = Vector2(140, 56)
		btn.custom_minimum_size = Vector2(140, 56)
		btn.pressed.connect(_set_markup.bind(value))
		add_child(btn)
		mx += 150
	var barista: Dictionary = Catalog.shop.get("barista", {})
	var note := str(barista.get("blurb", ""))
	if GameState._barista_on():
		note = "Biscuit is on the till. Visitors linger."
	var cat := UIKit.label(note, 28, UIKit.DARK, "small")
	cat.position = Vector2(640, my + 90)
	cat.size = Vector2(600, 80)
	add_child(cat)


func _set_markup(value: float) -> void:
	GameState.set_markup(value)
	AudioDirector.play_sfx("sfx_ui_click")
	SaveManager.save_game()
	_build()
