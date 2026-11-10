class_name CharacterLoadout
extends Resource
## Leque base e inventário de um personagem (D-1079).
## É conteúdo do projeto, não save de jogador.

@export var skills: Array[StringName] = []
@export var inventory: Dictionary = {}
## Futuro: nível -> Array[StringName]. Vazio na Etapa 1.
@export var learnset: Dictionary = {}
