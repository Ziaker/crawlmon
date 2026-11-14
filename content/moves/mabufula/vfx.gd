extends Node3D

const TAIL := 1.5

const VFX_SCRIPTS: Array[Script] = [
	preload("res://content/moves/mabufula/vfx_frost.gd"),
	preload("res://content/moves/mabufula/vfx_snow.gd"),
	preload("res://content/moves/mabufula/vfx_crystals.gd"),
	preload("res://content/moves/mabufula/vfx_dust.gd"),
	preload("res://content/moves/mabufula/vfx_shards.gd"),
]

var _layers: Array[Node3D] = []

func _ready() -> void:
	for script in VFX_SCRIPTS:
		var layer := Node3D.new()
		layer.set_script(script)
		layer.name = script.resource_path.get_file().get_basename()
		add_child(layer)
		_layers.append(layer)

func setup(camera: Camera3D) -> void:
	for layer in _layers:
		layer.setup(camera)

func draw(s: Dictionary) -> void:
	for layer in _layers:
		layer.draw(s)
