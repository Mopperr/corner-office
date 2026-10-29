extends RefCounted
# Dresses the job venues so each reads as a real place: the cat café with
# its tables and bunting, the train shop with shelves of engines and a floor
# loop, the park shed with pots and tools, the bakery loft with its racks,
# the studio with an easel, the flat with a sofa. Big pieces block so the
# unpack never drops a box through a table; the small stuff is scenery.

const Props = preload("res://scripts/props.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

const WOOD := Color("B98A5A")
const WOOD_DARK := Color("7A5C40")
const STEEL := Color("A9ABB0")
const PAPER := Color("F4ECDD")
const BOARD := Color("3E3A4F")
const TRACK := Color("4E4A48")
const CLOTH := Color("FFF8EC")
const BULB := Color("FFE2A8")


static func build(parent: Node3D, venue: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "VenueDressing"
	parent.add_child(root)
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	match str(venue.get("id", "")):
		"cafe":
			_cafe(root, x, z, w, d)
		"train":
			_train(root, x, z, w, d)
		"park":
			_park(root, x, z, w, d)
		"bakery":
			_bakery(root, x, z, w, d)
		"studio":
			_studio(root, x, z, w, d)
		"flat":
			_flat(root, x, z, w, d)
	return root


# ---------------------------------------------------------------- helpers

static func _add(root: Node3D, mesh_instance: MeshInstance3D, at: Vector3, rot_y := 0.0) -> MeshInstance3D:
	mesh_instance.position += at
	mesh_instance.rotation.y = deg_to_rad(rot_y)
	root.add_child(mesh_instance)
	return mesh_instance


static func _block(root: Node3D, at: Vector3, size: Vector3) -> void:
	# A blocking body so placement treats the piece as solid.
	var body := StaticBody3D.new()
	body.collision_layer = Props.LAYER_BLOCKING
	body.collision_mask = Props.LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at + Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	root.add_child(body)


static func _floor_tone(root: Node3D, x: float, z: float, w: float, d: float, a: Color, b: Color, cell := 1.0) -> void:
	# A checker of thin tiles over the floor, no collision.
	var cx := x + cell * 0.5
	var ix := 0
	while cx < x + w:
		var cz := z + cell * 0.5
		var iz := 0
		while cz < z + d:
			var tile := Props.mesh_box(Vector3(cell - 0.02, 0.006, cell - 0.02), a if (ix + iz) % 2 == 0 else b)
			tile.position = Vector3(cx, 0.0, cz)
			root.add_child(tile)
			cz += cell
			iz += 1
		cx += cell
		ix += 1


static func _planks(root: Node3D, x: float, z: float, w: float, d: float, tone: Color) -> void:
	var cz := z + 0.1
	var k := 0
	while cz < z + d - 0.05:
		var plank := Props.mesh_box(Vector3(w - 0.1, 0.006, 0.17), tone.lightened(0.04 * (k % 3)))
		plank.position = Vector3(x + w * 0.5, 0.0, cz)
		root.add_child(plank)
		cz += 0.2
		k += 1


static func _round_table(root: Node3D, at: Vector3, top_color: Color, seat_color: Color, seats := 2) -> void:
	var top := Props.mesh_cylinder(0.42, 0.04, top_color)
	top.position = at + Vector3(0, 0.72, 0)
	root.add_child(top)
	var post := Props.mesh_cylinder(0.035, 0.72, STEEL)
	post.position = at
	root.add_child(post)
	var foot := Props.mesh_cylinder(0.24, 0.02, STEEL)
	foot.position = at
	root.add_child(foot)
	for k in seats:
		var angle := float(k) * TAU / float(seats) + 0.8
		var seat_pos := at + Vector3(cos(angle), 0.0, sin(angle)) * 0.66
		var seat := Props.mesh_box(Vector3(0.38, 0.05, 0.38), seat_color)
		seat.position = seat_pos + Vector3(0, 0.44, 0)
		seat.rotation.y = -angle
		root.add_child(seat)
		var back := Props.mesh_box(Vector3(0.38, 0.42, 0.04), seat_color)
		back.position = seat_pos + Vector3(cos(angle), 0.0, sin(angle)) * 0.17 + Vector3(0, 0.47, 0)
		back.rotation.y = -angle
		root.add_child(back)
		var leg := Props.mesh_cylinder(0.02, 0.44, STEEL)
		leg.position = seat_pos
		root.add_child(leg)
	_block(root, at, Vector3(1.5, 0.78, 1.5))


const CEILING_Y := 3.0


static func _pendant(root: Node3D, at: Vector3, shade: Color, energy := 0.6) -> void:
	# The cord runs all the way up to the ceiling line, with a rose where it meets it.
	var bottom := at.y - 0.6
	var cord := Props.mesh_box(Vector3(0.012, CEILING_Y - bottom, 0.012), BOARD)
	cord.position = Vector3(at.x, (CEILING_Y + bottom) * 0.5, at.z)
	root.add_child(cord)
	var rose := Props.mesh_cylinder(0.07, 0.03, BOARD)
	rose.position = Vector3(at.x, CEILING_Y - 0.015, at.z)
	root.add_child(rose)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.18
	mesh.height = 0.16
	mesh.radial_segments = 12
	cone.mesh = mesh
	cone.material_override = Props.mat(shade)
	cone.position = at - Vector3(0, 0.68, 0)
	root.add_child(cone)
	var light := OmniLight3D.new()
	light.position = at - Vector3(0, 0.85, 0)
	light.light_color = Color("FFCF92")
	light.light_energy = energy
	light.omni_range = 3.4
	light.shadow_enabled = false
	root.add_child(light)


static func _bunting(root: Node3D, from: Vector3, to: Vector3) -> void:
	var span := to - from
	var count := int(span.length() / 0.32)
	var wire := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.012, span.length())
	wire.mesh = mesh
	wire.material_override = Props.mat(BOARD)
	wire.position = from + span * 0.5
	wire.look_at_from_position(wire.position, to, Vector3.UP)
	root.add_child(wire)
	var colors := [UIKit.TERRA, UIKit.MUSTARD, UIKit.SAGE, UIKit.BLUE, UIKit.PINK]
	for i in range(1, count):
		var t := float(i) / float(count)
		var at := from.lerp(to, t) - Vector3(0, sin(t * PI) * 0.12, 0)
		var flag := Props.mesh_box(Vector3(0.16, 0.2, 0.01), colors[i % colors.size()])
		flag.position = at - Vector3(0, 0.2, 0)
		flag.look_at_from_position(flag.position, flag.position + span.normalized().cross(Vector3.UP), Vector3.UP)
		root.add_child(flag)


static func _wall_frame(root: Node3D, at: Vector3, size: Vector2, frame: Color, art: Color, rot_y := 0.0) -> void:
	var back := Props.mesh_box(Vector3(size.x, size.y, 0.03), frame)
	back.position = at - Vector3(0, size.y * 0.5, 0)
	back.rotation.y = deg_to_rad(rot_y)
	root.add_child(back)
	var inner := Props.mesh_box(Vector3(size.x - 0.08, size.y - 0.08, 0.012), art)
	inner.position = at - Vector3(0, size.y * 0.5, 0) + Vector3(0, 0, 0.02).rotated(Vector3.UP, deg_to_rad(rot_y))
	inner.rotation.y = deg_to_rad(rot_y)
	root.add_child(inner)


static func _shelf_row(root: Node3D, at: Vector3, length: float, rot_y: float) -> void:
	var board := Props.mesh_box(Vector3(length, 0.035, 0.26), WOOD_DARK)
	board.position = at
	board.rotation.y = deg_to_rad(rot_y)
	root.add_child(board)
	for k in 2:
		var bracket := Props.mesh_box(Vector3(0.03, 0.14, 0.2), STEEL)
		bracket.position = at + Vector3(-length * 0.35 + k * length * 0.7, -0.08, -0.02).rotated(Vector3.UP, deg_to_rad(rot_y))
		bracket.rotation.y = deg_to_rad(rot_y)
		root.add_child(bracket)


static func _window_light(root: Node3D, from: Vector3, to: Vector3) -> void:
	var spot := SpotLight3D.new()
	spot.position = from
	spot.light_color = Color("FFEBCB")
	spot.light_energy = 1.0
	spot.spot_range = 7.0
	spot.spot_angle = 32.0
	spot.shadow_enabled = false
	root.add_child(spot)
	spot.look_at_from_position(from, to, Vector3.UP)


# ---------------------------------------------------------------- venues

static func _cafe(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	_floor_tone(root, x + 0.05, z + 0.05, w - 0.1, d - 0.1, Color("D9CFBF"), Color("C9BCA8"), 1.0)
	_round_table(root, Vector3(x + 1.2, 0, z + 3.6), WOOD, UIKit.PINK)
	_round_table(root, Vector3(x + 5.0, 0, z + 3.5), WOOD, UIKit.SAGE)
	_pendant(root, Vector3(x + 2.6, 2.7, z + 4.7), UIKit.TERRA)
	_pendant(root, Vector3(x + 3.8, 2.7, z + 4.7), UIKit.TERRA)
	_bunting(root, Vector3(x + 0.2, 2.5, z + 1.0), Vector3(x + 2.0, 2.5, z + 0.2))
	_wall_frame(root, Vector3(x + 1.2, 1.9, z + 0.1), Vector2(0.9, 0.6), BOARD, Color("2F2B3E"))
	for i in 3:
		var line := Props.mesh_box(Vector3(0.5 - i * 0.1, 0.02, 0.01), PAPER)
		line.position = Vector3(x + 1.2 - 0.1, 1.72 - i * 0.12, z + 0.12)
		root.add_child(line)
	# Cake stand and a tip jar on the counter.
	var stand := Props.mesh_cylinder(0.18, 0.03, CLOTH)
	stand.position = Vector3(x + 2.6, 0.98, z + 4.7)
	root.add_child(stand)
	var stem := Props.mesh_cylinder(0.03, 0.12, CLOTH)
	stem.position = Vector3(x + 2.6, 0.86, z + 4.7)
	root.add_child(stem)
	var cake := Props.mesh_cylinder(0.14, 0.1, UIKit.PINK)
	cake.position = Vector3(x + 2.6, 1.01, z + 4.7)
	root.add_child(cake)
	var jar := Props.mesh_cylinder(0.06, 0.14, Color("DCE9EE"))
	jar.position = Vector3(x + 3.9, 0.95, z + 4.6)
	root.add_child(jar)
	# Window shelf with plants.
	_shelf_row(root, Vector3(x + 0.18, 1.5, z + 2.0), 1.4, 90.0)
	for k in 3:
		var pot := Props.mesh_cylinder(0.08, 0.1, UIKit.TERRA)
		pot.position = Vector3(x + 0.2, 1.52, z + 1.5 + k * 0.5)
		root.add_child(pot)
		var leaf := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.2
		leaf.mesh = sphere
		leaf.material_override = Props.mat(Color("7FA866"))
		leaf.position = Vector3(x + 0.2, 1.7, z + 1.5 + k * 0.5)
		root.add_child(leaf)
	_window_light(root, Vector3(x - 0.3, 2.3, z + 2.0), Vector3(x + 1.6, 0.0, z + 2.6))


static func _train(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	_planks(root, x + 0.05, z + 0.05, w - 0.1, d - 0.1, Color("B48A5E"))
	# Shelves of engines along the back wall.
	for row in 2:
		_shelf_row(root, Vector3(x + 0.18, 1.2 + row * 0.55, z + 3.2), 2.6, 90.0)
		for k in 4:
			var engine := Props.model("toy_train")
			if engine:
				engine.position = Vector3(x + 0.22, 1.22 + row * 0.55, z + 2.1 + k * 0.7)
				engine.rotation.y = deg_to_rad(90)
				engine.scale = Vector3(0.7, 0.7, 0.7)
				Props.cap_prop_materials(engine, 2)
				root.add_child(engine)
			else:
				var loco := Props.mesh_box(Vector3(0.12, 0.1, 0.3), [UIKit.TERRA, UIKit.BLUE, UIKit.SAGE, UIKit.MUSTARD][k])
				loco.position = Vector3(x + 0.22, 1.22 + row * 0.55, z + 2.1 + k * 0.7)
				root.add_child(loco)
	# A floor loop of track with sleepers.
	var cx := x + 2.6
	var cz := z + 4.0
	var hw := 1.2
	var hd := 0.7
	for seg in [[Vector3(cx - hw, 0, cz - hd), Vector3(cx + hw, 0, cz - hd)], [Vector3(cx + hw, 0, cz - hd), Vector3(cx + hw, 0, cz + hd)], [Vector3(cx + hw, 0, cz + hd), Vector3(cx - hw, 0, cz + hd)], [Vector3(cx - hw, 0, cz + hd), Vector3(cx - hw, 0, cz - hd)]]:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		var along := absf(b.x - a.x) > absf(b.z - a.z)
		for rail in [-0.05, 0.05]:
			var piece := Props.mesh_box(Vector3(length, 0.012, 0.02) if along else Vector3(0.02, 0.012, length), TRACK)
			piece.position = mid + (Vector3(0, 0.006, rail) if along else Vector3(rail, 0.006, 0))
			root.add_child(piece)
		var count := int(length / 0.16)
		for k in count:
			var t := (float(k) + 0.5) / float(count)
			var sleeper := Props.mesh_box(Vector3(0.04, 0.008, 0.16) if along else Vector3(0.16, 0.008, 0.04), WOOD_DARK)
			sleeper.position = a.lerp(b, t)
			root.add_child(sleeper)
	var runner := Props.mesh_box(Vector3(0.12, 0.1, 0.28), UIKit.TERRA)
	runner.position = Vector3(cx + hw, 0.02, cz)
	root.add_child(runner)
	# Signal post, posters, lamps.
	var post := Props.mesh_cylinder(0.025, 1.3, STEEL)
	post.position = Vector3(cx - hw - 0.3, 0.0, cz + hd + 0.3)
	root.add_child(post)
	var arm := Props.mesh_box(Vector3(0.3, 0.06, 0.02), UIKit.TERRA)
	arm.position = Vector3(cx - hw - 0.18, 1.2, cz + hd + 0.3)
	root.add_child(arm)
	_wall_frame(root, Vector3(x + 2.0, 2.0, z + 0.1), Vector2(0.6, 0.8), WOOD_DARK, UIKit.BLUE)
	_wall_frame(root, Vector3(x + 2.9, 2.0, z + 0.1), Vector2(0.6, 0.8), WOOD_DARK, UIKit.MUSTARD)
	_pendant(root, Vector3(x + 5.6, 2.7, z + 2.4), Color("3E5A52"))
	_pendant(root, Vector3(x + 2.5, 2.7, z + 5.1), Color("3E5A52"))
	_window_light(root, Vector3(x - 0.3, 2.3, z + 2.0), Vector3(x + 1.8, 0.0, z + 2.4))


static func _park(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	_planks(root, x + 0.05, z + 0.05, w - 0.1, d - 0.1, Color("A89272"))
	# Tool rack on the back wall.
	_shelf_row(root, Vector3(x + 0.18, 1.6, z + 4.2), 1.8, 90.0)
	for k in 3:
		var handle := Props.mesh_cylinder(0.015, 1.3, WOOD)
		handle.position = Vector3(x + 0.2, 0.2, z + 3.5 + k * 0.5)
		root.add_child(handle)
		var head := Props.mesh_box(Vector3(0.05, 0.08, 0.22), STEEL)
		head.position = Vector3(x + 0.22, 1.5, z + 3.5 + k * 0.5)
		root.add_child(head)
	# Stacked pots, soil sacks, a wheelbarrow.
	for k in 4:
		var pot := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.17
		cone.bottom_radius = 0.13
		cone.height = 0.2
		pot.mesh = cone
		pot.material_override = Props.mat(UIKit.TERRA)
		pot.position = Vector3(x + 0.6, 0.1 + k * 0.07, z + 4.8)
		root.add_child(pot)
	for k in 2:
		var sack := Props.mesh_box(Vector3(0.5, 0.3, 0.34), Color("8E7A5E"))
		sack.position = Vector3(x + 1.2, 0.0, z + 5.2 + k * 0.4)
		sack.rotation.y = deg_to_rad(-12 + k * 20)
		root.add_child(sack)
	var barrow := Props.mesh_box(Vector3(0.6, 0.3, 0.9), UIKit.SAGE)
	barrow.position = Vector3(x + 5.2, 0.3, z + 1.0)
	root.add_child(barrow)
	var wheel := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.16
	wheel.mesh = torus
	wheel.material_override = Props.mat(UIKit.DARK)
	wheel.position = Vector3(x + 5.2, 0.16, z + 1.5)
	wheel.rotation.z = PI * 0.5
	root.add_child(wheel)
	for k in 2:
		var leg := Props.mesh_box(Vector3(0.04, 0.3, 0.04), WOOD)
		leg.position = Vector3(x + 4.95 + k * 0.5, 0.0, z + 0.6)
		root.add_child(leg)
	_block(root, Vector3(x + 5.2, 0, z + 1.0), Vector3(0.7, 0.6, 1.0))
	# Seed trays on a potting bench.
	var bench := Props.mesh_box(Vector3(1.6, 0.06, 0.6), WOOD)
	bench.position = Vector3(x + 4.6, 0.84, z + 5.0)
	root.add_child(bench)
	for k in 2:
		var leg2 := Props.mesh_box(Vector3(0.08, 0.84, 0.5), WOOD_DARK)
		leg2.position = Vector3(x + 3.9 + k * 1.4, 0.0, z + 5.0)
		root.add_child(leg2)
	_block(root, Vector3(x + 4.6, 0, z + 5.0), Vector3(1.6, 0.92, 0.6))
	for k in 6:
		var sprout := Props.mesh_cylinder(0.02, 0.12, Color("7FA866"))
		sprout.position = Vector3(x + 4.0 + (k % 3) * 0.4, 0.9, z + 4.85 + int(k / 3) * 0.3)
		root.add_child(sprout)
	# Lanterns and a birdhouse by the window.
	_pendant(root, Vector3(x + 3.0, 2.6, z + 3.0), UIKit.MUSTARD, 0.5)
	var house := Props.mesh_box(Vector3(0.2, 0.22, 0.2), PAPER)
	house.position = Vector3(x + 0.25, 2.0, z + 1.2)
	root.add_child(house)
	var roof := Props.mesh_box(Vector3(0.26, 0.06, 0.26), UIKit.TERRA)
	roof.position = Vector3(x + 0.25, 2.22, z + 1.2)
	root.add_child(roof)
	_window_light(root, Vector3(x - 0.3, 2.3, z + 2.0), Vector3(x + 1.8, 0.0, z + 2.6))


static func _bakery(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	# Baker's rack with loaves, a café table, framed menus, warm pendants.
	var rack_at := Vector3(x + w - 0.6, 0, z + 2.2)
	for k in 4:
		var board := Props.mesh_box(Vector3(0.5, 0.03, 1.2), WOOD_DARK)
		board.position = rack_at + Vector3(0, 0.35 + k * 0.42, 0)
		root.add_child(board)
		for b in 3:
			var loaf := Props.mesh_box(Vector3(0.28, 0.12, 0.16), Color("C8913F").lightened(0.1 * (b % 2)))
			loaf.position = rack_at + Vector3(0, 0.38 + k * 0.42, -0.4 + b * 0.4)
			root.add_child(loaf)
	for corner in [Vector3(-0.22, 0, -0.58), Vector3(0.22, 0, -0.58), Vector3(-0.22, 0, 0.58), Vector3(0.22, 0, 0.58)]:
		var post := Props.mesh_cylinder(0.02, 2.0, STEEL)
		post.position = rack_at + corner
		root.add_child(post)
	_block(root, rack_at, Vector3(0.6, 2.0, 1.3))
	_round_table(root, Vector3(x + 6.4, 0, z + 3.2), CLOTH, UIKit.MUSTARD)
	_wall_frame(root, Vector3(x + 3.0, 2.1, z + 0.1), Vector2(0.7, 0.9), WOOD_DARK, PAPER)
	_wall_frame(root, Vector3(x + 4.0, 2.1, z + 0.1), Vector2(0.7, 0.9), WOOD_DARK, PAPER)
	_pendant(root, Vector3(x + 6.4, 2.8, z + 3.2), UIKit.MUSTARD)
	_pendant(root, Vector3(x + 5.5, 2.8, z + 7.0), UIKit.MUSTARD)
	var sack := Props.mesh_box(Vector3(0.5, 0.34, 0.36), PAPER)
	sack.position = Vector3(x + 1.0, 0, z + 8.6)
	root.add_child(sack)
	var sack2 := Props.mesh_box(Vector3(0.5, 0.34, 0.36), PAPER)
	sack2.position = Vector3(x + 1.45, 0, z + 8.9)
	sack2.rotation.y = deg_to_rad(25)
	root.add_child(sack2)


static func _studio(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	_planks(root, x + 0.05, z + 0.05, w - 0.1, d - 0.1, Color("D8C9A8"))
	# Easel with a canvas, a paint table, rolls of paper, a tall lamp.
	var easel := Vector3(x + 2.2, 0, z + 4.4)
	for leg in [Vector3(-0.28, 0, 0.1), Vector3(0.28, 0, 0.1), Vector3(0, 0, -0.3)]:
		var post := Props.mesh_box(Vector3(0.04, 1.8, 0.04), WOOD)
		post.position = easel + leg
		post.rotation.x = deg_to_rad(-10) if leg.z < 0.0 else deg_to_rad(6)
		root.add_child(post)
	var canvas := Props.mesh_box(Vector3(0.8, 0.95, 0.03), CLOTH)
	canvas.position = easel + Vector3(0, 0.7, 0.14)
	canvas.rotation.x = deg_to_rad(6)
	root.add_child(canvas)
	var daub := Props.mesh_box(Vector3(0.5, 0.4, 0.01), UIKit.BLUE)
	daub.position = easel + Vector3(-0.05, 0.95, 0.17)
	daub.rotation.x = deg_to_rad(6)
	root.add_child(daub)
	var daub2 := Props.mesh_box(Vector3(0.3, 0.25, 0.01), UIKit.TERRA)
	daub2.position = easel + Vector3(0.15, 1.2, 0.175)
	daub2.rotation.x = deg_to_rad(6)
	root.add_child(daub2)
	_block(root, easel, Vector3(0.8, 1.8, 0.6))
	var table := Props.mesh_box(Vector3(1.2, 0.05, 0.6), WOOD)
	table.position = Vector3(x + 6.2, 0.78, z + 1.4)
	root.add_child(table)
	for k in 2:
		var leg2 := Props.mesh_box(Vector3(0.06, 0.78, 0.5), WOOD_DARK)
		leg2.position = Vector3(x + 5.7 + k * 1.0, 0.0, z + 1.4)
		root.add_child(leg2)
	_block(root, Vector3(x + 6.2, 0, z + 1.4), Vector3(1.2, 0.85, 0.6))
	for k in 6:
		var pot := Props.mesh_cylinder(0.04, 0.08, [UIKit.TERRA, UIKit.MUSTARD, UIKit.BLUE, UIKit.SAGE, UIKit.PINK, UIKit.DARK][k])
		pot.position = Vector3(x + 5.8 + (k % 3) * 0.3, 0.83, z + 1.25 + int(k / 3) * 0.25)
		root.add_child(pot)
	for k in 3:
		var roll := Props.mesh_cylinder(0.06, 1.1, PAPER)
		roll.position = Vector3(x + 0.4 + k * 0.14, 0.0, z + d - 0.5)
		roll.rotation.z = deg_to_rad(-8 + k * 6)
		root.add_child(roll)
	var lamp_post := Props.mesh_cylinder(0.02, 1.6, STEEL)
	lamp_post.position = Vector3(x + 1.0, 0.0, z + 1.0)
	root.add_child(lamp_post)
	_pendant(root, Vector3(x + 1.0, 2.5, z + 1.0), BOARD, 0.5)
	_wall_frame(root, Vector3(x + 3.0, 2.1, z + 0.1), Vector2(0.7, 0.5), BOARD, UIKit.PINK)
	_wall_frame(root, Vector3(x + 3.9, 2.0, z + 0.1), Vector2(0.5, 0.7), BOARD, UIKit.SAGE)
	_window_light(root, Vector3(x - 0.3, 2.4, z + 2.0), Vector3(x + 2.0, 0.0, z + 2.4))


static func _flat(root: Node3D, x: float, z: float, w: float, d: float) -> void:
	_planks(root, x + 0.05, z + 0.05, w - 0.1, d - 0.1, Color("C9A47A"))
	# A sofa, a low table, a floor lamp, curtains, a few frames.
	var sofa := Vector3(x + w - 0.75, 0, z + 5.0)
	var seat := Props.mesh_box(Vector3(0.9, 0.42, 1.8), UIKit.SAGE)
	seat.position = sofa
	root.add_child(seat)
	var back := Props.mesh_box(Vector3(0.25, 0.8, 1.8), UIKit.SAGE.darkened(0.12))
	back.position = sofa + Vector3(0.33, 0, 0)
	root.add_child(back)
	for side in [-0.95, 0.95]:
		var arm := Props.mesh_box(Vector3(0.9, 0.56, 0.2), UIKit.SAGE.darkened(0.12))
		arm.position = sofa + Vector3(0, 0, side)
		root.add_child(arm)
	for k in 2:
		var cushion := Props.mesh_box(Vector3(0.36, 0.1, 0.36), [UIKit.MUSTARD, UIKit.PINK][k])
		cushion.position = sofa + Vector3(0.05, 0.42, -0.4 + k * 0.8)
		cushion.rotation.y = deg_to_rad(-10 + k * 25)
		root.add_child(cushion)
	_block(root, sofa, Vector3(0.95, 0.85, 1.9))
	var table := Props.mesh_box(Vector3(0.6, 0.04, 1.0), WOOD)
	table.position = Vector3(x + w - 1.9, 0.38, z + 5.0)
	root.add_child(table)
	for corner in [Vector3(-0.25, 0, -0.45), Vector3(0.25, 0, -0.45), Vector3(-0.25, 0, 0.45), Vector3(0.25, 0, 0.45)]:
		var leg := Props.mesh_cylinder(0.02, 0.38, WOOD_DARK)
		leg.position = Vector3(x + w - 1.9, 0.0, z + 5.0) + corner
		root.add_child(leg)
	_block(root, Vector3(x + w - 1.9, 0, z + 5.0), Vector3(0.6, 0.45, 1.0))
	var lamp_post := Props.mesh_cylinder(0.02, 1.5, STEEL)
	lamp_post.position = Vector3(x + w - 0.6, 0.0, z + 3.4)
	root.add_child(lamp_post)
	_pendant(root, Vector3(x + w - 0.6, 2.2, z + 3.4), CLOTH, 0.5)
	for k in 2:
		var curtain := Props.mesh_box(Vector3(0.08, 2.0, 0.5), UIKit.TERRA)
		curtain.position = Vector3(x + 0.2, 0.3, z + 0.9 + k * 2.2)
		root.add_child(curtain)
	var rail := Props.mesh_cylinder(0.015, 2.8, STEEL)
	rail.position = Vector3(x + 0.2, 2.3, z + 2.0)
	rail.rotation.x = PI * 0.5
	root.add_child(rail)
	_wall_frame(root, Vector3(x + 1.6, 2.0, z + 0.1), Vector2(0.5, 0.6), WOOD_DARK, UIKit.BLUE)
	_wall_frame(root, Vector3(x + 2.3, 1.9, z + 0.1), Vector2(0.4, 0.4), WOOD_DARK, UIKit.MUSTARD)
	_window_light(root, Vector3(x - 0.3, 2.3, z + 2.0), Vector3(x + 1.8, 0.0, z + 2.6))
