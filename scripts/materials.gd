class_name Mats
extends RefCounted

static var cache := {}

static func tex(name: String) -> Texture2D:
	if cache.has(name):
		return cache[name]
	var path := "res://assets/textures/%s.jpg" % name
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	cache[name] = t
	return t

static func surf(tex_name: String, tint: Color = Color.WHITE, metallic := 0.12, rough := 0.74, scale := 1.35, world := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	var t := tex(tex_name)
	if t:
		m.albedo_texture = t
	m.metallic = metallic
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 6.0
	m.uv1_world_triplanar = world
	m.uv1_scale = Vector3(scale, scale, scale)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m

static func emit(tex_name: String, tint: Color, energy := 2.4, scale := 1.0) -> StandardMaterial3D:
	var m := surf(tex_name, tint, 0.0, 0.4, scale)
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = energy
	return m
