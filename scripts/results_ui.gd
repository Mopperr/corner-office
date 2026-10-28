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
			lines.append("Not quite: %s." % ", ".join(wrong.slice(0, 2)))
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
	if int(pay.get("life_extra", 0)) > 0:
		lines.append("Your own people  +$%d" % int(pay.get("life_extra", 0)))
	if int(pay.get("split_loss", 0)) > 0:
		lines.append("Split sets  −$%d" % int(pay.get("split_loss", 0)))
	if int(pay.get("cut", 0)) > 0:
		lines.append("Kept damage  −$%d from tips" % int(pay.get("cut", 0)))
	else:
		lines.append("Damage cut  $0")
	lines.append("Tips you keep  $%d" % int(pay.get("net_tips", 0)))
	lines.append("You take home  $%d" % int(pay.get("total", 0)))
	var stamps := []
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
	var card_size := Vector2(860, 680)
	if vp.y < card_size.y + 16.0:
		card_size.y = maxf(360.0, vp.y - 16.0)
	if vp.x < card_size.x + 16.0:
		card_size.x = maxf(480.0, vp.x - 16.0)
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
	card.custom_minimum_size = Vector2(860, 680)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	add_child(card)
	var title := UIKit.ribbon(str(GameState.payout.get("title", "Job done")), UIKit.TERRA, 40)
	title.position = Vector2(36, 20)
	title.size = Vector2(780, 56)
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
	face.position = Vector2(732, 14)
	card.add_child(face)
	var star_row := UIKit.label("★".repeat(clampi(stars, 0, 3)) + "☆".repeat(3 - clampi(stars, 0, 3)), 44, UIKit.MUSTARD, "title", false)
	star_row.position = Vector2(36, 76)
	star_row.size = Vector2(780, 56)
	star_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(star_row)
	var y := 136.0
	var step := 40.0
	for i in lines.size():
		var is_story := i >= lines.size() - 2
		var row := UIKit.label(lines[i], 24 if is_story else 30, UIKit.BLUE if is_story else UIKit.DARK, "small" if is_story else "body", is_story)
		row.position = Vector2(40, y)
		row.size = Vector2(780, 44 if not is_story else 80)
		if not is_story:
			row.custom_minimum_size = Vector2(minf(760.0, maxf(180.0, float(str(lines[i]).length()) * 17.0)), 40)
		else:
			row.custom_minimum_size = Vector2(760, 0)
			row.max_lines_visible = 2
		row.modulate.a = 0.0
		row.name = "Line%d" % i
		card.add_child(row)
		y += step if not is_story else 64
	var to_ward := GameState.in_hospital()
	var btn := UIKit.button("To the ward" if to_ward else "Back to the office", UIKit.NIGHT if to_ward else UIKit.SAGE)
	btn.position = Vector2(250, 604)
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


func _reveal() -> void:
	var card := get_child(1)
	for i in lines.size():
		var row := card.get_node_or_null("Line%d" % i)
		if row == null:
			continue
		var tw := create_tween()
		tw.tween_interval(0.28 * float(i))
		tw.tween_property(row, "modulate:a", 1.0, 0.25)
		if i == lines.size() - 2:
			tw.tween_callback(func(): AudioDirector.play_sfx("sfx_cash_gain"))
