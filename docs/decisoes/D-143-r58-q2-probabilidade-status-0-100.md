<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-143 — Rodada 58 Q2 (A): Probabilidade final de status limitada ao intervalo 0–100%

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 58.
- **Proveniência:** escolha expressa do criador, aceitando a recomendação do assistente para esta questão.
- **Estado:** regra de design aprovada e documentada; não implementada.

## Declaração literal do criador

> 2A — Como limitar a chance final de aplicação de status? Limitar a probabilidade final ao intervalo 0–100%. (recomendação aceita)

## Regra aprovada e compatibilidade

- - O resultado final da **chance de aplicação de um efeito probabilístico de status** deve permanecer **entre 0% e 100%**, inclusive; se a combinação da chance-base com os modificadores produzir um número fora do intervalo, **limitar o resultado a 0% ou a 100%, conforme o extremo ultrapassado**.
- - A regra vale para probabilidades **efetivamente declaradas na ficha do Move** e ajustadas pelas diferenças de Luck (LUK) entre aplicador e alvo (D-134/D-137). **Efeitos garantidos permanecem garantidos**, sem nova rolagem.
- - **Não fixa nem revisa** o coeficiente de LUK por esta escolha. D-142 contém taxa histórica de 1 pp por 10 LUK; a observação R58-Q1D apresenta taxa aparentemente diferente e permanece **pendente de esclarecimento**.
- - **Exemplo:** chance-base 98%, modificação hipotética de +5 pontos percentuais produz 103% intermediários; a probabilidade final é **100%**. De forma análoga, valor intermediário negativo fica em 0%.
- - Este limite de chance não impõe teto a atributos permanentes, que podem superar 100 (D-139), nem estende o clamp a crítico ou esquiva automática sem regra específica.

## Pendências e implementação

- **Ainda não definido:** Coeficiente efetivo de LUK em conflito R58-Q1D × D-142; tratamento de diferenças fracionárias e chances-base individuais.
- Esta atividade autoriza apenas atualizar documentos, não implementar código, testes, VFX ou fichas de Moves.

## Complemento posterior — Rodada 59 (2026-11-03)

**D-146 — Rodada 59, Q1A:** o conflito registrado na Rodada 58 sobre o coeficiente de LUK foi **resolvido por escolha expressa**. O coeficiente vigente é **1 ponto percentual por 1 ponto de diferença de LUK** (aplicador − alvo), substituindo a taxa anterior de D-142. **Esta D-143 permanece integralmente válida**: limitar o resultado final da chance probabilística a **0–100%**; efeitos garantidos não ganham rolagem.
