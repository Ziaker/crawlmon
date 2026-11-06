# D-283 — O Evade só existe como desvio perfeito, nos últimos 0,25 s do golpe

- **Data:** 2026-11-05
- **Área:** Combate / Evade
- **Origem:** Conversa (sala de VFX, cenário de Evade)

## O que o criador disse (literal)

> "não existe isso de EVADE CEDO, o evade deve ser SEMPRE perfeito, nos últimos .25 segundos como definido (até agora o contra-ataque instantâneo tá bugado por conta disso"

## Decisão

1. O Evade manual **só funciona nos últimos 0,25 s** da fase de golpe (a janela de D-030) e **é sempre perfeito**. Não existe Evade "cedo"/comum.
2. Apertar o Evade antes da janela **não tem efeito** (D-034: "fora da janela, botão sem efeito").
3. A janela perfeita passa de 0,22 s (D-907, D-075) para **0,25 s** (`Battle.PERFECT_WINDOW`), em todos os usos da constante.
4. A IA, por simetria (D-021), tenta o Evade dentro dessa janela final (antes ela sorteava um instante entre 25% e 75% do golpe, que agora seria cedo demais).
5. O aviso de Evade do HUD continua aparecendo durante o golpe; a contagem fica dourada só dentro da janela.
6. Os ramos de desvio **não perfeito** (D-029: cancela a corrida e volta à origem; D-066: Evade comum na onda AoE) ficam sem uso; o código não foi removido.

## Ambiguidades em aberto

- 0,25 s substitui os 0,22 s de D-907 e D-075 (o criador disse ".25 como definido"); se a janela da onda AoE (D-075) deveria continuar 0,22 s.
- Se a esquiva automática (10%) continua como está (não é Evade manual; não alterada).
- Moves com golpe mais curto que 0,25 s (Mach Punch, 0,20 s): a janela cobre o golpe inteiro.

## Estado no código

Implementado (2026-11-05): `Incoming.in_strike_window/can_evade_now`, `Battle.PERFECT_WINDOW`, `BattleEvade.find_evadable`, `Battle._roll_ai_evade`.
