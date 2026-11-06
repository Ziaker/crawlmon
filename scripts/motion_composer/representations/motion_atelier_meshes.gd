class_name MotionAtelierMeshes
extends RefCounted
## Motion Composer V1.8 (D-337): construtores e desenhadores em pool das malhas 3D compostas e shaders do Atelier HTML
## para Media, Mabufula, Dig, Sand Attack, Dragon Rage e Splitter Flames. Chamado por MotionPainter.
## Tudo determinístico pelo relógio explícito `painter.time` (D-019) e independente de personagem/time/lado (D-235).


static func _unshaded_mat(col: Color, additive: bool, cull_off := true, depth_write := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	if additive or col.a < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED if cull_off else BaseMaterial3D.CULL_BACK
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY if depth_write else BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m


static func _lit_rock_mat(col: Color, emit_col := Color(0, 0, 0), emit_e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.8
	if emit_e > 0.01:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_e
	return m


## Cria um cone com a base em y = 0 e o ápice em y = height (igual a ConeGeometry.translate(0, h/2, 0) do Three.js).
static func _cone_bottom_origin(radius: float, height: float, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3(0.0, height, 0.0)
	for i in sides:
		var a0 := float(i) / float(sides) * TAU
		var a1 := float(i + 1) / float(sides) * TAU
		var p0 := Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		var nrm := (p1 - apex).cross(p0 - apex).normalized()
		st.set_normal(nrm)
		st.set_uv(Vector2(float(i) / float(sides), 1.0))
		st.add_vertex(p0)
		st.set_normal(nrm)
		st.set_uv(Vector2((float(i) + 0.5) / float(sides), 0.0))
		st.add_vertex(apex)
		st.set_normal(nrm)
		st.set_uv(Vector2(float(i + 1) / float(sides), 1.0))
		st.add_vertex(p1)
	return st.commit()


## 1. Partícula billboard procedural do Atelier (10 texturas, aditiva ou alfa-mix, com rotação 2D `angle`).
static func draw_ptcl(painter: MotionPainter, pos: Vector3, size: float, shape_id: int, col: Color, alpha: float, angle: float, additive: bool) -> void:
	if size <= 0.01 or alpha <= 0.01:
		return
	if painter.neutral:
		painter.dot(pos, size * 0.25)
		return
	var key := "at_ptcl_add" if additive else "at_ptcl_mix"
	var sh := "mc_atelier_add" if additive else "mc_atelier_mix"
	var mi := painter._node(key, sh)
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("shape_id", shape_id)
	mat.set_shader_parameter("col", col)
	mat.set_shader_parameter("alpha", alpha)
	mat.set_shader_parameter("angle", angle)


## 2. Media: Círculo Sagrado no chão (spawnSacredHealCircle).
static func draw_heal_circle(painter: MotionPainter, center: Vector3, radius: float, progress: float) -> void:
	if radius <= 0.05 or progress <= 0.0 or progress >= 0.999:
		return
	if painter.neutral:
		painter.dot(center, radius * 0.2)
		return
	var mi := painter._node("heal_circle", "mc_heal_circle")
	var s := lerpf(0.2, 1.0, progress / 0.2) if progress < 0.2 else 1.0
	var d := radius * 2.0 * s
	mi.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(d, d, 1.0)), Vector3(center.x, 0.04, center.z))
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", painter.time)
	mat.set_shader_parameter("progress", progress)


## 3. Media: Pilar Volumétrico de Cura (spawnVolumetricHealPillar).
static func draw_heal_pillar(painter: MotionPainter, center: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999:
		return
	if painter.neutral:
		painter.dot(center + Vector3.UP * 2.0, 0.5)
		return
	var mi := painter._node("heal_pillar", "mc_heal_pillar", "cyl_heal")
	mi.position = Vector3(center.x, 3.75, center.z)
	mi.scale = Vector3.ONE
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", painter.time)
	mat.set_shader_parameter("progress", progress)


## 4. Mabufula: Decalque de Geada no chão (spawnCryoFrostDecal).
static func draw_cryo_decal(painter: MotionPainter, center: Vector3, forward: Vector3, width: float, depth: float, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var mi := painter._node("cryo_decal", "mc_cryo_decal")
	var f := Vector3(forward.x, 0.0, forward.z).normalized()
	if f.length_squared() < 0.01:
		f = Vector3.FORWARD
	var yaw := atan2(f.x, f.z)
	mi.transform = Transform3D((Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI * 0.5)) * Basis.from_scale(Vector3(width, depth, 1.0)), Vector3(center.x, 0.03, center.z))
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", painter.time)
	mat.set_shader_parameter("progress", progress)


## 5. Mabufula: Cluster de 5 Geleiras Cônicas de 5 faces (spawnGlacialSpireCluster).
static func draw_glacial_cluster(painter: MotionPainter, pos: Vector3, scale_k: float, progress: float, seed_v: float) -> void:
	if progress <= 0.0 or progress >= 0.999:
		return
	if painter.neutral:
		painter.dot(pos + Vector3.UP * 1.5, 0.6 * scale_k)
		return
	var cfgs := [
		{"r": 0.65, "h": 3.6, "x": 0.0, "z": 0.0, "rx": 0.08, "rz": -0.05, "ry": 0.4},
		{"r": 0.48, "h": 2.6, "x": -0.55, "z": 0.35, "rx": 0.22, "rz": 0.32, "ry": 1.3},
		{"r": 0.52, "h": 2.8, "x": 0.58, "z": 0.25, "rx": 0.18, "rz": -0.35, "ry": 2.1},
		{"r": 0.42, "h": 2.2, "x": -0.38, "z": -0.52, "rx": -0.28, "rz": 0.22, "ry": 0.9},
		{"r": 0.45, "h": 2.4, "x": 0.42, "z": -0.45, "rx": -0.25, "rz": -0.28, "ry": 2.8},
	]
	var sy := 1.0
	if progress < 0.18:
		var t := progress / 0.18
		var tm1 := t - 1.0
		sy = maxf(0.01, 1.0 + 1.7 * tm1 * tm1 * tm1 + 0.7 * tm1 * tm1)
	var vib := sin(painter.time * 110.0 + seed_v * 7.0) * 0.06 if progress > 0.75 else 0.0
	var base_pos := Vector3(pos.x + vib, 0.0, pos.z)
	for i in cfgs.size():
		var c: Dictionary = cfgs[i]
		var mi := painter._node("glacial_spire_%d" % i, "mc_glacial_spire", "cone5")
		var b := Basis.from_euler(Vector3(float(c["rx"]), float(c["ry"]) + seed_v, float(c["rz"])))
		b = b * Basis.from_scale(Vector3(float(c["r"]) * scale_k, float(c["h"]) * scale_k * sy, float(c["r"]) * scale_k))
		mi.transform = Transform3D(b, base_pos + Vector3(float(c["x"]) * scale_k, 0.0, float(c["z"]) * scale_k))


## 6. Dig: Cratera Sísmica + 8 Rochas 3D na Borda (spawnSeismicCraterDecal).
static func draw_seismic_crater(painter: MotionPainter, pos: Vector3, radius: float, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var mi := painter._node("seismic_crater", "mc_seismic_crater")
	var d := radius * 2.2
	mi.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(d, d, 1.0)), Vector3(pos.x, 0.03, pos.z))
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", painter.time)
	mat.set_shader_parameter("progress", progress)
	var fade := 1.0 - smoothstep(0.75, 1.0, progress)
	for i in 8:
		var ang := float(i) / 8.0 * TAU
		var r_rock := (0.26 + float(i % 2) * 0.1) * fade
		if r_rock <= 0.02:
			continue
		var rock := painter._node("crater_rock", "mc_surface", "frag_one")
		var rp := Vector3(pos.x + cos(ang) * (radius * 0.65), 0.14 * fade, pos.z + sin(ang) * (radius * 0.65))
		var rb := Basis.from_euler(Vector3(float(i), float(i) * 0.7, 0.0)).scaled(Vector3.ONE * r_rock * 2.0)
		rock.transform = Transform3D(rb, rp)
		var rmat := rock.material_override as ShaderMaterial
		rmat.set_shader_parameter("use_vcolor", 0.0)
		rmat.set_shader_parameter("u_dissolve", 0.0)
		var look := MotionLooks.get_look("surface", "earth")
		for k in look.keys():
			rmat.set_shader_parameter(k, look[k])


## 7. Dig: Monte Sísmico Subterrâneo Cônico 3D (Phase 2 mounds).
static func draw_dig_mound(painter: MotionPainter, pos: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999:
		return
	if painter.neutral:
		painter.dot(pos + Vector3.UP * 0.4, 0.4)
		return
	var sy := maxf(0.01, sin(progress * PI))
	var sxz := 1.0 + progress * 0.3
	var mi := painter._node("dig_mound", "mc_surface", "cone7")
	mi.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(0.85 * sxz, 0.95 * sy, 0.85 * sxz)), Vector3(pos.x, 0.0, pos.z))
	var rmat := mi.material_override as ShaderMaterial
	rmat.set_shader_parameter("use_vcolor", 0.0)
	rmat.set_shader_parameter("u_dissolve", 0.0)
	var look := MotionLooks.get_look("surface", "earth")
	for k in look.keys():
		rmat.set_shader_parameter(k, look[k])


## 8. Dig: Coroa de 6 Espirais de Basalto/Magma no Impacto (Phase 3 spireGroup).
static func draw_basalt_spires(painter: MotionPainter, pos: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var sy := (progress / 0.2) if progress < 0.2 else (1.0 - maxf(0.0, (progress - 0.65) / 0.35))
	sy = maxf(0.01, sy)
	var look := MotionLooks.get_look("surface", "earth")
	look["rim_color"] = Color(0.96, 0.62, 0.04)
	look["rim_amount"] = 0.85
	for k in 6:
		var ang := float(k) / 6.0 * TAU
		var h := (2.4 + float(k % 2) * 0.8) * sy
		var mi := painter._node("basalt_spire", "mc_surface", "cone5")
		var tilt := (float(k % 3) - 1.0) * 0.18
		var b := Basis.from_euler(Vector3(sin(ang) * 0.22, ang, tilt)) * Basis.from_scale(Vector3(0.48, h, 0.48))
		mi.transform = Transform3D(b, Vector3(pos.x + cos(ang) * 0.75, 0.0, pos.z + sin(ang) * 0.75))
		var rmat := mi.material_override as ShaderMaterial
		rmat.set_shader_parameter("use_vcolor", 0.0)
		rmat.set_shader_parameter("u_dissolve", 0.0)
		for lk in look.keys():
			rmat.set_shader_parameter(lk, look[lk])


## 9. Sand Attack: Onda Crescente de Areia (spawnSandCrescentWave).
static func draw_sand_crescent(painter: MotionPainter, pos: Vector3, forward: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var mi := painter._node("sand_crescent", "mc_sand_crescent")
	var f := Vector3(forward.x, 0.0, forward.z).normalized()
	if f.length_squared() < 0.01:
		f = Vector3.FORWARD
	var yaw := atan2(f.x, f.z) - PI * 0.5
	var s := (0.8 + progress * 1.4) * 2.9
	mi.transform = Transform3D((Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI * 0.5)) * Basis.from_scale(Vector3(s, s, 1.0)), Vector3(pos.x, 0.65, pos.z))
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("progress", progress)


## 10. Sand Attack: Funil de Redemoinho (spawnDustDevilFunnel).
static func draw_dust_devil(painter: MotionPainter, pos: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999:
		return
	if painter.neutral:
		painter.dot(pos + Vector3.UP * 1.9, 0.9)
		return
	var mi := painter._node("dust_devil", "mc_dust_devil", "funnel")
	mi.transform = Transform3D(Basis(Vector3.UP, painter.time * 8.0), Vector3(pos.x, 1.9, pos.z))
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", painter.time)
	mat.set_shader_parameter("progress", progress)


## 11. Dragon Rage: Mandíbula 3D Espectral de Dragão com Chifres, Olhos e 8 Presas (spawnSpectralDragonMaw).
static func draw_dragon_maw(painter: MotionPainter, pos: Vector3, forward: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999:
		return
	if painter.neutral:
		painter.dot(pos, 0.8)
		return
	var f := forward.normalized() if forward.length_squared() > 0.01 else Vector3.FORWARD
	var up := Vector3.UP if absf(f.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	var base_b := Basis.looking_at(f, up) # -Z olha para o alvo
	var jaw_open := lerpf(0.05, 0.62, progress / 0.75) if progress < 0.75 else lerpf(0.62, 0.1, (progress - 0.75) / 0.25)
	var sc := lerpf(0.3, 1.35, progress / 0.2) if progress < 0.2 else (1.35 + progress * 0.25)
	var env := sin(progress * PI)
	var upper_b := base_b * Basis(Vector3.RIGHT, jaw_open)
	var lower_b := base_b * Basis(Vector3.RIGHT, -jaw_open * 1.15)
	var upper_p := pos + base_b.y * (jaw_open * 0.55 * sc)
	var lower_p := pos - base_b.y * (jaw_open * 0.55 * sc)

	# Focinho superior (snout)
	var snout := painter._node("dr_maw_snout", "mc_dragon_spire", "cone5")
	snout.transform = Transform3D((upper_b * Basis(Vector3.RIGHT, -PI * 0.5)) * Basis.from_scale(Vector3(1.14 * sc, 1.8 * sc, 0.52 * sc)),
		upper_p + upper_b * (Vector3(0.0, 0.35, 0.7) * sc))
	(snout.material_override as ShaderMaterial).set_shader_parameter("progress", clampf(progress, 0.05, 0.95))

	# 2 Chifres dracônicos e 2 Olhos amarelos
	for side_i in 2:
		var side := -1.0 if side_i == 0 else 1.0
		var horn := painter._node("dr_maw_horn", "mc_dragon_spire", "cone5")
		var hb := (upper_b * Basis.from_euler(Vector3(0.85, 0.0, side * 0.42))) * Basis.from_scale(Vector3(0.22 * sc, 1.65 * sc, 0.22 * sc))
		horn.transform = Transform3D(hb, upper_p + upper_b * (Vector3(side * 0.78, 0.85, 0.45) * sc))
		(horn.material_override as ShaderMaterial).set_shader_parameter("progress", clampf(progress, 0.05, 0.95))

		var eye := painter._node("dr_maw_eye", "mc_atelier_add")
		eye.position = upper_p + upper_b * (Vector3(side * 0.55, 0.52, -0.15) * sc)
		eye.scale = Vector3(0.45 * sc, 0.22 * sc, 1.0)
		var emat := eye.material_override as ShaderMaterial
		emat.set_shader_parameter("shape_id", 0)
		emat.set_shader_parameter("col", Color(1.0, 0.918, 0.0, 1.0))
		emat.set_shader_parameter("alpha", env)

	# 4 Presas superiores e 4 Presas inferiores
	var fx_arr := [-0.68, -0.38, 0.38, 0.68]
	for idx in 4:
		var fx_x := float(fx_arr[idx])
		var flen := 0.62 if (idx == 0 or idx == 3) else 0.44
		var ufang := painter._node("dr_maw_fang", "mc_dragon_spire", "cone4")
		var ufb := (upper_b * Basis(Vector3.RIGHT, PI)) * Basis.from_scale(Vector3(0.11 * sc, flen * sc, 0.11 * sc))
		ufang.transform = Transform3D(ufb, upper_p + upper_b * (Vector3(fx_x, 0.12, -0.65) * sc))
		var ufmat := ufang.material_override as ShaderMaterial
		ufmat.set_shader_parameter("c_base", Color(1.0, 0.95, 0.98, 1.0))
		ufmat.set_shader_parameter("c_mid", Color(1.0, 0.82, 0.9, 1.0))
		ufmat.set_shader_parameter("c_tip", Color(1.0, 0.0, 0.333, 1.0))
		ufmat.set_shader_parameter("progress", clampf(progress, 0.05, 0.95))

		var lfang := painter._node("dr_maw_fang", "mc_dragon_spire", "cone4")
		var lfb := lower_b * Basis.from_scale(Vector3(0.10 * sc, flen * 0.9 * sc, 0.10 * sc))
		lfang.transform = Transform3D(lfb, lower_p + lower_b * (Vector3(fx_x * 0.9, -0.12, -0.60) * sc))
		var lfmat := lfang.material_override as ShaderMaterial
		lfmat.set_shader_parameter("c_base", Color(1.0, 0.95, 0.98, 1.0))
		lfmat.set_shader_parameter("c_mid", Color(1.0, 0.82, 0.9, 1.0))
		lfmat.set_shader_parameter("c_tip", Color(1.0, 0.0, 0.333, 1.0))
		lfmat.set_shader_parameter("progress", clampf(progress, 0.05, 0.95))


## 12. Dragon Rage: Decalque de Fissuras Dracônicas no chão (spawnDraconicFissureDecal).
static func draw_draconic_fissure(painter: MotionPainter, pos: Vector3, radius: float, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var mi := painter._node("dr_fissure", "mc_draconic_fissure")
	var d := radius * 2.0
	mi.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(d, d, 1.0)), Vector3(pos.x, 0.035, pos.z))
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", painter.time)
	mat.set_shader_parameter("progress", progress)


## 13. Dragon Rage: Bola de Fogo Dracônica Monstruosa + 12 Espinhos 3D + 5 Raios Bio-Elétricos (createMonstrousDragonRageFireball).
static func draw_dragon_fireball(painter: MotionPainter, pos: Vector3, forward: Vector3, scale_k: float, spin: float) -> void:
	if scale_k <= 0.02:
		return
	if painter.neutral:
		painter.dot(pos, scale_k)
		return
	var f := forward.normalized() if forward.length_squared() > 0.01 else Vector3.FORWARD
	var up := Vector3.UP if absf(f.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	var base_b := Basis.looking_at(f, up)

	# 1. Halo incandescente interno
	draw_ptcl(painter, pos, 2.2 * scale_k, 0, Color(1.0, 0.94, 0.83, 1.0), 0.95, 0.0, true)

	# 2. Casca com deslocamento de espinhos no vértice (mc_dragon_fireball)
	var shell := painter._node("dr_fireball_shell", "mc_dragon_fireball", "sphere")
	shell.transform = Transform3D(base_b.scaled(Vector3.ONE * 2.24 * scale_k), pos)
	(shell.material_override as ShaderMaterial).set_shader_parameter("tt", painter.time)

	# 3. Coroa de 12 línguas/espinhos 3D de chama girando ao redor da esfera
	var spin_b := base_b * Basis(Vector3.FORWARD, spin)
	for i in 12:
		var ang := float(i) / 12.0 * TAU
		var local_p := Vector3(cos(ang) * 0.72, sin(ang) * 0.72, 0.15) * scale_k
		var spike_b := spin_b * Basis(Vector3.FORWARD, -ang + PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.38)
		var cone := painter._node("dr_fireball_spike", "mc_dragon_spire", "cone4")
		cone.transform = Transform3D(spike_b * Basis.from_scale(Vector3(0.28 * scale_k, 1.35 * scale_k, 0.28 * scale_k)), pos + spin_b * local_p)
		var smat := cone.material_override as ShaderMaterial
		smat.set_shader_parameter("c_base", Color(1.0, 0.918, 0.475, 1.0))
		smat.set_shader_parameter("c_mid", Color(1.0, 0.0, 0.333, 1.0))
		smat.set_shader_parameter("c_tip", Color(0.22, 0.0, 0.12, 1.0))
		smat.set_shader_parameter("progress", 0.5)

	# 4. 5 Arcos de Bio-Eletricidade Dracônica 3D estalando ao redor da esfera
	var tick := int(floor(painter.time * 30.0))
	for b in 5:
		var theta := MotionHash.float01(tick, b, 1, 70) * TAU
		var phi := MotionHash.float01(tick, b, 2, 70) * PI
		var cur := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)) * (0.85 * scale_k)
		var col := Color(1.0, 0.82, 0.9, 1.0) if b % 2 == 0 else Color(1.0, 0.0, 0.333, 1.0)
		for s in 6:
			var dx := (MotionHash.float01(tick, b, s, 71) - 0.5) * 0.75 * scale_k
			var dy := (MotionHash.float01(tick, b, s, 72) - 0.5) * 0.75 * scale_k
			var dz := (MotionHash.float01(tick, b, s, 73) - 0.5) * 0.75 * scale_k
			var nxt := cur + Vector3(dx, dy, dz)
			var mid := pos + base_b * ((cur + nxt) * 0.5)
			var seg := base_b * (nxt - cur)
			if seg.length() > 0.02:
				painter.streak(mid, seg.normalized(), seg.length(), 0.09 * scale_k, 0.05, b % 2 == 0)
			cur = nxt


## 14. Dragon Rage: 10 Espirais 3D de Chamas Dracônicas no Impacto (clawSpires).
static func draw_dragon_claw_spires(painter: MotionPainter, pos: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var sy := lerpf(0.1, 1.25, progress / 0.18) if progress < 0.18 else (1.25 - (progress - 0.18) * 0.45)
	sy = maxf(0.01, sy)
	var sxz := 0.85 + progress * 0.55
	var rot_y := painter.time * 2.2
	for k in 10:
		var ang := float(k) / 10.0 * TAU + rot_y
		var h := (3.2 + float(k % 3) * 0.95) * sy
		var r := (0.52 + float(k % 2) * 0.18) * sxz
		var dist := (0.65 if k % 2 == 0 else 1.35) * sxz
		var mi := painter._node("dr_claw_spire", "mc_dragon_spire", "cone4")
		var b := Basis.from_euler(Vector3(sin(ang) * 0.38, ang, -cos(ang) * 0.38)) * Basis.from_scale(Vector3(r, h, r))
		mi.transform = Transform3D(b, Vector3(pos.x + cos(ang) * dist, 0.0, pos.z + sin(ang) * dist))
		var smat := mi.material_override as ShaderMaterial
		smat.set_shader_parameter("c_base", Color(1.0, 0.918, 0.475, 1.0))
		smat.set_shader_parameter("c_mid", Color(1.0, 0.0, 0.333, 1.0))
		smat.set_shader_parameter("c_tip", Color(0.122, 0.0, 0.141, 1.0))
		smat.set_shader_parameter("progress", progress)


## 15. Dragon Rage: 8 Raios Dracônicos 3D chicoteando no Impacto (blastLightningGroup).
static func draw_dragon_blast_bolts(painter: MotionPainter, pos: Vector3, progress: float) -> void:
	if progress <= 0.0 or progress >= 0.999 or painter.neutral:
		return
	var tick := int(floor(painter.time * 32.0))
	var fade := clampf(progress * 0.7, 0.0, 0.95)
	for idx in 8:
		var ang := float(idx) / 8.0 * TAU + (MotionHash.float01(tick, idx, 0, 80) - 0.5) * 0.5
		var cur := Vector3.ZERO
		for s in 7:
			var nx := cur.x + cos(ang) * 0.42 + (MotionHash.float01(tick, idx, s, 81) - 0.5) * 0.45
			var ny := cur.y + 0.35 + (MotionHash.float01(tick, idx, s, 82) - 0.3) * 0.45
			var nz := cur.z + sin(ang) * 0.42 + (MotionHash.float01(tick, idx, s, 83) - 0.5) * 0.45
			var nxt := Vector3(nx, ny, nz)
			var seg := nxt - cur
			if seg.length() > 0.02:
				painter.streak(pos + (cur + nxt) * 0.5, seg.normalized(), seg.length(), 0.11, fade, idx % 2 == 0)
			cur = nxt
