extends RefCounted

# v2 routes are already in play pixels. full_scale keeps that scale at 1.0,
# so an alley that saves at about 9–11 s stays that long.
const LOADER_SCALE := 1.0

static func course_for(id: String, fallback: Dictionary) -> Dictionary:
	var raw := _find(id)
	if raw.is_empty():
		return fallback
	var adopted := adopt(raw)
	if adopted.is_empty():
		return fallback
	if str(adopted.get("id", "")) == "":
		adopted["id"] = id
	return adopted


static func has_v2(id: String) -> bool:
	return not adopt(_find(id)).is_empty()


static func adopt(data: Dictionary) -> Dictionary:
	if data.is_empty() or not _is_v2(data) or not bool(data.get("full_scale", false)):
		return {}
	var copy: Dictionary = data.duplicate(true)
	_scale_course(copy, LOADER_SCALE)
	return copy


static func alley_seconds(course: Dictionary, px_per_m: float, speed_mps: float) -> float:
	var alley = course.get("alley")
	if typeof(alley) != TYPE_DICTIONARY:
		return -1.0
	var a: Array = alley.get("a", [0, 0])
	var b: Array = alley.get("b", [0, 0])
	var pixels := Vector2(float(a[0]), float(a[1])).distance_to(Vector2(float(b[0]), float(b[1])))
	return (pixels / maxf(px_per_m, 0.001)) / maxf(speed_mps, 0.001)


static func _is_v2(data: Dictionary) -> bool:
	var version := str(data.get("version", ""))
	return version == "v2" or version == "2"


static func _find(id: String) -> Dictionary:
	var files: Array[String] = [
		"/workspace/game/drive_routes/v2/%s.json" % id,
		"/workspace/game/drive_routes/%s.json" % id,
		"res://game/drive_routes/v2/%s.json" % id,
		"res://game/drive_routes/%s.json" % id,
	]
	for path in files:
		var parsed = _read(path)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		if str(parsed.get("id", id)) != id and not parsed.has("roads"):
			continue
		return parsed
	var packs: Array[String] = [
		"/workspace/game/drive_routes/v2/routes.json",
		"/workspace/game/drive_routes/routes.json",
		"res://game/drive_routes/v2/routes.json",
		"res://game/drive_routes/routes.json",
	]
	for path in packs:
		var pack = _read(path)
		if typeof(pack) != TYPE_DICTIONARY:
			continue
		var routes = pack.get("routes", {})
		if typeof(routes) != TYPE_DICTIONARY or not routes.has(id):
			continue
		var one = routes[id]
		if typeof(one) != TYPE_DICTIONARY:
			continue
		if not one.has("version"):
			one["version"] = pack.get("version", "")
		if not one.has("full_scale"):
			one["full_scale"] = pack.get("full_scale", false)
		return one
	return {}


static func _read(path: String):
	if path.begins_with("res://"):
		if not FileAccess.file_exists(path):
			return null
	elif not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


static func _scale_course(course: Dictionary, scale: float) -> void:
	if is_equal_approx(scale, 1.0):
		return
	_scale_list(course, "start", scale)
	for rect in course.get("roads", []):
		if typeof(rect) == TYPE_ARRAY:
			_scale_list_in_place(rect, scale)
	var finish = course.get("finish")
	if typeof(finish) == TYPE_ARRAY:
		_scale_list_in_place(finish, scale)
	var alley = course.get("alley")
	if typeof(alley) == TYPE_DICTIONARY:
		for key in ["a", "b"]:
			var point = alley.get(key)
			if typeof(point) == TYPE_ARRAY:
				_scale_list_in_place(point, scale)
		if alley.has("width"):
			alley["width"] = float(alley["width"]) * scale
	for hazard in course.get("hazards", []):
		if typeof(hazard) != TYPE_DICTIONARY:
			continue
		for key in ["x", "y", "w", "h", "r"]:
			if hazard.has(key):
				hazard[key] = float(hazard[key]) * scale


static func _scale_list(course: Dictionary, key: String, scale: float) -> void:
	var value = course.get(key)
	if typeof(value) == TYPE_ARRAY:
		_scale_list_in_place(value, scale)


static func _scale_list_in_place(values: Array, scale: float) -> void:
	for i in values.size():
		values[i] = float(values[i]) * scale
