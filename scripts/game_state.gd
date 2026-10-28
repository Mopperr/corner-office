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
var life: Dictionary = {}
const Workshop = preload("res://scripts/workshop.gd")
const Crime = preload("res://scripts/crime.gd")
const JobGen = preload("res://scripts/job_gen.gd")
const Homes = preload("res://scripts/homes.gd")
const Life = preload("res://scripts/life.gd")
const Books = preload("res://scripts/books.gd")
const Extras = preload("res://scripts/extras.gd")
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
	hospital = {}
	grudge = {}
	accountant = {}
	ledger = {}
	ledger_days = []
	gear = []
	streak = 0
	league = Extras.league_fresh()
	achievements = []
	contracts_done = {}
	day_log = _fresh_day_log()
	shop_tier = "stand"
	workshop = Workshop.fresh()
	crime = Crime.fresh()
	life = Life.fresh()
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
	_character_start()
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
		Life.check_milestones(before, total_earned)
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


# ------------------------------------------------------------ the player
# Five people can run Corner Office (data/narrative/player_characters.json
# and data/content.json "characters"): each with a look, a start, a perk
# that does something, and their own name in everyone's mouth.

const PERKS := {"dana": "spreadsheet_brain", "hank": "road_legs", "milo": "campus_buzz", "bea": "handmade_touch", "sol": "cafe_regular"}


func player_record() -> Dictionary:
	for who in _player_characters():
		if str(who.get("id", "")).trim_prefix("pc_") == character:
			return who
	return {}


func player_name() -> String:
	var rec := player_record()
	if not rec.is_empty():
		return str(rec.get("name", "Dana Reyes"))
	for who in ItemDB.characters:
		if str(who.get("id", "")) == character:
			return str(who.get("name", "Dana Reyes"))
	return "Dana Reyes"


func first_name() -> String:
	var full := player_name()
	var bits := full.split(" ")
	return str(bits[0]) if bits.size() > 0 else full


func perk(id: String) -> bool:
	return str(PERKS.get(character, "")) == id


func perk_name() -> String:
	return str((player_record().get("perk", {}) as Dictionary).get("name", ""))


func repair_taps_for(level: int) -> int:
	# Bea's hands: one tap mends what takes others two or three.
	if perk("handmade_touch"):
		return 1
	return Tuning.repair_taps(level)


func playable_characters() -> Array:
	# Every character with a record: the slice one first.
	var out: Array = []
	for who in _player_characters():
		var id := str(who.get("id", "")).trim_prefix("pc_")
		var money_start := int(Tuning.get_value("starter_money." + id, 120))
		out.append({"id": id, "name": str(who.get("name", id)), "pitch": str(who.get("pitch", "")), "backstory": str(who.get("backstory", "")), "perk": str((who.get("perk", {}) as Dictionary).get("name", "")), "perk_desc": str((who.get("perk", {}) as Dictionary).get("desc", "")), "money": money_start, "space": str((who.get("starting_space", {}) as Dictionary).get("name", "Garage Startup"))})
	out.sort_custom(func(a, b): return (str(a["id"]) == "dana") and str(b["id"]) != "dana")
	return out


func _character_start() -> void:
	# Their own things on the desk and the floor of the garage, and Marge's welcome.
	var rec := player_record()
	if rec.is_empty():
		return
	var n := 0
	for entry in rec.get("starting_items", []):
		var id := str(entry.get("id", ""))
		if id == "" or ItemDB.get_item(id).is_empty() or not ItemDB.content_items.has(id):
			continue
		var def := ItemDB.get_item(id)
		var mount := str(def.get("mount", "floor"))
		var copy := {"uid": "start_%s" % id, "item": id, "state": "placed", "damage": 0, "rot": 0.0}
		if mount == "small":
			copy["x"] = 2.9 + float(n) * 0.12
			copy["y"] = 0.76
			copy["z"] = 4.3 + float(n) * 0.08
		elif mount == "hang":
			copy["x"] = 0.0
			copy["y"] = 1.3
			copy["z"] = 3.0 + float(n) * 0.9
			copy["wall"] = "west"
			copy["rot"] = 90.0
		else:
			copy["x"] = 1.0 + float(n) * 0.8
			copy["y"] = 0.0
			copy["z"] = 2.2
		var dup := false
		for existing in office_items:
			if str(existing.get("item", "")) == id:
				dup = true
		if not dup:
			office_items.append(copy)
		n += 1
	var mail: Dictionary = rec.get("welcome_email", {})
	if not mail.is_empty() and character != slice_character_id():
		inbox.append({"id": str(mail.get("id", "welcome_" + character)), "from": str(mail.get("from", "Marge")), "subject": str(mail.get("subject", "Welcome")), "body": str(mail.get("body", "")), "read": false})


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
	if perk("cafe_regular") and str(job.get("id", "")) == "job_catcafe":
		return not jobs_cleared.has("job_catcafe")
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
	var count := 2 + mini(jobs_done / 2, 2) + Life.board_bonus() + (1 if perk("campus_buzz") else 0)
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
	_post_payback_job()


func day_phase() -> String:
	# Morning until the first job is done, afternoon after it, evening after two.
	var done := int(day_log.get("jobs", 0))
	if done <= 0:
		return "morning"
	return "afternoon" if done == 1 else "evening"


func bump_stat(key: String, amount := 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount
	check_contracts()


# ----------------------------------------------------------- handling
# Dana's hands. Every piece she packs or unpacks counts; the level climbs
# every dozen and the helper drops fewer things. A dropped piece is chipped
# on the spot, the owner's temper rises, and past a point they come at you.

func handling_level() -> int:
	var per := maxi(1, int(Tuning.get_value("handling.per_level", 12)))
	return mini(int(Tuning.get_value("handling.max_level", 5)), int(stats.get("handled", 0)) / per)


func note_handled() -> int:
	# One more piece through Dana's hands. Returns the new level when it just went up, else -1.
	var before := handling_level()
	bump_stat("handled")
	var after := handling_level()
	return after if after > before else -1


func break_chance(item: Dictionary) -> float:
	var level := handling_level()
	var chance := maxf(float(Tuning.get_value("handling.break_floor", 0.02)), float(Tuning.get_value("handling.break_base", 0.18)) - float(Tuning.get_value("handling.break_step", 0.035)) * float(level))
	if bool(item.get("fragile", false)):
		chance *= float(Tuning.get_value("handling.fragile_mult", 2.0))
	chance *= Extras.break_mult()
	return clampf(chance, 0.0, 1.0)


func roll_break(item: Dictionary, bias := 0.0) -> bool:
	# The helper's hands slip: the piece is chipped and the job remembers. A
	# bias of 1.0 breaks for certain (tests); below 0 never breaks.
	if item.is_empty():
		return false
	var chance := break_chance(item) + bias
	if chance <= 0.0 or rng.randf() >= chance:
		return false
	if bias < 1.0 and Extras.charm_catches(job):
		emit_signal("toast_requested", "The brass duck swung. Caught it.")
		return false
	item["damage"] = maxi(int(item.get("damage", 0)), 2)
	job["broken"] = int(job.get("broken", 0)) + 1
	job["drops"] = int(job.get("drops", 0)) + 1
	bump_stat("broken")
	emit_signal("box_damaged", str(item.get("uid", "")), 2)
	return true


func temper_limit() -> int:
	# Word gets round that you let things go: every owner takes one more
	# break before they come at you, up to a cap.
	var calm := mini(int(stats.get("forgiven", 0)), int(Tuning.get_value("hospital.forgive_temper_cap", 2)))
	return int(Tuning.get_value("handling.temper", 3)) + calm


# --- The window, the fall, the ward ---
# The worst an owner can do is put you through the window. Downstairs it
# is a cracked rib and two days in St. Bridget's; from upstairs, a broken
# leg and four. In the ward you cry, you sleep, and you decide: plan to get
# even, or forgive them.

var hospital: Dictionary = {}
var grudge: Dictionary = {}

# The books: the accountant on the payroll, the all-time ledger, and the
# last seven day summaries for the Books page.
var accountant: Dictionary = {}
var ledger: Dictionary = {}
var ledger_days: Array = []

# The replay layer: gear kept for good, the clean-run streak, the Movers'
# League table, and the journal of achievements (`scripts/extras.gd`).
var gear: Array = []
var streak := 0
var league: Dictionary = {}
var achievements: Array = []


func no_helper() -> bool:
	return Extras.has_mod(job.get("def", {}), "no_helper")


func fold_ledger(summary: Dictionary) -> void:
	for key in ["jobs", "job_pay", "shop_earned", "shop_visitors", "served_by_hand", "trade_profit", "decor", "rent"]:
		ledger[key] = int(ledger.get(key, 0)) + int(summary.get(key, 0))
	var books: Dictionary = summary.get("books", {})
	ledger["wages"] = int(ledger.get("wages", 0)) + int(books.get("wage", 0))
	ledger["saved"] = int(ledger.get("saved", 0)) + int(books.get("saved", 0))
	ledger["sundries"] = int(ledger.get("sundries", 0)) + int(books.get("sundries", 0))
	var life_night: Dictionary = summary.get("life", {})
	ledger["fleet"] = int(ledger.get("fleet", 0)) + int(life_night.get("truck_pay", 0)) + int(life_night.get("shop_pay", 0)) + int(life_night.get("income", 0)) + int(life_night.get("grown", 0))
	ledger["upkeep"] = int(ledger.get("upkeep", 0)) + int(life_night.get("upkeep", 0))
	ledger["days"] = int(ledger.get("days", 0)) + 1
	var kept := summary.duplicate(true)
	kept.erase("goals")
	ledger_days.append(kept)
	while ledger_days.size() > 7:
		ledger_days.pop_front()


func throw_chance() -> float:
	return float(Tuning.get_value("hospital.throw_chance", 0.5))


func fall_terms(floor: int) -> Dictionary:
	var up := floor > 0
	return {
		"floor": floor,
		"days": int(Tuning.get_value("hospital.upper_days" if up else "hospital.ground_days", 4 if up else 2)),
		"bill": int(Tuning.get_value("hospital.upper_bill" if up else "hospital.ground_bill", 360 if up else 140)),
		"injury": "a broken leg, two cracked ribs and a week of hospital mush" if up else "a cracked rib, a black eye and a badly bruised ego",
		"window": "an upstairs window" if up else "a ground-floor window",
	}


func in_hospital() -> bool:
	return not hospital.is_empty() and int(hospital.get("days", 0)) > 0


func thrown_out(floor: int) -> Dictionary:
	# Out the window: the job ends where it stands. Half pay for what was
	# placed, the bill comes off the jar, and the next days are the ward's.
	var def: Dictionary = job.get("def", {})
	var terms := fall_terms(floor)
	job["attacked"] = true
	job["thrown"] = true
	bump_stat("thrown")
	if floor > 0:
		bump_stat("thrown_upstairs")
	var placed := 0
	var items: Array = job.get("items", [])
	for item in items:
		if str(item.get("state", "")) == "placed":
			placed += 1
	var part := int(float(JobDB.base_pay(def)) * float(placed) / float(maxi(1, items.size())) * float(Tuning.get_value("hospital.part_pay", 0.5)))
	if part > 0:
		add_money(part, true)
	var bill := int(terms["bill"])
	add_money(-bill, false)
	var client := str(def.get("client", "The client"))
	var kept_def: Dictionary = def.duplicate(true)
	kept_def.erase("items")
	hospital = {
		"days": int(terms["days"]), "total": int(terms["days"]), "bill": bill, "floor": floor, "client": client,
		"job_title": str(def.get("title", "the job")), "choice": "", "injury": str(terms["injury"]), "window": str(terms["window"]),
		"placed": placed, "total_items": items.size(), "refund": 0, "day_in": day,
		"def": kept_def, "drive": generated_drives.get(str(def.get("drive", "")), {}),
	}
	inbox.append({
		"id": "ward_d%d" % day, "from": "Marge Holloway", "subject": "I heard. Don't move.",
		"body": "%s put you through %s on %s. The nurse says %s. I've told the board you're off for %d days. The bill is $%d and no, the client isn't paying it.\n\nRest. Cry if you need to. Then decide what kind of mover you want to be.\n\n— Marge" % [client, terms["window"], def.get("title", "the job"), terms["injury"], terms["days"], bill],
		"read": false,
	})
	emit_signal("emails_changed")
	payout = {
		"thrown": true, "attacked": true, "title": "Out the window", "job_title": str(def.get("title", "the job")), "client": client,
		"base": part, "hospital_bill": bill, "floor": floor, "injury": str(terms["injury"]), "window": str(terms["window"]),
		"days": int(terms["days"]), "placed": placed, "total_items": items.size(),
		"stars": 0, "total": part - bill, "box_tip": 0, "net_tips": 0, "bonuses": 0, "split_loss": 0, "cut": 0,
	}
	job = {}
	set_mode("results")
	return payout


func choose_recovery(choice: String) -> Dictionary:
	# In the ward, the decision: forgive them, and they send flowers and half
	# the bill, and you grow a thicker skin; or hold a grudge, and the next
	# owner who raises a hand finds you ready, with a doubled claim.
	if hospital.is_empty():
		return {"error": "You are not in the ward."}
	if str(hospital.get("choice", "")) != "":
		return {"error": "You already decided."}
	if not (choice in ["forgive", "revenge"]):
		return {"error": "Forgive or revenge."}
	hospital["choice"] = choice
	var client := str(hospital.get("client", "the client"))
	if choice == "forgive":
		rep_stars += 1
		emit_signal("rep_changed", rep_rank(), rep_stars)
		bump_stat("forgiven")
		var refund := int(float(hospital.get("bill", 0)) * float(Tuning.get_value("hospital.forgive_refund", 0.5)))
		hospital["refund"] = refund
		if refund > 0:
			add_money(refund, true)
		inbox.append({
			"id": "flowers_d%d" % day, "from": client, "subject": "I am so sorry",
			"body": "There is no excuse for what I did. The carnations are from all of us. I've paid $%d toward the ward; it's not enough and I know it. If you'll still take our business, we'd be glad of it.\n\n— %s" % [refund, client],
			"read": false,
		})
	else:
		grudge = {
			"client": client, "job_title": str(hospital.get("job_title", "")), "day": day, "floor": int(hospital.get("floor", 0)),
			"bill": int(hospital.get("bill", 0)), "def": hospital.get("def", {}), "drive": hospital.get("drive", {}), "done": [],
		}
		bump_stat("grudges")
		inbox.append({
			"id": "grudge_d%d" % day, "from": "Sal", "subject": "heard you went flying",
			"body": "Word is %s put you out a window. Terrible thing. I know their new street, if that's useful. Either way: next time a client raises a hand, don't be the one who ends up on the floor.\n\n— S" % client,
			"read": false,
		})
	emit_signal("emails_changed")
	return hospital


func hospital_sleep() -> bool:
	# A night in the ward is a day gone. Back at the garage when the days run out.
	if hospital.is_empty():
		return true
	advance_day()
	hospital["days"] = int(hospital.get("days", 1)) - 1
	if int(hospital["days"]) > 0:
		return false
	var days := int(hospital.get("total", 1))
	inbox.append({
		"id": "discharged_d%d" % day, "from": "St. Bridget's", "subject": "Discharge note",
		"body": "%d night%s on Ward 3 after a fall from %s. No lifting above the shoulder for a week, and we both know you'll ignore that.\n\nMind the windows." % [days, "" if days == 1 else "s", str(hospital.get("window", "a window"))],
		"read": false,
	})
	emit_signal("emails_changed")
	hospital = {}
	set_mode("office")
	return true


func has_grudge() -> bool:
	return not grudge.is_empty()


func job_step() -> Dictionary:
	# Where a job is, in four steps: pack, load, drive, unpack.
	match mode:
		"job_pack":
			return {"n": 1, "of": 4, "name": "Pack"}
		"truck":
			return {"n": 2, "of": 4, "name": "Load"}
		"drive":
			return {"n": 3, "of": 4, "name": "Drive"}
		"job_unpack":
			return {"n": 4, "of": 4, "name": "Unpack"}
	return {}


# --- Payback ---
# What a grudge can do, from the clipboard. Each move is one shot; most of
# them settle the matter, and the payback job settles it when it is done.
# Standing your ground on site stays on for as long as the grudge is open.

func payback_moves() -> Array:
	if not has_grudge():
		return []
	var client := str(grudge.get("client", "them"))
	var done: Array = grudge.get("done", [])
	var out: Array = [
		{"id": "egg", "name": "Egg the house", "cost": 0, "blurb": "A dozen eggs, a dark street and %s's new front door. Street cred, a little heat, and a chance of being seen, which costs a rep star." % client},
		{"id": "invoice", "name": "The invoice", "cost": int(Tuning.get_value("hospital.invoice_cost", 40)), "blurb": "Hale & Pruett send %s a bill for the window and the ward ($%d). Some people pay. Some write back." % [client, int(grudge.get("bill", 0))]},
		{"id": "review", "name": "Write them up", "cost": 0, "blurb": "The whole story on the town board, with the X-ray. The town takes your side: a rep star, and %s's name is mud." % client},
		{"id": "parcel", "name": "Sal's parcel", "cost": int(Tuning.get_value("hospital.parcel_cost", 60)), "blurb": "A box arrives at %s's. It is full of glitter. It is very, very full of glitter. Sal's people talk about it for weeks." % client},
		{"id": "move_again", "name": "Move them again", "cost": 0, "blurb": "%s need moving again and nobody else will take it. Twice the pay, they stay by the door, and nothing that goes in your bag is noticed." % client},
		{"id": "forgive_late", "name": "Let it go after all", "cost": 0, "blurb": "Put the folder in a drawer. A rep star for grace, and a thicker skin for the next one."},
	]
	for move in out:
		move["done"] = done.has(str(move["id"]))
		move["open"] = not bool(move["done"]) and money >= int(move["cost"])
	return out


func do_payback(id: String) -> Dictionary:
	if not has_grudge():
		return {"error": "No grudge to settle."}
	var done: Array = grudge.get("done", [])
	if done.has(id):
		return {"error": "Done already."}
	var client := str(grudge.get("client", "them"))
	var said := ""
	var settled := true
	match id:
		"egg":
			var seen := rng.randf() < float(Tuning.get_value("hospital.egg_seen", 0.3))
			Crime.bump_heat(2 if seen else 1)
			Crime.state()["cred"] = Crime.cred() + 1
			bump_stat("egged")
			if seen:
				rep_stars = maxi(0, rep_stars - 1)
				emit_signal("rep_changed", rep_rank(), rep_stars)
				said = "Twelve eggs, a clean throw, and %s's neighbour on the step with a phone. A rep star gone, but the door looked lovely." % client
			else:
				said = "Twelve eggs on %s's new front door in the dark. Nobody saw. Sal heard, though." % client
		"invoice":
			var cost := int(Tuning.get_value("hospital.invoice_cost", 40))
			if money < cost:
				return {"error": "The solicitor wants $%d up front." % cost}
			add_money(-cost, false)
			var bill := int(grudge.get("bill", 0))
			if rng.randf() < float(Tuning.get_value("hospital.invoice_pays", 0.55)):
				add_money(bill, true)
				bump_stat("invoice_paid")
				said = "A cheque for $%d by return of post, and not one word with it. The ward is paid for." % bill
				inbox.append({"id": "invoice_d%d" % day, "from": "Hale & Pruett, solicitors", "subject": "Re: %s, settled" % client, "body": "Our letter of the 3rd was answered with a cheque for $%d and no comment. We suggest you let that be the end of it.\n\nOur fee has been deducted." % bill, "read": false})
			else:
				said = "%s's reply ran to three pages and the word 'provoked' four times. No cheque. The $%d is gone." % [client, cost]
				inbox.append({"id": "invoice_d%d" % day, "from": "Hale & Pruett, solicitors", "subject": "Re: %s, declined" % client, "body": "Our letter was answered at length. The gist is that you were, in their words, provoked, and that they will see us in court. We do not advise that.\n\nOur fee is enclosed." % [], "read": false})
			emit_signal("emails_changed")
		"review":
			rep_stars += 1
			emit_signal("rep_changed", rep_rank(), rep_stars)
			bump_stat("reviewed")
			said = "The whole story on the town board, X-ray and all. Three hundred likes by lunch. %s's name is mud and you got a rep star for telling it straight." % client
		"parcel":
			var cost := int(Tuning.get_value("hospital.parcel_cost", 60))
			if money < cost:
				return {"error": "Sal wants $%d for the parcel." % cost}
			add_money(-cost, false)
			Crime.bump_heat(1)
			Crime.state()["cred"] = Crime.cred() + 2
			bump_stat("glittered")
			said = "The parcel went Tuesday. Sal says %s opened it in the lounge. He says there is glitter in the grout. He says it will be there when they sell." % client
			inbox.append({"id": "parcel_d%d" % day, "from": "Sal", "subject": "re: the parcel", "body": "Delivered. Opened in the front room, I'm told, with the windows shut. You can't hoover glitter, it just moves house. Two cred for style.\n\n— S", "read": false})
			emit_signal("emails_changed")
		"move_again":
			var def: Dictionary = (grudge.get("def", {}) as Dictionary).duplicate(true)
			if def.is_empty():
				return {"error": "No address for them."}
			def["id"] = "payback_%d" % day
			def["generated"] = true
			def["payback"] = true
			def["unlock"] = "tutorial_done"
			def["title"] = "Payback: %s again" % client
			def["narrative_base"] = int(float(JobDB.base_pay(def)) * float(Tuning.get_value("hospital.move_again_mult", 2)))
			def.erase("base_key")
			def["brief"] = "%s need moving again and every other firm said no. Twice the money. They'll stay by the door and keep their hands to themselves, and they won't be watching your bag." % client
			def["mentor_note"] = "Marge: 'Take the money. Be the bigger person, or don't. Your call.'"
			grudge["posted_job"] = def
			if not (grudge.get("drive", {}) as Dictionary).is_empty():
				generated_drives[str(def.get("drive", ""))] = grudge["drive"]
			_post_payback_job()
			settled = false
			said = "On the board: %s, again, at twice the money. Nobody else would take it." % client
		"forgive_late":
			rep_stars += 1
			emit_signal("rep_changed", rep_rank(), rep_stars)
			bump_stat("forgiven")
			said = "The folder goes in the drawer. It was a window. You've had worse Tuesdays."
		_:
			return {"error": "No such move."}
	done.append(id)
	grudge["done"] = done
	if settled:
		grudge = {}
	return {"said": said, "settled": settled}


func _post_payback_job() -> void:
	# The payback job stays on the board through the daily refresh until it is done.
	var def: Dictionary = grudge.get("posted_job", {})
	if def.is_empty() or jobs_cleared.has(str(def.get("id", ""))):
		return
	for row in generated_jobs:
		if str(row.get("id", "")) == str(def.get("id", "")):
			return
	generated_jobs.push_front(def.duplicate(true))
	if not (grudge.get("drive", {}) as Dictionary).is_empty():
		generated_drives[str(def.get("drive", ""))] = grudge["drive"]


func settle_grudge() -> Dictionary:
	# The owner came at you again and this time you were ready: they go
	# down, the grudge is spent, and the claim that follows is doubled.
	var old := grudge.duplicate(true)
	grudge = {}
	job["attacked"] = true
	job["payback"] = true
	bump_stat("payback")
	return old


func sue_owner() -> Dictionary:
	# Dana goes to the small claims court over the shove. The first one pays;
	# each one after that is likelier to come back as a fraud claim ten times
	# over, with two stars off the rep and a solicitor's letter.
	if not bool(job.get("attacked", false)):
		return {"error": "Nobody has laid a hand on you."}
	if bool(job.get("sued", false)):
		return {"error": "Already filed."}
	var suits := int(stats.get("lawsuits", 0))
	var amount := rng.randi_range(int(Tuning.get_value("handling.sue_min", 1000)), int(Tuning.get_value("handling.sue_max", 2000)))
	if bool(job.get("payback", false)):
		amount *= int(Tuning.get_value("hospital.payback_mult", 2))
	var chance := minf(float(Tuning.get_value("handling.counter_cap", 0.85)), float(Tuning.get_value("handling.counter_step", 0.25)) * float(suits))
	var countered := suits > 0 and rng.randf() < chance
	job["sued"] = true
	bump_stat("lawsuits")
	var out := {"amount": amount, "countered": countered, "penalty": 0}
	if countered:
		var penalty := amount * int(Tuning.get_value("handling.counter_mult", 12))
		out["penalty"] = penalty
		job["counter_sued"] = penalty
		add_money(-penalty, false)
		var stars_off := int(Tuning.get_value("handling.counter_rep", 2))
		rep_stars = maxi(0, rep_stars - stars_off)
		emit_signal("rep_changed", rep_rank(), rep_stars)
		bump_stat("counter_sued")
		var client := str(job.get("def", {}).get("client", "the client"))
		inbox.append({"id": "counter_%d" % int(stats.get("lawsuits", 0)), "from": "Hale & Pruett, solicitors", "subject": "Re: %s v. Corner Office" % client, "body": "Our client has read the file. %d claims from one mover, every one after a dropped box, and witnesses who say the shoving started with you. The court found fraud and vexatious conduct. Judgment: $%d, plus costs. We suggest you find a gentler line of work." % [suits + 1, penalty], "read": false})
	else:
		job["sue_won"] = amount
		add_money(amount, true)
		bump_stat("sue_won")
	return out
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
		"floor": 0,
		"owner_items": [],
		"pocketed": [],
		"caught_pocketing": false,
	}
	Extras.on_job_start(job)
	var place: Dictionary = ItemDB.venues().get(str(def.get("venue", "")), {})
	if Homes.is_home(place):
		job["owner_items"] = Homes.owner_layout(place, hash("%s:%d" % [id, seed]))
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


# ------------------------------------------------------------- the bed
# The truck bed is a grid of places: columns across, rows from the front
# wall to the door, layers to the ceiling. Slot index = layer * (rows *
# cols) + row * cols + col. It fills from the front corner outward and up,
# and empties from the door and the top down. Every piece has a weight; a
# box carries the sum; on the drive a box with too much on top is crushed.

func truck_slots() -> int:
	return int(Tuning.get_value("truck.slots", 8))


func truck_cols() -> int:
	return int(Tuning.get_value("truck.cols", 2))


func truck_rows() -> int:
	return int(Tuning.get_value("truck.rows", 2))


func truck_layers() -> int:
	return int(Tuning.get_value("truck.layers", 2))


func floor_slots() -> int:
	return int(Tuning.get_value("truck.floor_slots", 4))


func per_box() -> int:
	return int(Tuning.get_value("pack.per_box", 5)) + Extras.per_box_extra()


func slot_cell(slot: int) -> Dictionary:
	var per_layer := truck_rows() * truck_cols()
	var layer := int(slot / per_layer)
	var rest := slot - layer * per_layer
	return {"layer": layer, "row": int(rest / truck_cols()), "col": rest % truck_cols()}


func slot_at(layer: int, row: int, col: int) -> int:
	if layer < 0 or row < 0 or col < 0 or layer >= truck_layers() or row >= truck_rows() or col >= truck_cols():
		return -1
	return layer * truck_rows() * truck_cols() + row * truck_cols() + col


func box_in_slot(slot: int) -> Dictionary:
	# No place is no box: a box waiting to be loaded, or already carried
	# in, has slot -1, and so does the cell above the top layer.
	if slot < 0:
		return {}
	for box in job.get("boxes", []):
		if int(box.get("slot", -1)) == slot:
			return box
	return {}


func slot_open(slot: int) -> String:
	# Why a box cannot go here, or "" when it can: the place is taken, there
	# is nothing under it, the row in front is not filled yet, or a wrapped
	# piece sits below (nothing stacks on a sofa).
	if slot < 0 or slot >= truck_slots():
		return "No such place."
	if slot_taken(slot):
		return "Something's already sitting there."
	var cell := slot_cell(slot)
	if int(cell["layer"]) > 0:
		var below := box_in_slot(slot_at(int(cell["layer"]) - 1, int(cell["row"]), int(cell["col"])))
		if below.is_empty():
			return "Nothing to stand that on yet. Fill the floor first."
		if str(below.get("big", "")) != "":
			return "Nothing goes on top of a wrapped piece."
	if int(cell["row"]) > 0:
		var ahead_slot := slot_at(int(cell["layer"]), int(cell["row"]) - 1, int(cell["col"]))
		var ahead := box_in_slot(ahead_slot)
		if ahead.is_empty() and not _slot_dead(ahead_slot):
			return "Front first: fill from the wall by the cab."
	return ""


func _slot_dead(slot: int) -> bool:
	# A place nothing can ever take: above a wrapped piece (nothing stacks
	# on a sofa), on any layer. The row behind it need not wait for it.
	var cell := slot_cell(slot)
	for layer in range(int(cell["layer"]) - 1, -1, -1):
		var under := box_in_slot(slot_at(layer, int(cell["row"]), int(cell["col"])))
		if not under.is_empty() and str(under.get("big", "")) != "":
			return true
	return false


func slot_can_unload(slot: int) -> String:
	# Why a box cannot come off yet: something on top, or a box in the way
	# toward the door.
	var cell := slot_cell(slot)
	var above := box_in_slot(slot_at(int(cell["layer"]) + 1, int(cell["row"]), int(cell["col"])))
	if not above.is_empty():
		return "The box on top of it first."
	var toward_door := box_in_slot(slot_at(int(cell["layer"]), int(cell["row"]) + 1, int(cell["col"])))
	if not toward_door.is_empty():
		return "The one nearer the door first."
	return ""


func open_slots() -> Array:
	var out: Array = []
	for i in truck_slots():
		if slot_open(i) == "":
			out.append(i)
	return out


func box_weight(box_id: int) -> float:
	var total := 0.0
	for item in job.get("items", []):
		if int(item.get("box", -1)) == box_id:
			total += float(item.get("weight", 1.0))
	return snappedf(total, 0.1)


func load_above(box_id: int) -> float:
	# The kilos stacked on this box: every box in the layers above its place.
	var box := job_box(box_id)
	var slot := int(box.get("slot", -1))
	if slot < 0:
		return 0.0
	var cell := slot_cell(slot)
	var total := 0.0
	for layer in range(int(cell["layer"]) + 1, truck_layers()):
		var other := box_in_slot(slot_at(layer, int(cell["row"]), int(cell["col"])))
		if other.is_empty():
			break
		total += box_weight(int(other.get("id", -1)))
	return snappedf(total, 0.1)


func load_box_into(box_id: int, slot: int, _floor_slots: int = -1) -> String:
	var box := job_box(box_id)
	if box.is_empty() or not bool(box.get("sealed", false)):
		return "Seal it first."
	var why := slot_open(slot)
	if why != "":
		return why
	if str(box.get("big", "")) != "" and slot >= floor_slots():
		return "That one rides on the floor."
	if box_has_heavy(box_id) and slot >= floor_slots() and floor_slot_free():
		# A heavy box takes the floor while there is floor to take; once it is
		# full it rides up top and crushes whatever is under it.
		return "The heavy box is happier on the bottom."
	box["slot"] = slot
	return ""


func floor_slot_free() -> bool:
	for i in floor_slots():
		if slot_open(i) == "":
			return true
	return false


func crush_warning(box_id: int) -> String:
	# A word when a box has just been put on something it will flatten.
	var box := job_box(box_id)
	var slot := int(box.get("slot", -1))
	var cell := slot_cell(slot)
	if slot < 0 or int(cell["layer"]) == 0:
		return ""
	var below := box_in_slot(slot_at(int(cell["layer"]) - 1, int(cell["row"]), int(cell["col"])))
	if below.is_empty():
		return ""
	var on_it := load_above(int(below.get("id", -1)))
	if on_it <= float(Tuning.get_value("weight.crush_threshold_kg", 18)):
		return ""
	var fragile := box_needs_padding(int(below.get("id", -1)))
	return "%d kg on top of box %d%s. That will tell on the road." % [int(round(on_it)), int(below.get("id", 0)) + 1, ", and that one has glass in it" if fragile else ""]


func auto_load_order() -> Array:
	# Wrapped pieces and heavy boxes first on the floor, then the heaviest
	# boxes, lightest last on top: each to the first open place that takes it.
	var waiting: Array = []
	for box in job.get("boxes", []):
		if bool(box.get("sealed", false)) and int(box.get("slot", -1)) < 0:
			waiting.append(box)
	waiting.sort_custom(func(a, b):
		var fa := 2 if str(a.get("big", "")) != "" else (1 if box_has_heavy(int(a.get("id", -1))) else 0)
		var fb := 2 if str(b.get("big", "")) != "" else (1 if box_has_heavy(int(b.get("id", -1))) else 0)
		if fa != fb:
			return fa > fb
		return box_weight(int(a.get("id", -1))) > box_weight(int(b.get("id", -1)))
	)
	var out: Array = []
	for box in waiting:
		out.append(int(box.get("id", -1)))
	return out


func unload_order() -> Array:
	# Boxes still on the truck, the ones that can come off first.
	var loaded: Array = []
	for box in job.get("boxes", []):
		if int(box.get("slot", -1)) >= 0:
			loaded.append(box)
	loaded.sort_custom(func(a, b): return int(a.get("slot", -1)) > int(b.get("slot", -1)))
	var out: Array = []
	for box in loaded:
		out.append(int(box.get("id", -1)))
	return out


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
		if box_has_heavy(int(box.get("id", -1))) and int(box.get("slot", -1)) >= floor_slots():
			return false
	return true


func apply_drive_result(result: Dictionary) -> void:
	job["condition"] = clampi(int(result.get("condition", 100)), 0, 100)
	job["drive_time"] = float(result.get("time", 0.0))
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
	# Crushed pieces take their own hurt from the weight on them, smooth
	# drive or not: scuffed past the first band, chipped past the third.
	for entry in order:
		var item3 := job_item(str(entry["uid"]))
		if not bool(item3.get("crushed", false)):
			continue
		var level := _severity(float(entry["stress"]))
		if level > int(item3.get("damage", 0)):
			item3["damage"] = level
			emit_signal("box_damaged", item3["uid"], level)


func _item_stress(item: Dictionary, base_stress: float) -> float:
	var stress := base_stress
	var box := job_box(int(item.get("box", -1)))
	if bool(item.get("fragile", false)) and not box.is_empty() and bool(box.get("padded", false)):
		stress *= float(Tuning.get_value("box_condition.padding_multiplier", 0.5))
	if bool(item.get("heavy", false)) and _box_on_bottom(box):
		stress *= float(Tuning.get_value("box_condition.heavy_bottom_multiplier", 0.75))
	if bool(item.get("nobox", false)) and Extras.gear_has("blankets"):
		stress *= Extras.wrap_mult()
	# Crushed: the kilos on top of the box past what cardboard takes.
	var over := load_above(int(box.get("id", -1))) * Extras.load_mult() - Extras.crush_threshold()
	if over > 0.0:
		var per_kg := float(Tuning.get_value("weight.crush_per_kg", 0.04))
		if bool(item.get("fragile", false)):
			per_kg *= float(Tuning.get_value("weight.fragile_crush_mult", 1.5))
		stress = maxf(stress, 8.0) * (1.0 + over * per_kg)
		item["crushed"] = true
	return stress


func _box_on_bottom(box: Dictionary) -> bool:
	if box.is_empty():
		return false
	var slot := int(box.get("slot", -1))
	return slot >= 0 and slot < floor_slots()


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
	if int(item["taps"]) >= repair_taps_for(level):
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
	var room_pay := int(job.get("rooms_right", 0)) * int(Tuning.get_value("pay.room_match", 3))
	bonuses += room_pay
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
	payout["rooms_right"] = int(job.get("rooms_right", 0))
	payout["rooms_total"] = int(job.get("rooms_total", 0))
	payout["rooms_wrong"] = job.get("rooms_wrong", [])
	payout["room_pay"] = room_pay
	var pocketed: Array = job.get("pocketed", [])
	payout["pocketed"] = pocketed.size()
	var loot_value := 0
	for entry in pocketed:
		loot_value += int(entry.get("value", 0))
	payout["loot_value"] = loot_value
	payout["caught_pocketing"] = bool(job.get("caught_pocketing", false))
	payout["broken"] = int(job.get("broken", 0))
	var crushed := 0
	for item in job.get("items", []):
		if bool(item.get("crushed", false)) and int(item.get("damage", 0)) > 0:
			crushed += 1
	payout["crushed"] = crushed
	payout["attacked"] = bool(job.get("attacked", false))
	payout["sue_won"] = int(job.get("sue_won", 0))
	payout["counter_sued"] = int(job.get("counter_sued", 0))
	if bool(job.get("caught_pocketing", false)):
		var cut := int(round(float(int(payout.get("base", 0))) * float(Tuning.get_value("pay.caught_cut", 0.25))))
		payout["caught_cut"] = cut
		payout["base"] = int(payout.get("base", 0)) - cut
		payout["total"] = int(payout.get("total", 0)) - cut
	payout["job_id"] = job.get("id", "")
	payout["title"] = def.get("title", "Job")
	var stars := 1
	if int(job.get("condition", 0)) >= 70:
		stars += 1
	if all_fine:
		stars += 1
	if bool(job.get("caught_pocketing", false)):
		stars = maxi(1, stars - 1)
		rep_stars = maxi(0, rep_stars - 1)
	stars = mini(3, stars)
	payout["stars"] = stars
	var extras := Extras.settle(job, payout)
	payout["total"] = int(payout.get("total", 0)) + extras
	var net_pay := int(payout.get("base", 0)) + int(payout.get("net_tips", 0)) + int(payout.get("shortcut", 0)) + extras
	# Dana's own life pays back: Pickle at the door, Sam's lunches, a rested first job.
	var life_mult := Life.tip_mult() - 1.0
	if int(day_log.get("jobs", 0)) == 0:
		life_mult += Life.first_job_mult() - 1.0
	var life_extra := int(round(float(int(payout.get("net_tips", 0))) * life_mult))
	payout["life_extra"] = life_extra
	payout["total"] = int(payout.get("total", 0)) + life_extra
	net_pay += life_extra
	add_money(net_pay, true)
	rep_stars += stars
	jobs_done += 1
	jobs_cleared[str(job.get("id", ""))] = true
	if bool(def.get("payback", false)):
		bump_stat("payback_jobs")
		payout["payback_job"] = true
		grudge = {}
	if int(job.get("condition", 0)) >= 90:
		stats["smooth_rides"] = int(stats.get("smooth_rides", 0)) + 1
	if bool(job.get("cat_opened", false)):
		stats["cats_found"] = int(stats.get("cats_found", 0)) + 1
	if bool(job.get("alley", false)):
		stats["alley_runs"] = int(stats.get("alley_runs", 0)) + 1
	if bool(def.get("generated", false)) and not bool(def.get("shady", false)):
		stats["board_jobs"] = int(stats.get("board_jobs", 0)) + 1
	Extras.check_achievements()
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


func pocket_owner_item(uid: String) -> Dictionary:
	# Something of the client's goes in the bag: loot for Sal, heat for you,
	# and a growing chance someone notices, which costs pay and a rep star.
	for rec in job.get("owner_items", []):
		if str(rec.get("uid", "")) != uid or str(rec.get("state", "placed")) != "placed":
			continue
		if not bool(rec.get("pocketable", true)):
			return {"error": "Too big to walk out with."}
		rec["state"] = "pocketed"
		var pocketed: Array = job.get("pocketed", [])
		var entry := {"item_id": str(rec.get("item_id", "")), "name": str(rec.get("name", "")), "value": int(rec.get("value", 10))}
		pocketed.append(entry)
		job["pocketed"] = pocketed
		var heat := int(Tuning.get_value("crime.pocket_heat", 1))
		Crime.add_loot(entry)
		Crime.bump_heat(heat)
		var chance := float(Tuning.get_value("crime.pocket_notice", 0.2)) + float(Tuning.get_value("crime.pocket_notice_step", 0.15)) * float(pocketed.size() - 1)
		if Extras.has_mod(job.get("def", {}), "nosy"):
			chance += float(Tuning.get_value("play.nosy_notice", 0.4))
		var noticed := rng.randf() < clampf(chance, 0.0, 0.95)
		if bool(job.get("def", {}).get("payback", false)):
			noticed = false
		if noticed:
			job["caught_pocketing"] = true
		bump_stat("pocketed")
		return {"noticed": noticed, "heat": heat, "value": int(entry["value"])}
	return {"error": "That is not here any more."}


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
	summary["life"] = Life.nightly(earned)
	summary["books"] = Books.nightly(summary)
	summary["tip"] = Books.tip_for(day)
	Extras.league_nightly(summary)
	fold_ledger(summary)
	Extras.check_achievements()
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
	bump_stat("rent_paid")
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
	score += Life.vibe_bonus()
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
		"life": life.duplicate(true),
		"rent_owed": rent_owed,
		"freebie_day": freebie_day,
		"forest_serial": forest_serial,
		"latched_goals": latched_goals.duplicate(true),
		"hospital": hospital.duplicate(true),
		"grudge": grudge.duplicate(true),
		"accountant": accountant.duplicate(true),
		"ledger": ledger.duplicate(true),
		"ledger_days": ledger_days.duplicate(true),
		"gear": gear.duplicate(),
		"streak": streak,
		"league": league.duplicate(true),
		"achievements": achievements.duplicate(),
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
	life = raw.get("life", {}).duplicate(true) if raw.has("life") else Life.fresh()
	if life.is_empty():
		life = Life.fresh()
	if generated_jobs.is_empty():
		refresh_board()
	freebie_day = int(raw.get("freebie_day", -1))
	forest_serial = int(raw.get("forest_serial", 0))
	latched_goals = raw.get("latched_goals", {})
	goal_marked = {}
	hospital = raw.get("hospital", {}).duplicate(true) if raw.has("hospital") else {}
	grudge = raw.get("grudge", {}).duplicate(true) if raw.has("grudge") else {}
	accountant = raw.get("accountant", {}).duplicate(true) if raw.has("accountant") else {}
	ledger = raw.get("ledger", {}).duplicate(true) if raw.has("ledger") else {}
	ledger_days = raw.get("ledger_days", []).duplicate(true) if raw.has("ledger_days") else []
	gear = raw.get("gear", []).duplicate() if raw.has("gear") else []
	streak = int(raw.get("streak", 0))
	league = raw.get("league", {}).duplicate(true) if raw.has("league") else Extras.league_fresh()
	if league.is_empty():
		league = Extras.league_fresh()
	achievements = raw.get("achievements", []).duplicate() if raw.has("achievements") else []
	emit_signal("money_changed", money)
	emit_signal("emails_changed")
