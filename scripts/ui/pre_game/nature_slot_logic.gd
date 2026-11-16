class_name NatureSlotLogic
extends RefCounted
## Pure, non-visual logic of the Nature slot machine (D-1215, D-1216, D-1217).
## Ported 1:1 from `prototypes/nature_slot/nature_slot.html`
## (TIMING, `symbolsFor`, the `SYMBOLS` build + sort, `endPosition`,
## `positionAt` and `teaseAt`). Nothing here draws, plays sound or touches the
## scene tree: the visual layer only calls these static functions.
##
## Natures are read at runtime from `NatureData.NATURES` and
## `PreGameCatalog.NATURE_ORDER` / `PURE_NATURES` / `STAT_ORDER`, so the same
## code works with 8 or 18 Natures (D-1216) without any list in this file.

## Milliseconds for each reel to settle (prototype TIMING.stop).
const TIMING_STOP_MS: Array[float] = [1800.0, 2600.0, 4300.0]
## Milliseconds of constant speed at the start of each reel (prototype TIMING.flat).
const TIMING_FLAT_MS: Array[float] = [700.0, 900.0, 1100.0]
## Prototype TIMING.reveal / TIMING.settle / TIMING.exit.
const TIMING_REVEAL_MS := 300.0
const TIMING_SETTLE_MS := 700.0
const TIMING_EXIT_MS := 700.0

const NONE_SYMBOL := "NONE"
## Minimum reel travel per reel (prototype `24 + i * 5`).
const MIN_TRAVEL_BASE := 24.0
const MIN_TRAVEL_STEP := 5.0

## Near miss on the last reel only: split of the ease and the "almost" offset,
## both literal from the prototype.
const TEASE_SPLIT_RATIO := 0.72
const TEASE_NEAR_OFFSET := 0.88
const TEASE_HOLD_RATIO := 0.45
const TEASE_HOLD_AMOUNT := 0.08


## The three symbols a Nature shows on the reels: pure Natures show NONE x3,
## any other Nature shows its non-zero mods sorted by value DESC (ties by
## STAT_ORDER index), first 3, formatted `"STR +2"` / `"AGI -3"`.
static func symbols_for(nature_id: String) -> Array[String]:
	var out: Array[String] = []
	var key := nature_id.to_lower()
	if PreGameCatalog.PURE_NATURES.has(key):
		for _i in 3:
			out.append(NONE_SYMBOL)
		return out

	var mods: Dictionary = NatureData.get_nature(key).get("mods", {})
	var entries: Array[Dictionary] = []
	var stat_order: Array[String] = PreGameCatalog.STAT_ORDER
	for i in stat_order.size():
		var stat := stat_order[i]
		var value := int(mods.get(stat, 0))
		if value == 0:
			continue
		entries.append({"stat": stat, "value": value, "order": i})
	entries.sort_custom(_mod_entries_desc)

	for i in mini(entries.size(), 3):
		var entry: Dictionary = entries[i]
		var value := int(entry["value"])
		var sign_text := "+" if value > 0 else "-"
		out.append("%s %s%d" % [str(entry["stat"]), sign_text, absi(value)])
	return out

## Every symbol any Nature can show, unique, sorted by STAT_ORDER index then by
## the signed value DESC (prototype `parseInt(right[1]) - parseInt(left[1])`),
## with NONE appended last. This is the one shared reel strip.
static func all_symbols() -> Array[String]:
	var seen: Dictionary = {}
	var symbols: Array[String] = []
	for nature_id in _nature_ids():
		for symbol in symbols_for(nature_id):
			if symbol == NONE_SYMBOL or seen.has(symbol):
				continue
			seen[symbol] = true
			symbols.append(symbol)
	symbols.sort_custom(_symbols_desc)
	symbols.append(NONE_SYMBOL)
	return symbols


## "none" for NONE, "pos" when the symbol carries a plus sign, "neg" otherwise.
static func symbol_kind(symbol: String) -> String:
	if symbol == NONE_SYMBOL:
		return "none"
	return "pos" if symbol.contains("+") else "neg"


## Index of the symbol in `all_symbols()`, or -1 when it is not on the strip.
static func symbol_index(symbol: String) -> int:
	return all_symbols().find(symbol)


## Landing position: congruent to `target_index - 1` mod size and never behind
## `start + min_travel` (prototype `endPosition`).
static func end_position(start: float, target_index: int, min_travel: float) -> float:
	var size := all_symbols().size()
	var wanted := posmod(target_index - 1, size)
	var base := ceili(start + min_travel)
	var current := posmod(base, size)
	return float(base + posmod(wanted - current, size))

## Reel offset in symbol units at `elapsed_ms`: constant phase then ease-out
## cubic, or the last-reel near miss when `tease` is true (prototype
## `positionAt` / `teaseAt`).
static func position_at(start_pos: float, end_pos: float, dur_ms: float, flat_ms: float, tease: bool, elapsed_ms: float) -> float:
	if tease:
		return _tease_at(start_pos, end_pos, dur_ms, flat_ms, elapsed_ms)
	var travel := end_pos - start_pos
	if elapsed_ms <= 0.0:
		return start_pos
	if elapsed_ms >= dur_ms:
		return end_pos
	var flat_travel := (3.0 * flat_ms * travel) / (dur_ms + 2.0 * flat_ms)
	if elapsed_ms < flat_ms:
		return start_pos + (flat_travel / flat_ms) * elapsed_ms
	var u := (elapsed_ms - flat_ms) / (dur_ms - flat_ms)
	var eased := 1.0 - pow(1.0 - u, 3.0)
	return start_pos + flat_travel + (travel - flat_travel) * eased

## One entry per reel: the symbol to land on, its strip index, where the reel
## starts, where it ends from `end_position` (min travel `24 + i * 5`), the
## timings and whether that reel teases (only reel 2). The result is already
## locked here, before any animation happens (D-1208).
static func reel_plan(nature_id: String, start_positions: Array[float]) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var symbols := symbols_for(nature_id)
	for i in 3:
		var symbol: String = symbols[i] if i < symbols.size() else NONE_SYMBOL
		var target_index := symbol_index(symbol)
		if target_index < 0:
			target_index = 0
		var start_pos: float = start_positions[i] if i < start_positions.size() else 0.0
		plan.append({
			"symbol": symbol,
			"target_index": target_index,
			"start_pos": start_pos,
			"end_pos": end_position(start_pos, target_index, MIN_TRAVEL_BASE + i * MIN_TRAVEL_STEP),
			"dur_ms": TIMING_STOP_MS[i],
			"flat_ms": TIMING_FLAT_MS[i],
			"tease": i == 2,
		})
	return plan

## Symbol under the payline for each reel at the given offsets.
## Prototype math: the strip holds 3 copies of all_symbols(), it is shifted by
## `-wrapped * cell_h` where `wrapped = pos % size` (made positive), and
## `render()` / `markWin()` / `shownSymbols()` read `cells[round(wrapped) + 1]`;
## `cells[k]` is `all_symbols()[k % size]`, so the symbol is
## `all_symbols()[(round(wrapped) + 1) % size]` (round(wrapped) may equal size,
## which wraps to index 1 - the formula below reproduces that).
static func shown_symbols_at(positions: Array[float]) -> Array[String]:
	var symbols := all_symbols()
	var size := symbols.size()
	var out: Array[String] = []
	for position in positions:
		var wrapped := fposmod(position, float(size))
		out.append(symbols[posmod(roundi(wrapped) + 1, size)])
	return out


## The locked result: what the three reels must show.
static func final_symbols(nature_id: String) -> Array[String]:
	return symbols_for(nature_id)

static func _tease_at(start_pos: float, end_pos: float, dur_ms: float, flat_ms: float, elapsed_ms: float) -> float:
	if elapsed_ms <= 0.0:
		return start_pos
	if elapsed_ms >= dur_ms:
		return end_pos
	var split := dur_ms * TEASE_SPLIT_RATIO
	var near := end_pos - TEASE_NEAR_OFFSET
	if elapsed_ms < split:
		return position_at(start_pos, near, split, flat_ms, false, elapsed_ms)
	var u := (elapsed_ms - split) / (dur_ms - split)
	var eased := (
		TEASE_HOLD_AMOUNT * (u / TEASE_HOLD_RATIO)
		if u < TEASE_HOLD_RATIO
		else TEASE_HOLD_AMOUNT + (1.0 - TEASE_HOLD_AMOUNT) * pow((u - TEASE_HOLD_RATIO) / (1.0 - TEASE_HOLD_RATIO), 3.0)
	)
	return near + (end_pos - near) * eased


static func _mod_entries_desc(a: Dictionary, b: Dictionary) -> bool:
	if int(a["value"]) != int(b["value"]):
		return int(a["value"]) > int(b["value"])
	return int(a["order"]) < int(b["order"])


static func _symbols_desc(a: String, b: String) -> bool:
	var left := a.split(" ")
	var right := b.split(" ")
	var stat_order: Array[String] = PreGameCatalog.STAT_ORDER
	var by_stat := stat_order.find(left[0]) - stat_order.find(right[0])
	if by_stat != 0:
		return by_stat < 0
	# JS sort((a, b) => right - left) is descending; GDScript's less-than form is left > right.
	return int(left[1]) > int(right[1])


## Nature ids from the canonical order plus any extra entry in NatureData, so
## the strip is complete whichever catalog is filled first.
static func _nature_ids() -> Array[String]:
	var ids: Array[String] = []
	for nature_id in PreGameCatalog.NATURE_ORDER:
		if not ids.has(nature_id):
			ids.append(nature_id)
	for key in NatureData.NATURES.keys():
		var extra_id := str(key)
		if not ids.has(extra_id):
			ids.append(extra_id)
	return ids