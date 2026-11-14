class_name FxKnock
extends RefCounted
## Reação de impacto genérica (D-1205), para QUALQUER Move: knock-up do alvo (voo com gravidade de subida e de descida
## diferentes), recuo suave do alvo e do atacante, tremor lateral e FOV extra da câmera. Tudo vem dos campos do `MoveData`
## (`knockup_*`, `target_push`, `attacker_push`, `push_return_*`, `impact_fov_boost`); com os campos em 0 o Move não muda.
## Só desenho (D-019): dano e o status Knock-up são do Battle. Nada depende de personagem, time ou lado (D-235): o eixo
## do recuo é atacante->alvo, o tremor usa o eixo lateral da câmera.
##
## Os deslocamentos são aplicados por cima da posição que os outros sistemas deram ao modelo, sem acumular: guarda-se o
## último deslocamento e ele é desfeito antes de aplicar o novo.

const DUST_FX := preload("res://scripts/vfx/combat/dust/dust_fx.gd")
const MATERIALS := preload("res://scripts/vfx/combat/dust/dust_materials.gd")
const MESHES := preload("res://scripts/vfx/combat/dust/dust_meshes.gd")
const WIND_SHADER := preload("res://shaders/wind_swirl.gdshader")

var fx: BattleFx
var _reactions: Array[Dictionary] = []  ## uma por (alvo|atacante) afetado


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## The battle HUD that draws the card effect: the battle scene owns `hud` and BattleFx is its child. Null in a lab.
func _hud() -> BattleHud:
	var n: Node = fx
	while n != null:
		var h: Variant = n.get("hud")
		if h is BattleHud:
			return h
		n = n.get_parent()
	return null


## Chamado pelo BattleFx.play_hit quando o acerto é real (esquiva/erro não chegam aqui).
func on_hit(attacker: Combatant, target: Combatant, data: MoveData, info: Dictionary) -> void:
	if data == null or attacker == null or target == null:
		return
	var launch := data.knockup_launch()
	var knock_up := bool(info.get("knockup", false)) and not launch.is_empty()
	if not knock_up and data.target_push <= 0.0 and data.attacker_push <= 0.0:
		return
	var from_home: Vector3 = fx._home[attacker] if fx._home.has(attacker) else fx.rest_pos(attacker)
	var to_home: Vector3 = fx._home[target] if fx._home.has(target) else fx.rest_pos(target)
	var axis := Vector3(to_home.x - from_home.x, 0.0, to_home.z - from_home.z)
	axis = axis.normalized() if axis.length() > 0.001 else Vector3.ZERO
	var air := data.knockup_air_time if knock_up else 0.0
	var travel := air if air > 0.0 else 0.3  ## segundos que o recuo leva para chegar (sem voo: um passo curto)
	var ret_at := maxf(data.push_return_at, travel)
	if data.target_push > 0.0 or knock_up:
		_reactions.append({
			"c": target, "axis": axis, "dist": data.target_push, "travel": travel, "ret_at": ret_at, "ret": data.push_return_time,
			"t": 0.0, "y": 0.0, "air": air, "v": float(launch["v"]) if knock_up else 0.0,
			"g_up": float(launch["g_up"]) if knock_up else 22.0, "g_down": data.knockup_gravity_down, "fall": float(launch["fall"]) if knock_up else 0.0,
			"shudder": data.knockup_shudder if knock_up else 0.0, "fov": data.impact_fov_boost,
			"spin": data.knockup_spin_turns * TAU if knock_up else 0.0, "land_dust": data.knockup_landing_dust if knock_up else 0.0,
			"land_shake": data.knockup_landing_shake if knock_up else 0.0, "landed": false, "dir": axis,
			"lat": Vector3.UP.cross(axis), "body": _body_box(target), "anim": true, "anim_stage": 0,
			"wind": _make_wind(target, Vector3.UP.cross(axis)) if (knock_up and data.knockup_wind) else null,
		})
	# D-1205: eco textual "KNOCK-UP" above the target's real body (option 1 of the prototype), for the whole flight.
	if knock_up and fx._models.has(target):
		var echo_hud := _hud()
		var cam := fx.get_viewport().get_camera_3d() if fx.is_inside_tree() else null
		if echo_hud != null and cam != null:
			var bbox := _body_box(target)
			var mid := Vector3(fx._models[target].global_position.x, float(bbox["top"]) - float(bbox["h"]) * 0.15, fx._models[target].global_position.z)
			var body_px: Vector2 = cam.unproject_position(mid)
			var anchor: Variant = echo_hud.card_anchor_screen(target)
			KnockEcho.spawn(echo_hud, anchor if anchor is Vector2 else body_px + Vector2(0.0, -120.0), body_px, data.knockup_air_time)
	# The target's HUD tag must not follow the spinning body (its origin orbits the body centre: the tag shook up and down at ~4 Hz, measured
	# with --card-trace): it stays at the resting spot and the card pose does the lifting.
	if knock_up and fx._models.has(target) and fx._home.has(target):
		var rest_h: Vector3 = fx._home[target]
		fx._models[target].set_meta("tag_home", Vector3(rest_h.x, 0.0, rest_h.z))
	# The card effect reads when the Knock-up started (pose drawn by BattleHud.card_pose_begin).
	if knock_up and data.knockup_air_time > 0.0:
		var hud := _hud()
		if hud != null:
			hud.card_knock_start(target, data.card_style, data.knockup_air_time)
	if data.attacker_push > 0.0:
		_reactions.append({
			"c": attacker, "axis": -axis, "dist": data.attacker_push, "travel": travel, "ret_at": ret_at, "ret": data.push_return_time,
			"t": 0.0, "y": 0.0, "air": 0.0, "v": 0.0, "g_up": 22.0, "g_down": 48.0, "fall": 0.0, "shudder": 0.0, "fov": data.impact_fov_boost,
		})


func clear_all() -> void:
	for r in _reactions:
		_undo(r)
		_cleanup(r)
	_reactions.clear()
	_set_fov(0.0)


## No fim de BattleFx._process: depois da pose ociosa e dos outros sistemas, para ter a última palavra.
func process(delta: float) -> void:
	var fov := 0.0
	for r in _reactions.duplicate():
		var c: Combatant = r["c"]
		if c == null or not fx._models.has(c) or not c.is_alive():
			_cleanup(r)
			_reactions.erase(r)
			continue
		var m: Node3D = fx._models[c]
		var base := _base_of(m, r)
		var t := float(r["t"]) + delta
		var air := float(r["air"])
		if air > 0.0 and c.stun_kind == "knockup":
			# O voo é regido pelo mesmo relógio do status: o alvo pousa exatamente quando o Knock-up acaba (a pausa/hit-stop
			# do Battle também para o voo).
			t = maxf(float(r["t"]), air - c.stun_timer)
		elif air > 0.0 and t < air:
			t = air
		r["t"] = t
		var y := 0.0
		if air > 0.0:
			var ta := minf(t, air)
			var rise := maxf(air - float(r["fall"]), 0.001)
			if ta <= rise:
				y = float(r["v"]) * ta - 0.5 * float(r["g_up"]) * ta * ta
			else:
				var apex := float(r["v"]) * rise - 0.5 * float(r["g_up"]) * rise * rise
				var tf := ta - rise
				y = maxf(apex - 0.5 * float(r["g_down"]) * tf * tf, 0.0)
		r["y"] = y
		# Recuo: linear no tempo até chegar (com o voo vira uma parábola), segura, e volta suave (smoothstep).
		var push := clampf(t / maxf(float(r["travel"]), 0.001), 0.0, 1.0)
		var finished := false
		if t > float(r["ret_at"]):
			var back := clampf((t - float(r["ret_at"])) / maxf(float(r["ret"]), 0.001), 0.0, 1.0)
			back = back * back * (3.0 - 2.0 * back)
			push *= 1.0 - back
			finished = back >= 1.0
		var off := Vector3(0.0, y, 0.0) + (r["axis"] as Vector3) * float(r["dist"]) * push
		var shudder := maxf(float(r["shudder"]) - delta, 0.0)
		r["shudder"] = shudder
		if shudder > 0.0:
			off += _screen_right() * (sin(fx.clock * 85.0) * 0.11)
		var spin_total := float(r.get("spin", 0.0))
		var center_off := Vector3.ZERO
		var body_h := float((r["body"] as Dictionary).get("h", 1.8)) if r.has("body") else 1.8
		if spin_total > 0.0 and air > 0.0 and (r["lat"] as Vector3).length() > 0.001:
			# Gira como uma roda (cambalhota) em volta do eixo lateral ao recuo, pelo centro do corpo: o centro não sai do lugar.
			var lat: Vector3 = (r["lat"] as Vector3).normalized()
			# Velocidade pela duração: começa rápida e vai ficando mais lenta até zero ao chegar no chão (ease-out), para
			# aterrissar de pé: a derivada do ângulo some em k = 1 e o total é um número inteiro de voltas.
			var k_spin := clampf(t / air, 0.0, 1.0)
			var angle := spin_total * (1.0 - (1.0 - k_spin) * (1.0 - k_spin))
			var rot := Basis(lat, angle)
			var center := Vector3(0.0, body_h * 0.5, 0.0)
			center_off = center - rot * center
			m.basis = rot * _base_basis(m, r)
			r["last_basis"] = m.basis
			r["prev_basis_rot"] = rot
			r["angle"] = angle
			r["center_pos"] = base + off + center
		m.position = base + off + center_off
		off += center_off
		var wind = r.get("wind", null)
		if wind != null and is_instance_valid(wind):
			_update_wind(wind, r, t, air, delta)
		if bool(r.get("anim", false)):
			_drive_anim(r, c, t, air)
		if air > 0.0 and not bool(r.get("landed", false)) and t >= air:
			r["landed"] = true
			_land(r, m)
		r["last_pos"] = m.position
		r["prev_off"] = off
		fov = maxf(fov, float(r["fov"]))
		if OS.get_cmdline_user_args().has("--knock-trace"):  # D-1204: data instead of eyeballing
			var ap_dbg: AnimationPlayer = fx.fx_motion._anim_player(c)
			print("[knock] t=%.2f who=%s y=%.2f off=(%.2f,%.2f) stun=%.2f anim=%s speed=%.2f pos=%.2f" % [t, c.name, y, off.x, off.z, c.stun_timer, ap_dbg.current_animation if ap_dbg != null else "-", ap_dbg.speed_scale if ap_dbg != null else -1.0, ap_dbg.current_animation_position if ap_dbg != null else -1.0])
		if finished and shudder <= 0.0 and y <= 0.0:
			m.position = base
			_cleanup(r)
			_reactions.erase(r)
	_set_fov(fov if not _reactions.is_empty() else 0.0)


## Câmera: quem está em reação conta no enquadramento pelo ponto de repouso, não pelo corpo no ar.
func anchor(c: Combatant, current: Vector3) -> Vector3:
	for r in _reactions:
		if r["c"] == c and fx._home.has(c):
			var h: Vector3 = fx._home[c]
			return Vector3(h.x, 0.0, h.z)
	return current


func _set_fov(deg: float) -> void:
	if fx.cam != null:
		fx.cam.fov_boost_target = deg


## A posição de repouso do modelo sem o meu deslocamento. O BattleFx zera o Y de modelos não ociosos a cada quadro: o Y só
## é desfeito se ainda for o que eu pus; X e Z sempre são desfeitos (senão o recuo acumularia quadro a quadro).
func _base_of(m: Node3D, r: Dictionary) -> Vector3:
	if not r.has("last_pos"):
		return m.position
	var prev: Vector3 = r["prev_off"]
	var last: Vector3 = r["last_pos"]
	var base_y := m.position.y - prev.y if is_equal_approx(m.position.y, last.y) else m.position.y
	return Vector3(m.position.x - prev.x, base_y, m.position.z - prev.z)


func _undo(r: Dictionary) -> void:
	var c: Combatant = r["c"]
	if c != null and fx._models.has(c):
		var m: Node3D = fx._models[c]
		m.position = _base_of(m, r)


func _screen_right() -> Vector3:
	if fx.cam != null and fx.cam.camera != null:
		var right: Vector3 = fx.cam.camera.global_transform.basis.x
		right.y = 0.0
		if right.length() > 0.001:
			return right.normalized()
	return Vector3.RIGHT


## A orientação do modelo sem o meu giro. Se outro sistema reescreveu a orientação (o yaw ocioso), volta ao yaw guardado.
func _base_basis(m: Node3D, r: Dictionary) -> Basis:
	if not r.has("base_yaw"):
		r["base_yaw"] = m.rotation.y
	if r.has("last_basis") and m.basis.is_equal_approx(r["last_basis"] as Basis):
		return (r["prev_basis_rot"] as Basis).inverse() * m.basis
	return Basis(Vector3.UP, float(r["base_yaw"]))


## Caixa do corpo medida dos meshes reais do modelo (mundo): altura e largura. Escala com o personagem (D-235).
func _body_box(c: Combatant) -> Dictionary:
	var out := {"h": 1.8, "w": 1.0, "top": 1.8}
	if c == null or not fx._models.has(c):
		return out
	var box := AABB()
	var first := true
	for mi in VfxLib.meshes_of(fx._models[c]):
		if not mi.visible:
			continue
		var wb: AABB = mi.global_transform * mi.get_aabb()
		box = wb if first else box.merge(wb)
		first = false
	if first:
		return out
	out["h"] = maxf(box.size.y, 0.3)
	out["top"] = box.end.y
	out["w"] = maxf(maxf(box.size.x, box.size.z), 0.3)
	return out


## Arcos de vento em volta do corpo, no plano da cambalhota (como aros de uma roda): três faixas abertas com o shader
## wind_swirl, eixo = eixo lateral do recuo, tamanho medido do modelo (D-235). Giram junto com o corpo.
func _make_wind(c: Combatant, lat: Vector3) -> Node3D:
	var box := _body_box(c)
	var height := float(box["h"])
	# Raio = meia diagonal do corpo (altura x largura): o arco abraça o personagem, qualquer que seja o tamanho do modelo.
	var radius := sqrt(pow(height * 0.5, 2.0) + pow(float(box["w"]) * 0.5, 2.0)) * 1.1
	var root := Node3D.new()
	root.name = "KnockupWind"
	root.top_level = true
	fx.add_child(root)
	if lat.length() > 0.001:
		root.basis = Basis(Quaternion(Vector3.UP, lat.normalized()))  # o eixo Y local do anel = eixo lateral
	var bands := [[-0.30, 1.0], [0.0, 1.15], [0.30, 1.0]]  ## [posição ao longo do eixo (x raio), raio relativo]
	for i in range(bands.size()):
		var band: Array = bands[i]
		var node := MeshInstance3D.new()
		node.name = "WindBand%d" % i
		var rr := radius * float(band[1])
		node.mesh = MESHES.open_frustum(rr * 2.0, rr * 1.9, height * 0.22, 48)
		node.position = Vector3(0.0, radius * float(band[0]), 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = WIND_SHADER
		mat.set_shader_parameter("u_streaks", 3.0 + float(i))  # poucos riscos longos: leem como arcos
		mat.set_shader_parameter("u_speed", 0.6)  # os riscos quase não correm sozinhos: o giro do corpo já os leva
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	return root


func _update_wind(root: Node3D, r: Dictionary, t: float, air: float, _delta: float) -> void:
	if r.has("center_pos"):
		root.global_position = r["center_pos"] as Vector3
	var k := clampf(t / maxf(air, 0.001), 0.0, 1.0)
	var fade := smoothstep(0.0, 0.08, k) * (1.0 - smoothstep(0.92, 1.0, k))
	var angle := float(r.get("angle", 0.0))
	var i := 0
	for n in root.get_children():
		var node := n as MeshInstance3D
		var mat := node.material_override as ShaderMaterial
		mat.set_shader_parameter("u_time", fx.clock)
		mat.set_shader_parameter("u_alpha", fade)
		node.rotation.y = angle  # giram exatamente junto com o corpo
		i += 1


func _free_wind(r: Dictionary) -> void:
	var wind = r.get("wind", null)
	if wind != null and is_instance_valid(wind):
		(wind as Node).queue_free()
	r["wind"] = null


## Pouso: impactinho com tremor de camera e anel de poeira, medidos da posicao real (D-235).
func _land(r: Dictionary, m: Node3D) -> void:
	var pos := Vector3(m.global_position.x, 0.0, m.global_position.z)
	var dust := float(r.get("land_dust", 0.0))
	if dust > 0.0:
		var earth: Dictionary = MATERIALS.PALETTE_EARTH_DIG
		DUST_FX.veil_and_shock_ring(fx, pos, dust * 0.6, dust * 0.9, 0.7, 0.0, earth)
		DUST_FX.cloud_ring(fx, pos, 6, dust * 0.5, dust * 0.5, 0.8, 0.0, earth)
		fx._shock(pos, Color(0.95, 0.88, 0.75), dust * 2.2, 0.35)
	var shake := float(r.get("land_shake", 0.0))
	if shake > 0.0 and fx.cam != null:
		fx.cam.hit_shake(r.get("dir", Vector3.FORWARD), false, shake)


## Soltar tudo o que a reação segurou: o vento e a animação congelada (se o alvo morreu ou a batalha acabou antes do pouso).
func _cleanup(r: Dictionary) -> void:
	_free_wind(r)
	var rc: Combatant = r.get("c", null)
	if rc != null and fx._models.has(rc) and is_instance_valid(fx._models[rc]):
		fx._models[rc].remove_meta("tag_home")
	if int(r.get("anim_stage", 0)) == 2:
		_unfreeze_anim(r)
		r["anim_stage"] = 3


const ANIM_CONTACT_AT := 0.08  ## segundos depois do acerto em que a animação de dano trava (o pose de contato)


## Animação de queda/dano do Knock-up: trava no contato durante o voo e termina depois de aterrissar (criador).
## 0: invalida o retorno ao idle que o BattleFx agendou para o dano normal; 1: trava no contato; 2: solta no pouso e agenda o idle.
func _drive_anim(r: Dictionary, c: Combatant, t: float, air: float) -> void:
	var stage := int(r.get("anim_stage", 0))
	var ap: AnimationPlayer = fx.fx_motion._anim_player(c)
	if stage == 0:
		fx.fx_motion._react_token[c] = int(fx.fx_motion._react_token.get(c, 0)) + 1  # o idle agendado pelo dano comum não vale
		fx._busy_for(c, air + 0.6)
		r["anim_stage"] = 1
		return
	if t < air:
		# Enquanto está no ar nenhum retorno ao idle agendado pelo dano comum (que pode começar depois do hit-stop) vale.
		fx.fx_motion._react_token[c] = int(fx.fx_motion._react_token.get(c, 0)) + 1
	if ap == null or not ap.has_animation("damage"):
		return
	if stage == 1 and t >= ANIM_CONTACT_AT and t < air:
		if ap.current_animation != "damage":
			ap.play("damage", 0.0)
		fx.fx_motion._freeze(ap)
		r["anim_pos"] = ap.current_animation_position
		r["anim_stage"] = 2
	elif stage == 2 and t < air:
		# Segura o pose de contato: se outro sistema trocou o clipe (idle), devolve o dano no mesmo ponto.
		if ap.current_animation != "damage":
			ap.play("damage", 0.0)
			ap.seek(float(r.get("anim_pos", 0.0)), true)
	elif stage == 2 and t >= air:
		_unfreeze_anim(r)
		r["anim_stage"] = 3
		# termina o que sobrou do clipe e só então volta ao idle
		var left := 0.3
		if ap.current_animation == "damage":
			left = clampf(ap.current_animation_length - ap.current_animation_position, 0.15, 0.8)
		var token: int = int(fx.fx_motion._react_token.get(c, 0))
		fx.get_tree().create_timer(left + 0.1, false).timeout.connect(func() -> void:
			if c != null and c.is_alive() and token == int(fx.fx_motion._react_token.get(c, 0)):
				fx.fx_motion._reset_idle(c))


func _unfreeze_anim(r: Dictionary) -> void:
	var c: Combatant = r["c"]
	if c != null:
		fx.fx_motion._unfreeze(fx.fx_motion._anim_player(c))
