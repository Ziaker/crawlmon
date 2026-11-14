extends Node3D

const CRYSTAL_SHADER := preload("res://content/moves/mabufula/crystal.gdshader")

const SPECS := [
	[0.65, 3.6, 0.0, 0.0, 0.08, -0.05],
	[0.48, 2.6, -0.55, 0.35, 0.22, 0.32],
	[0.52, 2.8, 0.58, 0.25, 0.18, -0.35],
	[0.42, 2.2, -0.38, -0.52, -0.28, 0.22],
	[0.45, 2.4, 0.42, -0.45, -0.25, -0.28],
]

const GROUP_COUNT := 5
const GROUP_SCALE := 0.85
const GROUP_SCALE_MID := 1.18
const GROUP_SCALE_INDEX := 2
const LIFETIME_START := 0.42
const LIFETIME_STEP := 0.11
const LIFETIME_END := 1.55
const EASE_IN_SPAN := 0.18
const SWAY_SPAN := 0.25
const SWAY_AMPLITUDE := 0.06

var _groups: Array[Node3D] = []
var _base_scales: Array[float] = []

func setup(_camera: Camera3D) -> void:
	for g in GROUP_COUNT:
		var group := Node3D.new()
		group.name = "Group%d" % g
		var base_scale := GROUP_SCALE_MID if g == GROUP_SCALE_INDEX else GROUP_SCALE
		group.scale = Vector3.ONE * base_scale
		group.visible = false
		add_child(group)
		_base_scales.append(base_scale)

		for i in SPECS.size():
			var spec: Array = SPECS[i]
			var r: float = spec[0]
			var h: float = spec[1]
			var x: float = spec[2]
			var z: float = spec[3]
			var rx: float = spec[4]
			var rz: float = spec[5]

			var mesh := CylinderMesh.new()
			mesh.radial_segments = 5
			mesh.rings = 1
			mesh.top_radius = 0.0
			mesh.bottom_radius = r
			mesh.height = h

			var mat := ShaderMaterial.new()
			mat.shader = CRYSTAL_SHADER

			var mi := MeshInstance3D.new()
			mi.name = "Cone%d" % i
			mi.mesh = mesh
			mi.material_override = mat
			mi.rotation_order = EULER_ORDER_XYZ
			mi.rotation = Vector3(rx, fposmod(sin(float(g * 5 + i) * 12.9898 + 4.1414) * 43758.5453, 1.0) * PI, rz)
			mi.position = Vector3(x, 0.0, z) + mi.basis.y * (h * 0.5)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			group.add_child(mi)

		_groups.append(group)

func draw(s: Dictionary) -> void:
	var timeline: float = s.travel * LIFETIME_END
	var right: Vector3 = s.right
	var axis: Vector3 = s.axis
	var orientation := Basis(right, Vector3.UP, -axis)
	for g in GROUP_COUNT:
		var group := _groups[g]
		var start := LIFETIME_START + LIFETIME_STEP * g
		var progress := (timeline - start) / (LIFETIME_END - start)
		group.visible = progress >= 0.0 and s.impact < 0.0
		if not group.visible:
			continue

		var grow := 1.0
		if progress < EASE_IN_SPAN:
			var d := progress / EASE_IN_SPAN - 1.0
			grow = maxf(0.01, 1.0 + 1.7 * d * d * d + 0.7 * d * d)
		var sway := 0.0
		if progress > 1.0 - SWAY_SPAN:
			var frame := floorf(float(s.time) * 60.0)
			sway = (fposmod(sin(frame * 78.233 + g * 1.618) * 43758.5453, 1.0) * 2.0 - 1.0) * SWAY_AMPLITUDE
		var geometry_scale: float = _base_scales[g] * s.scale
		var dimensions := Vector3(geometry_scale, geometry_scale * grow, geometry_scale)
		var center: Vector3 = s.clusters[g]
		group.global_transform = Transform3D(orientation * Basis.from_scale(dimensions), center + right * sway)
		for child in group.get_children():
			var mat: ShaderMaterial = child.material_override
			mat.set_shader_parameter("fade", s.fade)
			mat.set_shader_parameter("phase_time", s.time)
			mat.set_shader_parameter("fracture", smoothstep(0.75, 1.0, progress))