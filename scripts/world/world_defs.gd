class_name WorldDefs
extends RefCounted
## Per-world data. Nothing here is per-character, per-team or per-side (D-235).

const WORLDS := {
	"murky_forest": {
		"name": "MURKY FOREST",
		"scene": "res://scenes/debug/murky_forest_3d_lab.tscn",
		"floors": 5,
		"colors": [Color("298c59"), Color("472e6b"), Color("144d42")],
	},
	"hub": {
		"name": "HUB",
		"scene": "res://scenes/hub_3d_lab.tscn",
		"floors": 0,
		"colors": [Color("d6fa66"), Color("f0c57e"), Color("143343")],
	},
}

## Worlds selectable at the gate portal.
const WARP_ORDER := ["murky_forest"]


static func get_world(id: String) -> Dictionary:
	if not WORLDS.has(id):
		return {}
	return WORLDS[id].duplicate(true)


static func world_name(id) -> String:
	return str(get_world(str(id)).get("name", ""))


static func world_colors(id) -> Array:
	return get_world(str(id)).get("colors", [])


static func warp_ids() -> Array:
	return WARP_ORDER.duplicate()
