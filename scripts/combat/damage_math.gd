class_name DamageMath
extends RefCounted
## D-1153 / Fase 1: um único lugar para as etapas puras do dano.
##
## Nenhuma função rola RNG, lê estado mutável do Battle ou altera Combatant.
## O chamador passa os valores já resolvidos no instante correto (crítico,
## passos, WIS, def_buff), preservando a ordem e o arredondamento atuais.
##
## Regra de ouro (D-1152): a ofensa é UMA expressão com um único `roundi`.
## Não extrair `round(stat × power)` antes de multiplicar fraqueza/crítico/passos.

const DMG_PER_STEP := 0.10
const WEAKNESS_MULT := Affinity.WEAK_MULT  ## D-1157: the affinity table is the source.
const CRIT_MULT := 2.0
const GUARD_REDUCTION := 0.5
const DEF_STAGE := 0.25
const MIN_DAMAGE := 1


## +10% por passo à frente do atacante; -10% por passo atrás do alvo.
static func step_multiplier(attacker_step: int, target_step: int) -> float:
	return (1.0 + DMG_PER_STEP * maxi(attacker_step, 0)) * (1.0 - DMG_PER_STEP * maxi(-target_step, 0))


## Dano ofensivo antes de WIS/defesa/Guard/escudo. Um único `roundi`.
static func offense(attack_stat: int, power: float, affinity_mult: float, crit: bool, step_mult: float) -> int:
	return maxi(MIN_DAMAGE, roundi(attack_stat * power * affinity_mult * (CRIT_MULT if crit else 1.0) * step_mult))


## D-1157: traduz a afinidade da espécie no multiplicador de dano.
static func affinity_multiplier(affinity_kind: int) -> float:
	return Affinity.damage_multiplier(affinity_kind)


## Drain Spear: 5 + MAG - SPI, sem fraqueza/crítico/passos/WIS.
static func drain(flat: int, mag: int, spi: int) -> int:
	return maxi(MIN_DAMAGE, flat + mag - spi)


## WIS natural: 10/(10+WIS), mínimo 1. Não chamar com amount 0.
static func mitigate_magic(amount: int, wis: int) -> int:
	return CrawlmonAttributeMath.mitigate_magic_damage(amount, wis)


## Offense + Drain + WIS num só ponto. O chamador decide crítico/weak/passos
## no instante correto; esta função não rola RNG.
static func resolve_offense(attack_stat: int, power: float, affinity_mult: float, crit: bool, step_mult: float, magical: bool, wis: int, magic_flat := -1, mag := 0, spi := 0) -> int:
	if magic_flat >= 0:
		return drain(magic_flat, mag, spi)
	var dmg := offense(attack_stat, power, affinity_mult, crit, step_mult)
	if magical:
		dmg = mitigate_magic(dmg, wis)
	return dmg


## Guard: metade, arredondada para cima, mínimo 1.
static func apply_guard(amount: int, reduction := GUARD_REDUCTION) -> int:
	return maxi(MIN_DAMAGE, ceili(float(amount) * (1.0 - reduction)))


## Estágio de Defense: ±25% por estágio. `min_one=false` preserva o cálculo antigo da IA,
## que podia prever 0 de dano contra defesa muito alta.
static func apply_defense(amount: int, def_buff: int, min_one := true) -> int:
	var value: int
	if def_buff >= 0:
		value = roundi(float(amount) / (1.0 + float(def_buff) * DEF_STAGE))
	else:
		value = roundi(float(amount) * (1.0 + float(abs(def_buff)) * DEF_STAGE))
	return maxi(MIN_DAMAGE, value) if min_one else value


## Dano final de `take_damage`: fixed ignora defesa e não tem mínimo.
static func final_damage(amount: int, def_buff: int, fixed := false, min_one := true) -> int:
	return amount if fixed else apply_defense(amount, def_buff, min_one)


## Base sem alvo, só para UI (card/ficha). `min_one=false` preserva a StatusScreen.
static func base_damage(stat: int, power: float, min_one := true) -> int:
	var dmg := roundi(float(stat) * power)
	return maxi(MIN_DAMAGE, dmg) if min_one else dmg
