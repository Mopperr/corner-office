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
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	for child in get_children():
		child.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NIGHT, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var bezel := Panel.new()
	bezel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezel.offset_left = 70
	bezel.offset_top = 36
	bezel.offset_right = -70
	bezel.offset_bottom = -36
	bezel.add_theme_stylebox_override("panel", UIKit.style(Color("E4D3B4"), 28, 8, UIKit.DARK))
	add_child(bezel)
	var screen := Panel.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.offset_left = 28
	screen.offset_top = 28
	screen.offset_right = -28
	screen.offset_bottom = -36
	screen.add_theme_stylebox_override("panel", UIKit.style(UIKit.SCREEN, 12, 0))
	bezel.add_child(screen)
	var bar := Panel.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 52
	bar.add_theme_stylebox_override("panel", UIKit.style(UIKit.BLUE, 8))
	screen.add_child(bar)
	var home := UIKit.label("HomeDesk", 28, UIKit.CREAM_CARD, "crt", false)
	home.position = Vector2(18, 8)
	home.custom_minimum_size = Vector2(220, 36)
	bar.add_child(home)
	balance = UIKit.label(_money(), 28, UIKit.MUSTARD, "crt")
	balance.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	balance.offset_left = -280
	balance.offset_top = 8
	balance.offset_right = -90
	bar.add_child(balance)
	var power := UIKit.button("x", UIKit.TERRA, UIKit.CREAM_CARD)
	power.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	power.offset_left = -64
	power.offset_top = 6
	power.offset_right = -12
	power.offset_bottom = 46
	power.pressed.connect(_close)
	bar.add_child(power)
	var icons := HBoxContainer.new()
	icons.position = Vector2(16, 60)
	icons.add_theme_constant_override("separation", 8)
	screen.add_child(icons)
	_icon(icons, "Market", "res://assets/ui/icons/icon_market.png", "market")
	_icon(icons, "Shop", "res://assets/ui/icons/icon_shop.png", "shop")
	_icon(icons, "Forest", "res://assets/ui/icons/icon_listings.png", "forest")
	_icon(icons, "Till", "res://assets/ui/icons/icon_shop.png", "manager")
	_icon(icons, "Email", "res://assets/ui/icons/icon_email.png", "email")
	_icon(icons, "Listings", "res://assets/ui/icons/icon_listings.png", "listings")
	body = Panel.new()
	body.position = Vector2(20, 156)
	body.size = Vector2(1040, 460)
	body.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 12))
	screen.add_child(body)
	_show_page()


func _icon(row: HBoxContainer, caption: String, path: String, id: String) -> void:
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


func _market() -> void:
	var goods := ItemDB.trade_goods()
	var list := ItemList.new()
	list.position = Vector2(12, 12)
	list.size = Vector2(280, 360)
	list.add_theme_font_override("font", UIKit.body_font())
	list.add_theme_font_size_override("font_size", UIKit.font_px(18))
	for good in goods:
		var id := str(good.get("id", ""))
		list.add_item("%s  $%d" % [good.get("name", id), GameState.price_of(id)])
		list.set_item_metadata(list.item_count - 1, id)
	list.item_selected.connect(func(idx):
		selected = str(list.get_item_metadata(idx))
		_market()
	)
	body.add_child(list)
	if selected == "" and not goods.is_empty():
		selected = str(goods[0].get("id", ""))
	var item := ItemDB.get_item(selected)
	var title := UIKit.label(str(item.get("name", "Market")), 28, UIKit.DARK, "title")
	title.position = Vector2(310, 8)
	title.size = Vector2(500, 36)
	body.add_child(title)
	var flavor := UIKit.label(str(item.get("flavor", "")), 18, UIKit.DARK)
	flavor.position = Vector2(310, 44)
	flavor.size = Vector2(480, 48)
	body.add_child(flavor)
	chart = Control.new()
	chart.position = Vector2(310, 96)
	chart.size = Vector2(460, 100)
	chart.draw.connect(_draw_chart)
	body.add_child(chart)
	var series: Array = GameState.history.get(selected, [])
	var yesterday := ""
	if series.size() >= 2:
		yesterday = "Yesterday $%d" % int(round(float(series[series.size() - 2])))
	var ylbl := UIKit.label("Dana's note: %s" % yesterday, 18, UIKit.BLUE)
	ylbl.position = Vector2(310, 200)
	body.add_child(ylbl)
	var own := UIKit.label("You have %d    Buy $%d    Sell $%d" % [int(GameState.goods.get(selected, 0)), GameState.price_of(selected), GameState.sell_price_of(selected)], 18, UIKit.DARK)
	own.position = Vector2(310, 224)
	own.size = Vector2(500, 28)
	body.add_child(own)
	var buy := UIKit.button("BUY", UIKit.GREEN)
	buy.position = Vector2(310, 330)
	buy.size = Vector2(180, 56)
	buy.pressed.connect(_buy)
	body.add_child(buy)
	var sell := UIKit.button("SELL", UIKit.TERRA)
	sell.position = Vector2(510, 330)
	sell.size = Vector2(180, 56)
	sell.pressed.connect(_sell)
	body.add_child(sell)
	var nxt := UIKit.button("Next day", UIKit.BLUE)
	nxt.position = Vector2(710, 330)
	nxt.size = Vector2(160, 56)
	nxt.pressed.connect(func():
		GameState.advance_day()
		AudioDirector.play_sfx("sfx_notification_soft")
		_pop_text("A new day", UIKit.BLUE)
		_show_page()
		_refresh_money()
	)
	body.add_child(nxt)
	if not GameState.buyer_offer.is_empty():
		var offer: Dictionary = GameState.buyer_offer
		var line := UIKit.label("%s wants a %s for $%d. %s" % [offer.get("name", ""), ItemDB.display_name(str(offer.get("item", ""))), int(offer.get("price", 0)), offer.get("line", "")], 18, UIKit.DARK)
		line.name = "Offer"
		line.position = Vector2(310, 256)
		line.size = Vector2(490, 48)
		line.custom_minimum_size = Vector2(490, 40)
		body.add_child(line)
		var take := UIKit.button("Sell to them", UIKit.MUSTARD, UIKit.DARK)
		take.position = Vector2(820, 256)
		take.size = Vector2(180, 44)
		take.pressed.connect(_sell_buyer)
		body.add_child(take)


func _draw_chart() -> void:
	if chart == null:
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
	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(12, 12)
	grid.size = Vector2(1000, 430)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)
	for decor in ItemDB.decor_goods():
		var id := str(decor.get("id", ""))
		var card := Panel.new()
		card.custom_minimum_size = Vector2(320, 120)
		card.add_theme_stylebox_override("panel", UIKit.style(Color("F7F1E4"), 10))
		var name := UIKit.label(str(decor.get("name", id)), 18, UIKit.DARK, "title")
		name.position = Vector2(12, 8)
		name.size = Vector2(200, 28)
		card.add_child(name)
		var flavor := UIKit.label(str(decor.get("flavor", "")), 18, UIKit.DARK)
		flavor.position = Vector2(12, 38)
		flavor.size = Vector2(200, 48)
		card.add_child(flavor)
		var price := int(decor.get("price", 0))
		var buy := UIKit.button("$%d" % price, UIKit.MUSTARD, UIKit.DARK)
		buy.position = Vector2(210, 36)
		buy.size = Vector2(96, 44)
		buy.pressed.connect(_buy_decor.bind(id))
		card.add_child(buy)
		grid.add_child(card)


func _email() -> void:
	AudioDirector.play_sfx("sfx_email_ping")
	var y := 8.0
	if GameState.inbox.is_empty():
		var empty := UIKit.label("The inbox is quiet.", 18, UIKit.DARK)
		empty.position = Vector2(16, 16)
		body.add_child(empty)
		return
	for mail in GameState.inbox:
		var card := Panel.new()
		card.position = Vector2(12, y)
		card.size = Vector2(1000, 148)
		card.add_theme_stylebox_override("panel", UIKit.style(Color("F7F1E4"), 8))
		var subject := UIKit.label("%s  —  %s" % [mail.get("subject", ""), mail.get("from", "")], 18, UIKit.DARK, "title")
		subject.position = Vector2(10, 6)
		subject.size = Vector2(960, 24)
		card.add_child(subject)
		var text := UIKit.label(str(mail.get("body", "")), 18, UIKit.DARK)
		text.position = Vector2(10, 34)
		text.size = Vector2(960, 104)
		card.add_child(text)
		mail["read"] = true
		body.add_child(card)
		y += 156


func _listings() -> void:
	var y := 12.0
	for office in Tuning.get_value("offices", []):
		var id := str(office.get("id", ""))
		var met := GameState.office_gate_met(id)
		var here := GameState.office_id == id
		var text := "%s   $%s\nEarned $%d / $%d    Jobs %d / %d    Rep %d / %d" % [
			office.get("name", id),
			str(office.get("cost", 0)),
			GameState.total_earned,
			int(office.get("earned", 0)),
			GameState.jobs_done,
			int(office.get("jobs", 0)),
			GameState.rep_rank(),
			int(office.get("rep", 0)),
		]
		var card := UIKit.label(text, 18, UIKit.DARK)
		card.position = Vector2(16, y)
		card.size = Vector2(700, 70)
		body.add_child(card)
		if not here and bool(office.get("playable", false)):
			var btn := UIKit.button("Move in" if met else "Locked", UIKit.SAGE if met else UIKit.BLUE)
			btn.position = Vector2(760, y + 8)
			btn.size = Vector2(200, 48)
			btn.disabled = not met
			btn.pressed.connect(_move_office.bind(id))
			body.add_child(btn)
		elif here:
			var tag := UIKit.label("You are here", 18, UIKit.SAGE, "title")
			tag.position = Vector2(780, y + 16)
			body.add_child(tag)
		y += 86


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
	var host := get_tree().current_scene
	if host != null and host.has_method("show_play"):
		host.show_play()
	_close()


func _money() -> String:
	return "●  $%d" % GameState.money


func _refresh_money() -> void:
	if balance:
		balance.text = _money()


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
