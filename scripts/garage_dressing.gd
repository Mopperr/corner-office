extends RefCounted
# Dresses the garage so it reads as somebody's workshop rather than a shed:
# a workbench with a pegboard of tools, paint tins, beams with string lights,
# a cork board, a bike, archive boxes, a broom, bins, a door mat, and warm
# light through the window. Everything here is scenery. Only the workbench
# has collision, so a mug can be set on it like any other surface.

const Props = preload("res://scripts/props.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

const CONCRETE_LINE := Color("8A7E6E")
const SKIRT := Color("5C4632")
const BENCH_TOP := Color("B98A5A")
const BENCH_BODY := Color("5F7D74")
const DRAWER := Color("6E8C83")
const STEEL := Color("A9ABB0")
const RUBBER := Color("4A4745")
const CORK := Color("C99A62")
const TIN_RED := Color("C95E4A")
const TIN_BLUE := Color("5F8FB0")
const TIN_WHITE := Color("EDE5D6")
const BULB := Color("FFE2A8")
const WIRE := Color("3B3734")
const BIKE := Color("D66A4F")
const PAPER := Color("F4ECDD")


static func build(parent: Node3D, venue: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "GarageDressing"
	parent.add_child(root)
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	_floor_finish(root, x, z, w, d)
	_floor_lines(root, x, z, w, d)
	_rug(root, Vector3(x + 3.0, 0.0, z + 4.1))
	_skirting(root, x, z, w, d)
	_workbench(root, Vector3(x + 0.42, 0.0, z + 6.0))
	_pegboard(root, Vector3(x + 0.1, 1.45, z + 6.0))
	_cork_board(root, Vector3(x + 1.5, 2.0, z + 0.1))
	# No rafters: the lights swag from the back corner, wall top to wall top.
	_string_lights(root, Vector3(x + 0.2, 2.5, z + 0.9), Vector3(x + 1.95, 2.5, z + 0.2))
	_string_lights(root, Vector3(x + 0.2, 2.55, z + 3.4), Vector3(x + 0.2, 2.55, z + 7.6))
	_pendant(root, Vector3(x + 1.0, 2.75, z + 6.0))
	_window_light(root, Vector3(x - 0.2, 2.3, z + 2.0), Vector3(x + 1.7, 0.0, z + 2.6))
	_sun_patch(root, Vector3(x + 1.35, 0.004, z + 2.5))
	_bike(root, Vector3(x + 4.3, 0.0, z + d - 0.42))
	_box_stack(root, Vector3(x + 0.62, 0.0, z + d - 0.55))
	_broom(root, Vector3(x + 0.3, 0.0, z + 1.05))
	_bin(root, Vector3(x + 0.78, 0.0, z + 0.95))
	_door_mat(root, Vector3(x + 3.5, 0.0, z + 0.42))
	# Both planters sit on the open side of the door, where the camera can see them.
	_planter(root, Vector3(x + 5.85, 0.0, z - 0.45))
	_planter(root, Vector3(x + w + 0.45, 0.0, z + 0.9))
	return root


static func _add(root: Node3D, mesh_instance: MeshInstance3D, at: Vector3, rot_y := 0.0) -> MeshInstance3D:
	mesh_instance.position += at
	mesh_instance.rotation.y = deg_to_rad(rot_y)
	root.add_child(mesh_instance)
	return mesh_instance


static func _floor_finish(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	# Sealed concrete with a soft sheen, a darker painted zone by the bench,
	# and a pale walkway from the door to the desk.
	var slab := Props.mesh_box(Vector3(w - 0.08, 0.012, d - 0.08), Color("CFC3B2"))
	var sheen := Props.mat(Color("CFC3B2"))
	sheen.roughness = 0.45
	sheen.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	sheen.metallic_specular = 0.35
	slab.material_override = sheen
	slab.position = Vector3(x + w * 0.5, 0.0, z + d * 0.5)
	root.add_child(slab)
	var zone := Props.mesh_box(Vector3(1.9, 0.004, 3.0), Color("B9AE9C"))
	zone.position = Vector3(x + 1.0, 0.012, z + 6.0)
	root.add_child(zone)
	var walk := Props.mesh_box(Vector3(1.6, 0.004, 3.4), Color("D9CFBF"))
	walk.position = Vector3(x + 3.5, 0.012, z + 1.9)
	root.add_child(walk)


static func _rug(root: Node3D, at: Vector3) -> void:
	# A woven rug: border, field, and three stripes.
	var border := Props.mesh_box(Vector3(2.6, 0.014, 1.9), Color("A8563F"))
	border.position = at + Vector3(0, 0.012, 0)
	root.add_child(border)
	var field := Props.mesh_box(Vector3(2.3, 0.006, 1.6), Color("D9A866"))
	field.position = at + Vector3(0, 0.026, 0)
	root.add_child(field)
	for i in 3:
		var stripe := Props.mesh_box(Vector3(2.3, 0.004, 0.12), [Color("A8563F"), Color("E8B4A8"), Color("8FAF7E")][i])
		stripe.position = at + Vector3(0, 0.032, -0.5 + i * 0.5)
		root.add_child(stripe)
	for side in [-1.0, 1.0]:
		for k in 9:
			var tassel := Props.mesh_box(Vector3(0.05, 0.008, 0.1), Color("E9DCC4"))
			tassel.position = at + Vector3(side * 1.34, 0.012, -0.8 + k * 0.2)
			root.add_child(tassel)


static func _floor_lines(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	# Expansion joints in the slab. Thin, no collision, just enough to break up the floor.
	var xx := x + 2.0
	while xx < x + w - 0.5:
		_add(root, Props.mesh_box(Vector3(0.02, 0.004, d - 0.3), CONCRETE_LINE), Vector3(xx, 0.014, z + d * 0.5))
		xx += 2.0
	var zz := z + 2.0
	while zz < z + d - 0.5:
		_add(root, Props.mesh_box(Vector3(w - 0.3, 0.004, 0.02), CONCRETE_LINE), Vector3(x + w * 0.5, 0.014, zz))
		zz += 2.0
	# A rubber mat in front of the bench.
	_add(root, Props.mesh_box(Vector3(1.0, 0.012, 2.0), RUBBER), Vector3(x + 1.25, 0.014, z + 6.0))


static func _skirting(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	_add(root, Props.mesh_box(Vector3(0.05, 0.11, d - 0.4), SKIRT), Vector3(x + 0.05, 0.0, z + d * 0.5))
	_add(root, Props.mesh_box(Vector3(1.6, 0.11, 0.05), SKIRT), Vector3(x + 1.2, 0.0, z + 0.05))
	_add(root, Props.mesh_box(Vector3(1.0, 0.11, 0.05), SKIRT), Vector3(x + w - 0.5, 0.0, z + 0.05))


static func _workbench(root: Node3D, at: Vector3) -> void:
	var bench := Node3D.new()
	bench.name = "Workbench"
	bench.position = at
	bench.set_meta("uid", "workbench")
	root.add_child(bench)
	var top := Props.mesh_box(Vector3(0.64, 0.06, 1.8), BENCH_TOP)
	top.position.y = 0.88
	bench.add_child(top)
	var lip := Props.mesh_box(Vector3(0.64, 0.03, 1.8), BENCH_TOP.darkened(0.2))
	lip.position.y = 0.85
	bench.add_child(lip)
	for side in [-0.62, 0.62]:
		var cabinet := Props.mesh_box(Vector3(0.56, 0.82, 0.5), BENCH_BODY)
		cabinet.position = Vector3(0.0, 0.03, side)
		bench.add_child(cabinet)
		for row in 3:
			var front := Props.mesh_box(Vector3(0.03, 0.2, 0.42), DRAWER)
			front.position = Vector3(0.29, 0.1 + row * 0.26, side)
			bench.add_child(front)
			var pull := Props.mesh_box(Vector3(0.02, 0.03, 0.12), STEEL)
			pull.position = Vector3(0.31, 0.19 + row * 0.26, side)
			bench.add_child(pull)
	var shelf := Props.mesh_box(Vector3(0.5, 0.03, 0.5), BENCH_TOP.darkened(0.1))
	shelf.position = Vector3(0.0, 0.3, 0.0)
	bench.add_child(shelf)
	var body := StaticBody3D.new()
	body.name = "BenchBody"
	body.collision_layer = Props.LAYER_BLOCKING
	body.collision_mask = Props.LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.64, 0.94, 1.8)
	shape.shape = box
	shape.position = Vector3(0.0, 0.47, 0.0)
	body.add_child(shape)
	bench.add_child(body)
	# Things on the bench.
	_tin(bench, Vector3(0.08, 0.94, -0.62), 0.09, 0.2, TIN_RED)
	_tin(bench, Vector3(0.18, 0.94, -0.46), 0.075, 0.16, TIN_WHITE)
	_tin(bench, Vector3(-0.1, 0.94, -0.52), 0.07, 0.14, TIN_BLUE)
	_toolbox(bench, Vector3(-0.02, 0.94, 0.12))
	_jar(bench, Vector3(0.16, 0.94, 0.62))
	_rope(bench, Vector3(-0.14, 0.94, 0.58))
	var radio := Props.model("cb_radio")
	if radio:
		radio.position = Vector3(-0.05, 0.94, -0.12)
		radio.rotation.y = deg_to_rad(96)
		Props.cap_prop_materials(radio, 2)
		bench.add_child(radio)
	var thermos := Props.model("thermos_dented")
	if thermos:
		thermos.position = Vector3(0.2, 0.94, 0.36)
		Props.cap_prop_materials(thermos, 2)
		bench.add_child(thermos)
	var stool := Props.mesh_cylinder(0.16, 0.05, BENCH_TOP)
	stool.position = Vector3(0.95, 0.52, 0.55)
	bench.add_child(stool)
	for leg in [Vector2(-0.1, -0.1), Vector2(0.1, -0.1), Vector2(-0.1, 0.1), Vector2(0.1, 0.1)]:
		var post := Props.mesh_cylinder(0.018, 0.52, STEEL)
		post.position = Vector3(0.95 + leg.x, 0.0, 0.55 + leg.y)
		bench.add_child(post)


static func _tin(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> void:
	var tin := Props.mesh_cylinder(radius, height, color)
	tin.position += at
	parent.add_child(tin)
	var lid := Props.mesh_cylinder(radius * 0.92, 0.012, STEEL)
	lid.position = at + Vector3(0.0, height, 0.0)
	parent.add_child(lid)


static func _toolbox(parent: Node3D, at: Vector3) -> void:
	var box := Props.mesh_box(Vector3(0.22, 0.14, 0.38), TIN_RED.darkened(0.15))
	box.position += at
	parent.add_child(box)
	var lid := Props.mesh_box(Vector3(0.23, 0.03, 0.39), TIN_RED.darkened(0.3))
	lid.position = at + Vector3(0.0, 0.14, 0.0)
	parent.add_child(lid)
	var handle := Props.mesh_box(Vector3(0.03, 0.05, 0.16), STEEL)
	handle.position = at + Vector3(0.0, 0.17, 0.0)
	parent.add_child(handle)


static func _jar(parent: Node3D, at: Vector3) -> void:
	var jar := Props.mesh_cylinder(0.055, 0.14, Color("DCE9EE"))
	jar.position += at
	parent.add_child(jar)
	for i in 4:
		var brush := Props.mesh_box(Vector3(0.014, 0.24, 0.014), [UIKit.WOOD, UIKit.DARK, TIN_BLUE, TIN_RED][i])
		brush.position = at + Vector3(-0.025 + (i % 2) * 0.05, 0.05, -0.025 + (i / 2) * 0.05)
		brush.rotation.z = deg_to_rad(-6 + i * 4)
		parent.add_child(brush)


static func _rope(parent: Node3D, at: Vector3) -> void:
	var coil := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.06
	torus.outer_radius = 0.11
	torus.rings = 16
	torus.ring_segments = 8
	coil.mesh = torus
	coil.material_override = Props.mat(Color("D8C39A"))
	coil.position = at + Vector3(0.0, 0.025, 0.0)
	parent.add_child(coil)


static func _pegboard(root: Node3D, at: Vector3) -> void:
	var board := Node3D.new()
	board.name = "Pegboard"
	board.position = at
	root.add_child(board)
	var back := Props.mesh_box(Vector3(0.04, 0.9, 1.7), Color("D9B98A"))
	back.position.y = -0.45
	board.add_child(back)
	var frame := Props.mesh_box(Vector3(0.05, 0.94, 1.74), SKIRT)
	frame.position = Vector3(-0.01, -0.47, 0.0)
	board.add_child(frame)
	# Hammer.
	_tool(board, Vector3(0.05, 0.0, -0.6), [[Vector3(0.03, 0.34, 0.03), UIKit.WOOD, Vector3(0, -0.17, 0)], [Vector3(0.05, 0.08, 0.14), UIKit.DARK, Vector3(0, 0.06, 0)]])
	# Wrench.
	_tool(board, Vector3(0.05, 0.05, -0.3), [[Vector3(0.02, 0.3, 0.05), STEEL, Vector3(0, -0.15, 0)], [Vector3(0.025, 0.09, 0.1), STEEL, Vector3(0, 0.02, 0)]])
	# Saw.
	_tool(board, Vector3(0.05, -0.1, 0.1), [[Vector3(0.015, 0.14, 0.42), STEEL, Vector3(0, -0.07, 0.1)], [Vector3(0.03, 0.12, 0.1), UIKit.WOOD, Vector3(0, -0.04, -0.18)]])
	# Tape measure and a level.
	var tape := Props.mesh_cylinder(0.05, 0.03, UIKit.MUSTARD)
	tape.position = Vector3(0.06, -0.15, 0.48)
	tape.rotation.z = deg_to_rad(90)
	board.add_child(tape)
	var level := Props.mesh_box(Vector3(0.03, 0.05, 0.5), UIKit.MUSTARD)
	level.position = Vector3(0.05, -0.55, 0.42)
	board.add_child(level)
	# Pliers and a screwdriver row.
	for i in 3:
		var driver := Props.mesh_box(Vector3(0.02, 0.16, 0.02), [TIN_RED, TIN_BLUE, UIKit.DARK][i])
		driver.position = Vector3(0.05, -0.62, -0.62 + i * 0.1)
		board.add_child(driver)
		var tip := Props.mesh_box(Vector3(0.01, 0.1, 0.01), STEEL)
		tip.position = Vector3(0.05, -0.72, -0.62 + i * 0.1)
		board.add_child(tip)


static func _tool(parent: Node3D, at: Vector3, parts: Array) -> void:
	for part in parts:
		var piece := Props.mesh_box(part[0], part[1])
		piece.position = at + part[2]
		parent.add_child(piece)


static func _cork_board(root: Node3D, at: Vector3) -> void:
	var board := Node3D.new()
	board.name = "CorkBoard"
	board.position = at
	root.add_child(board)
	var cork := Props.mesh_box(Vector3(0.8, 0.56, 0.03), CORK)
	cork.position.y = -0.28
	board.add_child(cork)
	var frame := Props.mesh_box(Vector3(0.84, 0.6, 0.025), SKIRT)
	frame.position = Vector3(0.0, -0.3, -0.004)
	board.add_child(frame)
	var notes: Array = [
		[Vector3(-0.26, 0.1, 0.02), UIKit.MUSTARD, 5.0], [Vector3(-0.02, 0.12, 0.02), Color("E8B4A8"), -4.0],
		[Vector3(0.24, 0.08, 0.02), UIKit.SAGE, 7.0], [Vector3(-0.2, -0.16, 0.02), PAPER, -3.0],
		[Vector3(0.1, -0.18, 0.02), PAPER, 2.0],
	]
	for note in notes:
		var paper := Props.mesh_box(Vector3(0.16, 0.16, 0.006), note[1])
		paper.position = note[0] + Vector3(0, -0.36, 0)
		paper.rotation.z = deg_to_rad(float(note[2]))
		board.add_child(paper)
		var pin := Props.mesh_cylinder(0.012, 0.012, TIN_RED)
		pin.position = note[0] + Vector3(0.0, -0.21, 0.01)
		pin.rotation.x = deg_to_rad(90)
		board.add_child(pin)
	var photo := Props.mesh_box(Vector3(0.14, 0.11, 0.006), UIKit.BLUE)
	photo.position = Vector3(0.28, -0.52, 0.02)
	board.add_child(photo)


static func _string_lights(root: Node3D, from: Vector3, to: Vector3) -> void:
	var span := to - from
	var length := span.length()
	var wire := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.018, 0.018, length)
	wire.mesh = mesh
	wire.material_override = Props.mat(WIRE)
	wire.position = from + span * 0.5
	wire.look_at_from_position(wire.position, to, Vector3.UP)
	root.add_child(wire)
	var count := int(length / 0.55)
	for i in range(1, count):
		var t := float(i) / float(count)
		var sag := sin(t * PI) * 0.18
		var at := from.lerp(to, t) - Vector3(0.0, sag, 0.0)
		var drop := Props.mesh_box(Vector3(0.012, 0.08, 0.012), WIRE)
		drop.position = at - Vector3(0.0, 0.0, 0.0)
		drop.position.y = at.y - 0.08
		root.add_child(drop)
		var bulb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.045
		sphere.height = 0.09
		sphere.radial_segments = 8
		sphere.rings = 4
		bulb.mesh = sphere
		var glow := Props.mat(BULB)
		glow.emission_enabled = true
		glow.emission = BULB
		glow.emission_energy_multiplier = 1.6
		bulb.material_override = glow
		bulb.position = at - Vector3(0.0, 0.12, 0.0)
		root.add_child(bulb)
		if i % 2 == 1:
			var light := OmniLight3D.new()
			light.position = bulb.position
			light.light_color = Color("FFD79A")
			light.light_energy = 0.22
			light.omni_range = 2.6
			light.shadow_enabled = false
			root.add_child(light)


static func _pendant(root: Node3D, at: Vector3) -> void:
	var ceiling := 3.0
	var bottom := at.y - 0.7
	var cord := Props.mesh_box(Vector3(0.012, ceiling - bottom, 0.012), WIRE)
	cord.position = Vector3(at.x, (ceiling + bottom) * 0.5, at.z)
	root.add_child(cord)
	var rose := Props.mesh_cylinder(0.07, 0.03, WIRE)
	rose.position = Vector3(at.x, ceiling - 0.015, at.z)
	root.add_child(rose)
	var shade := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.2
	cone.height = 0.16
	cone.radial_segments = 12
	shade.mesh = cone
	shade.material_override = Props.mat(Color("3E5A52"))
	shade.position = at - Vector3(0.0, 0.78, 0.0)
	root.add_child(shade)
	var bulb := Props.mesh_cylinder(0.035, 0.05, BULB)
	var glow := Props.mat(BULB)
	glow.emission_enabled = true
	glow.emission = BULB
	glow.emission_energy_multiplier = 1.4
	bulb.material_override = glow
	bulb.position = at - Vector3(0.0, 0.9, 0.0)
	root.add_child(bulb)
	var light := OmniLight3D.new()
	light.name = "BenchLight"
	light.position = at - Vector3(0.0, 0.95, 0.0)
	light.light_color = Color("FFCF92")
	light.light_energy = 0.75
	light.omni_range = 3.6
	light.shadow_enabled = true
	light.shadow_blur = 2.0
	root.add_child(light)


static func _window_light(root: Node3D, at: Vector3, target: Vector3) -> void:
	var spot := SpotLight3D.new()
	spot.name = "WindowLight"
	spot.position = at
	spot.light_color = Color("FFEBCB")
	spot.light_energy = 1.1
	spot.spot_range = 7.0
	spot.spot_angle = 30.0
	spot.spot_angle_attenuation = 0.8
	spot.shadow_enabled = false
	root.add_child(spot)
	spot.look_at_from_position(at, target, Vector3.UP)


static func _sun_patch(root: Node3D, at: Vector3) -> void:
	var patch := Props.mesh_box(Vector3(1.4, 0.002, 1.1), Color("FFF1D2"))
	var glow := Props.mat(Color("FFF1D2", 0.28))
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	patch.material_override = glow
	patch.position = at
	patch.rotation.y = deg_to_rad(-18)
	root.add_child(patch)


static func _bike(root: Node3D, at: Vector3) -> void:
	var bike := Node3D.new()
	bike.name = "Bike"
	bike.position = at
	bike.rotation.z = deg_to_rad(8)
	root.add_child(bike)
	for wx in [-0.52, 0.52]:
		var wheel := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.28
		torus.outer_radius = 0.33
		torus.rings = 20
		torus.ring_segments = 8
		wheel.mesh = torus
		wheel.material_override = Props.mat(UIKit.DARK)
		wheel.position = Vector3(wx, 0.33, 0.0)
		wheel.rotation.x = deg_to_rad(90)
		bike.add_child(wheel)
		var hub := Props.mesh_cylinder(0.05, 0.04, STEEL)
		hub.position = Vector3(wx, 0.31, 0.0)
		hub.rotation.x = deg_to_rad(90)
		bike.add_child(hub)
	var tubes: Array = [
		[Vector3(0.0, 0.62, 0.0), Vector3(0.95, 0.03, 0.03), 0.0],
		[Vector3(-0.26, 0.45, 0.0), Vector3(0.03, 0.4, 0.03), 0.0],
		[Vector3(0.1, 0.42, 0.0), Vector3(0.03, 0.46, 0.03), -32.0],
		[Vector3(-0.1, 0.36, 0.0), Vector3(0.03, 0.4, 0.03), 36.0],
		[Vector3(0.42, 0.52, 0.0), Vector3(0.03, 0.5, 0.03), 18.0],
	]
	for tube in tubes:
		var part := Props.mesh_box(tube[1], BIKE)
		part.position = tube[0] - Vector3(0.0, float(tube[1].y) * 0.5, 0.0)
		part.rotation.z = deg_to_rad(float(tube[2]))
		bike.add_child(part)
	var saddle := Props.mesh_box(Vector3(0.22, 0.05, 0.08), UIKit.DARK)
	saddle.position = Vector3(-0.28, 0.7, 0.0)
	bike.add_child(saddle)
	var bars := Props.mesh_box(Vector3(0.04, 0.03, 0.44), UIKit.DARK)
	bars.position = Vector3(0.5, 0.78, 0.0)
	bike.add_child(bars)
	var basket := Props.mesh_box(Vector3(0.2, 0.16, 0.26), Color("D8C39A"))
	basket.position = Vector3(0.62, 0.6, 0.0)
	bike.add_child(basket)


static func _box_stack(root: Node3D, at: Vector3) -> void:
	var sizes: Array = [Vector3(0.52, 0.34, 0.44), Vector3(0.46, 0.3, 0.4), Vector3(0.36, 0.26, 0.34)]
	var y := 0.0
	for i in sizes.size():
		var size: Vector3 = sizes[i]
		var box := Props.mesh_box(size, [Color("C9A47A"), Color("D2AE86"), Color("BE9A70")][i])
		box.position = at + Vector3((i % 2) * 0.03, y, (i % 2) * -0.02)
		box.rotation.y = deg_to_rad(-6.0 + i * 9.0)
		root.add_child(box)
		var tape := Props.mesh_box(Vector3(size.x + 0.01, 0.012, 0.06), Color("B98451"))
		tape.position = box.position + Vector3(0.0, size.y, 0.0)
		tape.rotation.y = box.rotation.y
		root.add_child(tape)
		var tag := Props.mesh_box(Vector3(0.12, 0.08, 0.004), PAPER)
		tag.position = box.position + Vector3(size.x * 0.18, size.y * 0.5, size.z * 0.5 + 0.004)
		tag.rotation.y = box.rotation.y
		root.add_child(tag)
		y += size.y


static func _broom(root: Node3D, at: Vector3) -> void:
	var broom := Node3D.new()
	broom.position = at
	broom.rotation.z = deg_to_rad(-9)
	broom.rotation.x = deg_to_rad(6)
	root.add_child(broom)
	var handle := Props.mesh_cylinder(0.014, 1.3, UIKit.WOOD)
	handle.position.y = 0.2
	broom.add_child(handle)
	var head := Props.mesh_box(Vector3(0.08, 0.2, 0.28), Color("D8B96A"))
	broom.add_child(head)
	var band := Props.mesh_box(Vector3(0.09, 0.04, 0.29), UIKit.DARK)
	band.position.y = 0.18
	broom.add_child(band)


static func _bin(root: Node3D, at: Vector3) -> void:
	var bin := Props.mesh_cylinder(0.2, 0.58, STEEL)
	bin.position += at
	root.add_child(bin)
	var rim := Props.mesh_cylinder(0.21, 0.03, STEEL.darkened(0.2))
	rim.position = at + Vector3(0.0, 0.58, 0.0)
	root.add_child(rim)
	var bag := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.17
	sphere.height = 0.2
	sphere.radial_segments = 10
	sphere.rings = 4
	bag.mesh = sphere
	bag.material_override = Props.mat(UIKit.DARK)
	bag.position = at + Vector3(0.0, 0.62, 0.0)
	root.add_child(bag)


static func _door_mat(root: Node3D, at: Vector3) -> void:
	var mat := Props.mesh_box(Vector3(1.3, 0.016, 0.7), Color("6E5A44"))
	mat.position += at
	root.add_child(mat)
	var inner := Props.mesh_box(Vector3(1.1, 0.018, 0.5), Color("8A7358"))
	inner.position += at
	root.add_child(inner)


static func _planter(root: Node3D, at: Vector3) -> void:
	var pot := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.26
	cone.bottom_radius = 0.2
	cone.height = 0.42
	cone.radial_segments = 12
	pot.mesh = cone
	pot.material_override = Props.mat(UIKit.TERRA)
	pot.position = at + Vector3(0.0, 0.21, 0.0)
	root.add_child(pot)
	var soil := Props.mesh_cylinder(0.24, 0.02, Color("4A3626"))
	soil.position = at + Vector3(0.0, 0.41, 0.0)
	root.add_child(soil)
	var bush := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.5
	sphere.radial_segments = 10
	sphere.rings = 5
	bush.mesh = sphere
	bush.material_override = Props.mat(Color("7FA866"))
	bush.position = at + Vector3(0.0, 0.62, 0.0)
	root.add_child(bush)
	for i in 5:
		var flower := Props.mesh_cylinder(0.035, 0.02, [TIN_RED, UIKit.MUSTARD, Color("E8B4A8"), TIN_RED, UIKit.MUSTARD][i])
		flower.position = at + Vector3(cos(i * 1.3) * 0.2, 0.74 + (i % 2) * 0.06, sin(i * 1.3) * 0.2)
		root.add_child(flower)
