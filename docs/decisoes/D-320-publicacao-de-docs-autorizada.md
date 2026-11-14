<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-320 — Publicação de documentação autorizada nesta rodada

- **Data:** 2026-11-05
- **Área:** Processo / Git
- **Origem:** Conversa (respostas Q12 e Git do plano do overworld)

## O que o criador disse (literal)

> Commit + push só de docs

> Mesclar origin/main e push

> Índice/REGRAS inteiros

> Worktree limpo do origin/main

## Decisão

1. O criador autoriza **commit e push apenas de documentação**. Código, cenas, VFX e testes não entram nesse envio.
2. A `main` local está **ahead 11 / behind 56** em relação a `origin/main`; para não arriscar o trabalho não commitado de outras sessões, a publicação será feita por um **worktree limpo a partir de `origin/main`**, e não por merge direto na working tree suja.
3. O worktree leva os documentos desta rodada (D-278, D-309 a D-321), a atualização do índice e da §14 do `REGRAS_DO_JOGO.md`, e é enviado ao `origin/main`.

## Ambiguidades em aberto

- O merge de `origin/main` pode conflitar com as alterações não commitadas de outras sessões; será preciso resolver conflitos sem perder trabalho alheio.

## Estado no código

Nada enviado ainda. A autorização existe; falta executar o merge e o push só de docs.
