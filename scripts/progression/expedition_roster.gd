class_name ExpeditionRoster
extends RefCounted
## D-1233/D-1234: individual identity (uid), place (active / substitute / stationed) and
## per-battle participation for the player's roster.
##
## Pure data: no Node, no autoload access, no randomness, no signals. No XP, Employ or
## guild-capacity rule lives here; the caller decides and this file only records it.

const Combatant = preload("res://scripts/combat/combatant.gd")

const MAX_ACTIVE := 3  ## D-1233: 3 active, protagonist included.
const MAX_SUBSTITUTES := 2  ## D-1233: 2 companion substitutes.
const STATIONED_CAPACITY := 1 << 30  ## D-1233: STATIONED has no capacity limit (do not invent one).

enum Place { ACTIVE, SUBSTITUTE, STATIONED }  ## STATIONED has no capacity limit (D-1233).

var _next_id := 1
var _members: Dictionary = {}  # uid -> Combatant
var _order: Dictionary = {  # Place -> Array of uids, in order
	Place.ACTIVE: [],
	Place.SUBSTITUTE: [],
	Place.STATIONED: [],
}
var _station_info: Dictionary = {}  # uid -> Dictionary given by the caller (opaque)

# Per-battle state.
var _battle_open := false
var _employ_failed := false
var _recruited_in_battle: Array[String] = []
var _participation: Dictionary = {}  # uid -> Array of {"event": "enter"|"leave", "t": float}
var _enter_order: Array[String] = []  # uids in first-enter order (participants())


## Registers `c` at `place` and returns its uid, or "" when it was rejected.
## A null, an already registered instance and an already known `c.uid` are never duplicated
## and never moved. A full destination rejects the registration and changes nothing.
func register(c: Combatant, place: Place, info: Dictionary = {}) -> String:
	if c == null:
		return ""
	if c.uid != "" and _members.has(c.uid):
		return c.uid
	for known_uid in _members.keys():
		if _members[known_uid] == c:
			return String(known_uid)
	if capacity_left(place) <= 0:
		return ""
	var uid := _alloc_uid(c)
	(_order[place] as Array).append(uid)
	if place == Place.STATIONED:
		_station_info[uid] = info.duplicate(true)
	return uid


## True when `uid` belongs to the roster.
func has(uid: String) -> bool:
	return _members.has(uid)


## The Combatant registered under `uid`; null when unknown.
func member(uid: String) -> Combatant:
	return _members.get(uid, null) as Combatant


## The place of `uid`; -1 when unknown.
func place_of(uid: String) -> int:
	if not _members.has(uid):
		return -1
	for place in [Place.ACTIVE, Place.SUBSTITUTE, Place.STATIONED]:
		if (_order[place] as Array).has(uid):
			return int(place)
	return -1


## Copy of the uids at `place`, in order.
func uids(place: Place) -> Array[String]:
	var result: Array[String] = []
	for uid in (_order.get(place, []) as Array):
		result.append(String(uid))
	return result


## The members at `place`, in order.
func members(place: Place) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for uid in uids(place):
		var c := member(uid)
		if c != null:
			result.append(c)
	return result


## How many uids are at `place`.
func count(place: Place) -> int:
	return (_order.get(place, []) as Array).size()


## Free room at `place`. STATIONED is effectively unlimited (D-1233).
func capacity_left(place: Place) -> int:
	match place:
		Place.ACTIVE:
			return MAX_ACTIVE - count(Place.ACTIVE)
		Place.SUBSTITUTE:
			return MAX_SUBSTITUTES - count(Place.SUBSTITUTE)
		_:
			return STATIONED_CAPACITY


## Moves `uid` to `place`; false when unknown, already there or the destination is full.
## `info` is stored only for STATIONED and erased when leaving it.
func move(uid: String, place: Place, info: Dictionary = {}) -> bool:
	if not _members.has(uid):
		return false
	var current := place_of(uid)
	if current == place:
		return false
	if current < 0:
		return false
	if capacity_left(place) <= 0:
		return false
	(_order[current] as Array).erase(uid)
	(_order[place] as Array).append(uid)
	if current == Place.STATIONED:
		_station_info.erase(uid)
	if place == Place.STATIONED:
		_station_info[uid] = info.duplicate(true)
	return true


## Exchanges the places and order positions of two uids. Uids never change.
## The one that ends in STATIONED gets the station info of the one that was there.
func swap(uid_a: String, uid_b: String) -> bool:
	if uid_a == uid_b:
		return false
	if not _members.has(uid_a) or not _members.has(uid_b):
		return false
	var place_a := place_of(uid_a)
	var place_b := place_of(uid_b)
	if place_a < 0 or place_b < 0:
		return false
	var list_a: Array = _order[place_a]
	var list_b: Array = _order[place_b]
	var index_a := list_a.find(uid_a)
	var index_b := list_b.find(uid_b)
	if index_a < 0 or index_b < 0:
		return false
	list_a[index_a] = uid_b
	list_b[index_b] = uid_a
	if place_a == Place.STATIONED and place_b != Place.STATIONED:
		var moved_info: Dictionary = _station_info.get(uid_a, {})
		_station_info.erase(uid_a)
		_station_info[uid_b] = moved_info
	elif place_b == Place.STATIONED and place_a != Place.STATIONED:
		var moved_info: Dictionary = _station_info.get(uid_b, {})
		_station_info.erase(uid_b)
		_station_info[uid_a] = moved_info
	elif place_a == Place.STATIONED and place_b == Place.STATIONED:
		var info_a: Dictionary = _station_info.get(uid_a, {})
		var info_b: Dictionary = _station_info.get(uid_b, {})
		_station_info[uid_a] = info_b
		_station_info[uid_b] = info_a
	return true


## Copy of the station info of `uid`, {} when it is not stationed.
func station_info(uid: String) -> Dictionary:
	if not _members.has(uid) or place_of(uid) != Place.STATIONED:
		return {}
	return (_station_info.get(uid, {}) as Dictionary).duplicate(true)


## Makes ACTIVE mirror `party` exactly, in party order, without ever changing a uid.
## Unregistered members get a uid; members that left ACTIVE go to SUBSTITUTE when there is
## room, otherwise to STATIONED with {} info. Does not enforce MAX_ACTIVE on purpose:
## `party` is the source of truth today and validate() reports the overflow.
func sync_active(party: Array) -> void:
	var desired: Array[String] = []
	for entry in party:
		if entry == null or not (entry is Combatant):
			continue
		var c := entry as Combatant
		var uid := c.uid
		if uid == "" or not _members.has(uid) or _members[uid] != c:
			uid = _alloc_uid(c)
		if not desired.has(uid):
			desired.append(uid)

	# Promoted members leave their old place first, so the room they free is seen by _demote().
	for place in [Place.SUBSTITUTE, Place.STATIONED]:
		var list: Array = _order[place]
		for uid in desired:
			if list.has(uid):
				list.erase(uid)
				_station_info.erase(uid)

	var active: Array = _order[Place.ACTIVE]
	for uid in active.duplicate():
		if not desired.has(uid):
			active.erase(uid)
			_demote(uid)

	_order[Place.ACTIVE] = desired


## Human-readable problems; empty when the roster is consistent.
func validate() -> Array[String]:
	var problems: Array[String] = []
	var seen: Dictionary = {}
	for place in [Place.ACTIVE, Place.SUBSTITUTE, Place.STATIONED]:
		for ordered_uid in (_order.get(place, []) as Array):
			var uid := String(ordered_uid)
			if seen.has(uid):
				problems.append("uid %s is listed twice (also in %s)" % [uid, _place_name(int(seen[uid]))])
			else:
				seen[uid] = place
			if not _members.has(uid):
				problems.append("uid %s is ordered in %s but has no member" % [uid, _place_name(int(place))])
	for key in _members.keys():
		var uid := String(key)
		if not seen.has(uid):
			problems.append("uid %s has a member but is in no order" % uid)
		var c := _members[uid] as Combatant
		if c == null or c.uid != uid:
			problems.append("member %s keeps uid %s" % [uid, "" if c == null else c.uid])
	if count(Place.ACTIVE) > MAX_ACTIVE:
		problems.append("ACTIVE has %d members (max %d)" % [count(Place.ACTIVE), MAX_ACTIVE])
	if count(Place.SUBSTITUTE) > MAX_SUBSTITUTES:
		problems.append("SUBSTITUTE has %d members (max %d)" % [count(Place.SUBSTITUTE), MAX_SUBSTITUTES])
	return problems


## Starts a battle: resets per-battle state and records an enter for every ACTIVE uid.
func begin_battle(t: float = 0.0) -> void:
	_battle_open = true
	_employ_failed = false
	_recruited_in_battle.clear()
	_participation.clear()
	_enter_order.clear()
	for uid in uids(Place.ACTIVE):
		note_enter(uid, t)


## Closes the battle; participation stays readable until the next begin_battle().
func end_battle() -> void:
	_battle_open = false


## D-1229: a failed Employ blocks new attempts until the next battle.
func can_attempt_employ() -> bool:
	return _battle_open and not _employ_failed


func mark_employ_failed() -> void:
	_employ_failed = true


## Battle snapshot support (Battle.save_state/restore_state): the per-battle "Employ failed" flag.
func employ_failed() -> bool:
	return _employ_failed


func restore_employ_failed(value: bool) -> void:
	_employ_failed = value


func mark_recruited_in_battle(uid: String) -> void:
	if not _members.has(uid):
		return
	if not _recruited_in_battle.has(uid):
		_recruited_in_battle.append(uid)


func recruited_in_battle() -> Array[String]:
	var result: Array[String] = []
	for uid in _recruited_in_battle:
		result.append(uid)
	return result


## D-1234: records when a uid entered the battle. Unknown uids and closed battles are ignored.
func note_enter(uid: String, t: float) -> void:
	if not _battle_open or not _members.has(uid):
		return
	if not _enter_order.has(uid):
		_enter_order.append(uid)
	var events: Array = _participation.get(uid, [])
	events.append({"event": "enter", "t": t})
	_participation[uid] = events


## D-1234: records when a uid left the battle. Unknown uids and closed battles are ignored.
func note_leave(uid: String, t: float) -> void:
	if not _battle_open or not _members.has(uid):
		return
	var events: Array = _participation.get(uid, [])
	events.append({"event": "leave", "t": t})
	_participation[uid] = events


## Copy of the events of `uid` this battle; [] when none.
func participation(uid: String) -> Array:
	var result: Array = []
	for event in (_participation.get(uid, []) as Array):
		result.append((event as Dictionary).duplicate(true))
	return result


## Uids with at least one "enter" this battle, in first-enter order.
func participants() -> Array[String]:
	var result: Array[String] = []
	for uid in _enter_order:
		result.append(uid)
	return result


func _alloc_uid(c: Combatant) -> String:
	var uid := "c%d" % _next_id
	_next_id += 1
	c.uid = uid
	_members[uid] = c
	return uid


## Moves a uid that left ACTIVE to SUBSTITUTE when there is room, otherwise to STATIONED.
func _demote(uid: String) -> void:
	var substitutes: Array = _order[Place.SUBSTITUTE]
	if substitutes.size() < MAX_SUBSTITUTES:
		substitutes.append(uid)
		_station_info.erase(uid)
		return
	(_order[Place.STATIONED] as Array).append(uid)
	_station_info[uid] = {}


static func _place_name(place: int) -> String:
	match place:
		Place.ACTIVE:
			return "ACTIVE"
		Place.SUBSTITUTE:
			return "SUBSTITUTE"
		Place.STATIONED:
			return "STATIONED"
	return "UNKNOWN"
