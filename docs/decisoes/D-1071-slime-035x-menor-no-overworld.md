# D-1071 — Slime 0,35× menor no overworld

- **Data:** 2026-11-09
- **Área:** Exploração / overworld 3D / escala de inimigo
- **Origem:** depois de aprovar o mini-mapa de bolinhas e o HUD, o criador pediu só o ajuste de tamanho do Slime.
- **Status:** **teste implementado no lab da Murky Forest** via nó `SlimeOverworldScaler`; o resto do overworld/HUD/mini-mapa está aprovado; nada publicado.

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

## Teste implementado (2026-11-09)

- **Nó `SlimeOverworldScaler`:** adicionado como filho de `scenes/debug/murky_forest_3d_lab.tscn` (e do `murky.tscn` isolado). Ele espera um frame de física e escala o `_enemy_body` já construído; o script do lab não foi alterado (outra sessão também edita esse arquivo).
- **Escala aplicada:** altura da cápsula **1,4 → 0,49 m**, raio **0,40 → 0,14 m**, agente de navegação idem; modelo em 0,35×; sombra **1,2×1,0 → 0,42×0,35**; etiqueta "SLIME" com fonte 23 e y 0,686; poeira em 0,4×.
- **Auditoria solo/party:** `capsule_h=0.4900000095`, `scale=0.35`; 0 paredes/câmeras/paths/stack; porta `near/visible/used`; Slime em `CHASE`; bolinhas/HUD/MP/alerta intactos; toon true.
- **Mídias:** `murky_forest_solo.*`, `murky_forest_party.*`, `murky_forest_minimap.png`, `murky_forest_hud.png`; 11,0 s / 330 quadros.
- **NPCs paralelos:** o lab tem código de NPCs de outra sessão (D-1063) ainda em trabalho; para a gravação do Slime, os NPCs foram desativados no projeto isolado e o texto de controles voltou ao aprovado. O código principal não foi commitado por esta decisão.

## O que não foi verificado

- Se "0,35× menor" era **35% do tamanho** (0,49 m; escolhido) ou **35% de redução** (0,91 m). Trocar a constante se for o segundo caso.
- O lab de pedra D-1023 continua em 1,4 m; só a Murky Forest recebeu a escala.
- A batalha 3D, o jogo 2D, a party e as regras não foram tocados.
- NPCs, performance em 60 fps, mobile/web, licença.

## Estado

Teste implementado no lab isolado; mídias regravadas. O Slime do overworld está em 0,49 m. O lab de pedra D-1023 fica como referência em 1,4 m; a batalha 3D e o jogo 2D não mudam; nada publicado.
