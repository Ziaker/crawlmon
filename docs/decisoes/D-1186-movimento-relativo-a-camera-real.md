# D-1186 — Movimento relativo à câmera real, não ao yaw da órbita

- **Data:** 2026-11-11.
- **Área:** Exploração 3D / lab Murky Forest / câmera e controle.
- **Origem:** o criador relatou que a câmera força o boneco a virar e quebra o senso de direção dos botões.
- **Status:** corrigido e testado headless.

## O que o criador disse

> "tem como corrigir os bugs da camera forcando o boneco a virar e tambem quebrando todo senso de direcao dos botoes"

## Diagnóstico

- O controle é relativo à câmera (D-1107) e A/D giram a câmera (D-1130); não existe auto-follow.
- Quando uma parede bloqueia a câmera, `_update_camera` faz uma **busca lateral** e move a câmera para o lado. O `_cam_yaw` da órbita **não muda**.
- O movimento usava `Vector3(sin(_cam_yaw), 0, cos(_cam_yaw))`, ou seja, o yaw **antigo**. A câmera visível podia estar olhando de outro lado, então W/setas não correspondiam ao que o jogador via e o personagem virava para a direção errada.
- Em espaço aberto o yaw da órbita e a câmera real coincidem; o bug aparece perto de paredes/portas, quando a busca lateral desloca a câmera.

## Decisão

1. **A base do movimento é a câmera real:** usar a direção horizontal de `-_camera.global_transform.basis.z` (frente real da câmera), projetada no chão e normalizada.
2. **Fallback:** se a câmera estiver quase vertical/sem componente horizontal, usar o `_cam_yaw` como antes.
3. **A direita também vem da câmera real:** `cam_right = cam_forward.cross(Vector3.UP)`, para setas/W/S manterem o sentido da tela.
4. **O personagem continua virando para a direção do movimento** (D-1107). O que muda é que a direção agora é a que o jogador vê, não o yaw antigo da órbita.
5. **A/D continuam sendo só câmera** (D-1130); W/S e setas continuam andando. Não há auto-rotação.
6. **Nada muda em combate, 2D, regras, HUD ou velocidades.**

## Relação com decisões

- **D-1107:** mantém o controle relativo à câmera; corrige qual câmera é usada como referência.
- **D-1130:** A/D câmera, setas/W/S movimento; inalterado.
- **D-1023/D-1060:** a colisão da câmera continua; esta decisão só faz os botões seguirem a câmera resultante.
- **D-019/D-1040:** só visual/controle, sem tocar no relógio ou nas regras.

## Ambiguidades em aberto

- **Personagem não virar ao girar a câmera:** se o criador quiser que o boneco mantenha a facing enquanto a câmera orbita (strafe), isso muda o item 4 da D-1107 e precisa de decisão própria. Não foi feito.
- **Reduzir a busca lateral da câmera:** não foi alterada; o teste cobre o desalinhamento, não a suavidade do lado.
- **Vídeo/gamepad:** não verificado.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/debug/third_person_3d_lab.gd`: `_camera_ground_forward()` e uso no `_physics_process`.
- `tests/overworld/test_d1186_camera_relative.gd`: **6/6 PASS** (`D1186_CAMERA_RELATIVE_TEST_PASS`), simulando a câmera empurrada para o lado e verificando que ela não gira sozinha nem vira o boneco parado.
- Cena `murky_forest_3d_lab.tscn` headless: `exit=0`.
