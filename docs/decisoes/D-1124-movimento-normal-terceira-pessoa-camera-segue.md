# D-1124 — Movimento normal de terceira pessoa: A/D de lado, câmera acompanha a posição

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / controle e câmera.
- **Relacionadas:** D-1107 (WASD relativo à câmera), D-1123 (trava + auto-follow, **revertida**), D-1027 (câmera), D-1088 (diálogo), D-1100 (ataque).
- **Status:** **implementado/provado**; commit local; **sem push**.

## O que o criador disse (literal)

> EU NÃO QUERO MOVIMENTO DE TANQUE MEU DEUS, EU SÓ QUERO UM MOVIMENTO NORMAL DE TERCEIRA PESSOA

> andam de lado e movem a camera junto, como kingdom hearts e zelda

## Regra

1. **WASD relativo à câmera, sem trava:** a direção é recalculada a cada quadro. **A/D andam de lado**, W/S vão para frente/trás, e o personagem vira para a direção do movimento (`TURN_RATE`). Nada de direção presa, nada de tanque.
2. **A câmera acompanha a posição:** o pivô da câmera segue o jogador a cada quadro, então ela **vai junto** e o personagem não sai da tela. O **ângulo** da câmera não gira sozinho; quem gira é o jogador, com Q/E ou botão direito.
3. **A/D anda reto:** como a câmera não gira sozinha, segurar A/D move o personagem em linha reta para o lado. **Não** há curva, círculo, trava ou giro de 180°.
4. **Por que não auto-follow de yaw:** testado, segurar A/D com a câmera perseguindo o yaw faz o personagem girar em círculo (mais de 450° em 1,25 s), que é o "tanque" que o criador rejeitou.
5. **Diálogo e ataque:** continuam travando o jogador como antes (D-1088/D-1100).
6. **O que não muda:** paredes a 40% (D-1122), texturas, HUD, cards, regras, batalha, 2D e o resto.

## Relação com decisões anteriores

- **D-1123** (câmera seguindo o yaw + direção travada) fica **revertida**: a trava e o auto-follow de yaw saem.
- **D-1107** volta a valer integralmente: WASD relativo à câmera, personagem vira para a direção, câmera segue a **posição**, Q/E e mouse orbitam.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: remove `_move_input`/`_move_dir`, `CAM_FOLLOW_RATE`/`CAM_FOLLOW_GRACE` e o bloco de auto-follow; restaura o cálculo de `dir` por quadro e o giro do personagem.

## Provas

- `docs/referencias/exploracao/3d/d1124_camera_start.png` — início.
- `docs/referencias/exploracao/3d/d1124_camera_w.png` — depois de W.
- `docs/referencias/exploracao/3d/d1124_camera_a.png` — depois de A (de lado, reto).
- `docs/referencias/exploracao/3d/d1124_camera_s.png` — depois de S.
- `docs/referencias/exploracao/3d/d1124_camera_d.png` — depois de D (de lado, reto).
- `docs/referencias/exploracao/3d/d1124_camera_contact.png` — início/A/S/D em 2×2.
- `docs/referencias/exploracao/3d/d1124_camera_follow.mp4` / `.gif` — 12,7 s com W, A, S e D.

## O que foi verificado

- W, A, S e D movem o personagem sem girar a câmera; A e D andam em linha reta para o lado.
- No teste, o yaw da câmera ficou fixo em **3,142** durante W/A/S/D, enquanto o personagem virava para a direção do movimento.
- A câmera acompanha a posição (o personagem permanece enquadrado).
- A cena roda com `exit=0`.
- Não há trava, não há curva e não há giro de 180°.

## O que não foi verificado

- Q/E e botão direito no vídeo (a lógica é a mesma da D-1107, já provada).
- Gamepad/analógico, sensibilidade, outros labs e o jogo 3D principal (ainda 2D).

## Estado

Implementado e provado. Commit local; **sem push**.
