<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-003 — Fazer só o que foi pedido; perguntar na dúvida; refatorar sem mudar nada

- **Data:** 2026-11-02
- **Área:** Processo
- **Origem:** Conversa + memória

## O que o criador disse (literal)

> Eu já to desistindo, vc simplesmente não me ouve, esquece o que já tava setado, coisa que não devia mudar e que já tava pronto vc mudava

## Decisão

Nada que o criador não pediu pode mudar (regra, tempo, visual, ordem de eventos). **Refatoração mantém tudo idêntico.** "Auditoria", "proponha" e "corrija" **não** autorizam mudar comportamento. Sim a um plano grande **não** autoriza as escolhas de detalhe dentro dele: cada detalhe ambíguo é perguntado.

## Ambiguidades em aberto (perguntar antes de agir)

Mudanças já feitas sem pedido (hit-stop global, investida até o contato, perseguição no golpe, interceptação na declaração, corpos parados, volta na vitória, recuo do atingido, retarget do AoE, suavização visual): o criador ainda não decidiu se reverte tudo ou escolhe quais.

## Estado no código

Violada na Fase 2; correção pendente de decisão.
