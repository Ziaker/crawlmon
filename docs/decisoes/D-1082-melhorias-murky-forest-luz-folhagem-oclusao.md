# D-1082 — Melhorias do lab da Murky Forest: luz, folhagem/verticalidade e oclusão

- **Data:** 2026-11-09.
- **Área:** Exploração / lab 3D / level art.
- **Relacionadas:** D-1028 (visual), D-1023 (câmera), D-1063 (NPCs), D-1043 (escala), D-1075 (status).
- **Status:** **teste implementado e verificado** no lab isolado; HUD/status/cards, NPCs, batalha, 2D e regras não mudam; commit local; **sem push**.
- **Nota D-1083 (2026-11-09):** a iluminação foi baixada e ficou menos contrastada/saturada; geometria, vinhas/galhos e fade de oclusão continuam iguais.

## O que o criador disse (literal)

> me diz 10 melhorias que faria nesse mapa

> prossiga

## Decisão

O criador autorizou prosseguir com as três melhorias de maior impacto que eu propus:

1. **Iluminação legível:**
   - luzes de preenchimento frio no início/corredor para tirar os vazios pretos;
   - luz quente de aproximação da saída;
   - lua/light key um pouco mais forte, sem mudar a paleta verde/teal/âmbar de D-1028;
   - nenhuma luz azul nova.
2. **Folhagem e verticalidade:**
   - vinhas penduradas nas paredes/troncos, ligando a copa ao nível dos personagens;
   - galhos médios saindo dos troncos, com folhagem nas pontas;
   - mais variação de copa (alta/baixa/pendurada) e clumps menores nas paredes;
   - nada flutuando solto: vinhas/galhos ancorados em parede, tronco ou copa.
3. **Câmera/oclusão:**
   - empurrar a folhagem baixa das paredes um pouco para dentro da parede e reduzir os raios que invadem o corredor;
   - fade suave das folhas que ficam entre a câmera e o jogador, mantendo D-1023 (a câmera nunca obstrui, só se ajusta);
   - o fade é visual; não altera colisão, navmesh, NPCs ou a câmera.

## Escopo

- Só `scripts/debug/murky_forest_3d_lab.gd` (e o lab isolado para teste).
- Não mudar HUD/cards, status D-1075, Sugimori/Gible, NPCs, Slime, batalha, 2D, renderer ou regras.
- Manter a escala do lab (D-1043) e a paleta D-1028.

## O que não foi verificado

- Performance com o fade em muitos clumps e luzes em 60 fps/mobile.
- Se o fade de folhagem fica bom em todas as resoluções; pode precisar de ajuste de alpha/raio.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Teste implementado (2026-11-09)

- **Luz:** lua 0,72; preenchimento central 1,2; preenchimento frio no início (0, 3,0, -2,0) e na curva (0, 2,8, -8,8); aproximação quente da saída em (13,5, 2,2, -10,0). Sem luz azul.
- **Verticalidade:** 10 vinhas ancoradas nas paredes/copa, 4 galhos saindo dos troncos e 12 clumps médios nas paredes. A folhagem baixa foi empurrada para dentro da parede e os raios reduzidos para não invadir o corredor.
- **Oclusão:** cada folhagem (principal e clumps) tem alpha animado; quando fica entre a câmera e o jogador, desce para 0,22; volta a 1,0 quando sai. A colisão, a navmesh e a câmera continuam iguais.
- **Auditoria solo:** `wall_hits=0`, `cam_inside=0`, `cam_close_frames=0`, `path_short=0`, `path_min=2`, `stack_pairs=0`.
- **Auditoria party:** os mesmos resultados; `cam_min=3,79`.
- **Provas:** `murky_forest_hud_sugimori.png`, `murky_forest_status_hidden.png`, vídeos party/solo e `murky_forest_status_contato.png` regravados com o mapa novo.
- **Escopo:** HUD/status D-1075, cards, Sugimori/Gible, NPCs, Slime, batalha, 2D e renderer não foram tocados.

## O que não foi verificado

- Performance do fade/mais luzes em 60 fps/mobile.
- O fade em todas as resoluções e com a câmera muito perto de paredes.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Teste implementado e verificado no lab isolado. Luz, folhagem/verticalidade e oclusão suave aplicadas; auditoria de câmera/caminho passou; provas regravadas. Commit local; **sem push**. Nada de combate/2D/HUD mudou.
