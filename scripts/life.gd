class_name Life
extends RefCounted

## What Dana is earning for: a ladder of things of her own, from a dog to a
## fleet, read from data/life.json. Each rung costs money, may need a Rep
## rank, a shop tier or an earlier rung, and pays back in play: bigger
## tips, more jobs on the board, trucks and shops that earn every night.
## The first million is a milestone that opens the late game.

const Tuning = preload("res://scripts/tuning.gd")

static var data: Dictionary = {}


static func load_data() -> Dictionary:
	if data.is_empty():
		var file := FileAccess.open("res://data/life.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
	return data


static func fresh() -> Dictionary:
	return {"bought": {}, "milestones": {}, "log": []}


static func state() -> Dictionary:
	if GameState.life.is_empty():
		GameState.life = fresh()
	return GameState.life


static func rungs() -> Array:
	return load_data().get("rungs", [])


static func rung(id: String) -> Dictionary:
	for row in rungs():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func bought(id: String) -> bool:
	return (state().get("bought", {}) as Dictionary).has(id)


static func bought_count() -> int:
	return (state().get("bought", {}) as Dictionary).size()


static func blocker(row: Dictionary) -> String:
	# Why a rung cannot be bought yet, or "" when it can.
	var id := str(row.get("id", ""))
	if bought(id):
		return "yours"
	for need in row.get("needs", []):
		if not bought(str(need)):
			return "needs %s" % str(rung(str(need)).get("name", need))
	if GameState.rep_rank() < int(row.get("rep", 0)):
		return "needs Rep %d" % int(row.get("rep", 0))
	var tier := str(row.get("shop_tier", ""))
	if tier != "" and GameState.shop_tier_rank() < _tier_rank(tier):
		return "needs the %s" % tier
	if GameState.money < int(row.get("cost", 0)):
		return "short by $%d" % (int(row.get("cost", 0)) - GameState.money)
	return ""


static func _tier_rank(tier_id: String) -> int:
	var rank := 0
	for tier in load("res://scripts/catalog.gd").tiers():
		if str(tier.get("id", "")) == tier_id:
			return rank
		rank += 1
	return 0


static func next_rung() -> Dictionary:
	# The cheapest rung still to buy whose other requirements are met, else the cheapest left.
	var best: Dictionary = {}
	var fallback: Dictionary = {}
	for row in rungs():
		if bought(str(row.get("id", ""))):
			continue
		if fallback.is_empty() or int(row.get("cost", 0)) < int(fallback.get("cost", 0)):
			fallback = row
		var why := blocker(row)
		if why == "" or why.begins_with("short by"):
			if best.is_empty() or int(row.get("cost", 0)) < int(best.get("cost", 0)):
				best = row
	return best if not best.is_empty() else fallback


static func buy(id: String) -> Dictionary:
	var row := rung(id)
	if row.is_empty():
		return {"error": "No such thing."}
	var why := blocker(row)
	if why != "":
		return {"error": why}
	var cost := int(row.get("cost", 0))
	GameState.add_money(-cost, false)
	var s := state()
	var owned: Dictionary = s.get("bought", {})
	owned[id] = GameState.day
	s["bought"] = owned
	if int(row.get("rep_gain", 0)) > 0:
		GameState.rep_stars += int(row.get("rep_gain", 0))
	GameState.bump_stat("life_rungs")
	_mail(row.get("mail", {}), "life_" + id)
	_log("%s: $%d." % [str(row.get("name", id)), cost])
	if GameState.generated_jobs.size() > 0 and int(row.get("board_jobs", 0)) > 0:
		GameState.refresh_board()
	return {"bought": id, "cost": cost}


static func _mail(mail: Dictionary, id: String) -> void:
	if mail.is_empty():
		return
	for entry in GameState.inbox:
		if str(entry.get("id", "")) == id:
			return
	GameState.inbox.append({"id": id, "from": str(mail.get("from", "Marge")), "subject": str(mail.get("subject", "")), "body": str(mail.get("body", "")), "read": false})


static func _log(line: String) -> void:
	var s := state()
	var log: Array = s.get("log", [])
	log.push_front({"day": GameState.day, "line": line})
	while log.size() > 20:
		log.pop_back()
	s["log"] = log


static func _sum(key: String) -> float:
	var total := 0.0
	for row in rungs():
		if bought(str(row.get("id", ""))):
			total += float(row.get(key, 0))
	return total


static func tip_mult() -> float:
	# Pickle at the door, Sam's packed lunches: a share on every job's tips.
	return 1.0 + _sum("tip_mult")


static func first_job_mult() -> float:
	return 1.0 + _sum("first_job_mult")


static func vibe_bonus() -> int:
	return int(_sum("vibe"))


static func board_bonus() -> int:
	return int(_sum("board_jobs"))


static func trucks() -> int:
	return 1 + int(_sum("trucks"))


static func shops() -> int:
	return 1 + int(_sum("shops"))


static func upkeep() -> int:
	return int(_sum("upkeep"))


static func pet() -> String:
	for row in rungs():
		if bought(str(row.get("id", ""))) and str(row.get("pet", "")) != "":
			return str(row["pet"])
	return ""


static func nightly(shop_earned: int) -> Dictionary:
	# What the other trucks and counters brought in today, and what the dog ate.
	var cfg := load_data()
	var runs := trucks() - 1
	var run_pay := int(cfg.get("run_pay", 140))
	var rep_lift := 1.0 + 0.08 * float(GameState.rep_rank())
	var truck_pay := int(round(float(runs) * float(run_pay) * rep_lift))
	var counters := shops() - 1
	var share := float(cfg.get("shop_share", 0.5))
	var floor_take := int(cfg.get("shop_floor", 40))
	var shop_pay := int(round(float(counters) * share * float(maxi(shop_earned, floor_take))))
	var food := upkeep()
	var net := truck_pay + shop_pay - food
	if truck_pay > 0 or shop_pay > 0:
		GameState.add_money(truck_pay + shop_pay, true)
	if food > 0:
		GameState.add_money(-food, false)
	return {"trucks": runs, "truck_pay": truck_pay, "shops": counters, "shop_pay": shop_pay, "upkeep": food, "net": net}


static func check_milestones(before: int, after: int) -> void:
	var s := state()
	var done: Dictionary = s.get("milestones", {})
	for row in load_data().get("milestones", []):
		var id := str(row.get("id", ""))
		var at := int(row.get("at", 0))
		if done.has(id) or not (before < at and after >= at):
			continue
		done[id] = GameState.day
		s["milestones"] = done
		_mail(row.get("mail", {}), "life_" + id)
		_log("%s, on day %d." % [str(row.get("name", id)), GameState.day])
		GameState.bump_stat("milestone_" + id)
		GameState.emit_signal("toast_requested", "%s. %s" % [str(row.get("name", id)), str(row.get("blurb", ""))])


static func millionaire() -> bool:
	return (state().get("milestones", {}) as Dictionary).has("million")


static func progress() -> Dictionary:
	# Toward the next milestone not yet reached.
	for row in load_data().get("milestones", []):
		var id := str(row.get("id", ""))
		if (state().get("milestones", {}) as Dictionary).has(id):
			continue
		return {"id": id, "name": str(row.get("name", id)), "at": int(row.get("at", 0)), "earned": GameState.total_earned, "share": clampf(float(GameState.total_earned) / float(maxi(1, int(row.get("at", 1)))), 0.0, 1.0)}
	return {"id": "", "name": "Beyond the million", "at": 0, "earned": GameState.total_earned, "share": 1.0}
