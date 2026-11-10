class_name MoveVfxRegistry
extends RefCounted
## Registro central de VFX por Move (D-1079, Etapa 3). O `move_id`/`vfx_key`
## escolhe a família visual; os módulos continuam desenhando só o que o Battle
## manda (D-019/D-1040) e são independentes de personagem/time/lado (D-235).

static var _move_vfx_cache: Dictionary = {}

const FAMILY_BY_ID := {
	&"confusao": &"abra",
	&"raio_psiquico": &"abra",
	&"onda_choque": &"abra",
	&"teleporte_rapido": &"abra",
	&"electric_beam": &"electric",
	&"tidal_surge": &"tidal",
	&"flame_stream": &"element",
	&"splitter_flames": &"element",
	&"fire_bullet": &"fire",
	&"media": &"media",
	&"quebra_telha": &"brick_break",
	&"tiro_areia": &"sand_attack",
	&"furia_dragao": &"dragon_rage",
	&"provocacao": &"taunt",
	&"drain_spear": &"drain_spear",
	&"armored_bulk": &"armored_bulk",
}


static func family(move_id: StringName) -> StringName:
	return FAMILY_BY_ID.get(move_id, &"generic")


static func family_for_inc(inc: Incoming) -> StringName:
	if inc != null and inc.move_data != null and not inc.move_data.vfx_key.is_empty():
		return inc.move_data.vfx_key
	if inc != null:
		return family(StringName(inc.move_id))
	return &"generic"


## Optional authored VFX for a Move package (D-1079 item 3). Returns a cached
## instance only when the move.tres points to a valid `vfx_script` extending
## MoveVfx; otherwise the existing family modules keep ownership. The script is
## stateless between battles except for its own effect nodes, and it never owns
## a clock (D-019/D-1040).
static func move_vfx_for(fx: BattleFx, move_id: StringName) -> MoveVfx:
	var key := StringName(move_id)
	var move := MoveCatalog.get_move(key)
	if move == null or move.vfx_script == null:
		return null
	if _move_vfx_cache.has(key):
		var cached: MoveVfx = _move_vfx_cache[key]
		cached.fx = fx
		return cached
	if not move.vfx_script.can_instantiate():
		return null
	var custom: Variant = move.vfx_script.new()
	if not (custom is MoveVfx):
		return null
	var authored := custom as MoveVfx
	authored.setup(fx, move)
	_move_vfx_cache[key] = authored
	return authored


static func clear_move_vfx_cache() -> void:
	_move_vfx_cache.clear()


## Impact/travel family for an id without an explicit map entry. Existing ids
## keep the map above; a new MoveData can choose a family through `vfx_key`
## without adding a hardcoded id to this registry.
static func impact_family(move_id: StringName) -> StringName:
	var fam := family(move_id)
	if fam != &"generic":
		return fam
	var move := MoveCatalog.get_move(move_id)
	if move != null and not move.vfx_key.is_empty():
		return move.vfx_key
	return fam


## The projectile phase has one exception: Teleport has its own blink driver,
## not the Abra travel layer.
static func travel_family(move_id: StringName) -> StringName:
	if move_id == &"teleporte_rapido":
		return &"teleport"
	return impact_family(move_id)


## Wind-up authored by the Move. Returns {"handled": bool, "nodes": Array}.
## `handled=false` means the generic ground reticle/charge aura should be used.
static func windup(fx: BattleFx, inc: Incoming, move_id: String, from: Vector3, to: Vector3, duration: float) -> Dictionary:
	var nodes: Array[Node] = []
	match family_for_inc(inc):
		&"abra":
			# D-170: Abra's prototype-v9 wind-up replaces the default reticle/aura.
			nodes.append(AbraMoveVfx.windup(fx, move_id, from, to, duration))
			return {"handled": true, "nodes": nodes}
		&"electric":
			# D-957: the library beam's START + WINDUP; the charge is held until the shot.
			nodes.append(ElectricBeamVfx.begin(fx, move_id, from + Vector3.UP, [to + Vector3.UP], duration))
			return {"handled": true, "nodes": nodes}
		&"tidal":
			# D-1021: the water charge is born in front of the real caster model.
			nodes.append(TidalSurgeVfx.begin(fx, move_id, from + Vector3.UP, [to + Vector3.UP], duration, inc.attacker, [inc.target]))
			return {"handled": true, "nodes": nodes}
		&"element":
			# D-308: the element charge replaces the default reticle/aura.
			nodes.append(ElementMoveVfx.windup(fx, move_id, from, to, duration))
			return {"handled": true, "nodes": nodes}
		&"fire":
			# D-236: the fire hand replaces the default reticle/aura.
			nodes.append(FireMoveVfx.windup(fx, move_id, from, to, duration))
			return {"handled": true, "nodes": nodes}
		&"media":
			# D-337: the party-wide healing ritual anchored on the real allies.
			nodes.append(ElementMoveVfx.ceremony(fx, move_id, from, to, duration, inc.attacker))
			return {"handled": true, "nodes": nodes}
		&"brick_break":
			var barrier := fx.fx_impacts.spawn_brick_barrier(inc.target, to + Vector3(0, 1.15, 0), fx._flat_dir(from, to))
			if barrier != null:
				nodes.append(barrier)
			return {"handled": true, "nodes": nodes}
	return {"handled": false, "nodes": nodes}


## Authored impact routing (Etapa 3). The impact nodes themselves stay in
## FxImpacts/AbraMoveVfx/ElementMoveVfx/FireMoveVfx; only the dispatch is here.
static func impact(fx: BattleFx, move_id: String, pos: Vector3, big: bool, dir: Vector3) -> Dictionary:
	# D-1079: an authored vfx.gd gets the first chance. An empty result falls
	# back to the existing family/match path, so moves without a script are
	# unchanged.
	var authored := move_vfx_for(fx, StringName(move_id))
	if authored != null:
		var authored_nodes: Array[Node3D] = authored.impact(null, pos, big, dir)
		if not authored_nodes.is_empty():
			return {"handled": true, "nodes": authored_nodes}
	var family := impact_family(StringName(move_id))
	var impacts := fx.fx_impacts
	if family == &"abra":
		return {"handled": true, "nodes": impacts._abra_impact(move_id, pos, dir, big)}
	if family == &"element":
		return {"handled": true, "nodes": impacts._element_impact(move_id, pos, dir, big)}
	if family == &"fire":
		return {"handled": true, "nodes": impacts._fire_impact(move_id, pos, dir, big)}
	match move_id:
		"investida", "tackle":
			return {"handled": true, "nodes": impacts._tackle_impact(pos, dir, big)}
		"soco_rapido":
			return {"handled": true, "nodes": impacts._quick_punch_impact(pos, dir, big)}
		"golpe_carate":
			return {"handled": true, "nodes": impacts._karate_impact(pos, dir, big)}
		"quebra_telha":
			return {"handled": true, "nodes": impacts._brick_break_impact(pos, dir, big)}
		"electric_beam":
			# D-957: the beam that ends here draws its own IMPACT and POST.
			var found := ProjectileLibVfx.find_for_impact(move_id, pos)
			if found[0] != null:
				(found[0] as ProjectileLibVfx).hit(int(found[1]), pos, dir)
				if found[0] is ElectricBeamVfx:
					(found[0] as ElectricBeamVfx).set_stun(int(found[1]), bool(fx.last_hit_info.get("stun", false)))
			var empty_electric: Array[Node3D] = []
			return {"handled": true, "nodes": empty_electric}
		"tidal_surge":
			# D-1021/D-1025: the main jet that ends here draws its own IMPACT and POST.
			var wfound := ProjectileLibVfx.find_for_impact(move_id, pos)
			if wfound[0] != null:
				(wfound[0] as ProjectileLibVfx).hit(int(wfound[1]), pos, dir)
			var empty_tidal: Array[Node3D] = []
			return {"handled": true, "nodes": empty_tidal}
		"mordida":
			return {"handled": true, "nodes": impacts._bite_impact(pos, dir)}
		"tiro_areia":
			return {"handled": true, "nodes": impacts._sand_attack_impact(pos, dir)}
		"garra_dragao":
			return {"handled": true, "nodes": impacts._dragon_claw_impact(pos, dir, big)}
		"furia_dragao":
			return {"handled": true, "nodes": impacts._dragon_rage_impact(pos, big)}
		"investida_subterranea", "investida_escavadora":
			return {"handled": true, "nodes": impacts._dig_rush_impact(pos, big)}
		"mabufula":
			return {"handled": true, "nodes": impacts._mabufula_impact(pos, dir, big)}
		"megido":
			return {"handled": true, "nodes": impacts._megido_impact(pos, dir, big)}
		"hassou_tobi":
			return {"handled": true, "nodes": impacts._hassou_tobi_impact(pos, dir, big)}
		"titanomachia":
			return {"handled": true, "nodes": impacts._titanomachia_impact(pos, dir, big)}
	return {"handled": false, "nodes": []}
