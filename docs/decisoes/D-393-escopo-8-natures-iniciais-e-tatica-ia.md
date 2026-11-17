<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-393 — Escopo das 8 Natures iniciais e direcionamento tático da IA

- **Data:** 2026-11-07
- **Área:** Personagens / Natures / IA
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> sim, podem existir neutras, no momento só usaremos 8 natures, vc define o escopo delas

> gostei da recomendação seguiremos com ela (sobre a Nature inclinar a tendência tática da IA em combate)

## Regra aprovada

- O catálogo atual é de **18 Natures**; as **8 iniciais** estão abaixo, contemplando neutras e ativas (atualizado: D-1216):
  1. **Hardy** (Neutra / Equilibrada: 0 em todos; ritmo regular).
  2. **Docile** (Neutra / Suporte: 0 em todos; mantém distância e prioriza apoio).
  3. **Brave** (Ofensiva Física: +2 STR, +1 VIT, −3 AGI; gasta ATB imediatamente) (atualizado: D-1217).
  4. **Timid** (Evasiva: +2 AGI, +1 LUK, −3 STR; reserva ATB para Evade) (atualizado: D-1217).
  5. **Modest** (Especial / Mágica: +3 MAG, −2 STR, −1 AGI; conjuradora à distância).
  6. **Calm** (Defensiva / Reativa: +2 WIS, +1 VIT, −3 STR; reativa, foco em Guard) (atualizado: D-1217).
  7. **Jolly** (Ágil / Disruptiva: +2 AGI, +1 LUK, −3 MAG; oportunista, reposiciona-se).
  8. **Adamant** (Poder Bruto: +3 STR, −2 MAG, −1 LUK; implacável corpo a corpo) (atualizado: D-1217).
- Preservados os mandatos de D-271: modificadores *flat* de −3 a +3, soma zero, sem interferência no crescimento por nível.

## Ambiguidades em aberto (perguntar antes de agir)

- Nenhuma.

## Estado no código

Nenhuma alteração.
