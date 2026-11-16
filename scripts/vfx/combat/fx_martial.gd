class_name FxMartial
extends RefCounted
## Karate Chop (`golpe_carate`), opção A do HTML "toon construct" (D-1209): a mão marrom
## holográfica do shuto, corte a -38°.
##
## O `Battle`/`Incoming` continua dono do relógio (D-019): este módulo só lê `phase`,
## `phase_time`, `total_windup`, `time_left`, `plan`, `stand`, `dir` e `interrupted`, e as
## medidas reais dos modelos; ele não decide acerto, dano nem tempo (D-1040). Nada depende
## de personagem, time, lado ou coordenada fixa (D-235): o eixo é atacante -> alvo reais,
## o lateral é UP x eixo, e a posição e a altura do alvo saem do próprio modelo. Tudo marrom
## (D-1209), sem tremor/zoom de câmera, sem luz pontual e sem flash de tela.
##
## Linha do tempo (segundos desde a declaração; W = total_windup; contato = fim do STRIKE):
##   0.00-0.08   WINDUP: focus snap marrom (4 barras + anel de chão, <=0.25 s)
##   0.05-(W-0.10) WINDUP: a mão se materializa no ombro (form 0 -> 1, fecha no fim)
##   0.40-W      WINDUP: pow(t,1.45) do ombro até a posição de saque, relativa ao corpo
##   TRAVEL      a mão fica COLADA ao corpo no saque e corre com ele, saltando a cada passo
##               (arco |sin|, período = clipe de corrida / 2)
##   STRIKE      início: o corpo salta e a mão se apronta, subindo ALTO até o cut_start e
##               crescendo de x1.0 a x1.35, armada ARMED_HOLD antes da janela
##               janela [contato-0.08, contato+0.08]: diagonal completa cut_start -> cut_end
##               em curva S, cruzando o centro no contato; 1 ghost em s=0.30
##   PÓS         deriva no sentido do corte com atrito (ease-out) e continua visível até o
##               pouso (contato + hold); só então dissolve devagar em RETURN_DISSOLVE
## O corpo do impacto é de `fx_impacts.gd` (outra tarefa): aqui o contato só marca a janela.

const Phase = Incoming.Phase
const HAND := preload("res://scripts/vfx/combat/fx_martial_hand.gd")

const KARATE := "golpe_carate"
const CUT_ANGLE := -0.66  ## criador (D-1209): corte a -38° no plano do eixo
const WINDUP_TILT := 0.28  ## dedos inclinados para cima na pose de saque
const CUT_FINGERS_FWD := 0.81  ## HTML: os dedos vão ~(0.81 frente, -0.59 baixo) no corte
const CUT_FINGERS_DOWN := 0.59
const WINDUP_ACCEL := 1.45  ## HTML: pow(t, 1.45), aceleração tardia do saque
const HAND_UNIT := 0.77  ## D-1209: 0.45 x1.7 (min. 70% maior). A versão x1.4 ficou grande demais (criador); o valor é escolha da IA
const HAND_UNIT_MIN := 1.02  ## 0.6 x 1.7
const HAND_UNIT_MAX := 2.04  ## 1.2 x 1.7
const RING_AT := 0.08
const SNAP_HEIGHT := 0.65  ## HTML: 65% da altura do atacante
const SNAP_LEAD := 0.55  ## HTML: 0.55 m à frente do atacante
const SNAP_D0 := 0.62
const SNAP_D1 := 0.19
const SNAP_ALPHA := 0.81
const SNAP_BAR := 0.399
const SNAP_BAR_THIN := 0.043
const SNAP_RING_D := 1.28
const SNAP_LIFE := 0.22
const SNAP_RING_LIFE := 0.25
const FORM_IN := 0.05
const FORM_LAST := 0.10  ## 100% formada só perto do fim do wind-up (HTML: cT*1.15)
const WINDUP_ARC := 0.40
const CUT_HALF := 0.08  ## metade da janela do corte (0.16 s no total; Motion Lens: chicote de ~0.17 s)
const PRELUDE_T := 0.20  ## criador: subir, virar e atacar "TUDO ISSO EM .20 SEGUNDOS DO PRELUDE" (antes disso a mão só corre com o corpo)
const PRELUDE_RISE := 0.60  ## fração do prelúdio gasta SUBINDO até o alto; o resto é VIRAR a lâmina e entrar em cut_start
const PRELUDE_TOP := 0.45  ## altura do ponto alto acima de cut_start, em frações de `reach`
const GROW_EXTRA := 0.35  ## criador (rodada 2): a mão cresce +35% durante a subida até a janela
const GROW_EASE := 2.0  ## ease-out (expoente) da subida e do crescimento
const JUMP_RISE := 0.60  ## criador: "sobe ALTO" no salto; altura do arco em corpos do atacante
const RUN_STEP_RISE := 0.10  ## criador: cada passo do TRAVEL é um arco |sin| desta fração do corpo
const RUN_STEP_FALLBACK := 0.40  ## período do passo (s) quando o atacante não tem clipe "run"
const ARMED_TREMOR := 0.6  ## fração do tremor decorativo enquanto espera armada em cut_start
const RETURN_DISSOLVE := 0.85  ## D-1209: a mão fica e some devagar por 0.85 s depois do ataque
const FOLLOW_FRACTION := 0.5  ## criador (rodada 2): deslize total do pós-impacto = 0.5 x reach
const FOLLOW_EASE := 4.0  ## desaceleração exponencial (ease-out) do deslize
const FLOOR_FRACTION := 0.25  ## a mão nunca desce abaixo de 0.25 x unit
const CANCEL_DISSOLVE := 0.12
const GHOST_AT := 0.30  ## HTML: um único fantasma, a 30% da janela do corte
const GHOST_ALPHA := 0.42
const GHOST_LIFE := 0.16
const TREMOR_TAIL := 0.30
const TREMOR_AMP := 0.01
const BODY_FALLBACK_H := 1.6  ## só quando o corpo do modelo não pode ser medido
const BROWN_LIGHT := Color(1.0, 1.0, 1.0, 0.0)  ## foco branco (D-1209: tudo branco); o alpha é do tween

var fx: BattleFx
var _active: Dictionary = {}  ## Incoming -> estado da mão


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


static func is_martial(inc) -> bool:
	return inc != null and _move_id_of(inc) == KARATE


static func _move_id_of(inc) -> String:
	var id := String(inc.move_id)
	return id if id != "" else BattleFx.normalize_move_id(String(inc.label))


## Telegraph: o Move foi declarado. O Brick Break entra neste mesmo `match` (D-1209).
func start(inc) -> void:
	if inc == null or _active.has(inc):
		return
	match _move_id_of(inc):
		KARATE:
			_start_karate(inc)


func _start_karate(inc) -> void:
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	if a == null or not fx._models.has(a):
		return
	var ah := _body_height(fx._models.get(a))
	var th := _body_height(fx._models.get(t)) if t != null else BODY_FALLBACK_H
	# Far away the same metres are a speck on screen: grow with the camera distance, like the Fire Bullet hand does.
	var dist_k := clampf(fx.vfx_scale_at((fx._models[a] as Node3D).global_position), 1.0, 2.2)  # far = a speck on screen; the base size is now the one the creator asked for
	var unit := clampf(ah * HAND_UNIT * dist_k, HAND_UNIT_MIN, HAND_UNIT_MAX)
	var hand = HAND.create(fx, unit)
	if hand == null:
		return
	hand.set_look(0.0, 0.0, 0.0)
	_active[inc] = {
		"hand": hand,
		"ah": ah,
		"th": th,
		"unit": unit,
		"ring": false,
		"ghost": false,
	}


func cancel(inc) -> void:
	if not _active.has(inc):
		return
	var st: Dictionary = _active[inc]
	st["stage"] = "cancel"  # D-1218: assignment only, before the hand is released
	_active.erase(inc)
	_dissolve_and_free(st.get("hand"))


func clear_all() -> void:
	for inc in _active.keys().duplicate():
		cancel(inc)


## Segundos desde o início do Move, pelas fases reais do jogo (a pausa congela os relógios).
func cast_time(inc) -> float:
	if inc.phase == Phase.WINDUP:
		return clampf(float(inc.total_windup) - maxf(float(inc.time_left), 0.0), 0.0, float(inc.total_windup))
	var t := float(inc.total_windup)
	for i in range(mini(int(inc.plan_i), inc.plan.size())):
		t += float(inc.plan[i][1])
	return t + float(inc.phase_time)


func process(delta: float) -> void:
	for inc in _active.keys().duplicate():
		var st: Dictionary = _active[inc]
		var a: Combatant = inc.attacker
		var posting := st.has("post_t")  # after the hit the hand outlives the attack and fades on its own (D-1209)
		if a == null or not fx._models.has(a):
			cancel(inc)
		elif posting:
			_post(inc, st, delta)
		elif inc.interrupted or inc.phase == Phase.STAGGER:
			# Only a REAL interruption before the cut cuts the hand short (D-1209): a hit taken
			# after the contact must not erase the hand, so it keeps its own cosmetic tail.
			var contact := _contact(inc)
			if inc.impacted and contact >= 0.0 and cast_time(inc) >= contact - CUT_HALF:
				_drive(inc, st, delta)
			else:
				cancel(inc)
		elif inc.phase == Phase.DONE:
			# DONE is not a hit: a one-segment plan ends the engine timeline exactly at the
			# contact, so the hand keeps its own cosmetic tail instead of vanishing (D-1209).
			if inc.impacted and _contact(inc) >= 0.0:
				_drive(inc, st, delta)
			else:
				cancel(inc)
		else:
			_drive(inc, st, delta)
		if _active.has(inc):
			_sample_speed(st, delta)  # D-1218: speed from this frame's pose, on the real process delta


func _drive(inc, st: Dictionary, delta: float) -> void:
	var hand = st.get("hand")
	if hand == null or not is_instance_valid(hand):
		_active.erase(inc)
		return
	var t: Combatant = inc.target
	var a_pos: Vector3 = (fx._models[inc.attacker] as Node3D).global_position
	var t_pos := _target_pos(inc, t, a_pos)
	var dir := _dir(inc, a_pos, t_pos)
	# `UP x dir` is the attacker's LEFT; `cut_start = center - cut_dir*reach` flips it back, so the
	# hand flies to the target's upper right seen from the attacker (dir x UP would be its right).
	var right := Vector3.UP.cross(dir).normalized()
	var cut_dir := (right * cos(CUT_ANGLE) + Vector3.UP * sin(CUT_ANGLE)).normalized()
	var ah := float(st["ah"])
	var th := float(st["th"])
	var unit := float(st["unit"])
	# D-1209: exactly the centre of the target body. D-1218 (telemetry found it): the body box jumps ~6 m
	# when the target's own hit reaction / impact FX start, which teleported the hand mid-cut. The centre
	# is therefore measured live only until the cut window opens and frozen from then on.
	var center: Vector3
	if st.has("center") and bool(st.get("center_locked", false)):
		center = st["center"]
	else:
		center = _body_center(t, t_pos, th)
		st["center"] = center
	var reach := clampf(0.8 * th, 0.9, 1.25)  # diagonal inteira de ate 2.5 m (D-1033)
	var cut_start := center - cut_dir * reach
	var cut_end := center + cut_dir * reach
	var contact := _contact(inc)
	var t_now := cast_time(inc)
	st["geo"] = {"a": a_pos, "c": center, "cs": cut_start, "ce": cut_end, "dir": dir}  # D-1218: telemetry only
	# D-1209/D-1218: the engine clock stalls at the contact (the plan ends there) and again at DONE, which froze
	# the hand mid-cut for ~0.14 s in the telemetry. This own cosmetic clock follows the engine while it
	# advances and keeps running on the real delta when it stalls, so the cut and the tail never stop.
	var prev_tn := float(st.get("tn", -1.0))
	if prev_tn >= 0.0 and t_now <= prev_tn + 0.0005:
		t_now = prev_tn + delta
	st["tn"] = t_now
	var w := maxf(float(inc.total_windup), 0.001)
	var win0 := contact - CUT_HALF
	var win1 := contact + CUT_HALF
	if contact >= 0.0 and t_now >= win0 - PRELUDE_T:
		st["center_locked"] = true  # frozen for the rest of the move (next frame onwards)
	var draw_pos := a_pos + Vector3.UP * (0.55 * ah) + dir * (0.42 * ah)  # saque, relativo ao corpo
	var edge := cut_dir  # which side of the hand leads: straight up in the prelude, the cut direction in the cut
	var fingers := (dir * cos(WINDUP_TILT) + Vector3.UP * sin(WINDUP_TILT)).normalized()
	# HTML: no corte a aresta do mindinho (+X) lidera descendo; dedos frente-baixo.
	var fingers_cut := (dir * CUT_FINGERS_FWD - Vector3.UP * CUT_FINGERS_DOWN).normalized()
	var pos := draw_pos
	var form := 0.0
	var grow := 1.0
	var dissolve := 0.0
	var fade := 0.9
	var ghosts: Array = []

	if inc.phase == Phase.WINDUP:
		st["stage"] = "windup"  # D-1218: assignment only, never poses or times anything
		var shoulder := a_pos + Vector3.UP * (0.80 * ah) + right * (0.16 * ah)
		if not bool(st["ring"]) and t_now <= RING_AT:
			st["ring"] = true
			_focus_snap(a_pos + Vector3.UP * (SNAP_HEIGHT * ah) + dir * SNAP_LEAD, a_pos + Vector3.UP * (0.5 * ah), a_pos.y)
		# a mão só fecha perto do fim do wind-up (HTML: updateShader(min(1, cT*1.15)))
		form = smoothstep(FORM_IN, maxf(w - FORM_LAST, FORM_IN + 0.001), t_now)
		if t_now < WINDUP_ARC:
			pos = shoulder
		else:
			var q := clampf((t_now - WINDUP_ARC) / maxf(w - WINDUP_ARC, 0.001), 0.0, 1.0)
			var draw := pow(q, WINDUP_ACCEL)  # HTML: aceleração tardia até o saque
			pos = shoulder.lerp(draw_pos, draw) + Vector3.UP * (sin(draw * PI) * 0.12 * unit)
		pos += _tremor(t_now, w, unit, right, cut_dir)
	else:
		form = 1.0  # the hand NEVER disappears during the run: it rides the body until the cut
		fade = 1.0
		st["stage"] = "run"  # D-1218: TRAVEL, riding the body and hopping each step
		var pre0 := win0 - PRELUDE_T  # D-1209: the whole prelude (up, turn) lasts PRELUDE_T, right before the cut
		var ride := draw_pos + _run_step(t_now - w, inc.attacker, ah)  # TRAVEL: the hand runs with the body, hopping each step
		if contact < 0.0 or t_now < pre0:
			pos = ride
		elif t_now < win0:
			st["stage"] = "jump"  # D-1218: the rise + the turn, still before the cut window
			# PRELUDE (criador): the hand MOVES UP over the target, TURNS the blade and gets into cut_start, all in
			# PRELUDE_T; the cut that follows is the full diagonal. Continuous every frame: no teleport, no hold.
			var q := clampf((t_now - pre0) / PRELUDE_T, 0.0, 1.0)
			var top := cut_start + Vector3.UP * (PRELUDE_TOP * reach)
			top.y = maxf(top.y, ride.y)  # criador: a mão SOBE por cima do alvo, nunca desce no prelúdio (D-1218)
			var q1 := clampf(q / PRELUDE_RISE, 0.0, 1.0)
			var q2 := clampf((q - PRELUDE_RISE) / (1.0 - PRELUDE_RISE), 0.0, 1.0)
			var up_k := 1.0 - pow(1.0 - q1, GROW_EASE)  # fast rise, ease-out
			var turn_k := smoothstep(0.0, 1.0, q2)  # the turn: blade edge swings from straight up to the cut direction
			pos = ride.lerp(top, up_k) if q2 <= 0.0 else top.lerp(cut_start, turn_k)
			edge = Vector3.UP.lerp(cut_dir, turn_k).normalized()
			fingers = fingers.lerp(fingers_cut, q).normalized()
			grow = 1.0 + GROW_EXTRA * up_k
		else:
			st["stage"] = "cut"  # D-1218: inside the 0.16 s cut window
			var s := clampf((t_now - win0) / (2.0 * CUT_HALF), 0.0, 1.0)
			var curve := 2.0 * s * s
			if s >= 0.5:
				var u := -2.0 * s + 2.0
				curve = 1.0 - u * u * 0.5
			pos = cut_start.lerp(cut_end, curve)  # diagonal completa, cruzando o centro no contato
			fingers = fingers_cut
			grow = 1.0 + GROW_EXTRA
			if s >= GHOST_AT and not bool(st["ghost"]):
				st["ghost"] = true
				ghosts.append([GHOST_ALPHA, GHOST_LIFE])
		if contact >= 0.0 and t_now >= win1:
			# the cut is done: the hand keeps going with friction, stays fully visible until the
			# body lands (contact + hold) and only then fades for RETURN_DISSOLVE, even after
			# the Move ends (D-1209)
			st["post_t"] = 0.0
			st["end"] = cut_end
			st["cut_dir"] = cut_dir
			st["fingers"] = fingers_cut
			st["slide"] = FOLLOW_FRACTION * reach
			st["wait"] = maxf(float(inc.hold) - CUT_HALF, 0.0)  # landing = contact + hold; the cut ends at contact + CUT_HALF
			_post(inc, st, 0.0)
			return

	hand.pose_knife(pos, fingers, edge)
	hand.set_look(form, dissolve, fade)
	hand.set_grow(grow)
	for g in ghosts:
		hand.ghost(float(g[0]), float(g[1]))


## Fim do STRIKE: W + todos os segmentos do plano até STRIKE inclusive (o contato).
func _contact(inc) -> float:
	if inc.plan.is_empty():
		return -1.0
	var t := float(inc.total_windup)
	for seg in inc.plan:
		t += float(seg[1])
		if int(seg[0]) == Phase.STRIKE:
			return t
	return -1.0


## Início do STRIKE: W + os segmentos anteriores (é quando o corpo começa a saltar).
func _strike_start(inc) -> float:
	if inc.plan.is_empty():
		return -1.0
	var t := float(inc.total_windup)
	for seg in inc.plan:
		if int(seg[0]) == Phase.STRIKE:
			return t
		t += float(seg[1])
	return -1.0


func _target_pos(inc, t: Combatant, a_pos: Vector3) -> Vector3:
	if t != null and fx._models.has(t):
		var m: Node3D = fx._models[t]
		if is_instance_valid(m):
			return m.global_position
	if inc.stand != Vector3.ZERO:
		return inc.stand
	return a_pos + Vector3(0.0, 0.0, BattleSpace.STAND_GAP)


func _dir(inc, a_pos: Vector3, t_pos: Vector3) -> Vector3:
	var d := Vector3(inc.dir.x, 0.0, inc.dir.z)
	if d.length_squared() < 1e-6:
		d = Vector3(t_pos.x - a_pos.x, 0.0, t_pos.z - a_pos.z)
	return d.normalized() if d.length_squared() > 1e-6 else Vector3.FORWARD


## D-235: altura real do corpo (caixa em espaço de mundo), a mesma medida de FxArmor e MP.
func _body_height(m: Node3D) -> float:
	if m == null or not is_instance_valid(m) or fx.fx_armor == null:
		return BODY_FALLBACK_H
	var box: AABB = fx.fx_armor.body_box_of(m)
	return box.size.y if box.size.y > 0.1 else BODY_FALLBACK_H


## Tremor decorativo mínimo, crescente nos últimos 0.30 s do wind-up.
## Real centre of the target body (world AABB centre); falls back to 58% of its height.
func _body_center(t: Combatant, t_pos: Vector3, th: float) -> Vector3:
	if t != null and fx._models.has(t) and fx.fx_armor != null:
		var m: Node3D = fx._models[t]
		if is_instance_valid(m):
			var box: AABB = fx.fx_armor.body_box_of(m)
			if box.size.y > 0.1:
				return box.get_center()
	return t_pos + Vector3.UP * (0.58 * th)


## After the cut: the hand keeps going along the cut with friction, decelerating (exponential
## ease-out) over 0.5 x reach, and stays fully visible until the body lands (contact + hold).
## Only then it dissolves slowly for RETURN_DISSOLVE, even after the Move ends. Cosmetic only,
## with its own counter; never below the floor.
func _post(inc, st: Dictionary, delta: float) -> void:
	var hand = st.get("hand")
	if hand == null or not is_instance_valid(hand):
		_active.erase(inc)
		return
	st["post_t"] = float(st["post_t"]) + delta
	st["stage"] = "fade" if float(st["post_t"]) >= float(st["wait"]) else "post"  # D-1218: post until the body lands
	var d := clampf(float(st["post_t"]) / RETURN_DISSOLVE, 0.0, 1.0)
	var span := 1.0 - exp(-FOLLOW_EASE)  # normaliza o ease-out: desliza exatamente st["slide"]
	var slide := float(st["slide"]) * (1.0 - exp(-FOLLOW_EASE * d)) / span
	var cut_dir: Vector3 = st["cut_dir"]
	var pos: Vector3 = st["end"] + cut_dir * slide
	pos.y = maxf(pos.y, maxf(float(st["end"].y), FLOOR_FRACTION * float(st["unit"])))  # keeps friction/drift but never sinks to the floor
	# A mão fica inteira visível até o corpo pousar (fim do hold) e SÓ ENTÃO começa o fade
	# lento: contador cosmético próprio, mesmo depois de o Move terminar (D-1209).
	var f := clampf((float(st["post_t"]) - float(st["wait"])) / RETURN_DISSOLVE, 0.0, 1.0)
	hand.pose_knife(pos, st["fingers"], cut_dir)
	hand.set_look(1.0, f * 0.95, 1.0 - f)
	hand.set_grow(1.0 + GROW_EXTRA)
	if f >= 1.0:
		_active.erase(inc)
		_free_hand(hand)


## D-1218: one read-only row per live hand, once per frame, for BattleTrace. It never poses,
## scales, frees or touches a clock (D-019): it only reads what this frame already drew.
func telemetry() -> Array:
	var out: Array = []
	for inc in _active.keys():
		var st: Dictionary = _active[inc]
		var hand = st.get("hand")
		if hand == null or not is_instance_valid(hand):
			continue
		var snap: Dictionary = hand.sample()
		if snap.is_empty():
			continue
		var look: Dictionary = hand.look()
		var a: Combatant = inc.attacker
		var t: Combatant = inc.target
		var contact := _contact(inc)
		out.append({
			"move": _move_id_of(inc),
			"attacker": a.name if a != null else "",
			"target": t.name if t != null else "",
			"pos": snap["pos"],
			"rot": snap["rot"],
			"scale": snap["scale"],
			"fade": snappedf(float(look["fade"]), 0.001),
			"dissolve": snappedf(float(look["dissolve"]), 0.001),
			"form": snappedf(float(look["form"]), 0.001),
			"speed": snappedf(float(st.get("speed", 0.0)), 0.001),
			"stage": String(st.get("stage", "")),
			"contact_in": snappedf(contact - _now_of(inc, st), 0.001),
			"geo": _geo_arrays(st.get("geo", {})),
		})
	return out


## D-1218: the geometry the choreography aims at (attacker, target centre, cut ends, axis), as arrays.
func _geo_arrays(g: Dictionary) -> Dictionary:
	var out := {}
	for k in g:
		var v: Vector3 = g[k]
		out[k] = [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]
	return out


## D-1218: cosmetic clock of this hand; after the cut the post counter keeps it running even
## when the engine timeline has already stopped.
func _now_of(_inc, st: Dictionary) -> float:
	return float(st.get("tn", 0.0))


## D-1218: world speed of the hand from this frame's pose vs the previous one, on the real
## `process` delta. Drawing state only: nothing here drives anything.
func _sample_speed(st: Dictionary, delta: float) -> void:
	var hand = st.get("hand")
	if hand == null or not is_instance_valid(hand):
		return
	var snap: Dictionary = hand.sample()
	if snap.is_empty():
		return
	var p: Array = snap["pos"]
	var pos := Vector3(float(p[0]), float(p[1]), float(p[2]))
	if st.has("last_pos") and delta > 0.0:
		st["speed"] = pos.distance_to(st["last_pos"]) / delta
	else:
		st["speed"] = 0.0
	st["last_pos"] = pos


func _tremor(t: float, w: float, unit: float, right: Vector3, cut_dir: Vector3) -> Vector3:
	var grow := clampf((t - (w - TREMOR_TAIL)) / TREMOR_TAIL, 0.0, 1.0)
	if grow <= 0.0:
		return Vector3.ZERO
	var amp := TREMOR_AMP * unit * grow
	return right * (sin(t * 57.0) * amp) + cut_dir * (cos(t * 43.0) * amp * 0.6)


## Focus snap do HTML (D-1209): 4 barras marrons fecham de 0.62 m a 0.19 m e um anel de chão
## abre de 0.75 a 1.70; tudo cosmético, vida curta e sem luz, liberado sempre.
func _focus_snap(pos: Vector3, look_pos: Vector3, ground_y: float) -> void:
	var look := look_pos - pos
	look = look.normalized() if look.length_squared() > 1e-6 else Vector3.FORWARD
	var tang := look.cross(Vector3.UP)
	tang = tang.normalized() if tang.length_squared() > 1e-6 else Vector3.RIGHT
	var up2 := tang.cross(look).normalized()
	for i in 4:
		var ang := TAU * float(i) / 4.0 + PI * 0.25  # 45/135/225/315 graus
		var radial := (tang * cos(ang) + up2 * sin(ang)).normalized()
		var bar: MeshInstance3D = fx._node(fx._box(Vector3(SNAP_BAR, SNAP_BAR_THIN, SNAP_BAR_THIN)), BROWN_LIGHT, pos)
		bar.basis = Basis(radial, look.cross(radial).normalized(), look)
		bar.global_position = pos
		var mat := bar.material_override as StandardMaterial3D
		var step := func(p: float) -> void:
			bar.global_position = pos + radial * lerpf(SNAP_D0, SNAP_D1, p)
			mat.albedo_color.a = sin(p * PI) * SNAP_ALPHA
		var tw := bar.create_tween()
		tw.tween_method(step, 0.0, 1.0, SNAP_LIFE)
		tw.tween_callback(bar.queue_free)
	var torus := TorusMesh.new()
	torus.inner_radius = SNAP_RING_D * 0.5 - SNAP_BAR_THIN
	torus.outer_radius = SNAP_RING_D * 0.5
	torus.rings = 28
	var ring: MeshInstance3D = fx._node(torus, BROWN_LIGHT, Vector3(pos.x, ground_y + 0.05, pos.z))
	ring.scale = Vector3.ONE * 0.75
	var rmat := ring.material_override as StandardMaterial3D
	var step_ring := func(p: float) -> void:
		rmat.albedo_color.a = sin(p * PI) * SNAP_ALPHA
	var rtw := ring.create_tween().set_parallel(true)
	rtw.tween_property(ring, "scale", Vector3.ONE * 1.70, SNAP_RING_LIFE)
	rtw.tween_method(step_ring, 0.0, 1.0, SNAP_RING_LIFE)
	rtw.chain().tween_callback(ring.queue_free)


## Interrupção/cancelamento: dissolve rápido, só cosmético, e libera sem deixar nó.
func _dissolve_and_free(hand) -> void:
	if hand == null or not is_instance_valid(hand):
		return
	var tw: Tween = hand.create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void: hand.set_look(1.0, v, 1.0 - v), 0.0, 1.0, CANCEL_DISSOLVE)
	tw.chain().tween_callback(_free_hand.bind(hand))


func _free_hand(hand) -> void:
	if hand == null or not is_instance_valid(hand):
		return
	hand.free_now()
	hand.queue_free()


## TRAVEL (D-1209): a mão corre junto com o corpo, saltando a cada passo. Um salto por meio
## período do clipe de corrida; o arco |sin| sobe e desce em fase com o tempo do TRAVEL.
func _run_step(travel_t: float, a: Combatant, ah: float) -> Vector3:
	var period := a.clip_len("run") / 2.0 if a != null else 0.0
	if period <= 0.01:
		period = RUN_STEP_FALLBACK
	return Vector3.UP * (RUN_STEP_RISE * ah * absf(sin(PI * travel_t / period)))


## Tremor decorativo mínimo enquanto a mão espera armada em cut_start (a janela ainda não abriu).
func _armed_tremor(t: float, unit: float, right: Vector3, cut_dir: Vector3) -> Vector3:
	var amp := TREMOR_AMP * unit * ARMED_TREMOR
	return right * (sin(t * 61.0) * amp) + cut_dir * (cos(t * 47.0) * amp * 0.6)
