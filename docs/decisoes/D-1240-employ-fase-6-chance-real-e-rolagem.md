<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1240 — Employ, Fase 6 (recorte): chance real e rolagem

**Data:** 2026-11-16
**Área:** combate, Employ
**Estado:** respondida pelo criador; implementação da Fase 6 em andamento (só este recorte).
**Relacionadas:** D-1229, D-1230, D-1231, D-1239, D-159, D-167.

## Escopo escolhido

À pergunta sobre o que entra na Fase 6, o criador escolheu "Só rolagem + cálculo (Recomendado)": função de chance (D-1230) ligada ao Employ e a rolagem real. **Fora desta fase** (continuam pendentes, nada implementado): diálogo, minigame rítmico, cutscenes, BOOST (Fase 7), entrada por Summon (Fase 8).

## Respostas literais do criador

- Atributos de STR/MAG: "Efetivos com buffs ativos".
- Participantes: "Os do time em campo, vivos (Recomendado)".
- Rolagem: "P sem arredondar; sorteio float 0 a 100, sucesso se roll < P (Recomendado)" (sem sorteio quando P é 0 ou 100, como a D-1230).
- `level_traveler` e `respect`: "Nível do líder; respeito 50 (Recomendado)".
- Como o buff entra: "Multiplica STR e MAG (Recomendado)" (o estágio de ATK, ×(1 + 0,25·estágio) ou o inverso, D-159/D-167; DEF e AGI não entram).
- STR/MAG do inimigo sem valor: "Usar `str`/`mag` do Combatant como estão (Recomendado)" (sem fallback).

## Pendências que continuam sem regra

- Bônus de ritmo `B`: sem minigame, vale 0 nesta fase.
- Contrato de RNG definitivo (usa o `randf()` global, que o `--seed` já controla).
- Fonte real do Respeito (D-1231) e "level_traveler" quando existir o Traveler.
