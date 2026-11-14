<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1164 — Papel (aliado/inimigo/NPC) não é propriedade da espécie

- **Data:** 2026-11-11
- **Área:** Personagens / dados / ferramenta de afinidades.
- **Origem:** observação direta do criador ao revisar os filtros da matriz.
- **Estado:** filtros por papel removidos do protótipo; o campo `role` continua no cadastro e no JSON, aguardando decisão.

## Declaração literal do criador

> "isso aqui é redundante, toda espécie pode ser aliado inimigo e npc"

## Regra aprovada

1. **Toda espécie pode ser aliada, inimiga ou NPC.** O papel depende da situação no jogo, não da espécie.
2. Por isso, **filtrar a matriz por Party/Inimigos/NPCs é redundante** e foi removido.
3. Filtros que sobraram na matriz: **Todos** e **Só novos**.
4. Um filtro salvo antigo (`party`, `enemy` ou `npc`) cai automaticamente em **Todos** ao abrir.
5. Nenhuma afinidade, dano ou regra de combate foi alterada.

## Em aberto (não decidido por mim)

O campo `role` existia em três lugares: cadastro/edição, rótulo embaixo do nome e JSON exportado. O criador decidiu **remover o papel de vez**:

- dropdown **Papel** removido do cadastro/edição;
- rótulo de papel removido das duas visões;
- `role` removido do JSON exportado e da busca;
- `role` que ainda exista em dados antigos do navegador é ignorado na leitura.

A cor de destaque dos cards, que vinha do papel, passou a ser neutra.

## Estado no código

- `prototypes/affinity_matrix.html`: chips Party/Inimigos/NPCs removidos; `matchesFilter` não usa mais papel; `loadFilter` aceita só `all` e `new`; campo, rótulo e `role` do JSON removidos.
- Nenhum arquivo do jogo foi alterado.
- Nada de commit/push sem autorização (D-022).
