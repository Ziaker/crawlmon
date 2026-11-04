# D-182 — Rodada 66 Q1 (1A): uma observação por valor distinto de AGI-base em cada espécie

- **Data:** 2026-11-03.
- **Área:** Atributos / AGI / amostragem de espécies e formas.
- **Origem:** aprovação expressa do criador, Rodada 66.
- **Estado:** regra aprovada e documentada; sem cálculo da mediana ou implementação.

## Declaração literal do criador

> 1A — Contar somente uma observação por valor distinto de AGI-base dentro de cada espécie, sem duplicar formas com valor igual.

## Regra aprovada

- Para construir a amostra da mediana da **AGI-base no nível 50** (D-162/D-168/D-172), contabilizar **no máximo uma observação de cada valor distinto de AGI-base dentro de cada espécie**.
- Formas alternativas só são candidatas à amostra se puderem ser **controladas diretamente pelo jogador** e possuírem **AGI-base própria distinta**, conforme D-177; duas formas da **mesma espécie** com AGI-base igual no nível 50 **não duplicam o mesmo valor** na amostra. Preservar a contribuição da forma-base quando elegível.
- **O agrupamento é por espécie**: o mesmo valor de AGI-base em **espécies distintas não deve ser deduplicado globalmente**, pois a decisão diz “dentro de cada espécie”.
- **Exemplo fictício:** espécie A tem forma-base elegível com AGI 40, forma Alfa controlável com AGI própria 60 e forma Beta controlável com AGI própria 60: para essa espécie, as observações são **40 e 60**; a segunda ocorrência de 60 não é contabilizada. Outra espécie B com AGI 60 mantém a sua própria observação.
- A amostra também inclui espécies oficialmente documentadas como controláveis mesmo não implementadas (D-174), com dados verificáveis no nível 50 (D-178). O valor da mediana final continua sujeito à validação prévia do criador (D-162).

## Pendências e escopo

- Confirmar o mapeamento real de espécies e formas e seus valores de AGI-base no nível 50. Não aprovar espécies, fórmulas ou AGIs por exemplo.
- Apenas documentação; nenhum dado de espécie, código ou teste alterado.
