class_name MakeCard
extends PanelContainer

## Making an order by hand: tap the ingredients into the cup or onto the
## plate in the recipe's order. A clean make earns a bigger tip, slips cost
## a little, and the till can always do it for you at half the tip.

signal finished(result: Dictionary)

const UIKit = preload("res://scripts/ui_kit.gd")
const Catalog = preload("res://scripts/catalog.gd")

const CUP_SIZE := Vector2(220, 300)
const PLATE_SIZE := Vector2(320, 220)
const PERFECT_MULT := 1.3
const SLIP_MULT := 0.85
# What each ingredient sounds like going in; anything else pours.
const TAP_SFX := {
	"espresso": "sfx_espresso_pull", "drip": "sfx_drip_brew", "cold_brew": "sfx_drip_brew", "foam": "sfx_milk_foam", "oat_milk": "sfx_milk_steam",
	"ice": "sfx_ice_clink", "lemon": "sfx_lemon_squeeze", "sugar": "sfx_sugar_pour", "tea": "sfx_tea_steep", "mint": "sfx_muddle",
	"caramel": "sfx_syrup_drizzle", "jam": "sfx_syrup_drizzle", "cream": "sfx_whip_topping", "ice_cream": "sfx_whip_topping",
	"cup": "sfx_cup_set_down", "glass": "sfx_cup_set_down", "plate": "sfx_cup_set_down", "water": "sfx_pour", "soup": "sfx_pour",
	"custard": "sfx_spoon_stir", "hollandaise": "sfx_spoon_stir", "garlic_sauce": "sfx_spoon_stir", "mayo": "sfx_spoon_stir",
}

var dish: Dictionary = {}
var recipe: Array = []
var step := 0
var slips := 0
var done := false
var vessel: Control
var layers: Array = []
var step_labels: Array = []
var tray: Array = []
var serve_button: Button
var status_label: Label


func setup(dish_def: Dictionary, who: String, seed: int) -> void:
	dish = dish_def
	recipe = []
	for ing in dish.get("recipe", []):
		recipe.append(str(ing))
	name = "MakeCard"
	add_theme_stylebox_override("panel", UIKit.style(UIKit.CREAM_CARD, 20, 4, UIKit.MUSTARD))
	layout_mode = 1
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	offset_left = -520
	offset_right = 520
	offset_top = -300
	offset_bottom = 300
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	# Head: who wants what.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	column.add_child(head)
	head.add_child(UIKit.ribbon("Make it", UIKit.MUSTARD, 34, UIKit.DARK))
	var order_line := UIKit.label("%s for %s" % [dish.get("name", "the order"), who], 30, UIKit.DARK, "title", false)
	order_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	order_line.custom_minimum_size = Vector2(560, 48)
	head.add_child(order_line)
	# Body: the vessel on the left, the recipe on the right.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var is_cup := _is_cup()
	var vessel_box := CenterContainer.new()
	vessel_box.custom_minimum_size = Vector2(360, 300)
	body.add_child(vessel_box)
	vessel = Panel.new()
	vessel.name = "Vessel"
	vessel.custom_minimum_size = CUP_SIZE if is_cup else PLATE_SIZE
	var shell := UIKit.style(Color("FFFDF6"), 26 if is_cup else 110, 5, UIKit.OUTLINE)
	if is_cup:
		shell.corner_radius_top_left = 8
		shell.corner_radius_top_right = 8
	shell.shadow_size = 2
	vessel.add_theme_stylebox_override("panel", shell)
	vessel.clip_contents = true
	vessel_box.add_child(vessel)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	var recipe_head := UIKit.label("Recipe, in order", 26, UIKit.WOOD, "small", false)
	side.add_child(recipe_head)
	for i in recipe.size():
		var ing := Catalog.ingredient(recipe[i])
		var row := UIKit.label("○  %d. %s" % [i + 1, ing.get("name", recipe[i])], 28, UIKit.DARK, "small", false)
		row.name = "Step%d" % i
		step_labels.append(row)
		side.add_child(row)
	status_label = UIKit.label("Tap the ingredients in order. Slips cost a little tip.", 26, UIKit.BLUE, "small")
	status_label.name = "MakeStatus"
	status_label.custom_minimum_size = Vector2(540, 0)
	side.add_child(status_label)
	# Tray: the recipe plus two red herrings, shuffled.
	var ids: Array = recipe.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var extras: Array = Catalog.ingredients().keys()
	extras.shuffle()
	var added := 0
	var k := rng.randi() % maxi(1, extras.size())
	for n in extras.size():
		var cand := str(extras[(k + n) % extras.size()])
		if ids.has(cand):
			continue
		ids.append(cand)
		added += 1
		if added >= 2:
			break
	# A seeded shuffle, so a test can read the tray back.
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	var tray_row := HFlowContainer.new()
	tray_row.add_theme_constant_override("h_separation", 10)
	tray_row.add_theme_constant_override("v_separation", 10)
	column.add_child(tray_row)
	for ing_id in ids:
		var ing := Catalog.ingredient(str(ing_id))
		var fill := Color(str(ing.get("color", "C68B59")))
		var fg: Color = UIKit.DARK if fill.get_luminance() > 0.55 else UIKit.CREAM_CARD
		var btn := UIKit.button(str(ing.get("name", ing_id)), fill, fg)
		btn.name = "Ing_" + str(ing_id)
		btn.custom_minimum_size = Vector2(180, 56)
		btn.pressed.connect(_tap.bind(str(ing_id)))
		tray_row.add_child(btn)
		tray.append(btn)
	# Foot: serve when it is done, or hand it to the till.
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	column.add_child(foot)
	serve_button = UIKit.button("Serve it", UIKit.SAGE)
	serve_button.name = "MakeServe"
	serve_button.custom_minimum_size = Vector2(220, 56)
	serve_button.disabled = true
	serve_button.pressed.connect(_serve)
	foot.add_child(serve_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	var till := UIKit.button("Let the till do it (half tip)", UIKit.WOOD)
	till.name = "MakeTill"
	till.custom_minimum_size = Vector2(380, 56)
	till.pressed.connect(func(): _finish(false))
	foot.add_child(till)
	var focus_list: Array = tray.duplicate()
	focus_list.append(serve_button)
	focus_list.append(till)
	UIKit.link_focus(focus_list)


func _is_cup() -> bool:
	return str(dish.get("tag", "")) in ["coffee", "juice"] or str(dish.get("vessel", "")) == "cup"


func _tap(ing_id: String) -> void:
	if done:
		return
	if step < recipe.size() and recipe[step] == ing_id:
		_add_layer(ing_id)
		var row: Label = step_labels[step]
		row.text = "●" + row.text.substr(1)
		row.add_theme_color_override("font_color", UIKit.SAGE.darkened(0.25))
		step += 1
		AudioDirector.play_sfx(str(TAP_SFX.get(ing_id, "sfx_items_grab")), true)
		if step >= recipe.size():
			serve_button.disabled = false
			status_label.text = "Perfect. Serve it!" if slips == 0 else "Done, with %d slip%s. Serve it." % [slips, "" if slips == 1 else "s"]
			serve_button.grab_focus()
		else:
			status_label.text = "Next: %s" % Catalog.ingredient(recipe[step]).get("name", recipe[step])
	else:
		slips += 1
		AudioDirector.play_sfx("sfx_invalid_placement")
		var wanted := "nothing"
		if step < recipe.size():
			wanted = str(Catalog.ingredient(recipe[step]).get("name", recipe[step]))
		status_label.text = "Not that one. The recipe wants %s next." % wanted
		var tw := create_tween()
		tw.tween_property(vessel, "position:x", vessel.position.x + 8, 0.05)
		tw.tween_property(vessel, "position:x", vessel.position.x - 8, 0.05)
		tw.tween_property(vessel, "position:x", vessel.position.x, 0.05)


func _add_layer(ing_id: String) -> void:
	var ing := Catalog.ingredient(ing_id)
	var is_cup := _is_cup()
	var size: Vector2 = CUP_SIZE if is_cup else PLATE_SIZE
	var count := recipe.size()
	var height := (size.y - 24.0) / float(maxi(count, 1))
	var layer := ColorRect.new()
	layer.name = "Layer_" + ing_id
	layer.color = Color(str(ing.get("color", "C68B59")))
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var index := layers.size()
	if is_cup:
		layer.size = Vector2(size.x - 20.0, height)
		layer.position = Vector2(10.0, size.y - 12.0 - height * float(index + 1))
	else:
		# Plate: each thing is a little smaller than the one under it, like a stack.
		var shrink := float(index) * 14.0
		layer.size = Vector2(size.x - 60.0 - shrink, height)
		layer.position = Vector2(30.0 + shrink * 0.5, size.y - 16.0 - height * float(index + 1))
	vessel.add_child(layer)
	layers.append(layer)
	var pop := create_tween()
	layer.scale = Vector2(1.0, 0.2)
	layer.pivot_offset = Vector2(layer.size.x * 0.5, layer.size.y)
	pop.tween_property(layer, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _serve() -> void:
	if step < recipe.size():
		return
	_finish(true)


func _finish(by_hand: bool) -> void:
	if done:
		return
	done = true
	var mult := 1.0
	if by_hand:
		mult = PERFECT_MULT if slips == 0 else (1.0 if slips == 1 else SLIP_MULT)
		AudioDirector.play_sfx("sfx_cup_set_down")
		if slips == 0:
			AudioDirector.play_sfx("sfx_tip_jar_coin")
	emit_signal("finished", {"by_hand": by_hand, "slips": slips, "tip_mult": mult, "perfect": by_hand and slips == 0})
	queue_free()


static func tray_ids(card: Node) -> Array:
	var out: Array = []
	for btn in card.find_children("Ing_*", "Button", true, false):
		out.append(str(btn.name).trim_prefix("Ing_"))
	return out
