# D-940 — Inimigos alinhados para a esquerda, 6 entre eles, e chão de largura 60 (todas as batalhas)

> **Renumerada em 2026-11-06:** D-338 → D-940. O ID D-338 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-05
- **Área:** Combate / Visual / Arena
- **Origem:** Conversa

## O que o criador disse (literal)

> "Para os inimigos eles estão dentro das coisas no cenário ao invés de estarem alinhados, ao invés de alinhar pra direita (na visao do jogador pokémon) alinhe pra esquerda e os separe um pouco"

Respostas às perguntas de esclarecimento:

- Onde vale: **"Todas as batalhas"**.
- Posições: **"x = −8 / −14 / −20 + chão maior"**.
- Linha: **"Manter o escalonado"**.

## Decisão

1. Em todas as batalhas, o inimigo de índice i fica em `x = −8 − 6·i` (antes `8 + 5·i`), ou seja, a linha vai para a **esquerda** na visão da câmera dos aliados, com 6 unidades entre eles (antes 5).
2. O escalonamento em profundidade continua: `z = −TEAM_DISTANCE − 2·i`.
3. O chão fica mais largo para o terceiro inimigo (x=−20) não entrar no pilar: largura 44 → **60** (`HALF_W` 22 → 30), com os pilares acompanhando a borda (x=±27). O valor 60 foi a largura que o criador já tinha escolhido na D-938 (lá, só para a batalha DQT); aqui vale para todas porque o alinhamento vale para todas.
4. Os inimigos de teste do depurador (tecla H) usam a mesma fórmula de slot.

## Ambiguidades em aberto

- O criador disse "chão maior" sem medida; usada a largura 60 que ele escolheu antes (D-938). Confirmar.
- A verificação de enquadramento da D-015 foi feita com os slots antigos (x=13 e x=18); precisa ser refeita com os novos.

## Estado no código

`scripts/combat/battle_scene.gd` (slots de inimigo) e `scripts/combat/battle_arena.gd` (`HALF_W`).

## Correção (mesma data)

O criador reprovou a primeira aplicação (x=−8/−14/−20 e chão 60):

> "Vc arruinou TUDO"
> "O PROBLEMA NÃO É SÓ A CAMERA VC JOGOU OS BONECOS ORA ESQUERDA EU SÓ MANDEI ALINHAR ELES PRA ESQUERDA NÃO JOGAR PRA TRÁS NÃO MOVER TODOS"

Regra vigente: **o primeiro inimigo fica onde estava (x=8, z=−30); os seguintes vão para a esquerda dele em vez da direita**, 6 entre eles, com o escalonamento de sempre: `x = 8 − 6·i`, `z = −30 − 2·i` (x=8/2/−4). O chão **volta a 44** (`HALF_W` = 22), porque só tinha sido alargado para o x=−20. Os itens 1 e 3 da decisão acima ficam substituídos por esta correção.

## Ajuste (mesma data)

> "Separe um pouco eles, um do outro sem exagerar"

Espaçamento entre inimigos: 6 → **8** (`x = 8 − 8·i`: x=8/0/−8). O resto não muda.

## Ajuste 2 (mesma data)

> "Os separe ainda mais um pouco e corrija o problema de suas barras de vida estarem sobrepondo uma a outra"

Espaçamento entre inimigos: 8 → **10** (`x = 8 − 10·i`: x=8/−2/−12). As barras de vida flutuantes dos inimigos que se sobreporiam são empurradas para os lados, cada uma metade da sobreposição, e continuam sobre o próprio inimigo (`battle_hud.gd`, `_separate_tags`). Vale para todas as batalhas.
