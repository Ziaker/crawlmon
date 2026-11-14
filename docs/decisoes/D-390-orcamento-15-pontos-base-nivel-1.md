<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-390 — Orçamento de 15 pontos base no nível 1 convertidos dos status originais

- **Data:** 2026-11-07
- **Área:** Personagens / atributos
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> uma distribuição de 15 pontos entre cada status baseado nos status dos pokemons/DQTs em seus jogos principais, convertendo automáticamente

> (À pergunta se a soma dos 6 atributos é 15 pontos:) Sim, primeira opção

## Regra aprovada

- No nível 1, cada espécie possui um orçamento total de **15 pontos** distribuídos entre os seis atributos (STR, MAG, VIT, WIS, AGI, LUK).
- A distribuição dos 15 pontos é calculada proporcionalmente aos status originais da espécie em seus jogos de origem (D-270).
- Preservados: a variação individual triangular de −3 a +3 (D-132, D-144, D-147) e a ausência de teto artificial rígido permanente (D-139).

## Ambiguidades em aberto (perguntar antes de agir)

- Nenhuma identificada no orçamento básico.

## Estado no código

Nenhuma alteração.
