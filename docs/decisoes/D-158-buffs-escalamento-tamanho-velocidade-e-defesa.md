# D-158 — Efeitos Visuais Físicos de Buffs e Debuffs: Tamanho, Velocidade de Animação e Armadura

- **Data:** 2026-11-03
- **Área:** Visual / Combate / Game Feel / Shaders
- **Origem:** Conversa (/grill-me)

## O que o criador disse (literal)

> "faça com que os buffs aumentem também o tamanho do personagem, no caso de +atk, eles ficam .15 maiores por stack e -atk, ficam .15 menores por stack, para +spd, a animação idle deles é tocada .15x mais rápida por stack e o mesmo pra quando é -spd, .15x mais lenta. Quanto a +def eu não sei /grill-me"
> "Brilho e Contorno de Armadura (Shader): +def engrossa o contorno anime e aplica um tom sutil metálico/cristalino, enquanto -def enfraquece o contorno e adiciona leve efeito de rachadura"
> "(Recommended) Transição animada suave (~0.35s): o modelo cresce/encolhe e ajusta contorno/velocidade com um tween fluido e leve bounce ao receber o stack"
> "se vc ver o gdd mais recente, sim, até pq um influencia o outro" (sobre velocidade de animação afetar tanto idle quanto corrida).

## Decisão

1. **Alteração de Tamanho por ATK (+atk / -atk):**
   - O modelo do personagem escala em proporção de `±0.15` (+15% / -15%) por stack de ataque:
     - `+1 ATK`: escala multiplicada por `1.15`.
     - `+2 ATK`: escala multiplicada por `1.30`.
     - `-1 ATK`: escala multiplicada por `0.85`.
     - `-2 ATK`: escala multiplicada por `0.70`.
     - `0 ATK`: escala base nominal (`1.0`).
   - A transição é interpolada via tween suave (`~0.35s`) com leve amortecimento elástico (`TRANS_BACK`, `EASE_OUT`).
   - O `_base_scale` em `BattleFx` e `FxMotion` é atualizado dinamicamente para que movimentos, poses de ataque e deformações cinéticas de hit-stop preservem o novo porte do personagem.

2. **Alteração de Velocidade de Animação por SPD (+spd / -spd):**
   - A taxa de reprodução (`speed_scale`) das animações de combate (idle e corrida de deslocamento) é multiplicada por `±0.15x` por stack de velocidade:
     - `+1 SPD`: velocidade `1.15x`.
     - `+2 SPD`: velocidade `1.30x`.
     - `-1 SPD`: velocidade `0.85x`.
     - `-2 SPD`: velocidade `0.70x`.
     - `0 SPD`: velocidade nominal (`1.0x`).
   - Transição suave via tween no `speed_scale` do `AnimationPlayer`.

3. **Alteração de Armadura e Shader por DEF (+def / -def):**
   - Para `+def`:
     - O contorno anime (`outline`) tem sua espessura aumentada em `+35%` por stack (ex: de 0.0035 para 0.0047 em +1 e 0.0059 em +2).
     - Os materiais de superfície recebem elevação de brilho metálico/cristalino (`metallic` / `metallic_specular`) com leve reflexo de blindagem.
   - Para `-def`:
     - A espessura do contorno anime é adelgaçada em `-35%` por stack (ex: para 0.0023 em -1 e 0.0012 em -2).
     - Materiais de superfície recebem redução de brilho com aspecto desprotegido/fragilizado.
   - Transição interpolada em `~0.35s`.

4. **Persistência, Limpeza e Cancelamento:**
   - Ao zerar os buffs (`clear_buffs`) ou ao término da batalha, o modelo transiciona suavemente de volta à sua escala original, velocidade normal e parâmetros padrão de contorno e materiais.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma (todas as ramificações alinhadas via /grill-me).

## Estado no código

Implementado (`battle_fx.gd`, `combatant.gd`, `vfx_lib.gd`, `tests/battle/test_d158_buff_visuals.gd`).

## Complemento posterior (2026-11-03)

**D-165:** a velocidade por SPD vale para todos os clipes, não só idle e corrida. **Correção:** o VFX do Tarukaja restaurava a escala antiga ao terminar e desfazia o tamanho; `smt_stage_vfx.gd` agora só restaura a escala no Rakunda. O fim do hit-stop restaurava a velocidade antiga e desfazia o SPD; `fx_motion.gd` agora usa a velocidade atual.
