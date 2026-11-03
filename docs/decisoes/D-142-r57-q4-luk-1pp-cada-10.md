# D-142 — Rodada 57 Q4 (B): Status probabilístico: 1 ponto percentual para cada 10 pontos de diferença LUK

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 57.
- **Origem:** escolha enviada expressamente pelo criador; as alternativas das questões 2–4 haviam sido recomendadas pelo assistente.
- **Estado:** regra aprovada e registrada em documentação; não implementada nesta atividade.

## Declaração literal do criador

> 4B — Como transformar a diferença de LUK em chance de status? Modificar a chance em 1 ponto percentual a cada 10 pontos de diferença de LUK. No exemplo, 43%. (recomendação aceita)

## Regra aprovada

- Para efeito probabilístico cuja ficha de Move declare chance-base, usar a **diferença LUK(aplicador) − LUK(alvo)** (D-137): para **cada 10 pontos da diferença**, ajustar **1 ponto percentual** da chance de aplicação.
- Se a diferença for positiva, a chance aumenta; se negativa, diminui. Exemplo expressamente aprovado: **40% base**, LUK 70 contra LUK 40, diferença +30 ⇒ **43%**.
- Preservar D-134: **efeitos garantidos não recebem rolagem**, apenas efeitos com chance declarada são alterados. D-012: rolagem de status não introduz Evade em golpes não esquiváveis.
- A resposta não definiu **interpolação/arredondamento** para diferenças como +7 ou −15, nem limitação de probabilidades calculadas além de 0–100%, especialmente com atributos que podem superar 100 (D-139). Não decidir esses detalhes por suposição.
- Esta decisão não define os ajustes de LUK em crítico ou esquiva automática da D-127.

## Limitações

- Detalhes quantitativos não contidos na declaração literal continuam pendentes. Sem alterações de código, dados, testes, VFX ou assets.

## Complemento posterior — Rodada 58 (2026-11-03)

**Rodada 58, Q1D — esclarecimento pendente:** o criador escreveu literalmente: **“não entendi a 1, 50% + 7 luck = 57% - 10luck do oponente = 47% de chance no total”**. Esse cálculo equivale a **1 ponto percentual por 1 ponto de LUK** de cada participante, diferindo da taxa expressamente aprovada nesta D-142 (**1 ponto percentual a cada 10 pontos de diferença**), que daria **49,7%** no exemplo usando interpolação proporcional. **Não substituir esta D-142 por suposição**: confirmar se o novo exemplo é uma revisão intencional da taxa ou uma interpretação a esclarecer. A decisão R58-Q2A sobre limitar probabilidades a 0–100% permanece independente desta dúvida.

## Complemento posterior — Rodada 59 (2026-11-03)

**D-146 — Rodada 59, Q1A (decisão expressa e posterior):** a proporção desta D-142 de **1 ponto percentual por 10 pontos de diferença de LUK** fica **revogada** para a aplicação de status probabilístico. A nova regra é **1 ponto percentual por 1 ponto de diferença entre LUK do aplicador e LUK do alvo**. Exemplo expressamente aprovado: **50% + 7 − 10 = 47%**. Preservar o texto histórico da D-142 e o registro de conflito da Rodada 58, agora **resolvido**; a chance final permanece limitada a 0–100% pela D-143, e efeitos garantidos permanecem garantidos.
