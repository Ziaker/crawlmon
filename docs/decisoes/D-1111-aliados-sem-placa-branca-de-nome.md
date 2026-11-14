<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1111 — Aliados sem placa branca de nome

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / aliados / placas de nome.
- **Relacionadas:** D-1086 (nomes dos aliados), D-1089/D-1092 (cards de diálogo dos aliados), D-1097 (Flat Card A), D-1110 (cards 10% menores).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> os aliados nao precisam dos cartoes de npc brancos removadeles

## Regra

1. **Remove a placa branca de nome (Flat Card A) dos aliados.** Os aliados não usam mais o card de NPC acima da cabeça.
2. **Os cards de diálogo bege dos aliados continuam** (D-1089/D-1092/D-1110): o nome e o retrato do aliado aparecem na faixa lateral durante a conversa.
3. **O resto do aliado continua:** anel azul no chão, `...` de fala, comportamento e reações.
4. **O que não muda:** as placas dos NPCs, a do inimigo, os ícones de estado, os cards de diálogo, HUD e o resto.

## Implementação

- `scripts/debug/murky_forest_3d_lab.gd`: remove a chamada `_add_ally_name(f)` em `_add_world_markers`; a função pode ficar sem uso.

## Provas

- `docs/referencias/exploracao/3d/d1111_allies_no_nameplate.png` — aliados sem a placa; NPCs com a placa.
- `docs/referencias/exploracao/3d/allies_no_nameplate_d1111.mp4` — 4 s do lab com os aliados.
- `docs/referencias/exploracao/3d/allies_no_nameplate_d1111.gif` — o mesmo em GIF.

## O que foi verificado

- Pancham e Orc (aliados) aparecem com o anel azul e **sem** a placa branca.
- Bulbasaur e Dracky (NPCs) continuam com a placa branca; o inimigo também.
- Os cards de diálogo bege dos aliados (D-1089/D-1092/D-1110) não foram tocados.

## O que não foi verificado

- Todas as combinações de party e outras resoluções/aspectos.

## Estado

Implementado e provado. Commit local; **sem push**.
