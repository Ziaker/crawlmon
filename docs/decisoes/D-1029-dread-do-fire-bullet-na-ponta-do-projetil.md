# D-1029 — Dread do Fire Bullet na ponta do projétil

- **Data:** 2026-11-09.

## Frase literal do criador

> vi que o efeito de dread que só deve ser usado para moves mid range e moves melee está surgindo no personagem, ele encaixa com o efeito visual do move, então abro uma exceção para o fire bullet
>
> faça com que o efeito e dread do preludio do ataque apareca na verdade no projétil, na ponta dele, seguindo sua mesma velocidade ao invés da mão do personagem, faça esta correção

## Decisão

1. **Fire Bullet é a única exceção** à regra de não mostrar Dread em moves que não sejam corpo a corpo (D-1016 do Drain Spear / D-1022). O aviso Dread continua aparecendo no Fire Bullet.
2. Na janela de Evade do Fire Bullet (os últimos 0,25 s do TRAVEL, quando o projétil já está no ar), o Dread aparece **na ponta do projétil**, e não no corpo, na mão ou na arma do atacante.
3. A posição acompanha a ponta do projétil **quadro a quadro**, percorrendo o mesmo trajeto e a mesma velocidade dele. Não há posição fixa nem atraso/antecipação extra.
4. O tamanho, o brilho, o anel e a estrela continuam os do Dread atual (D-986, D-987, D-989); só a âncora muda no Fire Bullet.
5. Vale para qualquer atacante, time, lado e câmera (D-235). A ponta vem do próprio Move/projétil, nunca de nome de personagem, espécie ou índice fixo.

## Ambiguidades

- "Seguindo sua mesma velocidade" foi interpretado como o efeito acompanhar a ponta do projétil a cada quadro, sem suavização que o deixe para trás.
- Não foi pedido mudar tamanho, cor ou duração do Dread; esses valores ficam como estão.
- O criador citou "mid range e moves melee", mas D-1016 (Drain Spear) registra que mid-range **não** tem Dread. A exceção explícita desta decisão é só o Fire Bullet; as demais regras permanecem como estão. Se houver conflito com outra decisão, preservar as duas e perguntar.

## Estado

**Implementado para revisão em 2026-11-09.** `FireMoveVfx.bullet_tip()` entrega a ponta real do projétil; `FxEvadeFlash` usa essa ponta somente quando o Move é `fire_bullet` e mantém o Dread de corpo/arma para os demais. O timing segue D-1039: na câmera do jogo, o Dread aparece nos quadros 51–53, some no 54 e o clarão/impacto só vem nos quadros 59–60. Evidência principal (POV do jogador, `--cam=0`): `test_captures/vfx_tools/fire_bullet_player_pov.mp4`; complementares: `test_captures/vfx_tools/fire_bullet_dread_tip_final.mp4` e `test_captures/vfx_tools/fire_bullet_dread_gamecam.mp4`. Regressão: `test_captures/vfx_tools/tackle_dread_regression_long.mp4` mantém o Dread no corpo/mão no Tackle espelhado. Não verificado: Fire Bullet instantâneo de contra-ataque, alvos de tamanhos diferentes, DQT espelhado (timeout de 180 s) e aprovação visual do criador. Nada commitado.
