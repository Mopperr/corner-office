class_name Narrative
extends RefCounted
# Why Dana does each thing: data/narrative/why.json, in her words and
# Marge's. The clipboard, the results card and the how-to-play page read it.

static var _why: Dictionary = {}


static func why() -> Dictionary:
	if _why.is_empty():
		var file := FileAccess.open("res://data/narrative/why.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				_why = parsed
	return _why


static func why_loop(id: String) -> Dictionary:
	for loop in why().get("loops", []):
		if str(loop.get("id", "")) == id:
			return loop
	return {}


static func why_loops() -> Array:
	return why().get("loops", [])


static func why_result(key: String) -> String:
	return str(why().get("results", {}).get(key, ""))


static func premise() -> String:
	return str(why().get("premise", ""))
