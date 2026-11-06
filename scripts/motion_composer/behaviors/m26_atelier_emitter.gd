class_name MotionM26AtelierEmitter
extends MotionBehavior
## M26 Emissor Atelier (V1.8, D-337): avalia de forma 100% determinística e sem estado as trajetórias de partículas do
## Atelier HTML (esfera, hemisfério, cone, círculo/hélice, sucção inward, órbita com taxa radial, arrasto, gravidade e
## quique no chão em y = floor_y), preenchendo posição, largura (curva de tamanho), opacidade (curva de alfa),
## intensidade (idade normalizada t = 0..1 para gradiente de 3 paradas) e visibilidade.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M26"
	display_name = "Emissor Atelier"
	description = "Trajetórias determinísticas do Atelier HTML (esfera, hemisfério, cone, hélice, inward e quique no chão)."
	group = &"trajetorias"
	kind = MotionTypes.Kind.GENERATOR
	accepted_operations = [Op.REPLACE]
	params = [
		MotionParam.make_int(&"shape", 0, 0, 4, ""), # 0=sphere, 1=hemisphere, 2=cone, 3=circle/helix, 4=inward
		MotionParam.make_float(&"radius", 1.0, 0.0, 50.0, "m"),
		MotionParam.make_float(&"cone_rad", 0.5, 0.0, 3.1416, "rad"),
		MotionParam.make_vec3(&"direction", Vector3(0, 1, 0), -1.0, 1.0, ""),
		MotionParam.make_float(&"speed_min", 1.0, 0.0, 100.0, "m/s"),
		MotionParam.make_float(&"speed_max", 3.0, 0.0, 100.0, "m/s"),
		MotionParam.make_float(&"life_min", 0.6, 0.05, 20.0, "s"),
		MotionParam.make_float(&"life_max", 1.4, 0.05, 20.0, "s"),
		MotionParam.make_float(&"size_min", 0.6, 0.01, 20.0, "m"),
		MotionParam.make_float(&"size_max", 1.4, 0.01, 20.0, "m"),
		MotionParam.make_bool(&"size_bell", false),
		MotionParam.make_float(&"orbit_speed", 0.0, -50.0, 50.0, "rad/s"),
		MotionParam.make_float(&"radial_rate", -0.25, -10.0, 10.0, ""),
		MotionParam.make_float(&"gravity", 0.0, -50.0, 60.0, "m/s2"),
		MotionParam.make_float(&"drag", 0.98, 0.5, 1.0, ""),
		MotionParam.make_bool(&"bounce_floor", false),
		MotionParam.make_float(&"floor_y", -0.1, -20.0, 20.0, "m"),
		MotionParam.make_float(&"stagger", 0.0, 0.0, 10.0, "s"),
		MotionParam.make_float(&"delay", 0.0, 0.0, 10.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var shape := int(p["shape"])
	var radius := float(p["radius"])
	var cone_rad := float(p["cone_rad"])
	var dir_cone := MotionProfile.safe_axis(p["direction"])
	var spd_min := float(p["speed_min"])
	var spd_max := float(p["speed_max"])
	var life_min := float(p["life_min"])
	var life_max := maxf(float(p["life_max"]), life_min)
	var size_min := float(p["size_min"])
	var size_max := maxf(float(p["size_max"]), size_min)
	var size_bell := bool(p["size_bell"])
	var orbit_speed := float(p["orbit_speed"])
	var radial_rate := float(p["radial_rate"])
	var gravity := float(p["gravity"])
	var drag := float(p["drag"])
	var bounce_floor := bool(p["bounce_floor"])
	var floor_y := float(p["floor_y"])
	var stagger := float(p["stagger"])
	var delay_max := float(p["delay"])

	var q_cone := Quaternion(Vector3.UP, dir_cone) if absf(dir_cone.dot(Vector3.UP)) < 0.999 else (Quaternion.IDENTITY if dir_cone.y > 0.0 else Quaternion(Vector3.RIGHT, PI))
	var total := maxf(float(samples.size()), 1.0)
	var out: Array[MotionSample] = []

	for idx in samples.size():
		var s := samples[idx].duplicate_sample()
		var eid := s.element_id & 0xFFFFFFFF
		var eh := s.element_id >> 32
		var r0 := MotionHash.float01(ctx.seed, eid, eh, 101)
		var r1 := MotionHash.float01(ctx.seed, eid, eh, 102)
		var r2 := MotionHash.float01(ctx.seed, eid, eh, 103)
		var r3 := MotionHash.float01(ctx.seed, eid, eh, 104)
		var r4 := MotionHash.float01(ctx.seed, eid, eh, 105)
		var r5 := MotionHash.float01(ctx.seed, eid, eh, 106)
		var r6 := MotionHash.float01(ctx.seed, eid, eh, 107)

		var p_delay := (float(idx) / total) * stagger if stagger > 0.0 else delay_max * r0
		var age := lt - p_delay
		var max_life := lerpf(life_min, life_max, r1)
		if age < 0.0 or age >= max_life:
			s.visible = false
			s.opacity = 0.0
			s.width = 0.01
			s.intensity = 1.0
			s.position = Vector3.ZERO
			out.append(s)
			continue

		var t := clampf(age / maxf(max_life, 0.001), 0.0, 1.0)
		var spd := lerpf(spd_min, spd_max, r2)
		var size_start := lerpf(size_min, size_max, r3)
		var orbit_angle := (float(idx) / total) * TAU + r4 * 0.5
		var orbit_radius := radius * (0.35 + 0.65 * r5)
		var pos := Vector3.ZERO
		var vel := Vector3.ZERO

		if shape == 3:
			# circle / helix
			pos = Vector3(cos(orbit_angle) * orbit_radius, (r6 - 0.5) * 0.3, sin(orbit_angle) * orbit_radius)
			vel = Vector3(0.0, spd, 0.0)
		elif shape == 4:
			# inward
			var u := r4 * TAU
			var v := (r5 - 0.5) * 2.0
			var rr := radius * (0.65 + 0.35 * r6)
			var sq := sqrt(maxf(0.0, 1.0 - v * v))
			var offset := Vector3(cos(u) * sq * rr, v * rr, sin(u) * sq * rr)
			pos = offset
			vel = -offset.normalized() * spd if offset.length() > 0.001 else Vector3.ZERO
		elif shape == 2:
			# cone
			var theta := r4 * TAU
			var ca := cone_rad * r5
			var d_loc := Vector3(sin(ca) * cos(theta), cos(ca), sin(ca) * sin(theta))
			var d_w := q_cone * d_loc
			pos = d_w * (r6 * radius)
			vel = d_w * spd
		elif shape == 1:
			# hemisphere
			var theta_h := r4 * TAU
			var phi_h := acos(clampf(r5, 0.0, 1.0))
			var d_h := Vector3(sin(phi_h) * cos(theta_h), absf(cos(phi_h)), sin(phi_h) * sin(theta_h))
			pos = d_h * (r6 * radius * 0.4)
			vel = d_h * spd
		else:
			# sphere
			var theta_s := r4 * TAU
			var phi_s := acos(clampf(2.0 * r5 - 1.0, -1.0, 1.0))
			var d_s := Vector3(sin(phi_s) * cos(theta_s), cos(phi_s), sin(phi_s) * sin(theta_s))
			pos = d_s * (r6 * radius * 0.35)
			vel = d_s * spd

		if absf(orbit_speed) > 0.0001:
			var cur_ang := orbit_angle + orbit_speed * age
			var cur_rad := maxf(0.05, orbit_radius * (1.0 + radial_rate * t))
			pos.x = cos(cur_ang) * cur_rad
			pos.z = sin(cur_ang) * cur_rad
			pos.y += vel.y * age
		else:
			var dt_step := 1.0 / 60.0
			var rem := age
			while rem > 0.0001:
				var dt := minf(rem, dt_step)
				vel.y -= gravity * dt
				vel *= pow(drag, dt * 60.0)
				pos += vel * dt
				if bounce_floor and pos.y < floor_y and vel.y < 0.0:
					pos.y = floor_y
					vel.y *= -0.45
					vel.x *= 0.72
					vel.z *= 0.72
				rem -= dt

		var size_curve := sin(t * PI) if size_bell else (1.0 - pow(t, 1.45))
		var alpha_curve := (t / 0.14) if t < 0.14 else pow(maxf(0.0, 1.0 - (t - 0.14) / 0.86), 1.35)

		s.position = pos
		s.width = maxf(0.01, size_start * size_curve)
		s.opacity = clampf(alpha_curve, 0.0, 1.0)
		s.intensity = t
		s.visible = s.opacity > 0.01
		out.append(s)

	return out
