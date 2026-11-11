# D-1127 — Speedlines menores e presas só no início, dash 30% menor e E fora do ataque

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / VFX / ataque / input
- **Origem:** ajustes pedidos pelo criador sobre o tamanho das speedlines, a distância do dash e a tecla de ataque.
- **Status:** **implementado e testado** (66/66 controlador; 100/100 VFX; ponta a ponta PASS; E/Z do lab verificado manualmente).
- **Nota D-1135 (2026-11-10):** os valores de distância desta decisão foram substituídos por **2,0 m para jogador e inimigo**; o Z do jogador ficou **sem wind-up**. O resto (speedlines, E fora do ataque) continua.
- **Relacionadas:** D-1100 (input E/Z e alcance), D-1119 (speedlines), D-1120 (dash 0,18 s), D-1125 (inimigos visíveis), D-235.

## O que o criador disse (literal)

> esses speedlines estão grande demais, largos demais, não levam em conta o tamanho do personagem, eram pra estar junto do personagem naverdade, estava certo eles estarem presos, mas é pra estarem presos só nos primeiros milesimos do dash
>
> 2 - reduza a distância do movimento do dash em 30%
>
> e também remova o E como botão de ataque

## Decisão

1. As speedlines são **dimensionadas pelo corpo real do ator** (altura/raio medidos): comprimento, largura e raio em torno do corpo encolhem proporcionalmente. Elas ficam **junto do personagem**, não como faixas enormes atravessando a tela.
2. As linhas ficam **presas ao ator apenas nos primeiros milésimos do dash** (primeiros **0,04 s**). Depois disso, ficam no **espaço do mundo** e o ator continua; as linhas já nascidas não são mais arrastadas.
3. A **distância do movimento do dash** cai **30%**: jogador de 3,5 m para **2,45 m**; inimigo de 3,4 m para **2,38 m**. A duração continua **até 0,18 s** (D-1120) e o impacto de 0,5 s não muda. O alcance de aquisição de 4,5 m (D-1100) **não muda**; um alvo longe demais pode resultar em erro (sem batalha), como a regra de erro já prevê.
4. O ataque passa a ser **somente Z**. **E não ataca mais**. Com um inimigo no alcance, E não inicia ataque (o inimigo continua dono do prompt `[Z] ATTACK`, D-1100); sem inimigo, E continua falando/interagindo com NPCs/portas como antes.
5. D-235: o tamanho vem do corpo real do ator, não de nome/time/lado; o attach/detach usa a posição real do ator; o mesmo vale para qualquer ator, lado e tamanho de alvo.
6. D-308 não se aplica (overworld). D-1119 e D-1120 são atualizadas; a parte de E/Z da D-1100 fica substituída no ataque.

## Implementação

- `overworld_dash_speedlines.gd`: comprimento/largura/raio derivados de `_body_height`/`_body_radius`; `set_node_origin()` para o attach; o nó fica no mundo depois do attach.
- `overworld_dash_vfx.gd`: `ATTACH_TIME = 0,04 s`; enquanto `_elapsed <= ATTACH_TIME`, o nó das speedlines acompanha o ator; depois, não.
- `overworld_attack_controller.gd`: `PLAYER_DASH_MAX = 2.45`; `ENEMY_DASH_MAX = 2.38`.
- `murky_forest_3d_lab.gd`: o ataque só chama `try_interact()` quando **Z** foi o just-pressed; E não chama o ataque.
- `overworld_prompt.gd`: o E era desenhado fixo em todo prompt; o ataque chama `show_prompt("", "ATTACK", false)` e mostra só `[Z] ATTACK`; o talk mantém o E.
- Testes: **66/66** controlador (alvo grande/atrás da D-235 ajustado para 3,2 m), **100/100** VFX (overdraw p99 4,00/3,81) e ponta a ponta PASS; a demo foi regravada em slow motion. O input E/Z do lab não é coberto por teste headless (verificado no lab).

## Estado

Implementado e testado; demo regravada (`overworld_showcase_demo.mp4`); pendente aprovação visual. Sem commit e sem push.

