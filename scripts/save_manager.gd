extends Node

const SAVE_PATH := "user://corner_office_save.json"
const SETTINGS_PATH := "user://settings.cfg"

var music_linear := 0.8
var sfx_linear := 0.8
var shake := true
var text_scale := 1.0
var snap_to_grid := false
var graphics_quality := "medium"

const Graphics = preload("res://scripts/settings_manager.gd")
const Controls = preload("res://scripts/control_map.gd")


func _ready() -> void:
	load_settings()
	Graphics.apply_tier(get_tree(), graphics_quality)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	# The file never holds an item in hand or mid-drop: those are written as
	# placed. The live game keeps holding it, so an autosave mid-pickup cannot
	# snatch the item back.
	var data := GameState.to_dict()
	_settle_states(data.get("office_items", []))
	_settle_states(data.get("job", {}).get("items", []))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	save_settings()
	return true


func _settle_states(items: Array) -> void:
	for rec in items:
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		var state := str(rec.get("state", ""))
		if state == "hand" or state == "settling":
			rec["state"] = "placed"


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	GameState.from_dict(parsed)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_linear)
	cfg.set_value("audio", "sfx", sfx_linear)
	cfg.set_value("access", "shake", shake)
	cfg.set_value("access", "text_scale", text_scale)
	cfg.set_value("place", "snap_to_grid", snap_to_grid)
	cfg.set_value("graphics", "quality", graphics_quality)
	cfg.set_value("controls", "bindings", Controls.export_json())
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_linear = float(cfg.get_value("audio", "music", music_linear))
	sfx_linear = float(cfg.get_value("audio", "sfx", sfx_linear))
	shake = bool(cfg.get_value("access", "shake", shake))
	text_scale = float(cfg.get_value("access", "text_scale", text_scale))
	snap_to_grid = bool(cfg.get_value("place", "snap_to_grid", snap_to_grid))
	graphics_quality = Graphics.normalize(str(cfg.get_value("graphics", "quality", graphics_quality)))
	Controls.import_json(str(cfg.get_value("controls", "bindings", "")))
