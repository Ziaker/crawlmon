class_name MotionRep
extends RefCounted
## D-308: a REPRESENTATION (spec section 8, D-044): turns the samples of a composition into a picture. The motion
## stays independent of the look: the same composition can be drawn as flames, streaks, embers, smoke, a 3D fire
## ball or neutral dots. A sample's `width`, `opacity` and `intensity` come from the composition (M10, M12, M17,
## M18, ...), the rep only decides how to paint them.
##
## V1.2 (D-323): every look comes from MotionLooks (fire / water / earth / air), only data:
##         surface - any shape of the composer with the stylized material mc_surface; `shape` = tube | ribbon | blade | arc | shell | fragments
##         spark   - an ember / spark / bright droplet stretched along its motion          (shaders/mc_spark)
##         puff    - a stylized cloud: smoke, steam, dust, mist                            (shaders/mc_puff)
##         drops   - small spheres (droplets, bubbles, pebbles) stretched along the motion (mc_surface)
##         halo    - a stylized light halo at the last sample                              (shaders/mc_halo)
##         mark    - a decorative ground mark under the first sample (burn, puddle, crack, scuff) (shaders/mc_mark)
## kinds:  flames  - camera-facing fire quads (tip along the motion on screen)
##         streaks - fire streaks lying along the motion (or radial from the origin: bursts)
##         embers  - small hot sparks that show up while the sample dissolves
##         smoke   - grey puffs that show up (and drift up) while the sample dissolves
##         orb     - a 3D fire mesh at the last sample (the head)
##         glow    - a soft halo at the last sample
##         scorch  - burn mark on the floor under the first sample
## V1.1 (D-322):
##         tube    - a closed 3D flame tube along each branch of the strand (MotionMesh + shaders/mc_flame_body)
##         bulb    - the same flame shader on a sphere / spindle at the last sample (a charge ball, a head)
##         flipbook- game flipbook sprites (assets/vfx/flipbook_<sheet>.png) at every sample, frame by the sample's age
##                   (V1.9: `progress_source` can be "intensity" for the M26 age, "u" or empty for 1 - opacity)
##         ring    - a heat ring on the floor under the frame origin, closing in as the phase progresses

var kind := "flames"
var size := 0.4
var length := 0.5  ## streaks
var width := 0.1  ## streaks
var taper := 0.0  ## 0 = same size along the strand, > 0 = bigger toward u = 1 (a head)
var blob := 0.35
var radial := false  ## streaks: oriented away from the frame origin (bursts) instead of along the motion
var hot_every := 2  ## streaks: every n-th is the hot (yellow) kind
var drift := Vector3.ZERO  ## embers/smoke: how far they drift over their dissolve
var stride := 1  ## draw every n-th sample
var strength := 1.0
var fade_bias := 0.0
var size_jitter := 0.0  ## flames / embers: random size spread per sample (0 = all equal, 0.6 = from 40% to 160%)
var spark := false  ## flames: painted in the hot-spark palette
# --- V1.1 (D-322): tube / bulb ---
var radius := 0.2  ## tube: radius at the thickest point (metres at scale 1); bulb: use `size`
var profile_pow := 0.8  ## tube: radius ~ u^profile_pow (0 = same thickness all along, 1 = a cone to the tail)
var head_bulge := 0.25  ## tube: extra thickness at the head
var sides := 12  ## tube: sides around
var max_rings := 56  ## tube: points used along a branch (the strand is resampled down to this)
var flip := false  ## tube: the first sample is the thick base and the last the eroding tip (tongues that start at a contact point)
var expand := false  ## ring D-953: true = the ring opens and fades (a shockwave); false = it closes in (the old heat ring)
var light_range := 5.0  ## light D-953: omni range (metres); `strength` is the energy multiplier
var sheet := "fire"  ## flipbook: which flipbook (fire, impact, smoke, ...)
var color := Color(1, 1, 1, 1)  ## flipbook
var energy := 2.0  ## flipbook
var rate := 0.7  ## flame_life: life cycles per second (each flame also gets its own rate)
var rise := 1.6  ## flame_life: how far a flame climbs in its life (m)
var sway := 0.35  ## flame_life: side drift while it climbs (m)
var trail := false  ## spark: draw a streak from where the sample was (needs the layer option trail_dt) to where it is
var trail_gain := 1.0  ## spark: streak length multiplier
var grow := 0.0  ## fireball: seconds the ball takes to grow from 0.05 to 1.05 of its size (0 = full size)
var duration := 1.0  ## vortex_disc / pillar: life of the effect in seconds (progress = local time / duration)
var age_u := false  ## flipbook / puff: age by position along the strand (tail = old) instead of by dissolve
var progress_source := ""  ## flipbook V1.9 (D-343): "intensity" (M26 age t) or "u"; empty = 1 - opacity
var tint := false  ## flipbook D-953: multiply the sheet by `color` (mc_sprite_tint); existing presets keep false
var follow := false  ## cel_flame: the tip turns toward the motion (false = the tip stays up on screen)
var sway_speed := 1.4  ## cel_flame: cycles of sway per second
var element := "fire"  ## V1.2: which element's MotionLooks to use
var shape := "tube"  ## surface: tube | ribbon | blade | arc | shell | fragments | flame (a flame ribbon: round base, thin tip)
var shader := "mc_surface"  ## surface: which material (mc_surface, mc_fire_ribbon)
var spin := 0.0  ## fragments: radians per second
var stretch := 2.5  ## spark / drops: how long along the motion
var appear := 1  ## puff: 1 = shows while the sample dissolves (residue), 0 = shows whole while it lives
var camera_facing := true  ## ribbon / blade / arc: the strip faces the camera (false = lies flat, face = UP)
var look := {}  ## tube / bulb: overrides of the shader uniforms (colours, flow, lick, rise, noise_scale, swirl, bias, tail_erode)
# --- V1.10 (D-377): lança da Drain Spear ---
var spear_mode := "none"  ## "reveal" (cresce do cabo à ponta), "dissolve" (apaga do cabo à ponta) ou "none"
var spear_part := "full"  ## D-378: "full" (cabo + lâmina), "shaft" ou "blade"
var blade_length := 1.0  ## D-378: comprimento fixo da lâmina na ponta (metros); o cabo é o resto
var ghosts := 0  ## cópias atrasadas da lança na estocada (pós-imagens)
var ghost_gap := 0.10  ## fração do comprimento entre as pós-imagens
var ghost_alpha := 0.22  ## opacidade de cada pós-imagem
# --- D-378: aura em faixas espirais ---
var aura_bands := 6  ## 6 faixas no total (D-378)
var aura_radius := 0.46  ## raio da hélice em volta do cabo (metros)
var aura_width := 0.055  ## largura da fita (metros)
var aura_turns := 2.4  ## voltas ao longo da lança inteira
var aura_spin := 0.55  ## voltas por segundo (o giro é derivado do relógio do efeito)
var aura_opacity := 0.18  ## baixa opacidade, como pedido
var aura_energy := 1.25
var aura_color := Color(0.32, 0.82, 1.0, 1.0)
# --- D-379: vórtice helicoidal do início da estocada ---
var vortex_bands := 10
var vortex_length := 3.0  ## metros atrás da ponta
var vortex_radius := 1.10  ## raio na base do vórtice
var vortex_end_radius := 0.08  ## raio na ponta (afina como uma broca)
var vortex_turns := 3.2
var vortex_spin := 4.2  ## voltas por segundo (giro de ventilador)
var vortex_width := 0.12
var vortex_split := 0.0  ## D-1015: m each band drifts outward as the vortex fades (0 = off)
var vortex_opacity := 0.55
var vortex_energy := 3.2
var vortex_color := Color(0.55, 0.95, 1.0, 1.0)
var vortex_base_length := 5.0  ## segundo cone, a partir da mão: é o "boost" visível no início
var vortex_base_radius := 1.80
var vortex_base_end_radius := 0.25
var vortex_cone_opacity := 0.42
var vortex_cone_energy := 3.2


func _jit(id: int) -> float:
	if size_jitter <= 0.0:
		return 1.0
	var h := float((id * 2654435761) & 0xFFFF) / 65535.0
	return 1.0 - size_jitter + 2.0 * size_jitter * h


static func make(p_kind: String, opts := {}) -> MotionRep:
	var r := MotionRep.new()
	r.kind = p_kind
	for k in opts.keys():
		r.set(k, opts[k])
	return r


## items: Array of {pos, tan, u, width, opacity, intensity, id}, already in world space. `origin` is the world
## origin of the layer's frame, `k` is the 0..1 progress of the phase (growth of heads, etc.).
func draw(painter: MotionPainter, items: Array, origin: Vector3, k: float, sc := 1.0) -> void:
	if items.is_empty():
		return
	match kind:
		"flames":
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var s := float(it["u"])
				var sz := size * sc * float(it["width"]) * (1.0 + taper * pow(s, 0.7)) * _jit(int(it["id"]))
				var tan_v: Vector3 = it["tan"]
				painter.flame(it["pos"], sz, float(it["intensity"]), painter.roll_for(tan_v) if tan_v.length() > 0.01 else 0.0,
					clampf(1.0 - float(it["opacity"]) + fade_bias + 0.85 * pow(1.0 - s, 1.4) * (1.0 if taper > 0.0 else 0.0), 0.0, 0.99), blob, float(int(it["id"]) % 997) * 0.37, spark)
		"streaks":
			var n := 0
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var dir_w: Vector3 = (Vector3(it["pos"]) - origin) if radial else Vector3(it["tan"])
				if dir_w.length() < 0.001:
					continue
				n += 1
				painter.streak(it["pos"], dir_w, length * sc * float(it["width"]) * strength, width * sc, clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99), (n % hot_every) == 0)
		"embers":
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var prog := 1.0 - float(it["opacity"])  # dissolve progress of this sample
				if prog < 0.04 or prog > 0.995:
					continue
				var vis := 1.0 - pow(sin(PI * prog), 0.7)  # visible mid-dissolve, gone at the end
				painter.flame(Vector3(it["pos"]) + drift * sc * prog, size * sc * (1.0 - 0.5 * prog) * _jit(int(it["id"])), 1.0, 0.0, clampf(vis, 0.0, 0.99), 1.0, float(int(it["id"]) % 997) * 0.51, true)
		"smoke":
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var prog := 1.0 - float(it["opacity"])
				if prog < 0.25 or prog > 0.995:
					continue
				var a := 0.7 * sin(PI * clampf((prog - 0.25) / 0.75, 0.0, 1.0))
				painter.smoke(Vector3(it["pos"]) + drift * sc * prog, size * sc * (0.7 + 0.8 * prog), a, float(int(it["id"]) % 997) * 0.29)
		"orb":
			var last: Dictionary = items[items.size() - 1]
			var tan_v: Vector3 = last["tan"]
			var r := size * sc * float(last["width"])
			painter.orb(last["pos"], r, strength, clampf(1.0 - float(last["opacity"]), 0.0, 0.99), tan_v if tan_v.length() > 0.01 else Vector3.UP, r * 2.0 * (1.0 + taper), 5.0, 4.0)
		"glow":
			var last2: Dictionary = items[items.size() - 1]
			painter.glow(last2["pos"], size * sc * float(last2["width"]), strength * float(last2["opacity"]))
		"tube":
			var groups: Dictionary = {}
			for it in items:
				var key := String(it.get("branch", "root"))
				if not groups.has(key):
					groups[key] = []
				(groups[key] as Array).append(it)
			for key in groups.keys():
				var g: Array = groups[key]
				if g.size() < 2:
					continue
				if flip:
					g.reverse()
				var step := maxi(1, int(ceil(float(g.size()) / float(max_rings))))
				var pts := PackedVector3Array()
				var rad := PackedFloat32Array()
				var dis := PackedFloat32Array()
				var inten := PackedFloat32Array()
				var i := 0
				while true:
					var it: Dictionary = g[i]
					var uu := float(it["u"]) if not flip else 1.0 - float(it["u"])
					pts.append(it["pos"])
					rad.append(radius * sc * float(it["width"]) * pow(clampf(uu, 0.0, 1.0), profile_pow) * (1.0 + head_bulge * smoothstep(0.8, 1.0, uu)))
					dis.append(clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 1.0))
					inten.append(float(it["intensity"]) * strength)
					if i == g.size() - 1:
						break
					i = mini(i + step, g.size() - 1)
				var p := look.duplicate()
				p["seed"] = float(int(String(key).hash()) % 997) * 0.37 + float(look.get("seed", 0.0))
				painter.tube(MotionMesh.tube(pts, rad, dis, inten, sides), p)
		"bulb":
			var lastb: Dictionary = items[items.size() - 1]
			var tb: Vector3 = lastb["tan"]
			var rb := size * sc * float(lastb["width"])
			var pb := look.duplicate()
			pb["dissolve"] = clampf(1.0 - float(lastb["opacity"]) + fade_bias, 0.0, 1.0)
			pb["intensity"] = strength * float(lastb["intensity"])
			pb["seed"] = float(look.get("seed", 0.0)) + float(int(lastb["id"]) % 97)
			painter.bulb(lastb["pos"], rb, tb if tb.length() > 0.01 else Vector3.UP, rb * 2.0 * (1.0 + taper), pb)
		"flipbook":
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var prog := 1.0 - float(it["opacity"])
				if progress_source == "intensity":
					prog = float(it["intensity"])  # M26: normalized age (0 = born, 1 = dead)
				elif progress_source == "u" or age_u:
					prog = float(it["u"])
				prog = clampf(prog, 0.0, 1.0)
				painter.flipbook(it["pos"], size * sc * float(it["width"]), prog, sheet, color, energy, float(int(it["id"]) % 360), tint)
		"ring":
			var kk := clampf(k, 0.0, 1.0)
			var ek := 1.0 - pow(1.0 - kk, 3.0)
			var rr := lerpf(size * 0.2, size, ek) if expand else lerpf(size, size * 0.4, ek)
			var aa := (1.0 - kk) if expand else 1.0 - (0.3 + 0.7 * kk) * 0.9
			painter.ring(Vector3(origin.x, 0.05, origin.z), Vector3.UP, rr * sc, aa, strength, 4.0, 0.06)
		"plate":
			# V1.13 (D-1026): every sample is a flat chrome triangular plate; it turns about its own axis (`spin` rad/s, a different axis and
			# rate per sample) and dissolves with the composition's opacity. The size is `size` metres times the sample's width.
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var idn := int(it["id"])
				var h1 := fposmod(sin(float(idn) * 12.9898) * 43758.5453, 1.0)
				var h2 := fposmod(sin(float(idn) * 78.233 + 1.7) * 43758.5453, 1.0)
				var h3 := fposmod(sin(float(idn) * 39.346 + 5.1) * 43758.5453, 1.0)
				var axis := Vector3(h1 - 0.5, h2 - 0.5, h3 - 0.5)
				axis = axis.normalized() if axis.length() > 0.05 else Vector3.UP
				var ang := h3 * TAU + painter.time * spin * (0.5 + h1)
				painter.plate(it["pos"], size * sc * float(it["width"]), Basis(axis, ang), clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99), h2 * 6.28)
		"floor_ring":
			# V1.12 (D-1026): a clean shock ring on the floor that OPENS from the origin and FADES OUT as `k` goes 0 -> 1 (the old `ring`
			# with `expand` fades the other way and is kept untouched for the presets that already use it). The colour comes from `look`.
			var fk := clampf(k, 0.0, 1.0)
			var fe := 1.0 - pow(1.0 - fk, 3.0)
			painter.ring(Vector3(origin.x, 0.05, origin.z), Vector3.UP, lerpf(size * 0.12, size, fe) * sc, fk, strength, 4.0, float(look.get("thick", 0.045)), look)
		"flame_life":
			# V1.5 (D-332): cada amostra do compositor é um EMISSOR; cada emissor solta chamas em ciclos, sem estado: a idade e a semente saem
			# do relógio do efeito e do id (a semente muda a cada ciclo, então cada chama nasce com outra forma, outro balanço e outra
			# velocidade). O compositor dá o campo de posições (M03, M24...); aqui só a vida da chama: sobe, balança, encolhe, esfria.
			var fl := look.duplicate()
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var idn := int(it["id"])
				var h1 := fposmod(sin(float(idn) * 12.9898) * 43758.5453, 1.0)
				var h2 := fposmod(sin(float(idn) * 78.233 + 1.7) * 43758.5453, 1.0)
				var h3 := fposmod(sin(float(idn) * 39.346 + 5.1) * 43758.5453, 1.0)
				var ph := painter.time * rate * (0.65 + 0.7 * h1) + h2
				var cyc := floorf(ph)
				var age := ph - cyc
				var cseed := fposmod(float(idn) * 0.173 + cyc * 7.31, 97.0)
				var env := 0.55 + 0.9 * h3
				var rise_v := rise * (0.55 + 0.9 * h1) * (1.0 - pow(1.0 - age, 2.0))
				var side := sway * (h2 - 0.5) * 2.0 * age + sway * 0.5 * sin(painter.time * (1.0 + h3) + float(idn))
				var dir_up := Vector3.UP
				var fpos := Vector3(it["pos"]) + dir_up * (rise_v + size * sc * env * 0.5) + painter._cam_basis().x * side
				painter.flame_one(fpos, size * sc * env * float(it["width"]), age, cseed, fl)
		"fire_flow":
			# V1.4 (D-332): fogo como campo de calor turbulento (mc_fire_flow). Cada amostra é uma língua de fogo com semente, velocidade
			# e largura próprias; `look` troca as cores (amarelo, laranja, vermelho, queimado, fuligem) ou a turbulência.
			var ff := look.duplicate()
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var idn := int(it["id"])
				ff["width"] = float(look.get("width", 1.0)) * (0.8 + 0.4 * float(idn % 5) / 4.0)
				painter.fire_flow(it["pos"], size * sc * float(it["width"]) * _jit(idn), float(idn % 97), clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99),
					0.75 + 0.1 * float(idn % 7), 0.0, ff)
		"cel_flame":
			# V1.3 (D-332): chama estilizada de contorno nítido. `upright` (padrão) mantém a ponta para cima na tela (fogo sobe);
			# `follow` vira a ponta para onde o fluxo anda. A fase do balanço vem do relógio do efeito + o id (cada chama balança diferente).
			var cf := look.duplicate()
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var tv: Vector3 = it["tan"]
				var rl := painter.roll_for(tv) if (follow and tv.length() > 0.01) else 0.0
				painter.cel_flame(it["pos"], size * sc * float(it["width"]) * _jit(int(it["id"])), clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99),
					float(int(it["id"]) % 97), rl, painter.time * sway_speed + float(int(it["id"]) % 13) * 0.17, cf)
		"sprite":
			# V1.3: flipbook assado, mistura alfa; `sway_speed` = ciclos por segundo; cada amostra começa numa fase diferente.
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var tv: Vector3 = it["tan"]
				painter.sprite(it["pos"], size * sc * float(it["width"]) * _jit(int(it["id"])), painter.time * sway_speed + float(int(it["id"]) % 16) / 16.0,
					sheet, clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99), painter.roll_for(tv) if (follow and tv.length() > 0.01) else 0.0, energy)
		"fireball":
			var fb_item: Dictionary = items[items.size() - 1]
			var gk := 1.05 if grow <= 0.0 else lerpf(0.05, 1.05, clampf(float(fb_item.get("lt", 0.0)) / grow, 0.0, 1.0))
			var fbp := look.duplicate()
			painter.fireball(fb_item["pos"], size * gk * sc * float(fb_item["width"]), float(int(fb_item["id"]) % 97), fbp)
		"vortex_disc":
			var vd_item: Dictionary = items[0]
			var vp := clampf(float(vd_item.get("lt", 0.0)) / maxf(duration, 0.01), 0.0, 1.0)
			var vtan: Vector3 = vd_item["tan"]
			painter.vortex_disc(vd_item["pos"], vtan, 1.76 * (0.45 + vp * 2.15) * size * sc, vp, painter.time * 12.0, look.duplicate())
		"pillar":
			var pl_item: Dictionary = items[0]
			var pp := clampf(float(pl_item.get("lt", 0.0)) / maxf(duration, 0.01), 0.0, 1.0)
			var psxz := lerpf(0.3, 1.15, pp / 0.2) if pp < 0.2 else 1.15 - (pp - 0.2) * 0.3
			var pbase := Vector3(pl_item["pos"])
			painter.pillar(Vector3(pbase.x, 0.0, pbase.z), psxz * size * sc, pp, look.duplicate())
		"surface":
			_draw_surface(painter, items, origin, k, sc)
		"spark":
			var sp := MotionLooks.get_look("spark", element)
			sp.merge(look, true)
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var tv: Vector3 = it["tan"]
				sp["flicker_seed"] = float(int(it["id"]) % 997) * 0.37
				if trail and it.has("prev"):
					var dv: Vector3 = Vector3(it["pos"]) - Vector3(it["prev"])
					var wd := size * sc * float(it["width"]) * _jit(int(it["id"]))
					if dv.length() > 0.001:
						painter.spark((Vector3(it["pos"]) + Vector3(it["prev"])) * 0.5, wd, clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99),
							maxf(dv.length() * trail_gain / maxf(wd, 0.001), 1.0), painter.roll_for(dv), sp)
					continue
				painter.spark(it["pos"], size * sc * float(it["width"]) * _jit(int(it["id"])), clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 0.99),
					stretch if tv.length() > 0.01 else 1.0, painter.roll_for(tv) if tv.length() > 0.01 else 0.0, sp)
		"puff":
			var pf := MotionLooks.get_look("puff", element)
			pf.merge(look, true)
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var prog := clampf(float(it["u"]) if age_u else 1.0 - float(it["opacity"]), 0.0, 1.0)
				var a := 1.0
				var fd := prog
				if appear == 1:
					if prog < 0.2 or prog > 0.995:
						continue
					a = sin(PI * clampf((prog - 0.2) / 0.8, 0.0, 1.0))
					fd = 0.0
				painter.puff(Vector3(it["pos"]) + drift * sc * prog, size * sc * (0.7 + 0.8 * prog) * float(it["width"]), a * float(pf.get("alpha", 0.8)), fd,
					float(int(it["id"]) % 997) * 0.29, float(int(it["id"]) % 360) * 0.0174, pf)
		"drops":
			var dp := MotionLooks.get_look("surface", element)
			dp.merge(look, true)
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var tv: Vector3 = it["tan"]
				dp["seed"] = float(int(it["id"]) % 997) * 0.37
				painter.drop(it["pos"], size * sc * float(it["width"]) * _jit(int(it["id"])), tv, stretch, clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 1.0), dp)
		"halo":
			var hl := MotionLooks.get_look("halo", element)
			hl.merge(look, true)
			var lh: Dictionary = items[items.size() - 1]
			painter.halo(lh["pos"], size * sc * float(lh["width"]), strength * float(lh["opacity"]), hl)
		"light":
			# D-953: a short pooled omni pulse at the contact. The opacity curve of the composition fades it.
			var li: Dictionary = items[items.size() - 1]
			painter.light(li["pos"], color, strength * float(li["opacity"]), light_range)
		"shock":
			# D-377: anel de choque no primeiro ponto, virado para a câmera. `k` abre o raio.
			var sh: Dictionary = items[0]
			var sp := Vector3(sh["pos"])
			var sn := (painter.cam_pos() - sp)
			sn = sn.normalized() if sn.length() > 0.01 else Vector3.FORWARD
			var sr := lerpf(size * 0.22, size, clampf(k, 0.0, 1.0)) * sc
			painter.shock_ring(sp, sn, sr, k, clampf(1.0 - float(sh["opacity"]), 0.0, 0.99), strength, float(int(sh["id"]) % 997) * 0.37, 0.055)
		"mark":
			var mk := MotionLooks.get_look("mark", element)
			mk.merge(look, true)
			var fm: Dictionary = items[0]
			painter.mark(fm["pos"], size * sc, clampf(1.0 - float(fm["opacity"]) + fade_bias, 0.0, 0.99), 3.0, mk)
		"scorch":
			var first: Dictionary = items[0]
			painter.scorch(first["pos"], size * sc, clampf(1.0 - float(first["opacity"]), 0.0, 0.99), strength, 3.0)
		"spear":
			# V1.10 (D-377) / D-378: a lança é o segmento entre a primeira e a última amostra. O cabo cresce e a
			# lâmina fica fixa na ponta; as duas partes têm malha própria e reveal/dissolve próprios. Nada depende de
			# personagem, time, lado ou alvo (D-235).
			var first_s: Dictionary = items[0]
			var last_s: Dictionary = items[items.size() - 1]
			var base_s := Vector3(first_s["pos"])
			var tip_s := Vector3(last_s["pos"])
			var axis_s := tip_s - base_s
			var len_s := axis_s.length()
			if len_s > 0.01:
				var unit_s := axis_s / len_s
				var rev_s := 1.0
				var dis_s := 0.0
				if spear_mode == "reveal":
					rev_s = clampf(k, 0.0, 1.0)
				elif spear_mode == "dissolve":
					dis_s = clampf(k, 0.0, 1.0)
				var op_s := clampf(float(first_s["opacity"]), 0.0, 1.0) * strength
				var blade_len := clampf(blade_length, 0.15, len_s)
				var shaft_len := maxf(len_s - blade_len, 0.02)
				var shaft_base := base_s
				var blade_base := base_s + unit_s * shaft_len
				var rev_shaft := clampf(rev_s * len_s / shaft_len, 0.0, 1.0)
				var rev_blade := clampf((rev_s * len_s - shaft_len) / blade_len, 0.0, 1.0)
				var dis_shaft := clampf(dis_s * len_s / shaft_len, 0.0, 1.0)
				var dis_blade := clampf((dis_s * len_s - shaft_len) / blade_len, 0.0, 1.0)
				# The shaft is 20% thinner; the blade/tip meshes keep their own thickness.
				var thick_s := clampf(1.0 + maxf(len_s - 3.0, 0.0) * 0.055, 1.0, 1.65) * 0.8
				if spear_part == "full" or spear_part == "shaft":
					painter.spear_part(shaft_base, axis_s, shaft_len, "shaft", rev_shaft, dis_shaft, op_s, energy, color, look, thick_s)
				if spear_part == "full" or spear_part == "blade":
					painter.spear_part(blade_base, axis_s, blade_len, "blade", rev_blade, dis_blade, op_s, energy, color, look)
				if ghosts > 0 and spear_mode != "dissolve" and dis_s <= 0.0:
					for g in ghosts:
						var off_s := -unit_s * (ghost_gap * len_s * float(g + 1))
						var ga := op_s * ghost_alpha * (1.0 - 0.18 * float(g))
						if spear_part == "full" or spear_part == "shaft":
							painter.spear_part(shaft_base + off_s, axis_s, shaft_len, "shaft", rev_shaft, 0.0, ga, energy * 0.65, color, look, thick_s)
						if spear_part == "full" or spear_part == "blade":
							painter.spear_part(blade_base + off_s, axis_s, blade_len, "blade", rev_blade, 0.0, ga, energy * 0.65, color, look)
		"aura":
			# D-378: 6 faixas espirais em volta da lança inteira, baixa opacidade. O segmento vem do compositor; o
			# giro vem do relógio do efeito; a cor/energia vêm do preset. Nada de personagem, time ou lado (D-235).
			var first_a: Dictionary = items[0]
			var last_a: Dictionary = items[items.size() - 1]
			var base_a := Vector3(first_a["pos"])
			var tip_a := Vector3(last_a["pos"])
			var axis_a := tip_a - base_a
			var len_a := axis_a.length()
			if len_a > 0.05:
				var op_a := maxf(float(first_a["opacity"]), float(last_a["opacity"])) * strength
				var spin_a := aura_spin * TAU * painter.time
				for b in aura_bands:
					var ph := TAU * float(b) / float(maxi(aura_bands, 1)) + spin_a
					painter.aura_band(base_a, axis_a, len_a, ph, aura_turns, aura_radius, aura_width, aura_opacity * op_a, aura_energy, aura_color, look)
		"vortex":
			# D-379: vórtice cônico no começo da estocada, girando como um ventilador. A opacidade vem da última
			# amostra (o fade começa em 0,4 s no preset). Nada de personagem/time/lado (D-235).
			var first_v: Dictionary = items[0]
			var last_v: Dictionary = items[items.size() - 1]
			var base_v := Vector3(first_v["pos"])
			var tip_v := Vector3(last_v["pos"])
			var axis_v := tip_v - base_v
			var len_v := axis_v.length()
			if len_v > 0.10:
				var unit_v := axis_v / len_v
				var vlen := minf(vortex_length, len_v)
				var vbase := tip_v - unit_v * vlen
				var op_v := float(last_v["opacity"]) * strength
				if op_v > 0.01:
					var spin_v := vortex_spin * TAU * painter.time
					# Funis grandes: a parte que o olho lê como "vórtice drill".
					painter.vortex_cone(base_v, axis_v, minf(vortex_base_length, len_v), vortex_base_radius * 1.15, vortex_cone_opacity * op_v, vortex_cone_energy, vortex_color, look)
					painter.vortex_cone(vbase, axis_v, vlen, vortex_radius * 1.10, vortex_cone_opacity * op_v, vortex_cone_energy, vortex_color, look)
					var sp_k := (1.0 - clampf(op_v / maxf(strength, 0.001), 0.0, 1.0)) * vortex_split  # D-1015
					var px := unit_v.cross(Vector3.UP)
					px = px.normalized() if px.length() > 0.01 else Vector3.RIGHT
					var py := unit_v.cross(px).normalized()
					for b in vortex_bands:
						var ph := TAU * float(b) / float(maxi(vortex_bands, 1)) + spin_v
						var off_b := (px * cos(ph) + py * sin(ph)) * sp_k
						painter.vortex_band(vbase + off_b, axis_v, vlen, ph, vortex_turns, vortex_radius, vortex_end_radius, vortex_width, vortex_opacity * op_v, vortex_energy, vortex_color, look)
					# D-379: segundo cone na BASE (mão), para o boost ser visível já no primeiro quadro da estocada.
					var blen := minf(vortex_base_length, len_v)
					var bphase := PI / float(maxi(vortex_bands, 1))
					for b in vortex_bands:
						var phb := TAU * float(b) / float(maxi(vortex_bands, 1)) + spin_v + bphase
						var off_bb := (px * cos(phb) + py * sin(phb)) * sp_k
						painter.vortex_band(base_v + off_bb, axis_v, blen, phb, vortex_turns, vortex_base_radius, vortex_base_end_radius, vortex_width, vortex_opacity * op_v, vortex_energy, vortex_color, look)
		"atelier":
			_draw_atelier(painter, items, origin, k, sc)


## V1.8 (D-337): as malhas e shaders do Atelier HTML. Cada `shape` é uma peça da coreografia; a posição, a direção
## (o eixo do quadro) e o progresso vêm do compositor, nunca de um personagem, time ou lado (D-235).
func _draw_atelier(painter: MotionPainter, items: Array, origin: Vector3, _k: float, sc: float) -> void:
	if items.is_empty():
		return
	var first: Dictionary = items[0]
	var fwd := Vector3(first.get("tan", Vector3.FORWARD))
	if fwd.length() < 0.01:
		fwd = Vector3.FORWARD
	var lt := float(first.get("lt", 0.0))
	var pr := clampf(lt / maxf(duration, 0.01), 0.0, 1.0)
	match shape:
		"ptcl":
			var c0: Color = look.get("c0", Color.WHITE)
			var c1: Color = look.get("c1", c0)
			var sid := int(look.get("shape_id", 0))
			var add := bool(look.get("add", true))
			var spin := float(look.get("spin", 4.0))
			var km := float(look.get("km", 0.66))
			var base_a := float(look.get("alpha", 1.0))
			for i in range(0, items.size(), stride):
				var it: Dictionary = items[i]
				var t := clampf(float(it["intensity"]), 0.0, 1.0)
				var idn := int(it["id"])
				var h1 := MotionHash.float01(idn, 11, 0, 0)
				var h2 := MotionHash.float01(idn, 23, 0, 0)
				var ang := h1 * TAU + painter.time * spin * (h2 * 2.0 - 1.0)
				MotionAtelierMeshes.draw_ptcl(painter, it["pos"], size * sc * km * float(it["width"]), sid,
					c0.lerp(c1, t), float(it["opacity"]) * base_a, ang, add)
		"heal_circle":
			MotionAtelierMeshes.draw_heal_circle(painter, origin, size * sc, pr, float(look.get("alpha_scale", 1.0)))
		"heal_pillar":
			MotionAtelierMeshes.draw_heal_pillar(painter, origin, pr)
		"cryo_decal":
			MotionAtelierMeshes.draw_cryo_decal(painter, origin, fwd, float(look.get("w", 14.0)) * sc, float(look.get("d", 5.5)) * sc, pr)
		"glacial_cluster":
			MotionAtelierMeshes.draw_glacial_cluster(painter, origin, size * sc, pr, float(look.get("seed", 0.0)))
		"seismic_crater":
			MotionAtelierMeshes.draw_seismic_crater(painter, origin, size * sc, pr)
		"dig_mound":
			MotionAtelierMeshes.draw_dig_mound(painter, origin, pr)
		"basalt_spires":
			MotionAtelierMeshes.draw_basalt_spires(painter, origin, pr)
		"sand_crescent":
			MotionAtelierMeshes.draw_sand_crescent(painter, origin, fwd, pr)
		"dust_devil":
			MotionAtelierMeshes.draw_dust_devil(painter, origin, pr)
		"dragon_maw":
			MotionAtelierMeshes.draw_dragon_maw(painter, origin, fwd, pr)
		"draconic_fissure":
			MotionAtelierMeshes.draw_draconic_fissure(painter, origin, size * sc, pr)
		"dragon_fireball":
			MotionAtelierMeshes.draw_dragon_fireball(painter, origin, fwd, size * sc, painter.time * 3.0)
		"dragon_claw_spires":
			MotionAtelierMeshes.draw_dragon_claw_spires(painter, origin, pr)
		"dragon_blast_bolts":
			MotionAtelierMeshes.draw_dragon_blast_bolts(painter, origin, pr)


## V1.2: `surface` draws any shape with mc_surface. tube / ribbon / blade / arc follow each branch of the strand; shell is
## one cone or dome from the first to the last sample; fragments is one block per sample.
func _draw_surface(painter: MotionPainter, items: Array, _origin: Vector3, k: float, sc: float) -> void:
	var params := MotionLooks.get_look("surface", element) if shader == "mc_surface" else {}
	params.merge(look, true)
	if shape == "fragments":
		var centers := PackedVector3Array()
		var sizes := PackedFloat32Array()
		var spins := PackedFloat32Array()
		var dis := PackedFloat32Array()
		var inten := PackedFloat32Array()
		for i in range(0, items.size(), stride):
			var it: Dictionary = items[i]
			centers.append(it["pos"])
			sizes.append(size * sc * float(it["width"]) * _jit(int(it["id"])))
			spins.append(spin * k + float(int(it["id"]) % 628) * 0.01)
			dis.append(clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 1.0))
			inten.append(float(it["intensity"]) * strength)
		painter.surface(MotionShapes.fragments(centers, sizes, int(params.get("seed", 3.0)) + 11, 0.35, spins, dis, inten), params, "frag")
		return
	if shape == "shell":
		if items.size() < 2:
			return
		var a: Dictionary = items[0]
		var b: Dictionary = items[items.size() - 1]
		var axis := Vector3(b["pos"]) - Vector3(a["pos"])
		var h := axis.length()
		if h < 0.02:
			return
		var w := float(b["width"])
		var op := 0.0
		for it in items:
			op += float(it["opacity"])
		op /= float(items.size())
		painter.surface(MotionShapes.shell(a["pos"], axis, h, radius * sc * w, profile_pow, 10, sides, clampf(1.0 - op + fade_bias, 0.0, 1.0), float(b["intensity"]) * strength), params, "shell")
		return
	var groups: Dictionary = {}
	for it in items:
		var key := String(it.get("branch", "root"))
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(it)
	for key in groups.keys():
		var g: Array = groups[key]
		if g.size() < 2:
			continue
		if flip:
			g.reverse()
		var step := maxi(1, int(ceil(float(g.size()) / float(max_rings))))
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		var dis := PackedFloat32Array()
		var inten := PackedFloat32Array()
		var i := 0
		while true:
			var it: Dictionary = g[i]
			var uu := float(it["u"]) if not flip else 1.0 - float(it["u"])
			pts.append(it["pos"])
			var prof := pow(clampf(uu, 0.0, 1.0), profile_pow) * (1.0 + head_bulge * smoothstep(0.8, 1.0, uu))
			if shape == "blade":
				prof = pow(maxf(sin(PI * clampf(uu, 0.0, 1.0)), 0.0), 0.7)
			elif shape == "arc":
				prof = pow(maxf(sin(PI * clampf(uu, 0.0, 1.0)), 0.0), profile_pow)
			elif shape == "flame":
				var rb := sqrt(maxf(1.0 - pow(1.0 - clampf(uu / 0.2, 0.0, 1.0), 2.0), 0.0))
				prof = pow(maxf(1.0 - clampf(uu, 0.0, 1.0), 0.0), profile_pow) * rb
			rad.append(radius * sc * float(it["width"]) * prof)
			dis.append(clampf(1.0 - float(it["opacity"]) + fade_bias, 0.0, 1.0))
			inten.append(float(it["intensity"]) * strength)
			if i == g.size() - 1:
				break
			i = mini(i + step, g.size() - 1)
		var p := params.duplicate()
		p["seed"] = float(int(String(key).hash()) % 997) * 0.37 + float(params.get("seed", 0.0)) + float(g[0].get("cseed", 0.0))
		var data: Dictionary
		if shape == "tube":
			data = MotionMesh.tube(pts, rad, dis, inten, sides)
		else:
			var widths := PackedFloat32Array()
			for r in rad:
				widths.append(r * 2.0)
			var face := (painter._cam_pos() - pts[pts.size() / 2]).normalized() if camera_facing else Vector3.UP
			data = MotionShapes.ribbon(pts, widths, face, dis, inten)
		painter.surface(data, p, "surf_" + shape + shader, shader)
