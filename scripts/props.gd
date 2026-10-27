class_name Props
extends RefCounted

const UIKit = preload("res://scripts/ui_kit.gd")

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
			var base: Material = mesh_instance.mesh.surface_get_material(i)
			if base == null:
				keep_material(mesh_instance, i, mat(Color("8E8276")))
				continue
			if not (base is StandardMaterial3D):
				continue
			var std := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			var luma := std.albedo_color.get_luminance()
			if luma > 0.72:
				std.albedo_color = Color("8E8276")
			elif luma > 0.42:
				std.albedo_color = Color("7A5C40")
			std.roughness = maxf(std.roughness, 0.88)
			keep_material(mesh_instance, i, std)


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
			var base: Material = mesh_instance.mesh.surface_get_material(i)
			if base == null:
				keep_material(mesh_instance, i, mat(UIKit.CARD))
				continue
			if not (base is StandardMaterial3D):
				continue
			var std := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			var color := std.albedo_color
			std.albedo_color = Color.from_hsv(0.075, clampf(color.s * 1.25 + 0.18, 0.0, 0.82), clampf(color.v, 0.42, 0.62))
			std.roughness = 0.84
			keep_material(mesh_instance, i, std)


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


static func keep_material(mesh_instance: MeshInstance3D, surface: int, material: Material) -> void:
	if mesh_instance == null or material == null or mesh_instance.mesh == null:
		return
	if not bool(mesh_instance.get_meta("material_mesh", false)):
		mesh_instance.mesh = mesh_instance.mesh.duplicate()
		mesh_instance.set_meta("material_mesh", true)
	mesh_instance.mesh.surface_set_material(surface, material)
	var kept: Array = []
	if mesh_instance.has_meta("kept_materials"):
		kept = mesh_instance.get_meta("kept_materials")
	kept.append(material)
	mesh_instance.set_meta("kept_materials", kept)


static func mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


static func material_count(root: Node) -> int:
	var ids := {}
	for mesh_instance in _mesh_instances(root):
		if mesh_instance.material_override != null:
			ids[mesh_instance.material_override.get_instance_id()] = true
			continue
		if mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(i)
			if material != null:
				ids[material.get_instance_id()] = true
	return ids.size()


static var _polished: Dictionary = {}


static func _polished_copy(base: StandardMaterial3D) -> StandardMaterial3D:
	# One polished twin per source material, so shared materials stay shared
	# and the two-material cap still holds.
	if base.has_meta("polished"):
		return base
	var key := base.get_instance_id()
	if _polished.has(key):
		return _polished[key]
	var copy := base.duplicate() as StandardMaterial3D
	copy.roughness = minf(copy.roughness, 0.62)
	copy.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	copy.metallic_specular = 0.3
	copy.set_meta("polished", true)
	_polished[key] = copy
	return copy


static func polish(root: Node) -> void:
	# Props pick up the room lights: a little specular, a little less chalk.
	if root == null:
		return
	for mesh_instance in _mesh_instances(root):
		var over := mesh_instance.material_override
		if over is StandardMaterial3D:
			mesh_instance.material_override = _polished_copy(over as StandardMaterial3D)
			continue
		if mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var base: Material = mesh_instance.get_surface_override_material(i)
			if base == null:
				base = mesh_instance.mesh.surface_get_material(i)
			if base is StandardMaterial3D:
				mesh_instance.set_surface_override_material(i, _polished_copy(base as StandardMaterial3D))


static func cap_prop_materials(root: Node, limit := 2) -> void:
	if root == null or limit < 1:
		return
	var uses: Array = []
	for mesh_instance in _mesh_instances(root):
		if mesh_instance.material_override != null:
			uses.append({
				"mesh": mesh_instance,
				"surface": -1,
				"material": mesh_instance.material_override,
				"weight": _mesh_weight(mesh_instance),
			})
			continue
		if mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			uses.append({
				"mesh": mesh_instance,
				"surface": i,
				"material": mesh_instance.mesh.surface_get_material(i),
				"weight": _surface_weight(mesh_instance.mesh, i),
			})
	if uses.is_empty():
		return
	var groups: Array = []
	for use in uses:
		var material: Material = use["material"]
		var key := _material_key(material)
		var slot := -1
		for index in groups.size():
			if str(groups[index]["key"]) == key:
				slot = index
				break
		if slot >= 0:
			groups[slot]["weight"] = float(groups[slot]["weight"]) + float(use["weight"])
		else:
			groups.append({
				"key": key,
				"weight": float(use["weight"]),
				"material": material,
				"color": _albedo_of(material),
			})
	groups.sort_custom(func(a, b): return float(a["weight"]) > float(b["weight"]))
	var keep_n := mini(limit, groups.size())
	var shared: Array = []
	var kept_keys: Array = []
	for index in keep_n:
		var source: Material = groups[index]["material"]
		var copy: Material = source.duplicate() if source != null else mat(UIKit.CARD)
		shared.append(copy)
		kept_keys.append(str(groups[index]["key"]))
	for use in uses:
		var material: Material = use["material"]
		var key := _material_key(material)
		var chosen: Material = shared[0]
		var kept := kept_keys.find(key)
		if kept >= 0:
			chosen = shared[kept]
		else:
			var color := _albedo_of(material)
			var best := 999.0
			for index in keep_n:
				var delta := _color_delta(color, groups[index]["color"])
				if delta < best:
					best = delta
					chosen = shared[index]
		var mesh_instance: MeshInstance3D = use["mesh"]
		var surface := int(use["surface"])
		if surface < 0:
			mesh_instance.material_override = chosen
		else:
			keep_material(mesh_instance, surface, chosen)


static func _mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		found.append(root)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		found.append(node)
	return found


static func _mesh_weight(mesh_instance: MeshInstance3D) -> float:
	if mesh_instance.mesh == null:
		return 1.0
	var weight := 0.0
	for i in mesh_instance.mesh.get_surface_count():
		weight += _surface_weight(mesh_instance.mesh, i)
	return maxf(weight, 1.0)


static func _surface_weight(mesh: Mesh, surface: int) -> float:
	var arrays: Array = mesh.surface_get_arrays(surface)
	if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
		return 1.0
	return maxf(float((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()), 1.0)


static func _material_key(material: Material) -> String:
	if material == null:
		return "null"
	if material is StandardMaterial3D:
		var std := material as StandardMaterial3D
		var tex := ""
		if std.albedo_texture != null:
			tex = str(std.albedo_texture.get_instance_id())
		var color := std.albedo_color
		return "%s|%d|%d|%d" % [tex, int(round(color.r * 32.0)), int(round(color.g * 32.0)), int(round(color.b * 32.0))]
	return "other|%d" % material.get_instance_id()


static func _albedo_of(material: Material) -> Color:
	if material is StandardMaterial3D:
		return (material as StandardMaterial3D).albedo_color
	return UIKit.CARD


static func _color_delta(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return dr * dr + dg * dg + db * db


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
	var node: Node3D
	if spec.begins_with("proc:"):
		node = _proc(spec.trim_prefix("proc:"))
	else:
		node = model(spec)
		if node == null:
			node = Node3D.new()
			node.add_child(mesh_box(Vector3(0.4, 0.3, 0.4), UIKit.CARD))
		ensure_box_collision(node)
		if "box" in spec:
			restyle_box(node)
	cap_prop_materials(node, 2)
	polish(node)
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
		"pitcher":
			var jug := mesh_cylinder(0.1, 0.26, Color("F2E27A"))
			root.add_child(jug)
			var rim := mesh_cylinder(0.105, 0.03, Color("DCE9EE"))
			rim.position.y = 0.26
			root.add_child(rim)
			var handle := mesh_box(Vector3(0.03, 0.14, 0.06), Color("DCE9EE"))
			handle.position = Vector3(0.12, 0.14, 0)
			root.add_child(handle)
			var lemon := mesh_cylinder(0.035, 0.012, Color("F7D040"))
			lemon.position = Vector3(0.0, 0.29, 0.06)
			root.add_child(lemon)
		"cup":
			for i in 3:
				var cup := mesh_cylinder(0.045 + i * 0.004, 0.08, UIKit.CREAM_CARD if i % 2 == 0 else Color("D9765F"))
				cup.position.y = i * 0.06
				root.add_child(cup)
		"glass":
			root.add_child(mesh_cylinder(0.04, 0.12, Color("F2E27A")))
			var straw := mesh_box(Vector3(0.012, 0.16, 0.012), Color("D9765F"))
			straw.position = Vector3(0.02, 0.06, 0)
			root.add_child(straw)
		"mug":
			root.add_child(mesh_cylinder(0.05, 0.1, UIKit.CREAM_CARD))
			var grip := mesh_box(Vector3(0.02, 0.06, 0.04), UIKit.CREAM_CARD)
			grip.position = Vector3(0.06, 0.05, 0)
			root.add_child(grip)
			var brew := mesh_cylinder(0.042, 0.01, Color("5A3B2A"))
			brew.position.y = 0.1
			root.add_child(brew)
		"bun":
			root.add_child(mesh_box(Vector3(0.12, 0.07, 0.1), Color("D9A866")))
			var seeds := mesh_box(Vector3(0.08, 0.012, 0.06), Color("F2DCB2"))
			seeds.position.y = 0.07
			root.add_child(seeds)
		"croissant":
			for i in 3:
				var crescent := mesh_box(Vector3(0.06, 0.05, 0.05), Color("D99A4E").lightened(i * 0.06))
				crescent.position = Vector3(-0.05 + i * 0.05, 0.0, absf(1 - i) * 0.03)
				crescent.rotation.y = (i - 1) * 0.5
				root.add_child(crescent)
		"sandwich":
			var bread_base := mesh_box(Vector3(0.14, 0.02, 0.12), Color("E0B570"))
			root.add_child(bread_base)
			var filling := mesh_box(Vector3(0.14, 0.03, 0.12), Color("7FB069"))
			filling.position.y = 0.02
			root.add_child(filling)
			var bacon := mesh_box(Vector3(0.15, 0.012, 0.05), Color("B5543A"))
			bacon.position = Vector3(0, 0.05, 0.02)
			root.add_child(bacon)
			var top := mesh_box(Vector3(0.14, 0.03, 0.12), Color("E0B570"))
			top.position.y = 0.065
			root.add_child(top)
		"wrap":
			var roll := mesh_cylinder(0.04, 0.17, Color("E7D7B8"))
			roll.rotation.z = 1.2
			roll.position.y = 0.05
			root.add_child(roll)
			var foil := mesh_cylinder(0.042, 0.09, Color("C9CED3"))
			foil.rotation.z = 1.2
			foil.position = Vector3(-0.04, 0.035, 0)
			root.add_child(foil)
			var greens := mesh_box(Vector3(0.03, 0.03, 0.05), Color("7FB069"))
			greens.position = Vector3(0.09, 0.07, 0)
			root.add_child(greens)
		"soup":
			root.add_child(mesh_cylinder(0.06, 0.09, Color("F4EFE6")))
			var broth := mesh_cylinder(0.052, 0.01, Color("D86B3A"))
			broth.position.y = 0.09
			root.add_child(broth)
			var spoon := mesh_box(Vector3(0.012, 0.12, 0.02), Color("C9CED3"))
			spoon.position = Vector3(0.03, 0.09, 0)
			spoon.rotation.z = -0.5
			root.add_child(spoon)
		"fries":
			var tray := mesh_box(Vector3(0.11, 0.08, 0.07), Color("D9534F"))
			tray.position.y = 0.04
			root.add_child(tray)
			for i in 5:
				var chip := mesh_box(Vector3(0.014, 0.11, 0.014), Color("F2C14E"))
				chip.position = Vector3(-0.035 + i * 0.017, 0.1, (i % 2) * 0.02 - 0.01)
				chip.rotation.z = (i - 2) * 0.12
				root.add_child(chip)
		"eggs":
			root.add_child(mesh_cylinder(0.1, 0.012, UIKit.CREAM_CARD))
			var muffin := mesh_cylinder(0.045, 0.03, Color("D9A866"))
			muffin.position.y = 0.012
			root.add_child(muffin)
			var egg := mesh_cylinder(0.04, 0.025, Color("F7F1E1"))
			egg.position.y = 0.042
			root.add_child(egg)
			var sauce := mesh_cylinder(0.032, 0.012, Color("F2C14E"))
			sauce.position.y = 0.067
			root.add_child(sauce)
		"steak":
			root.add_child(mesh_cylinder(0.11, 0.012, UIKit.CREAM_CARD))
			var cut := mesh_box(Vector3(0.09, 0.03, 0.06), Color("7A3B2E"))
			cut.position = Vector3(-0.03, 0.027, 0)
			root.add_child(cut)
			for i in 4:
				var chip := mesh_box(Vector3(0.012, 0.012, 0.07), Color("F2C14E"))
				chip.position = Vector3(0.04 + i * 0.014, 0.018, 0)
				root.add_child(chip)
		"tasting":
			root.add_child(mesh_cylinder(0.12, 0.012, UIKit.DARK))
			for i in 3:
				var morsel := mesh_cylinder(0.02, 0.025, [Color("E07A5F"), Color("81B29A"), Color("F2CC8F")][i])
				morsel.position = Vector3(-0.06 + i * 0.06, 0.012, 0)
				root.add_child(morsel)
			var smear := mesh_box(Vector3(0.14, 0.004, 0.02), Color("3D405B"))
			smear.position = Vector3(0, 0.012, 0.05)
			root.add_child(smear)
		"brulee":
			var dish := mesh_cylinder(0.055, 0.04, Color("F4EFE6"))
			root.add_child(dish)
			var sugar := mesh_cylinder(0.05, 0.008, Color("B8732F"))
			sugar.position.y = 0.04
			root.add_child(sugar)
			var berry := mesh_cylinder(0.012, 0.015, Color("B5343E"))
			berry.position = Vector3(0.02, 0.048, 0)
			root.add_child(berry)
		"latte":
			root.add_child(mesh_cylinder(0.05, 0.1, UIKit.CREAM_CARD))
			var grip := mesh_box(Vector3(0.02, 0.06, 0.04), UIKit.CREAM_CARD)
			grip.position = Vector3(0.06, 0.05, 0)
			root.add_child(grip)
			var foam := mesh_cylinder(0.042, 0.012, Color("E9DCC7"))
			foam.position.y = 0.1
			root.add_child(foam)
			var leaf := mesh_box(Vector3(0.012, 0.004, 0.04), Color("8A5A3C"))
			leaf.position.y = 0.112
			root.add_child(leaf)
		"espresso":
			root.add_child(mesh_cylinder(0.03, 0.055, UIKit.CREAM_CARD))
			var crema := mesh_cylinder(0.025, 0.008, Color("A86B3C"))
			crema.position.y = 0.055
			root.add_child(crema)
			var saucer := mesh_cylinder(0.055, 0.006, UIKit.CREAM_CARD)
			root.add_child(saucer)
		"teacup":
			root.add_child(mesh_cylinder(0.045, 0.06, Color("DCE9EE")))
			var tea := mesh_cylinder(0.04, 0.008, Color("B9814A"))
			tea.position.y = 0.06
			root.add_child(tea)
			var tag := mesh_box(Vector3(0.02, 0.025, 0.004), UIKit.TERRA)
			tag.position = Vector3(0.05, 0.03, 0)
			root.add_child(tag)
		"coldbrew":
			root.add_child(mesh_cylinder(0.04, 0.13, Color("4A2E1E")))
			var ice := mesh_box(Vector3(0.03, 0.03, 0.03), Color("DCE9EE"))
			ice.position = Vector3(0.0, 0.11, 0.0)
			root.add_child(ice)
			var straw := mesh_box(Vector3(0.012, 0.17, 0.012), UIKit.DARK)
			straw.position = Vector3(0.02, 0.07, 0)
			root.add_child(straw)
		"affogato":
			root.add_child(mesh_cylinder(0.045, 0.07, Color("DCE9EE")))
			var scoop := mesh_cylinder(0.035, 0.035, Color("F7F1E1"))
			scoop.position.y = 0.07
			root.add_child(scoop)
			var shot := mesh_cylinder(0.038, 0.012, Color("5A3B2A"))
			shot.position.y = 0.1
			root.add_child(shot)
		"book":
			root.add_child(mesh_box(Vector3(0.14, 0.03, 0.1), UIKit.BLUE))
			var pages := mesh_box(Vector3(0.13, 0.022, 0.09), UIKit.CREAM_CARD)
			pages.position = Vector3(0.008, 0.004, 0)
			root.add_child(pages)
		"pencil":
			var stick := mesh_cylinder(0.008, 0.18, UIKit.MUSTARD)
			stick.rotation.z = 1.2
			stick.position.y = 0.02
			root.add_child(stick)
			var tip := mesh_cylinder(0.006, 0.02, Color("E7C9A8"))
			tip.rotation.z = 1.2
			tip.position = Vector3(0.095, 0.055, 0)
			root.add_child(tip)
		"cutting":
			root.add_child(mesh_cylinder(0.035, 0.05, UIKit.TERRA))
			for i in 3:
				var leaf := mesh_box(Vector3(0.02, 0.06, 0.006), UIKit.SAGE)
				leaf.position = Vector3(0, 0.08, 0)
				leaf.rotation.y = i * 2.1
				leaf.rotation.z = 0.4
				root.add_child(leaf)
		"aframe":
			for side in [-1.0, 1.0]:
				var board := mesh_box(Vector3(0.6, 0.9, 0.03), UIKit.CREAM_CARD)
				board.position = Vector3(0, 0, side * 0.16)
				board.rotation.x = side * 0.32
				root.add_child(board)
				var panel := mesh_box(Vector3(0.5, 0.5, 0.012), Color("3E3A4F"))
				panel.position = Vector3(0, 0.28, side * 0.33)
				panel.rotation.x = side * 0.32
				root.add_child(panel)
		"part":
			root.add_child(mesh_box(Vector3(0.22, 0.06, 0.1), UIKit.DARK))
			var stripe := mesh_box(Vector3(0.08, 0.04, 0.12), UIKit.MUSTARD)
			stripe.position = Vector3(0.04, 0.06, 0)
			root.add_child(stripe)
		_:
			root.add_child(mesh_box(Vector3(0.3, 0.3, 0.3), UIKit.CARD))
	ensure_box_collision(root)
	return root


static func content_aabb(node: Node3D) -> AABB:
	if node == null:
		return AABB()
	return _merged_aabb(node, Transform3D.IDENTITY)


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
	body.name = "Picker"
	body.collision_layer = LAYER_PICKABLE
	body.collision_mask = 0
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
	light.name = "LampLight"
	light.position = Vector3(0, 0.42, 0)
	light.light_color = Color("FFD9A0")
	light.light_energy = 0.8
	light.omni_range = 2.5
	light.shadow_enabled = false
	root.add_child(light)
	_glow_shade(root)


static func _glow_shade(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var current: Material = mesh_node.get_active_material(0)
		var shade := StandardMaterial3D.new()
		if current is StandardMaterial3D:
			shade = (current as StandardMaterial3D).duplicate() as StandardMaterial3D
		shade.emission_enabled = true
		shade.emission = Color("FFD9A0")
		shade.emission_energy_multiplier = 1.2
		mesh_node.material_override = shade
	for child in node.get_children():
		_glow_shade(child)
