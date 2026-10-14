extends Node

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
	if abs(float(Tuning.get_value("wall_mount_offset_m", 0)) - 0.11) > 0.001:
		failures.append("wall offset")
	var board := GameState.find_office_item("board")
	if board.is_empty() or abs(float(board.get("x", 0)) - 0.11) > 0.001:
		failures.append("board clearance")
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
	var diorama_script: GDScript = load("res://scripts/diorama.gd")
	if diorama_script == null:
		failures.append("diorama script")
	else:
		GameState.set_mode("office")
		var office: Node = diorama_script.new()
		add_child(office)
		office.queue_free()
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
	if failures.is_empty():
		print("SMOKE_OK")
		get_tree().quit(0)
	else:
		print("SMOKE_FAIL")
		for failure in failures:
			print(" - ", failure)
		get_tree().quit(1)
