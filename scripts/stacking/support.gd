class_name Support
extends RefCounted

const Tune = preload("res://scripts/tuning.gd")

const GAP := 0.04
const TILT_LIMIT := 20.0
const NEAR := 0.75
const WALL_Y_MIN := 0.6
const WALL_Y_MAX := 2.6
const ROOM_MARGIN := 0.05


static func _n(key: String, fallback: float) -> float:
	return float(Tune.get_value("stacking." + key, fallback))


static func footprint(center: Vector2, size: Vector2, rot_deg: float) -> Rect2:
	var deg := fposmod(rot_deg, 180.0)
	var span_x := size.x
	var span_z := size.y
	if deg > 45.0 and deg < 135.0:
		span_x = size.y
		span_z = size.x
	return Rect2(center.x - span_x * 0.5, center.y - span_z * 0.5, span_x, span_z)


static func check(com: Vector2, foot: Rect2, bottom_y: float, surfaces: Array) -> Dictionary:
	var gap := _n("support_gap", GAP)
	var contacts: Array = []
	var max_level := 0
	for surface in surfaces:
		if typeof(surface) != TYPE_DICTIONARY:
			continue
		var top := float(surface.get("top", 0.0))
		if absf(top - bottom_y) > gap:
			continue
		var rect: Rect2 = surface.get("rect", Rect2())
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if not rect.intersects(foot, true):
			continue
		var patch := rect.intersection(foot)
		if patch.size.x <= 0.00001 or patch.size.y <= 0.00001:
			continue
		var level := int(surface.get("level", 0))
		contacts.append({
			"id": str(surface.get("id", "")),
			"rect": patch,
			"top": top,
			"level": level,
		})
		max_level = maxi(max_level, level)
	var supported := false
	var bridged := false
	if contacts.size() == 1:
		supported = _contains_point(com, contacts[0]["rect"])
	elif contacts.size() >= 2:
		for contact in contacts:
			if _contains_point(com, contact["rect"]):
				supported = true
				break
		if not supported and _in_hull(com, contacts):
			supported = true
			bridged = true
	return {
		"supported": supported,
		"stack_level": max_level + 1 if supported else 0,
		"contacts": contacts,
		"bridged": bridged,
	}


static func wall_mount_ok(y: float) -> bool:
	return y >= _n("wall_y_min", WALL_Y_MIN) and y <= _n("wall_y_max", WALL_Y_MAX)


static func in_room(point: Vector2, room_size: Vector2) -> bool:
	var margin := _n("room_margin", ROOM_MARGIN)
	return point.x >= margin and point.y >= margin and point.x <= room_size.x - margin and point.y <= room_size.y - margin


static func tilt_deg(up: Vector3) -> float:
	if up.length_squared() < 0.0000001:
		return 0.0
	return rad_to_deg(up.normalized().angle_to(Vector3.UP))


static func tipped(up: Vector3) -> bool:
	return tilt_deg(up) > _n("tilt_deg", TILT_LIMIT)


static func near_hint(point: Vector2, hints: Array, radius: float = -1.0) -> bool:
	var reach := radius if radius >= 0.0 else _n("near_hint", NEAR)
	for hint in hints:
		var at := Vector2.ZERO
		if hint is Vector2:
			at = hint
		elif hint is Vector3:
			var vec: Vector3 = hint
			at = Vector2(vec.x, vec.z)
		elif typeof(hint) == TYPE_DICTIONARY:
			at = Vector2(float(hint.get("x", 0.0)), float(hint.get("z", hint.get("y", 0.0))))
		else:
			continue
		if point.distance_to(at) <= reach:
			return true
	return false


static func room_score(placed: int, fine: int, near: int, count: int) -> float:
	if count <= 0:
		return 0.0
	var placed_w := _n("score_placed", 50.0)
	var fine_w := _n("score_fine", 30.0)
	var near_w := _n("score_near", 20.0)
	var n := float(count)
	return placed_w * float(placed) / n + fine_w * float(fine) / n + near_w * float(near) / n


static func wants_cylinder(tokens: Array) -> bool:
	for token in tokens:
		var name := str(token).to_lower()
		if name.begins_with("mug") or name.begins_with("plant") or name.begins_with("lamp"):
			return true
	return false


static func _contains_point(point: Vector2, rect: Rect2) -> bool:
	var eps := 0.0001
	return point.x >= rect.position.x - eps and point.x <= rect.end.x + eps and point.y >= rect.position.y - eps and point.y <= rect.end.y + eps


static func _in_hull(point: Vector2, contacts: Array) -> bool:
	var pts := PackedVector2Array()
	for contact in contacts:
		var rect: Rect2 = contact["rect"]
		pts.append(rect.position)
		pts.append(Vector2(rect.end.x, rect.position.y))
		pts.append(rect.end)
		pts.append(Vector2(rect.position.x, rect.end.y))
	if pts.size() < 3:
		return false
	var hull := Geometry2D.convex_hull(pts)
	return Geometry2D.is_point_in_polygon(point, hull)
