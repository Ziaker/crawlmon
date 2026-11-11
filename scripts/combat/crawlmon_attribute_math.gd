class_name CrawlmonAttributeMath
extends RefCounted
## Regras matematicas de conversao, atributos-base, HP, MP e ATB.
## Decisoes: D-120, D-126, D-131, D-132, D-139, D-143, D-144, D-145, D-146, D-147,
## D-150..D-153, D-156, D-163, D-164, D-170, D-269, D-270, D-271, D-390, D-391, D-392, D-393, D-394.

const ATTRIBUTES: Array[String] = ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]


## Sorteio triangular independente discreto com 16 bilhetes inteiros (0 a 15)
## e distribuicao simetrica 1:2:3:4:3:2:1 para a faixa inteira de -3 a +3 (D-144).
static func individual_offset_from_ticket(ticket: int) -> int:
	assert(ticket >= 0 and ticket < 16, "Triangular ticket must be in [0, 15]")
	if ticket == 0:
		return -3
	if ticket <= 2:
		return -2
	if ticket <= 5:
		return -1
	if ticket <= 9:
		return 0
	if ticket <= 12:
		return 1
	if ticket <= 14:
		return 2
	return 3


## Executa o sorteio independente dos 6 atributos para persistencia individual.
static func roll_individual_offsets(rng: RandomNumberGenerator) -> Dictionary:
	var offsets: Dictionary = {}
	for attribute in ATTRIBUTES:
		offsets[attribute] = individual_offset_from_ticket(rng.randi_range(0, 15))
	return offsets


## Converte qualquer conjunto de status oficiais (Pokemon ou Dragon Quest Tact)
## em exatamente 15 pontos inteiros de atributos no nivel 1 via metodo dos maiores restos
## (Hare-Niemeyer), garantindo proporcionalidade biologica estrita (D-390, D-270, D-120).
static func convert_species_stats_to_15_points(species_stats: Dictionary) -> Dictionary:
	# Normaliza as chaves para maiusculo
	var normalized: Dictionary = {}
	for k in species_stats.keys():
		normalized[str(k).to_upper()] = float(species_stats[k])

	# Mapeamento e suporte a nomes canonicos
	var str_val := float(normalized.get("STR", normalized.get("ATTACK", normalized.get("ATK", 0.0))))
	var mag_val := float(normalized.get("MAG", normalized.get("SP_ATK", normalized.get("SPATK", normalized.get("WISDOM", normalized.get("MAGIC", 0.0))))))
	var vit_val := float(normalized.get("VIT", normalized.get("DEFENSE", normalized.get("DEF", 0.0))))
	var wis_val := float(normalized.get("WIS", normalized.get("SP_DEF", normalized.get("SPDEF", normalized.get("SPI", 0.0)))))
	var agi_val := float(normalized.get("AGI", normalized.get("SPEED", normalized.get("SPE", normalized.get("AGILITY", 0.0)))))

	# RefLUK: media aritmetica arredondada dos 5 atributos caso nao fornecido
	var luk_val: float
	if normalized.has("LUK") or normalized.has("LUCK") or normalized.has("REFLUK"):
		luk_val = float(normalized.get("LUK", normalized.get("LUCK", normalized.get("REFLUK", 0.0))))
	else:
		luk_val = roundf((str_val + mag_val + vit_val + wis_val + agi_val) / 5.0)

	var raw_stats: Dictionary = {
		"STR": maxf(str_val, 1.0),
		"MAG": maxf(mag_val, 1.0),
		"VIT": maxf(vit_val, 1.0),
		"WIS": maxf(wis_val, 1.0),
		"AGI": maxf(agi_val, 1.0),
		"LUK": maxf(luk_val, 1.0),
	}

	var total_raw: float = 0.0
	for attr in ATTRIBUTES:
		total_raw += float(raw_stats[attr])
	assert(total_raw > 0.0, "Total species raw stats must be greater than zero")

	var base_points: Dictionary = {}
	var remainders: Array = []
	var sum_base: int = 0

	for attr in ATTRIBUTES:
		var quota: float = 15.0 * (float(raw_stats[attr]) / total_raw)
		var floor_val: int = floori(quota)
		base_points[attr] = floor_val
		sum_base += floor_val
		var rem: float = quota - float(floor_val)
		remainders.append({"attr": attr, "rem": rem})

	# Ordena restos de forma decrescente; em empate exato, preserva ordem canonica
	remainders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a["rem"]), float(b["rem"])):
			return ATTRIBUTES.find(str(a["attr"])) < ATTRIBUTES.find(str(b["attr"]))
		return float(a["rem"]) > float(b["rem"])
	)

	var points_to_distribute: int = 15 - sum_base
	for i in range(points_to_distribute):
		var target_attr: String = str(remainders[i % remainders.size()]["attr"])
		base_points[target_attr] = int(base_points[target_attr]) + 1

	var final_sum: int = 0
	for attr in ATTRIBUTES:
		final_sum += int(base_points[attr])
	assert(final_sum == 15, "Hare-Niemeyer conversion must sum to exactly 15 points")

	return base_points


## Consolida os atributos inatos individuais no nivel 1 somando a base (15 pts),
## o offset triangular e o modificador de Nature, aplicando piso minimo de 1 (D-390, D-393).
## Substitui apply_individual_offsets e previne perdas por clamping em progressao futura.
static func consolidate_innate_attributes(base_15: Dictionary, offsets: Dictionary, nature_mod: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	for attr in ATTRIBUTES:
		var b: int = int(base_15.get(attr, base_15.get(attr.to_lower(), 0)))
		var o: int = int(offsets.get(attr, offsets.get(attr.to_lower(), 0)))
		var n: int = int(nature_mod.get(attr, nature_mod.get(attr.to_lower(), 0)))
		result[attr] = maxi(1, b + o + n)
	return result


## Mantido para compatibilidade reversa com testes e chamadas pontuais pre-existentes (D-139).
static func apply_individual_offsets(base: Dictionary, offsets: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for attribute in ATTRIBUTES:
		var base_key := attribute if base.has(attribute) else ("SPI" if attribute == "WIS" and base.has("SPI") else "")
		var off_key := attribute if offsets.has(attribute) else ("SPI" if attribute == "WIS" and offsets.has("SPI") else "")
		if base_key == "" or off_key == "":
			continue
		var offset: int = int(offsets[off_key])
		assert(offset >= -3 and offset <= 3, "Individual offset out of range")
		result[attribute] = maxi(1, int(base[base_key]) + offset)
	return result


## Calculo de HP Maximo fechado: +10 por nivel regular, +25 a cada 10 niveis (marcos 1, 10, 20...),
## e +2 por ponto de VIT (D-392). Garante 39-43 HP no nivel 1 para mitigar hitkills.
static func calculate_max_hp(level: int, vit: int) -> int:
	var lvl := maxi(1, level)
	var v := maxi(1, vit)
	var milestones := floori(float(lvl) / 10.0)
	return 25 + (10 * lvl) + (25 * milestones) + (2 * v)


## Calculo de MP Maximo de ficha: 10 + 2*WIS + level (D-391).
## Permanece como dado numerico estatico da ficha (sem alteracao no HUD de batalha).
static func calculate_max_mp(level: int, wis: int) -> int:
	var lvl := maxi(1, level)
	var w := maxi(1, wis)
	return 10 + (2 * w) + lvl


## Ritmo de ATB por funcao afim universal vinculada a Agilidade (D-126, D-145).
## Suporta assinatura direta de 2 parametros (delta, effective_agi) e sobrecarga legada de 4 parametros.
static func natural_atb_increment(delta: float, effective_agi: float, reference_agi: float = 0.0, reference_blocks_per_second: float = 0.0) -> float:
	assert(delta >= 0.0, "Delta must be nonnegative")
	if reference_agi > 0.0 and reference_blocks_per_second > 0.0:
		# Fallback legado para prototipos que injetam referencias ad-hoc
		return delta * reference_blocks_per_second * (maxf(effective_agi, 1.0) / reference_agi)
	# Formula afim universal oficial: 0.35 + (max(agi, 1.0) * 0.0375) blocos/s
	return delta * (0.35 + maxf(effective_agi, 1.0) * 0.0375)


## Probabilidade de acerto critico (D-150 / D-151): 10% + 1 ponto percentual por ponto de diferenca de LUK.
static func critical_chance(attacker_luk: int, target_luk: int) -> float:
	return clampf(0.10 + float(attacker_luk - target_luk) * 0.01, 0.0, 1.0)


## Chance de aplicacao de status probabilistico (D-146 / D-143).
static func status_application_chance(base_chance: float, applier_luk: int, target_luk: int) -> float:
	assert(base_chance >= 0.0 and base_chance <= 1.0, "Declared base chance must be in [0, 1]")
	return clampf(base_chance + float(applier_luk - target_luk) * 0.01, 0.0, 1.0)


## D-1142: mitigacao natural de dano magico por WIS. WIS 10 = metade; nunca zera.
## A decisao foi delegada ao assistente pelo criador ("inventa").
static func magic_mitigation_multiplier(wis: int) -> float:
	return 10.0 / (10.0 + maxf(float(wis), 0.0))


## D-1142: aplica a mitigacao de WIS a um dano magico ja calculado. Minimo 1.
static func mitigate_magic_damage(amount: int, wis: int) -> int:
	return maxi(1, roundi(float(amount) * magic_mitigation_multiplier(wis)))


## Esquiva automatica baseada na diferenca de LUK com retornos decrescentes simetricos (D-152 / D-153).
static func automatic_dodge_chance(attacker_luk: int, defender_luk: int) -> float:
	var difference: int = defender_luk - attacker_luk
	var magnitude: int = absi(difference)
	var completed_bands: int = floori(float(magnitude) / 10.0)
	var remainder: int = magnitude % 10
	var band_rate: float = pow(0.5, completed_bands)
	var correction_pp: float = 20.0 * (1.0 - band_rate) + float(remainder) * band_rate
	var sign_factor := -1.0 if difference < 0 else 1.0
	return clampf(0.10 + sign_factor * correction_pp * 0.01, 0.0, 1.0)


## Retorna a quantidade de XP necessaria para transicionar do nivel atual para o proximo (D-399).
static func get_xp_for_level_transition(current_level: int) -> int:
	var lvl := maxi(1, current_level)
	return 50 * lvl * lvl


## Retorna a experiencia dropada pela derrota de um oponente (D-399).
static func get_enemy_xp_drop(base_exp: int, level: int) -> int:
	return maxi(1, base_exp) * maxi(1, level)


## Retorna os pontos de atributo distribuidos ao alcancar determinado nivel (D-394).
static func get_stat_points_for_level(new_level: int) -> int:
	return 3 if new_level % 10 == 0 else 1

