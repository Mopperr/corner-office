class_name Figure
extends RefCounted

## A jointed toy-town person built from primitives, animated in code: hips,
## thighs, shins and feet; torso; shoulders, upper arms, forearms and hands;
## a head with hair. Everything hangs off pivots at the joints so a walk
## cycle, a carry pose, a sit, and the short action poses all read.

const UIKit = preload("res://scripts/ui_kit.gd")
const Props = preload("res://scripts/props.gd")

const SKIN := Color("E7C9A8")
# The eight approved skin tones (Andrew, 28 Oct 2026), used unchanged and
# assigned per person, never by name or role. 1 to 8; four sit off the
# furniture palette on purpose.
const SKIN_TONES := ["E7C9A8", "D9B98A", "C9A070", "C68B59", "B27243", "8D5A3B", "6B4A3A", "553629"]
# The adult figure is about 1.70 m; kids come in three size tiers by age:
# K1 (4 to 6) about 1.05 m, K2 (7 to 9) about 1.28 m, K3 (10 to 12) about
# 1.45 m. Seat and hip heights scale with the figure.
const ADULT_HEIGHT := 1.70
const KINDS := {
	"adult": {"scale": 1.0, "head": 1.0, "lean": 0.0},
	"short": {"scale": 0.9, "head": 1.05, "lean": 0.0},
	"tall": {"scale": 1.08, "head": 0.95, "lean": 0.0},
	"kid": {"scale": 0.68, "head": 1.3, "lean": 0.0},
	"kid_k1": {"scale": 0.62, "head": 1.35, "lean": 0.0},
	"kid_k2": {"scale": 0.75, "head": 1.25, "lean": 0.0},
	"kid_k3": {"scale": 0.85, "head": 1.15, "lean": 0.0},
	"elder": {"scale": 0.95, "head": 1.0, "lean": 0.18},
}
const SEAT_HEIGHT := 0.47
const HIP_HEIGHT := 0.85


static func skin_tone(index: int) -> Color:
	# skin_index 1 to 8 on a person record; anything else is the default tone.
	if index >= 1 and index <= SKIN_TONES.size():
		return Color(str(SKIN_TONES[index - 1]))
	return SKIN


static func kid_tier(age: int) -> String:
	if age <= 6:
		return "kid_k1"
	if age <= 9:
		return "kid_k2"
	return "kid_k3"


static func is_kid_kind(kind: String) -> bool:
	return kind.begins_with("kid")


static func seat_height(kind: String) -> float:
	return SEAT_HEIGHT * float((KINDS.get(kind, KINDS["adult"]) as Dictionary).get("scale", 1.0))


static func hip_height(kind: String) -> float:
	return HIP_HEIGHT * float((KINDS.get(kind, KINDS["adult"]) as Dictionary).get("scale", 1.0))


static func build_person(record: Dictionary, color: Color, hair: Color, trousers: Color) -> Node3D:
	# A person from a record: kind (or a kid's age for the size tier),
	# skin_index for the tone, and seated for someone who stays in a chair
	# (Finn's wheelchair: a seat height and seated clips in place of a walk;
	# the chair model and the seated clips are not built yet, so this is the
	# hook only).
	var kind := str(record.get("kind", "adult"))
	if kind == "kid" and record.has("age"):
		kind = kid_tier(int(record.get("age", 8)))
	var person := build(color, hair, kind, trousers, skin_tone(int(record.get("skin_index", 0))), record.get("style", {}))
	person.set_meta("kind", kind)
	person.set_meta("seat_height", seat_height(kind))
	person.set_meta("hip_height", hip_height(kind))
	if bool(record.get("seated", false)):
		person.set_meta("seated", true)
		person.set_meta("sitting", true)
		person.set_meta("seat_height", float(record.get("seat_height", 0.45)))
	return person


const HEADS := ["short", "bob", "ponytail", "bun", "bald", "curly", "cap"]
const TORSOS := ["tee", "shirt", "jacket", "apron"]


static func pick_style(kind: String, seed: int) -> Dictionary:
	# A head and a top to suit: kids in caps and curls, elders in buns or bald.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var heads: Array = HEADS
	var tops: Array = TORSOS
	match kind:
		"kid":
			heads = ["cap", "curly", "short", "bob"]
			tops = ["tee", "tee", "shirt"]
		"elder":
			heads = ["bun", "bald", "short"]
			tops = ["shirt", "jacket"]
	return {"head": str(heads[rng.randi() % heads.size()]), "torso": str(tops[rng.randi() % tops.size()])}


static func _part_model(name: String, colors: Dictionary) -> Node3D:
	# A Blender-built part, recoloured by what each mesh is named for.
	var node := Props.model(name)
	if node == null:
		return null
	for mesh_instance in node.find_children("*", "MeshInstance3D", true, false):
		var role := str(mesh_instance.name).split("_")[0].to_lower()
		if colors.has(role):
			mesh_instance.material_override = Props.mat(colors[role])
	return node


static func build(color: Color, hair: Color = Color("4A3626"), kind := "adult", trousers: Color = Color("3E3A4F"), skin: Color = SKIN, style: Dictionary = {}) -> Node3D:
	var person := Node3D.new()
	var spec: Dictionary = KINDS.get(kind, KINDS["adult"])
	var figure := Node3D.new()
	figure.name = "Figure"
	figure.scale = Vector3.ONE * float(spec["scale"])
	person.add_child(figure)
	person.set_meta("kind", kind)
	if style.is_empty():
		style = pick_style(kind, hash("%s:%s:%s" % [color.to_html(), hair.to_html(), kind]))
	var colors := {
		"skin": skin, "cloth": color, "cloth2": color.darkened(0.18), "trouser": trousers, "trouser2": trousers.darkened(0.12),
		"hair": hair, "shoe": Color("2B2622"), "eye": Color("2B2622"), "mouth": skin.darkened(0.3), "accent": Color("E6B655") if kind != "kid" else Color("7FA3B8"),
	}
	if ResourceLoader.exists("res://assets/models/fig_thigh.glb"):
		_build_modelled(person, figure, spec, style, colors)
		return person
	# Hips and legs.
	var hips := Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.55, 0)
	figure.add_child(hips)
	var belt := Props.mesh_box(Vector3(0.3, 0.1, 0.22), trousers)
	belt.position = Vector3(0, 0.0, 0)
	hips.add_child(belt)
	for side in [-1.0, 1.0]:
		var thigh := Node3D.new()
		thigh.name = "ThighL" if side < 0.0 else "ThighR"
		thigh.position = Vector3(side * 0.09, -0.03, 0)
		hips.add_child(thigh)
		var thigh_mesh := Props.mesh_cylinder(0.07, 0.28, trousers)
		thigh_mesh.position = Vector3(0, -0.14, 0)
		thigh.add_child(thigh_mesh)
		var shin := Node3D.new()
		shin.name = "ShinL" if side < 0.0 else "ShinR"
		shin.position = Vector3(0, -0.28, 0)
		thigh.add_child(shin)
		var shin_mesh := Props.mesh_cylinder(0.06, 0.24, trousers.darkened(0.12))
		shin_mesh.position = Vector3(0, -0.12, 0)
		shin.add_child(shin_mesh)
		var foot := Props.mesh_box(Vector3(0.11, 0.06, 0.2), Color("2B2622"))
		foot.position = Vector3(0, -0.24, 0.04)
		shin.add_child(foot)
	# Torso.
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 0.55, 0)
	torso.rotation.x = float(spec["lean"])
	figure.add_child(torso)
	var body := Props.mesh_cylinder(0.2, 0.46, color)
	body.position = Vector3(0, 0.23, 0)
	torso.add_child(body)
	var collar := Props.mesh_cylinder(0.21, 0.05, color.darkened(0.18))
	collar.position = Vector3(0, 0.44, 0)
	torso.add_child(collar)
	# Head: kept directly under the figure, at the height the rest of the
	# game expects (bubbles and glances read it from here).
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15 * float(spec["head"])
	sphere.height = 0.3 * float(spec["head"])
	head.mesh = sphere
	head.material_override = Props.mat(skin)
	head.position = Vector3(0, 1.18, 0)
	head.name = "Head"
	figure.add_child(head)
	var cap := Props.mesh_cylinder(0.15 * float(spec["head"]), 0.08, hair)
	cap.position = Vector3(0, 0.09 * float(spec["head"]), 0)
	head.add_child(cap)
	var fringe := Props.mesh_box(Vector3(0.2 * float(spec["head"]), 0.05, 0.08), hair)
	fringe.position = Vector3(0, 0.06 * float(spec["head"]), 0.1 * float(spec["head"]))
	head.add_child(fringe)
	var nose := Props.mesh_box(Vector3(0.03, 0.03, 0.04), skin.darkened(0.08))
	nose.position = Vector3(0, -0.01, 0.15 * float(spec["head"]))
	head.add_child(nose)
	# Shoulders and arms: the pivots keep the old names so poses still apply.
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0.0 else "ArmR"
		arm.position = Vector3(side * 0.24, 0.98, 0)
		figure.add_child(arm)
		var upper := Props.mesh_cylinder(0.05, 0.24, color.darkened(0.12))
		upper.position = Vector3(0, -0.12, 0)
		arm.add_child(upper)
		var fore := Node3D.new()
		fore.name = "ForeL" if side < 0.0 else "ForeR"
		fore.position = Vector3(0, -0.24, 0)
		arm.add_child(fore)
		var fore_mesh := Props.mesh_cylinder(0.045, 0.2, color.darkened(0.12))
		fore_mesh.position = Vector3(0, -0.1, 0)
		fore.add_child(fore_mesh)
		var hand := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.05
		ball.height = 0.1
		hand.mesh = ball
		hand.material_override = Props.mat(skin)
		hand.position = Vector3(0, -0.22, 0)
		fore.add_child(hand)
	# Something to carry, shown only while carrying.
	var carry := Props.make("box_closed")
	carry.name = "Carry"
	carry.scale = Vector3(0.7, 0.7, 0.7)
	carry.position = Vector3(0, 0.62, 0.3)
	carry.visible = false
	var carry_collision := carry.get_node_or_null("PropCollision")
	if carry_collision:
		carry_collision.free()
	figure.add_child(carry)
	return person


static func _build_modelled(person: Node3D, figure: Node3D, spec: Dictionary, style: Dictionary, colors: Dictionary) -> void:
	# The same rig as below, dressed in the Blender-built parts.
	var hips := Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.55, 0)
	figure.add_child(hips)
	var belt := Props.mesh_box(Vector3(0.3, 0.1, 0.22), colors["trouser"])
	hips.add_child(belt)
	for side in [-1.0, 1.0]:
		var thigh := Node3D.new()
		thigh.name = "ThighL" if side < 0.0 else "ThighR"
		thigh.position = Vector3(side * 0.09, -0.03, 0)
		hips.add_child(thigh)
		thigh.add_child(_part_model("fig_thigh", colors))
		var shin := Node3D.new()
		shin.name = "ShinL" if side < 0.0 else "ShinR"
		shin.position = Vector3(0, -0.28, 0)
		thigh.add_child(shin)
		shin.add_child(_part_model("fig_shin", colors))
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 0.55, 0)
	torso.rotation.x = float(spec["lean"])
	figure.add_child(torso)
	torso.add_child(_part_model("fig_torso_" + str(style.get("torso", "tee")), colors))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.18, 0)
	head.scale = Vector3.ONE * float(spec["head"])
	figure.add_child(head)
	var face := _part_model("fig_head_" + str(style.get("head", "short")), colors)
	if face == null:
		face = _part_model("fig_head_short", colors)
	head.add_child(face)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0.0 else "ArmR"
		arm.position = Vector3(side * 0.24, 0.98, 0)
		figure.add_child(arm)
		arm.add_child(_part_model("fig_upper_arm", colors))
		var fore := Node3D.new()
		fore.name = "ForeL" if side < 0.0 else "ForeR"
		fore.position = Vector3(0, -0.24, 0)
		arm.add_child(fore)
		fore.add_child(_part_model("fig_fore_arm", colors))
	var carry := Props.make("box_closed")
	carry.name = "Carry"
	carry.scale = Vector3(0.7, 0.7, 0.7)
	carry.position = Vector3(0, 0.62, 0.3)
	carry.visible = false
	var carry_collision := carry.get_node_or_null("PropCollision")
	if carry_collision:
		carry_collision.free()
	figure.add_child(carry)
	person.set_meta("style", style)


static func part(node: Node3D, path: String) -> Node3D:
	var figure := node.get_node_or_null("Figure") as Node3D
	if figure == null:
		return null
	return figure.get_node_or_null(path) as Node3D


static func animate(node: Node3D, t: float, walking: bool, delta: float) -> void:
	# The base motion. Short action poses are layered on top by the caller.
	var figure := node.get_node_or_null("Figure") as Node3D
	if figure == null:
		return
	var hips := figure.get_node_or_null("Hips") as Node3D
	var torso := figure.get_node_or_null("Torso") as Node3D
	var head := figure.get_node_or_null("Head") as Node3D
	var arm_l := figure.get_node_or_null("ArmL") as Node3D
	var arm_r := figure.get_node_or_null("ArmR") as Node3D
	var thigh_l := figure.get_node_or_null("Hips/ThighL") as Node3D
	var thigh_r := figure.get_node_or_null("Hips/ThighR") as Node3D
	var shin_l := figure.get_node_or_null("Hips/ThighL/ShinL") as Node3D
	var shin_r := figure.get_node_or_null("Hips/ThighR/ShinR") as Node3D
	var fore_l := figure.get_node_or_null("ArmL/ForeL") as Node3D
	var fore_r := figure.get_node_or_null("ArmR/ForeR") as Node3D
	var carry := bool(node.get_meta("carry", false))
	var sitting := bool(node.get_meta("sit", false))
	var carry_box := figure.get_node_or_null("Carry") as Node3D
	if carry_box:
		carry_box.visible = carry
	var k := minf(1.0, delta * 8.0)
	# Face the way we are moving.
	var last: Vector3 = node.get_meta("last_pos", node.position)
	var moved := node.position - last
	moved.y = 0.0
	node.set_meta("last_pos", node.position)
	if walking and moved.length() > 0.002:
		var yaw := atan2(moved.x, moved.z)
		node.rotation.y = lerp_angle(node.rotation.y, yaw, minf(1.0, delta * 10.0))
	if bool(node.get_meta("down", false)):
		# Flat on her back: the whole figure tips over from the feet.
		figure.rotation.x = lerpf(figure.rotation.x, -1.45, minf(1.0, delta * 6.0))
		figure.position.y = lerpf(figure.position.y, 0.12, k)
		for arm in [arm_l, arm_r]:
			if arm:
				arm.rotation.x = lerpf(arm.rotation.x, -1.6, k)
		return
	if figure.rotation.x != 0.0:
		figure.rotation.x = lerpf(figure.rotation.x, 0.0, minf(1.0, delta * 5.0))
		if absf(figure.rotation.x) < 0.01:
			figure.rotation.x = 0.0
	if sitting:
		if hips:
			hips.position.y = lerpf(hips.position.y, 0.38, k)
		if thigh_l:
			thigh_l.rotation.x = lerpf(thigh_l.rotation.x, -1.45, k)
		if thigh_r:
			thigh_r.rotation.x = lerpf(thigh_r.rotation.x, -1.45, k)
		if shin_l:
			shin_l.rotation.x = lerpf(shin_l.rotation.x, 1.45, k)
		if shin_r:
			shin_r.rotation.x = lerpf(shin_r.rotation.x, 1.45, k)
		if torso:
			torso.position.y = lerpf(torso.position.y, 0.38, k)
		if head:
			head.position.y = lerpf(head.position.y, 1.01, k)
			head.rotation.y = sin(t * 0.7) * 0.3
		for arm in [arm_l, arm_r]:
			if arm:
				arm.position.y = lerpf(arm.position.y, 0.81, k)
				arm.rotation.x = lerpf(arm.rotation.x, -0.5, k)
		for fore in [fore_l, fore_r]:
			if fore:
				fore.rotation.x = lerpf(fore.rotation.x, -1.0, k)
		figure.position.y = sin(t * 1.6) * 0.008
		return
	# Standing or walking: joints come back from a sit.
	if hips:
		hips.position.y = lerpf(hips.position.y, 0.55, k)
	if torso:
		torso.position.y = lerpf(torso.position.y, 0.55, k)
	for arm in [arm_l, arm_r]:
		if arm:
			arm.position.y = lerpf(arm.position.y, 0.98, k)
	if walking:
		var phase := t * 9.0
		var swing := sin(phase)
		figure.position.y = absf(sin(phase)) * 0.045
		figure.rotation.z = sin(phase) * 0.03
		if thigh_l:
			thigh_l.rotation.x = swing * 0.55
		if thigh_r:
			thigh_r.rotation.x = -swing * 0.55
		# The trailing leg bends at the knee.
		if shin_l:
			shin_l.rotation.x = maxf(0.0, -swing) * 0.9
		if shin_r:
			shin_r.rotation.x = maxf(0.0, swing) * 0.9
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, 0.08, k)
			torso.rotation.y = sin(phase) * 0.06
		if head:
			head.position.y = lerpf(head.position.y, 1.18, k)
			head.rotation.y = lerpf(head.rotation.y, 0.0, k)
		if carry:
			for arm in [arm_l, arm_r]:
				if arm:
					arm.rotation.x = lerpf(arm.rotation.x, -1.1, k)
					arm.rotation.z = 0.0
			for fore in [fore_l, fore_r]:
				if fore:
					fore.rotation.x = lerpf(fore.rotation.x, -0.9, k)
		else:
			if arm_l:
				arm_l.rotation.x = -swing * 0.6
			if arm_r:
				arm_r.rotation.x = swing * 0.6
			for fore in [fore_l, fore_r]:
				if fore:
					fore.rotation.x = lerpf(fore.rotation.x, -0.25, k)
	else:
		figure.position.y = sin(t * 1.6) * 0.01
		figure.rotation.z = 0.0
		if thigh_l:
			thigh_l.rotation.x = lerpf(thigh_l.rotation.x, 0.0, k)
		if thigh_r:
			thigh_r.rotation.x = lerpf(thigh_r.rotation.x, 0.0, k)
		if shin_l:
			shin_l.rotation.x = lerpf(shin_l.rotation.x, 0.0, k)
		if shin_r:
			shin_r.rotation.x = lerpf(shin_r.rotation.x, 0.0, k)
		if hips:
			# A slow shift of weight from foot to foot.
			hips.rotation.z = sin(t * 0.8) * 0.04
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, 0.0, k)
			torso.rotation.y = lerpf(torso.rotation.y, 0.0, k)
		if head:
			head.position.y = lerpf(head.position.y, 1.18, k)
			head.rotation.y = sin(t * 0.9) * 0.25
		if carry:
			for arm in [arm_l, arm_r]:
				if arm:
					arm.rotation.x = lerpf(arm.rotation.x, -1.1, k)
			for fore in [fore_l, fore_r]:
				if fore:
					fore.rotation.x = lerpf(fore.rotation.x, -0.9, k)
		else:
			for arm in [arm_l, arm_r]:
				if arm:
					arm.rotation.x = lerpf(arm.rotation.x, 0.0, minf(1.0, delta * 6.0))
					arm.rotation.z = lerpf(arm.rotation.z, 0.0, minf(1.0, delta * 6.0))
			for fore in [fore_l, fore_r]:
				if fore:
					fore.rotation.x = lerpf(fore.rotation.x, -0.15, k)


static func reset_pose(node: Node3D) -> void:
	# After an action pose: arms straight, head level.
	for name in ["ArmL", "ArmR", "Head", "ArmL/ForeL", "ArmR/ForeR", "Torso"]:
		var p := part(node, name)
		if p:
			p.rotation = Vector3.ZERO
			if name == "Head":
				p.position.y = 1.18
