class_name Props
extends RefCounted

const LAYER_BLOCKING := 1
const LAYER_PICKABLE := 2
const MASK_QUERY := 3
const WALL_THICKNESS := 0.24
const WALL_BODY_HALF := 0.12

static var _cache: Dictionary = {}

static func restyle_architecture(root: Node) -> void:
	if root == null:
		return
	var meshes: Array = []
	if root is MeshInstance3D:
		meshes.append(root)
	meshes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var base := mesh_instance.get_active_material(i)
			if not (base is StandardMaterial3D):
				continue
			var std := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			var luma := std.albedo_color.get_luminance()
			if luma > 0.72:
				std.albedo_color = Color("8E8276")
			elif luma > 0.42:
				std.albedo_color = Color("7A5C40")
			std.roughness = maxf(std.roughness, 0.88)
			mesh_instance.set_surface_override_material(i, std)


static func restyle_box(root: Node) -> void:
	if root == null:
		return
	var meshes: Array = []
	if root is MeshInstance3D:
		meshes.append(root)
	meshes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var base := mesh_instance.get_active_material(i)
			if not (base is StandardMaterial3D):
				continue
			var std := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			var color := std.albedo_color
			std.albedo_color = Color.from_hsv(0.075, clampf(color.s * 1.25 + 0.18, 0.0, 0.82), clampf(color.v, 0.42, 0.62))
			std.roughness = 0.84
			mesh_instance.set_surface_override_material(i, std)


static func set_hover_outline(root: Node, on: bool) -> void:
	if root == null:
		return
	var meshes: Array = []
	if root is MeshInstance3D:
		meshes.append(root)
	meshes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null:
			continue
		if not on:
			mesh_instance.material_overlay = null
			continue
		var outline := StandardMaterial3D.new()
		outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		outline.albedo_color = Color("3E2A22")
		outline.grow = true
		outline.grow_amount = 0.014
		outline.cull_mode = BaseMaterial3D.CULL_FRONT
		mesh_instance.material_overlay = outline


static func mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


static func mesh_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = mat(color)
	mesh_instance.position.y = size.y * 0.5
	return mesh_instance


static func mesh_cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 10
	mesh_instance.mesh = cyl
	mesh_instance.material_override = mat(color)
	mesh_instance.position.y = height * 0.5
	return mesh_instance


static func model(name: String) -> Node3D:
	var path := "res://assets/models/%s.glb" % name
	if not ResourceLoader.exists(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var packed: PackedScene = _cache[path]
	if packed == null:
		return null
	return packed.instantiate() as Node3D


static func make(spec: String) -> Node3D:
	if spec.begins_with("proc:"):
		return _proc(spec.trim_prefix("proc:"))
	var node := model(spec)
	if node == null:
		node = Node3D.new()
		node.add_child(mesh_box(Vector3(0.4, 0.3, 0.4), UIKit.CARD))
	ensure_box_collision(node)
	if "box" in spec:
		restyle_box(node)
	return node


static func _proc(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"sticky":
			root.add_child(mesh_box(Vector3(0.12, 0.012, 0.12), UIKit.MUSTARD))
			var mid := mesh_box(Vector3(0.11, 0.012, 0.11), UIKit.CREAM_CARD)
			mid.position = Vector3(0.008, 0.012, -0.004)
			root.add_child(mid)
			var top := mesh_box(Vector3(0.1, 0.012, 0.1), Color("E8B4A8"))
			top.position = Vector3(-0.006, 0.024, 0.006)
			root.add_child(top)
		"fridge":
			root.add_child(mesh_box(Vector3(0.58, 1.0, 0.52), UIKit.BLUE))
			var door := mesh_box(Vector3(0.5, 0.9, 0.04), UIKit.BLUE.lightened(0.12))
			door.position = Vector3(0, 0.05, 0.26)
			root.add_child(door)
			var handle := mesh_box(Vector3(0.04, 0.28, 0.04), UIKit.DARK)
			handle.position = Vector3(0.18, 0.2, 0.3)
			root.add_child(handle)
		"kettle":
			root.add_child(mesh_cylinder(0.09, 0.22, UIKit.CREAM_CARD))
			var lid := mesh_cylinder(0.07, 0.04, UIKit.DARK)
			lid.position.y = 0.22
			root.add_child(lid)
		"lights":
			var wire := mesh_box(Vector3(1.1, 0.02, 0.02), UIKit.DARK)
			wire.position.y = 0.12
			root.add_child(wire)
			for i in 5:
				var bulb := mesh_box(Vector3(0.06, 0.08, 0.06), UIKit.MUSTARD)
				bulb.position = Vector3(-0.4 + i * 0.2, 0.04, 0)
				root.add_child(bulb)
		"catbed":
			root.add_child(mesh_box(Vector3(0.48, 0.08, 0.38), UIKit.PINK))
			var rim := mesh_box(Vector3(0.48, 0.1, 0.06), UIKit.PINK.darkened(0.08))
			rim.position = Vector3(0, 0.04, -0.16)
			root.add_child(rim)
		"cattree":
			root.add_child(mesh_cylinder(0.22, 0.08, UIKit.CARD))
			var post := mesh_cylinder(0.05, 0.9, UIKit.WOOD)
			post.position.y = 0.08
			root.add_child(post)
			var perch := mesh_cylinder(0.18, 0.06, UIKit.SAGE)
			perch.position.y = 0.9
			root.add_child(perch)
		"cushion":
			root.add_child(mesh_box(Vector3(0.42, 0.12, 0.42), UIKit.PINK))
		"bowl":
			root.add_child(mesh_cylinder(0.09, 0.05, UIKit.PINK.lightened(0.1)))
		"clock":
			root.add_child(mesh_box(Vector3(0.22, 0.22, 0.08), UIKit.WOOD))
			var face := mesh_box(Vector3(0.16, 0.16, 0.02), UIKit.CREAM_CARD)
			face.position = Vector3(0, 0.02, 0.04)
			root.add_child(face)
		"tin":
			root.add_child(mesh_box(Vector3(0.32, 0.14, 0.2), UIKit.MUSTARD))
		"house":
			root.add_child(mesh_box(Vector3(0.22, 0.16, 0.18), UIKit.CREAM))
			var roof := mesh_box(Vector3(0.26, 0.08, 0.22), UIKit.TERRA)
			roof.position.y = 0.16
			root.add_child(roof)
		"part":
			root.add_child(mesh_box(Vector3(0.22, 0.06, 0.1), UIKit.DARK))
			var stripe := mesh_box(Vector3(0.08, 0.04, 0.12), UIKit.MUSTARD)
			stripe.position = Vector3(0.04, 0.06, 0)
			root.add_child(stripe)
		_:
			root.add_child(mesh_box(Vector3(0.3, 0.3, 0.3), UIKit.CARD))
	ensure_box_collision(root)
	return root


static func ensure_box_collision(root: Node3D) -> void:
	if root == null or root.get_node_or_null("PropCollision") != null:
		return
	var bounds := _merged_aabb(root, Transform3D.IDENTITY)
	if bounds.size.length() < 0.02:
		return
	var body := StaticBody3D.new()
	body.name = "PropCollision"
	body.collision_layer = LAYER_BLOCKING
	body.collision_mask = LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = bounds.size
	shape.shape = box
	shape.position = bounds.get_center()
	body.add_child(shape)
	root.add_child(body)


static func _merged_aabb(node: Node3D, parent_xform: Transform3D) -> AABB:
	var here := parent_xform * node.transform
	var merged := AABB()
	var has := false
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			merged = _transform_aabb(here, mesh_instance.mesh.get_aabb())
			has = true
	for child in node.get_children():
		if str(child.name) == "PropCollision" or not (child is Node3D):
			continue
		var sub := _merged_aabb(child as Node3D, here)
		if sub.size.length() < 0.001:
			continue
		if not has:
			merged = sub
			has = true
		else:
			merged = merged.merge(sub)
	return merged if has else AABB()


static func _transform_aabb(xform: Transform3D, box: AABB) -> AABB:
	var points: Array[Vector3] = [
		box.position,
		box.position + Vector3(box.size.x, 0, 0),
		box.position + Vector3(0, box.size.y, 0),
		box.position + Vector3(0, 0, box.size.z),
		box.position + Vector3(box.size.x, box.size.y, 0),
		box.position + Vector3(box.size.x, 0, box.size.z),
		box.position + Vector3(0, box.size.y, box.size.z),
		box.position + box.size,
	]
	var first := xform * points[0]
	var out := AABB(first, Vector3.ZERO)
	for point in points:
		out = out.expand(xform * point)
	return out


static func add_picker(root: Node3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_BLOCKING
	body.collision_mask = LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.2), maxf(size.y, 0.15), maxf(size.z, 0.2))
	shape.shape = box
	shape.position = Vector3(0, box.size.y * 0.5, 0)
	body.add_child(shape)
	root.add_child(body)


static func prepare(root: Node3D) -> void:
	if root == null or root.get_node_or_null("StructureCollision") != null:
		return
	var node_name := str(root.name)
	if node_name.begins_with("npc_"):
		_add_npc_capsule(root)
		return
	var kind := _structure_kind(node_name)
	if kind == "":
		return
	if kind == "pickable":
		if not _claim_colonly(root, LAYER_PICKABLE, 0, 0.0):
			_add_pickable_box(root)
		return
	var scale_half := WALL_BODY_HALF
	if _claim_colonly(root, LAYER_BLOCKING, LAYER_BLOCKING, scale_half):
		_stamp_wall(root, scale_half)
		return
	match _wall_style(node_name):
		"corner":
			_add_corner_boxes(root)
		"opening":
			_add_opening_collision(root)
		_:
			_add_straight_wall(root)
	_stamp_wall(root, scale_half)


static func _stamp_wall(root: Node3D, body_half: float) -> void:
	root.set_meta("body_half", body_half)
	root.set_meta("wall_thickness", body_half * 2.0)


static func _structure_kind(node_name: String) -> String:
	var lowered := node_name.to_lower()
	if lowered.begins_with("npc_"):
		return "npc"
	if "wall" in lowered or "corner" in lowered:
		return "wall"
	if "floor" in lowered or "tile" in lowered or "rug" in lowered or "stain" in lowered or "apron" in lowered:
		return "pickable"
	return ""


static func _wall_style(node_name: String) -> String:
	var lowered := node_name.to_lower()
	if "corner" in lowered:
		return "corner"
	if "garage" in lowered or "door" in lowered or "window" in lowered:
		return "opening"
	return "straight"


static func _is_colonly_name(node_name: String) -> bool:
	var lowered := node_name.to_lower()
	return lowered.ends_with("-colonly") or lowered.ends_with("_colonly") or lowered.contains("colonly")


static func _is_moving_piece(node_name: String) -> bool:
	return node_name == "GarageDoor" or node_name == "RollerHousing" or node_name == "DoorLeaf" or node_name.begins_with("Slat_")


static func _is_collision_name(node_name: String) -> bool:
	return node_name == "StructureCollision" or node_name == "DoorCollision" or node_name == "PropCollision"


static func _claim_colonly(root: Node3D, layer: int, mask: int, scale_half: float) -> bool:
	var meshes: Array[MeshInstance3D] = []
	var imported: Array[CollisionObject3D] = []
	_gather_colonly(root, root, meshes, imported)
	if not imported.is_empty():
		for body in imported:
			body.collision_layer = layer
			body.collision_mask = mask
		for mesh_node in meshes:
			mesh_node.visible = false
		return true
	if meshes.is_empty():
		return false
	var scale_z := 1.0
	if scale_half > 0.0:
		var half := 0.0
		for mesh_node in meshes:
			var bounds := _transform_aabb(_mesh_to_root(mesh_node, root), mesh_node.mesh.get_aabb())
			half = maxf(half, _z_half(bounds))
		root.set_meta("source_half_z", half)
		if half > 0.001 and half < 0.5:
			scale_z = scale_half / half
	var faces := PackedVector3Array()
	for mesh_node in meshes:
		mesh_node.visible = false
		_append_mesh_faces(mesh_node.mesh, _mesh_to_root(mesh_node, root), scale_z, faces)
	if faces.size() < 3:
		return false
	var body := _body(root, layer, mask, "StructureCollision")
	_add_trimesh(body, faces)
	return true


static func _gather_colonly(node: Node, root: Node3D, meshes: Array[MeshInstance3D], imported: Array[CollisionObject3D]) -> void:
	if node != root and _is_colonly_name(str(node.name)):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			meshes.append(node as MeshInstance3D)
		elif node is CollisionObject3D:
			imported.append(node as CollisionObject3D)
	for child in node.get_children():
		_gather_colonly(child, root, meshes, imported)


static func _add_pickable_box(root: Node3D) -> void:
	var bounds := _content_aabb(root)
	if bounds.size.length() < 0.01:
		return
	var body := _body(root, LAYER_PICKABLE, 0, "StructureCollision")
	_add_box(body, bounds.size, bounds.get_center())


static func _add_straight_wall(root: Node3D) -> void:
	var bounds := _content_aabb(root)
	if bounds.size.length() < 0.01:
		return
	root.set_meta("source_half_z", _z_half(bounds))
	var body := _body(root, LAYER_BLOCKING, LAYER_BLOCKING, "StructureCollision")
	var center := bounds.get_center()
	_add_box(body, Vector3(maxf(bounds.size.x, 0.05), maxf(bounds.size.y, 0.05), WALL_THICKNESS), Vector3(center.x, center.y, 0.0))


static func _add_corner_boxes(root: Node3D) -> void:
	var bounds := _content_aabb(root)
	if bounds.size.length() < 0.01:
		return
	var x0 := bounds.position.x
	var x1 := x0 + bounds.size.x
	var z0 := bounds.position.z
	var z1 := z0 + bounds.size.z
	var y0 := bounds.position.y
	var height := maxf(bounds.size.y, 0.05)
	var mid_y := y0 + height * 0.5
	root.set_meta("source_half_z", minf(minf(absf(x0), absf(x1)), minf(absf(z0), absf(z1))))
	var body := _body(root, LAYER_BLOCKING, LAYER_BLOCKING, "StructureCollision")
	if absf(x1) >= absf(x0):
		_add_box(body, Vector3(maxf(x1, 0.05), height, WALL_THICKNESS), Vector3(x1 * 0.5, mid_y, 0.0))
	else:
		_add_box(body, Vector3(maxf(-x0, 0.05), height, WALL_THICKNESS), Vector3(x0 * 0.5, mid_y, 0.0))
	if absf(z0) >= absf(z1):
		_add_box(body, Vector3(WALL_THICKNESS, height, maxf(-z0, 0.05)), Vector3(0.0, mid_y, z0 * 0.5))
	else:
		_add_box(body, Vector3(WALL_THICKNESS, height, maxf(z1, 0.05)), Vector3(0.0, mid_y, z1 * 0.5))


static func _add_opening_collision(root: Node3D) -> void:
	var meshes := _structural_meshes(root)
	var half := 0.0
	for mesh_node in meshes:
		var bounds := _transform_aabb(_mesh_to_root(mesh_node, root), mesh_node.mesh.get_aabb())
		half = maxf(half, _z_half(bounds))
	root.set_meta("source_half_z", half)
	var scale_z := 1.0 if half <= 0.001 else WALL_BODY_HALF / half
	var faces := PackedVector3Array()
	for mesh_node in meshes:
		_append_mesh_faces(mesh_node.mesh, _mesh_to_root(mesh_node, root), scale_z, faces)
	if faces.size() >= 3:
		var body := _body(root, LAYER_BLOCKING, LAYER_BLOCKING, "StructureCollision")
		_add_trimesh(body, faces)
	else:
		_add_straight_wall(root)
	_add_door_leaf(root)
	_add_garage_curtain(root)


static func _add_door_leaf(root: Node3D) -> void:
	var leaf := root.find_child("DoorLeaf", true, false) as Node3D
	if leaf == null or leaf.get_node_or_null("DoorCollision") != null:
		return
	var bounds := _subtree_aabb(leaf)
	if bounds.size.length() < 0.01:
		return
	var body := _body(leaf, LAYER_BLOCKING, LAYER_BLOCKING, "DoorCollision")
	_add_box(body, bounds.size, bounds.get_center())


static func _add_garage_curtain(root: Node3D) -> void:
	var door := root.find_child("GarageDoor", true, false) as Node3D
	if door == null or door.get_node_or_null("DoorCollision") != null:
		return
	var bounds := _subtree_aabb(door)
	if bounds.size.y < 0.05:
		return
	var center := bounds.get_center()
	var body := _body(door, LAYER_BLOCKING, LAYER_BLOCKING, "DoorCollision")
	_add_box(body, Vector3(maxf(bounds.size.x, 0.05), bounds.size.y, WALL_THICKNESS), Vector3(center.x, center.y, 0.0))


static func _add_npc_capsule(root: Node3D) -> void:
	var bounds := _content_aabb(root)
	var height := bounds.size.y if bounds.size.y > 0.3 else 1.7
	var radius := 0.28
	if bounds.size.x > 0.05 and bounds.size.z > 0.05:
		radius = clampf(minf(bounds.size.x, bounds.size.z) * 0.5, 0.12, 0.45)
	if height < radius * 2.0 + 0.02:
		height = radius * 2.0 + 0.02
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	capsule.margin = 0.001
	var body := _body(root, LAYER_BLOCKING, LAYER_BLOCKING, "StructureCollision")
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	if bounds.size.y > 0.3:
		shape.position = bounds.get_center()
	else:
		shape.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(shape)
	root.set_meta("npc_capsule", true)


static func _structural_meshes(root: Node3D) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var node_name := str(node.name)
		if node != root and (_is_moving_piece(node_name) or _is_collision_name(node_name) or _is_colonly_name(node_name)):
			continue
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			found.append(node as MeshInstance3D)
		for child in node.get_children():
			stack.append(child)
	return found


static func _content_aabb(root: Node3D) -> AABB:
	return _collect_aabb(root, true)


static func _subtree_aabb(root: Node3D) -> AABB:
	return _collect_aabb(root, false)


static func _collect_aabb(root: Node3D, skip_moving: bool) -> AABB:
	var merged := AABB()
	var has := false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var node_name := str(node.name)
		if node != root and (_is_collision_name(node_name) or (skip_moving and _is_moving_piece(node_name)) or _is_colonly_name(node_name)):
			continue
		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh != null:
				var box := _transform_aabb(_mesh_to_root(mesh_instance, root), mesh_instance.mesh.get_aabb())
				if not has:
					merged = box
					has = true
				else:
					merged = merged.merge(box)
		for child in node.get_children():
			stack.append(child)
	return merged if has else AABB()


static func _mesh_to_root(mesh_node: Node3D, root: Node3D) -> Transform3D:
	if mesh_node == root:
		return Transform3D.IDENTITY
	var xform := Transform3D.IDENTITY
	var current: Node = mesh_node
	while current != null and current != root:
		xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform


static func _append_mesh_faces(mesh: Mesh, xform: Transform3D, scale_z: float, into: PackedVector3Array) -> void:
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue
		var index_data: Variant = arrays[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		if index_data is PackedInt32Array:
			indices = index_data
		if indices.is_empty():
			var count := verts.size() - verts.size() % 3
			for i in count:
				var bare: Vector3 = xform * verts[i]
				bare.z *= scale_z
				into.append(bare)
		else:
			for index in indices:
				var point: Vector3 = xform * verts[index]
				point.z *= scale_z
				into.append(point)


static func _body(parent: Node, layer: int, mask: int, body_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = layer
	body.collision_mask = mask
	parent.add_child(body)
	return body


static func _add_box(body: StaticBody3D, size: Vector3, center: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.01), maxf(size.y, 0.01), maxf(size.z, 0.01))
	box.margin = 0.001
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = center
	body.add_child(shape)


static func _add_trimesh(body: StaticBody3D, faces: PackedVector3Array) -> void:
	var concave := ConcavePolygonShape3D.new()
	concave.margin = 0.001
	concave.set_faces(faces)
	var shape := CollisionShape3D.new()
	shape.shape = concave
	body.add_child(shape)


static func _z_half(bounds: AABB) -> float:
	var z0 := bounds.position.z
	var z1 := z0 + bounds.size.z
	return maxf(absf(z0), absf(z1))


static func play_clip(root: Node, clip: String, looping: bool) -> void:
	var player := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null or not player.has_animation(clip):
		return
	var anim := player.get_animation(clip)
	anim.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	player.play(clip)


static func attach_lamp_light(root: Node3D) -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.42, 0)
	light.light_color = Color("FFD7A1")
	light.light_energy = 0.4
	light.omni_range = 3.4
	light.shadow_enabled = false
	root.add_child(light)
