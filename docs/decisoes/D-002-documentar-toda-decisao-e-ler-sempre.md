<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-002 — Cada decisão vira um documento, e eu leio todos sempre

- **Data:** 2026-11-02
- **Área:** Processo
- **Origem:** Conversa

## O que o criador disse (literal)

> A partir de agora cria um documento pra cada decisão minha definida e se obrigue SEMPRE a ler ele, não importa o que seja, ambuiguidades devem ser perguntadas, agents md sla enfia isso na memória

## Decisão

1) Cada decisão do criador vira um arquivo em `docs/decisoes/`. 2) **Antes de qualquer tarefa, sem exceção, o agente lê o índice e todos os arquivos de decisão.** 3) Qualquer ambiguidade é **perguntada**, nunca decidida. 4) Isso é gravado em `AGENTS.md`, `CLAUDE.md` e na memória do agente.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Implementado: `AGENTS.md`, `CLAUDE.md`, memória, esta pasta.
