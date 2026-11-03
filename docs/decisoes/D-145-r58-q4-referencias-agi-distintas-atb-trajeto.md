# D-145 — Rodada 58 Q4 (B): Referências numéricas distintas para ATB e trajetos com AGI única

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 58.
- **Proveniência:** escolha expressa do criador, aceitando a recomendação do assistente para esta questão.
- **Estado:** regra de design aprovada e documentada; não implementada.

## Declaração literal do criador

> 4B — O valor de referência de AGI deve ser o mesmo para ATB e deslocamento? Permitir referências numéricas distintas para ATB e trajetos, mantendo AGI como um único atributo. (recomendação aceita)

## Regra aprovada e compatibilidade

- - **Agility (AGI) é um único atributo do Pokémon** (D-117 e D-131), usado em **regeneração de ATB** e **redução do tempo próprio de deslocamento de cada Move** (D-119).
- - A calibração pode usar **dois valores de referência numéricos diferentes**, um para a **taxa de regeneração do ATB** e outro para **duração dos trajetos**; isso **não** cria dois atributos de AGI.
- - A **referência de trajeto continua comum às espécies** (D-136). A opção por referências distintas entre subsistemas não autoriza valores individuais por espécie.
- - Preservar a **proporcionalidade inversa** de AGI efetiva para a duração (D-136), a aplicação de AGI antes dos passos e o piso final de **0,25 s** (D-133/D-018), e AGI mínima de **1 exclusivamente nessa fórmula** (D-140).
- - **Não foram fixados valores numéricos** para nenhuma referência, nem a função final de ATB, arredondamentos ou tempos próprios de cada Move. A calibração inicial deve preservar tanto quanto possível o ritmo aprovado (D-126).
- - **Exemplo ilustrativo:** referências possíveis de ATB e trajetória podem ser distintas (valores hipotéticos 40 e 60), sem que isso signifique atributos distintos. **40 e 60 não são valores aprovados**.

## Pendências e implementação

- **Ainda não definido:** Valores de referência de ATB e trajeto, fórmula de ATB, parâmetros de calibração e testes de equilíbrio.
- Esta atividade autoriza apenas atualizar documentos, não implementar código, testes, VFX ou fichas de Moves.
