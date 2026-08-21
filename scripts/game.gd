extends Node

signal changed

const SAVE_PATH := "user://ashen-road-save.json"

var engine := CombatEngine.new()
var screen := "title"
var gold := 40
var heroes: Array = []
var inventory: Array = []
var shop: Array = []
var upgrades := {"training": false, "infirmary": false, "chapel": false, "armory": false}
var expedition = null
var combat = null
var event_id := ""
var reward = null
var result = null
var toast := ""
var stats := {"expeditions": 0, "victories": 0}
var tutorial_done := false

func _ready() -> void:
	randomize()
	if not load_game():
		new_game(false)

func notify(msg: String = "") -> void:
	if msg != "":
		toast = msg
	changed.emit()

func new_game(keep_save := true) -> void:
	screen = "intro" if keep_save else "title"
	gold = 40
	heroes = _roster()
	inventory = [_item("bandage"), _item("bandage"), _item("bitter_tincture"), _item("antidote")]
	shop = Data.restock()
	upgrades = {"training": false, "infirmary": false, "chapel": false, "armory": false}
	expedition = null
	combat = null
	event_id = ""
	reward = null
	result = null
	stats = {"expeditions": 0, "victories": 0}
	tutorial_done = false
	if keep_save:
		screen = "intro"
	notify()

func _roster() -> Array:
	var order := ["warrior", "hunter", "wanderer", "occultist"]
	var out: Array = []
	var i := 0
	for id in order:
		var t: Dictionary = Data.heroes()[id]
		out.append({
			"id": id, "name": t.name, "title": t.title, "role": t.role, "portrait": t.portrait,
			"level": 1, "xp": 0, "hp": t.hp, "max_hp": t.hp, "stress": 12 + i * 4,
			"str": t.str, "def": t.def, "spd": t.spd, "crit": t.crit,
			"skills": t.skills.duplicate(), "pos": i + 1, "breakdown": "", "virtue": false,
		})
		i += 1
	return out

func _item(id: String) -> Dictionary:
	return {"uid": "it_%d" % (Time.get_ticks_msec() + randi() % 9999), "def": id}

func set_screen(s: String) -> void:
	screen = s
	notify()

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		notify("Не удалось сохранить.")
		return
	f.store_string(JSON.stringify(_snap(), "  "))
	notify("Путь записан.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_apply(parsed)
	notify("Путь восстановлен.")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func _snap() -> Dictionary:
	return {
		"screen": screen, "gold": gold, "heroes": heroes, "inventory": inventory, "shop": shop,
		"upgrades": upgrades, "expedition": expedition, "combat": combat, "event_id": event_id,
		"reward": reward, "result": result, "stats": stats, "tutorial_done": tutorial_done,
	}

func _apply(d: Dictionary) -> void:
	screen = str(d.get("screen", "title"))
	gold = int(d.get("gold", 40))
	heroes = d.get("heroes", _roster())
	inventory = d.get("inventory", [])
	shop = d.get("shop", Data.restock())
	upgrades = d.get("upgrades", upgrades)
	expedition = d.get("expedition", null)
	combat = d.get("combat", null)
	event_id = str(d.get("event_id", ""))
	reward = d.get("reward", null)
	result = d.get("result", null)
	stats = d.get("stats", stats)
	tutorial_done = bool(d.get("tutorial_done", false))

func set_pos(id: String, pos: int) -> void:
	var mover
	var swap
	for h in heroes:
		if h.id == id:
			mover = h
		elif h.pos == pos:
			swap = h
	if mover == null:
		return
	if swap != null:
		swap.pos = mover.pos
	mover.pos = pos
	notify()

func begin_expedition() -> void:
	for h in heroes:
		if h.hp <= 0:
			h.hp = 1
	stats.expeditions += 1
	expedition = {"current": "start", "available": ["fight1", "event1"], "done": ["start"], "locked": []}
	combat = null
	event_id = ""
	reward = null
	result = null
	screen = "map"
	notify()

func node_by_id(id: String):
	for n in Data.map_nodes():
		if n.id == id:
			return n
	return null

func choose_node(id: String) -> void:
	if expedition == null or id not in expedition.available:
		return
	var node = node_by_id(id)
	if node == null:
		return
	var locked: Array = []
	for a in expedition.available:
		if a != id:
			locked.append(a)
	expedition.current = id
	expedition.available = []
	expedition.done.append(id)
	expedition.locked.append_array(locked)
	if node.kind in ["fight", "elite", "boss"]:
		var enc: String = node.get("enc", "fight1")
		var tut := not tutorial_done and enc == "fight1"
		combat = engine.start("tutorial" if tut else enc, heroes, tut)
		if tut:
			tutorial_done = true
		screen = "combat"
		notify()
		return
	if node.kind == "event":
		var evs := Data.events()
		event_id = evs[randi() % evs.size()].id
		screen = "event"
		notify()
		return
	if node.kind == "reward":
		var items: Array = [Data.roll_loot(0.1)]
		if randf() < 0.35:
			items.append(Data.roll_loot(0.2))
		var g := 18 + randi() % 16
		_add_xp(20)
		gold += g
		for it in items:
			inventory.append(_item(it))
		_set_reward("Тайник", "В камне спрятан свёрток.", g, 20, items)
		return
	if node.kind == "rest":
		for h in heroes:
			if h.hp > 0:
				h.hp = mini(h.max_hp, h.hp + 14)
				h.stress = maxi(0, h.stress - 18)
		var items: Array = []
		if randf() < 0.4:
			items.append(Data.roll_loot(-0.1))
			inventory.append(_item(items[0]))
		_add_xp(8)
		_set_reward("Короткий отдых", "Вы переводите дух у камней.", 0, 8, items)

func _set_reward(title: String, body: String, g: int, xp: int, items: Array) -> void:
	reward = {"title": title, "body": body, "gold": g, "xp": xp, "items": items}
	screen = "reward"
	notify()

func _add_xp(n: int) -> void:
	for h in heroes:
		if h.hp <= 0:
			continue
		h.xp += n
		while h.level < 5 and h.xp >= Data.XP[h.level]:
			h.level += 1
			h.max_hp += 6
			h.hp = mini(h.max_hp, h.hp + 6)
			h.str += 1
			if h.level % 2 == 0:
				h.def += 1
			else:
				h.spd += 1
			h.crit += 1

func collect_reward() -> void:
	reward = null
	if expedition == null:
		screen = "town"
		notify()
		return
	var node = node_by_id(expedition.current)
	if node == null:
		screen = "town"
		notify()
		return
	if node.kind == "boss":
		expedition = null
		screen = "result"
		result = {"win": true, "title": "Дорога пройдена", "body": "Серый Приют ещё дымит, но вы вернулись."}
		notify()
		return
	expedition.available = node.next.duplicate()
	screen = "map"
	notify()

func resolve_event(choice: String) -> void:
	var res := _event_result(event_id, choice)
	for h in heroes:
		if h.hp <= 0:
			continue
		if res.has("hp"):
			h.hp = clampi(h.hp + int(res.hp), 1, h.max_hp)
		if res.has("stress"):
			h.stress = clampi(h.stress + int(res.stress), 0, 100)
	if res.has("xp"):
		_add_xp(int(res.xp))
	if res.has("gold"):
		gold = maxi(0, gold + int(res.gold))
	var items: Array = []
	if res.has("item"):
		inventory.append(_item(res.item))
		items.append(res.item)
	event_id = ""
	_set_reward(_event_title(), str(res.get("text", "")), maxi(0, int(res.get("gold", 0))), int(res.get("xp", 0)), items)

func _event_title() -> String:
	for e in Data.events():
		if e.id == event_id:
			return e.title
	return "Событие"

func _event_result(eid: String, cid: String) -> Dictionary:
	match eid:
		"altar":
			if cid == "pray":
				return {"text": "Уголь вспыхивает и гаснет.", "stress": -18} if randf() < 0.7 else {"text": "Камень отвечает холодом.", "stress": 8}
			if cid == "search":
				return {"text": "Под плитой — монеты.", "gold": 18 + randi() % 15}
			return {"text": "Вы обходите круг."}
		"merchant":
			if cid == "buy":
				if gold >= 25:
					return {"text": "Он суёт вам пузырёк.", "gold": -25, "item": "bitter_tincture"}
				return {"text": "Монет не хватает."}
			if cid == "mystery":
				if gold >= 40:
					return {"text": "В свёртке редкая вещь.", "gold": -40, "item": Data.roll_loot(0.35)} if randf() < 0.55 else {"text": "Свёрток пуст.", "gold": -40, "stress": 14}
				return {"text": "Сорок — или ничего."}
			return {"text": "Когда вы оборачиваетесь, урны уже нет."}
		"corpse":
			if cid == "bury":
				return {"text": "Вы засыпаете тело пеплом.", "stress": -12}
			if cid == "loot":
				return {"text": "Мешочек тяжёлый.", "gold": 22 + randi() % 18, "item": Data.roll_loot(), "stress": 16}
			return {"text": "Раны оставлены не зверем.", "xp": 25, "stress": 6}
		"chest":
			if cid == "open":
				return {"text": "Замок осыпается.", "item": Data.roll_loot(0.4), "gold": 10 + randi() % 14} if randf() < 0.55 else {"text": "Из ящика — холод.", "stress": 12}
			if cid == "ward":
				return {"text": "Сундук открывается тише.", "item": Data.roll_loot(0.1), "gold": 8 + randi() % 8}
			return {"text": "Вы оставляете ящик."}
		"door":
			if cid == "force":
				return {"text": "Плита поддаётся.", "gold": 20 + randi() % 16, "hp": -10}
			if cid == "rite":
				return {"text": "Обряд открывает нишу.", "stress": 18, "item": Data.pick(Data.pools()["epic"])}
			return {"text": "Гул провожает вас."}
		"fire":
			if cid == "rest":
				return {"text": "Вы сидите у углей.", "hp": 16, "stress": -20}
			if cid == "watch":
				return {"text": "Дежурство короткое.", "hp": 8, "stress": -8}
			if gold >= 8:
				return {"text": "Монета шипит в углях.", "gold": -8, "stress": -6}
			return {"text": "Монет нет."}
		"shrine":
			if cid == "drink":
				return {"text": "Вода горькая, но раны стягиваются.", "hp": 22}
			if cid == "gold":
				if gold >= 30:
					return {"text": "Чаша принимает металл.", "gold": -30, "hp": 40}
				return {"text": "Тридцать — или ничего."}
			return {"text": "На дне спрятанные монеты.", "gold": 28 + randi() % 20, "stress": 10}
		"voice":
			if cid == "listen":
				return {"text": "Настоятель слабеет, если снимать проклятия и держать стресс.", "stress": 10, "xp": 20}
			if cid == "answer":
				return {"text": "Ветер отступает.", "stress": -20} if randf() < 0.45 else {"text": "Имя уже не ваше.", "stress": 22}
			return {"text": "Шёпот остаётся позади.", "stress": 4}
	return {"text": "Ничего не происходит."}

func select_skill(id: String) -> void:
	if combat == null or not combat.waiting:
		return
	var actor = engine.actor_of(combat)
	if actor == null:
		return
	var skill: Dictionary = engine.SKILLS[id]
	if not engine.can_use(actor, skill, combat):
		notify("С этой позиции нельзя.")
		return
	if skill.target in ["self", "move", "all-enemies", "all-allies"]:
		engine.resolve(combat, actor, skill, actor)
		_after()
		return
	combat.selected = id
	notify()

func select_target(id: String) -> void:
	if combat == null or combat.selected == "":
		return
	var actor = engine.actor_of(combat)
	var skill: Dictionary = engine.SKILLS[combat.selected]
	var chosen
	for t in engine.valid_targets(actor, skill, combat):
		if t.id == id:
			chosen = t
	if chosen == null:
		return
	engine.resolve(combat, actor, skill, chosen)
	_after()

func skip_turn() -> void:
	if combat == null or not combat.waiting:
		return
	engine.skip(combat)
	_after()

func enemy_turn() -> void:
	if combat == null or combat.waiting or combat.finished != "none":
		return
	var actor = engine.actor_of(combat)
	if actor == null or actor.side == "player":
		engine.prepare(combat)
		notify()
		return
	var pick: Dictionary = engine.enemy_pick(combat, actor)
	engine.resolve(combat, actor, pick.skill, pick.target)
	_after()

func _after() -> void:
	engine.prepare(combat)
	_commit_heroes()
	notify()

func _commit_heroes() -> void:
	if combat == null:
		return
	for h in heroes:
		for u in combat.units:
			if u.id == h.id:
				h.hp = u.hp if u.alive else 0
				h.stress = u.stress

func finish_combat() -> void:
	if combat == null:
		return
	_commit_heroes()
	var node = node_by_id(expedition.current) if expedition != null else null
	if combat.finished == "win":
		var g := 22 + randi() % 14
		var xp := 28
		if node and node.kind == "elite":
			g = 45 + randi() % 14
			xp = 45
		if node and node.kind == "boss":
			g = 80 + randi() % 14
			xp = 70
			stats.victories += 1
		gold += g
		_add_xp(xp)
		var items: Array = [Data.roll_loot(0.4 if node and node.kind == "boss" else 0.0)]
		if node and node.kind == "boss":
			items.append(Data.roll_loot(0.5))
		for it in items:
			inventory.append(_item(it))
		combat = null
		_set_reward("Собор пал" if node and node.kind == "boss" else "Победа",
			"Настоятель осыпается в прах." if node and node.kind == "boss" else "Враги больше не встанут.",
			g, xp, items)
		return
	for h in heroes:
		h.hp = maxi(1, int(round(h.max_hp * 0.3)))
		h.stress = clampi(h.stress, 40, 80)
	var lost := int(round(gold * 0.35))
	gold = maxi(0, gold - lost)
	combat = null
	expedition = null
	screen = "result"
	result = {"win": false, "title": "Отряд рассеян", "body": "Вы отступаете в Серый Приют. Потеряно %d золота." % lost}
	notify()

func return_town() -> void:
	screen = "town"
	expedition = null
	combat = null
	result = null
	reward = null
	event_id = ""
	shop = Data.restock()
	save_game()
	notify()

func rest_town() -> void:
	if gold < 15:
		notify("Нужно 15 золота.")
		return
	gold -= 15
	var inf: bool = bool(upgrades.infirmary)
	var chap: bool = bool(upgrades.chapel)
	for h in heroes:
		h.hp = mini(h.max_hp, h.hp + int(round(h.max_hp * (0.7 if inf else 0.45))))
		h.stress = maxi(0, h.stress - (45 if chap else 28))
		h.breakdown = ""
	notify("Ночь в Приюте.")

func buy_upgrade(key: String) -> void:
	var prices := {"training": 70, "infirmary": 60, "chapel": 60, "armory": 70}
	if upgrades[key]:
		notify("Уже сделано.")
		return
	if gold < prices[key]:
		notify("Не хватает золота.")
		return
	gold -= prices[key]
	upgrades[key] = true
	if key == "training":
		for h in heroes:
			h.str += 1
	if key == "armory":
		for h in heroes:
			h.def += 1
	notify("Серый Приют стал чуть крепче.")

func buy_shop(def_id: String) -> void:
	var idx := shop.find(def_id)
	if idx < 0:
		notify("Этого уже нет.")
		return
	var price := Data.buy_price(def_id)
	if gold < price:
		notify("Не хватает золота.")
		return
	gold -= price
	shop.remove_at(idx)
	inventory.append(_item(def_id))
	notify("Куплено: %s." % Data.items()[def_id].name)

func sell_item(uid: String) -> void:
	for it in inventory:
		if it.uid == uid:
			gold += Data.sell_price(it.def)
			inventory.erase(it)
			notify("Продано.")
			return

func use_item(uid: String, hero_id: String = "") -> void:
	var found
	for it in inventory:
		if it.uid == uid:
			found = it
	if found == null:
		return
	var def: Dictionary = Data.items()[found.def]
	if combat != null and combat.waiting:
		var actor = engine.actor_of(combat)
		var target = actor
		if hero_id != "":
			for u in combat.units:
				if u.id == hero_id:
					target = u
		engine.use_item(combat, actor, def, target)
		inventory.erase(found)
		_after()
		return
	var town := def.has("heal") or int(def.get("party_stress", 0)) > 0 or int(def.get("stress", 0)) > 0
	if def.get("combat", false) or not town:
		notify("Это только для боя.")
		return
	var h
	for x in heroes:
		if x.id == (hero_id if hero_id != "" else heroes[0].id):
			h = x
	if h == null:
		return
	if def.has("heal"):
		h.hp = mini(h.max_hp, h.hp + int(def.heal))
	if int(def.get("stress", 0)) > 0:
		h.stress = maxi(0, h.stress - int(def.stress))
	if int(def.get("party_stress", 0)) > 0:
		for x in heroes:
			x.stress = maxi(0, x.stress - int(def.party_stress))
	inventory.erase(found)
	notify("%s использует «%s»." % [h.name, def.name])
