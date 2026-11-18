class_name Battle
extends Node
## ATB battle rules. Every combatant has a 5-block gauge that fills over time.
## Skills cost 2 blocks, items 1. Every attack, from either side, takes a moment
## to land; Evade (3 blocks) dodges one and grants a burst (free extra action).
## Every hit also has an automatic evade chance based on the target's speed
## (grants +1 ATB block). party[0] is the player-controlled leader; every other
## combatant, allies and enemies alike, follows its Tactics (act/react policy).

signal log_message(text: String)
signal battle_ended(player_won: bool)
signal state_changed
## Visual events (consumed by BattleFx). `inc` is an Incoming.
signal attack_telegraphed(inc)
signal attack_resolved(inc)
signal attack_cancelled(inc)
## One attack = one timeline owned by this node: PREPARO (WINDUP) -> TRAJETO (TRAVEL) ->
## GOLPE (STRIKE) -> RETORNO (RETURN). BattleFx only draws the progress it reads here.
signal attack_phase(inc, phase: int)  ## `inc` entered `phase` (Battle.Phase).
signal manual_evaded(actor: Combatant, inc)
signal evade_mistimed(actor: Combatant, inc)  ## D-1015: a dodge pressed outside the valid window (it did not dodge)
## A status move paused the engine (D-031) / the engine runs again.
signal status_pause_started(inc)
signal status_pause_ended(inc)
## A perfect Evade during its own run: `actor` jumped from `from` to the front of `opponent`.
signal evade_teleported(actor: Combatant, opponent: Combatant, from: Vector3)
## A non-perfect Evade during its own run: the run was cancelled and `actor` is back home.
signal evade_returned(actor: Combatant, from: Vector3)
signal stepped(actor: Combatant, to_pos: int)  ## `actor` started a position step.
signal ai_positioned(actor: Combatant, why: Dictionary)  ## D-1301: the AI chose a new position (scores and reasons, for telemetry).
## `actor` dodged `opponent`'s attack on its way in: the attack is interrupted and `actor`
## is now next to it. BattleFx draws the arrival.
signal engaged(actor: Combatant, opponent: Combatant, inc)
## The engaged state is over: `actor` (ghost) and the staggered attack (`staggered`, may be
## null) return home. BattleFx fills their `plan`.
signal engage_ended(actor: Combatant, opponent: Combatant, ghost, staggered)
signal evade_whiffed(actor: Combatant, inc)
signal hit_resolved(attacker: Combatant, target: Combatant, element: Element.Type, info: Dictionary)
signal healed(actor: Combatant, target: Combatant, amount: int)
signal attack_clashed(inc_a, inc_b, point: Vector3, mutual: bool)  ## D-279: two opposing runners bumped into each other.
signal attack_interrupted(inc)  ## A hit stopped an attack on its way: BattleFx fills its recovery plan.
signal action_interrupted(actor: Combatant)  ## D-1105: a non-damaging interrupt (War Cry) makes the actor play the damage reaction.
signal windup_interrupted(actor: Combatant, source: Combatant)  ## D-1129: War Cry/status cancelled `actor`'s wind-up; `source` is the interrupter.
signal windup_hit_interrupted(actor: Combatant, source: Combatant)  ## D-1129: a hit cancelled `actor`'s wind-up (it already has the normal hit shake).
signal burn_applied(target: Combatant)  ## D-238
signal burn_ticked(target: Combatant, damage: int)  ## D-238: for the future HUD / VFX of the Burn
signal burn_ended(target: Combatant)  ## D-238: the Burn ran out (not when the target died)
signal guard_started(actor: Combatant)  ## D-272
signal guard_ended(actor: Combatant, reason: String)  ## D-272: "expired", "hit", "broken" or "battle_end".
signal mp_regenerated(actor: Combatant, amount: int)  ## D-1062: a unit recovered MP (the amount really gained)
signal armor_changed(actor: Combatant, state: String)  ## D-1026: "started", "extended", "hit", "expired" or "battle_end".
signal reward_spawned(reward)
signal reward_landed(reward)
## D-1229 (Phase 5): the Employ attempt changed stage ("picking", "cancelled", "refused", "started",
## "ended"); `data` is the telemetry row documented in docs/TELEMETRIA.md.
signal employ_changed(stage: String, data: Dictionary)
## D-1232/D-1244 (Phase 8): a Summon swap was refused ("refused") or done ("done"); `data` is the
## telemetry row documented in docs/TELEMETRIA.md.
signal summon_changed(stage: String, data: Dictionary)
var _arrivals: Array[Dictionary] = []  ## D-1254: Summons whose pentagram is still forming: {entering, leaving, slot, left}.

const Phase = Incoming.Phase

## Opt-in benchmark mode (--fast-combat): the same rules, every pacing constant shortened.
## Off by default, so the shipped game is unchanged.
static var fast_combat_test := false


const REWARD_FLOAT := 0.6  ## Seconds a reward token floats over where it was earned.
const REWARD_FLY := 0.25  ## Seconds it flies to the HUD.
const REWARD_IMPACT := 0.46  ## Seconds of impact effect at the slot.
const SKILL_BLOCKS := 2.0
const ITEM_BLOCKS := 1.0
const GUARD_BLOCKS := 1.0  ## D-272: Guard costs 1 ATB; Burst does not pay it.
## D-1242: how long the BOOST lasts (the target of an Employ that failed receives it).
const BOOST_SECONDS := 10.0
const EMPLOY_BLOCKS := 5.0  ## D-1229: Employ costs 5 ATB and 0 MP; Burst does not pay it.
## D-1254 timeline of a Summon (creator's numbers): the beam that takes the leaver out of the floor, 1 s of gap, the
## 4 s pentagram, then the beam falls; the entrant is in `party` (and can act) the moment it touches the floor.
## Summon costs no ATB and cannot be cancelled.
const SUMMON_EXIT_SECONDS := 0.95
const SUMMON_GAP_SECONDS := 1.0
const SUMMON_PENTAGRAM_SECONDS := 4.0
const SUMMON_FALL_SECONDS := 0.95
const SUMMON_ARRIVAL_SECONDS := SUMMON_EXIT_SECONDS + SUMMON_GAP_SECONDS + SUMMON_PENTAGRAM_SECONDS + SUMMON_FALL_SECONDS
const GUARD_SECONDS := 2.0  ## D-272: no cancelling; ends by time, contact or Brick Break.
const GUARD_REDUCTION := DamageMath.GUARD_REDUCTION  ## D-1153: single source in DamageMath; D-272 (VIT/WIS already exist, D-391).
const AI_GUARD_CHANCE := 0.25  ## D-272/D-116: chance an AI target guards when an attack is declared on it.


func _init() -> void:
	if OS.get_cmdline_user_args().has("--fast-combat"):
		fast_combat_test = true
	_reward_queue = BattleRewards.new(self)
	_badges = BattleBadges.new(self)

## Minimum ATB cost among the combatant's usable skills (or 0 if Burst is active) — D-040.
static func min_skill_cost(c: Combatant) -> float:
	if c == null:
		return SKILL_BLOCKS
	if c.burst > 0:
		return 0.0
	var moves := Skill.combatant_moves(c)
	if moves.is_empty():
		return SKILL_BLOCKS
	var min_cost := moves[0].cost
	for s in moves:
		if s.cost < min_cost:
			min_cost = s.cost
	return float(min_cost)


static func evade_still_cost() -> float:
	return 2.0 if fast_combat_test else EVADE_STILL


static func evade_on_run_cost() -> float:
	return EVADE_ON_RUN


static func base_windup() -> float:
	return WINDUP


static func status_windup() -> float:
	return STATUS_WINDUP


static func status_vfx_tail() -> float:
	return STATUS_VFX_TAIL


static func start_atb_blocks() -> float:
	return START_ATB


## Fast-combat benchmark only: attacking or stepping drops the Guard (the default rules
## keep it uncancellable, D-272). Emits through the owner, which forwards to Battle.guard_ended.
static func _cancel_guard_if_fast(actor: Combatant) -> void:
	if not fast_combat_test or not actor.is_guarding():
		return
	actor.end_guard("cancelled")


const EVADE_STILL := 3.0  ## Evade while standing still (not running in its own attack) — D-006.
const EVADE_ON_RUN := 2.0  ## Evade during the run of its own melee attack — D-006.
const PRELUDE_GAP := 0.25  ## D-988: the Evade window closes this long before the contact (the attacker's rise)
const PERFECT_WINDOW := 0.25  ## D-283: the Evade only works in the last seconds before the hit, inside the strike, and is always perfect (D-027, D-030).
const EVADE_LATE_GRACE := 0.15  ## D-1180: a late press while the Dread is still lit is valid, down to 0.10 s before contact.
const COUNTER_WINDUP := 0.3  ## D-284: wind-up of the counter-attack after a perfect Evade, whatever the move (a status move stays instant).
const AUTO_DODGE_BASE := 0.10  ## D-1193 (teste, fase 1): base automatic evade chance per hit.
const AUTO_DODGE_PER_AGI := 0.003  ## D-1193: +0.3 pp per AGI point (AGI 50 = 25%).
const AGI_EFFECT_CAP := 50.0  ## D-1193/D-1194: AGI above this adds nothing to evade or travel.
const AGI_STAGE_STEP := 0.03  ## D-1193/D-1194: +3 pp per speed stage (buff +, debuff -), evade and travel.
const TRAVEL_AGI_MAX_REDUCTION := 0.20  ## D-1194: melee/CAST travel time reduction at AGI 50.
var debug_roll := 0  ## Sala de VFX (debug): 0 = sorteio normal, 1 = acerto sem crítico, 2 = esquiva, 3 = acerto crítico.
const STATUS_WINDUP := 0.5  ## Status moves prepare faster, with the engine paused (D-031).
const STATUS_VFX_TAIL := 1.0  ## Seconds the engine stays paused after the status effect is applied.
const ARMORED_BULK := "armored_bulk"  ## D-1026: SELF status move, instant wind-up.
const WAR_CRY := "war_cry"  ## D-1127: the only status move that does NOT pause the engine (experimental).
const ARMORED_BULK_PAUSE := 1.5  ## D-1026: kept for FX timing; the rule reads MoveData.status_pause.
const BURN_DMG := 2  ## D-238 (D-236 sheet): fixed damage of each Burn tick
const BURN_INTERVAL := 1.0  ## seconds between ticks; the first comes one interval after the hit
const WINDUP := 1.5  ## Every attack takes this long to land; the attacker's ATB is locked meanwhile.
const STEP_MAX := 2  ## Positions go from -STEP_MAX (behind) to +STEP_MAX (in front).
const STEP_TIME := 0.35  ## Seconds a step takes to walk.
const TRAVEL_PER_STEP := 0.10  ## Seconds off an attack's travel per step of attacker + target.
const TRAVEL_MIN := 0.25
const DMG_PER_STEP := DamageMath.DMG_PER_STEP  ## D-1153: single source in DamageMath.
const ENGAGE_SECONDS := 2.0  ## Real seconds the evader stays next to the opponent (the Burst slow-motion).
const WEAKNESS_MULT := DamageMath.WEAKNESS_MULT  ## D-1153: single source in DamageMath.
const CRIT_CHANCE := 0.1
const CRIT_MULT := DamageMath.CRIT_MULT  ## D-1153: single source in DamageMath.
const START_ATB := 3.0  ## Every combatant starts a battle with this many blocks.
const AI_HEAL_BELOW := 0.5  ## AI combatants drink a potion at or below this HP fraction.

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var protagonist: Combatant = null  ## D-1244: party[0] at start(); pays the Summon and owns the menu while it is on the field.
var incoming: Array[Incoming] = []
var running := false
var _reward_queue: BattleRewards
var rewards: Array[BattleReward]:
	get:
		return _reward_queue.items
var _badges: BattleBadges
var _landing: Array[Incoming] = []  ## Resolved attacks whose strike has not landed yet.
var _returning: Array[Incoming] = []  ## Struck already: only the return is left to play.
var _status_pause: Incoming = null  ## A status move is being performed: only it runs (D-031).
var _war_cry_active: Array[Incoming] = []  ## D-1127: War Cries run outside the status pause; each closes its own banner when done.
var _status_tail := -1.0
var _status_total := 0.0  ## D-1026: when > 0 the move fixes the TOTAL length of the pause (no default tail).
var _status_elapsed := 0.0
## D-1229/D-1233: where a failed Employ is remembered and a recruit is registered. The battle scene
## sets the player's roster before start(); a battle without one (isolated tests) gets a private one.
var roster: ExpeditionRoster = null
## D-1229 "Sim, só teste": recruiting the LAST living enemy exists only as an isolated test (victory, XP and loot
## of that case are not decided), so the real game refuses it ("last_enemy"). Only the debug room turns this on.
var employ_allow_last := false
## D-1240 (Phase 6): debug only. >= 0 replaces the random roll (0..100) of resolve_employ(); -1 = real roll.
var employ_roll_override := -1.0
var _employ: Dictionary = {}  ## D-1229: the Employ attempt in progress ({} = none). While it exists the whole battle holds still.
var _employ_left_no_enemy := false  ## D-1229: a recruit left the field with no living enemy; victory for this case is not decided, so none is declared.
var _freeze_left := 0.0  ## Hit-stop: the whole battle clock holds still for this many seconds.
var battle_time := 0.0  ## D-1234: battle clock in seconds; it is the `t` of the roster participation events.
var _evade := BattleEvade.new(self)
var _ai := BattleAI.new(self)
var _planner := AttackPlanner.new(self)
var _hop_back := 0.3  ## Placeholder; BattleFx decides how long a return takes.



func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	protagonist = party[0] if not party.is_empty() else null  # D-1244: the leader is the first active member.
	for c in party + enemies:
		c.atb = start_atb_blocks()
		c.burst = 0
		c.clear_pending()
		c.engaged_with = null
		c.pos_step = 0
		c.step_from = 0.0
		c.step_t = 1.0
		if not c.armor_changed.is_connected(_on_armor_changed):
			c.armor_changed.connect(_on_armor_changed)  # D-1026
		if not c.mp_regenerated.is_connected(_on_mp_regenerated):
			c.mp_regenerated.connect(_on_mp_regenerated)  # D-1062
	_landing.clear()
	_ai.reset()
	_status_pause = null
	_war_cry_active.clear()
	_returning.clear()
	rewards.clear()
	_badges.clear()
	_employ = {}
	_employ_left_no_enemy = false
	if roster == null:
		roster = ExpeditionRoster.new()
	roster.begin_battle()  # D-1229: a failed Employ blocks new attempts until the next battle.
	running = true
	log_message.emit("Batalha iniciada!")


## Debug aid: is an attack (pending or still playing out) using this combatant?
## The test spawns must not be removed while one is.
func is_in_action(c: Combatant) -> bool:
	for inc in incoming + _landing + _returning:
		if inc.attacker == c or inc.target == c or inc.target2 == c:
			return true
	return _status_pause != null and (_status_pause.attacker == c or _status_pause.target == c or _status_pause.target2 == c)


## Everyone not carried by an attack's motion stands at its rest spot.
func _update_positions() -> void:
	var carried := {}
	for inc in _landing + _returning:
		if AttackMotion.carries(inc):
			carried[inc.attacker] = true
	for c in party + enemies:
		if not carried.has(c):
			c.pos = c.rest_pos()


## Holds the battle clock for `seconds` (the contact freeze), so movement, rules and the
## frozen animations stay on the same frame.
func freeze(seconds: float) -> void:
	_freeze_left = maxf(_freeze_left, seconds)


func _process(delta: float) -> void:
	battle_time += delta
	if not _employ.is_empty():
		return  # D-1229 ("congela tudo"): nothing advances while an Employ attempt is open.
	# D-1297: reward tokens fly on real time: no hit-stop, status pause or slow-motion holds them.
	_reward_queue.step(delta / maxf(Engine.time_scale, 0.05))
	if _freeze_left > 0.0:
		_freeze_left -= delta
		return
	_badges.step(delta)
	if not running:
		if not _returning.is_empty():
			_step_attacks(delta)  # The winners' leaps back still play out after the last hit.
		return
	if _status_pause != null:
		_step_status_pause(delta)
		state_changed.emit()
		return
	_step_arrivals(delta)
	for c in party + enemies:
		c.tick_shield(delta)  # Drain Spear / Badge Steal: the shield badge has its own clock.
		c.tick_magic_immunity(delta)
		c.tick_armor(delta)  # D-1026: counts down also during a Guard; frozen by a status pause like every duration
		c.tick_boost(delta)  # D-1242: same clock as the other durations (every pause stops it)
		if not is_winding_up(c):  # ATB stays locked until the action finishes.
			c.tick(delta)
		elif c.is_alive() and c.in_battle and not _acting_spends_mp(c):
			c.tick_mp_regen(delta * c.mp_regen_rate())  # D-1298: a Move that costs no MP never pauses the MP pulse
		_tick_burn(c, delta)  # D-238: burns on, also while it winds up
	for c in party + enemies:
		if c.step_t < 1.0:
			c.step_t = minf(c.step_t + delta / STEP_TIME, 1.0)
	_update_positions()
	_ai.run(delta)
	if _status_pause != null:
		# D-031/D-1150: the pause starts when the status move is declared. Do not let an
		# attack resolve later in this same frame and interrupt/cancel the player's action.
		state_changed.emit()
		return
	_resolve_incoming(delta)
	_step_attacks(delta)
	_run_queued()
	_run_queued_steps()  # D-1299
	if _status_pause != null:
		state_changed.emit()
		return
	_evade.step_engage(delta)
	_finish_war_cry_if_done()
	state_changed.emit()


# --- Actions (same for the player, allies and enemies) -----------------------

## D-1200/D-235: the team of `c` read from the battle lists, never from `is_player`.
## A combatant outside both lists (isolated tests) falls back to its `is_player` flag.
func team_of(c: Combatant) -> Array[Combatant]:
	if enemies.has(c):
		return enemies
	if party.has(c):
		return party
	return party if c.is_player else enemies


func opponents_of(c: Combatant) -> Array[Combatant]:
	return party if team_of(c) == enemies else enemies


func same_team(a: Combatant, b: Combatant) -> bool:
	if a == null or b == null:
		return false
	var a_in := party.has(a) or enemies.has(a)
	var b_in := party.has(b) or enemies.has(b)
	if a_in and b_in:
		return team_of(a) == team_of(b)
	return a.is_player == b.is_player


## D-1200: does `c` fit `side` (a MoveData.TargetSide) from the point of view of `actor`?
func side_allows(actor: Combatant, c: Combatant, side: int) -> bool:
	match side:
		MoveData.TargetSide.ALLY:
			return same_team(actor, c)
		MoveData.TargetSide.ENEMY:
			return not same_team(actor, c)
	return true


func use_skill(actor: Combatant, skill: Skill, target: Combatant, target2: Combatant = null) -> bool:
	if is_employ_active():
		return false  # D-1229: the whole battle is frozen.
	if not actor.is_alive() or actor.is_stunned() or (actor.is_guarding() and not fast_combat_test) or is_winding_up(actor) or not actor.can_pay_skill(skill):
		return false
	if _status_pause != null and skill.kind == Skill.Kind.STATUS:
		return false  # D-1159: attacks may start their wind-up during the pause; status moves wait.
	if (skill.data != null and skill.data.has_tag(&"self_status")) or BattleSpace.move_id(skill.display_name) == ARMORED_BULK:
		target = actor  # D-1026: SELF
	elif skill.target_mode == MoveData.TargetMode.DUAL:
		# D-1200: primary + secondary, both alive. Which half affects whom is not defined yet, so the
		# structure accepts any living pair (same or opposing teams) and leaves the effect to the behavior.
		if target == null or not target.is_alive() or target2 == null or not target2.is_alive():
			return false
		if not side_allows(actor, target, skill.primary_side) or not side_allows(actor, target2, skill.secondary_side):
			return false  # each DUAL Move declares which side its picks may be (D-1200)
	elif skill.is_friendly:
		if target == null or not target.is_alive() or not same_team(target, actor):
			target = actor
	else:
		if target == null or not target.is_alive():
			return false
		if actor.engaged_with != null and target != actor.engaged_with:
			return false  # Engaged: it only acts on the opponent it is standing next to.
	_cancel_guard_if_fast(actor)
	var by_burst := actor.burst > 0  # D-1239: remember what pay_skill() takes, for the Employ refund.
	var mp_before := actor.mp
	var timer_before := actor.mp_regen_timer
	actor.pay_skill(skill)
	var inc := Incoming.new()
	inc.paid_burst = by_burst
	inc.paid_blocks = 0.0 if by_burst else skill.cost
	inc.paid_mp = mp_before - actor.mp
	inc.paid_mp_timer = timer_before
	inc.attacker = actor
	inc.target = target
	inc.target2 = target2 if skill.target_mode == MoveData.TargetMode.DUAL else null
	inc.power = skill.power
	inc.element = skill.element
	inc.kind = skill.kind
	inc.ground = skill.ground
	inc.label = skill.display_name
	inc.is_aoe = skill.is_aoe
	inc.is_friendly = skill.is_friendly
	inc.skill = skill
	# D-1079: one stable move id + canonical sheet for the planner, rules and AI.
	inc.move_id = BattleSpace.move_id(skill.display_name)
	inc.move_data = MoveCatalog.get_move(StringName(inc.move_id))
	# After a perfect Evade during its own run, the next attack is immediate (D-027).
	inc.instant = (actor.engaged_with != null or actor.counter_ready) and not skill.is_friendly
	if not skill.is_friendly:
		actor.counter_ready = false
	if actor.engaged_with != null and not skill.is_friendly:
		actor.engage_left = ENGAGE_SECONDS  # Acting keeps it engaged.

	# Taunt redirection (D-032)
	if actor.taunted_by != null and actor.taunted_by.is_alive() and not skill.is_friendly and not skill.is_aoe and inc.kind != Skill.Kind.STATUS:
		target = actor.taunted_by
		inc.target = target
		actor.taunt_atk_bonus = true

	# Individual windup overrides (D-032 / D-034)
	var w_override := skill.windup if skill.windup >= 0.0 else (status_windup() if inc.kind == Skill.Kind.STATUS else base_windup())
	inc.total_windup = ((0.0 if inc.kind == Skill.Kind.STATUS else COUNTER_WINDUP) if inc.instant else w_override)  # D-284
	inc.time_left = inc.total_windup

	incoming.append(inc)
	if inc.kind == Skill.Kind.STATUS:
		var no_pause := BattleSpace.move_id(inc.label) == WAR_CRY  # D-1127: experimental exception
		if no_pause:
			_war_cry_active.append(inc)
		else:
			_status_pause = inc  # From the wind-up until its effect has played (D-031).
		_status_tail = -1.0
		var status_pause := inc.move_data.status_pause if inc.move_data != null and inc.move_data.status_pause >= 0.0 else 0.0
		if status_pause <= 0.0 and BattleSpace.move_id(inc.label) == ARMORED_BULK:
			status_pause = ARMORED_BULK_PAUSE  # compatibility for Skills without MoveData
		_status_total = status_pause  # D-1026
		_status_elapsed = 0.0
		status_pause_started.emit(inc)
	log_message.emit("%s prepara %s em %s..." % [actor.name, skill.display_name, target.name])
	_planner.redirect_if_blocked(inc)
	attack_telegraphed.emit(inc)
	_roll_ai_guard(inc)
	return true


## A player's move: it starts now if it can; otherwise it waits in the one slot, replacing
## whatever was there. Nothing is paid until it starts (D-161).
func request_skill(actor: Combatant, skill: Skill, target: Combatant, target2: Combatant = null) -> bool:
	if is_employ_active():
		return false  # D-1229: the whole battle is frozen.
	if not running or not actor.is_alive() or actor.is_stunned() or (actor.is_guarding() and not fast_combat_test) or actor.mp < skill.mp_cost:
		return false
	if can_start_windup_now(actor, skill):
		var started := _start_move(actor, skill, target, target2)
		if started:
			_clear_queued(actor)  # D-1146: the new choice replaces the old slot; it cannot run later too.
		return started
	if not skill.is_friendly and (target == null or not target.is_alive()):
		return false
	actor.queued_skill = skill
	actor.queued_target = target
	actor.queued_target2 = target2
	log_message.emit("%s guarda %s para em seguida." % [actor.name, skill.display_name])
	return true


## False during a status pause (D-031) and until its own attack has ended, return included.
func can_start_now(actor: Combatant) -> bool:
	return _status_pause == null and not is_attacking(actor) and not (actor.is_guarding() and not fast_combat_test)


## D-1159: an attack (non-status) may start its wind-up during a status pause and stay
## frozen; a status move still waits so pauses never stack.
func can_start_windup_now(actor: Combatant, skill: Skill) -> bool:
	if not actor.is_alive() or is_attacking(actor) or (actor.is_guarding() and not fast_combat_test) or actor.is_stunned():
		return false
	return _status_pause == null or (skill != null and skill.kind != Skill.Kind.STATUS)


## D-1146: the HUD uses this to block Items/Steps without reading the private field.
func is_status_paused() -> bool:
	return _status_pause != null


func _start_move(actor: Combatant, skill: Skill, target: Combatant, target2: Combatant = null) -> bool:
	if actor.is_stunned() or (actor.is_guarding() and not fast_combat_test) or not actor.can_pay_skill(skill):
		return false
	if not skill.is_friendly and (target == null or not target.is_alive()):
		return false
	return use_skill(actor, skill, target, target2)


## A queued move starts as soon as nothing holds it; without ATB, a living target or the
## ability to act at that moment, it is dropped (D-161).
func _run_queued() -> void:
	for c in party + enemies:
		if c.queued_skill == null or not can_start_now(c):
			continue
		var skill := c.queued_skill
		var target := c.queued_target
		var target2 := c.queued_target2
		_clear_queued(c)
		if not c.is_alive():
			continue
		if not _start_move(c, skill, target, target2):
			log_message.emit("%s não pôde usar %s." % [c.name, skill.display_name])


func _clear_queued(c: Combatant) -> void:
	c.queued_skill = null
	c.queued_target = null
	c.queued_target2 = null


func use_item(actor: Combatant, item: Item, target: Combatant) -> bool:
	if is_employ_active():
		return false  # D-1229: the whole battle is frozen.
	if _status_pause != null:
		return false  # D-1146: items may not skip the status pause (Evade/Guard are the exceptions).
	if item.kind != Item.Kind.CONSUMABLE or actor.is_stunned() or actor.is_guarding() or not actor.can_pay(ITEM_BLOCKS):
		return false
	if not actor.is_alive() or actor.item_count(item.id) <= 0:
		return false
	actor.pay(ITEM_BLOCKS)
	if actor.engaged_with != null:
		actor.engage_left = ENGAGE_SECONDS
	actor.remove_item(item.id)
	var before := target.hp
	target.heal(item.heal)
	healed.emit(actor, target, target.hp - before)
	log_message.emit("%s usa %s em %s" % [actor.name, item.display_name, target.name])
	return true


# --- Guard (D-272) -----------------------------------------------------------

## Why `actor` cannot Guard right now ("" when it can).
func guard_block_reason(actor: Combatant) -> String:
	if not running or not actor.is_alive():
		return "fora de combate"
	if actor.is_guarding():
		return "em Guard"
	if actor.is_stunned():
		return "atordoado"
	if actor.engaged_with != null:
		return "engajado"
	if is_attacking(actor) and not is_held(actor):  # D-282: held in its idle it may Guard
		return "em ação"
	# D-1146: an otherwise free actor may Guard during the status pause (Evade/Guard are allowed).
	if actor.blocks() < GUARD_BLOCKS:
		return "falta ATB"  # Burst never pays the Guard (D-272).
	return ""


func can_guard(actor: Combatant) -> bool:
	return guard_block_reason(actor) == ""


## 1 ATB, 2 s, no cancelling: the actor can do nothing else and its ATB is paused until the
## Guard expires or is hit/broken.
func use_guard(actor: Combatant) -> bool:
	if is_employ_active():
		return false  # D-1229: frozen, without Evade or Guard.
	if not can_guard(actor):
		return false
	if not actor.guard_ended.is_connected(_on_guard_ended):
		actor.guard_ended.connect(_on_guard_ended)
	actor.spend(GUARD_BLOCKS)
	actor.guard_timer = GUARD_SECONDS
	_clear_queued(actor)
	log_message.emit("%s entra em Guard!" % actor.name)
	guard_started.emit(actor)
	actor.record_proficiency("VIT", 3)
	return true


func _on_guard_ended(actor: Combatant, reason: String) -> void:
	guard_ended.emit(actor, reason)


func _on_mp_regenerated(actor: Combatant, amount: int) -> void:
	mp_regenerated.emit(actor, amount)


func _on_armor_changed(actor: Combatant, state: String) -> void:
	armor_changed.emit(actor, state)


## An AI-controlled target may raise a Guard when an attack is declared on it (D-272, D-116).
func _roll_ai_guard(inc: Incoming) -> void:
	var t := inc.target
	if inc.is_friendly or inc.kind == Skill.Kind.STATUS or t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if t.is_player == inc.attacker.is_player:
		return
	if randf() < AI_GUARD_CHANCE:
		inc.ai_guard_eta = randf_range(0.8, 1.3)  # D-285: it raises the shield near the impact, not at the start of the wind-up


# --- Position steps ----------------------------------------------------------

## D-1193 (test, phase 1): automatic evade chance of `c` per hit: 10% + 0.3 pp per AGI (cap 50) + 3 pp per speed stage.
static func auto_dodge_chance(c: Combatant) -> float:
	return clampf(AUTO_DODGE_BASE + AUTO_DODGE_PER_AGI * minf(float(c.agi), AGI_EFFECT_CAP) + AGI_STAGE_STEP * float(c.speed_buff), 0.0, 1.0)


## D-1194 (test, phase 1): factor applied to the sheet's travel time of a MELEE/CAST move, before the steps and the floor (D-133).
static func agi_travel_factor(c: Combatant) -> float:
	var reduction := TRAVEL_AGI_MAX_REDUCTION * minf(float(c.agi), AGI_EFFECT_CAP) / AGI_EFFECT_CAP + AGI_STAGE_STEP * float(c.speed_buff)
	return 1.0 - clampf(reduction, -0.5, 0.5)


## Travel time of an attack: the base minus 0.10 s per step of attacker and target.
static func travel_seconds(base: float, attacker: Combatant, target: Combatant) -> float:
	return maxf(base - TRAVEL_PER_STEP * float(attacker.pos_step + target.pos_step), TRAVEL_MIN)


## No step while preparing/executing its own attack, while an attack involves it (as
## attacker or target), while engaged, while still walking a step, or without 1 ATB.
func can_step(c: Combatant, dir: int) -> bool:
	# D-1299: no lock and no ATB cost. A step is only refused when it makes no sense
	# (out of -2..+2, dead, battle over); a busy combatant queues it (see `step`).
	if not running or not c.is_alive() or dir == 0:
		return false
	var target := (c.queued_step if c.queued_step != 0 else 0) + c.pos_step + dir
	return target >= -STEP_MAX and target <= STEP_MAX


## Short reason a step is not possible right now ("" when it is).
func step_block_reason(c: Combatant) -> String:
	if not running or not c.is_alive():
		return ""
	return "na fila" if c.queued_step != 0 else ""  # D-1299: nothing blocks a step any more; it only waits


func step(c: Combatant, dir: int) -> bool:
	if is_employ_active():
		return false  # D-1229: the whole battle is frozen.
	if not can_step(c, dir):
		return false
	if not _can_step_now(c):
		c.queued_step = clampi(c.queued_step + dir, -STEP_MAX, STEP_MAX)  # D-1299: waits until it is idle
		return true
	_do_step(c, dir)
	return true


## D-1299: idle = it may start an action right now and is not stunned or engaged.
func _can_step_now(c: Combatant) -> bool:
	return can_start_now(c) and not c.is_stunned() and c.engaged_with == null and not is_winding_up(c)


## Runs the queued steps of everyone who became idle (one step per call).
func _run_queued_steps() -> void:
	for c in party + enemies:
		if c.queued_step == 0 or not c.is_alive() or not _can_step_now(c):
			continue
		var dir := signi(c.queued_step)
		c.queued_step -= dir
		if c.pos_step + dir >= -STEP_MAX and c.pos_step + dir <= STEP_MAX:
			_do_step(c, dir)


func _do_step(c: Combatant, dir: int) -> void:
	_cancel_guard_if_fast(c)
	c.step_from = c.visual_step()
	c.pos_step += dir
	c.step_t = 0.0
	log_message.emit("%s dá um passo %s." % [c.name, "à frente" if dir > 0 else "atrás"])
	stepped.emit(c, c.pos_step)
	return true


## The attack `actor` may press Evade against: one on its way in (works), otherwise one
## still winding up (pressing then is the "too early" whiff).
## Damage a move would deal now (no crit), same formula as a hit; 0 for status moves.
static func estimate_damage(attacker: Combatant, target: Combatant, skill: Skill) -> int:
	if skill.kind == Skill.Kind.STATUS:
		return 0
	var move_data: MoveData = skill.data
	if move_data == null:
		move_data = MoveCatalog.get_move(StringName(BattleSpace.move_id(skill.display_name)))
	var flat := move_data.magic_flat if move_data != null else -1
	var step_mult := DamageMath.step_multiplier(attacker.pos_step, target.pos_step)
	var magical := skill.is_magical()
	var attack_stat := attacker.mag if magical else attacker.attack
	var affinity_mult := DamageMath.affinity_multiplier(target.affinity_for(skill.element))
	return DamageMath.resolve_offense(attack_stat, skill.power, affinity_mult, false, step_mult, magical, target.wis, flat, attacker.mag, target.spi)


## A projectile that meets another opponent on its way hits that one instead.
func redirect(inc: Incoming, new_target: Combatant) -> void:
	log_message.emit("%s intercepta %s de %s (era para %s)!" % [new_target.name, inc.label, inc.attacker.name, inc.target.name])
	inc.target = new_target


## True while `c` is itself attacking, returning from an attack or stunned.
func is_attacking(c: Combatant) -> bool:
	if is_winding_up(c):
		return true
	for inc in _returning:
		if inc.attacker == c:
			return true
	return false


func evade_cost(actor: Combatant) -> float:
	return _evade.cost(actor)


func find_evadable(actor: Combatant) -> Incoming:
	return _evade.find_evadable(actor)


func try_evade(actor: Combatant, inc: Incoming) -> bool:
	if is_employ_active():
		return false  # D-1229: frozen, without Evade or Guard.
	return _evade.try_evade(actor, inc)


## Attacks still able to hurt: winding up, or already on their way to land.
func active_attacks() -> Array[Incoming]:
	var list: Array[Incoming] = []
	list.append_array(incoming)
	list.append_array(_landing)
	return list


## D-1298: does the Move `c` is performing cost MP? (It resets the MP timer when paid, D-413.)
func _acting_spends_mp(c: Combatant) -> bool:
	for inc in incoming + _landing + _returning:
		if inc.attacker == c and inc.skill != null and inc.skill.mp_cost > 0:
			return true
	return false


func is_winding_up(c: Combatant) -> bool:
	for inc in incoming:
		if inc.attacker == c:
			return true
	for inc in _landing:
		if inc.attacker == c:
			return true
	for inc in _returning:
		if inc.attacker == c and inc.phase == Phase.STAGGER:
			return true  # Interrupted: stunned until the engaged state ends.
	return false


## D-1102: true only while `c` has an attack that has not resolved yet (the WINDUP window).
func has_windup(c: Combatant) -> bool:
	for inc in incoming:
		if inc.attacker == c and not inc.ghost and inc.phase == Phase.WINDUP:
			return true
	return false


## D-1102: War Cry cancels only the WINDUP attack of `c`, without damage, knockback or a
## return animation from a hit. The ATB already spent by `c` is not refunded.
func interrupt_windup_of(c: Combatant, hitter: Combatant) -> bool:
	var stopped := false
	for inc in incoming.duplicate():
		if inc.attacker == c and not inc.ghost and inc.phase == Phase.WINDUP:
			incoming.erase(inc)
			inc.interrupted = true
			inc.interruption_feedback = true  # D-1160: War Cry really cancelled the wind-up.
			stopped = true
			attack_cancelled.emit(inc)
			log_message.emit("%s é interrompido!" % c.name)
	if stopped:
		_clear_queued(c)
		action_interrupted.emit(c)
		windup_interrupted.emit(c, hitter)  # D-1129: one shake for the War Cry-style interrupt
	return stopped


func _resolve_incoming(delta: float, only: Incoming = null) -> void:
	for inc in incoming.duplicate():
		if only != null and inc != only:
			continue
		if inc.attacker.is_alive() and not inc.target.is_alive():
			_retarget_aoe(inc)
		if not inc.attacker.is_alive() or not inc.target.is_alive():
			attack_cancelled.emit(inc)
			incoming.erase(inc)
			continue
		_roll_ai_dodge(inc)  # D-1007
		_tick_ai_dodge(inc, delta)
		inc.time_left -= delta
		if inc.time_left > 0.0:
			continue
		incoming.erase(inc)
		if move_is_untargetable(inc):
			inc.attacker.is_invulnerable = true
		inc.auto_dodged = inc.kind != Skill.Kind.STATUS and not inc.dodged and not inc.whiffed and (debug_roll == 2 or (debug_roll == 0 and randf() < auto_dodge_chance(inc.target)))
		inc.resolved = true
		_planner.plan(inc)
		attack_resolved.emit(inc)  # BattleFx prepares the drawing of the planned attack.
		if inc.plan.is_empty():
			inc.plan = [[Phase.STRIKE, 0.0]]
			inc.impact_phase = Phase.STRIKE
		inc.plan_i = 0
		inc.phase = inc.plan[0][0]
		inc.phase_time = 0.0
		_landing.append(inc)
		attack_phase.emit(inc, inc.phase)
		_roll_ai_evade(inc)
	_check_end()


## Advances every resolved attack along its timeline. The hit counts (damage, death) when
## the impact phase ends; the return is played out afterwards.
func _step_attacks(delta: float, only: Incoming = null) -> void:
	if only == null:
		_detect_clashes()
	for inc in _landing.duplicate() + _returning.duplicate():
		if only != null and inc != only:
			continue
		if inc.phase == Phase.STAGGER:
			inc.phase_time += delta
			continue
		var before: float = inc.phase_time
		inc.phase_time += delta
		# D-282: in its idle after a melee strike it does not hop home while another melee attack is striking it.
		if inc.phase == Phase.RETURN and inc.hold > 0.0 and before <= inc.hold and inc.phase_time >= inc.hold and _holds_idle(inc, true):
			inc.phase_time = inc.hold - 0.0005
		while inc.plan_i < inc.plan.size() and inc.phase_time >= inc.plan[inc.plan_i][1]:
			inc.phase_time -= inc.plan[inc.plan_i][1]
			var ended: int = inc.plan[inc.plan_i][0]
			if ended == inc.impact_phase and not inc.impacted:
				_strike(inc)
			inc.plan_i += 1
			if inc.plan_i < inc.plan.size():
				inc.phase = inc.plan[inc.plan_i][0]
				if inc.phase == Phase.STRIKE:
					if move_is_untargetable(inc):
						inc.attacker.is_invulnerable = false
				elif inc.phase == Phase.RETURN:
					if move_teleports(inc):
						inc.attacker.is_invulnerable = true
				AttackMotion.on_phase(inc)
				attack_phase.emit(inc, inc.phase)
				_roll_ai_evade(inc)
		AttackMotion.update(inc, delta)
		if inc.ai_guard_eta >= 0.0 and inc.resolved and not inc.impacted and not inc.interrupted and not inc.dodged and inc.eta() <= inc.ai_guard_eta:
			inc.ai_guard_eta = -1.0
			if inc.target.is_alive() and can_guard(inc.target):
				use_guard(inc.target)
		AttackMotion.update_projectile(inc)
		_tick_ai_dodge(inc, delta)  # D-1007: the AI dodges at its random moment (wind-up to contact)
		if inc.plan_i >= inc.plan.size():
			if not inc.impacted:
				_strike(inc)
			inc.phase = Phase.DONE
			if move_is_untargetable(inc):
				inc.attacker.is_invulnerable = false
			_returning.erase(inc)
			if inc.motion != "engaged" and inc.attacker.is_alive():
				inc.attacker.clear_rest()  # Back at its step spot.
				inc.attacker.pos = inc.attacker.rest_pos()
			attack_phase.emit(inc, Phase.DONE)
	_check_end()


## D-282: `c` is in its post-strike idle (before the hop home) and held there by an attack that is striking it.
func is_held(c: Combatant) -> bool:
	for inc in _returning:
		if inc.attacker == c and _holds_idle(inc):
			return true
	return false


## D-282: this returning melee attack is still in its idle and another melee attack is in its strike against its attacker.
func _holds_idle(ret: Incoming, crossing := false) -> bool:
	if ret.ghost or ret.interrupted or ret.kind != Skill.Kind.MELEE or ret.motion != "melee" or ret.hold <= 0.0:
		return false
	if ret.phase != Phase.RETURN or (not crossing and ret.phase_time > ret.hold + 0.001):
		return false  # already hopping
	for x in _landing:
		if x.target == ret.attacker and x.attacker != ret.attacker and x.attacker.is_alive() and x.phase == Phase.STRIKE 				and (x.motion == "melee" or x.motion == "engaged") and x.kind == Skill.Kind.MELEE 				and not x.impacted and not x.interrupted and not x.dodged and not x.auto_dodged and not x.ghost and not x.is_friendly:
			return true
	return false


## D-279: two runners of opposing teams that meet bump back with a hop. If they were running at each
## other, both then strike at once from there (each with its own move's timing, so the faster one hits
## first and the existing interruption rule applies); with different targets both give up and go home.
func _detect_clashes() -> void:
	var runners: Array[Incoming] = []
	for inc in _landing:
		if inc.motion == "melee" and inc.phase == Phase.TRAVEL and not inc.clash and not inc.blink and not inc.interrupted 				and not inc.dodged and not inc.auto_dodged and not inc.ghost and inc.phase_time > AttackMotion.RUN_START 				and not inc.attacker.is_invulnerable:
			runners.append(inc)
	for i in runners.size():
		var ia := runners[i]
		if ia.clash:
			continue
		for j in range(i + 1, runners.size()):
			var ib := runners[j]
			if ib.clash or ia.attacker.is_player == ib.attacker.is_player:
				continue
			if ia.attacker.pos.distance_to(ib.attacker.pos) > BattleSpace.CLASH_DIST:
				continue
			_clash(ia, ib)
			break


func _clash(ia: Incoming, ib: Incoming) -> void:
	var pa := ia.attacker.pos
	var pb := ib.attacker.pos
	var axis := BattleSpace.flat_dir(pa, pb)  # from a to b
	var center := (pa + pb) * 0.5
	var mutual := ia.target == ib.attacker and ib.target == ia.attacker
	attack_clashed.emit(ia, ib, center, mutual)
	log_message.emit("%s e %s se chocam!" % [ia.attacker.name, ib.attacker.name])
	var sides := [[ia, axis], [ib, -axis]]
	for s in sides:
		var inc: Incoming = s[0]
		var toward: Vector3 = s[1]  # where the opponent is, seen from this runner
		if mutual:
			inc.clash = true
			inc.clash_mode = "strike"
			inc.clash_start = inc.phase_time
			inc.clash_from = inc.attacker.pos
			inc.clash_land = inc.attacker.pos - toward * BattleSpace.CLASH_BACK
			inc.dir = toward
			inc.stand = center - toward * (BattleSpace.STAND_GAP * 0.5)  # a gap of 2.6 between the two
			inc.plan[inc.plan_i][1] = inc.phase_time + BattleSpace.CLASH_HOP_T  # the run ends with the hop
		else:
			_landing.erase(inc)
			inc.interrupted = true
			inc.interruption_feedback = true  # D-1160: the clash really stopped this run.
			AttackMotion.begin_hit_return(inc, -toward * BattleSpace.CLASH_BACK)
			attack_interrupted.emit(inc)
			_returning.append(inc)
			attack_phase.emit(inc, inc.phase)


## The engine is paused: only the status move runs (wind-up, cast, effect), then the engine
## waits STATUS_VFX_TAIL more seconds for its visual effect before everything resumes.
func _step_status_pause(delta: float) -> void:
	var inc := _status_pause
	_status_elapsed += delta
	if incoming.has(inc):
		_resolve_incoming(delta, inc)
	elif _landing.has(inc) or _returning.has(inc):
		_step_attacks(delta, inc)
	elif _status_tail < 0.0:
		# Done (or cancelled): let its effect finish. A move with a fixed total pause keeps the engine paused up to that total.
		_status_tail = maxf(_status_total - _status_elapsed, 0.01) if _status_total > 0.0 else status_vfx_tail()
	else:
		_status_tail -= delta
		if _status_tail <= 0.0:
			_status_pause = null
			status_pause_ended.emit(inc)


## D-1127: War Cry does not pause the engine, so nothing closes its banner for it.
## Emit the end event once its attack left the clock (finished or cancelled).
func _finish_war_cry_if_done() -> void:
	for inc in _war_cry_active.duplicate():
		if incoming.has(inc) or _landing.has(inc) or _returning.has(inc):
			continue
		_war_cry_active.erase(inc)
		status_pause_ended.emit(inc)


## A computer-controlled target reacts on the way in with a chance equal to its speed.
## D-1007/D-1014: an AI target decides here (chance = SPD) whether it will Evade; the moment is a random one INSIDE the valid window.
func _roll_ai_dodge(inc: Incoming) -> void:
	if inc.ai_dodge_rolled:
		return
	inc.ai_dodge_rolled = true
	var t := inc.target
	if inc.ghost or inc.is_friendly or inc.kind == Skill.Kind.STATUS or t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if randf() < auto_dodge_chance(t):  # D-1193: the same chance as the automatic evade (it was t.speed)
		inc.ai_dodge_in = 0.0  # D-1014: it will try; the moment is picked once the valid window opens


func _tick_ai_dodge(inc: Incoming, delta: float) -> void:
	if inc.ai_dodge_in < 0.0:
		return  # It will not dodge.
	# D-1014: the AI only dodges inside the valid window (physical: the prelude; projectile/area: the last 0.25 s).
	if not inc.can_evade_now():
		return
	if not inc.ai_dodge_armed:
		inc.ai_dodge_armed = true
		inc.ai_dodge_in = randf_range(0.0, maxf(inc.window_left() - 0.04, 0.0))
		return
	inc.ai_dodge_in -= delta
	if inc.ai_dodge_in <= 0.0:
		inc.ai_dodge_in = -1.0
		_ai.try_evade(inc)


func _roll_ai_evade(inc: Incoming) -> void:
	return  # D-1007: replaced by _roll_ai_dodge (random moment from the wind-up to the contact)
	if inc.phase != inc.impact_phase or inc.ghost or inc.is_friendly:
		return  # (a buff or a heal is not something to dodge)
	var t := inc.target
	if t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if randf() < t.speed:
		var end_at := minf(PRELUDE_GAP, maxf(inc.phase_len() - PERFECT_WINDOW, 0.0))
		inc.ai_evade_at = maxf(inc.phase_len() - end_at - randf_range(0.03, PERFECT_WINDOW - 0.03), 0.0)  # D-988: inside the rise window




func _ensure_move_data(inc: Incoming) -> void:
	if inc.move_id.is_empty():
		inc.move_id = BattleSpace.move_id(inc.label)
	if inc.move_data == null:
		inc.move_data = MoveCatalog.get_move(StringName(inc.move_id))


func move_is_untargetable(inc: Incoming) -> bool:
	if inc.move_data != null and inc.move_data.untargetable:
		return true
	return BattleSpace.move_id(inc.label) in ["investida_subterranea", "investida_escavadora", "teleporte_rapido"]


func move_teleports(inc: Incoming) -> bool:
	if inc.move_data != null and inc.move_data.teleport:
		return true
	return BattleSpace.move_id(inc.label) == "teleporte_rapido"


func _strike(inc: Incoming) -> void:
	_ensure_move_data(inc)
	AttackMotion.arrive(inc)
	inc.impacted = true
	_landing.erase(inc)
	if not _returning.has(inc):
		_returning.append(inc)
	if inc.ghost or inc.interrupted:
		return
	if inc.kind != Skill.Kind.STATUS and not inc.bounce_no_reward:
		_record_strike_proficiency(inc)
	if not inc.target.is_alive():
		_retarget_aoe(inc)
	if inc.dodged:
		if inc.attacker.taunt_atk_bonus:
			inc.attacker.taunt_atk_bonus = false
			inc.attacker.taunted_by = null
		log_message.emit("%s esquivou de %s!" % [inc.target.name, inc.label])
		inc.target.record_proficiency("AGI", 3)
	elif inc.attacker.is_alive() and inc.kind == Skill.Kind.STATUS:
		_execute_status_move(inc)
	elif inc.target.is_alive() and (inc.attacker.is_alive() or inc.kind == Skill.Kind.PROJECTILE):
		var behavior := MoveBehaviorRegistry.get_behavior(inc.move_id)
		if behavior.on_strike(inc, self):
			return
		var vpush := true
		if inc.skill != null:
			vpush = inc.skill.pushes_visually()  # D-1073: projectile does not shove; melee/CAST does.
		elif inc.kind == Skill.Kind.MELEE or inc.kind == Skill.Kind.CAST:
			vpush = true
		else:
			vpush = false
		var hit_info: Dictionary
		if behavior.has_before_hit():
			hit_info = behavior.before_hit(inc, self)
		else:
			var hit_opts := {"visual_push": vpush, "move_data": inc.move_data}
			if inc.bounce_no_reward:
				# D-1025: a bounce is a normal hit but never grants extra ATB/Burst, and the FX must not treat
				# it as the main beam's impact.
				hit_opts = {"no_gain": true, "bounce": true, "bounce_index": inc.bounce_index, "visual_push": vpush, "move_data": inc.move_data}
			hit_info = apply_hit(inc.attacker, inc.target, inc.power, inc.element, inc.label, inc.whiffed, inc.auto_dodged, hit_opts)
		var foes: Array[Combatant] = enemies if inc.attacker.is_player else party  # The attacker's opponents.
		if inc.is_aoe:
			for foe in foes:
				if foe.is_alive() and foe != inc.target:
					apply_hit(inc.attacker, foe, inc.power * 0.85, inc.element, inc.label, inc.whiffed, false, {"visual_push": vpush, "move_data": inc.move_data})
		elif (inc.move_data != null and inc.move_data.aoe_on_contact) or (inc.skill != null and inc.skill.aoe_on_contact):
			# D-032: Se o alvo principal foi atingido (não esquivou / não invulnerável), aliados sofrem dano total (1.6x)
			if not hit_info.get("evaded", false):
				for foe in foes:
					if foe.is_alive() and foe != inc.target:
						apply_hit(inc.attacker, foe, inc.power, inc.element, inc.label, inc.whiffed, false, {"visual_push": vpush, "move_data": inc.move_data})
		behavior.on_hit(inc, self, hit_info)


## An area attack whose aimed target is gone aims at the next opponent still standing, so the
## rest of the team does not escape it. (Single-target attacks are simply lost.)
func _retarget_aoe(inc: Incoming) -> void:
	if not inc.is_aoe or inc.is_friendly:
		return
	var foes: Array[Combatant] = enemies if inc.attacker.is_player else party
	var next := _first_alive(foes)
	if next != null:
		inc.target = next


func _execute_status_move(inc: Incoming) -> void:
	_ensure_move_data(inc)
	inc.attacker.record_proficiency("WIS", 3)
	var behavior := MoveBehaviorRegistry.get_behavior(inc.move_id)
	if behavior.on_status(inc, self):
		return
	# Fallback for status Moves that do not declare a behavior yet.
	if inc.target.is_alive():
		log_message.emit("%s usa %s em %s" % [inc.attacker.name, inc.label, inc.target.name])
		hit_resolved.emit(inc.attacker, inc.target, inc.element, {
			"status": true, "evaded": false, "dmg": 0, "weak": false,
			"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
			"skill_name": inc.label
		})


## D-1223: records the attacker's real action once per execution (never per AoE target or bounce).
func _record_strike_proficiency(inc: Incoming) -> void:
	var magical := false
	if inc.move_data != null:
		magical = inc.move_data.damage_type == MoveData.DamageType.MAGICAL
	elif inc.skill != null:
		magical = inc.skill.is_magical()
	inc.attacker.record_proficiency("MAG" if magical else "STR", 3)


## Resolved attacks that FX still has to draw (landing or returning).
func attacks_in_flight() -> Array[Incoming]:
	var list: Array[Incoming] = []
	list.append_array(_landing)
	list.append_array(_returning)
	return list


# --- Rewards ------------------------------------------------------------------

## Credits `amount` ATB blocks to `owner` right now and queues one token per block.
## The token flight lives in BattleRewards (Etapa 4); Battle keeps this API.
func grant_atb(owner: Combatant, amount: int, source: Combatant) -> void:
	_reward_queue.grant_atb(owner, amount, source)


func grant_burst(owner: Combatant, source: Combatant, fast := false) -> void:
	_reward_queue.grant_burst(owner, source, fast)


# --- Helpers ---------------------------------------------------------------

## Removes every positive badge from `target` and queues it for `attacker` after the 0.30 s
## transfer. Debuffs are never stolen. Returns one entry per badge (also used by the VFX).
## The transfer flight lives in BattleBadges (Etapa 4); Battle keeps this API.
func steal_badges(attacker: Combatant, target: Combatant) -> Array:
	return _badges.steal(attacker, target)


## D-1103: Javelin Throw keeps the D-150 base (10% + LUK difference) and adds up to
## 20 percentage points linearly as the target's current HP falls. Other Moves keep CRIT_CHANCE.
func crit_chance_for(attacker: Combatant, target: Combatant, label: String) -> float:
	if BattleSpace.move_id(label) == "javelin_throw":
		var missing := 1.0 - float(target.hp) / float(maxi(target.max_hp, 1))
		# D-150 raw base: clamping only at the end keeps a negative LUK difference
		# able to cancel the life bonus instead of being floored at 0 first.
		var base := 0.10 + float(attacker.luk - target.luk) * 0.01
		return clampf(base + 0.20 * missing, 0.0, 1.0)
	return CRIT_CHANCE


func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false, opts := {}) -> Dictionary:
	var info := {"evaded": false, "dmg": 0, "weak": false, "crit": false, "gain": 0, "whiffed": whiffed, "power": power, "skill_name": label}
	info["visual_push"] = bool(opts.get("visual_push", true))  # D-1073: the contact FX may skip the shove.
	var hit_move_data: MoveData = opts.get("move_data", null)
	if hit_move_data == null:
		hit_move_data = MoveCatalog.get_move(StringName(BattleSpace.move_id(label)))
	if bool(opts.get("bounce", false)):
		# D-1025: a bounce hit is a normal hit for weakness/crit/evade, but the FX and the reward rules can tell it
		# apart from the main beam.
		info["bounce"] = true
		info["bounce_index"] = int(opts.get("bounce_index", 0))

	# Consumo do bônus de ATK do Taunt (D-032: consumido na primeira ação ofensiva, mesmo se errar/desviar/alvo invulnerável)
	if attacker.taunt_atk_bonus:
		attacker.taunt_atk_bonus = false
		attacker.taunted_by = null

	# Invulnerabilidade (Teleport / Dig sob o chão — D-032)
	if target.is_invulnerable_target():
		info["evaded"] = true
		log_message.emit("%s não está lá e o ataque erra completamente! (MISS!)" % target.name)
		hit_resolved.emit(attacker, target, element, info)
		return info

	# Cegueira (Sand Attack — D-032: 35% de chance de errar)
	if attacker.is_blind() and randf() < 0.35:
		info["evaded"] = true
		log_message.emit("%s erra o ataque devido à cegueira! (MISS!)" % attacker.name)
		hit_resolved.emit(attacker, target, element, info)
		return info

	# Automatic evade: disabled if the target whiffed an early manual Evade!
	if auto_dodged:
		grant_atb(target, 1, target)
		info["evaded"] = true
		log_message.emit("%s esquiva de %s automaticamente! +1 bloco" % [target.name, label])
		target.record_proficiency("AGI", 3)
		hit_resolved.emit(attacker, target, element, info)
		return info
	# Move-authored step between a confirmed contact and the damage (Drain Spear's Badge Steal).
	if opts.has("before_damage"):
		var before: Callable = opts["before_damage"]
		if before.is_valid():
			before.call()
	var magic_flat := int(opts.get("magic_flat", -1))
	if magic_flat >= 0 and target.is_magic_immune():
		info["immune"] = true
		log_message.emit("%s é imune ao dano mágico!" % target.name)
		hit_resolved.emit(attacker, target, element, info)
		return info
	var weak := false
	var crit := false
	var dmg := 0
	var affinity_kind := target.affinity_for(element)
	var affinity_mult := DamageMath.affinity_multiplier(affinity_kind)
	info["affinity"] = affinity_kind
	info["affinity_mult"] = affinity_mult
	info["affinity_applied"] = magic_flat < 0
	if magic_flat >= 0:
		# Drain Spear: 5 + MAG - WIS, minimum 1. No weakness, crit or position multiplier.
		dmg = DamageMath.drain(magic_flat, attacker.mag, target.spi)
		info["magic"] = true
	else:
		weak = affinity_kind == Affinity.Type.WEAK
		crit = whiffed or debug_roll == 3 or (debug_roll == 0 and randf() < crit_chance_for(attacker, target, label))
		# Position: +10% per step in front for the attacker, -10% per step behind for the target.
		var step_mult := DamageMath.step_multiplier(attacker.pos_step, target.pos_step)
		# D-1140/D-122: a Move declared magic scales with MAG instead of STR; the rest of the formula is the same.
		var magical := hit_move_data != null and hit_move_data.damage_type == MoveData.DamageType.MAGICAL
		var attack_stat := attacker.mag if magical else attacker.attack
		dmg = DamageMath.resolve_offense(attack_stat, power, affinity_mult, crit, step_mult, magical, target.wis)
	var guard_break := false
	if hit_move_data != null:
		guard_break = hit_move_data.has_tag(&"guard_break")
	else:
		guard_break = BattleSpace.move_id(label) == "quebra_telha"  # compatibility for Skills without MoveData
	# D-272: contact destroys the Guard. It cuts the damage (rounded up), except Brick Break, which
	# breaks it, deals the full damage and gives the attacker 1 ATB.
	var guard_result := ""
	if target.is_guarding():
		if guard_break:
			guard_result = "broken"
			grant_atb(attacker, 1, target)
			target.end_guard("broken")
		else:
			guard_result = "absorbed"
			dmg = DamageMath.apply_guard(dmg)
			target.end_guard("hit")
	info["guard"] = guard_result
	# D-1026: ARMOR. The Guard has priority and keeps the badge. Otherwise the first contact of a Move destroys it: the
	# damage is normal, but there is no interruption, no contact effect and no knockback (the K.O. launch stays).
	var armor_result := ""
	if target.is_armored() and guard_result == "":
		armor_result = "hit"
		target.end_armor("hit")
	info["armor"] = armor_result
	# Badge Steal shield: a reserve absorbs before HP. The Drain Spear already removed the
	# target's shield before this point, so the stolen shield never absorbs its own hit.
	var shield_absorbed := 0
	if target.is_shielded():
		shield_absorbed = target.absorb_shield(dmg)
		dmg -= shield_absorbed
		info["shield_absorbed"] = shield_absorbed
		if target.shield_hp <= 0:
			info["shield_broke"] = true
			target.end_shield("broken")
	if shield_absorbed > 0:
		info["shield_hit"] = true
	if dmg > 0:
		target.take_damage(dmg, bool(opts.get("bypass_def", false)))
		if not bool(opts.get("bounce", false)):
			target.record_proficiency("VIT", 1)
	if not target.is_alive():
		_drop_returns_of(target)
	var gain := 0 if bool(opts.get("no_gain", false)) else (2 if weak else 0) + (1 if crit else 0)
	if gain > 0:
		grant_atb(attacker, gain, target)
	info["dmg"] = dmg
	info["weak"] = weak
	if weak and not target.is_player:  # D-981: a weakness hit reveals the species' elements
		var gst: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameState") if Engine.get_main_loop() is SceneTree else null
		if gst != null:
			gst.discovered_species[gst.species_key(target)] = true
	info["crit"] = crit
	if crit:
		attacker.record_proficiency("LUK", 2)
	info["gain"] = gain
	var element_name := "mágico" if magic_flat >= 0 else Element.name_of(element)
	log_message.emit("%s usa %s (%s) em %s (%d dano)%s%s" % [
		attacker.name, label, element_name, target.name, dmg,
		(" [escudo -%d]" % shield_absorbed if shield_absorbed > 0 else ""),
		(" FRAQUEZA! +2 bloco(s)" if weak else "") + (" RESISTIU! (x0.5)" if affinity_kind == Affinity.Type.RESIST and magic_flat < 0 else "") + (" CRÍTICO! +1 bloco" if crit else "")])

	# Efeitos de contato adicionais (D-032/D-1005/D-977/D-238), por Move (D-1079).
	if armor_result != "":
		info["interrupted"] = false  # D-1026: ARMOR absorbs the interruption and every contact effect
		log_message.emit("A ARMOR de %s absorve o impacto (sem interrupção nem efeitos de contato)!" % target.name)
	else:
		var behavior_id := hit_move_data.id if hit_move_data != null else StringName(BattleSpace.move_id(label))
		MoveBehaviorRegistry.get_behavior(behavior_id).on_contact(attacker, target, info, self)

	hit_resolved.emit(attacker, target, element, info)
	return info


## Public wrappers used by MoveBehavior (D-1079, Etapa 2). They keep the same
## code paths the old inline move-specific branches used.
func apply_hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false, opts := {}) -> Dictionary:
	return _hit(attacker, target, power, element, label, whiffed, auto_dodged, opts)


func interrupt_attacks_of(c: Combatant, hitter: Combatant, force: float) -> bool:
	return _interrupt_attacks_of(c, hitter, force)


## Used by Tidal Surge's behavior to register a bounce without owning the
## Battle's landing list (D-1079).
func add_landing(inc: Incoming) -> void:
	_landing.append(inc)


func roll_ai_for(inc: Incoming) -> void:
	_roll_ai_evade(inc)
	_roll_ai_dodge(inc)


## D-238: one Burn clock step. Each tick takes BURN_DMG fixed HP; it may kill (the death animation plays, no K.O. launch).
func _tick_burn(c: Combatant, delta: float) -> void:
	if not c.is_burning() or not c.is_alive():
		return
	c.burn_clock -= delta
	while c.burn_clock <= 0.0 and c.burn_ticks_left > 0 and c.is_alive():
		c.burn_clock += BURN_INTERVAL
		c.burn_ticks_left -= 1
		c.set_meta("died_by_burn", true)  # the scene reads it from `died` (no ballistic K.O. launch)
		c.take_damage(BURN_DMG, true)
		burn_ticked.emit(c, BURN_DMG)
		log_message.emit("%s sofre %d de Burn" % [c.name, BURN_DMG])
		if not c.is_alive():
			c.clear_burn()
			_drop_returns_of(c)
			_check_end()
			return
		c.set_meta("died_by_burn", false)
	if c.is_alive() and c.burn_ticks_left <= 0:
		c.burn_clock = 0.0
		burn_ended.emit(c)


## A combatant that died stops being driven by its own attacks in flight.
func _drop_returns_of(c: Combatant) -> void:
	c.set_rest(c.pos)
	c.is_invulnerable = false
	for inc in incoming.duplicate():
		if inc.attacker == c and not inc.ghost:
			incoming.erase(inc)
			attack_cancelled.emit(inc)
	for inc in _landing.duplicate():
		if inc.attacker == c and not inc.ghost:
			_landing.erase(inc)
			attack_cancelled.emit(inc)
	for inc in _returning.duplicate():
		if inc.attacker == c and not inc.ghost:
			_returning.erase(inc)
			attack_cancelled.emit(inc)


## Being hit before its own strike lands stops whatever `c` was doing: still winding up
## (cancelled) or already on its way (it stops where it is, never hits, then recovers).
## Returns true when it really stopped an action of `c` (D-236: Fire Bullet draws another impact then; nothing else reads it).
func _interrupt_attacks_of(c: Combatant, hitter: Combatant, force: float) -> bool:
	var stopped := false
	var stopped_windup := false
	for inc in incoming.duplicate():
		if inc.attacker == c and not inc.ghost:
			incoming.erase(inc)
			inc.interrupted = true
			inc.interruption_feedback = true  # D-1160: the hit really cancelled the wind-up.
			stopped = true
			stopped_windup = true
			log_message.emit("%s é interrompido!" % c.name)
			attack_cancelled.emit(inc)
	if stopped_windup:
		windup_hit_interrupted.emit(c, hitter)  # D-1129: the hit already shakes; this only feeds the slow-motion.
	# The knockback it takes: away from the hit, or straight back from its own facing.
	var own_back := -Vector3(sin(c.yaw), 0.0, cos(c.yaw))
	var hit_push := BattleSpace.flat_dir(hitter.pos, c.pos)
	var back := hit_push if (c.pos.distance_to(hitter.pos) > 0.25 and hit_push.dot(own_back) > 0.15) else own_back
	var push := back.normalized() * clampf(1.5 * force, 1.1, 2.4)
	for inc in _landing.duplicate():
		if inc.attacker != c or inc.impacted or inc.interrupted or inc.ghost:
			continue
		if inc.kind == Skill.Kind.PROJECTILE and inc.phase == Phase.TRAVEL:
			continue  # Projectile already fired and in flight: hitting the caster no longer destroys it.
		_landing.erase(inc)
		inc.interrupted = true
		inc.interruption_feedback = true  # D-1160: the hit stopped it before its impact.
		stopped = true
		if not c.is_alive():
			c.set_rest(c.pos)  # It falls where it is: no hop home for a body.
			inc.motion = "cast"
			inc.plan = [[Phase.RETURN, 0.05]]
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
		elif inc.motion == "cast":
			inc.plan = [[Phase.RETURN, 0.55 + AttackMotion.HIT_STUN_EXTRA]]
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
		else:
			AttackMotion.begin_hit_return(inc, push)
		attack_interrupted.emit(inc)
		if not _returning.has(inc):
			_returning.append(inc)
		log_message.emit("%s é interrompido!" % c.name)
		attack_phase.emit(inc, inc.phase)
	for inc in _returning.duplicate():
		if inc.attacker == c and inc.phase == Phase.RETURN and not inc.interrupted and not inc.ghost and inc.kind == Skill.Kind.MELEE:
			inc.interrupted = true  # D-1160: the action already hit; a hit during the return is not shown as an interruption.
			stopped = true
			if inc.motion == "cast":
				inc.plan = [[Phase.RETURN, 0.55 + AttackMotion.HIT_STUN_EXTRA]]
				inc.plan_i = 0
				inc.phase_time = 0.0
			else:
				AttackMotion.begin_hit_return(inc, push)
			attack_interrupted.emit(inc)
	if stopped:
		_clear_queued(c)  # D-1146: only an action that was really interrupted drops the slot.
	return stopped


# --- Employ (D-1229, Phase 5: the mechanical flow only) ----------------------

func is_employ_active() -> bool:
	return not _employ.is_empty()


## "" when `actor` may start an Employ attempt now (on `target`, or on any living opponent when
## null); otherwise why not. The codes are telemetry codes, not menu texts.
func employ_refusal(actor: Combatant, target: Combatant = null) -> String:
	if not running:
		return "not_running"
	if is_employ_active():
		return "busy"
	if actor == null or not actor.is_alive():
		return "actor_down"
	if roster == null or not roster.can_attempt_employ():
		return "blocked"
	if actor.blocks() < EMPLOY_BLOCKS:
		return "need_atb"  # ATB blocks only: Burst never pays an Employ.
	var foes := opponents_of(actor)
	var living := 0
	for f in foes:
		if f.is_alive():
			living += 1
	if living == 0:
		return "no_target"
	if living == 1 and not employ_allow_last:
		return "last_enemy"
	if target == null:
		return ""
	if not foes.has(target) or not target.is_alive():
		return "target_invalid"  # Provisional (creator): any living enemy may be the target.
	return ""


## The target picker opened ("picking") or closed without a confirmed target ("cancelled").
## Nothing is paid by either.
func note_employ_pick(actor: Combatant, stage: String) -> void:
	employ_changed.emit(stage, _employ_row(stage, actor, null))


## The target was confirmed: pays the 5 ATB for real (spend(), never pay(): Burst stays) and freezes
## the whole battle until finish_employ(). False, with nothing paid, when it may not start.
func begin_employ(actor: Combatant, target: Combatant) -> bool:
	var why := employ_refusal(actor, target)
	if why != "":
		employ_changed.emit("refused", _employ_row("refused", actor, target, {"reason": why}))
		return false
	# D-1239 (revista): nothing is cancelled here. The attempt freezes the battle and, once it ends, everything
	# resumes where it stopped; only a success cancels what involves the recruit (see finish_employ()).
	var before := {"cost": EMPLOY_BLOCKS, "blocks_before": snappedf(actor.blocks(), 0.01), "burst_before": actor.burst}
	actor.spend(EMPLOY_BLOCKS)
	_employ = {"actor": actor, "target": target}
	employ_changed.emit("started", _employ_row("started", actor, target, before))
	state_changed.emit()
	return true


## D-1239 (revista, "ok siga com as mudanças ao invés de cancelamento"): the Employ freezes the battle and
## it resumes as it was. Only when the attempt succeeds, what involves the recruit `who` (as attacker or as
## target) is cancelled, wind-up or on its way, with its cost given back (ATB, MP and MP regen timer, or the
## Burst when the Burst paid). Queued moves of `who`, or aimed at `who`, are dropped (nothing was paid, D-161).
## A runner of someone else that was heading to `who` hops back like at the end of a battle; `who`'s own
## runner just stops (it leaves the field). Moves that already landed are not touched. Everything else
## keeps going. Returns the telemetry lists.
func _employ_cancel_moves(who: Combatant) -> Dictionary:
	var cancelled: Array = []
	var queue_cleared: Array = []
	for c in party + enemies:
		if c.queued_skill != null and (c == who or c.queued_target == who or c.queued_target2 == who):
			queue_cleared.append({"actor": c.name, "move": c.queued_skill.display_name})
			_clear_queued(c)
	for inc in incoming.duplicate():
		if inc.ghost or not _involves(inc, who):
			continue
		incoming.erase(inc)
		inc.interrupted = true  # D-1160: mechanical end, not an interruption on screen.
		cancelled.append(_employ_refund(inc))
		attack_cancelled.emit(inc)
	for inc in _landing.duplicate():
		if inc.ghost or inc.impacted or not _involves(inc, who):
			continue
		_landing.erase(inc)
		cancelled.append(_employ_refund(inc))
		inc.attacker.is_invulnerable = false
		inc.interrupted = true
		if inc.attacker != who and inc.attacker.is_alive() and AttackMotion.carries(inc):
			AttackMotion.begin_plain_return(inc, inc.attacker.pos)
			inc.impacted = true  # Nothing lands any more: only the way home is left.
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
			_returning.append(inc)
			attack_phase.emit(inc, Phase.RETURN)
		else:
			attack_cancelled.emit(inc)
	for inc in _returning.duplicate():
		if inc.attacker == who:
			_returning.erase(inc)  # The recruit leaves the field: its own way home is not played.
			attack_cancelled.emit(inc)
	if _status_pause != null and not incoming.has(_status_pause) and not _landing.has(_status_pause) and _status_pause.interrupted:
		var paused := _status_pause  # Its status move was cancelled above: the status pause closes with it.
		_status_pause = null
		status_pause_ended.emit(paused)
	return {"cancelled": cancelled, "queue_cleared": queue_cleared}


func _involves(inc: Incoming, who: Combatant) -> bool:
	return inc.attacker == who or inc.target == who or inc.target2 == who


## Gives back what `inc` cost its attacker (the Burst when the Burst paid, else the ATB; and the MP).
func _employ_refund(inc: Incoming) -> Dictionary:
	var a := inc.attacker
	if inc.paid_burst:
		a.gain_burst(1)
	elif inc.paid_blocks > 0.0:
		a.add_atb(inc.paid_blocks)
	if inc.paid_mp > 0:
		a.mp = mini(a.mp + inc.paid_mp, a.max_mp)
		a.mp_regen_timer = inc.paid_mp_timer  # D-1239: the timer the move reset goes back to what it was.
	var row := {"actor": a.name, "move": inc.label, "phase": Phase.keys()[inc.phase],
		"atb": inc.paid_blocks, "mp": inc.paid_mp, "mp_timer": inc.paid_mp_timer, "burst": 1 if inc.paid_burst else 0}
	inc.paid_burst = false
	inc.paid_blocks = 0.0
	inc.paid_mp = 0
	return row


## D-1240: STR and MAG of `c` as the Employ chance reads them: effective attributes times the ATK stage
## multiplier (no rounding, no cap).
func _employ_pair(c: Combatant) -> Array:
	var m := c.atk_stage_mult()
	return [float(c.str) * m, float(c.mag) * m]


## D-1230/D-1240: the deterministic Employ chance (no roll, no side effect) with every intermediate.
## Participants: the living members of the actor's team. level_traveler: the level of the team leader (first
## member). Respect: neutral 50 until a real source exists (D-1231). Rhythm bonus: D-1257 note_bonuses,
## empty until the minigame feeds it.
func employ_chance(actor: Combatant, target: Combatant, note_bonuses: Array = []) -> Dictionary:
	var members: Array = []
	var side := team_of(actor)
	for c in side:
		if c.is_alive():
			members.append(_employ_pair(c))
	var foe := _employ_pair(target)
	var leader_level: int = side[0].level if not side.is_empty() else actor.level
	var info := EmployMath.breakdown(members, foe[0], foe[1], leader_level, target.level, EmployMath.RESPECT_NEUTRAL, note_bonuses)
	info["members"] = members.size()
	info["level_traveler"] = leader_level
	info["level_enemy"] = target.level
	info["respect"] = EmployMath.RESPECT_NEUTRAL
	info["note_bonuses"] = note_bonuses
	info["rhythm_pp"] = EmployMath.rhythm_bonus(note_bonuses)
	return info


## D-1240: ends the open attempt by the real chance. No roll is made when P is 0 or 100 (D-1230); otherwise
## roll = randf() * 100 (the global RNG, so --seed rules it) and it succeeds when roll < P. Returns the chance
## breakdown plus "rolled", "roll" (-1 when none) and "success"; {} when no attempt is open.
## D-1257: note_bonuses feed the rhythm bonus B of the chance.
func resolve_employ(note_bonuses: Array = []) -> Dictionary:
	if _employ.is_empty():
		return {}
	var info := employ_chance(_employ["actor"], _employ["target"], note_bonuses)
	var p := float(info["P"])
	var rolled := EmployMath.needs_roll(p)
	var roll := -1.0
	if rolled:
		roll = employ_roll_override if employ_roll_override >= 0.0 else randf() * 100.0
	var success := EmployMath.resolve(p, roll)
	info["rolled"] = rolled
	info["roll"] = roll
	info["success"] = success
	finish_employ(success, false, {"chance": info, "rolled": rolled, "roll": roll})
	return info


## Ends the open attempt and lets the battle run again. Failure: Employ is blocked for the rest of
## this battle (the BOOST is Phase 7). Success: the target leaves the field without being defeated
## and joins the roster once; it only fights again through Summon (Phase 8). No damage, XP, loot,
## death or victory comes from here. `forced`: the result came from debug, not from a roll.
func finish_employ(success: bool, forced := false, info := {}) -> bool:
	if _employ.is_empty():
		return false
	var actor: Combatant = _employ["actor"]
	var target: Combatant = _employ["target"]
	_employ = {}
	var extra := {"result": "success" if success else "failure", "forced": forced, "cancelled": [], "queue_cleared": []}
	extra.merge(info)
	if success:
		var cleared := _employ_cancel_moves(target)  # D-1239: only what involves the recruit; the rest resumes.
		extra["cancelled"] = cleared["cancelled"]
		extra["queue_cleared"] = cleared["queue_cleared"]
		var list := team_of(target)
		list.erase(target)
		for c in party + enemies:
			if c.engaged_with == target:
				c.engaged_with = null  # the recruit left the field: nobody stays engaged with it
		_clear_queued(target)
		var place := ExpeditionRoster.Place.SUBSTITUTE if roster.capacity_left(ExpeditionRoster.Place.SUBSTITUTE) > 0 else ExpeditionRoster.Place.STATIONED
		var uid := roster.register(target, place)
		roster.mark_recruited_in_battle(uid)
		if _first_alive(list) == null:
			_employ_left_no_enemy = true
		extra["uid"] = uid
		extra["place"] = "SUBSTITUTE" if roster.place_of(uid) == ExpeditionRoster.Place.SUBSTITUTE else "STATIONED"
		extra["in_field"] = party.has(target) or enemies.has(target)
	else:
		roster.mark_employ_failed()
		target.start_boost(BOOST_SECONDS)  # D-1229/D-1242: the enemy that refused gets the BOOST
		extra["boost"] = {"target": target.name, "seconds": BOOST_SECONDS}
	extra["blocked"] = not roster.can_attempt_employ()
	var alive := 0
	for e in opponents_of(actor):
		if e.is_alive():
			alive += 1
	extra["enemies_left"] = alive
	employ_changed.emit("ended", _employ_row("ended", actor, target, extra))
	state_changed.emit()
	return true


func _employ_row(stage: String, actor: Combatant, target: Combatant, extra := {}) -> Dictionary:
	var row := {
		"stage": stage, "actor": actor.name if actor != null else "", "target": target.name if target != null else "",
		"atb": snappedf(actor.atb, 0.01) if actor != null else 0.0, "extra": actor.extra if actor != null else 0.0,
		"blocks": snappedf(actor.blocks(), 0.01) if actor != null else 0.0, "burst": actor.burst if actor != null else 0,
	}
	row.merge(extra)
	return row


## D-1257: telemetry of the rhythm minigame, emitted as its own "rhythm" stage with the summary
## (grades, bonuses, total_pp) merged into the row. Uses the open attempt's actor/target when there is one.
func note_employ_rhythm(summary: Dictionary) -> void:
	var actor: Combatant = _employ.get("actor", null)
	var target: Combatant = _employ.get("target", null)
	employ_changed.emit("rhythm", _employ_row("rhythm", actor, target, summary))


# --- Summon (D-1232/D-1244, Phase 8: the mechanical swap only) ---------------

## D-1244: who commands the menu. The protagonist while it is on the field and alive; otherwise the first
## living active ally. null when nobody is alive. Read from `party`, never from `is_player` (D-235).
func menu_owner() -> Combatant:
	if protagonist != null and party.has(protagonist) and protagonist.is_alive():
		return protagonist
	return _first_alive(party)


## D-1254: units whose pentagram is still forming. They are not in `party` yet: nobody targets them and
## they cannot act.
func arriving() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for a in _arrivals:
		out.append(a["entering"])
	return out


## Seconds since the Summon of `entering` started (0..SUMMON_ARRIVAL_SECONDS); -1 when it is not arriving. For the visuals.
func arrival_elapsed(entering: Combatant) -> float:
	for a in _arrivals:
		if a["entering"] == entering:
			return SUMMON_ARRIVAL_SECONDS - float(a["left"])
	return -1.0


func is_summon_arriving() -> bool:
	return not _arrivals.is_empty()


## "" when `leaving` may be swapped for `entering` right now; otherwise why not. The codes are telemetry
## codes, not menu texts. `leaving`: any active member of `party`, alive or knocked out (D-1244 "Pode sair").
## `entering`: a roster SUBSTITUTE (a STATIONED recruit does not enter, D-1233). D-1254: no ATB cost.
func summon_refusal(leaving: Combatant, entering: Combatant) -> String:
	if not running:
		return "not_running"
	if is_employ_active():
		return "busy"
	if roster == null:
		return "no_roster"
	if leaving == null or entering == null or leaving.uid == "" or entering.uid == "":
		return "no_uid"
	if not party.has(leaving):
		return "leaving_invalid"
	if roster.place_of(entering.uid) != ExpeditionRoster.Place.SUBSTITUTE:
		return "entering_invalid"
	for a in _arrivals:
		if a["entering"] == entering:
			return "entering_invalid"
	return ""


## D-1254: the one that leaves goes at once (it is out of `party`, keeps its HP and MP, loses every temporary
## effect and its Moves are cancelled with the cost given back, like the Employ does with the recruit, D-1239).
## The slot stays EMPTY for SUMMON_ARRIVAL_SECONDS (the pentagram); only then does the entrant enter `party`
## in that slot with ATB 0 and no temporary effect. No ATB cost, cannot be cancelled, nothing is frozen.
## False, with nothing changed, when summon_refusal() refuses.
func summon(leaving: Combatant, entering: Combatant) -> bool:
	var why := summon_refusal(leaving, entering)
	if why != "":
		summon_changed.emit("refused", _summon_row("refused", leaving, entering, {"reason": why}))
		return false
	var cleared := _employ_cancel_moves(leaving)
	var slot := party.find(leaving)
	leaving.clear_pending()  # D-1244 "quem sai perde tudo": HP and MP stay as they were.
	leaving.end_boost()
	for c in party + enemies:
		if c.engaged_with == leaving:
			c.engaged_with = null
	leaving.engaged_with = null
	leaving.in_battle = false
	party.remove_at(slot)
	roster.swap(leaving.uid, entering.uid)  # Uids never change.
	roster.note_leave(leaving.uid, battle_time)  # D-1234: participation by identity, not by slot.
	_arrivals.append({"entering": entering, "leaving": leaving, "slot": slot, "left": SUMMON_ARRIVAL_SECONDS})
	summon_changed.emit("started", _summon_row("started", leaving, entering, {
		"slot": slot, "cancelled": cleared["cancelled"], "queue_cleared": cleared["queue_cleared"],
	}))
	state_changed.emit()
	return true


func _step_arrivals(delta: float) -> void:
	for a in _arrivals.duplicate():
		a["left"] = float(a["left"]) - delta
		if float(a["left"]) <= 0.0:
			_arrivals.erase(a)
			_finish_arrival(a["leaving"], a["entering"], int(a["slot"]))


func _finish_arrival(leaving: Combatant, entering: Combatant, slot: int) -> void:
	entering.clear_pending()  # D-1244 "quem entra começa limpo": HP, MP and Burst stay as they were.
	entering.pos = leaving.pos
	entering.home = leaving.home
	entering.rest = leaving.rest
	entering.has_rest = leaving.has_rest
	entering.yaw = leaving.yaw
	entering.pos_step = leaving.pos_step
	entering.step_from = leaving.step_from
	entering.step_t = 1.0
	entering.tactic_pos = leaving.tactic_pos
	entering.engaged_with = null
	entering.in_battle = true
	party.insert(mini(slot, party.size()), entering)
	entering.atb = 0.0  # D-1244 "Entra com ATB 0".
	entering.extra = 0.0
	if not entering.armor_changed.is_connected(_on_armor_changed):
		entering.armor_changed.connect(_on_armor_changed)  # D-1026
	if not entering.mp_regenerated.is_connected(_on_mp_regenerated):
		entering.mp_regenerated.connect(_on_mp_regenerated)  # D-1062
	roster.note_enter(entering.uid, battle_time)
	summon_changed.emit("done", _summon_row("done", leaving, entering, {"slot": party.find(entering)}))
	state_changed.emit()


func _summon_row(stage: String, leaving: Combatant, entering: Combatant, extra := {}) -> Dictionary:
	var row := {
		"stage": stage,
		"leaving": leaving.name if leaving != null else "",
		"entering": entering.name if entering != null else "",
		"slot": -1,
		"arrival_seconds": SUMMON_ARRIVAL_SECONDS,
		"cancelled": [],
		"queue_cleared": [],
	}
	row.merge(extra, true)  # overwrite: the defaults above are placeholders for the refused rows
	return row


func _first_alive(list: Array[Combatant]) -> Combatant:
	for c in list:
		if c.is_alive():
			return c
	return null


func _check_end() -> void:
	if not running:
		return
	# D-1229: an enemy that left by Employ was not defeated (D-105); with no living enemy left that
	# way, victory/XP/loot are still the creator's to decide, so the battle is not ended here.
	var enemies_dead := _first_alive(enemies) == null and not _employ_left_no_enemy
	var party_dead := _first_alive(party) == null and _arrivals.is_empty()  # D-1254: an ally still arriving keeps the team alive
	if not enemies_dead and not party_dead:
		return
	running = false
	for inc in incoming:
		attack_cancelled.emit(inc)
	incoming.clear()
	# Winners caught mid-run or mid-swing hop home from where they are; nothing else lands.
	for inc in _landing.duplicate():
		if inc.attacker.is_alive() and AttackMotion.carries(inc):
			AttackMotion.begin_plain_return(inc, inc.attacker.pos)
			inc.impacted = true
			inc.interrupted = true  # D-1160: battle-end cleanup is not an interruption on screen.
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
			_returning.append(inc)
			attack_phase.emit(inc, Phase.RETURN)
	_landing.clear()
	_update_positions()
	for r in rewards:
		_reward_queue.release_pending(r)
	rewards.clear()
	for c in party + enemies:
		c.engaged_with = null
		c.in_battle = false
		c.end_guard("battle_end")
		c.end_boost()  # D-1242/D-1244: the BOOST ends with the battle (attributes back, Burst above 5 back to 5)
		c.end_armor("battle_end")
		_clear_queued(c)
		if c.is_alive():
			c.clear_buffs()  # The drawing goes back to normal too (D-158); a launched body keeps its own (D-166).
	if roster != null:
		roster.end_battle()
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)


## Snapshot e Rollback em memória e avanço determinístico por ticks para agentes de IA (D-1042 / D-1044).
func save_state() -> Dictionary:
	var units_state := {}
	for c in party + enemies:
		units_state[c] = c.save_state()
	return {
		"running": running,
		"debug_roll": debug_roll,
		"freeze_left": _freeze_left,
		"employ_failed": roster != null and roster.employ_failed(),  # D-1229: the block lasts the whole battle
		"employ_left_no_enemy": _employ_left_no_enemy,
		"units": units_state,
	}


func restore_state(state: Dictionary) -> void:
	running = bool(state.get("running", running))
	debug_roll = int(state.get("debug_roll", debug_roll))
	_freeze_left = float(state.get("freeze_left", 0.0))
	incoming.clear()
	_landing.clear()
	_returning.clear()
	_status_pause = null
	_employ = {}
	if roster != null:
		roster.restore_employ_failed(bool(state.get("employ_failed", false)))
	_employ_left_no_enemy = bool(state.get("employ_left_no_enemy", false))
	var units_state: Dictionary = state.get("units", {})
	for c in party + enemies:
		if units_state.has(c):
			c.restore_state(units_state[c])
	state_changed.emit()


func step_ticks(ticks: int, fixed_dt := 1.0 / 60.0) -> void:
	for _i in maxi(0, ticks):
		_process(fixed_dt)
