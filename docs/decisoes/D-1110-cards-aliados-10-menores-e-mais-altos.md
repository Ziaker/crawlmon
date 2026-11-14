<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1110 — Cards dos aliados 10% menores e mais altos

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / diálogo / faixas laterais dos aliados (D-1089/D-1092).
- **Relacionadas:** D-1089 (reações dos aliados), D-1092 (faixas laterais), D-1090 (HUD C), D-1088 (câmera de diálogo).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> durante a conversa, os cartoes de dialogo dos aliados podia ser 10% menor, alem de estarem melhor espacados pra cima, nao tao perto assim do bloco de texto do NPC

## Regra

1. **10% menores:** a faixa lateral do aliado é desenhada em **90%** do tamanho atual (escala 0,9; o texto, o retrato e o espaçamento interno acompanham).
2. **Mais para cima:** a pilha sai de `y = 288 + 92 × slot` para `y = 200 + 83 × slot`. O terceiro card termina em ~**440 px**; o topo do painel de texto do NPC fica em ~**460 px**, sobrando ~**20 px** de folga. Antes o terceiro começava em `472` e encostava no painel.
3. **Comportamento intacto:** entrada pela esquerda, digitação letra a letra, rotação de -1,5°, abrir/fechar e o vínculo com as reações (D-1089/D-1092) não mudam.
4. **O que não muda:** o painel/HUD do NPC (D-1090), o card do NPC, a câmera de diálogo e o resto.

## Implementação

- `scripts/debug/ally_banner.gd`: `scale = Vector2(0.9, 0.9)`; `_base_y` base 200; espaçamento 83.

## Provas

- `docs/referencias/exploracao/3d/d1110_ally_cards.png` — conversa com os cards dos aliados acima do painel do NPC.
- `docs/referencias/exploracao/3d/dialogue_ally_cards_d1110.mp4` — 10 s da conversa.
- `docs/referencias/exploracao/3d/dialogue_ally_cards_d1110.gif` — o mesmo em GIF.

## O que foi verificado

- A faixa ficou em 90% (342 × 74 px) e a pilha em `y = 200 + 83 × slot`.
- No print com Pancham e Orc, os cards ficam em 200/283 e o painel do NPC começa em ~455; sobra ~100 px. Com um terceiro aliado ele iria para 366 e terminaria em ~440, ainda ~15–20 px acima do painel.
- A entrada, a digitação, a rotação e o vínculo com as reações continuam iguais.
- O vídeo mostra a conversa e os cards entrando no novo lugar.

## O que não foi verificado

- Outras resoluções/aspectos (as posições são em pixels de 720p).
- Com 3 aliados simultâneos em todas as etapas.

## Estado

Implementado e provado. Commit local; **sem push**.
