class_name BattlePositioning
extends RefCounted
## D-1299/D-1301: where an AI combatant stands (-2..+2). Steps are free and never locked, so position is a pure
## trade-off that the AI re-evaluates continuously. D-018: +10% damage dealt per step FORWARD of the
## attacker, -10% damage taken per step BACK of the target; the multiplier is read at the moment of the hit.
##
## Every candidate position p is scored in "HP-share points" (the scale the AI uses to value Moves):
##   U(p) = offense(p) * audacity            what my strike is worth standing at p (knock-out included)
##        - defense(p) / audacity            what the hits I expect to take cost me at p (death risk included)
##        - price * |p - now|                the step price (agile natures pay little: they flip a lot)
##        - pull * |p - preferred|           the Nature's soft preference (shooter/caster back, brawler front)
## The Nature only changes HOW the terms are weighed (profile()); the combat context changes WHAT enters them:
## the foe's window (busy, stunned, empty ATB), Taunt, the way the fight is going, an ally's hit already in
## flight on the same foe, Guard, and the foe's own Nature (its attack rhythm).

const HORIZON := 4.0  ## Seconds ahead the plan looks at (a high-WIS Nature sees further).
const MOVE_EPS := 1.5  ## Value price of one step walked (before the Nature's agility).
const PULL_SHARE := 0.5  ## The Nature's preferred-position pull, in steps' worth of price.
const MAX_ATTACKS := 3.0
const KO_BONUS := 40.0  ## Same as BattleAI.KO_BONUS.
const BUSY_AFTER_WINDUP := 1.0  ## Run + strike + return after the wind-up (rough).
const BUSY_ATTACKING := 1.5  ## A foe that is attacking cannot throw another one for about this long.
const BEHIND := 0.2  ## Team HP-share gap that counts as "losing" (or "winning").
const RE_THINK := 0.3  ## Seconds between two re-evaluations of one combatant.

var b: Battle
var ai: BattleAI
var _next_think: Dictionary = {}
var _want: Dictionary = {}
var scores: Dictionary = {}  ## Combatant -> {position: utility}, the last table (debug and tests).
var info: Dictionary = {}  ## Combatant -> why it chose what it chose (profile + context), for telemetry/tests.


func _init(p_battle: Battle, p_ai: BattleAI) -> void:
	b = p_battle
	ai = p_ai


func reset() -> void:
	_next_think.clear()
	_want.clear()
	scores.clear()
	info.clear()


## The five axes of a Nature (D-1301), read from fields that already exist. Neutral without a Nature.
static func profile(c: Combatant) -> Dictionary:
	var n: Dictionary = NatureData.get_nature(c.nature_id) if c.nature_id != "" else {}
	var mods: Dictionary = n.get("mods", {})
	var aud := clampf(float(n.get("aggression_mult", 1.0)), 0.5, 1.6)
	var cau := clampf(float(n.get("atb_reserve_bias", 0.0)), -1.0, 1.0)
	var agi := float(mods.get("AGI", 0))
	var wis := float(mods.get("WIS", 0))
	var style := float(mods.get("STR", 0)) - float(mods.get("MAG", 0))  # physical (+) against magical (-)
	return {
		"audacity": aud,
		"caution": cau,
		"step_price": MOVE_EPS * clampf(1.0 - 0.2 * agi, 0.4, 1.6),
		"preferred": clampf(style / 3.0 + (aud - 1.0) * 2.0, -2.0, 2.0),
		"horizon": HORIZON * clampf(1.0 + 0.15 * wis, 0.55, 1.45),
		"foresight": clampf(0.7 + 0.1 * wis, 0.3, 1.0),  # how much of the not-yet-declared threat it counts
	}


## The position `c` wants right now (counting steps already queued).
func desired(c: Combatant, delta: float) -> int:
	var now := c.pos_step + c.queued_step
	var left := float(_next_think.get(c, 0.0)) - delta
	if left > 0.0 and _want.has(c):
		_next_think[c] = left
		return int(_want[c])
	_next_think[c] = RE_THINK
	var prof := profile(c)
	var ctx := _context(c, prof)
	var best := now
	var best_u := -INF
	var table := {}
	for p in range(-Battle.STEP_MAX, Battle.STEP_MAX + 1):
		var u := _utility(c, ctx, prof, p)
		u -= float(prof["step_price"]) * absf(float(p - now))
		u -= float(prof["step_price"]) * PULL_SHARE * absf(float(p) - float(prof["preferred"]))
		table[p] = snappedf(u, 0.01)
		if u > best_u + 0.0001 or (absf(u - best_u) <= 0.0001 and absi(p - now) < absi(best - now)):
			best = p
			best_u = u
	scores[c] = table
	_want[c] = best
	var why: Dictionary = ctx["why"]
	why["from"] = now
	why["to"] = best
	why["table"] = table
	why["profile"] = prof
	info[c] = why
	if best != now:
		b.ai_positioned.emit(c, why)
	return best


# --- Reading the situation (once per decision) -------------------------------------

func _context(c: Combatant, prof: Dictionary) -> Dictionary:
	var foes: Array[Combatant] = []
	for f in b.opponents_of(c):
		if f.is_alive():
			foes.append(f)
	var team := b.team_of(c)
	var allies := 0
	for a in team:
		if a.is_alive():
			allies += 1
	var lead := _hp_lead(c, foes, team)
	# Way the fight is going (D-1301): bold natures double the bet when behind, cautious ones close the defense.
	var off_w := float(prof["audacity"])
	var def_w := 1.0 / float(prof["audacity"])
	var ko_w := 1.0 + 0.5 * float(prof["caution"])
	var mood := "even"
	if lead < -BEHIND:
		mood = "behind"
		if float(prof["audacity"]) >= 1.1 or float(prof["caution"]) < 0.0:
			off_w *= 1.25
		elif float(prof["audacity"]) < 1.0 or float(prof["caution"]) > 0.3:
			def_w *= 1.25
	elif lead > BEHIND:
		mood = "ahead"
		ko_w *= 1.2  # winning: no reason to gamble its life
	var ctx := {"foes": foes, "hp": float(maxi(c.hp, 1)), "mobile": b._can_step_now(c),
			"off": [], "hit_all": false, "n_out": 0.0, "tr": 0.0, "threats": [],
			"off_w": off_w, "def_w": def_w, "ko_w": ko_w, "guard": 0.5 if c.is_guarding() else 1.0,
			"why": {"mood": mood, "hp_lead": snappedf(lead, 0.01)}}
	_read_offense(c, foes, ctx)
	_read_threats(c, foes, maxi(allies, 1), prof, ctx)
	return ctx


## Share of HP my team has minus the opponents' share (-1..+1).
func _hp_lead(c: Combatant, foes: Array[Combatant], team: Array[Combatant]) -> float:
	var mine := 0.0
	var mine_max := 0.0
	for a in team:
		mine += float(maxi(a.hp, 0))
		mine_max += float(maxi(a.max_hp, 1))
	var theirs := 0.0
	var theirs_max := 0.0
	for f in foes:
		theirs += float(maxi(f.hp, 0))
		theirs_max += float(maxi(f.max_hp, 1))
	if mine_max <= 0.0 or theirs_max <= 0.0:
		return 0.0
	return mine / mine_max - theirs / theirs_max


## Damage allies already have in flight on `foe` (so the KO bonus sees the combo, not just my hit).
func _ally_damage_on(c: Combatant, foe: Combatant) -> float:
	var total := 0.0
	for inc in b.active_attacks():
		if inc.target == foe and inc.attacker != c and b.same_team(inc.attacker, c) and inc.kind != Skill.Kind.STATUS and not inc.is_friendly and inc.skill != null:
			total += float(Battle.estimate_damage(inc.attacker, foe, inc.skill))
	return total


## The Move it would use (best value per cost, as the AI scores Moves) and how many times it can use it.
func _read_offense(c: Combatant, foes: Array[Combatant], ctx: Dictionary) -> void:
	var best_score := 0.0
	for s in ai._moves_of(c):
		if s.kind == Skill.Kind.STATUS or s.is_friendly or s.target_mode == MoveData.TargetMode.DUAL or c.mp < s.mp_cost:
			continue
		var hit_all := s.is_aoe or s.aoe_on_contact
		var list := []
		var v0 := 0.0
		for f in foes:
			if f.is_invulnerable_target():
				continue
			var base := float(ai._damage_to(c, s, f)) / DamageMath.step_multiplier(c.pos_step, f.pos_step)
			var hp_eff := maxf(float(f.hp) - _ally_damage_on(c, f), 1.0)  # combo with an ally's hit in flight
			list.append([f, base, hp_eff])
			v0 += _value(base * DamageMath.step_multiplier(0, f.pos_step), hp_eff)
		if list.is_empty():
			continue
		var score := (v0 if hit_all else v0 / float(list.size())) / (1.0 + ai.COST_WEIGHT * s.cost)
		if score > best_score:
			best_score = score
			ctx["off"] = list
			ctx["hit_all"] = hit_all
			var cost := maxf(s.cost, 0.5)
			var pace := maxf(c.speed * Combatant.ATB_PACE_MULT, 0.01)
			if c.burst > 0:
				ctx["n_out"] = minf(float(c.burst) + pace * HORIZON / cost, MAX_ATTACKS)
				ctx["tr"] = 0.0
			else:
				ctx["n_out"] = minf(floorf((c.atb + pace * HORIZON) / cost), MAX_ATTACKS)
				ctx["tr"] = maxf((cost - c.atb) / pace, 0.0)  # seconds until it can strike


## Hits it expects: attacks already in flight (certain, with an arrival time) and the ones each foe can
## still throw inside its horizon, shaped by that foe's window, Taunt and its own Nature.
func _read_threats(c: Combatant, foes: Array[Combatant], allies: int, prof: Dictionary, ctx: Dictionary) -> void:
	var threats: Array = ctx["threats"]
	var declared := {}
	for inc in b.active_attacks():
		if inc.target != c or inc.dodged or inc.is_friendly or inc.kind == Skill.Kind.STATUS or inc.skill == null:
			continue
		declared[inc.attacker] = int(declared.get(inc.attacker, 0)) + 1
		var base := float(Battle.estimate_damage(inc.attacker, c, inc.skill)) / DamageMath.step_multiplier(inc.attacker.pos_step, c.pos_step)
		var eta: float = inc.eta() if inc.resolved else inc.time_left + BattleAI.UNRESOLVED_ETA
		threats.append({"pos": inc.attacker.pos_step, "base": base, "n": 1.0, "eta": eta})
	var horizon := float(prof["horizon"])
	for f in foes:
		var best_d := 0.0
		var best_cost := 1.0
		var aoe := false
		for s in ai._moves_of(f):
			if s.kind == Skill.Kind.STATUS or s.is_friendly or s.target_mode == MoveData.TargetMode.DUAL or f.mp < s.mp_cost:
				continue
			var d := float(ai._damage_to(f, s, c))
			if d > best_d:
				best_d = d
				best_cost = maxf(s.cost, 0.5)
				aoe = s.is_aoe or s.aoe_on_contact
		if best_d <= 0.0:
			continue
		# The foe's window: time it cannot attack (busy with its own attack, stunned) shortens its horizon.
		var window := horizon - (BUSY_ATTACKING if b.is_attacking(f) else 0.0) - maxf(f.stun_timer, 0.0)
		var fp := profile(f)
		var pace := maxf(f.speed * Combatant.ATB_PACE_MULT, 0.01)
		var n := clampf((f.atb + pace * maxf(window, 0.0)) / best_cost, 0.0, MAX_ATTACKS) - float(declared.get(f, 0))
		n *= clampf(float(fp["audacity"]), 0.7, 1.4) * (1.0 - 0.15 * float(fp["caution"]))  # its own Nature's rhythm
		# Taunt (D-032): a taunted foe can only hit its taunter.
		var share := 1.0 if aoe else 1.0 / float(allies)
		if f.taunted_by != null and f.taunted_by.is_alive() and not aoe:
			share = 1.0 if f.taunted_by == c else 0.0
		n = maxf(n, 0.0) * share * float(prof["foresight"])  # only what it can foresee beyond what is declared
		if n > 0.0:
			threats.append({"pos": f.pos_step, "base": best_d / DamageMath.step_multiplier(f.pos_step, c.pos_step), "n": n})


# --- Scoring a position ---------------------------------------------------------------

## `pos_step` changes at once (the walk is only the animation) and a combatant cannot step while it attacks,
## so the position it has when it STARTS a strike is the one the hit gets, and it keeps it until it is idle again.
func _utility(c: Combatant, ctx: Dictionary, prof: Dictionary, p: int) -> float:
	var off := 0.0
	var striking := float(ctx["n_out"]) >= 1.0 and float(ctx["tr"]) <= Battle.STEP_TIME
	var busy := Battle.base_windup() + BUSY_AFTER_WINDUP  # how long a strike pins it where it stands
	if striking:
		var total := 0.0
		var count := 0
		for pair in ctx["off"]:
			var f: Combatant = pair[0]
			total += _value(float(pair[1]) * DamageMath.step_multiplier(p, f.pos_step), float(pair[2]))
			count += 1
		if count > 0:
			off = total if bool(ctx["hit_all"]) else total / float(count)
	var hp: float = ctx["hp"]
	var ko_w: float = ctx["ko_w"]
	var def := 0.0
	var expected := 0.0
	for t in ctx["threats"]:
		var w := 1.0
		var p_t := p
		var certain: bool = t.has("eta")
		if certain:
			var eta := float(t["eta"])
			if striking and eta > busy:
				continue  # lands after it is idle again: it can fix its position then
			# Already in flight: the step has to finish (STEP_TIME) before it lands, and only an idle unit walks.
			if eta < Battle.STEP_TIME or not bool(ctx["mobile"]):
				p_t = c.pos_step
			w = 1.0 + 0.3 * float(prof["caution"])  # cautious natures take a dodge-step more seriously
		elif striking:
			w = minf(busy / float(prof["horizon"]), 1.0)  # only the part of the horizon it is pinned
		var d := float(t["base"]) * DamageMath.step_multiplier(int(t["pos"]), p_t) * float(ctx["guard"])
		var n := float(t["n"]) * w
		def += n * minf(d, hp) / hp * 100.0
		if d >= hp:
			def += n * KO_BONUS * ko_w  # a hit that kills
		expected += n * d
	def += KO_BONUS * ko_w * pow(clampf(expected / hp, 0.0, 1.0), 2.0)  # the closer to dying, the more every point counts
	return off * float(ctx["off_w"]) - def * float(ctx["def_w"])


func _value(damage: float, hp: float) -> float:
	var v := minf(damage, hp) / maxf(hp, 1.0) * 100.0
	return v + (KO_BONUS if damage >= hp else 0.0)
