class_name CombatEngine
extends RefCounted

var SKILLS: Dictionary
var ENEMIES: Dictionary
var STATUSES: Dictionary

func _init() -> void:
	SKILLS = Data.skills()
	ENEMIES = Data.enemies()
	STATUSES = Data.status_defs()

func uid(p: String) -> String:
	return "%s_%d" % [p, randi() % 999999]

func living(c: Dictionary, side: String = "") -> Array:
	var out: Array = []
	for u in c.units:
		if u.alive and (side == "" or u.side == side):
			out.append(u)
	return out

func actor_of(c: Dictionary):
	if c.turn < 0 or c.turn >= c.order.size():
		return null
	var id = c.order[c.turn]
	for u in c.units:
		if u.id == id:
			return u
	return null

func has_st(u: Dictionary, id: String) -> bool:
	for s in u.statuses:
		if s.id == id:
			return true
	return false

func get_st(u: Dictionary, id: String):
	for s in u.statuses:
		if s.id == id:
			return s
	return null

func apply_st(u: Dictionary, inst: Dictionary) -> bool:
	if has_st(u, "ward") and inst.id in ["bleed", "poison", "stun", "weaken", "curse"]:
		if randf() < 0.5:
			return false
	for s in u.statuses:
		if s.id == inst.id:
			s.duration = maxi(s.duration, inst.duration)
			s.potency = maxi(s.potency, inst.potency)
			return true
	u.statuses.append(inst.duplicate(true))
	return true

func blog(c: Dictionary, t: String, tone: String = "n") -> void:
	c.log.append({"t": t, "tone": tone})
	if c.log.size() > 40:
		c.log.pop_front()

func fx(c: Dictionary, id: String, text: String, kind: String) -> void:
	c.fx.append({"id": uid("fx"), "who": id, "text": text, "kind": kind})

func valid_targets(actor: Dictionary, skill: Dictionary, c: Dictionary) -> Array:
	var tt: String = skill.target
	if tt == "self" or tt == "move":
		return [actor]
	var opp := "enemy" if actor.side == "player" else "player"
	if tt == "all-enemies":
		var pool := living(c, opp)
		var filt: Array = []
		for t in pool:
			if skill.ranks.is_empty() or t.pos in skill.ranks:
				filt.append(t)
		return filt if not filt.is_empty() else pool
	if tt == "all-allies":
		return living(c, actor.side)
	var side: String = actor.side if tt == "single-ally" else opp
	var filtered: Array = []
	for t in living(c, side):
		if tt == "single-ally" and t.id == actor.id and skill.kind == "guard":
			continue
		if not skill.ranks.is_empty() and t.pos not in skill.ranks:
			continue
		filtered.append(t)
	if filtered.is_empty() and not skill.ranks.is_empty() and tt != "single-ally":
		return living(c, side)
	return filtered

func can_use(actor: Dictionary, skill: Dictionary, c: Dictionary) -> bool:
	if not actor.alive or has_st(actor, "stun"):
		return false
	if actor.pos not in skill.from:
		return false
	if int(actor.cd.get(skill.id, 0)) > 0:
		return false
	return valid_targets(actor, skill, c).size() > 0 or tt_ok(skill)

func tt_ok(skill: Dictionary) -> bool:
	return skill.target in ["move", "self"] or str(skill.summon) != ""

func make_enemy(type: String, pos: int, hp_mult: float = 1.0) -> Dictionary:
	var t: Dictionary = ENEMIES[type]
	return {
		"id": uid(type), "side": "enemy", "name": t.name, "portrait": t.portrait,
		"type": type, "hp": int(round(t.hp * hp_mult)), "max_hp": int(round(t.hp * hp_mult)),
		"stress": 0, "max_stress": 100, "str": t.str, "def": t.def, "spd": t.spd, "crit": t.crit,
		"skills": t.skills.duplicate(), "pos": pos, "alive": true, "statuses": [], "cd": {},
		"guarding": "", "taunt_by": "", "taunt_turns": 0, "refuse": 0, "phase": 1,
		"ai": t.get("ai", "front"), "elite": t.get("elite", false), "boss": t.get("boss", false),
		"class_id": "",
	}

func hero_unit(h: Dictionary) -> Dictionary:
	return {
		"id": h.id, "side": "player", "name": h.name, "portrait": h.portrait, "class_id": h.id,
		"hp": h.hp, "max_hp": h.max_hp, "stress": h.stress, "max_stress": 100,
		"str": h.str, "def": h.def, "spd": h.spd, "crit": h.crit,
		"skills": h.skills.duplicate(), "pos": h.pos, "alive": h.hp > 0, "statuses": [], "cd": {},
		"guarding": "", "taunt_by": "", "taunt_turns": 0,
		"refuse": 30 if h.get("breakdown", "") == "panic" else 0, "phase": 1, "ai": "",
		"elite": false, "boss": false, "type": "",
	}

func start(enc: String, heroes: Array, tutorial: bool) -> Dictionary:
	var types: Array
	if enc == "fight2":
		types = Data.encounters()["fight2a" if randf() < 0.5 else "fight2b"]
	else:
		types = Data.encounters().get(enc, Data.encounters()["fight1"])
	var units: Array = []
	var hs: Array = heroes.duplicate()
	hs.sort_custom(func(a, b): return a.pos < b.pos)
	for h in hs:
		units.append(hero_unit(h))
	var i := 1
	for t in types:
		units.append(make_enemy(t, i, 0.85 if tutorial else 1.0))
		i += 1
	var c := {
		"enc": enc, "round": 1, "turn": 0, "order": [], "units": units,
		"selected": "", "waiting": false, "finished": "none",
		"log": [], "fx": [], "banner": "Фаза I — Проповедь пепла" if enc == "boss" else "",
		"attacker": "", "anim_key": "",
	}
	blog(c, "Пепельный Собор отвечает гулом." if enc == "boss" else "Бой начался.", "w")
	_build_order(c)
	prepare(c)
	return c

func _build_order(c: Dictionary) -> void:
	var alive := living(c)
	for u in alive:
		u["_initv"] = float(u.spd) + randf() * 2.0
	alive.sort_custom(func(a, b): return float(a._initv) > float(b._initv))
	c.order = []
	for u in alive:
		c.order.append(u.id)
	c.turn = 0

func prepare(c: Dictionary) -> void:
	c.selected = ""
	if c.finished != "none":
		c.waiting = false
		return
	var guard := 0
	while guard < 24:
		guard += 1
		if c.turn >= c.order.size():
			for u in c.units:
				if u.alive:
					u.guarding = ""
			if living(c, "player").is_empty():
				c.finished = "lose"
				return
			if living(c, "enemy").is_empty():
				c.finished = "win"
				return
			c.round += 1
			_build_order(c)
			blog(c, "Раунд %d." % c.round)
		var a = actor_of(c)
		if a == null or not a.alive:
			c.turn += 1
			continue
		if has_st(a, "stun"):
			blog(c, "%s оглушён и пропускает ход." % a.name, "w")
			a.statuses = a.statuses.filter(func(s): return s.id != "stun")
			tick_dots(c, a)
			c.turn += 1
			continue
		c.waiting = a.side == "player"
		return
	c.waiting = false

func tick_dots(c: Dictionary, a: Dictionary) -> void:
	for s in a.statuses.duplicate():
		if s.id in ["bleed", "poison"]:
			true_dmg(c, a, s.potency)
		if s.id == "regen":
			a.hp = mini(a.max_hp, a.hp + s.potency)
			fx(c, a.id, "+%d" % s.potency, "heal")
		s.duration -= 1
	a.statuses = a.statuses.filter(func(s): return s.duration > 0)
	if a.taunt_turns > 0:
		a.taunt_turns -= 1
		if a.taunt_turns <= 0:
			a.taunt_by = ""
	for k in a.cd.keys():
		a.cd[k] = maxi(0, int(a.cd[k]) - 1)

func true_dmg(c: Dictionary, t: Dictionary, n: int) -> void:
	if not t.alive:
		return
	t.hp = maxi(0, t.hp - n)
	fx(c, t.id, "-%d" % n, "dmg")
	if t.hp <= 0:
		kill(c, t)

func kill(c: Dictionary, t: Dictionary) -> void:
	t.alive = false
	t.hp = 0
	t.statuses = []
	blog(c, "%s падает." % t.name, "b")
	fx(c, t.id, "Смерть", "info")
	if t.side == "enemy":
		compact(c, "enemy")
	if t.side == "player":
		for a in living(c, "player"):
			add_stress(c, a, 22)
	_check(c)

func compact(c: Dictionary, side: String) -> void:
	var units := living(c, side)
	units.sort_custom(func(a, b): return a.pos < b.pos)
	var i := 1
	for u in units:
		u.pos = i
		i += 1

func add_stress(c: Dictionary, t: Dictionary, n: int) -> void:
	if not t.alive or t.side != "player":
		return
	var before: int = t.stress
	t.stress = clampi(t.stress + n, 0, t.max_stress)
	if n > 0:
		fx(c, t.id, "+%d стр." % n, "stress")
	elif n < 0:
		fx(c, t.id, "%d стр." % n, "heal")
	if before < 100 and t.stress >= 100:
		_crisis(c, t)

func _crisis(c: Dictionary, t: Dictionary) -> void:
	if randf() < 0.12:
		t.stress = 35
		apply_st(t, {"id": "virtue", "duration": 3, "potency": 20})
		t.refuse = 0
		blog(c, "%s преодолевает кризис — просветление." % t.name, "g")
		fx(c, t.id, "Просветление", "heal")
		for a in living(c, "player"):
			if a.id != t.id:
				add_stress(c, a, -8)
		return
	var kinds := [
		{"id": "weaken", "text": "Срыв: руки не слушаются.", "refuse": 0},
		{"id": "panic", "text": "Срыв: паника.", "refuse": 32},
		{"id": "curse", "text": "Срыв: шёпот пепла.", "refuse": 0},
		{"id": "bleed", "text": "Срыв: самоповреждение.", "refuse": 0},
	]
	var k: Dictionary = Data.pick(kinds)
	t.stress = 70
	apply_st(t, {"id": k.id, "duration": 3, "potency": 4 if k.id == "bleed" else 25})
	t.refuse = k.refuse
	if k.id == "curse":
		for a in living(c, "player"):
			if a.id != t.id:
				add_stress(c, a, 10)
	blog(c, "%s: %s" % [t.name, k.text], "b")
	fx(c, t.id, "Срыв", "status")

func resolve(c: Dictionary, actor: Dictionary, skill: Dictionary, chosen) -> void:
	c.fx = []
	c.attacker = actor.id
	c.anim_key = uid("an")
	if actor.refuse > 0 and randf() * 100 < actor.refuse:
		blog(c, "%s отказывается подчиниться." % actor.name, "w")
		add_stress(c, actor, 6)
		_finish(c, actor, skill, false)
		return
	if skill.kind == "move":
		_move(actor, int(skill.move), c)
		blog(c, "%s отступает на позицию %d." % [actor.name, actor.pos])
		_fx_effects(c, actor, actor, skill)
		_finish(c, actor, skill)
		return
	if str(skill.summon) != "":
		var pos := _empty_enemy(c)
		if pos > 0:
			var sp := make_enemy(skill.summon, pos, 0.85)
			c.units.append(sp)
			blog(c, "%s призывает: %s." % [actor.name, sp.name], "w")
		else:
			blog(c, "%s зовёт верных, но места нет.")
		_finish(c, actor, skill)
		return
	var targets: Array = []
	if skill.target == "self":
		targets = [actor]
	elif skill.target in ["all-enemies", "all-allies"]:
		targets = valid_targets(actor, skill, c)
	elif chosen != null:
		targets = [chosen]
	if targets.is_empty():
		blog(c, "%s не находит цели." % actor.name)
		_finish(c, actor, skill)
		return
	if skill.kind == "guard" and chosen != null:
		actor.guarding = chosen.id
		blog(c, "%s прикрывает %s." % [actor.name, chosen.name], "g")
		_finish(c, actor, skill)
		return
	if int(skill.taunt) > 0:
		for t in living(c, "enemy" if actor.side == "player" else "player"):
			t.taunt_by = actor.id
			t.taunt_turns = skill.taunt
		apply_st(actor, {"id": "bless", "duration": skill.taunt, "potency": 10})
		blog(c, "%s провоцирует врагов." % actor.name, "w")
		_finish(c, actor, skill)
		return
	if int(skill.cleanse) > 0 and chosen != null:
		_cleanse(chosen, int(skill.cleanse))
		blog(c, "%s очищает %s." % [actor.name, chosen.name], "g")
		_finish(c, actor, skill)
		return
	for raw in targets:
		if raw == null or not raw.alive:
			continue
		var target: Dictionary = raw
		if skill.kind == "damage" and target.side != actor.side:
			if target.taunt_by != "" and actor.side == "enemy" and randf() < 0.85:
				var tn = _by_id(c, target.taunt_by)
				if tn != null and tn.alive:
					target = tn
			else:
				var g = _guard_of(c, target)
				if g != null:
					blog(c, "%s перехватывает удар, целящийся в %s." % [g.name, target.name])
					target = g
		if skill.kind == "heal":
			var heal: int = skill.heal
			if heal > 0:
				target.hp = mini(target.max_hp, target.hp + heal)
				fx(c, target.id, "+%d" % heal, "heal")
			if int(skill.stress_heal) > 0:
				add_stress(c, target, -int(skill.stress_heal))
			blog(c, "%s поддерживает %s." % [actor.name, target.name], "g")
			_fx_effects(c, actor, target, skill)
			continue
		if skill.kind in ["buff", "utility", "debuff"]:
			if int(skill.heal) > 0:
				target.hp = mini(target.max_hp, target.hp + int(skill.heal))
				fx(c, target.id, "+%d" % skill.heal, "heal")
			_fx_effects(c, actor, target, skill)
			blog(c, "%s использует «%s»." % [actor.name, skill.name])
			continue
		var dodge: float = float(target.spd) * 1.4
		var acc: float = skill.accuracy - dodge * 0.15
		var roll := randf() * 100.0
		if roll > acc:
			fx(c, target.id, "Промах", "miss")
			blog(c, "%s промахивается по %s." % [actor.name, target.name])
			continue
		var crit: bool = roll < (actor.crit + skill.crit_bonus)
		var power: float = skill.power + actor.str * skill.str_scale
		if skill.extra_wound > 0 and (float(target.hp) / target.max_hp <= 0.5 or target.statuses.size() > 0):
			power *= 1.0 + skill.extra_wound
		if has_st(actor, "weaken"):
			power *= 0.7
		if has_st(actor, "empower"):
			power *= 1.25
		if has_st(actor, "virtue"):
			power *= 1.15
		if has_st(actor, "panic"):
			power *= 0.75
		var dmg: float = power - target.def * 0.45
		if has_st(target, "curse"):
			dmg *= 1.25
		if has_st(target, "bless"):
			dmg *= 0.9
		if crit:
			dmg *= 1.5
		var di := maxi(1, int(round(dmg)))
		target.hp = maxi(0, target.hp - di)
		fx(c, target.id, ("%d!" % di) if crit else ("-%d" % di), "crit" if crit else "dmg")
		blog(c, "%s бьёт %s (%d)." % [actor.name, target.name, di], "w" if crit else "n")
		if skill.id == "leech" and int(skill.heal) > 0:
			actor.hp = mini(actor.max_hp, actor.hp + int(skill.heal))
			fx(c, actor.id, "+%d" % skill.heal, "heal")
		if target.side == "player":
			var ratio: float = float(di) / maxf(1.0, float(target.max_hp))
			if ratio >= 0.22:
				add_stress(c, target, int(round(8 + ratio * 18)))
			if crit:
				add_stress(c, target, 8)
		if int(skill.stress_damage) > 0:
			if target.side == "player":
				add_stress(c, target, int(skill.stress_damage))
			else:
				var extra := maxi(1, int(round(skill.stress_damage * 0.45)))
				target.hp = maxi(0, target.hp - extra)
				fx(c, target.id, "-%d" % extra, "stress")
		_fx_effects(c, actor, target, skill)
		if target.hp <= 0:
			kill(c, target)
	_finish(c, actor, skill)

func _fx_effects(c: Dictionary, _a: Dictionary, target: Dictionary, skill: Dictionary) -> void:
	for e in skill.effects:
		if randf() * 100.0 > e.chance:
			continue
		if apply_st(target, {"id": e.status, "duration": e.duration, "potency": e.potency}):
			fx(c, target.id, STATUSES[e.status].name, "status")
			blog(c, "%s: %s." % [target.name, STATUSES[e.status].name], "w")

func _finish(c: Dictionary, actor: Dictionary, skill: Dictionary, pay := true) -> void:
	if pay and int(skill.self_stress) > 0:
		add_stress(c, actor, int(skill.self_stress))
	if int(skill.cooldown) > 0:
		actor.cd[skill.id] = skill.cooldown
	tick_dots(c, actor)
	_boss(c)
	_check(c)
	c.turn += 1
	c.waiting = false

func _boss(c: Dictionary) -> void:
	for u in c.units:
		if u.boss and u.alive:
			var ratio: float = float(u.hp) / float(u.max_hp)
			if u.phase == 1 and ratio <= 0.6:
				u.phase = 2
				u.str += 2
				c.banner = "Фаза II — Пепел встаёт"
				blog(c, "Настоятель трещит. Пепел вокруг густеет.", "b")
			elif u.phase == 2 and ratio <= 0.3:
				u.phase = 3
				u.str += 2
				apply_st(u, {"id": "empower", "duration": 4, "potency": 20})
				c.banner = "Фаза III — Последний обряд"
				blog(c, "Настоятель сбрасывает камень с лица.", "b")

func _check(c: Dictionary) -> void:
	if living(c, "player").is_empty():
		c.finished = "lose"
	elif living(c, "enemy").is_empty():
		c.finished = "win"

func _move(a: Dictionary, d: int, c: Dictionary) -> void:
	var nxt := clampi(a.pos + d, 1, 4)
	if nxt == a.pos:
		return
	for o in living(c, a.side):
		if o.id != a.id and o.pos == nxt:
			o.pos = a.pos
	a.pos = nxt

func _empty_enemy(c: Dictionary) -> int:
	var used := {}
	for u in living(c, "enemy"):
		used[u.pos] = true
	for p in [4, 3, 2, 1]:
		if not used.has(p):
			return p
	return 0

func _by_id(c: Dictionary, id: String):
	for u in c.units:
		if u.id == id:
			return u
	return null

func _guard_of(c: Dictionary, t: Dictionary):
	if t.side != "player":
		return null
	for u in living(c, "player"):
		if u.guarding == t.id and u.id != t.id and randf() < 0.7:
			return u
	return null

func _cleanse(u: Dictionary, n: int) -> void:
	var harm := ["bleed", "poison", "stun", "weaken", "curse", "panic"]
	var left := n
	var keep: Array = []
	for s in u.statuses:
		if left > 0 and s.id in harm:
			left -= 1
			continue
		keep.append(s)
	u.statuses = keep

func enemy_pick(c: Dictionary, actor: Dictionary) -> Dictionary:
	var usable: Array = []
	for id in actor.skills:
		var s: Dictionary = SKILLS[id]
		if can_use(actor, s, c):
			usable.append(s)
	var fb = usable[0] if not usable.is_empty() else null
	var heroes := living(c, "player")
	if heroes.is_empty() or fb == null:
		return {"skill": null, "target": null}
	heroes.sort_custom(func(a, b): return a.hp < b.hp)
	var low = heroes[0]
	if actor.ai == "stress":
		for s in usable:
			if int(s.stress_damage) > 0:
				return {"skill": s, "target": low}
	if actor.ai == "lowhp":
		return {"skill": fb, "target": low}
	if actor.ai == "boss":
		if actor.phase >= 2:
			for s in usable:
				if s.id == "call_faithful" and living(c, "enemy").size() < 3:
					return {"skill": s, "target": actor}
			for s in usable:
				if s.id == "funeral_pyre":
					return {"skill": s, "target": null}
		if actor.phase >= 3:
			for s in usable:
				if s.id == "last_rite":
					return {"skill": s, "target": low}
		for s in usable:
			if s.id == "ash_sermon" and randf() < 0.35:
				return {"skill": s, "target": null}
		for s in usable:
			if s.id == "cinder_strike":
				return {"skill": s, "target": low}
	var pool := valid_targets(actor, fb, c)
	return {"skill": fb, "target": pool[0] if not pool.is_empty() else low}

func use_item(c: Dictionary, actor: Dictionary, def: Dictionary, target: Dictionary) -> void:
	c.fx = []
	c.attacker = actor.id
	c.anim_key = uid("an")
	c.fx = []
	if int(def.get("heal", 0)) > 0:
		target.hp = mini(target.max_hp, target.hp + int(def.heal))
		fx(c, target.id, "+%d" % def.heal, "heal")
	if int(def.get("stress", 0)) != 0:
		add_stress(c, target, -int(def.stress))
	if int(def.get("party_stress", 0)) > 0:
		for a in living(c, "player"):
			add_stress(c, a, -int(def.party_stress))
	if def.has("cleanse"):
		for id in def.cleanse:
			target.statuses = target.statuses.filter(func(s): return s.id != id)
	if def.get("buff", "") != "":
		apply_st(target, {"id": def.buff, "duration": 3, "potency": 30})
	if int(def.get("aoe", 0)) > 0:
		for e in living(c, "enemy"):
			e.hp = maxi(0, e.hp - int(def.aoe))
			fx(c, e.id, "-%d" % def.aoe, "dmg")
			if e.hp <= 0:
				kill(c, e)
	blog(c, "%s использует «%s»." % [actor.name, def.name], "g")
	tick_dots(c, actor)
	c.turn += 1
	c.waiting = false
	_check(c)

func skip(c: Dictionary) -> void:
	var a = actor_of(c)
	if a == null:
		return
	blog(c, "%s выжидает." % a.name)
	tick_dots(c, a)
	c.turn += 1
	c.selected = ""
	c.waiting = false
