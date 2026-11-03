class_name BattleSpace
extends RefCounted
## The arena geometry shared by the rules and the drawing. Positions are flat (x, z) world
## units; Combatant.pos is the authority, models only follow it.

const STEP_DIST := 1.5  ## World units per position step (kept short: the party stands near the camera).
const RUN_SPEED := 30.0  ## Units per second while running at a target (slow enough to read as a run, not a teleport).
const STAND_GAP := 2.6  ## Where a melee attacker stops, in front of its target.
const ANTICIP_T := 0.08  ## Brief crouch/pull-back anticipation before melee swing.
const HIT_AT := 0.45  ## Seconds into the attack clip when the strike lands.
const CAST_AT := 0.5  ## Seconds into a cast when the effect leaves the caster.
const FLY_TIME := 0.25  ## Shortest projectile flight.
const FLY_SPEED := 50.0  ## Units per second of a projectile.
const TELEPORT_PINCH := 0.12 / 0.22  ## Share of Teleporte Rapido's flight after which the caster has blinked away.
const DODGE_SIDE := 3.6  ## How far to the side an evader's dodge spot is.
const DODGE_BACK := 1.4


static func ease_quad_out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)


static func ease_expo_out(k: float) -> float:
	return 1.0 if k >= 1.0 else 1.0 - pow(2.0, -10.0 * k)


## Flat copy of `v` (y = 0).
static func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Unit direction on the floor from `from` to `to` (RIGHT when they coincide).
static func flat_dir(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.RIGHT


## Stable routing key for a skill name ("Golpe de Caráte" -> "golpe_carate").
static func move_id(skill_name: String) -> String:
	var move_id := skill_name.strip_edges().to_lower()
	var accented := ["á", "à", "â", "ã", "ä", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ó", "ò", "ô", "õ", "ö", "ú", "ù", "û", "ü", "ç", "ñ"]
	var plain :=    ["a", "a", "a", "a", "a", "e", "e", "e", "e", "i", "i", "i", "i", "o", "o", "o", "o", "o", "u", "u", "u", "u", "c", "n"]
	for i in accented.size():
		move_id = move_id.replace(accented[i], plain[i])
	var out := ""
	var last_was_separator := false
	for ch in move_id:
		var keep := (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")
		if keep:
			out += ch
			last_was_separator = false
		elif not out.is_empty() and not last_was_separator:
			out += "_"
			last_was_separator = true
	move_id = out.trim_suffix("_")
	var aliases := {
		"golpe_de_carate": "golpe_carate",
		"quebra_de_telha": "quebra_telha",
		"onda_de_choque": "onda_choque",
		"tiro_de_areia": "tiro_areia",
		"garra_do_dragao": "garra_dragao",
		"furia_do_dragao": "furia_dragao",
		# Nomes oficiais em inglês (D-032)
		"mach_punch": "soco_rapido",
		"bullet_punch": "soco_rapido",
		"karate_chop": "golpe_carate",
		"brick_break": "quebra_telha",
		"taunt": "provocacao",
		"confusion": "confusao",
		"psybeam": "raio_psiquico",
		"shock_wave": "onda_choque",
		"teleport": "teleporte_rapido",
		"quick_teleport": "teleporte_rapido",
		"bite": "mordida",
		"sand_attack": "tiro_areia",
		"dragon_claw": "garra_dragao",
		"dragon_rage": "furia_dragao",
		"dig": "investida_escavadora",
		"bulldoze": "investida_escavadora",
		"investida_subterranea": "investida_escavadora",
	}
	return aliases.get(move_id, move_id)
