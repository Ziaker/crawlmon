# D-164 — Rodada 62 Q3 (3B, versão prevalente): AGI mínima 1 no cálculo de regeneração ATB

- Data: 2026-11-03.
- Origem: resposta expressa do criador e confirmação de prevalência desta versão da Rodada 62.
- Estado: regra aprovada; não implementada.

## Declaração literal

> 3B — Usar AGI mínima de 1 exclusivamente no cálculo de regeneração de ATB.

## Regra vigente

- Na fórmula de **regeneração natural de ATB** (D-163), usar `AGI_para_ATB = max(1, AGI_efetiva)`, **apenas durante o cálculo**.
- AGI efetiva zero ou negativa usa valor numérico 1 nessa operação, **sem mudar a AGI do Pokémon**, os atributos persistentes nem os buffs/debuffs.
- Exemplo ilustrativo: AGI efetiva −5 ou 0 usa 1 para cálculo do ATB; AGI efetiva 3 usa 3. O ritmo exato depende da referência ATB ainda não fixada.
- **D-140** originalmente concedeu piso AGI 1 **somente para o cálculo do trajeto**. A nova decisão autoriza esse piso **também no cálculo de ATB**, sem alterar retroativamente a declaração original da D-140.
- O piso não revoga suspensão/pausa de ATB e não cria mínimo geral de AGI para outras mecânicas.
- A D-159 da outra versão da Rodada 62 (ordem de eventos) fica conservada como **histórico não ratificado pela escolha vigente 3B**. Preservar separadamente decisões anteriores sobre simultaneidade.

## Escopo

- Só documentação; nenhum código, teste, cena ou recurso alterado. Referência numérica e arredondamento de ATB seguem pendentes.
