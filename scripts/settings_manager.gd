class_name SettingsManager
extends RefCounted

const UiLib = preload("res://scripts/ui_kit.gd")

const PRESET_DIR := "res://beauty/"


static func normalize(tier: String) -> String:
	var name := tier.to_lower()
	if name == "low" or name == "high":
		return name
	return "medium"


static func load_environment(tier: String) -> Environment:
	var name := normalize(tier)
	var path := "%sbeauty_env_%s.tres" % [PRESET_DIR, name]
	if ResourceLoader.exists(path):
		var loaded := load(path) as Environment
		if loaded != null:
			return loaded.duplicate(true) as Environment
	return make_environment(name)


static func menu_dof() -> CameraAttributesPractical:
	var path := PRESET_DIR + "menu_camera_dof.tres"
	if ResourceLoader.exists(path):
		var loaded := load(path) as CameraAttributesPractical
		if loaded != null:
			return loaded.duplicate(true) as CameraAttributesPractical
	return make_menu_dof()


static func make_environment(tier: String) -> Environment:
	var name := normalize(tier)
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("3E3A4F")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("F2E2CC")
	world.ambient_light_energy = 0.25
	world.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.tonemap_exposure = 0.85
	world.tonemap_white = 4.0
	world.tonemap_agx_white = 4.0
	world.adjustment_enabled = true
	world.adjustment_brightness = 1.0
	world.adjustment_contrast = 1.2
	world.adjustment_saturation = 1.08
	world.fog_enabled = false
	world.ssao_radius = 0.8
	world.ssao_intensity = 1.5
	world.ssao_power = 1.3
	world.ssao_detail = 0.5
	world.ssao_horizon = 0.06
	world.ssao_sharpness = 0.98
	world.ssao_light_affect = 0.2
	world.ssil_radius = 3.0
	world.ssil_intensity = 0.6
	world.sdfgi_enabled = false
	world.glow_intensity = 0.4
	world.glow_strength = 0.8
	world.glow_bloom = 0.05
	world.glow_hdr_threshold = 1.1
	world.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	for level in range(1, 8):
		var lit := level >= 2 and level <= 4
		world.set("glow_levels/%d" % level, 1.0 if lit else 0.0)
	world.ssao_enabled = name != "low"
	world.glow_enabled = name != "low"
	world.ssil_enabled = name == "high"
	return world


static func make_menu_dof() -> CameraAttributesPractical:
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_distance = 14.0
	attr.dof_blur_far_transition = 6.0
	attr.dof_blur_amount = 0.06
	return attr


static func apply_tier(tree: SceneTree, tier: String) -> void:
	var name := normalize(tier)
	var msaa := Viewport.MSAA_2X
	var aa := Viewport.SCREEN_SPACE_AA_DISABLED
	var shadow_size := 2048
	var soft := 2
	if name == "low":
		msaa = Viewport.MSAA_DISABLED
		aa = Viewport.SCREEN_SPACE_AA_FXAA
		shadow_size = 2048
		soft = 1
	elif name == "high":
		msaa = Viewport.MSAA_4X
		aa = Viewport.SCREEN_SPACE_AA_DISABLED
		shadow_size = 4096
		soft = 3
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", int(msaa))
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa", int(aa))
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", shadow_size)
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", soft)
	if tree != null and tree.root != null:
		tree.root.msaa_3d = msaa
		tree.root.screen_space_aa = aa
	RenderingServer.directional_shadow_atlas_set_size(shadow_size, true)
	if tree == null or tree.root == null:
		return
	var dof := menu_dof()
	for node in tree.root.find_children("*", "WorldEnvironment", true, false):
		var world_env := node as WorldEnvironment
		if world_env == null:
			continue
		var world := load_environment(name)
		var parent := world_env.get_parent()
		if parent != null and bool(parent.get("backdrop")):
			world.background_color = UiLib.CREAM
			var cam := parent.get("cam") as Camera3D
			if cam != null:
				cam.attributes = dof
		world_env.environment = world
