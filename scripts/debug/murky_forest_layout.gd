class_name MurkyForestLayout
extends Node3D

## Planta autoral da Murky Forest (D-1256): um unico mapa, em dados explicitos,
## sem geracao procedural. Escala: 1 unidade = 1 metro (D-1028).
##
## Formato aberto, estilo Kingdom Hearts 2/3 (pedido do criador): clareiras
## largas e exploraveis, poucas paredes - apenas perimetro e divisorias curtas -
## linhas de visao longas e o arco (marco) visivel de longe. Os corredores
## estreitos foram removidos: o que delimita as areas e o espaco entre paredes,
## nao portas de 3 m fechando passagens.
##
## Nada depende de personagem, time ou lado (D-235).

const H := 4.2
const NAV_Y := 0.05

## Ordem do grafo aprovado (plano secao 3.1).
const ROOM_ORDER: Array[String] = [
	"entrada", "corredor_arco", "dossel", "nicho_opcional",
	"abrigo", "ciclos_amuleto", "orc", "saida",
]

## Clareiras amplas: center em y=0, size ja com a espessura do piso (D-1256).
const ROOMS: Array[Dictionary] = [
	{"name": "entrada", "center": Vector3(0.0, 0.0, -2.0), "size": Vector3(26.0, 0.4, 24.0)},
	{"name": "corredor_arco", "center": Vector3(0.0, 0.0, -24.0), "size": Vector3(26.0, 0.4, 20.0)},
	{"name": "dossel", "center": Vector3(-16.0, 0.0, -2.0), "size": Vector3(12.0, 0.4, 24.0)},
	{"name": "nicho_opcional", "center": Vector3(-22.0, 0.0, -14.0), "size": Vector3(8.0, 0.4, 10.0)},
	{"name": "abrigo", "center": Vector3(16.0, 0.0, -2.0), "size": Vector3(12.0, 0.4, 24.0)},
	{"name": "ciclos_amuleto", "center": Vector3(-9.0, 0.0, -34.0), "size": Vector3(14.0, 0.4, 12.0)},
	{"name": "orc", "center": Vector3(9.0, 0.0, -34.0), "size": Vector3(14.0, 0.4, 12.0)},
	{"name": "saida", "center": Vector3(0.0, 0.0, -34.0), "size": Vector3(1.0, 0.4, 1.0)},
]

## Paredes: 8 caixas, apenas perimetro e divisorias curtas. Pos em y=H*0.5
## (D-1028). Sem paredes internas longas: a abertura e o espaco entre elas.
const WALLS: Array[Dictionary] = [
	{"size": Vector3(26.0, H, 0.5), "pos": Vector3(0.0, H * 0.5, 10.25), "mat": 0},
	{"size": Vector3(0.5, H, 50.0), "pos": Vector3(-26.25, H * 0.5, -15.0), "mat": 1},
	{"size": Vector3(0.5, H, 50.0), "pos": Vector3(26.25, H * 0.5, -15.0), "mat": 5},
	{"size": Vector3(26.0, H, 0.5), "pos": Vector3(0.0, H * 0.5, -41.25), "mat": 3},
	{"size": Vector3(10.0, H, 0.5), "pos": Vector3(-21.0, H * 0.5, -34.25), "mat": 3},
	{"size": Vector3(10.0, H, 0.5), "pos": Vector3(21.0, H * 0.5, -34.25), "mat": 3},
	{"size": Vector3(0.5, H, 8.0), "pos": Vector3(-16.0, H * 0.5, -26.0), "mat": 2},
	{"size": Vector3(0.5, H, 8.0), "pos": Vector3(16.0, H * 0.5, -26.0), "mat": 2},
]

## Pilares de tronco: ritmo vertical no meio da clareira, nunca parede.
## Posicoes autorais em XZ (y vem de H).
const PILLARS: Array[Vector2] = [
	Vector2(-6.0, -6.0),
	Vector2(6.0, -6.0),
	Vector2(-6.0, -18.0),
	Vector2(6.0, -18.0),
	Vector2(-12.0, -2.0),
	Vector2(12.0, -2.0),
	Vector2(-3.0, -30.0),
	Vector2(3.0, -30.0),
]

const PILLAR_SIZE := Vector3(0.7, H, 0.7)

## Vaos amplos de ligacao (D-1245 so mede quando ha porta; aqui sao aberturas
## largas entre paredes, mantidas como dado para checagem/teleporte).
const DOORS: Array[Dictionary] = [
	{"id": "arco", "axis": "x", "value": -34.0, "min": -2.0, "max": 2.0},
	{"id": "oeste", "axis": "z", "value": -12.0, "min": -4.0, "max": 4.0},
	{"id": "leste", "axis": "z", "value": 12.0, "min": -4.0, "max": 4.0},
]

## Constroi a planta com os materiais recebidos. Nada depende de personagem,
## time ou lado (D-235).
func build(floor_mat: Material, wall_mats: Array, trunk_mat: Material) -> void:
	# Pisos: so malha. A colisao do chao fica com o _box da cena (D-1256).
	for room in ROOMS:
		var room_name := String(room["name"])
		if room_name == "saida":
			continue
		var floor_mesh := MeshInstance3D.new()
		var floor_box := BoxMesh.new()
		floor_box.size = room["size"] as Vector3
		floor_mesh.mesh = floor_box
		floor_mesh.material_override = floor_mat
		floor_mesh.position = room["center"] as Vector3
		floor_mesh.name = "Piso_%s" % room_name
		add_child(floor_mesh)

	# Paredes com colisao (D-1028).
	for i in WALLS.size():
		var wall: Dictionary = WALLS[i]
		var wall_mesh := _box(
				wall["size"] as Vector3,
				wall["pos"] as Vector3,
				wall_mats[int(wall["mat"])] as Material)
		wall_mesh.name = "Parede_%02d" % (i + 1)

	# Pilares de tronco, com colisao.
	for i in PILLARS.size():
		var p: Vector2 = PILLARS[i]
		var pillar_mesh := _box(PILLAR_SIZE, Vector3(p.x, H * 0.5, p.y), trunk_mat)
		pillar_mesh.name = "Pilar_%02d" % (i + 1)

## Navmesh explicita da planta aberta: 16 vertices, poligonos em y=NAV_Y,
## winding horario em XZ (area negativa). Sem geracao procedural (D-1256).
## A malha e conectada: os poligonos compartilham arestas de ponta a ponta.
func build_navmesh() -> NavigationMesh:
	var nav := NavigationMesh.new()
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	nav.agent_radius = 0.45
	nav.agent_height = 2.1

	var verts := PackedVector3Array([
		Vector3(-13.0, NAV_Y, 10.0),    # 0
		Vector3(13.0, NAV_Y, 10.0),     # 1
		Vector3(13.0, NAV_Y, -12.0),    # 2
		Vector3(-13.0, NAV_Y, -12.0),   # 3
		Vector3(-25.0, NAV_Y, 10.0),    # 4
		Vector3(-25.0, NAV_Y, -12.0),   # 5
		Vector3(25.0, NAV_Y, 10.0),     # 6
		Vector3(25.0, NAV_Y, -12.0),    # 7
		Vector3(-13.0, NAV_Y, -14.0),   # 8
		Vector3(13.0, NAV_Y, -14.0),    # 9
		Vector3(-16.0, NAV_Y, -26.0),   # 10
		Vector3(16.0, NAV_Y, -26.0),    # 11
		Vector3(-16.0, NAV_Y, -40.0),   # 12
		Vector3(16.0, NAV_Y, -40.0),    # 13
		Vector3(-3.0, NAV_Y, -40.0),    # 14
		Vector3(3.0, NAV_Y, -40.0),     # 15
	])
	nav.set_vertices(verts)

	var polygons: Array[PackedInt32Array] = [
		PackedInt32Array([0, 1, 2, 3]),      # clareira de entrada (x -13..13, z 10..-12)
		PackedInt32Array([4, 0, 3, 5]),      # ala oeste (-25..-13)
		PackedInt32Array([1, 6, 7, 2]),      # ala leste (13..25)
		PackedInt32Array([3, 2, 9, 8]),      # passagem do arco (-13..13, z -12..-14)
		PackedInt32Array([8, 9, 11, 10]),    # area do arco (-16..16, z -14..-26)
		PackedInt32Array([10, 11, 13, 12]),  # area sul (-16..16, z -26..-40)
		# Vertices 14/15 (vao central) ficam sem poligono proprio: sao colineares
		# em z=-40 e o poligono acima ja cobre toda a faixa sul.
	]

	for i in polygons.size():
		var poly: PackedInt32Array = polygons[i]
		var area := _signed_area_xz(verts, poly)
		# Poligonos colineares (area zero) nao entram na malha; os de area
		# positiva tem a ordem dos vertices invertida para ficarem horarios.
		if absf(area) < 0.001:
			continue
		if area > 0.0:
			poly = _reversed_winding(poly)
		nav.add_polygon(poly)

	return nav

## Nomes das salas na ordem do grafo aprovado (nao na ordem de declaracao).
func room_names() -> Array[String]:
	var names: Array[String] = []
	names.assign(ROOM_ORDER)
	return names

## Area com sinal do poligono no plano XZ (shoelace). Negativa = horario.
func _signed_area_xz(verts: PackedVector3Array, poly: PackedInt32Array) -> float:
	var total := 0.0
	var count := poly.size()
	for i in count:
		var a := verts[poly[i]]
		var b := verts[poly[(i + 1) % count]]
		total += a.x * b.z - b.x * a.z
	return total * 0.5

## Inverte a ordem dos vertices para corrigir o winding do poligono.
func _reversed_winding(poly: PackedInt32Array) -> PackedInt32Array:
	var flipped := PackedInt32Array()
	var count := poly.size()
	flipped.resize(count)
	for i in count:
		flipped[i] = poly[count - 1 - i]
	return flipped

## Helper: MeshInstance3D + BoxMesh + material_override, filho de self.
## A colisao e uma BoxShape3D explicita (StaticBody3D + CollisionShape3D):
## create_trimesh_collision() foi removido porque o processo varre malhas que
## nao sao trimesh (QuadMesh da vignette, discos, folhagem) e aborta com
## "Nonexistent function surface_get_array_len in base QuadMesh".
func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	add_child(mesh_instance)
	var body := StaticBody3D.new()
	body.name = "Body"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	mesh_instance.add_child(body)
	return mesh_instance
