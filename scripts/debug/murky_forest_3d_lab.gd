extends "res://scripts/debug/third_person_3d_lab.gd"
## Lab 3D da Murky Forest (D-1027/D-1028).
##
## Herda o lab de terceira pessoa (câmera, aliados, Slime, navmesh, porta) e
## troca o cenário de pedra por uma reconstrução low-poly 3D do bioma
## `murky_forest` do PMD, com toon em tudo no overworld e um mini-mapa
## top-down renderizado num SubViewport.
##
## Escala do teste (D-1028): 1 unidade = 1 m; célula 3 m; corredor 6 m;
## parede 4,2 m; copa 5,5 m. Não é a escala final do jogo.

const FOREST_VIGNETTE := preload("res://shaders/vignette.gdshader")
const NPC_DATA := preload("res://scripts/dungeon/npc_data.gd")
const NPC_PROMPT := preload("res://scripts/debug/overworld_prompt.gd")
const NPC_HUD := preload("res://scripts/debug/dialogue_hud_styles.gd")
const ALLY_DIALOGUE := preload("res://scripts/dungeon/ally_dialogue.gd")
const ALLY_BANNER := preload("res://scripts/debug/ally_banner.gd")
const NAMEPLATE := preload("res://scripts/debug/floating_nameplate.gd")
const STATE_ICON := preload("res://scripts/debug/overworld_state_icon.gd")
const MARKER_RING_SHADER := preload("res://shaders/overworld_marker_ring.gdshader")
const WALL_SHADER := preload("res://shaders/wall_palisade_blend.gdshader")
const ITEM_PICKUP := preload("res://scripts/debug/overworld_item_pickup.gd")
const ITEM_NOTIFICATION := preload("res://scripts/debug/item_pickup_notification.gd")
const ITEM_ORB := preload("res://scripts/debug/item_pickup_orb.gd")
## D-1100: contextual overworld attack and its VFX (Agentes A/B).
const ATTACK_CONTROLLER := preload("res://scripts/overworld/overworld_attack_controller.gd")
const ATTACK_HUD := preload("res://scripts/ui/attack_hud.gd")
const DASH_VFX := preload("res://scripts/overworld/vfx/overworld_dash_vfx.gd")
const ICON_ANGER := preload("res://assets/ui/overworld_icons/state_anger.png")
const ICON_SWEAT := preload("res://assets/ui/overworld_icons/state_sweat.png")
const ICON_ALERT := preload("res://assets/ui/overworld_icons/state_alert.png")
const ICON_QUESTION := preload("res://assets/ui/overworld_icons/state_question.png")
const ICON_TALKED := preload("res://assets/ui/overworld_icons/state_talked.png")
const FOLLOWER_NAMES := {"pancham": "PANCHAM", "dqt_orc": "ORC"}
const FOREST_WALL_HEIGHT := 4.2
const MINIMAP_SIZE := 256
const MINIMAP_DISPLAY_SIZE := 112
const MINIMAP_WORLD_SIZE := 20.0
const NPC_LOOK_RADIUS := 3.8
const NPC_INTERACT_RADIUS := 2.4
const NPC_COLLISION_LAYER := 1 << 4  ## 16: o jogador colide; o raio da câmera (mask 1) ignora.

## D-1106: segundo inimigo do lab (não-Medroso), para a transição vermelha.
const SECOND_ENEMY_ID := "gible"
const SECOND_ENEMY_NAME := "GIBLE"
const SECOND_ENEMY_HEIGHT := 1.0
## D-1133: o Gible agora patrulha o novo cômodo a leste, fora das paredes.
const SECOND_ENEMY_SPAWN := Vector3(11.0, 0.0, 0.0)
const SECOND_ENEMY_SPEED := 2.2
const SECOND_ENEMY_PATROL_SPEED := 1.2
const SECOND_ENEMY_CHASE_RADIUS := 5.0
const SECOND_ENEMY_STOP_RADIUS := 1.4
const SECOND_ENEMY_PATROL := [
	Vector3(6.0, 0.0, 4.0),
	Vector3(16.0, 0.0, 4.0),
	Vector3(16.0, 0.0, -4.0),
	Vector3(6.0, 0.0, -4.0),
]
## D-1143: sala do Cyclops (oeste) e sala do Orc (leste), na ala sul.
const ROOM_ENEMY_DATA := [
	{
		"id": "dqt_cyclops", "name": "CYCLOPS", "height": 2.2,
		"spawn": Vector3(-0.5, 0.0, -18.0),
		"patrol": [Vector3(-2.0, 0.0, -16.0), Vector3(-2.0, 0.0, -20.0),
			Vector3(2.0, 0.0, -20.0), Vector3(2.0, 0.0, -16.0)],
	},
	{
		"id": "dqt_orc", "name": "ORC", "height": 2.1,
		"spawn": Vector3(14.0, 0.0, -18.0),
		"patrol": [Vector3(12.0, 0.0, -16.0), Vector3(16.0, 0.0, -16.0),
			Vector3(16.0, 0.0, -20.0), Vector3(12.0, 0.0, -20.0)],
	},
]
## Itens da ala sul: amuleto na sala do Cyclops, poção na sala do meio.
const ROOM_ITEMS := [
	{"id": "amulet", "pos": Vector3(2.4, 0.8, -16.2)},
	{"id": "super_potion", "pos": Vector3(7.0, 0.8, -18.0)},
]
## D-1112: attack clip speed during the short advance.
const ATTACK_ANIM_SPEED := 2.0
## D-1045/D-1050: generic hit reaction shared by every actor (D-235).
const HIT_PUSH_DISTANCE := 1.8
const HIT_PUSH_LIFT := 0.22
const HIT_REACTION_TIME := 0.5
const HIT_REACTION_ANIM_MIN := 0.75

## D-1063: o NPC é sólido para o jogador, mas não puxa a câmera (D-1023).

## Pool de 10 NPCs 3D (D-1063): 5 Pokémon Stage-1 + 5 monstros básicos do DQT.
const NPC_POOL: Array[Dictionary] = [
	{"id": "bulbasaur", "name": "BULBASAUR", "height": 0.78, "has_quest": true},
	{"id": "charmander", "name": "CHARMANDER", "height": 0.85},
	{"id": "squirtle", "name": "SQUIRTLE", "height": 0.80},
	{"id": "pikachu", "name": "PIKACHU", "height": 0.72},
	{"id": "eevee", "name": "EEVEE", "height": 0.70},
	{"id": "dqt_dracky", "name": "DRACKY", "height": 0.95},
	{"id": "dqt_healslime", "name": "HEAL SLIME", "height": 1.15},
	{"id": "dqt_sabrecub", "name": "SABRECUB", "height": 0.85},
	{"id": "dqt_platypunk", "name": "PLATYPUNK", "height": 0.95},
	{"id": "dqt_fungi", "name": "FUNGHOUL", "height": 0.95},
]

## 3 posições laterais no corredor em L (não obstruem o caminho nem a patrulha).
const NPC_SLOTS: Array[Dictionary] = [
	{"pos": Vector3(-2.6, 0.0, -4.2), "yaw": PI * 0.35},
	{"pos": Vector3(2.5, 0.0, -9.8), "yaw": -PI * 0.35},
	{"pos": Vector3(8.2, 0.0, -7.2), "yaw": 0.0},
]

## D-1096: estilo das placas de nome na linguagem dos cards/HUDs.
## F6 alterna no lab para comparação.
@export_enum("unit_card", "move_strip", "expedition") var name_style := "unit_card"

var _rng := RandomNumberGenerator.new()
var _foliage_fade: Array[Dictionary] = []
var _marker_rings: Array[Dictionary] = []
var _state_icons: Array[Dictionary] = []
var _name_labels: Array[Dictionary] = []
var _npc_prompt: Control
var _npc_hud: Control
var _attack_hud: Control
var _slowmo_token := 0
var _hit_shake_left := 0.0
var _hit_shake_time := 0.25
var _hit_shake_amp := 0.06
var _damage_locks: Dictionary = {}
## D-235: actor instance id -> seconds left of the hit push. Gates every lab
## movement/animation owner so the real position tween is not fought.
var _hit_move_locks: Dictionary = {}
var _dialogue_banners: Array[Control] = []
var _battle_hud: Node
var _dialogue_stage := 0
var _dialogue_reactions: Array[Dictionary] = []
var _enemy_marker_root: Node3D
var _enemy_icon_entry: Dictionary = {}
var _enemy_ring_entry: Dictionary = {}
## D-1093: retratos usam o ícone estabelecido (face crop/portrait), não a arte
## inteira. O Bulbasaur usa a opção B final, com 0,03 para a esquerda.
var PORTRAIT_FACE_REGIONS := {
	"abra": Rect2(300.0 / 851.0, 120.0 / 851.0, 320.0 / 851.0, 360.0 / 851.0),
	"pancham": Rect2(300.0 / 1261.0, 40.0 / 1261.0, 680.0 / 1261.0, 760.0 / 1261.0),
	"gible": Rect2(30.0 / 762.0, 100.0 / 762.0, 490.0 / 762.0, 560.0 / 762.0),
	"bulbasaur": Rect2(0.03, 0.04, 0.78, 0.78),
}
var _minimap_viewport: SubViewport
var _minimap_camera: Camera3D
var _minimap_rect: TextureRect
var _marker_root: Control
var _minimap_markers: Array[Dictionary] = []
var _hud_badges: Array[Dictionary] = []
var _enemy_alert: PanelContainer
var _npcs: Array[Dictionary] = []
var _npc_offset := 0
var _npc_talking := false
var _npc_talk_target: Dictionary = {}
var _npc_dialogue_panel: PanelContainer
var _npc_dialogue_title: Label
var _npc_dialogue_text: Label
var _interact_prev := false
var _z_prev := false
var _attack_controller: Node
var _attack_vfx_root: Node3D
var _player_attack_anim_active := false
var _second_enemy: Node3D
var _second_enemy_body: CharacterBody3D
var _second_enemy_ap: AnimationPlayer
var _second_enemy_state := EnemyState.PATROL
var _second_enemy_patrol_index := 0
var _second_enemy_dust: CPUParticles3D
## D-1143: Cyclops e Orc, cada um com corpo/AP/dust/patrulha próprios.
var _room_enemies: Array[Dictionary] = []
var _item_notification: Control
var _ally_notification: Control
var _pickup_orb
var _pending_card: Control


func _ready() -> void:
	# D-1086: o Slime deste lab é o protótipo Medroso (D-310/D-315).
	enable_threat_demo = true
	super()
	# D-1063: os NPCs são sólidos para o jogador (layer 16), mas o raio da
	# câmera usa a máscara 1 e continua ignorando os NPCs (D-1023).
	player.collision_mask |= NPC_COLLISION_LAYER
	# D-1157: jogador e aliados são coletores; o pickup escolhe o mais próximo.
	player.add_to_group("item_collector")
	for f in _followers:
		(f["node"] as Node).add_to_group("item_collector")
	_restore_battle_return()
	_rng.seed = 20261109
	_build_npcs()
	_build_second_enemy()
	_build_room_enemies()
	_build_room_items()
	_build_attack_controller()
	_apply_toon(self)
	_set_actor_layers()
	_add_world_markers()
	if _camera != null:
		# A camada 5 é só do mapa do mini-mapa; a câmera principal não a vê.
		_camera.cull_mask = 0xFFFFFFFF & ~(1 << 4)
	_build_minimap()
	if _second_enemy != null:
		_add_minimap_marker(_second_enemy, Color(1.0, 0.22, 0.18, 1.0), "enemy")
	for entry in _room_enemies:
		var body: Node3D = entry.get("node")
		if body != null and is_instance_valid(body):
			_add_minimap_marker(body, Color(1.0, 0.22, 0.18, 1.0), "enemy")
	_build_hud_badges()
	_build_npc_dialogue_ui()


## D-1100: when the battle came from this lab, A's GameState keeps the exact
## return spot/direction until the new scene is ready. Restore it before the
## first physics frame.
func _restore_battle_return() -> void:
	if GameState.return_scene == "" or GameState.return_scene != scene_file_path:
		return
	player.global_position = GameState.return_pos_3d
	player_yaw = GameState.return_yaw
	player.rotation.y = player_yaw
	_cam_yaw = player_yaw
	player.velocity = Vector3.ZERO


## Debug/test tool (E selector): the lab is isolated from GameState.party, so it
## exposes its real controlled body plus its real `_followers` (Pancham and the
## DQT Orc). Index 0 is the controlled body; index i maps to `_followers[i - 1]`.
func debug_party_selector_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	entries.append({
		"name": _model_display_name(player_model_id),
		"species": player_model_id,
		"leader": true,
	})
	for f in _followers:
		var id := str(f.get("model_id", ""))
		entries.append({
			"name": _model_display_name(id),
			"species": id,
			"leader": false,
		})
	return entries


func _model_display_name(model_id: String) -> String:
	if FOLLOWER_NAMES.has(model_id):
		return str(FOLLOWER_NAMES[model_id])
	return model_id.to_upper()


## Debug/test tool (E selector): E still belongs to NPC dialogue, the exit door
## and the contextual enemy attack. Only open the selector when none of them is
## relevant for the current frame.
func debug_party_selector_blocked() -> bool:
	if _npc_talking or _dialogue_focus != null:
		return true
	if _npc_dialogue_panel != null and _npc_dialogue_panel.visible:
		return true
	if _door_near:
		return true
	if _attack_controller != null:
		if _attack_controller.has_attack_target() or _attack_controller.is_player_attacking():
			return true
	if player != null:
		for npc in _npcs:
			var body: Node3D = npc.get("node")
			if body == null or not is_instance_valid(body):
				continue
			var to := body.global_position - player.global_position
			to.y = 0.0
			if to.length() < NPC_INTERACT_RADIUS:
				return true
	return false


## Debug/test tool (E selector): trades the controlled body's model/AP/height/
## model_id and its world position with `_followers[i - 1]`. The player body stays
## the controlled one; only what it looks like and where it stands change.
## Works for any follower model (Pancham, Orc/DQT, ...), with no team/side rule.
func debug_swap_party(i: int) -> Dictionary:
	if i <= 0:
		return {"ok": false, "message": "Esse já é o líder."}
	if player == null or player_model == null or player_ap == null:
		return {"ok": false, "message": "O lab ainda não tem jogador."}
	var follower_index := i - 1
	if follower_index < 0 or follower_index >= _followers.size():
		return {"ok": false, "message": "O lab não tem esse follower."}
	var f: Dictionary = _followers[follower_index]
	var body: CharacterBody3D = f.get("node")
	var new_model: Node3D = f.get("model")
	var new_ap: AnimationPlayer = f.get("ap")
	if body == null or not is_instance_valid(body) or new_model == null or new_ap == null:
		return {"ok": false, "message": "O follower está inválido."}
	if bool(f.get("busy", false)):
		return {"ok": false, "message": "Aguarde o aliado terminar a coleta."}
	if _is_hit_reacting(player) or (_attack_controller != null and _attack_controller.is_player_attacking()):
		return {"ok": false, "message": "Aguarde o ataque atual terminar."}
	if _is_hit_reacting(body) or (_attack_controller != null and _attack_controller.is_enemy_attacking(body)):
		return {"ok": false, "message": "Aguarde a reação do aliado terminar."}

	var player_pos := player.global_position
	var follower_pos := body.global_position
	var old_model := player_model
	var old_ap := player_ap
	var old_height := player_height
	var old_id := player_model_id
	var new_height := float(f.get("height", HEIGHTS.get(str(f.get("model_id", "")), 1.0)))
	var new_id := str(f.get("model_id", ""))

	old_model.reparent(body, false)
	new_model.reparent(player, false)
	player_model = new_model
	player_ap = new_ap
	player_height = new_height
	player_model_id = new_id
	f["model"] = old_model
	f["ap"] = old_ap
	f["height"] = old_height
	f["model_id"] = old_id

	player.global_position = follower_pos
	body.global_position = player_pos
	player.velocity = Vector3.ZERO
	body.velocity = Vector3.ZERO
	_apply_actor_capsule(player, new_height)
	_apply_actor_capsule(body, old_height)
	_apply_follower_agent(f, old_height)
	if _attack_controller != null:
		var attack_len := 0.0
		if player_ap.has_animation("attack"):
			attack_len = player_ap.get_animation("attack").length
		_attack_controller.set_player_attack_length(attack_len)
	_player_attack_anim_active = false
	_play(player_ap, "idle")
	_play(old_ap, "idle")

	var message := "%s agora controla; %s ficou no lugar." % [new_id.to_upper(), old_id.to_upper()]
	print("[DebugPartySwap] ", message)
	return {"ok": true, "message": message}


## Keeps the body capsule coherent with the model that now lives in it.
func _apply_actor_capsule(body: CharacterBody3D, height: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	for child in body.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null:
			continue
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule == null:
			continue
		var radius := clampf(height * 0.28, 0.2, 0.45)
		capsule.radius = radius
		capsule.height = maxf(height, radius * 2.0 + 0.05)
		shape_node.position.y = capsule.height * 0.5
		return


func _apply_follower_agent(f: Dictionary, height: float) -> void:
	var agent: NavigationAgent3D = f.get("agent")
	if agent == null:
		return
	var radius := clampf(height * 0.28, 0.2, 0.45)
	agent.radius = radius
	agent.height = maxf(height, radius * 2.0 + 0.05)


## D-1106: second, non-Medroso enemy. The Slime keeps D-1086 (flees); this
## Gible enters CHASE and uses the same controller/VFX as any other actor.
func _build_second_enemy() -> void:
	var body := CharacterBody3D.new()
	body.name = "GibleEnemy"
	body.position = SECOND_ENEMY_SPAWN
	body.collision_layer = 8
	body.collision_mask = 1
	body.floor_snap_length = 0.3
	body.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = SECOND_ENEMY_HEIGHT
	shape.shape = capsule
	shape.position.y = SECOND_ENEMY_HEIGHT * 0.5
	body.add_child(shape)
	add_child(body)
	_second_enemy = body
	_second_enemy_body = body
	var model := _make_model(SECOND_ENEMY_ID, SECOND_ENEMY_HEIGHT)
	body.add_child(model)
	_add_blob_shadow(body, 0.80, 0.65)
	_second_enemy_dust = _add_footstep_dust(body)
	_second_enemy_ap = _anim_player(model)
	_play_idle(_second_enemy_ap)
	var tag := _spawn_nameplate(body, SECOND_ENEMY_NAME, "ENEMY", _actor_visual_top(body) + 0.55)
	_name_labels.append({"node": tag, "owner": body})
	_add_ground_ring(body, 0.55, Color(1.0, 0.22, 0.18, 0.85), "enemy")


## D-1143: Cyclops and Orc in the south rooms, with their own patrol.
func _build_room_enemies() -> void:
	for data in ROOM_ENEMY_DATA:
		var height := float(data["height"])
		var body := CharacterBody3D.new()
		body.name = "RoomEnemy_%s" % str(data["id"])
		body.position = data["spawn"]
		body.collision_layer = 8
		body.collision_mask = 1
		body.floor_snap_length = 0.3
		body.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.38
		capsule.height = height
		shape.shape = capsule
		shape.position.y = height * 0.5
		body.add_child(shape)
		add_child(body)
		var model := _make_model(str(data["id"]), height)
		body.add_child(model)
		_add_blob_shadow(body, clampf(height * 0.85, 0.65, 1.2), clampf(height * 0.65, 0.5, 0.95))
		var dust := _add_footstep_dust(body)
		var ap := _anim_player(model)
		_play_idle(ap)
		var tag := _spawn_nameplate(body, str(data["name"]), "ENEMY", _actor_visual_top(body) + 0.55)
		_name_labels.append({"node": tag, "owner": body})
		_add_ground_ring(body, clampf(height * 0.35, 0.5, 0.9), Color(1.0, 0.22, 0.18, 0.85), "enemy")
		_room_enemies.append({
			"node": body, "ap": ap, "dust": dust, "state": EnemyState.PATROL,
			"patrol_index": 0, "patrol": data["patrol"], "speed": 1.2,
		})


## D-1143: two items in the new rooms. Auto-collected on walk-over.
## D-1156: one shared pickup notification for every item.
func _build_room_items() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 22
	layer.add_to_group("overworld_hud")
	add_child(layer)
	_item_notification = ITEM_NOTIFICATION.new()
	layer.add_child(_item_notification)
	_ally_notification = ITEM_NOTIFICATION.new()
	_ally_notification.visible = false
	layer.add_child(_ally_notification)

	var orb_layer := CanvasLayer.new()
	orb_layer.layer = 23
	orb_layer.add_to_group("overworld_hud")
	add_child(orb_layer)
	_pickup_orb = ITEM_ORB.new()
	orb_layer.add_child(_pickup_orb)
	_pickup_orb.arrived.connect(_on_orb_arrived)

	for data in ROOM_ITEMS:
		var pickup := ITEM_PICKUP.new()
		pickup.name = "Item_%s" % str(data["id"])
		pickup.position = data["pos"]
		pickup.setup(str(data["id"]), player)
		pickup.collected.connect(_on_item_collected.bind(pickup))
		add_child(pickup)


func _on_item_collected(item_id: String, collector: Node3D, pickup: Node3D) -> void:
	if _item_notification == null or _ally_notification == null:
		return
	var cam := get_viewport().get_camera_3d()
	if _pickup_orb == null or cam == null or pickup == null or not is_instance_valid(pickup):
		return
	var icon_target: Vector2
	if collector == player:
		icon_target = _item_notification.show_item(item_id)
		_pending_card = _item_notification
	else:
		var height := _ally_height(collector)
		var on_screen := _ally_on_screen(cam, collector, height)
		if on_screen:
			_ally_notification.configure_ally(collector, height)
		else:
			_ally_notification.configure_ally_hud(_ally_hud_slot(collector))
		icon_target = _ally_notification.show_item(item_id)
		_pending_card = _ally_notification
		print("[D-1157] ally card=", "head" if on_screen else "hud",
			" slot=", _ally_hud_slot(collector))
	var ground := Vector3(pickup.global_position.x, 0.02, pickup.global_position.z)
	var start := cam.unproject_position(ground)
	print("[D-1157] collected=", item_id, " by=", collector.name,
		" card=", "ally" if collector != player else "player",
		" start=", start, " target=", icon_target)
	_pickup_orb.fly(start, icon_target)


func _on_orb_arrived() -> void:
	if _pending_card != null:
		_pending_card.call("reveal_from_impact")
		_pending_card = null


func _ally_height(collector: Node3D) -> float:
	for f in _followers:
		if f["node"] == collector:
			return float(f["height"])
	return 1.4


func _ally_on_screen(cam: Camera3D, ally: Node3D, height: float) -> bool:
	if cam == null:
		return false
	var point := ally.global_position + Vector3(0.0, height * 0.5, 0.0)
	if cam.is_position_behind(point):
		return false
	if not cam.is_position_in_frustum(point):
		return false
	var screen := cam.unproject_position(point)
	return get_viewport().get_visible_rect().has_point(screen)


func _ally_hud_slot(collector: Node3D) -> Vector2:
	var y := 190.0
	for f in _followers:
		if f["node"] == collector:
			match str(f.get("model_id", "")):
				"pancham":
					y = 190.0
				"dqt_orc":
					y = 292.0
				"gible":
					y = 394.0
	return Vector2(20.0, y + 20.0)


## D-1100: one controller and one VFX component per actor. B's OverworldDashVfx
## is stateful per advance, so the player and the enemy must not share one.
func _build_attack_controller() -> void:
	_attack_vfx_root = Node3D.new()
	_attack_vfx_root.name = "OverworldAttackVfx"
	add_child(_attack_vfx_root)
	var player_vfx = DASH_VFX.new()
	player_vfx.name = "PlayerDashVfx"
	_attack_vfx_root.add_child(player_vfx)
	var enemy_vfx = DASH_VFX.new()
	enemy_vfx.name = "EnemyDashVfx"
	_attack_vfx_root.add_child(enemy_vfx)
	var second_vfx = DASH_VFX.new()
	second_vfx.name = "SecondEnemyDashVfx"
	_attack_vfx_root.add_child(second_vfx)

	_attack_controller = ATTACK_CONTROLLER.new()
	_attack_controller.name = "OverworldAttackController"
	add_child(_attack_controller)
	_attack_controller.setup(player, _camera, _attack_vfx_root)
	if player_ap != null and player_ap.has_animation("attack"):
		_attack_controller.set_player_attack_length(player_ap.get_animation("attack").length)
	_attack_controller.bind_dash_vfx(player, player_vfx, _player_dust)
	if _enemy != null:
		_attack_controller.bind_dash_vfx(_enemy, enemy_vfx, _enemy_dust)
		_attack_controller.register_enemy(_enemy)
		if _enemy_ap != null and _enemy_ap.has_animation("attack"):
			_attack_controller.set_enemy_attack_length(_enemy, _enemy_ap.get_animation("attack").length)
	if _second_enemy != null:
		_attack_controller.bind_dash_vfx(_second_enemy, second_vfx, _second_enemy_dust)
		_attack_controller.register_enemy(_second_enemy)
		if _second_enemy_ap != null and _second_enemy_ap.has_animation("attack"):
			_attack_controller.set_enemy_attack_length(_second_enemy, _second_enemy_ap.get_animation("attack").length)
	for entry in _room_enemies:
		var body: Node3D = entry.get("node")
		if body == null:
			continue
		var vfx = DASH_VFX.new()
		vfx.name = "RoomDashVfx_%s" % body.name
		_attack_vfx_root.add_child(vfx)
		_attack_controller.bind_dash_vfx(body, vfx, entry.get("dust"))
		_attack_controller.register_enemy(body)
		var ap: AnimationPlayer = entry.get("ap")
		if ap != null and ap.has_animation("attack"):
			_attack_controller.set_enemy_attack_length(body, ap.get_animation("attack").length)
	_attack_controller.battle_requested.connect(_on_attack_battle_requested)
	_attack_controller.player_dash_started.connect(_on_attack_player_dash)
	_attack_controller.enemy_dash_started.connect(_on_attack_enemy_dash)
	_attack_controller.impact_requested.connect(_on_attack_impact)


func _on_attack_player_dash(_target: Node3D, direction: Vector3) -> void:
	# Keep the lab's own facing/camera state in sync with the controller's turn.
	if direction.length_squared() > 0.001:
		player_yaw = atan2(direction.x, direction.z)
		player.rotation.y = player_yaw
	# Comic overhaul: the clip fills wind-up + dash + recovery (0.62 s total).
	if _player_dust != null:
		_player_dust.emitting = false
	if player_ap != null and player_ap.has_animation("attack"):
		var total: float = _attack_controller.get_player_attack_total_time()
		player_ap.speed_scale = player_ap.get_animation("attack").length / maxf(0.01, total)
	else:
		player_ap.speed_scale = 1.0
	_play(player_ap, "attack")


## D-1112: any registered enemy uses its own AnimationPlayer; the Slime's
## `attack` is the DQT alias (11), Abra/Gible have it natively (D-235).
func _on_attack_enemy_dash(enemy: Node3D, _direction: Vector3) -> void:
	var ap: AnimationPlayer = null
	if enemy == _enemy:
		ap = _enemy_ap
	elif enemy == _second_enemy:
		ap = _second_enemy_ap
	if ap == null and enemy != null and is_instance_valid(enemy):
		ap = _find_anim_player(enemy)
	if enemy == _enemy and _enemy_dust != null:
		_enemy_dust.emitting = false
	elif enemy == _second_enemy and _second_enemy_dust != null:
		_second_enemy_dust.emitting = false
	else:
		for entry in _room_enemies:
			if entry.get("node") == enemy:
				var dust: CPUParticles3D = entry.get("dust")
				if dust != null:
					dust.emitting = false
				break
	if ap != null:
		# D-1142: enemy attack clip also runs at normal speed through endlag.
		ap.speed_scale = 1.0
		_play(ap, "attack")


func _on_attack_battle_requested(advantage: int) -> void:
	if _attack_controller == null:
		return
	_attack_controller.set_interact_blocked(true)
	GameState.start_battle_3d(
		"lab_3d_attack",
		scene_file_path,
		_attack_controller.get_battle_origin(),
		_attack_controller.get_battle_origin_yaw(),
		advantage)


## D-1115: reuse the actual Tackle impact package in a standalone BattleFx host.
## D-235: `contacts` carries the real victims resolved by the controller (player,
## Slime, Gible, Cyclops, Orc or an ally); the lab no longer guesses by distance.
func _on_attack_impact(pos: Vector3, direction: Vector3, advantage: int, contacts: Array) -> void:
	var host := BattleFx.new()
	host.name = "TackleImpact"
	add_child(host)
	MoveVfxRegistry.impact(host, "tackle", pos, false, direction)
	# The Tackle impact is authored for BattleFx's 12 m reference camera and
	# 1.5 m actors. The overworld camera is closer and the Slime is smaller, so
	# we pivot at the real contact point and scale by camera * actor size. The
	# authored nodes are kept intact (D-235: no fixed character/team).
	var cam_dist := BattleFx.VFX_REF_DISTANCE
	if _camera != null:
		cam_dist = _camera.global_position.distance_to(pos)
	var factor := clampf(cam_dist / BattleFx.VFX_REF_DISTANCE, 0.25, 1.0) * 1.6
	host.global_position = pos
	for child in host.get_children():
		if child is Node3D:
			var node := child as Node3D
			if node.name == "BubbleShieldFX":
				node.visible = false
				node.queue_free()
				continue
			node.position -= pos
	# The first mesh is the full-screen white star authored for the 12 m battle
	# camera. In the close overworld it whites out the whole scene; the rest of
	# the Tackle package (cone, arcs, flipbooks, dust) stays.
	for child in host.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
			break
	host.scale = Vector3.ONE * factor
	var timer := Timer.new()
	timer.wait_time = 0.60
	timer.one_shot = true
	host.add_child(timer)
	timer.timeout.connect(host.queue_free)
	timer.start()
	_slow_motion(0.075, 0.45)
	_hit_shake_left = _hit_shake_time
	for entry in contacts:
		var actor: Node3D = entry.get("actor")
		var dir: Vector3 = entry.get("direction", direction)
		react_to_hit(actor, dir)


func _slow_motion(scale: float, real_seconds: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_slowmo_token += 1
	var token := _slowmo_token
	Engine.time_scale = scale
	var timer := get_tree().create_timer(real_seconds, true, false, true)
	timer.timeout.connect(func() -> void:
		if token == _slowmo_token:
			Engine.time_scale = 1.0)


## D-1045/D-1050/D-235: generic hit reaction. Any actor with a `damage` clip
## (player, follower, Slime, Gible, Cyclops, Orc) plays it and is pushed 1.8 m
## away from the actor that really hit it, with a small arc, over 0.5 s.
##
## `direction` must point from the real attacker to the victim; it is never
## derived from a team, a character name or a fixed side. Public so a future
## enemy/allied hit source can reuse the exact same reaction path.
func react_to_hit(actor: Node3D, direction: Vector3) -> bool:
	if actor == null or not is_instance_valid(actor) or not actor.is_inside_tree():
		return false
	var dir := direction
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return false
	dir = dir.normalized()
	# Hits that arrive while the actor is already reacting do not stack tweens.
	if _is_hit_reacting(actor):
		return false
	var base := actor.global_position
	var land := _reaction_land(actor, base, dir, HIT_PUSH_DISTANCE)
	_hit_move_locks[actor.get_instance_id()] = HIT_REACTION_TIME + 0.05
	var held := _hold_follower(actor)
	_play_damage_animation(actor)
	var lift := base + dir * 1.2 + Vector3.UP * HIT_PUSH_LIFT
	var tw := create_tween()
	tw.tween_property(actor, "global_position", lift, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(actor, "global_position", land, 0.32) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func() -> void: _release_follower(held))
	return true


## Keeps the real target in front of a wall instead of pushing it through the
## geometry, so the reaction stays visible. Uses only the actor's world and its
## own collision RID (D-235: no fixed positions).
func _reaction_land(actor: Node3D, base: Vector3, dir: Vector3, distance: float) -> Vector3:
	var land := base + dir * distance
	var world := actor.get_world_3d()
	if world == null:
		return land
	var from := base + Vector3.UP * 0.6
	var to := land + Vector3.UP * 0.6
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var exclude: Array[RID] = []
	if actor is CollisionObject3D:
		exclude.append((actor as CollisionObject3D).get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return land
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	normal.y = 0.0
	if normal.length_squared() > 0.0001:
		point += normal.normalized() * 0.35
	point.y = base.y
	return point


## D-1157: the base follower update skips a body marked `busy`. The hit reaction
## reuses that existing gate (instead of disabling the node's processes) and
## restores the previous value when the push ends.
func _hold_follower(actor: Node3D) -> Dictionary:
	for f in _followers:
		if f.get("node") != actor:
			continue
		var was_busy := bool(f.get("busy", false))
		f["busy"] = true
		return {"follower": f, "was_busy": was_busy}
	return {}


func _release_follower(held: Dictionary) -> void:
	if held.is_empty():
		return
	var follower: Dictionary = held.get("follower", {})
	if follower.is_empty():
		return
	follower["busy"] = bool(held.get("was_busy", false))


func _is_hit_reacting(actor: Node3D) -> bool:
	return actor != null and _hit_move_locks.has(actor.get_instance_id())


func _play_damage_animation(actor: Node3D) -> void:
	for child in actor.find_children("*", "AnimationPlayer", true, false):
		var ap := child as AnimationPlayer
		if ap != null and ap.has_animation("damage"):
			# D-235: the lock belongs to this actor's own AnimationPlayer, so the
			# generic idle/move overrides cannot cut the reaction mid-clip.
			var length := ap.get_animation("damage").length
			_damage_locks[ap.get_instance_id()] = maxf(HIT_REACTION_ANIM_MIN, length)
			ap.play("damage")
			ap.seek(0.0, true)
			ap.speed_scale = 1.0
			return


func _enemy_state_name() -> String:
	match _enemy_state:
		EnemyState.CHASE:
			return "CHASE"
		EnemyState.SEARCH:
			return "SEARCH"
		EnemyState.RETURN:
			return "RETURN"
		EnemyState.FLEE:
			return "FLEE"
		_:
			return "PATROL"


func _second_enemy_state_name() -> String:
	return "CHASE" if _second_enemy_state == EnemyState.CHASE else "PATROL"


## D-1106: simple chase for the second enemy; the controller owns the actual
## enemy advance/telegraph, so this only supplies the CHASE state and movement.
func _update_second_enemy(_delta: float) -> void:
	if _second_enemy_body == null or not is_instance_valid(_second_enemy_body):
		return
	if _is_hit_reacting(_second_enemy_body):
		_second_enemy_body.velocity.x = 0.0
		_second_enemy_body.velocity.z = 0.0
		if _second_enemy_dust != null:
			_second_enemy_dust.emitting = false
		return
	if _attack_controller != null and _attack_controller.is_enemy_attacking(_second_enemy_body):
		return
	if _second_enemy_ap != null:
		_second_enemy_ap.speed_scale = 1.0
	if player == null or not is_instance_valid(player) or _npc_talking:
		_second_enemy_body.velocity.x = 0.0
		_second_enemy_body.velocity.z = 0.0
		_second_enemy_state = EnemyState.PATROL
		_play_idle(_second_enemy_ap)
		return
	var to_player := player.global_position - _second_enemy_body.global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist <= SECOND_ENEMY_CHASE_RADIUS and dist > SECOND_ENEMY_STOP_RADIUS:
		_second_enemy_state = EnemyState.CHASE
		var dir := to_player.normalized()
		_second_enemy_body.rotation.y = atan2(dir.x, dir.z)
		_second_enemy_body.velocity.x = dir.x * SECOND_ENEMY_SPEED
		_second_enemy_body.velocity.z = dir.z * SECOND_ENEMY_SPEED
		_second_enemy_body.move_and_slide()
		_play_move(_second_enemy_ap, true)
	else:
		_second_enemy_state = EnemyState.PATROL
		var target: Vector3 = SECOND_ENEMY_PATROL[_second_enemy_patrol_index]
		var to_target := target - _second_enemy_body.global_position
		to_target.y = 0.0
		if to_target.length() < 0.6:
			_second_enemy_patrol_index = (_second_enemy_patrol_index + 1) % SECOND_ENEMY_PATROL.size()
			_second_enemy_body.velocity.x = 0.0
			_second_enemy_body.velocity.z = 0.0
			_play_idle(_second_enemy_ap)
		else:
			var pdir := to_target.normalized()
			_second_enemy_body.rotation.y = atan2(pdir.x, pdir.z)
			_second_enemy_body.velocity.x = pdir.x * SECOND_ENEMY_PATROL_SPEED
			_second_enemy_body.velocity.z = pdir.z * SECOND_ENEMY_PATROL_SPEED
			_second_enemy_body.move_and_slide()
			_play_move(_second_enemy_ap, true)
	if _second_enemy_dust != null:
		_second_enemy_dust.emitting = _second_enemy_body.velocity.length() > 0.1


## D-1143: generic chase/patrol for the Cyclops and Orc.
func _update_room_enemies(delta: float) -> void:
	for entry in _room_enemies:
		var body: CharacterBody3D = entry.get("node")
		if body == null or not is_instance_valid(body):
			continue
		if _is_hit_reacting(body):
			body.velocity.x = 0.0
			body.velocity.z = 0.0
			var hit_dust: CPUParticles3D = entry.get("dust")
			if hit_dust != null:
				hit_dust.emitting = false
			continue
		if _attack_controller != null and _attack_controller.is_enemy_attacking(body):
			continue
		var ap: AnimationPlayer = entry.get("ap")
		if ap != null:
			ap.speed_scale = 1.0
		var dust: CPUParticles3D = entry.get("dust")
		if player == null or not is_instance_valid(player) or _npc_talking:
			body.velocity.x = 0.0
			body.velocity.z = 0.0
			entry["state"] = EnemyState.PATROL
			_play_idle(ap)
			if dust != null:
				dust.emitting = false
			continue
		var to_player := player.global_position - body.global_position
		to_player.y = 0.0
		var dist := to_player.length()
		var moving := false
		if dist <= SECOND_ENEMY_CHASE_RADIUS and dist > SECOND_ENEMY_STOP_RADIUS:
			entry["state"] = EnemyState.CHASE
			var dir := to_player.normalized()
			body.rotation.y = atan2(dir.x, dir.z)
			body.velocity.x = dir.x * SECOND_ENEMY_SPEED
			body.velocity.z = dir.z * SECOND_ENEMY_SPEED
			moving = true
		else:
			entry["state"] = EnemyState.PATROL
			var patrol: Array = entry.get("patrol", [])
			if patrol.is_empty():
				body.velocity.x = 0.0
				body.velocity.z = 0.0
			else:
				var idx := int(entry.get("patrol_index", 0)) % patrol.size()
				var target: Vector3 = patrol[idx]
				var to_target := target - body.global_position
				to_target.y = 0.0
				if to_target.length() < 0.6:
					entry["patrol_index"] = (idx + 1) % patrol.size()
					body.velocity.x = 0.0
					body.velocity.z = 0.0
				else:
					var pdir := to_target.normalized()
					body.rotation.y = atan2(pdir.x, pdir.z)
					body.velocity.x = pdir.x * float(entry.get("speed", 1.2))
					body.velocity.z = pdir.z * float(entry.get("speed", 1.2))
					moving = true
		body.move_and_slide()
		_play_move(ap, moving)
		if dust != null:
			dust.emitting = moving


func _room_enemy_state_name(entry: Dictionary) -> String:
	return "CHASE" if int(entry.get("state", EnemyState.PATROL)) == EnemyState.CHASE else "PATROL"


# D-1100 hooks used by the base lab (D-235: the actor is the key, never a side).
func _is_attack_player_locked() -> bool:
	if _is_hit_reacting(player):
		return true
	return _attack_controller != null and _attack_controller.is_player_attacking()


## D-1112: while the attack clip is playing, the base lab must not override it
## with walk/idle. The flag is refreshed from the controller before super().
func _is_attack_animation_locked() -> bool:
	return _player_attack_anim_active


func _is_attack_enemy_locked(enemy: Node3D) -> bool:
	if _is_hit_reacting(enemy):
		return true
	return _attack_controller != null and _attack_controller.is_enemy_attacking(enemy)


func _is_interaction_claimed_by_attack() -> bool:
	return _attack_controller != null and _attack_controller.has_attack_target()


func _process(delta: float) -> void:
	super(delta)
	_update_enemy_marker()
	_update_marker_rings(delta)
	_update_name_labels()
	_update_state_icons(delta)
	_update_talking_labels()
	_update_foliage_fade(delta)
	_update_hud_badges()
	_update_attack_hud()
	_update_hit_shake(delta)
	_tick_damage_locks(delta)
	_tick_hit_move_locks(delta)


func _play_idle(ap: AnimationPlayer) -> void:
	if ap != null and _damage_locks.has(ap.get_instance_id()):
		return
	super(ap)


## D-235: the same damage lock also protects `walk`/`idle` from the base lab and
## from every follower/enemy update, so the hit clip is never cut on the next frame.
func _play_move(ap: AnimationPlayer, moving: bool) -> void:
	if ap != null and _damage_locks.has(ap.get_instance_id()):
		return
	super(ap, moving)


func _tick_damage_locks(delta: float) -> void:
	for id in _damage_locks.keys():
		var left := float(_damage_locks[id]) - delta
		if left <= 0.0:
			_damage_locks.erase(id)
		else:
			_damage_locks[id] = left


func _tick_hit_move_locks(delta: float) -> void:
	for id in _hit_move_locks.keys():
		var left := float(_hit_move_locks[id]) - delta
		if left <= 0.0:
			_hit_move_locks.erase(id)
		else:
			_hit_move_locks[id] = left


func _update_hit_shake(delta: float) -> void:
	if _camera == null:
		return
	if _hit_shake_left <= 0.0:
		if not is_zero_approx(_camera.h_offset) or not is_zero_approx(_camera.v_offset):
			_camera.h_offset = 0.0
			_camera.v_offset = 0.0
		return
	_hit_shake_left = maxf(0.0, _hit_shake_left - delta)
	var k := _hit_shake_left / maxf(0.001, _hit_shake_time)
	var amp := _hit_shake_amp * k
	_camera.h_offset = _rng.randf_range(-amp, amp)
	_camera.v_offset = _rng.randf_range(-amp, amp)


func _physics_process(delta: float) -> void:
	var was_player_anim := _player_attack_anim_active
	if _attack_controller != null:
		_player_attack_anim_active = _attack_controller.is_player_attacking()
	if was_player_anim and not _player_attack_anim_active and player_ap != null:
		player_ap.speed_scale = 1.0
	super(delta)
	_update_second_enemy(delta)
	_update_room_enemies(delta)
	# D-1100: the Slime arms its 0.4 s / 4 s advance only in CHASE; FLEE cancels.
	# Dialogue/UI blocks first so a telegraph does not arm on the frame it opens.
	if _attack_controller != null:
		_attack_controller.set_interact_blocked(_npc_talking)
		if _enemy != null:
			_attack_controller.notify_enemy_state(_enemy, _enemy_state_name())
		if _second_enemy != null:
			_attack_controller.notify_enemy_state(_second_enemy, _second_enemy_state_name())
		for entry in _room_enemies:
			var body: Node3D = entry.get("node")
			if body != null and is_instance_valid(body):
				_attack_controller.notify_enemy_state(body, _room_enemy_state_name(entry))
	_update_npcs(delta)
	_update_minimap()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_2:
			cycle_npcs((_npc_offset + 3) % NPC_POOL.size())
		elif key == KEY_F6:
			_cycle_name_style()


# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.012, 0.030)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.32, 0.50)
	env.ambient_light_energy = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.88
	env.fog_enabled = true
	env.fog_light_color = Color(0.055, 0.035, 0.085)
	env.fog_density = 0.022
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.02
	# D-1083: menos contraste/saturação no 3D, sem mexer no HUD.
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.98
	env.adjustment_contrast = 0.82
	env.adjustment_saturation = 0.88
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Lua verde-pálida: fria, mas não azul, para manter a paleta do bioma.
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	moon.light_color = Color(0.66, 0.86, 0.72)
	moon.light_energy = 0.45
	moon.shadow_enabled = true
	moon.shadow_opacity = 0.55
	moon.directional_shadow_max_distance = 40.0
	add_child(moon)

	# Preenchimento quente no centro do L.
	var fill := OmniLight3D.new()
	fill.position = Vector3(8.0, 3.4, -10.0)
	fill.light_color = Color(1.0, 0.58, 0.30)
	fill.light_energy = 0.85
	fill.omni_range = 17.0
	add_child(fill)

	# D-1077/D-1083: preenchimento frio no início e no corredor, mais discreto.
	for data in [
		[Vector3(0.0, 3.0, -2.0), Color(0.55, 0.78, 0.75), 0.32, 9.0],
		[Vector3(0.0, 2.8, -8.8), Color(0.62, 0.80, 0.92), 0.22, 7.0],
	]:
		var light := OmniLight3D.new()
		light.position = data[0]
		light.light_color = data[1]
		light.light_energy = data[2]
		light.omni_range = data[3]
		add_child(light)


# --- Forest room -------------------------------------------------------------

## D-1116/D-1118: paliçada base + 5 variações, uma por parede, em ordem
## sorteada, com crossfade nos cantos e 60% de textura sobre a cor antiga.
const WALL_TEXTURE_PATHS := [
	"res://assets/textures/walls/murky_wall_root_palisade.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v1.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v2.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v3.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v4.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v5.png",
]
## Vizinhas de cada parede nos dois cantos internos.
const WALL_NEIGHBORS := [
	[1, 2], [0, 3], [0, 4], [1, 5], [2, 5], [3, 4],
]
## Canto interno (x, z) de cada ponta de cada parede.
const WALL_CORNERS := [
	[Vector2(-4.0, 6.0), Vector2(4.0, 6.0)],
	[Vector2(-4.0, 6.0), Vector2(-4.0, -14.0)],
	[Vector2(4.0, 6.0), Vector2(4.0, -6.0)],
	[Vector2(-4.0, -14.0), Vector2(18.0, -14.0)],
	[Vector2(4.0, -6.0), Vector2(18.0, -6.0)],
	[Vector2(18.0, -14.0), Vector2(18.0, -6.0)],
]


func _wall_materials() -> Array[ShaderMaterial]:
	var texs: Array[Texture2D] = []
	for path in WALL_TEXTURE_PATHS:
		texs.append(load(path) as Texture2D)
	texs.shuffle()
	var mats: Array[ShaderMaterial] = []
	for i in texs.size():
		mats.append(_wall_material(i, texs))
	return mats


func _wall_material(index: int, texs: Array[Texture2D]) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WALL_SHADER
	mat.set_shader_parameter("tex_own", texs[index])
	mat.set_shader_parameter("tex_a", texs[int(WALL_NEIGHBORS[index][0])])
	mat.set_shader_parameter("tex_b", texs[int(WALL_NEIGHBORS[index][1])])
	var ca: Vector2 = WALL_CORNERS[index][0]
	var cb: Vector2 = WALL_CORNERS[index][1]
	mat.set_shader_parameter("corner_a", Vector4(ca.x, ca.y, 0.0, 1.0))
	mat.set_shader_parameter("corner_b", Vector4(cb.x, cb.y, 0.0, 1.0))
	mat.set_shader_parameter("corner_width", 2.0)
	mat.set_shader_parameter("tile", 0.20)
	mat.set_shader_parameter("strength", 0.40)
	mat.set_shader_parameter("base_color", Color(0.075, 0.145, 0.135, 1.0))
	return mat


func _build_room() -> void:
	var floor_mat := _toon_mat(Color(0.19, 0.11, 0.22))
	var wall_mats := _wall_materials()
	var trunk_mat := _toon_mat(Color(0.10, 0.065, 0.055))

	# Piso em L + novo cômodo a leste (D-1133).
	_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, -0.2, -4.0), floor_mat)
	_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -10.0), floor_mat)
	_box(Vector3(14.0, 0.4, 12.0), Vector3(11.0, -0.2, 0.0), floor_mat)
	# Paredes externas do L + cômodo novo, com 4,2 m.
	_box(Vector3(8.5, FOREST_WALL_HEIGHT, 0.5), Vector3(0.0, FOREST_WALL_HEIGHT * 0.5, 6.25), wall_mats[0])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 20.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -4.0), wall_mats[1])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, 0.0), wall_mats[2])
	# Parede sul (z=-14,25) com três portas de 2 m: x -1..1, 6..8 e 13..15.
	_box(Vector3(3.25, FOREST_WALL_HEIGHT, 0.5), Vector3(-2.625, FOREST_WALL_HEIGHT * 0.5, -14.25), wall_mats[3])
	_box(Vector3(5.0, FOREST_WALL_HEIGHT, 0.5), Vector3(3.5, FOREST_WALL_HEIGHT * 0.5, -14.25), wall_mats[3])
	_box(Vector3(5.0, FOREST_WALL_HEIGHT, 0.5), Vector3(10.5, FOREST_WALL_HEIGHT * 0.5, -14.25), wall_mats[3])
	_box(Vector3(3.25, FOREST_WALL_HEIGHT, 0.5), Vector3(16.625, FOREST_WALL_HEIGHT * 0.5, -14.25), wall_mats[3])
	# Parede interna dividida: porta de 3 m em x 8..11, para o cômodo novo.
	_box(Vector3(4.25, FOREST_WALL_HEIGHT, 0.5), Vector3(5.875, FOREST_WALL_HEIGHT * 0.5, -5.75), wall_mats[4])
	_box(Vector3(7.25, FOREST_WALL_HEIGHT, 0.5), Vector3(14.625, FOREST_WALL_HEIGHT * 0.5, -5.75), wall_mats[4])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -10.0), wall_mats[5])
	# Paredes externas do cômodo novo.
	_box(Vector3(14.0, FOREST_WALL_HEIGHT, 0.5), Vector3(11.25, FOREST_WALL_HEIGHT * 0.5, 6.25), wall_mats[0])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, 0.0), wall_mats[5])
	# Ala sul (D-1143): três salas x -4..4, 4..10 e 10..18, z -14..-22.
	_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -18.0), floor_mat)
	_box(Vector3(22.5, FOREST_WALL_HEIGHT, 0.5), Vector3(7.0, FOREST_WALL_HEIGHT * 0.5, -22.25), wall_mats[3])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -18.0), wall_mats[1])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -18.0), wall_mats[5])
	# Divisórias com porta de 2 m em z -19..-17.
	for x in [4.25, 10.25]:
		_box(Vector3(0.5, FOREST_WALL_HEIGHT, 3.0), Vector3(x, FOREST_WALL_HEIGHT * 0.5, -20.5), wall_mats[2])
		_box(Vector3(0.5, FOREST_WALL_HEIGHT, 3.0), Vector3(x, FOREST_WALL_HEIGHT * 0.5, -15.5), wall_mats[2])
	# Pilares: colisão igual, visual de tronco.
	for p in [
		Vector2(-3.0, -2.0), Vector2(3.0, -7.0),
		Vector2(7.0, -13.0), Vector2(13.0, -7.0),
	]:
		_box(Vector3(0.55, FOREST_WALL_HEIGHT, 0.55),
			Vector3(p.x, FOREST_WALL_HEIGHT * 0.5, p.y), trunk_mat)

	_build_canopy()
	_build_foliage()
	_build_forest_lights()
	_build_minimap_map()


## D-1133: acrescenta o polígono do novo cômodo à navmesh do L.
func _build_navigation() -> void:
	super()
	if _nav_region == null or _nav_region.navigation_mesh == null:
		return
	var nav := _nav_region.navigation_mesh
	var verts := nav.get_vertices()
	if verts.size() < 8:
		return
	verts.append(Vector3(17.7, NAV_Y, 5.7))
	nav.set_vertices(verts)
	nav.add_polygon(PackedInt32Array([1, 8, 4, 2]))


func _build_canopy() -> void:
	# Copa escura; fica na camada 10, fora do mini-mapa, e não projeta sombra.
	var dark := _toon_mat(Color(0.045, 0.035, 0.075))
	var canopy := _box(Vector3(30.0, 0.3, 38.0), Vector3(7.0, 5.6, -8.0), dark, false)
	canopy.layers = 1 << 9
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Aglomerados de folhas penduradas na copa.
	for i in 26:
		var x := _rng.randf_range(-3.5, 17.5)
		var z := _rng.randf_range(-13.5, 5.5)
		var pos := Vector3(x, _rng.randf_range(4.55, 5.15), z)
		_foliage(pos, _rng.randf_range(0.55, 1.05), _leaf_color(), 1 << 9)


func _build_foliage() -> void:
	# Parede oeste e leste da sala norte.
	for z in range(-5, 7, 2):
		for side in [-1, 1]:
			var x: float = side * 3.98
			for k in 2:
				var pos := Vector3(x + side * 0.14,
					_rng.randf_range(0.8, 3.4) + k * 0.5,
					z + _rng.randf_range(-0.45, 0.45))
				_foliage(pos, _rng.randf_range(0.35, 0.65), _leaf_color(), 1 << 8)
	# Parede norte da sala.
	for x in range(-3, 4, 2):
		_foliage(Vector3(x + _rng.randf_range(-0.3, 0.3),
			_rng.randf_range(1.0, 3.3), 5.92), _rng.randf_range(0.45, 0.75), _leaf_color(), 1 << 8)
	# Paredes do corredor leste-oeste.
	for x in range(4, 18, 2):
		for z in [-5.95, -14.05]:
			var sign_z := 1.0 if z > -6.5 else -1.0
			_foliage(Vector3(x + _rng.randf_range(-0.4, 0.4),
				_rng.randf_range(0.9, 3.5), z + sign_z * 0.12),
				_rng.randf_range(0.4, 0.7), _leaf_color(), 1 << 8)
	# Topo das paredes: arbustos grandes.
	for i in 34:
		var on_north_room := i % 3 == 0
		var pos: Vector3
		if on_north_room:
			var side := -1.0 if i % 2 == 0 else 1.0
			pos = Vector3(side * 4.0, _rng.randf_range(3.9, 4.45), _rng.randf_range(-5.5, 5.5))
		else:
			var z := -5.95 if i % 2 == 0 else -14.05
			pos = Vector3(_rng.randf_range(4.0, 17.5), _rng.randf_range(3.9, 4.45), z)
		_foliage(pos, _rng.randf_range(0.5, 0.9), _leaf_color(), 1 << 9)
	# Folhas no chão (não bloqueiam o caminho).
	for i in 120:
		var x := _rng.randf_range(-3.6, 3.6)
		var z := _rng.randf_range(-5.8, 5.5)
		if i % 2 == 1:
			x = _rng.randf_range(4.0, 17.3)
			z = _rng.randf_range(-13.4, -6.6)
		_leaf_patch(Vector3(x, 0.02, z), _rng.randf_range(0.0, TAU), _ground_color())
	# Cômodo novo (D-1133): folhas e samambaias no piso, sem collisão.
	for i in 30:
		_leaf_patch(Vector3(_rng.randf_range(4.5, 17.5), 0.02,
			_rng.randf_range(-5.5, 5.5)), _rng.randf_range(0.0, TAU), _ground_color())
	for i in 10:
		_fern(Vector3(_rng.randf_range(5.0, 17.0), 0.0,
			_rng.randf_range(-5.0, 5.0)), _rng.randf_range(0.5, 0.9), _fern_color())
	for i in 5:
		_mushroom(Vector3(_rng.randf_range(5.0, 17.0), 0.0,
			_rng.randf_range(-5.0, 5.0)), _mushroom_color(), _glow_color(), i % 5 == 0)
	# Ala sul (D-1143): folhas e samambaias nas três salas.
	for i in 36:
		_leaf_patch(Vector3(_rng.randf_range(-3.5, 17.5), 0.02,
			_rng.randf_range(-21.5, -14.5)), _rng.randf_range(0.0, TAU), _ground_color())
	for i in 12:
		_fern(Vector3(_rng.randf_range(-3.0, 17.0), 0.0,
			_rng.randf_range(-21.0, -15.0)), _rng.randf_range(0.5, 0.9), _fern_color())
	# Pedras, cogumelos, samambaias e raízes, longe do caminho do jogador.
	for i in 12:
		var pos := Vector3(_rng.randf_range(-2.8, 2.8), 0.08, _rng.randf_range(-5.0, 4.5))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(5.0, 16.5), 0.08, _rng.randf_range(-12.5, -7.5))
		if _near_path(pos):
			continue
		_stone(pos, _rng.randf_range(0.22, 0.50))
	for i in 20:
		var pos := Vector3(_rng.randf_range(-3.4, 3.4), 0.0, _rng.randf_range(-5.2, 5.2))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(4.5, 17.0), 0.0, _rng.randf_range(-12.8, -7.0))
		if _near_path(pos):
			continue
		_mushroom(pos, _mushroom_color(), _glow_color(), i % 5 == 0)
	for i in 26:
		var pos := Vector3(_rng.randf_range(-3.5, 3.5), 0.0, _rng.randf_range(-5.4, 5.4))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(4.2, 17.2), 0.0, _rng.randf_range(-13.2, -6.8))
		if _near_path(pos):
			continue
		_fern(pos, _rng.randf_range(0.5, 0.9), _fern_color())
	for i in 14:
		var pos := Vector3(_rng.randf_range(-3.6, 3.6), 0.0, _rng.randf_range(-5.6, 5.4))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(4.2, 17.2), 0.0, _rng.randf_range(-13.3, -6.7))
		if _near_path(pos):
			continue
		_root(pos, _rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.6))
	_build_vertical_foliage()
	_build_fireflies()


## D-1077: vinhas, galhos e clumps médios ancorados nas paredes/árvores.
func _build_vertical_foliage() -> void:
	var vine_tops := [
		Vector3(-3.95, 4.5, -4.0), Vector3(3.95, 4.5, 1.5),
		Vector3(-3.95, 4.5, 3.0), Vector3(3.95, 4.5, -5.0),
		Vector3(6.0, 4.5, -5.9), Vector3(10.0, 4.5, -5.9),
		Vector3(14.0, 4.5, -5.9), Vector3(7.0, 4.5, -14.1),
		Vector3(11.0, 4.5, -14.1), Vector3(15.0, 4.5, -14.1),
	]
	for i in vine_tops.size():
		_vine(vine_tops[i], 1.6 + float(i % 3) * 0.35)
	var branches := [
		{"pos": Vector3(-3.0, 3.2, -2.0), "dir": Vector3(1.0, 0.0, 0.0), "len": 1.3},
		{"pos": Vector3(3.0, 3.0, -7.0), "dir": Vector3(-1.0, 0.0, 0.0), "len": 1.2},
		{"pos": Vector3(7.0, 3.1, -13.0), "dir": Vector3(0.0, 0.0, 1.0), "len": 1.4},
		{"pos": Vector3(13.0, 3.0, -7.0), "dir": Vector3(0.0, 0.0, -1.0), "len": 1.3},
	]
	for b in branches:
		_branch(b["pos"], b["dir"], float(b["len"]))
	# Clumps médios nas paredes, menores, preenchendo a altura.
	for i in 12:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * 3.98
		var z := _rng.randf_range(-5.2, 5.0)
		_foliage(Vector3(x, _rng.randf_range(2.5, 3.5), z),
			_rng.randf_range(0.25, 0.42), _leaf_color(), 1 << 8)


func _vine(top: Vector3, length: float) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.04
	mesh.height = length
	mesh.radial_segments = 5
	mi.mesh = mesh
	mi.position = top + Vector3(0.0, -length * 0.5, 0.0)
	mi.material_override = _toon_mat(Color(0.10, 0.16, 0.10))
	mi.layers = 1 << 8
	add_child(mi)
	for k in 3:
		var off := Vector3(_rng.randf_range(-0.14, 0.14), 0.0, _rng.randf_range(-0.14, 0.14))
		_foliage(top + off + Vector3(0.0, -length * (0.35 + 0.2 * float(k)), 0.0),
			_rng.randf_range(0.18, 0.30), _leaf_color(), 1 << 8)


func _branch(base: Vector3, dir: Vector3, length: float) -> void:
	var d := dir.normalized()
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.065
	mesh.height = length
	mesh.radial_segments = 5
	mi.mesh = mesh
	mi.position = base + d * (length * 0.5)
	if absf(d.x) > 0.5:
		mi.rotation.z = PI * 0.5 * signf(d.x)
	else:
		mi.rotation.x = -PI * 0.5 * signf(d.z)
	mi.material_override = _toon_mat(Color(0.10, 0.07, 0.05))
	mi.layers = 1 << 8
	add_child(mi)
	_foliage(base + d * length, _rng.randf_range(0.32, 0.48), _leaf_color(), 1 << 8)


func _near_path(pos: Vector3) -> bool:
	for slot in NPC_SLOTS:
		var spos: Vector3 = slot["pos"]
		if Vector2(pos.x - spos.x, pos.z - spos.z).length() < 1.1:
			return true
	if pos.x > -1.7 and pos.x < 1.7 and pos.z > -6.2 and pos.z < 5.5:
		return true
	if pos.z > -11.3 and pos.z < -7.5 and pos.x > 3.7:
		return true
	return false


func _build_forest_lights() -> void:
	# Cogumelos luminosos e vaga-lumes; sem azul, só verde/teal e âmbar.
	for p in [Vector3(-3.2, 2.2, -4.5), Vector3(3.2, 2.0, 1.0),
			Vector3(6.5, 2.2, -12.8), Vector3(15.5, 2.2, -7.2),
			Vector3(11.5, 2.2, 1.5), Vector3(-0.5, 2.2, -18.0),
			Vector3(7.0, 2.2, -18.0), Vector3(14.0, 2.2, -18.0)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color(0.35, 0.95, 0.55)
		light.light_energy = 0.40
		light.omni_range = 4.5
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.40)

	# D-1077/D-1083: aproximação quente da saída, mais discreta.
	var approach := OmniLight3D.new()
	approach.position = Vector3(13.5, 2.2, -10.0)
	approach.light_color = Color(1.0, 0.68, 0.38)
	approach.light_energy = 0.30
	approach.omni_range = 6.0
	add_child(approach)


func _build_fireflies() -> void:
	for p in [Vector3(0.0, 1.7, -3.0), Vector3(10.0, 1.9, -10.0), Vector3(5.0, 1.6, 3.0),
			Vector3(12.0, 1.7, 1.0)]:
		var quad := QuadMesh.new()
		quad.size = Vector2(0.09, 0.09)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_color = Color(1.0, 0.72, 0.30, 0.9)
		var particles := CPUParticles3D.new()
		particles.position = p
		particles.amount = 14
		particles.lifetime = 5.0
		particles.emitting = true
		particles.local_coords = false
		particles.mesh = quad
		particles.material_override = mat
		particles.direction = Vector3.UP
		particles.spread = 180.0
		particles.gravity = Vector3.ZERO
		particles.initial_velocity_min = 0.05
		particles.initial_velocity_max = 0.25
		particles.scale_amount_min = 0.7
		particles.scale_amount_max = 1.4
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 4.0
		particles.layers = 1 << 8
		add_child(particles)


func _leaf_color() -> Color:
	var colors := [
		Color(0.10, 0.42, 0.34),
		Color(0.16, 0.55, 0.35),
		Color(0.08, 0.30, 0.26),
		Color(0.28, 0.18, 0.42),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _ground_color() -> Color:
	var colors := [
		Color(0.24, 0.14, 0.26),
		Color(0.17, 0.10, 0.20),
		Color(0.13, 0.20, 0.19),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _mushroom_color() -> Color:
	var colors := [
		Color(0.25, 0.55, 0.38),
		Color(0.38, 0.22, 0.45),
		Color(0.45, 0.30, 0.18),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _glow_color() -> Color:
	var colors := [
		Color(0.30, 1.0, 0.55),
		Color(0.75, 0.95, 0.72),
		Color(1.0, 0.65, 0.25),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _fern_color() -> Color:
	var colors := [
		Color(0.10, 0.40, 0.25),
		Color(0.16, 0.50, 0.28),
		Color(0.08, 0.30, 0.22),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


# --- Forest meshes -----------------------------------------------------------

func _toon_mat(color: Color, emission := Color(0, 0, 0, 1), emission_energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.92
	mat.metallic = 0.0
	mat.rim_enabled = true
	mat.rim = 0.22
	mat.rim_tint = 0.35
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


func _foliage(pos: Vector3, radius: float, color: Color, layer: int) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.position = pos
	mi.scale = Vector3(
		_rng.randf_range(0.9, 1.25),
		_rng.randf_range(0.65, 0.95),
		_rng.randf_range(0.9, 1.25))
	mi.rotation.y = _rng.randf_range(0.0, TAU)
	var mat := _toon_mat(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 1.0
	mi.material_override = mat
	mi.layers = layer
	add_child(mi)
	_foliage_fade.append({
		"mesh": mi,
		"mat": mat,
		"radius": radius * maxf(maxf(mi.scale.x, mi.scale.y), mi.scale.z),
	})
	# Clumps menores por cima: quebra a leitura de "pedra" e vira folhagem.
	for k in 2:
		var clump := SphereMesh.new()
		clump.radius = radius * _rng.randf_range(0.35, 0.55)
		clump.height = clump.radius * 1.6
		clump.radial_segments = 5
		clump.rings = 2
		var leaf := MeshInstance3D.new()
		leaf.mesh = clump
		leaf.position = pos + Vector3(
			_rng.randf_range(-radius * 0.7, radius * 0.7),
			_rng.randf_range(radius * 0.35, radius * 0.9),
			_rng.randf_range(-radius * 0.7, radius * 0.7))
		leaf.rotation.y = _rng.randf_range(0.0, TAU)
		leaf.scale = Vector3(1.0, 0.72, 1.0)
		var leaf_mat := _toon_mat(color.lightened(0.16))
		leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		leaf_mat.albedo_color.a = 1.0
		leaf.material_override = leaf_mat
		leaf.layers = layer
		add_child(leaf)
		_foliage_fade.append({
			"mesh": leaf,
			"mat": leaf_mat,
			"radius": clump.radius * 1.1,
		})


## D-1077: some suavemente com folhas que ficam entre a câmera e o jogador.
func _update_foliage_fade(delta: float) -> void:
	if _camera == null or player == null:
		return
	var cam := _camera.global_position
	var target := player.global_position + Vector3(0.0, 1.0, 0.0)
	var seg := target - cam
	var seg_len2 := maxf(seg.length_squared(), 0.001)
	for entry in _foliage_fade:
		var mesh := entry["mesh"] as MeshInstance3D
		if mesh == null or not is_instance_valid(mesh):
			continue
		var mat := entry["mat"] as StandardMaterial3D
		if mat == null:
			continue
		var pos := mesh.global_position
		var t := clampf((pos - cam).dot(seg) / seg_len2, 0.0, 1.0)
		var closest := cam + seg * t
		var occlude := t > 0.02 and t < 0.98 \
			and pos.distance_to(cam) < 3.6 \
			and pos.distance_to(closest) < float(entry["radius"]) + 0.35
		var target_a := 0.22 if occlude else 1.0
		var col := mat.albedo_color
		col.a = lerpf(col.a, target_a, clampf(delta * 8.0, 0.0, 1.0))
		mat.albedo_color = col


func _leaf_patch(pos: Vector3, rot: float, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(_rng.randf_range(0.18, 0.4), 0.02, _rng.randf_range(0.12, 0.28))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = rot
	mi.material_override = _toon_mat(color)
	mi.layers = 1 << 8
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _stone(pos: Vector3, radius: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.2
	mesh.radial_segments = 5
	mesh.rings = 2
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = Vector3(1.0, 0.55, 0.85)
	mi.material_override = _toon_mat(Color(0.16, 0.14, 0.17))
	mi.layers = 1 << 8
	add_child(mi)


func _mushroom(pos: Vector3, cap_color: Color, glow: Color, light_on: bool) -> void:
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.10
	cyl.height = _rng.randf_range(0.26, 0.46)
	cyl.radial_segments = 5
	stem.mesh = cyl
	stem.position = pos + Vector3(0.0, cyl.height * 0.5, 0.0)
	stem.material_override = _toon_mat(Color(0.32, 0.24, 0.18))
	stem.layers = 1 << 8
	add_child(stem)

	var cap := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _rng.randf_range(0.13, 0.23)
	sphere.height = sphere.radius * 1.2
	sphere.radial_segments = 6
	sphere.rings = 2
	cap.mesh = sphere
	cap.position = pos + Vector3(0.0, cyl.height + sphere.radius * 0.35, 0.0)
	cap.scale = Vector3(1.0, 0.55, 1.0)
	cap.material_override = _toon_mat(cap_color, glow, 1.4 if light_on else 0.0)
	cap.layers = 1 << 8
	add_child(cap)

	if light_on:
		var light := OmniLight3D.new()
		light.position = cap.position + Vector3(0.0, 0.25, 0.0)
		light.light_color = glow
		light.light_energy = 0.45
		light.omni_range = 3.2
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.45)


func _fern(pos: Vector3, scale: float, color: Color) -> void:
	for i in 5:
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.05, 0.75, 0.02)
		blade.mesh = mesh
		blade.position = pos + Vector3(0.0, 0.34 * scale, 0.0)
		blade.rotation = Vector3(
			deg_to_rad(_rng.randf_range(-28.0, -10.0)),
			deg_to_rad(float(i) * 72.0 + _rng.randf_range(-10.0, 10.0)),
			0.0)
		blade.scale = Vector3(scale, scale, scale)
		blade.material_override = _toon_mat(color)
		blade.layers = 1 << 8
		add_child(blade)


func _root(pos: Vector3, rot: float, length: float) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.14
	mesh.height = length
	mesh.radial_segments = 5
	mi.mesh = mesh
	mi.position = pos + Vector3(0.0, 0.16, 0.0)
	mi.rotation = Vector3(0.0, rot, deg_to_rad(_rng.randf_range(-12.0, 12.0)))
	mi.material_override = _toon_mat(Color(0.12, 0.08, 0.06))
	mi.layers = 1 << 8
	add_child(mi)


# --- Exit --------------------------------------------------------------------

func _build_exit() -> void:
	var gate_mat := _toon_mat(Color(0.10, 0.55, 0.28), Color(0.15, 0.85, 0.35), 1.1)
	var gate_a := _box(Vector3(0.3, 3.4, 0.3), Vector3(17.7, 1.7, -11.4), gate_mat, false)
	var gate_b := _box(Vector3(0.3, 3.4, 0.3), Vector3(17.7, 1.7, -8.6), gate_mat, false)
	var gate_top := _box(Vector3(0.3, 0.3, 3.2), Vector3(17.7, 3.4, -10.0), gate_mat, false)
	var dark := _box(Vector3(0.15, 2.8, 2.6), Vector3(17.85, 1.4, -10.0), _toon_mat(Color(0.01, 0.02, 0.015)), false)
	for mi in [gate_a, gate_b, gate_top, dark]:
		mi.layers = 1 << 8
	var exit_light := OmniLight3D.new()
	exit_light.position = Vector3(17.2, 1.8, -10.0)
	exit_light.light_color = Color(0.35, 1.0, 0.55)
	exit_light.light_energy = 0.45
	exit_light.omni_range = 4.5
	add_child(exit_light)
	# Trepadeiras Verdes no portal.
	for i in 8:
		var side := -1.0 if i % 2 == 0 else 1.0
		_foliage(Vector3(17.55, _rng.randf_range(1.0, 3.2), -10.0 + side * _rng.randf_range(0.9, 1.7)),
			_rng.randf_range(0.22, 0.38), _leaf_color(), 1 << 8)
	var tag := Label3D.new()
	tag.text = "SAÍDA"
	tag.font_size = 46
	tag.modulate = Color(0.55, 1.0, 0.62)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(17.5, 3.9, -10.0)
	tag.no_depth_test = false
	tag.layers = 1 << 8
	add_child(tag)


# --- Vignette / HUD ----------------------------------------------------------

func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = FOREST_VIGNETTE
	mat.set_shader_parameter("tint", Color(0.02, 0.012, 0.035, 1.0))
	mat.set_shader_parameter("strength", 0.34)
	mat.set_shader_parameter("softness", 0.58)
	mat.set_shader_parameter("dither_strength", 0.006)
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.add_to_group("overworld_hud")
	var label := Label.new()
	label.text = "Lab 3D — Murky Forest (SMT III + toon)\nSetas/W/S: andar · A/D ou botão direito: câmera · 1: aliados · 2: trocar NPCs · F6: estilo do nome · Z: atacar · E: falar/saída/trocar personagem · Esc: sair"
	label.position = Vector2(20, 16)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.70, 0.95, 0.72))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)

	_door_prompt = Label.new()
	_door_prompt.text = ""
	_door_prompt.position = Vector2(520, 660)
	_door_prompt.add_theme_font_size_override("font_size", 22)
	_door_prompt.add_theme_color_override("font_color", Color(0.75, 1.0, 0.70))
	_door_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_door_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_door_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_door_prompt.visible = false
	layer.add_child(_door_prompt)
	add_child(layer)


# --- NPCs (D-1063) -----------------------------------------------------------

func _build_npcs() -> void:
	# Sorteia/exibe 3 NPCs no corredor (misturando Pokémon Stage-1 e DQT básicos).
	var default_indices: Array[int] = [0, 5, 3] # Bulbasaur, Dracky, Pikachu no início; KEY_2 gira todos os 10.
	for slot_i in NPC_SLOTS.size():
		var pool_idx: int = default_indices[slot_i] if _npc_offset == 0 else ((_npc_offset + slot_i) % NPC_POOL.size())
		_spawn_npc_at_slot(slot_i, pool_idx)


func _spawn_npc_at_slot(slot_i: int, pool_idx: int) -> void:
	var slot: Dictionary = NPC_SLOTS[slot_i]
	var data: Dictionary = NPC_POOL[pool_idx]
	var model_id := str(data["id"])
	var npc_name := str(data["name"])
	var height := float(data["height"])
	var pos: Vector3 = slot["pos"]
	var base_yaw := float(slot["yaw"])

	var body := StaticBody3D.new()
	body.name = "Npc_%s" % model_id
	body.position = pos
	body.rotation.y = base_yaw
	# Layer 16 (bit 4): sólida para o jogador (máscara 1|16); o raio da câmera
	# usa a máscara 1 e ignora os NPCs (D-1023).
	body.collision_layer = NPC_COLLISION_LAYER
	body.collision_mask = 0
	body.add_to_group("minimap_npc")

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = clampf(height * 0.30, 0.22, 0.42)
	capsule.height = maxf(height, capsule.radius * 2.0 + 0.05)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	body.add_child(shape)
	add_child(body)

	var model := _make_model(model_id, height)
	body.add_child(model)
	_add_blob_shadow(body, clampf(height * 0.85, 0.65, 1.1), clampf(height * 0.65, 0.50, 0.90))
	var ap := _anim_player(model)
	_play_idle(ap)

	var top_y := height
	if model_id == "dqt_dracky":
		top_y = height * 1.48

	# D-1094: placa de nome (Paper/terminal/comic) em vez do Label3D solto.
	var tag := _spawn_nameplate(body, npc_name, "NPC", top_y + 0.65)

	var dlg_idx := (pool_idx * 3 + slot_i) % NPC_DATA.DIALOGUES.size()
	_npcs.append({
		"node": body,
		"model": model,
		"ap": ap,
		"id": model_id,
		"name": npc_name,
		"height": height,
		"base_yaw": base_yaw,
		"dialogue": NPC_DATA.DIALOGUES[dlg_idx],
		"pool_idx": pool_idx,
		"has_quest": bool(data.get("has_quest", false)),
		"talked": false,
		"tag": tag,
	})


# --- D-1086: círculos no chão, ícones de estado e nomes dos aliados --------

func _add_world_markers() -> void:
	for npc in _npcs:
		_decorate_npc(npc)
	for f in _followers:
		var body: Node3D = f["node"]
		var height := float(f["height"])
		_add_ground_ring(body, clampf(height * 0.55, 0.42, 0.95), Color(0.22, 0.48, 1.0, 0.65), "ally")
		_add_ally_talking(f)
	if _enemy_body != null:
		_enemy_marker_root = Node3D.new()
		_enemy_marker_root.name = "EnemyMarkers"
		add_child(_enemy_marker_root)
		_add_ground_ring(_enemy_marker_root, 0.45, Color(1.0, 0.72, 0.15, 0.70), "enemy")
		_enemy_ring_entry = _marker_rings.back()
		_enemy_icon_entry = _add_state_icon(_enemy_marker_root, Vector3(0.0, 1.05, 0.0), clampf(_actor_visual_top(_enemy_body) / 1.2, 0.55, 1.0))
		var enemy_name := "SLIME"
		for child in _enemy_body.get_children():
			if child is Label3D:
				enemy_name = (child as Label3D).text
				(child as Label3D).visible = false
				break
		var enemy_tag := _spawn_nameplate(_enemy_body, enemy_name, "ENEMY", _actor_visual_top(_enemy_body) + 0.55)
		_name_labels.append({"node": enemy_tag, "owner": _enemy_body})
		_enemy_icon_entry["plate"] = enemy_tag


func _decorate_npc(npc: Dictionary) -> void:
	if npc.has("icon_entry"):
		var old_sprite = npc["icon_entry"].get("sprite")
		if is_instance_valid(old_sprite):
			return
	var body: Node3D = npc["node"]
	var height := float(npc["height"])
	var top_y := height
	if str(npc["id"]) == "dqt_dracky":
		top_y = height * 1.48
	_add_ground_ring(body, clampf(height * 0.75, 0.45, 0.85), Color(1.0, 1.0, 1.0, 0.68), "npc")
	# D-1105: a posição final é dinâmica (acima da placa); este é só o inicial.
	npc["icon_entry"] = _add_state_icon(body, Vector3(0.0, top_y + 1.75, 0.0), clampf(_actor_visual_top(body) / 1.2, 0.55, 1.0))
	if npc.has("tag") and is_instance_valid(npc["tag"]):
		npc["icon_entry"]["plate"] = npc["tag"]
	var talking := Label3D.new()
	talking.text = "..."
	talking.font_size = 48
	talking.modulate = Color(1.0, 0.86, 0.45)
	talking.outline_size = 6
	talking.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	talking.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	talking.no_depth_test = false
	talking.position = Vector3(0.0, top_y + 1.65, 0.0)
	talking.layers = 1 << 6
	talking.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talking.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talking.visible = false
	body.add_child(talking)
	npc["talking_label"] = talking
	npc["icon_entry"]["talk"] = talking
	if npc.has("tag") and is_instance_valid(npc["tag"]):
		_name_labels.append({"node": npc["tag"], "owner": body})
	_update_npc_icon(npc)


func _add_ground_ring(parent: Node3D, radius: float, color: Color, kind: String = "") -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.6, radius * 2.6)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(0.0, 0.025, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = MARKER_RING_SHADER
	mat.set_shader_parameter("ring_color", color)
	mat.set_shader_parameter("inner_radius", 0.80)
	mat.set_shader_parameter("outer_radius", 0.95)
	mat.set_shader_parameter("softness", 0.04)
	mi.material_override = mat
	parent.add_child(mi)
	_marker_rings.append({
		"mesh": mi,
		"mat": mat,
		"owner": parent,
		"kind": kind,
		"phase": _rng.randf_range(0.0, TAU),
	})


func _actor_visual_top(body: Node3D) -> float:
	var top := 0.0
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		if mi.has_meta("dash_vfx_ignore_measure"):
			continue
		var box := mi.global_transform * mi.mesh.get_aabb()
		top = maxf(top, box.position.y + box.size.y - body.global_position.y)
	return top


func _add_state_icon(parent: Node3D, pos: Vector3, base_scale := 1.0) -> Dictionary:
	# D-1098/D-1105/D-1127: ícone 3D extrudado, escalado pela altura do ator.
	var icon = STATE_ICON.new()
	icon.name = "StateIcon"
	icon.setup(ICON_QUESTION, Color.WHITE)
	icon.position = pos
	parent.add_child(icon)
	var entry := {
		"sprite": icon,
		"base_y": pos.y,
		"base_scale": clampf(base_scale, 0.4, 1.0),
		"phase": _rng.randf_range(0.0, TAU),
		"state": "",
		"pop": 0.0,
		"owner": parent,
	}
	_state_icons.append(entry)
	return entry


func _add_ally_name(f: Dictionary) -> void:
	var body: Node3D = f["node"]
	var height := float(f["height"])
	var model_id := str(f.get("model_id", ""))
	var display := str(FOLLOWER_NAMES.get(model_id, model_id.to_upper()))
	var tag := _spawn_nameplate(body, display, "ALLY", height + 0.65)
	_name_labels.append({"node": tag, "owner": body})


func _add_ally_talking(f: Dictionary) -> void:
	var body: Node3D = f["node"]
	var height := float(f["height"])
	var talk := Label3D.new()
	talk.text = "..."
	talk.font_size = 48
	talk.modulate = Color(1.0, 0.86, 0.45)
	talk.outline_size = 6
	talk.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	talk.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	talk.no_depth_test = false
	talk.position = Vector3(0.0, height + 1.65, 0.0)
	talk.layers = 1 << 6
	talk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talk.visible = false
	body.add_child(talk)
	f["talking_label"] = talk


func _update_enemy_marker() -> void:
	if _enemy_marker_root == null or _enemy_body == null:
		return
	if not is_instance_valid(_enemy_body):
		return
	_enemy_marker_root.global_position = _enemy_body.global_position
	_enemy_marker_root.visible = _enemy_body.visible
	_update_enemy_icon()
	_update_enemy_ring_color()


func _update_marker_rings(_delta: float) -> void:
	if _camera == null:
		return
	for i in range(_marker_rings.size() - 1, -1, -1):
		var entry := _marker_rings[i]
		var owner := entry["owner"] as Node3D
		var mesh := entry["mesh"] as MeshInstance3D
		if owner == null or not is_instance_valid(owner) or mesh == null or not is_instance_valid(mesh):
			_marker_rings.remove_at(i)
			continue
		var dist := _camera.global_position.distance_to(owner.global_position)
		mesh.visible = dist > 1.4
		if not mesh.visible:
			continue
		if str(entry.get("kind", "")) == "ally" and player != null:
			var to_owner := owner.global_position - player.global_position
			var to_cam := _camera.global_position - player.global_position
			if to_owner.length_squared() > 0.001 and to_cam.length_squared() > 0.001:
				var ang := rad_to_deg(acos(clampf(
					to_owner.normalized().dot(to_cam.normalized()), -1.0, 1.0)))
				if ang < 50.0:
					mesh.visible = false
					continue
		var fade := clampf(1.0 - (dist - 7.0) / 11.0, 0.22, 1.0)
		var pulse := 0.88 + 0.12 * sin(_time * 2.1 + float(entry["phase"]))
		var mat := entry["mat"] as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("alpha", fade * pulse)


func _update_state_icons(delta: float) -> void:
	for i in range(_state_icons.size() - 1, -1, -1):
		var entry := _state_icons[i]
		var icon := entry["sprite"] as Node3D
		if icon == null or not is_instance_valid(icon):
			_state_icons.remove_at(i)
			continue
		var pop := maxf(0.0, float(entry["pop"]) - delta * 4.0)
		entry["pop"] = pop
		var dist := 9.0
		if _camera != null:
			dist = _camera.global_position.distance_to(icon.global_position)
		# D-1098: ícones 3D ficam maiores também a média distância.
		var s := (1.0 + pop * 0.35) * clampf(0.55 + dist / 16.0, 0.55, 1.15)
		var base_scale := float(entry.get("base_scale", 1.0))
		var total := s * base_scale
		icon.scale = Vector3(total, total, total)
		var base := float(entry["base_y"])
		# D-1105: o ícone fica sempre acima do card atual; se o NPC fala,
		# fica acima do "..." também para não cobri-lo.
		var plate := entry.get("plate") as Node3D
		if plate != null and is_instance_valid(plate) and plate.has_method("card_top_local"):
			var top := float(plate.card_top_local())
			var min_bottom := top + 0.08
			var talk := entry.get("talk") as Node3D
			if talk != null and is_instance_valid(talk) and talk.visible:
				min_bottom = maxf(min_bottom, talk.position.y + 0.14)
			var mesh: Mesh = icon._front.mesh
			if mesh != null:
				var aabb := mesh.get_aabb()
				base = min_bottom - aabb.position.y * total
				entry["base_y"] = base
		icon.position.y = base \
			+ sin(_time * 2.4 + float(entry["phase"])) * 0.045 + pop * 0.15


func _update_name_labels() -> void:
	if _camera == null:
		return
	for i in range(_name_labels.size() - 1, -1, -1):
		var entry := _name_labels[i]
		var tag := entry.get("node") as Node3D
		var owner := entry["owner"] as Node3D
		if tag == null or not is_instance_valid(tag) or owner == null or not is_instance_valid(owner):
			_name_labels.remove_at(i)
			continue
		var dist := _camera.global_position.distance_to(tag.global_position)
		# D-1105: o card encolhe com a distância; a 9 m a tela fica na
		# metade do tamanho de 4 m. A base de 40% está no estilo do card.
		var s := clampf(0.5 + (dist - 4.0) * 0.0125, 0.4, 0.7)
		if tag.has_method("set_distance_scale"):
			tag.set_distance_scale(s)
		else:
			tag.scale = Vector3(s, s, s)


func _spawn_nameplate(parent: Node3D, text: String, role: String, y: float) -> Node3D:
	var plate = NAMEPLATE.new()
	plate.display_name = text
	plate.role_text = role
	plate.style_id = name_style
	plate.position = Vector3(0.0, y, 0.0)
	parent.add_child(plate)
	return plate as Node3D


## D-1094: troca o estilo das placas em tempo real (F6 no lab e captura A/B/C).
func set_name_style(style: String) -> void:
	if not ["unit_card", "move_strip", "expedition"].has(style):
		return
	name_style = style
	for entry in _name_labels:
		var node = entry.get("node")
		if node != null and is_instance_valid(node) and node.has_method("set_style"):
			node.set_style(style)


func _cycle_name_style() -> void:
	var order := ["unit_card", "move_strip", "expedition"]
	var idx := order.find(name_style)
	set_name_style(order[(idx + 1) % order.size()])


func _set_icon(entry: Dictionary, state: String, texture: Texture2D, tint: Color) -> void:
	if str(entry.get("state", "")) == state:
		return
	entry["state"] = state
	var icon = entry["sprite"]
	if icon == null:
		return
	if icon.has_method("set_state"):
		icon.set_state(texture, tint)
	entry["pop"] = 0.28


func _update_npc_icon(npc: Dictionary) -> void:
	var entry: Dictionary = npc.get("icon_entry", {})
	if entry.is_empty():
		return
	if bool(npc.get("talked", false)):
		_set_icon(entry, "talked", ICON_TALKED, Color(0.75, 1.0, 0.78))
	elif bool(npc.get("has_quest", false)):
		_set_icon(entry, "quest", ICON_QUESTION, Color(1.0, 0.82, 0.22))
	else:
		_set_icon(entry, "question", ICON_QUESTION, Color.WHITE)


func _update_talking_labels() -> void:
	var active_label: Label3D = null
	if _npc_talking and not _npc_talk_target.is_empty():
		if _dialogue_stage == 0:
			var label = _npc_talk_target.get("talking_label")
			if label is Label3D:
				active_label = label
		elif _dialogue_stage > 0 and _dialogue_stage <= _dialogue_reactions.size():
			var reaction: Dictionary = _dialogue_reactions[_dialogue_stage - 1]
			var label = reaction.get("talking_label")
			if label is Label3D:
				active_label = label
	for npc in _npcs:
		if npc.has("talking_label") and is_instance_valid(npc["talking_label"]):
			npc["talking_label"].visible = false
	for f in _followers:
		if f.has("talking_label") and is_instance_valid(f["talking_label"]):
			f["talking_label"].visible = false
	if active_label != null and is_instance_valid(active_label):
		active_label.visible = true
		var phase := int(_time * 3.0) % 3
		active_label.text = ".".repeat(phase + 1)


func _build_ally_reactions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _npc_talk_target.is_empty():
		return out
	var line_idx := int(_npc_talk_target.get("pool_idx", 0))
	for f in _followers:
		var model_id := str(f.get("model_id", ""))
		var nature := "hardy"
		if model_id == "pancham":
			nature = "brave"
		elif model_id == "dqt_orc":
			nature = "orc"
		var display := str(FOLLOWER_NAMES.get(model_id, model_id.to_upper()))
		var tint := Color(0.08, 0.08, 0.10)
		if model_id == "dqt_orc":
			tint = Color(0.18, 0.30, 0.16)
		out.append({
			"name": display,
			"text": ALLY_DIALOGUE.get_line(nature, line_idx),
			"portrait": _portrait_for_speaker(display),
			"tint": tint,
			"talking_label": f.get("talking_label"),
		})
	return out


func _show_dialogue_stage() -> void:
	if _npc_hud == null or _npc_talk_target.is_empty():
		return
	if _dialogue_stage == 0:
		var has_more := not _dialogue_reactions.is_empty()
		_npc_hud.open(str(_npc_talk_target["name"]), str(_npc_talk_target["dialogue"]),
			"NEXT" if has_more else "CLOSE")
		_npc_hud.set_portrait(_portrait_for_speaker(str(_npc_talk_target["name"])))
	else:
		if _dialogue_stage > _dialogue_reactions.size():
			return
		var reaction: Dictionary = _dialogue_reactions[_dialogue_stage - 1]
		var has_more := _dialogue_stage < _dialogue_reactions.size()
		if _dialogue_stage - 1 < _dialogue_banners.size():
			var banner: Control = _dialogue_banners[_dialogue_stage - 1]
			if banner != null:
				banner.open(str(reaction["name"]), str(reaction["text"]),
					reaction.get("portrait") as Texture2D,
					reaction.get("tint", Color(0.14, 0.23, 0.15)))
		_npc_hud.set_next_text("NEXT" if has_more else "CLOSE")
	_update_talking_labels()


func _npc_portrait(npc_name: String) -> Texture2D:
	return _portrait_for_speaker(npc_name)


func _circular_portrait(tex: Texture2D, region: Rect2) -> Texture2D:
	# D-1093: o recorte já sai circular; o AtlasTexture + shader de máscara
	# desalinhava e deixava o quadrado vazar do medalhão.
	var img := tex.get_image()
	if img == null:
		return tex
	var full := Rect2i(Vector2i.ZERO, img.get_size())
	var px := Rect2i(
		int(region.position.x * img.get_width()),
		int(region.position.y * img.get_height()),
		int(region.size.x * img.get_width()),
		int(region.size.y * img.get_height()))
	px = px.intersection(full)
	if px.size.x < 2 or px.size.y < 2:
		return tex
	var face := img.get_region(px)
	face.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	# D-1095: o fundo do medalhão é cozido em dourado e o RGB de fora do
	# círculo também fica dourado. Antes o transparente era preto e a borda
	# da máscara puxava a "borda interna marrom" entre o fundo e o retrato.
	var brown := Color(92.0 / 255.0, 60.0 / 255.0, 30.0 / 255.0, 1.0)
	var canvas := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	canvas.fill(brown)
	canvas.blend_rect(face, Rect2i(0, 0, 256, 256), Vector2i.ZERO)
	var center := Vector2(127.5, 127.5)
	var radius := 124.0
	for y in 256:
		for x in 256:
			var d := Vector2(float(x), float(y)).distance_to(center)
			var a := clampf((radius - d) / 1.5, 0.0, 1.0)
			if a >= 0.999:
				continue
			var c := canvas.get_pixel(x, y)
			c.a = a
			canvas.set_pixel(x, y, c)
	return ImageTexture.create_from_image(canvas)


func _portrait_for_speaker(speaker: String) -> Texture2D:
	var key := speaker.to_lower()
	# D-1095: ícone fechado do Bulbasaur, já mascarado e com o fundo do medalhão.
	# Ícone único das HUDs (recorte Sugimori + fundo ciano-verde): scripts/ui/portrait_icon.gd.
	var icon: Texture2D = preload("res://scripts/ui/portrait_icon.gd").get_icon(key)
	if icon == null:
		return null
	return _circular_portrait(icon, Rect2(0.0, 0.0, 1.0, 1.0))


func _update_enemy_ring_color() -> void:
	if _enemy_ring_entry.is_empty():
		return
	var mesh := _enemy_ring_entry.get("mesh") as MeshInstance3D
	if mesh == null or not is_instance_valid(mesh):
		return
	var mat := _enemy_ring_entry.get("mat") as ShaderMaterial
	if mat == null:
		return
	var wants_talk := false
	if _enemy_body != null and is_instance_valid(_enemy_body):
		wants_talk = bool(_enemy_body.get_meta("wants_to_talk", false))
	var color: Color
	if _enemy_alert_timer > 0.0:
		color = Color(1.0, 0.82, 0.15, 0.85)  # alerta (!)
	elif wants_talk or _enemy_state == EnemyState.FLEE:
		color = Color(0.22, 0.48, 1.0, 0.78)  # fugindo ou quer conversar
	elif _enemy_state == EnemyState.CHASE:
		color = Color(0.95, 0.15, 0.15, 0.80)  # indo atrás de você
	elif _enemy_state == EnemyState.SEARCH:
		color = Color(1.0, 0.82, 0.15, 0.85)  # procurando
	else:
		color = Color(1.0, 0.62, 0.15, 0.45)  # patrulha/return: âmbar
	mat.set_shader_parameter("ring_color", color)


func _update_enemy_icon() -> void:
	if _enemy_icon_entry.is_empty():
		return
	var sprite := _enemy_icon_entry["sprite"] as Sprite3D
	if sprite == null:
		return
	var state := "none"
	var tex: Texture2D = null
	var tint := Color.WHITE
	if _enemy_alert_timer > 0.0:
		state = "alert"
		tex = ICON_ALERT
		tint = Color(1.0, 0.85, 0.25)
	elif _enemy_state == EnemyState.CHASE:
		state = "anger"
		tex = ICON_ANGER
		tint = Color(1.0, 0.45, 0.35)
	elif _enemy_state == EnemyState.FLEE:
		state = "sweat"
		tex = ICON_SWEAT
		tint = Color(0.55, 0.85, 1.0)
	elif _enemy_state == EnemyState.SEARCH:
		state = "search"
		tex = ICON_QUESTION
		tint = Color(1.0, 0.45, 0.45)
	if tex == null:
		sprite.visible = false
		_enemy_icon_entry["state"] = "none"
		return
	sprite.visible = true
	_set_icon(_enemy_icon_entry, state, tex, tint)


func cycle_npcs(new_offset: int) -> void:
	_npc_offset = posmod(new_offset, NPC_POOL.size())
	if _npc_prompt != null:
		_npc_prompt.hide_prompt()
	_close_npc_dialogue()
	for npc in _npcs:
		var node: Node3D = npc["node"]
		if is_instance_valid(node):
			node.queue_free()
	_npcs.clear()
	# Remove marcadores antigos de NPC no mini-mapa.
	for i in range(_minimap_markers.size() - 1, -1, -1):
		if _minimap_markers[i]["kind"] == "npc":
			var rect: Control = _minimap_markers[i]["rect"]
			if is_instance_valid(rect):
				rect.queue_free()
			_minimap_markers.remove_at(i)
	for slot_i in NPC_SLOTS.size():
		var pool_idx := (_npc_offset + slot_i) % NPC_POOL.size()
		_spawn_npc_at_slot(slot_i, pool_idx)
	for npc in _npcs:
		var node: Node3D = npc["node"]
		_apply_toon(node)
		_set_layers(node, 1 << 6)
		_decorate_npc(npc)
		if _marker_root != null:
			_add_minimap_marker(node, Color(1.0, 1.0, 1.0, 1.0), "npc")


func _build_npc_dialogue_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 22
	layer.add_to_group("overworld_hud")
	_npc_dialogue_panel = PanelContainer.new()
	_npc_dialogue_panel.position = Vector2(260, 540)
	_npc_dialogue_panel.custom_minimum_size = Vector2(760, 108)
	_npc_dialogue_panel.visible = false
	_npc_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.04, 0.92)
	style.border_color = Color(0.65, 0.88, 0.68, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_npc_dialogue_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_dialogue_panel.add_child(vbox)

	_npc_dialogue_title = Label.new()
	_npc_dialogue_title.text = "NPC"
	_npc_dialogue_title.add_theme_font_size_override("font_size", 17)
	_npc_dialogue_title.add_theme_color_override("font_color", Color(0.75, 1.0, 0.72))
	_npc_dialogue_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_npc_dialogue_title)

	_npc_dialogue_text = Label.new()
	_npc_dialogue_text.text = ""
	_npc_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_npc_dialogue_text.custom_minimum_size = Vector2(720, 52)
	_npc_dialogue_text.add_theme_font_size_override("font_size", 15)
	_npc_dialogue_text.add_theme_color_override("font_color", Color(0.95, 0.94, 0.88))
	_npc_dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_npc_dialogue_text)

	layer.add_child(_npc_dialogue_panel)

	# Opção C aprovada: GLIFO no lugar do prompt [Z] ATTACK.
	_attack_hud = ATTACK_HUD.new()
	_attack_hud.name = "AttackHud"
	layer.add_child(_attack_hud)
	_attack_hud.call("set_mode", 2)
	_attack_hud.call("set_context", "", 0.0, 2)
	_attack_hud.visible = false

	# D-1085: prompt torto [Z] TALK, separado do prompt da porta.
	_npc_prompt = NPC_PROMPT.new()
	layer.add_child(_npc_prompt)
	_npc_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_npc_prompt.offset_left = -190.0
	_npc_prompt.offset_top = -68.0
	_npc_prompt.offset_right = 190.0
	_npc_prompt.offset_bottom = -10.0
	_npc_prompt.visible = false

	# D-1090: HUD C (Paper/RPG) no diálogo real; A/B ficam no lab de protótipos.
	_npc_hud = NPC_HUD.new()
	layer.add_child(_npc_hud)
	_npc_hud.setup(2)
	_npc_hud.close()

	# D-1092: uma faixa lateral por aliado, acima do card do NPC.
	_battle_hud = get_node_or_null("ExplorationBattleHud")
	for i in _followers.size():
		var banner = ALLY_BANNER.new()
		banner.name = "AllyBanner%d" % i
		layer.add_child(banner)
		banner.setup(i)
		banner.close()
		_dialogue_banners.append(banner)
	add_child(layer)


func _close_npc_dialogue() -> void:
	_npc_talking = false
	_dialogue_stage = 0
	_dialogue_reactions.clear()
	if _npc_dialogue_panel != null:
		_npc_dialogue_panel.visible = false
	if _npc_hud != null:
		_npc_hud.close()
	for banner in _dialogue_banners:
		if banner != null:
			banner.close()
	clear_dialogue_focus()
	if _battle_hud != null:
		_battle_hud.set_dialogue_open(false)
	_update_talking_labels()


func _update_npcs(delta: float) -> void:
	if player == null:
		return
	var interact_now := Input.is_action_pressed("lab_interact")
	var interact_just := interact_now and not _interact_prev
	_interact_prev = interact_now
	# D-1127: só Z ataca. E continua interagindo/falando quando não há inimigo.
	var z_now := Input.is_physical_key_pressed(KEY_Z)
	var z_just := z_now and not _z_prev
	_z_prev = z_now
	var nearest_npc: Dictionary = {}
	var nearest_dist := INF
	for npc in _npcs:
		var body: Node3D = npc["node"]
		if not is_instance_valid(body):
			continue
		_update_npc_icon(npc)
		var talking_now: bool = _npc_talking and _dialogue_stage == 0 and _npc_talk_target.get("node") == body
		if npc.has("talking_label") and is_instance_valid(npc["talking_label"]):
			npc["talking_label"].visible = talking_now
		var icon_sprite = npc.get("icon_entry", {}).get("sprite")
		if icon_sprite != null and is_instance_valid(icon_sprite):
			icon_sprite.visible = not talking_now
		_play_idle(npc["ap"])
		var to_player := player.global_position - body.global_position
		to_player.y = 0.0
		var dist := to_player.length()
		if dist < NPC_LOOK_RADIUS and dist > 0.05:
			var target_yaw := atan2(to_player.x, to_player.z)
			body.rotation.y = lerp_angle(body.rotation.y, target_yaw, clampf(delta * 6.5, 0.0, 1.0))
		else:
			body.rotation.y = lerp_angle(body.rotation.y, float(npc["base_yaw"]), clampf(delta * 3.0, 0.0, 1.0))
		if dist < NPC_INTERACT_RADIUS and dist < nearest_dist:
			nearest_dist = dist
			nearest_npc = npc

	# D-1100/D-1127: an enemy inside 4.5 m owns the contextual prompt and Z;
	# it wins over the NPC/door. E is not an attack button.
	var nearest_npc_node: Node3D = null
	if not nearest_npc.is_empty():
		nearest_npc_node = nearest_npc.get("node") as Node3D
	if _attack_controller != null:
		_attack_controller.set_npc_near(nearest_npc_node)
		_attack_controller.set_interact_blocked(_npc_talking)
		# D-1136: Z ataca a qualquer momento, com ou sem alvo.
		if z_just and not _npc_talking:
			_attack_controller.attack_anytime()
			if _attack_hud != null:
				_attack_hud.call("play_press")
		if _attack_controller.has_attack_target() and not _npc_talking:
			if _npc_prompt != null:
				_npc_prompt.hide_prompt()
			return

	if nearest_npc.is_empty():
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
		_close_npc_dialogue()
		return

	# D-1136: Z ataca; falar com NPC é só E. A porta tem o prompt dela.
	if _door_near or _npc_talking:
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
	elif _npc_prompt != null:
		_npc_prompt.show_prompt(str(nearest_npc["name"]), "TALK", false, "E")
	if interact_just and not _door_near:
		if _npc_talking and _npc_talk_target.get("node") == nearest_npc.get("node"):
			if _npc_hud != null and _npc_hud.is_typing():
				_npc_hud.finish_typing()
			elif _dialogue_stage < _dialogue_reactions.size():
				_dialogue_stage += 1
				_show_dialogue_stage()
			else:
				_close_npc_dialogue()
		else:
			_npc_talking = true
			_npc_talk_target = nearest_npc
			nearest_npc["talked"] = true
			_update_npc_icon(nearest_npc)
			_dialogue_stage = 0
			_dialogue_reactions = _build_ally_reactions()
			_show_dialogue_stage()
			set_dialogue_focus(nearest_npc["node"] as Node3D)
			if _battle_hud != null:
				_battle_hud.set_dialogue_open(true)


# --- Minimap -----------------------------------------------------------------

func _build_minimap_map() -> void:
	# Cópias chapadas do piso/paredes/pilares na camada 5: só o mini-mapa vê.
	var floor_col := Color(0.42, 0.27, 0.50)
	var wall_col := Color(0.10, 0.26, 0.23)
	var trunk_col := Color(0.16, 0.12, 0.18)
	_minimap_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, -0.2, -4.0), floor_col)
	_minimap_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -10.0), floor_col)
	_minimap_box(Vector3(14.0, 0.4, 12.0), Vector3(11.0, -0.2, 0.0), floor_col)
	_minimap_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -18.0), floor_col)
	for data in [
		[Vector3(8.5, FOREST_WALL_HEIGHT, 0.5), Vector3(0.0, FOREST_WALL_HEIGHT * 0.5, 6.25)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 20.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -4.0)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, 0.0)],
		[Vector3(3.25, FOREST_WALL_HEIGHT, 0.5), Vector3(-2.625, FOREST_WALL_HEIGHT * 0.5, -14.25)],
		[Vector3(5.0, FOREST_WALL_HEIGHT, 0.5), Vector3(3.5, FOREST_WALL_HEIGHT * 0.5, -14.25)],
		[Vector3(5.0, FOREST_WALL_HEIGHT, 0.5), Vector3(10.5, FOREST_WALL_HEIGHT * 0.5, -14.25)],
		[Vector3(3.25, FOREST_WALL_HEIGHT, 0.5), Vector3(16.625, FOREST_WALL_HEIGHT * 0.5, -14.25)],
		[Vector3(4.25, FOREST_WALL_HEIGHT, 0.5), Vector3(5.875, FOREST_WALL_HEIGHT * 0.5, -5.75)],
		[Vector3(7.25, FOREST_WALL_HEIGHT, 0.5), Vector3(14.625, FOREST_WALL_HEIGHT * 0.5, -5.75)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -10.0)],
		[Vector3(14.0, FOREST_WALL_HEIGHT, 0.5), Vector3(11.25, FOREST_WALL_HEIGHT * 0.5, 6.25)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, 0.0)],
		[Vector3(22.5, FOREST_WALL_HEIGHT, 0.5), Vector3(7.0, FOREST_WALL_HEIGHT * 0.5, -22.25)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -18.0)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -18.0)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 3.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, -20.5)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 3.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, -15.5)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 3.0), Vector3(10.25, FOREST_WALL_HEIGHT * 0.5, -20.5)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 3.0), Vector3(10.25, FOREST_WALL_HEIGHT * 0.5, -15.5)],
	]:
		_minimap_box(data[0], data[1], wall_col)
	for p in [
		Vector2(-3.0, -2.0), Vector2(3.0, -7.0),
		Vector2(7.0, -13.0), Vector2(13.0, -7.0),
	]:
		_minimap_box(Vector3(0.55, FOREST_WALL_HEIGHT, 0.55),
			Vector3(p.x, FOREST_WALL_HEIGHT * 0.5, p.y), trunk_col)
	# Saída verde no mapa.
	_minimap_box(Vector3(0.7, 0.2, 3.0), Vector3(17.7, 0.1, -10.0), Color(0.25, 1.0, 0.45))


func _minimap_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mi.material_override = mat
	mi.layers = 1 << 4
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_minimap() -> void:
	# Os marcadores são bolinhas de UI (sem textura): azul, branco e vermelho.
	_minimap_viewport = SubViewport.new()
	_minimap_viewport.size = Vector2i(MINIMAP_SIZE, MINIMAP_SIZE)
	_minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_minimap_viewport.own_world_3d = false
	add_child(_minimap_viewport)
	_minimap_viewport.world_3d = get_world_3d()

	_minimap_camera = Camera3D.new()
	_minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_minimap_camera.size = MINIMAP_WORLD_SIZE
	_minimap_camera.near = 0.1
	_minimap_camera.far = 60.0
	_minimap_camera.cull_mask = 1 << 4
	_minimap_camera.current = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.008, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_minimap_camera.environment = env
	_minimap_camera.position = Vector3(0.0, 30.0, 0.0)
	_minimap_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_minimap_viewport.add_child(_minimap_camera)

	var layer := CanvasLayer.new()
	layer.layer = 15
	layer.add_to_group("overworld_hud")
	var border := ColorRect.new()
	border.color = Color(0.48, 0.40, 0.22, 0.95)
	border.position = Vector2(1150, 12)
	border.size = Vector2(120, 120)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(border)
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.008, 0.02, 1.0)
	bg.position = Vector2(1152, 14)
	bg.size = Vector2(116, 116)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)
	_minimap_rect = TextureRect.new()
	_minimap_rect.texture = _minimap_viewport.get_texture()
	_minimap_rect.position = Vector2(1154, 16)
	_minimap_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_minimap_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_minimap_rect.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	_minimap_rect.scale = Vector2(
		float(MINIMAP_DISPLAY_SIZE) / float(MINIMAP_SIZE),
		float(MINIMAP_DISPLAY_SIZE) / float(MINIMAP_SIZE))
	_minimap_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_minimap_rect)
	_marker_root = Control.new()
	_marker_root.position = Vector2(1154, 16)
	_marker_root.size = Vector2(MINIMAP_DISPLAY_SIZE, MINIMAP_DISPLAY_SIZE)
	_marker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_marker_root)
	add_child(layer)

	_add_minimap_marker(player, Color(0.25, 0.55, 1.0, 1.0), "player")
	for f in _followers:
		_add_minimap_marker(f["node"], Color(0.25, 0.55, 1.0, 1.0), "ally")
	if _enemy_body != null:
		_add_minimap_marker(_enemy_body, Color(1.0, 0.22, 0.18, 1.0), "enemy")
	for node in get_tree().get_nodes_in_group("minimap_npc"):
		if node is Node3D:
			_add_minimap_marker(node, Color(1.0, 1.0, 1.0, 1.0), "npc")


func _add_minimap_marker(node: Node3D, color: Color, kind: String) -> void:
	var dot_size := 10.0
	match kind:
		"player":
			dot_size = 12.0
		"ally":
			dot_size = 8.0
		"npc":
			dot_size = 10.0
		_:
			dot_size = 10.0
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(dot_size, dot_size)
	dot.size = Vector2(dot_size, dot_size)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.02, 0.01, 0.02, 0.90)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var radius := int(dot_size * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	dot.add_theme_stylebox_override("panel", style)
	match kind:
		"player":
			dot.z_index = 4
		"ally":
			dot.z_index = 3
		"npc":
			dot.z_index = 2
		_:
			dot.z_index = 1
	_marker_root.add_child(dot)
	dot.size = Vector2(dot_size, dot_size)
	_minimap_markers.append({
		"node": node,
		"rect": dot,
		"size": dot_size,
		"kind": kind,
	})


func _build_hud_badges() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	layer.add_to_group("overworld_hud")
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(14, 76)
	vbox.size = Vector2(250, 260)
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vbox)
	# HP/MP demo: o lab não tem combate; a HUD final deve ler GameState.party.
	var badges := [
		["ABRA", 86, 100, 14, 20, false],
		["PANCHAM", 100, 100, 10, 20, true],
		["ORC", 46, 100, 8, 20, true],
	]
	for data in badges:
		vbox.add_child(_make_hud_badge(str(data[0]), int(data[1]), int(data[2]), int(data[3]), int(data[4]), bool(data[5])))
	_build_enemy_alert(layer)
	add_child(layer)


func _build_enemy_alert(layer: CanvasLayer) -> void:
	_enemy_alert = PanelContainer.new()
	_enemy_alert.custom_minimum_size = Vector2(42, 42)
	_enemy_alert.position = Vector2(760, 16)
	_enemy_alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_alert.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.02, 0.02, 0.88)
	style.border_color = Color(1.0, 0.25, 0.18, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_enemy_alert.add_theme_stylebox_override("panel", style)
	var bang := Label.new()
	bang.text = "!"
	bang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bang.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bang.add_theme_font_size_override("font_size", 26)
	bang.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	bang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_alert.add_child(bang)
	layer.add_child(_enemy_alert)


func _make_hud_badge(character_name: String, hp: int, max_hp: int, mp: int, max_mp: int, is_ally: bool) -> PanelContainer:
	var ratio := float(hp) / float(max_hp)
	var color := _hp_color(ratio)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 70)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.025, 0.02, 0.88)
	style.border_color = Color(0.55, 0.45, 0.22, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var accent := ColorRect.new()
	accent.color = color
	accent.custom_minimum_size = Vector2(4, 56)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = character_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(hp_row)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = float(max_hp)
	bar.value = float(hp)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(140, 9)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.07, 0.055, 0.045, 0.95)
	bar_bg.corner_radius_top_left = 2
	bar_bg.corner_radius_top_right = 2
	bar_bg.corner_radius_bottom_left = 2
	bar_bg.corner_radius_bottom_right = 2
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = color
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", bar_bg)
	bar.add_theme_stylebox_override("fill", bar_fill)
	hp_row.add_child(bar)
	var hp_label := Label.new()
	hp_label.text = "%d / %d" % [hp, max_hp]
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.78, 0.75, 0.66))
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_label)

	var mp_row := HBoxContainer.new()
	mp_row.add_theme_constant_override("separation", 6)
	mp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(mp_row)
	var mp_color := Color(0.35, 0.65, 1.0)
	var mp_bar := ProgressBar.new()
	mp_bar.min_value = 0.0
	mp_bar.max_value = float(max_mp)
	mp_bar.value = float(mp)
	mp_bar.show_percentage = false
	mp_bar.custom_minimum_size = Vector2(140, 7)
	mp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	mp_bg.corner_radius_top_left = 2
	mp_bg.corner_radius_top_right = 2
	mp_bg.corner_radius_bottom_left = 2
	mp_bg.corner_radius_bottom_right = 2
	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = mp_color
	mp_fill.corner_radius_top_left = 2
	mp_fill.corner_radius_top_right = 2
	mp_fill.corner_radius_bottom_left = 2
	mp_fill.corner_radius_bottom_right = 2
	mp_bar.add_theme_stylebox_override("background", mp_bg)
	mp_bar.add_theme_stylebox_override("fill", mp_fill)
	mp_row.add_child(mp_bar)
	var mp_label := Label.new()
	mp_label.text = "%d / %d" % [mp, max_mp]
	mp_label.add_theme_font_size_override("font_size", 9)
	mp_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.92))
	mp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_row.add_child(mp_label)

	_hud_badges.append({
		"panel": panel,
		"bar": bar,
		"hp_label": hp_label,
		"mp_bar": mp_bar,
		"mp_label": mp_label,
		"ally": is_ally,
	})
	return panel


func _hp_color(ratio: float) -> Color:
	if ratio <= 0.25:
		return Color(0.90, 0.25, 0.20)
	if ratio <= 0.50:
		return Color(0.95, 0.75, 0.20)
	return Color(0.25, 0.90, 0.40)


func _update_hud_badges() -> void:
	for badge in _hud_badges:
		if bool(badge["ally"]):
			(badge["panel"] as Control).visible = _party_visible
	if _enemy_alert != null:
		_enemy_alert.visible = _enemy_state == EnemyState.CHASE
		if _enemy_alert.visible:
			_enemy_alert.modulate.a = 0.72 + 0.28 * sin(_time * 6.0)


func _update_attack_hud() -> void:
	if _attack_hud == null or _attack_controller == null or player == null or _camera == null:
		return
	var target := _attack_controller.get_attack_target() as Node3D
	var cooldown: float = _attack_controller.get_player_cooldown_ratio()
	var state := 0
	if target == null:
		state = 2
	elif cooldown > 0.01:
		state = 1
	var dist := 0.0
	if target != null:
		var flat := target.global_position - player.global_position
		flat.y = 0.0
		dist = flat.length()
	_attack_hud.call("set_context", _attack_target_name(target), dist, state, cooldown)
	_attack_hud.call("set_projection", _camera, player, target)
	_attack_hud.visible = not _npc_talking and target != null


func _attack_target_name(target: Node3D) -> String:
	if target == null:
		return ""
	if target == _enemy:
		return "SLIME"
	if target == _second_enemy:
		return "GIBLE"
	for child in target.find_children("*", "Label3D", true, false):
		if child.name == "Name":
			var label := child as Label3D
			if label != null and not label.text.is_empty():
				return label.text.to_upper()
	return target.name.to_upper()


func _update_minimap() -> void:
	if _minimap_camera == null or _minimap_rect == null or player == null:
		return
	_minimap_camera.global_position = player.global_position + Vector3(0.0, 30.0, 0.0)
	var vp := Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	var rect_size := _marker_root.size
	for m in _minimap_markers:
		var rect: Control = m["rect"]
		var node: Node3D = m["node"]
		var show := is_instance_valid(node)
		if show and m["kind"] == "ally" and not _party_visible:
			show = false
		if show:
			var world := node.global_position + Vector3(0.0, 0.7, 0.0)
			var view := _minimap_camera.unproject_position(world)
			var pos := Vector2(view.x / vp.x, view.y / vp.y) * rect_size
			if pos.x < 0.0 or pos.y < 0.0 or pos.x > rect_size.x or pos.y > rect_size.y:
				show = false
			else:
				rect.position = pos - Vector2(m["size"], m["size"]) * 0.5
		rect.visible = show


# --- Toon and render layers --------------------------------------------------

func _apply_toon(root: Node) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mi as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		if mesh_instance.material_override is BaseMaterial3D:
			var over := mesh_instance.material_override as BaseMaterial3D
			if over.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			var dup := over.duplicate(true) as BaseMaterial3D
			dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
			dup.rim_enabled = true
			dup.rim = 0.22
			dup.rim_tint = 0.35
			mesh_instance.material_override = dup
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var mat := mesh_instance.get_active_material(i)
			if not (mat is BaseMaterial3D):
				continue
			var base := mat as BaseMaterial3D
			if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			var dup := base.duplicate(true) as BaseMaterial3D
			dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
			dup.rim_enabled = true
			dup.rim = 0.22
			dup.rim_tint = 0.35
			mesh_instance.set_surface_override_material(i, dup)


func _set_actor_layers() -> void:
	_set_layers(player, 1 << 1)
	for f in _followers:
		_set_layers(f["node"], 1 << 2)
	if _enemy_body != null:
		_set_layers(_enemy_body, 1 << 3)
	for npc in _npcs:
		_set_layers(npc["node"], 1 << 6)


func _set_layers(root: Node, layer: int) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = layer
	for particles in root.find_children("*", "CPUParticles3D", true, false):
		(particles as CPUParticles3D).layers = layer
	for label in root.find_children("*", "Label3D", true, false):
		(label as Label3D).layers = layer
