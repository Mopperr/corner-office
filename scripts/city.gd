extends RefCounted
# The town the truck drives through: a grid of blocks with roads between
# them, one park, one alley, and a loading bay at the curb of every place.
# Everything is in drive pixels (32 px per metre), built from data/city.json.

var cols := 5
var rows := 4
var block := Vector2(640, 480)
var road := 192.0
var sidewalk := 48.0
var park_block := Vector2i(4, 0)
var alley := Rect2()
var alley_block := Vector2i(-1, -1)
var buildings: Array = []
var roads: Array = []
var places: Dictionary = {}
var shops: Array = []
var roof_colors: Array = []
var bounds := Rect2()


static func load_default():
	var city = load("res://scripts/city.gd").new()
	var file := FileAccess.open("res://data/city.json", FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			city.setup(parsed)
			return city
	city.setup({})
	return city


func setup(data: Dictionary) -> void:
	cols = int(data.get("cols", cols))
	rows = int(data.get("rows", rows))
	var size: Array = data.get("block", [640, 480])
	block = Vector2(float(size[0]), float(size[1]))
	road = float(data.get("road", road))
	sidewalk = float(data.get("sidewalk", sidewalk))
	var park: Array = data.get("park", [4, 0])
	park_block = Vector2i(int(park[0]), int(park[1]))
	roof_colors = data.get("roof_colors", ["B9A58C"])
	bounds = Rect2(0, 0, road + cols * (block.x + road), road + rows * (block.y + road))
	var alley_def: Dictionary = data.get("alley", {})
	if not alley_def.is_empty():
		var at: Array = alley_def.get("block", [2, 1])
		alley_block = Vector2i(int(at[0]), int(at[1]))
		var rect := block_rect(alley_block.x, alley_block.y)
		var width := float(alley_def.get("width", 72))
		if str(alley_def.get("axis", "y")) == "y":
			alley = Rect2(rect.position.x + rect.size.x * 0.5 - width * 0.5, rect.position.y - road * 0.5, width, rect.size.y + road)
		else:
			alley = Rect2(rect.position.x - road * 0.5, rect.position.y + rect.size.y * 0.5 - width * 0.5, rect.size.x + road, width)
	roads.clear()
	for i in cols + 1:
		roads.append(Rect2(i * (block.x + road), 0, road, bounds.size.y))
	for j in rows + 1:
		roads.append(Rect2(0, j * (block.y + road), bounds.size.x, road))
	buildings.clear()
	for c in cols:
		for r in rows:
			if Vector2i(c, r) == park_block:
				continue
			var footprint := block_rect(c, r).grow(-sidewalk)
			var color := Color(str(roof_colors[(c * 3 + r * 5) % roof_colors.size()]))
			if Vector2i(c, r) == alley_block and alley.size != Vector2.ZERO:
				# The alley splits this block in two.
				if alley.size.y > alley.size.x:
					var left := Rect2(footprint.position, Vector2(alley.position.x - footprint.position.x, footprint.size.y))
					var right := Rect2(Vector2(alley.end.x, footprint.position.y), Vector2(footprint.end.x - alley.end.x, footprint.size.y))
					buildings.append({"rect": left, "color": color, "block": Vector2i(c, r)})
					buildings.append({"rect": right, "color": color.darkened(0.08), "block": Vector2i(c, r)})
				else:
					var top := Rect2(footprint.position, Vector2(footprint.size.x, alley.position.y - footprint.position.y))
					var bottom := Rect2(Vector2(footprint.position.x, alley.end.y), Vector2(footprint.size.x, footprint.end.y - alley.end.y))
					buildings.append({"rect": top, "color": color, "block": Vector2i(c, r)})
					buildings.append({"rect": bottom, "color": color.darkened(0.08), "block": Vector2i(c, r)})
			else:
				buildings.append({"rect": footprint, "color": color, "block": Vector2i(c, r)})
	places.clear()
	for place in data.get("places", []):
		var entry := _curb_entry(place)
		places[str(place.get("id", ""))] = entry
	shops.clear()
	for shop in data.get("shops", []):
		shops.append(_curb_entry(shop))


func block_rect(c: int, r: int) -> Rect2:
	return Rect2(road + c * (block.x + road), road + r * (block.y + road), block.x, block.y)


func park_rect() -> Rect2:
	return block_rect(park_block.x, park_block.y)


func pond() -> Dictionary:
	var rect := park_rect()
	return {"center": rect.get_center() + Vector2(40, 10), "radius": minf(rect.size.x, rect.size.y) * 0.3}


func place(id: String) -> Dictionary:
	return places.get(id, {})


func _curb_entry(spec: Dictionary) -> Dictionary:
	var at: Array = spec.get("block", [0, 0])
	var c := int(at[0])
	var r := int(at[1])
	var rect := block_rect(c, r)
	var side := str(spec.get("side", "N"))
	var t := float(spec.get("t", 0.5))
	var bay := Rect2()
	var door := Vector2.ZERO
	var heading := 0.0
	var lane := road * 0.5
	match side:
		"N":
			door = Vector2(rect.position.x + rect.size.x * t, rect.position.y)
			bay = Rect2(door.x - 90, rect.position.y - lane + 10, 180, lane - 20)
			heading = 0.0
		"S":
			door = Vector2(rect.position.x + rect.size.x * t, rect.end.y)
			bay = Rect2(door.x - 90, rect.end.y + 10, 180, lane - 20)
			heading = PI
		"W":
			door = Vector2(rect.position.x, rect.position.y + rect.size.y * t)
			bay = Rect2(rect.position.x - lane + 10, door.y - 90, lane - 20, 180)
			heading = PI * 0.5
		_:
			door = Vector2(rect.end.x, rect.position.y + rect.size.y * t)
			bay = Rect2(rect.end.x + 10, door.y - 90, lane - 20, 180)
			heading = -PI * 0.5
	return {
		"id": str(spec.get("id", spec.get("name", ""))),
		"name": str(spec.get("name", "")),
		"block": Vector2i(c, r),
		"side": side,
		"door": door,
		"bay": bay,
		"heading": heading,
		"color": Color(str(spec.get("color", "C9B9A0"))),
		"rect": rect,
	}


func on_road(p: Vector2) -> bool:
	for rect in roads:
		if (rect as Rect2).grow(10).has_point(p):
			return true
	if alley.size != Vector2.ZERO and alley.grow(6).has_point(p):
		return true
	return false


func in_park(p: Vector2) -> bool:
	return park_rect().has_point(p)


func node_at(i: int, j: int) -> Vector2:
	return Vector2(i * (block.x + road) + road * 0.5, j * (block.y + road) + road * 0.5)


func nearest_node(p: Vector2) -> Vector2i:
	var i := clampi(int(round((p.x - road * 0.5) / (block.x + road))), 0, cols)
	var j := clampi(int(round((p.y - road * 0.5) / (block.y + road))), 0, rows)
	return Vector2i(i, j)


func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	# Shortest path over the intersections, then straight to the curb at each end.
	var start := _road_node(from)
	var goal := _road_node(to)
	var prev: Dictionary = {}
	var queue: Array = [start]
	prev[start] = start
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			break
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = current + step
			if next.x < 0 or next.y < 0 or next.x > cols or next.y > rows:
				continue
			if prev.has(next):
				continue
			prev[next] = current
			queue.append(next)
	var points := PackedVector2Array()
	points.append(from)
	var chain: Array = []
	var walk: Vector2i = goal
	var guard := 0
	while walk != start and guard < 200:
		chain.push_front(walk)
		walk = prev.get(walk, start)
		guard += 1
	chain.push_front(start)
	for node in chain:
		points.append(node_at(node.x, node.y))
	points.append(to)
	return _tidy(points)


func _road_node(p: Vector2) -> Vector2i:
	# The intersection you would actually drive to first: along the road the curb is on.
	var best := nearest_node(p)
	var best_d := INF
	for i in cols + 1:
		for j in rows + 1:
			var n := node_at(i, j)
			var on_same_road := absf(n.x - p.x) < road or absf(n.y - p.y) < road
			if not on_same_road:
				continue
			var d := n.distance_to(p)
			if d < best_d:
				best_d = d
				best = Vector2i(i, j)
	return best


func _tidy(points: PackedVector2Array) -> PackedVector2Array:
	# Drop a node that sits right next to the curb point, so the truck does not double back.
	var out := PackedVector2Array()
	for i in points.size():
		if i > 0 and i < points.size() - 1 and points[i].distance_to(points[i - 1]) < 30.0:
			continue
		out.append(points[i])
	if out.size() >= 3 and out[1].distance_to(out[0]) > out[2].distance_to(out[0]) + 60.0:
		out.remove_at(1)
	var n := out.size()
	if n >= 3 and out[n - 2].distance_to(out[n - 1]) > out[n - 3].distance_to(out[n - 1]) + 60.0:
		out.remove_at(n - 2)
	return out


func point_along(points: PackedVector2Array, fraction: float) -> Dictionary:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	var target := clampf(fraction, 0.0, 1.0) * total
	var run := 0.0
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if run + seg >= target or i == points.size() - 1:
			var t := 0.0 if seg <= 0.0 else clampf((target - run) / seg, 0.0, 1.0)
			var dir := (points[i] - points[i - 1]).normalized()
			return {"pos": points[i - 1].lerp(points[i], t), "dir": dir}
		run += seg
	return {"pos": points[0] if points.size() > 0 else Vector2.ZERO, "dir": Vector2.RIGHT}


func traffic_loops() -> Array:
	# Right-hand traffic: a clockwise lap around a block keeps the curb on the right.
	var loops: Array = []
	for c in cols:
		for r in rows:
			var rect := block_rect(c, r).grow(road * 0.25)
			loops.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	return loops


func curb_spots(rng: RandomNumberGenerator) -> Array:
	# A few sidewalk positions per block for lamp posts, mailboxes, and parked cars.
	var spots: Array = []
	for c in cols:
		for r in rows:
			if Vector2i(c, r) == park_block:
				continue
			var rect := block_rect(c, r)
			spots.append({"kind": "lamppost", "at": rect.position + Vector2(sidewalk * 0.5, sidewalk * 0.5)})
			spots.append({"kind": "lamppost", "at": rect.end - Vector2(sidewalk * 0.5, sidewalk * 0.5)})
			if rng.randf() < 0.5:
				spots.append({"kind": "mailbox", "at": Vector2(rect.end.x - sidewalk * 0.5, rect.position.y + rect.size.y * 0.3)})
			if rng.randf() < 0.6:
				spots.append({"kind": "parked_car", "at": Vector2(rect.position.x + rect.size.x * rng.randf_range(0.6, 0.85), rect.end.y + road * 0.25), "rot": 0.0})
			if rng.randf() < 0.4:
				spots.append({"kind": "umbrella", "at": Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + sidewalk * 0.5)})
	return spots
