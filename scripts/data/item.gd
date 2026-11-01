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
var attack_bonus := 0
var speed_bonus := 0.0


static func get_item(item_id: String) -> Item:
	if _db.is_empty():
		_build_db()
	return _db.get(item_id)


static func _build_db() -> void:
	var potion := _make("potion", "Poção", Kind.CONSUMABLE, "Recupera 30 de HP.")
	potion.heal = 30
	var amulet := _make("amulet_str", "Amuleto de Força", Kind.HELD, "Segurando: +2 de ataque.")
	amulet.attack_bonus = 2
	var boots := _make("boots", "Botas Leves", Kind.HELD, "Segurando: ATB 0.1 bloco/s mais rápido.")
	boots.speed_bonus = 0.1


static func _make(p_id: String, p_name: String, p_kind: Kind, p_desc: String) -> Item:
	var item := Item.new()
	item.id = p_id
	item.display_name = p_name
	item.kind = p_kind
	item.description = p_desc
	_db[p_id] = item
	return item
