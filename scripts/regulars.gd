class_name Regulars
extends RefCounted

## The shop's eight regulars, from the team's characters bundle
## (assets/characters/customers): who they are, how they look, what they
## say when they order, while they wait and after they drink, and the
## wordless voice clips that go with each. The shop's dishes are mapped to
## the team's product ids so the product-specific lines land.

const ROOT := "res://assets/characters/customers/"
const IDS := ["steve", "lamp_lady", "keyclackr", "dottie", "theo", "pippa", "rocco", "wren"]
# The voice files are named by first name for two of them.
const VOICE := {"lamp_lady": "lorna", "keyclackr": "kit"}
const SHORT_NAME := {"steve": "Steve", "lamp_lady": "Lorna", "keyclackr": "Kit", "dottie": "Dottie", "theo": "Theo", "pippa": "Pippa", "rocco": "Rocco", "wren": "Wren"}
# The shop's dish ids against the team's product ids.
const PRODUCT := {
	"lemonade": "classic_lemonade", "iced_tea": "iced_tea_lemonade", "drip": "black_coffee", "espresso_shot": "espresso",
	"latte": "latte", "flat_white": "cappuccino", "cold_brew": "iced_coffee", "affogato": "mocha", "tea": "honey_lavender_lemonade",
}
# Build kinds for the rig, from the spec's heights and ages.
const KIND := {"steve": "adult", "lamp_lady": "short", "keyclackr": "tall", "dottie": "elder", "theo": "tall", "pippa": "kid", "rocco": "short", "wren": "adult"}
const TAKES := {"greet": 3, "happy": 4, "okay": 3, "unhappy": 3, "goodbye": 3}

static var _data: Dictionary = {}
static var _last_take: Dictionary = {}


static func _read(name: String) -> Dictionary:
	var file := FileAccess.open(ROOT + name, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = {
			"customers": _read("narrative/customers.json"), "orders": _read("narrative/order_lines.json"),
			"idle": _read("narrative/idle_thoughts.json"), "reviews": _read("narrative/reviews.json"), "spec": _read("customers_spec.json"),
		}
	return _data


static func available() -> bool:
	return not (data()["customers"] as Dictionary).is_empty() and not (data()["spec"] as Dictionary).is_empty()


static func bio(id: String) -> Dictionary:
	for row in (data()["customers"] as Dictionary).get("customers", []):
		if str(row.get("id", "")) == id:
			return row
	return {}


static func display_name(id: String) -> String:
	return str(SHORT_NAME.get(id, id.capitalize()))


static func full_name(id: String) -> String:
	return str(bio(id).get("name", display_name(id)))


static func kind(id: String) -> String:
	return str(KIND.get(id, "adult"))


static func colours(id: String) -> Dictionary:
	# Top, hair and trousers from the spec's palette: the second entry is
	# the hair, the third the top, and the trousers are whichever entry is
	# named for legs.
	var spec: Dictionary = (data()["spec"] as Dictionary).get(id, {})
	var out := {"top": Color("8FA882"), "hair": Color("4A3626"), "trousers": Color("3E3A4F"), "skin": Color("E7C9A8")}
	var rows: Array = spec.get("palette", [])
	for i in rows.size():
		var pair: Array = rows[i]
		if pair.size() < 2:
			continue
		var key := str(pair[0])
		var color := Color(str(pair[1]))
		if key == "skin":
			out["skin"] = color
		elif key.begins_with("hair"):
			out["hair"] = color
		elif key in ["slacks", "joggers", "shorts", "cords", "scrubs", "overall skirt"]:
			out["trousers"] = color
		elif i == 2:
			out["top"] = color
	return out


static func pick(rng: RandomNumberGenerator, exclude: Array) -> String:
	var pool: Array = []
	for id in IDS:
		if not exclude.has(id) and not bio(id).is_empty():
			pool.append(id)
	if pool.is_empty():
		return ""
	return str(pool[rng.randi_range(0, pool.size() - 1)])


static func product_of(dish_id: String) -> String:
	return str(PRODUCT.get(dish_id, ""))


static func _one(pool: Array, rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return ""
	return str(pool[rng.randi_range(0, pool.size() - 1)])


static func order_line(id: String, dish_id: String, dish_name: String, rng: RandomNumberGenerator) -> String:
	var orders: Dictionary = data()["orders"]
	var product := product_of(dish_id)
	var specific: Dictionary = (orders.get("product_specific", {}) as Dictionary).get(id, {})
	var said := _one(specific.get(product, []), rng) if product != "" else ""
	if said == "":
		said = _one((orders.get("generic", {}) as Dictionary).get(id, []), rng)
	if said == "":
		said = _one((orders.get("any_customer_product", {}) as Dictionary).get(product, []), rng)
	return said.replace("{product}", dish_name)


static func idle_line(id: String, rng: RandomNumberGenerator) -> String:
	var idle: Dictionary = data()["idle"]
	var said := _one((idle.get("per_customer", {}) as Dictionary).get(id, []), rng)
	if said == "":
		said = _one(idle.get("generic", []), rng)
	return said


static func review_line(id: String, dish_id: String, quality: String, rng: RandomNumberGenerator) -> String:
	# quality: great, okay or off.
	var reviews: Dictionary = data()["reviews"]
	var product := product_of(dish_id)
	var by_cp: Dictionary = ((reviews.get("per_customer_product", {}) as Dictionary).get(id, {}) as Dictionary).get(product, {})
	if by_cp.has(quality):
		return str(by_cp[quality])
	var by_c: Dictionary = (reviews.get("per_customer", {}) as Dictionary).get(id, {})
	if by_c.has(quality):
		return str(by_c[quality])
	var by_p: Dictionary = (reviews.get("by_product", {}) as Dictionary).get(product, {})
	return _one(by_p.get(quality, []), rng)


static func voice_path(id: String, variant: String, rng: RandomNumberGenerator) -> String:
	# A random take, never the one just played for this voice and variant.
	var voice := str(VOICE.get(id, id))
	var takes := int(TAKES.get(variant, 3))
	var key := voice + ":" + variant
	var take := rng.randi_range(1, takes)
	if takes > 1 and take == int(_last_take.get(key, 0)):
		take = take % takes + 1
	_last_take[key] = take
	return "%svoices/sfx_vo_%s_%s_%02d.wav" % [ROOT, voice, variant, take]
