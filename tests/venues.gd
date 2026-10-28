extends Node
# The gallery: build every venue and every rung of the shop ladder, make
# sure each one comes up with its dressing, its outdoors and its people,
# and (with CO_SHOTS set and a renderer) take a picture of each.
#
#   godot --headless --path . --quit-after 20000 res://tests/venues.tscn

const RoomLib = preload("res://scripts/diorama.gd")
const JobGen = preload("res://scripts/job_gen.gd")
const Catalog = preload("res://scripts/catalog.gd")

var fails: Array[String] = []
var shot_dir := ""
var shot_index := 0


func _ready() -> void:
	shot_dir = OS.get_environment("CO_SHOTS")
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	SaveManager.delete_save()
	await _run()
	if fails.is_empty():
		print("VENUES_OK")
	else:
		for line in fails:
			print("FAIL: " + line)
		print("VENUES_FAILED (%d)" % fails.size())
	get_tree().quit(0 if fails.is_empty() else 1)


func _run() -> void:
	GameState.new_game("dana")
	GameState.tutorial_done = true
	# Every job venue, as a move-in with a generated job's pieces.
	for venue_id in ItemDB.venues().keys():
		var venue: Dictionary = ItemDB.venues()[venue_id]
		if str(venue.get("shop_layout", "")) != "" or venue_id == "garage":
			continue
		var made: Dictionary = JobGen.board(7, 2, 1, 2, 1)
		var job: Dictionary = made["jobs"][0]
		job["venue"] = venue_id
		GameState.generated_jobs = [job]
		GameState.generated_drives = made["drives"]
		GameState.start_job(str(job["id"]))
		GameState.set_mode("job_unpack")
		for box in GameState.job.get("boxes", []):
			box["sealed"] = true
		await _show(str(venue_id), func(room: Node):
			_check(room.get_node_or_null("VenueDressing") != null, "%s: dressing" % venue_id)
			if not bool(room.call("_is_home")):
				var clutter := 0
				for child in room.get_children():
					if bool(child.get_meta("clutter", false)):
						clutter += 1
				_check(clutter >= 2, "%s: clutter from the catalogue (%d)" % [venue_id, clutter])
			_check(room.get_node_or_null("Outdoors") != null, "%s: outdoors" % venue_id)
			_check((room.get("street") as Array).size() >= 4, "%s: passers-by" % venue_id)
		)
	# Upstairs in three houses: the stairwell, the landing, the bedrooms.
	for home_id in ["semi_a", "townhouse_b", "villa_a"]:
		var made_up: Dictionary = JobGen.board(5, 2, 1, 2, 1)
		var up_job: Dictionary = made_up["jobs"][0]
		up_job["venue"] = home_id
		GameState.generated_jobs = [up_job]
		GameState.generated_drives = made_up["drives"]
		GameState.start_job(str(up_job["id"]))
		GameState.set_mode("job_unpack")
		for box in GameState.job.get("boxes", []):
			box["sealed"] = true
		await _show(home_id + "_up", func(room: Node):
			room.call("_set_floor", 1)
			var interior: Node = room.get_node_or_null("Interior")
			_check(interior != null and int(interior.get_meta("floor", 0)) == 1, "%s: upstairs shown" % home_id)
			_check(interior != null and interior.get_node_or_null("Stairs") != null, "%s: stairwell upstairs" % home_id)
		)
	# The office, and the yard at every rung of the ladder.
	GameState.new_game("dana")
	GameState.tutorial_done = true
	GameState.office_phase = "live"
	GameState.set_mode("office")
	for tier in Catalog.tiers():
		var tier_id := str(tier.get("id", ""))
		GameState.shop_tier = tier_id
		await _show("shop_" + tier_id, func(room: Node):
			var yard: Node = room.get_node_or_null("YardShop")
			_check(yard != null, "%s: yard shop node" % tier_id)
			if tier_id != "stand":
				_check(yard != null and yard.get_node_or_null("YardCounter") != null, "%s: counter in the yard" % tier_id)
				_check(room.call("_counter_node") != null, "%s: customers have a counter" % tier_id)
			if tier_id != "stand":
				_check(GameState.shop_open(), "%s: shop counts as open" % tier_id)
				_check(not GameState.shop_dishes().is_empty(), "%s: menu has dishes" % tier_id)
		)
	# The Bakery Loft as an office.
	GameState.office_id = "bakery"
	GameState.shop_tier = "stand"
	await _show("office_bakery", func(room: Node):
		_check(room.get_node_or_null("VenueDressing") != null, "bakery office: dressing")
	)


func _show(tag: String, probe: Callable) -> void:
	var room: Node = RoomLib.new()
	add_child(room)
	await wait(0.6)
	probe.call(room)
	await shot(tag)
	room.queue_free()
	await wait(0.1)


func _check(ok: bool, what: String) -> void:
	if ok:
		print("ok: " + what)
	else:
		fails.append(what)
		push_error("FAIL: " + what)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func shot(tag: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png("%s/%02d_%s.png" % [shot_dir, shot_index, tag])
		shot_index += 1
