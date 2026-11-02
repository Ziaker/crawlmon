class_name BattleDebug
extends CanvasLayer
## Quick-test panel for the battle. F1 shows/hides it. Everything here only pokes the
## normal Battle API (use_skill, step, try_evade...), so what you see is the real game.

const PHASES := ["PREPARO", "TRAJETO", "GOLPE", "RETORNO", "FIM", "ATORDOADO"]
const SPEEDS := [1.0, 0.5, 0.25, 2.0, 4.0]

var _battle: Battle
var _party: Array[Combatant]
var _enemies: Array[Combatant]
var _label: Label
var _god := false
var _ai_off := false
var _speed_i := 0
var _skill_i := {}  ## Combatant -> index of the next skill the F-keys make it use
var _saved_policy := {}
var _note := ""


func setup(battle: Battle, party: Array[Combatant], enemies: Array[Combatant]) -> void:
	_battle = battle
	_party = party
	_enemies = enemies
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.62)
	bg.position = Vector2(300, 6)
	bg.size = Vector2(680, 188)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_label = Label.new()
	_label.position = Vector2(308, 8)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color("d7fd6a"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	bg.name = "Bg"


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F1:
			visible = not visible
		KEY_F2:
			for c in _party + _enemies:
				c.atb = Combatant.BLOCKS
			_party[0].burst = mini(_party[0].burst + 1, Combatant.BURST_MAX)
			_note = "ATB cheio e +1 Burst no líder"
		KEY_F3:
			_force(_enemies[0], _party[0])
		KEY_F4:
			_force(_enemies[0], _party[1] if _party.size() > 1 else _party[0])
		KEY_F8:
			if _party.size() > 1:
				_force(_party[1], _enemies[0])
		KEY_F5:
			_god = not _god
		KEY_F6:
			_toggle_ai()
		KEY_F7:
			_speed_i = (_speed_i + 1) % SPEEDS.size()
			Engine.time_scale = SPEEDS[_speed_i]
		KEY_F10:
			_party[0].atb = Combatant.BLOCKS
			_note = "passo à frente: %s" % _battle.step(_party[0], 1)
		KEY_F11:
			_party[0].atb = Combatant.BLOCKS
			_note = "passo atrás: %s" % _battle.step(_party[0], -1)


## Makes `actor` use its next skill on `target` right now (ATB filled, normal wind-up).
func _force(actor: Combatant, target: Combatant) -> void:
	var skills: Array[Skill] = [Skill.basic()]
	skills.append_array(actor.skills)
	var i: int = _skill_i.get(actor, 0) % skills.size()
	_skill_i[actor] = i + 1
	actor.atb = Combatant.BLOCKS
	var ok := _battle.use_skill(actor, skills[i], target)
	_note = "%s usa %s em %s: %s" % [actor.name, skills[i].display_name, target.name, "ok" if ok else "bloqueado (ocupado/engajado)"]


func _toggle_ai() -> void:
	_ai_off = not _ai_off
	for c in _party.slice(1) + _enemies:
		if _ai_off:
			_saved_policy[c] = c.act_policy
			c.act_policy = Combatant.Act.HOLD
		else:
			c.act_policy = _saved_policy.get(c, c.act_policy)


func _process(_delta: float) -> void:
	if _battle == null:
		return
	if _god:
		for c in _party:
			c.hp = c.max_hp
	if not visible:
		return
	var lines := PackedStringArray()
	lines.append("DEBUG (F1 esconde)   velocidade x%s   deus %s   IA %s" % [str(SPEEDS[_speed_i]), "ON" if _god else "off", "PARADA" if _ai_off else "ligada"])
	lines.append("F2 ATB cheio+Burst  F3 inimigo ataca %s  F4 inimigo ataca %s  F8 aliado ataca inimigo" % [_party[0].name, _party[1].name if _party.size() > 1 else "-"])
	lines.append("F5 deus  F6 para a IA  F7 velocidade  F10/F11 passo +/- do líder  F9 reinicia  (golpes ciclam: Tackle e skills)")
	if _note != "":
		lines.append("> " + _note)
	for c in _party + _enemies:
		var eng := "-"
		if c.engaged_with != null:
			eng = "%s (%.1fs)" % [c.engaged_with.name, c.engage_left]
		lines.append("%-8s HP %d/%d  ATB %.1f  Burst %d  pos %+d  engajado: %s" % [c.name, c.hp, c.max_hp, c.atb, c.burst, c.pos_step, eng])
	var any := false
	for inc in _battle.incoming + _battle.attacks_in_flight():
		any = true
		var tag := ""
		if inc.interrupted:
			tag = " [interrompido]"
		elif inc.void_miss:
			tag = " [erra o vazio]"
		elif inc.can_evade_now():
			tag = " [EVADE AGORA %.2fs]" % inc.travel_left()
		var prog := inc.progress() if inc.resolved else 1.0 - inc.time_left / maxf(inc.total_windup, 0.01)
		lines.append("  %s>%s %s (%s) %s %d%% eta %.2fs%s" % [inc.attacker.name, inc.target.name, inc.label, Skill.kind_name(inc.kind), PHASES[inc.phase], int(prog * 100.0), inc.eta() if inc.resolved else inc.time_left, tag])
	if not any:
		lines.append("  (nenhum ataque em curso)")
	_label.text = "\n".join(lines)
