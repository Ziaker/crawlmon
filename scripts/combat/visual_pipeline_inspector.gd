class_name VisualPipelineInspector
extends RefCounted
## Inspetor de Pipeline Visual do Crawlmon.
## Audita nós, malhas, materiais e shaders para garantir que nenhum placeholder
## quadrado (BoxMesh, PlaneMesh de trajeto ou QuadMesh com bounding box dura)
## seja instanciado durante o combate.

enum ViolationKind {
	ILLEGAL_GEOMETRY,
	INVALID_MATERIAL,
	MISSING_SHADER,
	SOLID_BLOCK_SUSPECT,
}

const DISALLOWED_VFX_MESH_CLASSES := ["BoxMesh", "PlaneMesh"]


## Audita uma subárvore inteira de nós 3D retornando uma lista de violações encontradas.
static func audit_tree(root_node: Node) -> Array[Dictionary]:
	var violations: Array[Dictionary] = []
	_audit_recursive(root_node, violations)
	return violations


static func _audit_recursive(node: Node, out_violations: Array[Dictionary]) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var m := mi.mesh
		if m != null:
			var mesh_class := m.get_class()
			# Checagem 1: Geometria proibida em efeitos de combate
			if mesh_class in DISALLOWED_VFX_MESH_CLASSES:
				out_violations.append({
					"node": mi.name,
					"kind": ViolationKind.ILLEGAL_GEOMETRY,
					"mesh": mesh_class,
					"details": "Malha proibida '%s' detectada no nó '%s'. Efeitos devem usar cilindros, toros, curvas 3D ou flipbooks." % [mesh_class, mi.name]
				})
			
			# Checagem 2: QuadMesh sem material ou sem transparência
			if mesh_class == "QuadMesh":
				var mat := mi.material_override
				if mat == null and m is QuadMesh and (m as QuadMesh).material != null:
					mat = (m as QuadMesh).material
				if mat == null:
					out_violations.append({
						"node": mi.name,
						"kind": ViolationKind.INVALID_MATERIAL,
						"mesh": mesh_class,
						"details": "QuadMesh '%s' sem material definido (renderizará como bloco sólido)." % mi.name
					})
				elif mat is StandardMaterial3D:
					var sm := mat as StandardMaterial3D
					if sm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
						out_violations.append({
							"node": mi.name,
							"kind": ViolationKind.SOLID_BLOCK_SUSPECT,
							"mesh": mesh_class,
							"details": "QuadMesh '%s' com transparência desativada (bloco opaco)." % mi.name
						})
					if sm.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES:
						out_violations.append({
							"node": mi.name,
							"kind": ViolationKind.INVALID_MATERIAL,
							"mesh": mesh_class,
							"details": "QuadMesh normal '%s' com BILLBOARD_PARTICLES (causa falha de vértice em GL_Compatibility)." % mi.name
						})

	for child in node.get_children():
		_audit_recursive(child, out_violations)


## Audita uma lista de nós e retorna se passou 100% limpo.
static func is_clean(nodes: Array[Node]) -> bool:
	for n in nodes:
		if is_instance_valid(n):
			var viols := audit_tree(n)
			if not viols.is_empty():
				return false
	return true
