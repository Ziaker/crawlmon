extends Node
## D-1018: lab de escala dos modelos 3D. Variantes A/B/C/D no mesmo andar.
##
## A: 1,0x, gap 32, zoom 2,3x (referência)
## B: 1,5x, gap 32, zoom 2,3x
## C: 2,0x, gap 48, zoom 2,3x
## D: 2,0x, gap 48, zoom 2,8x
## C32: 2,0x, gap 32, zoom 2,3x (só para mostrar a sobreposição da fila)
##
## O NPC e o inimigo ficam em 1x de propósito, como referência do mundo atual.
## Nada aqui altera o jogo normal: os multiplicadores são estáticos e voltam a
## 1,0 quando o processo termina.

const EXPLORATION := preload("res://scenes/exploration.tscn")
const FOLLOWER := preload("res://scripts/dungeon/follower.gd")
const FOLLOWER_3D := preload("res://scripts/dungeon/dungeon_follower_3d.gd")
const NPC_CLASS := preload("res://scripts/dungeon/npc.gd")
const VIEW := preload("res://scripts/dungeon/model_3d_view.gd")

const TILE := 48
const SEED := 20261108
const VARIANTS := {
	"a": {"scale": 1.0, "gap": 32.0, "zoom": 2.3, "label": "A — 1,0x (Abra 25 / Pancham 24 / Orc 30) — gap 32 — zoom 2,3x"},
	"b": {"scale": 1.5, "gap": 32.0, "zoom": 2.3, "label": "B — 1,5x (Abra 37,5 / Pancham 36 / Orc 45) — gap 32 — zoom 2,3x"},
	"c": {"scale": 2.0, "gap": 48.0, "zoom": 2.3, "label": "C — 2,0x (Abra 50 / Pancham 48 / Orc 60) — gap 48 — zoom 2,3x"},
	"d": {"scale": 2.0, "gap": 48.0, "zoom": 2.8, "label": "D — 2,0x (Abra 50 / Pancham 48 / Orc 60) — gap 48 — zoom 2,8x"},
	"c32": {"scale": 2.0, "gap": 32.0, "zoom": 2.3, "label": "C32 — 2,0x (50/48/60) — gap 32 (atual) — zoom 2,3x"},
}

var exploration: Node
var orc: Node2D
var variant := "a"
var _scale := 1.0
var _gap := 32.0
var _zoom := 2.3


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="):
			variant = arg.substr(10).to_lower()
	var cfg: Dictionary = VARIANTS.get(variant, VARIANTS["a"])
	_scale = float(cfg.get("scale", 1.0))
	_gap = float(cfg.get("gap", 32.0))
	_zoom = float(cfg.get("zoom", 2.3))

	var weather_script = load("res://scripts/dungeon/weather_controller.gd")
	weather_script.debug_disable = true
	# O lab cria o próprio Orc; a exploração não deve criar outro.
	FOLLOWER_3D.enabled = false
	# D-1018: o gap é uma variável do teste, não do jogo normal.
	FOLLOWER.gap_scale = _gap / float(FOLLOWER.TRAIL_GAP)
	VIEW.height_scale = _scale
	VIEW.current_style = "pixel"

	GameState.biome_seed = SEED
	GameState.new_dungeon(SEED, false)
	# Um salão com espaço para a fila e as referências, para a comparação não
	# ser dominada pelo aperto do quarto de spawn.
	GameState.player_pos = _find_open_spawn()

	exploration = EXPLORATION.instantiate()
	add_child(exploration)

	_set_camera_zoom(_zoom)
	_setup_references()
	_spawn_orc()
	_add_overlay()


func _find_open_spawn() -> Vector2:
	var grid: Array = GameState.dungeon_layout
	if grid.is_empty():
		return Vector2(TILE * 1.5, TILE * 1.5)
	var h := grid.size()
	var w := str(grid[0]).length()
	for y in range(3, h - 3):
		for x in range(4, w - 2):
			var ok := true
			for dy in range(-2, 3):
				for dx in range(-2, 1):
					if str(grid[y + dy])[x + dx] != ".":
						ok = false
						break
				if not ok:
					break
			if ok:
				return Vector2(x + 0.5, y + 0.5) * TILE
	return Vector2(TILE * 1.5, TILE * 1.5)


func _set_camera_zoom(zoom: float) -> void:
	for child in exploration.player.get_children():
		if child is Camera2D:
			(child as Camera2D).zoom = Vector2(zoom, zoom)
			return


## Coloca um NPC fixo (bulbasaur, 1x) à esquerda e um inimigo (1x, congelado)
## em diagonal superior esquerda, longe do caminho do gravador (direita → baixo
## → esquerda → cima). O NPC fixo evita que cada variante use uma espécie e um
## tamanho diferentes.
func _setup_references() -> void:
	var player_pos: Vector2 = exploration.player.position

	for other in exploration.npcs:
		other.queue_free()
	exploration.npcs.clear()
	var npc: Node2D = NPC_CLASS.new()
	npc.setup({"id": "bulbasaur", "name": "Bulbasaur"}, "…", exploration.dialogue_box, exploration.player)
	exploration.entities.add_child(npc)
	exploration.npcs.append(npc)
	npc.position = _free_spot(player_pos + Vector2(-2.0 * TILE, 0), [
		Vector2(2.0 * TILE, 0), Vector2(0, -2.0 * TILE), Vector2(0, 2.0 * TILE),
	])

	var enemy: Node2D = null
	var enemy_nodes: Array = exploration.enemies.values()
	if not enemy_nodes.is_empty():
		enemy = enemy_nodes[0]
	for other in enemy_nodes:
		if other != enemy:
			other.queue_free()
	exploration.enemies.clear()
	if enemy != null:
		# Fora do quadrado do gravador (direita → baixo → esquerda → cima).
		var spot := _free_spot(player_pos + Vector2(-2.0 * TILE, -2.0 * TILE), [
			Vector2(-2.0 * TILE, 2.0 * TILE), Vector2(2.0 * TILE, -2.0 * TILE),
			Vector2(0, -2.0 * TILE),
		])
		enemy.position = spot
		enemy.home = spot
		enemy.can_act = func() -> bool: return false


func _free_spot(preferred: Vector2, fallbacks: Array[Vector2]) -> Vector2:
	var candidates: Array[Vector2] = [preferred]
	candidates.append_array(fallbacks)
	for p in candidates:
		if not exploration._is_wall_at(p):
			return p
	return exploration.player.position


func _spawn_orc() -> void:
	var leader: Node2D = exploration.player
	if not exploration.followers.is_empty():
		leader = exploration.followers[-1]
	orc = FOLLOWER.new()
	orc.setup("dqt_orc", leader)
	orc.position = exploration._follower_spawn(leader.position)
	exploration.entities.add_child(orc)
	if VIEW.has_model("dqt_orc"):
		orc.set_meta("model_3d", "dqt_orc")
		var view = VIEW.new()
		view.setup("dqt_orc", VIEW.pixel_height_for("dqt_orc"))
		orc.add_child(view)


func _add_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	var label := Label.new()
	label.text = "%s\nNPC e inimigo em 1x (referência do mundo atual). Setas para andar." % str(
		VARIANTS.get(variant, VARIANTS["a"]).get("label", ""))
	label.position = Vector2(20, 14)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	add_child(layer)
