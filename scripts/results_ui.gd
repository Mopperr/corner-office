extends Control

const Tuning = preload("res://scripts/tuning.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

signal closed

var shown := 0
var lines: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(_center_card)
	AudioDirector.play_music("music_office_build")
	var pay: Dictionary = GameState.payout
	if bool(pay.get("busted", false)):
		lines = [
			"A patrol boxed the truck in on %s." % pay.get("job_title", "the job"),
			"The boxes went in the van. No pay.",
			"Fine  −$%d" % int(pay.get("fine", 0)),
			"Rep star lost. A strike on the record.",
			"Spotted %d time%s before they gave chase." % [int(pay.get("spotted", 0)), "" if int(pay.get("spotted", 0)) == 1 else "s"],
			"Marge heard. Of course Marge heard." if not bool(pay.get("shady", false)) else "Sal won't call for a while.",
			"Jar: $%d." % GameState.money,
		]
		_build()
		_center_card()
		_reveal()
		return
	if bool(pay.get("thrown", false)):
		lines = [
			"%s put you through %s." % [pay.get("client", "The client"), pay.get("window", "the window")],
			"Placed before the fall  %d/%d  +$%d" % [int(pay.get("placed", 0)), int(pay.get("total_items", 0)), int(pay.get("base", 0))],
			"St. Bridget's, %d night%s  −$%d" % [int(pay.get("days", 1)), "" if int(pay.get("days", 1)) == 1 else "s", int(pay.get("hospital_bill", 0))],
			"The nurse says: %s." % pay.get("injury", "rest"),
			"The ward is quiet. Think about what comes next.",
			"Jar: $%d." % GameState.money,
		]
		_build()
		_center_card()
		_reveal()
		return
	lines = [
		"Base pay  $%d" % int(pay.get("base", 0)),
		"Box tip  $%d" % int(pay.get("box_tip", 0)),
	]
	var room_score := float(pay.get("room_score", -1.0))
	if room_score >= 0.0:
		lines.append("Room setup %d/100 +$%d" % [int(round(room_score)), int(pay.get("room_tip", 0))])
	if int(pay.get("shortcut", 0)) > 0:
		lines.append("Shortcut  +$%d" % int(pay.get("shortcut", 0)))
	if int(pay.get("bonuses", 0)) > 0:
		var extra := "Bonuses  $%d" % int(pay.get("bonuses", 0))
		if bool(pay.get("cat", false)):
			extra += "   Cat"
		if bool(pay.get("duck", false)):
			extra += "   Duck Friend"
		lines.append(extra)
	if int(pay.get("honks", 0)) > 0:
		lines.append("Friendly honks  +$%d" % int(pay.get("honk_pay", 0)))
	if int(pay.get("rooms_total", 0)) > 0:
		lines.append("In the right room  %d/%d  +$%d" % [int(pay.get("rooms_right", 0)), int(pay.get("rooms_total", 0)), int(pay.get("room_pay", 0))])
		var wrong: Array = pay.get("rooms_wrong", [])
		if not wrong.is_empty():
			# One example, short, so the line keeps to its column.
			var example := str(wrong[0])
			if example.length() > 34:
				example = example.left(31) + "..."
			lines.append("Not quite: %s%s" % [example, "" if wrong.size() == 1 else " and %d more" % (wrong.size() - 1)])
	if int(pay.get("caught_cut", 0)) > 0:
		lines.append("Seen pocketing  −$%d and a rep star" % int(pay.get("caught_cut", 0)))
	if int(pay.get("crushed", 0)) > 0:
		lines.append("Crushed under the load  %d piece%s" % [int(pay.get("crushed", 0)), "" if int(pay.get("crushed", 0)) == 1 else "s"])
	if int(pay.get("broken", 0)) > 0:
		lines.append("Dropped  %d piece%s" % [int(pay.get("broken", 0)), "" if int(pay.get("broken", 0)) == 1 else "s"])
	if int(pay.get("sue_won", 0)) > 0:
		lines.append("Small claims, the shove  +$%d" % int(pay.get("sue_won", 0)))
	elif int(pay.get("counter_sued", 0)) > 0:
		lines.append("Counter-sued for fraud  −$%d and two rep stars" % int(pay.get("counter_sued", 0)))
	elif bool(pay.get("attacked", false)):
		lines.append("Shoved over, let it go")
	elif int(pay.get("pocketed", 0)) > 0:
		lines.append("In the bag  %d piece%s, about $%d to Sal" % [int(pay.get("pocketed", 0)), "" if int(pay.get("pocketed", 0)) == 1 else "s", int(pay.get("loot_value", 0))])
	var rush: Dictionary = pay.get("rush", {})
	if not rush.is_empty():
		lines.append("Rush job, %ds of %ds: made it" % [int(rush.get("took", 0)), int(rush.get("budget", 0))] if bool(rush.get("made", false)) else "Rush job, %ds of %ds: too slow  −$%d" % [int(rush.get("took", 0)), int(rush.get("budget", 0)), int(pay.get("rush_off", 0))])
	var heirloom: Dictionary = pay.get("heirloom", {})
	if not heirloom.is_empty():
		lines.append(("The %s arrived whole  +$%d" if bool(heirloom.get("whole", false)) else "The %s came marked  −$%d and a rep star") % [str(heirloom.get("name", "heirloom")).to_lower(), int(heirloom.get("amount", 0))])
	var nosy: Dictionary = pay.get("nosy", {})
	if not nosy.is_empty():
		lines.append("The neighbour saw nothing to report  +$%d" % int(nosy.get("amount", 0)) if bool(nosy.get("clean", false)) else "The neighbour saw you at the bag")
	var wish: Dictionary = pay.get("wish", {})
	if not wish.is_empty():
		lines.append(("As asked  +$%d" % int(wish.get("amount", 0))) if bool(wish.get("met", false)) else "They asked: \"%s\" Not this time." % wish.get("text", ""))
	var streak: Dictionary = pay.get("streak", {})
	if int(streak.get("count", 0)) >= 2:
		lines.append("Clean run ×%d  +$%d" % [int(streak.get("count", 0)), int(streak.get("amount", 0))])
	elif bool(streak.get("broken", false)):
		lines.append("The clean run ends here.")
	if int(pay.get("league_points", 0)) > 0:
		lines.append("Movers' League  +%d points" % int(pay.get("league_points", 0)))
	var haul: Dictionary = pay.get("haul", {})
	if not haul.is_empty():
		lines.append("Long haul  %s, %d miles  +$%d" % [haul.get("city", ""), int(haul.get("miles", 0)), int(haul.get("pay", 0))])
	if int(pay.get("life_extra", 0)) > 0:
		lines.append("Your own people  +$%d" % int(pay.get("life_extra", 0)))
	var network: Dictionary = pay.get("network", {})
	# First name only: the card's lines are one column wide.
	var who := str(network.get("client", "They")).split(" ")[0]
	if int(network.get("lost", 0)) > 0:
		lines.append(Narrative.why_result("lost").format({"client": who}))
	elif int(network.get("added", 0)) > 0:
		lines.append(Narrative.why_result("told" if bool(network.get("told", false)) else "known").format({"client": who}))
	if int(pay.get("split_loss", 0)) > 0:
		lines.append("Split sets  −$%d" % int(pay.get("split_loss", 0)))
	if int(pay.get("cut", 0)) > 0:
		lines.append("Kept damage  −$%d from tips" % int(pay.get("cut", 0)))
	else:
		lines.append("Damage cut  $0")
	lines.append("Tips you keep  $%d" % int(pay.get("net_tips", 0)))
	lines.append("You take home  $%d" % int(pay.get("total", 0)))
	var stamps := []
	if bool(pay.get("perfect", false)):
		stamps.append("PERFECT MOVE")
	if str(pay.get("stamp", "")) != "":
		stamps.append(pay.get("stamp"))
	if bool(pay.get("all_fine", false)):
		stamps.append("Careful Hands")
	if bool(pay.get("cat", false)):
		stamps.append("Cat")
	if bool(pay.get("duck", false)):
		stamps.append("Duck Friend")
	if float(pay.get("room_score", -1.0)) >= float(Tuning.get_value("stacking.room_complete", 90.0)):
		stamps.append("ROOM COMPLETE")
	if not stamps.is_empty():
		var packed := PackedStringArray()
		for stamp in stamps:
			packed.append(str(stamp))
		lines.append("Stamps: " + ", ".join(packed))
	lines.append("Rep stars +%d   (rank %d)" % [int(pay.get("stars", 1)), GameState.rep_rank()])
	var condition := int(pay.get("condition", 100))
	var def: Dictionary = GameState.job.get("def", {})
	var client := str(def.get("client", "the client"))
	var verdict: String = load("res://scripts/client_party.gd").finish_line(def, condition, int(pay.get("rooms_right", 0)), int(pay.get("rooms_total", 0)))
	if verdict != "":
		lines.append(verdict)
	elif condition >= 90:
		lines.append("%s walks the room twice and says nothing, which is the good kind of nothing." % client)
	elif condition >= 70:
		lines.append("%s finds the scuff, shrugs, and puts the kettle on." % client)
	else:
		lines.append("%s says 'well' in a way that means several things." % client)
	lines.append("Jobs done: %d.  Jar: $%d.  Earned so far: $%s." % [GameState.jobs_done, GameState.money, UIKit.commas(GameState.total_earned)])
	_build()
	_center_card()
	_reveal()


func _center_card() -> void:
	var card := get_node_or_null("Card") as Control
	if card == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 8.0 or vp.y < 8.0:
		vp = Vector2(1280, 720)
	layout_mode = 0
	position = Vector2.ZERO
	size = vp
	var card_size: Vector2 = card.custom_minimum_size
	# A card taller than the window shrinks as a whole, so the button at
	# its foot stays on screen instead of the card being cut off.
	var fit := minf(1.0, minf((vp.y - 16.0) / maxf(card_size.y, 1.0), (vp.x - 16.0) / maxf(card_size.x, 1.0)))
	card.pivot_offset = card_size * 0.5
	card.scale = Vector2(fit, fit)
	card.set_meta("fit_scale", Vector2(fit, fit))
	card.layout_mode = 1
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_left = -card_size.x * 0.5
	card.offset_top = -card_size.y * 0.5
	card.offset_right = card_size.x * 0.5
	card.offset_bottom = card_size.y * 0.5
	card.position = (vp - card_size) * 0.5
	card.size = card_size


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NIGHT, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	UIKit.fill(dim, 0, 0, 0, 0)
	var card := Panel.new()
	card.name = "Card"
	var photos := _has_photos()
	card.custom_minimum_size = Vector2(960, 860) if photos else Vector2(900, 760)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	add_child(card)
	# The room as it was and as you left it, side by side under the stars.
	var top := 136.0
	if photos:
		var pair := HBoxContainer.new()
		pair.name = "Photos"
		pair.add_theme_constant_override("separation", 20)
		pair.position = Vector2(40, 136)
		card.add_child(pair)
		for key in ["before", "after"]:
			var frame := PanelContainer.new()
			var paper := UIKit.style(Color("FFFDF7"), 10, 3, UIKit.WOOD)
			paper.content_margin_left = 6
			paper.content_margin_right = 6
			paper.content_margin_top = 6
			paper.content_margin_bottom = 6
			frame.add_theme_stylebox_override("panel", paper)
			pair.add_child(frame)
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", 4)
			frame.add_child(column)
			var pic := TextureRect.new()
			pic.texture = GameState.job_photos[key]
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic.custom_minimum_size = Vector2(416, 200)
			column.add_child(pic)
			var caption := UIKit.label("Before" if key == "before" else "After", 24, UIKit.WOOD, "small", false)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(caption)
		top = 136.0 + 254.0
	var title := UIKit.ribbon(str(GameState.payout.get("title", "Job done")), UIKit.TERRA, 40)
	# The ribbon stops short of Dana's portrait instead of running under it.
	title.position = Vector2(36, 20)
	title.size = Vector2(724, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var stars := int(GameState.payout.get("stars", 1))
	# Dana's face for the day: proud of three stars, happy with two, tired
	# after one, and still surprised if she was shoved.
	var expression := "proud" if stars >= 3 else ("happy" if stars == 2 else "tired")
	if bool(GameState.payout.get("attacked", false)):
		expression = "surprised"
	if bool(GameState.payout.get("busted", false)):
		expression = "tired"
	var face := UIKit.portrait(112, expression)
	face.name = "ResultsFace"
	face.position = Vector2(772, 14)
	card.add_child(face)
	var star_row := UIKit.label("★".repeat(clampi(stars, 0, 3)) + "☆".repeat(3 - clampi(stars, 0, 3)), 44, UIKit.MUSTARD, "title", false)
	star_row.position = Vector2(36, 76)
	star_row.size = Vector2(820, 56)
	star_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(star_row)
	# Two columns: the money on the left down to what you take home, the
	# stamps, stars and the rest on the right; the story lines run full
	# width beneath. A thrown or busted card has only its own few lines.
	var story_from := maxi(0, lines.size() - 2)
	var money_end := story_from
	for i in lines.size():
		if str(lines[i]).begins_with("You take home"):
			money_end = i + 1
			break
	var columns := money_end < story_from
	var left_y := top
	var right_y := top
	# The money and the extras first; the story lines go under whichever
	# column ran longer, and the card grows to hold it all.
	var story_y := 0.0
	var card_h := card.custom_minimum_size.y
	for i in lines.size():
		var is_story := i >= story_from
		var text := str(lines[i])
		var home := text.begins_with("You take home")
		var row: Label
		if is_story:
			if story_y <= 0.0:
				story_y = maxf(left_y, right_y) + 14.0
			row = UIKit.label(text, 24, UIKit.BLUE, "small", true)
			row.position = Vector2(40, story_y + 64.0 * float(i - story_from))
			row.size = Vector2(820, 80)
			row.custom_minimum_size = Vector2(800, 0)
			row.max_lines_visible = 2
		elif columns and i >= money_end:
			row = UIKit.label(text, 25, UIKit.WOOD, "small", true)
			var right_lines := _lines_for(text, row.get_theme_font_size("font_size"), 290.0, 3)
			row.max_lines_visible = right_lines
			row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row.position = Vector2(620, right_y)
			row.custom_minimum_size = Vector2(290, 0)
			var right_tall := float(row.get_theme_font_size("font_size")) * 1.45 * float(right_lines) + 6.0
			row.size = Vector2(290, right_tall)
			right_y += right_tall + 2.0
		else:
			row = UIKit.label(text, 32 if home else 28, UIKit.TERRA if home else UIKit.DARK, "title" if home else "body", false)
			var width := 560.0 if columns else 820.0
			# A long line wraps onto a second line rather than losing its end to an ellipsis.
			var money_lines := 1 if home else _lines_for(text, row.get_theme_font_size("font_size"), width, 2)
			if money_lines > 1:
				row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.max_lines_visible = money_lines
			row.clip_text = true
			row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row.position = Vector2(40, left_y)
			# Out of the tree a label does not know its line height yet; the font size does.
			var tall := float(row.get_theme_font_size("font_size")) * 1.45 * float(money_lines) + 8.0
			row.custom_minimum_size = Vector2(width, 40.0 if money_lines == 1 else tall)
			left_y += (38.0 if not home else 44.0) + (tall - 40.0 if money_lines > 1 else 0.0)
		row.modulate.a = 0.0
		row.name = "Line%d" % i
		# The width is applied again once the row is in the tree: out of it,
		# a label keeps the minimum size it was first given (the helper's
		# estimate of its text width), so a long line would run under the rule.
		var want := row.custom_minimum_size
		card.add_child(row)
		row.size = Vector2(want.x, maxf(want.y, row.size.y))
	if columns:
		# A hairline between the columns.
		var rule := ColorRect.new()
		rule.color = Color(UIKit.WOOD, 0.35)
		rule.position = Vector2(602, top + 4.0)
		rule.size = Vector2(2, maxf(left_y, right_y) - top - 4.0)
		card.add_child(rule)
	var story_count := lines.size() - story_from
	var need := (story_y + 64.0 * float(story_count) if story_y > 0.0 else maxf(left_y, right_y)) + 100.0
	if need > card_h:
		card_h = need
		card.custom_minimum_size.y = card_h
	var to_ward := GameState.in_hospital()
	var btn := UIKit.button("To the ward" if to_ward else "Back to the office", UIKit.NIGHT if to_ward else UIKit.SAGE)
	btn.position = Vector2(270, card_h - 76.0)
	btn.size = Vector2(360, 56)
	btn.custom_minimum_size = Vector2(360, 56)
	btn.pressed.connect(func():
		GameState.job = {}
		GameState.payout = {}
		GameState.set_mode("hospital" if GameState.in_hospital() else "office")
		SaveManager.save_game()
		emit_signal("closed")
	)
	card.add_child(btn)
	UIKit.link_focus([btn])
	UIKit.pop_in(card, 0.26)


func _lines_for(text: String, px: int, width: float, cap: int) -> int:
	# How many lines a label needs, from the text's rough width at its font size.
	var per_line := maxf(8.0, width / (float(px) * 0.5))
	return clampi(int(ceil(float(text.length()) / per_line)), 1, cap)


func _has_photos() -> bool:
	return GameState.job_photos.has("before") and GameState.job_photos.has("after") and GameState.job_photos["before"] != null and GameState.job_photos["after"] != null


func _reveal() -> void:
	var card := get_child(1)
	for i in lines.size():
		var row := card.get_node_or_null("Line%d" % i)
		if row == null:
			continue
		var tw := create_tween()
		tw.tween_interval(0.12 * float(i))
		tw.tween_property(row, "modulate:a", 1.0, 0.22)
		if i == lines.size() - 2:
			tw.tween_callback(func(): AudioDirector.play_sfx("sfx_cash_gain"))
