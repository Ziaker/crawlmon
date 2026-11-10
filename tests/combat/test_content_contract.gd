extends SceneTree
## Contrato da Etapa 6 (D-1079): um Move novo e um Personagem novo devem entrar
## só como conteúdo (MoveData/CharacterData + catálogo), sem `if` por nome no
## código. O teste usa catálogos em memória e restaura os catálogos reais no fim;
## nenhum `.tres` do projeto é alterado.

const MoveCatalog = preload("res://scripts/data/move_catalog.gd")
const CharacterCatalog = preload("res://scripts/data/character_catalog.gd")
const CharacterFactory = preload("res://scripts/combat/character_factory.gd")
const MoveBehaviorRegistry = preload("res://scripts/combat/moves/move_behavior_registry.gd")
const MoveBehavior = preload("res://scripts/combat/moves/move_behavior.gd")
const MoveVfxRegistry = preload("res://scripts/vfx/combat/move_vfx_registry.gd")
const Skill = preload("res://scripts/data/skill.gd")
const Element = preload("res://scripts/data/element.gd")
const ContractBehavior = preload("res://tests/combat/fixtures/contract_move_behavior.gd")
const ContractVfx = preload("res://tests/combat/fixtures/contract_move_vfx.gd")

var _failures := 0
var _orig_moves: MoveCatalog = null
var _orig_chars: CharacterCatalog = null


func _init() -> void:
	_orig_moves = MoveCatalog.load_default()
	_orig_chars = CharacterCatalog.load_default()

	var move := _new_move()
	var character := _new_character(move)
	_install_catalogs(move, character)
	_test_move_contract(move)
	_test_character_contract(character, move)
	_restore_catalogs()

	if _failures == 0:
		print("[TEST SUCCESS] Etapa 6: um Move novo e um Personagem novo entram só como conteúdo, sem branch por nome.")
		quit(0)
	else:
		push_error("[TEST FAILURE] Etapa 6: %d falhas." % _failures)
		quit(1)


func ok(condition: bool, message: String) -> void:
	if condition:
		print("  OK  ", message)
	else:
		_failures += 1
		push_error("  FAIL " + message)


func _new_move() -> MoveData:
	var move := MoveData.new()
	move.id = &"contrato_novo_move"
	move.display_name = "Contrato Novo Move"
	move.kind = Skill.Kind.PROJECTILE
	move.element = Element.Type.RAIO
	move.power = 1.10
	move.atb_cost = 2
	move.mp_cost = 3
	move.windup = 0.40
	move.vfx_key = &"fire"
	move.behavior_script = ContractBehavior
	move.vfx_script = ContractVfx
	move.tags = [&"contrato"]
	move.effect_line_text = "110% raio | Projétil | 2 ATB"
	move.short_effect_text = "110% raio"
	move.mechanics_text = "Dano de raio de contrato."
	move.visual_text = "Projétil de contrato."
	move.motion_text = "Voa em linha reta."
	move.windup_text = "Preparo curto."
	move.tactical_text = "Teste de conteúdo."
	move.visual_motion_text = "Contrato visual."
	return move


func _new_character(move: MoveData) -> CharacterData:
	var base := CharacterCatalog.get_character(&"gible")
	var data := CharacterData.new()
	data.id = &"contrato_novo_personagem"
	data.display_name = "Contrato"
	data.species_id = "contrato_novo_personagem"
	data.hp = 39
	data.attack = 9
	data.speed = 0.425
	data.nature_id = "modest"
	data.base_experience = 10
	data.raw_stats = base.raw_stats.duplicate(true)
	data.weaknesses = base.weaknesses.duplicate()
	data.loadout = CharacterLoadout.new()
	var skills: Array[StringName] = [move.id, &"tackle"]
	data.loadout.skills = skills
	data.loadout.inventory = {"poção": 1}
	data.model_profile = CharacterModelProfile.new()
	data.model_profile.profile = {"native_height": 1.0, "target_height": 1.0}
	return data


func _install_catalogs(move: MoveData, character: CharacterData) -> void:
	var moves := MoveCatalog.new()
	moves.moves = _orig_moves.moves.duplicate()
	moves.moves.append(move)
	MoveCatalog._cached = moves

	var chars := CharacterCatalog.new()
	chars.characters = _orig_chars.characters.duplicate()
	chars.characters.append(character)
	CharacterCatalog._cached = chars


func _restore_catalogs() -> void:
	MoveCatalog._cached = _orig_moves
	CharacterCatalog._cached = _orig_chars
	# The registry caches by move_id; drop the test-only entry so another test
	# in the same process cannot see the contract Move.
	MoveBehaviorRegistry._cache.erase(&"contrato_novo_move")
	MoveVfxRegistry.clear_move_vfx_cache()


func _test_move_contract(move: MoveData) -> void:
	print("[TEST] Move novo entra pelo catálogo e pelo dispatcher")
	ok(MoveCatalog.get_move(move.id) == move, "catálogo de teste encontra o Move novo")
	ok(MoveCatalog.get_move(move.id).display_name == "Contrato Novo Move", "display_name não é a chave de roteamento")

	var skill := Skill.from_data(move)
	ok(skill != null, "MoveData cria Skill de runtime")
	if skill != null:
		ok(skill.data == move, "Skill guarda a definição")
		ok(skill.display_name == move.display_name, "nome exibido")
		ok(skill.cost == move.atb_cost, "custo ATB")
		ok(skill.mp_cost == move.mp_cost, "custo MP")
		ok(skill.element == move.element, "elemento")
		ok(skill.kind == move.kind, "tipo de trajeto")

	var from_catalog := Skill.from_id(move.id)
	ok(from_catalog != null and from_catalog.data == move, "Skill.from_id usa o catálogo")

	var behavior := MoveBehaviorRegistry.get_behavior(move.id)
	ok(behavior != null, "dispatcher devolve behavior para Move novo")
	ok(behavior is MoveBehavior, "Move novo usa um behavior válido")
	ok(behavior.get_script() == ContractBehavior, "behavior_script do Move novo é respeitado")
	ok(behavior.data == move, "behavior recebe a ficha do Move novo")

	ok(MoveVfxRegistry.family(move.id) == &"generic", "id novo não entra no mapa fixo de famílias")
	ok(MoveVfxRegistry.family(&"contrato_novo_move") == &"generic", "família por move_id é estável")

	var inc := Incoming.new()
	inc.move_id = String(move.id)
	inc.move_data = move
	ok(MoveVfxRegistry.family_for_inc(inc) == &"fire", "vfx_key do Move novo é respeitado no wind-up")
	ok(MoveVfxRegistry.impact_family(move.id) == &"fire", "impacto usa vfx_key quando o id não tem mapa")
	ok(MoveVfxRegistry.travel_family(move.id) == &"fire", "trajeto usa vfx_key quando o id não tem mapa")

	var authored := MoveVfxRegistry.move_vfx_for(null, move.id)
	ok(authored != null, "vfx_script do Move novo é instanciado")
	if authored != null:
		ok(authored.get_script() == ContractVfx, "vfx_script correto é usado")
		ok(authored.data == move, "vfx_script recebe a ficha do Move")
		ok(authored.fx == null, "setup aceita um FX de teste nulo")


func _test_character_contract(character: CharacterData, move: MoveData) -> void:
	print("[TEST] Personagem novo entra pelo catálogo e pela fábrica")
	ok(CharacterCatalog.get_character(character.id) == character, "catálogo de teste encontra o Personagem novo")
	ok(character.has_skill(move.id), "loadout do Personagem novo aceita o Move novo")

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109
	var combatant := CharacterFactory.create(String(character.id), {
		"is_player": true,
		"forced_nature": "modest",
		"rng": rng,
	})
	ok(combatant != null, "CharacterFactory cria o Personagem novo")
	if combatant == null:
		return
	ok(combatant.name == character.display_name, "nome do Personagem novo")
	ok(combatant.species_id == character.species_id, "species_id do Personagem novo")
	ok(combatant.max_hp > 0 and combatant.max_mp > 0, "HP/MP calculados para o Personagem novo")
	ok(combatant.skills.size() == 2, "Personagem novo recebe os 2 Moves do loadout (encontrado %d)" % combatant.skills.size())
	ok(int(combatant.inventory.get("poção", 0)) == 1, "inventário do loadout chega ao Combatant")
	var found := false
	for skill in combatant.skills:
		if skill.data != null and skill.data.id == move.id:
			found = true
			ok(skill.display_name == move.display_name, "Move novo chega à ficha com o nome exibido")
			ok(skill.data == move, "Move novo chega à ficha com a definição do catálogo")
	ok(found, "Personagem novo tem o Move novo na lista de Skills")
	ok(not combatant.skills.any(func(s): return s == null), "nenhum Skill nulo na ficha")
