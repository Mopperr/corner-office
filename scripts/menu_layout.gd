extends RefCounted

# The menu showroom reads this when it is present. The file is the Bakery Loft.
const PATHS: Array[String] = [
	"/workspace/game/menu_room_loft.json",
	"res://game/menu_room_loft.json",
]


static func load_layout() -> Dictionary:
	for path in PATHS:
		if not FileAccess.file_exists(path):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_ARRAY:
			return {"items": parsed, "path": path, "venue": "bakery"}
		if typeof(parsed) == TYPE_DICTIONARY:
			parsed["path"] = path
			if str(parsed.get("venue", "")) == "":
				parsed["venue"] = "bakery"
			return parsed
	return {}


static func records(layout: Dictionary) -> Array:
	var raw = _record_list(layout)
	var out: Array = []
	var index := 0
	for entry in raw:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item := str(entry.get("item", entry.get("item_id", "")))
		var model_name := str(entry.get("model", ""))
		if item == "" and model_name == "":
			item = str(entry.get("id", ""))
		var x := float(entry.get("x", 0.0))
		var y := float(entry.get("y", 0.0))
		var z := float(entry.get("z", 0.0))
		var pos = entry.get("position", entry.get("pos", null))
		if typeof(pos) == TYPE_ARRAY and pos.size() >= 3:
			x = float(pos[0])
			y = float(pos[1])
			z = float(pos[2])
		elif typeof(pos) == TYPE_DICTIONARY:
			x = float(pos.get("x", x))
			y = float(pos.get("y", y))
			z = float(pos.get("z", z))
		index += 1
		out.append({
			"uid": str(entry.get("uid", "loft_%d" % index)),
			"item": item,
			"model": model_name,
			"x": x,
			"y": y,
			"z": z,
			"rot": float(entry.get("rot", entry.get("rotation_y", entry.get("rotation", 0.0)))),
			"wall": str(entry.get("wall", "")),
			"state": "placed",
		})
	return out


static func look_target(layout: Dictionary) -> Variant:
	var look = layout.get("look", null)
	var camera = layout.get("camera", null)
	if typeof(camera) == TYPE_DICTIONARY:
		if camera.has("look"):
			look = camera["look"]
		elif camera.has("target"):
			look = camera["target"]
	elif typeof(camera) == TYPE_ARRAY:
		look = camera
	if typeof(look) == TYPE_ARRAY and look.size() >= 3:
		return Vector3(float(look[0]), float(look[1]), float(look[2]))
	if typeof(look) == TYPE_DICTIONARY:
		return Vector3(float(look.get("x", 0.0)), float(look.get("y", 0.9)), float(look.get("z", 0.0)))
	return null


static func _record_list(layout: Dictionary) -> Array:
	for key in ["items", "props", "placements", "furniture", "nodes"]:
		var raw = layout.get(key, null)
		if typeof(raw) == TYPE_ARRAY:
			return raw
	var room = layout.get("room", null)
	if typeof(room) == TYPE_DICTIONARY:
		for key in ["items", "props", "placements", "furniture"]:
			var nested = room.get(key, null)
			if typeof(nested) == TYPE_ARRAY:
				return nested
	return []
