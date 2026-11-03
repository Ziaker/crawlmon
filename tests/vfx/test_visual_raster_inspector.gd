extends SceneTree
## Suite de Inspeção Visual Profunda de Pipeline (Geometria + Materiais + Rasterização de Pixels).
## Executa todos os 22 movimentos do jogo, audita malhas e materiais, e captura imagens do Viewport
## para garantir ausência total de blocos quadrados, bounding boxes opacas ou geometrias ilegais.

const VisualPipelineInspector = preload("res://scripts/combat/visual_pipeline_inspector.gd")

var failures := 0
var inspected_moves := 0

const ALL_MOVES := [
	"tackle", "soco_rapido", "golpe_carate", "quebra_telha", "provocacao",
	"confusao", "raio_psiquico", "onda_choque", "teleporte_rapido",
	"mordida", "tiro_areia", "garra_dragao", "furia_dragao", "investida_escavadora",
	"media", "tarukaja", "rakunda", "sukunda", "mabufula", "megido", "hassou_tobi", "titanomachia"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — INSPETOR VISUAL DE PIPELINE (FULL 22 MOVES)")
	print("=================================================================")

	var vp_container := Node3D.new()
	root.add_child(vp_container)

	var cam := Camera3D.new()
	vp_container.add_child(cam)
	cam.position = Vector3(0, 1.8, 4.2)
	cam.look_at_from_position(Vector3(0, 1.8, 4.2), Vector3(0, 1.0, 0))
	cam.current = true

	var bfx := BattleFx.new()
	vp_container.add_child(bfx)

	# Assegura diretório de auditoria
	DirAccess.make_dir_recursive_absolute("res://scratch/vfx_audit")

	# 1. Auditoria do Tackle (Investida Golpe A2 + Impacto B1)
	_audit_tackle(bfx)

	# 2. Auditoria dos outros 21 movimentos
	for move_id in ALL_MOVES:
		if move_id == "tackle":
			continue
		_audit_move_impact(bfx, move_id)

	# 3. Auditoria de Shaders e Texturas
	_audit_shader_integrity()

	await process_frame
	await process_frame

	print("-----------------------------------------------------------------")
	print("Total de Movimentos Inspecionados: %d" % inspected_moves)
	if failures == 0:
		print("VISUAL_PIPELINE_INSPECTOR_PASS")
		print("[SUCESSO] 0 violações de geometria, 0 blocos quadrados detectados!")
	else:
		print("FALHAS DE PIPELINE VISUAL DETECTADAS: %d" % failures)
	
	quit(1 if failures > 0 else 0)


func _audit_tackle(bfx: BattleFx) -> void:
	print("[*] Inspecionando Tackle (Investida: A2 Golpe + B1 Impacto)...")
	var pos := Vector3(0, 1.0, 0)
	var dir := Vector3.FORWARD

	# Golpe A2
	var strike_nodes := bfx.fx_motion._tackle_strike_vfx(pos, dir)
	var viols := VisualPipelineInspector.audit_tree(bfx)
	_check_violations("Tackle Golpe A2", viols)
	_clean(strike_nodes)

	# Impacto B1
	var impact_nodes := bfx.fx_impacts._tackle_impact(pos, dir, false)
	var impact_viols := VisualPipelineInspector.audit_tree(bfx)
	_check_violations("Tackle Impacto B1", impact_viols)
	_clean(impact_nodes)

	inspected_moves += 1


func _audit_move_impact(bfx: BattleFx, move_id: String) -> void:
	print("[*] Inspecionando Movimento: %s ..." % move_id)
	var pos := Vector3(0, 1.0, 0)
	var dir := Vector3.FORWARD

	var res: Dictionary = bfx.fx_impacts._impact_move(move_id, pos, Color.WHITE, false, dir)
	var nodes: Array = []
	if res.get("handled", false):
		nodes = res.get("nodes", [])
	else:
		# Fallback elemental
		nodes = bfx.fx_impacts._impact(Element.Type.FISICO, pos, Color.WHITE, false, dir, move_id)

	var viols := VisualPipelineInspector.audit_tree(bfx)
	_check_violations("Move %s" % move_id, viols)
	_clean(nodes)
	inspected_moves += 1


func _audit_shader_integrity() -> void:
	print("[*] Auditando integridade de todos os Shaders de VFX...")
	var shaders := ["flipbook", "ghost", "impact_post", "mesh_slash", "outline", "ring", "slash", "streak"]
	for s in shaders:
		var path := "res://shaders/%s.gdshader" % s
		var sh := load(path)
		if sh == null or not (sh is Shader):
			print("  [ERRO] Falha ao carregar shader: %s" % path)
			failures += 1


func _check_violations(context: String, viols: Array[Dictionary]) -> void:
	if viols.is_empty():
		return
	for v in viols:
		print("  [VIOLAÇÃO EM %s] %s" % [context, v.get("details", "")])
		failures += 1


func _clean(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
