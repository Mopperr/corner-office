extends RefCounted
# The business in the yard. As the shop climbs the ladder, the lawn beside
# the garage grows a stand: a coffee cart, a sandwich kiosk, a shawarma
# grill, a café terrace, and finally a little pavilion with white cloths.
# Customers queue at the stand's counter. All of it is scenery except the
# counter body, which blocks like a real counter.

const Props = preload("res://scripts/props.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

const WOOD := Color("B98A5A")
const WOOD_DARK := Color("7A5C40")
const STEEL := Color("A9ABB0")
const CLOTH := Color("FFF8EC")
const AWNING_A := Color("D9765F")
const AWNING_B := Color("FFF1D2")
const GLASS := Color("DCE9EE", 0.55)
const BOARD := Color("3E3A4F")
const MEAT := Color("B86B44")
const BULB := Color("FFE2A8")


static func build(parent: Node3D, venue: Dictionary, tier: String) -> Node3D:
	var root := Node3D.new()
	root.name = "YardShop"
	root.set_meta("tier", tier)
	parent.add_child(root)
	# The business sits on the lawn east of the room, its front facing south so
	# the camera looks in through the serving window. Tables go out front.
	var x := float(venue.get("x", 0)) + float(venue.get("w", 6)) + 2.3
	var z := float(venue.get("z", 0)) + 2.0
	var at := Vector3(x, 0.0, z)
	var front := at + Vector3(0.0, 0.0, 1.4)
	match tier:
		"cart":
			_cart(root, at + Vector3(0, 0, 1.2))
			_counter_body(root, at + Vector3(0, 0, 1.2))
		"sandwich":
			_house(root, at, "Sandwiches", AWNING_A, Color("FFF1D2"), "sandwich")
			_front_tables(root, front, 2, false)
			_counter_body(root, front)
		"shawarma":
			_house(root, at, "Shawarma", Color("E6B655"), Color("F2D9A8"), "grill")
			_front_tables(root, front, 2, false)
			_bar_tables(root, front + Vector3(0, 0, 0.6))
			_counter_body(root, front)
		"cafe":
			_house(root, at, "Corner Café", Color("8FAF7E"), Color("E8EFD9"), "coffee")
			_front_tables(root, front, 3, false)
			_pendants(root, front + Vector3(0, 0, 1.0))
			_counter_body(root, front)
		"restaurant":
			_deck(root, front + Vector3(0.2, 0, 1.2))
			_house(root, at, "Reservations", BOARD, Color("3E3A4F"), "pass")
			_front_tables(root, front + Vector3(0, 0.12, 0.4), 4, true)
			_pergola(root, front + Vector3(0, 0, 1.0))
			_counter_body(root, front)
		_:
			return root
	return root


static func _house(root: Node3D, at: Vector3, title: String, accent: Color, wall: Color, kitchen: String) -> void:
	# A small shop building: slab, back and side walls, a flat roof with a
	# parapet, an open front with a serving counter in the window, a door,
	# shelves and a kitchen inside, a sign and a menu board out front.
	var w := 3.6
	var d := 2.8
	var h := 2.7
	var slab := Props.mesh_box(Vector3(w + 0.3, 0.1, d + 0.3), Color("CFC3B2"))
	slab.position = at
	root.add_child(slab)
	var floor := Props.mesh_box(Vector3(w, 0.02, d), Color("B98A5A"))
	floor.position = at + Vector3(0, 0.1, 0)
	root.add_child(floor)
	var back := Props.mesh_box(Vector3(w, h, 0.16), wall)
	back.position = at + Vector3(0, 0.1, -d * 0.5 + 0.08)
	root.add_child(back)
	for side in [-1.0, 1.0]:
		var side_wall := Props.mesh_box(Vector3(0.16, h, d), wall.darkened(0.06))
		side_wall.position = at + Vector3(side * (w * 0.5 - 0.08), 0.1, 0)
		root.add_child(side_wall)
	# Front: a low wall under the serving window, a door on the right.
	var sill := Props.mesh_box(Vector3(w - 1.0, 1.0, 0.16), wall)
	sill.position = at + Vector3(-0.5, 0.1, d * 0.5 - 0.08)
	root.add_child(sill)
	var header := Props.mesh_box(Vector3(w, 0.5, 0.16), wall)
	header.position = at + Vector3(0, 0.1 + h - 0.5, d * 0.5 - 0.08)
	root.add_child(header)
	var door := Props.mesh_box(Vector3(0.84, 2.1, 0.08), accent.darkened(0.2))
	door.position = at + Vector3(w * 0.5 - 0.58, 0.1, d * 0.5 - 0.06)
	root.add_child(door)
	var knob := Props.mesh_cylinder(0.025, 0.05, STEEL)
	knob.position = at + Vector3(w * 0.5 - 0.3, 1.1, d * 0.5 + 0.02)
	knob.rotation.x = PI * 0.5
	root.add_child(knob)
	# The roof covers only the kitchen at the back, so the camera looks into
	# the shop over the counter; the front is shaded by the awning instead.
	var roof := Props.mesh_box(Vector3(w + 0.4, 0.16, d * 0.45), wall.darkened(0.3))
	roof.position = at + Vector3(0, 0.1 + h, -d * 0.5 + d * 0.225)
	root.add_child(roof)
	for side in [-1.0, 1.0]:
		var beam := Props.mesh_box(Vector3(0.12, 0.12, d * 0.55), wall.darkened(0.3))
		beam.position = at + Vector3(side * (w * 0.5 + 0.1), 0.1 + h, d * 0.5 - d * 0.275)
		root.add_child(beam)
	var parapet := Props.mesh_box(Vector3(w + 0.4, 0.3, 0.12), accent)
	parapet.position = at + Vector3(0, 0.1 + h + 0.16, d * 0.5 + 0.14)
	root.add_child(parapet)
	# Striped awning over the window.
	for i in 7:
		var stripe := Props.mesh_box(Vector3(0.42, 0.04, 1.1), accent if i % 2 == 0 else AWNING_B)
		stripe.position = at + Vector3(-1.26 + i * 0.42, 0.1 + h - 0.6, d * 0.5 + 0.5)
		stripe.rotation.x = deg_to_rad(14)
		root.add_child(stripe)
	# Counter in the window with the day's wares.
	var counter := Props.mesh_box(Vector3(w - 1.0, 0.06, 0.5), WOOD_DARK)
	counter.position = at + Vector3(-0.5, 1.1, d * 0.5 - 0.2)
	root.add_child(counter)
	var case := Props.mesh_box(Vector3(1.0, 0.34, 0.36), GLASS)
	var glass_mat := Props.mat(GLASS)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	case.material_override = glass_mat
	case.position = at + Vector3(-0.9, 1.16, d * 0.5 - 0.22)
	root.add_child(case)
	for i in 4:
		var bun := Props.mesh_box(Vector3(0.14, 0.08, 0.1), Color("D9A866"))
		bun.position = at + Vector3(-1.25 + i * 0.22, 1.18, d * 0.5 - 0.22)
		root.add_child(bun)
	var till := Props.mesh_box(Vector3(0.3, 0.22, 0.26), BOARD)
	till.position = at + Vector3(0.4, 1.16, d * 0.5 - 0.22)
	root.add_child(till)
	# Inside: shelves with jars, and the kitchen.
	var shelf := Props.mesh_box(Vector3(w - 0.6, 0.04, 0.3), WOOD_DARK)
	shelf.position = at + Vector3(0, 1.7, -d * 0.5 + 0.32)
	root.add_child(shelf)
	for i in 6:
		var jar := Props.mesh_cylinder(0.07, 0.16 + (i % 2) * 0.06, [UIKit.MUSTARD, AWNING_A, UIKit.SAGE, UIKit.BLUE, UIKit.PINK, UIKit.TERRA][i])
		jar.position = at + Vector3(-1.25 + i * 0.5, 1.74, -d * 0.5 + 0.32)
		root.add_child(jar)
	_kitchen(root, at + Vector3(-0.6, 0.12, -d * 0.5 + 0.55), kitchen)
	var glow := OmniLight3D.new()
	glow.position = at + Vector3(0, 2.2, 0)
	glow.light_color = Color("FFD9A0")
	glow.light_energy = 0.9
	glow.omni_range = 4.0
	glow.shadow_enabled = false
	root.add_child(glow)
	# Sign on the parapet, menu board by the door.
	_sign(root, at + Vector3(-0.3, 0.1 + h + 0.1, d * 0.5 + 0.22), title, accent)
	var board := Props.mesh_box(Vector3(0.5, 0.7, 0.03), BOARD)
	board.position = at + Vector3(w * 0.5 + 0.1, 0.1, d * 0.5 + 0.6)
	board.rotation.y = deg_to_rad(-20)
	root.add_child(board)
	for i in 4:
		var line := Props.mesh_box(Vector3(0.34 - i * 0.05, 0.02, 0.01), UIKit.CREAM_CARD)
		line.position = at + Vector3(w * 0.5 + 0.1, 0.62 - i * 0.12, d * 0.5 + 0.62)
		line.rotation.y = deg_to_rad(-20)
		root.add_child(line)
	for side in [-1.0, 1.0]:
		var planter := Props.mesh_box(Vector3(0.5, 0.4, 0.4), UIKit.TERRA)
		planter.position = at + Vector3(side * (w * 0.5 + 0.5), 0, d * 0.5 - 0.3)
		root.add_child(planter)
		var bush := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.5
		bush.mesh = sphere
		bush.material_override = Props.mat(Color("7FA866"))
		bush.position = at + Vector3(side * (w * 0.5 + 0.5), 0.58, d * 0.5 - 0.3)
		root.add_child(bush)


static func _kitchen(root: Node3D, at: Vector3, kind: String) -> void:
	var block := Props.mesh_box(Vector3(1.6, 0.9, 0.6), STEEL)
	block.position = at
	root.add_child(block)
	match kind:
		"grill":
			_spit(root, at + Vector3(0.3, 0.9, 0))
			var hob := Props.mesh_box(Vector3(0.6, 0.06, 0.5), UIKit.DARK)
			hob.position = at + Vector3(-0.4, 0.9, 0)
			root.add_child(hob)
		"coffee":
			var machine := Props.mesh_box(Vector3(0.5, 0.46, 0.4), Color("D9765F"))
			machine.position = at + Vector3(-0.3, 0.9, 0)
			root.add_child(machine)
			var grinder := Props.mesh_cylinder(0.1, 0.4, UIKit.DARK)
			grinder.position = at + Vector3(0.4, 0.9, 0)
			root.add_child(grinder)
		"pass":
			var lamp := Props.mesh_box(Vector3(1.4, 0.06, 0.3), UIKit.DARK)
			lamp.position = at + Vector3(0, 1.6, 0)
			root.add_child(lamp)
			for i in 3:
				var plate := Props.mesh_cylinder(0.12, 0.02, CLOTH)
				plate.position = at + Vector3(-0.5 + i * 0.5, 0.9, 0)
				root.add_child(plate)
			var heat := OmniLight3D.new()
			heat.position = at + Vector3(0, 1.5, 0)
			heat.light_color = Color("FF9A5A")
			heat.light_energy = 0.5
			heat.omni_range = 2.0
			heat.shadow_enabled = false
			root.add_child(heat)
		_:
			var toaster := Props.mesh_box(Vector3(0.4, 0.3, 0.3), STEEL.darkened(0.2))
			toaster.position = at + Vector3(-0.4, 0.9, 0)
			root.add_child(toaster)
			var loaf := Props.mesh_box(Vector3(0.36, 0.14, 0.18), Color("C8913F"))
			loaf.position = at + Vector3(0.3, 0.9, 0)
			root.add_child(loaf)
			var board := Props.mesh_box(Vector3(0.5, 0.03, 0.34), WOOD)
			board.position = at + Vector3(0.3, 0.9, 0)
			root.add_child(board)


static func _front_tables(root: Node3D, front: Vector3, count: int, fancy: bool) -> void:
	var spots: Array = [Vector3(-1.5, 0, 1.3), Vector3(0.2, 0, 1.6), Vector3(1.8, 0, 1.2), Vector3(0.4, 0, 3.0)]
	for i in mini(count, spots.size()):
		var centre: Vector3 = front + spots[i]
		var top := Props.mesh_cylinder(0.42, 0.04, CLOTH if fancy else WOOD_DARK)
		top.position = centre + Vector3(0, 0.72, 0)
		root.add_child(top)
		if fancy:
			var cloth := Props.mesh_cylinder(0.46, 0.3, CLOTH)
			cloth.position = centre + Vector3(0, 0.44, 0)
			root.add_child(cloth)
			var candle := Props.mesh_cylinder(0.025, 0.12, UIKit.CREAM_CARD)
			candle.position = centre + Vector3(0, 0.76, 0)
			root.add_child(candle)
			var flame := OmniLight3D.new()
			flame.position = centre + Vector3(0, 0.95, 0)
			flame.light_color = Color("FFC98A")
			flame.light_energy = 0.3
			flame.omni_range = 1.8
			flame.shadow_enabled = false
			root.add_child(flame)
		else:
			var cup := Props.mesh_cylinder(0.04, 0.08, UIKit.CREAM_CARD)
			cup.position = centre + Vector3(0.12, 0.76, -0.08)
			root.add_child(cup)
		var post := Props.mesh_cylinder(0.03, 0.72, STEEL)
		post.position = centre
		root.add_child(post)
		var foot := Props.mesh_cylinder(0.22, 0.02, STEEL)
		foot.position = centre
		root.add_child(foot)
		for k in 2:
			var angle := float(k) * PI + 0.6
			var seat_pos := centre + Vector3(cos(angle), 0.0, sin(angle)) * 0.62
			var seat := Props.mesh_box(Vector3(0.36, 0.04, 0.36), AWNING_A if not fancy else UIKit.DARK)
			seat.position = seat_pos + Vector3(0, 0.44, 0)
			seat.rotation.y = -angle
			root.add_child(seat)
			var back := Props.mesh_box(Vector3(0.36, 0.4, 0.04), AWNING_A if not fancy else UIKit.DARK)
			back.position = seat_pos + Vector3(cos(angle), 0.0, sin(angle)) * 0.16 + Vector3(0, 0.46, 0)
			back.rotation.y = -angle
			root.add_child(back)
			var leg := Props.mesh_cylinder(0.02, 0.44, STEEL)
			leg.position = seat_pos
			root.add_child(leg)


static func _counter_body(root: Node3D, at: Vector3) -> void:
	var counter := Node3D.new()
	counter.name = "YardCounter"
	counter.position = at
	counter.set_meta("yard_counter", true)
	root.add_child(counter)
	var body := StaticBody3D.new()
	body.collision_layer = Props.LAYER_BLOCKING
	body.collision_mask = Props.LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 1.0, 0.9)
	shape.shape = box
	shape.position = Vector3(0, 0.5, 0)
	body.add_child(shape)
	counter.add_child(body)


static func _sign(root: Node3D, at: Vector3, text: String, color: Color) -> void:
	var board := Props.mesh_box(Vector3(1.6, 0.42, 0.05), color)
	board.position = at
	root.add_child(board)
	var label := Label3D.new()
	label.text = text
	label.font = UIKit.title_font()
	label.font_size = 64
	label.pixel_size = 0.005
	label.modulate = UIKit.CREAM_CARD if color.get_luminance() < 0.6 else UIKit.DARK
	label.position = at + Vector3(0, 0.21, 0.03)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	root.add_child(label)


static func _cart(root: Node3D, at: Vector3) -> void:
	var body := Props.mesh_box(Vector3(1.6, 0.9, 0.9), WOOD)
	body.position = at + Vector3(0, 0.2, 0)
	root.add_child(body)
	var top := Props.mesh_box(Vector3(1.7, 0.06, 1.0), WOOD_DARK)
	top.position = at + Vector3(0, 1.1, 0)
	root.add_child(top)
	for side in [-0.6, 0.6]:
		var wheel := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.16
		torus.outer_radius = 0.22
		wheel.mesh = torus
		wheel.material_override = Props.mat(UIKit.DARK)
		wheel.position = at + Vector3(side, 0.22, 0.5)
		wheel.rotation.x = PI * 0.5
		root.add_child(wheel)
	var machine := Props.mesh_box(Vector3(0.4, 0.42, 0.36), STEEL)
	machine.position = at + Vector3(-0.45, 1.16, 0)
	root.add_child(machine)
	for i in 3:
		var cup := Props.mesh_cylinder(0.05, 0.1, UIKit.CREAM_CARD)
		cup.position = at + Vector3(0.2 + i * 0.14, 1.16, 0.2)
		root.add_child(cup)
	var pole := Props.mesh_cylinder(0.03, 2.4, STEEL)
	pole.position = at + Vector3(0.55, 0.0, -0.2)
	root.add_child(pole)
	var umbrella := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.3
	cone.height = 0.5
	cone.radial_segments = 8
	umbrella.mesh = cone
	umbrella.material_override = Props.mat(AWNING_A)
	umbrella.position = at + Vector3(0.55, 2.45, -0.2)
	root.add_child(umbrella)
	_sign(root, at + Vector3(0, 0.5, 0.48), "Coffee", BOARD)


static func _spit(root: Node3D, at: Vector3) -> void:
	var base := Props.mesh_box(Vector3(0.5, 0.12, 0.5), STEEL)
	base.position = at
	root.add_child(base)
	var rod := Props.mesh_cylinder(0.02, 1.1, STEEL)
	rod.position = at + Vector3(0, 0.12, 0)
	root.add_child(rod)
	var meat := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.12
	cone.bottom_radius = 0.2
	cone.height = 0.7
	cone.radial_segments = 10
	meat.mesh = cone
	meat.material_override = Props.mat(MEAT)
	meat.position = at + Vector3(0, 0.6, 0)
	root.add_child(meat)
	var hood := Props.mesh_box(Vector3(0.6, 0.08, 0.6), UIKit.DARK)
	hood.position = at + Vector3(0, 1.3, 0)
	root.add_child(hood)
	var glow := OmniLight3D.new()
	glow.position = at + Vector3(0, 1.2, 0.2)
	glow.light_color = Color("FF9A5A")
	glow.light_energy = 0.6
	glow.omni_range = 2.4
	glow.shadow_enabled = false
	root.add_child(glow)


static func _bar_tables(root: Node3D, at: Vector3) -> void:
	for i in 2:
		var pos := at + Vector3(-0.7 + i * 1.6, 0.0, 1.6)
		var top := Props.mesh_cylinder(0.3, 0.04, WOOD_DARK)
		top.position = pos + Vector3(0, 1.0, 0)
		root.add_child(top)
		var post := Props.mesh_cylinder(0.03, 1.0, STEEL)
		post.position = pos
		root.add_child(post)
		var foot := Props.mesh_cylinder(0.22, 0.02, STEEL)
		foot.position = pos
		root.add_child(foot)


static func _pendants(root: Node3D, at: Vector3) -> void:
	for i in 2:
		var pole := Props.mesh_cylinder(0.03, 2.6, STEEL)
		pole.position = at + Vector3(-2.0 + i * 4.4, 0, 1.0)
		root.add_child(pole)
	var wire := Props.mesh_box(Vector3(4.4, 0.015, 0.015), UIKit.DARK)
	wire.position = at + Vector3(0.2, 2.55, 1.0)
	root.add_child(wire)
	for i in 7:
		var bulb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		bulb.mesh = sphere
		var glow := Props.mat(BULB)
		glow.emission_enabled = true
		glow.emission = BULB
		glow.emission_energy_multiplier = 1.4
		bulb.material_override = glow
		bulb.position = at + Vector3(-1.6 + i * 0.6, 2.42 - sin(float(i) / 6.0 * PI) * 0.12, 1.0)
		root.add_child(bulb)
		if i % 2 == 0:
			var light := OmniLight3D.new()
			light.position = bulb.position
			light.light_color = Color("FFD79A")
			light.light_energy = 0.25
			light.omni_range = 2.2
			light.shadow_enabled = false
			root.add_child(light)


static func _deck(root: Node3D, at: Vector3) -> void:
	var deck := Props.mesh_box(Vector3(6.4, 0.12, 5.4), WOOD_DARK)
	deck.position = at + Vector3(0.2, 0, 1.4)
	root.add_child(deck)
	for i in 14:
		var plank := Props.mesh_box(Vector3(6.2, 0.01, 0.02), WOOD)
		plank.position = at + Vector3(0.2, 0.12, -1.1 + i * 0.38)
		root.add_child(plank)


static func _pergola(root: Node3D, at: Vector3) -> void:
	for corner in [Vector3(-2.6, 0, -1.0), Vector3(3.0, 0, -1.0), Vector3(-2.6, 0, 3.8), Vector3(3.0, 0, 3.8)]:
		var post := Props.mesh_box(Vector3(0.16, 2.8, 0.16), CLOTH)
		post.position = at + corner
		root.add_child(post)
	for z in [-1.0, 3.8]:
		var beam := Props.mesh_box(Vector3(5.9, 0.12, 0.16), CLOTH)
		beam.position = at + Vector3(0.2, 2.8, z)
		root.add_child(beam)
	for i in 8:
		var slat := Props.mesh_box(Vector3(0.1, 0.08, 5.0), CLOTH)
		slat.position = at + Vector3(-2.4 + i * 0.75, 2.86, 1.4)
		root.add_child(slat)
	for i in 4:
		var lantern := Props.mesh_box(Vector3(0.18, 0.26, 0.18), BULB)
		var glow := Props.mat(BULB)
		glow.emission_enabled = true
		glow.emission = BULB
		glow.emission_energy_multiplier = 1.2
		lantern.material_override = glow
		lantern.position = at + Vector3(-1.8 + i * 1.3, 2.5, 1.4)
		root.add_child(lantern)
		var light := OmniLight3D.new()
		light.position = lantern.position
		light.light_color = Color("FFD79A")
		light.light_energy = 0.3
		light.omni_range = 2.6
		light.shadow_enabled = false
		root.add_child(light)
