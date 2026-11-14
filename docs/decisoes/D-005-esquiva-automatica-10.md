<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
