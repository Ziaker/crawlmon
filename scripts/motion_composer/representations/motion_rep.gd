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
				painter.flipbook(it["pos"], size * sc * float(it["width"]), prog, sheet, color, energy, float(int(it["id"]) % 360))
		"ring":
			var kk := clampf(k, 0.0, 1.0)
			var ek := 1.0 - pow(1.0 - kk, 3.0)
			painter.ring(Vector3(origin.x, 0.05, origin.z), Vector3.UP, lerpf(size, size * 0.4, ek) * sc, 1.0 - (0.3 + 0.7 * kk) * 0.9, strength, 4.0, 0.06)
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
		"mark":
			var mk := MotionLooks.get_look("mark", element)
			mk.merge(look, true)
			var fm: Dictionary = items[0]
			painter.mark(fm["pos"], size * sc, clampf(1.0 - float(fm["opacity"]) + fade_bias, 0.0, 0.99), 3.0, mk)
		"scorch":
			var first: Dictionary = items[0]
			painter.scorch(first["pos"], size * sc, clampf(1.0 - float(first["opacity"]), 0.0, 0.99), strength, 3.0)
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
			MotionAtelierMeshes.draw_heal_circle(painter, origin, size * sc, pr)
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
