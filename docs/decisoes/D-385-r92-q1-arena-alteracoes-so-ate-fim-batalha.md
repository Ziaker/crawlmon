# D-385 — R92-Q1 (1A): alterações de arena encerram-se com a batalha

- **Data:** 2026-11-07.
- **Área:** Combate / arena e overworld.
- **Estado:** aprovada como requisito; não implementada nesta atualização.

## Declaração literal do criador

> 1A — Alterações e destruição de elementos da arena duram apenas até o encerramento daquela batalha; os ambientes de exploração permanecem inalterados.

## Regra aprovada

- Alterações e destruições de elementos da arena resultantes do combate **duram somente até o encerramento daquela batalha**; **não são persistidas nem transferidas para o ambiente de exploração**.
- **D-381** continua exigindo interações explicitamente definidas no **Move e no cenário**. **D-377** preserva a possibilidade de arenas com obstáculos e zonas perigosas; **D-235** preserva a independência de Moves em relação a personagem, facção e lado.
- **Exemplo ilustrativo:** um Move com interação válida destrói um obstáculo da arena; este não altera os elementos do overworld quando a batalha termina. Não foram homologados obstáculos ou Moves reais.

## Pendências e limites

- Não foram definidos objetos destrutíveis reais, colisões, regeneração visual, durabilidade, relação com projéteis, efeitos ambientais e VFX. A decisão não impede alterações **independentes** do overworld por outras mecânicas expressamente aprovadas.
- **Somente documentação:** nenhum código, Move, Resource, mapa, arena, VFX, teste ou asset alterado.
