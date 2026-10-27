extends Control

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
	body = Panel.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 12))
	screen.add_child(body)
	body.layout_mode = 1
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 16
	body.offset_top = 188
	body.offset_right = -16
	body.offset_bottom = -16
	_show_page()


func _icon(row: HBoxContainer, caption: String, path: String, id: String) -> Button:
	var btn := UIKit.icon_button(path, caption)
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
	var ylbl := UIKit.label("Dana's note: %s    You have %d" % [yesterday, int(GameState.goods.get(selected, 0))], 28, UIKit.BLUE)
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
	AudioDirector.play_sfx("sfx_buy_click")
	_pop_text("-$%d" % GameState.price_of(selected), UIKit.LOSS)
	_refresh_money()
	_show_page()
	SaveManager.save_game()


func _sell() -> void:
	var result := GameState.sell_good(selected)
	if result.has("error"):
		_pop_text(str(result["error"]), UIKit.LOSS)
		return
	AudioDirector.play_sfx("sfx_sell_click")
	AudioDirector.play_sfx("sfx_cash_gain")
	var profit := int(result.get("profit", 0))
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
	var view := get_viewport_rect().size
	if view.x < 1600.0:
		return
	var side := VBoxContainer.new()
	side.name = "DeskSide"
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_theme_constant_override("separation", 14)
	body.add_child(side)
	side.layout_mode = 1
	side.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	side.offset_left = -470
	side.offset_right = -14
	side.offset_top = 12
	side.offset_bottom = -12
	var day := GameState.day
	var ads: Array = [
		["TropicalForest", "Lightning deal, no rush. %s" % _deal_name(), "Order from the Forest page. It waits for you.", UIKit.SAGE, "box"],
		["Toucan Prime", "Express shipping, free, forever.", "One payment. The toucan naps on your parcels.", UIKit.MUSTARD, "bird"],
		["Corner Movers", "Jobs on the board, new every morning.", "Pad the fragile. Heavy goes low.", UIKit.TERRA, "truck"],
		["The Till", "Serve by hand for the whole tip.", "Click a customer before the till rings them up.", UIKit.BLUE, "mug"],
	]
	var ad: Array = ads[day % ads.size()]
	side.add_child(_side_card(str(ad[0]), str(ad[1]), str(ad[2]), ad[3], str(ad[4])))
	var tips: Array = [
		"Heavy on the bottom, fragile in padding, and the rest sorts itself.",
		"Buy what's cheap today and sleep on it. Prices move overnight.",
		"The alley is quicker. The alley is bumpier. Pick one.",
		"A plant and a lamp raise the vibe more than a second beanbag.",
		"Goals pay cash and Rep. The clipboard keeps the list.",
		"If a box meows, open it before the drive.",
	]
	side.add_child(_side_card("Marge's tip", str(tips[day % tips.size()]), "", UIKit.WOOD, "note"))
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
