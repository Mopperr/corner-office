extends Node

const PlaceLib = preload("res://scripts/placement.gd")
const RoomLib = preload("res://scripts/diorama.gd")
const SupportMath = preload("res://scripts/stacking/support.gd")
const StackItemLib = preload("res://scripts/stacking/stack_item.gd")
const StackRoomLib = preload("res://scripts/stacking/stack_room.gd")
const Graphics = preload("res://scripts/settings_manager.gd")
const Tuning = preload("res://scripts/tuning.gd")
const Catalog = preload("res://scripts/catalog.gd")
const UIKit = preload("res://scripts/ui_kit.gd")
const Props = preload("res://scripts/props.gd")

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
	else:
		_bury(mug_prop)
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
		_bury(office)
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
			_bury(drive)
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
		var orphans_before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var loft: Node = diorama_script.new()
		add_child(loft)
		var scraps := 0
		for child in loft.get_children():
			if child.has_meta("floor_scrap"):
				scraps += 1
		if scraps != 6:
			failures.append("nook floor scraps %d" % scraps)
		var orphans_after := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		if orphans_after > orphans_before:
			failures.append("nook floor orphans %d" % (orphans_after - orphans_before))
		_bury(loft)
		GameState.office_id = "garage"
		GameState.set_mode("job_pack")
		GameState.job = {"def": {"venue": "cafe", "cat": true}, "items": [], "boxes": []}
		var cafe: Node = diorama_script.new()
		add_child(cafe)
		_bury(cafe)
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
	failures.append_array(await _qa_regressions())
	failures.append_array(await _review_fixes())
	failures.append_array(_engine_choices())
	failures.append_array(await _stack_world())
	AudioDirector.release_audio()
	var leaked := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if leaked > 0:
		failures.append("orphan nodes %d" % leaked)
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
	if credits is Dictionary and str(credits.get("headline", "")) != "Created by Andrew's Helpers (Grok Bots)":
		found.append("credits headline")
	if absf(RoomLib.MENU_YAW_DEG - 45.0) > 0.001 or absf(RoomLib.MENU_PITCH_DEG - (-30.0)) > 0.001:
		found.append("menu angles")
	if absf(RoomLib.MENU_ORTHO_SIZE - 7.2) > 0.001 or absf(RoomLib.MENU_DRIFT_SEC - 24.0) > 0.001:
		found.append("menu camera")
	OS.set_environment("CORNER_OFFICE_REDUCED_MOTION", "1")
	if not RoomLib.prefers_reduced_motion():
		found.append("reduced motion on")
	OS.set_environment("CORNER_OFFICE_REDUCED_MOTION", "0")
	if RoomLib.prefers_reduced_motion():
		found.append("reduced motion off")
	OS.set_environment("CORNER_OFFICE_REDUCED_MOTION", "")
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
	desk.free()
	crate.free()
	mug.free()
	return found


func _qa_regressions() -> Array:
	var found: Array = []
	var plain := GameState.compute_payout(120, 95, 20, 2, 0, false, 0)
	if int(plain.get("shortcut", -1)) != 0 or int(plain.get("total", 0)) != 188:
		found.append("shortcut absent %s" % plain)
	var alley_pay := GameState.compute_payout(120, 95, 20, 2, 0, true, 0)
	if int(alley_pay.get("shortcut", 0)) != 12 or int(alley_pay.get("box_tip", 0)) != 60 or int(alley_pay.get("total", 0)) != 200:
		found.append("shortcut line %s" % alley_pay)
	if RoomLib.mend_caption("Mug", 1) != "Mend Mug (1 tap)" or RoomLib.mend_caption("Mug", 3) != "Mend Mug (3 taps)":
		found.append("tap plural")
	var tint := RoomLib.ghost_color(Color.WHITE, false)
	var soft := Color.WHITE.lerp(UIKit.SOFT_RED, 0.65)
	soft.a = 0.5
	var loss := Color.WHITE.lerp(UIKit.LOSS, 0.65)
	loss.a = 0.5
	if not tint.is_equal_approx(soft) or tint.is_equal_approx(loss) or UIKit.SOFT_RED == UIKit.LOSS:
		found.append("ghost red %s" % tint)
	if RoomLib.SQUASH_KEYS.size() != 3:
		found.append("squash keys")
	else:
		var squash: Vector3 = RoomLib.SQUASH_KEYS[0]["scale"]
		var stretch: Vector3 = RoomLib.SQUASH_KEYS[1]["scale"]
		var settle: Vector3 = RoomLib.SQUASH_KEYS[2]["scale"]
		if squash.y >= 0.95 or squash.x < 1.1 or stretch.x >= 1.0 or stretch.y <= 1.0 or settle != Vector3.ONE:
			found.append("squash curve %s %s %s" % [squash, stretch, settle])
		if int(RoomLib.SQUASH_KEYS[2]["trans"]) == Tween.TRANS_BACK or int(RoomLib.SQUASH_KEYS[0]["ease"]) != Tween.EASE_OUT:
			found.append("squash ease")
	var window := Props.model("wall_window_2m")
	if window == null:
		found.append("window model")
	else:
		Props.restyle_architecture(window)
		var surfaces := 0
		var nulls := 0
		for mesh_node in window.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := mesh_node as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			for i in mesh_instance.mesh.get_surface_count():
				surfaces += 1
				if mesh_instance.mesh.surface_get_material(i) == null:
					nulls += 1
		if surfaces != 4 or nulls != 0:
			found.append("null materials %d %d" % [surfaces, nulls])
		_bury(window)
	GameState.new_game("dana")
	for item in GameState.office_items:
		item["state"] = "boxed"
	var room: Node = RoomLib.new()
	add_child(room)
	room.set("held_source", "office")
	room.set("held_rot", 90.0)
	var wall_points: Array = room.call("_wall_points")
	if wall_points.is_empty():
		found.append("no wall points")
	for point in wall_points:
		var hang := str(point.get("kind", "")) == "hang"
		room.set("held_uid", "board" if hang else "shelf_a")
		var normal: Vector3 = point["normal"]
		var spot: Dictionary = room.call("_snap_point", Vector3(point["x"], point["y"], point["z"]) + normal * 0.2)
		if not bool(spot.get("valid", false)):
			found.append("wall snap %s" % point)
			break
		var mounted: Vector3 = spot["pos"]
		if absf(mounted.distance_to(Vector3(point["x"], point["y"], point["z"])) - 0.12) > 0.001:
			found.append("wall offset %s" % mounted)
			break
		var venue_now: Dictionary = room.get("venue")
		var local := Vector2(mounted.x, mounted.z) - Vector2(float(venue_now.get("x", 0.0)), float(venue_now.get("z", 0.0)))
		var room_size := Vector2(float(venue_now.get("w", 6.0)), float(venue_now.get("d", 8.0)))
		var inset := minf(minf(local.x, room_size.x - local.x), minf(local.y, room_size.y - local.y))
		if inset >= 0.25:
			found.append("wall used room margin")
			break
		if not SupportMath.in_room(local, room_size):
			found.append("wall outside room")
			break
	for item in GameState.office_items:
		item["state"] = "placed"
	room.call("_maybe_live")
	if not GameState.tutorial_done or not GameState.job_available(JobDB.get_job("job_catcafe")):
		found.append("jobs after tutorial")
	_bury(room)
	var show: Node = RoomLib.new()
	show.set("backdrop", true)
	add_child(show)
	var show_worlds: Array = show.find_children("*", "WorldEnvironment", true, false)
	if show_worlds.is_empty() or (show_worlds[0] as WorldEnvironment).environment.background_color != UIKit.CREAM:
		found.append("menu background")
	var show_venue: Dictionary = show.get("venue")
	var layout_script = preload("res://scripts/menu_layout.gd")
	var loft: Dictionary = layout_script.load_layout()
	var expect_id := "bakery" if not loft.is_empty() else "garage"
	if str(show_venue.get("id", "")) != expect_id:
		found.append("menu room %s" % show_venue.get("id", ""))
	var menu_cam: Camera3D = show.get("cam")
	if menu_cam == null or absf(menu_cam.size - 7.2) > 0.001:
		found.append("menu ortho %s" % (menu_cam.size if menu_cam else "missing"))
	var menu_dof: CameraAttributesPractical = null
	if menu_cam != null:
		menu_dof = menu_cam.attributes as CameraAttributesPractical
	if menu_dof == null or not menu_dof.dof_blur_far_enabled or absf(menu_dof.dof_blur_far_distance - 14.0) > 0.001 or absf(menu_dof.dof_blur_far_transition - 6.0) > 0.001 or absf(menu_dof.dof_blur_amount - 0.06) > 0.001:
		found.append("menu dof")
	_bury(show)
	var play: Node = RoomLib.new()
	add_child(play)
	var play_worlds: Array = play.find_children("*", "WorldEnvironment", true, false)
	if play_worlds.is_empty():
		found.append("office background")
	else:
		var office := (play_worlds[0] as WorldEnvironment).environment
		if office.background_color != Color("3E3A4F"):
			found.append("office background %s" % office.background_color)
		if office.tonemap_mode != Environment.TONE_MAPPER_AGX or absf(office.tonemap_exposure - 0.85) > 0.001 or absf(office.tonemap_white - 4.0) > 0.001 or absf(office.tonemap_agx_white - 4.0) > 0.001:
			found.append("tonemap")
		if office.ambient_light_color != Color("F2E2CC") or absf(office.ambient_light_energy - 0.25) > 0.001:
			found.append("ambient")
		if not office.adjustment_enabled or absf(office.adjustment_contrast - 1.2) > 0.001 or absf(office.adjustment_saturation - 1.08) > 0.001:
			found.append("grade")
		if office.fog_enabled or office.sdfgi_enabled or not office.ssao_enabled or office.ssil_enabled or not office.glow_enabled:
			found.append("features")
		if absf(office.ssao_radius - 0.8) > 0.001 or absf(office.ssao_intensity - 1.5) > 0.001:
			found.append("ssao")
		if absf(office.glow_intensity - 0.4) > 0.001 or absf(office.glow_strength - 0.8) > 0.001 or office.glow_blend_mode != Environment.GLOW_BLEND_MODE_SOFTLIGHT:
			found.append("glow")
	var play_cam: Camera3D = play.get("cam")
	var garage_center := Vector3(3.0, 0.9, 4.0)
	if play_cam == null or play_cam.position.distance_to(Vector3(11.2, 9.9, 12.0)) > 0.02 or absf(play_cam.size - maxf(6.0, 8.0) * 1.3) > 0.001:
		found.append("garage cam %s" % (play_cam.position if play_cam else "missing"))
	elif (-play_cam.global_transform.basis.z).dot((garage_center - play_cam.global_position).normalized()) < 0.999:
		found.append("garage look")
	var sun := play.find_child("Sun", true, false) as DirectionalLight3D
	if sun == null or sun.light_color != Color("FFE3C0") or absf(sun.light_energy - 0.85) > 0.001 or sun.rotation_degrees.distance_to(Vector3(-50, 35, 0)) > 0.1 or not sun.shadow_enabled or absf(sun.light_angular_distance - 1.75) > 0.001:
		found.append("sun")
	var fill := play.find_child("Fill", true, false) as DirectionalLight3D
	if fill == null or fill.light_color != Color("A9C4D4") or absf(fill.light_energy - 0.2) > 0.001 or fill.shadow_enabled:
		found.append("fill")
	var door := play.find_child("DoorGlow", true, false) as OmniLight3D
	if door == null or door.light_color != Color("FFC98A") or absf(door.light_energy - 0.9) > 0.001:
		found.append("door glow")
	var lamp_light := play.find_child("LampLight", true, false) as OmniLight3D
	if lamp_light == null or lamp_light.light_color != Color("FFD9A0") or absf(lamp_light.light_energy - 0.8) > 0.001 or absf(lamp_light.omni_range - 2.5) > 0.001 or lamp_light.shadow_enabled:
		found.append("lamp omni")
	else:
		var shade_mesh: MeshInstance3D = null
		var shade_nodes: Array = lamp_light.get_parent().find_children("*", "MeshInstance3D", true, false)
		if not shade_nodes.is_empty():
			shade_mesh = shade_nodes[0] as MeshInstance3D
		var shade: StandardMaterial3D = null
		if shade_mesh != null:
			shade = shade_mesh.material_override as StandardMaterial3D
		if shade == null or not shade.emission_enabled or shade.emission != Color("FFD9A0") or absf(shade.emission_energy_multiplier - 1.2) > 0.001:
			found.append("lamp shade")
	_bury(play)
	var menu: Control = load("res://scripts/menu_ui.gd").new()
	add_child(menu)
	var logo := _label_with(menu, "Corner Office")
	if logo == null or logo.autowrap_mode != TextServer.AUTOWRAP_OFF or logo.custom_minimum_size.x < 600.0:
		found.append("logo wrap")
	menu.layout_mode = 0
	menu.position = Vector2.ZERO
	menu.size = Vector2(1280, 800)
	menu.call("_intro", "dana")
	await get_tree().process_frame
	await get_tree().process_frame
	var intro := menu.find_child("Intro", true, false) as Control
	if intro == null:
		found.append("intro missing")
	else:
		var intro_rect := intro.get_global_rect()
		var intro_center := intro_rect.get_center()
		if intro_rect.position.x < 0.0 or intro_rect.position.y < 0.0 or intro_rect.size.x < 800.0 or intro_center.distance_to(Vector2(640, 400)) > 8.0:
			found.append("intro card %s" % intro_rect)
	_bury(menu)
	var host := Node.new()
	add_child(host)
	UIKit.show_level_beat(host, {"level_name": "Garage Startup", "arrival": "The roller door sticks.", "moment": "Dana sets the kettle on."})
	await get_tree().process_frame
	await get_tree().process_frame
	var beat := host.find_child("LevelBeat", true, false) as Control
	var view: Vector2 = get_viewport().get_visible_rect().size
	if view.y < 8.0:
		view = Vector2(1280, 800)
	if beat == null:
		found.append("level beat missing")
	else:
		var beat_rect := beat.get_global_rect()
		var hint_top: float = view.y - 104.0
		if beat_rect.end.y > hint_top - 8.0 or absf(beat_rect.get_center().x - view.x * 0.5) > 8.0:
			found.append("level beat %s hint %s" % [beat_rect, hint_top])
	_bury(host)
	var shell = load("res://scripts/app.gd").new()
	add_child(shell)
	shell.call("_pause")
	get_tree().paused = false
	await get_tree().process_frame
	await get_tree().process_frame
	var column: Control = shell.find_child("PauseColumn", true, false) as Control
	var pause_panel: Control = shell.find_child("Pause", true, false) as Control
	var paused_title: Label = shell.find_child("Paused", true, false) as Label
	if paused_title == null:
		for node in shell.find_children("*", "Label", true, false):
			if str(node.text) == "Paused":
				paused_title = node as Label
				break
	if column == null or pause_panel == null or paused_title == null:
		found.append("pause missing")
	else:
		var column_rect := column.get_global_rect()
		var panel_rect := pause_panel.get_global_rect()
		if column_rect.size.x < 400.0 or panel_rect.size.x < 50.0 or column_rect.get_center().distance_to(panel_rect.get_center()) > 8.0:
			found.append("pause center %s %s" % [column_rect, panel_rect])
		if paused_title.autowrap_mode != TextServer.AUTOWRAP_OFF or paused_title.get_line_count() > 1:
			found.append("pause wrap %s" % paused_title.get_line_count())
	get_tree().paused = false
	_bury(shell)
	GameState.payout = {
		"base": 120, "box_tip": 60, "shortcut": 12, "bonuses": 0, "split_loss": 0,
		"cut": 0, "net_tips": 60, "total": 192, "title": "Job done", "stars": 1, "stamp": "",
	}
	var results: Control = load("res://scripts/results_ui.gd").new()
	add_child(results)
	var card := results.get_node_or_null("Card") as Control
	var vp := results.get_viewport_rect().size
	if vp.x < 8.0 or vp.y < 8.0:
		vp = Vector2(1280, 720)
	if card == null or card.anchor_left != 0.5 or card.anchor_top != 0.5 or card.position.x < 0.0 or card.position.y < 0.0:
		found.append("results anchors %s" % (card.position if card else "missing"))
	elif card.get_global_rect().get_center().distance_to(vp * 0.5) > 24.0:
		found.append("results center %s %s" % [card.get_global_rect().get_center(), vp])
	var packed := PackedStringArray()
	for row in results.get("lines"):
		packed.append(str(row))
	if not "\n".join(packed).contains("Shortcut  +$12"):
		found.append("results shortcut %s" % results.get("lines"))
	_bury(results)
	GameState.buyer_offer = {"name": "Nia", "item": "plant_fern", "price": 22, "line": "I'll take the fern."}
	var computer: Control = load("res://scripts/computer_ui.gd").new()
	add_child(computer)
	var home := _label_with(computer, "HomeDesk")
	if home == null or home.autowrap_mode != TextServer.AUTOWRAP_OFF or home.custom_minimum_size.x < 160.0:
		found.append("computer title")
	var offer := computer.find_child("Offer", true, false) as Label
	var hint_top := vp.y - 104.0
	if offer == null or offer.position.y > 320.0 or offer.size.x < 400.0 or offer.global_position.y + offer.size.y >= hint_top:
		found.append("offer overlap %s" % (offer.position if offer else "missing"))
	_bury(computer)
	GameState.job = {"def": {"drive": "sunny_main", "level": "L3"}, "boxes": [], "items": []}
	GameState.set_mode("drive")
	var drive: Node = load("res://scripts/drive_course.gd").new()
	add_child(drive)
	var meter := _label_with(drive, "Box condition")
	if meter == null or meter.autowrap_mode != TextServer.AUTOWRAP_OFF or meter.custom_minimum_size.x < 160.0:
		found.append("meter title")
	drive.set("condition", 100)
	(drive.get("touching") as Dictionary).clear()
	(drive.get("contact_ready") as Dictionary).clear()
	var collision := int(Tuning.get_value("box_condition.collision", 10))
	drive.call("_contact", "offroad", true, collision)
	drive.call("_contact", "offroad", true, collision)
	drive.call("_contact", "offroad", true, collision)
	if int(drive.get("condition")) != 90:
		found.append("offroad drip %s" % drive.get("condition"))
	drive.call("_contact", "offroad", false, collision)
	drive.call("_contact", "offroad", true, collision)
	if int(drive.get("condition")) != 90:
		found.append("offroad cooldown %s" % drive.get("condition"))
	drive.call("_contact", "offroad", false, collision)
	(drive.get("contact_ready") as Dictionary)["offroad"] = 0
	drive.call("_contact", "offroad", true, collision)
	if int(drive.get("condition")) != 80:
		found.append("offroad reentry %s" % drive.get("condition"))
	drive.set("condition", 100)
	(drive.get("touching") as Dictionary).clear()
	(drive.get("contact_ready") as Dictionary).clear()
	drive.call("_contact", "bump", true, int(Tuning.get_value("box_condition.bump_min", 3)))
	drive.call("_contact", "bump", false, 0)
	(drive.get("contact_ready") as Dictionary).erase("bump")
	drive.call("_contact", "bump", true, int(Tuning.get_value("box_condition.bump_max", 8)))
	drive.call("_contact", "cone", true, collision)
	if int(drive.get("condition")) != 79:
		found.append("meter amounts %s" % drive.get("condition"))
	drive.set("course", JobDB.get_drive("duck_pond"))
	drive.set("condition", 100)
	drive.set("speed", 120.0)
	drive.set("heading", 0.0)
	(drive.get("touching") as Dictionary).clear()
	(drive.get("contact_ready") as Dictionary).clear()
	drive.set("pos", Vector2(1200, 410))
	drive.call("_hazards")
	drive.call("_hazards")
	if int(drive.get("condition")) != 100:
		found.append("l5 gravel %s" % drive.get("condition"))
	drive.set("pos", Vector2(1500, 2050))
	drive.call("_hazards")
	drive.call("_hazards")
	if int(drive.get("condition")) != 100:
		found.append("l5 ducks %s" % drive.get("condition"))
	(drive.get("touching") as Dictionary).clear()
	(drive.get("contact_ready") as Dictionary).clear()
	drive.set("speed", 10.0)
	drive.set("pos", Vector2(830, 1400))
	drive.call("_hazards")
	if int(drive.get("condition")) != 97:
		found.append("l5 bump %s" % drive.get("condition"))
	_bury(drive)
	return found


func _bury(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var kids: Array = node.get_children()
	for kid in kids:
		if kid is Node:
			_bury(kid)
	node.free()


func _label_with(root: Node, text: String) -> Label:
	if root is Label and (root as Label).text == text:
		return root
	for child in root.find_children("*", "Label", true, false):
		var label := child as Label
		if label.text == text:
			return label
	return null


func _review_fixes() -> Array:
	var found: Array = []
	var routes = preload("res://scripts/drive_routes.gd")
	GameState.new_game("dana")
	for item in GameState.office_items:
		if str(item.get("uid", "")) != "desk":
			item["state"] = "boxed"
	var mug_rec := GameState.find_office_item("mug")
	mug_rec["state"] = "hand"
	var room: Node = RoomLib.new()
	add_child(room)
	room.set("held_uid", "mug")
	room.set("held_source", "office")
	room.set("held_rot", 0.0)
	var spot: Dictionary = room.call("_snap_point", Vector3(2.15, 0.76, 4.45))
	var spot_pos: Vector3 = spot.get("pos", Vector3.ZERO)
	if not bool(spot.get("valid", false)) or absf(spot_pos.y - 0.76) > 0.05:
		found.append("desk top %s" % spot)
	else:
		var mug_def := ItemDB.get_item("starter_mug")
		var foot := SupportMath.footprint(Vector2(spot_pos.x, spot_pos.z), Vector2(float(mug_def.get("w", 0.16)), float(mug_def.get("d", 0.14))), float(spot.get("rot", 0.0)))
		var desk_top := {"id": "desk", "rect": SupportMath.footprint(Vector2(2.5, 4.5), Vector2(1.2, 0.7), 0.0), "top": 0.76, "level": 0}
		var held_up: Dictionary = SupportMath.check(Vector2(spot_pos.x, spot_pos.z), foot, spot_pos.y, [desk_top])
		if not bool(held_up.get("supported", false)):
			found.append("desk support %s" % held_up)
	var buried: Dictionary = room.call("_snap_point", Vector3(2.5, 0.0, 4.5))
	if bool(buried.get("valid", false)):
		found.append("desk should block a floor overlap")
	_bury(room)
	mug_rec = GameState.find_office_item("mug")
	mug_rec["state"] = "hand"
	mug_rec["x"] = 2.05
	SaveManager.save_game()
	if str(GameState.find_office_item("mug").get("state", "")) != "placed":
		found.append("save left mug in hand")
	GameState.job = {"items": [{"uid": "j0", "state": "hand", "x": 1.2, "y": 0.0, "z": 1.4}], "boxes": []}
	SaveManager.save_game()
	var saved_job: Dictionary = GameState.job
	var saved_items: Array = saved_job.get("items", [])
	if saved_items.is_empty() or str(saved_items[0].get("state", "")) != "placed":
		found.append("save left job item in hand")
	GameState.money = 5000
	GameState.total_earned = 2000
	GameState.jobs_done = 3
	GameState.rep_stars = 2
	GameState.office_id = "garage"
	GameState.set_mode("office")
	var app: Node = load("res://scripts/app.gd").new()
	add_child(app)
	var move_err := GameState.try_buy_office("bakery")
	if move_err != "":
		found.append("buy bakery %s" % move_err)
	await get_tree().process_frame
	var saw_bakery := false
	var view := app.get_node_or_null("View")
	if view == null:
		found.append("no play view")
	else:
		for child in view.get_children():
			var venue = child.get("venue")
			if typeof(venue) == TYPE_DICTIONARY and str(venue.get("id", "")) == "bakery":
				saw_bakery = true
	if not saw_bakery:
		found.append("bakery room %s" % GameState.office_id)
	_bury(app)
	var good: Dictionary = ItemDB.trade_goods()[0]
	var good_id := str(good.get("id", ""))
	var base := float(ItemDB.base_price(good_id))
	GameState.prices[good_id] = base
	if GameState.sell_price_of(good_id) != int(round(base * 0.90)):
		found.append("sell ratio %s" % GameState.sell_price_of(good_id))
	var capped := float(GameState._swing(100.0, 10000.0))
	var floored := float(GameState._swing(100.0, 0.0))
	if absf(capped - 250.0) > 0.01 or absf(floored - 50.0) > 0.01:
		found.append("price band %s %s" % [capped, floored])
	GameState.money = 5000
	GameState.total_earned = 0
	GameState.goods_cost = {}
	GameState.goods = {}
	GameState.prices[good_id] = base
	if GameState.buy_good(good_id) != "":
		found.append("buy good")
	GameState.prices[good_id] = base * 2.0
	var before_earned := GameState.total_earned
	var sold: Dictionary = GameState.sell_good(good_id)
	var profit := int(sold.get("profit", 0))
	var gain := int(sold.get("gain", 0))
	if profit == gain or GameState.total_earned - before_earned != profit:
		found.append("earned net %s %s %s" % [profit, gain, GameState.total_earned - before_earned])
	GameState.total_earned = 0
	GameState.job = {
		"id": "job_catcafe",
		"def": JobDB.get_job("job_catcafe"),
		"condition": 95,
		"alley": false,
		"cat_opened": false,
		"items": [
			{"uid": "a", "damage": 1, "state": "placed"},
			{"uid": "b", "damage": 1, "state": "placed"},
		],
		"boxes": [],
	}
	var expected: Dictionary = GameState.compute_payout(120, 95, 0, 2, 0, false, 0)
	var earned_before := GameState.total_earned
	GameState.finish_job()
	var net_pay := int(expected.get("base", 0)) + int(expected.get("net_tips", 0)) + int(expected.get("shortcut", 0))
	var gross_pay := int(expected.get("base", 0)) + int(expected.get("box_tip", 0)) + int(expected.get("bonuses", 0))
	if GameState.total_earned - earned_before != net_pay or net_pay >= gross_pay:
		found.append("job earned %s %s" % [GameState.total_earned - earned_before, expected])
	GameState.job = {
		"condition": 40,
		"items": [
			{"uid": "plain", "fragile": false, "heavy": false, "box": 0, "damage": 0},
			{"uid": "padded", "fragile": true, "heavy": false, "box": 1, "damage": 0},
		],
		"boxes": [
			{"id": 0, "padded": false, "slot": 0},
			{"id": 1, "padded": true, "slot": 1},
		],
	}
	GameState._assign_damage()
	if int(GameState.job_item("plain").get("damage", 0)) != 2 or int(GameState.job_item("padded").get("damage", 0)) > 1:
		found.append("padding per item %s %s" % [GameState.job_item("plain"), GameState.job_item("padded")])
	GameState.job = {
		"condition": 40,
		"items": [
			{"uid": "bottom", "fragile": false, "heavy": true, "box": 0, "damage": 0},
			{"uid": "upper", "fragile": false, "heavy": true, "box": 1, "damage": 0},
		],
		"boxes": [
			{"id": 0, "padded": false, "slot": 0},
			{"id": 1, "padded": false, "slot": 5},
		],
	}
	GameState._assign_damage()
	if int(GameState.job_item("upper").get("damage", 0)) != 2 or int(GameState.job_item("bottom").get("damage", 0)) > 1:
		found.append("heavy per item %s %s" % [GameState.job_item("upper"), GameState.job_item("bottom")])
	var drive: Node = load("res://scripts/drive_course.gd").new()
	add_child(drive)
	if int(drive.call("bump_points", 0.0)) != 3 or int(drive.call("bump_points", 4.5 * 32.0)) != 8:
		found.append("bump ends %s %s" % [drive.call("bump_points", 0.0), drive.call("bump_points", 4.5 * 32.0)])
	var mid := int(drive.call("bump_points", 2.25 * 32.0))
	if mid <= 3 or mid >= 8:
		found.append("bump scale %s" % mid)
	drive.set("condition", 100)
	drive.set("speed", 10.0)
	drive.call("_maybe_hard_brake", "clear", 200.0, 0.05)
	if int(drive.get("condition")) != 100:
		found.append("clear brake %s" % drive.get("condition"))
	drive.call("_maybe_hard_brake", "rain", 200.0, 0.05)
	if int(drive.get("condition")) >= 100 or int(drive.get("condition")) < 96:
		found.append("rain brake %s" % drive.get("condition"))
	_bury(drive)
	var rainy: Dictionary = JobDB.get_drive("rainy_afternoon")
	var lane_left := 0.0
	var lane_right := 0.0
	for rect in rainy.get("roads", []):
		if float(rect[3]) > float(rect[2]):
			lane_left = float(rect[0])
			lane_right = lane_left + float(rect[2])
	for hazard in rainy.get("hazards", []):
		if str(hazard.get("type", "")) != "cone":
			continue
		var cone_x := float(hazard.get("x", 0))
		if cone_x - lane_left < 110.0 or lane_right - cone_x < 110.0:
			found.append("cone lane %s %s %s" % [lane_left, cone_x, lane_right])
	var sample := {
		"version": "v2",
		"full_scale": true,
		"id": "sample",
		"roads": [[10, 20, 30, 40]],
		"alley": {"a": [0, 0], "b": [1280, 0], "width": 110},
	}
	var adopted: Dictionary = routes.adopt(sample)
	var adopted_roads: Array = adopted.get("roads", [])
	var adopted_span: Array = adopted_roads[0] if not adopted_roads.is_empty() else []
	if adopted_span.size() < 3 or int(adopted_span[2]) != 30:
		found.append("route scale %s" % adopted)
	if absf(float(routes.alley_seconds(adopted, 32.0, 4.0)) - 10.0) > 0.05:
		found.append("alley sample %s" % routes.alley_seconds(adopted, 32.0, 4.0))
	if not routes.adopt({"version": "v1", "full_scale": true}).is_empty():
		found.append("v1 route adopted")
	if routes.has_v2("rainy_afternoon"):
		var live := float(routes.alley_seconds(rainy, 32.0, 4.0))
		if live < 9.0 or live > 11.0:
			found.append("v2 alley %s" % live)
	else:
		var alley: Dictionary = rainy.get("alley", {})
		var alley_a: Array = alley.get("a", [])
		var alley_b: Array = alley.get("b", [])
		if alley_a.size() < 2 or alley_b.size() < 2 or int(alley_a[0]) != 2000 or int(alley_b[0]) != 4100:
			found.append("alley moved %s" % alley)
	return found


func _engine_choices() -> Array:
	var found: Array = []
	if str(ProjectSettings.get_setting("physics/3d/physics_engine")) != "Jolt Physics":
		found.append("physics %s" % ProjectSettings.get_setting("physics/3d/physics_engine"))
	if str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) != "forward_plus":
		found.append("renderer %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	if str(ProjectSettings.get_setting("display/window/stretch/aspect")) != "expand":
		found.append("stretch %s" % ProjectSettings.get_setting("display/window/stretch/aspect"))
	if int(ProjectSettings.get_setting("display/window/size/viewport_width")) != 1920 or int(ProjectSettings.get_setting("display/window/size/viewport_height")) != 1080:
		found.append("base %s %s" % [ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height")])
	var low := Graphics.load_environment("low")
	var high := Graphics.load_environment("high")
	if low.ssao_enabled or low.glow_enabled or low.ssil_enabled or low.sdfgi_enabled:
		found.append("low tier")
	if not high.ssao_enabled or not high.glow_enabled or not high.ssil_enabled or high.sdfgi_enabled or absf(high.ssil_radius - 3.0) > 0.001 or absf(high.ssil_intensity - 0.6) > 0.001:
		found.append("high tier")
	if get_viewport().msaa_3d != Viewport.MSAA_2X or int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size")) != 2048:
		found.append("medium quality")
	var tiny := UIKit.label("Readable", 13)
	if int(tiny.get_theme_font_size("font_size")) < 18:
		found.append("font %s" % tiny.get_theme_font_size("font_size"))
	tiny.free()
	var shelf := Props.make("shelf")
	if Props.material_count(shelf) > 2:
		found.append("shelf materials %d" % Props.material_count(shelf))
	_bury(shelf)
	var notes := Props.make("proc:sticky")
	if Props.material_count(notes) > 2:
		found.append("sticky materials %d" % Props.material_count(notes))
	_bury(notes)
	var layout_script = preload("res://scripts/menu_layout.gd")
	var sample: Array = layout_script.records({
		"items": [{"item": "desk_main", "position": [1.5, 0.0, 4.0], "rot": 12}],
	})
	if sample.size() != 1 or str(sample[0].get("item", "")) != "desk_main" or absf(float(sample[0].get("x", 0.0)) - 1.5) > 0.001:
		found.append("loft records %s" % sample)
	var look = layout_script.look_target({"camera": {"look": [4.0, 0.9, 5.0]}})
	if not (look is Vector3) or absf(look.x - 4.0) > 0.001:
		found.append("loft look")
	return found


func _stack_world() -> Array:
	var found: Array = []
	found.append_array(_stack_math())
	found.append_array(_stack_bodies())
	found.append_array(await _stack_physics())
	return found


func _stack_math() -> Array:
	var found: Array = []
	var wide: Rect2 = SupportMath.footprint(Vector2.ZERO, Vector2(2, 1), 0)
	var turned: Rect2 = SupportMath.footprint(Vector2.ZERO, Vector2(2, 1), 90)
	var almost: Rect2 = SupportMath.footprint(Vector2.ZERO, Vector2(2, 1), 46)
	var edge: Rect2 = SupportMath.footprint(Vector2.ZERO, Vector2(2, 1), 45)
	if absf(wide.size.x - 2.0) > 0.001 or absf(wide.size.y - 1.0) > 0.001 or absf(turned.size.x - 1.0) > 0.001 or absf(turned.size.y - 2.0) > 0.001:
		found.append("footprint swap")
	if absf(almost.size.x - 1.0) > 0.001 or absf(edge.size.x - 2.0) > 0.001:
		found.append("footprint band")
	var low := {"id": "a", "rect": Rect2(0, 0, 1, 1), "top": 0.5, "level": 0}
	var high := {"id": "b", "rect": Rect2(1.2, 0, 1, 1), "top": 0.5, "level": 1}
	var span := Rect2(0, 0, 2.2, 1)
	var bridged: Dictionary = SupportMath.check(Vector2(1.1, 0.5), span, 0.5, [low, high])
	if not bool(bridged.get("supported", false)) or not bool(bridged.get("bridged", false)) or int(bridged.get("stack_level", 0)) != 2:
		found.append("bridge %s" % bridged)
	var outside: Dictionary = SupportMath.check(Vector2(2.0, 0.5), Rect2(0, 0, 1, 1), 0.5, [low])
	if bool(outside.get("supported", false)):
		found.append("single hull")
	var inside: Dictionary = SupportMath.check(Vector2(0.5, 0.5), Rect2(0, 0, 1, 1), 0.5, [low])
	if not bool(inside.get("supported", false)) or bool(inside.get("bridged", false)) or int(inside.get("stack_level", 0)) != 1:
		found.append("patch %s" % inside)
	var gapped: Dictionary = SupportMath.check(Vector2(0.5, 0.5), Rect2(0, 0, 1, 1), 0.6, [low])
	if bool(gapped.get("supported", false)):
		found.append("support gap")
	if not SupportMath.wall_mount_ok(0.6) or not SupportMath.wall_mount_ok(2.6) or SupportMath.wall_mount_ok(0.59) or SupportMath.wall_mount_ok(0.0) or SupportMath.wall_mount_ok(2.61):
		found.append("wall band")
	var room_size := Vector2(6, 8)
	if not SupportMath.in_room(Vector2(0.05, 0.05), room_size) or SupportMath.in_room(Vector2(0.04, 1.0), room_size) or not SupportMath.in_room(Vector2(5.95, 7.95), room_size):
		found.append("room margin")
	if SupportMath.tipped(Vector3.UP) or SupportMath.tipped(Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(19.0))):
		found.append("tilt under")
	if not SupportMath.tipped(Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(21.0))):
		found.append("tilt over")
	if absf(SupportMath.room_score(2, 1, 1, 2) - 75.0) > 0.001 or SupportMath.room_score(1, 1, 1, 0) != 0.0:
		found.append("room score math")
	if not SupportMath.near_hint(Vector2.ZERO, [Vector2(0.75, 0)]) or SupportMath.near_hint(Vector2.ZERO, [Vector2(0.76, 0)]):
		found.append("near hint")
	if absf(float(Tuning.get_value("stacking.support_gap", 0.0)) - 0.04) > 0.001 or absf(float(Tuning.get_value("stacking.friction", 0.0)) - 0.9) > 0.001:
		found.append("tuning stacking")
	var rich: Dictionary = GameState.compute_payout(120, 95, 20, 2, 0, false, 0, 100)
	if int(rich.get("room_tip", 0)) != 12 or int(rich.get("total", 0)) != 200:
		found.append("room tip 100 %s" % rich)
	var plain: Dictionary = GameState.compute_payout(120, 95, 20, 2, 0, false, 0, -1)
	if int(plain.get("total", 0)) != 188 or int(plain.get("room_tip", 0)) != 0:
		found.append("room tip absent %s" % plain)
	var floor_score: Dictionary = GameState.compute_payout(120, 95, 20, 2, 0, false, 0, 50)
	if int(floor_score.get("room_tip", -1)) != 0 or int(floor_score.get("total", 0)) != 188:
		found.append("room tip floor %s" % floor_score)
	found.append_array(_stack_results_card(100, "Room setup 100/100 +$12", true))
	found.append_array(_stack_results_card(89, "Room setup 89/100 +$9", false))
	var mug := GameState.find_office_item("mug")
	if not mug.is_empty():
		mug["state"] = "settling"
		SaveManager.save_game()
		if str(GameState.find_office_item("mug").get("state", "")) != "placed":
			found.append("save settling")
	GameState.job = {"items": [
		{"uid": "loose", "state": "loose"},
		{"uid": "boxed", "state": "boxed"},
		{"uid": "mid", "state": "settling"},
		{"uid": "held", "state": "hand"},
	], "boxes": []}
	SaveManager.save_game()
	var states := {}
	for item in GameState.job.get("items", []):
		states[str(item.get("uid", ""))] = str(item.get("state", ""))
	if states.get("loose", "") != "loose" or states.get("boxed", "") != "boxed" or states.get("mid", "") != "placed" or states.get("held", "") != "placed":
		found.append("save states %s" % states)
	return found


func _stack_results_card(score: int, line: String, stamp: bool) -> Array:
	var found: Array = []
	GameState.payout = GameState.compute_payout(120, 95, 0, 0, 0, false, 0, float(score))
	GameState.payout["title"] = "Room"
	GameState.payout["stars"] = 1
	GameState.payout["all_fine"] = false
	var card = load("res://scripts/results_ui.gd").new()
	add_child(card)
	var saw_line := false
	var saw_stamp := false
	for label in card.find_children("*", "Label", true, false):
		if str(label.text) == line:
			saw_line = true
		if "ROOM COMPLETE" in str(label.text):
			saw_stamp = true
	if not saw_line or saw_stamp != stamp:
		found.append("results %s line=%s stamp=%s" % [score, saw_line, saw_stamp])
	_bury(card)
	GameState.payout = {}
	return found


func _stack_bodies() -> Array:
	var found: Array = []
	var holder := Node3D.new()
	add_child(holder)
	Props.add_picker(holder, Vector3(0.4, 0.3, 0.4))
	var picker := holder.get_node_or_null("Picker") as StaticBody3D
	if picker == null or picker.collision_layer != Props.LAYER_PICKABLE or picker.collision_mask != 0:
		found.append("picker layer")
	_bury(holder)
	var sticky := Props.make("proc:sticky")
	if sticky.get_node_or_null("PropCollision") == null:
		found.append("prop collision kept")
	var wrapped = StackItemLib.new()
	wrapped.setup("box", Vector3(0.2, 0.2, 0.2), sticky)
	if sticky.get_node_or_null("PropCollision") != null or wrapped.get_node_or_null("Collider") == null:
		found.append("wrapped collision")
	var visual := Node3D.new()
	visual.name = "Visual"
	wrapped.add_child(visual)
	var squashed = RoomLib._squash_target(wrapped)
	if squashed == wrapped or squashed == null or str(squashed.name) != "Visual":
		found.append("squash mesh")
	wrapped.free()
	var mug = StackItemLib.new()
	mug.setup("mug", Vector3(0.16, 0.11, 0.14))
	if not (mug.get_node("Collider").shape is CylinderShape3D):
		found.append("cylinder mug")
	mug.free()
	var lamp = StackItemLib.new()
	lamp.setup("desk_lamp", Vector3(0.2, 0.4, 0.2))
	if not (lamp.get_node("Collider").shape is BoxShape3D):
		found.append("desk lamp box")
	lamp.free()
	var fern = StackItemLib.new()
	fern.setup("pot", Vector3(0.2, 0.3, 0.2), null, PackedStringArray(["plant_fern"]))
	if not (fern.get_node("Collider").shape is CylinderShape3D):
		found.append("cylinder plant")
	fern.free()
	var room = StackRoomLib.new()
	room.configure(Vector2.ZERO, Vector2(6, 8))
	room.add_floor()
	add_child(room)
	var mounted := {"n": Vector3(2.0, 1.5, 0.12), "w": Vector3(0.12, 1.5, 2.0), "e": Vector3(5.88, 1.5, 2.0)}
	var yaws := {"n": 0.0, "w": 90.0, "e": -90.0}
	for side in ["n", "w", "e"]:
		var frame = StackItemLib.new()
		frame.setup("frame", Vector3(0.4, 0.3, 0.08))
		if not room.mount("pic_%s" % side, 2.0, 1.5, side, frame):
			found.append("mount %s" % side)
			frame.free()
			continue
		var want: Vector3 = mounted[side]
		if frame.global_position.distance_to(want) > 0.02:
			found.append("mount pos %s %s" % [side, frame.global_position])
		if absf(wrapf(rad_to_deg(frame.rotation.y) - float(yaws[side]), -180.0, 180.0)) > 0.2:
			found.append("mount yaw %s %s" % [side, rad_to_deg(frame.rotation.y)])
		if not frame.freeze:
			found.append("mount freeze %s" % side)
	var low = StackItemLib.new()
	low.setup("frame", Vector3(0.2, 0.2, 0.05))
	if room.mount("low", 2.0, 0.2, "n", low):
		found.append("low mount")
	else:
		low.free()
	if str(room.nearest_wall(Vector3(0.4, 1.2, 3.0))) != "w" or str(room.nearest_wall(Vector3(3.0, 1.2, 4.0))) != "":
		found.append("nearest wall")
	for i in 3:
		var tier = StackItemLib.new()
		tier.setup("crate", Vector3(0.4, 0.3, 0.4))
		tier.item_id = "tier%d" % i
		room.adopt(tier)
		tier.spawn_frozen(Vector3(2, 0.3 * i, 3), 0)
		room.results[tier.item_id] = {"supported": true}
	var saved: Dictionary = room.items.duplicate()
	room.items = {"tier0": saved["tier0"], "tier1": saved["tier1"], "tier2": saved["tier2"]}
	if absf(float(room.score()) - 100.0) > 0.01:
		found.append("scored stack %s" % room.score())
	room.items = saved
	room.wake("tier0")
	for tier_id in ["tier0", "tier1", "tier2"]:
		if bool(room.items[tier_id].freeze):
			found.append("wake %s" % tier_id)
	var floater = StackItemLib.new()
	floater.setup("crate", Vector3(0.3, 0.3, 0.3))
	floater.item_id = "float"
	room.adopt(floater)
	floater.spawn_frozen(Vector3(4, 1.5, 3), 0)
	floater.note_safe(Vector3(4, 0, 3), 0)
	room.resolve_settled(floater)
	if floater.global_position.distance_to(Vector3(4, 0, 3)) > 0.05 or not bool(room.results["float"].get("reset", false)):
		found.append("gentle reset %s" % floater.global_position)
	var lean = StackItemLib.new()
	lean.setup("crate", Vector3(0.3, 0.3, 0.3))
	lean.item_id = "lean"
	room.adopt(lean)
	lean.spawn_frozen(Vector3(4, 0, 5), 0)
	lean.rotation = Vector3(deg_to_rad(35), 0, 0)
	lean.note_safe(Vector3(4, 0, 5), 0)
	room.resolve_settled(lean)
	if not bool(lean.live_drop):
		found.append("retip")
	lean.halt()
	room.snap_assist = true
	var snap = StackItemLib.new()
	snap.setup("box", Vector3(0.2, 0.2, 0.2))
	room.place("snap", Vector3(1.12, 0.4, 2.08), deg_to_rad(10.0), snap)
	if absf(snap.global_position.x - snapped(1.12, 0.25)) > 0.001 or absf(snap.global_position.z - snapped(2.08, 0.25)) > 0.001:
		found.append("snap grid %s" % snap.global_position)
	if absf(rad_to_deg(snap.rotation.y) - snapped(10.0, 15.0)) > 0.05:
		found.append("snap yaw %s" % rad_to_deg(snap.rotation.y))
	snap.halt()
	room.shutdown()
	_bury(room)
	return found


func _stack_physics() -> Array:
	var found: Array = []
	var capped := Engine.max_fps
	Engine.max_fps = 60
	var room = StackRoomLib.new()
	room.configure(Vector2.ZERO, Vector2(6, 8))
	room.add_floor()
	room.add_block(Vector3(2.0, 0.38, 3.0), Vector3(1.2, 0.76, 0.7))
	room.add_furniture("desk", Vector2(2.0, 3.0), Vector2(1.2, 0.7), 0.76, 0.0, 0)
	room.add_block(Vector3(4.2, 1.06, 5.5), Vector3(0.9, 0.08, 0.4))
	room.add_furniture("shelf", Vector2(4.2, 5.5), Vector2(0.9, 0.4), 1.10, 0.0, 0)
	room.add_block(Vector3(1.5, 0.125, 6.4), Vector3(1.0, 0.25, 0.6))
	room.add_furniture("ledge", Vector2(1.5, 6.4), Vector2(1.0, 0.6), 0.25, 0.0, 0)
	add_child(room)
	var desk = StackItemLib.new()
	desk.setup("crate", Vector3(0.28, 0.28, 0.28))
	desk.item_id = "on_desk"
	desk.note_safe(Vector3(2, 0, 3), 0)
	room.adopt(desk)
	desk.drop_at(Vector3(2, 0.77, 3), 0)
	if not await _wait_eval(room, "on_desk", 32):
		found.append("desk settle")
	else:
		var desk_result: Dictionary = room.results["on_desk"]
		if not bool(desk_result.get("supported", false)) or int(desk_result.get("stack_level", 0)) != 1 or absf(desk.rest_bottom() - 0.76) > 0.06:
			found.append("desk rest %s %s" % [desk.rest_bottom(), desk_result])
	var upper = StackItemLib.new()
	upper.setup("crate", Vector3(0.24, 0.24, 0.24))
	upper.item_id = "on_box"
	upper.note_safe(Vector3(2, 0, 3), 0)
	room.adopt(upper)
	upper.drop_at(Vector3(2, desk.rest_bottom() + desk.size.y + 0.01, 3), 0)
	if not await _wait_eval(room, "on_box", 32):
		found.append("stack settle")
	else:
		var pile: Dictionary = room.results["on_box"]
		if not bool(pile.get("supported", false)) or int(pile.get("stack_level", 0)) != 2:
			found.append("stack level %s" % pile)
	var shelf_item = StackItemLib.new()
	shelf_item.setup("crate", Vector3(0.22, 0.18, 0.22))
	shelf_item.item_id = "on_shelf"
	shelf_item.note_safe(Vector3(4.2, 0, 5.5), 0)
	room.adopt(shelf_item)
	shelf_item.drop_at(Vector3(4.2, 1.12, 5.5), 0)
	if not await _wait_eval(room, "on_shelf", 32):
		found.append("shelf settle")
	else:
		var shelf_result: Dictionary = room.results["on_shelf"]
		if not bool(shelf_result.get("supported", false)) or str(shelf_result.get("support_id", "")) != "shelf" or absf(shelf_item.rest_bottom() - 1.10) > 0.06:
			found.append("shelf rest %s %s" % [shelf_item.rest_bottom(), shelf_result])
	var hang = StackItemLib.new()
	hang.setup("crate", Vector3(0.4, 0.2, 0.3))
	hang.item_id = "over"
	var over_at := Vector2(2.16, 6.4)
	var overhang: Dictionary = SupportMath.check(over_at, SupportMath.footprint(over_at, Vector2(0.4, 0.3), 0), 0.28, room.surfaces)
	if bool(overhang.get("supported", false)):
		found.append("overhang math %s" % overhang)
	hang.note_safe(Vector3(3.4, 0.02, 6.4), 0)
	room.adopt(hang)
	# The pose above is unsupported. Release the body just past the ledge so it falls to the floor.
	hang.drop_at(Vector3(2.4, 0.08, over_at.y), 0)
	if not await _wait_eval(room, "over", 28):
		found.append("overhang settle %s" % hang.global_position)
	elif hang.global_position.y > 0.1 and hang.global_position.distance_to(Vector3(3.4, 0.02, 6.4)) > 0.3:
		found.append("overhang stayed %s" % hang.global_position)
	var lost = StackItemLib.new()
	lost.setup("crate", Vector3(0.2, 0.2, 0.2))
	lost.item_id = "lost"
	lost.note_safe(Vector3(3.0, 0.05, 2.0), 0)
	room.adopt(lost)
	lost.drop_at(Vector3(-1.2, 0.4, 2.0), 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if lost.global_position.x < 1.0:
		found.append("out of room %s" % lost.global_position)
	lost.halt()
	await get_tree().process_frame
	room.shutdown()
	_bury(room)
	Engine.max_fps = capped
	return found


func _wait_eval(room, id: String, limit: int) -> bool:
	var hit := {"id": ""}
	var cb := func(got_id: String, _result: Dictionary) -> void:
		if got_id == id:
			hit["id"] = got_id
	room.item_evaluated.connect(cb)
	var ok := false
	for _i in limit:
		await get_tree().physics_frame
		if str(hit["id"]) == id:
			ok = true
			break
	if not ok:
		await get_tree().process_frame
		ok = str(hit["id"]) == id
	if room.item_evaluated.is_connected(cb):
		room.item_evaluated.disconnect(cb)
	return ok
