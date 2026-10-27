extends Panel
# The workbench card: Make (recipes with their con colour), Fix up (trade
# goods up a grade for fussy buyers), Shelf (materials) and Journal (skill
# and where the things you made ended up).

const UIKit = preload("res://scripts/ui_kit.gd")
const Workshop = preload("res://scripts/workshop.gd")

const CARD := Vector2(1100, 720)
const CON_COLORS := {
	"red": Color("D9765F"), "orange": Color("E08A3C"), "yellow": Color("E6B655"),
	"blue": Color("7FA3B8"), "green": Color("8FAF7E"), "grey": Color("B9B2A6"),
}

var tab := "make"
var rows: VBoxContainer
var note: Label


func _ready() -> void:
	name = "WorkshopCard"
	add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 18))
	UIKit.pin_center(self, CARD)
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var title := UIKit.label("Workbench", 40, UIKit.DARK, "title", false)
	title.position = Vector2(24, 16)
	add_child(title)
	var skill_tag := UIKit.label("Skill %d  ·  %d made  ·  $%d" % [Workshop.skill(), int(Workshop.state().get("crafts", 0)), GameState.money], 24, UIKit.WOOD, "small", false)
	skill_tag.name = "SkillTag"
	skill_tag.position = Vector2(290, 30)
	add_child(skill_tag)
	var close := UIKit.button("Close", UIKit.DARK)
	close.position = Vector2(CARD.x - 184, 16)
	close.size = Vector2(160, 56)
	close.custom_minimum_size = Vector2(160, 56)
	close.pressed.connect(queue_free)
	add_child(close)
	var x := 24.0
	var tabs: Array = []
	for pair in [["make", "Make"], ["fix", "Fix up"], ["shelf", "Shelf"], ["journal", "Journal"]]:
		var btn := UIKit.button(str(pair[1]), UIKit.TERRA if tab == str(pair[0]) else UIKit.WOOD)
		btn.position = Vector2(x, 80)
		btn.size = Vector2(170, 52)
		btn.custom_minimum_size = Vector2(170, 52)
		btn.pressed.connect(func():
			tab = str(pair[0])
			_build()
		)
		add_child(btn)
		tabs.append(btn)
		x += 180
	note = UIKit.label("", 24, UIKit.BLUE, "small", false)
	note.name = "Note"
	note.position = Vector2(24, CARD.y - 52)
	note.custom_minimum_size = Vector2(CARD.x - 48, 36)
	note.clip_text = true
	add_child(note)
	var scroll := ScrollContainer.new()
	scroll.name = "Rows"
	scroll.position = Vector2(24, 144)
	scroll.size = Vector2(CARD.x - 48, CARD.y - 206)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	rows.custom_minimum_size = Vector2(CARD.x - 72, 0)
	scroll.add_child(rows)
	match tab:
		"fix":
			_fix_rows()
		"shelf":
			_shelf_rows()
		"journal":
			_journal_rows()
		_:
			_make_rows()
	var focus: Array = [close]
	focus.append_array(tabs)
	for child in rows.get_children():
		for kid in child.get_children():
			if kid is Button:
				focus.append(kid)
			for grand in kid.get_children():
				if grand is Button:
					focus.append(grand)
	UIKit.link_focus(focus)


func _card(width: float, tint: Color = Color("F6EEDC")) -> PanelContainer:
	var card := PanelContainer.new()
	var box := UIKit.style(tint, 12)
	box.shadow_size = 0
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(width, 0)
	return card


func _say(text: String, color: Color = UIKit.BLUE) -> void:
	if note:
		note.text = text
		note.add_theme_color_override("font_color", color)


func _materials_line(need: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	for id in need.keys():
		var row := Workshop.material(str(id))
		bits.append("%s %d/%d" % [row.get("name", id), Workshop.have(str(id)), int(need[id])])
	return ", ".join(bits)


func _make_rows() -> void:
	var ask := Workshop.offer()
	if not ask.is_empty() and not bool(ask.get("served", false)):
		var want := _card(CARD.x - 72, Color("E4EBD6"))
		var want_text := UIKit.label("%s wants something %s today, %d%% or better, and pays extra. \"%s\"" % [ask.get("name", ""), ask.get("tag", ""), int(ask.get("min_quality", 94)), ask.get("line", "")], 24, UIKit.DARK, "small")
		want_text.custom_minimum_size = Vector2(CARD.x - 110, 0)
		want.add_child(want_text)
		rows.add_child(want)
	var width := CARD.x - 72
	for recipe in Workshop.recipes():
		if not Workshop.unlocked(recipe):
			continue
		var id := str(recipe.get("id", ""))
		var con := Workshop.con_of(int(recipe.get("level", 1)))
		var con_name := str(con.get("name", "grey"))
		var card := _card(width)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(22, 22)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_box := UIKit.style(CON_COLORS.get(con_name, UIKit.WOOD), 11)
		dot_box.shadow_size = 0
		dot.add_theme_stylebox_override("panel", dot_box)
		row.add_child(dot)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		text.add_child(head)
		head.add_child(UIKit.label(str(recipe.get("name", id)), 28, UIKit.DARK, "title", false))
		var meta := UIKit.label("level %d  ·  %s  ·  sells about $%d" % [int(recipe.get("level", 1)), con_name, int(recipe.get("sell", 0))], 24, UIKit.WOOD, "small", false)
		meta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(meta)
		var need: Dictionary = recipe.get("materials", {})
		var mats := UIKit.label(_materials_line(need), 24, UIKit.SAGE if Workshop.can_afford(need) else UIKit.LOSS, "small", false)
		text.add_child(mats)
		var have := Workshop.made_count(id)
		if have > 0:
			var best := Workshop.best_made(id)
			text.add_child(UIKit.label("On the bench: %d (best %d%%)" % [have, int(best.get("quality", 0))], 24, UIKit.BLUE, "small", false))
		var make := UIKit.button("Make it", UIKit.TERRA)
		make.name = "Make_" + id
		make.custom_minimum_size = Vector2(120, 52)
		make.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		make.pressed.connect(func():
			var result: Dictionary = Workshop.craft(id)
			if bool(result.get("ok", false)):
				AudioDirector.play_sfx("sfx_repair")
				if bool(result.get("masterpiece", false)) or bool(result.get("skill_up", false)):
					AudioDirector.play_sfx("sfx_success_chime")
			else:
				AudioDirector.play_sfx("sfx_invalid_placement")
			SaveManager.save_game()
			_build()
			_say(str(result.get("message", "")), UIKit.SAGE if bool(result.get("ok", false)) else UIKit.LOSS)
		)
		row.add_child(make)
		if have > 0:
			var sell := UIKit.button("Sell", UIKit.SAGE)
			sell.name = "Sell_" + id
			sell.custom_minimum_size = Vector2(110, 52)
			sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sell.pressed.connect(func():
				var to_buyer := not ask.is_empty() and not bool(ask.get("served", false)) and str(ask.get("tag", "")) == str(recipe.get("tag", ""))
				var result: Dictionary = Workshop.sell(id, to_buyer)
				if result.has("error"):
					result = Workshop.sell(id, false)
				if result.has("error"):
					_say(str(result["error"]), UIKit.LOSS)
					return
				AudioDirector.play_sfx("sfx_cash_gain")
				SaveManager.save_game()
				_build()
				_say("$%d from %s. %s" % [int(result.get("pay", 0)), result.get("who", ""), result.get("story", "")], UIKit.SAGE)
			)
			row.add_child(sell)
			if bool(recipe.get("decor", false)):
				var keep := UIKit.button("Keep", UIKit.BLUE)
				keep.custom_minimum_size = Vector2(110, 52)
				keep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				keep.pressed.connect(func():
					var err := Workshop.keep(id)
					if err != "":
						_say(err, UIKit.LOSS)
						return
					AudioDirector.play_sfx("sfx_item_snap")
					SaveManager.save_game()
					_build()
					_say("It's by the door. Place decor puts it where you like.", UIKit.SAGE)
				)
				row.add_child(keep)
		rows.add_child(card)
	if rows.get_child_count() == 0:
		rows.add_child(UIKit.label("Nothing within reach yet.", 28, UIKit.DARK, "small"))


func _fix_rows() -> void:
	var width := CARD.x - 72
	var offer_row: Dictionary = GameState.buyer_offer
	if not offer_row.is_empty():
		var want := _card(width, Color("E4EBD6"))
		var text := UIKit.label("%s wants a %s %s for $%d." % [offer_row.get("name", ""), offer_row.get("grade", "worn"), ItemDB.display_name(str(offer_row.get("item", ""))), int(offer_row.get("price", 0))], 24, UIKit.DARK, "small")
		text.custom_minimum_size = Vector2(width - 40, 0)
		want.add_child(text)
		rows.add_child(want)
	var any := false
	for good in ItemDB.trade_goods():
		var id := str(good.get("id", ""))
		var worn := int(GameState.goods.get(id, 0))
		var restored := Workshop.graded(id, "restored")
		var mint := Workshop.graded(id, "mint")
		if worn + restored + mint <= 0:
			continue
		any = true
		var card := _card(width)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UIKit.label(str(good.get("name", id)), 28, UIKit.DARK, "title", false))
		col.add_child(UIKit.label("worn %d  ·  restored %d  ·  mint %d" % [worn, restored, mint], 24, UIKit.WOOD, "small", false))
		var step_name := "restored" if worn > 0 else "mint"
		var fix := UIKit.button("Fix up to %s" % step_name, UIKit.TERRA)
		fix.name = "Fix_" + id
		fix.custom_minimum_size = Vector2(260, 52)
		fix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fix.pressed.connect(func():
			var result: Dictionary = Workshop.fix_up(id)
			if result.has("error"):
				AudioDirector.play_sfx("sfx_invalid_placement")
				_say(str(result["error"]), UIKit.LOSS)
				return
			AudioDirector.play_sfx("sfx_repair")
			SaveManager.save_game()
			_build()
			_say(str(result.get("message", "")), UIKit.SAGE)
		)
		row.add_child(fix)
		for grade in ["restored", "mint"]:
			if Workshop.graded(id, grade) <= 0:
				continue
			var sell := UIKit.button("Sell %s" % grade, UIKit.SAGE)
			sell.custom_minimum_size = Vector2(190, 52)
			sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sell.pressed.connect(func():
				var result: Dictionary = Workshop.sell_graded(id, grade)
				if result.has("error"):
					_say(str(result["error"]), UIKit.LOSS)
					return
				AudioDirector.play_sfx("sfx_cash_gain")
				SaveManager.save_game()
				_build()
				_say("$%d from %s. %s" % [int(result.get("pay", 0)), result.get("who", ""), result.get("story", "")], UIKit.SAGE)
			)
			row.add_child(sell)
		rows.add_child(card)
	if not any:
		rows.add_child(UIKit.label("Buy a trade good at the market and bring it here. Restored sells for more. Mint, more again.", 28, UIKit.DARK, "small"))


func _shelf_rows() -> void:
	var width := CARD.x - 72
	for mat in Workshop.materials():
		var id := str(mat.get("id", ""))
		var card := _card(width)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UIKit.label("%s  ·  have %d" % [mat.get("name", id), Workshop.have(id)], 28, UIKit.DARK, "title", false))
		col.add_child(UIKit.label(str(mat.get("blurb", "")), 24, UIKit.WOOD, "small", false))
		for count in [1, 5]:
			var buy := UIKit.button("Buy %d  $%d" % [count, int(mat.get("price", 5)) * count], UIKit.MUSTARD, UIKit.DARK)
			buy.name = "Buy_%s_%d" % [id, count]
			buy.custom_minimum_size = Vector2(170, 52)
			buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			buy.pressed.connect(func():
				var err := Workshop.buy_material(id, count)
				if err != "":
					AudioDirector.play_sfx("sfx_invalid_placement")
					_say(err, UIKit.LOSS)
					return
				AudioDirector.play_sfx("sfx_buy_click")
				SaveManager.save_game()
				_build()
				_say("%d %s on the shelf." % [Workshop.have(id), mat.get("name", id)], UIKit.SAGE)
			)
			row.add_child(buy)
		rows.add_child(card)


func _journal_rows() -> void:
	var width := CARD.x - 72
	var s := Workshop.state()
	var intro := _card(width, Color("E4EBD6"))
	var text := UIKit.label("Skill %d. %d made, %d masterpiece%s. Grey recipes teach nothing; yellow and orange teach most. A red make can fail and eat half the materials." % [Workshop.skill(), int(s.get("crafts", 0)), int(s.get("masterpieces", 0)), "" if int(s.get("masterpieces", 0)) == 1 else "s"], 24, UIKit.DARK, "small")
	text.custom_minimum_size = Vector2(width - 40, 0)
	intro.add_child(text)
	rows.add_child(intro)
	var journal: Array = s.get("journal", [])
	if journal.is_empty():
		rows.add_child(UIKit.label("Nothing sold yet. The journal fills with where your things end up.", 28, UIKit.DARK, "small"))
	for entry in journal:
		var card := _card(width)
		var line := UIKit.label("Day %d  ·  %s%s" % [int(entry.get("day", 0)), entry.get("line", ""), ("  (+$%d)" % int(entry.get("pay", 0))) if int(entry.get("pay", 0)) > 0 else ""], 24, UIKit.DARK, "small")
		line.custom_minimum_size = Vector2(width - 40, 0)
		card.add_child(line)
		rows.add_child(card)
