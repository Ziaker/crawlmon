class_name CharacterFactory
extends RefCounted
## Cria um Combatant a partir de um CharacterData (D-1079/D-1080).
##
## A ficha canônica vem do catálogo. Overrides de teste (HP, ataque, velocidade,
## MP) são passados explicitamente em `opts` e nunca ficam escondidos na ficha.

const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")


static func create(species_id: String, opts: Dictionary = {}) -> Combatant:
	var data := CharacterCatalog.get_character(StringName(species_id))
	if data == null:
		push_warning("CharacterFactory: espécie desconhecida '%s', usando fallback 'gible'" % species_id)
		data = CharacterCatalog.get_character(&"gible")
	if data == null:
		# Último recurso: mantém o jogo carregando mesmo sem catálogo.
		var fallback := Combatant.new(species_id.capitalize(), 39, 9, 0.425, false)
		fallback.species_id = species_id
		return fallback

	# D-1080: a party de teste pode pedir a construção "crua" (sem Nature,
	# atributos de 15 pontos nem recálculo de HP/MP), preservando os cenários
	# antigos. Esses valores não são a ficha do personagem.
	if bool(opts.get("test_bare", false)):
		return _create_bare(data, opts)

	var rng: RandomNumberGenerator = opts.get("rng", null)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var base_stats := CrawlmonAttributeMath.convert_species_stats_to_15_points(data.raw_stats)
	var offsets := CrawlmonAttributeMath.roll_individual_offsets(rng)

	var nat_id := str(opts.get("forced_nature", data.nature_id)).to_lower()
	if nat_id.is_empty():
		var all_natures := NatureData.get_all_nature_ids()
		nat_id = all_natures[rng.randi_range(0, all_natures.size() - 1)]
	var nature_mods: Dictionary = NatureData.get_nature(nat_id)["mods"]
	var innate := CrawlmonAttributeMath.consolidate_innate_attributes(base_stats, offsets, nature_mods)

	var is_player := bool(opts.get("is_player", false))
	var combatant := Combatant.new(data.display_name, data.hp, data.attack, data.speed, is_player)
	combatant.species_id = data.species_id
	combatant.base_experience = data.base_experience
	combatant.nature_id = nat_id
	combatant.individual_offsets = offsets
	combatant.innate_stats = innate
	combatant.sync_effective_stats()
	combatant.update_resource_maximums()
	combatant.hp = combatant.max_hp
	combatant.mp = combatant.max_mp
	combatant.base_attack = combatant.str

	combatant.weaknesses.clear()
	for weakness in data.weaknesses:
		combatant.weaknesses.append(weakness)
	combatant.travel_extra = data.travel_extra
	combatant.act_policy = int(opts.get("act_policy", data.act_policy))
	combatant.react_policy = int(opts.get("react_policy", data.react_policy))

	combatant.skills.clear()
	for move_id in data.skill_ids():
		var skill := Skill.from_id(move_id)
		if skill != null:
			combatant.skills.append(skill)
		else:
			push_warning("CharacterFactory: Move '%s' de '%s' não existe no catálogo" % [move_id, data.id])

	combatant.inventory = data.inventory().duplicate(true)

	# Overrides explícitos (a party de teste usa estes; a ficha não).
	if opts.has("inventory"):
		combatant.inventory = opts["inventory"]
	if opts.has("max_hp"):
		combatant.max_hp = int(opts["max_hp"])
		combatant.hp = combatant.max_hp
	if opts.has("max_mp"):
		combatant.max_mp = int(opts["max_mp"])
		combatant.mp = combatant.max_mp
	if opts.has("attack"):
		combatant.base_attack = int(opts["attack"])
		combatant.mag = combatant.base_attack
	if opts.has("speed"):
		combatant.base_speed = float(opts["speed"])
	if opts.has("level"):
		combatant.level = int(opts["level"])

	return combatant


## Construção mínima usada só por cenários de teste (D-1080). Mantém o
## Combatant sem Nature/atributos de 15 pontos, como os testes antigos.
static func _create_bare(data: CharacterData, opts: Dictionary) -> Combatant:
	var combatant := Combatant.new(
		data.display_name,
		int(opts.get("max_hp", data.hp)),
		int(opts.get("attack", data.attack)),
		float(opts.get("speed", data.speed)),
		bool(opts.get("is_player", false))
	)
	combatant.species_id = data.species_id
	combatant.base_experience = data.base_experience
	combatant.weaknesses.clear()
	for weakness in data.weaknesses:
		combatant.weaknesses.append(weakness)
	combatant.travel_extra = data.travel_extra
	combatant.skills.clear()
	for move_id in data.skill_ids():
		var skill := Skill.from_id(move_id)
		if skill != null:
			combatant.skills.append(skill)
	combatant.inventory = data.inventory().duplicate(true)
	if opts.has("inventory"):
		combatant.inventory = opts["inventory"]
	combatant.max_mp = int(opts.get("max_mp", 0))
	combatant.mp = combatant.max_mp
	return combatant
