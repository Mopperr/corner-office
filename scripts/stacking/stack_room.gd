class_name StackRoom
extends Node3D

const Tune = preload("res://scripts/tuning.gd")
const SupportMath = preload("res://scripts/stacking/support.gd")
const ItemBody = preload("res://scripts/stacking/stack_item.gd")

signal item_evaluated(id: String, result: Dictionary)

var origin := Vector2.ZERO
var room_size := Vector2(6, 8)
var extra_rects: Array = []
var items: Dictionary = {}
var surfaces: Array = []
var results: Dictionary = {}
var hints: Array = []
var snap_assist := false
var ceiling_y := 2.8
var _retries: Dictionary = {}
var _pending_drops: Array = []
var _shell_ready := false


func configure(room_origin: Vector2, size: Vector2, extras: Array = []) -> void:
	origin = room_origin
	room_size = size
	extra_rects = extras
	_ensure_shell()


func _ensure_shell() -> void:
	if _shell_ready:
		return
	_shell_ready = true
	ceiling_y = float(Tune.get_value("stacking.wall_height", 2.8))
	var body := StaticBody3D.new()
	body.name = "StackShell"
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("cutaway_shell")
	var thick := 0.06
	_add_perimeter(body, origin, room_size, ceiling_y, thick)
	_add_ceiling(body, origin, room_size, ceiling_y)
	for extra in extra_rects:
		if not (extra is Rect2):
			continue
		var rect: Rect2 = extra
		var extra_origin := Vector2(rect.position.x, rect.position.y)
		_add_perimeter(body, extra_origin, rect.size, ceiling_y, thick)
		_add_ceiling(body, extra_origin, rect.size, ceiling_y)
	add_child(body)
	_add_floor_surface("floor", Rect2(origin, room_size))
	var index := 0
	for extra in extra_rects:
		if extra is Rect2:
			index += 1
			_add_floor_surface("floor_%d" % index, extra)


func add_floor() -> void:
	if get_node_or_null("StackFloor") != null:
		return
	var body := StaticBody3D.new()
	body.name = "StackFloor"
	body.collision_layer = 1
	body.collision_mask = 1
	var material := PhysicsMaterial.new()
	material.friction = float(Tune.get_value("stacking.friction", 0.9))
	material.bounce = 0.0
	body.physics_material_override = material
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(room_size.x, 0.08, room_size.y)
	shape.shape = box
	shape.position = Vector3(origin.x + room_size.x * 0.5, -0.04, origin.y + room_size.y * 0.5)
	body.add_child(shape)
	add_child(body)


func add_block(center: Vector3, extents: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var material := PhysicsMaterial.new()
	material.friction = float(Tune.get_value("stacking.friction", 0.9))
	material.bounce = 0.0
	body.physics_material_override = material
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = extents
	shape.shape = box
	body.position = center
	body.add_child(shape)
	add_child(body)
	return body


func add_furniture(id: String, center: Vector2, size: Vector2, top: float, rot_deg: float = 0.0, level: int = 0) -> void:
	_remove_surface(id)
	surfaces.append({
		"id": id,
		"rect": SupportMath.footprint(center, size, rot_deg),
		"top": top,
		"level": level,
		"kind": "furniture",
	})
	hints.append(center)


func adopt(item) -> void:
	if item.get_parent() == null:
		add_child(item)
	item.room_origin = origin
	item.room_size = room_size
	item.extra_rects = extra_rects
	item.room_ceiling = ceiling_y
	item.track_bounds = true
	if not item.safe_ready:
		item.note_safe(Vector3(origin.x + room_size.x * 0.5, 0.0, origin.y + room_size.y * 0.5), 0.0)
	items[item.item_id] = item
	if not item.settled.is_connected(_on_item_settled):
		item.settled.connect(_on_item_settled)


func place(id: String, pos: Vector3, yaw: float, item) -> void:
	item.item_id = id
	adopt(item)
	var posed := _snap_pose(pos, yaw)
	item.drop_at(posed["pos"], float(posed["yaw"]))


func queue_drop(item, pos: Vector3, yaw: float) -> void:
	item.hold_eval = true
	item.global_position = pos
	item.rotation = Vector3(0, yaw, 0)
	item.freeze = true
	_pending_drops.append({"item": item, "pos": pos, "yaw": yaw})


func flush_drops() -> void:
	var queued := _pending_drops.duplicate()
	_pending_drops.clear()
	for entry in queued:
		var item = entry["item"]
		if not is_instance_valid(item):
			continue
		var posed := _snap_pose(entry["pos"], float(entry["yaw"]))
		var pos: Vector3 = posed["pos"]
		pos.y += 0.01
		item.drop_at(pos, float(posed["yaw"]))


func mount(id: String, along: float, y: float, mount_side: String, item) -> bool:
	if not SupportMath.wall_mount_ok(y):
		return false
	var inset := float(Tune.get_value("stacking.wall_offset", 0.12))
	var pos := Vector3.ZERO
	var yaw := 0.0
	match mount_side:
		"n":
			pos = Vector3(along, y, origin.y + inset)
			yaw = 0.0
		"s":
			pos = Vector3(along, y, origin.y + room_size.y - inset)
			yaw = PI
		"w":
			pos = Vector3(origin.x + inset, y, along)
			yaw = PI * 0.5
		"e":
			pos = Vector3(origin.x + room_size.x - inset, y, along)
			yaw = -PI * 0.5
		_:
			return false
	item.item_id = id
	adopt(item)
	item.mount_at(pos, yaw, mount_side)
	var result := {
		"supported": true,
		"stack_level": 1,
		"contacts": [],
		"bridged": false,
		"support_id": mount_side,
		"wall": mount_side,
		"mounted": true,
		"tipped": false,
		"in_room": true,
		"reset": false,
	}
	results[id] = result
	item_evaluated.emit(id, result)
	return true


func nearest_wall(point: Vector3) -> String:
	var reach := float(Tune.get_value("stacking.wall_reach", 0.6))
	var best := ""
	var best_d := reach + 0.0001
	var x0 := origin.x
	var z0 := origin.y
	var x1 := origin.x + room_size.x
	var z1 := origin.y + room_size.y
	var options := {
		"w": absf(point.x - x0),
		"e": absf(point.x - x1),
		"n": absf(point.z - z0),
		"s": absf(point.z - z1),
	}
	for mount_side in ["n", "w", "e", "s"]:
		var dist: float = float(options[mount_side])
		if dist <= reach and dist < best_d:
			best_d = dist
			best = mount_side
	return best


func release(id: String) -> Array:
	var released: Array = []
	_collect_deps(id, {}, released)
	for dep_id in released:
		var dep = items.get(dep_id)
		if dep and is_instance_valid(dep):
			dep.drop_at(dep.global_position, dep.rotation.y)
	items.erase(id)
	results.erase(id)
	_remove_surface(id)
	_remove_surface("item:" + id)
	return released


func wake(id: String) -> void:
	var chain: Array = []
	var seen := {id: true}
	chain.append(id)
	_collect_deps(id, seen, chain)
	for entry_id in chain:
		var item = items.get(entry_id)
		if item and is_instance_valid(item):
			item.drop_at(item.global_position, item.rotation.y)


func prepare_refresh() -> void:
	for id in items.keys():
		var item = items[id]
		if is_instance_valid(item):
			item.halt()
			if item.settled.is_connected(_on_item_settled):
				item.settled.disconnect(_on_item_settled)
	items.clear()
	results.clear()
	_retries.clear()
	_pending_drops.clear()
	var kept: Array = []
	for surface in surfaces:
		if str(surface.get("kind", "")) == "floor":
			kept.append(surface)
	surfaces = kept
	hints.clear()


func evaluate_frozen() -> void:
	var ordered: Array = items.values()
	ordered.sort_custom(func(a, b) -> bool:
		return a.rest_bottom() < b.rest_bottom()
	)
	for item in ordered:
		if item == null or not is_instance_valid(item):
			continue
		if item.hold_eval or item.live_drop or str(item.side) != "":
			continue
		_accept_frozen(item)


func resolve_settled(item) -> void:
	_on_item_settled(item)


func shutdown() -> void:
	prepare_refresh()


func contains_point(point: Vector3) -> bool:
	var local := Vector2(point.x - origin.x, point.z - origin.y)
	if SupportMath.in_room(local, room_size):
		return true
	for extra in extra_rects:
		if not (extra is Rect2):
			continue
		var rect: Rect2 = extra
		var shifted := Vector2(point.x - rect.position.x, point.z - rect.position.y)
		if SupportMath.in_room(shifted, rect.size):
			return true
	return false


func score() -> float:
	var placed := 0
	var fine := 0
	var near := 0
	var count := 0
	for id in items.keys():
		var item = items[id]
		if item == null or not is_instance_valid(item) or item.live_drop:
			continue
		count += 1
		var up: Vector3 = item.global_transform.basis.y
		var leaning := SupportMath.tipped(up)
		var result: Dictionary = results.get(id, {})
		var supported := bool(result.get("supported", false))
		var inside := contains_point(item.global_position)
		if supported and inside and not leaning:
			placed += 1
		if not leaning:
			fine += 1
		if _near_any(item):
			near += 1
	return SupportMath.room_score(placed, fine, near, count)


func _near_any(item) -> bool:
	var point := Vector2(float(item.global_position.x), float(item.global_position.z))
	var crowd: Array = []
	for hint in hints:
		crowd.append(hint)
	for id in items.keys():
		var other = items[id]
		if other == null or other == item or not is_instance_valid(other):
			continue
		crowd.append(Vector2(float(other.global_position.x), float(other.global_position.z)))
	return SupportMath.near_hint(point, crowd)


func _on_item_settled(item) -> void:
	if item == null or not is_instance_valid(item) or not items.has(item.item_id):
		return
	var up: Vector3 = item.global_transform.basis.y
	var tries := int(_retries.get(item.item_id, 0))
	if SupportMath.tipped(up) and tries < 1:
		_retries[item.item_id] = tries + 1
		var yaw: float = item.rotation.y
		var pos: Vector3 = item.global_position + Vector3(0, 0.02, 0)
		item.rotation = Vector3(0, yaw, 0)
		item.drop_at(pos, yaw)
		return
	var result := _evaluate(item)
	var bad := not bool(result.get("supported", false)) or SupportMath.tipped(up) or not bool(result.get("in_room", false))
	if bad:
		_gentle_reset(item)
		result = _evaluate(item)
		result["reset"] = true
	else:
		item.note_safe(item.global_position, item.rotation.y)
		result["reset"] = false
	if bool(result.get("supported", false)):
		_register_item_surface(item)
	_retries.erase(item.item_id)
	results[item.item_id] = result
	item_evaluated.emit(item.item_id, result)


func _accept_frozen(item) -> void:
	var result := _evaluate(item)
	result["reset"] = false
	if bool(result.get("supported", false)):
		item.note_safe(item.global_position, item.rotation.y)
	results[item.item_id] = result
	if bool(result.get("supported", false)):
		_register_item_surface(item)


func _evaluate(item) -> Dictionary:
	_remove_surface("item:" + item.item_id)
	var foot := _footprint_of(item)
	var com := Vector2(item.global_position.x, item.global_position.z)
	var result: Dictionary = SupportMath.check(com, foot, item.rest_bottom(), surfaces)
	var support_id := ""
	var support_ids: Array = []
	var best_top := -9999.0
	for contact in result.get("contacts", []):
		var cid := str(contact.get("id", ""))
		support_ids.append(cid)
		if float(contact.get("top", 0.0)) >= best_top:
			best_top = float(contact.get("top", 0.0))
			support_id = cid
	var up: Vector3 = item.global_transform.basis.y
	result["support_id"] = support_id
	result["support_ids"] = support_ids
	result["tipped"] = SupportMath.tipped(up)
	result["tilt"] = SupportMath.tilt_deg(up)
	result["in_room"] = contains_point(item.global_position)
	return result


func _register_item_surface(item) -> void:
	if item.furniture or str(item.side) != "":
		return
	_remove_surface("item:" + item.item_id)
	var level := int(results.get(item.item_id, {}).get("stack_level", 1))
	surfaces.append({
		"id": "item:" + item.item_id,
		"rect": _footprint_of(item),
		"top": item.rest_bottom() + item.size.y,
		"level": level,
		"kind": "item",
	})


func _gentle_reset(item) -> void:
	item.halt()
	item.global_position = item.safe_spot
	item.rotation = Vector3(0, item.safe_yaw, 0)
	item.linear_velocity = Vector3.ZERO
	item.angular_velocity = Vector3.ZERO
	item.freeze = true


func _collect_deps(id: String, seen: Dictionary, out: Array) -> void:
	for dep_id in _dependents(id):
		if seen.has(dep_id):
			continue
		seen[dep_id] = true
		out.append(dep_id)
		_collect_deps(dep_id, seen, out)


func _dependents(id: String) -> Array:
	var base = items.get(id)
	if base == null or not is_instance_valid(base):
		return []
	var top: float = base.rest_bottom() + base.size.y
	var foot := _footprint_of(base)
	var gap := float(Tune.get_value("stacking.support_gap", 0.04))
	var found: Array = []
	for other_id in items.keys():
		if other_id == id:
			continue
		var other = items[other_id]
		if other == null or not is_instance_valid(other):
			continue
		var result: Dictionary = results.get(other_id, {})
		var support_id := str(result.get("support_id", ""))
		var support_ids: Array = result.get("support_ids", [])
		if support_id == id or support_id == "item:" + id or support_ids.has(id) or support_ids.has("item:" + id):
			found.append(other_id)
			continue
		if absf(other.rest_bottom() - top) <= gap and foot.intersects(_footprint_of(other), true):
			found.append(other_id)
	return found


func _footprint_of(item) -> Rect2:
	var yaw: float = rad_to_deg(item.rotation.y)
	return SupportMath.footprint(Vector2(float(item.global_position.x), float(item.global_position.z)), Vector2(float(item.size.x), float(item.size.z)), yaw)


func _snap_pose(pos: Vector3, yaw: float) -> Dictionary:
	if not snap_assist:
		return {"pos": pos, "yaw": yaw}
	var grid := float(Tune.get_value("stacking.snap_grid", 0.25))
	var step := float(Tune.get_value("stacking.snap_yaw_fine", 15.0))
	pos.x = snapped(pos.x, grid)
	pos.z = snapped(pos.z, grid)
	yaw = deg_to_rad(snapped(rad_to_deg(yaw), step))
	return {"pos": pos, "yaw": yaw}


func _add_floor_surface(id: String, rect: Rect2) -> void:
	surfaces.append({
		"id": id,
		"rect": rect,
		"top": 0.0,
		"level": 0,
		"kind": "floor",
	})


func _remove_surface(id: String) -> void:
	var kept: Array = []
	for surface in surfaces:
		if str(surface.get("id", "")) == id:
			continue
		kept.append(surface)
	surfaces = kept


func _add_perimeter(body: StaticBody3D, at: Vector2, size: Vector2, height: float, thick: float) -> void:
	var x0 := at.x
	var z0 := at.y
	var x1 := at.x + size.x
	var z1 := at.y + size.y
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	_add_box(body, Vector3(cx, height * 0.5, z0 - thick * 0.5), Vector3(size.x, height, thick))
	_add_box(body, Vector3(cx, height * 0.5, z1 + thick * 0.5), Vector3(size.x, height, thick))
	_add_box(body, Vector3(x0 - thick * 0.5, height * 0.5, cz), Vector3(thick, height, size.y))
	_add_box(body, Vector3(x1 + thick * 0.5, height * 0.5, cz), Vector3(thick, height, size.y))


func _add_ceiling(body: StaticBody3D, at: Vector2, size: Vector2, height: float) -> void:
	_add_box(body, Vector3(at.x + size.x * 0.5, height + 0.025, at.y + size.y * 0.5), Vector3(size.x, 0.05, size.y))


func _add_box(body: StaticBody3D, center: Vector3, extents: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = extents
	shape.shape = box
	shape.position = center
	body.add_child(shape)
