> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste pode levar mais de 1 minuto; crie o cenário/controle antes de testar. Ver `docs/TELEMETRIA.md`.

# D-1264 — Locomoção sincronizada e pés no chão, medidos do rig

**Frase literal do criador:** "o modelo do gible fica embaixo do chão, a velocidade de movimento dele e a velocidade da animação não estão sincronizadas e desconfio que ele tem uma animação de corrida melhor"

## Decisão (técnica, sem mudar regra nem velocidade de movimento)
- A velocidade de movimento não foi alterada. A animação é que acompanha: `ModelGait` (`scripts/overworld/model_gait.gd`) mede do próprio esqueleto, por clip, a velocidade do pé plantado e o quanto o vértice mais baixo desce abaixo do repouso. Nenhum número por espécie (D-235).
- `_apply_gait` (`third_person_3d_lab.gd`) escolhe `walk` ou `run` pela velocidade real e ajusta `speed_scale` (0,5 a 3,0). Vale para líder e seguidores, no hub e na Murky Forest. Espécies sem pé plantado (Abra flutua) mantêm o comportamento antigo.

## Medido (headless, `tests/overworld/diag_gait_sync.gd`, velocidade 4,8 m/s)
- Gible: clip `run`, escala 3,0 (teto), pé plantado a 4,54 m/s vs corpo 4,8. Antes: `walk` a 1,0× (pé a ~0,6 m/s: patinava).
- Afundamento do Gible pela malha skinada: ≤ 0,007 m (corrida) e 0,003 m (andar); pés a ~1 cm do chão. Não se confirmou afundamento no hub; ver pendências.
- Clips do Gible: attack, attack_special, battle_idle, charge, damage, down, idle, run, victory, walk. Não existe clip de corrida melhor; `run` (0,50 s) é o usado.

## Pés no chão (ordem do criador: corrigir)
- `_apply_ground_lift` sobe o modelo pelo quanto o clip empurra o vértice mais baixo abaixo do repouso (medido por `ModelGait`, cache por modelo+altura). Platypunk −8,5 cm → +0,9 cm; Sabrecub −2,0 → +1,1; Charmander −1,1 → +0,2. Restam Bulbasaur −2,2 cm (plano) e Gible −2,5 cm (rampa do altar).

## Olhos (Charmander)
- A íris azul-esverdeada é a cor oficial do material original (`BaseColorLayer3` linear 0/0,165/0,191 ≈ sRGB 0/110/120); nada alterado. Tentativa de brilho via `eye_msk` foi revertida (a máscara cobre o olho todo).

## Pendente
- Cyclops/Orc: velocidade do pé medida pouco confiável; Cyclops bate no teto 3,0×.
- Se 3× parecer frenético, o criador decide: reduzir a velocidade do corpo ou aceitar.
