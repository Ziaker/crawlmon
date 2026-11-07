# D-388 — R92-Q4 (4C): grupos próximos podem perseguir no overworld após alerta

- **Data:** 2026-11-07.
- **Área:** Exploração / patrulhas / grupos inimigos.
- **Estado:** reação entre grupos aprovada; critérios e implementação pendentes.

## Declaração literal do criador

> 4C — Grupos próximos podem ser alertados e passar a perseguir o jogador no overworld, mas não entram automaticamente no mesmo combate.

## Regra aprovada

- **Grupos inimigos próximos podem ser alertados e passar a perseguir o jogador no overworld**. O alerta **não faz outros grupos entrarem automaticamente no mesmo encontro de combate 3D**.
- Preservar **D-321**: grupos soltos com no máximo três inimigos, e a estrutura de combates entre equipes de até três integrantes. Preservar **D-205/GDD R38-Q1** (detecção principalmente por proximidade), **D-383** (furtividade ambiental), **GDD R9-Q3** (perseguição) e **GDD R37-Q1** (combate por contato).
- **Exemplo hipotético:** grupo A detecta o jogador e alerta grupo B, que passa a perseguir no mapa; B não se incorpora automaticamente ao combate iniciado contra A. Nenhuma patrulha real foi criada.

## Pendências e limites

- Não definidos raio, velocidade, propagação/cadeias de alertas, duração, condições de fuga e perda de alvo, regras de detecção e composição de patrulhas. Não criar reforços no meio de batalhas.
- **Somente documentação:** nenhum código, IA, mapa, personagem, cena, teste, asset ou VFX alterado.
