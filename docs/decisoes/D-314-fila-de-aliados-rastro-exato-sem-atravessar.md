<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-314 — Fila de aliados: rastro exato, sem atravessar

- **Data:** 2026-11-05
- **Área:** Exploração
- **Origem:** Conversa (respostas Q1 e F2 do plano do overworld)

## O que o criador disse (literal)

> Rastro exato, sem atravessar

> Espera 1 s e reposiciona

> Sim; contato inicia batalha

## Decisão

1. Os aliados ativos seguem o **rastro exato** do protagonista, **sem atravessar** paredes/obstáculos.
2. Se um aliado ficar preso, ele **espera 1 s**; se continuar preso, vai para o **ponto livre mais próximo atrás do líder**.
3. Aliados **podem atravessar inimigos**: inimigos não são corpos sólidos e o contato de um aliado com um inimigo **inicia batalha** (R37-Q1).

## Ambiguidades em aberto

- “Ponto livre mais próximo atrás do líder” é o ponto mais próximo na trilha ou qualquer tile livre adjacente? (detalhe de implementação; seguir a trilha primeiro)

## Estado no código

Não implementado. Detalha a D-309.
