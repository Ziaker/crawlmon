# D-167 — Rodada 63 Q1 (1B): amostra da mediana inclui todas as espécies diretamente controláveis

- **Data:** 2026-11-03.
- **Área:** AGI / referência de trajeto / seleção das espécies.
- **Origem:** resposta expressa do criador na Rodada 63.
- **Estado:** decisão aprovada e documentada; amostra e mediana numérica não calculadas; sem implementação.

## Declaração literal do criador

> 1B — Incluir todas as espécies que podem ser controladas diretamente pelo jogador, inclusive formas evoluídas elegíveis.

## Regra aprovada

- Para a referência de AGI de trajeto determinada pela **mediana das espécies jogáveis** (D-162), a amostra deve incluir **todas as espécies que podem ser controladas diretamente pelo jogador**, inclusive **formas evoluídas que sejam elegíveis ao controle direto**.
- Não limitar a amostra apenas às espécies iniciais; também não acrescentar automaticamente espécies que **não possam ser diretamente controladas pelo jogador**, mesmo que participem de batalhas como adversárias ou unidades exclusivamente da IA.
- Esta decisão define o **critério de inclusão**, mas **não identifica nem congela uma lista concreta de espécies**, e não determina como contar duplicatas, variantes ou formas quando sua elegibilidade for incerta.
- **D-168 (Q2A)** estabelece como obter um valor comparável de AGI de cada espécie da amostra. A **mediana final e o valor numérico de referência ainda exigem validação do criador antes de implementar** (D-162).
- **Exemplo ilustrativo:** caso uma espécie inicial e sua evolução sejam ambas controláveis diretamente, **ambas** atendem ao critério de inclusão; se uma espécie só puder aparecer sob controle de IA, não entra apenas por participar do combate. Nenhuma lista de espécies foi aprovada neste exemplo.

## Pendências e escopo

- Determinar a partir de fontes atuais do projeto quais espécies e evoluções são efetivamente elegíveis, qual a representação de cada forma e os valores de AGI no nível de referência ainda a definir.
- Somente documentação; nenhum arquivo de código, teste, recurso ou ficha foi alterado.

## Complemento posterior — Rodada 64 / D-172 e D-174 (2026-11-03)

**D-172 (R64-Q1C):** comparar AGI-base das espécies elegíveis no **nível comum 50**. **D-174 (R64-Q3B):** incluir também espécies **oficialmente previstas na documentação vigente** para controle direto pelo jogador, **mesmo se ainda não implementadas**, inclusive evoluções que cumpram o critério. Nenhuma lista ou AGI de espécies foi deduzida; preservar a exigência de validação numérica da D-162. Esta nota é aditiva e não modifica código.
