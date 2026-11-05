extends Node
# Renders the drive at a few points along the lane and saves a picture of
# each, for a look at the road without playing the whole slice.
# CO_SHOTS=dir CO_DRIVE=rainy_afternoon CO_VENUE=cafe

var shot_dir := ""


func _ready() -> void:
	shot_dir = OS.get_environment("CO_SHOTS")
	var drive_id := OS.get_environment("CO_DRIVE")
	if drive_id == "":
		drive_id = "rainy_afternoon"
	var venue_id := OS.get_environment("CO_VENUE")
	if venue_id == "":
		venue_id = "cafe"
	GameState.new_game("dana")
	GameState.set_mode("drive")
	GameState.job = {"def": {"id": "peek", "venue": venue_id, "drive": drive_id, "level": "L3"}, "boxes": [{"id": 0}, {"id": 1}, {"id": 2}, {"id": 3}], "items": []}
	var drive = load("res://scripts/drive_course.gd").new()
	add_child(drive)
	await _settle(0.6)
	await _shot("parked")
	drive.state = "drive"
	drive.speed = 120.0
	for frac in [0.04, 0.2, 0.45, 0.7, 0.9, 0.985]:
		drive.along = float(frac) * drive.lane_total
		drive.pos = drive._lane_point(drive.along)
		var ahead: Vector2 = drive._lane_point(drive.along + 12.0)
		drive.heading = (ahead - drive.pos).angle()
		drive._snap_camera()
		await _settle(0.5)
		await _shot("along_%02d" % int(float(frac) * 100.0))
	drive.along = drive.lane_total
	drive.speed = 0.0
	drive.at_end = true
	drive.pos = drive._lane_point(drive.lane_total)
	var tail: Vector2 = drive._lane_point(drive.lane_total - 8.0)
	drive.heading = (drive.pos - tail).angle()
	drive._check_dropoff()
	drive._snap_camera()
	await _settle(0.5)
	await _shot("at_kerb")
	print("PEEK_OK")
	get_tree().quit()


func _settle(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(label: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/peek_%s.png" % [shot_dir, label])
