extends RefCounted

# Keys the game actually reads. Arrows stay as a second set for driving.
# Joypad buttons and the left stick work alongside the keys.

const SPECS: Array = [
	{"id": "drive_forward", "label": "Drive forward", "key": KEY_W, "joy": JOY_BUTTON_DPAD_UP},
	{"id": "drive_back", "label": "Drive back", "key": KEY_S, "joy": JOY_BUTTON_DPAD_DOWN},
	{"id": "steer_left", "label": "Steer left", "key": KEY_A, "joy": JOY_BUTTON_DPAD_LEFT},
	{"id": "steer_right", "label": "Steer right", "key": KEY_D, "joy": JOY_BUTTON_DPAD_RIGHT},
	{"id": "horn", "label": "Horn", "key": KEY_H, "joy": JOY_BUTTON_RIGHT_SHOULDER},
	{"id": "handbrake", "label": "Handbrake", "key": KEY_SPACE, "joy": JOY_BUTTON_B},
	{"id": "interact", "label": "Load / unload", "key": KEY_E, "joy": JOY_BUTTON_A},
	{"id": "rotate", "label": "Rotate", "key": KEY_R, "joy": JOY_BUTTON_X},
	{"id": "snap", "label": "Grid snap", "key": KEY_G, "joy": JOY_BUTTON_Y},
	{"id": "pause", "label": "Pause", "key": KEY_ESCAPE, "joy": JOY_BUTTON_START},
]

const ALT := {
	"drive_forward": KEY_UP,
	"drive_back": KEY_DOWN,
	"steer_left": KEY_LEFT,
	"steer_right": KEY_RIGHT,
}

static var current: Dictionary = {}


static func specs() -> Array:
	return SPECS


static func ensure() -> void:
	if not current.is_empty():
		return
	current = {}
	for spec in SPECS:
		current[str(spec.get("id", ""))] = {
			"key": int(spec.get("key", 0)),
			"joy": int(spec.get("joy", -1)),
		}


static func binding(id: String) -> Dictionary:
	ensure()
	if current.has(id):
		return current[id]
	return {"key": 0, "joy": -1}


static func set_key(id: String, key: Key) -> void:
	ensure()
	var row: Dictionary = binding(id).duplicate()
	row["key"] = int(key)
	current[id] = row
	_mirror_pause()


static func set_joy(id: String, button: int) -> void:
	ensure()
	var row: Dictionary = binding(id).duplicate()
	row["joy"] = button
	current[id] = row
	_mirror_pause()


static func held(id: String) -> bool:
	var row := binding(id)
	var key := int(row.get("key", 0))
	if key != 0 and Input.is_key_pressed(key as Key):
		return true
	var alt := int(ALT.get(id, 0))
	if alt != 0 and Input.is_key_pressed(alt as Key):
		return true
	var joy := int(row.get("joy", -1))
	if joy >= 0:
		for device in Input.get_connected_joypads():
			if Input.is_joy_button_pressed(device, joy):
				return true
	return false


static func axis(neg_id: String, pos_id: String) -> float:
	var value := 0.0
	if held(neg_id):
		value -= 1.0
	if held(pos_id):
		value += 1.0
	for device in Input.get_connected_joypads():
		if neg_id == "steer_left":
			var x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
			if absf(x) > 0.25:
				value += clampf(x, -1.0, 1.0)
		elif neg_id == "drive_back":
			var y := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
			if absf(y) > 0.25:
				value -= clampf(y, -1.0, 1.0)
	return clampf(value, -1.0, 1.0)


static func describe_key(id: String) -> String:
	var name := OS.get_keycode_string(int(binding(id).get("key", 0)))
	return name if name != "" else "Unbound"


static func event_pressed(event: InputEvent, id: String) -> bool:
	# Only keys and pad buttons carry `pressed`; mouse motion would throw here.
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return false
	if not event.pressed or event.is_echo():
		return false
	var row := binding(id)
	if event is InputEventKey and (event as InputEventKey).keycode == int(row.get("key", 0)):
		return true
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == int(row.get("joy", -1)):
		return true
	return false


static func describe(id: String) -> String:
	var row := binding(id)
	var key_name := OS.get_keycode_string(int(row.get("key", 0)))
	if key_name == "":
		key_name = "Unbound"
	var joy := int(row.get("joy", -1))
	return "%s  /  %s" % [key_name, _joy_name(joy)]


static func export_json() -> String:
	ensure()
	return JSON.stringify(current)


static func import_json(raw: String) -> void:
	ensure()
	if raw == "":
		return
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for spec in SPECS:
		var id := str(spec.get("id", ""))
		if not (parsed as Dictionary).has(id):
			continue
		var row: Variant = (parsed as Dictionary)[id]
		if typeof(row) != TYPE_DICTIONARY:
			continue
		current[id] = {
			"key": int((row as Dictionary).get("key", spec.get("key", 0))),
			"joy": int((row as Dictionary).get("joy", spec.get("joy", -1))),
		}
	_mirror_pause()


static func _joy_name(button: int) -> String:
	match button:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_START:
			return "Start"
		JOY_BUTTON_DPAD_UP:
			return "D-pad up"
		JOY_BUTTON_DPAD_DOWN:
			return "D-pad down"
		JOY_BUTTON_DPAD_LEFT:
			return "D-pad left"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-pad right"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "R"
		_:
			if button < 0:
				return "No pad"
			return "Pad %d" % button


static func _mirror_pause() -> void:
	if not InputMap.has_action("ui_cancel"):
		return
	var row := binding("pause")
	var key := InputEventKey.new()
	key.keycode = int(row.get("key", KEY_ESCAPE)) as Key
	var known := false
	for event in InputMap.action_get_events("ui_cancel"):
		if event is InputEventKey and (event as InputEventKey).keycode == key.keycode:
			known = true
	if not known:
		InputMap.action_add_event("ui_cancel", key)
	var joy_button := int(row.get("joy", -1))
	if joy_button < 0:
		return
	var joy := InputEventJoypadButton.new()
	joy.button_index = joy_button
	for event in InputMap.action_get_events("ui_cancel"):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == joy_button:
			return
	InputMap.action_add_event("ui_cancel", joy)
