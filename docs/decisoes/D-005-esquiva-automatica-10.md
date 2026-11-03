# D-005 — Esquiva automática: 10% por golpe

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> reduz o desvio automático pra 10%

## Decisão

A esquiva automática passa de "chance igual à velocidade" para **10% por golpe**, para todos os alvos (`AUTO_DODGE_CHANCE`).

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma. (O desvio da IA durante o trajeto continua com chance igual à velocidade, regra do PROMPT.)

## Estado no código

Implementado.

## Complemento posterior — Rodada 54 / D-127 (2026-11-03)

A escolha expressa **8C** da Rodada 54 determina que **Sorte modifique as chances de crítico, esquiva automática e aplicação de efeitos de status**. O valor de **10% por golpe** aqui documentado continua sendo o **valor atual do código** e a regra histórica, mas **não deve ser tratado como chance final universal e imutável** quando a regra D-127 for implementada. Os valores, a curva e os limites futuros ainda não foram aprovados. Não confundir esquiva automática com a reação da IA durante trajetória (D-021) ou a impossibilidade de desviar de debuffs de alvo único (D-012); casos de aplicação de status exigem detalhamento.
