extends Control

const BG := Color("0c0b0a")
const SURFACE := Color("161310")
const RAISED := Color("1f1a16")
const FG := Color("e8dcc8")
const MUTED := Color("8a8174")
const BORDER := Color("3a332c")
const EMBER := Color("c45c3a")
const GOLD := Color("c4a35a")
const HEAL := Color("5a8f72")
const STRESS_C := Color("7d93a6")
const HP_C := Color("b54a3a")

var root: VBoxContainer
var content: Control
var toast_lbl: Label
var enemy_timer := 0.0
var combat_layer: Control
var combat_world: CombatWorld
var combat_hud: Control
var header_bar: Control
var body_font: Font
var display_font: Font

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	body_font = load("res://assets/fonts/EBGaramond-Regular.ttf")
	display_font = load("res://assets/fonts/Cinzel-SemiBold.ttf")
	if body_font:
		theme = _make_theme()
	Game.changed.connect(_on_changed)
	_build_shell()
	_on_changed()

func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = body_font
	th.set_default_font_size(18)
	th.set_color("font_color", "Label", FG)
	th.set_color("font_color", "Button", FG)
	th.set_font("font", "Label", body_font)
	th.set_font("font", "Button", body_font)
	return th

func _process(d: float) -> void:
	if Game.screen != "combat" or Game.combat == null:
		enemy_timer = 0.0
		return
	var c: Dictionary = Game.combat
	if c.finished != "none" or c.waiting:
		enemy_timer = 0.0
		return
	enemy_timer += d
	if enemy_timer >= 0.7:
		enemy_timer = 0.0
		Game.enemy_turn()

func _on_changed() -> void:
	if toast_lbl:
		toast_lbl.text = Game.toast
		toast_lbl.visible = Game.toast != ""
	var in_combat := Game.screen == "combat" and Game.combat != null
	if combat_layer:
		combat_layer.visible = in_combat
	if content:
		content.visible = not in_combat
	if header_bar:
		header_bar.visible = Game.screen not in ["title", "combat"]
	if in_combat:
		_update_combat()
	else:
		_rebuild()

func _update_combat() -> void:
	combat_world.bind_combat(Game.combat)
	for ch in combat_hud.get_children():
		ch.queue_free()
	_fill_combat_hud(Game.combat)

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	root = VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	var m := MarginContainer.new()
	m.set_anchors_preset(PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 0)
	m.add_theme_constant_override("margin_right", 0)
	m.add_theme_constant_override("margin_top", 0)
	m.add_theme_constant_override("margin_bottom", 0)
	add_child(m)
	m.add_child(root)
	header_bar = _header()
	root.add_child(header_bar)
	var stack := Control.new()
	stack.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(stack)
	content = Control.new()
	content.set_anchors_preset(PRESET_FULL_RECT)
	stack.add_child(content)
	combat_layer = Control.new()
	combat_layer.set_anchors_preset(PRESET_FULL_RECT)
	combat_layer.visible = false
	stack.add_child(combat_layer)
	_build_combat_layer()
	toast_lbl = Label.new()
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_color_override("font_color", GOLD)
	toast_lbl.visible = false
	root.add_child(toast_lbl)

func _build_combat_layer() -> void:
	var vp_wrap := SubViewportContainer.new()
	vp_wrap.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vp_wrap.stretch = true
	vp_wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var vp := SubViewport.new()
	vp.transparent_bg = false
	vp.handle_input_locally = true
	vp.physics_object_picking = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1280, 720)
	vp_wrap.add_child(vp)
	combat_world = CombatWorld.new()
	combat_world.unit_clicked.connect(func(id): Game.select_target(id))
	vp.add_child(combat_world)
	combat_layer.add_child(vp_wrap)
	combat_hud = Control.new()
	combat_hud.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	combat_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_layer.add_child(combat_hud)

func _header() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var pad := MarginContainer.new()
	# wrapper via offsets on children
	h.custom_minimum_size = Vector2(0, 48)
	var t := Button.new()
	t.text = "ASHEN ROAD"
	t.flat = true
	_style_btn(t, GOLD, Color.TRANSPARENT)
	if display_font:
		t.add_theme_font_override("font", display_font)
	t.pressed.connect(func():
		if Game.screen in ["title", "combat", "event", "reward", "result", "map"]:
			return
		Game.set_screen("town")
	)
	h.add_child(t)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(sp)
	var gold := Label.new()
	gold.name = "GoldLbl"
	gold.add_theme_color_override("font_color", GOLD)
	h.add_child(gold)
	h.add_child(_small_btn("Сохранить", Game.save_game))
	h.add_child(_small_btn("Загрузить", func(): Game.load_game()))
	h.add_child(_small_btn("Новая", func(): Game.new_game(true)))
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 18)
	wrap.add_theme_constant_override("margin_right", 18)
	wrap.add_theme_constant_override("margin_top", 8)
	wrap.add_theme_constant_override("margin_bottom", 4)
	wrap.add_child(h)
	# return inner; caller needs header_bar as the wrap for visibility
	# Can't nest easily. Return h; shell already added margins via... we'll keep h.
	return h

func _rebuild() -> void:
	var gl: Label = header_bar.get_node_or_null("GoldLbl") if header_bar else null
	if gl:
		gl.text = "%d зол." % Game.gold if Game.screen != "title" else ""
	for ch in content.get_children():
		ch.queue_free()
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var side := 28 if Game.screen in ["title", "town"] else 28
	pad.add_theme_constant_override("margin_left", side)
	pad.add_theme_constant_override("margin_right", side)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 20)
	content.add_child(pad)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pad.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	match Game.screen:
		"title":
			_scr_title(box)
		"intro":
			_scr_intro(box)
		"town":
			_scr_town(box)
		"party":
			_scr_party(box)
		"heroes":
			_scr_heroes(box)
		"inventory":
			_scr_inv(box)
		"shop":
			_scr_shop(box)
		"rest":
			_scr_rest(box)
		"upgrades":
			_scr_upg(box)
		"map":
			_scr_map(box)
		"event":
			_scr_event(box)
		"combat":
			pass
		"reward":
			_scr_reward(box)
		"result":
			_scr_result(box)

func _heading(box: VBoxContainer, kicker: String, title: String) -> void:
	var k := Label.new()
	k.text = kicker.to_upper()
	k.add_theme_color_override("font_color", MUTED)
	k.add_theme_font_size_override("font_size", 12)
	if display_font:
		k.add_theme_font_override("font", display_font)
	box.add_child(k)
	var t := Label.new()
	t.text = title
	t.add_theme_color_override("font_color", FG)
	t.add_theme_font_size_override("font_size", 30)
	if display_font:
		t.add_theme_font_override("font", display_font)
	box.add_child(t)

func _p(box: VBoxContainer, text: String, c: Color = MUTED) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", c)
	box.add_child(l)

func _btn(text: String, cb: Callable, gold := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	_style_btn(b, BG if gold else FG, GOLD if gold else FG)
	b.pressed.connect(cb)
	return b

func _small_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(88, 36)
	_style_btn(b, FG, Color.TRANSPARENT)
	b.pressed.connect(cb)
	return b

func _style_btn(b: Button, fg: Color, bg: Color) -> void:
	var on_gold := bg == GOLD
	b.add_theme_color_override("font_color", BG if on_gold else fg)
	b.add_theme_color_override("font_hover_color", BG if on_gold else GOLD)
	b.add_theme_color_override("font_disabled_color", MUTED)
	var n := StyleBoxFlat.new()
	n.bg_color = bg if bg != Color.TRANSPARENT else Color(0.12, 0.1, 0.09, 0.92)
	n.set_border_width_all(1)
	n.border_color = GOLD if on_gold else BORDER
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	n.set_corner_radius_all(2)
	b.add_theme_stylebox_override("normal", n)
	var hov := n.duplicate()
	hov.border_color = GOLD
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	var dis := n.duplicate()
	dis.bg_color = Color(0.1, 0.09, 0.08, 0.5)
	b.add_theme_stylebox_override("disabled", dis)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.075, 0.065, 0.055, 0.94)
	s.set_border_width_all(1)
	s.border_color = Color(0.28, 0.24, 0.2, 0.85)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel", s)
	return p

func _bar(val: float, mx: float, col: Color) -> ColorRect:
	var wrap := ColorRect.new()
	wrap.color = Color("100e0c")
	wrap.custom_minimum_size = Vector2(80, 8)
	wrap.size_flags_horizontal = SIZE_EXPAND_FILL
	var fill := ColorRect.new()
	fill.color = col
	wrap.add_child(fill)
	fill.set_anchors_preset(PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(val / maxf(1.0, mx), 0.0, 1.0)
	return wrap

func _portrait(path: String, sz: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = sz
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	return tr

func _scr_title(box: VBoxContainer) -> void:
	if ResourceLoader.exists("res://assets/portraits/title.jpg"):
		var img := _portrait("res://assets/portraits/title.jpg", Vector2(0, 220))
		img.size_flags_horizontal = SIZE_EXPAND_FILL
		box.add_child(img)
	var k := Label.new()
	k.text = "СЕРЫЙ ПРИЮТ ПОМНИТ ДОРОГУ"
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_theme_color_override("font_color", GOLD)
	if display_font:
		k.add_theme_font_override("font", display_font)
	k.add_theme_font_size_override("font_size", 13)
	box.add_child(k)
	var t := Label.new()
	t.text = "ASHEN ROAD"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 52)
	t.add_theme_color_override("font_color", FG)
	if display_font:
		t.add_theme_font_override("font", display_font)
	box.add_child(t)
	var s := Label.new()
	s.text = "Пепельный Тракт"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", MUTED)
	s.add_theme_font_size_override("font_size", 22)
	box.add_child(s)
	_p(box, "Четыре путника. Одна короткая экспедиция. Разум ломается раньше тела.")
	box.add_child(_btn("Новая игра", func(): Game.new_game(true), true))
	var loadb := _btn("Загрузить", func(): Game.load_game())
	loadb.disabled = not Game.has_save()
	box.add_child(loadb)

func _scr_intro(box: VBoxContainer) -> void:
	_heading(box, "Начало", "После Первого Тлена")
	_p(box, "Небо больше не синее. Над степью стоит серая пелена, и каждое поселение держится за уголь, как за молитву.")
	_p(box, "В Сером Приюте собрались четверо. Гарн держит строй. Сайка стреляет туда, где уже слабо. Осир платит покоем за силу. Илис зашивает то, что ещё можно зашить.")
	_p(box, "Пепельный Собор зовёт. Если дойти и вернуться — Приют продержится ещё одну зиму.")
	box.add_child(_btn("В Серый Приют", func(): Game.set_screen("town"), true))

func _scr_town(box: VBoxContainer) -> void:
	_heading(box, "Серый Приют", "Последний тёплый камень")
	_p(box, "Вылазок %d  ·  побед %d" % [Game.stats.expeditions, Game.stats.victories])
	if ResourceLoader.exists("res://assets/portraits/town.jpg"):
		var img := _portrait("res://assets/portraits/town.jpg", Vector2(0, 200))
		img.size_flags_horizontal = SIZE_EXPAND_FILL
		box.add_child(img)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var buildings := [
		["Ворота", "party"],
		["Очаг", "rest"],
		["Лавка", "shop"],
		["Схрон", "inventory"],
		["Казарма", "heroes"],
		["Кузница", "upgrades"],
	]
	for b in buildings:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		_style_btn(btn, FG, SURFACE)
		var scr: String = b[1]
		btn.pressed.connect(func(): Game.set_screen(scr))
		grid.add_child(btn)
	box.add_child(grid)

func _scr_party(box: VBoxContainer) -> void:
	_heading(box, "Позиции", "Кто стоит впереди")
	_p(box, "Позиция 1 — у врага. Нажмите номер, чтобы поменять места.")
	var sorted: Array = Game.heroes.duplicate()
	sorted.sort_custom(func(a, b): return a.pos < b.pos)
	for h in sorted:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(_portrait(h.portrait, Vector2(64, 86)))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = SIZE_EXPAND_FILL
		var n := Label.new()
		n.text = "%s  ·  %s" % [h.name, h.title]
		n.add_theme_color_override("font_color", FG)
		col.add_child(n)
		var nums := HBoxContainer.new()
		for p in range(1, 5):
			var b := Button.new()
			b.text = str(p)
			b.custom_minimum_size = Vector2(40, 40)
			_style_btn(b, BG if h.pos == p else MUTED, GOLD if h.pos == p else RAISED)
			var pid: String = h.id
			var pp: int = p
			b.pressed.connect(func(): Game.set_pos(pid, pp))
			nums.add_child(b)
		col.add_child(nums)
		row.add_child(col)
		box.add_child(row)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	acts.add_child(_btn("На тракт", Game.begin_expedition, true))
	acts.add_child(_btn("В Приют", func(): Game.set_screen("town")))
	box.add_child(acts)

func _scr_heroes(box: VBoxContainer) -> void:
	_heading(box, "Отряд", "Четыре имени")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for h in Game.heroes:
		var p := _panel()
		var v := VBoxContainer.new()
		var n := Label.new()
		n.text = "%s  ·  ур. %d  ·  поз. %d" % [h.name, h.level, h.pos]
		n.add_theme_color_override("font_color", FG)
		v.add_child(n)
		v.add_child(_bar(h.hp, h.max_hp, HP_C))
		v.add_child(_bar(h.stress, 100, STRESS_C))
		var st := Label.new()
		st.text = "Сила %d  ·  Защита %d  ·  Скорость %d  ·  Крит %d%%" % [h.str, h.def, h.spd, h.crit]
		st.add_theme_color_override("font_color", MUTED)
		st.add_theme_font_size_override("font_size", 14)
		v.add_child(st)
		p.add_child(v)
		grid.add_child(p)
	box.add_child(grid)
	box.add_child(_btn("Назад", func(): Game.set_screen("town")))

func _scr_inv(box: VBoxContainer) -> void:
	_heading(box, "Сумка", "То, что ещё не истратили")
	if Game.inventory.is_empty():
		_p(box, "Пусто. Добыча ждёт на тракте.")
	for it in Game.inventory:
		var def: Dictionary = Data.items()[it.def]
		var p := _panel()
		var v := VBoxContainer.new()
		var n := Label.new()
		n.text = def.name
		n.add_theme_color_override("font_color", FG)
		v.add_child(n)
		var d := Label.new()
		d.text = def.desc
		d.add_theme_color_override("font_color", MUTED)
		v.add_child(d)
		var town := def.has("heal") or int(def.get("party_stress", 0)) > 0 or int(def.get("stress", 0)) > 0
		if not def.get("combat", false) and town:
			var row := HBoxContainer.new()
			for h in Game.heroes:
				row.add_child(_small_btn(h.name, func(): Game.use_item(it.uid, h.id)))
			v.add_child(row)
		else:
			var only := Label.new()
			only.text = "Только в бою."
			only.add_theme_color_override("font_color", MUTED)
			v.add_child(only)
		p.add_child(v)
		box.add_child(p)
	box.add_child(_btn("Назад", func(): Game.set_screen("town")))

func _scr_shop(box: VBoxContainer) -> void:
	_heading(box, "Лавка угля", "Торговец не называет цены дважды")
	_p(box, "В казне %d золота." % Game.gold)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 12)
	var buy := _panel()
	var bv := VBoxContainer.new()
	var bt := Label.new()
	bt.text = "КУПИТЬ"
	bt.add_theme_color_override("font_color", GOLD)
	if display_font:
		bt.add_theme_font_override("font", display_font)
	bv.add_child(bt)
	if Game.shop.is_empty():
		_p(bv, "Полки пусты.")
	for id in Game.shop:
		var def: Dictionary = Data.items()[id]
		var row := HBoxContainer.new()
		var n := Label.new()
		n.text = def.name
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.add_theme_color_override("font_color", FG)
		row.add_child(n)
		var price := Data.buy_price(id)
		var b := _small_btn(str(price), func(): Game.buy_shop(id))
		b.disabled = Game.gold < price
		row.add_child(b)
		bv.add_child(row)
	buy.add_child(bv)
	buy.size_flags_horizontal = SIZE_EXPAND_FILL
	split.add_child(buy)
	var sellp := _panel()
	var sv := VBoxContainer.new()
	var st := Label.new()
	st.text = "ПРОДАТЬ"
	st.add_theme_color_override("font_color", MUTED)
	sv.add_child(st)
	for it in Game.inventory:
		var def: Dictionary = Data.items()[it.def]
		var row := HBoxContainer.new()
		var n := Label.new()
		n.text = def.name
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.add_theme_color_override("font_color", FG)
		row.add_child(n)
		row.add_child(_small_btn("+%d" % Data.sell_price(it.def), func(): Game.sell_item(it.uid)))
		sv.add_child(row)
	sellp.add_child(sv)
	sellp.size_flags_horizontal = SIZE_EXPAND_FILL
	split.add_child(sellp)
	box.add_child(split)
	box.add_child(_btn("На площадь", func(): Game.set_screen("town")))

func _scr_rest(box: VBoxContainer) -> void:
	_heading(box, "Ночь", "Угли в очаге")
	_p(box, "15 золота за кров.")
	for h in Game.heroes:
		var n := Label.new()
		n.text = "%s    HP %d/%d    стресс %d" % [h.name, h.hp, h.max_hp, h.stress]
		n.add_theme_color_override("font_color", FG)
		box.add_child(n)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var r := _btn("Отдохнуть (15)", Game.rest_town, true)
	r.disabled = Game.gold < 15
	row.add_child(r)
	row.add_child(_btn("Назад", func(): Game.set_screen("town")))
	box.add_child(row)

func _scr_upg(box: VBoxContainer) -> void:
	_heading(box, "Камень и труд", "Улучшения Приюта")
	var rows := [
		["training", "Двор", "+1 сила всем.", 70],
		["infirmary", "Лазарет", "Отдых лечит больше.", 60],
		["chapel", "Часовня угля", "Отдых сильнее снимает стресс.", 60],
		["armory", "Кузница", "+1 защита всем.", 70],
	]
	for r in rows:
		var p := _panel()
		var h := HBoxContainer.new()
		var v := VBoxContainer.new()
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		var n := Label.new()
		n.text = r[1]
		n.add_theme_color_override("font_color", FG)
		v.add_child(n)
		var d := Label.new()
		d.text = r[2]
		d.add_theme_color_override("font_color", MUTED)
		v.add_child(d)
		h.add_child(v)
		var key: String = r[0]
		var b := _small_btn("Готово" if Game.upgrades[key] else "%d зол." % r[3], func(): Game.buy_upgrade(key))
		b.disabled = Game.upgrades[key] or Game.gold < r[3]
		h.add_child(b)
		p.add_child(h)
		box.add_child(p)
	box.add_child(_btn("Назад", func(): Game.set_screen("town")))

func _scr_map(box: VBoxContainer) -> void:
	_heading(box, "Пепельный тракт", "Короткий путь безопаснее. Опасный — сытнее.")
	if Game.expedition == null:
		return
	for n in Data.map_nodes():
		if n.kind == "start":
			continue
		var avail: bool = n.id in Game.expedition.available
		var done: bool = n.id in Game.expedition.done
		var b := Button.new()
		b.text = n.label
		b.disabled = not avail
		b.custom_minimum_size = Vector2(0, 48)
		_style_btn(b, GOLD if done else FG, SURFACE)
		if avail:
			var nid: String = n.id
			b.pressed.connect(func(): Game.choose_node(nid))
		box.add_child(b)
	box.add_child(_btn("Оставить тракт", Game.return_town))

func _scr_event(box: VBoxContainer) -> void:
	var ev
	for e in Data.events():
		if e.id == Game.event_id:
			ev = e
	if ev == null:
		_p(box, "Событие уже прошло.")
		box.add_child(_btn("На тракт", Game.collect_reward))
		return
	_heading(box, "На тракте", ev.title)
	_p(box, ev.body, FG)
	for c in ev.choices:
		var b := Button.new()
		b.text = "%s    ·    %s" % [c.label, c.hint]
		b.custom_minimum_size = Vector2(0, 52)
		_style_btn(b, FG, SURFACE)
		var cid: String = c.id
		b.pressed.connect(func(): Game.resolve_event(cid))
		box.add_child(b)

func _fill_combat_hud(c: Dictionary) -> void:
	var actor = Game.engine.actor_of(c)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_preset(PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 14
	top.offset_bottom = 46
	var r := Label.new()
	r.text = "РАУНД  %d" % c.round
	r.add_theme_color_override("font_color", MUTED)
	if display_font:
		r.add_theme_font_override("font", display_font)
	r.add_theme_font_size_override("font_size", 13)
	top.add_child(r)
	if str(c.banner) != "":
		var ban := Label.new()
		ban.text = "    " + str(c.banner)
		ban.add_theme_color_override("font_color", EMBER)
		if display_font:
			ban.add_theme_font_override("font", display_font)
		top.add_child(ban)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	var gold := Label.new()
	gold.text = "%d зол." % Game.gold
	gold.add_theme_color_override("font_color", MUTED)
	top.add_child(gold)
	combat_hud.add_child(top)
	var logp := PanelContainer.new()
	logp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ls := StyleBoxFlat.new()
	ls.bg_color = Color(0.05, 0.04, 0.035, 0.55)
	ls.content_margin_left = 12
	ls.content_margin_right = 12
	ls.content_margin_top = 8
	ls.content_margin_bottom = 8
	logp.add_theme_stylebox_override("panel", ls)
	logp.set_anchors_preset(PRESET_TOP_LEFT)
	logp.offset_left = 20
	logp.offset_top = 52
	logp.offset_right = 430
	logp.offset_bottom = 168
	var lv := VBoxContainer.new()
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for line in c.log.slice(maxi(0, c.log.size() - 4)):
		var l := Label.new()
		l.text = line.t
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", HEAL if line.tone == "g" else (EMBER if line.tone == "b" else (Color("d8c8a8") if line.tone == "w" else MUTED)))
		lv.add_child(l)
	logp.add_child(lv)
	combat_hud.add_child(logp)
	if c.finished != "none":
		var wrap := CenterContainer.new()
		wrap.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		wrap.mouse_filter = Control.MOUSE_FILTER_STOP
		var card := _panel()
		card.custom_minimum_size = Vector2(420, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 12)
		var msg := Label.new()
		msg.text = "Враги пали" if c.finished == "win" else "Отряд сломлен"
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if display_font:
			msg.add_theme_font_override("font", display_font)
		msg.add_theme_font_size_override("font_size", 26)
		v.add_child(msg)
		v.add_child(_btn("Забрать добычу" if c.finished == "win" else "Отступить в Приют", Game.finish_combat, c.finished == "win"))
		card.add_child(v)
		wrap.add_child(card)
		combat_hud.add_child(wrap)
		return
	var dock := PanelContainer.new()
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.05, 0.045, 0.038, 0.9)
	ds.border_width_top = 1
	ds.border_color = Color(0.3, 0.26, 0.2, 0.7)
	ds.content_margin_left = 18
	ds.content_margin_right = 18
	ds.content_margin_top = 10
	ds.content_margin_bottom = 14
	dock.add_theme_stylebox_override("panel", ds)
	dock.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock.offset_top = -140
	dock.offset_bottom = 0
	if actor and actor.side == "player" and c.waiting:
		_skill_dock(dock, actor, c)
	else:
		var wait := Label.new()
		wait.text = "%s действует…" % (actor.name if actor else "Смена хода")
		wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wait.add_theme_color_override("font_color", MUTED)
		dock.add_child(wait)
	combat_hud.add_child(dock)

func _skill_dock(dock: PanelContainer, actor: Dictionary, c: Dictionary) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	var n := Label.new()
	n.text = "%s    ·    позиция %d" % [actor.name, actor.pos]
	n.size_flags_horizontal = SIZE_EXPAND_FILL
	if display_font:
		n.add_theme_font_override("font", display_font)
	n.add_theme_font_size_override("font_size", 15)
	top.add_child(n)
	if c.selected != "" and Game.engine.SKILLS.has(c.selected):
		var hint := Label.new()
		hint.text = str(Game.engine.SKILLS[c.selected].description) + "  →  клик по цели"
		hint.add_theme_color_override("font_color", EMBER)
		hint.add_theme_font_size_override("font_size", 14)
		top.add_child(hint)
	top.add_child(_small_btn("Ждать", Game.skip_turn))
	v.add_child(top)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	for id in actor.skills:
		var s: Dictionary = Game.engine.SKILLS[id]
		var ok: bool = Game.engine.can_use(actor, s, c)
		var b := Button.new()
		b.text = s.name
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 46)
		b.disabled = not ok
		_style_btn(b, GOLD if c.selected == id else FG, SURFACE)
		var sid: String = id
		b.pressed.connect(func(): Game.select_skill(sid))
		grid.add_child(b)
	v.add_child(grid)
	if not Game.inventory.is_empty():
		var items := HBoxContainer.new()
		items.add_theme_constant_override("separation", 6)
		var cap := Label.new()
		cap.text = "Предметы"
		cap.add_theme_color_override("font_color", MUTED)
		cap.add_theme_font_size_override("font_size", 13)
		items.add_child(cap)
		var shown := 0
		for it in Game.inventory:
			if shown >= 6:
				break
			var def: Dictionary = Data.items()[it.def]
			items.add_child(_small_btn(def.name, func(): Game.use_item(it.uid, actor.class_id)))
			shown += 1
		v.add_child(items)
	dock.add_child(v)

func _scr_reward(box: VBoxContainer) -> void:
	if Game.reward == null:
		return
	var r: Dictionary = Game.reward
	_heading(box, "Итог", r.title)
	_p(box, r.body, FG)
	if int(r.gold) > 0:
		_p(box, "+%d золота" % r.gold, GOLD)
	if int(r.xp) > 0:
		_p(box, "+%d опыта" % r.xp, GOLD)
	for id in r.items:
		var def: Dictionary = Data.items().get(id, {"name": id})
		_p(box, def.name, GOLD)
	box.add_child(_btn("Продолжить", Game.collect_reward, true))

func _scr_result(box: VBoxContainer) -> void:
	if Game.result == null:
		return
	var r: Dictionary = Game.result
	_heading(box, "Возвращение" if r.win else "Поражение", r.title)
	_p(box, r.body, FG)
	box.add_child(_btn("В Серый Приют", Game.return_town, true))
