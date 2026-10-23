extends Node

const PlaceLib = preload("res://scripts/placement.gd")

func _ready() -> void:
	var failures: Array = []
	var sample := GameState.compute_payout(120, 95, 20, 2, 0, false, 0)
	if int(sample["total"]) != 188 or int(sample["cut"]) != 12 or int(sample["base"]) != 120:
		failures.append("payout example %s" % sample)
	var floored := GameState.compute_payout(120, 10, 0, 0, 5, false, 0)
	if int(floored["total"]) != 120 or int(floored["cut"]) != 6:
		failures.append("cap %s" % floored)
	if Tuning.tip_ratio(95) != 0.5 or Tuning.tip_ratio(70) != 0.3 or Tuning.tip_ratio(50) != 0.15 or Tuning.tip_ratio(10) != 0.05:
		failures.append("tiers")
	if Tuning.rep_rank(2) != 1 or Tuning.rep_rank(0) != 0:
		failures.append("rep")
	var bakery: Dictionary = Tuning.office_def("bakery")
	if int(bakery.get("cost", 0)) != 1500 or int(bakery.get("jobs", 0)) != 3 or int(bakery.get("rep", 0)) != 1:
		failures.append("bakery gate")
	if int(Tuning.office_def("corner").get("cost", 0)) != 40000:
		failures.append("corner cost")
	if ItemDB.trade_goods().size() < 8:
		failures.append("goods %d" % ItemDB.trade_goods().size())
	if ItemDB.narrative_items.size() < 20:
		failures.append("narrative items")
	var cat := JobDB.get_job("job_catcafe")
	if JobDB.base_pay(cat) != 120:
		failures.append("cat pay")
	if JobDB.build_job_items(cat).size() != 18:
		failures.append("cat count %d" % JobDB.build_job_items(cat).size())
	var train := JobDB.get_job("job_train")
	if JobDB.build_job_items(train).size() != 24:
		failures.append("train count %d" % JobDB.build_job_items(train).size())
	if not str(cat.get("brief", "")).contains("Biscuit") and not str(cat.get("brief", "")).contains("box"):
		failures.append("brief missing")
	GameState.new_game("dana")
	if GameState.money != 120 or GameState.office_items.size() != 12:
		failures.append("new game %d %d" % [GameState.money, GameState.office_items.size()])
	var mug := GameState.find_office_item("mug")
	var notes := GameState.find_office_item("notes")
	if mug.is_empty() or notes.is_empty():
		failures.append("desk props")
	elif abs(float(mug["y"]) - 0.76) > 0.01 or abs(float(notes["y"]) - 0.76) > 0.01:
		failures.append("desk height")
	if GameState.inbox.is_empty() or str(GameState.inbox[0].get("id", "")) != "tut_welcome":
		failures.append("welcome email")
	if not str(GameState.inbox[0].get("body", "")).contains("Hey Dana") or str(GameState.inbox[0].get("subject", "")) != "Welcome to the garage, boss":
		failures.append("dana welcome")
	if GameState.character != "dana" or GameState.office_id != "garage" or GameState.slice_character_id() != "dana":
		failures.append("dana start")
	var listing := FileAccess.get_file_as_string("res://data/narrative/emails.json")
	if listing.contains("Shared Coworking") or not listing.contains("Bakery Loft") or not listing.contains("Hey Dana"):
		failures.append("bakery email rename")
	var notes_def := ItemDB.get_item("sticky_note_stack")
	if str(notes_def.get("model", "")) != "sticky_note_stack":
		failures.append("notes model")
	var notes_prop := Props.make("sticky_note_stack")
	if notes_prop == null or notes_prop.get_node_or_null("PropCollision") == null:
		failures.append("notes mesh")
	else:
		notes_prop.free()
	for model_name in ["cb_radio", "thermos_dented", "ramen_kettle", "yarn_basket"]:
		if not FileAccess.file_exists("res://assets/models/%s.glb" % model_name):
			failures.append("missing %s" % model_name)
			continue
		var made := Props.make(model_name)
		if made == null or made.get_node_or_null("PropCollision") == null:
			failures.append("model %s" % model_name)
		if made != null:
			made.free()
	var dana_name := ""
	for who in ItemDB.characters:
		if str(who.get("id", "")) == "dana":
			dana_name = str(who.get("name", ""))
	if dana_name != "Dana Reyes":
		failures.append("dana name %s" % dana_name)
	SaveManager.save_game()
	GameState.money = 5
	if not SaveManager.load_game() or GameState.money != 120:
		failures.append("save roundtrip")
	if abs(float(Tuning.get_value("wall_mount_offset_m", 0)) - 0.12) > 0.001:
		failures.append("wall offset")
	var board := GameState.find_office_item("board")
	if board.is_empty() or abs(float(board.get("x", 0)) - 0.12) > 0.001:
		failures.append("board clearance")
	if abs(float(ItemDB.get_item("shelf").get("back_offset", 0)) - 0.12) > 0.001:
		failures.append("shelf offset")
	var mug_prop := Props.make("mug_worlds_okayest")
	if mug_prop == null or mug_prop.get_node_or_null("PropCollision") == null:
		failures.append("prop collision")
	var rain_import := FileAccess.get_file_as_string("res://assets/audio/sfx/sfx_rain_ambience_loop.wav.import")
	var idle_import := FileAccess.get_file_as_string("res://assets/audio/sfx/sfx_truck_idle_loop.wav.import")
	var music_import := FileAccess.get_file_as_string("res://assets/audio/music/music_rainy_office.ogg.import")
	if not rain_import.contains("edit/loop_mode=1") or not idle_import.contains("edit/loop_mode=1") or not music_import.contains("loop=true"):
		failures.append("ambience loop import")
	var ambience := DirAccess.open("res://assets/audio/ambience")
	if ambience != null:
		for file_name in ambience.get_files():
			if not (file_name.ends_with(".ogg") or file_name.ends_with(".wav")):
				continue
			var imported := FileAccess.get_file_as_string("res://assets/audio/ambience/%s.import" % file_name)
			var loops_on := imported.contains("loop=true") or imported.contains("edit/loop_mode=1")
			if not loops_on:
				failures.append("ambience file %s" % file_name)
	var music_dir := DirAccess.open("res://assets/audio/music")
	if music_dir == null:
		failures.append("music folder")
	else:
		for file_name in music_dir.get_files():
			if not file_name.ends_with(".ogg"):
				continue
			var imported := FileAccess.get_file_as_string("res://assets/audio/music/%s.import" % file_name)
			if not imported.contains("loop=true"):
				failures.append("music loop %s" % file_name)
	if Tuning.audio_gain("amb_l02_cafe_loop") < 7.5 or Tuning.audio_gain("amb_l03_rain_loop") < 7.5:
		failures.append("ambience boost")
	if Tuning.audio_gain("amb_l04_shop_clock_loop") < 7.5 or Tuning.audio_gain("amb_l06_skylight_rain_loop") < 7.5:
		failures.append("clock skylight boost")
	if Tuning.audio_gain("sfx_box_fold") < 5.5 or Tuning.audio_gain("sfx_truck_idle_loop") > -9.0:
		failures.append("other gains")
	var garage_venue: Dictionary = ItemDB.venues().get("garage", {})
	var bakery_venue: Dictionary = ItemDB.venues().get("bakery", {})
	if str(garage_venue.get("music", "")) != "music_act1_home" or str(garage_venue.get("ambience", "")) != "amb_l01_garage_loop":
		failures.append("garage bed")
	if str(bakery_venue.get("music", "")) != "music_act2_morning" or not str(bakery_venue.get("ambience", "")).contains("amb_l06"):
		failures.append("bakery bed")
	var rainy: Dictionary = JobDB.get_drive("rainy_afternoon")
	var pond: Dictionary = JobDB.get_drive("duck_pond")
	if str(rainy.get("music", "")) != "music_driving_rain" or str(rainy.get("ambience", "")) != "amb_l03_rain_loop":
		failures.append("rainy bed")
	if str(pond.get("music", "")) != "music_driving" or str(pond.get("ambience", "")) != "amb_l05_park_birds_loop":
		failures.append("pond bed")
	var diorama_script: GDScript = load("res://scripts/diorama.gd")
	if diorama_script == null:
		failures.append("diorama script")
	else:
		GameState.set_mode("office")
		var office: Node = diorama_script.new()
		add_child(office)
		office.queue_free()
		if GameState.loaded_arc_characters() != 5 or GameState.slice_beats().size() != 6:
			failures.append("arc filter %d %d" % [GameState.loaded_arc_characters(), GameState.slice_beats().size()])
		var saw_l1 := false
		for mail in GameState.inbox:
			if str(mail.get("id", "")) == "arc_L1" and str(mail.get("body", "")).contains("Grayline"):
				saw_l1 = true
		if not saw_l1:
			failures.append("l1 beat")
		var l2: Dictionary = GameState.present_slice_level("L2")
		var l3: Dictionary = GameState.present_slice_level("L3")
		var l4: Dictionary = GameState.present_slice_level("L4")
		var l5: Dictionary = GameState.present_slice_level("L5")
		var l6: Dictionary = GameState.present_slice_level("L6")
		if str(l2.get("level_name", "")) != "Cat Cafe Owner" or str(l4.get("level_name", "")) != "Grandpa's Model Train Shop":
			failures.append("job beats")
		if not str(l3.get("arrival", "")).contains("Rain") or not str(l5.get("level_name", "")).contains("Duck"):
			failures.append("drive beats")
		var l6_mail: Variant = l6.get("marge_email", {})
		if str(l6.get("level_name", "")) != "Bakery Loft" or typeof(l6_mail) != TYPE_DICTIONARY or not str(l6_mail.get("body", "")).contains("Bakery Loft"):
			failures.append("l6 bakery")
		if not GameState.present_slice_level("L2").is_empty() or not GameState.present_slice_level("L7").is_empty():
			failures.append("arc repeat")
		GameState.fired.erase("arc_L2")
		GameState.character = "hank"
		if not GameState.present_slice_level("L2").is_empty():
			failures.append("hank arc shown")
		GameState.character = "dana"
		GameState.fired["arc_L2"] = true
		GameState.set_mode("truck")
		var room: Node = diorama_script.new()
		add_child(room)
		var player: AnimationPlayer = room.get("door_player")
		var door: Node3D = room.get("back_door")
		if player == null or door == null or not player.has_animation("open") or not player.has_animation("close"):
			failures.append("truck door animation")
		else:
			player.play("open")
			player.seek(0.55, true)
			if door.rotation.y < 1.5:
				failures.append("truck door open")
			player.play("close")
			player.seek(0.55, true)
			if absf(door.rotation.y) > 0.05:
				failures.append("truck door close")
		var drive_script: GDScript = load("res://scripts/drive_course.gd")
		if drive_script == null:
			failures.append("drive script")
		else:
			GameState.set_mode("drive")
			GameState.job = {"def": {"drive": "duck_pond", "level": "L5"}, "boxes": [], "items": []}
			GameState.fired.erase("arc_L5")
			var before_mail := GameState.inbox.size()
			var drive: Node = drive_script.new()
			add_child(drive)
			drive.queue_free()
			var duck_note := false
			for mail in GameState.inbox:
				if str(mail.get("id", "")) == "arc_L5" and str(mail.get("subject", "")).contains("Detours"):
					duck_note = true
			if not duck_note or GameState.inbox.size() <= before_mail:
				failures.append("duck beat on drive")
			var dressed := 0
			for child in drive.get_children():
				if child is Sprite2D and str(child.name) in ["fountain", "willow", "bridge_closed", "duck", "duckling"]:
					dressed += 1
			if dressed < 4:
				failures.append("pond sprites %d" % dressed)
			GameState.job = {}
			GameState.set_mode("office")
		if str(ItemDB.get_item("desk_main").get("model", "")) != "folding_table":
			failures.append("folding table")
		if str(ItemDB.venues().get("bakery", {}).get("kit", "")) != "bakery_loft":
			failures.append("bakery kit")
		for model_name in ["pegboard", "cafe_counter", "cat_biscuit", "display_case", "bakery_loft_wall_2m", "pastry_basket"]:
			var dressed_prop := Props.model(model_name)
			if dressed_prop == null:
				failures.append("level prop %s" % model_name)
			else:
				dressed_prop.free()
		var saved_office := GameState.office_id
		GameState.office_id = "bakery"
		GameState.set_mode("office")
		var loft: Node = diorama_script.new()
		add_child(loft)
		loft.queue_free()
		GameState.office_id = "garage"
		GameState.set_mode("job_pack")
		GameState.job = {"def": {"venue": "cafe", "cat": true}, "items": [], "boxes": []}
		var cafe: Node = diorama_script.new()
		add_child(cafe)
		cafe.queue_free()
		GameState.job = {}
		GameState.office_id = saved_office
		GameState.set_mode("office")
	if load("res://scripts/forest_page.gd") == null or load("res://scripts/shop_page.gd") == null:
		failures.append("store pages")
	if Catalog.category_open("coffee", "garage"):
		failures.append("coffee aisle early")
	if not Catalog.category_open("plants", "garage"):
		failures.append("plants aisle")
	var deals: Array = Catalog.deal_skus(GameState.day)
	if deals.is_empty() or Catalog.price_of(str(deals[0]), GameState.day) >= Catalog.list_price(str(deals[0])):
		failures.append("deal price")
	if GameState.order_forest("tf_coffee", "standard") == "":
		failures.append("locked aisle bought")
	var jar := GameState.money
	var fern := Catalog.price_of("tf_fern", GameState.day)
	var express_fee := int(Catalog.shipping("express").get("fee", 0))
	if GameState.order_forest("tf_fern", "express") != "":
		failures.append("express order")
	elif GameState.money != jar - fern - express_fee:
		failures.append("express charge")
	elif GameState.door_orders().is_empty():
		failures.append("courier box")
	else:
		var ship_uid := str(GameState.door_orders()[0].get("uid", ""))
		if GameState.return_delivery(ship_uid) != "":
			failures.append("return sealed")
		elif GameState.money != jar - express_fee:
			failures.append("return refund")
	if GameState.order_forest("tf_cactus", "standard") != "":
		failures.append("standard order")
	GameState.advance_day()
	var cactus_uid := ""
	for order in GameState.door_orders():
		if str(order.get("sku", "")) == "tf_cactus":
			cactus_uid = str(order.get("uid", ""))
	if cactus_uid == "":
		failures.append("standard arrived")
	else:
		GameState.start_unbox(cactus_uid)
		var left := 1
		while left > 0:
			left = GameState.pop_bubble(cactus_uid)
		var opened := GameState.finish_unbox(cactus_uid)
		if str(opened.get("item", "")) != "plant_cactus" or str(opened.get("source", "")) != "forest":
			failures.append("unbox")
		else:
			var before_vibe := GameState.vibe_score()
			GameState.place_decor_from_queue({"x": 1.5, "y": 0, "z": 1.5, "rot": 0}, str(opened.get("uid", "")))
			if GameState.vibe_score() <= before_vibe:
				failures.append("vibe")
	GameState.office_items.append({"uid": "shop_coffee", "item": "coffee_machine", "state": "placed", "x": 3, "y": 0, "z": 3, "rot": 0, "damage": 0})
	var visit := GameState.serve_visitor()
	if visit.is_empty() or int(visit.get("pay", 0)) <= 0:
		failures.append("visitor")
	else:
		GameState.advance_day()
		var mailed := false
		for mail in GameState.inbox:
			if "till" in str(mail.get("subject", "")).to_lower():
				mailed = true
		if not mailed:
			failures.append("shop email")
	if not GameState.toggle_wishlist("tf_fern"):
		failures.append("wishlist")
	SaveManager.save_game()
	GameState.wishlist = []
	if not SaveManager.load_game() or not ("tf_fern" in GameState.wishlist):
		failures.append("wishlist save")
	failures.append_array(_collision_checks())
	failures.append_array(_stack_checks())
	failures.append_array(_screen_copy_checks())
	failures.append_array(await _settle_checks())
	if failures.is_empty():
		print("SMOKE_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_FAIL")
		for failure in failures:
			print(" - ", failure)
		get_tree().quit(1)


func _collision_checks() -> Array:
	var found: Array = []
	for model_name in ["wall_garage_3m", "wall_door_2m", "wall_window_2m"]:
		var node := Props.model(model_name)
		if node == null:
			found.append("missing %s" % model_name)
			continue
		Props.prepare(node)
		var body := node.get_node_or_null("StructureCollision") as StaticBody3D
		if body == null or body.collision_layer != Props.LAYER_BLOCKING or body.collision_mask != Props.LAYER_BLOCKING:
			found.append("%s layer" % model_name)
		else:
			var face := _collision_face_z(body)
			if absf(face - Props.WALL_BODY_HALF) > 0.004 or face > 0.125:
				found.append("%s face %s" % [model_name, face])
		if absf(float(node.get_meta("body_half", 0.0)) - 0.12) > 0.001:
			found.append("%s body half" % model_name)
		if model_name == "wall_garage_3m" and absf(float(node.get_meta("source_half_z", 0.0)) - 0.13) > 0.008:
			found.append("garage aabb half %s" % node.get_meta("source_half_z", 0.0))
		node.free()
	if FileAccess.file_exists("res://assets/models/cafe_wall_window_2m.glb"):
		var cafe := Props.model("cafe_wall_window_2m")
		if cafe == null:
			found.append("cafe window")
		else:
			Props.prepare(cafe)
			var cafe_body := cafe.get_node_or_null("StructureCollision") as StaticBody3D
			if cafe_body == null or absf(_collision_face_z(cafe_body) - 0.12) > 0.004:
				found.append("cafe window face")
			cafe.free()
	var straight := Props.model("wall_straight_2m")
	if straight == null:
		found.append("missing straight")
	else:
		Props.prepare(straight)
		var straight_body := straight.get_node_or_null("StructureCollision") as StaticBody3D
		var straight_box: BoxShape3D = null
		if straight_body != null and straight_body.get_child_count() > 0:
			straight_box = (straight_body.get_child(0) as CollisionShape3D).shape as BoxShape3D
		if straight_body == null or straight_body.collision_layer != Props.LAYER_BLOCKING or straight_box == null or absf(straight_box.size.z - Props.WALL_THICKNESS) > 0.001:
			found.append("straight thickness")
		straight.free()
	var corner := Props.model("wall_corner")
	if corner == null:
		found.append("missing corner")
	else:
		Props.prepare(corner)
		var corner_body := corner.get_node_or_null("StructureCollision") as StaticBody3D
		var thick := 0
		if corner_body == null:
			found.append("corner body")
		else:
			for child in corner_body.get_children():
				var box := (child as CollisionShape3D).shape as BoxShape3D
				if box == null:
					continue
				if absf(box.size.x - 0.24) < 0.001 or absf(box.size.z - 0.24) < 0.001:
					thick += 1
				if absf(box.size.x - 0.22) < 0.001 or absf(box.size.z - 0.22) < 0.001:
					found.append("corner used visual thickness")
			if thick < 2:
				found.append("corner thickness %d" % thick)
		corner.free()
	var tile := Props.model("floor_tile_2m")
	if tile == null:
		found.append("missing floor")
	else:
		Props.prepare(tile)
		var tile_body := tile.get_node_or_null("StructureCollision") as StaticBody3D
		if tile_body == null or tile_body.collision_layer != Props.LAYER_PICKABLE or tile_body.collision_mask != 0:
			found.append("floor layer")
		tile.free()
	var rug := Props.model("rug")
	if rug != null:
		Props.prepare(rug)
		var rug_body := rug.get_node_or_null("StructureCollision") as StaticBody3D
		if rug_body == null or rug_body.collision_layer != Props.LAYER_PICKABLE or rug_body.collision_mask != 0:
			found.append("rug layer")
		rug.free()
	var npc := Node3D.new()
	npc.name = "npc_clerk"
	Props.prepare(npc)
	var npc_body := npc.get_node_or_null("StructureCollision") as StaticBody3D
	var capsule: CapsuleShape3D = null
	if npc_body != null and npc_body.get_child_count() > 0:
		capsule = (npc_body.get_child(0) as CollisionShape3D).shape as CapsuleShape3D
	if npc_body == null or npc_body.collision_layer != Props.LAYER_BLOCKING or capsule == null or not bool(npc.get_meta("npc_capsule", false)):
		found.append("npc capsule")
	npc.free()
	return found


func _collision_face_z(body: StaticBody3D) -> float:
	var face := 0.0
	for child in body.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			continue
		var concave := shape_node.shape as ConcavePolygonShape3D
		if concave != null:
			for point in concave.get_faces():
				face = maxf(face, absf(point.z))
			continue
		var box := shape_node.shape as BoxShape3D
		if box != null:
			face = maxf(face, absf(shape_node.position.z) + box.size.z * 0.5)
	return face


func _screen_copy_checks() -> Array:
	var found: Array = []
	var how_path := "res://data/narrative/how_to_play.json"
	var credits_path := "res://data/narrative/credits.json"
	if not FileAccess.file_exists(how_path) or not FileAccess.file_exists(credits_path):
		found.append("screen copy missing")
		return found
	var how: Variant = JSON.parse_string(FileAccess.get_file_as_string(how_path))
	var credits: Variant = JSON.parse_string(FileAccess.get_file_as_string(credits_path))
	var how_titles: Array = []
	if how is Dictionary:
		for tip in how.get("tips", []):
			how_titles.append(str(tip.get("title", "")))
	var expected_tips := ["Pack with Care", "Load the Truck", "A Gentle Drive", "Unpack & Place", "Pay & Tips", "Trade on the Computer", "Make It Yours", "No Rush, No Fail"]
	if how_titles != expected_tips:
		found.append("how to play %s" % how_titles)
	var credit_names: Array = []
	if credits is Dictionary:
		for person in credits.get("people", []):
			credit_names.append(str(person.get("name", "")))
	var expected_names := ["Andrew S", "Coding Master Boss", "Game Director", "Narrative Writer", "Audio Producer", "Art Specialist", "Design Specialist", "Level Platform Brainstormer", "Programmer Master", "QA Tester", "Marketing Bot"]
	if credit_names != expected_names:
		found.append("credits %s" % credit_names)
	return found


func _stack_checks() -> Array:
	var found: Array = []
	var room := Rect2(0, 0, 6, 8)
	var mug := {"w": 0.16, "d": 0.14, "h": 0.11, "mount": "small"}
	var desk := {"uid": "desk", "state": "placed", "x": 2.0, "y": 0.0, "z": 2.0, "rot": 0.0, "w": 1.2, "d": 0.7, "h": 0.76, "surface": 0.76}
	var floor_spot: Dictionary = PlaceLib.resolve(2.0, 3.0, 0.0, 0.0, mug, [], room, false)
	if not bool(floor_spot.get("valid", false)) or absf(float(floor_spot["pos"].y)) > 0.001:
		found.append("stack floor %s" % floor_spot)
	var on_desk: Dictionary = PlaceLib.resolve(2.0, 2.0, -1.0, 0.0, mug, [desk], room, false)
	if not bool(on_desk.get("valid", false)) or absf(float(on_desk["pos"].y) - 0.76) > 0.02:
		found.append("stack desk %s" % on_desk)
	var box := {"uid": "box", "state": "placed", "x": 2.0, "y": 0.76, "z": 2.0, "rot": 0.0, "w": 0.45, "d": 0.4, "h": 0.4}
	var on_box: Dictionary = PlaceLib.resolve(2.0, 2.0, -1.0, 0.0, mug, [desk, box], room, false)
	if not bool(on_box.get("valid", false)) or absf(float(on_box["pos"].y) - 1.16) > 0.02:
		found.append("stack box %s" % on_box)
	var floating: Dictionary = PlaceLib.resolve(2.0, 3.0, 1.5, 0.0, mug, [], room, false)
	if bool(floating.get("valid", false)):
		found.append("float")
	var other := {"uid": "mug2", "state": "placed", "x": 2.0, "y": 0.0, "z": 2.0, "rot": 0.0, "w": 0.16, "d": 0.14, "h": 0.11}
	var overlap: Dictionary = PlaceLib.resolve(2.0, 2.0, 0.0, 0.0, mug, [other], room, false)
	if bool(overlap.get("valid", false)):
		found.append("overlap")
	var inside: Dictionary = PlaceLib.resolve(2.0, 2.0, 0.2, 0.0, mug, [desk], room, false)
	if bool(inside.get("valid", false)):
		found.append("penetrate")
	var grid: Dictionary = PlaceLib.resolve(2.13, 2.13, -1.0, 0.0, mug, [], room, true)
	if not bool(grid.get("valid", false)) or absf(float(grid["pos"].x) - snapped(2.13, 0.25)) > 0.001:
		found.append("snap %s" % grid)
	return found


func _settle_checks() -> Array:
	var found: Array = []
	var desk_h := 0.76
	var crate_h := 0.4
	var mug_h := 0.11
	var desk := PlaceLib.make_body(Vector3(1.2, desk_h, 0.7), Vector3(0, 0, 0), 0, false)
	var crate := PlaceLib.make_body(Vector3(0.45, crate_h, 0.4), Vector3(0, desk_h, 0), 0, true)
	var mug := PlaceLib.make_body(Vector3(0.16, mug_h, 0.14), Vector3(0, desk_h + crate_h, 0), 0, true)
	add_child(desk)
	add_child(crate)
	add_child(mug)
	var calm := 0
	for i in 80:
		await get_tree().physics_frame
		if not is_instance_valid(crate) or not is_instance_valid(mug):
			found.append("settle missing")
			return found
		var settled := crate.linear_velocity.length() < 0.05 and mug.linear_velocity.length() < 0.05
		if settled and i > 6:
			calm += 1
			if calm >= 4:
				break
		else:
			calm = 0
	if absf(desk.position.y) > 0.02:
		found.append("settle desk %s" % desk.position.y)
	if absf(crate.position.y - desk_h) > 0.03:
		found.append("settle crate %s" % crate.position.y)
	if absf(mug.position.y - (desk_h + crate_h)) > 0.03:
		found.append("settle mug %s" % mug.position.y)
	var crate_at := crate.position
	var mug_at := mug.position
	PlaceLib.finish_settle(crate)
	PlaceLib.finish_settle(mug)
	for _i in 8:
		await get_tree().physics_frame
	if crate.position.distance_to(crate_at) > 0.01 or mug.position.distance_to(mug_at) > 0.01:
		found.append("settle drift")
	desk.queue_free()
	crate.queue_free()
	mug.queue_free()
	return found
