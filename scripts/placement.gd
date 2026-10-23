class_name Placement
extends RefCounted

const Tuning = preload("res://scripts/tuning.gd")
const Props = preload("res://scripts/props.gd")

const SUPPORT_GAP := 0.04
const MIN_SUPPORT := 0.55
const PENETRATE := 0.03
const EDGE_SHRINK := 0.01
const DROP_LIFT := 0.018

static func resolve(x: float, z: float, y_hint: float, rot: float, def: Dictionary, others: Array, room: Rect2, snap: bool, extra_rooms: Array = []) -> Dictionary:
	if snap:
		var grid := Tuning.snap_grid()
		x = snapped(x, grid)
		z = snapped(z, grid)
	var w := float(def.get("w", 0.4))
	var d := float(def.get("d", 0.4))
	var h := float(def.get("h", 0.3))
	var samples := _samples(x, z, rot, w, d)
	var heights: Array[float] = []
	var plane := -1.0
	for sample in samples:
		var support := _support_at(sample, others, room, extra_rooms)
		heights.append(support)
		if support > plane:
			plane = support
	var supported := 0
	if plane >= 0.0:
		for height in heights:
			if height >= 0.0 and plane - height <= SUPPORT_GAP:
				supported += 1
	var fraction := 0.0 if heights.is_empty() else float(supported) / float(heights.size())
	var support_ok := plane >= 0.0 and fraction >= MIN_SUPPORT
	var bottom := plane if plane >= 0.0 else 0.0
	var floating := false
	if y_hint >= 0.0:
		if not support_ok or y_hint > plane + SUPPORT_GAP:
			floating = y_hint > plane + SUPPORT_GAP
			bottom = y_hint
		elif y_hint < plane - SUPPORT_GAP:
			bottom = y_hint
		else:
			bottom = plane
	elif not support_ok:
		bottom = 0.0
	var penetrating := _penetrates(x, z, bottom, rot, w, d, h, others)
	var valid := support_ok and not floating and not penetrating
	return {
		"valid": valid,
		"pos": Vector3(x, bottom, z),
		"rot": rot,
		"wall": "",
		"support": plane if plane >= 0.0 else 0.0,
	}


static func make_body(size: Vector3, pos: Vector3, rot_deg: float, settle: bool) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.lock_rotation = true
	body.linear_damp = 8.0
	body.angular_damp = 8.0
	body.continuous_cd = true
	body.collision_layer = Props.LAYER_BLOCKING
	body.collision_mask = Props.LAYER_BLOCKING
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.05), maxf(size.y, 0.05), maxf(size.z, 0.05))
	box.margin = 0.001
	shape_node.shape = box
	shape_node.position = Vector3(0, box.size.y * 0.5, 0)
	body.add_child(shape_node)
	body.position = pos
	body.rotation.y = deg_to_rad(rot_deg)
	if settle:
		body.freeze = false
		body.position.y += DROP_LIFT
		body.linear_velocity = Vector3.ZERO
	else:
		body.freeze = true
	return body


static func finish_settle(body: RigidBody3D) -> void:
	if body == null:
		return
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.freeze = true


static func _samples(x: float, z: float, rot: float, w: float, d: float) -> Array[Vector2]:
	var basis := Basis(Vector3.UP, deg_to_rad(rot))
	var hw := w * 0.5 * 0.7
	var hd := d * 0.5 * 0.7
	var points: Array[Vector2] = []
	for iu in [-1.0, 0.0, 1.0]:
		for iv in [-1.0, 0.0, 1.0]:
			var world: Vector3 = Vector3(x, 0, z) + basis * Vector3(iu * hw, 0, iv * hd)
			points.append(Vector2(world.x, world.z))
	return points


static func _support_at(sample: Vector2, others: Array, room: Rect2, extra_rooms: Array) -> float:
	var best := -1.0
	if _in_rooms(sample, room, extra_rooms):
		best = 0.0
	for rec in others:
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		if str(rec.get("state", "placed")) != "placed":
			continue
		var size := _size_of(rec)
		if not _contains(sample, float(size.x), float(size.z), float(size.rot), float(size.w), float(size.d)):
			continue
		var surface := float(size.surface)
		var height := float(size.h)
		if surface > 0.0:
			height = surface
		var top := float(size.y) + height
		if top > best:
			best = top
	return best


static func _penetrates(x: float, z: float, bottom: float, rot: float, w: float, d: float, h: float, others: Array) -> bool:
	var top := bottom + h
	for rec in others:
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		if str(rec.get("state", "placed")) != "placed":
			continue
		var size := _size_of(rec)
		var other_y := float(size.y)
		var surface := float(size.surface)
		var solid_h := float(size.h)
		if surface > 0.0:
			solid_h = surface
		var other_top := other_y + solid_h
		# A desk, shelf, or box top is a place to sit, not a volume to avoid.
		if surface > 0.0 and bottom >= other_top - SUPPORT_GAP:
			continue
		var overlap_y := minf(top, other_top) - maxf(bottom, other_y)
		if overlap_y <= PENETRATE:
			continue
		if _obb_hit(x, z, rot, w, d, float(size.x), float(size.z), float(size.rot), float(size.w), float(size.d)):
			return true
	return false


static func _size_of(rec: Dictionary) -> Dictionary:
	var item_id := str(rec.get("item", rec.get("item_id", "")))
	var def: Dictionary = {}
	if item_id != "":
		def = ItemDB.get_item(item_id)
	return {
		"x": float(rec.get("x", 0.0)),
		"y": float(rec.get("y", 0.0)),
		"z": float(rec.get("z", 0.0)),
		"rot": float(rec.get("rot", 0.0)),
		"w": float(rec.get("w", def.get("w", 0.4))),
		"d": float(rec.get("d", def.get("d", 0.4))),
		"h": float(rec.get("h", def.get("h", 0.3))),
		"surface": float(rec.get("surface", def.get("surface", 0.0))),
	}


static func _in_rooms(sample: Vector2, room: Rect2, extra_rooms: Array) -> bool:
	if _in_rect(sample, room):
		return true
	for extra in extra_rooms:
		if extra is Rect2 and _in_rect(sample, extra):
			return true
	return false


static func _in_rect(sample: Vector2, room: Rect2) -> bool:
	return sample.x >= room.position.x and sample.x <= room.position.x + room.size.x and sample.y >= room.position.y and sample.y <= room.position.y + room.size.y


static func _contains(sample: Vector2, cx: float, cz: float, rot: float, w: float, d: float) -> bool:
	var basis := Basis(Vector3.UP, deg_to_rad(rot))
	var local: Vector3 = basis.inverse() * Vector3(sample.x - cx, 0, sample.y - cz)
	return absf(local.x) <= w * 0.5 and absf(local.z) <= d * 0.5


static func _obb_hit(ax: float, az: float, arot: float, aw: float, ad: float, bx: float, bz: float, brot: float, bw: float, bd: float) -> bool:
	var a_basis := Basis(Vector3.UP, deg_to_rad(arot))
	var b_basis := Basis(Vector3.UP, deg_to_rad(brot))
	var a_x := Vector2(a_basis.x.x, a_basis.x.z)
	var a_z := Vector2(a_basis.z.x, a_basis.z.z)
	var b_x := Vector2(b_basis.x.x, b_basis.x.z)
	var b_z := Vector2(b_basis.z.x, b_basis.z.z)
	var ahx := maxf(aw * 0.5 - EDGE_SHRINK, 0.01)
	var ahz := maxf(ad * 0.5 - EDGE_SHRINK, 0.01)
	var bhx := maxf(bw * 0.5 - EDGE_SHRINK, 0.01)
	var bhz := maxf(bd * 0.5 - EDGE_SHRINK, 0.01)
	var delta := Vector2(bx - ax, bz - az)
	var axes: Array[Vector2] = [a_x, a_z, b_x, b_z]
	for axis in axes:
		if axis.length_squared() < 0.0001:
			continue
		var dir := axis.normalized()
		var dist := absf(delta.dot(dir))
		var ra := ahx * absf(a_x.dot(dir)) + ahz * absf(a_z.dot(dir))
		var rb := bhx * absf(b_x.dot(dir)) + bhz * absf(b_z.dot(dir))
		if dist > ra + rb:
			return false
	return true
