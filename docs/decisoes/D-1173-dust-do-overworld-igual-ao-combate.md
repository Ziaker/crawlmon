# D-1173 — Dust do overworld igual ao dust de entrada e de corrida do combate

- **Data:** 2026-11-11
- **Área:** Overworld 3D / VFX / dust de caminhada e de avanço
- **Origem:** pedido do criador sobre o dust do dash e da caminhada.
- **Status:** **implementado e testado; aguardando aprovação visual.**

## O que o criador disse (literal)

> quero que corrija o dust do dash e da caminhada pra ser igual ao dust da entrada e das corridas do combate no overworld

## Decisão

1. O dust do **avanço de ataque** (dash) e o dust da **caminhada** no overworld 3D passam a usar a **receita do combate**:
   - **Entrada/arranque:** `_spawn_takeoff_dust` de `scripts/vfx/combat/fx_motion.gd` — flipbook `smoke`, 8 puffs de fumaça e 7 pedregulhos no ponto de partida.
   - **Corrida:** `_dust_trail` — a cada **0,055 s**, 4 puffs de fumaça (`0,82, 0,78, 0,72`; 0,55-1,15 m; sobe 0,25) e 3 pedregulhos, nos pés alternados (offset lateral de 0,22 m).
2. **Caminhada:** esteira contínua da corrida do combate, na mesma cadência e nos pés alternados; sem takeoff/chegada.
3. **Dash:** takeoff no início + esteira durante o avanço. O **alpha continua 0,22** (D-1100 item 12), enquanto a caminhada usa a opacidade cheia do combate.
4. **Escala:** as dimensões físicas do combate (metros), sem encolher pela câmera do overworld.
5. **Sem mudar regra:** nenhum tempo, dano, alcance, ATB, câmera ou ataque muda. O dust continua só visual (D-019/D-235). D-308 não se aplica (overworld, D-1100 item 15).
6. A "entrada" citada pelo criador é o **burst de arranque (takeoff)**, não a transição de encontro.

## Ajuste do criador (2026-11-11)

> a fumaca da caminhada e muito maior do que devia, reduza ela em 50% de tamanho, inclusive adicione esse efeito de fumaca de caminhada no start do dash, nao continuamente com o dash, nao remova a dust que esta no dash, so adicione esta pra indicar um avanco bem forte

Regras adicionais:

7. **Fumaça da caminhada 50% menor:** os puffs de fumaça passam de **0,55-1,15 m** para **0,275-0,575 m** (metade linear). Os pedregulhos (0,06-0,14 m) e o offset dos pés (±0,22 m) não mudam.
8. **Start do dash:** o mesmo puff de fumaça da caminhada é emitido **uma vez** no arranque, nos **dois pés** (±0,22 m), em **opacidade cheia** — mas com o **tamanho atual cheio (0,55-1,15 m)**, não o tamanho reduzido da caminhada. Não continua durante o dash.
9. A dust existente do dash **não é removida**: o takeoff (flipbook + 8 puffs + 7 pedregulhos) e a esteira continuam com **alpha 0,22**. O puff extra é o indicador de “avanço bem forte”.
10. Nada de tempo, dano, alcance, ATK ou transição muda (D-235).

## Retificação do criador (2026-11-11)

> no caso, na caminhada ter a reducao de 50% mas ter o tamanho atual no dash, nao o tamanho de 50%

O item 8 fica assim: o puff extra do **start do dash** usa o **tamanho atual cheio** (0,55-1,15 m); somente a **caminhada** usa os 50% (0,275-0,575 m).

## Segundo ajuste do criador (2026-11-11)

> reduza a taxa de geracao de dust na caminhada em 40% e faca com que durante metade do dash inteiro ele continue gerando dust mas com 50% de tamanho, alem de deixar ainda maior o dust ja grande do inicio do dash, 20% maior

Regras adicionais:

11. **Taxa da caminhada 40% menor:** a cadência passa de **0,055 s** para **0,091667 s** (10,9 gerações/s em vez de 18,2/s). O tamanho da fumaça da caminhada continua **0,275-0,575 m**.
12. **Primeira metade do dash:** a fumaça da caminhada (tamanho 50%, **0,275-0,575 m**) continua sendo gerada na **primeira metade da duração real do dash**, na cadência da caminhada (0,0917 s), com pelo menos uma geração garantida. Depois da metade, só a dust existente do dash continua.
13. **Start do dash 20% maior:** o puff grande do início passa de **0,55-1,15 m** para **0,66-1,38 m** (×1,2), nos dois pés, em opacidade cheia, uma vez.
14. A dust existente do dash **não muda**: takeoff (flipbook + 8 puffs + 7 pedregulhos) e esteira continuam com alpha 0,22.
15. A duração real do dash vem do controlador (`_player_dash_duration` / `plan["time"]` do inimigo) e é passada ao VFX/dust por `set_dash_duration`.

## Ambiguidades resolvidas pelo criador (2026-11-11)

- Opacidade do dash: **manter 0,22** (D-1100 preservada).
- Escala: **tamanho físico do combate**.
- Caminhada: **esteira contínua do combate**.
- "Entrada": **burst de arranque (takeoff)**.

## Implementação

- `scripts/overworld/vfx/overworld_walk_dust.gd` (novo): ticker `CPUParticles3D` invisível que reproduz a esteira do combate nos pés do ator; mantém a API `emitting` usada pelo lab e expõe `set_alpha_multiplier`. A fumaça da caminhada usa **0,275-0,575 m** (50% do combate) e cadência **0,091667 s** (40% menos); o helper estático `spawn_effect` permite reutilizar o mesmo puff no dash com o **tamanho cheio 0,55-1,15 m** e no start com **0,66-1,38 m**.
- `scripts/overworld/vfx/overworld_dash_dust.gd`: reescrito para o takeoff + esteira do combate com alpha 0,22; no `begin` adiciona **uma vez** o puff de caminhada nos dois pés, em opacidade cheia e tamanho **0,66-1,38 m**; na **primeira metade da duração real do dash**, continua gerando o puff de caminhada em **0,275-0,575 m** e opacidade cheia, na cadência 0,0917 s.
- `scripts/debug/third_person_3d_lab.gd`: `_add_footstep_dust` passa a criar o novo dust.
- `scripts/overworld/vfx/overworld_dash_vfx.gd`: passa a direção real ao dash dust, recebe `set_dash_duration` e reduz o alpha da caminhada pelo novo método.
- `scripts/overworld/overworld_attack_controller.gd`: `_vfx_begin` leva a duração real do avanço (`_player_dash_duration` e `plan["time"]` do inimigo) ao VFX/dust.
- `tests/overworld/test_dust_match.gd`: **31/31** provas headless (textura de fumaça do combate, 4 puffs, 3 pedregulhos, pés alternados, alpha 0,22 no dash e 0,75 na caminhada; aliado e inimigo usam a mesma receita; caminhada a 50% e cadência 0,0917; start do dash 20% maior; continuação só na primeira metade).
- Capturas: `test_captures/d1173_walk_dust.png`, `d1173_dash_dust_normal_*` e `d1173_dash_dust_mirror_*` (harness isolado) e `d1173_dash_real_*` (lab real). Vídeo da revisão: `test_captures/d1173_dust_v3.mp4` (caminhada normal/espelhada, dash normal/espelhado).

## Relação com D-1100 item 12

A D-1100 pedia “dust de opacidade reduzida só no avanço; a corrida normal continua como está”. O criador agora pediu que a caminhada também use o dust do combate: a **corrida normal muda para a receita do combate em opacidade cheia**, e o **alpha 0,22 fica só no avanço**. O resto da D-1100 (regras do ataque, transições, alvo, retorno) não muda.

## Observação técnica

`VfxLib.burst` cria a curva de escala com `Curve.max_value` no padrão **1,0**, então o `end_scale` 1,8 do combate não cresce além de 1,0. O overworld usa a mesma função e ficou **idêntico ao combate**; corrigir isso mudaria todos os bursts do jogo e fica para uma decisão separada.

## Estado

Implementado e testado; aguardando aprovação visual. Sem commit e sem push.
