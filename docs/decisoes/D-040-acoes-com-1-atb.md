# D-040 — Liberação de Ações com 1 ATB (Habilidades de Custo 1)

- **Área:** Combate / Menu / ATB
- **Data:** 2026-11-03
- **Estado:** Implementado
- **Frase literal do criador:**
  > "depois disso eu quero que corrija o erro do jogador nao poder realizar acoes mesmo tendo 1ATB (no caso de ter acoes que custam 1ATB no seu leque de movimentos)"

---

## 1. Contexto
Com a introdução de golpes de custo 1 ATB em D-031 (golpes de status a 1 ATB) e D-032 (Sand Attack, Rakunda, Taunt, etc.), o menu principal de batalha em `battle_scene.gd` mantinha a validação fixa `leader.can_pay(Battle.SKILL_BLOCKS)` (`SKILL_BLOCKS = 2.0`).

Dessa forma, quando o jogador possuía 1 bloco de ATB, o botão "Fight" ficava desabilitado exibindo "falta ATB", impedindo o jogador de abrir a lista de habilidades e usar qualquer ação de 1 ATB disponível no seu leque. O mesmo bloqueio ocorria na IA (`battle.gd`) e na postura de prontidão (`battle_fx.gd`).

---

## 2. Decisão
1. **Custo Mínimo Dinâmico (`Battle.min_skill_cost(c)`):** O custo mínimo para lutar passa a ser calculado dinamicamente com base nas habilidades que o combatente de fato possui em seu leque (ou `0` se tiver Burst). Se possuir golpes de custo 1 ATB, o custo mínimo é 1 ATB; caso contrário, 2 ATB.
2. **Menu Principal do Jogador (`battle_scene.gd`):** O botão "Fight" passa a ser habilitado assim que o líder tiver ATB suficiente para pagar sua habilidade mais barata (`leader.can_pay(Battle.min_skill_cost(leader))`).
3. **Detalhamento no Menu:** Se o combatente puder agir com 1 ATB, o botão exibe "1 ATB" (ou "GRÁTIS" se tiver Burst); apenas se não tiver ATB suficiente para nenhuma habilidade exibe "falta ATB".
4. **Lista de Golpes (`FIGHT`):** A lista interna já validava individualmente cada habilidade (`leader.can_pay(sk.cost)`). Ao abrir a lista com 1 ATB, apenas as habilidades de custo 1 ficam ativas, enquanto as de custo 2 ou 3 permanecem bloqueadas com indicação de "falta X ATB".
5. **Simetria Total (D-021):** A IA aliada e inimiga (`_tick_ai` em `battle.gd`) e a postura de prontidão (`battle_fx.gd`) também passam a utilizar `Battle.min_skill_cost(c)`, permitindo que qualquer combatente com golpes de 1 ATB aja assim que atingir 1 ATB.

---

## 3. Ambiguidades resolvidas
- Habilidades que custam 2 ou 3 ATB continuam exigindo seus respectivos custos integrais.
- A tecla de atalho numérico (1-9) já validava individualmente o custo de cada golpe via `_use_move()`.
