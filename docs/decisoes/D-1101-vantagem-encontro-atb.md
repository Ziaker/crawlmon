# D-1101 — Vantagem de encontro no ATB

- **Data:** 2026-11-10
- **Área:** Combate / ATB / encontros
- **Origem:** resposta do criador sobre o efeito das cores azul/vermelho.
- **Status:** **implementada e testada** (24/24 + ponta a ponta 4/2 e 2/4); retorno ao lab validado.

## O que o criador disse (literal)

> esqueci de mencionar, quem ataca primeiro e acerta com sucesso, ganha 1 atb extra e o perdedor perde 1 atb (no caso começa com 4 e o outro começa com 2)

## Decisão

1. Quem ataca primeiro no overworld **e acerta** ganha **+1 bloco de ATB** no início da batalha. O ajuste vale para **todos os combatentes do lado** (party inteira ou todos os inimigos), não só para o líder.
2. O outro lado perde **−1 bloco de ATB** em **todos** os seus combatentes.
3. Com a base atual do código (`START_ATB := 3.0` em `scripts/combat/battle.gd`), o lado vencedor começa com **4** e o perdedor com **2**.
4. Vale para o lado que venceu o avanço: jogador primeiro (azul) ou inimigo primeiro (vermelho).
5. Contato normal ou empate (branco) não altera o ATB: os dois lados começam com **3**.
6. Se o ataque **erra**, a batalha **não inicia**; logo, não há vantagem.
7. A regra é sobre o **ATB normal** (0..5), não sobre o campo `extra` de blocos acima de 5.

## Notas de implementação

- `Battle.start()` aplica `START_ATB = 3.0` a `party + enemies`; a vantagem entra **depois** dessa chamada, em `battle_scene.gd` (linha 181).
- O ajuste é aplicado a **todos** os combatentes do lado vencedor (+1) e do lado perdedor (−1), com clamp em 0..5.
- O campo `extra` (blocos acima de 5) **não** é usado por esta regra.

## Notas técnicas

- `Battle.start()` (`scripts/combat/battle.gd`) aplica `START_ATB = 3.0` a `party + enemies`; é o ponto onde a vantagem precisa ser aplicada.
- O campo `extra` existe para blocos além dos 5 normais e não deve ser usado para esta regra.

## Estado

Implementada e testada (24/24 regras e ponta a ponta 4/2 e 2/4). Nenhum commit e nenhum push.
