# D-176 — Rodada 64 Q5 (5B): proximidade medida no plano horizontal da arena

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / geometria.
- **Origem:** escolha expressa do criador na Rodada 64.
- **Estado:** regra aprovada e registrada; sem implementação.

## Declaração literal do criador

> 5B — Calcular a distância horizontal no plano da arena, desconsiderando diferença de altura.

## Regra aprovada

- Para a seleção de **inimigo vivo mais próximo durante retarget no WINDUP** (D-108), calcular a proximidade pela **distância horizontal no plano da arena**, **ignorando a diferença de altura** entre atacante e candidatos.
- Aplicar a **tolerância de 0,01 unidade da arena, inclusiva**, relativa ao menor valor de distância horizontal (D-171). Se vários alvos vivos estiverem dentro da faixa de empate, manter **sorteio reproduzível entre eles** (D-166), não desempate fixo por ID da histórica D-158.
- **Exemplo ilustrativo:** um alvo está deslocado cinco unidades horizontalmente e três unidades acima do atacante; a distância considerada para seleção é **5 unidades horizontais**, não aproximadamente **5,83** unidades em 3D. Isso não declara a escala física da arena em metros.
- Esta escolha **não determina** se a origem geométrica deve ser centro, pivô, posição dos pés ou outro ponto; tampouco define quais eixos do motor representam o plano horizontal na cena atual. Esses detalhes requerem verificação técnica, não suposição.
- Não alterar alcance ou comportamento de ataques, detecção de colisões, posicionamento tático, deslocamento vertical, projéteis ou ondas por analogia; apenas a **métrica de proximidade do retarget especificado**.

## Pendências e escopo

- Estabelecer pontos de referência por combatente e inspecionar o plano horizontal efetivo no Godot, além de algoritmo/seed e ordem dos sorteios reproduzíveis.
- Somente documentação; nenhum código, cena, teste ou VFX alterado.

## Complemento posterior — Rodada 65 / D-181 (2026-11-03)

**D-181 (R65-Q5A)** fixa o ponto de referência de proximidade: medir **entre posições lógicas de referência dos combatentes projetadas no plano horizontal**, **não** entre centros ou superfícies de colisão. Permanecem a tolerância de empate **até 0,01 unidade da arena, inclusive** (D-171) e o sorteio reproduzível entre empatados (D-166). Os eixos e propriedades concretas da posição lógica precisam ser conferidos no código, sem alterar arquitetura por presunção. Histórico preservado; sem código.
