class_name BattleRewards
extends RefCounted
## ATB/Burst reward tokens and their flight to the HUD. Extracted from battle.gd
## in Etapa 4; Battle keeps the public `rewards` array and the REWARD_* timings
## used by RewardLayer, so the HUD contract is unchanged.

var battle
var items: Array[BattleReward] = []
var _next_id := 0


func _init(p_battle) -> void:
	battle = p_battle


## Credits `amount` ATB blocks to `owner` right now and queues one token per block.
func grant_atb(owner: Combatant, amount: int, source: Combatant) -> void:
	var before := owner.atb
	var extra_in_grant := 0
	for k in amount:
		var r := BattleReward.new()
		_next_id += 1
		r.id = _next_id
		r.owner = owner
		r.source = source
		r.float_time = battle.REWARD_FLOAT
		r.fly_time = battle.REWARD_FLY
		r.delay = k * 0.09
		if before + float(k) >= Combatant.BLOCKS - 0.001:  # No room in the bar: an extra block.
			r.extra = true
			r.slot = int(owner.extra) + extra_in_grant
			extra_in_grant += 1
			owner.pending_extra += 1
		else:
			r.slot = clampi(int(floor(before + float(k))), 0, int(Combatant.BLOCKS) - 1)
			owner.pending_atb += 1
		items.append(r)
		battle.reward_spawned.emit(r)
	owner.add_atb(float(amount))


func grant_burst(owner: Combatant, source: Combatant, fast := false) -> void:
	var r := BattleReward.new()
	_next_id += 1
	r.id = _next_id
	r.kind = "burst"
	r.owner = owner
	r.source = source
	# Long-distance interruptions (War Cry): the token is born where the victim was
	# interrupted and zips to the owner's slot instead of hovering for 0.6 s.
	r.float_time = 0.15 if fast else battle.REWARD_FLOAT
	r.fly_time = 0.18 if fast else battle.REWARD_FLY
	owner.pending_burst += 1
	items.append(r)
	battle.reward_spawned.emit(r)


func step(delta: float) -> void:
	for r in items.duplicate():
		r.t += delta
		if not r.landed and r.age() >= r.float_time + r.fly_time:
			r.landed = true
			release_pending(r)
			battle.reward_landed.emit(r)
		if r.age() >= r.float_time + r.fly_time + battle.REWARD_IMPACT:
			items.erase(r)


func release_pending(r: BattleReward) -> void:
	if r.kind == "burst":
		r.owner.pending_burst = maxi(r.owner.pending_burst - 1, 0)
	elif r.extra:
		r.owner.pending_extra = maxi(r.owner.pending_extra - 1, 0)
	else:
		r.owner.pending_atb = maxi(r.owner.pending_atb - 1, 0)
