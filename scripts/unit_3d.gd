extends Node3D
class_name Unit3D

signal clicked(unit_id: String)

const MATS := preload("res://scripts/materials.gd")

var unit_id := ""
var side := "player"
var kind := "warrior"
var base_pos := Vector3.ZERO
var facing := 1.0
var dead := false
var _body: Node3D
var _ring: MeshInstance3D
var _hp_bar: MeshInstance3D
var _hp_fill: MeshInstance3D
var _name: Label3D
var _fx: Label3D
var _tween: Tween
var _outline: StandardMaterial3D

func setup(data: Dictionary) -> void:
	unit_id = data.id
	side = data.side
	kind = str(data.get("class_id", "")) if str(data.get("class_id", "")) != "" else str(data.get("type", "scavenger"))
	facing = 1.0 if side == "player" else -1.0
	base_pos = _slot(data.side, int(data.pos))
	position = base_pos
	rotation.y = 0.0 if side == "player" else PI
	_build_figure()
	_make_ui(data)
	_make_click()
	_sync_hp(data)

func slot_from(data: Dictionary) -> void:
	base_pos = _slot(data.side, int(data.pos))
	if dead:
		return
	if _tween and _tween.is_running():
		return
	position = position.lerp(base_pos, 0.25)

func _slot(s: String, pos: int) -> Vector3:
	var rank := clampf(float(pos), 1.0, 4.0)
	var x := (1.8 + (rank - 1.0) * 1.45)
	if s == "player":
		x = -x
	var z := (rank - 2.5) * 0.35
	return Vector3(x, 0.0, z)

func _mat(color: Color, metallic := 0.15, rough := 0.72) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m

func _tex(name: String, tint := Color.WHITE, metallic := 0.12, rough := 0.74, scale := 1.2) -> StandardMaterial3D:
	return MATS.surf(name, tint, metallic, rough, scale, false)

func _mesh(mi_mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mi_mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	_body.add_child(mi)
	return mi

func _build_figure() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	match kind:
		"warrior":
			_fig_warrior()
		"hunter":
			_fig_hunter()
		"occultist":
			_fig_occultist()
		"wanderer":
			_fig_wanderer()
		"butcher":
			_fig_butcher()
		"ash_keeper":
			_fig_keeper()
		"hierophant":
			_fig_boss()
		"parasite":
			_fig_parasite()
		"cultist":
			_fig_cultist()
		_:
			_fig_scavenger()

func _fig_warrior() -> void:
	var bronze := _tex("bronze", Color("d8b08a"), 0.62, 0.38, 1.6)
	var cloth := _tex("wool", Color("6a4a3a"), 0.04, 0.86, 1.4)
	var skin := _tex("skin", Color("e8c8a8"), 0.0, 0.62, 0.9)
	var iron := _tex("iron", Color("c8c4bc"), 0.82, 0.28, 1.8)
	_mesh(CapsuleMesh.new(), cloth, Vector3(0, 1.05, 0), Vector3(1.15, 0.95, 1.1))
	_mesh(BoxMesh.new(), bronze, Vector3(0, 1.35, 0.05), Vector3(1.25, 0.55, 0.7))
	_mesh(SphereMesh.new(), skin, Vector3(0, 1.85, 0), Vector3(0.7, 0.7, 0.7))
	_mesh(BoxMesh.new(), bronze, Vector3(0, 2.05, 0), Vector3(0.85, 0.28, 0.85))
	_mesh(BoxMesh.new(), bronze, Vector3(-0.55, 1.2, 0.15), Vector3(0.7, 1.1, 0.12))
	_mesh(BoxMesh.new(), iron, Vector3(0.7, 1.35, 0), Vector3(0.08, 1.5, 0.18))
	_mesh(BoxMesh.new(), bronze, Vector3(0.7, 0.7, 0), Vector3(0.22, 0.12, 0.28))

func _fig_hunter() -> void:
	var leather := _tex("leather", Color("c4a07a"), 0.05, 0.7, 1.3)
	var cloak := _tex("wool", Color("5a5048"), 0.02, 0.9, 1.5)
	var skin := _tex("skin", Color("e0c4a4"), 0.0, 0.62, 0.9)
	var wood := _tex("wood", Color("c4b090"), 0.05, 0.7, 1.2)
	_mesh(CapsuleMesh.new(), leather, Vector3(0, 1.1, 0), Vector3(0.85, 1.0, 0.85))
	_mesh(SphereMesh.new(), skin, Vector3(0, 1.95, 0), Vector3(0.58, 0.58, 0.58))
	_mesh(PrismMesh.new(), cloak, Vector3(0, 1.2, -0.28), Vector3(1.1, 1.4, 0.15))
	_mesh(CylinderMesh.new(), wood, Vector3(0.45, 1.3, 0.1), Vector3(0.08, 1.15, 0.08))
	_mesh(BoxMesh.new(), leather, Vector3(0.55, 1.85, 0.05), Vector3(0.08, 0.55, 0.35))

func _fig_occultist() -> void:
	var robe := _tex("wool", Color("4a4440"), 0.04, 0.88, 1.5)
	var ash := _tex("stone", Color("8a8278"), 0.08, 0.86, 1.4)
	_mesh(CapsuleMesh.new(), robe, Vector3(0, 1.2, 0), Vector3(0.9, 1.15, 0.9))
	_mesh(CylinderMesh.new(), ash, Vector3(0, 2.05, 0), Vector3(0.85, 0.45, 0.85))
	_mesh(SphereMesh.new(), _tex("bone", Color("c8bca8"), 0.05, 0.55, 0.8), Vector3(0, 1.88, 0.12), Vector3(0.42, 0.42, 0.42))
	_mesh(CylinderMesh.new(), _tex("wood", Color("b8a078"), 0.1, 0.6, 1.0), Vector3(-0.55, 1.35, 0), Vector3(0.07, 1.4, 0.07))
	_mesh(SphereMesh.new(), MATS.emit("iron", Color("c45c3a"), 2.6, 0.6), Vector3(-0.55, 2.15, 0), Vector3(0.18, 0.18, 0.18))

func _fig_wanderer() -> void:
	var cloth := _tex("wool", Color("8a8c6a"), 0.04, 0.86, 1.4)
	var skin := _tex("skin", Color("f0d2b0"), 0.0, 0.6, 0.9)
	var wood := _tex("wood", Color("d4c08a"), 0.08, 0.55, 1.1)
	_mesh(CapsuleMesh.new(), cloth, Vector3(0, 1.08, 0), Vector3(0.9, 0.95, 0.9))
	_mesh(SphereMesh.new(), skin, Vector3(0, 1.9, 0), Vector3(0.6, 0.6, 0.6))
	_mesh(CylinderMesh.new(), _tex("leather", Color("c4a070"), 0.05, 0.7, 1.0), Vector3(0, 2.18, 0), Vector3(0.7, 0.12, 0.7))
	_mesh(CylinderMesh.new(), wood, Vector3(0.5, 1.25, 0), Vector3(0.07, 1.25, 0.07))
	_mesh(SphereMesh.new(), MATS.emit("stone", Color("5a8f72"), 1.8, 0.7), Vector3(0.5, 2.0, 0), Vector3(0.16, 0.16, 0.16))

func _fig_scavenger() -> void:
	var hide := _tex("leather", Color("8a6a50"), 0.04, 0.78, 1.3)
	var bone := _tex("bone", Color("e8dcc4"), 0.12, 0.45, 1.0)
	_mesh(CapsuleMesh.new(), hide, Vector3(0, 0.75, 0), Vector3(0.95, 0.7, 1.1))
	_mesh(SphereMesh.new(), hide, Vector3(0.15, 1.25, 0.25), Vector3(0.55, 0.45, 0.7))
	_mesh(BoxMesh.new(), bone, Vector3(0.45, 0.7, 0.3), Vector3(0.12, 0.08, 0.55))
	_mesh(BoxMesh.new(), bone, Vector3(-0.35, 0.7, 0.3), Vector3(0.12, 0.08, 0.55))

func _fig_cultist() -> void:
	var robe := _tex("wool", Color("4a3c36"), 0.04, 0.9, 1.5)
	var mask := _tex("bone", Color("d4c4a8"), 0.08, 0.5, 0.9)
	_mesh(CapsuleMesh.new(), robe, Vector3(0, 1.1, 0), Vector3(0.95, 1.05, 0.95))
	_mesh(SphereMesh.new(), _tex("wool", Color("2a2420"), 0.02, 0.9, 1.0), Vector3(0, 1.95, 0), Vector3(0.55, 0.55, 0.55))
	_mesh(BoxMesh.new(), mask, Vector3(0, 1.95, 0.22), Vector3(0.45, 0.35, 0.08))
	_mesh(CylinderMesh.new(), _tex("wood", Color("b8a078"), 0.08, 0.65, 1.0), Vector3(0.4, 1.15, 0), Vector3(0.06, 1.1, 0.06))

func _fig_butcher() -> void:
	var meat := _tex("leather", Color("8a4030"), 0.05, 0.72, 1.4)
	var iron := _tex("iron", Color("c0b8b0"), 0.75, 0.32, 1.8)
	var skin := _tex("skin", Color("c08060"), 0.0, 0.65, 0.9)
	_mesh(CapsuleMesh.new(), meat, Vector3(0, 1.25, 0), Vector3(1.35, 1.05, 1.2))
	_mesh(SphereMesh.new(), skin, Vector3(0, 2.15, 0), Vector3(0.7, 0.6, 0.7))
	_mesh(BoxMesh.new(), iron, Vector3(0.85, 1.55, 0), Vector3(0.12, 1.7, 0.45))
	_mesh(BoxMesh.new(), iron, Vector3(0.85, 0.75, 0), Vector3(0.2, 0.15, 0.2))

func _fig_parasite() -> void:
	var chitin := _tex("chitin", Color("8aa878"), 0.18, 0.38, 1.6)
	_mesh(SphereMesh.new(), chitin, Vector3(0, 0.55, 0), Vector3(1.1, 0.7, 1.4))
	_mesh(SphereMesh.new(), chitin, Vector3(0.35, 0.85, 0.4), Vector3(0.5, 0.4, 0.55))
	for i in 4:
		var leg := _mesh(CylinderMesh.new(), chitin, Vector3(-0.4 + i * 0.25, 0.25, 0.45), Vector3(0.06, 0.55, 0.06))
		leg.rotation_degrees.z = 35 if i % 2 == 0 else -35

func _fig_keeper() -> void:
	var stone := _tex("stone", Color("c4b8a8"), 0.05, 0.9, 1.8)
	_mesh(BoxMesh.new(), stone, Vector3(0, 1.2, 0), Vector3(1.3, 2.2, 0.9))
	_mesh(BoxMesh.new(), stone, Vector3(0, 2.4, 0), Vector3(1.0, 0.45, 1.0))
	_mesh(SphereMesh.new(), MATS.emit("iron", Color("c45c3a"), 3.2, 0.8), Vector3(0, 1.35, 0.4), Vector3(0.35, 0.35, 0.2))

func _fig_boss() -> void:
	var ash := _tex("wool", Color("5a5048"), 0.06, 0.85, 1.6)
	var gold := _tex("bronze", Color("e8d09a"), 0.7, 0.32, 1.4)
	var mask := _tex("bone", Color("d8c8b0"), 0.08, 0.5, 0.9)
	_mesh(CapsuleMesh.new(), ash, Vector3(0, 1.55, 0), Vector3(1.2, 1.4, 1.2))
	_mesh(SphereMesh.new(), mask, Vector3(0, 2.7, 0), Vector3(0.85, 0.85, 0.85))
	_mesh(BoxMesh.new(), gold, Vector3(0, 2.7, 0.38), Vector3(0.7, 0.55, 0.1))
	_mesh(CylinderMesh.new(), gold, Vector3(0, 3.15, 0), Vector3(0.7, 0.2, 0.7))
	_mesh(SphereMesh.new(), MATS.emit("iron", Color("c45c3a"), 4.0, 0.7), Vector3(0, 3.45, 0), Vector3(0.28, 0.4, 0.28))
	_mesh(CylinderMesh.new(), _tex("wood", Color("b8a078"), 0.08, 0.65, 1.0), Vector3(-0.7, 1.6, 0), Vector3(0.1, 1.7, 0.1))

func _make_ui(data: Dictionary) -> void:
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.55
	_ring.mesh = torus
	_outline = _mat(Color("c4a35a"), 0.0, 0.4)
	_outline.emission_enabled = true
	_outline.emission = Color("c4a35a")
	_outline.emission_energy_multiplier = 1.8
	_ring.material_override = _outline
	_ring.position = Vector3(0, 0.05, 0)
	_ring.visible = false
	add_child(_ring)
	_name = Label3D.new()
	_name.text = str(data.name)
	_name.font_size = 42
	_name.pixel_size = 0.012
	_name.position = Vector3(0, _head_y() + 0.35, 0)
	_name.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name.modulate = Color("e8dcc8")
	_name.outline_modulate = Color("0c0b0a")
	_name.outline_size = 8
	add_child(_name)
	_hp_bar = MeshInstance3D.new()
	_hp_bar.mesh = BoxMesh.new()
	_hp_bar.scale = Vector3(0.9, 0.06, 0.06)
	_hp_bar.position = Vector3(0, _head_y() + 0.18, 0)
	_hp_bar.material_override = _mat(Color("1a1210"))
	add_child(_hp_bar)
	_hp_fill = MeshInstance3D.new()
	_hp_fill.mesh = BoxMesh.new()
	_hp_fill.material_override = _mat(Color("b54a3a") if side == "player" else Color("8a4030"))
	_hp_bar.add_child(_hp_fill)
	_fx = Label3D.new()
	_fx.font_size = 64
	_fx.pixel_size = 0.014
	_fx.position = Vector3(0, _head_y() + 0.7, 0)
	_fx.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_fx.modulate = Color("c45c3a")
	_fx.visible = false
	add_child(_fx)

func _head_y() -> float:
	match kind:
		"hierophant":
			return 3.2
		"ash_keeper":
			return 2.6
		"butcher":
			return 2.4
		"parasite", "scavenger":
			return 1.35
		_:
			return 2.15

func _make_click() -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shp := CapsuleShape3D.new()
	shp.radius = 0.55
	shp.height = 2.2
	col.shape = shp
	col.position = Vector3(0, 1.1, 0)
	body.add_child(col)
	body.input_ray_pickable = true
	body.collision_layer = 1
	body.input_event.connect(_on_input)
	add_child(body)

func _on_input(_cam, event, _pos, _normal, _shape) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(unit_id)

func _sync_hp(data: Dictionary) -> void:
	var pct := clampf(float(data.hp) / maxf(1.0, float(data.max_hp)), 0.0, 1.0)
	_hp_fill.scale = Vector3(pct, 1.0, 1.0)
	_hp_fill.position.x = (pct - 1.0) * 0.5

func sync(data: Dictionary, is_turn: bool, can_target: bool) -> void:
	if data.alive and dead:
		dead = false
		rotation = Vector3(0, 0.0 if side == "player" else PI, 0)
		position = base_pos
		_body.rotation = Vector3.ZERO
	if not data.alive and not dead:
		play_death()
	_sync_hp(data)
	_ring.visible = is_turn or can_target
	if is_turn:
		_outline.emission = Color("c4a35a")
		_outline.albedo_color = Color("c4a35a")
	elif can_target:
		_outline.emission = Color("c45c3a")
		_outline.albedo_color = Color("c45c3a")
	_name.modulate = Color("c4a35a") if is_turn else Color("e8dcc8")
	if not dead:
		slot_from(data)

func show_fx(text: String, kind: String) -> void:
	_fx.text = text
	_fx.visible = true
	_fx.modulate = Color("c4a35a") if kind == "crit" else (Color("5a8f72") if kind == "heal" else Color("c45c3a"))
	_fx.position.y = _head_y() + 0.55
	_fx.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fx, "position:y", _head_y() + 1.1, 0.7)
	tw.parallel().tween_property(_fx, "modulate:a", 0.0, 0.7)
	tw.tween_callback(func(): _fx.visible = false)

func play_lunge(target: Vector3) -> void:
	if dead:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var mid := base_pos.lerp(target, 0.45) + Vector3(0, 0.15, 0)
	_tween.tween_property(self, "position", mid, 0.16).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "position", base_pos, 0.22).set_trans(Tween.TRANS_QUAD)

func play_hit() -> void:
	if dead:
		return
	var tw := create_tween()
	tw.tween_property(_body, "rotation_degrees:z", 12.0 * -facing, 0.07)
	tw.tween_property(_body, "rotation_degrees:z", 0.0, 0.12)

func play_death() -> void:
	dead = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation_degrees:z", 85.0 * facing, 0.45).set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(self, "position:y", 0.15, 0.45)
	_ring.visible = false
