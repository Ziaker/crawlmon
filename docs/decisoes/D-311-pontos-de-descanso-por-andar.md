<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-311 - Pontos de descanso: cura total, 2 por andar (raramente 3), uso único

- **Data:** 2026-11-05
- **Área:** Exploração
- **Origem:** Conversa (resposta à P4 do plano do overworld)

## O que o criador disse (literal)

> p4 - cura todo hp e mp, até 2 vezes por andar (não pode usar o mesmo mais de uma vez), raramente 3

## Decisão

O ponto de descanso (R31-Q5, R32-Q2) recupera **todo o HP e todo o MP**. Cada andar tem até 2 pontos (raramente 3), e cada ponto só pode ser usado uma vez. Esta decisão define o valor de HP que estava pendente na R32-Q2.

## Ambiguidades em aberto

O que significa "raramente" (probabilidade) e se a cura alcança só a equipe ativa.

## Estado no código

Não implementado.