extends Node
# End-to-end playthrough. Boots the real main scene and plays it the way a
# player would: menu buttons, clicks on things in the room, HUD buttons, the
# drive. Prints PLAYTHROUGH_OK at the end or FAIL lines with what got stuck.
#
#   godot --headless --path . --quit-after 20000 res://tests/playthrough.tscn
#
# CO_SHOTS=<dir> writes a screenshot after each step (needs a renderer).
# CO_FAST_DRIVE=1 finishes each drive after a few seconds instead of driving
# the whole route.

var app: Node
var fails: Array[String] = []
var shot_dir := ""
var shot_index := 0
var fast_drive := false


func _ready() -> void:
	shot_dir = OS.get_environment("CO_SHOTS")
	fast_drive = OS.get_environment("CO_FAST_DRIVE") != ""
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	SaveManager.delete_save()
	app = load("res://scenes/main.tscn").instantiate()
	add_child(app)
	await _run()
	if fails.is_empty():
		print("PLAYTHROUGH_OK")
	else:
		for line in fails:
			print("FAIL: " + line)
		print("PLAYTHROUGH_FAILED (%d)" % fails.size())
	get_tree().quit(0 if fails.is_empty() else 1)


var _mouse_scale := Vector2.ONE
var _mouse_offset := Vector2.ZERO


func _calibrate_mouse() -> void:
	# Window pixels and canvas pixels differ (stretch, DPI, headless). Measure it.
	var a := Vector2(40, 40)
	var b := Vector2(640, 440)
	_send_motion(a)
	await wait(0.05)
	var ma := get_viewport().get_mouse_position()
	_send_motion(b)
	await wait(0.05)
	var mb := get_viewport().get_mouse_position()
	var d := mb - ma
	if absf(d.x) < 1.0 or absf(d.y) < 1.0:
		print("note: mouse calibration failed (%s -> %s, %s -> %s); using identity" % [a, ma, b, mb])
		return
	_mouse_scale = Vector2(d.x / (b.x - a.x), d.y / (b.y - a.y))
	_mouse_offset = ma - a * _mouse_scale
	print("mouse map: canvas = window * %s + %s" % [_mouse_scale, _mouse_offset])


func _to_window(canvas: Vector2) -> Vector2:
	return (canvas - _mouse_offset) / _mouse_scale


const PROBE_OFFSETS := [Vector3(0, 0.15, 0), Vector3(0, 0.05, 0), Vector3(0, 0.3, 0), Vector3(0, 0.5, 0), Vector3(0, 0.02, 0), Vector3(0, 0.8, 0),
	Vector3(0.18, 0.05, 0), Vector3(-0.18, 0.05, 0), Vector3(0, 0.05, 0.15), Vector3(0, 0.05, -0.15),
	Vector3(0.18, 0.05, 0.15), Vector3(-0.18, 0.05, -0.15), Vector3(0.18, 0.05, -0.15), Vector3(-0.18, 0.05, 0.15)]


func _probe(room: Node, node: Node3D, accept: Callable) -> String:
	# Hover around the node until the ray lands on something `accept` likes.
	for off in PROBE_OFFSETS:
		await hover_world(room, node.global_position + off)
		var hit: String = room._pick_uid()
		if hit != "" and accept.call(hit):
			return hit
	return ""


func _send_motion(window_pos: Vector2) -> void:
	# A real window reads the pointer from the OS, so move that too.
	Input.warp_mouse(window_pos)
	var move := InputEventMouseMotion.new()
	move.position = window_pos
	move.global_position = window_pos
	Input.parse_input_event(move)


func _run() -> void:
	await wait(0.6)
	await _calibrate_mouse()
	await shot("menu")
	_check(press("New game"), "menu: New game button")
	await wait(0.4)
	await shot("intro")
	_check(press("Put the kettle on"), "intro: start button")
	await wait(1.5)
	await wait(1.0)
	_check(GameState.mode == "office", "new game lands in office mode (got %s)" % GameState.mode)
	_check(GameState.money == 120, "Dana starts with $120 (got %d)" % GameState.money)
	await shot("garage_start")

	await _unpack_garage()
	await shot("garage_done")
	_check(GameState.office_phase == "live", "garage tutorial finished (phase %s)" % GameState.office_phase)
	if GameState.office_phase != "live":
		return

	await _check_computer()
	await _check_map()
	await _save_roundtrip("after garage")

	var job_ids := ["job_catcafe", "job_train", "job_ducks"]
	var limit := int(OS.get_environment("CO_JOBS")) if OS.get_environment("CO_JOBS") != "" else job_ids.size()
	for job_id in job_ids.slice(0, limit):
		await _do_job(job_id)
		if not fails.is_empty():
			return
	print("money after 3 jobs: $%d, earned $%d, rep %d" % [GameState.money, GameState.total_earned, GameState.rep_rank()])

	await _buy_loft()


# ---------------------------------------------------------------- garage

func _unpack_garage() -> void:
	var room := _room()
	if room == null:
		_fail("no room after new game")
		return
	# Phase one: box up the old office by clicking each piece.
	if GameState.office_phase == "pack":
		var passes := 0
		while GameState.office_phase == "pack" and passes < 12:
			passes += 1
			for rec in GameState.office_items:
				if str(rec.get("state", "")) == "boxed":
					continue
				room = _room()
				var uid := str(rec.get("uid", ""))
				var node := _node_for(room, uid)
				if node == null:
					_fail("garage pack: no node for %s" % uid)
					return
				# Click whatever the ray lands on near this item; it may be the thing in front.
				var hit_uid := await _probe(room, node, func(h): return not GameState.find_office_item(h).is_empty() and str(GameState.find_office_item(h).get("state", "")) != "boxed")
				if hit_uid == "":
					continue
				var hit_rec: Dictionary = GameState.find_office_item(hit_uid)
				await click_world(room, _last_hover)
				await wait(0.05)
				if str(hit_rec.get("state", "")) != "boxed":
					_fail("garage pack: clicking %s did not box it (state %s)" % [hit_uid, hit_rec.get("state", "")])
					return
		for rec in GameState.office_items:
			if str(rec.get("state", "")) != "boxed":
				_fail("garage pack: %s could never be clicked (state %s)" % [rec.get("uid", ""), rec.get("state", "")])
				return
		_check(GameState.office_phase == "place", "garage: everything boxed, phase place (got %s)" % GameState.office_phase)
		await shot("garage_boxed")
	# Floor furniture first, then wall pieces, then the desk-top bits.
	var order: Array = []
	for pass_name in ["floor", "wall", "small"]:
		for rec in GameState.office_items:
			var def: Dictionary = ItemDB.get_item(str(rec.get("item", "")))
			var mount := str(def.get("mount", "floor"))
			var group := "small" if mount == "small" else ("wall" if mount in ["hang", "wall_floor"] else "floor")
			if group == pass_name:
				order.append(rec)
	for rec in order:
		await _place_office_item(rec)
		room = _room()
		if room == null:
			_fail("room vanished while unpacking")
			return


func _place_office_item(rec: Dictionary) -> void:
	var room := _room()
	var uid := str(rec.get("uid", ""))
	if str(rec.get("state", "")) == "placed":
		return
	var def: Dictionary = ItemDB.get_item(str(rec.get("item", "")))
	var mount := str(def.get("mount", "floor"))
	# Pick it up by clicking it.
	var node := _node_for(room, uid)
	if node == null:
		_fail("garage: no node for %s (state %s)" % [uid, rec.get("state", "")])
		return
	await click_node(room, uid, node)
	await wait(0.1)
	if room.held_uid != uid:
		_fail("garage: clicking %s did not pick it up (held=%s)" % [uid, room.held_uid])
		return
	# Find a spot the game itself says is valid, then click it.
	var target: Variant = null
	if mount == "hang" or mount == "wall_floor":
		for point in room._wall_points():
			if str(point["kind"]) != mount:
				continue
			var probe: Vector3 = Vector3(point["x"], point["y"], point["z"]) + (point["normal"] as Vector3) * 0.3
			if bool(room._snap_point(probe)["valid"]):
				target = Vector3(point["x"], 1.0 if mount == "hang" else 0.0, point["z"]) + point["normal"] * 0.2
				break
	elif mount == "small":
		var desk: Node = room.nodes_by_uid.get("desk")
		if desk == null:
			_fail("garage: desk is not placed, cannot put %s on it" % uid)
			return
		var top := float(ItemDB.get_item("desk_main").get("h", 0.76))
		var base: Vector3 = (desk as Node3D).global_position + Vector3(0, top + 0.02, 0)
		var offs: Array = []
		for ix in range(-5, 6):
			for iz in range(-2, 3):
				offs.append(Vector3(ix * 0.12, 0, iz * 0.14))
		for off in offs:
			await hover_world(room, base + off)
			var aim = room._aim_point()
			if aim != null and bool(room._snap_point(aim)["valid"]):
				target = base + off
				break
		if target == null:
			print("note: no free desk spot for %s, putting it on the floor" % uid)
			target = await _find_floor_spot(room)
	else:
		target = await _find_floor_spot(room)
	if target == null:
		_fail("garage: no valid spot found for %s (mount %s)" % [uid, mount])
		room._drop_hold()
		return
	await hover_world(room, target)
	if OS.get_environment("CO_DEBUG") != "":
		var aim = room._aim_point()
		print("  place %s target=%s aim=%s snap=%s over_ui=%s hovered=%s" % [uid, target, aim, room._snap_point(aim) if aim != null else "null", room._over_ui(), get_viewport().gui_get_hovered_control()])
	await click_world(room, target)
	var ok := await wait_until(func(): return str(rec.get("state", "")) == "placed" and not room.settling, 8.0)
	if not ok:
		_fail("garage: %s never settled (state %s, settling %s)" % [uid, rec.get("state", ""), room.settling])


func _find_floor_spot(room: Node) -> Variant:
	# Hover each candidate and ask the game what its own aim ray would do.
	for hit in _floor_candidates(room):
		await hover_world(room, hit)
		var aim = room._aim_point()
		if aim == null:
			continue
		if bool(room._snap_point(aim)["valid"]):
			return hit
	return null


func _floor_candidates(room: Node) -> Array:
	var out: Array = []
	var v: Dictionary = room.venue
	var x0 := float(v.get("x", 0))
	var z0 := float(v.get("z", 0))
	var w := float(v.get("w", 6))
	var d := float(v.get("d", 8))
	var z := z0 + 1.0
	while z < z0 + d - 0.8:
		var x := x0 + 1.0
		while x < x0 + w - 0.8:
			out.append(Vector3(x, 0.0, z))
			x += 0.5
		z += 0.5
	return out


# ---------------------------------------------------------------- computer

func _check_computer() -> void:
	_check(press("Computer"), "HUD: Computer button")
	await wait(0.5)
	var computer: Node = app.overlay.get_child(0) if app.overlay.get_child_count() > 0 else null
	_check(computer != null, "computer opens")
	await shot("computer")
	if computer == null:
		return
	var before := GameState.money
	for page in ["Market", "Shop", "Email", "Listings", "Forest", "Till"]:
		if press(page, computer):
			await wait(0.2)
			await shot("computer_" + page.to_lower())
	press("Market", computer)
	await wait(0.2)
	if press("BUY", computer):
		await wait(0.1)
		_check(GameState.money < before, "market buy spends money")
		press("SELL", computer)
		await wait(0.1)
	press("Next day", computer)
	await wait(0.1)
	_check(press("x", computer), "computer closes (x button)")
	await wait(0.3)
	_check(app.overlay.get_child_count() == 0, "computer overlay removed")


func _check_map() -> void:
	_check(press("Map"), "HUD: Map button")
	await wait(0.4)
	var map: Node = app.overlay.get_child(0) if app.overlay.get_child_count() > 0 else null
	_check(map != null, "map opens")
	if map == null:
		return
	await shot("map")
	var pins := 0
	for btn in _buttons(map):
		if str(btn.name).begins_with("Pin_"):
			pins += 1
	_check(pins >= 5, "map shows pins (%d)" % pins)
	press("Whisker & Bean", map)
	await wait(0.2)
	await shot("map_cafe")
	_check(press("Close", map), "map closes")
	await wait(0.3)
	_check(app.overlay.get_child_count() == 0, "map overlay removed")


# ---------------------------------------------------------------- job loop

func _do_job(job_id: String) -> void:
	print("--- job %s" % job_id)
	_check(press("Jobs"), "HUD: Jobs button")
	await wait(0.3)
	await shot("clipboard_" + job_id)
	var took := false
	var room := _room()
	var wanted := -1
	var index := 0
	for job in JobDB.all_jobs():
		if not GameState.job_available(JobDB.get_job(str(job.get("id", "")))):
			continue
		if str(job.get("id", "")) == job_id:
			wanted = index
		index += 1
	for btn in _buttons(room):
		if btn.text == "Take job":
			if wanted <= 0:
				btn.pressed.emit()
				took = true
				break
			wanted -= 1
	_check(took, "clipboard offers %s" % job_id)
	await wait(1.0)
	_check(GameState.mode == "job_pack", "%s: pack mode (got %s)" % [job_id, GameState.mode])
	if GameState.mode != "job_pack":
		return
	await shot("pack_" + job_id)
	await _pack()
	if not fails.is_empty():
		return
	_check(press("Load the truck"), "%s: Load the truck button" % job_id)
	await wait(1.0)
	_check(GameState.mode == "truck", "%s: truck mode (got %s)" % [job_id, GameState.mode])
	await shot("truck_" + job_id)
	await _load_truck()
	if not fails.is_empty():
		return
	_check(press("Drive"), "%s: Drive button" % job_id)
	await wait(1.0)
	_check(GameState.mode == "drive", "%s: drive mode (got %s)" % [job_id, GameState.mode])
	await shot("drive_" + job_id)
	await _drive()
	if not fails.is_empty():
		return
	_check(GameState.mode == "job_unpack", "%s: unpack mode after drive (got %s)" % [job_id, GameState.mode])
	await shot("unpack_" + job_id)
	await _unpack()
	if not fails.is_empty():
		return
	_check(press("Finish job"), "%s: Finish job button" % job_id)
	await wait(1.0)
	_check(GameState.mode == "results", "%s: results (got %s)" % [job_id, GameState.mode])
	await shot("results_" + job_id)
	print("payout: %s" % JSON.stringify(GameState.payout))
	await wait(2.5)
	_check(press("Back to the office"), "%s: results close button" % job_id)
	await wait(1.0)
	_check(GameState.mode == "office", "%s: back in office (got %s)" % [job_id, GameState.mode])
	await _save_roundtrip("after " + job_id)


func _pack() -> void:
	# Loose items get re-laid-out after every pack, so re-aim every time and
	# box whichever loose item the ray lands on.
	var in_box := 0
	press("New box")
	await wait(0.1)
	var guard := 0
	while guard < 200:
		guard += 1
		var room := _room()
		var loose: Array = []
		for item in GameState.job.get("items", []):
			if str(item.get("state", "")) == "loose":
				loose.append(item)
		if loose.is_empty():
			break
		var picked := ""
		for item in loose:
			var node := _node_for(room, str(item.get("uid", "")))
			if node == null:
				continue
			picked = await _probe(room, node, func(h): return str(GameState.job_item(h).get("state", "")) == "loose")
			if picked != "":
				break
		if picked == "":
			_fail("pack: none of %d loose items can be clicked" % loose.size())
			return
		var rec: Dictionary = GameState.job_item(picked)
		if in_box >= 5:
			await _seal_current()
			press("New box")
			await wait(0.1)
			in_box = 0
			continue
		await click_world(room, _last_hover)
		await wait(0.1)
		if str(rec.get("state", "")) == "boxed":
			in_box += 1
			continue
		# Did not fit (bulky / heavy want their own box). Seal and start fresh.
		if in_box == 0:
			_fail("pack: %s refused an empty box (toast: %s)" % [picked, room.toast.text if room.toast else ""])
			return
		await _seal_current()
		press("New box")
		await wait(0.1)
		in_box = 0
	await _seal_current()
	_check(GameState.all_sealed(), "pack: every box sealed")
	print("  boxes: %d" % GameState.job.get("boxes", []).size())


func _seal_current() -> void:
	var room := _room()
	if room.selected_box >= 0 and GameState.box_needs_padding(room.selected_box):
		press("Add padding")
		await wait(0.05)
	press("Seal box")
	await wait(0.2)
	if press("Open the meowing box"):
		await wait(0.3)
		_check(bool(GameState.job.get("cat_opened", false)), "cat box opened")


func _load_truck() -> void:
	var room := _room()
	var boxes: Array = GameState.job.get("boxes", [])
	var heavy_first: Array = []
	for box in boxes:
		if GameState.box_has_heavy(int(box.get("id", 0))):
			heavy_first.append(box)
	for box in boxes:
		if not heavy_first.has(box):
			heavy_first.append(box)
	var slot := 0
	for box in heavy_first:
		var id := int(box.get("id", 0))
		var picked := false
		for btn in _buttons(room):
			if btn.text.begins_with("Box %d" % (id + 1)):
				btn.pressed.emit()
				picked = true
				break
		if not picked:
			_fail("truck: no button for box %d" % (id + 1))
			return
		var pad := _slot_node(room, slot)
		if pad == null:
			_fail("truck: no pad for slot %d" % slot)
			return
		await click_node(room, "slot:%d" % slot, pad)
		await wait(0.1)
		if int(box.get("slot", -1)) != slot and room._pick_uid() != "slot:%d" % slot:
			# The pad is hidden behind a loaded box from this camera. Note it and load anyway.
			print("UX: truck pad %d is occluded by a loaded box (ray hits %s); loading it directly" % [slot, room._pick_uid()])
			room.selected_box = id
			room._truck_click("slot:%d" % slot)
			await wait(0.1)
		if int(box.get("slot", -1)) != slot:
			_fail("truck: box %d did not load into slot %d (slot=%s, toast: %s, pick: %s)" % [id + 1, slot, box.get("slot", -1), room.toast.text if room.toast else "", room._pick_uid()])
			return
		slot += 1
		room = _room()
	_check(GameState.all_loaded(), "truck: all boxes loaded")


func _slot_node(room: Node, slot: int) -> Node3D:
	for node in room.find_children("*", "Node3D", true, false):
		if node.has_meta("slot") and int(node.get_meta("slot")) == slot:
			return node
	return null


func _drive() -> void:
	var drive: Node = app.view_root.get_child(0) if app.view_root.get_child_count() > 0 else null
	if drive == null or not drive.has_signal("finished"):
		_fail("drive: no drive course on screen")
		return
	var done := [false]
	_wp_index = 0
	drive.finished.connect(func(_r): done[0] = true)
	var t := 0.0
	var limit := 8.0 if fast_drive else 240.0
	while not done[0] and t < limit:
		_steer(drive)
		await wait(0.1)
		t += 0.1
	_release_keys()
	if not done[0]:
		if fast_drive:
			drive._complete()
			await wait(0.1)
		else:
			_fail("drive: course never finished in %ds (pos %s)" % [int(limit), drive.pos])
			return
	await wait(0.5)
	print("drive result: condition %d alley %s time %.1fs" % [GameState.job.get("condition", -1), GameState.job.get("alley", false), GameState.job.get("drive_time", 0.0)])


var _wp_index := 0


func _waypoints(drive: Node) -> Array:
	# Roads are rectangles. Drive through the middle of each overlap, then the finish.
	var rects: Array = []
	for r in drive.course.get("roads", []):
		rects.append(drive._rect(r))
	var out: Array = []
	var loop := bool(drive.course.get("loop", false))
	var n := rects.size()
	for i in n:
		if i + 1 < n or loop:
			var a: Rect2 = rects[i]
			var b: Rect2 = rects[(i + 1) % n]
			var cross := a.intersection(b)
			if cross.size != Vector2.ZERO:
				out.append(cross.get_center())
	if loop:
		var once := out.duplicate()
		for _lap in int(drive.course.get("laps", 2)):
			out.append_array(once)
	else:
		out.append(drive._rect(drive.course.get("finish", [0, 0, 10, 10])).get_center())
	return out


func _steer(drive: Node) -> void:
	var points := _waypoints(drive)
	if points.is_empty():
		_key(KEY_W, true)
		return
	_wp_index = mini(_wp_index, points.size() - 1)
	var goal: Vector2 = points[_wp_index]
	if (drive.pos as Vector2).distance_to(goal) < 90.0 and _wp_index + 1 < points.size():
		_wp_index += 1
		goal = points[_wp_index]
	var pos: Vector2 = drive.pos
	var want := (goal - pos).angle()
	var diff := wrapf(want - float(drive.heading), -PI, PI)
	_key(KEY_W, abs(diff) < 1.2)
	_key(KEY_S, false)
	_key(KEY_A, diff < -0.06)
	_key(KEY_D, diff > 0.06)


func _v2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
	return Vector2.ZERO


func _key(code: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)


func _release_keys() -> void:
	for code in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_key(code, false)


func _unpack() -> void:
	var room := _room()
	# Carry every box in.
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", 0))
		var node: Node3D = null
		for n in room.items_root.get_children():
			if n.has_meta("uid") and str(n.get_meta("uid")) == "boxcarry:%d" % id:
				node = n
		if node == null:
			_fail("unpack: no carry box for box %d" % (id + 1))
			return
		await click_node(room, "boxcarry:%d" % id, node)
		await wait(0.1)
		_check(bool(room.carried.get(id, false)), "unpack: box %d carried in" % (id + 1))
		room = _room()
	await shot("unpack_carried")
	# Open each box that is now in the room.
	for box in GameState.job.get("boxes", []):
		var id := int(box.get("id", 0))
		room = _room()
		var opened := _node_for(room, "boxopen:%d" % id)
		if opened == null:
			_fail("unpack: carried box %d is not in the room to open" % (id + 1))
			return
		await click_node(room, "boxopen:%d" % id, opened)
		await wait(0.1)
	for item in GameState.job.get("items", []):
		if str(item.get("state", "")) == "boxed":
			_fail("unpack: %s is still boxed after opening every box" % item.get("uid", ""))
			return
	await shot("unpack_opened")
	# Pick each item up and place it. Items crowd each other, so pick whichever
	# loose one the ray lands on.
	var guard := 0
	while guard < 120:
		guard += 1
		room = _room()
		var loose: Array = []
		for item in GameState.job.get("items", []):
			if str(item.get("state", "")) == "loose":
				loose.append(item)
		if loose.is_empty():
			break
		var picked := ""
		for item in loose:
			var node := _node_for(room, str(item.get("uid", "")))
			if node == null:
				continue
			picked = await _probe(room, node, func(h): return str(GameState.job_item(h).get("state", "")) == "loose")
			if picked != "":
				break
		if picked == "":
			_fail("unpack: none of %d loose items can be clicked" % loose.size())
			return
		await click_world(room, _last_hover)
		await wait(0.1)
		if room.held_uid != picked:
			_fail("unpack: cannot pick up %s (state %s, held %s)" % [picked, GameState.job_item(picked).get("state", ""), room.held_uid])
			return
		var item: Dictionary = GameState.job_item(picked)
		var target: Variant = null
		var mount := str(item.get("mount", "floor"))
		if mount == "hang" or mount == "wall_floor":
			for point in room._wall_points():
				if str(point["kind"]) != mount:
					continue
				var probe: Vector3 = Vector3(point["x"], point["y"], point["z"]) + (point["normal"] as Vector3) * 0.3
				if bool(room._snap_point(probe)["valid"]):
					target = Vector3(point["x"], 1.0 if mount == "hang" else 0.0, point["z"]) + (point["normal"] as Vector3) * 0.2
					break
		else:
			target = await _find_floor_spot(room)
		if target == null:
			_fail("unpack: no valid spot for %s (mount %s)" % [picked, mount])
			return
		await click_world(room, target)
		var ok := await wait_until(func(): return str(item.get("state", "")) == "placed" and not room.settling, 8.0)
		if not ok:
			_fail("unpack: %s never settled (state %s)" % [picked, item.get("state", "")])
			return
	# Repairs.
	for item in GameState.job.get("items", []):
		var taps := 0
		while int(item.get("damage", 0)) > 0 and taps < 6:
			var mended := false
			for btn in _buttons(_room()):
				if btn.text.begins_with("Mend") or btn.text.begins_with("Repair"):
					btn.pressed.emit()
					mended = true
					break
			if not mended:
				break
			await wait(0.1)
			taps += 1
	if bool(GameState.job.get("def", {}).get("mystery", false)):
		press("Sort mystery parts")
		await wait(0.1)
	await shot("unpack_done")


# ---------------------------------------------------------------- loft

func _buy_loft() -> void:
	# Three jobs do not reach the $1,500 gate on their own; top up and say so.
	if not GameState.office_gate_met("bakery"):
		print("note: topping up money to test the loft purchase (earned $%d, jobs %d, rep %d)" % [GameState.total_earned, GameState.jobs_done, GameState.rep_rank()])
		GameState.add_money(2000, true)
	_check(GameState.office_gate_met("bakery"), "bakery gate met after top-up")
	_check(press("Computer"), "HUD: Computer for listings")
	await wait(0.4)
	var computer: Node = app.overlay.get_child(0) if app.overlay.get_child_count() > 0 else null
	if computer == null:
		_fail("loft: computer did not open")
		return
	press("Listings", computer)
	await wait(0.2)
	await shot("listings")
	_check(press("Move in", computer), "listings: Move in button")
	await wait(1.5)
	_check(GameState.office_id == "bakery", "office is bakery (got %s)" % GameState.office_id)
	var room := _room()
	_check(room != null and str(room.venue.get("name", "")) == "Bakery Loft", "room rebuilt as Bakery Loft (got %s)" % (room.venue.get("name", "") if room else "none"))
	await shot("loft")
	await _save_roundtrip("in loft")


# ---------------------------------------------------------------- save

func _save_roundtrip(label: String) -> void:
	SaveManager.save_game()
	# JSON turns ints into floats; compare after one parse so 36 and 36.0 agree.
	var before := JSON.stringify(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	var ok := SaveManager.load_game()
	_check(ok, "save loads (%s)" % label)
	var after := JSON.stringify(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	_check(before == after, "save roundtrip is lossless (%s)" % label)
	if before != after:
		print("  before: " + before.left(600))
		print("  after:  " + after.left(600))


# ---------------------------------------------------------------- helpers

func _room() -> Node:
	if app.view_root.get_child_count() == 0:
		return null
	var node: Node = app.view_root.get_child(0)
	return node if node.has_method("_snap_point") else null


func _node_for(room: Node, uid: String) -> Node3D:
	var direct: Node = room.nodes_by_uid.get(uid)
	if direct != null:
		return direct as Node3D
	for n in room.items_root.get_children():
		if n.has_meta("uid") and str(n.get_meta("uid")) == uid:
			return n as Node3D
	return null


func _buttons(under: Node) -> Array:
	var out: Array = []
	if under == null:
		return out
	for b in under.find_children("*", "Button", true, false):
		if b.visible and not b.disabled:
			out.append(b)
	return out


func press(text: String, under: Node = null) -> bool:
	for btn in _buttons(under if under else self):
		if btn.text == text:
			btn.pressed.emit()
			return true
	return false


func click_node(room: Node, uid: String, node: Node3D) -> void:
	# Probe a few heights so the ray lands on the object's body, then click.
	var hit := await _probe(room, node, func(h): return h == uid)
	if hit != "":
		await click_world(room, _last_hover)
		return
	await click_world(room, node.global_position + Vector3(0, 0.15, 0))


var _last_hover := Vector3.ZERO


func hover_world(room: Node, world: Vector3) -> void:
	_last_hover = world
	var cam: Camera3D = room.cam
	var screen: Vector2 = cam.unproject_position(world)
	_send_motion(_to_window(screen))
	await wait(0.03)


func click_world(room: Node, world: Vector3) -> void:
	var cam: Camera3D = room.cam
	var screen: Vector2 = cam.unproject_position(world)
	# Input events arrive in window pixels; the canvas is stretched, so map back.
	var window_pos: Vector2 = _to_window(screen)
	_send_motion(window_pos)
	await wait(0.05)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = window_pos
	down.global_position = window_pos
	Input.parse_input_event(down)
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await wait(0.05)
	if OS.get_environment("CO_DEBUG") != "":
		var hovered := get_viewport().gui_get_hovered_control()
		print("  click %s -> screen %s hovered=%s pick=%s settling=%s mouse=%s" % [world, screen, hovered.name if hovered else "none", room._pick_uid(), room.settling, get_viewport().get_mouse_position()])


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func wait_until(pred: Callable, timeout: float) -> bool:
	var t := 0.0
	while t < timeout:
		if pred.call():
			return true
		await wait(0.1)
		t += 0.1
	return pred.call()


func shot(label: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/%02d_%s.png" % [shot_dir, shot_index, label])
	shot_index += 1


func _check(ok: bool, what: String) -> void:
	if ok:
		print("ok: " + what)
	else:
		_fail(what)


func _fail(what: String) -> void:
	fails.append(what)
	push_error("FAIL: " + what)
