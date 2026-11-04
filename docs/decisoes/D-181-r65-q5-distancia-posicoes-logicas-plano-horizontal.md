# D-181 — Rodada 65 Q5 (5A): proximidade horizontal entre posições lógicas dos combatentes

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / referências geométricas.
- **Origem:** escolha expressa do criador, Rodada 65.
- **Estado:** regra aprovada; não implementada.

## Declaração literal do criador

> 5A — Medir entre as posições lógicas de referência dos combatentes projetadas no plano horizontal.

## Regra aprovada

- Para o **redirecionamento automático durante WINDUP** da D-108, medir proximidade entre **as posições lógicas de referência dos combatentes**, **projetadas no plano horizontal da arena** (D-176).
- **Ignorar a diferença de altura** e não substituir a posição lógica por centros de colisão ou distâncias até superfícies de colisão por presunção.
- Comparar cada distância com a **menor distância horizontal dos inimigos vivos elegíveis**; incluir candidatos na **tolerância de até 0,01 unidade da arena, inclusive** (D-171), e, quando houver empate, efetuar **sorteio reproduzível** entre eles (D-166).
- **Exemplo hipotético:** as posições lógicas de dois alvos projetadas no plano horizontal ficam a 4,000 e 4,006 unidades do atacante; embora a altura ou tamanho de colisão varie, ambos entram no sorteio pela diferença 0,006, sem mudar os pontos lógicos de referência escolhidos.
- Esta decisão não altera colisões, hitboxes, alcance físico dos Moves, movimento durante TRAVEL ou projéteis. Preservar D-155 (recálculo uma vez por cada troca efetiva ainda no WINDUP).

## Pendências e escopo

- É preciso verificar a propriedade que representa as **posições lógicas** no código e a convenção de eixos do plano horizontal do Godot. A escolha não prescreve nova representação nem nova arquitetura.
- Seed/algoritmo e consumo da aleatoriedade reproduzível seguem pendentes; apenas documentação, sem código ou testes.
