# D-381 — Rodada 91 Q1 (1B): Moves podem modificar ou destruir cenário sob interações expressamente definidas

- **Data:** 2026-11-06.
- **Área:** Combate / arena 3D / ambiente interativo / Moves.
- **Origem:** aprovação expressa do criador na Rodada 91.
- **Estado:** permissão condicionada de gameplay aprovada; interações concretas e implementação pendentes.

## Declaração literal do criador

> 1B — Moves podem modificar ou destruir elementos da arena quando o próprio Move e o cenário possuírem interações expressamente definidas.

## Regra aprovada

- **Moves podem modificar ou destruir elementos da arena somente quando tanto o Move quanto o cenário possuírem interações expressamente definidas** que permitam aquele comportamento. A definição unilateral apenas no Move ou apenas no cenário não basta para presumir a interação.
- Preservar **D-377**: arenas podem possuir obstáculos, zonas perigosas e características de terreno que alteram posicionamento e combate. A D-381 amplia as **possibilidades de interação**, sem impor destruição generalizada ou obrigatória.
- **Não** definir um sistema universal de destruição por elemento, classe de dano, intensidade ou nome do Move: as interações precisam de declarações específicas compatíveis em ambas as partes.
- Preservar **D-235/AGENTS.md §7**: a interação declarada de um Move deve funcionar com **qualquer atacante, alvo, facção e posição**, sem especializar por personagem/time/lado. Preservar D-361/D-373/D-374/D-953/D-954 quanto a efeitos e condições declarativas sem presumir novos Resources ou fases técnicas.
- **Exemplo hipotético, não Move/cenário aprovado:** um pilar que expressamente permita destruição por uma interação declarada em determinado Move pode deixar de bloquear uma rota após o impacto. Sem ambas as declarações, nenhum comportamento destrutivo deve ser inferido.

## Pendências e limites

- Não estão definidos quais Moves/cenários interagem, atributos de objetos, durabilidade, persistência do terreno após o combate, restauração, efeitos de obstáculos em projéteis/AoE, dano ambiental, física, navegação, VFX, IA ou interface.
- Esta decisão não aprova destruição por qualquer Move existente, nem permite alterar o overworld automaticamente por causa do resultado visual da arena.
- **Somente documentação:** nenhum código, Move, Resource, ficha operacional, arena, mapa, cena, teste, IA, asset ou VFX alterado.
