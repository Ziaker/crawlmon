# D-1142 — Mitigação de dano mágico por WIS

- **Data:** 2026-11-10
- **Área:** Combate / dano mágico / atributos.
- **Origem:** ordem direta do criador, que delegou a fórmula ao assistente.
- **Estado:** regra aprovada; implementação nesta rodada.

## Declaração literal do criador

> "ENTÃO INVENTA, NÃO TÁ OBVIO JÁ? faça"

## Regra aprovada

1. **Fórmula.** Depois da fórmula ofensiva mágica (`MAG × potência × fraqueza × crítico × passos`, mínimo 1), o dano é reduzido pela WIS do alvo:
   `dano final = max(1, round(dano × 10 / (10 + WIS)))`.
   - WIS 10 = **metade** do dano.
   - WIS 20 = **um terço**.
   - WIS 0/1 = quase integral.
   - Nunca chega a zero: o mínimo continua 1.
2. **Ordem.** A mitigação de WIS entra **antes** dos estágios de Defense (`def_buff`), do Guard, da ARMOR e do escudo. Os estágios de Defense continuam afetando dano físico e mágico (D-138).
3. **Exceções.**
   - **Drain Spear** mantém a fórmula própria `5 + MAG − WIS` e **não** recebe a mitigação de WIS de novo.
   - **Dano fixo** (Burn) e **dano físico** não usam WIS.
   - Cura, status e dano de ambiente não passam por essa fórmula.
4. **Previsão.** `Battle.estimate_damage` usa exatamente a mesma mitigação, para a IA e a UI não mentirem.
5. **VIT física.** A resistência natural física por VIT (D-125/D-130) continua **pendente**; esta decisão implementa só o lado mágico (WIS).

## Ambiguidades em aberto (perguntar antes de agir)

- Fórmula da resistência física por VIT: ainda não aprovada.
- Se a WIS deve mitigar também dano mágico de status que não causa dano: não se aplica.
- Se o valor de WIS deve ser o efetivo (com progressão) ou o inato: usa o **efetivo**, como o resto do combate.

## Estado no código

- `CrawlmonAttributeMath.magic_mitigation_multiplier(wis)` e `mitigate_magic_damage(amount, wis)`.
- `Battle._hit` e `Battle.estimate_damage` aplicam a mitigação no caminho mágico normal.
- Drain Spear, Burn e dano físico ficam fora.
- Teste dedicado `tests/battle/test_d1142_wis_mitigation.gd` — **D1142_PASS**.
