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
	story_check()
	_maybe_visit()


static func loot() -> Array:
	return state().get("loot", [])


static func add_loot(entry: Dictionary) -> void:
	var s := state()
	var bag: Array = s.get("loot", [])
	bag.append(entry)
	s["loot"] = bag


static func bump_heat(amount: int) -> void:
	var s := state()
	s["heat"] = heat() + amount


static func loot_value() -> int:
	# What Sal pays for the bag: a cut of what the pieces are worth.
	var total := 0
	for entry in loot():
		total += int(entry.get("value", 0))
	return int(round(float(total) * float(Tuning.get_value("crime.loot_rate", 0.6))))


static func sell_loot() -> Dictionary:
	if loot().is_empty():
		return {"error": "The bag is empty."}
	if not unlocked("fence_1"):
		return {"error": "You need a fence before the bag is worth anything."}
	var paid := loot_value()
	var count := loot().size()
	var s := state()
	s["loot"] = []
	GameState.add_money(paid, true)
	GameState.bump_stat("loot_sold", count)
	_log("Sal took %d piece%s from the bag for $%d." % [count, "" if count == 1 else "s", paid])
	return {"paid": paid, "count": count}


static func fence_offer(item_id: String, count := 1) -> Dictionary:
	# Sal names a price. You can take it or push, twice; the third push loses him.
	ensure()
	var row := best_unlocked("fence")
	if row.is_empty():
		return {"error": "Sal doesn't know you yet."}
	if count > 1 and int(row.get("tier", 1)) < 2:
		return {"error": "Sal takes one at a time until he trusts you."}
	if int(GameState.goods.get(item_id, 0)) < count:
		return {"error": "You don't have %d of those." % count}
	var mult := float(row.get("mult", 1.5))
	var each := int(round(float(GameState.sell_price_of(item_id)) * mult))
	var haggle: Dictionary = data.get("haggle", {})
	return {"item": item_id, "count": count, "node": str(row.get("id", "")), "offer": each * count, "start": each * count, "pushes": 0, "walked": false, "line": str(haggle.get("line_open", "Cash, no receipt."))}


static func haggle_push(offer: Dictionary) -> Dictionary:
	ensure()
	var haggle: Dictionary = data.get("haggle", {})
	if bool(offer.get("walked", false)):
		return offer
	var pushes := int(offer.get("pushes", 0)) + 1
	offer["pushes"] = pushes
	if pushes > int(haggle.get("max_pushes", 2)):
		offer["walked"] = true
		offer["line"] = str(haggle.get("line_walk", "We're done here."))
		var s := state()
		s["heat"] = heat() + 1
		_log("Pushed Sal too far. No deal.")
		return offer
	var roll := GameState.rng.randf()
	if roll < float(haggle.get("push_odds", 0.6)):
		offer["offer"] = int(round(float(offer["offer"]) * (1.0 + float(haggle.get("push_up", 0.15)))))
		var ups: Array = haggle.get("lines_up", ["Fine."])
		offer["line"] = str(ups[(pushes - 1) % ups.size()])
	else:
		offer["offer"] = maxi(1, int(round(float(offer["offer"]) * (1.0 - float(haggle.get("push_down", 0.1))))))
		var downs: Array = haggle.get("lines_down", ["Less."])
		offer["line"] = str(downs[(pushes - 1) % downs.size()])
	return offer


static func fence_accept(offer: Dictionary) -> Dictionary:
	if bool(offer.get("walked", false)):
		return {"error": "Sal's gone. Try tomorrow."}
	var item_id := str(offer.get("item", ""))
	var count := int(offer.get("count", 1))
	if int(GameState.goods.get(item_id, 0)) < count:
		return {"error": "You don't have %d of those." % count}
	var row := node(str(offer.get("node", "")))
	var pay := int(offer.get("offer", 0))
	var cost_total := 0
	for i in count:
		cost_total += GameState._pop_cost(item_id)
		GameState.goods[item_id] = int(GameState.goods.get(item_id, 0)) - 1
	GameState._credit_net(pay - cost_total)
	GameState.add_money(pay, false)
	_earn(row)
	_log("Fenced %d x %s for $%d%s." % [count, ItemDB.display_name(item_id), pay, " after a push" if int(offer.get("pushes", 0)) > 0 else ""])
	return {"pay": pay}


static func fence(item_id: String, count := 1) -> Dictionary:
	# The one-shot: take Sal's first price.
	var offer := fence_offer(item_id, count)
	if offer.has("error"):
		return offer
	return fence_accept(offer)


static func lie_low() -> Dictionary:
	var row := node("cover_1")
	if not unlocked("cover_1"):
		return {"error": "Sal hasn't shown you how to disappear yet."}
	var s := state()
	if int(s.get("lay_low_day", -1)) == GameState.day:
		return {"error": "You've already closed up today."}
	var cost := int(row.get("cost", 30))
	if GameState.money < cost:
		return {"error": "Closing early costs $%d you don't have." % cost}
	GameState.add_money(-cost, false)
	s["heat"] = maxi(0, heat() - int(row.get("drop", 4)))
	s["lay_low_day"] = GameState.day
	_log("Closed up early. Heat down to %d." % heat())
	return {"heat": heat()}


static func bribe() -> Dictionary:
	var row := node("cover_2")
	if not unlocked("cover_2"):
		return {"error": "You don't have a friend on the force yet."}
	var s := state()
	if int(s.get("visits", 0)) <= 0:
		return {"error": "Nothing to forget. Save the money."}
	var cost := int(row.get("cost", 120))
	if GameState.money < cost:
		return {"error": "A quiet word costs $%d." % cost}
	GameState.add_money(-cost, false)
	s["visits"] = int(s.get("visits", 0)) - 1
	_log("A friend on the force lost a file. $%d." % cost)
	return {"visits": int(s["visits"])}


static func story_check() -> void:
	# Sal writes as cred climbs: a van, the patrols, the big one.
	ensure()
	var s := state()
	var sent: Array = s.get("story_sent", [])
	for beat in data.get("story", []):
		var id := str(beat.get("id", ""))
		if sent.has(id) or cred() < int(beat.get("cred", 999)):
			continue
		sent.append(id)
		GameState.inbox.append({"id": id, "from": "Sal", "subject": str(beat.get("subject", "")), "body": str(beat.get("body", "")), "read": false})
		GameState.emit_signal("emails_changed")
		GameState.emit_signal("toast_requested", "Sal wrote: %s." % GameState.fill_tokens(str(beat.get("subject", ""))))
	s["story_sent"] = sent


static func big_score_available() -> bool:
	ensure()
	var spec: Dictionary = data.get("big_score", {})
	return cred() >= int(spec.get("cred", 15)) and not bool(state().get("big_done", false)) and night_job_available()


static func on_drive(result: Dictionary) -> void:
	# Patrols that spotted you on a night move add heat; the quiet route forgives the alley.
	var spotted := int(result.get("spotted", 0))
	if spotted <= 0:
		return
	ensure()
	var per := int((data.get("patrols", {}) as Dictionary).get("heat", 3))
	var s := state()
	s["heat"] = heat() + spotted * per
	_log("Spotted by a patrol %d time%s. Heat %d." % [spotted, "" if spotted == 1 else "s", heat()])
	_maybe_visit()


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
	# The buyer might know the real thing: a better piece and a better label help.
	var spec: Dictionary = data.get("knockoff", {})
	var quality := int(entry.get("quality", 94))
	var catch := float(spec.get("base_catch", 0.32)) - float(quality - 80) / 100.0 - float(int(row.get("tier", 1)) - 1) * float(spec.get("tier_bonus", 0.08))
	catch = clampf(catch, 0.04, 0.5)
	if GameState.rng.randf() < catch:
		var lines: Array = spec.get("lines_caught", ["Caught."])
		var line := str(lines[GameState.rng.randi() % lines.size()])
		var s := state()
		s["heat"] = heat() + int(spec.get("heat_caught", 4))
		GameState.rep_stars = maxi(0, GameState.rep_stars - 1)
		GameState.emit_signal("rep_changed", GameState.rep_rank(), GameState.rep_stars)
		_log("%s No sale, heat %d." % [line, heat()])
		_maybe_visit()
		return {"caught": true, "line": line, "pay": 0}
	var pay := int(round(float(recipe.get("sell", 10)) * float(row.get("mult", 1.7))))
	GameState.add_money(pay, true)
	_earn(row)
	var story := "Sold a %s as the branded one for $%d." % [recipe.get("name", recipe_id), pay]
	if int(row.get("tier", 1)) >= 3:
		story += " It came with a story about a famous workshop. The buyer repeats it at dinner parties."
	_log(story)
	return {"pay": pay, "quality": int(entry.get("quality", 94)), "caught": false}


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
	drive["weather"] = "night"
	job["title"] = "No-questions move"
	job["client"] = "A friend of Sal's"
	job["brief"] = "Boxes already taped. Don't open them. %s" % job.get("brief", "")
	job["mentor_note"] = "Sal: in, out, nobody counts the boxes. Patrols are out: keep it slow near them."
	job["narrative_base"] = int(round(float(job.get("narrative_base", 120)) * float(row.get("mult", 1.6))))
	job["shady"] = true
	job["shady_node"] = str(row.get("id", ""))
	var big: Dictionary = data.get("big_score", {})
	if cred() >= int(big.get("cred", 15)) and not bool(state().get("big_done", false)):
		job["title"] = str(big.get("title", "The big one"))
		job["brief"] = str(big.get("brief", ""))
		job["narrative_base"] = int(round(float(job.get("narrative_base", 120)) / float(row.get("mult", 1.6)) * float(big.get("mult", 3.2))))
		job["big_score"] = true
		drive["patrols"] = 4
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
	if bool(def.get("big_score", false)):
		var s := state()
		s["big_done"] = true
		s["heat"] = heat() + int((data.get("big_score", {}) as Dictionary).get("heat", 12))
		GameState.bump_stat("big_score")
		GameState.inbox.append({"id": "sal_square", "from": "Sal", "subject": "We're square", "body": "Clean, quiet, by morning. I won't forget it, and neither will they, so keep your head down a while.\n\n— S", "read": false})
		GameState.emit_signal("emails_changed")
		_log("The big one, done. Sal says we're square.")
		_maybe_visit()
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


static func on_arrest(shady: bool) -> void:
	# Caught on the road: the heat is spent, and it counts as a visit.
	ensure()
	var s := state()
	s["heat"] = 0
	s["visits"] = int(s.get("visits", 0)) + 1
	_log("Boxed in by a patrol%s. That's a strike." % (" on a night move" if shady else ""))
	if int(s.get("visits", 0)) >= 3:
		_raid()


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
