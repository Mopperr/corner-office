extends Node3D
## A contact sheet of the Blender-built household pieces: every hh_ model on a
## grid under the room light, one screenshot into CO_SHOTS.

const Props = preload("res://scripts/props.gd")


func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("EAE2D2")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("EAD9C6")
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var ids: Array = []
	for item_id in ItemDB.content_items.keys():
		if str(ItemDB.content_items[item_id].get("model", "")).begins_with("hh_"):
			ids.append(str(item_id))
	ids.sort()
	var cols := 8
	var cell := 2.4
	var i := 0
	for item_id in ids:
		var node := Props.make(str(ItemDB.get_item(item_id).get("model", "")))
		node.position = Vector3((i % cols) * cell, 0, int(i / cols) * cell)
		node.rotation.y = deg_to_rad(20)
		add_child(node)
		var label := Label3D.new()
		label.text = str(ItemDB.get_item(item_id).get("name", item_id))
		label.font_size = 48
		label.pixel_size = 0.004
		label.modulate = Color("2E2A28")
		label.position = node.position + Vector3(0, -0.02, 1.0)
		label.rotation_degrees = Vector3(-90, 0, 0)
		add_child(label)
		i += 1
	# A row of people at the back: every head and top the parts can make.
	var Figure = load("res://scripts/figure.gd")
	var looks: Array = []
	for head in Figure.HEADS:
		looks.append({"head": head, "torso": Figure.TORSOS[looks.size() % Figure.TORSOS.size()]})
	var palette := [Color("D9765F"), Color("7FA3B8"), Color("E6B655"), Color("8FAF7E"), Color("D4C1D8"), Color("C68B59"), Color("F4ECDD")]
	var kinds := ["adult", "kid", "elder", "tall", "short", "adult", "kid"]
	var people_row := int(ceil(float(ids.size()) / float(cols))) + 1
	for j in looks.size():
		var person: Node3D = Figure.build(palette[j % palette.size()], [Color("4A3626"), Color("2B2622"), Color("A8763E"), Color("C9C2B5")][j % 4], kinds[j], Color("3E3A4F"), Figure.SKIN, looks[j])
		person.position = Vector3(j * cell * 1.1, 0, people_row * cell)
		person.rotation.y = deg_to_rad(25)
		add_child(person)
		Figure.animate(person, 0.0, false, 0.1)
	var rows := people_row + 1
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(cols * cell + 4, rows * cell + 4)
	floor.mesh = plane
	floor.material_override = Props.mat(Color("D9D2C4"))
	floor.position = Vector3(cols * cell * 0.5 - cell * 0.5, -0.01, rows * cell * 0.5 - cell * 0.5)
	add_child(floor)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = rows * cell + 2.0
	var center := Vector3(cols * cell * 0.5 - cell * 0.5, 0.5, rows * cell * 0.5 - cell * 0.5)
	cam.position = center + Vector3(6.0, 14.0, 12.0)
	add_child(cam)
	cam.look_at(center, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var dir := OS.get_environment("CO_SHOTS")
	if dir != "":
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/props_sheet.png" % dir)
	print("PROPS_SHEET_OK %d" % ids.size())
	get_tree().quit()
