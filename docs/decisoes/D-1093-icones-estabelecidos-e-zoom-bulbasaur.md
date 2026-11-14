<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1093 — Retratos/ícones usam o ícone estabelecido do personagem; 3 zooms do Bulbasaur

- **Data:** 2026-11-09.
- **Área:** Exploração / UI / diálogo / retratos.
- **Relacionadas:** D-1074 (face crop dos cards), D-1089 (aliados), D-1090 (HUD C), D-1092 (faixas/câmera).
- **Status:** **regra registrada; ícones estabelecidos implementados; Bulbasaur B escolhido com 0,03 para a esquerda**; batalha, 2D, regras de combate e HUD/status não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> não use o icon da arte inteira, usa o icon já estabelecido para o personagem, inclusive já me de as 3 opções de zoom pro bulbasaur em forma de png para eu escolher o melhor zoom de icone

> coloque isso nos documentos como regra do jogo também

## Regra

1. **Retratos de diálogo e faixas usam o ícone estabelecido do personagem**, não a arte Sugimori inteira.
2. **Pokémon com face crop estabelecido** (Abra, Pancham, Gible e, a partir desta decisão, Bulbasaur) usam o recorte de rosto, no mesmo método da D-1074. O recorte é aplicado com `AtlasTexture` sobre a arte local.
3. **Orc** usa o retrato estabelecido do Orc (`personagens/portraits/orc.png`), que já é um busto/rosto; não é a arte inteira.
4. **Bulbasaur:** três zooms candidatos, em PNG, para o criador escolher:
   - **A — fechado:** `Rect2(0.00, 0.10, 0.64, 0.64)`;
   - **B — médio (escolhido):** `Rect2(0.03, 0.04, 0.78, 0.78)` — a janela anda 0,03 para a direita, o que move o Bulbasaur um pouco para a esquerda no ícone;
   - **C — aberto:** `Rect2(0.00, 0.00, 0.92, 0.92)`.
   - O escolhido vira o recorte canônico do Bulbasaur em todo retrato de diálogo/faixa.
5. **Escolha final:** **B com 0,03 para a esquerda**. O código não usa mais o B antigo (x=0); A e C ficam no histórico/referência.
6. **Bulbasaur é o único com opções agora.** Os demais NPCs Pokémon sem face crop estabelecido continuam com a arte inteira até receberem seu próprio recorte; o pedido desta rodada é o Bulbasaur.
7. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas e a câmera.

## Arquivos das opções

- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_a.png` (fechado, 0,64)
- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_b.png` (médio, 0,78)
- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_c.png` (aberto, 0,92)
- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_opcoes.png` (folha A/B/C com o medalhão Paper)

Os PNGs mostram o recorte dentro do medalhão dourado com aro verde, como o retrato aparece no card/faixa. O jogo usa o **recorte** correspondente, não o PNG com o aro, para não duplicar a moldura.

## Teste implementado (2026-11-09)

- **Estabelecidos:** `_portrait_for_speaker()` agora recorta o rosto de Abra/Pancham/Gible/Bulbasaur; Orc continua no retrato próprio.
- **Correção do círculo:** o recorte é **pré-mascarado em círculo** (`ImageTexture` 256²) antes de entrar no `TextureRect`. Antes, o `AtlasTexture` + shader de máscara desalinhava e o quadrado do recorte vazava do medalhão; agora o rosto fica dentro do aro dourado.
- **Bulbasaur:** recorte **B com 0,03 para a esquerda** no card Paper e nos retratos de NPC; o card mostra o rosto, não o corpo inteiro.
- **Pancham:** faixa com o face crop estabelecido, não a arte inteira.
- **Orc:** retrato estabelecido, como antes.
- **Provas:** os retratos aparecem no `murky_forest_paper_dialogue.png` e nas faixas `murky_forest_panchan_reaction.png`/`murky_forest_orc_reaction.png`; as 3 opções estão em:
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_a.png`
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_b.png`
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_c.png`
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_opcoes.png`

## O que não foi verificado

- Nenhuma; a escolha do Bulbasaur foi feita (B com 0,03 para a esquerda).
- Os demais NPCs Pokémon (Charmander, Squirtle, Pikachu, Eevee) sem face crop estabelecido; continuam com a arte inteira por enquanto.
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).

## Nota D-1095 (2026-11-10)

O criador pediu um ícone fechado do Bulbasaur, com a face centralizada e a bochecha direita cortada, e o Bulbasaur passou a usar esse novo recorte (D-1095). O **B (0,78 + 0,03 para a esquerda)** e os PNGs A/B/C continuam como histórico/referência; a regra dos ícones estabelecidos para os demais personagens não muda.

## Estado

Regra registrada e ícones estabelecidos implementados; Bulbasaur em B escolhido, com 0,03 para a esquerda; o recorte fechado da D-1095 é o ícone atual. Commit local; **sem push**.
