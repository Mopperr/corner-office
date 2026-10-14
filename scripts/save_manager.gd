extends Node

const SAVE_PATH := "user://corner_office_save.json"
const SETTINGS_PATH := "user://settings.cfg"

var music_linear := 0.8
var sfx_linear := 0.8
var shake := true
var text_scale := 1.0


func _ready() -> void:
	load_settings()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save")
		return false
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	save_settings()
	return true


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
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_linear = float(cfg.get_value("audio", "music", music_linear))
	sfx_linear = float(cfg.get_value("audio", "sfx", sfx_linear))
	shake = bool(cfg.get_value("access", "shake", shake))
	text_scale = float(cfg.get_value("access", "text_scale", text_scale))
