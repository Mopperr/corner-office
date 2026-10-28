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
			for child in drive.find_children("*", "Node3D", true, false):
				if str(child.name) in ["fountain", "willow", "bridge_closed", "duck", "duckling"]:
					dressed += 1
			if dressed < 4:
				failures.append("pond props %d" % dressed)
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
		var goal_fern := loft.find_child("GoalFern", true, false) as Node3D
		var nook_beam := loft.find_child("NookBeam", true, false) as Node3D
		if goal_fern == null or nook_beam == null:
			failures.append("beam nook missing")
		else:
			var view_dir := Vector2(1, 1).normalized()
			var fern_depth := Vector2(goal_fern.position.x, goal_fern.position.z).dot(view_dir)
			var beam_depth := Vector2(nook_beam.position.x, nook_beam.position.z).dot(view_dir)
			if fern_depth <= beam_depth + 0.2:
				failures.append("beam hides fern %s %s" % [fern_depth, beam_depth])
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
	failures.append_array(_readability_goals())
	failures.append_array(_content_engine())
	failures.append_array(await _stack_world())
	failures.append_array(await _menu_audit())
	failures.append_array(await _home_checks())
	failures.append_array(await _party_checks())
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


func _content_engine() -> Array:
	# The daily board: same seed and day give the same jobs, every job is
	# playable (known items, a drive between real places), and goals pay out.
	var found: Array = []
	var gen = load("res://scripts/job_gen.gd")
	var a: Dictionary = gen.board(1234, 3, 1, 2, 3)
	var b: Dictionary = gen.board(1234, 3, 1, 2, 3)
	if JSON.stringify(a) != JSON.stringify(b):
		found.append("board not deterministic")
	var c: Dictionary = gen.board(1234, 4, 1, 2, 3)
	if JSON.stringify(a) == JSON.stringify(c):
		found.append("board same on a new day")
	var city = load("res://scripts/city.gd").load_default()
	var jobs: Array = a.get("jobs", [])
	if jobs.size() != 3:
		found.append("board size %d" % jobs.size())
	for job in jobs:
		var pieces := 0
		for group in job.get("recipe", []):
			var item_id := str(group.get("item", ""))
			if ItemDB.get_item(item_id).is_empty():
				found.append("board item %s" % item_id)
			pieces += int(group.get("count", 0))
		if pieces < 8:
			found.append("board job %s has %d pieces" % [job.get("id", ""), pieces])
		if not ItemDB.venues().has(str(job.get("venue", ""))):
			found.append("board venue %s" % job.get("venue", ""))
		var drive: Dictionary = a.get("drives", {}).get(str(job.get("drive", "")), {})
		if drive.is_empty():
			found.append("board drive missing for %s" % job.get("id", ""))
			continue
		var from: Dictionary = city.place(str(drive.get("pickup", "")))
		var to: Dictionary = city.place(str(drive.get("dropoff", "")))
		if from.is_empty() or to.is_empty():
			found.append("board drive places %s -> %s" % [drive.get("pickup", ""), drive.get("dropoff", "")])
		elif city.route((from.get("bay", Rect2()) as Rect2).get_center(), (to.get("bay", Rect2()) as Rect2).get_center()).size() < 2:
			found.append("board drive has no route %s" % drive.get("id", ""))
		if str(job.get("twist", "")) == "cat" and not bool(job.get("cat", false)):
			found.append("cat twist without cat flag")
	# Jobs land in JobDB beside the story jobs and leave the story jobs alone.
	GameState.new_game("dana")
	GameState.tutorial_done = true
	if GameState.generated_jobs.is_empty():
		found.append("new game has no board")
	var first: Dictionary = GameState.generated_jobs[0] if not GameState.generated_jobs.is_empty() else {}
	var listed := JobDB.get_job(str(first.get("id", "")))
	if listed.is_empty() or not GameState.job_available(listed):
		found.append("board job not offered")
	if JobDB.get_drive(str(first.get("drive", ""))).is_empty():
		found.append("board drive not served by JobDB")
	if JobDB.base_pay(listed) < 100:
		found.append("board pay %d" % JobDB.base_pay(listed))
	if JobDB.get_job("job_catcafe").is_empty():
		found.append("story job lost")
	var before_board := JSON.stringify(GameState.generated_jobs)
	GameState.start_job(str(first.get("id", "")))
	if GameState.mode != "job_pack" or GameState.job.get("items", []).is_empty():
		found.append("board job did not start (%s)" % GameState.mode)
	GameState.jobs_cleared[str(first.get("id", ""))] = true
	if GameState.job_available(listed):
		found.append("finished board job still offered")
	GameState.advance_day()
	if JSON.stringify(GameState.generated_jobs) == before_board:
		found.append("board did not refresh on a new day")
	if not GameState.generated_drives.has(str(first.get("drive", ""))):
		found.append("drive of the job in progress dropped on refresh")
	# The night card: a day's log is summed up and handed over on Next day.
	GameState.new_game("dana")
	GameState.money = 500
	GameState.day_log = GameState._fresh_day_log()
	GameState.stats["cats_found"] = 2
	GameState.check_contracts()
	var summaries: Array = []
	var catcher := func(summary: Dictionary): summaries.append(summary)
	GameState.day_ended.connect(catcher)
	GameState.advance_day()
	GameState.day_ended.disconnect(catcher)
	if summaries.size() != 1:
		found.append("day_ended emitted %d" % summaries.size())
	else:
		var summary: Dictionary = summaries[0]
		if int(summary.get("day", 0)) != 1 or int(summary.get("money_end", 0)) - int(summary.get("money_start", 0)) != 30:
			found.append("day summary money %s" % summary)
		if (summary.get("goals", []) as Array).size() != 1 or str(summary.get("next_job", "")) == "":
			found.append("day summary goals/next %s" % summary)
	if int(GameState.day_log.get("jobs", 0)) != 0 or int(GameState.day_log.get("money_start", 0)) != GameState.money:
		found.append("day log not reset")
	for venue_id in ["studio", "flat"]:
		if not ItemDB.venues().has(venue_id):
			found.append("venue %s missing" % venue_id)
	# The shop ladder: gated by money and Rep, widens the menu, and is saved.
	GameState.new_game("dana")
	if Catalog.tiers().size() < 6 or GameState.shop_tier != "stand":
		found.append("tiers %d / %s" % [Catalog.tiers().size(), GameState.shop_tier])
	GameState.money = 10
	if GameState.upgrade_shop() == "":
		found.append("upgrade with no money")
	GameState.money = 1000
	if GameState.upgrade_shop() != "" or GameState.shop_tier != "cart":
		found.append("upgrade to cart")
	if GameState.upgrade_shop() == "":
		found.append("sandwich bar without Rep")
	GameState.rep_stars = 10
	if GameState.upgrade_shop() != "" or GameState.shop_tier != "sandwich":
		found.append("upgrade to sandwich bar")
	if not GameState.contracts_done.has("tier_cart"):
		found.append("tier goal")
	GameState.office_items.append({"uid": "smoke_counter", "item": "coffee_machine", "state": "placed", "x": 2, "y": 0.76, "z": 4, "rot": 0})
	var dishes := GameState.shop_dishes()
	if not ("blt" in dishes and "flat_white" in dishes and "drip" in dishes):
		found.append("tier dishes %s" % str(dishes))
	if "tasting_menu" in dishes:
		found.append("restaurant dish served early")
	SaveManager.save_game()
	GameState.shop_tier = "stand"
	if not SaveManager.load_game() or GameState.shop_tier != "sandwich":
		found.append("shop tier not saved")
	# The workbench: materials, a make with a con, a sale with a story, fix-ups, and a save.
	var Workshop = load("res://scripts/workshop.gd")
	GameState.new_game("dana")
	GameState.money = 500
	if Workshop.skill() != 1 or Workshop.recipes().size() < 10:
		found.append("workshop fresh %d / %d" % [Workshop.skill(), Workshop.recipes().size()])
	if Workshop.craft("mug_glazed").get("ok", false):
		found.append("craft without materials")
	if Workshop.buy_material("clay", 5) != "" or Workshop.have("clay") != 5:
		found.append("buy material")
	if str(Workshop.con_of(1).get("name", "")) != "yellow" or str(Workshop.con_of(30).get("name", "")) != "red" or str(Workshop.con_of(-20).get("name", "")) != "grey":
		found.append("con colours %s %s %s" % [Workshop.con_of(1).get("name", ""), Workshop.con_of(30).get("name", ""), Workshop.con_of(-20).get("name", "")])
	var made_ok := false
	for attempt in 8:
		var result: Dictionary = Workshop.craft("mug_glazed")
		if bool(result.get("ok", false)):
			made_ok = true
			break
		if Workshop.have("clay") < 2:
			Workshop.buy_material("clay", 2)
	if not made_ok or Workshop.made_count("mug_glazed") < 1:
		found.append("craft never succeeded")
	if not GameState.contracts_done.has("first_craft"):
		found.append("craft goal")
	var before_money := GameState.money
	var sale: Dictionary = Workshop.sell("mug_glazed", false)
	if sale.has("error") or GameState.money <= before_money or str(sale.get("story", "")) == "":
		found.append("craft sale %s" % str(sale))
	if (Workshop.state().get("journal", []) as Array).is_empty():
		found.append("journal empty")
	var ask: Dictionary = Workshop.offer()
	if ask.is_empty() or Workshop.offer() != ask:
		found.append("craft offer not stable in a day")
	# Fix-up: a worn good becomes restored, and a buyer who wants restored takes it.
	var good_id := str(ItemDB.trade_goods()[0].get("id", ""))
	GameState.goods[good_id] = 1
	Workshop.buy_material("cloth", 2)
	Workshop.buy_material("metal", 2)
	var fixed: Dictionary = {}
	for attempt in 6:
		fixed = Workshop.fix_up(good_id)
		if not fixed.has("error"):
			break
		Workshop.buy_material("cloth", 1)
		Workshop.buy_material("metal", 1)
	if fixed.has("error") or Workshop.graded(good_id, "restored") != 1 or int(GameState.goods.get(good_id, 0)) != 0:
		found.append("fix up %s" % str(fixed))
	GameState.buyer_offer = {"name": "Nia", "item": good_id, "grade": "restored", "price": 90, "line": ""}
	var before2 := GameState.money
	var sold: Dictionary = GameState.sell_to_buyer()
	if sold.has("error") or GameState.money - before2 != 90 or Workshop.graded(good_id, "restored") != 0:
		found.append("sell restored to buyer %s" % str(sold))
	GameState.buyer_offer = {"name": "Nia", "item": good_id, "grade": "mint", "price": 120, "line": ""}
	if not GameState.sell_to_buyer().has("error"):
		found.append("sold a mint we do not have")
	var skill_before: int = Workshop.skill()
	SaveManager.save_game()
	GameState.workshop = {}
	if not SaveManager.load_game() or Workshop.skill() != skill_before or Workshop.have("clay") < 0:
		found.append("workshop not saved")
	# The back room: a tree bought with cred, fencing that heats up, a visit, and a save.
	var Crime = load("res://scripts/crime.gd")
	GameState.new_game("dana")
	GameState.money = 300
	if Crime.nodes().size() < 9 or Crime.cred() != 0 or Crime.heat() != 0:
		found.append("crime fresh")
	if Crime.unlock("fence_2") == "":
		found.append("unlocked a rung without the one below")
	if Crime.unlock("fence_1") != "" or not Crime.unlocked("fence_1"):
		found.append("unlock fence_1")
	var fence_good := str(ItemDB.trade_goods()[0].get("id", ""))
	if not Crime.fence(fence_good, 1).has("error"):
		found.append("fenced a good we do not own")
	GameState.goods[fence_good] = 6
	var cash_before := GameState.money
	var fenced: Dictionary = Crime.fence(fence_good, 1)
	if fenced.has("error") or GameState.money <= cash_before or Crime.cred() != 1 or Crime.heat() != 2:
		found.append("fence %s cred %d heat %d" % [str(fenced), Crime.cred(), Crime.heat()])
	if not Crime.fence(fence_good, 5).has("error"):
		found.append("bulk fence before tier 2")
	GameState.crime["heat"] = 9
	Crime.fence(fence_good, 1)
	var lie_low := 0
	for mail in GameState.inbox:
		if str(mail.get("subject", "")) == "Lie low":
			lie_low += 1
	if int(GameState.crime.get("visits", 0)) != 1 or Crime.heat() >= 9 or lie_low != 1:
		found.append("visit heat %d visits %d mail %d" % [Crime.heat(), int(GameState.crime.get("visits", 0)), lie_low])
	GameState.crime["heat"] = 6
	GameState.advance_day()
	if Crime.heat() != 4:
		found.append("heat decay %d" % Crime.heat())
	# Two more visits make a raid: goods halved, a fine, the shop shut.
	GameState.crime["visits"] = 2
	GameState.crime["heat"] = 9
	GameState.goods[fence_good] = 4
	# A big jar so the fine (30%) outweighs the fence sale and any goal reward that ticks over.
	GameState.money = 2000
	Crime.fence(fence_good, 1)
	if int(GameState.crime.get("raids", 0)) != 1 or int(GameState.goods.get(fence_good, 0)) != 1 or GameState.money >= 1700 or not Crime.raided_today():
		found.append("raid goods %d money %d raided %s" % [int(GameState.goods.get(fence_good, 0)), GameState.money, Crime.raided_today()])
	# Broke and idle, and Sal writes.
	GameState.money = 20
	var mail_before := GameState.inbox.size()
	GameState.advance_day()
	if GameState.inbox.size() != mail_before + 1 or not bool(GameState.crime.get("nudged", false)):
		found.append("sal nudge")
	GameState.money = 300
	GameState.crime["cred"] = 20
	GameState.tutorial_done = true
	GameState.set_mode("office")
	GameState.office_phase = "live"
	var night_err: String = Crime.take_night_job() if Crime.unlock("night_1") == "" else "unlock failed"
	if night_err != "" or GameState.mode != "job_pack" or not bool(GameState.job.get("def", {}).get("shady", false)):
		found.append("night job %s (%s)" % [GameState.mode, night_err])
	if JobDB.get_drive(str(GameState.job.get("def", {}).get("drive", ""))).is_empty():
		found.append("night drive missing")
	var cred_before: int = Crime.cred()
	SaveManager.save_game()
	GameState.crime = {}
	if not SaveManager.load_game() or Crime.cred() != cred_before or not Crime.unlocked("night_1"):
		found.append("crime not saved")
	# Goals: progress, reward, mail, and a save round trip.
	GameState.new_game("dana")
	var money_before := GameState.money
	var inbox_before := GameState.inbox.size()
	GameState.stats["cats_found"] = 2
	GameState.check_contracts()
	if not GameState.contracts_done.has("cat_two"):
		found.append("contract not awarded")
	if GameState.money - money_before != 30:
		found.append("contract money %d" % (GameState.money - money_before))
	if GameState.inbox.size() != inbox_before + 1:
		found.append("contract mail")
	if GameState.contracts_done.has("first_job"):
		found.append("contract awarded early")
	GameState.bump_stat("alley_runs", 3)
	if not GameState.contracts_done.has("alley_three"):
		found.append("bump_stat does not award")
	SaveManager.save_game()
	GameState.contracts_done = {}
	GameState.stats = {}
	GameState.generated_jobs = []
	if not SaveManager.load_game():
		found.append("contract save load")
	if not GameState.contracts_done.has("alley_three") or int(GameState.stats.get("alley_runs", 0)) != 3:
		found.append("contracts not saved")
	if GameState.generated_jobs.is_empty():
		found.append("board not saved")
	return found


func _readability_goals() -> Array:
	var found: Array = []
	var goals = preload("res://scripts/stack_goals.gd")
	var layouts = preload("res://scripts/shop_layout.gd")
	# The whiteboard is 0.10 m deep, so nothing can rest on it. The L1 notes goal is the desk.
	var notes := goals.by_id("stack_l1_notes_on_desk")
	if "desk" not in str(notes.get("hint", "")).to_lower():
		found.append("notes hint %s" % notes.get("hint", ""))
	var desk := {"uid": "desk", "item": "desk_main", "model": "desk_main", "x": 2.5, "y": 0.0, "z": 4.5, "rot": 0.0, "w": 1.4, "d": 0.7, "h": 0.76, "tag": ""}
	var on_desk := {"uid": "notes", "item": "sticky_note_stack", "model": "sticky_note_stack", "x": 2.05, "y": 0.76, "z": 4.6, "rot": 0.0, "w": 0.25, "d": 0.23, "h": 0.14, "tag": ""}
	var on_floor := on_desk.duplicate(true)
	on_floor["y"] = 0.0
	on_floor["x"] = 0.9
	on_floor["z"] = 1.0
	if not bool(goals.evaluate(notes, [desk, on_desk]).get("met", false)):
		found.append("notes desk")
	if bool(goals.evaluate(notes, [desk, on_floor]).get("met", false)):
		found.append("notes floor")
	var plant := goals.by_id("stack_l2_plant_on_counter")
	if "espresso" not in str(plant.get("hint", "")).to_lower() or "hanging" in str(plant.get("hint", "")).to_lower():
		found.append("plant hint")
	var counter := {"uid": "counter", "item": "cafe_counter", "model": "cafe_counter", "x": 3.2, "y": 0.0, "z": 4.7, "w": 2.05, "d": 0.75, "h": 0.95, "rot": 0.0, "tag": ""}
	var espresso := {"uid": "espresso", "item": "espresso", "model": "espresso_machine_pro", "x": 3.5, "y": 0.95, "z": 4.7, "w": 0.55, "d": 0.44, "h": 0.73, "rot": 0.0, "tag": ""}
	var small := {"uid": "plant", "item": "cafe_plant", "model": "plant_small", "x": 3.2, "y": 0.95, "z": 4.7, "w": 0.28, "d": 0.28, "h": 0.4, "rot": 0.0, "tag": ""}
	var hanging := small.duplicate(true)
	hanging["item"] = "hanging_plant"
	hanging["model"] = "hanging_plant"
	var on_machine := small.duplicate(true)
	on_machine["y"] = 1.68
	on_machine["x"] = 3.5
	if not bool(goals.evaluate(plant, [counter, small]).get("met", false)):
		found.append("plant counter")
	if bool(goals.evaluate(plant, [counter, hanging]).get("met", false)) or bool(goals.evaluate(plant, [counter, espresso, on_machine]).get("met", false)):
		found.append("plant espresso")
	var mug_goal := goals.by_id("stack_l2_mug_on_rack_shelf")
	if str(mug_goal.get("hint", "")) != "Mug on top of the rack.":
		found.append("mug hint")
	var rack := {"uid": "rack", "item": "mug_rack", "model": "mug_rack", "x": 0.12, "y": 1.35, "z": 3.2, "w": 0.7, "d": 0.185, "h": 0.6, "rot": 90.0, "tag": ""}
	var mug := {"uid": "mug", "item": "cafe_mug", "model": "mug_worlds_okayest", "x": 0.12, "y": 1.95, "z": 3.2, "w": 0.16, "d": 0.14, "h": 0.12, "rot": 0.0, "tag": ""}
	var peg := mug.duplicate(true)
	peg["y"] = 1.7
	if not bool(goals.evaluate(mug_goal, [rack, mug]).get("met", false)) or bool(goals.evaluate(mug_goal, [rack, peg]).get("met", false)):
		found.append("mug top")
	var pose := goals.marker_pose(mug_goal, [rack, mug])
	if str(pose.get("kind", "")) != "ghost" or str(pose.get("show", "")) != "held":
		found.append("mug ghost %s" % pose)
	var chalk := goals.by_id("stack_l2_menu_chalk_cushion")
	if int(chalk.get("stack_count", 0)) != 2 or absf(float(chalk.get("overhang", 0.0)) - 0.25) > 0.001:
		found.append("chalk rule")
	if "2 cushions" not in str(chalk.get("hint", "")):
		found.append("chalk hint")
	var base := {"uid": "c0", "item": "cushion", "model": "cafe_cushion", "x": 2.0, "y": 0.0, "z": 2.0, "w": 0.5, "d": 0.5, "h": 0.16, "rot": 0.0, "tag": ""}
	var mid := base.duplicate(true)
	mid["uid"] = "c1"
	mid["y"] = 0.16
	var extra := base.duplicate(true)
	extra["uid"] = "c2"
	extra["y"] = 0.32
	var board_item := {"uid": "board_item", "item": "menu_board", "model": "chalk_menu_board", "x": 2.0, "y": 0.32, "z": 2.0, "w": 0.9, "d": 0.05, "h": 1.2, "rot": 0.0, "tag": ""}
	if not bool(goals.evaluate(chalk, [base, mid, board_item]).get("met", false)):
		found.append("chalk two")
	if bool(goals.evaluate(chalk, [base, board_item]).get("met", false)) or bool(goals.evaluate(chalk, [base, mid, extra, board_item]).get("met", false)):
		found.append("chalk count")
	var fern_goal := goals.by_id("stack_l6_plant_on_beam_nook")
	if "clears" not in str(fern_goal.get("hint", "")):
		found.append("fern hint")
	var shelf := {"uid": "shelf", "item": "shelf", "model": "shelf", "x": -1.1, "y": 0.0, "z": 5.1, "w": 0.9, "d": 0.36, "h": 1.6, "rot": 0.0, "tag": ""}
	var fern := {"uid": "fern", "item": "plant_fern", "model": "plant_tall", "x": -1.1, "y": 1.6, "z": 5.1, "w": 0.55, "d": 0.5, "h": 1.14, "rot": 0.0, "tag": ""}
	var behind := {"uid": "beam_back", "item": "beam", "model": "ceiling_beam", "x": -2.2, "y": 2.35, "z": 3.3, "w": 1.6, "d": 0.29, "h": 0.29, "rot": 0.0, "tag": ""}
	var ahead := {"uid": "beam_front", "item": "beam", "model": "ceiling_beam", "x": -1.1, "y": 2.35, "z": 6.2, "w": 1.6, "d": 0.29, "h": 0.29, "rot": 0.0, "tag": ""}
	if not bool(goals.evaluate(fern_goal, [shelf, fern, behind]).get("met", false)):
		found.append("fern clear")
	if bool(goals.evaluate(fern_goal, [shelf, fern, ahead]).get("met", false)):
		found.append("fern blocked")
	var pastry_goal := goals.by_id("stack_l6_pastry_on_radiator_shelf")
	if absf(float(pastry_goal.get("near_m", 0.0)) - 1.0) > 0.001 or str(pastry_goal.get("marker", "")) != "ring":
		found.append("radiator rule")
	var radiator := {"uid": "rad", "item": "radiator", "model": "radiator", "x": 0.55, "y": 0.0, "z": 6.4, "w": 0.9, "d": 0.5, "h": 0.5, "rot": 0.0, "tag": ""}
	var near_shelf := shelf.duplicate(true)
	near_shelf["x"] = 0.7
	near_shelf["z"] = 6.2
	var far_shelf := near_shelf.duplicate(true)
	far_shelf["x"] = 2.2
	var bun := {"uid": "bun", "item": "pastry_basket", "model": "pastry_basket", "x": 0.7, "y": 1.6, "z": 6.2, "w": 0.4, "d": 0.4, "h": 0.23, "rot": 0.0, "tag": ""}
	var far_bun := bun.duplicate(true)
	far_bun["x"] = 2.2
	if not bool(goals.evaluate(pastry_goal, [radiator, near_shelf, bun]).get("met", false)):
		found.append("radiator near")
	if bool(goals.evaluate(pastry_goal, [radiator, far_shelf, far_bun]).get("met", false)):
		found.append("radiator far")
	var ring := goals.marker_pose(pastry_goal, [radiator])
	if str(ring.get("kind", "")) != "ring" or absf(float(ring.get("radius", 0.0)) - 1.0) > 0.001:
		found.append("radiator ring")
	var lamp_goal := goals.by_id("stack_l6_lamp_on_stair_nook")
	if "stair step" not in str(lamp_goal.get("hint", "")).to_lower():
		found.append("stair hint")
	var step := {"uid": "step", "item": "stair_step", "model": "stair_step", "x": 1.0, "y": 0.0, "z": 4.6, "w": 1.0, "d": 0.3, "h": 0.22, "rot": 0.0, "tag": ""}
	var tread := {"uid": "tread", "item": "stair_tread", "model": "stair_tread", "x": 1.0, "y": 0.0, "z": 4.6, "w": 1.0, "d": 0.3, "h": 0.22, "rot": 0.0, "tag": ""}
	var lamp := {"uid": "lamp", "item": "desk_lamp", "model": "lamp", "x": 1.0, "y": 0.22, "z": 4.6, "w": 0.36, "d": 0.36, "h": 0.58, "rot": 0.0, "tag": ""}
	if not bool(goals.evaluate(lamp_goal, [step, lamp]).get("met", false)) or bool(goals.evaluate(lamp_goal, [tread, lamp]).get("met", false)):
		found.append("stair only")
	var boxes := goals.by_id("stack_l4_box_on_box_sorted")
	if float(boxes.get("complete_yaw", 0.0)) != 15.0 or "keep-together" not in str(boxes.get("hint", "")):
		found.append("box hint")
	var lower := {"uid": "b0", "item": "box_closed", "model": "box_closed", "x": 1.0, "y": 0.0, "z": 1.0, "w": 0.5, "d": 0.4, "h": 0.36, "rot": 0.0, "tag": "clocks", "turned": false}
	var upper := lower.duplicate(true)
	upper["uid"] = "b1"
	upper["y"] = 0.36
	var other := upper.duplicate(true)
	other["tag"] = "tools"
	var stacked: Dictionary = goals.evaluate(boxes, [lower, upper])
	if not bool(stacked.get("met", false)) or absf(float(stacked.get("yaw_add", 0.0)) - 15.0) > 0.001:
		found.append("box tag %s" % stacked)
	if bool(goals.evaluate(boxes, [lower, other]).get("met", false)):
		found.append("box mismatch")
	var ghost := goals.marker_pose(boxes, [lower])
	if absf(float(ghost.get("rot", 0.0)) - 15.0) > 0.001:
		found.append("box ghost")
	var cat_goal := goals.by_id("stack_l1sol_cushion_on_catbed")
	if not bool(cat_goal.get("latch", false)) or "stays done" not in str(cat_goal.get("hint", "")):
		found.append("cat latch hint")
	var bed := {"uid": "bed", "item": "cat_bed", "model": "cat_bed", "x": 1.0, "y": 0.0, "z": 1.0, "w": 0.5, "d": 0.4, "h": 0.16, "rot": 0.0, "tag": ""}
	var seat := base.duplicate(true)
	seat["x"] = 1.0
	seat["z"] = 1.0
	seat["y"] = 0.16
	var latched := {str(cat_goal.get("id", "")): true}
	if not bool(goals.evaluate(cat_goal, [bed, seat]).get("met", false)):
		found.append("cat seat")
	if not bool(goals.evaluate(cat_goal, [], latched).get("met", false)):
		found.append("cat stays")
	var crate_goal := goals.by_id("shopl_cushion_crate_seat")
	if absf(float(crate_goal.get("overhang", 0.0)) - 0.3) > 0.001 or absf(float(crate_goal.get("marker_yaw", 0.0)) - 90.0) > 0.001:
		found.append("crate rule")
	var crate := {"uid": "crate", "item": "lemon_crate", "model": "box_closed", "x": 4.2, "y": 0.0, "z": 3.35, "w": 0.52, "d": 0.38, "h": 0.36, "rot": 0.0, "tag": ""}
	var pad := {"uid": "pad", "item": "cushion", "model": "cafe_cushion", "x": 4.2, "y": 0.36, "z": 3.35, "w": 0.5, "d": 0.5, "h": 0.16, "rot": 0.0, "tag": ""}
	var nudged := pad.duplicate(true)
	nudged["z"] = 3.42
	if not bool(goals.evaluate(crate_goal, [crate, pad]).get("met", false)) or not bool(goals.evaluate(crate_goal, [crate, nudged]).get("met", false)):
		found.append("crate nudge")
	var cups := goals.by_id("shopl_cups_on_counter")
	if int(cups.get("count", 0)) != 3:
		found.append("cups count")
	var stand := {"uid": "stand", "item": "stand", "model": "lemonade_stand_counter", "x": 2.9, "y": 0.0, "z": 2.9, "w": 1.6, "d": 0.6, "h": 0.95, "rot": 0.0, "tag": ""}
	var cup_items: Array = [stand]
	for i in 2:
		cup_items.append({"uid": "cup%d" % i, "item": "paper_cup_stack", "model": "paper_cup_stack", "x": 2.7 + float(i) * 0.12, "y": 0.95, "z": 2.9, "w": 0.1, "d": 0.1, "h": 0.14, "rot": 0.0, "tag": ""})
	if bool(goals.evaluate(cups, cup_items).get("met", false)):
		found.append("cups two")
	cup_items.append({"uid": "cup2", "item": "paper_cup_stack", "model": "paper_cup_stack", "x": 2.94, "y": 0.95, "z": 2.9, "w": 0.1, "d": 0.1, "h": 0.14, "rot": 0.0, "tag": ""})
	if not bool(goals.evaluate(cups, cup_items).get("met", false)):
		found.append("cups three")
	var shop_mug := goals.by_id("shopc_mugs_on_shelf")
	if str(shop_mug.get("item", "")) != "mug_worlds_okayest":
		found.append("shop mug")
	var coffee := layouts.load_named("coffee_counter")
	var placed := {}
	for rec in layouts.records(coffee):
		placed[str(rec.get("uid", ""))] = rec
	if absf(float(placed["pastry_case"]["x"]) - 0.85) > 0.001 or absf(float(placed["counter_M"]["x"]) - 4.55) > 0.001 or absf(float(placed["counter_R"]["x"]) - 6.7) > 0.001:
		found.append("coffee counters")
	if absf(float(placed["register"]["y"]) - 0.95) > 0.001 or absf(float(placed["tip_jar"]["x"]) - 3.85) > 0.001 or absf(float(placed["tip_jar"]["z"]) - 2.55) > 0.001:
		found.append("coffee top")
	if absf(float(placed["cushion_a"]["z"]) - 5.4) > 0.001 or absf(float(placed["cat_tree"]["x"]) - 7.45) > 0.001 or absf(float(placed["biscuit"]["x"]) - 6.6) > 0.001:
		found.append("coffee floor")
	var stand_layout := layouts.load_named("lemonade_stand")
	var lemonade := {}
	for rec in layouts.records(stand_layout):
		lemonade[str(rec.get("uid", ""))] = rec
	if absf(float(lemonade["cups"]["x"]) - 2.45) > 0.001 or absf(float(lemonade["cups"]["z"]) - 2.72) > 0.001:
		found.append("cups spot")
	if absf(float(lemonade["price_sign"]["y"])) > 0.001 or absf(float(lemonade["price_sign"]["x"]) - 1.3) > 0.001 or absf(float(lemonade["price_sign"]["z"]) - 1.8) > 0.001:
		found.append("price sign")
	if absf(float(lemonade["lemon_crate"]["x"]) - 4.2) > 0.001 or absf(float(lemonade["fern"]["x"]) - 5.7) > 0.001 or absf(float(lemonade["awning"]["y"])) > 0.001:
		found.append("lemonade floor")
	var room = preload("res://scripts/diorama.gd").new()
	room.backdrop = true
	add_child(room)
	var closed := room.find_child("BoxClosed", true, false) as Node3D
	var box_mug := room.find_child("BoxMug", true, false) as Node3D
	var founder := room.find_child("FounderBox", true, false) as Node3D
	var sky := room.find_child("Skylight", true, false) as SpotLight3D
	if closed == null or box_mug == null or founder == null or sky == null:
		found.append("menu stack missing")
	else:
		if absf(box_mug.position.y - 0.36) > 0.02 or absf(box_mug.position.x - closed.position.x) > 0.02:
			found.append("mug stack %s" % box_mug.position)
		if founder.position.y > 0.02 or absf(founder.position.x - closed.position.x) < 0.4:
			found.append("founder box %s" % founder.position)
		if absf(sky.position.y - 2.55) > 0.001 or sky.light_energy < 1.1:
			found.append("skylight %s %s" % [sky.position, sky.light_energy])
	_bury(room)
	return found


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
	if RoomLib.mend_caption("Mug", 1) != "Mend Mug" or RoomLib.mend_caption("Mug", 3) != "Mend Mug ×3":
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
		var office_theme: Dictionary = Catalog.theme("garage")
		var ambient_want := float(office_theme.get("ambient_energy", 0.22)) * float(Catalog.day_phase_mults(GameState.day_phase()).get("ambient", 1.0))
		if office.ambient_light_color != Color(str(office_theme.get("ambient", ""))) or absf(office.ambient_light_energy - ambient_want) > 0.001:
			found.append("ambient")
		if not office.adjustment_enabled or absf(office.adjustment_contrast - 1.2) > 0.001 or absf(office.adjustment_saturation - 1.08) > 0.001:
			found.append("grade")
		if office.fog_enabled or office.sdfgi_enabled or not office.ssao_enabled or office.ssil_enabled or not office.glow_enabled:
			found.append("features")
		if absf(office.ssao_radius - 0.8) > 0.001 or absf(office.ssao_intensity - 1.5) > 0.001:
			found.append("ssao")
		if absf(office.glow_intensity - 0.4) > 0.001 or absf(office.glow_strength - 0.8) > 0.001 or office.glow_blend_mode != Environment.GLOW_BLEND_MODE_SOFTLIGHT:
			found.append("glow")
	# Ambient life: passers-by on the pavement, and a neighbour who wanders in.
	var street_count: int = (play.get("street") as Array).size()
	if street_count < 4:
		found.append("street walkers %d" % street_count)
	GameState.set_mode("office")
	GameState.office_phase = "live"
	if not (play.call("_browse_targets") as Array).is_empty():
		if not play.call("_spawn_browser") or (play.get("browser") as Dictionary).is_empty():
			found.append("browser did not spawn")
	# Place it all for me: a boxed starter piece lands somewhere valid.
	GameState.office_phase = "place"
	var lazy_rec: Dictionary = {}
	for rec in GameState.office_items:
		if str(rec.get("uid", "")) == "chair":
			lazy_rec = rec
	if not lazy_rec.is_empty():
		lazy_rec["state"] = "boxed"
		play.call("_refresh_items")
		play.call("_place_office_all")
		if str(lazy_rec.get("state", "")) != "placed":
			found.append("place it all for me left the chair %s" % lazy_rec.get("state", ""))
	GameState.office_phase = "live"
	# Every dish on the board has a prop of its own, and the loft has no ceiling beams.
	var kinds := {}
	for dish in Catalog.menu():
		var prop: Node3D = play.call("_order_prop", str(dish.get("id", "")))
		if prop == null or prop.get_child_count() == 0:
			found.append("no prop for %s" % dish.get("id", ""))
		else:
			kinds[str(play.get("DISH_PROPS").get(str(dish.get("id", "")), ""))] = true
			prop.free()
	if kinds.size() < 18:
		found.append("dish props share too much (%d kinds)" % kinds.size())
	# The jointed rig: legs that swing on a walk, a sit that lowers the hips, a player who walks to clicks.
	var rig: Node3D = Figure.build(UIKit.SAGE, Color("4A3626"), "kid")
	play.add_child(rig)
	for path in ["Figure/Hips/ThighL/ShinL", "Figure/Hips/ThighR/ShinR", "Figure/ArmL/ForeL", "Figure/ArmR/ForeR", "Figure/Torso", "Figure/Head", "Figure/Carry"]:
		if rig.get_node_or_null(path) == null:
			found.append("rig part %s" % path)
	if absf((rig.get_node("Figure") as Node3D).scale.x - 0.68) > 0.001:
		found.append("kid scale")
	rig.position = Vector3(1, 0, 1)
	Figure.animate(rig, 0.3, true, 0.1)
	for i in 12:
		rig.position += Vector3(0.1, 0, 0)
		Figure.animate(rig, 0.3 + float(i) * 0.1, true, 0.1)
	rig.position += Vector3(0.1, 0, 0)
	Figure.animate(rig, 0.17, true, 0.1)
	var thigh := rig.get_node("Figure/Hips/ThighL") as Node3D
	if absf(thigh.rotation.x) < 0.05:
		found.append("walk does not swing the legs")
	if absf(rig.rotation.y - PI * 0.5) > 0.4:
		found.append("walker does not face the way it moves (%s)" % rig.rotation.y)
	rig.set_meta("sit", true)
	for i in 40:
		Figure.animate(rig, float(i) * 0.05, false, 0.05)
	if (rig.get_node("Figure/Hips") as Node3D).position.y > 0.45:
		found.append("sit does not lower the hips")
	rig.free()
	if play.player == null or not is_instance_valid(play.player):
		found.append("no player on screen")
	else:
		var before_pos: Vector3 = play.player.position
		play.call("_player_go", Vector3(3.0, 0.0, 3.0))
		for i in 60:
			play.call("_tick_player", 0.05)
		if play.player.position.distance_to(Vector3(2.45, 0.0, 2.45)) > 0.1 or play.player.position.distance_to(before_pos) < 0.5:
			found.append("player did not walk to the click (%s)" % play.player.position)
	# Characters hold a short pose on request and drop it when it ends.
	var poser: Node3D = play.call("_make_person", UIKit.BLUE)
	play.add_child(poser)
	play.call("_act", poser, "wave", 5.0)
	play.call("_animate_person", poser, 1.0, false, 0.016)
	var arm_r := poser.get_node("Figure/ArmR") as Node3D
	if absf(arm_r.rotation.x + 2.7) > 0.01:
		found.append("wave pose %s" % arm_r.rotation.x)
	poser.set_meta("action_until", 0.0)
	play.call("_animate_person", poser, 1.0, false, 0.016)
	if str(poser.get_meta("action", "")) != "" or arm_r.rotation != Vector3.ZERO:
		found.append("pose not cleared")
	poser.free()
	# Every sound effect the scripts name has a file.
	var dir := DirAccess.open("res://scripts")
	var missing_sfx: Array = []
	if dir:
		for file in dir.get_files():
			if not file.ends_with(".gd"):
				continue
			var text := FileAccess.get_file_as_string("res://scripts/" + file)
			var rx := RegEx.create_from_string("play_sfx\\(\"([a-z0-9_]+)\"")
			for hit in rx.search_all(text):
				var sfx := hit.get_string(1)
				if not ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % sfx) and not missing_sfx.has(sfx):
					missing_sfx.append(sfx)
	if not missing_sfx.is_empty():
		found.append("missing sfx %s" % str(missing_sfx))
	# Every household item builds from data/props.json and has a room and a line.
	var rooms := {}
	for item_id in ItemDB.content_items.keys():
		var hdef: Dictionary = ItemDB.get_item(str(item_id))
		if str(hdef.get("room", "")) == "":
			continue
		rooms[str(hdef["room"])] = true
		var hprop := Props.make(str(hdef.get("model", "")))
		if hprop == null or hprop.get_child_count() < 2:
			found.append("household prop %s is a placeholder" % item_id)
		else:
			hprop.free()
		if str(hdef.get("flavor", "")) == "":
			found.append("household item %s without a line" % item_id)
	for room_name in ["kitchen", "bathroom", "bedroom", "living", "loft", "shed"]:
		if not rooms.has(room_name):
			found.append("no items for the %s" % room_name)
	# A piece too big for a box is wrapped and takes a place on the truck as itself.
	GameState.job = {"def": {"id": "wrap_test", "venue": "cafe"}, "items": [{"uid": "w0", "item_id": "sofa", "name": "Sofa", "state": "loose", "box": -1, "damage": 0, "nobox": true, "heavy": true, "x": 1, "y": 0, "z": 1}, {"uid": "w1", "item_id": "cafe_mug", "name": "Mug", "state": "loose", "box": -1, "damage": 0, "x": 2, "y": 0, "z": 1}], "boxes": [], "next_box": 0, "carried": []}
	var open_id := GameState.make_box()
	if GameState.pack_into("w0", open_id) == "":
		found.append("a sofa went in a box")
	if GameState.wrap_big("w0") != "" or GameState.job["boxes"].size() != 2 or str(GameState.job_box(1).get("big", "")) != "w0" or not bool(GameState.job_box(1).get("sealed", false)):
		found.append("wrap_big %s" % str(GameState.job["boxes"]))
	if GameState.wrap_big("w1") == "":
		found.append("a mug got wrapped")
	GameState.job = {}
	# Every pool item builds a prop and carries a line about itself.
	for pool_id in load("res://scripts/job_gen.gd").POOL.keys():
		var pool_def := ItemDB.get_item(str(pool_id))
		if pool_def.is_empty():
			found.append("pool item %s missing" % pool_id)
			continue
		var pool_prop := Props.make(str(pool_def.get("model", "")))
		if pool_prop == null or pool_prop.get_child_count() == 0:
			found.append("no prop for %s" % pool_id)
		else:
			pool_prop.free()
	if ItemDB.get_item("globe").get("flavor", "") == "" or ItemDB.get_item("easel").get("flavor", "") == "":
		found.append("new items without a line")
	# The truck stage: the place's front stands behind the truck, Dana carries each box to the bed.
	GameState.job = {"def": {"id": "truck_smoke", "venue": "cafe", "title": "Truck test"}, "items": [], "boxes": [{"id": 0, "sealed": true, "slot": -1}, {"id": 1, "sealed": true, "slot": -1}], "carried": []}
	GameState.mode = "truck"
	play.call("_build_venue")
	if play.find_child("Facade", true, false) == null or play.find_child("BoxPile", true, false) == null:
		found.append("truck stage facade missing")
	if play.player == null or not is_instance_valid(play.player):
		found.append("no player on the truck stage")
	play.selected_box = 0
	play.call("_truck_click", "slot:0")
	if int(GameState.job["boxes"][0].get("slot", -1)) != 0:
		found.append("truck click did not load the box")
	if not play.truck_pending or not play.player_moving:
		found.append("Dana did not set off with the box")
	for i in 120:
		play.call("_tick_player", 0.05)
	if play.truck_pending:
		found.append("the box never landed on the pad")
	GameState.mode = "office"
	GameState.job = {}
	play.call("_build_venue")
	# Packing: the boxes being filled stand by the back wall, and clicking one picks it.
	GameState.job = {"def": {"id": "pack_test", "venue": "cafe"}, "items": [], "boxes": [{"id": 0, "sealed": true}, {"id": 1, "sealed": false}], "carried": []}
	for b in 3:
		GameState.job["items"].append({"uid": "p%d" % b, "item_id": "cafe_mug", "name": "Mug %d" % b, "state": "boxed" if b < 2 else "loose", "box": 0 if b < 2 else -1, "damage": 0, "x": 0, "y": 0, "z": 0})
	GameState.mode = "job_pack"
	play.selected_box = -1
	play.call("_refresh_items")
	var pack_nodes := 0
	for child in play.items_root.get_children():
		if child.has_meta("uid") and str(child.get_meta("uid")).begins_with("boxpack:"):
			pack_nodes += 1
	if pack_nodes != 2:
		found.append("pack boxes shown %d" % pack_nodes)
	play.call("_pack_click", "boxpack:1")
	if int(play.selected_box) != 1:
		found.append("pack click did not pick the box")
	play.call("_pack_click", "boxpack:0")
	if int(play.selected_box) != 1:
		found.append("sealed box got picked")
	GameState.mode = "office"
	GameState.job = {}
	play.call("_refresh_items")
	# Haggling: a push moves the price, three pushes lose Sal, taking it pays.
	var Crime = load("res://scripts/crime.gd")
	var Workshop = load("res://scripts/workshop.gd")
	GameState.crime = Crime.fresh()
	Crime.unlock("fence_1")
	var hag_good := str(ItemDB.trade_goods()[0].get("id", ""))
	GameState.goods[hag_good] = 3
	var hag_offer: Dictionary = Crime.fence_offer(hag_good, 1)
	var start_price := int(hag_offer.get("offer", 0))
	if start_price <= 0:
		found.append("no offer")
	Crime.haggle_push(hag_offer)
	if int(hag_offer.get("offer", 0)) == start_price:
		found.append("push did not move the price")
	var walked_offer: Dictionary = Crime.fence_offer(hag_good, 1)
	for i in 3:
		Crime.haggle_push(walked_offer)
	if not bool(walked_offer.get("walked", false)) or not Crime.fence_accept(walked_offer).has("error"):
		found.append("third push should lose Sal")
	var hag_money := GameState.money
	var hag_taken: Dictionary = Crime.fence_accept(hag_offer)
	if hag_taken.has("error") or GameState.money != hag_money + int(hag_offer.get("offer", 0)):
		found.append("accept pay %s" % str(hag_taken))
	# Knock-offs can be caught: over many rolls both outcomes happen.
	GameState.crime["cred"] = 10
	Crime.unlock("knock_1")
	var ko_recipe := str(Workshop.recipes()[0].get("id", ""))
	var ko_caught := 0
	var ko_sold := 0
	for i in 40:
		var made: Dictionary = Workshop.state().get("made", {})
		made[ko_recipe] = [{"quality": 70}]
		Workshop.state()["made"] = made
		var ko: Dictionary = Crime.knockoff(ko_recipe)
		if bool(ko.get("caught", false)):
			ko_caught += 1
		elif not ko.has("error"):
			ko_sold += 1
	if ko_caught == 0 or ko_sold == 0:
		found.append("knock-off outcomes caught %d sold %d" % [ko_caught, ko_sold])
	# Lie low and a friend on the force.
	GameState.crime = Crime.fresh()
	GameState.crime["heat"] = 7
	GameState.crime["visits"] = 1
	GameState.crime["cred"] = 20
	GameState.money = 500
	Crime.unlock("cover_1")
	Crime.unlock("cover_2")
	if Crime.lie_low().has("error") or Crime.heat() != 3 or GameState.money != 470:
		found.append("lie low heat %d money %d" % [Crime.heat(), GameState.money])
	if not Crime.lie_low().has("error"):
		found.append("lie low twice a day")
	if Crime.bribe().has("error") or int(GameState.crime.get("visits", 0)) != 0 or GameState.money != 350:
		found.append("bribe visits %d money %d" % [int(GameState.crime.get("visits", 0)), GameState.money])
	# Patrol heat from a night drive; Sal's story mails arrive with cred.
	GameState.crime = Crime.fresh()
	GameState.crime["cred"] = 3
	var kept_mail: Array = []
	for mail in GameState.inbox:
		if not str(mail.get("id", "")).begins_with("sal_story"):
			kept_mail.append(mail)
	GameState.inbox = kept_mail
	Crime.story_check()
	var story_mails := 0
	for mail in GameState.inbox:
		if str(mail.get("id", "")).begins_with("sal_story"):
			story_mails += 1
	if story_mails != 1:
		found.append("story mails %d" % story_mails)
	Crime.on_drive({"spotted": 2})
	if Crime.heat() != 6:
		found.append("patrol heat %d" % Crime.heat())
	# Rent: nothing in the grace days, then every few days; unpaid rent shuts the shop.
	GameState.rent_owed = 0
	GameState.day = 4
	GameState.money = 10
	var rent_summary := {}
	GameState.call("_charge_rent", rent_summary)
	if GameState.rent_owed != 0:
		found.append("rent in the grace period")
	GameState.day = 5
	GameState.call("_charge_rent", rent_summary)
	if GameState.rent_owed != GameState.rent_amount() or int(rent_summary.get("rent", 0)) != GameState.rent_amount():
		found.append("rent not charged on day 5 (%d)" % GameState.rent_owed)
	GameState.office_items.append({"uid": "smoke_counter3", "item": "coffee_machine", "state": "placed", "x": 2, "y": 0.76, "z": 4, "rot": 0})
	if GameState.shop_accepting():
		found.append("shop open with rent owed")
	GameState.add_money(500, true)
	if GameState.rent_owed != 0 or not GameState.shop_accepting():
		found.append("rent not settled when money came in")
	GameState.day = 6
	GameState.call("_charge_rent", rent_summary)
	if GameState.rent_owed != 0:
		found.append("rent charged on the wrong day")
	if GameState.rent_due_in() != 4:
		found.append("rent due in %d" % GameState.rent_due_in())
	GameState.rent_owed = 0
	# The radio: stations cycle and stick; the engine note climbs with speed.
	GameState.job = {"def": {"id": "radio_smoke", "venue": "cafe", "drive": "rainy_afternoon"}, "items": [], "boxes": []}
	var radio_drive: Node = load("res://scripts/drive_course.gd").new()
	add_child(radio_drive)
	if (radio_drive.STATIONS as Array).size() < 6 or radio_drive.radio_button == null:
		found.append("radio stations")
	GameState.stats["radio"] = 0
	radio_drive.call("_radio_next")
	if int(GameState.stats.get("radio", 0)) != 1 or not str(radio_drive.radio_button.text).contains("Rainy Nights"):
		found.append("radio switch %s %s" % [GameState.stats.get("radio", -1), radio_drive.radio_button.text])
	if float(radio_drive.call("_engine_pitch", 0.0)) >= float(radio_drive.call("_engine_pitch", 150.0)):
		found.append("engine pitch")
	radio_drive.free()
	GameState.stats["radio"] = 0
	GameState.job = {}
	# A night drive: patrols with light bars, headlights, and a watching patrol spots a speeding truck.
	GameState.generated_drives["smoke_night"] = {"id": "smoke_night", "title": "Night run", "weather": "night", "pickup": "garage", "dropoff": "cafe", "hazards": [], "length_m": 200}
	GameState.job = {"def": {"id": "night_smoke", "venue": "cafe", "drive": "smoke_night"}, "items": [], "boxes": []}
	var night_drive: Node = load("res://scripts/drive_course.gd").new()
	add_child(night_drive)
	if (night_drive.patrols as Array).size() < 2:
		found.append("night patrols %d" % (night_drive.patrols as Array).size())
	if night_drive.truck.get_node_or_null("Headlight") == null:
		found.append("no headlights at night")
	if night_drive.spot_label == null:
		found.append("no patrol meter")
	if not (night_drive.patrols as Array).is_empty():
		var patrol: Dictionary = night_drive.patrols[0]
		patrol["heading"] = 0.0
		patrol["pos"] = night_drive.call("_art_center") - Vector2(120, 0)
		night_drive.speed = 999.0
		for i in 60:
			night_drive.call("_patrols", 0.05)
		if int(night_drive.spotted) < 1:
			found.append("patrol never spotted a speeding truck")
		night_drive.speed = 0.0
	# Collisions carry momentum: a truck driving into a parked car shoves it and loses speed.
	var bumped: Dictionary = night_drive.cars[0]
	bumped["mode"] = "drive"
	bumped["vel"] = Vector2.ZERO
	bumped["speed"] = 0.0
	night_drive.heading = 0.0
	bumped["pos"] = night_drive.call("_art_center") + Vector2(60, 0)
	night_drive.vel = Vector2(300, 0)
	night_drive.call("_collide_truck_car", bumped)
	if (bumped["vel"] as Vector2).x < 100.0 or str(bumped.get("mode", "")) != "knocked" or night_drive.vel.x >= 300.0:
		found.append("collision did not shove the car (car %s truck %s mode %s)" % [bumped["vel"], night_drive.vel, bumped.get("mode", "")])
	# Two spots start a pursuit; stopped with a patrol on the bumper, you get boxed in.
	var bust_box: Dictionary = {}
	night_drive.finished.connect(func(r): bust_box["r"] = r)
	var cop: Dictionary = night_drive.patrols[0]
	night_drive.call("_start_pursuit", cop)
	if (night_drive.call("_pursuers") as Array).size() != 1:
		found.append("pursuit did not start")
	night_drive.vel = Vector2.ZERO
	night_drive.speed = 0.0
	cop["pos"] = night_drive.call("_art_center") - Vector2(60, 0)
	cop["vel"] = Vector2.ZERO
	for i in 80:
		cop["pos"] = night_drive.call("_art_center") - Vector2(60, 0)
		night_drive.call("_cops", 0.05)
	if not bool(bust_box.get("r", {}).get("busted", false)) or not night_drive.busted:
		found.append("boxed in but not busted (%s)" % str(bust_box))
	night_drive.free()
	# Busted: the job is gone, there is a fine, a strike, and a Busted results card.
	GameState.job = {"def": {"id": "night_smoke", "title": "a night move", "shady": true, "venue": "cafe"}, "items": [], "boxes": []}
	GameState.money = 400
	GameState.crime = Crime.fresh()
	GameState.crime["heat"] = 8
	GameState.bust_job({"busted": true, "spotted": 2})
	if GameState.money != 320 or not GameState.job.is_empty() or not bool(GameState.payout.get("busted", false)) or GameState.mode != "results" or Crime.heat() != 0 or int(GameState.crime.get("visits", 0)) != 1:
		found.append("bust_job money %d mode %s heat %d visits %d" % [GameState.money, GameState.mode, Crime.heat(), int(GameState.crime.get("visits", 0))])
	GameState.payout = {}
	GameState.mode = "office"
	GameState.job = {}
	GameState.generated_drives.erase("smoke_night")
	# The drive wants the truck backed into the bay: nose-first is not parked.
	var course_node = load("res://scripts/drive_course.gd").new()
	course_node.dropoff = {"bay": Rect2(0, 0, 180, 60)}
	course_node.pos = Vector2(90, 30)
	course_node.speed = 0.0
	course_node.vel = Vector2.ZERO
	course_node._check_dropoff()
	if course_node.at_dropoff:
		found.append("nose-first counted as parked")
	course_node.speed = -20.0
	course_node._check_dropoff()
	course_node.speed = 0.0
	course_node._check_dropoff()
	if not course_node.backed_in or not course_node.at_dropoff:
		found.append("backing in did not park")
	course_node.pos = Vector2(600, 600)
	course_node._check_dropoff()
	if course_node.backed_in:
		found.append("backed_in stuck after leaving")
	course_node.free()
	# Unpacking: a piece leaving a box arcs into place instead of popping.
	GameState.job = {"def": {"id": "arc_test", "venue": "cafe"}, "items": [{"uid": "arc0", "item_id": "cafe_mug", "name": "Mug", "state": "boxed", "box": 0, "damage": 0, "x": 0, "y": 0, "z": 0}], "boxes": [{"id": 0, "sealed": true}], "carried": [0]}
	GameState.mode = "job_unpack"
	play.carried = {0: true}
	play.call("_loosen", GameState.job["items"][0], 0, 0)
	if not play.arrive_from.has("arc0"):
		found.append("no arrival noted for the loosened piece")
	play.call("_refresh_items")
	var arc_node: Node3D = play.nodes_by_uid.get("arc0")
	if arc_node == null or play.arrive_from.has("arc0"):
		found.append("arrival not consumed")
	elif arc_node.get_child_count() > 0 and (arc_node.get_child(0) as Node3D).position.length() < 0.05:
		found.append("piece did not start its arc")
	GameState.mode = "office"
	GameState.job = {}
	play.carried = {}
	# Box towers: carried boxes pile in threes, the top one opens, emptied ones leave the tower.
	GameState.job = {"def": {"id": "stack_test", "venue": "cafe"}, "items": [], "boxes": [], "carried": [0, 1, 2, 3]}
	for b in 4:
		GameState.job["boxes"].append({"id": b, "sealed": true})
		GameState.job["items"].append({"uid": "s%d" % b, "item_id": "cafe_mug", "name": "Mug %d" % b, "state": "boxed", "box": b, "damage": 0, "x": 0, "y": 0, "z": 0})
	play.carried = {0: true, 1: true, 2: true, 3: true}
	play.call("_stack_boxes")
	var tower_box3: Dictionary = GameState.job_box(3)
	var tower_box2: Dictionary = GameState.job_box(2)
	if int(tower_box2.get("tower", -1)) != 0 or int(tower_box2.get("level", -1)) != 2 or int(tower_box3.get("tower", -1)) != 1 or int(tower_box3.get("level", -1)) != 0:
		found.append("towers %s %s" % [str(tower_box2), str(tower_box3)])
	if int(play.call("_tower_top", 0)) != 2 or (play.call("_open_box_spot", 2) as Vector3).y < 0.8:
		found.append("tower top %d spot %s" % [int(play.call("_tower_top", 0)), str(play.call("_open_box_spot", 2))])
	# The HUD lists the unpack helper exactly once after stacking.
	GameState.mode = "job_unpack"
	play.call("_refresh_hud_buttons")
	var unpack_buttons := 0
	for layer_node in play.get_children():
		if layer_node is CanvasLayer:
			for child in layer_node.get_children():
				if child is Button and (child as Button).text == "Unpack it all for me":
					unpack_buttons += 1
	if unpack_buttons != 1:
		found.append("unpack helper listed %d times" % unpack_buttons)
	GameState.mode = "office"
	GameState.job["items"][0]["state"] = "placed"
	play.call("_normalize_towers")
	if GameState.job_box(0).has("tower") or int(GameState.job_box(1).get("level", -1)) != 0 or int(GameState.job_box(2).get("level", -1)) != 1:
		found.append("towers after emptying %s" % str(GameState.job["boxes"]))
	GameState.job = {}
	play.carried = {}
	# No two pieces of a generated job share a name, over a handful of boards.
	for seed_n in range(1, 7):
		for job_def in load("res://scripts/job_gen.gd").board(seed_n * 101, 2, 1, 3, 4).get("jobs", []):
			var seen := {}
			for piece in JobDB.build_job_items(job_def):
				var piece_name := str(piece.get("name", ""))
				if seen.has(piece_name):
					found.append("duplicate piece name %s in %s" % [piece_name, job_def.get("id", "")])
				seen[piece_name] = true
	# Every dish has a recipe of known ingredients, and the make card scores it.
	for dish in Catalog.menu():
		var recipe: Array = dish.get("recipe", [])
		if recipe.size() < 2:
			found.append("recipe short for %s" % dish.get("id", ""))
		for ing in recipe:
			if not Catalog.ingredients().has(str(ing)):
				found.append("unknown ingredient %s" % ing)
	var make1 := MakeCard.new()
	play.add_child(make1)
	var latte: Dictionary = Catalog.menu_item("latte")
	make1.setup(latte, "Nia", 7)
	var tray_ids: Array = MakeCard.tray_ids(make1)
	if tray_ids.size() != (latte.get("recipe", []) as Array).size() + 2:
		found.append("tray size %d" % tray_ids.size())
	var make_box: Dictionary = {}
	make1.finished.connect(func(r): make_box["r"] = r)
	make1._tap("foam")
	if make1.slips != 1:
		found.append("slip not counted")
	for ing in latte.get("recipe", []):
		make1._tap(str(ing))
	if make1.serve_button.disabled:
		found.append("serve stays disabled after the recipe")
	make1._serve()
	var make_result: Dictionary = make_box.get("r", {})
	if make_result.is_empty() or bool(make_result.get("perfect", false)) or absf(float(make_result.get("tip_mult", 0.0)) - 1.0) > 0.001:
		found.append("make result %s" % str(make_result))
	var card2 := MakeCard.new()
	play.add_child(card2)
	card2.setup(latte, "Nia", 8)
	var box2: Dictionary = {}
	card2.finished.connect(func(r): box2["r"] = r)
	for ing in latte.get("recipe", []):
		card2._tap(str(ing))
	card2._serve()
	var result2: Dictionary = box2.get("r", {})
	if not bool(result2.get("perfect", false)) or float(result2.get("tip_mult", 0.0)) < 1.2:
		found.append("perfect make %s" % str(result2))
	# Customer asks: a dozen in the data, and a yes pays more than a no.
	if Catalog.asks().size() < 10:
		found.append("asks %d" % Catalog.asks().size())
	GameState.office_items.append({"uid": "smoke_counter2", "item": "coffee_machine", "state": "placed", "x": 2, "y": 0.76, "z": 4, "rot": 0})
	GameState.money = 100
	var yes_sale: Dictionary = GameState.serve_visitor(true, {"dish": "drip", "who": {"name": "Nia"}, "tip_mult": 2.0})
	var no_sale: Dictionary = GameState.serve_visitor(true, {"dish": "drip", "who": {"name": "Nia"}, "tip_mult": 0.5})
	if int(yes_sale.get("tip", 0)) <= int(no_sale.get("tip", 0)):
		found.append("ask tip %d vs %d" % [int(yes_sale.get("tip", 0)), int(no_sale.get("tip", 0))])
	# Two alleys in town, and a honk bonus on the pay.
	var town = load("res://scripts/city.gd").load_default()
	if (town.alleys as Array).size() < 2 or not town.on_road((town.alleys[1] as Rect2).get_center()):
		found.append("second alley")
	GameState.job = {"def": {"id": "x", "venue": "cafe"}, "items": [], "boxes": []}
	GameState.apply_drive_result({"condition": 95, "alley": false, "honks": 3})
	if int(GameState.job.get("honks", 0)) != 3:
		found.append("honks not kept")
	GameState.job = {}
	# A parking lot with three bays, a car that takes one, and a pool of things to think.
	if play.call("_parking_lot") == null or (play.call("_parking_lot").get_meta("slots", []) as Array).size() != 3:
		found.append("parking lot")
	if str(play.call("_chat", "arriving")) == "" or str(play.call("_chat_browsing", "sit")) == "" or str(play.call("_chat", "passing")) == "":
		found.append("chatter pool")
	play.set("browser", {})
	if not play.call("_arrive_car", false) or (play.get("cars") as Array).size() != 1 or int(play.call("_free_slot")) != 1:
		found.append("car did not arrive (%d cars)" % (play.get("cars") as Array).size())
	var play_cam: Camera3D = play.get("cam")
	var garage_center := Vector3(3.0, 0.9, 4.0)
	if play_cam == null or play_cam.position.distance_to(Vector3(11.6, 9.9, 12.4)) > 0.02 or absf(play_cam.size - maxf(6.0, 8.0) * 1.12) > 0.001:
		found.append("garage cam %s" % (play_cam.position if play_cam else "missing"))
	elif (-play_cam.global_transform.basis.z).dot((garage_center - play_cam.global_position).normalized()) < 0.999:
		found.append("garage look")
	var garage_theme: Dictionary = Catalog.theme("garage")
	var phase_mults: Dictionary = Catalog.day_phase_mults(GameState.day_phase())
	var want_sun := Color(str(garage_theme.get("sun", ""))).lerp(Color(str(phase_mults.get("sun_tint", "FFE3C0"))), 0.5)
	var want_energy := float(garage_theme.get("sun_energy", 0.6)) * float(phase_mults.get("sun", 1.0))
	var sun := play.find_child("Sun", true, false) as DirectionalLight3D
	if sun == null or not sun.light_color.is_equal_approx(want_sun) or absf(sun.light_energy - want_energy) > 0.001 or sun.rotation_degrees.distance_to(Vector3(-50, 35, 0)) > 0.1 or not sun.shadow_enabled or absf(sun.light_angular_distance - 1.75) > 0.001:
		found.append("sun")
	var fill := play.find_child("Fill", true, false) as DirectionalLight3D
	if fill == null or fill.light_color != Color(str(garage_theme.get("fill", ""))) or absf(fill.light_energy - float(garage_theme.get("fill_energy", 0.16))) > 0.001 or fill.shadow_enabled:
		found.append("fill")
	var room_key := play.find_child("RoomKey", true, false) as SpotLight3D
	var room_mood := play.find_child("RoomMood", true, false) as OmniLight3D
	if room_key == null or room_mood == null or room_key.light_color != Color(str(garage_theme.get("key", ""))) or not room_key.shadow_enabled:
		found.append("room lights")
	for venue_id in ItemDB.venues().keys():
		var venue_theme: Dictionary = Catalog.theme(str(venue_id))
		if str(venue_theme.get("wall", "")) == "" or str(venue_theme.get("key", "")) == "":
			found.append("theme for %s" % venue_id)
	if str(Catalog.theme("cafe").get("wall", "")) == str(Catalog.theme("train").get("wall", "")):
		found.append("themes all the same")
	if float(Catalog.day_phase_mults("evening").get("sun", 1.0)) >= float(Catalog.day_phase_mults("morning").get("sun", 1.0)):
		found.append("evening not dimmer")
	var door := play.find_child("DoorGlow", true, false) as OmniLight3D
	if door == null or door.light_color != Color("FFC98A") or absf(door.light_energy - 0.9) > 0.001:
		found.append("door glow")
	var lamp_light := play.find_child("LampLight", true, false) as OmniLight3D
	if lamp_light == null or lamp_light.light_color != Color("FFD9A0") or absf(lamp_light.light_energy - 0.8 * float(phase_mults.get("lamps", 1.0))) > 0.001 or absf(lamp_light.omni_range - 2.5) > 0.001 or lamp_light.shadow_enabled:
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
	_bury(drive)
	# The pond: hazards sit along the computed route, so read their spots from the drive.
	GameState.job = {"def": {"drive": "duck_pond", "level": "L5"}, "boxes": [], "items": []}
	var pond_drive: Node = load("res://scripts/drive_course.gd").new()
	add_child(pond_drive)
	var spots := {}
	for hazard in pond_drive.get("hazards"):
		var kind := str(hazard.get("type", ""))
		if not spots.has(kind):
			spots[kind] = Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
	if not spots.has("gravel") or not spots.has("ducks") or not spots.has("bump"):
		found.append("l5 hazards %s" % spots.keys())
	for kind in spots.keys():
		if not bool(pond_drive.call("_on_road", spots[kind])):
			found.append("l5 %s off the road at %s" % [kind, spots[kind]])
	pond_drive.set("state", "drive")
	pond_drive.set("condition", 100)
	pond_drive.set("speed", 120.0)
	pond_drive.set("heading", 0.0)
	(pond_drive.get("touching") as Dictionary).clear()
	(pond_drive.get("contact_ready") as Dictionary).clear()
	pond_drive.set("pos", spots.get("gravel", Vector2.ZERO))
	pond_drive.call("_hazards")
	pond_drive.call("_hazards")
	if int(pond_drive.get("condition")) != 100:
		found.append("l5 gravel %s" % pond_drive.get("condition"))
	pond_drive.set("pos", spots.get("ducks", Vector2.ZERO))
	pond_drive.call("_hazards")
	pond_drive.call("_hazards")
	if int(pond_drive.get("condition")) != 100:
		found.append("l5 ducks %s" % pond_drive.get("condition"))
	(pond_drive.get("touching") as Dictionary).clear()
	(pond_drive.get("contact_ready") as Dictionary).clear()
	pond_drive.set("speed", 10.0)
	pond_drive.set("pos", spots.get("bump", Vector2.ZERO))
	pond_drive.call("_hazards")
	if int(pond_drive.get("condition")) != 97:
		found.append("l5 bump %s" % pond_drive.get("condition"))
	_bury(pond_drive)
	GameState.job = {}
	return found


func _menu_audit() -> Array:
	var found: Array = []
	var allow_quit := UIKit.quit_enabled
	UIKit.quit_enabled = false
	var saved_mode := str(GameState.mode)
	# 1280x800 is the small window. 1920x1080 is the project base.
	# Deck 1280x800 under canvas_items/expand grows the canvas to 1920x1200.
	var sizes: Array = [
		["1280x800", Vector2i(1280, 800)],
		["1920x1080", Vector2i(1920, 1080)],
		["deck", Vector2i(1920, 1200)],
	]
	var screens: Array = ["home", "settings", "remap", "intro", "pause", "level", "results", "market", "map", "hud", "drive"]
	for screen in screens:
		for spec in sizes:
			var view: Dictionary = _audit_open(str(screen), str(spec[0]), spec[1])
			get_tree().paused = false
			await get_tree().process_frame
			await get_tree().process_frame
			found.append_array(_audit_check(view))
			_audit_click(view)
			get_tree().paused = false
			await get_tree().process_frame
			var vp: Node = view.get("vp")
			if is_instance_valid(vp):
				_bury(vp)
	get_tree().paused = false
	UIKit.quit_enabled = allow_quit
	GameState.set_mode(saved_mode)
	return found


func _audit_open(screen: String, tag: String, size: Vector2i) -> Dictionary:
	var vp := SubViewport.new()
	vp.name = "Audit%s%s" % [screen, tag.replace("x", "")]
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = screen != "pause"
	add_child(vp)
	var view_size := Vector2(size)
	var root: Node = null
	var center_name := ""
	var center_x_only := false
	if screen == "home" or screen == "settings" or screen == "remap" or screen == "intro":
		var menu: Control = load("res://scripts/menu_ui.gd").new()
		vp.add_child(menu)
		menu.layout_mode = 0
		menu.position = Vector2.ZERO
		menu.size = view_size
		if screen == "home":
			menu.call("_home")
			center_name = "HomeCard"
		elif screen == "settings":
			menu.call("_settings")
			center_name = "SettingsCard"
		elif screen == "remap":
			menu.call("_controls")
			center_name = "RemapCard"
		else:
			menu.call("_intro", "dana")
			center_name = "Intro"
		root = menu
	elif screen == "pause":
		GameState.set_mode("menu")
		var shell = load("res://scripts/app.gd").new()
		vp.add_child(shell)
		shell.call("_pause")
		get_tree().paused = false
		root = shell
		center_name = "PauseColumn"
	elif screen == "level":
		var host := Node.new()
		vp.add_child(host)
		UIKit.show_level_beat(host, {"level_name": "Garage Startup", "arrival": "The roller door sticks.", "moment": "Dana sets the kettle on."})
		root = host
		center_name = "LevelBeat"
		center_x_only = true
	elif screen == "results":
		GameState.payout = {
			"base": 120, "box_tip": 60, "shortcut": 12, "bonuses": 0, "split_loss": 0,
			"cut": 0, "net_tips": 60, "total": 192, "title": "Job done", "stars": 1, "stamp": "",
		}
		var results: Control = load("res://scripts/results_ui.gd").new()
		vp.add_child(results)
		results.call("_center_card")
		root = results
		center_name = "Card"
	elif screen == "market":
		GameState.buyer_offer = {"name": "Nia", "item": "plant_fern", "price": 22, "line": "I'll take the fern."}
		var computer: Control = load("res://scripts/computer_ui.gd").new()
		vp.add_child(computer)
		computer.layout_mode = 0
		computer.position = Vector2.ZERO
		computer.size = view_size
		computer.call("_build")
		root = computer
		center_name = "Bezel"
	elif screen == "map":
		GameState.set_mode("office")
		GameState.office_phase = "live"
		var map: Control = load("res://scripts/map_ui.gd").new()
		vp.add_child(map)
		map.layout_mode = 0
		map.position = Vector2.ZERO
		map.size = view_size
		root = map
		center_name = "MapCard"
	elif screen == "hud":
		GameState.set_mode("office")
		GameState.office_phase = "live"
		var room = load("res://scripts/diorama.gd").new()
		room.hud_only = true
		vp.add_child(room)
		root = room
		center_name = "HintBar"
		center_x_only = true
	else:
		var drive = load("res://scripts/drive_course.gd").new()
		drive.preview = true
		vp.add_child(drive)
		root = drive
		center_name = "DriveHint"
		center_x_only = true
	return {
		"vp": vp,
		"root": root,
		"tag": "%s %s" % [screen, tag],
		"center": center_name,
		"center_x": center_x_only,
		"size": view_size,
	}


func _audit_check(view: Dictionary) -> Array:
	var found: Array = []
	var root: Node = view.get("root")
	var tag := str(view.get("tag", ""))
	if root == null or not is_instance_valid(root):
		found.append("%s missing" % tag)
		return found
	var vp := root.get_viewport()
	var view_rect := vp.get_visible_rect()
	if view_rect.size.x < 8.0:
		view_rect = Rect2(Vector2.ZERO, view.get("size"))
	var controls: Array = []
	if root is Control:
		controls.append(root)
	controls.append_array(root.find_children("*", "Control", true, false))
	for node in controls:
		var control := node as Control
		if control == null or not control.visible or control.is_queued_for_deletion():
			continue
		if control.get_global_rect().size.x < 1.0 and control.get_global_rect().size.y < 1.0:
			continue
		var rect := control.get_global_rect()
		if rect.position.x < view_rect.position.x - 1.0 or rect.position.y < view_rect.position.y - 1.0 or rect.end.x > view_rect.end.x + 1.0 or rect.end.y > view_rect.end.y + 1.0:
			found.append("%s off %s %s view %s" % [tag, control.name, rect, view_rect])
		if control is Label:
			var label := control as Label
			if label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				found.append("%s label blocks %s" % [tag, label.text])
			var px := int(label.get_theme_font_size("font_size"))
			# Secondary text (key chips, chat lines, card footers) may sit at the Deck floor of 27px.
			var small := bool(label.get_meta("small_text", false))
			if px < (UIKit.SMALL_FONT if small else 28):
				found.append("%s tiny %s %d" % [tag, label.text, px])
			if label.get_theme_font("font") == UIKit.body_font() and px < 36 and not small:
				found.append("%s body %s %d" % [tag, label.text, px])
			if label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_line_count() > 1 and label.text != "":
				found.append("%s wrapped title %s" % [tag, label.text])
	var buttons: Array = root.find_children("*", "Button", true, false)
	var enabled := false
	for node in buttons:
		var btn := node as Button
		if not btn.visible or btn.is_queued_for_deletion():
			continue
		var rect := btn.get_global_rect()
		if rect.size.x < 48.0 or rect.size.y < 48.0:
			found.append("%s hit %s %s" % [tag, btn.text, rect.size])
		if btn.focus_mode != Control.FOCUS_ALL:
			found.append("%s focus mode %s" % [tag, btn.text])
		if btn.get_theme_stylebox("hover") == null or btn.get_theme_stylebox("focus") == null:
			found.append("%s focus style %s" % [tag, btn.text])
		for neighbor_name in ["focus_neighbor_top", "focus_neighbor_bottom", "focus_neighbor_left", "focus_neighbor_right"]:
			var path: NodePath = btn.get(neighbor_name)
			if path.is_empty() or btn.get_node_or_null(path) == null:
				found.append("%s neighbor %s %s path %s" % [tag, btn.text, neighbor_name, path])
		var spot := _audit_hit(root, rect.get_center())
		if spot != btn and not _audit_under(btn, spot) and (spot == null or spot is Label):
			found.append("%s blocked %s by %s" % [tag, btn.text, spot.name if spot else "nothing"])
		if not btn.disabled:
			enabled = true
	if enabled:
		var owner := vp.gui_get_focus_owner()
		if owner == null or not root.is_ancestor_of(owner):
			found.append("%s unfocused" % tag)
	var center := root.find_child(str(view.get("center", "")), true, false) as Control
	if center == null:
		var names: PackedStringArray = PackedStringArray()
		for child in root.get_children():
			names.append(str(child.name))
		found.append("%s center missing %s [%s]" % [tag, view.get("center"), ", ".join(names)])
	else:
		var delta := center.get_global_rect().get_center() - view_rect.get_center()
		var limit := 8.0 if bool(view.get("center_x")) else 12.0
		if bool(view.get("center_x")):
			if absf(delta.x) > limit:
				found.append("%s center x %s" % [tag, delta])
		elif delta.length() > limit:
			found.append("%s center %s" % [tag, delta])
	return found


func _audit_hit(node: Node, point: Vector2) -> Control:
	var kids: Array = node.get_children()
	for i in range(kids.size() - 1, -1, -1):
		var kid: Node = kids[i]
		var found := _audit_hit(kid, point)
		if found != null:
			return found
	if node is Control:
		var control := node as Control
		if control.visible and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(point):
			return control
	return null


func _audit_under(button: Node, spot: Control) -> bool:
	var node: Node = spot
	while node != null:
		if node == button:
			return true
		node = node.get_parent()
	return false


func _audit_click(view: Dictionary) -> void:
	var root: Node = view.get("root")
	if root == null or not is_instance_valid(root):
		return
	var buttons: Array = []
	for node in root.find_children("*", "Button", true, false):
		buttons.append(node)
	for node in buttons:
		if not is_instance_valid(node):
			continue
		var btn := node as Button
		if btn.disabled or not btn.visible:
			continue
		btn.pressed.emit()


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


func _home_checks() -> Array:
	# Houses: blueprints that tile, walls with doorways, floors to switch,
	# the client's things in the rooms, pieces scored by room, pocketing.
	var found: Array = []
	var Homes = load("res://scripts/homes.gd")
	var homes: Dictionary = Homes.all()
	if homes.size() < 15:
		found.append("only %d homes" % homes.size())
	var storeys := 0
	var kinds: Dictionary = {}
	for home_id in homes.keys():
		var venue: Dictionary = Homes.venue_for(str(home_id))
		if not ItemDB.venues().has(home_id) or not bool(ItemDB.venues()[home_id].get("home", false)):
			found.append("%s not a venue" % home_id)
		var floors: Array = Homes.floors(venue)
		if floors.size() > 1:
			storeys += 1
		for index in floors.size():
			var area := 0.0
			for room in Homes.rooms(venue, index):
				area += float(room["w"]) * float(room["d"])
				kinds[Homes.kind(str(room["id"]))] = true
			if absf(area - float(venue["w"]) * float(venue["d"])) > 0.01:
				found.append("%s floor %d does not tile (%.1f)" % [home_id, index, area])
			if Homes.rooms(venue, index).size() > 1 and Homes.walls(venue, index).is_empty():
				found.append("%s floor %d has no walls" % [home_id, index])
			if Homes.stairs(venue, index) != Vector3.INF and floors.size() == 1:
				found.append("%s has stairs on one floor" % home_id)
		if Catalog.theme(str(venue.get("theme", ""))).get("name", "") == "Plain":
			found.append("%s has no theme" % home_id)
	if storeys < 8:
		found.append("only %d homes with an upstairs" % storeys)
	for want in ["kitchen", "bathroom", "bedroom", "lounge", "loft", "shed"]:
		if not kinds.has(want):
			found.append("no %s in any home" % want)
	# Walls and doorways on the semi: the lounge/hall wall has a gap in the middle.
	var semi: Dictionary = Homes.venue_for("semi_a")
	if Homes.doorways(semi, 0).size() < Homes.rooms(semi, 0).size():
		found.append("semi: fewer doorways than rooms")
	if not Homes.crosses_wall(semi, 0, Rect2(2.6, 0.8, 0.4, 0.4)):
		found.append("semi: a piece on the lounge wall is allowed")
	if Homes.crosses_wall(semi, 0, Rect2(2.6, 2.3, 0.4, 0.4)):
		found.append("semi: the doorway counts as wall")
	if Homes.crosses_wall(semi, 0, Rect2(1.2, 1.2, 0.4, 0.4)):
		found.append("semi: the middle of the lounge counts as wall")
	if Homes.room_at(semi, 0, 1.0, 6.0).get("id", "") != "kitchen" or Homes.room_at(semi, 1, 1.0, 1.0).get("id", "") != "bedroom":
		found.append("semi: room_at wrong")
	if Homes.floor_for_tag(semi, "bedroom") != 1 or Homes.floor_for_tag(semi, "kitchen") != 0:
		found.append("semi: floor_for_tag wrong")
	# A household job on the semi.
	GameState.new_game("dana")
	GameState.tutorial_done = true
	var JobGen = load("res://scripts/job_gen.gd")
	var home_job: Dictionary = {}
	var seed := 1
	while home_job.is_empty() and seed < 40:
		var made: Dictionary = JobGen.board(seed, 1, 1, 2, 3)
		for job in made["jobs"]:
			if bool(job.get("home", false)):
				home_job = job
				GameState.generated_drives = made["drives"]
				break
		seed += 1
	if home_job.is_empty():
		found.append("no home job in 40 boards")
		return found
	var tagged := 0
	for group in home_job.get("recipe", []):
		if str(ItemDB.get_item(str(group.get("item", ""))).get("room", "")) != "":
			tagged += 1
	if tagged < 4:
		found.append("home job carries %d household pieces" % tagged)
	home_job["venue"] = "semi_a"
	GameState.generated_jobs = [home_job]
	GameState.start_job(str(home_job["id"]))
	var owners: Array = GameState.job.get("owner_items", [])
	if owners.size() < 6:
		found.append("semi: only %d owner items" % owners.size())
	for rec in owners:
		var room: Dictionary = Homes.room_at(semi, int(rec["floor"]), float(rec["x"]), float(rec["z"]))
		if str(room.get("id", "")) != str(rec.get("room", "")):
			found.append("owner %s stands in %s not %s" % [rec.get("item_id", ""), room.get("id", "?"), rec.get("room", "")])
		var def := ItemDB.get_item(str(rec.get("item_id", "")))
		if Homes.crosses_wall(semi, int(rec["floor"]), Homes.footprint(Vector3(float(rec["x"]), 0, float(rec["z"])), float(rec["rot"]), float(def.get("w", 0.4)), float(def.get("d", 0.4)))):
			found.append("owner %s stands in a wall" % rec.get("item_id", ""))
	for box in GameState.job.get("boxes", []):
		box["sealed"] = true
	GameState.set_mode("job_unpack")
	var play: Node = RoomLib.new()
	add_child(play)
	var interior: Node = play.get_node_or_null("Interior")
	if interior == null:
		found.append("semi: no interior")
		_bury(play)
		return found
	if interior.find_children("InnerWall_*", "", false, false).size() < 3:
		found.append("semi: too few inner walls")
	if interior.find_children("RoomName_*", "", false, false).size() != Homes.rooms(semi, 0).size():
		found.append("semi: room names")
	if interior.get_node_or_null("Stairs") == null:
		found.append("semi: no stairs downstairs")
	if play.find_children("Owner_*", "", true, false).size() != play.call("_owner_items_here").size():
		found.append("semi: owner items not spawned")
	play.call("_refresh_hud_buttons")
	play.call("_refresh_hud_buttons")
	var rotate_buttons := 0
	for btn in play.find_children("*", "Button", true, false):
		if str(btn.text) == "Rotate view":
			rotate_buttons += 1
	if rotate_buttons != 1:
		found.append("HUD refresh leaves stale buttons (%d Rotate view)" % rotate_buttons)
	var up_button := false
	for btn in play.find_children("*", "Button", true, false):
		if str(btn.text).begins_with("Up to"):
			up_button = true
	if not up_button:
		found.append("semi: no Up button")
	# Placement respects the walls; a piece held through the stairs lands upstairs.
	var first: Dictionary = GameState.job["items"][0]
	first["state"] = "loose"
	first["x"] = 1.4
	first["z"] = 1.5
	first["floor"] = 0
	first["mount"] = "floor"
	first["item_id"] = "toaster"
	first["room"] = "kitchen"
	play.held_uid = str(first["uid"])
	play.held_source = "job"
	play.held_rot = 0.0
	if bool(play.call("_snap_point", Vector3(2.8, 0, 1.0))["valid"]):
		found.append("semi: a piece can stand in the lounge wall")
	if not bool(play.call("_snap_point", Vector3(1.4, 0, 1.6))["valid"]):
		found.append("semi: the lounge floor refuses a toaster")
	play.held_uid = ""
	play.held_source = ""
	play.call("_set_floor", 1)
	if play.home_floor != 1 or int(play.get_node("Interior").get_meta("floor", 0)) != 1:
		found.append("semi: did not go upstairs")
	if play.get_node("Interior").get_node_or_null("Stairs") == null:
		found.append("semi: no stairwell upstairs")
	if not play.find_children("*", "", true, false).any(func(n): return str(n.name).begins_with("Owner_")):
		found.append("semi: no owner items upstairs")
	for n in play.items_root.get_children():
		if str(n.get_meta("uid", "")).begins_with("boxcarry:"):
			found.append("semi: carry boxes upstairs")
			break
	play.call("_use_stairs")
	if play.home_floor != 0:
		found.append("semi: the stairs did not come back down")
	# Rooms tally: a kitchen piece in the kitchen counts, one in the lounge does not.
	for item in GameState.job["items"]:
		item["state"] = "placed"
		item["room"] = ""
	first["room"] = "kitchen"
	first["x"] = 2.0
	first["z"] = 6.5
	first["floor"] = 0
	var second: Dictionary = GameState.job["items"][1]
	second["room"] = "kitchen"
	second["x"] = 1.4
	second["z"] = 1.5
	second["floor"] = 0
	play.call("_tally_rooms")
	if int(GameState.job.get("rooms_right", -1)) != 1 or int(GameState.job.get("rooms_total", -1)) != 2:
		found.append("semi: rooms tally %s/%s" % [GameState.job.get("rooms_right"), GameState.job.get("rooms_total")])
	# Pocketing: a small piece goes in the bag with heat; a bathtub does not.
	var small := ""
	var big := ""
	for rec in owners:
		if bool(rec.get("pocketable", false)) and small == "":
			small = str(rec["uid"])
		if not bool(rec.get("pocketable", true)) and big == "":
			big = str(rec["uid"])
	var Crime = load("res://scripts/crime.gd")
	var heat_before: int = Crime.heat()
	if small == "" or big == "":
		found.append("semi: owner items all one size (small %s big %s)" % [small, big])
	else:
		if not GameState.pocket_owner_item(big).has("error"):
			found.append("pocketed a %s" % big)
		var took: Dictionary = GameState.pocket_owner_item(small)
		if took.has("error") or Crime.loot().size() != 1 or Crime.heat() <= heat_before:
			found.append("pocketing failed %s loot %d" % [took, Crime.loot().size()])
		if GameState.pocket_owner_item(small).get("error", "") == "":
			found.append("pocketed the same thing twice")
		play.call("_refresh_items")
		if play.find_children("Owner_" + small.replace(":", "_"), "", true, false).size() > 0:
			found.append("pocketed piece still standing")
		play.call("_open_owner_card", owners[owners.size() - 1]["uid"])
		if play.call("_hud_layer").get_node_or_null("OwnerCard") == null:
			found.append("no owner card")
	if not Crime.sell_loot().has("error"):
		found.append("sold loot without a fence")
	GameState.crime["unlocked"]["fence_1"] = true
	var jar := GameState.money
	var sale: Dictionary = Crime.sell_loot()
	if sale.has("error") or GameState.money <= jar or not Crime.loot().is_empty():
		found.append("loot sale %s" % sale)
	# Results: the room bonus, and being seen costs a cut and a star.
	GameState.job["rooms_right"] = 3
	GameState.job["rooms_total"] = 4
	GameState.job["caught_pocketing"] = true
	GameState.job["condition"] = 95
	var pay: Dictionary = GameState.finish_job()
	if int(pay.get("room_pay", 0)) != 9 or int(pay.get("caught_cut", 0)) <= 0 or int(pay.get("rooms_right", 0)) != 3:
		found.append("home payout %s" % pay)
	# Buttons swapped out by the floor change are freed at the end of the frame.
	await get_tree().process_frame
	await get_tree().process_frame
	_bury(play)
	GameState.job = {}
	GameState.mode = "office"
	return found


func _party_checks() -> Array:
	# The people being moved: every mood has every line, the family stands
	# by the door, and it answers a scuff, a wrong room and a click.
	var found: Array = []
	var Party = load("res://scripts/client_party.gd")
	var pools: Dictionary = Party.load_data()
	var events := ["greet", "idle", "placed", "placed_good", "wrong_room", "scuff", "tipped", "stacked", "cat", "caught", "talk", "slow", "finish_good", "finish_ok", "finish_bad"]
	for mood in Party.MOODS:
		for event in events:
			if (((pools.get("moods", {}) as Dictionary).get(mood, {}) as Dictionary).get(event, []) as Array).is_empty():
				found.append("no %s lines for a %s client" % [event, mood])
	for event in events:
		if ((pools.get("kid", {}) as Dictionary).get(event, []) as Array).is_empty():
			found.append("no %s lines for a kid" % event)
	var filled: String = Party.line("fussy", "wrong_room", 0, {"item": "toaster", "room": "bathroom"})
	if "{" in filled or not ("toaster" in filled or "bathroom" in filled):
		found.append("line fill: %s" % filled)
	for client in load("res://scripts/job_gen.gd").clients():
		if (client.get("party", []) as Array).is_empty() or not (str(client.get("mood", "")) in Party.MOODS):
			found.append("client %s has no party or mood" % client.get("name", "?"))
	GameState.new_game("dana")
	GameState.tutorial_done = true
	var JobGen = load("res://scripts/job_gen.gd")
	var made: Dictionary = JobGen.board(3, 1, 1, 2, 3)
	var job: Dictionary = {}
	for candidate in made["jobs"]:
		if (candidate.get("party", []) as Array).size() >= 2:
			job = candidate
	if job.is_empty():
		job = made["jobs"][0]
	GameState.generated_jobs = [job]
	GameState.generated_drives = made["drives"]
	GameState.start_job(str(job["id"]))
	for box in GameState.job.get("boxes", []):
		box["sealed"] = true
	GameState.set_mode("job_unpack")
	var play: Node = RoomLib.new()
	add_child(play)
	var party: Node = play.party
	if party == null:
		found.append("no party on site")
		_bury(play)
		return found
	if party.members.size() != (job.get("party", []) as Array).size():
		found.append("party of %d, wanted %d" % [party.members.size(), (job.get("party", []) as Array).size()])
	if party.member_for("client:0") == null:
		found.append("party members not clickable")
	var said: String = party.react("wrong_room", {"item": "toaster", "room": "bathroom"}, true)
	if said == "":
		found.append("the family said nothing about the toaster")
	var bubbles := 0
	for person in party.members:
		if person.get_node_or_null("Thought") != null:
			bubbles += 1
	if bubbles == 0:
		found.append("no thought bubble over the family")
	if party.react("placed", {}, true) == "":
		found.append("nothing to say about a placed piece")
	party.cooldown = 0.0
	if party.react("talk", {}, true) == "":
		found.append("a click gets no answer")
	var verdict: String = Party.finish_line(GameState.job["def"], 95, 4, 4)
	if verdict == "":
		found.append("finish line: %s" % verdict)
	# Twenty stories: a household, a house, a reason, three beats and an ending each.
	var stories: Array = JobGen.stories()
	if stories.size() < 20:
		found.append("only %d stories" % stories.size())
	var homes_seen: Dictionary = {}
	for tale in stories:
		if (tale.get("beats", []) as Array).size() != 3 or str(tale.get("ending", "")) == "" or str(tale.get("why", "")) == "":
			found.append("story %s is short" % tale.get("id", "?"))
		if not ItemDB.venues().has(str(tale.get("venue", ""))):
			found.append("story %s has no house" % tale.get("id", "?"))
		if (tale.get("party", []) as Array).is_empty() or not (str(tale.get("mood", "")) in Party.MOODS):
			found.append("story %s has no people" % tale.get("id", "?"))
		homes_seen[str(tale.get("venue", ""))] = true
	if homes_seen.size() < 15:
		found.append("stories cover only %d houses" % homes_seen.size())
	var storied := 0
	for client in JobGen.clients():
		if str(client.get("story", "")) != "":
			storied += 1
	if storied != stories.size():
		found.append("board clients carry %d stories" % storied)
	# A story job: the brief says why, the party tells it in beats, the results close it.
	var tale_job: Dictionary = {}
	var seed2 := 1
	while tale_job.is_empty() and seed2 < 60:
		for candidate in JobGen.board(seed2, 2, 1, 2, 3)["jobs"]:
			if str(candidate.get("story", "")) != "":
				tale_job = candidate
				break
		seed2 += 1
	if tale_job.is_empty():
		found.append("no story job in 60 boards")
	else:
		if not (str(tale_job.get("why", "")) in str(tale_job.get("brief", ""))):
			found.append("story brief lacks the why")
		GameState.job = {"def": tale_job, "items": [], "boxes": []}
		var teller: Node = Party.new()
		add_child(teller)
		teller.setup(null, tale_job, Vector3.ZERO, Vector3(0, 0, 1))
		var first: String = teller.tell()
		teller.on_progress(1, 2)
		teller.on_progress(2, 2)
		if first == "" or teller.beat != 3:
			found.append("story beats: first '%s', told %d" % [first, teller.beat])
		if Party.finish_line(tale_job, 90, 1, 1) != str(JobGen.story(str(tale_job["story"])).get("ending", "")):
			found.append("story ending not on the results")
		_bury(teller)
	await get_tree().process_frame
	_bury(play)
	GameState.job = {}
	GameState.mode = "office"
	return found


func _review_fixes() -> Array:
	var found: Array = []
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
	# The save file never holds an item in hand, and the live game keeps holding it.
	mug_rec["state"] = "hand"
	mug_rec["x"] = 2.05
	SaveManager.save_game()
	if str(GameState.find_office_item("mug").get("state", "")) != "hand":
		found.append("save snatched the mug out of hand")
	if str(_saved_office_item("mug").get("state", "")) != "placed":
		found.append("save left mug in hand")
	GameState.job = {"items": [{"uid": "j0", "state": "hand", "x": 1.2, "y": 0.0, "z": 1.4}], "boxes": []}
	SaveManager.save_game()
	var saved_items: Array = _saved_file().get("job", {}).get("items", [])
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
	# Every rainy hazard lands on the road, the route reaches the bay, and the alley exists.
	GameState.job = {"def": {"drive": "rainy_afternoon", "level": "L3"}, "boxes": [{"id": 0}, {"id": 1}], "items": []}
	var rainy_drive: Node = load("res://scripts/drive_course.gd").new()
	add_child(rainy_drive)
	for hazard in rainy_drive.get("hazards"):
		var at := Vector2(float(hazard.get("x", 0)), float(hazard.get("y", 0)))
		if str(hazard.get("type", "")) == "wobble":
			continue
		if not bool(rainy_drive.call("_on_road", at)):
			found.append("rainy %s off the road at %s" % [hazard.get("type", ""), at])
	var route: PackedVector2Array = rainy_drive.get("route")
	var drop_bay: Rect2 = (rainy_drive.get("dropoff") as Dictionary).get("bay", Rect2())
	if route.size() < 3 or not drop_bay.grow(4).has_point(route[route.size() - 1]):
		found.append("rainy route %s" % route.size())
	for i in range(1, route.size() - 1):
		if not bool(rainy_drive.call("_on_road", route[i])):
			found.append("route leaves the road at %s" % route[i])
	var town = rainy_drive.get("city")
	if town == null or (town.alley as Rect2).size == Vector2.ZERO:
		found.append("alley missing")
	if str(rainy_drive.get("state")) != "load":
		found.append("drive should start parked for loading")
	rainy_drive.call("_interact")
	if str(rainy_drive.get("state")) != "load" or (rainy_drive.get("box_anim") as Array).is_empty():
		found.append("load up did not start")
	_bury(rainy_drive)
	GameState.job = {}
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
	if int(tiny.get_theme_font_size("font_size")) < 36:
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
		if str(_saved_office_item("mug").get("state", "")) != "placed":
			found.append("save settling")
	GameState.job = {"items": [
		{"uid": "loose", "state": "loose"},
		{"uid": "boxed", "state": "boxed"},
		{"uid": "mid", "state": "settling"},
		{"uid": "held", "state": "hand"},
	], "boxes": []}
	SaveManager.save_game()
	var states := {}
	for item in _saved_file().get("job", {}).get("items", []):
		states[str(item.get("uid", ""))] = str(item.get("state", ""))
	if states.get("loose", "") != "loose" or states.get("boxed", "") != "boxed" or states.get("mid", "") != "placed" or states.get("held", "") != "placed":
		found.append("save states %s" % states)
	return found


func _saved_file() -> Dictionary:
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _saved_office_item(uid: String) -> Dictionary:
	for rec in _saved_file().get("office_items", []):
		if str(rec.get("uid", "")) == uid:
			return rec
	return {}


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
