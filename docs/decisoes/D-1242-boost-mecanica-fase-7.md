<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1242 — BOOST, Fase 7: mecânica

**Data:** 2026-11-16
**Área:** combate, Employ
**Estado:** respondida pelo criador; mecânica em implementação. O visual do BOOST (D-1241) é outra sessão e não é tocado aqui.
**Relacionadas:** D-1229, D-1026, D-1239, D-1241, D-391.

## Texto do briefing (D-1229)

> "BOOST — Duração: 10 segundos. Efeitos: +1 STR. +1 MAG. +1 VIT. +1 SPI. +1 AGI. +1 LUK. +1 Burst. +2 ATB."
> "Após um fracasso: O combate é retomado. O inimigo recebe BOOST."

## Respostas do criador (2026-11-16)

- SPI × WIS: "+1 WIS (Recomendado)".
- Burst cheio: "Passa de 5 durante o BOOST".
- Fim com Burst acima de 5: "Volta a 5 (Recomendado)".
- Duração e pausas: "Pausa junto (Recomendado)" (a duração só corre quando a batalha corre: pausa de status D-1026 e congelamento do Employ).
- ATB e fim: "Sim, +2 ATB uma vez; atributos somem no fim (Recomendado)" (+2 ATB uma vez no início; o ATB e o Burst concedidos ficam; só os +1 atributos somem, e o Burst acima de 5 volta a 5).

## Escolhas técnicas da IA (para ele poder mudar)

- O +1 Burst é somado sem teto; os ganhos normais de Burst nunca reduzem um valor acima de 5 nem passam de 5.
- Os +1 atributos entram nos atributos diretos do Combatant; `attack` (quando deriva do STR efetivo) e a velocidade (AGI) seguem por ali. HP máximo e MP máximo não são recalculados.
- Quem recebe: o alvo do Employ que fracassou (o fracasso termina a tentativa e retoma o combate).
- Visual: nenhum nesta fase (D-1241 está em outra sessão).
