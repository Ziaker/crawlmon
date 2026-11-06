# D-335 — Implementar no Godot os efeitos do atelier.html, um de cada, melhorando com shaders sem arruinar o visual

- **Data:** 2026-11-05
- **Área:** VFX / Motion Composer
- **Origem:** o criador, depois de me mandar o `prototypes/vfx_atelier/atelier.html` e pedir para "ignorar essas idiotices por ora".
- **Estado:** em andamento; **1 de 8 implementado** (Splitter Flames, só alvo único); aguarda a aprovação do criador antes do próximo.

## Frases literais do criador

> so implementa os efeitos visuais que estao no html ignora essas idiotices por ora

Perguntado qual implementar e em que ordem (os 8: Media, Mabufula, Dig, Sand Attack, Dragon Rage, Psycho Orb, Psychic Cannon, Splitter Flames):

> um de cada mas melhorando usando os shaders do godot, sem arruinar o visual, so melhorar

## Decisão

1. Implementar no Godot, **sobre o Motion Composer** (protocolo, D-308), os efeitos visuais dos 8 Moves do atelier, **um de cada**, **um por vez, com aprovação** antes do seguinte (AGENTS §8).
2. **Manter o visual do HTML**; só melhorar com shaders do Godot (fbm no lugar de simplex, cel-shading opcional, tempo explícito).
3. Tamanho: **fixo no mundo** (D-334), valores do HTML. Os ajustes pedidos antes sobre o Flame Stream (escala de volta, impacto médio com opacidade caindo) foram aplicados e **o clarão de release que eu tinha acrescentado sem pedido foi removido**.
4. Ordem escolhida por mim (o criador não disse): Splitter Flames primeiro, por já estar em andamento (D-236). Corrigir se não for isso.

## Estado

**Splitter Flames (alvo único)**: duas esferas de fogo nas mãos (0,05 → 1,05 em 0,70 s) com brasas convergindo; **release**: dois vórtices de fogo **parados nas mãos**, 0,30 s, com 26 brasas girando; voo em arco para cada lado convergindo no alvo, com rastro de chama que esfria em cinza; **impacto**: pilar de fogo de 1,05 s que vira cinza, 90 chamas subindo e chuva de cinzas. Shaders novos portados do HTML: `mc_fireball`, `mc_vortex_disc`, `mc_pillar`; representações `fireball`, `vortex_disc`, `pillar`; opções do `MotionEffect` (`local_offset`, `side_start`/`arc_rel`/`arc_up`, `ground`, `lt` nos itens). Skill "Splitter Flames" (alvo único, só visual) na sala de VFX; `MotionPresets.effect_for(move_id)`. Correção: a carga segurada não morre mais antes do disparo.
Verificado na batalha real, vista normal e espelhada: `test_captures/splitter_flames_v1.mp4`. **Não verificado:** modo dois alvos e redirecionamento (D-236), outros atacantes e alvos, desempenho, o checklist ponto a ponto, a aprovação artística. **Fraco:** na vista normal (alvo a ~37 m) o impacto e o voo ficam pequenos; no espelhado, as chamas do impacto ainda estouram em branco.
Os outros 7 efeitos (Media, Mabufula, Dig, Sand Attack, Dragon Rage, Psycho Orb, Psychic Cannon) **não foram iniciados**.
