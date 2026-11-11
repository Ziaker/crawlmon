# D-1115 — Impacto do Tackle de 0,5 s após o contato

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / ataque / VFX
- **Origem:** pedido do criador sobre o momento do contato.
- **Status:** **implementado e testado** (66/66 controlador; Gible no ponta a ponta); demo em slow motion regravada.

## O que o criador disse (literal)

> deve ter um meio segundo de impacto apos o contato use o vfx de impacto do tackle pra isso

## Decisão

1. Quando o avanço conecta, tocar o **VFX de impacto do Tackle** no ponto de contato, na direção atacante→alvo.
2. A transição de combate espera **0,5 s** enquanto o impacto roda; só depois ela abre.
3. Vale para o jogador e para o inimigo; no empate, um impacto no ponto de encontro.
4. O dash termina no contato; a janela de 0,5 s é do impacto, sem congelamento artificial do relógio.
5. D-235: o impacto usa o ponto/direção reais, não o lado. O VFX do Tackle é reutilizado como está; D-308 não se aplica ao overworld (D-1100 item 15).

## Clarificação do criador (2026-11-11)

O criador mediu, no lab real:

> Medi: do golpe até o pedido de transição passam 0,91 s no caso azul e 1,81 s no vermelho, não 0,5 s.

Regra adotada a partir disso:

6. A espera de 0,5 s conta em **tempo real**: o delta é dividido por `Engine.time_scale`, então a câmera lenta do impacto (0,075× por 0,45 s) ocorre **dentro** dos 0,5 s.
7. A transição **não espera o endlag** da animação de ataque do inimigo; a trinca corta a animação.
8. O caso branco (contato/empate) continua **direto**, sem golpe para esperar.
9. Medição windowed em 2026-11-11: azul **501 ms**, vermelho **492 ms** (impacto → `battle_requested`).

## Implementação

- `OverworldAttackController`: sinal `impact_requested` + `IMPACT_HOLD = 0,5 s` antes de `battle_requested`; ponto/direção do contato.
- `murky_forest_3d_lab.gd`: um `BattleFx` autônomo recebe `MoveVfxRegistry.impact(host, "tackle", pos, false, dir)`; o efeito é escalado pela distância da câmera do lab (`BattleFx.VFX_REF_DISTANCE`) e o host é liberado depois do efeito.
- Testes: **66/66** controlador; o host do impacto é criado, a batalha não é emitida imediatamente e vem 0,5 s depois; Gible no ponta a ponta.
- Vídeos: `overworld_attack_player/enemy/contact` e o combinado `overworld_attack_3cases` regravados em **60 fps**; o impacto do jogador aparece; no caso inimigo o impacto é no jogador e a câmera do lab cobre parte dele. O VFX do dash limpa no contato (D-1120), então o impacto roda sozinho na janela de 0,5 s.

## Estado

Implementado e testado; vídeos regravados; pendente aprovação visual. Sem commit e sem push.
