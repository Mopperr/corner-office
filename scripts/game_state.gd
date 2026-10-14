extends Node

signal money_changed(amount)
signal rep_changed(rank, stars)
signal job_completed(job_id, payout)
signal box_damaged(uid, level)
signal emails_changed
signal mode_changed(mode)
signal toast_requested(message)
signal office_changed(office_id)

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
var freebie_day := -1
var forest_serial := 0
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
	freebie_day = -1
	forest_serial = 0
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
		var before := total_earned
		total_earned += amount
		_check_earn_triggers(before, total_earned)
	emit_signal("money_changed", money)
	_check_unlock_email()


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
	if rule == "tutorial_done":
		return tutorial_done
	if rule.begins_with("job:"):
		return jobs_cleared.has(rule.trim_prefix("job:"))
	return false


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
	_assign_damage()


func _assign_damage() -> void:
	var condition := int(job.get("condition", 100))
	var stress := float(100 - condition)
	var fragile_unpadded := false
	for box in job.get("boxes", []):
		if box_needs_padding(int(box.get("id", -1))) and not bool(box.get("padded", false)):
			fragile_unpadded = true
	if not fragile_unpadded:
		stress *= float(Tuning.get_value("box_condition.padding_multiplier", 0.5))
	if heavy_respected():
		stress *= float(Tuning.get_value("box_condition.heavy_bottom_multiplier", 0.75))
	var scuffed := 0
	var chipped := 0
	for band in Tuning.get_value("damage.stress_bands", []):
		if stress < float(band.get("below", 999)):
			scuffed = int(band.get("scuffed", 0))
			chipped = int(band.get("chipped", 0))
			break
	var order: Array = []
	for item in job.get("items", []):
		var score := 0
		if bool(item.get("fragile", false)):
			score += 2
			var box := job_box(int(item.get("box", -1)))
			if not box.is_empty() and not bool(box.get("padded", false)):
				score += 2
		order.append({"uid": item["uid"], "score": score})
	order.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	var idx := 0
	while chipped > 0 and idx < order.size():
		var item := job_item(str(order[idx]["uid"]))
		item["damage"] = 2
		emit_signal("box_damaged", item["uid"], 2)
		chipped -= 1
		idx += 1
	while scuffed > 0 and idx < order.size():
		var item2 := job_item(str(order[idx]["uid"]))
		if int(item2.get("damage", 0)) == 0:
			item2["damage"] = 1
			emit_signal("box_damaged", item2["uid"], 1)
			scuffed -= 1
		idx += 1


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


func compute_payout(base: int, condition: int, bonuses: int, scuffed: int, chipped: int, alley: bool, split_count: int) -> Dictionary:
	var ratio := Tuning.tip_ratio(condition)
	var box_tip := int(round(float(base) * ratio))
	if alley:
		var alley_bonus := float(Tuning.get_value("pay.alley_tip_bonus", 0.10))
		box_tip = int(round(float(box_tip) * (1.0 + alley_bonus)))
	var split_loss := split_count * int(Tuning.get_value("pay.split_set_tip_loss", 8))
	var tips := maxi(0, box_tip + bonuses - split_loss)
	var cut := Tuning.damage_cut(base, scuffed, chipped, tips)
	var net := tips - cut
	return {
		"base": base,
		"box_tip": box_tip,
		"bonuses": bonuses,
		"split_loss": mini(split_loss, box_tip + bonuses),
		"cut": cut,
		"net_tips": net,
		"total": base + net,
		"stamp": Tuning.tip_stamp(condition),
		"condition": condition,
		"scuffed": scuffed,
		"chipped": chipped,
	}


func finish_job() -> Dictionary:
	var def: Dictionary = job.get("def", {})
	var base := JobDB.base_pay(def)
	var bonuses := 0
	if bool(job.get("cat_opened", false)):
		bonuses += int(Tuning.get_value("pay.cat_bonus", 20))
	if bool(job.get("duck_friend", false)):
		bonuses += int(Tuning.get_value("pay.duck_friend_bonus", 15))
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
	payout = compute_payout(base, int(job.get("condition", 100)), bonuses, scuffed, chipped, bool(job.get("alley", false)), splits.size())
	payout["all_fine"] = all_fine
	payout["cat"] = bool(job.get("cat_opened", false))
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
	add_money(int(payout["total"]), true)
	rep_stars += stars
	jobs_done += 1
	jobs_cleared[str(job.get("id", ""))] = true
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
	return clampf(nxt, base * 0.55, base * 1.85)


func advance_day() -> void:
	var earned := shop_today
	var visitors := shop_visitors_today
	var vibe := vibe_score()
	var closed_day := day
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


func price_of(id: String) -> int:
	return maxi(1, int(round(float(prices.get(id, ItemDB.base_price(id))))))


func sell_price_of(id: String) -> int:
	var ratio := float(Tuning.get_value("pay.sell_ratio", 0.75))
	return maxi(1, int(round(float(price_of(id)) * ratio)))


func buy_good(id: String) -> String:
	var cost := price_of(id)
	if money < cost:
		return "Not quite enough in the jar."
	add_money(-cost, false)
	goods[id] = int(goods.get(id, 0)) + 1
	return ""


func sell_good(id: String) -> Dictionary:
	if int(goods.get(id, 0)) <= 0:
		return {"error": "You don't have one to sell."}
	var gain := sell_price_of(id)
	goods[id] = int(goods[id]) - 1
	var paid_guess := ItemDB.base_price(id)
	add_money(gain, true)
	var profit := gain - paid_guess
	if profit > 0:
		fire_trigger("first_profitable_sale")
	return {"gain": gain, "profit": profit}


func sell_to_buyer() -> Dictionary:
	if buyer_offer.is_empty():
		return {"error": "Nobody's asking today."}
	var id := str(buyer_offer.get("item", ""))
	if int(goods.get(id, 0)) <= 0:
		return {"error": "You don't have that one yet."}
	var gain := int(buyer_offer.get("price", 0))
	goods[id] = int(goods[id]) - 1
	add_money(gain, true)
	fire_trigger("first_profitable_sale")
	var result := {"gain": gain, "profit": gain - ItemDB.base_price(id), "buyer": buyer_offer.get("name", "")}
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
	buyer_offer = {
		"name": buyer.get("name", "A buyer"),
		"line": buyer.get("line", ""),
		"item": item_id,
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
	entry["x"] = pos.get("x", 0)
	entry["y"] = pos.get("y", 0)
	entry["z"] = pos.get("z", 0)
	entry["rot"] = pos.get("rot", 0)
	entry["wall"] = pos.get("wall", "")
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
	var gain := int(round(float(rec.get("paid", 0)) * float(Catalog.forest.get("resell_ratio", 0.6))))
	office_items.erase(rec)
	if gain > 0:
		add_money(gain, true)
	else:
		add_money(1, true)
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
	return not shop_fixtures().is_empty()


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


func serve_visitor() -> Dictionary:
	var fixes := shop_fixtures()
	if fixes.is_empty():
		return {}
	var dishes: Array = []
	for fix in fixes:
		for dish_id in fix.get("serves", []):
			dishes.append(str(dish_id))
	if dishes.is_empty():
		return {}
	var dish_id := str(dishes[rng.randi() % dishes.size()])
	var dish := Catalog.menu_item(dish_id)
	var vibe := vibe_score()
	var base := int(round(float(dish.get("price", 3)) * menu_markup))
	var tip := int(round(float(base) * float(vibe) * Catalog.shop_number("tip_per_vibe", 0.012)))
	var pay := maxi(1, base + tip)
	add_money(pay, true)
	shop_today += pay
	shop_visitors_today += 1
	var cast := Catalog.visitors()
	var who: Dictionary = {}
	if not cast.is_empty():
		who = cast[(day + shop_visitors_today) % cast.size()]
	_visitor_request(who)
	return {
		"name": str(who.get("name", "A neighbor")),
		"line": str(who.get("line", "Just looking, then not.")),
		"dish": str(dish.get("name", dish_id)),
		"pay": pay,
		"vibe": vibe,
	}


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
		"freebie_day": freebie_day,
		"forest_serial": forest_serial,
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
	freebie_day = int(raw.get("freebie_day", -1))
	forest_serial = int(raw.get("forest_serial", 0))
	emit_signal("money_changed", money)
	emit_signal("emails_changed")
