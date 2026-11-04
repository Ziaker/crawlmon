# D-177 — Rodada 65 Q1 (1C): formas alternativas só contam separadamente com AGI-base própria distinta

- **Data:** 2026-11-03.
- **Área:** AGI / composição da amostra de espécies e formas.
- **Origem:** escolha expressa do criador, Rodada 65.
- **Estado:** decisão aprovada e registrada; nenhuma mediana calculada, sem implementação.

## Declaração literal do criador

> 1C — Contar formas alternativas separadamente somente quando forem controláveis e possuírem AGI-base própria distinta.

## Regra aprovada

- Na amostra da mediana de AGI para os trajetos (D-162/D-167/D-168/D-172/D-174), **contar uma forma alternativa como observação separada somente se ela puder ser controlada diretamente pelo jogador e possuir AGI-base própria distinta**.
- A **AGI-base para comparar formas** é avaliada no **nível 50**, sem Nature, variação individual ou buffs (D-168/D-172). Uma aparência alternativa **sem AGI-base própria distinta** não acrescenta automaticamente uma observação só por ser visualmente diferente.
- **Não excluir** da amostra a espécie/forma-base quando esta também for elegível; a presente escolha se refere a quando contar **formas alternativas adicionalmente**.
- **Exemplo estritamente hipotético:** espécie-base controlável com AGI-base 40 e forma alternativa igualmente controlável com AGI-base própria 65 → duas observações; forma apenas cosmética com AGI-base 40 idêntica à espécie-base → não há uma observação adicional por essa forma.
- A regra não inventa espécies, tipos de formas, AGI, níveis de evolução ou referências numéricas. Conservar D-174 para espécies planejadas oficialmente documentadas; a amostra ainda exige dados verificáveis completos (D-178).

## Pendências e escopo

- Verificar na documentação vigente a elegibilidade de cada forma, se dispõe de AGI-base própria e se é distinta; não presumir valores de formas não documentadas. Critérios sobre múltiplas formas com valores iguais entre si não são definidos além da regra literal acima.
- D-162 continua exigindo validação expressa do valor da mediana real antes de implementar.
- Apenas documentação; nenhum código, dado de espécies, teste ou recurso modificado.

## Complemento posterior — Rodada 66 / D-182 (2026-11-03)

**D-182 (R66-Q1A)** esclarece a contagem de formas alternativas: **apenas uma observação por valor distinto de AGI-base no nível 50 dentro de cada espécie**. Se duas formas controláveis da mesma espécie possuírem o mesmo valor AGI-base, não duplicar a observação; AGI igual entre **espécies diferentes** continua contando separadamente. Preservar elegibilidade da D-174 e exigência de dados completos da D-178, sem calcular referência ou modificar código.
