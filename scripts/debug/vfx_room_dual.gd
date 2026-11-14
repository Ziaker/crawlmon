extends Node
## D-1204: os DOIS POVs ao mesmo tempo. Esquerda: o jogador usa o Move no inimigo, na câmera do jogo.
## Direita: o inimigo usa o mesmo Move no jogador, na câmera atrás do atacante (o POV do oponente).
## Cada metade é uma sala (vfx_room) com o seu próprio mundo 3D; as duas disparam no mesmo quadro.
## Uso: godot --path . scenes/debug/vfx_room_dual.tscn -- --move="Fire Bullet" --summary-json --quit
## Qualquer argumento da sala vale (--force, --speed, --cam da esquerda...). --attacker troca o lado de quem usa.

var _rooms: Array = []
var _finished := 0
var _done_rooms: Array = []
var _code := 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.06, 0.1))
	var base := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			base[kv[0]] = kv[1] if kv.size() > 1 else "true"
	if not base.has("target"):
		base["target"] = "opponent"
	var left := base.duplicate()
	var right := base.duplicate()
	var who := String(base.get("attacker", "player"))
	left["attacker"] = who
	right["attacker"] = "enemy" if who in ["player", "ally"] else "player"
	right["cam"] = "2"  # câmera atrás de quem usa o Move: o ponto de vista do oponente
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	for pair in [["jogador usa", left], ["oponente usa", right]]:
		_rooms.append(_make_half(box, String(pair[0]), pair[1]))


func _make_half(parent: Control, caption: String, args: Dictionary) -> Node:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(svc)
	var sv := SubViewport.new()
	sv.handle_input_locally = false
	svc.add_child(sv)
	var room := (load("res://scenes/debug/vfx_room.tscn") as PackedScene).instantiate()
	room.set_meta("dual_args", args)
	room.set_meta("dual_view", caption)
	room.set_meta("dual_done", Callable(self, "_on_room_done").bind(room))
	sv.add_child(room)
	var label := Label.new()
	label.text = "POV: " + caption
	label.add_theme_font_size_override("font_size", 20)
	label.position = Vector2(12, 8)
	svc.add_child(label)
	return room


func _on_room_done(code: int, room: Node) -> void:
	if _done_rooms.has(room):
		return  # a sala pode pedir para sair mais de uma vez
	_done_rooms.append(room)
	_finished += 1
	_code = maxi(_code, code)
	if _finished >= _rooms.size():
		get_tree().quit(_code)
