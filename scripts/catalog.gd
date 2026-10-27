class_name Catalog
extends RefCounted

static var forest: Dictionary = {}
static var shop: Dictionary = {}
const OFFICE_RANK: Array[String] = ["garage", "bakery", "warehouse", "glass", "corner"]


static func ensure() -> void:
	if not forest.is_empty():
		return
	forest = _read("res://data/forest.json")
	shop = _read("res://data/shop.json")


static func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func categories() -> Array:
	ensure()
	return forest.get("categories", [])


static func items() -> Array:
	ensure()
	return forest.get("items", [])


static func sku(id: String) -> Dictionary:
	for entry in items():
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func category_open(category_id: String, office_id: String) -> bool:
	for cat in categories():
		if str(cat.get("id", "")) != category_id:
			continue
		return _office_rank(office_id) >= _office_rank(str(cat.get("office", "garage")))
	return false


static func _office_rank(office_id: String) -> int:
	var idx := OFFICE_RANK.find(office_id)
	return idx if idx >= 0 else 0


static func search(category_id: String, query: String, office_id: String) -> Array:
	var needle := query.strip_edges().to_lower()
	var found: Array = []
	for entry in items():
		if str(entry.get("category", "")) != category_id:
			continue
		if not category_open(category_id, office_id):
			continue
		if needle == "":
			found.append(entry)
			continue
		var blob := "%s %s" % [str(entry.get("id", "")), str(entry.get("item", ""))]
		var def := ItemDB.get_item(str(entry.get("item", "")))
		blob += " " + str(def.get("name", ""))
		blob += " " + str(entry.get("name", ""))
		for review in entry.get("reviews", []):
			blob += " " + str(review.get("text", ""))
		if needle in blob.to_lower():
			found.append(entry)
	return found


static func list_price(id: String) -> int:
	var entry := sku(id)
	if entry.is_empty():
		return 0
	if int(entry.get("price", 0)) > 0:
		return int(entry.get("price", 0))
	return ItemDB.base_price(str(entry.get("item", "")))


static func deal_skus(day: int) -> Array:
	var pool: Array = []
	for entry in items():
		if bool(entry.get("mystery", false)):
			continue
		pool.append(str(entry.get("id", "")))
	if pool.is_empty():
		return []
	var roller := RandomNumberGenerator.new()
	roller.seed = day * 7919
	var count := mini(int(forest.get("deal_count", 2)), pool.size())
	var picked: Array = []
	var guard := 0
	while picked.size() < count and guard < 30:
		guard += 1
		var id := str(pool[roller.randi() % pool.size()])
		if id not in picked:
			picked.append(id)
	return picked


static func is_deal(id: String, day: int) -> bool:
	return id in deal_skus(day)


static func price_of(id: String, day: int) -> int:
	var price := list_price(id)
	if price <= 0 or not is_deal(id, day):
		return price
	var cut := float(forest.get("deal_discount", 0.25))
	return maxi(1, int(round(float(price) * (1.0 - cut))))


static func shipping(tier: String) -> Dictionary:
	ensure()
	var table: Dictionary = forest.get("shipping", {})
	return table.get(tier, {})


static func prime_def() -> Dictionary:
	ensure()
	return forest.get("prime", {})


static func display_name(id: String) -> String:
	var entry := sku(id)
	if bool(entry.get("mystery", false)):
		return "Mystery box"
	if str(entry.get("name", "")) != "":
		return str(entry.get("name", ""))
	return ItemDB.display_name(str(entry.get("item", id)))


static func fixtures() -> Array:
	ensure()
	return shop.get("fixtures", [])


static func tier_name(tier_id: String) -> String:
	for tier in tiers():
		if str(tier.get("id", "")) == tier_id:
			return str(tier.get("name", tier_id.capitalize()))
	return tier_id.capitalize()


static func ingredients() -> Dictionary:
	ensure()
	return shop.get("ingredients", {})


static func ingredient(id: String) -> Dictionary:
	return ingredients().get(id, {"name": id.capitalize(), "color": "C68B59"})


static func asks() -> Array:
	ensure()
	return shop.get("asks", [])


static func tiers() -> Array:
	ensure()
	return shop.get("tiers", [])


static func menu() -> Array:
	ensure()
	return shop.get("menu", [])


static func menu_item(id: String) -> Dictionary:
	for dish in menu():
		if str(dish.get("id", "")) == id:
			return dish
	return {}


static func visitors() -> Array:
	ensure()
	return shop.get("visitors", [])


static func tags_for(item_id: String) -> Array:
	ensure()
	var table: Dictionary = shop.get("tags", {})
	return table.get(item_id, [])


static func shop_number(key: String, fallback: float) -> float:
	ensure()
	return float(shop.get(key, fallback))
