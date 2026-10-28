class_name Homes
extends RefCounted

## Houses as job venues. A home is a footprint split into rooms per floor,
## read from data/homes.json. The library builds the blueprint view of one
## floor (half-height interior walls with doorways, a tinted floor and a
## name per room, the stairs), knows which room a point is in, which floor
## a kind of item belongs on, and lays out the client's own furniture.

const Props = preload("res://scripts/props.gd")

const WALL_H := 1.05
const WALL_T := 0.12
const DOOR_W := 1.0
const DOOR_MIN := 1.2
const STAIRS_W := 1.0
const STAIRS_D := 2.2

# Room kinds and the item room tag that belongs in them.
const KIND_TAG := {
	"lounge": "living", "study": "living", "kitchen": "kitchen", "dining": "kitchen", "utility": "kitchen",
	"bathroom": "bathroom", "bedroom": "bedroom", "loft": "loft", "boxroom": "loft", "shed": "shed",
}
# Floor tint per kind, blended into the house's floor colour.
const KIND_TINT := {
	"hall": "D9C9A8", "landing": "D9C9A8", "lounge": "C98F7A", "study": "B9A27E", "kitchen": "DCD3B6",
	"dining": "C9B18F", "utility": "C9C9C0", "bathroom": "BFD6DA", "bedroom": "C7B6D6", "loft": "A99784",
	"boxroom": "B5A48F", "shed": "9F9A86",
}
# What the client already has standing in each kind of room when you arrive.
const OWNER_ITEMS := {
	"kitchen": ["fridge_home", "cooker", "bread_bin", "knife_block"],
	"dining": ["kitchen_chair", "kitchen_chair"],
	"utility": ["laundry_basket", "paint_tins"],
	"bathroom": ["bathtub", "toilet", "pedestal_sink", "towel_stack"],
	"bedroom": ["wardrobe", "alarm_clock", "pillow_stack"],
	"lounge": ["tv_stand", "television", "magazine_rack"],
	"study": ["telescope", "globe"],
	"hall": ["standing_mirror"],
	"loft": ["old_suitcase", "christmas_box", "record_box"],
	"boxroom": ["travel_trunk"],
	"shed": ["lawnmower", "ladder", "paint_tins", "watering_can"],
}

# What a house sounds like, by what it is built of.
const STYLE_AIR := {"brick": "amb_l04_shop_clock_loop", "render": "amb_l10_library_loop", "stone": "amb_l20_lodge_loop", "timber": "amb_l14_greenhouse_loop", "clapboard": "amb_l15_coastal_loop"}

static var _data: Dictionary = {}


static func all() -> Dictionary:
	if _data.is_empty():
		var file := FileAccess.open("res://data/homes.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for home in parsed.get("homes", []):
					_data[str(home.get("id", ""))] = home
	return _data


static func venue_for(id: String) -> Dictionary:
	var home: Dictionary = all().get(id, {})
	if home.is_empty():
		return {}
	return {
		"name": str(home.get("name", "A house")),
		"x": 0, "z": 0, "w": float(home.get("w", 8)), "d": float(home.get("d", 8)),
		"opening": "door", "open_w": 2, "windows": true,
		"home": true, "style": str(home.get("style", "brick")), "kind": str(home.get("kind", "house")),
		"theme": "home_" + str(home.get("style", "brick")),
		"floors": home.get("floors", []),
		"box_row": 1.4,
		"music": "music_act1_home", "ambience": str(STYLE_AIR.get(str(home.get("style", "brick")), "amb_l04_shop_clock_loop")),
	}


static func is_home(venue: Dictionary) -> bool:
	return bool(venue.get("home", false))


static func floors(venue: Dictionary) -> Array:
	return venue.get("floors", [])


static func floor_name(venue: Dictionary, index: int) -> String:
	var list := floors(venue)
	if index < 0 or index >= list.size():
		return ""
	return str(list[index].get("name", "Floor %d" % (index + 1)))


static func rooms(venue: Dictionary, index: int) -> Array:
	var list := floors(venue)
	if index < 0 or index >= list.size():
		return []
	return list[index].get("rooms", [])


static func kind(room_id: String) -> String:
	return room_id.rstrip("0123456789")


static func tag_of_kind(room_kind: String) -> String:
	return str(KIND_TAG.get(room_kind, ""))


static func room_at(venue: Dictionary, index: int, x: float, z: float) -> Dictionary:
	var ox := float(venue.get("x", 0))
	var oz := float(venue.get("z", 0))
	for room in rooms(venue, index):
		var rx := ox + float(room.get("x", 0))
		var rz := oz + float(room.get("z", 0))
		if x >= rx - 0.001 and x <= rx + float(room.get("w", 0)) + 0.001 and z >= rz - 0.001 and z <= rz + float(room.get("d", 0)) + 0.001:
			return room
	return {}


static func has_tag(venue: Dictionary, tag: String) -> bool:
	for index in floors(venue).size():
		for room in rooms(venue, index):
			if tag_of_kind(kind(str(room.get("id", "")))) == tag:
				return true
	return false


static func floor_for_tag(venue: Dictionary, tag: String) -> int:
	# The first floor with a room this kind of item belongs in; ground floor otherwise.
	if tag == "":
		return 0
	for index in floors(venue).size():
		for room in rooms(venue, index):
			if tag_of_kind(kind(str(room.get("id", "")))) == tag:
				return index
	return 0


static func stairs(venue: Dictionary, index: int) -> Vector3:
	# World position of the stair foot on this floor, or Vector3.INF when none.
	var list := floors(venue)
	if index < 0 or index >= list.size() or not list[index].has("stairs"):
		return Vector3.INF
	var at: Array = list[index]["stairs"]
	return Vector3(float(venue.get("x", 0)) + float(at[0]), 0.0, float(venue.get("z", 0)) + float(at[1]))


static func stairs_rect(venue: Dictionary, index: int) -> Rect2:
	var at := stairs(venue, index)
	if at == Vector3.INF:
		return Rect2()
	return Rect2(at.x - STAIRS_W * 0.5, at.z - STAIRS_D * 0.5, STAIRS_W, STAIRS_D)


static func _shared_edges(venue: Dictionary, index: int) -> Array:
	# Every edge two rooms share: {along_x, fixed, a, b}. Outer walls are the shell's.
	var ox := float(venue.get("x", 0))
	var oz := float(venue.get("z", 0))
	var list := rooms(venue, index)
	var edges: Array = []
	for i in list.size():
		for j in range(i + 1, list.size()):
			var p: Dictionary = list[i]
			var q: Dictionary = list[j]
			var px := float(p["x"])
			var pz := float(p["z"])
			var pw := float(p["w"])
			var pd := float(p["d"])
			var qx := float(q["x"])
			var qz := float(q["z"])
			var qw := float(q["w"])
			var qd := float(q["d"])
			var ox1 := maxf(px, qx)
			var ox2 := minf(px + pw, qx + qw)
			var oz1 := maxf(pz, qz)
			var oz2 := minf(pz + pd, qz + qd)
			if absf(px + pw - qx) < 0.001 or absf(qx + qw - px) < 0.001:
				if oz2 - oz1 > 0.05:
					edges.append({"along_x": false, "fixed": ox + (qx if absf(px + pw - qx) < 0.001 else px), "a": oz + oz1, "b": oz + oz2})
			elif absf(pz + pd - qz) < 0.001 or absf(qz + qd - pz) < 0.001:
				if ox2 - ox1 > 0.05:
					edges.append({"along_x": true, "fixed": oz + (qz if absf(pz + pd - qz) < 0.001 else pz), "a": ox + ox1, "b": ox + ox2})
	return edges


static func doorways(venue: Dictionary, index: int) -> Array:
	# Centre of every doorway on this floor (the front door included downstairs).
	var out: Array = []
	for edge in _shared_edges(venue, index):
		if float(edge["b"]) - float(edge["a"]) < DOOR_MIN:
			continue
		var mid := (float(edge["a"]) + float(edge["b"])) * 0.5
		out.append(Vector3(mid, 0, float(edge["fixed"])) if bool(edge["along_x"]) else Vector3(float(edge["fixed"]), 0, mid))
	if index == 0:
		out.append(Vector3(float(venue.get("x", 0)) + float(venue.get("w", 8)) * 0.5, 0, float(venue.get("z", 0))))
	return out


static func walls(venue: Dictionary, index: int) -> Array:
	# Wall runs with the doorways cut out: {along_x, fixed, a, b}.
	var out: Array = []
	for edge in _shared_edges(venue, index):
		var a := float(edge["a"])
		var b := float(edge["b"])
		if b - a < DOOR_MIN:
			out.append(edge)
			continue
		var mid := (a + b) * 0.5
		var left := {"along_x": edge["along_x"], "fixed": edge["fixed"], "a": a, "b": mid - DOOR_W * 0.5}
		var right := {"along_x": edge["along_x"], "fixed": edge["fixed"], "a": mid + DOOR_W * 0.5, "b": b}
		if float(left["b"]) - float(left["a"]) > 0.05:
			out.append(left)
		if float(right["b"]) - float(right["a"]) > 0.05:
			out.append(right)
	return out


static func wall_rects(venue: Dictionary, index: int, pad := 0.0) -> Array:
	var out: Array = []
	for wall in walls(venue, index):
		var t := WALL_T * 0.5 + pad
		if bool(wall["along_x"]):
			out.append(Rect2(float(wall["a"]) - pad, float(wall["fixed"]) - t, float(wall["b"]) - float(wall["a"]) + pad * 2.0, t * 2.0))
		else:
			out.append(Rect2(float(wall["fixed"]) - t, float(wall["a"]) - pad, t * 2.0, float(wall["b"]) - float(wall["a"]) + pad * 2.0))
	var steps := stairs_rect(venue, index)
	if steps.size.x > 0.0:
		out.append(steps.grow(pad))
	return out


static func crosses_wall(venue: Dictionary, index: int, footprint: Rect2) -> bool:
	# A piece whose footprint overlaps an interior wall or the stairs cannot stand there.
	for rect in wall_rects(venue, index, 0.02):
		if (rect as Rect2).intersects(footprint):
			return true
	return false


static func footprint(pos: Vector3, rot_deg: float, w: float, d: float) -> Rect2:
	var turned := absf(fmod(absf(rot_deg), 180.0) - 90.0) < 1.0
	var fw := d if turned else w
	var fd := w if turned else d
	return Rect2(pos.x - fw * 0.5, pos.z - fd * 0.5, fw, fd)


static func build(parent: Node3D, venue: Dictionary, index: int, wall_color: Color, trim_color: Color, floor_color: Color, with_walls: bool) -> Node3D:
	# The blueprint of one floor: tinted floor and a name per room, the
	# interior walls cut down to waist height so every room reads from the
	# camera, door posts, and the stairs or the stairwell.
	var root := Node3D.new()
	root.name = "Interior"
	root.set_meta("floor", index)
	parent.add_child(root)
	var ox := float(venue.get("x", 0))
	var oz := float(venue.get("z", 0))
	for room in rooms(venue, index):
		var room_kind := kind(str(room.get("id", "")))
		var rx := ox + float(room.get("x", 0))
		var rz := oz + float(room.get("z", 0))
		var rw := float(room.get("w", 2))
		var rd := float(room.get("d", 2))
		var tint := floor_color.lerp(Color(str(KIND_TINT.get(room_kind, "D9C9A8"))), 0.42)
		var pad := Props.mesh_box(Vector3(rw - 0.16, 0.012, rd - 0.16), tint)
		pad.name = "RoomFloor_" + str(room.get("id", ""))
		pad.position = Vector3(rx + rw * 0.5, 0.018, rz + rd * 0.5)
		root.add_child(pad)
		var label := Label3D.new()
		label.name = "RoomName_" + str(room.get("id", ""))
		label.text = str(room.get("name", room_kind)).to_upper()
		label.font_size = 54
		label.pixel_size = 0.0045
		label.modulate = Color(0.16, 0.14, 0.12, 0.62)
		label.outline_size = 0
		label.no_depth_test = false
		label.transform.basis = Basis(Vector3(1, 0, -1).normalized(), Vector3(-1, 0, -1).normalized(), Vector3(0, 1, 0))
		# Toward the near corner of the room, where the camera looks first.
		label.position = Vector3(rx + rw * 0.5 + minf(rw, 1.6) * 0.18, 0.03, rz + rd * 0.5 + minf(rd, 1.6) * 0.18)
		root.add_child(label)
	if with_walls:
		for wall in walls(venue, index):
			var length := float(wall["b"]) - float(wall["a"])
			var mid := (float(wall["a"]) + float(wall["b"])) * 0.5
			var along_x := bool(wall["along_x"])
			var piece := StaticBody3D.new()
			piece.name = "InnerWall_%d" % root.get_child_count()
			piece.collision_layer = Props.LAYER_BLOCKING
			piece.collision_mask = Props.LAYER_BLOCKING
			piece.position = Vector3(mid, 0, float(wall["fixed"])) if along_x else Vector3(float(wall["fixed"]), 0, mid)
			piece.rotation.y = 0.0 if along_x else PI * 0.5
			var body := Props.mesh_box(Vector3(length, WALL_H, WALL_T), wall_color)
			body.position = Vector3(0, WALL_H * 0.5, 0)
			piece.add_child(body)
			var cap := Props.mesh_box(Vector3(length + 0.04, 0.04, WALL_T + 0.08), trim_color)
			cap.position = Vector3(0, WALL_H + 0.02, 0)
			piece.add_child(cap)
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(length, WALL_H, WALL_T)
			shape.shape = box
			shape.position = Vector3(0, WALL_H * 0.5, 0)
			piece.add_child(shape)
			root.add_child(piece)
		for door in doorways(venue, index):
			if index == 0 and absf(door.z - oz) < 0.01:
				continue
			var post_a := Props.mesh_box(Vector3(0.1, WALL_H + 0.12, 0.18), trim_color)
			var post_b := Props.mesh_box(Vector3(0.1, WALL_H + 0.12, 0.18), trim_color)
			var along_x := _door_along_x(venue, index, door)
			var off := Vector3(DOOR_W * 0.5 + 0.05, 0, 0) if along_x else Vector3(0, 0, DOOR_W * 0.5 + 0.05)
			post_a.position = door + off + Vector3(0, (WALL_H + 0.12) * 0.5, 0)
			post_b.position = door - off + Vector3(0, (WALL_H + 0.12) * 0.5, 0)
			if not along_x:
				post_a.rotation.y = PI * 0.5
				post_b.rotation.y = PI * 0.5
			root.add_child(post_a)
			root.add_child(post_b)
	var foot := stairs(venue, index)
	if foot != Vector3.INF:
		root.add_child(_stairs_node(index < floors(venue).size() - 1, index > 0, foot, trim_color, wall_color))
	return root


static func _door_along_x(venue: Dictionary, index: int, door: Vector3) -> bool:
	for edge in _shared_edges(venue, index):
		if bool(edge["along_x"]) and absf(float(edge["fixed"]) - door.z) < 0.01 and door.x >= float(edge["a"]) and door.x <= float(edge["b"]):
			return true
	return false


static func _stairs_node(goes_up: bool, goes_down: bool, foot: Vector3, trim_color: Color, wall_color: Color) -> Node3D:
	var node := Node3D.new()
	node.name = "Stairs"
	node.position = foot
	node.set_meta("uid", "stairs")
	if goes_up:
		# Six treads rising along +z, a banister on the open side.
		var treads := 6
		for i in treads:
			var tread := Props.mesh_box(Vector3(STAIRS_W, 0.16, STAIRS_D / float(treads)), trim_color.lightened(0.12 * float(i % 2)))
			tread.position = Vector3(0, 0.08 + float(i) * 0.17, -STAIRS_D * 0.5 + STAIRS_D / float(treads) * (float(i) + 0.5))
			node.add_child(tread)
		var rail := Props.mesh_box(Vector3(0.05, 0.05, STAIRS_D), trim_color.darkened(0.2))
		rail.position = Vector3(STAIRS_W * 0.5 + 0.02, 0.95, 0)
		rail.rotation.x = -atan2(0.17 * 6.0, STAIRS_D)
		node.add_child(rail)
		for i in 3:
			var post := Props.mesh_box(Vector3(0.05, 0.55 + float(i) * 0.33, 0.05), trim_color.darkened(0.2))
			post.position = Vector3(STAIRS_W * 0.5 + 0.02, post.mesh.size.y * 0.5 + float(i) * 0.03, -STAIRS_D * 0.5 + 0.2 + float(i) * (STAIRS_D - 0.4) * 0.5)
			node.add_child(post)
	else:
		# The top of the stairs: the well, a landing rail round it, the first tread down.
		var well := Props.mesh_box(Vector3(STAIRS_W, 0.03, STAIRS_D), wall_color.darkened(0.55))
		well.position = Vector3(0, 0.025, 0)
		node.add_child(well)
		var tread := Props.mesh_box(Vector3(STAIRS_W, 0.14, 0.4), trim_color)
		tread.position = Vector3(0, 0.07, STAIRS_D * 0.5 - 0.2)
		node.add_child(tread)
		var rail := Props.mesh_box(Vector3(0.05, 0.9, STAIRS_D), trim_color.darkened(0.2))
		rail.position = Vector3(STAIRS_W * 0.5 + 0.02, 0.45, 0)
		node.add_child(rail)
		var rail2 := Props.mesh_box(Vector3(STAIRS_W, 0.9, 0.05), trim_color.darkened(0.2))
		rail2.position = Vector3(0, 0.45, -STAIRS_D * 0.5 - 0.02)
		node.add_child(rail2)
	var body := StaticBody3D.new()
	body.name = "StairsCollision"
	body.collision_layer = Props.LAYER_BLOCKING
	body.collision_mask = Props.LAYER_BLOCKING
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(STAIRS_W, 1.0, STAIRS_D)
	shape.shape = box
	shape.position = Vector3(0, 0.5, 0)
	body.add_child(shape)
	node.add_child(body)
	Props.add_picker(node, Vector3(STAIRS_W + 0.2, 1.1, STAIRS_D))
	node.set_meta("goes_up", goes_up)
	node.set_meta("goes_down", goes_down)
	return node


static func value_of(def: Dictionary) -> int:
	# What Sal would give for it, roughly: big pieces more, fragile ones a little more.
	var value := 12
	if bool(def.get("nobox", false)):
		value = 25
	if bool(def.get("heavy", false)):
		value = 40
	if bool(def.get("fragile", false)):
		value += 6
	return value


static func pocketable(def: Dictionary) -> bool:
	return not bool(def.get("heavy", false))


static func owner_layout(venue: Dictionary, seed: int) -> Array:
	# The client's own pieces, standing along the far walls of each room so
	# the middle stays clear for what comes off the truck.
	var out: Array = []
	if not is_home(venue):
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var ox := float(venue.get("x", 0))
	var oz := float(venue.get("z", 0))
	var n := 0
	for index in floors(venue).size():
		var blocked := wall_rects(venue, index, 0.05)
		for door in doorways(venue, index):
			blocked.append(Rect2(door.x - 0.8, door.z - 0.8, 1.6, 1.6))
		if index == 0:
			# Keep the box row and the front of the house clear.
			blocked.append(Rect2(ox, oz + float(venue.get("d", 8)) - 2.6, float(venue.get("w", 8)), 2.6))
		for room in rooms(venue, index):
			var room_kind := kind(str(room.get("id", "")))
			var pool: Array = (OWNER_ITEMS.get(room_kind, []) as Array).duplicate()
			if pool.is_empty():
				continue
			var rx := ox + float(room.get("x", 0))
			var rz := oz + float(room.get("z", 0))
			var rw := float(room.get("w", 2))
			var rd := float(room.get("d", 2))
			var want := mini(pool.size(), 2 + (1 if rw * rd > 11.0 else 0))
			# Slots along the back wall (min z) and the left wall (min x): the sides the camera looks into.
			var slots: Array = []
			for f in [0.22, 0.5, 0.78]:
				slots.append({"x": rx + rw * f, "z": rz, "rot": 0.0, "side": "back"})
			for f in [0.3, 0.7]:
				slots.append({"x": rx, "z": rz + rd * f, "rot": 90.0, "side": "left"})
			var placed := 0
			var k := 0
			while placed < want and k < pool.size():
				var item_id := str(pool[k])
				k += 1
				var def: Dictionary = ItemDB.get_item(item_id)
				if def.is_empty():
					continue
				var w := float(def.get("w", 0.4))
				var d := float(def.get("d", 0.4))
				var found := false
				for s in slots.size():
					var slot: Dictionary = slots[(s + rng.randi() % slots.size()) % slots.size()]
					if bool(slot.get("used", false)):
						continue
					var pos := Vector3(float(slot["x"]), 0.0, float(slot["z"]))
					var rot := float(slot["rot"])
					if str(slot["side"]) == "back":
						pos.z += d * 0.5 + 0.14
					else:
						pos.x += d * 0.5 + 0.14
					var rect := footprint(pos, rot, w, d)
					if rect.position.x < rx + 0.1 or rect.end.x > rx + rw - 0.1 or rect.position.y < rz + 0.1 or rect.end.y > rz + rd - 0.1:
						continue
					var clear := true
					for b in blocked:
						if (b as Rect2).intersects(rect):
							clear = false
							break
					if not clear:
						continue
					slot["used"] = true
					blocked.append(rect.grow(0.25))
					out.append({
						"uid": "owner:%d" % n, "item_id": item_id, "name": str(def.get("name", item_id)),
						"x": pos.x, "y": 0.0, "z": pos.z, "rot": rot, "floor": index, "room": str(room.get("id", "")),
						"state": "placed", "value": value_of(def), "pocketable": pocketable(def),
					})
					n += 1
					placed += 1
					found = true
					break
				if not found:
					continue
	return out
