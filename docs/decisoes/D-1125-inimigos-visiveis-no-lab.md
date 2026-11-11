# D-1125 — Inimigos visíveis no lab: o alvo não pode sumir com a câmera perto

- **Data:** 2026-11-10
- **Área:** Lab 3D / câmera / visibilidade / ataque no overworld
- **Origem:** o criador relatou que os inimigos não aparecem no ambiente 3D e parecem bugados.
- **Status:** **implementado e testado** (câmera do jogo + diagnóstico + 66/66 controlador + 64/64 VFX + ponta a ponta); demo refeita.
- **Relacionadas:** D-1100, D-1106, D-235, D-1120, D-1127.

## O que o criador disse (literal)

> os inimigos não estão visiveis no ambiente 3D, estão todos bugados também

## Diagnóstico

- Os dois inimigos existem e estão no mundo: o Slime em ~`(11, 0, -10)` e o Gible em `(5, 0, -5)`.
- O Slime era escondido por `third_person_3d_lab.gd` quando a câmera ficava a menos de **6,2 m** dele (`_enemy_body.visible = cam_delta.length() > 6.2`). Como o ataque exige chegar a **4,5 m**, o alvo desaparecia justamente na hora de atacar.
- O Gible não tinha esse esconde; o que o escondia nos vídeos era o enquadramento da câmera atrás do jogador.

## Decisão

1. O inimigo **não pode desaparecer** quando o jogador se aproxima; o alvo do ataque (até 4,5 m) tem de estar visível.
2. O esconde antigo por distância da câmera (`< 6,2 m`) é **removido**.
3. A única exceção permitida é o inimigo **atrás do jogador** e a menos de **1,2 m** da câmera, para a câmera não entrar no modelo; ao sair dessa posição, ele volta a aparecer.
4. Vale para qualquer inimigo/ator (D-235). O Slime Medroso continua fugindo (D-1086), mas visível; o Gible continua visível.
5. Não muda IA, fuga, combate, dano, timing nem transições; é correção de visibilidade.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`, em `_update_enemy`: o `visible` agora só é falso se o inimigo estiver atrás do jogador **e** a menos de 1,2 m da câmera; caso contrário, visível.
- **Câmera travada:** `murky_forest_3d_lab._physics_process` chamava `super(delta)` só quando a animação de ataque terminava; o jogador andava e a câmera ficava no ponto inicial (os inimigos sumiam da tela). Agora a base roda **todo frame**.
- **Câmera dentro do jogador:** em `_update_camera`, quando a câmera chega a menos de 1,25 m do jogador (parede atrás), os meshes do jogador são escondidos; a cabeça não cobre o inimigo.
- **Placas/ícones:** as placas dos inimigos usam a altura visual real +0,55 m (`_actor_visual_top`); o ícone de estado é escalado pela altura do ator (D-1105/D-1127); o segundo Gible não tem ícone extra (D-1106) para não ficar no “?” inicial.
- O prompt do ataque é `[Z] ATTACK` (D-1127); o E era desenhado fixo no prompt e foi removido.
- Diagnóstico: `tests/overworld/diagnose_enemy_framing.gd` gera `docs/referencias/exploracao/3d/diag_enemy_slime_side.png` e `diag_enemy_gible_side.png`; `tests/overworld/diagnose_enemies_gamecam.gd` gera `diag_gamecam_slime.png` e `diag_gamecam_gible.png` com a câmera real.
- Gravação da demo: `tests/overworld/record_lab_attack_showcase.gd` (HUD do lab oculto, câmera de lado, 120 fps; slow motion 4× no ffmpeg).
- Demo limpa: `docs/referencias/exploracao/3d/overworld_showcase_demo.mp4` (120 fps gravados, 30 fps, 4×) e os casos `overworld_showcase_case_player/enemy/contact.mp4`; `overworld_attack_3cases.mp4` foi substituído pela demo.
- Testes: controlador **66/66**, VFX **64/64** e ponta a ponta PASS; o diagnóstico da câmera real mostra Slime e Gible visíveis.

## Estado

Implementado e testado; câmera do jogo e vídeos refeitos; pendente aprovação visual. Sem commit e sem push.
