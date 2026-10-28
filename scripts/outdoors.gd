extends RefCounted
# The world outside the room: ground, a driveway out of the door, a road,
# trees, bushes, a fence or lamp posts, and a row of neighbours in the distance.
# Everything is plain meshes with no collision, so the aim ray never sees it.
# Positions come from a seed, so a room always gets the same yard.

const Props = preload("res://scripts/props.gd")

const GRASS := Color("8FB573")
const GRASS_DARK := Color("7CA362")
const PAVEMENT := Color("C9C2B5")
const ROAD := Color("5E5A5C")
const ROAD_LINE := Color("E8DFC8")
const TRUNK := Color("7A4F2A")
const LEAF := Color("6E9F5A")
const LEAF_LIGHT := Color("8DB86E")
const BUSH := Color("7FA866")
const FENCE := Color("D9CFB8")
const POST := Color("4E4A48")
const LAMP := Color("FFE3A8")
const WATER := Color("9FC4D6")
const HOUSES: Array = [Color("E7C9A8"), Color("D8B4A0"), Color("C9D2C0"), Color("E3D5B8"), Color("BFC8D4"), Color("D4C1D8")]


static func build(parent: Node3D, venue: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Outdoors"
	parent.add_child(root)
	var kind := style_for(venue)
	var x := float(venue.get("x", 0))
	var z := float(venue.get("z", 0))
	var w := float(venue.get("w", 6))
	var d := float(venue.get("d", 8))
	var room := Rect2(x - 1.2, z - 1.2, w + 2.4, d + 2.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(venue.get("id", "garage")))
	_ground(root, x + w * 0.5, z + d * 0.5, kind)
	var door_x := _door_x(venue)
	_driveway(root, door_x, z, kind)
	_road(root, x + w * 0.5, z - 6.0, kind)
	_parking(root, door_x + 6.4, z - 2.4, kind)
	var keep: Array = [room, Rect2(door_x - 2.0, z - 7.5, 4.0, 7.5), Rect2(door_x + 2.8, z - 4.2, 7.2, 3.6)]
	match kind:
		"park":
			_pond(root, x + w + 5.5, z + d * 0.5)
			keep.append(Rect2(x + w + 2.5, z - 0.5, 7.0, d + 1.0))
			_bench(root, x + w + 2.6, z + d * 0.5 + 2.4)
		"town":
			_lamp_posts(root, x + w * 0.5, z - 4.4)
		_:
			_fence(root, x - 1.4, z - 1.0, d + 2.0)
			_mailbox(root, door_x + 2.4, z - 1.2)
	_houses(root, x + w * 0.5, z - 9.2, kind, rng)
	_trees(root, x + w * 0.5, z + d * 0.5, keep, kind, rng)
	return root


static func style_for(venue: Dictionary) -> String:
	var id := str(venue.get("id", ""))
	if id == "park":
		return "park"
	if id == "garage" or id == "" or bool(venue.get("home", false)):
		return "suburb"
	return "town"


static func _door_x(venue: Dictionary) -> float:
	var x := float(venue.get("x", 0))
	var w := float(venue.get("w", 6))
	var open_w := float(venue.get("open_w", 2))
	if abs(open_w - 3.0) < 0.1 and w >= 6.0:
		return x + 3.5
	return x + w * 0.5


static func _ground(root: Node3D, cx: float, cz: float, kind: String) -> void:
	var color := GRASS
	if kind == "town":
		color = PAVEMENT
	var ground := Props.mesh_box(Vector3(90, 0.04, 90), color)
	ground.position = Vector3(cx, -0.06, cz)
	ground.name = "Ground"
	root.add_child(ground)
	if kind != "town":
		# A couple of darker patches so the lawn is not one flat sheet.
		for patch in [Vector3(cx - 7.0, 0.0, cz - 3.0), Vector3(cx + 6.0, 0.0, cz + 5.0), Vector3(cx + 2.0, 0.0, cz - 9.0)]:
			var dark := _disc(2.6, GRASS_DARK)
			dark.position = patch + Vector3(0, -0.035, 0)
			root.add_child(dark)


static func _driveway(root: Node3D, door_x: float, z: float, kind: String) -> void:
	var color := PAVEMENT if kind != "town" else Color("B5AEA2")
	var drive := Props.mesh_box(Vector3(3.2, 0.03, 5.6), color)
	drive.position = Vector3(door_x, -0.03, z - 2.9)
	drive.name = "Driveway"
	root.add_child(drive)


static func _parking(root: Node3D, cx: float, cz: float, kind: String) -> void:
	# Three bays off the road, nose-in, for the people who drive here.
	var lot := Node3D.new()
	lot.name = "Parking"
	lot.set_meta("slots", [Vector3(cx - 2.2, 0.0, cz), Vector3(cx, 0.0, cz), Vector3(cx + 2.2, 0.0, cz)])
	lot.set_meta("entry", Vector3(cx, 0.0, cz - 2.6))
	root.add_child(lot)
	var slab := Props.mesh_box(Vector3(7.0, 0.03, 3.0), Color("6E6A6C") if kind == "town" else Color("8A8588"))
	slab.position = Vector3(cx, -0.03, cz)
	lot.add_child(slab)
	for i in 4:
		var line := Props.mesh_box(Vector3(0.08, 0.01, 2.6), ROAD_LINE)
		line.position = Vector3(cx - 3.3 + i * 2.2, 0.0, cz)
		lot.add_child(line)
	var stop := Props.mesh_box(Vector3(6.8, 0.1, 0.12), Color("C9C2B5"))
	stop.position = Vector3(cx, 0.0, cz + 1.4)
	lot.add_child(stop)
	var sign_post := Props.mesh_box(Vector3(0.06, 1.8, 0.06), POST)
	sign_post.position = Vector3(cx + 3.7, 0.0, cz + 1.3)
	lot.add_child(sign_post)
	var sign := Props.mesh_box(Vector3(0.5, 0.5, 0.04), Color("7FA3B8"))
	sign.position = Vector3(cx + 3.7, 1.5, cz + 1.3)
	lot.add_child(sign)
	var letter := Props.mesh_box(Vector3(0.2, 0.3, 0.01), Color("FFF8EC"))
	letter.position = Vector3(cx + 3.7, 1.6, cz + 1.33)
	lot.add_child(letter)


static func _road(root: Node3D, cx: float, z: float, kind: String) -> void:
	var road := Props.mesh_box(Vector3(60, 0.03, 3.2), ROAD)
	road.position = Vector3(cx, -0.03, z)
	road.name = "Road"
	root.add_child(road)
	var dash_x := cx - 29.0
	while dash_x < cx + 29.0:
		var dash := Props.mesh_box(Vector3(1.1, 0.01, 0.12), ROAD_LINE)
		dash.position = Vector3(dash_x, 0.0, z)
		root.add_child(dash)
		dash_x += 2.4
	if kind == "town":
		var kerb := Props.mesh_box(Vector3(60, 0.1, 0.25), Color("A39C90"))
		kerb.position = Vector3(cx, -0.02, z + 1.72)
		root.add_child(kerb)


static func _fence(root: Node3D, x: float, z: float, length: float) -> void:
	var fence := Node3D.new()
	fence.name = "Fence"
	root.add_child(fence)
	var zz := z
	while zz <= z + length:
		var post := Props.mesh_box(Vector3(0.1, 0.9, 0.1), FENCE)
		post.position = Vector3(x, 0, zz)
		fence.add_child(post)
		zz += 1.0
	for height in [0.35, 0.7]:
		var rail := Props.mesh_box(Vector3(0.06, 0.08, length), FENCE)
		rail.position = Vector3(x, height, z + length * 0.5)
		fence.add_child(rail)


static func _mailbox(root: Node3D, x: float, z: float) -> void:
	var post := Props.mesh_box(Vector3(0.08, 1.0, 0.08), POST)
	post.position = Vector3(x, 0, z)
	root.add_child(post)
	var box := Props.mesh_box(Vector3(0.22, 0.2, 0.42), Color("D86F5B"))
	box.position = Vector3(x, 1.0, z)
	root.add_child(box)


static func _lamp_posts(root: Node3D, cx: float, z: float) -> void:
	for i in 5:
		var x := cx - 10.0 + i * 5.0
		var post := Props.mesh_cylinder(0.06, 3.2, POST)
		post.position = Vector3(x, 0, z)
		root.add_child(post)
		var head := Props.mesh_box(Vector3(0.36, 0.2, 0.36), LAMP)
		head.position = Vector3(x, 3.2, z)
		root.add_child(head)


static func _pond(root: Node3D, x: float, z: float) -> void:
	var water := _disc(3.0, WATER)
	water.position = Vector3(x, -0.02, z)
	water.name = "Pond"
	root.add_child(water)
	var rim := _disc(3.25, Color("B9A98C"))
	rim.position = Vector3(x, -0.045, z)
	root.add_child(rim)
	# A few ducks: a body and a head, nothing fancy.
	for i in 3:
		var angle := i * 2.1
		var at := Vector3(x + cos(angle) * 1.4, 0.0, z + sin(angle) * 1.4)
		var body := Props.mesh_box(Vector3(0.28, 0.16, 0.18), Color("F2E5B8"))
		body.position = at
		root.add_child(body)
		var head := Props.mesh_box(Vector3(0.12, 0.12, 0.12), Color("5E8F4A"))
		head.position = at + Vector3(0.14, 0.16, 0)
		root.add_child(head)


static func _bench(root: Node3D, x: float, z: float) -> void:
	var seat := Props.mesh_box(Vector3(1.4, 0.08, 0.4), Color("A9774C"))
	seat.position = Vector3(x, 0.42, z)
	root.add_child(seat)
	var back := Props.mesh_box(Vector3(1.4, 0.4, 0.06), Color("A9774C"))
	back.position = Vector3(x, 0.5, z - 0.2)
	root.add_child(back)
	for dx in [-0.6, 0.6]:
		var leg := Props.mesh_box(Vector3(0.08, 0.42, 0.4), POST)
		leg.position = Vector3(x + dx, 0, z)
		root.add_child(leg)


static func _houses(root: Node3D, cx: float, z: float, kind: String, rng: RandomNumberGenerator) -> void:
	var houses := Node3D.new()
	houses.name = "Neighbours"
	root.add_child(houses)
	var x := cx - 14.0
	var i := 0
	while x < cx + 14.0:
		var w := rng.randf_range(3.0, 5.0)
		var h := rng.randf_range(2.6, 4.2) if kind != "town" else rng.randf_range(4.0, 7.5)
		var body := Props.mesh_box(Vector3(w, h, 4.0), HOUSES[i % HOUSES.size()])
		body.position = Vector3(x + w * 0.5, 0, z - 2.0)
		houses.add_child(body)
		if kind != "town":
			var roof := Props.mesh_box(Vector3(w + 0.4, 0.5, 4.4), Color("8A5A44"))
			roof.position = Vector3(x + w * 0.5, h, z - 2.0)
			houses.add_child(roof)
		var win := Props.mesh_box(Vector3(w * 0.3, 0.7, 0.05), Color("F6E7B2"))
		win.position = Vector3(x + w * 0.5, h * 0.45, z + 0.03)
		houses.add_child(win)
		x += w + rng.randf_range(1.2, 2.6)
		i += 1


static func _trees(root: Node3D, cx: float, cz: float, keep: Array, kind: String, rng: RandomNumberGenerator) -> void:
	var count := 14 if kind != "town" else 6
	var placed := 0
	var tries := 0
	while placed < count and tries < 200:
		tries += 1
		var at := Vector3(cx + rng.randf_range(-16.0, 16.0), 0.0, cz + rng.randf_range(-5.0, 14.0))
		var blocked := false
		for rect in keep:
			if (rect as Rect2).grow(0.8).has_point(Vector2(at.x, at.z)):
				blocked = true
		if blocked:
			continue
		if rng.randf() < 0.35:
			_bush(root, at, rng.randf_range(0.3, 0.5))
		else:
			_tree(root, at, rng.randf_range(0.85, 1.25))
		placed += 1


static func _tree(root: Node3D, at: Vector3, scale: float) -> void:
	var tree := Node3D.new()
	tree.position = at
	root.add_child(tree)
	var trunk := Props.mesh_cylinder(0.12 * scale, 0.9 * scale, TRUNK)
	tree.add_child(trunk)
	var lower := _cone(0.95 * scale, 1.4 * scale, LEAF)
	lower.position = Vector3(0, 0.8 * scale, 0)
	tree.add_child(lower)
	var upper := _cone(0.65 * scale, 1.1 * scale, LEAF_LIGHT)
	upper.position = Vector3(0, 1.6 * scale, 0)
	tree.add_child(upper)


static func _bush(root: Node3D, at: Vector3, radius: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.6
	sphere.radial_segments = 10
	sphere.rings = 5
	mesh_instance.mesh = sphere
	mesh_instance.material_override = Props.mat(BUSH)
	mesh_instance.position = at + Vector3(0, radius * 0.6, 0)
	root.add_child(mesh_instance)


static func _cone(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 8
	mesh_instance.mesh = cone
	mesh_instance.material_override = Props.mat(color)
	mesh_instance.position.y = height * 0.5
	return mesh_instance


static func _disc(radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.02
	disc.radial_segments = 20
	mesh_instance.mesh = disc
	mesh_instance.material_override = Props.mat(color)
	return mesh_instance
