# D-161 — Rodada 62 Q5 (5B): referência numérica de AGI para ATB continua pendente

- **Data:** 2026-11-03
- **Área:** Combate / ATB / política de calibração
- **Origem:** resposta expressa do criador, Rodada 62 Q5, aceitando a recomendação
- **Estado:** decisão expressa de **adiar a fixação numérica**; não é aprovação de fórmula ou de implementação

## Declaração literal do criador

> 5B — Manter a referência numérica pendente até avaliar o ritmo de combate (recomendada).

## Alcance da escolha

- **Não escolher ainda** o valor numérico da **AGI de referência para regeneração de ATB**. A questão voltará a ser avaliada quando houver avaliação do ritmo do combate.
- Preservar D-145: AGI é um atributo único; os subsistemas ATB e tempo de trajeto **podem ter referências numéricas distintas**, permitindo calibração independente.
- A referência **50 para trajeto**, aprovada na D-160, **não preenche nem implica** a referência de ATB.
- Preservar a intenção de calibração sem alterar silenciosamente o ritmo existente (D-126) e as regras de ATB previamente aprovadas. Não inferir que uma avaliação de ritmo foi realizada.

## Exemplo ilustrativo da pergunta

- Um cenário hipotético com referência ATB 50 e 5 s para regenerar cinco blocos poderia produzir 2,5 s em AGI 100 **se tal fórmula vier a ser aprovada**. Esses valores **não foram aprovados para ATB** nesta rodada; o exemplo apenas explica o tipo de calibração pendente.

## Pendências

- Valor de referência do ATB, relação quantitativa de AGI com regeneração, parâmetros e método da avaliação de ritmo, interação com efeitos e casos-limite não foram resolvidos por esta resposta.
- Não estabelecer uma nova tarefa de testes automáticos ou alterar código por esta decisão.

## Escopo

Registro documental apenas; nenhum código, teste, Move, cena, VFX ou asset alterado.

## Conciliação posterior — Rodada 62, versão prevalente confirmada (2026-11-03)

**Estado atual: histórico da versão divergente.** A resposta **Q5B** desta D-161 não é a escolha vigente Q5 da Rodada 62; o criador confirmou **Q5A / D-166** para o desempate por sorteio reproduzível. Na mesma versão vigente, **D-163 (Q2A)** aprovou tempo de preenchimento natural de ATB inversamente proporcional à AGI efetiva, e **D-164 (Q3B)** estabeleceu piso de cálculo 1 para ATB. **O número de referência AGI do ATB continua pendente**, mas sua relação matemática agora está aprovada. Preservado histórico, sem implementação.
