extends Node

var narrative_items: Dictionary = {}
var content_items: Dictionary = {}
# The big catalogue (data/items/*.json): generated families plus whatever
# the team adds in the same format. Items merge into content_items; the
# primitive models live in catalog_props for Props to build from.
var catalog_items: Dictionary = {}
var catalog_props: Dictionary = {}
var catalog_files: Array = []
var content: Dictionary = {}
var buyers: Array = []
var characters: Array = []


func _ready() -> void:
	_load()


func _load() -> void:
	var narrative: Variant = _read_json("res://data/narrative/items.json")
	if typeof(narrative) == TYPE_ARRAY:
		for entry in narrative:
			narrative_items[str(entry.get("id", ""))] = entry
	content = _read_json("res://data/content.json")
	if typeof(content) != TYPE_DICTIONARY:
		content = {}
	content_items = content.get("items", {})
	_load_catalog()
	buyers = content.get("buyers", [])
	characters = content.get("characters", [])


func _load_catalog() -> void:
	catalog_items = {}
	catalog_props = {}
	catalog_files = []
	var dir := DirAccess.open("res://data/items")
	if dir == null:
		return
	var names: Array = []
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			names.append(file_name)
	names.sort()
	for file_name in names:
		var parsed: Variant = _read_json("res://data/items/%s" % file_name)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		catalog_files.append(file_name)
		var props: Dictionary = parsed.get("props", {})
		for key in props.keys():
			catalog_props[str(key)] = props[key]
		var items: Dictionary = parsed.get("items", {})
		for key in items.keys():
			var id := str(key)
			if content_items.has(id) or catalog_items.has(id):
				continue
			var def: Dictionary = items[key]
			def["catalog"] = file_name.trim_suffix(".json")
			catalog_items[id] = def
			content_items[id] = def


func room_pool(tags: Array, mounts: Array = []) -> Array:
	# Catalogue ids for these rooms (and mounts), in a fixed order.
	var out: Array = []
	for id in catalog_items.keys():
		var def: Dictionary = catalog_items[id]
		if not tags.has(str(def.get("room", ""))):
			continue
		if not mounts.is_empty() and not mounts.has(str(def.get("mount", "floor"))):
			continue
		out.append(str(id))
	out.sort()
	return out


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing %s" % path)
		return null
	return JSON.parse_string(file.get_as_text())


func get_item(id: String) -> Dictionary:
	var merged := {}
	if narrative_items.has(id):
		merged = narrative_items[id].duplicate(true)
	if content_items.has(id):
		for key in content_items[id].keys():
			merged[key] = content_items[id][key]
	if not merged.has("name"):
		merged["name"] = id.capitalize()
	if not merged.has("flavor"):
		merged["flavor"] = ""
	merged["id"] = id
	return merged


func display_name(id: String) -> String:
	return str(get_item(id).get("name", id))


func flavor(id: String) -> String:
	return str(get_item(id).get("flavor", ""))


func trade_goods() -> Array:
	var goods: Array = []
	for id in narrative_items.keys():
		if str(narrative_items[id].get("type", "")) == "tradeable":
			var item := get_item(id)
			item["id"] = id
			goods.append(item)
	goods.sort_custom(func(a, b): return str(a["name"]) < str(b["name"]))
	return goods


func decor_goods() -> Array:
	var goods: Array = []
	for id in narrative_items.keys():
		if str(narrative_items[id].get("type", "")) != "decor":
			continue
		var item := get_item(id)
		if float(item.get("price", 0)) <= 0 and not content_items.has(id):
			continue
		if float(item.get("price", 0)) <= 0:
			continue
		item["id"] = id
		goods.append(item)
	goods.sort_custom(func(a, b): return str(a["name"]) < str(b["name"]))
	return goods


func base_price(id: String) -> int:
	return int(get_item(id).get("price", 10))


var _venues_cache: Dictionary = {}


func venues() -> Dictionary:
	# The authored venues plus every home in data/homes.json.
	if _venues_cache.is_empty():
		_venues_cache = (content.get("venues", {}) as Dictionary).duplicate(true)
		for home_id in Homes.all().keys():
			_venues_cache[str(home_id)] = Homes.venue_for(str(home_id))
	return _venues_cache


func starter_layout() -> Array:
	return content.get("starter", [])
