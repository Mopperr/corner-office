extends RefCounted
# The back room. Three branches of off-the-books work (fencing, night
# moves, knock-offs), each a short tree bought with street cred earned by
# doing the previous rung. Everything adds heat; heat fades a little each
# day, and past the line there is a visit: fines, confiscations, and Marge
# finding out. Nothing here is required to finish the game.

static var data: Dictionary = {}


static func ensure() -> void:
	if not data.is_empty():
		return
	var file := FileAccess.open("res://data/crime.json", FileAccess.READ)
	if file == null:
		data = {"nodes": [], "branches": [], "contact": {}, "visits": []}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	data = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func fresh() -> Dictionary:
	return {"cred": 0, "heat": 0, "unlocked": {}, "done": {}, "visits": 0, "log": []}


static func state() -> Dictionary:
	if GameState.crime.is_empty():
		GameState.crime = fresh()
	return GameState.crime


static func nodes() -> Array:
	ensure()
	return data.get("nodes", [])


static func branches() -> Array:
	ensure()
	return data.get("branches", [])


static func node(id: String) -> Dictionary:
	for row in nodes():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func cred() -> int:
	return int(state().get("cred", 0))


static func heat() -> int:
	return int(state().get("heat", 0))


static func unlocked(id: String) -> bool:
	return bool((state().get("unlocked", {}) as Dictionary).get(id, false))


static func available(row: Dictionary) -> bool:
	var needs := str(row.get("requires", ""))
	return needs == "" or unlocked(needs)


static func unlock(id: String) -> String:
	var row := node(id)
	if row.is_empty():
		return "Sal has never heard of that."
	if unlocked(id):
		return ""
	if not available(row):
		return "Earn the rung below first."
	var cost := int(row.get("cred_cost", 0))
	if cred() < cost:
		return "Needs %d cred. You have %d." % [cost, cred()]
	var s := state()
	s["cred"] = cred() - cost
	var open: Dictionary = s.get("unlocked", {})
	open[id] = true
	s["unlocked"] = open
	_log("Sal nods. %s is yours." % row.get("name", id))
	return ""


static func best_unlocked(action: String) -> Dictionary:
	# The highest rung you hold for an action family.
	var best: Dictionary = {}
	for row in nodes():
		if not unlocked(str(row.get("id", ""))):
			continue
		if not str(row.get("action", "")).begins_with(action):
			continue
		if best.is_empty() or int(row.get("tier", 0)) > int(best.get("tier", 0)):
			best = row
	return best


static func _earn(row: Dictionary) -> void:
	var s := state()
	s["cred"] = cred() + int(row.get("cred", 1))
	s["heat"] = heat() + int(row.get("heat", 1))
	var done: Dictionary = s.get("done", {})
	var id := str(row.get("id", ""))
	done[id] = int(done.get(id, 0)) + 1
	s["done"] = done
	GameState.bump_stat("shady_deals")
	_maybe_visit()


static func fence(item_id: String, count := 1) -> Dictionary:
	var row := best_unlocked("fence")
	if row.is_empty():
		return {"error": "Sal doesn't know you yet."}
	if count > 1 and int(row.get("tier", 1)) < 2:
		return {"error": "Sal takes one at a time until he trusts you."}
	if int(GameState.goods.get(item_id, 0)) < count:
		return {"error": "You don't have %d of those." % count}
	var mult := float(row.get("mult", 1.5))
	var pay := 0
	for i in count:
		var cost := GameState._pop_cost(item_id)
		GameState.goods[item_id] = int(GameState.goods.get(item_id, 0)) - 1
		var gain := int(round(float(GameState.sell_price_of(item_id)) * mult))
		pay += gain
		GameState._credit_net(gain - cost)
	GameState.add_money(pay, false)
	_earn(row)
	_log("Fenced %d x %s for $%d." % [count, ItemDB.display_name(item_id), pay])
	return {"pay": pay}


static func fence_graded(item_id: String, grade: String) -> Dictionary:
	var row := node("fence_3")
	if not unlocked("fence_3"):
		return {"error": "Sal only buys the good stuff once you're the good customer."}
	var Workshop = load("res://scripts/workshop.gd")
	if Workshop.graded(item_id, grade) <= 0:
		return {"error": "None in that grade."}
	var all: Dictionary = Workshop.state().get("graded", {})
	var by_grade: Dictionary = all.get(item_id, {})
	by_grade[grade] = int(by_grade.get(grade, 0)) - 1
	all[item_id] = by_grade
	Workshop.state()["graded"] = all
	var pay := int(round(float(GameState.sell_price_of(item_id)) * float(row.get("mult", 2.4))))
	GameState.add_money(pay, true)
	_earn(row)
	_log("Sal took the %s %s. $%d, no receipt." % [grade, ItemDB.display_name(item_id), pay])
	return {"pay": pay}


static func knockoff(recipe_id: String) -> Dictionary:
	var row := best_unlocked("knockoff")
	if row.is_empty():
		return {"error": "You'd need Sal's label man for that."}
	var Workshop = load("res://scripts/workshop.gd")
	if Workshop.made_count(recipe_id) <= 0:
		return {"error": "Make one first."}
	var recipe: Dictionary = Workshop.recipe(recipe_id)
	var entry: Dictionary = Workshop._take_made(recipe_id)
	var pay := int(round(float(recipe.get("sell", 10)) * float(row.get("mult", 1.7))))
	GameState.add_money(pay, true)
	_earn(row)
	var story := "Sold a %s as the branded one for $%d." % [recipe.get("name", recipe_id), pay]
	if int(row.get("tier", 1)) >= 3:
		story += " It came with a story about a famous workshop. The buyer repeats it at dinner parties."
	_log(story)
	return {"pay": pay, "quality": int(entry.get("quality", 94))}


static func night_job_available() -> bool:
	return not best_unlocked("night").is_empty() and GameState.mode == "office" and GameState.office_phase == "live" and not bool(state().get("night_taken", false))


static func take_night_job() -> String:
	# A board job with the lights off: the best night rung sets the pay.
	var row := best_unlocked("night")
	if row.is_empty():
		return "Sal doesn't trust you with a van yet."
	if GameState.mode != "office" or GameState.office_phase != "live":
		return "Not now."
	var JobGen = load("res://scripts/job_gen.gd")
	var made: Dictionary = JobGen.board(GameState.seed + 9001, GameState.day, GameState.rep_rank(), GameState.jobs_done, 1)
	if (made.get("jobs", []) as Array).is_empty():
		return "Nothing tonight."
	var job: Dictionary = made["jobs"][0]
	var drive: Dictionary = made["drives"][str(job.get("drive", ""))]
	job["id"] = "night_d%d" % GameState.day
	job["drive"] = "night_drive_d%d" % GameState.day
	drive["id"] = job["drive"]
	drive["title"] = "After dark, " + str(drive.get("title", ""))
	drive["weather"] = "rain"
	job["title"] = "No-questions move"
	job["client"] = "A friend of Sal's"
	job["brief"] = "Boxes already taped. Don't open them. %s" % job.get("brief", "")
	job["mentor_note"] = "Sal: in, out, nobody counts the boxes."
	job["narrative_base"] = int(round(float(job.get("narrative_base", 120)) * float(row.get("mult", 1.6))))
	job["shady"] = true
	job["shady_node"] = str(row.get("id", ""))
	job["cat"] = false
	job["twist"] = "plain"
	GameState.generated_jobs.append(job)
	GameState.generated_drives[job["drive"]] = drive
	state()["night_taken"] = true
	GameState.start_job(str(job["id"]))
	_log("Took a night move for $%d." % int(job["narrative_base"]))
	return ""


static func on_job_finished(def: Dictionary) -> void:
	if not bool(def.get("shady", false)):
		return
	var row := node(str(def.get("shady_node", "")))
	if row.is_empty():
		return
	_earn(row)
	_log("Night move done. Sal's friend didn't say thank you. That's the deal.")


static func new_day() -> void:
	ensure()
	var s := state()
	s["heat"] = maxi(0, heat() - int(data.get("heat_decay", 2)))
	s["night_taken"] = false


static func maybe_nudge(summary: Dictionary) -> void:
	# A quiet day with an empty jar, and Sal gets in touch. Once.
	var s := state()
	if bool(s.get("nudged", false)):
		return
	if GameState.money >= 60 or int(summary.get("jobs", 0)) > 0 or int(summary.get("shop_earned", 0)) > 0:
		return
	s["nudged"] = true
	GameState.inbox.append({
		"id": "sal_nudge",
		"from": "Sal",
		"subject": "Heard things are slow",
		"body": "No shame in it. Everyone's jar runs dry.\n\nI buy goods for more than the market. I've got moves nobody wants on paper. The back room of your clipboard, when you're ready.\n\nMarge doesn't need to know.\n\n— S",
		"read": false,
	})
	GameState.emit_signal("emails_changed")
	GameState.emit_signal("toast_requested", "Sal left a note. The clipboard has a back room now.")


static func raided_today() -> bool:
	return int(state().get("raided_until", -1)) > GameState.day


static func _maybe_visit() -> void:
	ensure()
	if heat() < int(data.get("heat_visit", 10)):
		return
	var s := state()
	s["heat"] = int(float(heat()) * 0.4)
	s["visits"] = int(s.get("visits", 0)) + 1
	if int(s.get("visits", 0)) >= 3:
		_raid()
		return
	var visits: Array = data.get("visits", [])
	var which := int(s.get("visits", 1)) - 1
	var line := str(visits[which % visits.size()]) if not visits.is_empty() else "A visit."
	var fine := clampi(int(float(GameState.money) * 0.15), 20, 400)
	GameState.add_money(-fine, false)
	match which % 3:
		0:
			var taken := 0
			for id in GameState.goods.keys():
				while int(GameState.goods[id]) > 0 and taken < 2:
					GameState.goods[id] = int(GameState.goods[id]) - 1
					GameState._pop_cost(str(id))
					taken += 1
		2:
			GameState.rep_stars = maxi(0, GameState.rep_stars - 1)
			GameState.emit_signal("rep_changed", GameState.rep_rank(), GameState.rep_stars)
	GameState.inbox.append({
		"id": "visit_%d" % int(s.get("visits", 1)),
		"from": "Sal",
		"subject": "Lie low",
		"body": "%s\n\nFine was $%d. Heat's down. Don't call me for a day.\n\n— S" % [line, fine],
		"read": false,
	})
	GameState.emit_signal("emails_changed")
	_log("%s (−$%d)" % [line, fine])
	GameState.emit_signal("toast_requested", line)


static func _raid() -> void:
	# Third time is the raid: the lock-up gets turned over, and so does yours.
	var s := state()
	var fine := clampi(int(float(GameState.money) * 0.3), 50, 900)
	GameState.add_money(-fine, false)
	var taken := 0
	for id in GameState.goods.keys():
		var have := int(GameState.goods[id])
		var lose := int(ceil(float(have) * 0.5))
		for i in lose:
			GameState._pop_cost(str(id))
		GameState.goods[id] = have - lose
		taken += lose
	GameState.rep_stars = maxi(0, GameState.rep_stars - 1)
	GameState.emit_signal("rep_changed", GameState.rep_rank(), GameState.rep_stars)
	s["raided_until"] = GameState.day + 2
	s["heat"] = 0
	s["cred"] = int(float(cred()) * 0.5)
	s["raids"] = int(s.get("raids", 0)) + 1
	GameState.inbox.append({
		"id": "raid_%d" % int(s.get("raids", 1)),
		"from": "Marge Holloway",
		"subject": "Police at the garage",
		"body": "They were at your door with a van and a warrant. %d trade goods went in the van. Fine was $%d. The shop sign stays CLOSED tomorrow.\n\nI don't know what you've been doing and I'm not asking. Yet.\n\n— Marge" % [taken, fine],
		"read": false,
	})
	GameState.emit_signal("emails_changed")
	_log("Raided. %d goods taken, $%d fine, Rep down, the shop shut for a day." % [taken, fine])
	GameState.emit_signal("toast_requested", "Police. They took %d goods and $%d. The shop is shut tomorrow." % [taken, fine])
	GameState.bump_stat("raids")


static func _log(line: String) -> void:
	var s := state()
	var log: Array = s.get("log", [])
	log.push_front({"day": GameState.day, "line": line})
	while log.size() > 16:
		log.pop_back()
	s["log"] = log
