class_name Regions
extends RefCounted
# The real cities for the long hauls: home is Columbia, South Carolina,
# and every other city is a road distance from the garage, a tier the
# reputation has to reach, and a region that picks the scenery on the
# highway leg. Data in data/cities.json.

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var file := FileAccess.open("res://data/cities.json", FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				_data = parsed
		if _data.is_empty():
			_data = {"home": {"name": "Columbia", "state": "SC"}, "cities": [], "tiers": [], "regions": {}}
	return _data


static func home() -> Dictionary:
	return data().get("home", {})


static func cities() -> Array:
	return data().get("cities", [])


static func city(id: String) -> Dictionary:
	for entry in cities():
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func tier_for(miles: int) -> Dictionary:
	for tier in data().get("tiers", []):
		if miles <= int(tier.get("max_miles", 0)):
			return tier
	return {"max_miles": 9999, "rep": 3, "name": "Cross-country"}


static func rep_needed(entry: Dictionary) -> int:
	return int(tier_for(int(entry.get("miles", 0))).get("rep", 0))


static func open_to(rep: int) -> Array:
	# The cities a reputation can take a haul to, nearest first.
	var out: Array = []
	for entry in cities():
		if rep >= rep_needed(entry):
			out.append(entry)
	out.sort_custom(func(a, b): return int(a.get("miles", 0)) < int(b.get("miles", 0)))
	return out


static func haul_pay(miles: int) -> int:
	return int(round(float(miles) * float(data().get("pay_per_mile", 2.2))))


static func highway_metres(miles: int) -> int:
	# The highway leg's length in the world: long enough to feel like a
	# haul, short enough that Nashville is not a real afternoon.
	return clampi(260 + miles * 4, 300, 1700)


static func region(id: String) -> Dictionary:
	var regions: Dictionary = data().get("regions", {})
	return regions.get(id, regions.get("midlands", {}))


static func billboards() -> Array:
	return data().get("billboards", [])


static func label(entry: Dictionary) -> String:
	return "%s, %s" % [entry.get("name", "?"), entry.get("state", "")]


static func outline_sc() -> Array:
	return data().get("outline_sc", [])
