class_name StackItem
extends RigidBody3D

const Tune = preload("res://scripts/tuning.gd")
const PropLib = preload("res://scripts/props.gd")
const SupportMath = preload("res://scripts/stacking/support.gd")

signal settled(item: StackItem)

var kind := ""
var item_id := ""
var size := Vector3.ONE
var side := ""
var furniture := false
var safe_spot := Vector3.ZERO
var safe_yaw := 0.0
var safe_ready := false
var live_drop := false
var hold_eval := false
var room_origin := Vector2.ZERO
var room_size := Vector2.ZERO
var extra_rects: Array = []
var room_ceiling := 2.8
var track_bounds := false
var _bottom_local := 0.0
var _calm := 0.0
var _age := 0.0
var _token := 0
var _escapes := 0


func setup(kind_name: String, body_size: Vector3, visual: Node = null, aliases: PackedStringArray = PackedStringArray()) -> void:
	kind = kind_name
	var names: Array = [kind_name]
	names.append_array(aliases)
	var center := Vector3(0, maxf(body_size.y, 0.05) * 0.5, 0)
	if visual is Node3D:
		var bounds := PropLib.content_aabb(visual)
		if bounds.size.length() >= 0.02:
			body_size = bounds.size
			center = bounds.get_center()
		var collision := visual.get_node_or_null("PropCollision")
		if collision:
			collision.free()
		visual.name = "Visual"
	size = Vector3(maxf(body_size.x, 0.05), maxf(body_size.y, 0.05), maxf(body_size.z, 0.05))
	_bottom_local = center.y - size.y * 0.5
	collision_layer = PropLib.LAYER_BLOCKING
	collision_mask = PropLib.LAYER_BLOCKING
	continuous_cd = true
	lock_rotation = false
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	linear_damp = float(Tune.get_value("stacking.linear_damp", 0.3))
	angular_damp = float(Tune.get_value("stacking.angular_damp", 2.0))
	var material := PhysicsMaterial.new()
	material.friction = float(Tune.get_value("stacking.friction", 0.9))
	material.bounce = float(Tune.get_value("stacking.bounce", 0.05))
	physics_material_override = material
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Collider"
	if SupportMath.wants_cylinder(names):
		var cyl := CylinderShape3D.new()
		cyl.height = size.y
		cyl.radius = maxf(size.x, size.z) * 0.5
		shape_node.shape = cyl
	else:
		var box := BoxShape3D.new()
		box.size = size
		shape_node.shape = box
	shape_node.position = center
	add_child(shape_node)
	if visual:
		add_child(visual)
	freeze = true
	live_drop = false


func rest_bottom() -> float:
	return global_position.y + _bottom_local


func note_safe(pos: Vector3, yaw: float) -> void:
	safe_spot = pos
	safe_yaw = yaw
	safe_ready = true


func drop_at(pos: Vector3, yaw: float) -> void:
	_token += 1
	global_position = pos
	rotation = Vector3(0, yaw, 0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_calm = 0.0
	_age = 0.0
	_escapes = 0
	hold_eval = false
	live_drop = true
	sleeping = false
	freeze = false


func spawn_frozen(pos: Vector3, yaw: float) -> void:
	_token += 1
	global_position = pos
	rotation = Vector3(0, yaw, 0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	note_safe(pos, yaw)
	live_drop = false
	hold_eval = false
	freeze = true


func mount_at(pos: Vector3, yaw: float, mount_side: String) -> void:
	side = mount_side
	spawn_frozen(pos, yaw)


func halt() -> void:
	_token += 1
	live_drop = false
	hold_eval = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func _physics_process(delta: float) -> void:
	if freeze or not live_drop:
		return
	if _escaped():
		global_position = safe_spot
		rotation = Vector3(0, safe_yaw, 0)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		_calm = 0.0
		_escapes += 1
		if _escapes > 8:
			_finish_settle()
		return
	_escapes = 0
	_age += delta
	var lin_max := float(Tune.get_value("stacking.settle_lin", 0.06))
	var ang_max := float(Tune.get_value("stacking.settle_ang", 0.25))
	var need := float(Tune.get_value("stacking.settle_time", 0.25))
	var timeout := float(Tune.get_value("stacking.settle_timeout", 4.0))
	if linear_velocity.length() < lin_max and angular_velocity.length() < ang_max:
		_calm += delta
	else:
		_calm = 0.0
	if _calm >= need or _age >= timeout:
		_finish_settle()


func _escaped() -> bool:
	if global_position.y < -0.25 or global_position.y > room_ceiling + 0.5:
		return true
	if not track_bounds:
		return false
	return not _inside_bounds(global_position)


func _inside_bounds(point: Vector3) -> bool:
	var local := Vector2(point.x - room_origin.x, point.z - room_origin.y)
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


func _finish_settle() -> void:
	if not live_drop:
		return
	live_drop = false
	_token += 1
	var token := _token
	set_deferred("linear_velocity", Vector3.ZERO)
	set_deferred("angular_velocity", Vector3.ZERO)
	set_deferred("freeze", true)
	call_deferred("_emit_settled", token)


func _emit_settled(token: int) -> void:
	if token != _token or not is_inside_tree():
		return
	settled.emit(self)
