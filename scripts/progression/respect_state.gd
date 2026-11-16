class_name RespectState
extends RefCounted
## D-1231: the Traveler's Respect, its feats and the per-expedition limits.
## Pure data: no signals, no nodes, no log of every action (only the paid feats).

const START := 50
const MIN_VALUE := 0
const MAX_VALUE := 100

enum Event {
	CHALLENGING_ENCOUNTER_WIN,
	IMPORTANT_BOSS_FIRST_WIN,
	TACTICAL_CHALLENGE,
	EXPEDITION_DEFEAT,
	STRATEGIC_RETREAT,
	EMPLOY_FAILURE,
	EMPLOY_SUCCESS,
	WEAK_ENEMY_REPEAT,
}

## Literal deltas from D-1231, keyed by the Event values.
const DELTAS := {
	Event.CHALLENGING_ENCOUNTER_WIN: 2,
	Event.IMPORTANT_BOSS_FIRST_WIN: 6,
	Event.TACTICAL_CHALLENGE: 3,
	Event.EXPEDITION_DEFEAT: -2,
	Event.STRATEGIC_RETREAT: 0,
	Event.EMPLOY_FAILURE: 0,
	Event.EMPLOY_SUCCESS: 0,
	Event.WEAK_ENEMY_REPEAT: 0,
}

const MAX_CHALLENGING_REWARDS_PER_EXPEDITION := 3

var value := START
var _feats: Dictionary = {}
var _challenging_rewards := 0


## Resets only the per-expedition counter. value and the feats persist.
func begin_expedition() -> void:
	_challenging_rewards = 0


func challenging_rewards_left() -> int:
	return MAX_CHALLENGING_REWARDS_PER_EXPEDITION - _challenging_rewards


func has_feat(feat_id: String) -> bool:
	return _feats.has(feat_id)


func feats() -> Dictionary:
	return _feats.duplicate()


## Applies one event and returns the delta actually added to value.
## Whether an encounter was challenging is decided by the caller, not here.
func apply(event: Event, feat_id: String = "") -> int:
	var old_value := value
	match event:
		Event.CHALLENGING_ENCOUNTER_WIN:
			if _challenging_rewards >= MAX_CHALLENGING_REWARDS_PER_EXPEDITION:
				return 0
			_challenging_rewards += 1
		Event.IMPORTANT_BOSS_FIRST_WIN, Event.TACTICAL_CHALLENGE:
			if feat_id.is_empty() or has_feat(feat_id):
				return 0
			_feats[feat_id] = event
		Event.EXPEDITION_DEFEAT:
			pass
		_:
			return 0
	value = clampi(value + int(DELTAS[event]), MIN_VALUE, MAX_VALUE)
	return value - old_value
