<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-101 — R47-Q2 (2A): Move e atacante-alvo escolhidos na mesma janela de dois segundos

- **Data:** 2026-11-03
- **Origem:** decisão expressa do criador na Rodada 47.
- **Estado:** decisão aprovada; somente documentação, sem implementação afirmada.

## Declaração literal do criador

> 2A — Quando deve ser escolhido o alvo do contra-ataque extra contra múltiplos atacantes?: O jogador escolhe o Move e o atacante-alvo dentro da mesma janela de dois segundos.

## Regra aprovada

Quando um Evade perfeito contra vários atacantes concede um único golpe extra (D-093), **o jogador deve escolher o Move e qual atacante será alvo dentro da mesma janela de dois segundos**. A escolha aceita é enfileirada e a execução aguarda o fim do ataque original (D-051/D-052). Preservar a suspensão do relógio durante hit-stop e pausa de status (D-071).

## Referências e pendências

- **Referências:** D-042; D-043; D-051; D-052; D-062; D-071; D-093; D-098.
- **Pendente:** Não foi definido o destino da escolha incompleta quando os dois segundos terminam (Move sem alvo ou o contrário), nem qual critério a IA usa entre atacantes; não presumir.
- **Observação literal do criador:** “na 3 ja temos o jogo vc ao menos ve o github direito?” — registro de contexto, não regra mecânica.
- **Escopo:** exclusivamente documentação; nenhum código, VFX, teste, modelo ou dado de Move deve ser alterado por esta entrega.
