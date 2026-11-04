# D-168 — Rodada 63 Q2 (2A): usar AGI-base em nível de referência comum, sem modificadores

- **Data:** 2026-11-03.
- **Área:** AGI / calibração / mediana entre espécies.
- **Origem:** resposta expressa do criador na Rodada 63.
- **Estado:** regra de seleção de dados aprovada; **nível de referência ainda não escolhido**; sem implementação.

## Declaração literal do criador

> 2A — Usar AGI-base de cada espécie em um nível de referência comum, sem Nature, variação individual ou buffs; nível ainda a definir.

## Regra aprovada

- Para calcular a **mediana de AGI** que definirá a referência de trajeto (D-162/D-167), considerar a **AGI-base de cada espécie elegível no mesmo nível de referência**, sem influências de **Nature, variação individual ou buffs**.
- A **escolha do nível comum permanece expressamente pendente**. Não assumir nível 1, 50, máximo, nem outro valor; não calcular a mediana com espécies em níveis diferentes.
- Os modificadores excluídos **apenas da amostra estatística de referência** continuam regidos por suas decisões próprias durante o combate e a progressão; esta decisão **não os remove do jogo**.
- **Exemplo ilustrativo:** espécie A teria AGI-base 35 no nível comum, mas um indivíduo com Nature +3 e variação −2 teria AGI efetiva diferente; **a contribuição da espécie para a mediana usa o 35**, não o valor individual. Estes valores são hipotéticos, não atributos reais do projeto.
- A referência numérica resultante **deve ser apresentada ao criador para validação antes de implementar** (D-162); a metodologia não aprova antecipadamente seu resultado.

## Pendências e escopo

- Definir o **nível de referência comum**, a fonte e escala da AGI-base por espécie nesse nível, a lista exata de espécies controláveis, e o tratamento de variantes e quantidade par de espécies.
- Apenas documentação; nenhum código, dado ou teste alterado.

## Complemento posterior — Rodada 64 / D-172 e D-173 (2026-11-03)

**D-172 (R64-Q1C)** define expressamente o **nível 50** como nível comum da comparação da **AGI-base**. A exclusão de Nature, variação individual e buffs da amostra desta D-168 continua válida. **D-173 (R64-Q2A)** escolhe **média aritmética dos dois valores centrais** para a mediana com número par de espécies. Nenhuma amostra real, arredondamento ou número de referência foi aprovado; é obrigatória a validação do resultado antes de implementar (D-162). Nenhum código alterado.
