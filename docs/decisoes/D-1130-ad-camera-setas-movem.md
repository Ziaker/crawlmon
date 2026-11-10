# D-1130 — A/D só giram a câmera; as setas movem o boneco

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / controle.
- **Relacionadas:** D-1128 (A/D câmera, W/S anda), D-1107, D-1127.
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> vc tá tratando o A e o D como movimento do boneco NÃO, NÃO NÃO, AS SETAS QUE SÃO O MOVIMENTO DO BONECO, VOLTA ATRÁS COM ISSO SÓ

## Regra

1. **A/D são só da câmera:** A gira para a esquerda, D para a direita, a **3,0 rad/s**. A/D **não movem** o personagem.
2. **As setas movem o boneco:** ←/→ andam de lado, ↑/↓ andam para frente/trás, relativo à câmera; o personagem vira para a direção do movimento. **W/S** continuam como atalhos de andar.
3. **Sem giro automático:** nada de auto-follow; a câmera só gira com A/D, Q/E (atalhos) ou botão direito.
4. **HUD:** `Setas/W/S: andar · A/D ou botão direito: câmera`.
5. **O que não muda:** paredes a 40% (D-1122), texturas, HUD/status, cards, regras, batalha, 2D e o resto.

## Relação com decisões anteriores

- **D-1128** estava certa em A/D = câmera, mas usava `ui_left/ui_right` para girar; como essas ações incluem **A/D e as setas**, as setas também giravam a câmera. Esta decisão **separa as teclas**: A/D vão direto para a câmera; as setas vão direto para o movimento.
- **D-1107** continua valendo no movimento relativo à câmera.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: A/D e Q/E leem `KEY_A`/`KEY_D`; o movimento lê `KEY_LEFT`/`KEY_RIGHT`/`KEY_UP`/`KEY_DOWN` + `KEY_W`/`KEY_S`.
- `scripts/debug/murky_forest_3d_lab.gd`: texto do HUD.

## Provas

- `docs/referencias/exploracao/3d/d1130_camera_start.png` — início.
- `docs/referencias/exploracao/3d/d1130_camera_a.png` — depois de A (câmera).
- `docs/referencias/exploracao/3d/d1130_camera_d.png` — depois de D (voltou).
- `docs/referencias/exploracao/3d/d1130_camera_left.png` — seta esquerda (boneco).
- `docs/referencias/exploracao/3d/d1130_camera_right.png` — seta direita.
- `docs/referencias/exploracao/3d/d1130_camera_up.png` — seta cima.
- `docs/referencias/exploracao/3d/d1130_camera_down.png` — seta baixo.
- `docs/referencias/exploracao/3d/d1130_camera_contact.png` — início/A/esquerda/cima em 2×2.
- `docs/referencias/exploracao/3d/d1130_camera_keys.mp4` / `.gif` — 6,5 s com A/D e as quatro setas.

## O que foi verificado

- **A/D só giram a câmera:** A por 0,5 s levou o yaw de **3,142** para **4,642** e D voltou para **3,142**, com o personagem **parado** em (7, -10).
- **Setas movem o boneco:** ← levou o personagem de x 7 para 4,87; → voltou para 7; ↑ foi de z -10 para -12,4; ↓ voltou para -10,8 — sempre com o yaw da câmera fixo em **3,142**.
- **Nenhum giro automático:** a câmera não se mexeu durante as setas.
- O HUD mostra `Setas/W/S: andar · A/D ou botão direito: câmera`.
- A cena rodou com `exit=0`.

## O que não foi verificado

- Gamepad/analógico, sensibilidade, outros labs e o jogo 3D principal (ainda 2D).

## Estado

Implementado e provado. Commit local; **sem push**.
