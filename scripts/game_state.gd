extends Node

const Tuning = preload("res://scripts/tuning.gd")
const Catalog = preload("res://scripts/catalog.gd")

signal money_changed(amount)
signal rep_changed(rank, stars)
signal job_completed(job_id, payout)
signal box_damaged(uid, level)
signal emails_changed
signal mode_changed(mode)
signal toast_requested(message)
signal office_changed(office_id)
signal held_cleared
signal day_ended(summary)

var character := "dana"
var money := 120
var total_earned := 0
var rep_stars := 0
var jobs_done := 0
var jobs_cleared: Dictionary = {}
var office_id := "garage"
var day := 1
var mode := "menu"
var office_phase := "pack"
var office_items: Array = []
var decor_queue: Array = []
var goods: Dictionary = {}
var goods_cost: Dictionary = {}
var prices: Dictionary = {}
var history: Dictionary = {}
var inbox: Array = []
var fired: Dictionary = {}
var tutorial_done := false
var first_placed := false
var museum: Array = []
var held_uid := ""
var job: Dictionary = {}
var payout: Dictionary = {}
var buyer_offer: Dictionary = {}
var pastry_day := -1
var decor_serial := 0
var orders: Array = []
var wishlist: Array = []
var prime := false
var menu_markup := 1.0
var shop_today := 0
var shop_visitors_today := 0
var shop_ledger: Array = []
var shop_closed := false
var shop_hand_served := 0
var seed := 0
var generated_jobs: Array = []
var generated_drives: Dictionary = {}
var stats: Dictionary = {}
var contracts_done: Dictionary = {}
var day_log: Dictionary = {}
var shop_tier := "stand"
var rent_owed := 0
var workshop: Dictionary = {}
var crime: Dictionary = {}
const Workshop = preload("res://scripts/workshop.gd")
const Crime = preload("res://scripts/crime.gd")
const JobGen = preload("res://scripts/job_gen.gd")
var freebie_day := -1
var forest_serial := 0
var latched_goals: Dictionary = {}
var goal_marked: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _arcs: Variant = null


func _ready() -> void:
	Tuning.load_data()
	rng.randomize()


func rep_rank() -> int:
	return Tuning.rep_rank(rep_stars)


func new_game(who: String) -> void:
	character = who
	money = int(Tuning.get_value("starter_money." + who, 120))
	total_earned = 0
	rep_stars = 0
	jobs_done = 0
	jobs_cleared = {}
	office_id = "garage"
	day = 1
	office_phase = "pack"
	office_items = []
	decor_queue = []
	goods = {}
	goods_cost = {}
	inbox = []
	fired = {}
	tutorial_done = false
	first_placed = false
	museum = []
	held_uid = ""
	job = {}
	payout = {}
	pastry_day = -1
	decor_serial = 0
	orders = []
	wishlist = []
	prime = false
	menu_markup = 1.0
	shop_today = 0
	shop_visitors_today = 0
	shop_ledger = []
	shop_closed = false
	shop_hand_served = 0
	seed = int(rng.randi())
	stats = {}
	contracts_done = {}
	day_log = _fresh_day_log()
	shop_tier = "stand"
	workshop = Workshop.fresh()
	crime = Crime.fresh()
	refresh_board()
	freebie_day = -1
	forest_serial = 0
	latched_goals = {}
	goal_marked = {}
	for entry in ItemDB.starter_layout():
		var copy: Dictionary = entry.duplicate(true)
		copy["state"] = "placed"
		copy["damage"] = 0
		office_items.append(copy)
	_seed_market()
	_roll_buyer()
	fire_trigger("game_start")
	set_mode("office")
	emit_signal("money_changed", money)


func set_mode(next: String) -> void:
	mode = next
	emit_signal("mode_changed", next)


func add_money(amount: int, earned: bool) -> void:
	money += amount
	if earned and amount > 0:
		_credit_net(amount)
	else:
		emit_signal("money_changed", money)
	if amount > 0 and rent_owed > 0 and try_pay_rent():
		emit_signal("toast_requested", "Rent settled. The shop can open again.")
	_check_unlock_email()


func _credit_net(profit: int) -> void:
	if profit != 0:
		var before := total_earned
		total_earned = maxi(0, total_earned + profit)
		_check_earn_triggers(before, total_earned)
	emit_signal("money_changed", money)
	_check_unlock_email()


func restore_held_items() -> void:
	var hands := false
	for rec in office_items:
		var state := str(rec.get("state", ""))
		if state == "hand" or state == "settling":
			if state == "hand":
				hands = true
			rec["state"] = "placed"
	for item in job.get("items", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var state := str(item.get("state", ""))
		if state == "hand" or state == "settling":
			if state == "hand":
				hands = true
			item["state"] = "placed"
	if hands:
		emit_signal("held_cleared")


func _push_cost(id: String, cost: int) -> void:
	var stack: Array = goods_cost.get(id, [])
	stack.append(cost)
	goods_cost[id] = stack


func _pop_cost(id: String) -> int:
	var stack: Array = goods_cost.get(id, [])
	var cost := ItemDB.base_price(id)
	if not stack.is_empty():
		cost = int(stack.pop_front())
		goods_cost[id] = stack
	return cost


func _check_earn_triggers(before: int, after: int) -> void:
	if before < 50 and after >= 50:
		fire_trigger("earned_50")
	if before < 100 and after >= 100:
		fire_trigger("total_earned_100")
	if before < 500 and after >= 500:
		fire_trigger("total_earned_500")


func _check_unlock_email() -> void:
	if office_gate_met("bakery") and not fired.has("unlock_next_office"):
		fire_trigger("unlock_next_office")


func office_gate_met(id: String) -> bool:
	var office := Tuning.office_def(id)
	if office.is_empty():
		return false
	return total_earned >= int(office.get("earned", 0)) \
		and jobs_done >= int(office.get("jobs", 0)) \
		and rep_rank() >= int(office.get("rep", 0))


func try_buy_office(id: String) -> String:
	var office := Tuning.office_def(id)
	if office.is_empty():
		return "That listing wandered off."
	if not bool(office.get("playable", false)):
		return "The blueprint is in the drawer. This chapter opens the Bakery Loft."
	if id == office_id:
		return "You're already here."
	if not office_gate_met(id):
		return "Not yet. Keep earning, hauling, and being gentle."
	var cost := int(office.get("cost", 0))
	if money < cost:
		return "The jar is a little light for that."
	add_money(-cost, false)
	for item in office_items:
		if str(item.get("state", "")) == "placed":
			item["state"] = "boxed"
	office_id = id
	office_phase = "place"
	emit_signal("office_changed", id)
	emit_signal("toast_requested", "Moving into the %s. Unpack when you're ready." % office.get("name", id))
	return ""


func mark_tutorial_live() -> void:
	if tutorial_done:
		return
	tutorial_done = true
	fire_trigger("unpack_complete")
	fire_trigger("mover_unlocked")
	emit_signal("toast_requested", "Your corner is open. The computer and the job clipboard are both awake.")


func note_first_place() -> void:
	if first_placed:
		return
	first_placed = true
	fire_trigger("first_item_placed")


func fire_trigger(trigger: String) -> void:
	if fired.has(trigger):
		return
	fired[trigger] = true
	var emails = _read_emails()
	var added := false
	for email in emails:
		if str(email.get("trigger", "")) == trigger:
			inbox.append({
				"id": email.get("id", trigger),
				"from": email.get("from", "Marge"),
				"subject": email.get("subject", "Hello"),
				"body": email.get("body", ""),
				"read": false,
			})
			added = true
	if added:
		emit_signal("emails_changed")


func loaded_arc_characters() -> int:
	return _arc_data().get("characters", []).size()


func slice_beats() -> Array:
	var beats: Array = []
	for who in _arc_data().get("characters", []):
		if typeof(who) != TYPE_DICTIONARY:
			continue
		if str(who.get("phase", "")) != "slice":
			continue
		for entry in who.get("levels", []):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			if str(entry.get("ship_in", "")) != "slice":
				continue
			beats.append(entry)
	return beats


func present_current_slice_level() -> Dictionary:
	return present_slice_level(_current_slice_level_id())


func present_slice_level(level_id: String) -> Dictionary:
	if level_id == "" or character != slice_character_id():
		return {}
	var key := "arc_%s" % level_id
	if fired.has(key):
		return {}
	var beat: Dictionary = {}
	for entry in slice_beats():
		var level: Dictionary = entry
		if str(level.get("level_id", "")) == level_id:
			beat = level
			break
	if beat.is_empty():
		return {}
	fired[key] = true
	var mail: Variant = beat.get("marge_email", {})
	var email: Dictionary = mail if typeof(mail) == TYPE_DICTIONARY else {}
	inbox.append({
		"id": key,
		"from": "Marge \"Mile Marker\" Holloway",
		"subject": email.get("subject", "Hello"),
		"body": email.get("body", ""),
		"read": false,
	})
	emit_signal("emails_changed")
	AudioDirector.play_sfx("sfx_notification_soft")
	return beat


func _current_slice_level_id() -> String:
	if character != slice_character_id():
		return ""
	if mode == "drive":
		var drive_id := str(job.get("def", {}).get("drive", ""))
		if drive_id == "rainy_afternoon":
			return "L3"
		if drive_id == "duck_pond":
			return "L5"
		return ""
	if mode == "job_pack" or mode == "truck" or mode == "job_unpack":
		var level := str(job.get("def", {}).get("level", ""))
		if level == "L2" or level == "L4":
			return level
		return ""
	if mode == "office":
		if office_id == "bakery":
			return "L6"
		if office_id == "garage":
			return "L1"
	return ""


func _arc_data() -> Dictionary:
	if _arcs is Dictionary:
		return _arcs
	_arcs = {}
	var path := "res://data/narrative/character_arcs.json"
	if not FileAccess.file_exists(path):
		return _arcs
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) == TYPE_DICTIONARY:
		_arcs = parsed
	return _arcs


func slice_character_id() -> String:
	for who in _player_characters():
		if str(who.get("phase", "")) != "slice":
			continue
		var raw := str(who.get("id", "pc_dana"))
		if raw.begins_with("pc_"):
			return raw.trim_prefix("pc_")
		return raw
	return "dana"


func _read_emails() -> Array:
	if not FileAccess.file_exists("res://data/narrative/emails.json"):
		return []
	var file := FileAccess.open("res://data/narrative/emails.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []
	var welcome := _slice_welcome_email()
	if welcome.is_empty():
		return parsed
	var emails: Array = []
	var replaced := false
	for email in parsed:
		var copy: Dictionary = (email as Dictionary).duplicate(true)
		if str(copy.get("id", "")) == "tut_welcome":
			copy["from"] = welcome.get("from", copy.get("from", ""))
			copy["subject"] = welcome.get("subject", copy.get("subject", ""))
			copy["body"] = welcome.get("body", copy.get("body", ""))
			copy["trigger"] = "game_start"
			replaced = true
		emails.append(copy)
	if not replaced:
		emails.push_front({
			"id": "tut_welcome",
			"from": welcome.get("from", "Marge"),
			"subject": welcome.get("subject", "Hello"),
			"body": welcome.get("body", ""),
			"trigger": "game_start",
		})
	return emails


func _slice_welcome_email() -> Dictionary:
	for who in _player_characters():
		if str(who.get("phase", "")) != "slice":
			continue
		var email: Variant = who.get("welcome_email", {})
		if typeof(email) == TYPE_DICTIONARY:
			return email
	return {}


func _player_characters() -> Array:
	var path := "res://data/narrative/player_characters.json"
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var characters: Variant = parsed.get("characters", [])
	if typeof(characters) != TYPE_ARRAY:
		return []
	return characters


func unread_count() -> int:
	var count := 0
	for email in inbox:
		if not bool(email.get("read", false)):
			count += 1
	return count


func job_available(job: Dictionary) -> bool:
	var rule := str(job.get("unlock", ""))
	if bool(job.get("generated", false)) and jobs_cleared.has(str(job.get("id", ""))):
		return false
	if rule == "tutorial_done":
		return tutorial_done
	if rule.begins_with("job:"):
		return jobs_cleared.has(rule.trim_prefix("job:"))
	if rule.begins_with("rep:"):
		return rep_rank() >= int(rule.trim_prefix("rep:"))
	return false


func refresh_board() -> void:
	# A fresh board every day: three generated moves beside the story jobs.
	var count := 2 + mini(jobs_done / 2, 2)
	var made: Dictionary = JobGen.board(seed, day, rep_rank(), jobs_done, count)
	generated_jobs = made.get("jobs", [])
	# Keep the drives of jobs still in progress or on the old board for a day.
	var keep: Dictionary = {}
	for key in generated_drives.keys():
		if str(key) == str(job.get("def", {}).get("drive", "")):
			keep[key] = generated_drives[key]
	for key in made.get("drives", {}).keys():
		keep[key] = made["drives"][key]
	generated_drives = keep


func day_phase() -> String:
	# Morning until the first job is done, afternoon after it, evening after two.
	var done := int(day_log.get("jobs", 0))
	if done <= 0:
		return "morning"
	return "afternoon" if done == 1 else "evening"


func bump_stat(key: String, amount := 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount
	check_contracts()


func contracts() -> Array:
	var file := FileAccess.open("res://data/contracts.json", FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_ARRAY else []


func contract_progress(contract: Dictionary) -> int:
	var key := str(contract.get("stat", ""))
	if key == "jobs_done":
		return jobs_done
	if key == "hand_served":
		return shop_hand_served
	if key == "venues_seen":
		var seen := 0
		for venue_id in ["cafe", "train", "park", "bakery", "studio", "flat"]:
			if int(stats.get("venue_" + venue_id, 0)) > 0:
				seen += 1
		return seen
	return int(stats.get(key, 0))


func check_contracts() -> void:
	for contract in contracts():
		var id := str(contract.get("id", ""))
		if contracts_done.has(id):
			continue
		if contract_progress(contract) < int(contract.get("need", 1)):
			continue
		contracts_done[id] = day
		if not day_log.is_empty():
			(day_log.get("goals", []) as Array).append(str(contract.get("title", id)))
		var money_reward := int(contract.get("money", 0))
		var rep_reward := int(contract.get("rep", 0))
		if money_reward > 0:
			add_money(money_reward, false)
		if rep_reward > 0:
			rep_stars += rep_reward
			emit_signal("rep_changed", rep_rank(), rep_stars)
		emit_signal("toast_requested", "Goal done: %s. +$%d%s" % [contract.get("title", id), money_reward, (", +%d Rep star" % rep_reward) if rep_reward > 0 else ""])
		inbox.append({
			"id": "contract_" + id,
			"from": "Marge Holloway",
			"subject": "That's one for the wall: %s" % contract.get("title", id),
			"body": "%s\n\nYou did it. $%d in the jar%s. I'm pinning the next one up.\n\n— Marge" % [contract.get("blurb", ""), money_reward, (" and a Rep star" if rep_reward > 0 else "")],
			"read": false,
		})
		emit_signal("emails_changed")


func start_job(id: String) -> void:
	var def := JobDB.get_job(id)
	if def.is_empty():
		return
	var items: Array = JobDB.build_job_items(def)
	var cat_uid := ""
	if bool(def.get("cat", false)):
		var pool: Array = []
		for item in items:
			if not bool(item.get("heavy", false)):
				pool.append(item["uid"])
		if not pool.is_empty():
			cat_uid = pool[rng.randi() % pool.size()]
	job = {
		"id": id,
		"def": def,
		"items": items,
		"boxes": [],
		"next_box": 0,
		"cat_uid": cat_uid,
		"cat_opened": false,
		"condition": int(Tuning.get_value("box_condition.start", 100)),
		"alley": false,
		"duck_friend": false,
		"near_miss": false,
		"heavy_ok": true,
		"mystery_sorted": false,
		"phase": "pack",
	}
	set_mode("job_pack")


func ensure_open_box() -> int:
	for box in job.get("boxes", []):
		if not bool(box.get("sealed", false)):
			return int(box.get("id", 0))
	return make_box()


func make_box() -> int:
	var id := int(job.get("next_box", 0))
	job["next_box"] = id + 1
	job["boxes"].append({
		"id": id,
		"sealed": false,
		"padded": false,
		"has_cat": false,
		"slot": -1,
		"shock": 0.0,
	})
	return id


func pack_into(uid: String, box_id: int) -> String:
	var item := job_item(uid)
	var box := job_box(box_id)
	if item.is_empty() or box.is_empty():
		return "That box isn't here."
	if bool(box.get("sealed", false)):
		return "That box is already sealed."
	if bool(item.get("nobox", false)):
		return "Too big for a box. Wrap it and it goes on the truck as it is."
	if bool(item.get("bulky", false)) or bool(item.get("heavy", false)):
		if box_item_count(box_id) > 0:
			return "This one wants a box of its own."
	if box_has_bulky(box_id) and item["uid"] != bulky_uid(box_id):
		return "That box is already full of something hefty."
	item["box"] = box_id
	item["state"] = "boxed"
	return ""


func box_item_count(box_id: int) -> int:
	var count := 0
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id:
			count += 1
	return count


func box_has_bulky(box_id: int) -> bool:
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id and (bool(item.get("bulky", false)) or bool(item.get("heavy", false))):
			return true
	return false


func bulky_uid(box_id: int) -> String:
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id and (bool(item.get("bulky", false)) or bool(item.get("heavy", false))):
			return str(item.get("uid", ""))
	return ""


func box_needs_padding(box_id: int) -> bool:
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id and bool(item.get("fragile", false)):
			return true
	return false


func seal_box(box_id: int) -> bool:
	var box := job_box(box_id)
	if box.is_empty() or box_item_count(box_id) == 0:
		return false
	box["sealed"] = true
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id and str(item.get("uid", "")) == str(job.get("cat_uid", "")):
			box["has_cat"] = true
	return true


func wrap_big(uid: String) -> String:
	# A piece too big for any box: a blanket round it and its own place on the truck.
	var item := job_item(uid)
	if item.is_empty():
		return "That piece isn't here."
	if not bool(item.get("nobox", false)):
		return "That one fits in a box."
	if str(item.get("state", "")) != "loose":
		return "Already wrapped."
	var id := make_box()
	var box := job_box(id)
	box["sealed"] = true
	box["padded"] = true
	box["big"] = uid
	item["box"] = id
	item["state"] = "boxed"
	return ""


func all_sealed() -> bool:
	var any := false
	for item in job.get("items", []):
		any = true
		if str(item.get("state", "")) != "boxed":
			return false
		var box := job_box(int(item.get("box", -1)))
		if box.is_empty() or not bool(box.get("sealed", false)):
			return false
	return any


func split_sets() -> Array:
	var members: Dictionary = {}
	for item in job.get("items", []):
		var set_id := str(item.get("set", ""))
		if set_id == "":
			continue
		if not members.has(set_id):
			members[set_id] = []
		members[set_id].append(int(item.get("box", -1)))
	var split: Array = []
	for set_id in members.keys():
		var boxes: Array = members[set_id]
		var first = boxes[0]
		for box_id in boxes:
			if box_id != first:
				split.append(set_id)
				break
	return split


func open_cat(box_id: int) -> bool:
	var box := job_box(box_id)
	if box.is_empty() or not bool(box.get("has_cat", false)):
		return false
	if bool(job.get("cat_opened", false)):
		return true
	job["cat_opened"] = true
	if not museum.has("biscuit"):
		museum.append("biscuit")
		decor_serial += 1
		decor_queue.append({"uid": "decor_photo_%d" % decor_serial, "item": "museum_photo"})
	return true


func load_box_into(box_id: int, slot: int, floor_slots: int) -> String:
	var box := job_box(box_id)
	if box.is_empty() or not bool(box.get("sealed", false)):
		return "Seal it first."
	if slot_taken(slot):
		return "Something's already sitting there."
	if box_has_heavy(box_id) and slot >= floor_slots:
		return "The espresso machine is happier on the bottom."
	box["slot"] = slot
	return ""


func slot_taken(slot: int) -> bool:
	for box in job.get("boxes", []):
		if int(box.get("slot", -1)) == slot:
			return true
	return false


func box_has_heavy(box_id: int) -> bool:
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id and bool(item.get("heavy", false)):
			return true
	return false


func all_loaded() -> bool:
	for box in job.get("boxes", []):
		if bool(box.get("sealed", false)) and int(box.get("slot", -1)) < 0:
			return false
	return all_sealed()


func heavy_respected() -> bool:
	for box in job.get("boxes", []):
		if box_has_heavy(int(box.get("id", -1))) and int(box.get("slot", -1)) >= 4:
			return false
	return true


func apply_drive_result(result: Dictionary) -> void:
	job["condition"] = clampi(int(result.get("condition", 100)), 0, 100)
	job["alley"] = bool(result.get("alley", false))
	job["duck_friend"] = bool(result.get("duck_friend", false))
	job["near_miss"] = bool(result.get("near_miss", false))
	job["honks"] = int(result.get("honks", 0))
	job["spotted"] = int(result.get("spotted", 0))
	if int(job.get("spotted", 0)) > 0:
		Crime.on_drive(result)
	_assign_damage()


func _assign_damage() -> void:
	var base_stress := float(100 - int(job.get("condition", 100)))
	var budget := _stress_budget(base_stress)
	var scuffed := int(budget.x)
	var chipped := int(budget.y)
	var order: Array = []
	for item in job.get("items", []):
		var stress := _item_stress(item, base_stress)
		order.append({"uid": item["uid"], "stress": stress, "cap": _severity(stress)})
	order.sort_custom(func(a, b): return float(a["stress"]) > float(b["stress"]))
	for entry in order:
		if chipped <= 0:
			break
		if int(entry["cap"]) < 2:
			continue
		var item := job_item(str(entry["uid"]))
		item["damage"] = 2
		emit_signal("box_damaged", item["uid"], 2)
		chipped -= 1
	for entry in order:
		if scuffed <= 0:
			break
		if int(entry["cap"]) < 1:
			continue
		var item2 := job_item(str(entry["uid"]))
		if int(item2.get("damage", 0)) != 0:
			continue
		item2["damage"] = 1
		emit_signal("box_damaged", item2["uid"], 1)
		scuffed -= 1


func _item_stress(item: Dictionary, base_stress: float) -> float:
	var stress := base_stress
	var box := job_box(int(item.get("box", -1)))
	if bool(item.get("fragile", false)) and not box.is_empty() and bool(box.get("padded", false)):
		stress *= float(Tuning.get_value("box_condition.padding_multiplier", 0.5))
	if bool(item.get("heavy", false)) and _box_on_bottom(box):
		stress *= float(Tuning.get_value("box_condition.heavy_bottom_multiplier", 0.75))
	return stress


func _box_on_bottom(box: Dictionary) -> bool:
	if box.is_empty():
		return false
	var slot := int(box.get("slot", -1))
	return slot >= 0 and slot < 4


func _stress_budget(stress: float) -> Vector2:
	for band in Tuning.get_value("damage.stress_bands", []):
		if stress < float(band.get("below", 999)):
			return Vector2(float(band.get("scuffed", 0)), float(band.get("chipped", 0)))
	return Vector2.ZERO


func _severity(stress: float) -> int:
	var budget := _stress_budget(stress)
	if budget.y > 0.0:
		return 2
	if budget.x > 0.0:
		return 1
	return 0


func tap_repair(uid: String) -> bool:
	var item := _find_repair_target(uid)
	if item.is_empty():
		return false
	var level := int(item.get("damage", 0))
	if level <= 0:
		return false
	item["taps"] = int(item.get("taps", 0)) + 1
	if int(item["taps"]) >= Tuning.repair_taps(level):
		item["damage"] = 0
		item["taps"] = 0
		return true
	return false


func _find_repair_target(uid: String) -> Dictionary:
	if not job.is_empty():
		var found := job_item(uid)
		if not found.is_empty():
			return found
	for item in office_items:
		if str(item.get("uid", "")) == uid:
			return item
	return {}


func compute_payout(base: int, condition: int, bonuses: int, scuffed: int, chipped: int, alley: bool, split_count: int, room_score: float = -1.0) -> Dictionary:
	var ratio := Tuning.tip_ratio(condition)
	var box_tip := int(round(float(base) * ratio))
	var shortcut := 0
	if alley:
		shortcut = int(round(float(base) * float(Tuning.get_value("pay.alley_tip_bonus", 0.10))))
	var room_tip := 0
	if room_score >= 0.0:
		var floor_score := float(Tuning.get_value("stacking.room_tip_score_floor", 50.0))
		var tip_ratio := float(Tuning.get_value("stacking.room_tip_ratio", 0.10))
		var span := clampf((room_score - floor_score) / 50.0, 0.0, 1.0)
		room_tip = int(round(float(base) * tip_ratio * span))
	var split_loss := split_count * int(Tuning.get_value("pay.split_set_tip_loss", 8))
	var tips := maxi(0, box_tip + bonuses + room_tip - split_loss)
	var cut := Tuning.damage_cut(base, scuffed, chipped, tips)
	var net := tips - cut
	return {
		"base": base,
		"box_tip": box_tip,
		"room_tip": room_tip,
		"room_score": room_score,
		"shortcut": shortcut,
		"bonuses": bonuses,
		"split_loss": mini(split_loss, box_tip + bonuses + room_tip),
		"cut": cut,
		"net_tips": net,
		"total": base + net + shortcut,
		"stamp": Tuning.tip_stamp(condition),
		"condition": condition,
		"scuffed": scuffed,
		"chipped": chipped,
	}


func bust_job(result: Dictionary) -> void:
	# Boxed in by a patrol: the job is gone, there is a fine, a strike on
	# the record, and Marge hears about it.
	var def: Dictionary = job.get("def", {})
	var fine := clampi(int(float(money) * 0.2), 60, 600)
	add_money(-fine, false)
	rep_stars = maxi(0, rep_stars - 1)
	emit_signal("rep_changed", rep_rank(), rep_stars)
	bump_stat("busted")
	Crime.on_arrest(bool(def.get("shady", false)))
	inbox.append({
		"id": "busted_d%d" % day,
		"from": "Marge Holloway",
		"subject": "The truck came back on a flatbed",
		"body": "A patrol boxed you in on %s. The boxes went in the van and so did a chunk of the jar: $%d.\n\n%s\n\n— Marge" % [def.get("title", "a job"), fine, "I don't want to know what was in those boxes." if bool(def.get("shady", false)) else "Slow down near the patrols. They're bored, and you're easy."],
		"read": false,
	})
	emit_signal("emails_changed")
	payout = {
		"busted": true,
		"title": "Busted",
		"job_title": str(def.get("title", "the job")),
		"fine": fine,
		"shady": bool(def.get("shady", false)),
		"spotted": int(result.get("spotted", 0)),
		"stars": 0,
		"total": -fine,
		"base": 0,
		"box_tip": 0,
		"net_tips": 0,
	}
	job = {}
	set_mode("results")


func finish_job() -> Dictionary:
	var def: Dictionary = job.get("def", {})
	var base := JobDB.base_pay(def)
	var bonuses := 0
	if bool(job.get("cat_opened", false)):
		bonuses += int(Tuning.get_value("pay.cat_bonus", 20))
	if bool(job.get("duck_friend", false)):
		bonuses += int(Tuning.get_value("pay.duck_friend_bonus", 15))
	var honk_pay := int(job.get("honks", 0)) * int(Tuning.get_value("pay.honk_tip", 2))
	bonuses += honk_pay
	if int(job.get("honks", 0)) > 0:
		stats["honks"] = int(stats.get("honks", 0)) + int(job.get("honks", 0))
	var scuffed := 0
	var chipped := 0
	var all_fine := true
	for item in job.get("items", []):
		var level := int(item.get("damage", 0))
		if level == 1:
			scuffed += 1
			all_fine = false
		elif level >= 2:
			chipped += 1
			all_fine = false
	var splits: Array = split_sets()
	var room_score := float(job.get("room_score", -1.0))
	payout = compute_payout(base, int(job.get("condition", 100)), bonuses, scuffed, chipped, bool(job.get("alley", false)), splits.size(), room_score)
	payout["all_fine"] = all_fine
	payout["cat"] = bool(job.get("cat_opened", false))
	payout["honks"] = int(job.get("honks", 0))
	payout["honk_pay"] = honk_pay
	payout["duck"] = bool(job.get("duck_friend", false))
	payout["job_id"] = job.get("id", "")
	payout["title"] = def.get("title", "Job")
	var stars := 1
	if int(job.get("condition", 0)) >= 70:
		stars += 1
	if all_fine:
		stars += 1
	stars = mini(3, stars)
	payout["stars"] = stars
	var net_pay := int(payout.get("base", 0)) + int(payout.get("net_tips", 0)) + int(payout.get("shortcut", 0))
	add_money(net_pay, true)
	rep_stars += stars
	jobs_done += 1
	jobs_cleared[str(job.get("id", ""))] = true
	if int(job.get("condition", 0)) >= 90:
		stats["smooth_rides"] = int(stats.get("smooth_rides", 0)) + 1
	if bool(job.get("cat_opened", false)):
		stats["cats_found"] = int(stats.get("cats_found", 0)) + 1
	if bool(job.get("alley", false)):
		stats["alley_runs"] = int(stats.get("alley_runs", 0)) + 1
	if bool(def.get("generated", false)) and not bool(def.get("shady", false)):
		stats["board_jobs"] = int(stats.get("board_jobs", 0)) + 1
	var venue_key := "venue_%s" % str(def.get("venue", ""))
	stats[venue_key] = int(stats.get(venue_key, 0)) + 1
	Crime.on_job_finished(def)
	if day_log.is_empty():
		day_log = _fresh_day_log()
	day_log["jobs"] = int(day_log.get("jobs", 0)) + 1
	day_log["job_pay"] = int(day_log.get("job_pay", 0)) + net_pay
	if str(day_log.get("best_job", "")) == "":
		day_log["best_job"] = str(def.get("title", ""))
	check_contracts()
	emit_signal("rep_changed", rep_rank(), rep_stars)
	emit_signal("job_completed", job.get("id", ""), payout)
	fire_trigger(str(job.get("id", "")) + "_complete")
	if bool(def.get("mystery", false)) and bool(job.get("mystery_sorted", false)):
		if not museum.has("train"):
			museum.append("train")
			decor_serial += 1
			decor_queue.append({"uid": "decor_train_%d" % decor_serial, "item": "train_reward"})
	_check_unlock_email()
	return payout


func sort_mystery() -> void:
	job["mystery_sorted"] = true


func job_item(uid: String) -> Dictionary:
	for item in job.get("items", []):
		if str(item.get("uid", "")) == uid:
			return item
	return {}


func job_box(id: int) -> Dictionary:
	for box in job.get("boxes", []):
		if int(box.get("id", -2)) == id:
			return box
	return {}


func _seed_market() -> void:
	prices.clear()
	history.clear()
	var days := int(Tuning.get_value("pay.history_days", 7))
	for good in ItemDB.trade_goods():
		var id := str(good.get("id", ""))
		var base := float(ItemDB.base_price(id))
		var series: Array = []
		var value := base
		for i in days:
			value = _swing(base, value)
			series.append(value)
		history[id] = series
		prices[id] = value
		goods[id] = int(goods.get(id, 0))


func _swing(base: float, current: float) -> float:
	var min_s := float(Tuning.get_value("pay.swing_min", 0.10))
	var max_s := float(Tuning.get_value("pay.swing_max", 0.25))
	var sign := 1.0 if rng.randf() > 0.48 else -1.0
	var mag := rng.randf_range(min_s, max_s)
	var nxt := current * (1.0 + sign * mag)
	var floor_pct := float(Tuning.get_value("pay.price_min", 0.50))
	var ceil_pct := float(Tuning.get_value("pay.price_max", 2.50))
	return clampf(nxt, base * floor_pct, base * ceil_pct)


func _fresh_day_log() -> Dictionary:
	return {"money_start": money, "jobs": 0, "job_pay": 0, "trade_profit": 0, "decor": 0, "goals": [], "served_by_hand": 0, "best_job": ""}


func day_summary(closed_day: int) -> Dictionary:
	var log: Dictionary = day_log if not day_log.is_empty() else _fresh_day_log()
	return {
		"day": closed_day,
		"money_start": int(log.get("money_start", money)),
		"money_end": money,
		"jobs": int(log.get("jobs", 0)),
		"job_pay": int(log.get("job_pay", 0)),
		"best_job": str(log.get("best_job", "")),
		"shop_earned": shop_today,
		"shop_visitors": shop_visitors_today,
		"served_by_hand": int(log.get("served_by_hand", 0)),
		"trade_profit": int(log.get("trade_profit", 0)),
		"decor": int(log.get("decor", 0)),
		"goals": (log.get("goals", []) as Array).duplicate(),
		"rep": rep_rank(),
	}


func advance_day() -> void:
	var earned := shop_today
	var visitors := shop_visitors_today
	var vibe := vibe_score()
	var closed_day := day
	var summary := day_summary(closed_day)
	day += 1
	for good in ItemDB.trade_goods():
		var id := str(good.get("id", ""))
		var base := float(ItemDB.base_price(id))
		var nxt := _swing(base, float(prices.get(id, base)))
		prices[id] = nxt
		var series: Array = history.get(id, [])
		series.append(nxt)
		var keep := int(Tuning.get_value("pay.history_days", 7))
		while series.size() > keep:
			series.pop_front()
		history[id] = series
	_roll_buyer()
	promote_deliveries()
	if visitors > 0:
		_shop_summary(closed_day, earned, visitors, vibe)
	shop_today = 0
	shop_visitors_today = 0
	refresh_board()
	Crime.new_day()
	_charge_rent(summary)
	Crime.maybe_nudge(summary)
	if not generated_jobs.is_empty():
		summary["next_job"] = str(generated_jobs[0].get("title", ""))
	day_log = _fresh_day_log()
	emit_signal("day_ended", summary)


func rent_amount() -> int:
	return int(Tuning.get_value("rent.base", 80)) + shop_tier_rank() * int(Tuning.get_value("rent.per_tier", 60))


func rent_due_in() -> int:
	# Days until the next rent day.
	var every := maxi(1, int(Tuning.get_value("rent.every_days", 5)))
	var grace := int(Tuning.get_value("rent.grace_days", 4))
	if day <= grace:
		return grace + 1 - day
	return every - ((day - grace - 1) % every)


func _charge_rent(summary: Dictionary) -> void:
	# Rent comes due every few days after a grace period at the start. Unpaid
	# rent closes the shop until it is settled, and the landlord writes.
	var every := maxi(1, int(Tuning.get_value("rent.every_days", 5)))
	var grace := int(Tuning.get_value("rent.grace_days", 4))
	if day <= grace or (day - grace - 1) % every != 0:
		summary["rent_owed"] = rent_owed
		return
	var amount := rent_amount()
	rent_owed += amount
	summary["rent"] = amount
	try_pay_rent()
	summary["rent_owed"] = rent_owed
	if rent_owed > 0:
		inbox.append({"id": "rent_d%d" % day, "from": "Hollis Property", "subject": "Rent overdue", "body": "Rent of $%d for the garage was due today and the account is short. The shop stays shut until it is settled.\n\nWe like you. We also like being paid.\n\n— Hollis Property" % amount, "read": false})
		emit_signal("emails_changed")
		emit_signal("toast_requested", "Rent is overdue: $%d. The shop stays shut until it's paid." % rent_owed)
	else:
		emit_signal("toast_requested", "Rent paid: $%d." % amount)


func try_pay_rent() -> bool:
	if rent_owed <= 0:
		return true
	if money < rent_owed:
		return false
	money -= rent_owed
	day_log["rent"] = int(day_log.get("rent", 0)) + rent_owed
	rent_owed = 0
	emit_signal("money_changed", money)
	return true


func price_of(id: String) -> int:
	return maxi(1, int(round(float(prices.get(id, ItemDB.base_price(id))))))


func sell_price_of(id: String) -> int:
	var ratio := float(Tuning.get_value("pay.sell_ratio", 0.90))
	return maxi(1, int(round(float(price_of(id)) * ratio)))


func buy_good(id: String) -> String:
	var cost := price_of(id)
	if money < cost:
		return "Not quite enough in the jar."
	add_money(-cost, false)
	goods[id] = int(goods.get(id, 0)) + 1
	_push_cost(id, cost)
	return ""


func sell_good(id: String) -> Dictionary:
	if int(goods.get(id, 0)) <= 0:
		return {"error": "You don't have one to sell."}
	var gain := sell_price_of(id)
	var cost := _pop_cost(id)
	goods[id] = int(goods[id]) - 1
	add_money(gain, false)
	var profit := gain - cost
	_credit_net(profit)
	if profit > 0:
		fire_trigger("first_profitable_sale")
	bump_stat("goods_sold")
	if not day_log.is_empty():
		day_log["trade_profit"] = int(day_log.get("trade_profit", 0)) + profit
	return {"gain": gain, "profit": profit}


func sell_to_buyer() -> Dictionary:
	if buyer_offer.is_empty():
		return {"error": "Nobody's asking today."}
	var id := str(buyer_offer.get("item", ""))
	var grade := str(buyer_offer.get("grade", "worn"))
	if grade != "worn":
		if Workshop.graded(id, grade) <= 0:
			return {"error": "They want a %s one. Fix one up on the workbench first." % grade}
		return Workshop.sell_graded(id, grade)
	if int(goods.get(id, 0)) <= 0:
		return {"error": "You don't have that one yet."}
	var gain := int(buyer_offer.get("price", 0))
	var cost := _pop_cost(id)
	goods[id] = int(goods[id]) - 1
	add_money(gain, false)
	var profit := gain - cost
	_credit_net(profit)
	if profit > 0:
		fire_trigger("first_profitable_sale")
	var result := {"gain": gain, "profit": profit, "buyer": buyer_offer.get("name", "")}
	_roll_buyer()
	return result


func _roll_buyer() -> void:
	buyer_offer = {}
	if ItemDB.buyers.is_empty() or ItemDB.trade_goods().is_empty():
		return
	var buyer: Dictionary = ItemDB.buyers[rng.randi() % ItemDB.buyers.size()]
	var wants: Array = buyer.get("wants", [])
	if wants.is_empty():
		return
	var item_id := str(wants[rng.randi() % wants.size()])
	var premium := float(Tuning.get_value("pay.buyer_premium", 1.35))
	# Some buyers want it fixed up first; the workbench can take a worn one up a grade.
	var grade := "worn"
	var roll := rng.randf()
	if roll < 0.25:
		grade = "restored"
		premium *= 1.6
	elif roll < 0.35:
		grade = "mint"
		premium *= 2.4
	buyer_offer = {
		"name": buyer.get("name", "A buyer"),
		"line": buyer.get("line", "") if grade == "worn" else "%s Only if it's %s, mind." % [buyer.get("line", ""), grade],
		"item": item_id,
		"grade": grade,
		"price": maxi(1, int(round(float(price_of(item_id)) * premium))),
	}


func buy_decor(id: String) -> String:
	var item := ItemDB.get_item(id)
	var cost := int(item.get("price", 0))
	if cost <= 0:
		return "That's a gift, not a listing."
	if money < cost:
		return "The jar needs a little more."
	add_money(-cost, false)
	decor_serial += 1
	decor_queue.append({"uid": "decor_%s_%d" % [id, decor_serial], "item": id})
	bump_stat("decor_bought")
	if not day_log.is_empty():
		day_log["decor"] = int(day_log.get("decor", 0)) + 1
	return ""


func queue_pop_to_hand() -> Dictionary:
	if decor_queue.is_empty():
		return {}
	return decor_queue[0]


func place_decor_from_queue(pos: Dictionary, prefer_uid := "") -> void:
	if decor_queue.is_empty():
		return
	var index := 0
	if prefer_uid != "":
		for i in decor_queue.size():
			if str(decor_queue[i].get("uid", "")) == prefer_uid:
				index = i
				break
	var entry: Dictionary = decor_queue.pop_at(index)
	entry["state"] = "placed"
	entry["damage"] = 0
	if pos.has("pos"):
		var at: Vector3 = pos["pos"]
		entry["x"] = at.x
		entry["y"] = at.y
		entry["z"] = at.z
	else:
		entry["x"] = pos.get("x", 0)
		entry["y"] = pos.get("y", 0)
		entry["z"] = pos.get("z", 0)
	entry["rot"] = pos.get("rot", 0)
	entry["wall"] = pos.get("wall", "")
	entry["settle"] = str(entry.get("wall", "")) == ""
	office_items.append(entry)


func find_office_item(uid: String) -> Dictionary:
	for item in office_items:
		if str(item.get("uid", "")) == uid:
			return item
	return {}


func loose_job_items() -> Array:
	var loose: Array = []
	for item in job.get("items", []):
		if str(item.get("state", "")) == "loose":
			loose.append(item)
	return loose


func order_forest(sku_id: String, tier: String) -> String:
	Catalog.ensure()
	var entry := Catalog.sku(sku_id)
	if entry.is_empty():
		return "That listing grew legs and left."
	if not Catalog.category_open(str(entry.get("category", "")), office_id):
		return "That aisle unlocks with a bigger office."
	var ship := Catalog.shipping(tier)
	if ship.is_empty():
		ship = Catalog.shipping("standard")
		tier = "standard"
	var price := Catalog.price_of(sku_id, day)
	var fee := int(ship.get("fee", 0))
	if prime and tier == "express":
		fee = 0
	if money < price + fee:
		return "The jar is a little light for that."
	add_money(-(price + fee), false)
	forest_serial += 1
	var days := int(ship.get("days", 1))
	orders.append({
		"uid": "ship_%d" % forest_serial,
		"sku": sku_id,
		"item": str(entry.get("item", "")),
		"paid": price,
		"fee": fee,
		"arrive_day": day + days,
		"status": "door" if days <= 0 else "shipping",
		"bubbles_left": -1,
		"mystery": bool(entry.get("mystery", false)),
	})
	_maybe_freebie()
	if days <= 0:
		emit_signal("toast_requested", "The courier is already on the block.")
	else:
		emit_signal("toast_requested", "Standard shipping. The bell rings tomorrow.")
	return ""


func _maybe_freebie() -> void:
	var every := int(Catalog.forest.get("freebie_every", 4))
	if every <= 0 or day % every != 0 or freebie_day == day:
		return
	var pool: Array = Catalog.forest.get("freebies", [])
	if pool.is_empty():
		return
	freebie_day = day
	forest_serial += 1
	var item_id := str(pool[rng.randi() % pool.size()])
	orders.append({
		"uid": "gift_%d" % forest_serial,
		"sku": "freebie",
		"item": item_id,
		"paid": 0,
		"fee": 0,
		"arrive_day": day,
		"status": "door",
		"bubbles_left": -1,
		"mystery": false,
		"gift": true,
	})


func promote_deliveries() -> void:
	for order in orders:
		if str(order.get("status", "")) == "shipping" and int(order.get("arrive_day", 99)) <= day:
			order["status"] = "door"


func door_orders() -> Array:
	var waiting: Array = []
	for order in orders:
		var status := str(order.get("status", ""))
		if status == "door" or status == "open":
			waiting.append(order)
	return waiting


func delivery_by_uid(uid: String) -> Dictionary:
	for order in orders:
		if str(order.get("uid", "")) == uid:
			return order
	return {}


func toggle_wishlist(sku_id: String) -> bool:
	if sku_id in wishlist:
		wishlist.erase(sku_id)
		return false
	wishlist.append(sku_id)
	return true


func buy_prime() -> String:
	if prime:
		return "Toucan Prime is already on the account."
	var spec := Catalog.prime_def()
	if total_earned < int(spec.get("earned", 400)):
		return str(spec.get("blurb", "Not yet."))
	var cost := int(spec.get("cost", 40))
	if money < cost:
		return "The jar needs a little more for Prime."
	add_money(-cost, false)
	prime = true
	return ""


func return_delivery(uid: String) -> String:
	var order := delivery_by_uid(uid)
	if order.is_empty():
		return "That box already came open."
	var status := str(order.get("status", ""))
	var sealed := int(Catalog.forest.get("bubbles", 5))
	if status == "open" and int(order.get("bubbles_left", sealed)) < sealed:
		return "The wrap is already open. Place it, then send it back if you want."
	if status != "door" and status != "open":
		return "That box already came open."
	var refund := int(round(float(order.get("paid", 0)) * float(Catalog.forest.get("return_sealed", 1.0))))
	orders.erase(order)
	if refund > 0:
		add_money(refund, false)
	emit_signal("toast_requested", "Returned in the box. $%d walked back to the jar." % refund)
	return ""


func start_unbox(uid: String) -> void:
	var order := delivery_by_uid(uid)
	if order.is_empty() or str(order.get("status", "")) != "door":
		return
	order["status"] = "open"
	order["bubbles_left"] = int(Catalog.forest.get("bubbles", 5))


func pop_bubble(uid: String) -> int:
	var order := delivery_by_uid(uid)
	if order.is_empty():
		return 0
	if str(order.get("status", "")) == "door":
		start_unbox(uid)
	var left := int(order.get("bubbles_left", 0)) - 1
	order["bubbles_left"] = maxi(0, left)
	return int(order.get("bubbles_left", 0))


func finish_unbox(uid: String) -> Dictionary:
	var order := delivery_by_uid(uid)
	if order.is_empty():
		return {}
	if int(order.get("bubbles_left", 1)) > 0:
		return {}
	var item_id := str(order.get("item", ""))
	if bool(order.get("mystery", false)):
		var pool: Array = Catalog.sku(str(order.get("sku", ""))).get("pool", [])
		if not pool.is_empty():
			item_id = str(pool[rng.randi() % pool.size()])
	decor_serial += 1
	var placed := {
		"uid": "forest_%d" % decor_serial,
		"item": item_id,
		"source": "forest",
		"sku": str(order.get("sku", "")),
		"paid": int(order.get("paid", 0)),
		"gift": bool(order.get("gift", false)),
	}
	decor_queue.append(placed)
	orders.erase(order)
	return placed


func return_office_item(uid: String) -> String:
	var rec := find_office_item(uid)
	if rec.is_empty() or str(rec.get("source", "")) != "forest":
		return "TropicalForest only takes its own boxes back."
	var refund := int(round(float(rec.get("paid", 0)) * float(Catalog.forest.get("return_placed", 0.8))))
	office_items.erase(rec)
	if refund > 0:
		add_money(refund, false)
	return ""


func resell_office_item(uid: String) -> String:
	var rec := find_office_item(uid)
	if rec.is_empty() or str(rec.get("source", "")) != "forest":
		return "The market wants something that came from the forest."
	var paid := int(rec.get("paid", 0))
	var gain := int(round(float(paid) * float(Catalog.forest.get("resell_ratio", 0.6))))
	office_items.erase(rec)
	if gain > 0:
		add_money(gain, false)
	else:
		add_money(1, false)
		gain = 1
	_credit_net(gain - paid)
	return ""


func vibe_score() -> int:
	Catalog.ensure()
	var score := int(Catalog.shop_number("music_bonus", 6)) + int(Catalog.shop_number("clean_base", 12))
	for rec in office_items:
		if str(rec.get("state", "")) != "placed":
			continue
		var item_id := str(rec.get("item", ""))
		for tag in Catalog.tags_for(item_id):
			match str(tag):
				"plant":
					score += 8
				"light":
					score += 6
				"decor", "counter":
					score += 3
				"music":
					score += 4
		if int(rec.get("damage", 0)) > 0:
			score -= int(Catalog.shop_number("damage_penalty", 2))
	if _barista_on():
		score += int(Catalog.shop.get("barista", {}).get("vibe", 8))
	var cap := int(Catalog.shop_number("cap", 100))
	var floor_v := int(Catalog.shop_number("floor_vibe", 8))
	return clampi(score, floor_v, cap)


func shop_fixtures() -> Array:
	var placed := {}
	for rec in office_items:
		if str(rec.get("state", "")) == "placed":
			placed[str(rec.get("item", ""))] = true
	var open: Array = []
	for fix in Catalog.fixtures():
		if placed.has(str(fix.get("item", ""))):
			open.append(fix)
	return open


func shop_open() -> bool:
	return not shop_fixtures().is_empty() or shop_tier_rank() >= 1


func shop_accepting() -> bool:
	return shop_open() and not shop_closed and not Crime.raided_today() and rent_owed <= 0


func shop_dishes() -> Array:
	var dishes: Array = []
	for fix in shop_fixtures():
		for dish_id in fix.get("serves", []):
			if not dishes.has(str(dish_id)):
				dishes.append(str(dish_id))
	# The tier's own menu comes with the counter: once a fixture is in, the
	# kitchen behind it can serve the lot.
	if not dishes.is_empty() or shop_tier_rank() >= 1:
		for tier in Catalog.tiers():
			for dish_id in tier.get("dishes", []):
				if not dishes.has(str(dish_id)):
					dishes.append(str(dish_id))
			if str(tier.get("id", "")) == shop_tier:
				break
	return dishes


func shop_tier_rank() -> int:
	var rank := 0
	for tier in Catalog.tiers():
		if str(tier.get("id", "")) == shop_tier:
			return rank
		rank += 1
	return 0


func next_shop_tier() -> Dictionary:
	var tiers := Catalog.tiers()
	var rank := shop_tier_rank()
	if rank + 1 < tiers.size():
		return tiers[rank + 1]
	return {}


func upgrade_shop() -> String:
	var tier := next_shop_tier()
	if tier.is_empty():
		return "That is the top of the ladder."
	if rep_rank() < int(tier.get("rep", 0)):
		return "Needs Rep %d. You have %d." % [int(tier.get("rep", 0)), rep_rank()]
	var cost := int(tier.get("cost", 0))
	if money < cost:
		return "Needs $%d. You have $%d." % [cost, money]
	add_money(-cost, false)
	shop_tier = str(tier.get("id", "stand"))
	stats["shop_tier_rank"] = shop_tier_rank()
	emit_signal("toast_requested", "The sign says %s now." % tier.get("name", ""))
	inbox.append({
		"id": "tier_" + shop_tier,
		"from": "Marge Holloway",
		"subject": "%s. Look at you." % tier.get("name", ""),
		"body": "%s\n\nNew menu, same jar. Serve them by hand when you can.\n\n— Marge" % tier.get("blurb", ""),
		"read": false,
	})
	emit_signal("emails_changed")
	check_contracts()
	return ""


func pick_order() -> Dictionary:
	# What the next customer wants, and who they are.
	var dishes := shop_dishes()
	if dishes.is_empty():
		return {}
	var dish_id := str(dishes[rng.randi() % dishes.size()])
	var cast := Catalog.visitors()
	var who: Dictionary = {}
	if not cast.is_empty():
		who = cast[(day + shop_visitors_today + shop_ledger.size()) % cast.size()]
	return {"dish": dish_id, "who": who}


func _barista_on() -> bool:
	var spec: Dictionary = Catalog.shop.get("barista", {})
	var job_id := str(spec.get("unlock_job", ""))
	if job_id != "" and not jobs_cleared.has(job_id):
		return false
	var needs: Array = spec.get("needs", [])
	if needs.is_empty():
		return false
	for rec in office_items:
		if str(rec.get("state", "")) != "placed":
			continue
		if str(rec.get("item", "")) in needs:
			return true
	return false


func serve_visitor(by_hand := false, order: Dictionary = {}) -> Dictionary:
	# Serving by hand earns the whole tip; a customer who waits it out still pays, tip halved.
	if order.is_empty():
		order = pick_order()
	if order.is_empty():
		return {}
	var dish_id := str(order.get("dish", ""))
	var who: Dictionary = order.get("who", {})
	var dish := Catalog.menu_item(dish_id)
	var vibe := vibe_score()
	var base := int(round(float(dish.get("price", 3)) * menu_markup))
	var tip := float(base) * float(vibe) * Catalog.shop_number("tip_per_vibe", 0.012)
	tip *= Catalog.shop_number("hand_tip_bonus", 1.6) if by_hand else 0.5
	tip *= float(order.get("tip_mult", 1.0))
	var pay := maxi(1, base + int(round(tip)))
	add_money(pay, true)
	shop_today += pay
	shop_visitors_today += 1
	if by_hand:
		shop_hand_served += 1
		if not day_log.is_empty():
			day_log["served_by_hand"] = int(day_log.get("served_by_hand", 0)) + 1
		check_contracts()
	_visitor_request(who)
	var sale := {
		"name": str(who.get("name", "A neighbor")),
		"line": str(who.get("line", "Just looking, then not.")),
		"dish": str(dish.get("name", dish_id)),
		"dish_id": dish_id,
		"pay": pay,
		"tip": int(round(tip)),
		"vibe": vibe,
		"hand": by_hand,
		"day": day,
	}
	shop_ledger.push_front(sale)
	if shop_ledger.size() > 8:
		shop_ledger.resize(8)
	return sale


func _visitor_request(who: Dictionary) -> void:
	var sku_id := str(who.get("request", ""))
	if sku_id == "":
		return
	var key := "request_%s" % str(who.get("id", sku_id))
	if fired.has(key):
		return
	var entry := Catalog.sku(sku_id)
	var item_id := str(entry.get("item", ""))
	for rec in office_items:
		if str(rec.get("state", "")) == "placed" and str(rec.get("item", "")) == item_id:
			return
	fired[key] = true
	inbox.append({
		"id": key,
		"from": str(who.get("name", "A regular")),
		"subject": "A small request",
		"body": str(who.get("request_note", "If you see it on TropicalForest, the shop would like it.")),
		"read": false,
	})
	emit_signal("emails_changed")


func _shop_summary(closed_day: int, earned: int, visitors: int, vibe: int) -> void:
	var spec: Dictionary = Catalog.shop.get("summary_email", {})
	var body := str(spec.get("body", ""))
	body = body.replace("{day}", str(closed_day))
	body = body.replace("{earned}", str(earned))
	body = body.replace("{visitors}", str(visitors))
	body = body.replace("{vibe}", str(vibe))
	inbox.append({
		"id": "shop_day_%d" % closed_day,
		"from": str(spec.get("from", "Marge Holloway")),
		"subject": str(spec.get("subject", "The till")).replace("{day}", str(closed_day)),
		"body": body,
		"read": false,
	})
	emit_signal("emails_changed")


func set_markup(value: float) -> void:
	menu_markup = clampf(value, 0.5, 2.0)


func to_dict() -> Dictionary:
	return {
		"version": 1,
		"character": character,
		"money": money,
		"total_earned": total_earned,
		"rep_stars": rep_stars,
		"jobs_done": jobs_done,
		"jobs_cleared": jobs_cleared.duplicate(true),
		"office_id": office_id,
		"day": day,
		"mode": mode,
		"office_phase": office_phase,
		"office_items": office_items.duplicate(true),
		"decor_queue": decor_queue.duplicate(true),
		"goods": goods.duplicate(true),
		"goods_cost": goods_cost.duplicate(true),
		"prices": prices.duplicate(true),
		"history": history.duplicate(true),
		"inbox": inbox.duplicate(true),
		"fired": fired.duplicate(true),
		"tutorial_done": tutorial_done,
		"first_placed": first_placed,
		"museum": museum.duplicate(),
		"job": _job_for_save(),
		"payout": payout.duplicate(true),
		"buyer_offer": buyer_offer.duplicate(true),
		"pastry_day": pastry_day,
		"decor_serial": decor_serial,
		"orders": orders.duplicate(true),
		"wishlist": wishlist.duplicate(),
		"prime": prime,
		"menu_markup": menu_markup,
		"shop_today": shop_today,
		"shop_visitors_today": shop_visitors_today,
		"shop_ledger": shop_ledger.duplicate(true),
		"shop_closed": shop_closed,
		"shop_hand_served": shop_hand_served,
		"seed": seed,
		"generated_jobs": generated_jobs.duplicate(true),
		"generated_drives": generated_drives.duplicate(true),
		"stats": stats.duplicate(true),
		"contracts_done": contracts_done.duplicate(true),
		"day_log": day_log.duplicate(true),
		"shop_tier": shop_tier,
		"workshop": workshop.duplicate(true),
		"crime": crime.duplicate(true),
		"rent_owed": rent_owed,
		"freebie_day": freebie_day,
		"forest_serial": forest_serial,
		"latched_goals": latched_goals.duplicate(true),
	}


func _job_for_save() -> Dictionary:
	if job.is_empty():
		return {}
	var copy := job.duplicate(true)
	return copy


func from_dict(raw: Dictionary) -> void:
	character = str(raw.get("character", "dana"))
	money = int(raw.get("money", 120))
	total_earned = int(raw.get("total_earned", 0))
	rep_stars = int(raw.get("rep_stars", 0))
	jobs_done = int(raw.get("jobs_done", 0))
	jobs_cleared = raw.get("jobs_cleared", {})
	office_id = str(raw.get("office_id", "garage"))
	day = int(raw.get("day", 1))
	mode = str(raw.get("mode", "office"))
	office_phase = str(raw.get("office_phase", "live"))
	office_items = raw.get("office_items", [])
	decor_queue = raw.get("decor_queue", [])
	goods = raw.get("goods", {})
	goods_cost = raw.get("goods_cost", {})
	prices = raw.get("prices", {})
	history = raw.get("history", {})
	inbox = raw.get("inbox", [])
	fired = raw.get("fired", {})
	tutorial_done = bool(raw.get("tutorial_done", false))
	first_placed = bool(raw.get("first_placed", false))
	museum = raw.get("museum", [])
	job = raw.get("job", {})
	if mode == "drive" or mode == "menu":
		mode = "truck" if not job.is_empty() else "office"
	payout = raw.get("payout", {})
	buyer_offer = raw.get("buyer_offer", {})
	pastry_day = int(raw.get("pastry_day", -1))
	decor_serial = int(raw.get("decor_serial", 0))
	orders = raw.get("orders", [])
	wishlist = raw.get("wishlist", [])
	prime = bool(raw.get("prime", false))
	menu_markup = float(raw.get("menu_markup", 1.0))
	shop_today = int(raw.get("shop_today", 0))
	shop_visitors_today = int(raw.get("shop_visitors_today", 0))
	shop_ledger = raw.get("shop_ledger", []).duplicate(true) if raw.has("shop_ledger") else []
	shop_closed = bool(raw.get("shop_closed", false))
	shop_hand_served = int(raw.get("shop_hand_served", 0))
	seed = int(raw.get("seed", 0))
	generated_jobs = raw.get("generated_jobs", []).duplicate(true) if raw.has("generated_jobs") else []
	generated_drives = raw.get("generated_drives", {}).duplicate(true) if raw.has("generated_drives") else {}
	stats = raw.get("stats", {}).duplicate(true) if raw.has("stats") else {}
	contracts_done = raw.get("contracts_done", {}).duplicate(true) if raw.has("contracts_done") else {}
	day_log = raw.get("day_log", {}).duplicate(true) if raw.has("day_log") else _fresh_day_log()
	if day_log.is_empty():
		day_log = _fresh_day_log()
	shop_tier = str(raw.get("shop_tier", "stand"))
	workshop = raw.get("workshop", {}).duplicate(true) if raw.has("workshop") else Workshop.fresh()
	if workshop.is_empty():
		workshop = Workshop.fresh()
	crime = raw.get("crime", {}).duplicate(true) if raw.has("crime") else Crime.fresh()
	rent_owed = int(raw.get("rent_owed", 0))
	if crime.is_empty():
		crime = Crime.fresh()
	if generated_jobs.is_empty():
		refresh_board()
	freebie_day = int(raw.get("freebie_day", -1))
	forest_serial = int(raw.get("forest_serial", 0))
	latched_goals = raw.get("latched_goals", {})
	goal_marked = {}
	emit_signal("money_changed", money)
	emit_signal("emails_changed")
