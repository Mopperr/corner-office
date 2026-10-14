extends Node

var view_root: Node
var overlay: Node


func _ready() -> void:
	view_root = Node.new()
	view_root.name = "View"
	add_child(view_root)
	overlay = Node.new()
	overlay.name = "Overlay"
	add_child(overlay)
	if GameState.mode == "menu" or (GameState.office_items.is_empty() and GameState.job.is_empty() and GameState.mode != "results"):
		show_menu()
	else:
		_show_saved_mode()
	if not GameState.office_changed.is_connected(_on_office_changed):
		GameState.office_changed.connect(_on_office_changed)


func show_menu() -> void:
	GameState.set_mode("menu")
	_clear(view_root)
	AudioDirector.stop_all_loops()
	var menu := preload("res://scripts/menu_ui.gd").new()
	menu.new_game.connect(_on_new_game)
	menu.continue_game.connect(_on_continue)
	view_root.add_child(menu)


func _on_new_game(character: String) -> void:
	GameState.new_game(character)
	SaveManager.save_game()
	show_play()


func _on_continue() -> void:
	if not SaveManager.load_game():
		show_menu()
		return
	_show_saved_mode()


func _show_saved_mode() -> void:
	var mode := GameState.mode
	if mode == "results" and not GameState.payout.is_empty():
		show_results()
	elif mode == "job_pack" or mode == "truck" or mode == "job_unpack" or mode == "office":
		show_play()
	else:
		GameState.set_mode("office")
		show_play()


func _on_office_changed(_id: String) -> void:
	if GameState.mode != "office" or view_root.get_child_count() == 0:
		return
	call_deferred("show_play")


func show_play() -> void:
	_clear(view_root)
	var room := preload("res://scripts/diorama.gd").new()
	room.open_computer.connect(_open_computer)
	room.request_drive.connect(_start_drive)
	room.request_results.connect(show_results)
	room.request_rebuild.connect(show_play)
	view_root.add_child(room)
	_pause_button()


func _start_drive() -> void:
	GameState.set_mode("drive")
	SaveManager.save_game()
	_clear(view_root)
	var drive := preload("res://scripts/drive_course.gd").new()
	drive.finished.connect(_on_drive_finished)
	view_root.add_child(drive)


func _on_drive_finished(result: Dictionary) -> void:
	GameState.apply_drive_result(result)
	GameState.set_mode("job_unpack")
	for box in GameState.job.get("boxes", []):
		box["slot"] = int(box.get("slot", 0))
	SaveManager.save_game()
	show_play()


func show_results() -> void:
	_clear(view_root)
	var results := preload("res://scripts/results_ui.gd").new()
	results.closed.connect(func():
		show_play()
	)
	view_root.add_child(results)


func _open_computer() -> void:
	if overlay.get_child_count() > 0:
		return
	var computer := preload("res://scripts/computer_ui.gd").new()
	computer.closed.connect(func():
		if is_instance_valid(view_root) and view_root.get_child_count() > 0:
			var room = view_root.get_child(0)
			if room.has_method("_refresh_hud_buttons"):
				room._refresh_hud_buttons()
	)
	overlay.add_child(computer)


func _pause_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	view_root.add_child(layer)
	var btn := UIKit.button("Pause", UIKit.DARK)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -100
	btn.offset_top = 16
	btn.offset_right = -16
	btn.offset_bottom = 56
	btn.pressed.connect(_pause)
	layer.add_child(btn)


func _pause() -> void:
	if overlay.get_node_or_null("Pause") != null:
		return
	get_tree().paused = true
	var panel := Panel.new()
	panel.name = "Pause"
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIKit.style(Color(UIKit.CREAM, 0.96), 0))
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.process_mode = Node.PROCESS_MODE_ALWAYS
	box.position = Vector2(460, 180)
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := UIKit.label("Paused", 42, UIKit.DARK, "title")
	title.process_mode = Node.PROCESS_MODE_ALWAYS
	box.add_child(title)
	var resume := UIKit.button("Resume", UIKit.SAGE)
	resume.process_mode = Node.PROCESS_MODE_ALWAYS
	resume.pressed.connect(func():
		get_tree().paused = false
		panel.queue_free()
	)
	box.add_child(resume)
	var save := UIKit.button("Save", UIKit.WOOD, UIKit.CREAM_CARD)
	save.process_mode = Node.PROCESS_MODE_ALWAYS
	save.pressed.connect(func():
		SaveManager.save_game()
		AudioDirector.play_sfx("sfx_success_chime")
	)
	box.add_child(save)
	var menu := UIKit.button("Main menu", UIKit.TERRA)
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	menu.pressed.connect(func():
		SaveManager.save_game()
		get_tree().paused = false
		panel.queue_free()
		show_menu()
	)
	box.add_child(menu)


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and GameState.mode != "menu":
		_pause()
