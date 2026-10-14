class_name Tuning
extends RefCounted

static var data: Dictionary = {}

static func load_data() -> Dictionary:
	if not data.is_empty():
		return data
	var file := FileAccess.open("res://data/tuning.json", FileAccess.READ)
	if file == null:
		push_error("Missing res://data/tuning.json")
		return data
	data = JSON.parse_string(file.get_as_text())
	return data


static func get_value(path: String, fallback = null):
	load_data()
	var node = data
	for part in path.split("."):
		if typeof(node) != TYPE_DICTIONARY or not node.has(part):
			return fallback
		node = node[part]
	return node


static func snap_grid() -> float:
	return float(get_value("snap.grid_m", 0.25))


static func rotate_step(fine: bool) -> float:
	if fine:
		return float(get_value("snap.fine_rotate_deg", 15))
	return float(get_value("snap.rotate_deg", 90))


static func tip_ratio(condition: int) -> float:
	var tiers: Array = get_value("box_condition.tip_tiers", [])
	var best := 0.05
	var best_min := -1
	for tier in tiers:
		var min_v := int(tier.get("min", 0))
		if condition >= min_v and min_v >= best_min:
			best_min = min_v
			best = float(tier.get("bonus", best))
	return best


static func tip_stamp(condition: int) -> String:
	var tiers: Array = get_value("box_condition.tip_tiers", [])
	var stamp := ""
	var best_min := -1
	for tier in tiers:
		var min_v := int(tier.get("min", 0))
		if condition >= min_v and min_v >= best_min:
			best_min = min_v
			stamp = str(tier.get("stamp", ""))
	return stamp


static func damage_cut(base: int, scuffed: int, chipped: int, tips_available: int) -> int:
	var scuff_pct := float(get_value("damage.scuffed_pct_of_base", 0.05))
	var chip_pct := float(get_value("damage.chipped_pct_of_base", 0.10))
	var cap_pct := float(get_value("damage.cap_pct_of_base", 0.20))
	var raw := int(round(float(base) * (scuff_pct * float(scuffed) + chip_pct * float(chipped))))
	var cap := int(round(float(base) * cap_pct))
	var cut := mini(raw, cap)
	return mini(cut, maxi(0, tips_available))


static func repair_taps(level: int) -> int:
	var table: Dictionary = get_value("damage.repair_taps", {"1": 1, "2": 3})
	return int(table.get(str(level), 1))


static func rep_rank(stars: int) -> int:
	var gates: Array = get_value("rep_star_gates", [0, 2, 6, 12, 20, 30])
	var rank := 0
	for i in gates.size():
		if stars >= int(gates[i]):
			rank = i
	return rank


static func office_def(id: String) -> Dictionary:
	for office in get_value("offices", []):
		if str(office.get("id", "")) == id:
			return office
	return {}


static func audio_gain(sfx_name: String) -> float:
	var quiet: Array = get_value("audio.quiet_sfx", [])
	if sfx_name in quiet:
		return float(get_value("audio.quiet_boost_db", 6))
	if sfx_name == "sfx_truck_idle_loop":
		return float(get_value("audio.truck_idle_db", -10))
	var boosted: Array = get_value("audio.ambience_boost", [])
	if sfx_name in boosted:
		return float(get_value("audio.ambience_boost_db", 8))
	return 0.0
