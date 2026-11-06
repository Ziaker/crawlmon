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
