extends Control
# The Till: how the shop is doing, the sign, what is on the counter, the
# last sales, the menu and its mood, and the ladder from lemonade stand to
# a restaurant with a waiting list. Two scrolling columns that fit the
# smallest window.

const Catalog = preload("res://scripts/catalog.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

const COLUMN_W := 580.0


func _ready() -> void:
	Catalog.ensure()
	if get_parent() is Control:
		size = (get_parent() as Control).size
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var title := UIKit.label("Shop Manager", 28, UIKit.DARK, "title", false)
	title.position = Vector2(12, 8)
	add_child(title)
	if not GameState.tutorial_done:
		var wait := UIKit.label("Unpack the garage first. The till can wait on the counter.", 24, UIKit.DARK, "small")
		wait.position = Vector2(16, 60)
		wait.size = Vector2(900, 60)
		add_child(wait)
		return
	var tier_name := ""
	for tier in Catalog.tiers():
		if str(tier.get("id", "")) == GameState.shop_tier:
			tier_name = str(tier.get("name", ""))
	var tag := UIKit.label(tier_name, 24, UIKit.TERRA, "small", false)
	tag.position = Vector2(290, 18)
	add_child(tag)
	_left_column()
	_right_column()


func _column(x: float) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(x, 56)
	scroll.size = Vector2(COLUMN_W + 20.0, 490)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(COLUMN_W, 0)
	scroll.add_child(column)
	return column


func _line(column: VBoxContainer, text: String, color: Color = UIKit.DARK, lines := 3) -> Label:
	var label := UIKit.label(text, 24, color, "small")
	label.custom_minimum_size = Vector2(COLUMN_W, 0)
	label.max_lines_visible = lines
	column.add_child(label)
	return label


func _heading(column: VBoxContainer, text: String) -> void:
	var label := UIKit.label(text, 24, UIKit.DARK, "title", false)
	label.custom_minimum_size = Vector2(COLUMN_W, 36)
	column.add_child(label)


func _left_column() -> void:
	var column := _column(12.0)
	var vibe := GameState.vibe_score()
	var open := GameState.shop_open()
	_line(column, "Vibe %d.  Today $%d from %d visitors, %d served by hand." % [vibe, GameState.shop_today, GameState.shop_visitors_today, GameState.shop_hand_served], UIKit.DARK, 2)
	_line(column, "Click a customer to serve them yourself: the whole tip. Leave them and the till rings them up at half." if open else "Put a coffee machine, kettle, or lemonade pitcher on a counter and people wander in. Nothing fails if you don't.", UIKit.BLUE, 3)
	var sign := UIKit.button("Sign: CLOSED" if GameState.shop_closed else "Sign: OPEN", UIKit.TERRA if GameState.shop_closed else UIKit.SAGE)
	sign.custom_minimum_size = Vector2(220, 56)
	sign.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sign.pressed.connect(func():
		GameState.shop_closed = not GameState.shop_closed
		AudioDirector.play_sfx("sfx_ui_click")
		SaveManager.save_game()
		_build()
	)
	column.add_child(sign)
	_heading(column, "On the counter")
	var fixes := GameState.shop_fixtures()
	if fixes.is_empty():
		_line(column, "Nothing yet.", UIKit.BLUE, 1)
	else:
		var names: PackedStringArray = PackedStringArray()
		for fix in fixes:
			names.append(str(fix.get("label", fix.get("item", ""))))
		_line(column, ", ".join(names), UIKit.SAGE, 2)
	_heading(column, "Last sales")
	if GameState.shop_ledger.is_empty():
		_line(column, "The till is quiet.", UIKit.BLUE, 1)
	var shown := 0
	for sale in GameState.shop_ledger:
		if shown >= 5:
			break
		shown += 1
		_line(column, "%s  ·  %s  $%d%s" % [sale.get("name", ""), sale.get("dish", ""), int(sale.get("pay", 0)), "  ✓ by hand" if bool(sale.get("hand", false)) else ""], UIKit.DARK, 1)
	var barista: Dictionary = Catalog.shop.get("barista", {})
	var note := str(barista.get("blurb", ""))
	if GameState._barista_on():
		note = "Biscuit is on the till. Visitors linger."
	_line(column, note, UIKit.WOOD, 2)


func _right_column() -> void:
	var column := _column(620.0)
	_heading(column, "Menu  ·  prices follow the mood")
	var served := GameState.shop_dishes()
	# The whole board, grouped by rung; the column scrolls when the restaurant is open.
	var last_tier := ""
	for dish in Catalog.menu():
		var id := str(dish.get("id", ""))
		var tier := str(dish.get("tier", "stand"))
		var on := served.has(id) or (served.is_empty() and tier == "stand")
		if not on:
			continue
		if tier != last_tier and tier != "stand":
			last_tier = tier
			_line(column, Catalog.tier_name(tier), UIKit.WOOD, 1)
		var price := int(round(float(dish.get("price", 1)) * GameState.menu_markup))
		_line(column, "%s   $%d" % [dish.get("name", ""), price], UIKit.DARK, 1)
	var moods := HBoxContainer.new()
	moods.add_theme_constant_override("separation", 10)
	column.add_child(moods)
	for markup in Catalog.shop.get("markups", [1.0]):
		var value := float(markup)
		var label := "Cozy" if value < 0.9 else ("Fair" if value < 1.1 else "Splurge")
		var current := absf(GameState.menu_markup - value) < 0.05
		var btn := UIKit.button(label, UIKit.MUSTARD if current else UIKit.BLUE, UIKit.DARK if current else UIKit.CREAM_CARD)
		btn.custom_minimum_size = Vector2(140, 56)
		btn.pressed.connect(_set_markup.bind(value))
		moods.add_child(btn)
	_heading(column, "The ladder")
	var rank := GameState.shop_tier_rank()
	var tiers := Catalog.tiers()
	var steps: PackedStringArray = PackedStringArray()
	for i in tiers.size():
		steps.append("%s %s" % ["●" if i <= rank else "○", tiers[i].get("name", "")])
	_line(column, "  ·  ".join(steps), UIKit.DARK, 3)
	var nxt := GameState.next_shop_tier()
	if nxt.is_empty():
		_line(column, "Top of the ladder. There is a waiting list.", UIKit.SAGE, 1)
		return
	_line(column, "Next: %s. $%d, Rep %d. %s" % [nxt.get("name", ""), int(nxt.get("cost", 0)), int(nxt.get("rep", 0)), nxt.get("blurb", "")], UIKit.DARK, 3)
	var btn := UIKit.button("Upgrade to %s" % nxt.get("name", ""), UIKit.TERRA)
	btn.name = "Upgrade"
	btn.custom_minimum_size = Vector2(360, 56)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.pressed.connect(func():
		var err := GameState.upgrade_shop()
		if err != "":
			_line(column, err, UIKit.LOSS, 1)
			AudioDirector.play_sfx("sfx_invalid_placement")
			return
		AudioDirector.play_sfx("sfx_cash_gain")
		SaveManager.save_game()
		_build()
	)
	column.add_child(btn)


func _set_markup(value: float) -> void:
	GameState.set_markup(value)
	AudioDirector.play_sfx("sfx_ui_click")
	SaveManager.save_game()
	_build()
