extends Control
# The ending, after the last delivery: the arc's closing moment, the people
# who know the counter now, and the credits, then back to the office to
# keep playing. The game never locks; this is the bow on it.

signal closed

var _page := 0
var _pages: Array = []


func _ready() -> void:
	AudioDirector.play_music("music_credits_reprise")
	_pages = _build_pages()
	_show()


func _build_pages() -> Array:
	var pages: Array = []
	var beat: Dictionary = {}
	for entry in GameState.slice_beats():
		if str((entry as Dictionary).get("level_id", "")) == "L22":
			beat = entry
			break
	var who := GameState.player_name()
	var first := who.split(" ")[0]
	var arrival := str(beat.get("arrival", "A young founder has bought the old garage. They look nervous. %s knows that face." % first))
	var moment := str(beat.get("moment", "%s hands over the sticky note stack and writes: 'You're more ready than you think.'" % first))
	pages.append({"title": "The Last Delivery", "lines": [arrival, "", moment.replace(" Credits.", "")]})
	var known := GameState.network.size()
	var names: Array = []
	for name in GameState.network:
		if not str(name).ends_with("'s friend"):
			names.append(str(name))
	var roll := "Nobody yet. The next one will." if names.is_empty() else ", ".join(names.slice(0, mini(names.size(), 8))) + (" and %d more" % (names.size() - 8) if names.size() > 8 else "")
	pages.append({"title": "%d people know the counter" % known, "lines": [
		"Laid off on a Tuesday. The garage opened on a Wednesday with a counter out front and nobody at it.",
		"",
		"Every job was somebody who would know where it was.",
		roll,
		"",
		"$%s earned  ·  %d moves  ·  rep %d" % [_money(GameState.total_earned), GameState.jobs_done, GameState.rep_rank()],
	]})
	var copy: Dictionary = _json_file("res://data/narrative/credits.json")
	var lines: Array = []
	for person in copy.get("people", []):
		var name := str(person.get("name", ""))
		var role := str(person.get("role", ""))
		if name == "":
			continue
		lines.append(name if role == "" else "%s (%s)" % [name, role])
	lines.append("")
	lines.append("Fonts: Fredoka, Nunito, and VT323, SIL Open Font License.")
	lines.append("Music and sound: original, made for Corner Office.")
	pages.append({"title": str(copy.get("headline", "Created by Andrew's Helpers (Grok Bots)")), "lines": lines})
	pages.append({"title": "From Garage Startup to Corner Office", "lines": [
		"One box at a time.",
		"",
		"The board is still pinned by the bench, the kettle is still on, and the street knows the name now.",
		"Keep going as long as you like.",
	]})
	return pages


func _show() -> void:
	for child in get_children():
		# Out of the tree at once, so the old page's button is not found
		# while the new one is being built.
		remove_child(child)
		child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.16, 0.14, 0.17, 0.92)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	UIKit.fill(shade)
	var center := UIKit.center_screen(self, "EndingCenter")
	var card := Panel.new()
	card.name = "EndingCard"
	card.custom_minimum_size = Vector2(1100, 640)
	card.add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20))
	center.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)
	UIKit.fill(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var page: Dictionary = _pages[_page]
	var title := UIKit.ribbon(str(page.get("title", "")), UIKit.TERRA, 40)
	column.add_child(title)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	for line in page.get("lines", []):
		var row := UIKit.label(str(line) if str(line) != "" else " ", 30, UIKit.DARK, "body")
		row.custom_minimum_size = Vector2(1000, 0)
		body.add_child(row)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 16)
	foot.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(foot)
	var dots := UIKit.label("%d / %d" % [_page + 1, _pages.size()], 24, UIKit.WOOD, "small", false)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(dots)
	var last := _page >= _pages.size() - 1
	var go := UIKit.button("Keep playing" if last else "Next", UIKit.SAGE if last else UIKit.TERRA)
	go.name = "EndingNext"
	go.custom_minimum_size = Vector2(260, 56)
	go.pressed.connect(func():
		if last:
			emit_signal("closed")
		else:
			_page += 1
			_show()
	)
	foot.add_child(go)
	UIKit.link_focus([go])
	UIKit.pop_in(card, 0.26)


func _money(amount: int) -> String:
	var text := str(amount)
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


func _json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
