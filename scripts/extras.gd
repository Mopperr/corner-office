extends RefCounted

## The replay layer on top of the jobs: modifiers that change a job's rules
## and pay, a client's wish worth a tip, the clean-run streak, the Movers'
## League against three rival firms, the gear you buy once and keep, and the
## journal of achievements (`data/gear.json`, `data/achievements.json`).

const Tuning = preload("res://scripts/tuning.gd")

const MODIFIERS := {
	"rush": {"name": "Rush", "bonus": 0.35, "blurb": "They need it today. Pay +35%, but only if the drive comes in on the clock."},
	"fragile_lot": {"name": "Fragile lot", "bonus": 0.25, "blurb": "Glass, china, a lifetime of it. Every piece counts as fragile. Pay +25%."},
	"no_helper": {"name": "No helper", "bonus": 0.20, "blurb": "Nobody to hand it to. Every piece is packed, loaded and placed by your own hands. Pay +20%."},
	"heirloom": {"name": "Heirloom", "bonus": 0.0, "blurb": "One piece matters more than the rest. Whole at the other end: $60. Marked: $60 off and a rep star."},
	"nosy": {"name": "Nosy neighbour", "bonus": 0.0, "blurb": "Someone is watching from next door. Anything pocketed is likelier seen; a clean job earns a good word, $25."},
}

const WISHES := [
	{"id": "no_drops", "text": "Please don't drop anything. Anything.", "home": false},
	{"id": "stack", "text": "Stack the empty boxes before you go, would you?", "home": false},
	{"id": "tidy", "text": "Make the room look like a room. I can't think in a mess.", "home": false},
	{"id": "right_rooms", "text": "Every piece in the room it belongs in. Every one.", "home": true},
]

const RIVALS := ["Hollis & Sons", "Two Men and a Van", "Pronto Movers"]

static var _gear: Array = []
static var _achievements: Array = []


static func _read(path: String, key: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return (parsed as Dictionary).get(key, [])


static func gear_list() -> Array:
	if _gear.is_empty():
		_gear = _read("res://data/gear.json", "gear")
	return _gear


static func achievement_list() -> Array:
	if _achievements.is_empty():
		_achievements = _read("res://data/achievements.json", "achievements")
	return _achievements


# --- modifiers and wishes, rolled onto the board ---

static func roll_modifiers(rng: RandomNumberGenerator, is_home: bool) -> Array:
	# None, one or two, no repeats; the heirloom and the nosy neighbour only at a home.
	var ids: Array = MODIFIERS.keys()
	var count: int = [0, 0, 1, 1, 1, 2][rng.randi_range(0, 5)]
	var out: Array = []
	var guard := 0
	while out.size() < count and guard < 12:
		guard += 1
		var id := str(ids[rng.randi_range(0, ids.size() - 1)])
		if out.has(id):
			continue
		if (id == "heirloom" or id == "nosy") and not is_home:
			continue
		out.append(id)
	return out


static func roll_wish(rng: RandomNumberGenerator, is_home: bool) -> Dictionary:
	if rng.randf() > 0.6:
		return {}
	var pool: Array = []
	for wish in WISHES:
		if bool(wish.get("home", false)) and not is_home:
			continue
		pool.append(wish)
	return (pool[rng.randi_range(0, pool.size() - 1)] as Dictionary).duplicate()


static func has_mod(def: Dictionary, id: String) -> bool:
	return (def.get("modifiers", []) as Array).has(id)


static func job_mult(def: Dictionary) -> float:
	# What the modifiers and the league do to a job's pay.
	var mult := 1.0
	for id in def.get("modifiers", []):
		mult += float((MODIFIERS.get(str(id), {}) as Dictionary).get("bonus", 0.0))
	if bool(def.get("generated", false)) and bool(GameState.league.get("leader", false)):
		mult += float(Tuning.get_value("play.leader_bonus", 0.10))
	return mult


static func modifier_name(id: String) -> String:
	return str((MODIFIERS.get(id, {}) as Dictionary).get("name", id.capitalize()))


static func modifier_blurb(id: String) -> String:
	return str((MODIFIERS.get(id, {}) as Dictionary).get("blurb", ""))


static func on_job_start(job: Dictionary) -> void:
	# The modifiers settle on the pieces: a fragile lot, the heirloom named.
	var def: Dictionary = job.get("def", {})
	var items: Array = job.get("items", [])
	if has_mod(def, "fragile_lot"):
		for item in items:
			if not bool(item.get("nobox", false)):
				item["fragile"] = true
	if has_mod(def, "heirloom"):
		var pool: Array = []
		for item in items:
			if not bool(item.get("nobox", false)) and not bool(item.get("heavy", false)):
				pool.append(item)
		if not pool.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(str(def.get("id", "")) + ":heirloom")
			var pick: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
			pick["heirloom"] = true
			job["heirloom"] = str(pick.get("uid", ""))
			job["heirloom_name"] = str(pick.get("name", "the heirloom"))
	job["drops"] = 0


static func rush_budget(def: Dictionary) -> float:
	var drive: Dictionary = JobDB.get_drive(str(def.get("drive", "")))
	return float(drive.get("length_m", 150)) * float(Tuning.get_value("play.rush_seconds_per_m", 0.5)) + float(Tuning.get_value("play.rush_grace", 25))


static func wish_met(job: Dictionary) -> bool:
	var wish: Dictionary = job.get("def", {}).get("wish", {})
	if wish.is_empty():
		return false
	match str(wish.get("id", "")):
		"no_drops":
			return int(job.get("drops", 0)) == 0
		"stack":
			for box in job.get("boxes", []):
				if int(box.get("tower", -1)) >= 0:
					return true
			return false
		"tidy":
			return float(job.get("room_score", -1.0)) >= float(Tuning.get_value("play.tidy_score", 60.0))
		"right_rooms":
			return int(job.get("rooms_total", 0)) > 0 and int(job.get("rooms_right", 0)) == int(job.get("rooms_total", 0))
	return false


static func settle(job: Dictionary, payout: Dictionary) -> int:
	# At the end of a job: the modifiers pay out or don't, the wish, the
	# streak, the league points. Returns the extra money, which the caller adds.
	var def: Dictionary = job.get("def", {})
	var extra := 0
	var base := int(payout.get("base", 0))
	if has_mod(def, "rush"):
		var took := float(job.get("drive_time", 0.0))
		var budget := rush_budget(def)
		var made := took <= budget
		payout["rush"] = {"made": made, "took": took, "budget": budget}
		if made:
			GameState.bump_stat("rush_met")
		else:
			# The bonus was in the base; it comes back off.
			var off := int(round(float(base) * float((MODIFIERS["rush"] as Dictionary).get("bonus", 0.35)) / job_mult(def)))
			payout["rush_off"] = off
			extra -= off
	if has_mod(def, "heirloom"):
		var item: Dictionary = GameState.job_item(str(job.get("heirloom", "")))
		var whole := not item.is_empty() and int(item.get("damage", 0)) == 0
		var amount := int(Tuning.get_value("play.heirloom_bonus", 60))
		payout["heirloom"] = {"name": str(job.get("heirloom_name", "the heirloom")), "whole": whole, "amount": amount if whole else int(Tuning.get_value("play.heirloom_loss", 60))}
		if whole:
			extra += amount
			GameState.bump_stat("heirlooms_safe")
		else:
			extra -= int(Tuning.get_value("play.heirloom_loss", 60))
			GameState.rep_stars = maxi(0, GameState.rep_stars - 1)
	if has_mod(def, "nosy"):
		var clean := (job.get("pocketed", []) as Array).is_empty()
		payout["nosy"] = {"clean": clean, "amount": int(Tuning.get_value("play.nosy_bonus", 25))}
		if clean:
			extra += int(Tuning.get_value("play.nosy_bonus", 25))
	var wish: Dictionary = def.get("wish", {})
	if not wish.is_empty():
		var met := wish_met(job)
		payout["wish"] = {"text": str(wish.get("text", "")), "met": met, "amount": int(Tuning.get_value("play.wish_tip", 20))}
		if met:
			extra += int(Tuning.get_value("play.wish_tip", 20))
			GameState.bump_stat("wishes_met")
	# The streak: nothing scuffed or chipped, nothing dropped, nobody shoved.
	var clean_run := int(payout.get("scuffed", 0)) == 0 and int(payout.get("chipped", 0)) == 0 and int(job.get("drops", 0)) == 0 and not bool(job.get("attacked", false))
	if clean_run:
		GameState.streak += 1
		if GameState.streak > int(GameState.stats.get("best_streak", 0)):
			GameState.stats["best_streak"] = GameState.streak
		var per := int(Tuning.get_value("play.streak_per", 5))
		var bonus := per * mini(GameState.streak, int(Tuning.get_value("play.streak_cap", 10))) if GameState.streak >= 2 else 0
		payout["streak"] = {"count": GameState.streak, "amount": bonus}
		extra += bonus
	else:
		payout["streak"] = {"count": 0, "amount": 0, "broken": GameState.streak > 0}
		GameState.streak = 0
	# League points: three a star, two for a clean run.
	var points := int(payout.get("stars", 1)) * int(Tuning.get_value("play.points_per_star", 3)) + (2 if clean_run else 0)
	GameState.league["points"] = int(GameState.league.get("points", 0)) + points
	payout["league_points"] = points
	if int(payout.get("stars", 1)) >= 3:
		GameState.bump_stat("three_star_jobs")
	payout["extras"] = extra
	return extra


# --- the Movers' League ---

static func league_fresh() -> Dictionary:
	var rivals := {}
	for name in RIVALS:
		rivals[name] = 0
	return {"points": 0, "rivals": rivals, "week": 1, "leader": false, "last_table": []}


static func league_nightly(summary: Dictionary) -> void:
	# The rivals earn their points overnight; every seventh night the table is settled and a letter comes.
	if GameState.league.is_empty():
		GameState.league = league_fresh()
	var L: Dictionary = GameState.league
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("league:%d:%d" % [GameState.seed, GameState.day])
	var rivals: Dictionary = L.get("rivals", {})
	for name in rivals.keys():
		rivals[name] = int(rivals[name]) + rng.randi_range(int(Tuning.get_value("play.rival_min", 2)), int(Tuning.get_value("play.rival_max", 6)))
	L["rivals"] = rivals
	var week := int(Tuning.get_value("play.league_week", 7))
	if GameState.day % week == 0:
		var table := standings()
		L["last_table"] = table
		var top := str(table[0].get("name", "")) == "Corner Movers"
		L["leader"] = top
		if top:
			GameState.bump_stat("league_weeks_won")
		var lines: Array = []
		for i in table.size():
			lines.append("%d. %s, %d points" % [i + 1, table[i].get("name", ""), int(table[i].get("points", 0))])
		GameState.inbox.append({
			"id": "league_w%d" % int(L.get("week", 1)), "from": "The Movers' League", "subject": "Week %d table" % int(L.get("week", 1)),
			"body": "%s\n\n%s" % ["\n".join(lines), "Top of the table. Every board job pays 10% more this week. Don't let it go to your head." if top else "Points come from stars and clean runs. The table resets Sunday night."],
			"read": false,
		})
		GameState.emit_signal("emails_changed")
		summary["league"] = {"table": table, "top": top, "week": int(L.get("week", 1))}
		L["week"] = int(L.get("week", 1)) + 1
		L["points"] = 0
		for name in rivals.keys():
			rivals[name] = 0


static func standings() -> Array:
	if GameState.league.is_empty():
		GameState.league = league_fresh()
	var rows: Array = [{"name": "Corner Movers", "points": int(GameState.league.get("points", 0)), "you": true}]
	for name in (GameState.league.get("rivals", {}) as Dictionary).keys():
		rows.append({"name": str(name), "points": int(GameState.league["rivals"][name]), "you": false})
	rows.sort_custom(func(a, b):
		if int(a["points"]) != int(b["points"]):
			return int(a["points"]) > int(b["points"])
		return bool(a["you"])
	)
	return rows


# --- gear ---

static func gear_has(id: String) -> bool:
	return GameState.gear.has(id)


static func gear_def(id: String) -> Dictionary:
	for row in gear_list():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func buy_gear(id: String) -> Dictionary:
	var row := gear_def(id)
	if row.is_empty():
		return {"error": "No such thing in the catalogue."}
	if gear_has(id):
		return {"error": "You have one."}
	var cost := int(row.get("cost", 0))
	if GameState.money < cost:
		return {"error": "That's $%d and the jar has $%d." % [cost, GameState.money]}
	GameState.add_money(-cost, false)
	GameState.gear.append(id)
	GameState.bump_stat("gear_bought")
	return {"said": "%s: yours. %s" % [row.get("name", id), row.get("effect", "")]}


static func crush_threshold() -> float:
	return float(Tuning.get_value("weight.crush_threshold_kg", 18)) + (8.0 if gear_has("racks") else 0.0)


static func load_mult() -> float:
	return 0.8 if gear_has("dolly") else 1.0


static func wrap_mult() -> float:
	return 0.6 if gear_has("blankets") else 1.0


static func per_box_extra() -> int:
	return 2 if gear_has("tape_gun") else 0


static func break_mult() -> float:
	return 0.7 if gear_has("gloves") else 1.0


static func charm_catches(job: Dictionary) -> bool:
	# Once a job, the brass duck takes the slip.
	if not gear_has("charm") or job.is_empty() or bool(job.get("charm_used", false)):
		return false
	job["charm_used"] = true
	return true


# --- the journal ---

static func unlocked(id: String) -> bool:
	return GameState.achievements.has(id)


static func _flag(name: String) -> bool:
	match name:
		"hands_max":
			return GameState.handling_level() >= int(Tuning.get_value("handling.max_level", 5))
		"any_payback":
			return int(GameState.stats.get("payback", 0)) + int(GameState.stats.get("payback_jobs", 0)) + int(GameState.stats.get("egged", 0)) + int(GameState.stats.get("reviewed", 0)) + int(GameState.stats.get("glittered", 0)) + int(GameState.stats.get("invoice_paid", 0)) > 0
		"all_gear":
			return GameState.gear.size() >= gear_list().size() and gear_list().size() > 0
		"earned_1000":
			return GameState.total_earned >= 1000
		"has_pet":
			return load("res://scripts/life.gd").pet() != ""
	return false


static func check_achievements() -> Array:
	# Anything newly earned: a line in the journal, a toast and a letter.
	var fresh: Array = []
	for row in achievement_list():
		var id := str(row.get("id", ""))
		if unlocked(id):
			continue
		var done := false
		if row.has("stat"):
			var key := str(row.get("stat", ""))
			var have := GameState.jobs_done if key == "jobs_done" else int(GameState.stats.get(key, 0))
			done = have >= int(row.get("at", 1))
		elif row.has("flag"):
			done = _flag(str(row.get("flag", "")))
		if done:
			GameState.achievements.append(id)
			fresh.append(row)
	if not fresh.is_empty():
		var names: Array = []
		for row in fresh:
			names.append("%s: %s" % [row.get("name", ""), row.get("blurb", "")])
		GameState.inbox.append({
			"id": "journal_%s_d%d" % [fresh[0].get("id", ""), GameState.day], "from": "The journal", "subject": "%s" % fresh[0].get("name", "") if fresh.size() == 1 else "%d new entries" % fresh.size(),
			"body": "\n".join(names), "read": false,
		})
		GameState.emit_signal("emails_changed")
		GameState.emit_signal("toast_requested", "Journal: %s" % fresh[0].get("name", ""))
	return fresh
