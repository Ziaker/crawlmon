# D-171 — Rodada 63 Q5 (5B): tolerância de 0,01 unidade da arena para empate de distância

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / desempate de proximidade.
- **Origem:** resposta expressa do criador na Rodada 63.
- **Estado:** regra quantitativa aprovada; sem implementação.

## Declaração literal do criador

> 5B — Considerar empate quando a diferença de distâncias for de até 0,01 unidade da arena.

## Regra aprovada

- Para a escolha de alvo no redirecionamento automático durante **WINDUP** (D-108), considerar **empatados em proximidade** os candidatos vivos cuja **diferença de distância em relação ao candidato mais próximo seja de até 0,01 unidade da arena**, **incluindo exatamente o limiar**.
- Entre os candidatos considerados empatados como **mais próximos**, realizar o **sorteio reproduzível** aprovado em D-166. A tolerância **não** transforma todo inimigo vivo em candidato: só os situados até **0,01 unidade** além da menor distância entram no empate.
- **Exemplo ilustrativo:** Abra a 4,000 unidades e Pancham a 4,006 unidades do atacante, sem candidato mais próximo: diferença 0,006 → **ambos entram no sorteio**; um terceiro a 4,020 unidades não entra, pois sua diferença para a mínima é 0,020.
- A escolha estabelece **somente o valor da tolerância**; não decide por suposição a métrica geométrica (posição de referência, centro do corpo, projeção no plano ou distância 3D) nem o algoritmo/seed de RNG.
- Preservar D-155: cada troca efetiva de alvo ainda em WINDUP autoriza um único recálculo da duração; D-113 preserva ausência de retarget após iniciar investida.

## Limites e escopo

- A unidade citada é a **unidade espacial da arena**; não converter automaticamente para metros reais sem fonte aprovada. A definição técnica da distância e o desempate por sorteio reproduzível ainda dependem de detalhes futuros.
- Somente documentação, sem código, testes ou mudanças de mecânicas adjacentes.

## Complemento posterior — Rodada 64 / D-176 (2026-11-03)

**D-176 (R64-Q5B)** define que a distância para escolher o adversário mais próximo durante retarget no WINDUP é **horizontal, medida no plano da arena, ignorando diferenças de altura**. Preservar a tolerância **inclusiva de 0,01 unidade da arena** desta D-171 e o sorteio reproduzível entre empatados (D-166). Ponto geométrico de referência e convenção de eixos da cena não foram escolhidos; não supor implementações de RNG nem converter unidade para metros reais. Somente documentação.
