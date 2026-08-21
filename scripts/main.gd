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
var last_screen := ""
var enemy_timer := 0.0
var combat_layer: Control
var combat_world: CombatWorld
var combat_hud: VBoxContainer
var bound_enc := ""

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	Game.changed.connect(_on_changed)
	_build_shell()
	_on_changed()

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
	if in_combat:
		_update_combat()
	else:
		bound_enc = ""
		_rebuild()

func _build_combat_layer() -> void:
	var v := VBoxContainer.new()
	v.set_anchors_preset(PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	combat_layer.add_child(v)
	var vp_wrap := SubViewportContainer.new()
	vp_wrap.size_flags_vertical = SIZE_EXPAND_FILL
	vp_wrap.stretch = true
	vp_wrap.custom_minimum_size = Vector2(0, 360)
	var vp := SubViewport.new()
	vp.transparent_bg = false
	vp.handle_input_locally = true
	vp.physics_object_picking = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1280, 520)
	vp_wrap.add_child(vp)
	combat_world = CombatWorld.new()
	combat_world.unit_clicked.connect(func(id): Game.select_target(id))
	vp.add_child(combat_world)
	v.add_child(vp_wrap)
	combat_hud = VBoxContainer.new()
	combat_hud.add_theme_constant_override("separation", 6)
	v.add_child(combat_hud)

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
	root.add_theme_constant_override("separation", 8)
	var m := MarginContainer.new()
	m.set_anchors_preset(PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 16)
	add_child(m)
	m.add_child(root)
	root.add_child(_header())
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

func _header() -> HBoxContainer:
	var h := HBoxContainer.new()
	var t := Button.new()
	t.text = "ASHEN ROAD"
	t.flat = true
	_style_btn(t, GOLD, Color.TRANSPARENT)
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
	return h

func _rebuild() -> void:
	var gl: Label = root.get_node_or_null("HBoxContainer/GoldLbl")
	if gl:
		gl.text = "%d зол." % Game.gold if Game.screen != "title" else ""
	for ch in content.get_children():
		ch.queue_free()
	var box := VBoxContainer.new()
	box.set_anchors_preset(PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	content.add_child(box)
	# fill
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
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
	box.add_child(k)
	var t := Label.new()
	t.text = title
	t.add_theme_color_override("font_color", FG)
	t.add_theme_font_size_override("font_size", 28)
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
	b.custom_minimum_size = Vector2(0, 44)
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
	b.add_theme_color_override("font_color", fg if bg != Color.TRANSPARENT and bg != GOLD else (BG if bg == GOLD else fg))
	var n := StyleBoxFlat.new()
	n.bg_color = bg if bg != Color.TRANSPARENT else RAISED
	n.set_border_width_all(1)
	n.border_color = BORDER if bg != GOLD else GOLD
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.border_color = GOLD
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = SURFACE
	s.set_border_width_all(1)
	s.border_color = BORDER
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
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
	var pct := clampf(val / maxf(1.0, mx), 0.0, 1.0)
	fill.anchor_right = pct
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
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 80)
	box.add_child(sp)
	var k := Label.new()
	k.text = "СЕРЫЙ ПРИЮТ ПОМНИТ ДОРОГУ"
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_theme_color_override("font_color", GOLD)
	box.add_child(k)
	var t := Label.new()
	t.text = "ASHEN ROAD"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 48)
	t.add_theme_color_override("font_color", FG)
	box.add_child(t)
	var s := Label.new()
	s.text = "Пепельный Тракт"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", MUTED)
	box.add_child(s)
	_p(box, "Четыре путника. Одна короткая экспедиция. Здоровье — ещё не всё: разум ломается раньше тела.")
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
	_p(box, "Вылазок %d · побед %d. Нажмите на здание." % [Game.stats.expeditions, Game.stats.victories])
	if ResourceLoader.exists("res://assets/portraits/town.jpg"):
		var img := _portrait("res://assets/portraits/town.jpg", Vector2(0, 180))
		img.size_flags_horizontal = SIZE_EXPAND_FILL
		box.add_child(img)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var buildings := [
		["Ворота тракта", "Собрать отряд и уйти в пепел.", "party"],
		["Очаг", "Ночлег за 15 золота.", "rest"],
		["Лавка угля", "Купить и продать припасы.", "shop"],
		["Схрон", "Сумка отряда.", "inventory"],
		["Казарма", "Герои, раны, связи.", "heroes"],
		["Кузница", "Укрепить Приют.", "upgrades"],
	]
	for b in buildings:
		var btn := Button.new()
		btn.text = "%s\n%s" % [b[0], b[1]]
		btn.custom_minimum_size = Vector2(0, 64)
		_style_btn(btn, FG, SURFACE)
		var scr: String = b[2]
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
		row.add_child(_portrait(h.portrait, Vector2(72, 96)))
		var col := VBoxContainer.new()
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
	acts.add_child(_btn("На тракт", Game.begin_expedition, true))
	acts.add_child(_btn("В Приют", func(): Game.set_screen("town")))
	box.add_child(acts)

func _scr_heroes(box: VBoxContainer) -> void:
	_heading(box, "Отряд", "Четыре имени")
	var grid := GridContainer.new()
	grid.columns = 2
	for h in Game.heroes:
		var p := _panel()
		var v := VBoxContainer.new()
		var n := Label.new()
		n.text = "%s  ур. %d  поз. %d" % [h.name, h.level, h.pos]
		n.add_theme_color_override("font_color", FG)
		v.add_child(n)
		v.add_child(_bar(h.hp, h.max_hp, HP_C))
		v.add_child(_bar(h.stress, 100, STRESS_C))
		var st := Label.new()
		st.text = "Сила %d · Защита %d · Скорость %d · Крит %d%%" % [h.str, h.def, h.spd, h.crit]
		st.add_theme_color_override("font_color", MUTED)
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
				var b := _small_btn(h.name, func(): Game.use_item(it.uid, h.id))
				row.add_child(b)
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
	_p(box, "В казне %d золота. Ассортимент обновляется после вылазки." % Game.gold)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 12)
	var buy := _panel()
	var bv := VBoxContainer.new()
	var bt := Label.new()
	bt.text = "КУПИТЬ"
	bt.add_theme_color_override("font_color", GOLD)
	bv.add_child(bt)
	if Game.shop.is_empty():
		var e := Label.new()
		e.text = "Полки пусты."
		e.add_theme_color_override("font_color", MUTED)
		bv.add_child(e)
	for id in Game.shop:
		var def: Dictionary = Data.items()[id]
		var row := HBoxContainer.new()
		var n := Label.new()
		n.text = "%s  (%s)" % [def.name, def.desc]
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
		n.text = "%s  HP %d/%d  стресс %d" % [h.name, h.hp, h.max_hp, h.stress]
		n.add_theme_color_override("font_color", FG)
		box.add_child(n)
	var row := HBoxContainer.new()
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
		b.text = "%s  —  %s" % [n.label, n.kind]
		b.disabled = not avail
		b.custom_minimum_size = Vector2(0, 44)
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
	_p(box, ev.body)
	for c in ev.choices:
		var b := Button.new()
		b.text = "%s\n%s" % [c.label, c.hint]
		b.custom_minimum_size = Vector2(0, 56)
		_style_btn(b, FG, SURFACE)
		var cid: String = c.id
		b.pressed.connect(func(): Game.resolve_event(cid))
		box.add_child(b)

func _fill_combat_hud(c: Dictionary) -> void:
	var box := combat_hud
	var top := HBoxContainer.new()
	var r := Label.new()
	r.text = "Раунд %d" % c.round
	r.add_theme_color_override("font_color", MUTED)
	top.add_child(r)
	if str(c.banner) != "":
		var ban := Label.new()
		ban.text = "   " + str(c.banner)
		ban.add_theme_color_override("font_color", EMBER)
		top.add_child(ban)
	box.add_child(top)
	var logp := _panel()
	var lv := VBoxContainer.new()
	for line in c.log.slice(maxi(0, c.log.size() - 4)):
		var l := Label.new()
		l.text = line.t
		l.add_theme_color_override("font_color", HEAL if line.tone == "g" else (EMBER if line.tone == "b" else (GOLD if line.tone == "w" else MUTED)))
		lv.add_child(l)
	logp.add_child(lv)
	box.add_child(logp)
	var actor = Game.engine.actor_of(c)
	if c.finished != "none":
		var msg := Label.new()
		msg.text = "Враги пали" if c.finished == "win" else "Отряд сломлен"
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.add_theme_color_override("font_color", FG)
		msg.add_theme_font_size_override("font_size", 22)
		box.add_child(msg)
		box.add_child(_btn("Забрать добычу" if c.finished == "win" else "Отступить в Приют", Game.finish_combat, c.finished == "win"))
	elif actor and actor.side == "player" and c.waiting:
		_skill_dock(box, actor, c)
		var hint := Label.new()
		hint.text = "Кликните по цели на поле. Тлеющий контур — доступная цель."
		hint.add_theme_color_override("font_color", MUTED)
		box.add_child(hint)
	else:
		_p(box, "%s действует…" % (actor.name if actor else "Смена хода"))

func _lane(c: Dictionary, side: String, actor, tset: Dictionary, can_click: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var units: Array = []
	for u in c.units:
		if u.side == side:
			units.append(u)
	if side == "player":
		units.sort_custom(func(a, b): return a.pos > b.pos)
	else:
		units.sort_custom(func(a, b): return a.pos < b.pos)
	for u in units:
		var card := _unit_card(u, actor != null and actor.id == u.id, tset.has(u.id), c)
		if can_click and tset.has(u.id) and u.alive:
			var uid: String = u.id
			card.gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					Game.select_target(uid)
			)
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.add_child(card)
	return row

func _unit_card(u: Dictionary, is_turn: bool, can_t: bool, c: Dictionary) -> PanelContainer:
	var p := _panel()
	p.size_flags_horizontal = SIZE_EXPAND_FILL
	if is_turn:
		var s: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
		s.border_color = GOLD
		s.set_border_width_all(2)
		p.add_theme_stylebox_override("panel", s)
	elif can_t:
		var s2: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
		s2.border_color = EMBER
		s2.set_border_width_all(2)
		p.add_theme_stylebox_override("panel", s2)
	var v := VBoxContainer.new()
	var top := Label.new()
	top.text = "П%d" % u.pos
	top.add_theme_color_override("font_color", MUTED)
	top.add_theme_font_size_override("font_size", 11)
	v.add_child(top)
	var pic := _portrait(u.portrait, Vector2(0, 110))
	pic.modulate = Color(0.5, 0.5, 0.5) if not u.alive else Color.WHITE
	v.add_child(pic)
	var nm := Label.new()
	nm.text = u.name
	nm.add_theme_color_override("font_color", FG)
	v.add_child(nm)
	v.add_child(_bar(u.hp, u.max_hp, HP_C))
	if u.side == "player":
		v.add_child(_bar(u.stress, 100, STRESS_C))
	var stt := PackedStringArray()
	for s in u.statuses:
		stt.append(Data.status_defs().get(s.id, {}).get("name", s.id))
	if stt.size() > 0:
		var sl := Label.new()
		sl.text = ", ".join(stt)
		sl.add_theme_color_override("font_color", GOLD)
		sl.add_theme_font_size_override("font_size", 11)
		v.add_child(sl)
	var last_fx := ""
	var last_kind := ""
	for f in c.fx:
		if f.who == u.id:
			last_fx = f.text
			last_kind = f.kind
	if last_fx != "":
		var fl := Label.new()
		fl.text = last_fx
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl.add_theme_font_size_override("font_size", 20)
		fl.add_theme_color_override("font_color", GOLD if last_kind == "crit" else (HEAL if last_kind == "heal" else EMBER))
		v.add_child(fl)
	p.add_child(v)
	return p

func _skill_dock(box: VBoxContainer, actor: Dictionary, c: Dictionary) -> void:
	var dock := _panel()
	var v := VBoxContainer.new()
	var top := HBoxContainer.new()
	var n := Label.new()
	n.text = "Ход: %s  поз. %d" % [actor.name, actor.pos]
	n.size_flags_horizontal = SIZE_EXPAND_FILL
	n.add_theme_color_override("font_color", FG)
	top.add_child(n)
	top.add_child(_small_btn("Ждать", Game.skip_turn))
	v.add_child(top)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	for id in actor.skills:
		var s: Dictionary = Game.engine.SKILLS[id]
		var ok: bool = Game.engine.can_use(actor, s, c)
		var b := Button.new()
		b.text = "%s\n%s" % [s.name, s.description]
		b.custom_minimum_size = Vector2(0, 72)
		b.disabled = not ok
		_style_btn(b, GOLD if c.selected == id else FG, SURFACE)
		var sid: String = id
		b.pressed.connect(func(): Game.select_skill(sid))
		grid.add_child(b)
	v.add_child(grid)
	if not Game.inventory.is_empty():
		var items := HBoxContainer.new()
		for it in Game.inventory:
			var def: Dictionary = Data.items()[it.def]
			items.add_child(_small_btn(def.name, func(): Game.use_item(it.uid, actor.class_id)))
		v.add_child(items)
	dock.add_child(v)
	box.add_child(dock)

func _scr_reward(box: VBoxContainer) -> void:
	if Game.reward == null:
		return
	var r: Dictionary = Game.reward
	_heading(box, "Итог", r.title)
	_p(box, r.body)
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
	_p(box, r.body)
	box.add_child(_btn("В Серый Приют", Game.return_town, true))
