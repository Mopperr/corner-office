class_name Props
extends RefCounted

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
	body.collision_layer = 1
	body.collision_mask = 1
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
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.2), maxf(size.y, 0.15), maxf(size.z, 0.2))
	shape.shape = box
	shape.position = Vector3(0, box.size.y * 0.5, 0)
	body.add_child(shape)
	root.add_child(body)


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
