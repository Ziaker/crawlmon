# D-1128 — A/D giram a câmera; W/S andam; sem giro automático

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / câmera e controle.
- **Relacionadas:** D-1126 (auto-follow lento, **substituída**), D-1124, D-1107, D-1027.
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> troque o controle de camera pra usar o D (direita) e o A (esquerda) para girar, e aumente a velocidade do giro e NUNCA PERMITA que o giro automatico controle ou colida com o movimento da camera pelo A e D

## Regra

1. **A/D giram a câmera:** A gira para a esquerda, D para a direita, a **3,0 rad/s** (aumentado dos 1,6 rad/s do Q/E antigo). A/D **não movem** mais o personagem de lado.
2. **W/S andam:** W vai para frente na direção da câmera, S vai para trás; o personagem vira para a direção do movimento (D-1107).
3. **Sem giro automático:** o auto-follow é **removido**. A câmera só gira por **A/D**, **Q/E** (atalhos mantidos) ou **botão direito**. Nada de giro automático para controlar ou colidir com A/D.
4. **HUD atualizado:** o texto do lab passa a dizer `W/S: andar · A/D ou botão direito: câmera`.
5. **O que não muda:** paredes a 40% (D-1122), texturas, HUD/status, cards, regras, batalha, 2D e o resto.

## Relação com decisões anteriores

- **D-1126** (auto-follow lento) fica **substituída**: não existe mais giro automático.
- **D-1124** (A/D de lado) fica **substituída** na parte do A/D: agora A/D giram a câmera.
- **D-1107** continua valendo para o W/S (personagem vira para a direção do movimento) e para o Q/E/mouse como atalhos.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: `CAM_TURN_SPEED = 3.0`; A/D alteram `_cam_yaw`; W/S calculam `dir` a partir do `_cam_yaw`; remove `CAM_FOLLOW_*` e o bloco de auto-follow.
- `scripts/debug/murky_forest_3d_lab.gd`: texto de ajuda do lab.

## Provas

- `docs/referencias/exploracao/3d/d1128_camera_start.png` — início.
- `docs/referencias/exploracao/3d/d1128_camera_a.png` — depois de A (câmera girada).
- `docs/referencias/exploracao/3d/d1128_camera_d.png` — depois de D (voltou).
- `docs/referencias/exploracao/3d/d1128_camera_w.png` — depois de W.
- `docs/referencias/exploracao/3d/d1128_camera_s.png` — depois de S.
- `docs/referencias/exploracao/3d/d1128_camera_contact.png` — início/A/W/S em 2×2.
- `docs/referencias/exploracao/3d/d1128_camera_turn.mp4` / `.gif` — 5,2 s com A, D, W e S.

## O que foi verificado

- A/D giram a câmera a **3,0 rad/s**: A por 0,5 s levou o yaw de **3,142** para **4,642** (1,5 rad = 86°) e D voltou para **3,142**. O personagem **não saiu do lugar** durante A/D.
- W andou para frente (z -10 → -12,4) e S para trás (z -10,8), com o yaw da câmera fixo em **3,142**.
- **Nenhum giro automático:** a câmera só mudou com A/D. Não há `auto-follow` no código.
- O HUD passou a mostrar `W/S: andar · A/D ou botão direito: câmera`.
- A cena rodou com `exit=0`.

## O que não foi verificado

- A sensação final da velocidade 3,0 rad/s; pode ser ajustada em um número.
- Q/E no vídeo (continuam como atalhos), gamepad/analógico, outros labs e o jogo 3D principal (ainda 2D).

## Estado

Implementado e provado. Commit local; **sem push**.
