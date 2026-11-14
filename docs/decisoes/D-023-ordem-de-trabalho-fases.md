<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-023 — Ordem de trabalho: fases e testes

- **Data:** 2026-11-02
- **Área:** Processo
- **Origem:** Conversa

## O que o criador disse (literal)

> faz uma auditoria extensa sobre esses 2 maiores problemas e depois me proponha suas mudanças / Objetivo da Fase 2: implementar posições 3D autoritativas, transferir a lógica espacial e temporal do FX para o motor e sincronizar movimento, animação e impacto, preservando as regras atuais sempre que possível. / corrija seus problemas antes de ir pra fase 3

## Decisão

Fase 0 (medir) → Fase 1 (limpeza) → Fase 2 (posições autoritativas no motor, sincronia) → correções da auditoria → **Fase 3 (testes de mecânica/sincronia)**. A Fase 2 devia **preservar as regras atuais sempre que possível**.

## Ambiguidades em aberto (perguntar antes de agir)

Quais mudanças da Fase 2 ficam (ver D-003).

## Estado no código

Fases 0 e 1 feitas; Fase 2 **revertida** por ordem do criador (D-025); Fase 3 não iniciada.
