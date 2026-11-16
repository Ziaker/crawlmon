class_name EmployRhythm
extends RefCounted
## D-1229/D-1257: pure and deterministic logic of the Employ rhythm minigame.
## The clock is injected: every call receives the time in milliseconds, so nothing here reads
## Time.get_ticks_* or the scene tree. No combat, no HUD, no autoload.

const PERFECT_MS := 60.0
const GOOD_MS := 130.0
const BONUS_PERFECT := 10.0
const BONUS_GOOD := 5.0
const BONUS_MISS := 0.0
const NOTES_MAX := 3

## One entry per note: { "time_ms": float, "grade": "pending" | "perfect" | "good" | "miss" }.
var _notes: Array = []


## D-1229: one note per living participating ally, clamped to 1..3.
static func note_count(members: int) -> int:
	return clampi(members, 1, NOTES_MAX)


## D-1257: grade of an absolute delta in ms. "" when it is outside the GOOD window.
static func grade_for(abs_delta_ms: float) -> String:
	if abs_delta_ms <= PERFECT_MS:
		return "perfect"
	if abs_delta_ms <= GOOD_MS:
		return "good"
	return ""


## Restarts the sequence with one pending note per entry of `note_times_ms`.
func setup(note_times_ms: Array) -> void:
	_notes.clear()
	for note_time in note_times_ms:
		_notes.append({"time_ms": float(note_time), "grade": "pending"})

## D-1257: a single key hits any note. Hits the pending note whose |t - note_time| is the
## smallest and within GOOD_MS (ties keep the earliest note). Returns
## {"note": i, "grade": "perfect"|"good", "delta_ms": t - note_time}, or {} when no note is in
## the window (a press outside every window is ignored).
func press(t_ms: float) -> Dictionary:
	var best := -1
	var best_delta := 0.0
	for i in range(_notes.size()):
		if _notes[i]["grade"] != "pending":
			continue
		var delta: float = t_ms - float(_notes[i]["time_ms"])
		var distance := absf(delta)
		if distance > GOOD_MS:
			continue
		if best == -1 or distance < absf(best_delta):
			best = i
			best_delta = delta
	if best == -1:
		return {}
	var grade := grade_for(absf(best_delta))
	_notes[best]["grade"] = grade
	return {"note": best, "grade": grade, "delta_ms": best_delta}


## D-1257: marks "miss" every pending note whose GOOD window has fully passed
## (t_ms > note_time + GOOD_MS). Returns the indices marked on this call.
func update(t_ms: float) -> Array:
	var missed: Array = []
	for i in range(_notes.size()):
		if _notes[i]["grade"] != "pending":
			continue
		if t_ms > float(_notes[i]["time_ms"]) + GOOD_MS:
			_notes[i]["grade"] = "miss"
			missed.append(i)
	return missed

## "pending" for a note not yet resolved, otherwise the stored grade.
func grades() -> Array:
	var out: Array = []
	for note in _notes:
		out.append(note["grade"])
	return out


## D-1229: bonus in percentage points per note, in note order: 10 perfect, 5 good, 0 miss/pending.
func bonuses() -> Array:
	var out: Array = []
	for note in _notes:
		out.append(_bonus_for(note["grade"]))
	return out


## B of D-1230: plain sum of the per-note bonuses.
func total_bonus() -> float:
	var total := 0.0
	for bonus in bonuses():
		total += float(bonus)
	return total


## True when no note is pending any more (every note was hit or missed).
func is_finished() -> bool:
	for note in _notes:
		if note["grade"] == "pending":
			return false
	return true


## Telemetry snapshot: {"grades": [...], "bonuses": [...], "total_pp": x}.
func summary() -> Dictionary:
	return {"grades": grades(), "bonuses": bonuses(), "total_pp": total_bonus()}


static func _bonus_for(grade: String) -> float:
	match grade:
		"perfect":
			return BONUS_PERFECT
		"good":
			return BONUS_GOOD
		_:
			return BONUS_MISS