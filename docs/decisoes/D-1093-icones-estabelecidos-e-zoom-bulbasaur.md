# D-1093 — Retratos/ícones usam o ícone estabelecido do personagem; 3 zooms do Bulbasaur

- **Data:** 2026-11-09.
- **Área:** Exploração / UI / diálogo / retratos.
- **Relacionadas:** D-1074 (face crop dos cards), D-1089 (aliados), D-1090 (HUD C), D-1092 (faixas/câmera).
- **Status:** **regra registrada; ícones estabelecidos implementados; zoom do Bulbasaur aguardando escolha A/B/C**; batalha, 2D, regras de combate e HUD/status não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> não use o icon da arte inteira, usa o icon já estabelecido para o personagem, inclusive já me de as 3 opções de zoom pro bulbasaur em forma de png para eu escolher o melhor zoom de icone

> coloque isso nos documentos como regra do jogo também

## Regra

1. **Retratos de diálogo e faixas usam o ícone estabelecido do personagem**, não a arte Sugimori inteira.
2. **Pokémon com face crop estabelecido** (Abra, Pancham, Gible e, a partir desta decisão, Bulbasaur) usam o recorte de rosto, no mesmo método da D-1074. O recorte é aplicado com `AtlasTexture` sobre a arte local.
3. **Orc** usa o retrato estabelecido do Orc (`personagens/portraits/orc.png`), que já é um busto/rosto; não é a arte inteira.
4. **Bulbasaur:** três zooms candidatos, em PNG, para o criador escolher:
   - **A — fechado:** `Rect2(0.00, 0.10, 0.64, 0.64)`;
   - **B — médio:** `Rect2(0.00, 0.04, 0.78, 0.78)`;
   - **C — aberto:** `Rect2(0.00, 0.00, 0.92, 0.92)`.
   - O escolhido vira o recorte canônico do Bulbasaur em todo retrato de diálogo/faixa.
5. **Até a escolha:** o código usa **B (médio)** como provisório. Não é a decisão final; é só para o jogo já não exibir a arte inteira.
6. **Bulbasaur é o único com opções agora.** Os demais NPCs Pokémon sem face crop estabelecido continuam com a arte inteira até receberem seu próprio recorte; o pedido desta rodada é o Bulbasaur.
7. **O que não muda:** batalha, 2D, HUD/status, cards, regras, falas e a câmera.

## Arquivos das opções

- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_a.png` (fechado, 0,64)
- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_b.png` (médio, 0,78)
- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_c.png` (aberto, 0,92)
- `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_opcoes.png` (folha A/B/C com o medalhão Paper)

Os PNGs mostram o recorte dentro do medalhão dourado com aro verde, como o retrato aparece no card/faixa. O jogo usa o **recorte** correspondente, não o PNG com o aro, para não duplicar a moldura.

## Teste implementado (2026-11-09)

- **Estabelecidos:** `_portrait_for_speaker()` agora aplica `AtlasTexture` para Abra/Pancham/Gible/Bulbasaur; Orc continua no retrato próprio.
- **Bulbasaur:** recorte B provisório no card Paper e nos retratos de NPC; o card mostra o rosto, não o corpo inteiro.
- **Pancham:** faixa com o face crop estabelecido, não a arte inteira.
- **Orc:** retrato estabelecido, como antes.
- **Provas:** os retratos aparecem no `murky_forest_paper_dialogue.png` e nas faixas `murky_forest_panchan_reaction.png`/`murky_forest_orc_reaction.png`; as 3 opções estão em:
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_a.png`
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_b.png`
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_c.png`
  - `docs/referencias/exploracao/3d/bulbasaur_icon_zoom_opcoes.png`

## O que não foi verificado

- A escolha final A/B/C do Bulbasaur.
- Os demais NPCs Pokémon (Charmander, Squirtle, Pikachu, Eevee) sem face crop estabelecido; continuam com a arte inteira por enquanto.
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).

## Estado

Regra registrada e ícones estabelecidos implementados; Bulbasaur em B provisório, aguardando A/B/C. Commit local; **sem push**.
