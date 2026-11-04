# D-179 — Rodada 65 Q3 (3A): preservar mediana fracionária exata, sem arredondamento

- **Data:** 2026-11-03.
- **Área:** AGI / precisão da referência de trajetos.
- **Origem:** escolha expressa do criador, Rodada 65.
- **Estado:** regra de cálculo aprovada; mediana real pendente e não implementada.

## Declaração literal do criador

> 3A — Preservar o valor fracionário exato da mediana, sem arredondamento.

## Regra aprovada

- Ao calcular a mediana de AGI-base das espécies elegíveis, **preservar exatamente o resultado fracionário**, **sem arredondar, truncar, arredondar para cima ou converter automaticamente em inteiro**.
- Mantém D-173: em amostra de quantidade par, calcular a **média aritmética dos dois valores centrais** após a ordenação; **o resultado pode ser decimal**.
- **Exemplo ilustrativo:** valores centrais hipotéticos **42** e **43** → mediana **42,5**, usada e apresentada como **42,5**, não como 42 ou 43. **42,5 não é referência aprovada do Crawlmon.**
- Não transformar a referência em uma AGI permanente de personagem: trata-se de parâmetro para a fórmula de duração de trajetos (D-136/D-162).
- O resultado numérico efetivo depende da amostra integral verificada (D-178) e deverá ser **validado pelo criador antes de implementar** (D-162).

## Pendências e escopo

- A representação técnica da precisão computacional e sua verificação em código não foram escolhidas nesta rodada; nenhuma biblioteca, formato ou arquitetura é imposta.
- Somente documentação; nenhuma regra de arredondamento de outras mecânicas alterada.
