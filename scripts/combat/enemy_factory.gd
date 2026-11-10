class_name EnemyFactory
extends RefCounted
## Fábrica de combatentes inimigos e geração de encontros aleatórios (D-405, D-390, D-392, D-393, D-399).
##
## D-1079: a ficha de cada espécie vive em `content/characters/<id>/species.tres`.
## Esta classe só sorteia o encontro e delega a construção ao CharacterFactory.

const ENEMY_SPECIES_POOL: Array[String] = [
	"dqt_slime",
	"abra",
	"pancham",
	"dqt_cyclops",
	"dqt_orc",
	"gible",
]


## Sorteia o tamanho do grupo de inimigos (D-405):
## Solo: 55% | Dupla: 30% | Trio: 15%
static func roll_party_size(rng: RandomNumberGenerator = null) -> int:
	var r := (rng.randf() if rng != null else randf())
	if r < 0.55:
		return 1
	elif r < 0.85:
		return 2
	else:
		return 3


## Gera um encontro completo de inimigos sorteando tamanho e espécies (D-405).
## Duplicatas de espécies são permitidas.
static func roll_encounter(rng: RandomNumberGenerator = null) -> Array[Combatant]:
	var active_rng := rng
	if active_rng == null:
		active_rng = RandomNumberGenerator.new()
		active_rng.randomize()

	var size := roll_party_size(active_rng)
	var enemies: Array[Combatant] = []
	for i in size:
		var idx := active_rng.randi_range(0, ENEMY_SPECIES_POOL.size() - 1)
		var sp := ENEMY_SPECIES_POOL[idx]
		enemies.append(create_enemy(sp, active_rng))
	return enemies


## Cria a instância canônica de um inimigo (D-390, D-392, D-393).
static func create_enemy(species: String, rng: RandomNumberGenerator = null, forced_nature: String = "") -> Combatant:
	return CharacterFactory.create(species, {
		"is_player": false,
		"rng": rng,
		"forced_nature": forced_nature,
	})
