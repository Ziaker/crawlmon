extends Node3D
const DUST := preload("res://content/moves/mabufula/dust.gdshader")
var _cam: Camera3D
var _mm: MultiMesh
var _mat: ShaderMaterial

func setup(camera: Camera3D) -> void:
	_cam = camera
	_mat = ShaderMaterial.new()
	_mat.shader = DUST
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = _mat
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.use_custom_data = true
	_mm.mesh = q
	_mm.instance_count = 25
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	add_child(mmi)

func draw(s: Dictionary) -> void:
	if _mm == null:
		return
	var clusters: Array = s.clusters
	var travel: float = s.travel
	var impact: float = s.impact
	var fade: float = s.fade
	var gs: float = s.scale
	_mat.set_shader_parameter("phase_time", s.time)
	var i := 0
	for c in 5:
		var p: Vector3 = clusters[c]
		var rise := (0.42 + float(c) * 0.11) / 1.55
		var lift := clampf((travel - rise) / 0.3, 0.0, 1.0)
		var mist := 1.0 - clampf(impact / 0.7, 0.0, 1.0) if impact >= 0.0 else 1.0
		var burst := sin(PI * clampf(impact / 0.6, 0.0, 1.0)) if impact >= 0.0 else 0.0
		var born := sin(PI * clampf((travel - rise) / 0.25, 0.0, 1.0)) if travel >= rise else 0.0
		var puff := maxf(born, burst)
		for m in 2:
			var a := minf(0.12 * mist * fade * (0.6 + 0.4 * lift), 0.12)
			var org := p + Vector3(0.0, 0.06 + 0.10 * lift + 0.05 * m, 0.0)
			var rot := Basis(Vector3.UP, 0.6 * float(c) + 1.3 * m) * Basis(Vector3.RIGHT, -PI / 2.0)
			_mm.set_instance_transform(i, Transform3D(rot * Basis.from_scale(Vector3.ONE * gs * (0.9 + 0.5 * lift)), org))
			_mm.set_instance_color(i, Color(0.85, 0.82, 0.76, a))
			_mm.set_instance_custom_data(i, Color(lift, float(m), 0.0, 1.0))
			i += 1
		var face := Basis.looking_at(p - _cam.global_position, Vector3.UP) if is_instance_valid(_cam) and p.distance_squared_to(_cam.global_position) > 1e-6 else Basis.IDENTITY
		for k in 3:
			var a := minf(0.16 * fade * puff, 0.16)
			var off := Vector3(cos(float(k) * TAU / 3.0), 0.0, sin(float(k) * TAU / 3.0)) * (0.18 + 0.12 * lift)
			var org := p + off + Vector3(0.0, 0.18 + 0.35 * lift, 0.0)
			_mm.set_instance_transform(i, Transform3D(face * Basis.from_scale(Vector3.ONE * gs * (0.7 + 0.8 * puff)), org))
			_mm.set_instance_color(i, Color(0.78, 0.74, 0.68, a))
			_mm.set_instance_custom_data(i, Color(puff, 0.0, 0.0, 1.0))
			i += 1
