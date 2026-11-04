extends Node
# Renders a character on a plain stage and saves a picture: CO_SHOTS=dir CO_WHO=dana

func _ready() -> void:
	var who := OS.get_environment("CO_WHO")
	if who == "":
		who = "dana"
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("F4E9D8")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("EAD9C6")
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_energy = 1.1
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	floor_mesh.mesh = plane
	floor_mesh.material_override = Props.mat(Color("C9BCA8"))
	add_child(floor_mesh)
	var person := Props.v2_character(who)
	if person == null:
		print("no figure for " + who)
		get_tree().quit()
		return
	add_child(person)
	person.rotation.y = deg_to_rad(-25)
	var cam := Camera3D.new()
	cam.position = Vector3(0.9, 1.3, 2.6)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	cam.fov = 45
	add_child(cam)
	cam.current = true
	await get_tree().create_timer(0.8).timeout
	await _shot(who + "_full")
	cam.position = Vector3(0.45, 1.55, 1.0)
	cam.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	cam.fov = 35
	await get_tree().create_timer(0.3).timeout
	await _shot(who + "_face")
	print("PEEK_OK")
	get_tree().quit()


func _shot(label: String) -> void:
	var dir := OS.get_environment("CO_SHOTS")
	if dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/figure_%s.png" % [dir, label])
