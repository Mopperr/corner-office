extends RefCounted

const Props = preload("res://scripts/props.gd")

const ROOT := "res://data/shop_layouts/"


static func load_named(layout_name: String) -> Dictionary:
	var path := ROOT + layout_name + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func records(layout: Dictionary) -> Array:
	var raw = layout.get("props", [])
	if typeof(raw) != TYPE_ARRAY:
		return []
	var out: Array = []
	for entry in raw:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		out.append({
			"uid": str(entry.get("uid", "")),
			"model": str(entry.get("model", "")),
			"x": float(entry.get("x", 0.0)),
			"y": float(entry.get("y", 0.0)),
			"z": float(entry.get("z", 0.0)),
			"rot": float(entry.get("rot", 0.0)),
		})
	return out


static func place(host: Node3D, layout_name: String) -> void:
	if host == null:
		return
	for rec in records(load_named(layout_name)):
		var model_name := str(rec.get("model", ""))
		var node: Node3D = Props.model(model_name)
		if node == null:
			node = Node3D.new()
		node.name = str(rec.get("uid", model_name))
		node.position = Vector3(float(rec.get("x", 0.0)), float(rec.get("y", 0.0)), float(rec.get("z", 0.0)))
		node.rotation.y = deg_to_rad(float(rec.get("rot", 0.0)))
		host.add_child(node)
