class_name BattlePositioning
extends RefCounted
## D-1299: where an AI combatant stands (-2..+2). Steps are free and never locked, so position is a pure
## trade-off that the AI re-evaluates continuously. D-018: +10% damage dealt per step FORWARD of the
## attacker, -10% damage taken per step BACK of the target; the multiplier is read at the moment of the hit.
##
## Every candidate position p is scored in "HP-share points" (the same scale the AI uses to value Moves):
##   U(p) = what my next attacks are worth standing at p      (offense, KO included)
##        - what the hits I expect to take cost me at p       (defense, incl. death risk)
##        - a small price per step walked                     (stops jitter)
## What falls out of that, with no per-role rule:
##   * hit-and-run: right after attacking its ATB is empty, so nothing to gain forward: it backs off, and it
##     starts walking forward early enough (steps take Battle.STEP_TIME each) to be in place when ATB is ready;
##   * dodge-by-step: an attack already in flight at me is certain damage; if I am idle and there is time to
##     step back before it lands, backing off pays; I come back forward for my own strike;
##   * finisher push: the extra +10%/step that turns a hit into a knock-out is worth the KO bonus;
##   * survival: when expected damage threatens to kill, the death-risk term pulls it back;
##   * roles emerge: a healer/buffer has no offense term, so it stays back whenever there is a threat.

const HORIZON := 4.0  ## Seconds ahead the plan looks at (attacks it can throw / expects to take).
const MOVE_EPS := 1.5  ## Value price of each step walked.
const MAX_ATTACKS := 3.0
const KO_BONUS := 40.0  ## Same as BattleAI.KO_BONUS.
const BUSY_AFTER_WINDUP := 1.0  ## Run + strike + return after the wind-up (rough).
const RE_THINK := 0.3  ## Seconds between two re-evaluations of one combatant.

var b: Battle
var ai: BattleAI
var _next_think: Dictionary = {}
var _want: Dictionary = {}
var scores: Dictionary = {}  ## Combatant -> {position: utility}, the last table (debug and tests).


func _init(p_battle: Battle, p_ai: BattleAI) -> void:
	b = p_battle
	ai = p_ai


func reset() -> void:
	_next_think.clear()
	_want.clear()
	scores.clear()


## The position `c` wants right now (counting steps already queued).
func desired(c: Combatant, delta: float) -> int:
	var now := c.pos_step + c.queued_step
	var left := float(_next_think.get(c, 0.0)) - delta
	if left > 0.0 and _want.has(c):
		_next_think[c] = left
		return int(_want[c])
	_next_think[c] = RE_THINK
	var ctx := _context(c)
	var best := now
	var best_u := -INF
	var table := {}
	for p in range(-Battle.STEP_MAX, Battle.STEP_MAX + 1):
		var u := _utility(c, ctx, now, p) - MOVE_EPS * absf(float(p - now))
		table[p] = snappedf(u, 0.01)
		if u > best_u + 0.0001 or (absf(u - best_u) <= 0.0001 and absi(p - now) < absi(best - now)):
			best = p
			best_u = u
	scores[c] = table
	_want[c] = best
	return best


# --- Reading the situation (once per decision) -------------------------------------

func _context(c: Combatant) -> Dictionary:
	var foes: Array[Combatant] = []
	for f in b.opponents_of(c):
		if f.is_alive():
			foes.append(f)
	var allies := 0
	for a in b.team_of(c):
		if a.is_alive():
			allies += 1
	var ctx := {"foes": foes, "hp": float(maxi(c.hp, 1)), "mobile": b._can_step_now(c),
			"off": [], "hit_all": false, "n_out": 0.0, "tr": 0.0, "threats": []}
	_read_offense(c, foes, ctx)
	_read_threats(c, foes, maxi(allies, 1), ctx)
	return ctx


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
			list.append([f, base])
			v0 += _value(base * DamageMath.step_multiplier(0, f.pos_step), float(f.hp))
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
## still throw inside the horizon (spread over the targets it may pick).
func _read_threats(c: Combatant, foes: Array[Combatant], allies: int, ctx: Dictionary) -> void:
	var threats: Array = ctx["threats"]
	var declared := {}
	for inc in b.active_attacks():
		if inc.target != c or inc.dodged or inc.is_friendly or inc.kind == Skill.Kind.STATUS or inc.skill == null:
			continue
		declared[inc.attacker] = int(declared.get(inc.attacker, 0)) + 1
		var base := float(Battle.estimate_damage(inc.attacker, c, inc.skill)) / DamageMath.step_multiplier(inc.attacker.pos_step, c.pos_step)
		var eta: float = inc.eta() if inc.resolved else inc.time_left + BattleAI.UNRESOLVED_ETA
		threats.append({"pos": inc.attacker.pos_step, "base": base, "n": 1.0, "eta": eta})
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
		var pace := maxf(f.speed * Combatant.ATB_PACE_MULT, 0.01)
		var n := clampf((f.atb + pace * HORIZON) / best_cost, 0.0, MAX_ATTACKS) - float(declared.get(f, 0))
		if f.is_stunned():
			n *= 0.5
		n *= 1.0 if aoe else 1.0 / float(allies)  # it picks its target at random among my team
		if n > 0.0:
			threats.append({"pos": f.pos_step, "base": best_d / DamageMath.step_multiplier(f.pos_step, c.pos_step), "n": n})


# --- Scoring a position ---------------------------------------------------------------

## `pos_step` changes at once (the walk is only the animation) and a combatant cannot step while it attacks,
## so the position it has when it STARTS a strike is the one the hit gets, and it keeps it until it is idle again.
func _utility(c: Combatant, ctx: Dictionary, now: int, p: int) -> float:
	var u := 0.0
	var striking := float(ctx["n_out"]) >= 1.0 and float(ctx["tr"]) <= Battle.STEP_TIME
	var busy := Battle.base_windup() + BUSY_AFTER_WINDUP  # how long a strike pins it where it stands
	if striking:
		var total := 0.0
		var count := 0
		for pair in ctx["off"]:
			var f: Combatant = pair[0]
			total += _value(float(pair[1]) * DamageMath.step_multiplier(p, f.pos_step), float(f.hp))
			count += 1
		if count > 0:
			u += total if bool(ctx["hit_all"]) else total / float(count)
	var hp: float = ctx["hp"]
	var expected := 0.0
	for t in ctx["threats"]:
		var w := 1.0
		var p_t := p
		if t.has("eta"):
			var eta := float(t["eta"])
			if striking and eta > busy:
				continue  # lands after it is idle again: it can fix its position then
			# Already in flight: the step has to finish (STEP_TIME) before it lands, and only an idle unit walks.
			if eta < Battle.STEP_TIME or not bool(ctx["mobile"]):
				p_t = c.pos_step
		elif striking:
			w = minf(busy / HORIZON, 1.0)  # only the part of the horizon it is pinned
		var d := float(t["base"]) * DamageMath.step_multiplier(int(t["pos"]), p_t)
		var n := float(t["n"]) * w
		u -= n * minf(d, hp) / hp * 100.0
		if d >= hp:
			u -= n * KO_BONUS  # a hit that kills
		expected += n * d
	u -= KO_BONUS * pow(clampf(expected / hp, 0.0, 1.0), 2.0)  # the closer to dying, the more every point counts
	return u


func _value(damage: float, hp: float) -> float:
	var v := minf(damage, hp) / maxf(hp, 1.0) * 100.0
	return v + (KO_BONUS if damage >= hp else 0.0)
