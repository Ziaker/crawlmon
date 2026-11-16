extends SceneTree

func _init() -> void:
	print("C=", ChildTestProbe.C, " f=", ChildTestProbe.f())
	quit(0)
