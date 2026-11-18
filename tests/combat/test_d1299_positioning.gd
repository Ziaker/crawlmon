extends SceneTree
## D-1299: strategic positioning of the AI. Logic only, both sides (D-235):
##   Godot --headless --path . --script res://tests/combat/test_d1299_positioning.gd

var _fails := 0


func _init() -> void:
	for me_is_player in [true, false]:
		print("== me on ", "party" if me_is_player else "enemy", " side")
		_hit_and_run(me_is_player)
		_finisher(me_is_player)
		_dodge_by_step(me_is_player)
		_healer_stays_back(me_is_player)
		_survival(me_is_player)
	print("RESULT: ", "PASS" if _fails == 0 else "FAIL (%d)" % _fails)
	quit(1 if _fails > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	print(("  ok  " if cond else "  FAIL ") + msg)
	if not cond:
		_fails += 1


## Me (AI-controlled) vs one foe; a bystander leads the player's team so `me` is never the menu owner.
func _setup(me_is_player: bool, my_hp := 100, my_atk := 10, foe_hp := 100, foe_atk := 10) -> Array:
	var me := Combatant.new("Me", my_hp, my_atk, 1.0, me_is_player)
	var foe := Combatant.new("Foe", foe_hp, foe_atk, 1.0, not me_is_player)
	var lead := Combatant.new("Lead", 400, 1, 1.0, true)
	var party: Array[Combatant] = []
	var enemies: Array[Combatant] = []
	party.append(lead)
	if me_is_player:
		party.append(me)
		enemies.append(foe)
	else:
		foe.is_player = true
		party.append(foe)
		enemies.append(me)
	var b := Battle.new()
	b.start(party, enemies)
	for c in [me, foe, lead]:
		c.in_battle = true
	return [b, me, foe]


func _want(b: Battle, me: Combatant) -> int:
	var w: int = b._ai.positioning.desired(me, 10.0)
	print("     table ", b._ai.positioning.scores[me], " -> ", w)
	return w


func _hit_and_run(side: bool) -> void:
	print("hit-and-run")
	var s := _setup(side, 100, 10, 100, 45)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	foe.atb = 5.0
	me.atb = 0.0  # just struck: far from the next one
	_ok(_want(b, me) < 0, "empty ATB with a loaded foe: backs off")
	# Ready to strike: the bonus is read at the hit, so it matters now. Who gains more decides.
	s = _setup(side, 100, 40, 100, 10)  # I hit much harder than I am hit: go forward
	b = s[0]
	me = s[1]
	foe = s[2]
	foe.atb = 5.0
	me.atb = 5.0
	var w := _want(b, me)
	_ok(w > 0, "ready to strike, foe weaker: goes forward for the bonus (want %d)" % w)
	s = _setup(side, 100, 10, 100, 45)  # the foe hits much harder than me: staying back pays more than +10%
	b = s[0]
	me = s[1]
	foe = s[2]
	foe.atb = 5.0
	me.atb = 5.0
	w = _want(b, me)
	_ok(w < 0, "ready to strike, foe much stronger: the defense bonus is worth more (want %d)" % w)


func _finisher(side: bool) -> void:
	print("finisher push")
	var s := _setup(side, 100, 10, 100, 1)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	foe.atb = 0.0
	me.atb = 4.2  # strike in under a step-time of walking budget: 0.8 blocks to go
	var base := Battle.estimate_damage(me, foe, Skill.basic())
	foe.hp = base + 1  # one point short at +0, enough with +10%
	foe.max_hp = 100
	var w := _want(b, me)
	_ok(w >= 1, "one step forward turns the hit into a knock-out: walks forward (want %d)" % w)


func _dodge_by_step(side: bool) -> void:
	print("dodge by step")
	var s := _setup(side, 100, 1, 400, 30)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	me.atb = 0.0
	foe.atb = 0.0
	foe.atb = 5.0
	b.use_skill(foe, Skill.basic(), me)
	foe.atb = 0.0
	_ok(b.incoming.size() == 1, "foe declared an attack on me")
	var w := _want(b, me)
	_ok(w < 0, "attack in flight, nothing to strike with: steps back (want %d)" % w)


func _healer_stays_back(side: bool) -> void:
	print("support stays back")
	var s := _setup(side, 100, 10, 100, 30)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	foe.atb = 5.0
	me.skills = []  # no damaging Move at all
	me.act_policy = Combatant.Act.HOLD
	# HOLD still resolves the basic Tackle through _moves_of; make the foe's offense the only term instead.
	var w := _want(b, me)
	_ok(w <= me.pos_step, "never walks into a loaded foe when it has little to gain (want %d)" % w)


func _survival(side: bool) -> void:
	print("survival")
	var s := _setup(side, 100, 10, 100, 12)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	foe.atb = 5.0
	me.hp = maxi(int(Battle.estimate_damage(foe, me, Skill.basic()) * 0.9), 1)  # 90% of one hit: only the step back saves it
	me.atb = 5.0
	me.pos_step = 0
	var w := _want(b, me)
	_ok(w < 0, "about to be killed: retreats even with a strike ready (want %d)" % w)
