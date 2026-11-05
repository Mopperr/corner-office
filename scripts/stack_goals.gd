extends RefCounted

const SupportMath = preload("res://scripts/stacking/support.gd")

const PATHS: Array[String] = [
	"res://data/stacking_goals.json",
	"res://data/shop_layouts/stacking_goals_shop.json",
]

const GAP := 0.06
const CAMERA_DIR := Vector2(1, 1)


static func all_goals() -> Array:
	var goals: Array = []
	for path in PATHS:
		if not FileAccess.file_exists(path):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var rows = parsed.get("goals", [])
		if typeof(rows) == TYPE_ARRAY:
			goals.append_array(rows)
	return goals


static func by_id(goal_id: String) -> Dictionary:
	for goal in all_goals():
		if str(goal.get("id", "")) == goal_id:
			return goal
	return {}


static func active(venue_id: String, who: String, items: Array, latched: Dictionary) -> Dictionary:
	for goal in all_goals():
		if str(goal.get("venue", "")) != venue_id:
			continue
		var owner := str(goal.get("character", ""))
		if owner != "" and owner != who:
			continue
		var result := evaluate(goal, items, latched)
		if not bool(result.get("met", false)):
			return goal
	return {}


static func evaluate(goal: Dictionary, items: Array, latched: Dictionary = {}) -> Dictionary:
	var goal_id := str(goal.get("id", ""))
	var empty := {"met": false, "latch": false, "yaw_uid": "", "yaw_add": 0.0, "pip": 0.0}
	if goal.is_empty():
		return empty
	if bool(goal.get("latch", false)) and bool(latched.get(goal_id, false)):
		return {"met": true, "latch": true, "yaw_uid": "", "yaw_add": 0.0, "pip": 0.0}
	var subject := _subjects(goal, items)
	if subject.is_empty():
		return empty
	var supports := _supports(goal, items)
	var overhang := float(goal.get("overhang", 0.0))
	var need := int(goal.get("stack_count", 0))
	var want := int(goal.get("count", 1))
	var hits := 0
	var yaw_uid := ""
	if bool(goal.get("same_tag", false)) or bool(goal.get("stack_on_self", false)):
		var stacked := _same_stack(subject, bool(goal.get("same_tag", false)))
		if stacked.is_empty():
			return empty
		yaw_uid = str(stacked.get("uid", ""))
		hits = 1
	else:
		for item in subject:
			if _item_met(goal, item, supports, items, overhang, need):
				hits += 1
	var met := hits >= maxi(want, 1)
	if not met:
		return empty
	var yaw_add := 0.0
	if met and float(goal.get("complete_yaw", 0.0)) != 0.0:
		var top := _by_uid(items, yaw_uid)
		if top.is_empty() or not bool(top.get("turned", false)):
			yaw_add = float(goal.get("complete_yaw", 0.0))
	return {
		"met": true,
		"latch": bool(goal.get("latch", false)),
		"yaw_uid": yaw_uid if yaw_add != 0.0 else "",
		"yaw_add": yaw_add,
		"pip": float(goal.get("pip", 0.0)),
	}


static func marker_pose(goal: Dictionary, items: Array) -> Dictionary:
	var kind := str(goal.get("marker", ""))
	if kind == "":
		return {}
	var yaw := float(goal.get("marker_yaw", 0.0))
	if kind == "ring":
		var anchor := _first(items, str(goal.get("near", "")))
		if anchor.is_empty():
			return {}
		return {
			"kind": "ring",
			"x": float(anchor.get("x", 0.0)),
			"y": 0.03,
			"z": float(anchor.get("z", 0.0)),
			"rot": 0.0,
			"radius": float(goal.get("near_m", 1.0)),
			"model": "",
		}
	var support := _first_support(goal, items)
	if support.is_empty():
		return {}
	var y := float(support.get("y", 0.0)) + float(support.get("h", 0.0))
	if need_stack(goal):
		y += float(support.get("h", 0.16)) * float(maxi(int(goal.get("stack_count", 1)) - 1, 0))
	return {
		"kind": "ghost",
		"x": float(support.get("x", 0.0)),
		"y": y,
		"z": float(support.get("z", 0.0)),
		"rot": yaw,
		"radius": 0.0,
		"model": _marker_model(goal),
		"show": str(goal.get("show", "always")),
	}


static func need_stack(goal: Dictionary) -> bool:
	return int(goal.get("stack_count", 0)) > 1


static func shows_when_held(goal: Dictionary) -> bool:
	return str(goal.get("show", "always")) == "held"


static func _item_met(goal: Dictionary, item: Dictionary, supports: Array, items: Array, overhang: float, need: int) -> bool:
	if _rejected(goal, item, items):
		return false
	var pile := _pile(items, goal, item)
	if need > 0 and pile.size() != need:
		return false
	var seat: Dictionary = pile[pile.size() - 1] if need > 0 and not pile.is_empty() else {}
	if seat.is_empty():
		seat = _best_support(item, supports, overhang)
	if seat.is_empty():
		return false
	if not _rests_on(item, seat, overhang):
		return false
	if str(goal.get("surface", "")) == "top" and not _on_top(item, seat):
		return false
	if not _near_ok(goal, seat, items):
		return false
	if bool(goal.get("camera_side", false)) and not _camera_clear(item, items):
		return false
	return true


static func _subjects(goal: Dictionary, items: Array) -> Array:
	var found: Array = []
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if _names(goal, item):
			found.append(item)
	return found


static func _supports(goal: Dictionary, items: Array) -> Array:
	var names := _name_list(goal, "support", "support_also")
	var found: Array = []
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if _named(item, names):
			found.append(item)
	return found


static func _names(goal: Dictionary, item: Dictionary) -> bool:
	return _named(item, _name_list(goal, "item", "also"))


static func _name_list(goal: Dictionary, key: String, extra: String) -> Array:
	var names: Array = [str(goal.get(key, ""))]
	var more = goal.get(extra, [])
	if typeof(more) == TYPE_ARRAY:
		for entry in more:
			names.append(str(entry))
	return names


static func _named(item: Dictionary, names: Array) -> bool:
	var item_id := str(item.get("item", ""))
	var model := str(item.get("model", ""))
	for name in names:
		var token := str(name)
		if token == "":
			continue
		if item_id == token or model == token:
			return true
	return false


static func _rejected(goal: Dictionary, item: Dictionary, items: Array) -> bool:
	var blocked = goal.get("reject", [])
	if typeof(blocked) != TYPE_ARRAY:
		return false
	if _named(item, blocked):
		return true
	for other in items:
		if typeof(other) != TYPE_DICTIONARY:
			continue
		if str(other.get("uid", "")) == str(item.get("uid", "")):
			continue
		if not _named(other, blocked):
			continue
		if _rests_on(item, other, 0.45):
			return true
	return false


static func _pile(items: Array, goal: Dictionary, around: Dictionary) -> Array:
	var names := _name_list(goal, "support", "support_also")
	var pile: Array = []
	var around_at := Vector2(float(around.get("x", 0.0)), float(around.get("z", 0.0)))
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if str(item.get("uid", "")) == str(around.get("uid", "")):
			continue
		if not _named(item, names):
			continue
		var at := Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0)))
		if at.distance_to(around_at) > 0.8:
			continue
		pile.append(item)
	pile.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("y", 0.0)) < float(b.get("y", 0.0))
	)
	return pile


static func _best_support(item: Dictionary, supports: Array, overhang: float) -> Dictionary:
	var best: Dictionary = {}
	var best_ratio := -1.0
	for support in supports:
		if not _rests_on(item, support, overhang):
			continue
		var ratio := _coverage(item, support)
		if ratio > best_ratio:
			best_ratio = ratio
			best = support
	return best


static func _rests_on(item: Dictionary, support: Dictionary, overhang: float) -> bool:
	if not _heights_match(item, support):
		return false
	if _coverage(item, support) + 0.0001 >= 1.0 - overhang:
		return true
	# A thin top, like the whiteboard frame or a standing board, still counts when
	# the item's center is on that top and its short side is not hanging off.
	if not _center_inside(item, support):
		return false
	if overhang <= 0.0:
		return true
	return _thin_coverage(item, support) + 0.0001 >= 1.0 - overhang


static func _on_top(item: Dictionary, support: Dictionary) -> bool:
	var top := float(support.get("y", 0.0)) + float(support.get("h", 0.0))
	return absf(float(item.get("y", 0.0)) - top) <= GAP


static func _heights_match(item: Dictionary, support: Dictionary) -> bool:
	var top := float(support.get("y", 0.0)) + float(support.get("h", 0.0))
	return absf(float(item.get("y", 0.0)) - top) <= GAP


static func _center_inside(item: Dictionary, support: Dictionary) -> bool:
	var support_foot := _foot(support)
	var point := Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0)))
	var grown := support_foot.grow(0.02)
	return grown.has_point(point)


static func _thin_coverage(item: Dictionary, support: Dictionary) -> float:
	var item_foot := _foot(item)
	var support_foot := _foot(support)
	if item_foot.size.x <= item_foot.size.y:
		if item_foot.size.x <= 0.00001:
			return 0.0
		var overlap := minf(item_foot.end.x, support_foot.end.x) - maxf(item_foot.position.x, support_foot.position.x)
		return maxf(overlap, 0.0) / item_foot.size.x
	if item_foot.size.y <= 0.00001:
		return 0.0
	var overlap_z := minf(item_foot.end.y, support_foot.end.y) - maxf(item_foot.position.y, support_foot.position.y)
	return maxf(overlap_z, 0.0) / item_foot.size.y


static func _foot(item: Dictionary) -> Rect2:
	return SupportMath.footprint(
		Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0))),
		Vector2(float(item.get("w", 0.2)), float(item.get("d", 0.2))),
		float(item.get("rot", 0.0))
	)


static func _coverage(item: Dictionary, support: Dictionary) -> float:
	var item_foot := SupportMath.footprint(
		Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0))),
		Vector2(float(item.get("w", 0.2)), float(item.get("d", 0.2))),
		float(item.get("rot", 0.0))
	)
	var support_foot := SupportMath.footprint(
		Vector2(float(support.get("x", 0.0)), float(support.get("z", 0.0))),
		Vector2(float(support.get("w", 0.2)), float(support.get("d", 0.2))),
		float(support.get("rot", 0.0))
	)
	var area := item_foot.size.x * item_foot.size.y
	if area <= 0.00001:
		return 0.0
	if not item_foot.intersects(support_foot, true):
		return 0.0
	var hit := item_foot.intersection(support_foot)
	return (hit.size.x * hit.size.y) / area


static func _near_ok(goal: Dictionary, seat: Dictionary, items: Array) -> bool:
	var token := str(goal.get("near", ""))
	if token == "":
		return true
	var reach := float(goal.get("near_m", 1.0))
	var anchor := _first(items, token)
	if anchor.is_empty():
		return false
	var at := Vector2(float(seat.get("x", 0.0)), float(seat.get("z", 0.0)))
	var other := Vector2(float(anchor.get("x", 0.0)), float(anchor.get("z", 0.0)))
	return at.distance_to(other) <= reach + 0.001


static func _camera_clear(item: Dictionary, items: Array) -> bool:
	var here := Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0)))
	var dir := CAMERA_DIR.normalized()
	var found := false
	var clear := true
	for other in items:
		if typeof(other) != TYPE_DICTIONARY:
			continue
		if str(other.get("item", "")) != "beam" and str(other.get("model", "")) != "ceiling_beam":
			continue
		found = true
		var beam := Vector2(float(other.get("x", 0.0)), float(other.get("z", 0.0)))
		if beam.dot(dir) > here.dot(dir) + 0.15:
			var span := here - beam
			if absf(span.x) < 1.6 and absf(span.y) < 1.6:
				clear = false
	return found and clear


static func _same_stack(items: Array, require_tag: bool) -> Dictionary:
	for top in items:
		for base in items:
			if str(top.get("uid", "")) == str(base.get("uid", "")):
				continue
			if require_tag:
				var tag := str(top.get("tag", ""))
				if tag == "" or tag != str(base.get("tag", "")):
					continue
			if float(top.get("y", 0.0)) <= float(base.get("y", 0.0)):
				continue
			if _rests_on(top, base, 0.2):
				return top
	return {}


static func _first(items: Array, token: String) -> Dictionary:
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if _named(item, [token]):
			return item
	return {}


static func _first_support(goal: Dictionary, items: Array) -> Dictionary:
	var supports := _supports(goal, items)
	if supports.is_empty():
		return {}
	return supports[0]


static func _by_uid(items: Array, uid: String) -> Dictionary:
	if uid == "":
		return {}
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("uid", "")) == uid:
			return item
	return {}


static func _marker_model(goal: Dictionary) -> String:
	var item_id := str(goal.get("item", ""))
	if item_id == "box_closed":
		return "box_closed"
	if item_id == "paper_cup_stack":
		return "paper_cup_stack"
	if item_id == "tip_jar":
		return "tip_jar"
	if ItemDB != null:
		var def := ItemDB.get_item(item_id)
		var model := str(def.get("model", ""))
		if model != "":
			return model
	return item_id
