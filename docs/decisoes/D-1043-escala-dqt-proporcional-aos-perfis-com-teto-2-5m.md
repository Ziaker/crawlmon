# D-1043 — Escala DQT proporcional aos perfis, com teto de 2,5 m; 1,2 m uniforme rejeitado

- **Data:** 2026-11-09
- **Área:** Visual / Modelos / DQT / D-1013 / D-1033
- **Origem:** resposta do criador ao vídeo de teste antes/depois.

## Frase literal do criador

> "eles realmente mudaram de tamanho ou vc só deu zoom out? o depois está péssimo, porém o antes tem os personagens com escalas mt maior do que deviam, como o slime estar gigante e o cyclops estar minusculo, corrija o que já está presente no jogo"

## Decisão

1. O teste **mudou o tamanho dos modelos**, não a câmera: `_apply_scale_test` multiplica `model.scale`; a câmera `--cam=2` ficou na mesma posição.
2. O "depois" que o criador reprovou era **todos os DQT a 1,2 m**. Isso fica **rejeitado para o DQT**: achatar todos no mesmo tamanho deixou o conjunto ruim.
3. O "antes" estava errado porque `battle_scene._fit_height` media o **span de ossos**, não a malha visível. Resultado: Slime 3,52 m, Orc 3,17 m, Cyclops 2,76 m — Slime gigante e Cyclops pequeno.
4. Correção aplicada em `battle_scene._fit_height`:
   - medir a **malha visível** (AABB), excluindo arma (`WModel*`), `BurstRing`, `ReadyRing`, `Guard*` e `Shield*`;
   - **Pokémon** continuam no alvo de **1,2 m** (D-1013);
   - **DQT** usam a altura relativa já existente no perfil: Orc **2,1 m**, Slime **1,4 m**, Cyclops **3,22 m** limitado a **2,5 m** (D-1033); com margem de 2% para a pose, o Cyclops mediu **2,49 m**;
   - nenhum modelo acima de **2,5 m**.
5. Isto **supera a parte da D-1034 que exigia 1,2 m para o DQT**. A D-1013 continua valendo para os Pokémon comuns; a D-1033 (teto 2,5 m) continua.
6. Evidência: `test_captures/audit/body_scale_fix2/measurements.json` mede Orc 2,142 m, Slime 1,428 m, Cyclops 2,491 m e Gible 1,200 m. O vídeo `test_captures/scale_test/scale_fix_before_after.mp4` mostra antes/depois nas duas vistas, mas usa a câmera fixa de debug. **Vídeo representativo do jogo normal:** `test_captures/scale_test/game_camera_normal_mirror.mp4`, com HUD e câmera de combate; o DQT não existe no jogo normal, só na sala de debug.

## Ambiguidades em aberto

- Os números de DQT usados são os **perfis existentes** (2,1 / 1,4 / 3,22), não valores novos inventados. Se o criador quiser outra proporção, ajustar os perfis.
- A ferramenta 4 continua reprovada quanto a `pose_height` (pose viva), mas a escala do jogo agora está corrigida.

## Estado

**Revertida por D-1047**, exceto as duas exceções de Cyclops e Slime que usam o perfil. O ajuste global por malha visível e o teto de 2,5 m para todos não estão mais no jogo. Sem commit/push.
