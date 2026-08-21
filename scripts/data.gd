class_name Data
extends RefCounted

const XP := [0, 80, 180, 300, 450]
const BUY := {"common": 16, "rare": 38, "epic": 72}

static func status_defs() -> Dictionary:
	return {
		"bleed": {"name": "Кровотечение", "color": Color("b54a3a")},
		"poison": {"name": "Отравление", "color": Color("5a8f72")},
		"stun": {"name": "Оглушение", "color": Color("c4a35a")},
		"weaken": {"name": "Ослабление", "color": Color("8a8174")},
		"curse": {"name": "Проклятие", "color": Color("7d93a6")},
		"regen": {"name": "Регенерация", "color": Color("5a8f72")},
		"empower": {"name": "Ярость", "color": Color("c45c3a")},
		"bless": {"name": "Благословение", "color": Color("c4a35a")},
		"ward": {"name": "Оберег", "color": Color("7d93a6")},
		"panic": {"name": "Срыв", "color": Color("8b3a2a")},
		"virtue": {"name": "Просветление", "color": Color("c4a35a")},
	}

static func sk(id: String, name: String, desc: String, kind: String, extra: Dictionary = {}) -> Dictionary:
	var s := {
		"id": id, "name": name, "description": desc, "kind": kind,
		"power": 0, "str_scale": 0.0, "accuracy": 100, "crit_bonus": 0,
		"from": [1, 2, 3, 4], "ranks": [1, 2, 3, 4], "target": "single-enemy",
		"effects": [], "cooldown": 0, "self_stress": 0, "stress_damage": 0,
		"stress_heal": 0, "heal": 0, "cleanse": 0, "taunt": 0, "move": 0,
		"summon": "", "extra_wound": 0.0,
	}
	for k in extra.keys():
		s[k] = extra[k]
	return s

static func skills() -> Dictionary:
	return {
		"strike": sk("strike", "Удар", "Надёжный удар по передней линии.", "damage",
			{"power": 8, "str_scale": 1.0, "accuracy": 92, "from": [1, 2], "ranks": [1, 2]}),
		"smash": sk("smash", "Сокрушение", "Тяжёлый удар. Шанс оглушить.", "damage",
			{"power": 14, "str_scale": 1.15, "accuracy": 78, "crit_bonus": 4, "from": [1, 2], "ranks": [1],
			"effects": [{"status": "stun", "chance": 35, "duration": 1, "potency": 0}], "cooldown": 1}),
		"guard": sk("guard", "Защита союзника", "Перехватывает удары выбранного союзника.", "guard",
			{"from": [1, 2], "target": "single-ally"}),
		"taunt": sk("taunt", "Провокация", "Все враги бьют вас 2 хода.", "taunt",
			{"from": [1, 2], "target": "all-enemies", "taunt": 2, "cooldown": 2}),
		"shot": sk("shot", "Выстрел", "Выстрел по средней и задней линии.", "damage",
			{"power": 10, "str_scale": 1.1, "accuracy": 90, "crit_bonus": 6, "from": [2, 3, 4], "ranks": [2, 3, 4]}),
		"aimed": sk("aimed", "Прицельный удар", "Сильнее против раненых.", "damage",
			{"power": 9, "str_scale": 1.2, "accuracy": 96, "crit_bonus": 12, "from": [3, 4], "extra_wound": 0.5, "cooldown": 1}),
		"bleed_arrow": sk("bleed_arrow", "Кровоточащая стрела", "Наносит кровотечение.", "damage",
			{"power": 6, "str_scale": 0.8, "accuracy": 88, "from": [2, 3, 4], "ranks": [1, 2, 3],
			"effects": [{"status": "bleed", "chance": 100, "duration": 3, "potency": 4}]}),
		"retreat": sk("retreat", "Отступление", "Отойти назад.", "move",
			{"from": [1, 2], "target": "move", "ranks": [], "move": 1,
			"effects": [{"status": "bless", "chance": 100, "duration": 1, "potency": 8}]}),
		"dark_pulse": sk("dark_pulse", "Тёмный импульс", "Магия по передним рядам.", "damage",
			{"power": 11, "str_scale": 1.2, "accuracy": 86, "from": [2, 3, 4], "ranks": [1, 2, 3], "self_stress": 4}),
		"curse_skill": sk("curse_skill", "Проклятие", "Цель получает больше урона.", "debuff",
			{"accuracy": 92, "from": [3, 4], "self_stress": 6,
			"effects": [{"status": "curse", "chance": 100, "duration": 3, "potency": 30}]}),
		"mind_devour": sk("mind_devour", "Пожирание разума", "Урон и стресс. Платите покоем.", "damage",
			{"power": 8, "str_scale": 1.0, "accuracy": 88, "from": [3, 4], "ranks": [2, 3, 4],
			"stress_damage": 14, "self_stress": 10, "cooldown": 1}),
		"ritual": sk("ritual", "Ритуал", "Усиливает отряд ценой стресса.", "buff",
			{"from": [4], "target": "all-allies", "self_stress": 16, "cooldown": 2,
			"effects": [{"status": "empower", "chance": 100, "duration": 3, "potency": 25}]}),
		"heal": sk("heal", "Лечение", "Закрывает раны союзника.", "heal",
			{"from": [2, 3, 4], "target": "single-ally", "heal": 18}),
		"cleanse": sk("cleanse", "Очищение", "Снимает два вредных эффекта.", "utility",
			{"from": [2, 3, 4], "target": "single-ally", "cleanse": 2}),
		"soothe": sk("soothe", "Успокоение", "Снимает стресс.", "heal",
			{"target": "single-ally", "stress_heal": 24}),
		"bless_skill": sk("bless_skill", "Благословение", "Регенерация отряду.", "buff",
			{"from": [3, 4], "target": "all-allies", "heal": 6, "cooldown": 2,
			"effects": [{"status": "regen", "chance": 100, "duration": 2, "potency": 5}]}),
		"rake": sk("rake", "Царапина", "Жадный удар.", "damage",
			{"power": 6, "str_scale": 1.0, "accuracy": 88, "from": [1, 2], "ranks": [1, 2]}),
		"filth_bite": sk("filth_bite", "Грязный укус", "Шанс кровотечения.", "damage",
			{"power": 5, "str_scale": 0.8, "accuracy": 82, "from": [1, 2], "ranks": [1],
			"effects": [{"status": "bleed", "chance": 55, "duration": 2, "potency": 3}]}),
		"cower": sk("cower", "Сжаться", "Временно повышает защиту.", "buff",
			{"target": "self", "effects": [{"status": "bless", "chance": 100, "duration": 2, "potency": 10}]}),
		"ash_whisper": sk("ash_whisper", "Шёпот пепла", "Бьёт по разуму.", "damage",
			{"power": 3, "str_scale": 0.4, "accuracy": 90, "from": [2, 3, 4], "stress_damage": 16}),
		"hex": sk("hex", "Метка культа", "Накладывает проклятие.", "debuff",
			{"accuracy": 88, "from": [3, 4],
			"effects": [{"status": "curse", "chance": 90, "duration": 3, "potency": 25}]}),
		"dark_nail": sk("dark_nail", "Тёмный гвоздь", "Магический укол.", "damage",
			{"power": 7, "str_scale": 1.0, "accuracy": 86, "from": [2, 3, 4], "ranks": [2, 3, 4]}),
		"cleaver": sk("cleaver", "Тесак", "Огромный удар.", "damage",
			{"power": 16, "str_scale": 1.2, "accuracy": 80, "from": [1, 2], "ranks": [1, 2]}),
		"hook": sk("hook", "Крюк", "Тянет и ослабляет.", "damage",
			{"power": 8, "str_scale": 0.9, "accuracy": 84, "from": [1, 2], "ranks": [1, 2, 3],
			"effects": [{"status": "weaken", "chance": 70, "duration": 2, "potency": 25}]}),
		"rend": sk("rend", "Рассечение", "Сильное кровотечение.", "damage",
			{"power": 7, "str_scale": 0.8, "accuracy": 82, "from": [1, 2], "ranks": [1],
			"effects": [{"status": "bleed", "chance": 80, "duration": 3, "potency": 5}]}),
		"sting": sk("sting", "Жало", "Яд в кровь.", "damage",
			{"power": 5, "str_scale": 0.9, "accuracy": 90, "from": [1, 2, 3], "ranks": [1, 2, 3],
			"effects": [{"status": "poison", "chance": 85, "duration": 3, "potency": 4}]}),
		"leech": sk("leech", "Пиявка", "Крадёт здоровье.", "damage",
			{"power": 6, "str_scale": 1.0, "accuracy": 86, "from": [1, 2], "ranks": [1, 2], "heal": 8}),
		"spit": sk("spit", "Плевок", "Яд по задней линии.", "damage",
			{"power": 4, "str_scale": 0.6, "accuracy": 84, "from": [2, 3, 4], "ranks": [3, 4],
			"effects": [{"status": "poison", "chance": 60, "duration": 2, "potency": 3}]}),
		"cinder_wall": sk("cinder_wall", "Стена тлена", "Защитная стойка.", "buff",
			{"from": [1, 2], "target": "self",
			"effects": [{"status": "bless", "chance": 100, "duration": 2, "potency": 14}]}),
		"ash_slam": sk("ash_slam", "Пепельный удар", "Бьёт переднюю линию.", "damage",
			{"power": 10, "str_scale": 1.0, "accuracy": 82, "from": [1, 2], "ranks": [1, 2], "target": "all-enemies"}),
		"smother": sk("smother", "Удушение", "Шанс оглушить.", "damage",
			{"power": 8, "str_scale": 0.9, "accuracy": 78, "from": [1, 2], "ranks": [1, 2],
			"effects": [{"status": "stun", "chance": 40, "duration": 1, "potency": 0}]}),
		"brand": sk("brand", "Клеймо", "Проклятие элиты.", "debuff",
			{"from": [1, 2, 3], "effects": [{"status": "curse", "chance": 100, "duration": 3, "potency": 30}]}),
		"cinder_strike": sk("cinder_strike", "Удар тлеющего", "Тяжёлый удар Настоятеля.", "damage",
			{"power": 12, "str_scale": 1.1, "accuracy": 86, "from": [1, 2], "ranks": [1, 2]}),
		"ash_sermon": sk("ash_sermon", "Пепельная проповедь", "Стресс всему отряду.", "damage",
			{"power": 2, "str_scale": 0.2, "accuracy": 94, "target": "all-enemies", "stress_damage": 10}),
		"ember_bolt": sk("ember_bolt", "Уголь-стрела", "Магия по задней линии.", "damage",
			{"power": 10, "str_scale": 1.0, "accuracy": 88, "from": [2, 3, 4], "ranks": [3, 4]}),
		"funeral_pyre": sk("funeral_pyre", "Погребальный костёр", "Огонь по всем.", "damage",
			{"power": 8, "str_scale": 0.8, "accuracy": 84, "target": "all-enemies"}),
		"last_rite": sk("last_rite", "Последний обряд", "Опасный одиночный удар.", "damage",
			{"power": 18, "str_scale": 1.3, "accuracy": 80,
			"effects": [{"status": "weaken", "chance": 50, "duration": 2, "potency": 20}]}),
		"call_faithful": sk("call_faithful", "Призыв верных", "Призывает культиста.", "utility",
			{"target": "self", "summon": "cultist", "cooldown": 3}),
		"cracked_benediction": sk("cracked_benediction", "Треснувшее благословение", "Настоятель усиливает себя.", "buff",
			{"target": "self", "cooldown": 2,
			"effects": [{"status": "empower", "chance": 100, "duration": 3, "potency": 30}]}),
	}

static func heroes() -> Dictionary:
	return {
		"warrior": {"id": "warrior", "name": "Гарн", "title": "Угольный Страж", "role": "Передняя линия",
			"portrait": "res://assets/portraits/warrior.jpg", "hp": 54, "str": 8, "def": 7, "spd": 4, "crit": 8,
			"skills": ["strike", "smash", "guard", "taunt"], "color": Color("8b5a3a")},
		"hunter": {"id": "hunter", "name": "Сайка", "title": "Пепельный Следопыт", "role": "Дальний урон",
			"portrait": "res://assets/portraits/hunter.jpg", "hp": 34, "str": 10, "def": 3, "spd": 7, "crit": 16,
			"skills": ["shot", "aimed", "bleed_arrow", "retreat"], "color": Color("6b5344")},
		"occultist": {"id": "occultist", "name": "Осир", "title": "Пепельный Провидец", "role": "Магия и проклятия",
			"portrait": "res://assets/portraits/occultist.jpg", "hp": 28, "str": 9, "def": 2, "spd": 5, "crit": 10,
			"skills": ["dark_pulse", "curse_skill", "mind_devour", "ritual"], "color": Color("5a534c")},
		"wanderer": {"id": "wanderer", "name": "Илис", "title": "Странница Тлеющих Троп", "role": "Поддержка",
			"portrait": "res://assets/portraits/wanderer.jpg", "hp": 36, "str": 5, "def": 4, "spd": 6, "crit": 5,
			"skills": ["heal", "cleanse", "soothe", "bless_skill"], "color": Color("6a6b55")},
	}

static func enemies() -> Dictionary:
	return {
		"scavenger": {"name": "Падальщик", "portrait": "res://assets/portraits/scavenger.jpg",
			"hp": 22, "str": 5, "def": 2, "spd": 6, "crit": 6, "skills": ["rake", "filth_bite", "cower"], "ai": "front"},
		"cultist": {"name": "Культист", "portrait": "res://assets/portraits/cultist.jpg",
			"hp": 26, "str": 6, "def": 2, "spd": 5, "crit": 8, "skills": ["ash_whisper", "hex", "dark_nail"], "ai": "stress"},
		"butcher": {"name": "Мясник", "portrait": "res://assets/portraits/butcher.jpg",
			"hp": 42, "str": 11, "def": 4, "spd": 3, "crit": 8, "skills": ["cleaver", "hook", "rend"], "ai": "lowhp"},
		"parasite": {"name": "Паразит", "portrait": "res://assets/portraits/parasite.jpg",
			"hp": 24, "str": 5, "def": 1, "spd": 8, "crit": 10, "skills": ["sting", "leech", "spit"], "ai": "dot"},
		"ash_keeper": {"name": "Хранитель Пепла", "portrait": "res://assets/portraits/ash_keeper.jpg",
			"hp": 58, "str": 9, "def": 6, "spd": 4, "crit": 8, "skills": ["cinder_wall", "ash_slam", "smother", "brand"],
			"ai": "elite", "elite": true},
		"hierophant": {"name": "Пепельный Настоятель", "portrait": "res://assets/portraits/hierophant.jpg",
			"hp": 150, "str": 10, "def": 6, "spd": 5, "crit": 10,
			"skills": ["cinder_strike", "ash_sermon", "ember_bolt", "funeral_pyre", "last_rite", "call_faithful", "cracked_benediction"],
			"ai": "boss", "boss": true},
	}

static func items() -> Dictionary:
	return {
		"bandage": {"name": "Бинт из золы", "desc": "Восстанавливает 18 здоровья.", "rarity": "common", "heal": 18},
		"field_kit": {"name": "Полевой набор", "desc": "Восстанавливает 32 здоровья.", "rarity": "rare", "heal": 32},
		"bitter_tincture": {"name": "Горькая настойка", "desc": "Снимает 20 стресса.", "rarity": "common", "stress": 20},
		"smelling_salts": {"name": "Нашатырь странника", "desc": "Снимает 35 стресса.", "rarity": "rare", "stress": 35},
		"antidote": {"name": "Противоядие", "desc": "Снимает яд и кровотечение.", "rarity": "common", "cleanse": ["bleed", "poison"]},
		"ash_salts": {"name": "Пепельная соль", "desc": "Снимает проклятие и ослабление.", "rarity": "rare", "cleanse": ["curse", "weaken"]},
		"ember_oil": {"name": "Масло тлена", "desc": "Усиливает урон на 3 хода.", "rarity": "rare", "buff": "empower", "combat": true},
		"warding_charm": {"name": "Оберег угля", "desc": "Защита от эффектов.", "rarity": "rare", "buff": "ward", "combat": true},
		"rage_draught": {"name": "Черновой настой", "desc": "Ярость ценой покоя.", "rarity": "epic", "buff": "empower", "stress": -12, "combat": true},
		"quiet_prayer": {"name": "Тихая молитва", "desc": "Снимает 12 стресса у отряда.", "rarity": "epic", "party_stress": 12},
		"firebomb": {"name": "Угольная бомба", "desc": "16 урона всем врагам.", "rarity": "rare", "aoe": 16, "combat": true},
		"lantern_oil": {"name": "Масло фонаря", "desc": "Стойкость на 2 хода.", "rarity": "common", "buff": "bless", "combat": true},
	}

static func pools() -> Dictionary:
	return {
		"common": ["bandage", "bitter_tincture", "antidote", "lantern_oil"],
		"rare": ["field_kit", "smelling_salts", "ash_salts", "ember_oil", "warding_charm", "firebomb"],
		"epic": ["rage_draught", "quiet_prayer"],
	}

static func map_nodes() -> Array:
	return [
		{"id": "start", "kind": "start", "label": "Серый Приют", "x": 50, "y": 92, "next": ["fight1", "event1"], "danger": "safe"},
		{"id": "fight1", "kind": "fight", "label": "Засада на тракте", "x": 28, "y": 74, "next": ["reward"], "danger": "normal", "enc": "fight1"},
		{"id": "event1", "kind": "event", "label": "Боковая тропа", "x": 72, "y": 74, "next": ["reward"], "danger": "safe"},
		{"id": "reward", "kind": "reward", "label": "Тайник путников", "x": 50, "y": 56, "next": ["fight2", "rest"], "danger": "safe"},
		{"id": "fight2", "kind": "fight", "label": "Разрушенный двор", "x": 28, "y": 38, "next": ["elite"], "danger": "risky", "enc": "fight2"},
		{"id": "rest", "kind": "rest", "label": "Укрытие у камней", "x": 72, "y": 38, "next": ["elite"], "danger": "safe"},
		{"id": "elite", "kind": "elite", "label": "Каменная стража", "x": 50, "y": 22, "next": ["boss"], "danger": "risky", "enc": "elite"},
		{"id": "boss", "kind": "boss", "label": "Пепельный Собор", "x": 50, "y": 8, "next": [], "danger": "risky", "enc": "boss"},
	]

static func encounters() -> Dictionary:
	return {
		"tutorial": ["scavenger", "scavenger"],
		"fight1": ["scavenger", "cultist"],
		"fight2a": ["butcher", "scavenger"],
		"fight2b": ["parasite", "cultist", "scavenger"],
		"elite": ["ash_keeper", "cultist"],
		"boss": ["hierophant"],
	}

static func events() -> Array:
	return [
		{"id": "altar", "title": "Заброшенный алтарь", "body": "Каменный круг покрыт серым налётом.",
			"choices": [
				{"id": "pray", "label": "Помолиться", "hint": "Стресс или проклятие"},
				{"id": "search", "label": "Обыскать", "hint": "Золото, риск раны"},
				{"id": "leave", "label": "Уйти", "hint": "Без последствий"},
			]},
		{"id": "merchant", "title": "Странный торговец", "body": "Человек в плаще сидит на перевёрнутой урне.",
			"choices": [
				{"id": "buy", "label": "Купить настойку (25 зол.)", "hint": "Предмет от стресса"},
				{"id": "mystery", "label": "Купить тайник (40 зол.)", "hint": "Редкость или беда"},
				{"id": "refuse", "label": "Отказать", "hint": "Уйти"},
			]},
		{"id": "corpse", "title": "Тело путника", "body": "У обочины лежит человек. На груди мешочек.",
			"choices": [
				{"id": "bury", "label": "Похоронить", "hint": "Стресс вниз"},
				{"id": "loot", "label": "Обыскать", "hint": "Золото и стыд"},
				{"id": "study", "label": "Осмотреть раны", "hint": "Опыт"},
			]},
		{"id": "chest", "title": "Проклятый сундук", "body": "Ящик из базальта, замок оплавлен.",
			"choices": [
				{"id": "open", "label": "Открыть", "hint": "Награда или проклятие"},
				{"id": "ward", "label": "Наложить оберег", "hint": "Безопаснее"},
				{"id": "leave", "label": "Оставить", "hint": "Ничего"},
			]},
		{"id": "door", "title": "Древняя дверь", "body": "В склоне холма плита с круговым орнаментом.",
			"choices": [
				{"id": "force", "label": "Выломать", "hint": "Урон, золото"},
				{"id": "rite", "label": "Провести обряд", "hint": "Стресс за редкость"},
				{"id": "walk", "label": "Обойти", "hint": "Безопасно"},
			]},
		{"id": "fire", "title": "Костёр", "body": "В ложбине ещё дымятся угли.",
			"choices": [
				{"id": "rest", "label": "Отдохнуть", "hint": "Лечение и покой"},
				{"id": "watch", "label": "Дежурить", "hint": "Меньше лечения"},
				{"id": "offer", "label": "Бросить монету", "hint": "Отношения"},
			]},
		{"id": "shrine", "title": "Алтарь лечения", "body": "Чаша из зелёного камня полна воды.",
			"choices": [
				{"id": "drink", "label": "Испить", "hint": "Лечение отряда"},
				{"id": "gold", "label": "Оставить золото (30)", "hint": "Полное лечение"},
				{"id": "desecrate", "label": "Осквернить", "hint": "Золото и проклятие"},
			]},
		{"id": "voice", "title": "Неизвестный голос", "body": "Ветер несёт слова. Они складываются в ваше имя.",
			"choices": [
				{"id": "listen", "label": "Слушать", "hint": "Знание о боссе, стресс"},
				{"id": "answer", "label": "Ответить", "hint": "Удача или срыв"},
				{"id": "cover", "label": "Закрыть уши", "hint": "Почти ничего"},
			]},
	]

static func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[randi() % arr.size()]

static func roll_loot(bias: float = 0.0) -> String:
	var r := randf() + bias
	var rarity := "common"
	if r > 0.92:
		rarity = "epic"
	elif r > 0.62:
		rarity = "rare"
	return pick(pools()[rarity])

static func buy_price(id: String) -> int:
	var it = items().get(id, {})
	return int(BUY.get(it.get("rarity", "common"), 16))

static func sell_price(id: String) -> int:
	return maxi(4, buy_price(id) / 2)

static func restock() -> Array:
	var stock: Array = ["bandage", "bitter_tincture", "antidote", "lantern_oil"]
	stock.append(pick(pools()["rare"]))
	stock.append(pick(pools()["rare"]))
	if randf() < 0.45:
		stock.append(pick(pools()["epic"]))
	else:
		stock.append(pick(pools()["rare"]))
	return stock
