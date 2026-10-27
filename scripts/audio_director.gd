extends Node

const Tuning = preload("res://scripts/tuning.gd")

var music: AudioStreamPlayer
var loops: Dictionary = {}
var _streams: Dictionary = {}
var bed_name := ""
var _released := false
var _silent := false
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"


func _exit_tree() -> void:
	release_audio()


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	music = AudioStreamPlayer.new()
	music.bus = MUSIC_BUS
	add_child(music)
	apply_volumes()
	# Movie Maker mode runs on the dummy driver too, but there the server
	# still mixes into the recording, so only a plain dummy driver mutes us.
	_silent = AudioServer.get_driver_name() == "Dummy" and not OS.has_feature("movie")
	if not _silent:
		_preload_loops()
	tree_exiting.connect(release_audio)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func apply_volumes() -> void:
	var music_db := linear_to_db(clampf(SaveManager.music_linear, 0.0001, 1.0)) if SaveManager.music_linear > 0.001 else -80.0
	var sfx_db := linear_to_db(clampf(SaveManager.sfx_linear, 0.0001, 1.0)) if SaveManager.sfx_linear > 0.001 else -80.0
	music_db += float(Tuning.get_value("audio.music_db_default", 0))
	sfx_db += float(Tuning.get_value("audio.sfx_db_default", 0))
	var mi := AudioServer.get_bus_index(MUSIC_BUS)
	var si := AudioServer.get_bus_index(SFX_BUS)
	if mi >= 0:
		AudioServer.set_bus_volume_db(mi, music_db)
	if si >= 0:
		AudioServer.set_bus_volume_db(si, sfx_db)


func play_bed(track: String, ambience := "") -> void:
	if track != "":
		play_music(track)
	if ambience == bed_name and (ambience == "" or loops.has(ambience)):
		return
	stop_bed()
	if ambience == "":
		return
	start_loop(ambience)
	if loops.has(ambience):
		bed_name = ambience


func stop_bed() -> void:
	if bed_name == "":
		return
	var name := bed_name
	bed_name = ""
	stop_loop(name)


func stop_level() -> void:
	stop_bed()
	for name in ["sfx_l01_fridge_hum_loop", "sfx_cat_purr_loop", "sfx_l05_fountain_loop", "sfx_rain_ambience_loop", "sfx_truck_idle_loop"]:
		stop_loop(name)


func play_music(track: String) -> void:
	if _silent:
		return
	var path := "res://assets/audio/music/%s.ogg" % track
	if music.stream != null and music.playing and str(music.stream.resource_path) == path:
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	_enable_loop(stream, path)
	music.stream = stream
	music.play()


func play_sfx(sfx_name: String, pitch_rand := false) -> void:
	if _silent:
		return
	var path := "res://assets/audio/sfx/%s.wav" % sfx_name
	var stream := _load_stream(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = Tuning.audio_gain(sfx_name)
	if pitch_rand:
		var span := float(Tuning.get_value("audio.pitch_rand", 0.08))
		player.pitch_scale = randf_range(1.0 - span, 1.0 + span)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func start_loop(sfx_name: String) -> void:
	if _silent:
		return
	if loops.has(sfx_name) and is_instance_valid(loops[sfx_name]):
		return
	var path := _loop_path(sfx_name)
	var stream := _load_stream(path)
	if stream == null:
		return
	_enable_loop(stream, path)
	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = Tuning.audio_gain(sfx_name)
	add_child(player)
	player.play()
	loops[sfx_name] = player


func stop_loop(sfx_name: String) -> void:
	if not loops.has(sfx_name):
		return
	var player: AudioStreamPlayer = loops[sfx_name]
	if is_instance_valid(player):
		player.stop()
		if player.stream is AudioStreamOggVorbis:
			(player.stream as AudioStreamOggVorbis).loop = false
		player.stream = null
		player.free()
	loops.erase(sfx_name)


func stop_all_loops() -> void:
	bed_name = ""
	for key in loops.keys():
		stop_loop(key)


func release_audio() -> void:
	if _released:
		return
	_released = true
	stop_all_loops()
	var players: Array = []
	for child in get_children():
		if child is AudioStreamPlayer:
			players.append(child)
	for player in players:
		var stream_player := player as AudioStreamPlayer
		if stream_player.stream is AudioStreamOggVorbis:
			(stream_player.stream as AudioStreamOggVorbis).loop = false
		stream_player.stop()
		stream_player.stream = null
		if stream_player == music:
			music = null
		stream_player.free()
	_streams.clear()


func _preload_loops() -> void:
	for name in ["sfx_truck_idle_loop", "sfx_rain_ambience_loop"]:
		_load_stream(_loop_path(name))
	var folder := DirAccess.open("res://assets/audio/ambience")
	if folder == null:
		return
	for file_name in folder.get_files():
		if file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".ogg.import") or file_name.ends_with(".wav.import"):
			if file_name.ends_with(".import"):
				continue
			_load_stream("res://assets/audio/ambience/%s" % file_name)


func _loop_path(sfx_name: String) -> String:
	var candidates := [
		"res://assets/audio/ambience/%s.ogg" % sfx_name,
		"res://assets/audio/ambience/%s.wav" % sfx_name,
		"res://assets/audio/sfx/%s.wav" % sfx_name,
		"res://assets/audio/sfx/%s.ogg" % sfx_name,
	]
	for path in candidates:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return path
	return candidates[2]


func _load_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		return null
	_enable_loop(stream, path)
	_streams[path] = stream
	return stream


func _enable_loop(stream: AudioStream, path: String) -> void:
	var file_name := path.get_file().to_lower()
	var should_loop := path.contains("/music/") or path.contains("/ambience/") or "loop" in file_name or "ambience" in file_name
	if not should_loop:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
