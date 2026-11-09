# D-1071 — Slime 0,35× menor no overworld

- **Data:** 2026-11-09
- **Área:** Exploração / overworld 3D / escala de inimigo
- **Origem:** depois de aprovar o mini-mapa de bolinhas e o HUD, o criador pediu só o ajuste de tamanho do Slime.
- **Status:** direção registrada; **implementar no lab da Murky Forest**; o resto do overworld/HUD/mini-mapa está aprovado; nada publicado.

## O que o criador disse (literal)

> deixe o slime 0.35x menor no overworld, de resto esta ok

## Decisão

1. **Slime do overworld 0,35× menor.** No lab 3D da Murky Forest, o Slime (modelo, cápsula de colisão, agente de navegação, sombra e etiqueta) passa a **0,35× o tamanho atual**:
   - altura **1,4 m → 0,49 m**;
   - raio da cápsula **0,40 m → 0,14 m**;
   - sombra **1,2×1,0 → 0,42×0,35**;
   - etiqueta "SLIME" desce e a fonte encolhe junto;
   - poeira de passo acompanha a escala.
2. **Só o overworld.** A batalha 3D, a party, os atributos, os Moves, as regras e o jogo 2D **não mudam**.
3. **Lab de pedra (D-1023):** fica como referência em 1,4 m; o ajuste é aplicado no lab da Murky Forest (o overworld 3D atual). O mini-mapa continua com a bolinha vermelha de 10 px, sem relação com a escala do modelo.
4. **HUD/mini-mapa:** nada muda; HP/MP, alerta "!" e bolinhas azul/branco/vermelho continuam como em D-1037/D-1064.

## Ambiguidade registrada

- **"0,35× menor":** interpretei como **35% do tamanho atual** (escala 0,35; 1,4 m → 0,49 m). Se o criador quis dizer **35% de redução** (escala 0,65; 1,4 m → 0,91 m), é só trocar a constante. A escolha de 0,35 é a leitura literal de "0,35×".

## Estado

Direção registrada; implementar a escala no lab da Murky Forest e regravar as mídias. Nada de combate/2D muda; nada publicado.
