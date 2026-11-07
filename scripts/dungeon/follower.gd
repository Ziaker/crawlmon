class_name DungeonFollower
extends Node2D
## Aliado que segue o protagonista em fila pelo rastro exato (D-309/D-314).
##
## O rastro é uma polyline dos pontos por onde o líder passou, amostrada a cada
## 4 px. O seguidor anda por esses pontos (nunca corta o canto de uma parede) e
## mantém 32 px de distância de trilha (D-361; antes 48). Se ficar preso por 1 s,
## ele é reposicionado no ponto livre atrás do líder.

const SPEED := 200.0
const TRAIL_STEP := 4.0
const TRAIL_GAP := 32.0  ## 2/3 tile at 48 px (D-361; was 48).
const TRAIL_MAX := 512
const STUCK_WAIT := 1.0

var species_id := ""
var leader: Node2D

var _trail := PackedVector2Array()
var _index := 0
var _sprite: Sprite2D
var _last_dir := "down"
var _anim_timer := 0.0
var _anim_frame := 1
var _stuck := 0.0
var _tex_path := ""


func setup(p_species: String, p_leader: Node2D) -> void:
	species_id = p_species
	leader = p_leader


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.2, 1.2)
	add_child(_sprite)
	if leader != null:
		# Começa com a trilha já preenchida entre o spawn e o líder.
		_trail.append(position)
		var dist := position.distance_to(leader.position)
		var steps := maxi(1, int(dist / TRAIL_STEP))
		for i in range(1, steps):
			_trail.append(position.lerp(leader.position, float(i) / steps))
		_trail.append(leader.position)
	_set_texture("down", 1)


func _process(delta: float) -> void:
	if leader == null:
		return
	_record_leader()
	_follow(delta)


func _record_leader() -> void:
	var p := leader.position
	if _trail.is_empty() or _trail[-1].distance_to(p) >= TRAIL_STEP:
		_trail.append(p)
		if _trail.size() > TRAIL_MAX:
			_trail.remove_at(0)
			_index = maxi(0, _index - 1)


## Índice do ponto que está 32 px atrás do líder ao longo da trilha.
func _target_index() -> int:
	if _trail.is_empty():
		return 0
	var dist := 0.0
	for i in range(_trail.size() - 1, 0, -1):
		dist += _trail[i].distance_to(_trail[i - 1])
		if dist >= TRAIL_GAP:
			return i - 1
	return 0


func _follow(delta: float) -> void:
	if _trail.is_empty():
		return
	var target := _target_index()
	if _index > target:
		_index = target
	_index = mini(_index, _trail.size() - 1)
	var point := _trail[_index]
	var to := point - position
	var step := SPEED * delta
	var old := position
	if to.length() <= step:
		position = point
		if _index < target:
			_index += 1
		_stuck = 0.0
	else:
		position += to.normalized() * step
		if position.distance_to(old) < 0.05:
			_stuck += delta
			if _stuck >= STUCK_WAIT:
				position = _trail[target]
				_index = target
				_stuck = 0.0
		else:
			_stuck = 0.0
	_update_animation(position - old, delta)


func _update_animation(movement: Vector2, delta: float) -> void:
	if movement.length_squared() > 0.0001:
		if absf(movement.x) > absf(movement.y):
			_last_dir = "right" if movement.x > 0 else "left"
		else:
			_last_dir = "down" if movement.y > 0 else "up"
		_anim_timer += delta
		if _anim_timer >= 0.2:
			_anim_timer = 0.0
			_anim_frame = 2 if _anim_frame == 1 else 1
	else:
		_anim_timer = 0.0
		_anim_frame = 1
	_set_texture(_last_dir, _anim_frame)


func _set_texture(dir: String, frame: int) -> void:
	var suffix := "frame2/" if frame == 2 else ""
	var path := "res://personagens/overworld/%s/%s%s.png" % [dir, suffix, species_id]
	if path == _tex_path:
		return
	if ResourceLoader.exists(path):
		_sprite.texture = load(path)
		_tex_path = path
