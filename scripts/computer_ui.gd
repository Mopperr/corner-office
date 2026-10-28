extends Control

const Books = preload("res://scripts/books.gd")
const Extras = preload("res://scripts/extras.gd")

const UIKit = preload("res://scripts/ui_kit.gd")
const Tuning = preload("res://scripts/tuning.gd")

signal closed

var page := "market"
var selected := ""
var chart: Control
var body: Control
var balance: Label
var pop: Label
var pop_time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	AudioDirector.play_music("music_computer_trading")
	var goods := ItemDB.trade_goods()
	if not goods.is_empty():
		selected = str(goods[0].get("id", ""))
	_build()


func _process(delta: float) -> void:
	if pop_time > 0.0:
		pop_time -= delta
		if pop:
			pop.modulate.a = clampf(pop_time, 0.0, 1.0)
			pop.position.y -= 18.0 * delta


func _build() -> void:
	var previous: Array = get_children()
	for child in previous:
		if child is CanvasItem and (child as CanvasItem).draw.is_connected(_draw_chart):
			(child as CanvasItem).draw.disconnect(_draw_chart)
		remove_child(child)
		child.free()
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NIGHT, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	UIKit.fill(dim, 0, 0, 0, 0)
	var bezel := Panel.new()
	bezel.name = "Bezel"
	bezel.add_theme_stylebox_override("panel", UIKit.style(Color("E4D3B4"), 28, 8, UIKit.DARK))
	add_child(bezel)
	UIKit.fill(bezel, 16, 16, 16, 16)
	UIKit.pop_in(bezel, 0.22)
	var screen := Panel.new()
	screen.name = "Screen"
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_theme_stylebox_override("panel", UIKit.style(UIKit.SCREEN, 12, 0))
	bezel.add_child(screen)
	UIKit.fill(screen, 20, 20, 20, 20)
	var bar := Panel.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.NIGHT, 8))
	screen.add_child(bar)
	bar.layout_mode = 1
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 64
	var home := UIKit.label("HomeDesk", 28, UIKit.CREAM_CARD, "crt", false)
	home.position = Vector2(18, 12)
	home.custom_minimum_size = Vector2(220, 40)
	bar.add_child(home)
	var market_name := UIKit.label("MARKET.EXE", 28, UIKit.MUSTARD, "crt", false)
	market_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen.add_child(market_name)
	UIKit.pin_center_top(market_name, -180, 28, 180, 76)
	balance = UIKit.label(_money(), 28, UIKit.MUSTARD, "crt", false)
	bar.add_child(balance)
	UIKit.pin_top_right(balance, -360, 12, -88, 52)
	var power := UIKit.button("x", UIKit.TERRA, UIKit.CREAM_CARD)
	power.custom_minimum_size = Vector2(56, 56)
	power.pressed.connect(_close)
	bar.add_child(power)
	UIKit.pin_top_right(power, -72, 4, -8, 60)
	var icons := HBoxContainer.new()
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.add_theme_constant_override("separation", 8)
	screen.add_child(icons)
	icons.layout_mode = 1
	icons.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	icons.offset_left = 16
	icons.offset_top = 76
	icons.offset_right = -16
	icons.offset_bottom = 176
	_icon(icons, "Market", "res://assets/ui/icons/icon_market.png", "market")
	_icon(icons, "Shop", "res://assets/ui/icons/icon_shop.png", "shop")
	_icon(icons, "Forest", "res://assets/ui/icons/icon_listings.png", "forest")
	_icon(icons, "Till", "res://assets/ui/icons/icon_shop.png", "manager")
	_icon(icons, "Email", "res://assets/ui/icons/icon_email.png", "email")
	_icon(icons, "Listings", "res://assets/ui/icons/icon_listings.png", "listings")
	_icon(icons, "Life", "res://assets/ui/icons/icon_email.png", "life")
	_icon(icons, "Books", "res://assets/ui/icons/icon_market.png", "books")
	body = Panel.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 12))
	screen.add_child(body)
	body.layout_mode = 1
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 16
	body.offset_top = 188
	# In a wide window the sidebar's column is its own: the page body stops
	# short of it, so no page ever runs under the cards.
	body.offset_right = -16 - (SIDEBAR_W + 12 if _sidebar_fits() else 0)
	body.offset_bottom = -16
	_show_page()


const SIDEBAR_W := 456.0


func _sidebar_fits() -> bool:
	var view := get_viewport_rect().size
	return view.x >= 1800.0


func _icon(row: HBoxContainer, caption: String, path: String, id: String) -> Button:
	var btn := UIKit.icon_button(path, caption)
	# The bar fills the row: every icon takes an equal share of the width.
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if id == "email" and GameState.unread_count() > 0:
		btn.text = "%s (%d)" % [caption, GameState.unread_count()]
	btn.pressed.connect(func():
		page = id
		if id == "email":
			AudioDirector.play_sfx("sfx_paper_rustle")
		_show_page()
	)
	row.add_child(btn)
	return btn


func _show_page() -> void:
	for child in body.get_children():
		child.queue_free()
	match page:
		"market":
			_market()
		"shop":
			_shop()
		"email":
			_email()
		"listings":
			_listings()
		"life":
			_life()
		"books":
			_books(books_tab)
		"forest":
			body.add_child(preload("res://scripts/forest_page.gd").new())
		"manager":
			body.add_child(preload("res://scripts/shop_page.gd").new())
	_sidebar()
	_wire_screen()


func _wire_screen() -> void:
	var icons: Array = []
	var pages: Array = []
	var power: Button = null
	for node in find_children("*", "Button", true, false):
		var btn := node as Button
		if btn.get_parent() == body:
			pages.append(btn)
		elif btn.text == "x":
			power = btn
		elif btn.get_parent() is HBoxContainer:
			icons.append(btn)
	var rows: Array = []
	if not icons.is_empty():
		rows.append(icons)
	if not pages.is_empty():
		rows.append(pages)
	if power != null:
		rows.append([power])
	if not rows.is_empty():
		UIKit.link_grid(rows)


func _market() -> void:
	var goods := ItemDB.trade_goods()
	# MARKET_LAYOUT_V2: the details column leaves room for two lines of copy at each step.
	var list := ItemList.new()
	list.position = Vector2(12, 12)
	list.size = Vector2(400, 524)
	list.custom_minimum_size = Vector2(400, 200)
	list.focus_mode = Control.FOCUS_ALL
	list.add_theme_font_override("font", UIKit.body_font())
	list.add_theme_font_size_override("font_size", UIKit.small_px(24))
	list.add_theme_color_override("font_color", UIKit.DARK)
	list.add_theme_color_override("font_hovered_color", UIKit.DARK)
	list.add_theme_color_override("font_selected_color", UIKit.CREAM_CARD)
	for good in goods:
		var id := str(good.get("id", ""))
		list.add_item("%s  $%d" % [good.get("name", id), GameState.price_of(id)])
		list.set_item_metadata(list.item_count - 1, id)
	list.item_selected.connect(func(idx):
		selected = str(list.get_item_metadata(idx))
		_show_page()
	)
	body.add_child(list)
	if selected == "" and not goods.is_empty():
		selected = str(goods[0].get("id", ""))
	var item := ItemDB.get_item(selected)
	var title := UIKit.label(str(item.get("name", "Market")), 28, UIKit.DARK, "title", false)
	title.position = Vector2(440, 4)
	title.size = Vector2(480, 44)
	title.custom_minimum_size = Vector2(minf(480.0, maxf(180.0, float(title.text.length()) * 16.0)), 44)
	body.add_child(title)
	var flavor := UIKit.label(str(item.get("flavor", "")), 28, UIKit.DARK)
	flavor.position = Vector2(440, 50)
	flavor.size = Vector2(760, 96)
	flavor.custom_minimum_size = Vector2(480, 44)
	flavor.max_lines_visible = 2
	body.add_child(flavor)
	chart = Control.new()
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chart.position = Vector2(440, 150)
	chart.size = Vector2(700, 80)
	chart.draw.connect(_draw_chart)
	body.add_child(chart)
	var series: Array = GameState.history.get(selected, [])
	var yesterday := ""
	if series.size() >= 2:
		yesterday = "Yesterday $%d" % int(round(float(series[series.size() - 2])))
	if not GameState.perk("spreadsheet_brain"):
		yesterday = ""
	var ylbl := UIKit.label("%s's note: %s    You have %d" % [GameState.first_name(), yesterday if yesterday != "" else "no head for prices", int(GameState.goods.get(selected, 0))], 28, UIKit.BLUE)
	ylbl.position = Vector2(440, 240)
	ylbl.size = Vector2(760, 44)
	ylbl.custom_minimum_size = Vector2(480, 44)
	body.add_child(ylbl)
	var buy := UIKit.button("BUY", UIKit.GREEN)
	buy.position = Vector2(440, 470)
	buy.size = Vector2(170, 56)
	buy.custom_minimum_size = Vector2(170, 56)
	buy.position = Vector2(440, 470)
	buy.size = Vector2(180, 56)
	buy.custom_minimum_size = Vector2(180, 56)
	buy.pressed.connect(_buy)
	body.add_child(buy)
	var sell := UIKit.button("SELL", UIKit.TERRA)
	sell.position = Vector2(630, 470)
	sell.size = Vector2(170, 56)
	sell.custom_minimum_size = Vector2(170, 56)
	sell.position = Vector2(630, 470)
	sell.size = Vector2(180, 56)
	sell.custom_minimum_size = Vector2(180, 56)
	sell.pressed.connect(_sell)
	body.add_child(sell)
	var nxt := UIKit.button("Next day", UIKit.BLUE)
	nxt.position = Vector2(820, 470)
	nxt.size = Vector2(170, 56)
	nxt.custom_minimum_size = Vector2(170, 56)
	nxt.position = Vector2(820, 470)
	nxt.size = Vector2(180, 56)
	nxt.custom_minimum_size = Vector2(180, 56)
	nxt.pressed.connect(func():
		if not GameState.day_ended.is_connected(_show_day_card):
			GameState.day_ended.connect(_show_day_card)
		if pop and is_instance_valid(pop):
			pop.queue_free()
		GameState.advance_day()
		AudioDirector.play_sfx("sfx_notification_soft")
		_show_page()
		_refresh_money()
	)
	body.add_child(nxt)
	if not GameState.buyer_offer.is_empty():
		var offer: Dictionary = GameState.buyer_offer
		var line := UIKit.label("%s wants a %s for $%d. %s" % [offer.get("name", ""), ItemDB.display_name(str(offer.get("item", ""))), int(offer.get("price", 0)), offer.get("line", "")], 24, UIKit.DARK)
		line.name = "Offer"
		line.position = Vector2(440, 296)
		line.size = Vector2(760, 150)
		line.custom_minimum_size = Vector2(490, 44)
		line.max_lines_visible = 3
		body.add_child(line)
		var take := UIKit.button("Sell to them", UIKit.MUSTARD, UIKit.DARK)
		take.position = Vector2(1010, 470)
		take.size = Vector2(180, 56)
		take.custom_minimum_size = Vector2(180, 56)
		take.pressed.connect(_sell_buyer)
		body.add_child(take)


func _draw_chart() -> void:
	if chart == null or not is_instance_valid(chart) or not chart.is_inside_tree():
		return
	var series: Array = GameState.history.get(selected, [])
	var rect := Rect2(Vector2.ZERO, chart.size)
	chart.draw_rect(rect, Color("F7F1E4"))
	if series.size() < 2:
		return
	var lo := float(series[0])
	var hi := lo
	for value in series:
		lo = minf(lo, float(value))
		hi = maxf(hi, float(value))
	if abs(hi - lo) < 0.5:
		hi = lo + 1.0
	var pts: PackedVector2Array = []
	for i in series.size():
		var x := 12.0 + float(i) / float(series.size() - 1) * (chart.size.x - 24.0)
		var y := chart.size.y - 16.0 - (float(series[i]) - lo) / (hi - lo) * (chart.size.y - 32.0)
		pts.append(Vector2(x, y))
	chart.draw_polyline(pts, UIKit.GREEN, 3.0, true)
	chart.draw_circle(pts[pts.size() - 1], 5.0, UIKit.GREEN)


func _buy() -> void:
	var err := GameState.buy_good(selected)
	if err != "":
		_pop_text(err, UIKit.LOSS)
		AudioDirector.play_sfx("sfx_invalid_placement")
		return
	AudioDirector.play_sfx("sfx_trade_buy")
	_pop_text("-$%d" % GameState.price_of(selected), UIKit.LOSS)
	_refresh_money()
	_show_page()
	SaveManager.save_game()


func _sell() -> void:
	var result := GameState.sell_good(selected)
	if result.has("error"):
		_pop_text(str(result["error"]), UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_trade_sell")
	var profit := int(result.get("profit", 0))
	AudioDirector.play_sfx("sfx_trade_profit_chime" if profit >= 0 else "sfx_trade_loss_thud")
	_pop_text("+$%d" % int(result.get("gain", 0)), UIKit.GREEN if profit >= 0 else UIKit.LOSS)
	_refresh_money()
	_show_page()
	SaveManager.save_game()


func _sell_buyer() -> void:
	var result := GameState.sell_to_buyer()
	if result.has("error"):
		_pop_text(str(result["error"]), UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_sell_click")
	AudioDirector.play_sfx("sfx_cash_gain")
	_pop_text("%s +$%d" % [result.get("buyer", "Sold"), int(result.get("gain", 0))], UIKit.GREEN)
	_refresh_money()
	_show_page()
	SaveManager.save_game()


func _shop() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 12)
	scroll.size = Vector2(1200, 530)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	for decor in ItemDB.decor_goods():
		var id := str(decor.get("id", ""))
		var card := PanelContainer.new()
		var box := UIKit.style(Color("F7F1E4"), 12)
		box.shadow_size = 0
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", box)
		card.custom_minimum_size = Vector2(590, 150)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 4)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var name := UIKit.label(str(decor.get("name", id)), 26, UIKit.DARK, "title", false)
		name.custom_minimum_size = Vector2(400, 36)
		name.clip_text = true
		text.add_child(name)
		var flavor := UIKit.label(str(decor.get("flavor", "")), 24, UIKit.DARK, "small")
		flavor.custom_minimum_size = Vector2(400, 0)
		flavor.max_lines_visible = 3
		text.add_child(flavor)
		var price := int(decor.get("price", 0))
		var buy := UIKit.button("$%d" % price, UIKit.MUSTARD, UIKit.DARK)
		buy.custom_minimum_size = Vector2(130, 56)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.pressed.connect(_buy_decor.bind(id))
		row.add_child(buy)
		grid.add_child(card)


func _email() -> void:
	AudioDirector.play_sfx("sfx_email_ping")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 12)
	scroll.size = Vector2(1200, 530)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size = Vector2(1180, 0)
	scroll.add_child(column)
	if GameState.inbox.is_empty():
		column.add_child(UIKit.label("The inbox is quiet.", 28, UIKit.DARK, "small"))
		return
	var mails: Array = GameState.inbox.duplicate()
	mails.reverse()
	for mail in mails:
		var card := PanelContainer.new()
		var box := UIKit.style(Color("F7F1E4") if bool(mail.get("read", false)) else Color("FFF4E0"), 10)
		box.shadow_size = 0
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", box)
		card.custom_minimum_size = Vector2(1180, 0)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		card.add_child(col)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		col.add_child(head)
		head.add_child(UIKit.avatar(str(mail.get("from", "?")).left(1), UIKit.TERRA if str(mail.get("from", "")).begins_with("Marge") else UIKit.BLUE, 40))
		var subject := UIKit.label(str(mail.get("subject", "")), 28, UIKit.DARK, "title", false)
		subject.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		subject.custom_minimum_size = Vector2(500, 40)
		subject.clip_text = true
		head.add_child(subject)
		var from := UIKit.label(str(mail.get("from", "")), 24, UIKit.WOOD, "small", false)
		from.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(from)
		var text := UIKit.label(str(mail.get("body", "")), 24, UIKit.DARK, "small")
		text.custom_minimum_size = Vector2(1140, 0)
		text.max_lines_visible = 8
		col.add_child(text)
		mail["read"] = true
		column.add_child(card)


func _life() -> void:
	# What Dana is earning for: the next milestone, and the ladder of her own things.
	var Life = load("res://scripts/life.gd")
	# The ladder fills the page: the sidebar has its own column.
	var view := get_viewport_rect().size
	if view.x < 8.0:
		view = Vector2(1280, 800)
	var wide := view.x - 104.0 - (SIDEBAR_W + 12.0 if _sidebar_fits() else 0.0) - 44.0
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	scroll.layout_mode = 1
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 12
	scroll.offset_top = 12
	scroll.offset_right = -12
	scroll.offset_bottom = -12
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(wide, 0)
	scroll.add_child(column)
	var goal: Dictionary = Life.progress()
	var head := PanelContainer.new()
	var head_box := UIKit.style(Color("E4EBD6"), 10)
	head_box.shadow_size = 0
	head_box.content_margin_left = 16
	head_box.content_margin_right = 16
	head_box.content_margin_top = 10
	head_box.content_margin_bottom = 10
	head.add_theme_stylebox_override("panel", head_box)
	head.custom_minimum_size = Vector2(wide, 0)
	column.add_child(head)
	var head_col := VBoxContainer.new()
	head_col.add_theme_constant_override("separation", 6)
	head.add_child(head_col)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	head_col.add_child(title_row)
	title_row.add_child(UIKit.label(str(goal.get("name", "")), 30, UIKit.DARK, "title", false))
	var earned_text := "earned $%s" % _commas(int(goal.get("earned", 0)))
	if int(goal.get("at", 0)) > 0:
		earned_text = "earned $%s of $%s" % [_commas(int(goal.get("earned", 0))), _commas(int(goal.get("at", 0)))]
	var earned_label := UIKit.label(earned_text, 24, UIKit.SAGE, "small", false)
	earned_label.name = "LifeEarned"
	earned_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(earned_label)
	var bar := ProgressBar.new()
	bar.name = "LifeBar"
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = float(goal.get("share", 0.0))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(wide - 40.0, 18)
	var trough := UIKit.style(Color("D9D2C4"), 9)
	trough.shadow_size = 0
	var fill := UIKit.style(UIKit.SAGE, 9)
	fill.shadow_size = 0
	bar.add_theme_stylebox_override("background", trough)
	bar.add_theme_stylebox_override("fill", fill)
	head_col.add_child(bar)
	var pet_note := ""
	if Life.upkeep() > 0:
		pet_note = "   ·   Pickle: $%d a day" % Life.upkeep()
	var fleet := UIKit.label("Trucks %d   ·   Counters %d   ·   Tips +%d%%   ·   Jobs on the board +%d%s" % [Life.trucks(), Life.shops(), int(round((Life.tip_mult() - 1.0) * 100.0)), Life.board_bonus(), pet_note], 22, UIKit.DARK, "small", false)
	head_col.add_child(fleet)
	if Life.billionaire():
		head_col.add_child(UIKit.label("A billionaire, since day %d. From a garage and a borrowed truck." % int((Life.state().get("milestones", {}) as Dictionary).get("billion", 0)), 24, UIKit.TERRA, "small", false))
	elif Life.sold_up():
		head_col.add_child(UIKit.label("Sold to Grayline on day %d. The dented van is still in the drive." % int((Life.state().get("milestones", {}) as Dictionary).get("sold", 0)), 24, UIKit.TERRA, "small", false))
	elif Life.millionaire():
		var empire_line := "A millionaire, since day %d. The town is small. The map is not." % int((Life.state().get("milestones", {}) as Dictionary).get("million", 0))
		if Life.income() > 0 or Life.yield_rate() > 0.0:
			empire_line += "   Rents and contracts $%s a night, the jar grows %d%%." % [_commas(Life.income()), int(round(Life.yield_rate() * 100.0))]
		head_col.add_child(UIKit.label(empire_line, 24, UIKit.TERRA, "small", false))
	if Life.buyout_open():
		var offer := UIKit.button("Take Grayline's $250,000,000", UIKit.NIGHT)
		offer.name = "LifeBuyout"
		offer.custom_minimum_size = Vector2(420, 52)
		offer.pressed.connect(func():
			var result: Dictionary = Life.take_buyout()
			if result.has("error"):
				return
			AudioDirector.play_sfx("sfx_cash_gain")
			SaveManager.save_game()
			GameState.emit_signal("toast_requested", "Sold. Grayline keep the lettering. Pickle keeps the van.")
			_show_page()
		)
		head_col.add_child(offer)
	var ladder: Array = Life.rungs()
	if Life.millionaire():
		ladder = Life.all_rungs()
	var empire_started := false
	for row in ladder:
		if not empire_started and Life.is_empire(str(row.get("id", ""))):
			empire_started = true
			column.add_child(UIKit.label("After the million: the road to a billion", 28, UIKit.DARK, "title", false))
		var id := str(row.get("id", ""))
		var owned: bool = Life.bought(id)
		var why: String = Life.blocker(row)
		var open_rung := why == "" or why.begins_with("short by")
		var card := PanelContainer.new()
		var box := UIKit.style(Color("E4EBD6") if owned else (Color("F7F1E4") if open_rung else Color("EDE7DD")), 10)
		box.shadow_size = 0
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", box)
		card.custom_minimum_size = Vector2(wide, 0)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		card.add_child(line)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 12)
		text.add_child(name_row)
		name_row.add_child(UIKit.label("%s%s" % ["✓ " if owned else "", row.get("name", id)], 28, UIKit.DARK if (owned or open_rung) else Color("9A9388"), "title", false))
		var price_text := "$%s" % _commas(int(row.get("cost", 0)))
		if owned:
			price_text = "day %d" % int((Life.state().get("bought", {}) as Dictionary).get(id, 0))
		var price := UIKit.label(price_text, 24, UIKit.SAGE, "small", false)
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_row.add_child(price)
		var blurb := UIKit.label(str(row.get("blurb", "")), 24, UIKit.DARK, "small")
		blurb.custom_minimum_size = Vector2(wide - 240.0, 0)
		text.add_child(blurb)
		var effect_text := str(row.get("effect", ""))
		if not owned and why != "":
			effect_text += "   ·   %s" % why
		var effect_label := UIKit.label(effect_text, 22, UIKit.BLUE if owned or why == "" else UIKit.WOOD, "small")
		effect_label.custom_minimum_size = Vector2(wide - 240.0, 0)
		text.add_child(effect_label)
		if not owned:
			var buy := UIKit.button("Buy", UIKit.SAGE if why == "" else UIKit.BLUE)
			buy.name = "LifeBuy_" + id
			buy.custom_minimum_size = Vector2(160, 56)
			buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			buy.disabled = why != ""
			buy.pressed.connect(func():
				var result: Dictionary = Life.buy(id)
				if result.has("error"):
					AudioDirector.play_sfx("sfx_invalid_placement")
					return
				AudioDirector.play_sfx("sfx_cash_gain")
				SaveManager.save_game()
				GameState.emit_signal("toast_requested", "%s. %s" % [str(row.get("name", id)), str(row.get("effect", ""))])
				_show_page()
			)
			line.add_child(buy)
		column.add_child(card)
	var log: Array = Life.state().get("log", [])
	if not log.is_empty():
		var bits: Array = []
		for entry in log.slice(0, 4):
			bits.append("day %d, %s" % [int(entry.get("day", 0)), str(entry.get("line", ""))])
		column.add_child(UIKit.label("So far: " + " ".join(bits), 22, UIKit.WOOD, "small"))


static func _commas(n: int) -> String:
	var text := str(absi(n))
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


func _listings() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(12, 12)
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(1180, 0)
	body.add_child(column)
	for office in Tuning.get_value("offices", []):
		var id := str(office.get("id", ""))
		var met := GameState.office_gate_met(id)
		var here := GameState.office_id == id
		var card := PanelContainer.new()
		var box := UIKit.style(Color("E4EBD6") if here else Color("F7F1E4"), 10)
		box.shadow_size = 0
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", box)
		card.custom_minimum_size = Vector2(1180, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		text.add_child(head)
		head.add_child(UIKit.label(str(office.get("name", id)), 28, UIKit.DARK, "title", false))
		var price := UIKit.label("$%s" % str(office.get("cost", 0)), 24, UIKit.SAGE, "small", false)
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(price)
		text.add_child(UIKit.label("Earned $%d / $%d   ·   Jobs %d / %d   ·   Rep %d / %d" % [
			GameState.total_earned, int(office.get("earned", 0)), GameState.jobs_done, int(office.get("jobs", 0)), GameState.rep_rank(), int(office.get("rep", 0))], 24, UIKit.DARK, "small", false))
		if not here and bool(office.get("playable", false)):
			var btn := UIKit.button("Move in" if met else "Locked", UIKit.SAGE if met else UIKit.BLUE)
			btn.custom_minimum_size = Vector2(200, 56)
			btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn.disabled = not met
			btn.pressed.connect(_move_office.bind(id))
			row.add_child(btn)
		elif here:
			var tag := UIKit.label("You are here", 24, UIKit.SAGE, "title", false)
			tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(tag)
		else:
			var later := UIKit.label("Coming later", 24, UIKit.WOOD, "small", false)
			later.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(later)
		column.add_child(card)


func _buy_decor(id: String) -> void:
	var err := GameState.buy_decor(id)
	if err != "":
		_pop_text(err, UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_buy_click")
	_pop_text("In the box", UIKit.GREEN)
	_refresh_money()
	SaveManager.save_game()


func _move_office(id: String) -> void:
	var err := GameState.try_buy_office(id)
	if err != "":
		_pop_text(err, UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_success_chime")
	SaveManager.save_game()
	# GameState.office_changed already rebuilt the room; a second build would eat the L6 beat.
	_close()


func _money() -> String:
	return "●  $%d" % GameState.money


func _refresh_money() -> void:
	if balance:
		balance.text = _money()


func _sidebar() -> void:
	# The right-hand column only exists in a wide window; the pages fit the
	# small one on their own. Ads, Marge's tip, the weather, a price mover.
	if not _sidebar_fits():
		return
	var old := body.get_parent().get_node_or_null("DeskSide")
	if old != null:
		old.queue_free()
	var side := VBoxContainer.new()
	side.name = "DeskSide"
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_theme_constant_override("separation", 14)
	body.get_parent().add_child(side)
	side.layout_mode = 1
	side.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	side.offset_left = -16 - SIDEBAR_W
	side.offset_right = -16
	side.offset_top = 188
	side.offset_bottom = -16
	var day := GameState.day
	var ads: Array = [
		["TropicalForest", "Lightning deal, no rush. %s" % _deal_name(), "Order from the Forest page. It waits for you.", UIKit.SAGE, "box"],
		["Toucan Prime", "Express shipping, free, forever.", "One payment. The toucan naps on your parcels.", UIKit.MUSTARD, "bird"],
		["Corner Movers", "Jobs on the board, new every morning.", "Pad the fragile. Heavy goes low.", UIKit.TERRA, "truck"],
		["The Till", "Serve by hand for the whole tip.", "Click a customer before the till rings them up.", UIKit.BLUE, "mug"],
	]
	var ad: Array = ads[day % ads.size()]
	var next_rung: Dictionary = load("res://scripts/life.gd").next_rung()
	if next_rung.is_empty():
		side.add_child(_side_card(str(ad[0]), str(ad[1]), str(ad[2]), ad[3], str(ad[4])))
	else:
		# The ad's slot goes to what Dana is saving for, so the column still fits.
		side.add_child(_side_card("Next up", "%s, $%s" % [str(next_rung.get("name", "")), _commas(int(next_rung.get("cost", 0)))], str(next_rung.get("effect", "")), UIKit.TERRA, "note"))
	side.add_child(_side_card("Marge's tip", Books.tip_for(day), "", UIKit.WOOD, "note"))

	var weather := "clear"
	for job in GameState.generated_jobs:
		var drive: Dictionary = JobDB.get_drive(str(job.get("drive", "")))
		if not drive.is_empty():
			weather = str(drive.get("weather", "clear"))
			break
	side.add_child(_side_card("Weather", "Rain on the board today." if weather == "rain" else "Clear skies for the drives.", "Rain makes stops longer. Brake early." if weather == "rain" else "A good day for the alley.", UIKit.BLUE, "rain" if weather == "rain" else "sun"))
	var mover := _price_mover()
	if not mover.is_empty():
		side.add_child(_side_card("Market", "%s %s %d%%" % [mover.get("name", ""), "up" if float(mover.get("change", 0.0)) > 0.0 else "down", absi(int(round(float(mover.get("change", 0.0)) * 100.0)))], "Yesterday $%d, today $%d." % [int(mover.get("before", 0)), int(mover.get("now", 0))], UIKit.SAGE if float(mover.get("change", 0.0)) > 0.0 else UIKit.LOSS, "chart"))


func _deal_name() -> String:
	var Catalog = preload("res://scripts/catalog.gd")
	var deals: Array = Catalog.deal_skus(GameState.day)
	if deals.is_empty():
		return "Today's deal is napping."
	return "%s today." % Catalog.display_name(str(deals[0]))


func _price_mover() -> Dictionary:
	var best: Dictionary = {}
	for good in ItemDB.trade_goods():
		var id := str(good.get("id", ""))
		var series: Array = GameState.history.get(id, [])
		if series.size() < 2:
			continue
		var before := float(series[series.size() - 2])
		var now := float(series[series.size() - 1])
		if before <= 0.0:
			continue
		var change := (now - before) / before
		if best.is_empty() or absf(change) > absf(float(best.get("change", 0.0))):
			best = {"name": good.get("name", id), "change": change, "before": before, "now": now}
	return best


var books_tab := "ledger"


func _books(sub := "ledger") -> void:
	# The books in three sheets: the ledger (today, this week, all time), the
	# record, and the accountant: hire one, set the wage, audit, fire.
	books_tab = sub
	# The sheets take the whole page: the width up to the sidebar's column,
	# the height to the bottom of the screen.
	var view := get_viewport_rect().size
	if view.x < 8.0:
		view = Vector2(1280, 800)
	# The body is the screen less the bezel and the icon bar; the sidebar's
	# column takes 484 of it in a wide window.
	var body_w := view.x - 104.0 - (SIDEBAR_W + 12.0 if _sidebar_fits() else 0.0)
	var wide := body_w - 24.0
	var column := VBoxContainer.new()
	column.name = "BooksScroll"
	column.add_theme_constant_override("separation", 10)
	body.add_child(column)
	column.layout_mode = 1
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12
	column.offset_top = 12
	column.offset_right = -12
	column.offset_bottom = -12
	var tall := view.y >= 900.0
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	for pair in [["ledger", "Ledger"], ["record", "The record"], ["staff", "The accountant"], ["gear", "Gear"], ["journal", "Journal"]]:
		var tab_btn := UIKit.button(str(pair[1]), UIKit.TERRA if str(pair[0]) == sub else UIKit.WOOD)
		tab_btn.name = "Books_" + str(pair[0])
		tab_btn.custom_minimum_size = Vector2(150, 50)
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var which := str(pair[0])
		tab_btn.pressed.connect(func():
			books_tab = which
			_show_page()
		)
		tabs.add_child(tab_btn)
	if sub == "staff":
		var staff := _accountant_panel(wide)
		staff.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(staff)
		return
	if sub == "record":
		var record := _record_panel(wide)
		record.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(record)
		return
	if sub == "gear":
		column.add_child(_gear_panel(wide))
		return
	if sub == "journal":
		column.add_child(_journal_panel(wide))
		return
	var today := GameState.money - int(GameState.day_log.get("money_start", GameState.money))
	var week_pay := 0
	var week_shop := 0
	var week_trade := 0
	var week_jobs := 0
	for day_row in GameState.ledger_days:
		week_pay += int(day_row.get("job_pay", 0))
		week_shop += int(day_row.get("shop_earned", 0))
		week_trade += int(day_row.get("trade_profit", 0))
		week_jobs += int(day_row.get("jobs", 0))
	var L: Dictionary = GameState.ledger
	var ledger_rows: Array = [
		["", "Today", "Last 7 days", "All time"],
		["Jobs done", str(int(GameState.day_log.get("jobs", 0))), str(week_jobs), str(GameState.jobs_done)],
		["Job pay", "$%d" % int(GameState.day_log.get("job_pay", 0)), "$%s" % _commas(week_pay), "$%s" % _commas(int(L.get("job_pay", 0)))],
		["Shop takings", "$%d" % GameState.shop_today, "$%s" % _commas(week_shop), "$%s" % _commas(int(L.get("shop_earned", 0)))],
		["Trading", "$%d" % int(GameState.day_log.get("trade_profit", 0)), "$%s" % _commas(week_trade), "$%s" % _commas(int(L.get("trade_profit", 0)))],
		["Rent, wages", "", "", "$%s, $%s" % [_commas(int(L.get("rent", 0))), _commas(int(L.get("wages", 0)))]],
		["Found, sundries", "", "", "$%s, $%s" % [_commas(int(L.get("saved", 0))), _commas(int(L.get("sundries", 0)))]],
		["Jar", "%s$%d" % ["+" if today >= 0 else "−", absi(today)], "", "$%s now, $%s earned" % [_commas(GameState.money), _commas(GameState.total_earned)]],
	]
	column.add_child(_books_panel("Ledger", UIKit.SAGE, ledger_rows, wide))
	# The week, a day a row, fills the rest of the sheet.
	var days: Array = [["", "Jobs", "Job pay", "Shop", "Trading", "Rent", "Books"]]
	var recent: Array = GameState.ledger_days.duplicate()
	recent.reverse()
	# Five days fit under the ledger at 1080; seven from 1200 up.
	while recent.size() > (7 if view.y >= 1200.0 else 5):
		recent.pop_back()
	for day_row in recent:
		var books_row: Dictionary = day_row.get("books", {})
		var books_text := ""
		if not books_row.is_empty():
			books_text = "−$%d wage" % int(books_row.get("wage", 0))
			if int(books_row.get("saved", 0)) > 0:
				books_text += ", +$%d found" % int(books_row.get("saved", 0))
			if int(books_row.get("sundries", 0)) > 0:
				books_text += ", sundries $%d" % int(books_row.get("sundries", 0))
		days.append(["Day %d" % int(day_row.get("day", 0)), str(int(day_row.get("jobs", 0))), "$%d" % int(day_row.get("job_pay", 0)), "$%d" % int(day_row.get("shop_earned", 0)), "$%d" % int(day_row.get("trade_profit", 0)), "$%d" % int(day_row.get("rent", 0)), books_text])
	if days.size() == 1:
		days.append(["No day closed yet", "", "", "", "", "", "Press Next day on the Market page and the week fills in here."])
	if tall:
		var week_panel := _books_panel("The week, day by day", UIKit.WOOD, days, wide)
		week_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(week_panel)


func _record_panel(wide: float) -> PanelContainer:
	var S: Dictionary = GameState.stats
	var hands := GameState.handling_level()
	var record_rows: Array = [
		["Hands", "level %d, %d pieces handled, %d dropped" % [hands, int(S.get("handled", 0)), int(S.get("broken", 0))]],
		["Rep", "%d star%s, rank %d" % [GameState.rep_stars, "" if GameState.rep_stars == 1 else "s", GameState.rep_rank()]],
		["Owners", "%d shove%s, %d thrown out, %d claim%s won, %d counter-sued" % [int(S.get("attacked", 0)), "" if int(S.get("attacked", 0)) == 1 else "s", int(S.get("thrown", 0)), int(S.get("sue_won", 0)), "" if int(S.get("sue_won", 0)) == 1 else "s", int(S.get("counter_sued", 0))]],
		["Grace", "%d forgiven, %d grudge%s, %d paid back" % [int(S.get("forgiven", 0)), int(S.get("grudges", 0)), "" if int(S.get("grudges", 0)) == 1 else "s", int(S.get("payback", 0)) + int(S.get("payback_jobs", 0))]],
		["Shop", "%d served by hand, %d perfect makes, %d asks granted" % [int(S.get("served_by_hand", 0)), int(S.get("perfect_makes", 0)), int(S.get("asks_granted", 0))]],
		["Bench", "%d made, %d sold, %d masterpiece%s" % [int(S.get("crafts_made", 0)), int(S.get("crafts_sold", 0)), int(S.get("masterpieces", 0)), "" if int(S.get("masterpieces", 0)) == 1 else "s"]],
		["Road", "%d busted, %d raid%s, %d pocketed" % [int(S.get("busted", 0)), int(S.get("raids", 0)), "" if int(S.get("raids", 0)) == 1 else "s", int(S.get("pocketed", 0))]],
	]
	record_rows.append(["Streak", "%d clean job%s in a row now, best %d" % [GameState.streak, "" if GameState.streak == 1 else "s", int(S.get("best_streak", 0))]])
	var table: Array = Extras.standings()
	var league_text: Array = []
	for i in table.size():
		league_text.append("%d. %s %d" % [i + 1, table[i].get("name", ""), int(table[i].get("points", 0))])
	record_rows.append(["League", "week %d:  %s%s" % [int(GameState.league.get("week", 1)), "  ·  ".join(league_text), "  ·  top this week, +10% on board jobs" if bool(GameState.league.get("leader", false)) else ""]])
	record_rows.append(["Journal", "%d of %d entries" % [GameState.achievements.size(), Extras.achievement_list().size()]])
	record_rows.append(["Tip", Books.tip_for(GameState.day)])
	return _books_panel("The record", UIKit.TERRA, record_rows, wide)


func _gear_panel(wide: float) -> PanelContainer:
	# Kit bought once and kept: one rule each.
	var panel := PanelContainer.new()
	panel.name = "GearPanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := UIKit.style(Color("F7F1E4"), 10, 3, UIKit.BLUE)
	box.shadow_size = 0
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(wide, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(UIKit.label("Gear  ·  %d of %d" % [GameState.gear.size(), Extras.gear_list().size()], 28, UIKit.BLUE, "title", false))
	for row in Extras.gear_list():
		var id := str(row.get("id", ""))
		var owned := Extras.gear_has(id)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		col.add_child(line)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 2)
		line.add_child(text)
		text.add_child(UIKit.label("%s%s  ·  %s" % ["✓ " if owned else "", row.get("name", id), row.get("effect", "")], 24, UIKit.DARK if owned else UIKit.WOOD, "title", false))
		var blurb := UIKit.label(str(row.get("blurb", "")), 24, UIKit.DARK, "small")
		blurb.custom_minimum_size = Vector2(wide - 260, 0)
		text.add_child(blurb)
		var buy := UIKit.button("Yours" if owned else "Buy $%d" % int(row.get("cost", 0)), UIKit.SAGE if owned else UIKit.BLUE)
		buy.name = "Gear_" + id
		buy.disabled = owned
		buy.custom_minimum_size = Vector2(170, 52)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.pressed.connect(func():
			var result: Dictionary = Extras.buy_gear(id)
			AudioDirector.play_sfx("sfx_coins_award" if not result.has("error") else "sfx_invalid_placement")
			GameState.emit_signal("toast_requested", str(result.get("error", result.get("said", ""))))
			Extras.check_achievements()
			SaveManager.save_game()
			_show_page()
			_refresh_money()
		)
		line.add_child(buy)
	return panel


func _journal_panel(wide: float) -> PanelContainer:
	# The journal: every entry, the ones earned in ink.
	var panel := PanelContainer.new()
	panel.name = "JournalPanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := UIKit.style(Color("F7F1E4"), 10, 3, UIKit.MUSTARD)
	box.shadow_size = 0
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(wide, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(UIKit.label("Journal  ·  %d of %d" % [GameState.achievements.size(), Extras.achievement_list().size()], 28, UIKit.MUSTARD, "title", false))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 0)
	col.add_child(grid)
	for row in Extras.achievement_list():
		var done := Extras.unlocked(str(row.get("id", "")))
		var cell := UIKit.label("%s %s: %s" % ["✓" if done else "·", row.get("name", ""), row.get("blurb", "")], 22, UIKit.DARK if done else Color("9A9388"), "small", false)
		cell.clip_text = true
		cell.custom_minimum_size = Vector2((wide - 60.0) * 0.5, 0)
		grid.add_child(cell)
	return panel


func _books_panel(title: String, accent: Color, table: Array, wide: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := UIKit.style(Color("F7F1E4"), 10, 3, accent)
	box.shadow_size = 0
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(wide, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(UIKit.label(title, 28, accent, "title", false))
	var grid := GridContainer.new()
	grid.columns = (table[0] as Array).size() if not table.is_empty() else 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 0)
	col.add_child(grid)
	# Columns share the panel's width and never push past it: a two-column
	# sheet wraps its text, a wider table clips.
	var inner := wide - 40.0 - 18.0 * float(grid.columns - 1)
	for row in table:
		for i in (row as Array).size():
			var wrap := grid.columns == 2 and i == 1
			var cell := UIKit.label(str(row[i]), 24, UIKit.DARK if i > 0 else UIKit.WOOD, "small", wrap)
			if grid.columns == 2:
				cell.custom_minimum_size = Vector2(110 if i == 0 else inner - 110.0, 0)
			elif grid.columns == 4:
				cell.custom_minimum_size = Vector2(200.0 if i == 0 else (inner - 200.0) / 3.0, 0)
			else:
				# The week: a narrow day column, even middles, and the last column (the books) twice a share.
				var share := (inner - 130.0) / float(grid.columns)
				cell.custom_minimum_size = Vector2(130.0 if i == 0 else (share * 2.0 if i == grid.columns - 1 else share), 0)
			if not wrap:
				cell.clip_text = true
			grid.add_child(cell)
	return panel


func _accountant_panel(wide: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "AccountantPanel"
	var box := UIKit.style(Color("F7F1E4"), 10, 3, UIKit.NIGHT)
	box.shadow_size = 0
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(wide, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(UIKit.label("The accountant", 28, UIKit.NIGHT, "title", false))
	if Books.hired():
		var acc: Dictionary = GameState.accountant
		var head := UIKit.label("%s, $%d a night (asks $%d). Since day %d: $%s found, wage paid %d night%s." % [acc.get("name", ""), int(acc.get("wage", 0)), int(acc.get("ask", 0)), int(acc.get("hired_day", 1)), _commas(int(acc.get("saved", 0))), int(acc.get("nights", 0)), "" if int(acc.get("nights", 0)) == 1 else "s"], 24, UIKit.DARK, "small")
		head.custom_minimum_size = Vector2(wide - 40, 0)
		col.add_child(head)
		var mood := Books.mood()
		var said := UIKit.label("\"%s\"" % Books.mood_line(), 24, UIKit.LOSS if mood == "caught" else (UIKit.SAGE if mood == "happy" else UIKit.WOOD), "small")
		said.custom_minimum_size = Vector2(wide - 40, 0)
		col.add_child(said)
		if bool(acc.get("caught", false)):
			col.add_child(UIKit.label("The audit found $%d of 'sundries' in their hand. Fire them and half comes back, or raise the wage and hope." % int(acc.get("skimmed", 0)), 24, UIKit.LOSS, "small", false))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		col.add_child(row)
		var less := UIKit.button("Pay $5 less", UIKit.WOOD)
		less.name = "WageLess"
		less.custom_minimum_size = Vector2(180, 52)
		less.pressed.connect(func():
			Books.set_wage(int(GameState.accountant.get("wage", 0)) - 5)
			SaveManager.save_game()
			_show_page()
		)
		row.add_child(less)
		var more := UIKit.button("Pay $5 more", UIKit.SAGE)
		more.name = "WageMore"
		more.custom_minimum_size = Vector2(180, 52)
		more.pressed.connect(func():
			Books.set_wage(int(GameState.accountant.get("wage", 0)) + 5)
			SaveManager.save_game()
			_show_page()
		)
		row.add_child(more)
		var audit := UIKit.button("Audit ($%d)" % Books.audit_cost(), UIKit.NIGHT)
		audit.name = "AuditBooks"
		audit.custom_minimum_size = Vector2(170, 52)
		audit.pressed.connect(func():
			var result: Dictionary = Books.audit()
			AudioDirector.play_sfx("sfx_paper_rustle")
			GameState.emit_signal("toast_requested", str(result.get("error", result.get("said", ""))))
			SaveManager.save_game()
			_show_page()
			_refresh_money()
		)
		row.add_child(audit)
		var fire := UIKit.button("Fire", UIKit.LOSS)
		fire.name = "FireAccountant"
		fire.custom_minimum_size = Vector2(120, 52)
		fire.pressed.connect(func():
			var result: Dictionary = Books.fire()
			GameState.emit_signal("toast_requested", str(result.get("error", result.get("said", ""))))
			SaveManager.save_game()
			_show_page()
			_refresh_money()
		)
		row.add_child(fire)
		return panel
	var intro := UIKit.label("Nobody keeps the books. An accountant costs a wage every night and finds savings on the day's takings. Pay what they ask. Pay less and some of them help themselves; you'll see 'sundries' until you audit.", 24, UIKit.DARK, "small")
	intro.custom_minimum_size = Vector2(wide - 40, 0)
	col.add_child(intro)
	for cand in Books.candidates():
		var card := HBoxContainer.new()
		card.add_theme_constant_override("separation", 12)
		col.add_child(card)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 2)
		card.add_child(text)
		text.add_child(UIKit.label("%s  ·  asks $%d a night" % [cand.get("name", ""), int(cand.get("ask", 0))], 24, UIKit.DARK, "title", false))
		var pitch := UIKit.label(str(cand.get("pitch", "")), 24, UIKit.WOOD, "small")
		pitch.custom_minimum_size = Vector2(wide - 260, 0)
		text.add_child(pitch)
		var hire := UIKit.button("Hire", UIKit.NIGHT)
		hire.name = "Hire_" + str(cand.get("id", ""))
		hire.custom_minimum_size = Vector2(150, 52)
		hire.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var id := str(cand.get("id", ""))
		var ask := int(cand.get("ask", 30))
		hire.pressed.connect(func():
			var result: Dictionary = Books.hire(id, ask)
			AudioDirector.play_sfx("sfx_notification_soft")
			GameState.emit_signal("toast_requested", str(result.get("error", result.get("said", ""))))
			SaveManager.save_game()
			_show_page()
		)
		card.add_child(hire)
	return panel


func _side_card(title: String, headline: String, text: String, accent: Color, picture: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UIKit.style(Color("F7F1E4"), 12, 3, accent)
	box.shadow_size = 0
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var art := Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(72, 72)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.draw.connect(_draw_picture.bind(art, picture, accent))
	row.add_child(art)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(UIKit.label(title, 24, accent, "title", false))
	var head := UIKit.label(headline, 24, UIKit.DARK, "small")
	head.custom_minimum_size = Vector2(330, 0)
	head.max_lines_visible = 2
	col.add_child(head)
	if text != "":
		var line := UIKit.label(text, 24, UIKit.WOOD, "small")
		line.custom_minimum_size = Vector2(330, 0)
		line.max_lines_visible = 2
		col.add_child(line)
	return card


func _draw_picture(art: Control, picture: String, accent: Color) -> void:
	var c := Vector2(36, 36)
	art.draw_circle(c, 34.0, Color(accent, 0.18))
	match picture:
		"box":
			art.draw_rect(Rect2(14, 22, 44, 34), UIKit.CARD)
			art.draw_rect(Rect2(14, 22, 44, 8), UIKit.CARD.darkened(0.2))
			art.draw_rect(Rect2(33, 22, 6, 34), Color("B98451"))
		"bird":
			art.draw_circle(c + Vector2(-4, 4), 18.0, UIKit.DARK)
			art.draw_circle(c + Vector2(10, -10), 10.0, UIKit.DARK)
			art.draw_colored_polygon(PackedVector2Array([c + Vector2(16, -12), c + Vector2(38, -6), c + Vector2(16, -2)]), UIKit.MUSTARD)
			art.draw_circle(c + Vector2(12, -12), 2.5, UIKit.CREAM_CARD)
		"truck":
			art.draw_rect(Rect2(10, 24, 34, 24), UIKit.TERRA)
			art.draw_rect(Rect2(44, 32, 16, 16), UIKit.TERRA.darkened(0.15))
			art.draw_circle(Vector2(20, 52), 6.0, UIKit.DARK)
			art.draw_circle(Vector2(50, 52), 6.0, UIKit.DARK)
		"mug":
			art.draw_rect(Rect2(18, 22, 28, 30), UIKit.CREAM_CARD)
			art.draw_arc(Vector2(48, 36), 9.0, -PI * 0.5, PI * 0.5, 10, UIKit.CREAM_CARD, 5.0)
			art.draw_rect(Rect2(18, 22, 28, 6), Color("5A3B2A"))
		"note":
			art.draw_rect(Rect2(18, 16, 36, 40), UIKit.MUSTARD)
			for i in 3:
				art.draw_line(Vector2(24, 28 + i * 9), Vector2(48, 28 + i * 9), UIKit.DARK, 2.0)
		"rain":
			art.draw_circle(c + Vector2(-8, -6), 12.0, UIKit.CREAM_CARD)
			art.draw_circle(c + Vector2(8, -8), 14.0, UIKit.CREAM_CARD)
			art.draw_rect(Rect2(c.x - 20, c.y - 6, 40, 12), UIKit.CREAM_CARD)
			for i in 4:
				art.draw_line(c + Vector2(-14 + i * 9, 10), c + Vector2(-18 + i * 9, 22), UIKit.BLUE, 3.0)
		"sun":
			art.draw_circle(c, 14.0, UIKit.MUSTARD)
			for i in 8:
				var a := float(i) * TAU / 8.0
				art.draw_line(c + Vector2(cos(a), sin(a)) * 19.0, c + Vector2(cos(a), sin(a)) * 27.0, UIKit.MUSTARD, 3.0)
		"chart":
			var pts := PackedVector2Array([Vector2(12, 52), Vector2(26, 40), Vector2(38, 46), Vector2(50, 28), Vector2(60, 22)])
			art.draw_polyline(pts, accent, 4.0, true)
		_:
			art.draw_circle(c, 10.0, accent)


func _show_day_card(summary: Dictionary) -> void:
	# The night between two days: what the day brought, and what tomorrow holds.
	var old := get_node_or_null("DayCard")
	if old != null:
		old.queue_free()
	var dim := ColorRect.new()
	dim.name = "DayCard"
	dim.color = Color(UIKit.NIGHT, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 22))
	dim.add_child(card)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_left = -380
	card.offset_right = 380
	card.offset_top = -40
	card.offset_bottom = 40
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	column.add_child(head)
	head.add_child(UIKit.avatar("%d" % int(summary.get("day", 1)), UIKit.BLUE, 48))
	var title := UIKit.label("Day %d, closed" % int(summary.get("day", 1)), 34, UIKit.DARK, "title", false)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var delta := int(summary.get("money_end", 0)) - int(summary.get("money_start", 0))
	var money_line := UIKit.label(("+$%d" if delta >= 0 else "-$%d") % absi(delta), 34, UIKit.SAGE if delta >= 0 else UIKit.LOSS, "title", false)
	money_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(money_line)
	var rows: Array = []
	var jobs := int(summary.get("jobs", 0))
	if jobs > 0:
		rows.append("%d job%s done for $%d. %s" % [jobs, "" if jobs == 1 else "s", int(summary.get("job_pay", 0)), ("First up: %s." % summary.get("best_job", "")) if str(summary.get("best_job", "")) != "" else ""])
	else:
		rows.append("No jobs today. The truck stayed in the drive.")
	var visitors := int(summary.get("shop_visitors", 0))
	if visitors > 0:
		rows.append("The shop served %d, %d of them by hand, for $%d." % [visitors, int(summary.get("served_by_hand", 0)), int(summary.get("shop_earned", 0))])
	var trade := int(summary.get("trade_profit", 0))
	if trade != 0:
		rows.append(("Trading cleared $%d." if trade > 0 else "Trading lost $%d. Buy low, sell high.") % absi(trade))
	var decor := int(summary.get("decor", 0))
	if decor > 0:
		rows.append("%d new piece%s of decor on the way." % [decor, "" if decor == 1 else "s"])
	for goal in summary.get("goals", []):
		rows.append("Goal done: %s." % goal)
	var life_night: Dictionary = summary.get("life", {})
	if int(life_night.get("truck_pay", 0)) > 0:
		rows.append("%d other truck%s ran today and brought in $%d." % [int(life_night.get("trucks", 0)), "" if int(life_night.get("trucks", 0)) == 1 else "s", int(life_night.get("truck_pay", 0))])
	if int(life_night.get("shop_pay", 0)) > 0:
		rows.append("The other counter%s took $%d." % ["" if int(life_night.get("shops", 0)) == 1 else "s", int(life_night.get("shop_pay", 0))])
	if int(life_night.get("income", 0)) > 0:
		rows.append("Rents and contracts brought in $%s." % _commas(int(life_night.get("income", 0))))
	if int(life_night.get("grown", 0)) > 0:
		rows.append("Dilys's funds grew the jar by $%s." % _commas(int(life_night.get("grown", 0))))
	if str(life_night.get("event", "")) != "":
		rows.append(str(life_night.get("event", "")))
	if int(life_night.get("upkeep", 0)) > 0:
		rows.append("Pickle ate $%d of it." % int(life_night.get("upkeep", 0)))
	var books: Dictionary = summary.get("books", {})
	if not books.is_empty():
		if bool(books.get("left", false)):
			rows.append("%s wasn't paid and walked out%s." % [books.get("name", "The accountant"), (" with $%d" % int(books.get("parting", 0))) if int(books.get("parting", 0)) > 0 else ""])
		else:
			var kept := "%s kept the books for $%d" % [books.get("name", "The accountant"), int(books.get("wage", 0))]
			if int(books.get("saved", 0)) > 0:
				kept += " and found $%d in savings" % int(books.get("saved", 0))
			rows.append(kept + ".")
			if bool(books.get("raise", false)):
				rows.append("%s mentioned a raise. Twice." % books.get("name", ""))
		if int(books.get("sundries", 0)) > 0:
			rows.append("Sundries  −$%d." % int(books.get("sundries", 0)))
	if int(summary.get("rent", 0)) > 0:
		if int(summary.get("rent_owed", 0)) > 0:
			rows.append("Rent of $%d came due and the jar was short: $%d owed, the shop is shut until it's paid." % [int(summary.get("rent", 0)), int(summary.get("rent_owed", 0))])
		else:
			rows.append("Rent paid: $%d to Hollis Property." % int(summary.get("rent", 0)))
	elif int(summary.get("rent_owed", 0)) > 0:
		rows.append("Rent still owed: $%d. The shop stays shut." % int(summary.get("rent_owed", 0)))
	else:
		rows.append("Rent due in %d day%s: $%d." % [GameState.rent_due_in(), "" if GameState.rent_due_in() == 1 else "s", GameState.rent_amount()])
	if str(summary.get("tip", "")) != "":
		rows.append("Marge's tip: %s" % summary.get("tip", ""))
	for row in rows:
		var line := UIKit.label(str(row), 24, UIKit.DARK, "small")
		line.custom_minimum_size = Vector2(700, 0)
		column.add_child(line)
	var next_job := str(summary.get("next_job", ""))
	var tomorrow := UIKit.label("Tomorrow's board: %s, and more." % next_job if next_job != "" else "A fresh board goes up in the morning.", 24, UIKit.BLUE, "small")
	tomorrow.custom_minimum_size = Vector2(700, 0)
	column.add_child(tomorrow)
	var go := UIKit.button("Morning", UIKit.TERRA)
	go.name = "Morning"
	go.custom_minimum_size = Vector2(220, 56)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	go.pressed.connect(func():
		AudioDirector.play_sfx("sfx_ui_click")
		dim.queue_free()
		_pop_text("A new day", UIKit.BLUE)
	)
	column.add_child(go)
	go.grab_focus()


func _pop_text(text: String, color: Color) -> void:
	if pop and is_instance_valid(pop):
		pop.queue_free()
	pop = UIKit.label(text, 32, color, "title")
	pop.position = Vector2(520, 200)
	add_child(pop)
	pop_time = 1.1


func _close() -> void:
	var venue: Dictionary = ItemDB.venues().get(GameState.office_id, {})
	AudioDirector.play_bed(str(venue.get("music", "music_office_build")), str(venue.get("ambience", "")))
	emit_signal("closed")
	queue_free()
