extends Node

const Tuning = preload("res://scripts/tuning.gd")

var briefs: Dictionary = {}
var jobs: Array = []
var drives: Dictionary = {}


func _ready() -> void:
	var raw_briefs = _read("res://data/narrative/job_briefs.json")
	if typeof(raw_briefs) == TYPE_ARRAY:
		for brief in raw_briefs:
			briefs[str(brief.get("id", ""))] = brief
	var content = _read("res://data/content.json")
	if typeof(content) == TYPE_DICTIONARY:
		jobs = content.get("jobs", [])
	drives = _read("res://data/drives.json")
	if typeof(drives) != TYPE_DICTIONARY:
		drives = {}


func _read(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func all_jobs() -> Array:
	var out: Array = jobs.duplicate()
	out.append_array(GameState.generated_jobs)
	return out


func get_job(id: String) -> Dictionary:
	for job in all_jobs():
		if str(job.get("id", "")) == id:
			return _decorate(job)
	return {}


func _decorate(job: Dictionary) -> Dictionary:
	var copy: Dictionary = job.duplicate(true)
	var brief: Dictionary = briefs.get(str(job.get("id", "")), {})
	if brief.is_empty():
		return copy
	if not copy.has("title"):
		copy["title"] = brief.get("title", "")
	if not copy.has("client"):
		copy["client"] = brief.get("client", "")
	if not copy.has("brief") or str(copy.get("brief", "")) == "":
		copy["brief"] = brief.get("brief", "")
	if not copy.has("mentor_note") or str(copy.get("mentor_note", "")) == "":
		copy["mentor_note"] = brief.get("mentor_note", "")
	copy["narrative_base"] = int(brief.get("base_pay", 0))
	return copy


func base_pay(job: Dictionary) -> int:
	var key := str(job.get("base_key", ""))
	if key != "":
		return int(Tuning.get_value("pay." + key, job.get("narrative_base", 100)))
	return int(job.get("narrative_base", 100))


func get_drive(id: String) -> Dictionary:
	if GameState.generated_drives.has(id):
		return (GameState.generated_drives[id] as Dictionary).duplicate(true)
	var course: Dictionary = drives.get(id, {})
	return course.duplicate(true)


func build_job_items(job: Dictionary) -> Array:
	var items: Array = []
	var index := 0
	for group in job.get("recipe", []):
		var count := int(group.get("count", 1))
		var names: Array = group.get("names", [])
		for n in count:
			var uid := "j%d" % index
			var item_id := str(group.get("item", "box"))
			var def := ItemDB.get_item(item_id)
			var label := str(def.get("name", item_id))
			if n < names.size():
				label = "%s (%s)" % [label, names[n]]
			elif count > 1:
				label = "%s %d" % [label, n + 1]
			items.append({
				"uid": uid,
				"item_id": item_id,
				"name": label,
				"set": str(group.get("set", "")),
				"state": "loose",
				"box": -1,
				"damage": 0,
				"taps": 0,
				"x": 0.8 + float(index % 6) * 0.7,
				"y": 0.0,
				"z": 1.2 + float(index / 6) * 0.7,
				"rot": 0.0,
				"fragile": bool(def.get("fragile", false)),
				"heavy": bool(def.get("heavy", false)),
				"bulky": bool(def.get("bulky", false)),
				"mystery": bool(def.get("mystery", false)),
				"mount": str(def.get("mount", "floor")),
			})
			index += 1
	return items
