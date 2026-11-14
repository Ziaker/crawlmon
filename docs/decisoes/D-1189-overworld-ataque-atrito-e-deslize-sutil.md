# D-1189 — Ataques no overworld: atrito e deslize sutil no avanço, para todos os personagens

- **Data:** 2026-11-12.
- **Área:** Overworld 3D / ataque / avanço (`overworld_attack_controller.gd`) / dust.
- **Status:** implementado e testado headless (`test_overworld_attack.gd`, `test_dash_vfx.gd`, `test_dust_match.gd`, `test_impact_reaction.gd`); **não visto no jogo**; **aprovado pelo criador em 2026-11-12** ("Está bom"). Código: `overworld_attack_controller.gd` (`_friction_plan`/`_friction_speed`, usados por jogador e inimigos), `overworld_dash_vfx.gd` e `overworld_dash_dust.gd` (`set_slide_time`).
- **Efeito conhecido:** em avanços longos (jogador, até 4,4 m) a velocidade inicial fica bem acima da antiga (~47 m/s contra 18 m/s); no avanço de 2 m é ~15 m/s contra 11 m/s.

## O que o criador disse

> "agora aplique atrito e deslize sutil durante ataques no overworld. todas mudanças pra ataques no overworld devem afetar todos personagens não só o jogador. todos inimigos também"

Respostas às perguntas: aplicar **"no avanço inteiro"**; deslize **"~0,3 m em ~0,25 s"**; poeira **"sim, pouca"**; combinação com o contato: **"freia até o contato"** (o impacto passa a ocorrer no fim da frenagem, no contato).

## Decisão

1. **Regra geral (do criador):** toda mudança de ataque no overworld vale para o jogador **e para todos os inimigos** (mesmo código, sem ramo por personagem; D-235).
2. O avanço deixa de ter velocidade constante: ele **sai rápido e freia por atrito** (posição `s(u) = D·(1 − (1−u)^p)`, `u` = tempo normalizado), terminando exatamente no contato (distância `D` inalterada).
3. O **deslize** é o trecho final: **~0,3 m nos últimos ~0,25 s** do avanço. O tempo do avanço cresce 0,25 s (a frenagem é somada); o expoente `p` é calculado para que os últimos 0,25 s cubram 0,3 m. Alvo muito perto (`D` curto): deslize e tempo escalam proporcionalmente (deslize ≤ metade de `D`).
4. **Poeira pouca no deslize:** durante o trecho final a esteira do dash roda a 1/3 da cadência (0,165 s em vez de 0,055 s). Nada de VFX novo.
5. **Efeito colateral aceito pelo criador:** o impacto/hit do avanço acontece ~0,25 s depois do que acontecia (no fim da frenagem). O endlag do inimigo continua derivado do clipe de ataque (total do clipe inalterado); o endlag do jogador (0,38 s) não muda.
6. Distância máxima, alcance, wind-up, regras de acerto/erro, câmera e transição de batalha: **não mudam**.

## Ajuste do criador (2026-11-12)

> "limitar um pouco, remova esse endlag imenso do personagem depois que ele finaliza a animação"

Respostas: pico **24 m/s**; remover o travamento (endlag) de **jogador e inimigo**; cooldowns entre ataques ficam como estão.

7. **Teto de pico 24 m/s:** se a velocidade inicial do perfil passar de 24 m/s (avanços longos), o expoente `p` baixa até o pico ficar em 24 m/s: o tempo do avanço **não** cresce (um acerto mais tardio deixava o inimigo empatar no mesmo quadro; medido nos testes de impacto) e o deslize final de avanços longos fica um pouco maior que 0,3 m (ex.: 4,4 m → ~0,7 m).
8. **Sem endlag:** depois do avanço (com o deslize) o personagem volta a agir na hora. Jogador: `PLAYER_ENDLAG_TIME` 0,38 s → 0; a janela de 0,30 s de hitbox após um erro com alvo ao alcance (regra anterior) continua. Inimigo: o travamento "até o clipe terminar" (~1,6 s, D-1141/D-1142) deixa de existir; o clipe só toca durante o avanço. Cooldowns (0,8 s jogador, 4 s inimigo) e a pausa de impacto de 0,5 s antes da batalha não mudam.
9. A animação do jogador é esticada só sobre wind-up + avanço (+ deslize estimado), não mais sobre um endlag.

## Ambiguidades em aberto

- Se o impacto ~0,25 s mais tarde deve ser compensado no futuro (por exemplo, encurtando o cruzeiro): não pedido.
