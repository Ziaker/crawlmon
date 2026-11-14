<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-323 — Remover seis espécies da Pokédex usável por falta de overworld

- **Data:** 2026-11-05
- **Área:** Exploração / Pokédex
- **Origem:** Conversa

## O que o criador disse (literal)

> ok, remova aromatisse e stunfisk, simisear, simipour, amoonguss e throh

## Decisão

As espécies **simisear, simipour, throh, amoonguss, stunfisk e aromatisse** saem da lista `usable_in_game` do `docs/pokedex_manifest.json`.
- Elas continuam no manifesto como registro histórico (`has_3d_model` e demais dados preservados).
- Nenhum asset existente é apagado.
- Contagem usável: **303 → 297**. Inutilizável: **418 → 424**.

## Ambiguidades em aberto

Nenhuma. A remoção é da lista usável, não dos arquivos de ícone/retrato/conquista nem do histórico da Pokédex.

## Estado no código

Aplicado em `docs/pokedex_manifest.json`.
