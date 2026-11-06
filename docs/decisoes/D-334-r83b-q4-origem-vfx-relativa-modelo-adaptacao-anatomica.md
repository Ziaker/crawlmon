# D-334 — Rodada 83B Q4 (4A): origem visual do Move relativa ao modelo, referências e adaptação anatômica genérica

- **Data:** 2026-11-06.
- **Área:** Fichas de Moves / especificação visual / anatomia / VFX.
- **Origem:** decisão expressa da Rodada 83B.
- **Estado:** requisitos da ficha visual aprovados; nenhuma implementação ou arte concreta adicional aprovada.

## Declaração literal do criador

> 4A — Especificar na ficha do Move a origem visual relativa ao modelo, os pontos de referência necessários e adaptações para anatomias diferentes, sem depender de uma espécie específica.

## Regra aprovada

- A **ficha visual de cada Move** deve **especificar a origem dos efeitos relativamente ao modelo do atacante**, os **pontos de referência necessários** e as **adaptações para anatomias diferentes** para que a execução não dependa da existência de mãos, membros, esqueleto ou proporções de uma espécie particular.
- **Preservar integralmente D-235/AGENTS.md §7:** os efeitos devem funcionar com qualquer atacante e alvo, ambos os lados do campo e diferentes tamanhos/formatos corporais. Posicionamento e orientação necessários são derivados das **referências e dimensões reais do atacante/alvo**, não de nomes de espécies, personagens, times, câmera fixa ou coordenadas absolutas de protótipo.
- **Exemplo ilustrativo, sem aprovar novas animações:** Fire Bullet já possui uma mão de fogo visual que surge independentemente da anatomia do usuário. Sua ficha poderá especificar a referência relativa ao corpo e como posicionar esse efeito quando o atacante não tiver mãos. **Não escolher automaticamente** ponto exato, distância, escala, trajetória, fallback anatômico ou animação de qualquer espécie.
- Preservar **D-248**: a descrição visual **fora do combate** segue as fases de preparação, movimento/emissão, impacto e dissipação, quando aplicáveis; incluir as referências/adaptações na fase pertinente, sem transformar a tooltip em combate em descrição VFX.
- Preservar **D-333**: se houver variantes visuais realmente distintas dentro do Move, documentar apenas as diferenças nos blocos das variantes, mantendo referências comuns reutilizáveis.
- Não modificar o comportamento ou visual já aprovado de Fire Bullet, Splitter Flames, Bubble Shield ou outros Moves; esta decisão acrescenta **campos/obrigações de especificação**, não cria novas artes.

## Pendências e limites

- Não foram aprovados nomes de âncoras, algoritmo de detecção anatômica, hierarquia de fallbacks, categorias corporais obrigatórias, proporções, parâmetros numéricos, recursos/efeitos novos, estrutura técnica da ficha nem alterações de câmera.
- **Nenhum código, malha, rig, Move operacional, teste, protótipo, VFX, cena, asset ou HUD foi modificado.** Somente documentação das regras de ficha.
