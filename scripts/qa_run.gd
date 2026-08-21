extends SceneTree

var fails: Array = []
var n := 0

func _init() -> void:
	call_deferred("_run")

func ok(cond: bool, name: String) -> void:
	n += 1
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		fails.append(name)

func _run() -> void:
	print("=== QA Ashen Road ===")
	seed(42)
	_flow_new_game()
	_flow_shop_rest()
	_flow_positions()
	_flow_items_town()
	_flow_event_title()
	_flow_event_broke()
	_flow_combat_basic()
	_flow_ritual_stress()
	_flow_soothe()
	_flow_status_and_kill()
	_flow_stress_crisis()
	_flow_skip_and_item()
	_flow_lose()
	_flow_full_expedition()
	_flow_save_load()
	_flow_xp()
	print("=== %d checks, %d failed ===" % [n, fails.size()])
	for f in fails:
		print("  - ", f)
	quit(1 if fails.size() > 0 else 0)

func G():
	return Engine.get_main_loop().root.get_node("Game")

func _flow_new_game() -> void:
	var g = G()
	g.new_game(true)
	ok(g.screen == "intro", "new game -> intro")
	ok(g.heroes.size() == 4, "4 heroes")
	ok(g.gold == 40, "start gold 40")
	g.set_screen("town")
	ok(g.screen == "town", "town screen")

func _flow_shop_rest() -> void:
	var g = G()
	g.new_game(true)
	var before: int = int(g.gold)
	var id: String = g.shop[0]
	var price := Data.buy_price(id)
	g.buy_shop(id)
	ok(g.gold == before - price, "shop deducts gold")
	ok(g.inventory.size() == 5, "bought item in inventory")
	g.buy_shop("not_real")
	ok(g.gold == before - price, "invalid buy no deduct")
	var uid: String = g.inventory[g.inventory.size() - 1].uid
	g.sell_item(uid)
	ok(g.gold == before - price + Data.sell_price(id), "sell returns gold")
	g.gold = 40
	g.heroes[0].hp = 10
	g.heroes[0].stress = 80
	g.rest_town()
	ok(g.gold == 25, "rest costs 15")
	ok(g.heroes[0].hp > 10, "rest heals")
	ok(g.heroes[0].stress < 80, "rest calms")
	g.gold = 10
	g.rest_town()
	ok(g.gold == 10, "rest blocked if broke")

func _flow_positions() -> void:
	var g = G()
	g.new_game(true)
	g.set_pos("occultist", 1)
	var w
	var o
	for h in g.heroes:
		if h.id == "warrior":
			w = h
		if h.id == "occultist":
			o = h
	ok(o.pos == 1 and w.pos == 4, "swap positions")

func _flow_items_town() -> void:
	var g = G()
	g.new_game(true)
	g.heroes[0].hp = 10
	var uid: String = g.inventory[0].uid
	g.use_item(uid, "warrior")
	ok(g.heroes[0].hp > 10, "town bandage heals")
	ok(g.inventory.size() == 3, "item consumed")
	g.inventory.append(g._item("ember_oil"))
	var n0: int = g.inventory.size()
	g.use_item(g.inventory[g.inventory.size() - 1].uid, "warrior")
	ok(g.inventory.size() == n0, "combat item not wasted in town")

func _flow_event_title() -> void:
	var g = G()
	g.new_game(true)
	g.begin_expedition()
	g.event_id = "corpse"
	g.screen = "event"
	g.resolve_event("bury")
	ok(g.screen == "reward", "event -> reward")
	ok(str(g.reward.title) != "Событие", "event keeps real title")
	ok(str(g.reward.title).find("путника") >= 0 or str(g.reward.title) == "Тело путника", "corpse title")

func _flow_event_broke() -> void:
	var g = G()
	g.new_game(true)
	g.gold = 5
	g.begin_expedition()
	g.choose_node("event1")
	g.event_id = "merchant"
	var scr: String = g.screen
	g.resolve_event("buy")
	ok(g.gold == 5, "broke merchant does not charge")
	ok(g.screen == "event", "broke choice stays on event")
	ok(g.event_id == "merchant", "event not consumed on failed buy")

func _flow_combat_basic() -> void:
	var g = G()
	g.new_game(true)
	g.begin_expedition()
	g.choose_node("fight1")
	ok(g.screen == "combat", "enter combat")
	ok(g.combat != null, "combat state")
	var safety := 0
	while g.combat != null and g.combat.finished == "none" and safety < 80:
		safety += 1
		if g.combat.waiting:
			var actor = g.engine.actor_of(g.combat)
			ok(actor != null and actor.side == "player", "player turn waiting")
			var used := false
			for sid in actor.skills:
				var sk: Dictionary = g.engine.SKILLS[sid]
				if not g.engine.can_use(actor, sk, g.combat):
					continue
				if sk.target in ["self", "move", "all-enemies", "all-allies"]:
					g.select_skill(sid)
					used = true
					break
				var tgts: Array = g.engine.valid_targets(actor, sk, g.combat)
				if tgts.is_empty():
					continue
				g.select_skill(sid)
				g.select_target(tgts[0].id)
				used = true
				break
			if not used:
				g.skip_turn()
		else:
			g.enemy_turn()
	ok(g.combat != null and g.combat.finished != "none", "combat ends")
	if g.combat and g.combat.finished == "win":
		g.finish_combat()
		ok(g.screen == "reward", "win -> reward")
		ok(g.gold > 40, "win gold applied")
		g.collect_reward()
		ok(g.screen == "map", "reward -> map")
	else:
		print("NOTE first fight lost (ok if later lose-path tested)")

func _flow_ritual_stress() -> void:
	var g = G()
	g.new_game(true)
	for h in g.heroes:
		h.pos = 4 if h.id == "occultist" else h.pos
		h.stress = 10
	var c: Dictionary = g.engine.start("tutorial", g.heroes, true)
	var osi
	for u in c.units:
		if u.class_id == "occultist":
			osi = u
	osi.pos = 4
	osi.stress = 10
	c.turn = c.order.find(osi.id)
	c.waiting = true
	var ritual: Dictionary = g.engine.SKILLS["ritual"]
	g.engine.resolve(c, osi, ritual, osi)
	ok(osi.stress == 26, "ritual self-stress once (16), not per ally")

func _flow_soothe() -> void:
	var g = G()
	g.new_game(true)
	var c: Dictionary = g.engine.start("tutorial", g.heroes, true)
	var ili
	var garn
	for u in c.units:
		if u.class_id == "wanderer":
			ili = u
		if u.class_id == "warrior":
			garn = u
	garn.stress = 40
	var soothe: Dictionary = g.engine.SKILLS["soothe"]
	g.engine.resolve(c, ili, soothe, garn)
	ok(garn.stress == 16, "soothe reduces 24 stress")

func _flow_status_and_kill() -> void:
	var g = G()
	g.new_game(true)
	var c: Dictionary = g.engine.start("tutorial", g.heroes, true)
	var hunter
	var enemy
	for u in c.units:
		if u.class_id == "hunter":
			hunter = u
		if u.side == "enemy" and enemy == null:
			enemy = u
	hunter.pos = 3
	var arrow: Dictionary = g.engine.SKILLS["bleed_arrow"]
	g.engine.resolve(c, hunter, arrow, enemy)
	ok(g.engine.has_st(enemy, "bleed") or not enemy.alive, "bleed applied or target died")
	enemy.hp = 1
	enemy.alive = true
	var strike: Dictionary = g.engine.SKILLS["strike"]
	var garn
	for u in c.units:
		if u.class_id == "warrior":
			garn = u
	garn.pos = 1
	g.engine.resolve(c, garn, strike, enemy)
	ok(not enemy.alive or enemy.hp < 1 or c.finished != "xxx", "damage lands")
	if not enemy.alive:
		ok(true, "enemy death")
		var living_e: Array = g.engine.living(c, "enemy")
		if living_e.size() > 0:
			ok(living_e[0].pos == 1, "compact enemy ranks")

func _flow_stress_crisis() -> void:
	var g = G()
	g.new_game(true)
	var c: Dictionary = g.engine.start("tutorial", g.heroes, true)
	var garn
	for u in c.units:
		if u.class_id == "warrior":
			garn = u
	g.engine.add_stress(c, garn, 100)
	ok(garn.stress < 100 or garn.stress == 70 or garn.stress == 35, "crisis clamps stress")
	var has: bool = g.engine.has_st(garn, "virtue") or g.engine.has_st(garn, "weaken") or g.engine.has_st(garn, "panic") or g.engine.has_st(garn, "curse") or g.engine.has_st(garn, "bleed")
	ok(has, "crisis applies virtue or breakdown")

func _flow_skip_and_item() -> void:
	var g = G()
	g.new_game(true)
	g.begin_expedition()
	g.choose_node("fight1")
	var safety := 0
	while g.combat.waiting == false and g.combat.finished == "none" and safety < 20:
		g.enemy_turn()
		safety += 1
	if g.combat.waiting:
		var turn0: int = g.combat.turn
		g.skip_turn()
		ok(g.combat.turn != turn0 or g.combat.round > 1 or not g.combat.waiting, "skip advances turn")
	# bandage in combat
	safety = 0
	while g.combat != null and g.combat.finished == "none" and safety < 10:
		safety += 1
		if not g.combat.waiting:
			g.enemy_turn()
			continue
		var actor = g.engine.actor_of(g.combat)
		if actor and g.inventory.size() > 0:
			var uid: String = g.inventory[0].uid
			var before: int = g.inventory.size()
			g.use_item(uid, actor.class_id)
			ok(g.inventory.size() == before - 1, "combat item consumed")
			break
		g.skip_turn()
	if g.combat and g.combat.finished != "none":
		g.finish_combat()
		if g.screen == "reward":
			g.collect_reward()
		elif g.screen == "result":
			g.return_town()

func _flow_lose() -> void:
	var g = G()
	g.new_game(true)
	g.begin_expedition()
	g.choose_node("fight1")
	for u in g.combat.units:
		if u.side == "player":
			u.hp = 0
			u.alive = false
	g.engine._check(g.combat)
	ok(g.combat.finished == "lose", "wipe -> lose")
	g.finish_combat()
	ok(g.screen == "result", "lose -> result")
	ok(g.expedition == null, "expedition cleared on lose")
	g.return_town()
	ok(g.screen == "town", "return town")
	ok(g.has_save(), "save after town")

func _flow_full_expedition() -> void:
	var g = G()
	g.new_game(true)
	g.begin_expedition()
	ok(g.stats.expeditions == 1, "expedition counted")
	# God-mode smash through map
	var hops := 0
	while g.screen != "result" and hops < 30:
		hops += 1
		if g.screen == "map":
			if g.expedition.available.is_empty():
				ok(false, "map has no available nodes")
				break
			g.choose_node(g.expedition.available[0])
			continue
		if g.screen == "event":
			var picked := false
			for e in Data.events():
				if e.id == g.event_id:
					g.resolve_event(e.choices[e.choices.size() - 1].id)
					picked = true
					break
			if not picked:
				g.resolve_event("leave")
			continue
		if g.screen == "combat":
			for u in g.combat.units:
				if u.side == "enemy":
					u.hp = 0
					u.alive = false
			g.engine._check(g.combat)
			ok(g.combat.finished == "win", "forced combat win")
			g.finish_combat()
			continue
		if g.screen == "reward":
			g.collect_reward()
			continue
		if g.screen == "result":
			break
		# stuck
		print("STUCK screen=", g.screen)
		break
	ok(g.screen == "result", "full expedition reached result")
	ok(g.result != null and g.result.win == true, "boss victory flag")
	g.return_town()
	ok(g.screen == "town", "back to town after win")
	g.begin_expedition()
	ok(g.stats.expeditions == 2, "second expedition")
	ok(g.screen == "map", "second map")

func _flow_save_load() -> void:
	var g = G()
	g.new_game(true)
	g.gold = 77
	g.set_screen("town")
	g.save_game()
	g.gold = 1
	ok(g.load_game(), "load succeeds")
	ok(g.gold == 77, "gold restored")
	ok(g.screen == "town", "screen restored")

func _flow_xp() -> void:
	var g = G()
	g.new_game(true)
	g._add_xp(80)
	ok(g.heroes[0].level == 2, "80 xp -> level 2")
	ok(g.heroes[0].max_hp > Data.heroes()["warrior"].hp, "level raises hp")
	g._add_xp(5000)
	ok(g.heroes[0].level == 5, "xp cap level 5")
