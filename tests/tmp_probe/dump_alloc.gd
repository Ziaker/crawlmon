extends SceneTree

const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")

func _init() -> void:
	for id in ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops"]:
		var path := "res://content/characters/%s/species.tres" % id
		var data = load(path)
		if data == null:
			print(id, " MISSING")
			continue
		var alloc: Dictionary = CrawlmonAttributeMath.convert_species_stats_to_15_points(data.raw_stats)
		print("%s %s total=%d" % [id, str(alloc), _sum(alloc)])
	quit(0)


func _sum(d: Dictionary) -> int:
	var t := 0
	for k in d.keys():
		t += int(d[k])
	return t
