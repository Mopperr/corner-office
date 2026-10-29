extends RefCounted
# The workbench. A light take on the old DAoC crafting loop: recipes con
# against your skill (grey to red), a make can fail and eat materials, a
# success can bump the skill, and the con decides how likely that is. Made
# things sell to whoever is asking that day, or go into the room as decor.
# Trade goods can be fixed up a grade to match what a buyer wants. Every
# sale leaves a line in the journal about where the thing ended up.

static var data: Dictionary = {}


static func ensure() -> void:
	if not data.is_empty():
		return
	var file := FileAccess.open("res://data/workshop.json", FileAccess.READ)
	if file == null:
		data = {"materials": [], "recipes": [], "grades": {}, "fix_steps": [], "craft_buyers": [], "stories": {}, "cons": []}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	data = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func materials() -> Array:
	ensure()
	return data.get("materials", [])


static func material(id: String) -> Dictionary:
	for row in materials():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func recipes() -> Array:
	ensure()
	return data.get("recipes", [])


static func recipe(id: String) -> Dictionary:
	for row in recipes():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func fresh() -> Dictionary:
	return {"skill": 1, "materials": {}, "made": {}, "graded": {}, "journal": [], "crafts": 0, "masterpieces": 0, "offer": {}}


static func state() -> Dictionary:
	if GameState.workshop.is_empty():
		GameState.workshop = fresh()
	return GameState.workshop


static func skill() -> int:
	return int(state().get("skill", 1))


static func con_of(level: int) -> Dictionary:
	ensure()
	var diff := level - skill()
	for con in data.get("cons", []):
		if diff >= int(con.get("from", -999)):
			return con
	return {"name": "grey", "fail": 0.0, "skill_up": 0.0}


static func unlocked(recipe_row: Dictionary) -> bool:
	# A recipe shows once it is within reach: red at most, so there is always a stretch goal.
	return int(recipe_row.get("level", 1)) - skill() <= 8


static func have(material_id: String) -> int:
	return int((state().get("materials", {}) as Dictionary).get(material_id, 0))


static func can_afford(need: Dictionary) -> bool:
	for id in need.keys():
		if have(str(id)) < int(need[id]):
			return false
	return true


static func buy_material(material_id: String, count := 1) -> String:
	var row := material(material_id)
	if row.is_empty():
		return "No such thing on the shelf."
	var cost := int(row.get("price", 5)) * count
	if GameState.money < cost:
		return "Needs $%d. You have $%d." % [cost, GameState.money]
	GameState.add_money(-cost, false)
	var stock: Dictionary = state().get("materials", {})
	stock[material_id] = int(stock.get(material_id, 0)) + count
	state()["materials"] = stock
	return ""


static func _spend(need: Dictionary, fraction := 1.0) -> void:
	var stock: Dictionary = state().get("materials", {})
	for id in need.keys():
		var take := int(ceil(float(need[id]) * fraction))
		stock[str(id)] = maxi(0, int(stock.get(str(id), 0)) - take)
	state()["materials"] = stock


static func craft(recipe_id: String) -> Dictionary:
	# Returns {ok, quality, skill_up, masterpiece, message}.
	var row := recipe(recipe_id)
	if row.is_empty():
		return {"ok": false, "message": "No such recipe."}
	if not unlocked(row):
		return {"ok": false, "message": "Too far above your skill. Make something closer first."}
	var need: Dictionary = row.get("materials", {})
	if not can_afford(need):
		return {"ok": false, "message": "Short on materials. The shelf tab sells them."}
	var con := con_of(int(row.get("level", 1)))
	var rng := GameState.rng
	var s := state()
	s["crafts"] = int(s.get("crafts", 0)) + 1
	if rng.randf() < float(con.get("fail", 0.0)):
		_spend(need, 0.5)
		return {"ok": false, "failed": true, "con": con.get("name", ""), "message": "It didn't take. Half the materials are scrap now. Try again."}
	_spend(need, 1.0)
	var quality := 94 + rng.randi_range(0, 5)
	var masterpiece := rng.randf() < 0.03 + float(skill()) * 0.002
	if masterpiece:
		quality = 100
		s["masterpieces"] = int(s.get("masterpieces", 0)) + 1
	var made: Dictionary = s.get("made", {})
	var pile: Array = made.get(recipe_id, [])
	pile.append({"quality": quality, "day": GameState.day})
	made[recipe_id] = pile
	s["made"] = made
	var skill_up := rng.randf() < float(con.get("skill_up", 0.0))
	if skill_up:
		s["skill"] = skill() + 1
	GameState.bump_stat("crafts_made")
	if masterpiece:
		GameState.bump_stat("masterpieces")
	if skill() >= 10:
		GameState.stats["skill_ten"] = 1
		GameState.check_contracts()
	return {
		"ok": true, "quality": quality, "skill_up": skill_up, "masterpiece": masterpiece, "con": con.get("name", ""),
		"message": "%s, %d%%.%s%s" % [row.get("name", ""), quality, "  Masterpiece!" if masterpiece else "", ("  Skill %d." % skill()) if skill_up else ""],
	}


static func made_count(recipe_id: String) -> int:
	return ((state().get("made", {}) as Dictionary).get(recipe_id, []) as Array).size()


static func best_made(recipe_id: String) -> Dictionary:
	var pile: Array = (state().get("made", {}) as Dictionary).get(recipe_id, [])
	var best: Dictionary = {}
	for entry in pile:
		if best.is_empty() or int(entry.get("quality", 0)) > int(best.get("quality", 0)):
			best = entry
	return best


static func _take_made(recipe_id: String) -> Dictionary:
	var made: Dictionary = state().get("made", {})
	var pile: Array = made.get(recipe_id, [])
	if pile.is_empty():
		return {}
	var best_index := 0
	for i in pile.size():
		if int(pile[i].get("quality", 0)) > int(pile[best_index].get("quality", 0)):
			best_index = i
	var entry: Dictionary = pile[best_index]
	pile.remove_at(best_index)
	made[recipe_id] = pile
	state()["made"] = made
	return entry


static func offer() -> Dictionary:
	# Who wants a made thing today. Rolled once per day from the save seed.
	var s := state()
	var current: Dictionary = s.get("offer", {})
	if int(current.get("day", -1)) == GameState.day:
		return current
	ensure()
	var buyers: Array = data.get("craft_buyers", [])
	if buyers.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("craft:%d:%d" % [GameState.seed, GameState.day])
	var buyer: Dictionary = buyers[rng.randi_range(0, buyers.size() - 1)]
	var tags: Array = buyer.get("tags", [])
	current = {
		"day": GameState.day,
		"name": buyer.get("name", "Someone"),
		"line": buyer.get("line", ""),
		"tag": str(tags[rng.randi_range(0, tags.size() - 1)]) if not tags.is_empty() else "wood",
		"min_quality": 94 + rng.randi_range(0, 3),
		"bonus": 1.4 + rng.randf() * 0.5,
	}
	s["offer"] = current
	return current


static func sell(recipe_id: String, to_buyer: bool) -> Dictionary:
	var row := recipe(recipe_id)
	var entry := _take_made(recipe_id)
	if row.is_empty() or entry.is_empty():
		return {"error": "Nothing of that on the bench."}
	var quality := int(entry.get("quality", 94))
	var base := float(row.get("sell", 10)) * pow(float(quality) / 100.0, 2.0)
	var who := "the market"
	var story_tag := str(row.get("tag", "wood"))
	if to_buyer:
		var ask := offer()
		if ask.is_empty() or str(ask.get("tag", "")) != story_tag or quality < int(ask.get("min_quality", 94)):
			# Put it back; the buyer is not asking for this.
			var made: Dictionary = state().get("made", {})
			var pile: Array = made.get(recipe_id, [])
			pile.append(entry)
			made[recipe_id] = pile
			return {"error": "That is not what %s is after today." % ask.get("name", "the buyer")}
		base *= float(ask.get("bonus", 1.4))
		who = str(ask.get("name", "a buyer"))
		# They are served; the next asker comes tomorrow.
		var s := state()
		var spent: Dictionary = ask.duplicate()
		spent["served"] = true
		s["offer"] = spent
	else:
		base *= 0.8
	var pay := maxi(1, int(round(base)))
	GameState.add_money(pay, true)
	var story := _story(story_tag, who, str(row.get("name", "")))
	_journal(story, pay)
	GameState.bump_stat("crafts_sold")
	return {"pay": pay, "story": story, "who": who}


static func keep(recipe_id: String) -> String:
	# A made thing goes into the room instead of the till.
	var row := recipe(recipe_id)
	if row.is_empty() or not bool(row.get("decor", false)):
		return "That one is for selling, not for the room."
	var entry := _take_made(recipe_id)
	if entry.is_empty():
		return "Nothing of that on the bench."
	GameState.decor_serial += 1
	GameState.decor_queue.append({"uid": "craft_%s_%d" % [recipe_id, GameState.decor_serial], "item": str(row.get("item", "")), "crafted": true, "quality": int(entry.get("quality", 94))})
	_journal("You kept the %s. It is the first thing people look at when they walk in." % row.get("name", ""), 0)
	return ""


static func grade_of_offer() -> String:
	return str(GameState.buyer_offer.get("grade", "worn"))


static func graded(item_id: String, grade: String) -> int:
	var all: Dictionary = state().get("graded", {})
	var by_grade: Dictionary = all.get(item_id, {})
	return int(by_grade.get(grade, 0))


static func fix_up(item_id: String) -> Dictionary:
	# Takes one plain (worn) unit, or a restored one, up a grade.
	ensure()
	var steps: Array = data.get("fix_steps", [])
	var from_grade := "worn"
	if graded(item_id, "restored") > 0 and int(GameState.goods.get(item_id, 0)) <= 0:
		from_grade = "restored"
	var step: Dictionary = {}
	for row in steps:
		if (from_grade == "worn" and str(row.get("to", "")) == "restored") or (from_grade == "restored" and str(row.get("to", "")) == "mint"):
			step = row
	if step.is_empty():
		return {"error": "Nothing left to improve on that."}
	if from_grade == "worn" and int(GameState.goods.get(item_id, 0)) <= 0:
		return {"error": "Buy one at the market first."}
	var need: Dictionary = step.get("materials", {})
	if not can_afford(need):
		return {"error": "Short on materials for that grade."}
	var con := con_of(int(step.get("level", 5)))
	var s := state()
	if GameState.rng.randf() < float(con.get("fail", 0.0)):
		_spend(need, 0.5)
		return {"error": "Slipped. Half the materials are gone, the piece is as it was."}
	_spend(need, 1.0)
	var all: Dictionary = s.get("graded", {})
	var by_grade: Dictionary = all.get(item_id, {})
	if from_grade == "worn":
		GameState.goods[item_id] = int(GameState.goods.get(item_id, 0)) - 1
	else:
		by_grade["restored"] = int(by_grade.get("restored", 0)) - 1
	var to_grade := str(step.get("to", "restored"))
	by_grade[to_grade] = int(by_grade.get(to_grade, 0)) + 1
	all[item_id] = by_grade
	s["graded"] = all
	if GameState.rng.randf() < float(con.get("skill_up", 0.0)):
		s["skill"] = skill() + 1
	GameState.bump_stat("fixed_up")
	return {"grade": to_grade, "message": "%s, now %s." % [ItemDB.display_name(item_id), to_grade]}


static func sell_graded(item_id: String, grade: String) -> Dictionary:
	# Sell a fixed-up unit: to the day's buyer if the grade matches, else the market at the grade's price.
	ensure()
	if graded(item_id, grade) <= 0:
		return {"error": "None of those in that grade."}
	var mult := float((data.get("grades", {}) as Dictionary).get(grade, 1.0))
	var price := float(GameState.sell_price_of(item_id)) * mult
	var who := "the market"
	var offer_row: Dictionary = GameState.buyer_offer
	if not offer_row.is_empty() and str(offer_row.get("item", "")) == item_id and str(offer_row.get("grade", "worn")) == grade:
		price = float(offer_row.get("price", price))
		who = str(offer_row.get("name", "a buyer"))
		GameState._roll_buyer()
	var all: Dictionary = state().get("graded", {})
	var by_grade: Dictionary = all.get(item_id, {})
	by_grade[grade] = int(by_grade.get(grade, 0)) - 1
	all[item_id] = by_grade
	state()["graded"] = all
	var pay := maxi(1, int(round(price)))
	GameState.add_money(pay, true)
	var story := _story("fix", who, ItemDB.display_name(item_id))
	_journal(story, pay)
	return {"pay": pay, "story": story, "who": who}


static func _story(tag: String, who: String, item_name: String) -> String:
	ensure()
	var pool: Array = (data.get("stories", {}) as Dictionary).get(tag, [])
	if pool.is_empty():
		return "%s took the %s home." % [who, item_name]
	var line := str(pool[GameState.rng.randi() % pool.size()])
	return GameState.fill_tokens(line, {"buyer": who, "item": item_name.to_lower()})


static func _journal(line: String, pay: int) -> void:
	var s := state()
	var journal: Array = s.get("journal", [])
	journal.push_front({"day": GameState.day, "line": line, "pay": pay})
	while journal.size() > 24:
		journal.pop_back()
	s["journal"] = journal
	GameState.emit_signal("toast_requested", line)
