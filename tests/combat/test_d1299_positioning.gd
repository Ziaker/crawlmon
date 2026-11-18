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
		_nature_axes_and_choice(me_is_player)
		_context_signals(me_is_player)
		_target_choice(me_is_player)
		_telemetry_signal(me_is_player)
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


func _want_quiet(b: Battle, me: Combatant) -> int:
	return b._ai.positioning.desired(me, 10.0)


## Same situation, different Nature: the bold brawler stands further forward than the shy caster.
func _nature_axes_and_choice(side: bool) -> void:
	print("Nature (D-1301)")
	var adamant := BattlePositioning.profile(_with_nature(side, "adamant"))
	var modest := BattlePositioning.profile(_with_nature(side, "modest"))
	var timid := BattlePositioning.profile(_with_nature(side, "timid"))
	var jolly := BattlePositioning.profile(_with_nature(side, "jolly"))
	var brave := BattlePositioning.profile(_with_nature(side, "brave"))
	_ok(float(adamant["preferred"]) > float(modest["preferred"]) and float(adamant["audacity"]) > float(timid["audacity"]), "brawler prefers the front, caster/timid the back (%.2f vs %.2f)" % [adamant["preferred"], modest["preferred"]])
	_ok(float(jolly["step_price"]) < float(brave["step_price"]), "agile Nature pays less per step (%.2f < %.2f)" % [jolly["step_price"], brave["step_price"]])
	var wants := {}
	for nat in ["adamant", "timid", "modest"]:
		var s := _setup(side, 100, 20, 100, 20)
		var b: Battle = s[0]
		var me: Combatant = s[1]
		var foe: Combatant = s[2]
		me.nature_id = nat
		foe.atb = 2.0
		me.atb = 5.0
		wants[nat] = _want_quiet(b, me)
	print("     wants ", wants)
	_ok(int(wants["adamant"]) >= int(wants["timid"]) and int(wants["adamant"]) > int(wants["modest"]), "same fight: Adamant stands further forward than Timid and Modest")


func _with_nature(side: bool, nat: String) -> Combatant:
	var c := Combatant.new("N", 100, 10, 1.0, side)
	c.nature_id = nat
	return c


func _context_signals(side: bool) -> void:
	print("context")
	# A stunned foe cannot hit me: more room to be forward than against the same foe awake.
	var s := _setup(side, 100, 20, 100, 40)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	foe.atb = 5.0
	me.atb = 2.0
	var awake := _want_quiet(b, me)
	s = _setup(side, 100, 20, 100, 40)
	b = s[0]
	me = s[1]
	foe = s[2]
	foe.atb = 5.0
	foe.stun_timer = 6.0
	me.atb = 2.0
	var stunned := _want_quiet(b, me)
	_ok(stunned >= awake, "stunned foe: it stands at least as far forward as against an awake one (%d vs %d)" % [stunned, awake])
	# Taunt: a foe forced onto somebody else cannot hit me.
	s = _setup(side, 100, 20, 100, 40)
	b = s[0]
	me = s[1]
	foe = s[2]
	foe.atb = 5.0
	me.atb = 2.0
	foe.taunted_by = b.team_of(foe)[0] if b.opponents_of(foe).size() > 0 and b.opponents_of(foe)[0] != me else b.opponents_of(foe)[0]
	var other: Combatant = null
	for a in b.team_of(me):
		if a != me:
			other = a
	if other == null:
		other = Combatant.new("Other", 400, 1, 1.0, side)
		b.team_of(me).append(other)
		other.in_battle = true
	foe.taunted_by = other
	var taunted := _want_quiet(b, me)
	_ok(taunted >= awake, "foe taunted onto an ally: it can go forward (%d vs %d)" % [taunted, awake])
	# Mood: my team nearly dead against a healthy foe is "behind".
	s = _setup(side, 100, 20, 100, 20)
	b = s[0]
	me = s[1]
	foe = s[2]
	for a in b.team_of(me):
		a.hp = 10
	_want_quiet(b, me)
	_ok(String(b._ai.positioning.info[me]["mood"]) == "behind", "team far behind in HP is read as 'behind'")


func _target_choice(side: bool) -> void:
	print("target choice")
	var me := Combatant.new("Me", 100, 30, 1.0, side)
	var near := Combatant.new("Near", 100, 10, 1.0, not side)
	var back := Combatant.new("Back", 100, 10, 1.0, not side)
	var lead := Combatant.new("Lead", 400, 1, 1.0, true)
	var mine: Array[Combatant] = []
	var theirs: Array[Combatant] = []
	if side:
		mine = [lead, me]
		theirs = [near, back]
	else:
		near.is_player = true
		back.is_player = true
		mine = [lead, near, back]
		theirs = [me]
		# `me` is the enemy: its foes are the party members, one standing back
	var b := Battle.new()
	b.start(mine, theirs)
	for c in [me, near, back, lead]:
		c.in_battle = true
	back.pos_step = -2  # takes 20% less from me
	var counts := {"near": 0, "back": 0}
	for i in 600:
		var t: Combatant = b._ai._pick_target(me)
		if t == near:
			counts["near"] += 1
		elif t == back:
			counts["back"] += 1
	print("     picks ", counts)
	_ok(float(counts["near"]) > 1.2 * float(counts["back"]) and counts["back"] > 0, "leans to the foe that is not backing away, but never deterministic")


func _telemetry_signal(side: bool) -> void:
	print("telemetry")
	var s := _setup(side, 100, 40, 100, 10)
	var b: Battle = s[0]
	var me: Combatant = s[1]
	var foe: Combatant = s[2]
	foe.atb = 5.0
	me.atb = 5.0
	var seen := {"n": 0, "keys": []}
	b.ai_positioned.connect(func(_c, why: Dictionary): seen["n"] += 1; seen["keys"] = why.keys())
	_want_quiet(b, me)
	_ok(int(seen["n"]) == 1 and seen["keys"].has("table") and seen["keys"].has("profile"), "pos_decision signal carries the score table and the profile")
