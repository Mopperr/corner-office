class_name ClientParty
extends Node3D

## The people you are moving, on site: a person, a couple, or a family who
## stand by the door, chat, and comment on the work. Lines come from
## data/clients.json by mood (warm, fussy, rude) and by event; kids have a
## pool of their own. The diorama owns the figures' bubbles and poses and
## calls react() when something happens.

const Figure = preload("res://scripts/figure.gd")
const Props = preload("res://scripts/props.gd")

const MOODS := ["warm", "fussy", "rude"]
const COOLDOWN := 2.5
const IDLE_MIN := 14.0
const IDLE_MAX := 26.0
const SLOW_AFTER := 150.0

static var data: Dictionary = {}

var diorama: Node = null
var mood := "warm"
var client_name := "the client"
var members: Array = []
var time := 0.0
var cooldown := 0.0
var idle_in := 9.0
var started_at := 0.0
var said_slow := false
var beats: Array = []
var beat := 0
var beat_in := 0.0
var ending := ""
var temper := 0
var rng := RandomNumberGenerator.new()


static func load_data() -> Dictionary:
	if data.is_empty():
		var file := FileAccess.open("res://data/clients.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
	return data


static func mood_for(def: Dictionary) -> String:
	var given := str(def.get("mood", ""))
	if given in MOODS:
		return given
	return MOODS[absi(hash(str(def.get("client", def.get("id", "x"))))) % MOODS.size()]


static func party_for(def: Dictionary) -> Array:
	var given: Array = def.get("party", [])
	if given.is_empty():
		return ["adult"]
	return given


static func line(pool_mood: String, event: String, seed: int, fills: Dictionary = {}) -> String:
	# One line from the pool, with {item}, {room} and {name} filled in.
	var pools: Dictionary = load_data()
	var pool: Array = []
	if pool_mood == "kid":
		pool = (pools.get("kid", {}) as Dictionary).get(event, [])
	else:
		pool = ((pools.get("moods", {}) as Dictionary).get(pool_mood, {}) as Dictionary).get(event, [])
	if pool.is_empty():
		return ""
	var text := str(pool[absi(seed) % pool.size()])
	for key in fills.keys():
		text = text.replace("{%s}" % key, str(fills[key]))
	text = text.replace("{name}", str(fills.get("name", GameState.first_name())))
	return text


static func story_for(def: Dictionary) -> Dictionary:
	var id := str(def.get("story", ""))
	if id == "":
		return {}
	return load("res://scripts/job_gen.gd").story(id)


static func finish_line(def: Dictionary, condition: int, rooms_right: int, rooms_total: int) -> String:
	var tale := story_for(def)
	if str(tale.get("ending", "")) != "":
		return str(tale["ending"])
	var event := "finish_ok"
	var share := 1.0 if rooms_total == 0 else float(rooms_right) / float(rooms_total)
	if condition >= 85 and share >= 0.75:
		event = "finish_good"
	elif condition < 60 or share < 0.4:
		event = "finish_bad"
	var who := str(def.get("client", "The client"))
	var said := line(mood_for(def), event, hash(str(def.get("id", "")) + event), {"name": GameState.first_name()})
	if said == "":
		return ""
	return "%s: \"%s\"" % [who, said]


func setup(owner: Node, def: Dictionary, door: Vector3, inward: Vector3) -> void:
	diorama = owner
	name = "ClientParty"
	mood = mood_for(def)
	client_name = str(def.get("client", "the client"))
	var tale := story_for(def)
	beats = (tale.get("beats", []) as Array).duplicate()
	ending = str(tale.get("ending", ""))
	beat = 0
	beat_in = 9.0
	rng.seed = hash(str(def.get("id", "")) + client_name)
	var pools: Dictionary = load_data()
	var palette: Array = pools.get("palette", ["D9765F"])
	var hairs: Array = pools.get("hair", ["4A3626"])
	var kinds: Array = party_for(def)
	var n := 0
	for kind in kinds:
		var color := Color(str(palette[(rng.randi() + n) % palette.size()]))
		var hair := Color(str(hairs[rng.randi() % hairs.size()]))
		var trousers: Color = [Color("3E3A4F"), Color("5A4A3A"), Color("4A5A6A"), Color("6B4A3A")][rng.randi() % 4]
		# A party entry is a kind ("adult", "kid", "elder") or a person record
		# ({"kind", "age", "skin_index", "seated"...}); a tone is dealt per
		# person when the record has none.
		var record: Dictionary = kind.duplicate() if kind is Dictionary else {"kind": str(kind)}
		var figure_kind := str(record.get("kind", "adult"))
		if figure_kind == "adult":
			figure_kind = ["adult", "short", "tall"][rng.randi() % 3]
		record["kind"] = figure_kind
		if not record.has("skin_index"):
			record["skin_index"] = 1 + rng.randi() % Figure.SKIN_TONES.size()
		var person := Figure.build_person(record, color, hair, trousers)
		person.name = "Client%d" % n
		person.set_meta("uid", "client:%d" % n)
		person.set_meta("kid", Figure.is_kid_kind(figure_kind))
		# A loose cluster just inside the door, to either side of it: out of the
		# box row and the spill behind it, facing the room.
		var side := -1.0 if n % 2 == 0 else 1.0
		var offset := Vector3(side * (1.5 + 0.6 * float(n / 2)), 0.0, 0.8 + 0.4 * float(n % 2))
		person.position = door + inward * offset.z + Vector3(offset.x, 0, 0)
		# A body the click ray can land on, like a customer's.
		Props.add_picker(person, Vector3(0.6, 1.5 * float((Figure.KINDS.get(figure_kind, Figure.KINDS["adult"]) as Dictionary).get("scale", 1.0)), 0.6))
		add_child(person)
		# In the tree first: look_at needs a world transform.
		person.look_at(person.position + inward, Vector3.UP)
		person.rotate_y(PI)
		# Where they stand; an angry owner comes back here after the shove.
		person.set_meta("home_pos", person.position)
		person.set_meta("home_yaw", person.rotation.y)
		members.append(person)
		n += 1
	started_at = 0.0
	time = 0.0


func _process(delta: float) -> void:
	time += delta
	cooldown = maxf(0.0, cooldown - delta)
	for person in members:
		if is_instance_valid(person):
			if diorama != null and diorama.has_method("_animate_person"):
				diorama.call("_animate_person", person, time, bool(person.get_meta("walking", false)), delta)
			else:
				Figure.animate(person, time, bool(person.get_meta("walking", false)), delta)
	if beat == 0 and not beats.is_empty():
		# The first part of the story comes a moment after the hello.
		beat_in -= delta
		if beat_in <= 0.0:
			tell()
	idle_in -= delta
	if idle_in <= 0.0:
		idle_in = rng.randf_range(IDLE_MIN, IDLE_MAX)
		react("idle", {})
	if not said_slow and time > SLOW_AFTER:
		said_slow = true
		react("slow", {})


func tell() -> String:
	# The next part of why they are moving, in an adult's words.
	if beat >= beats.size():
		return ""
	var who: Node3D = null
	for person in members:
		if is_instance_valid(person) and not bool(person.get_meta("kid", false)):
			who = person
			break
	if who == null and not members.is_empty():
		who = members[0]
	if who == null:
		return ""
	var said := str(beats[beat])
	beat += 1
	cooldown = COOLDOWN + 2.0
	idle_in = maxf(idle_in, 8.0)
	if diorama != null and diorama.has_method("_bubble"):
		diorama.call("_bubble", who, said, 7.0)
	if diorama != null and diorama.has_method("_act"):
		diorama.call("_act", who, "nod" if beat < beats.size() else "shrug", 1.4)
	return said


func on_progress(done: int, total: int) -> void:
	# The second and third parts come as the work gets on: a third in, two thirds in.
	if beats.is_empty() or total <= 0:
		return
	var share := float(done) / float(total)
	if (beat == 1 and share >= 0.34) or (beat == 2 and share >= 0.67):
		tell()


func speaker(event: String) -> Node3D:
	# Kids chip in a third of the time, adults do the commenting otherwise.
	var kids: Array = []
	var adults: Array = []
	for person in members:
		if not is_instance_valid(person):
			continue
		if bool(person.get_meta("kid", false)):
			kids.append(person)
		else:
			adults.append(person)
	if not kids.is_empty() and (adults.is_empty() or rng.randf() < 0.33 or event == "cat"):
		return kids[rng.randi() % kids.size()]
	if adults.is_empty():
		return null
	return adults[rng.randi() % adults.size()]


func react(event: String, fills: Dictionary, force := false, who_uid := "") -> String:
	# Say something about what just happened. Chatter about placing is
	# rationed so the family is not a commentary track on every piece. A
	# click names who answers.
	if members.is_empty():
		return ""
	if not force and cooldown > 0.0:
		return ""
	if not force and event == "placed" and rng.randf() > 0.3:
		return ""
	var who := member_for(who_uid) if who_uid != "" else speaker(event)
	if who == null:
		who = speaker(event)
	if who == null:
		return ""
	var pool_mood := "kid" if bool(who.get_meta("kid", false)) else mood
	var said := line(pool_mood, event, rng.randi(), fills)
	if said == "":
		return ""
	cooldown = COOLDOWN
	if diorama != null and diorama.has_method("_bubble"):
		diorama.call("_bubble", who, said, 4.5)
	var pose := "nod"
	match event:
		"wrong_room", "scuff", "caught", "tipped", "broken", "attack":
			pose = "point" if mood != "warm" else "shrug"
		"placed_good", "finish_good", "stacked":
			pose = "clap"
		"greet", "talk", "finish_ok":
			pose = "wave"
		"slow":
			pose = "shrug"
	if diorama != null and diorama.has_method("_act"):
		diorama.call("_act", who, pose, 1.2)
	return said


func member_for(uid: String) -> Node3D:
	for person in members:
		if is_instance_valid(person) and str(person.get_meta("uid", "")) == uid:
			return person
	return null
