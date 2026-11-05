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
	var base := int(job.get("narrative_base", 100))
	if key != "":
		base = int(Tuning.get_value("pay." + key, job.get("narrative_base", 100)))
	# Modifiers and a league week at the top lift it.
	return int(round(float(base) * load("res://scripts/extras.gd").job_mult(job)))


func get_drive(id: String) -> Dictionary:
	if GameState.generated_drives.has(id):
		return (GameState.generated_drives[id] as Dictionary).duplicate(true)
	var course: Dictionary = drives.get(id, {})
	return course.duplicate(true)


# What an authored place's extra pieces come from: the catalogue rooms that suit it.
const EXTRA_TAGS := {
	"cafe": ["kitchen", "office"], "train": ["loft", "office"], "park": ["shed", "living"], "bakery": ["kitchen", "living"],
	"studio": ["living", "office"], "flat": ["living", "bedroom", "kitchen"],
}


func _extra_recipe(job: Dictionary) -> Array:
	# A dozen small catalogue pieces on top of an authored job's own list, the
	# same ones every time for that job, so the place is really being moved.
	if bool(job.get("generated", false)) or bool(job.get("shady", false)):
		return []
	var extra := int(Tuning.get_value("jobs.authored_extra", 0))
	if extra <= 0:
		return []
	var tags: Array = EXTRA_TAGS.get(str(job.get("venue", "")), ["living", "office"])
	var pool: Array = ItemDB.room_pool(tags, ["small", "floor"])
	if pool.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("extra:" + str(job.get("id", "")))
	var out: Array = []
	var guard := 0
	while out.size() < extra and guard < extra * 6:
		guard += 1
		var id := str(pool[rng.randi_range(0, pool.size() - 1)])
		var def := ItemDB.get_item(id)
		if bool(def.get("nobox", false)) or bool(def.get("heavy", false)) or bool(def.get("bulky", false)):
			continue
		if float(def.get("w", 0)) > 0.7 or float(def.get("d", 0)) > 0.7:
			continue
		var dup := false
		for group in out:
			if str(group.get("item", "")) == id:
				dup = true
		if dup:
			continue
		out.append({"item": id, "count": 1})
	return out


func build_job_items(job: Dictionary) -> Array:
	var items: Array = []
	var index := 0
	var recipe: Array = (job.get("recipe", []) as Array).duplicate()
	recipe.append_array(_extra_recipe(job))
	for group in recipe:
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
				"nobox": bool(def.get("nobox", false)),
				"room": str(def.get("room", "")),
				"bulky": bool(def.get("bulky", false)),
				"mystery": bool(def.get("mystery", false)),
				"mount": str(def.get("mount", "floor")),
				"weight": ItemDB.weight(def),
			})
			index += 1
	return items
