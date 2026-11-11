class_name Item
extends RefCounted
## Item definition. CONSUMABLE items are used from the menu/battle; HELD items
## are equipped on a character and give passive bonuses.

enum Kind { CONSUMABLE, HELD }

static var _db: Dictionary = {}

var id: String
var display_name: String
var kind: Kind
var description: String
var heal := 0


static func get_item(item_id: String) -> Item:
	if _db.is_empty():
		_build_db()
	return _db.get(item_id)


## Icon for an item id, from res://assets/items/<id>.png (null if missing).
static func icon_of(item_id: String) -> Texture2D:
	const ALIASES := {
		"amulet": "amulet-coin",
		"charm": "cleanse-tag",
		"elixir": "max-ether",
	}
	var file_name: String = ALIASES.get(item_id, item_id.replace("_", "-"))
	var path := "res://assets/items/%s.png" % file_name
	if ResourceLoader.exists(path):
		return load(path)
	var direct_path := "res://assets/items/%s.png" % item_id
	return load(direct_path) if ResourceLoader.exists(direct_path) else null


static func _build_db() -> void:
	var potion := _make("potion", "POTION", Kind.CONSUMABLE, "Restores 30 HP instantly on target ally. Usable in field or combat.")
	potion.heal = 30
	var super_potion := _make("super_potion", "SUPER POTION", Kind.CONSUMABLE, "Concentrated battlefield tonic. Restores 60 HP to target ally.")
	super_potion.heal = 60
	_make("revive", "REVIVE", Kind.CONSUMABLE, "Revives a fainted party member with 50% max HP on the battlefield.")
	_make("sitrus_berry", "SITRUS BERRY", Kind.CONSUMABLE, "Emergency berry. Restores 25% max HP when critical.")
	_make("lum_berry", "LUM BERRY", Kind.CONSUMABLE, "Dispels all combat status afflictions (Stun, Burn, Freeze).")
	_make("elixir", "MAX ETHER", Kind.CONSUMABLE, "Restores 20 MP immediately, allowing instant tactical cast.")
	_make("amulet", "AMULET", Kind.HELD, "Ancient protective charm. Held item passive ward.")
	_make("charm", "TALISMAN", Kind.HELD, "Mystic lucky talisman. Held item passive boost.")


static func _make(p_id: String, p_name: String, p_kind: Kind, p_desc: String) -> Item:
	var item := Item.new()
	item.id = p_id
	item.display_name = p_name
	item.kind = p_kind
	item.description = p_desc
	_db[p_id] = item
	return item
