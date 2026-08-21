extends Node3D
class_name CombatWorld

signal unit_clicked(id: String)

const MATS := preload("res://scripts/materials.gd")

var units: Dictionary = {}
var cam: Camera3D
var last_anim := ""
var _shake := 0.0
var _cam_base := Vector3(0.15, 3.6, 8.6)

func _ready() -> void:
	_build_arena()
	_build_camera()
	_build_lights()
	_build_particles()

func _build_camera() -> void:
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 42.0
	cam.position = _cam_base
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)

func _build_lights() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("0d0b0a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("3a322c")
	e.ambient_light_energy = 0.85
	e.fog_enabled = true
	e.fog_light_color = Color("1a1612")
	e.fog_density = 0.018
	e.fog_aerial_perspective = 0.4
	e.glow_enabled = true
	e.glow_intensity = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("c4a88a")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48, 35, 0)
	add_child(sun)
	var ember := OmniLight3D.new()
	ember.light_color = Color("c45c3a")
	ember.light_energy = 6.0
	ember.omni_range = 14.0
	ember.position = Vector3(0, 2.8, 1.5)
	add_child(ember)
	var rim := OmniLight3D.new()
	rim.light_color = Color("7d93a6")
	rim.light_energy = 2.2
	rim.omni_range = 10.0
	rim.position = Vector3(0, 3.5, -4.0)
	add_child(rim)

func _ground_mat(color: Color, rough := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.02
	return m

func _box(size: Vector3, pos: Vector3, mat: Material, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	add_child(mi)
	return mi

func _build_arena() -> void:
	var ash: StandardMaterial3D = MATS.surf("ash", Color("c8c0b4"), 0.02, 0.95, 0.35, true)
	var stone: StandardMaterial3D = MATS.surf("stone", Color("b8b0a4"), 0.04, 0.9, 0.28, true)
	var rust: StandardMaterial3D = MATS.surf("iron", Color("c4a090"), 0.35, 0.62, 0.45, true)
	var dark: StandardMaterial3D = MATS.surf("stone", Color("6a645c"), 0.04, 0.92, 0.18, true)
	# road
	_box(Vector3(22, 0.12, 7.2), Vector3(0, -0.06, 0.4), ash)
	# shoulders
	_box(Vector3(22, 0.4, 3.0), Vector3(0, 0.05, 4.4), stone)
	_box(Vector3(22, 0.55, 3.5), Vector3(0, 0.1, -4.6), stone)
	# cracked slabs on the road
	for i in 8:
		_box(Vector3(1.6 + (i % 3) * 0.2, 0.08, 1.1), Vector3(-8 + i * 2.2, 0.02, 0.3 + (i % 2) * 0.4), stone, 0.08 * (i - 4))
	# ruined pillars
	for p in [Vector3(-7.5, 1.4, -3.2), Vector3(7.2, 1.6, -3.4), Vector3(-4.2, 0.9, 3.6), Vector3(5.8, 1.1, 3.8), Vector3(0.2, 1.8, -5.2)]:
		_box(Vector3(0.7, p.y * 2.0, 0.7), Vector3(p.x, p.y, p.z), stone, 0.2)
	# fallen column
	_box(Vector3(4.5, 0.55, 0.55), Vector3(2.8, 0.35, -2.4), stone, 0.7)
	# altar ruin center-back
	_box(Vector3(2.4, 0.4, 1.6), Vector3(0, 0.25, -3.8), rust)
	_box(Vector3(0.35, 1.6, 0.35), Vector3(-0.8, 1.0, -3.8), rust)
	_box(Vector3(0.35, 1.1, 0.35), Vector3(0.9, 0.75, -3.5), rust)
	# distant wall
	_box(Vector3(24, 6.0, 0.8), Vector3(0, 2.5, -7.4), dark)
	# ember brazier
	_box(Vector3(0.7, 0.5, 0.7), Vector3(0, 0.4, 2.6), rust)
	var flame := MeshInstance3D.new()
	flame.mesh = SphereMesh.new()
	flame.material_override = MATS.emit("iron", Color("c45c3a"), 5.0, 0.8)
	flame.position = Vector3(0, 1.05, 2.6)
	flame.scale = Vector3(0.35, 0.5, 0.35)
	add_child(flame)

func _build_particles() -> void:
	var p := GPUParticles3D.new()
	p.amount = 80
	p.lifetime = 6.0
	p.preprocess = 2.0
	p.position = Vector3(0, 4.5, 1)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.15, -1, 0.05)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 1.1
	mat.gravity = Vector3(0, -0.15, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color("8a8174", 0.7)
	p.process_material = mat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.08, 0.08)
	p.draw_pass_1 = qm
	add_child(p)

func bind_combat(c: Dictionary) -> void:
	for id in units.keys():
		var found := false
		for u in c.units:
			if u.id == id:
				found = true
				break
		if not found:
			units[id].queue_free()
			units.erase(id)
	for u in c.units:
		if not units.has(u.id):
			var n := Unit3D.new()
			n.setup(u)
			n.clicked.connect(func(id): unit_clicked.emit(id))
			add_child(n)
			units[u.id] = n
	refresh(c)

func refresh(c: Dictionary) -> void:
	var actor_id := ""
	if c.turn >= 0 and c.turn < c.order.size():
		actor_id = c.order[c.turn]
	var tset := {}
	if c.waiting and str(c.selected) != "" and Game.engine.SKILLS.has(c.selected):
		var actor
		for u in c.units:
			if u.id == actor_id:
				actor = u
		if actor != null:
			for t in Game.engine.valid_targets(actor, Game.engine.SKILLS[c.selected], c):
				tset[t.id] = true
	for u in c.units:
		if not units.has(u.id):
			continue
		var n: Unit3D = units[u.id]
		n.sync(u, u.id == actor_id, tset.has(u.id))
	_play_anims(c)

func _play_anims(c: Dictionary) -> void:
	var key := str(c.get("anim_key", ""))
	if key == "" or key == last_anim:
		return
	last_anim = key
	var actor_id := str(c.get("attacker", ""))
	if units.has(actor_id):
		var tgt := Vector3.ZERO
		var has_tgt := false
		for f in c.fx:
			if f.who != actor_id and units.has(f.who):
				tgt = units[f.who].global_position
				has_tgt = true
				units[f.who].play_hit()
				units[f.who].show_fx(str(f.text), str(f.kind))
		if has_tgt:
			units[actor_id].play_lunge(tgt)
		else:
			units[actor_id].play_lunge(Vector3.ZERO)
	else:
		for f in c.fx:
			if units.has(f.who):
				units[f.who].show_fx(str(f.text), str(f.kind))
				if str(f.kind) in ["dmg", "crit"]:
					units[f.who].play_hit()
	if c.fx.any(func(f): return str(f.text) == "Смерть"):
		_shake = 0.35

func _process(d: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - d)
		cam.position = _cam_base + Vector3(randf_range(-0.08, 0.08), randf_range(-0.05, 0.05), 0) * (_shake * 3.0)
	else:
		cam.position = cam.position.lerp(_cam_base, 1.0 - exp(-d * 8.0))
