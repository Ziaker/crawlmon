<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-080 — R43-Q9 (9C): Desaparecimento fatal com partículas e fumaça

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Como o inimigo deve desaparecer após cair no chão?
- **Escolha recomendada:** **9C — Desaparece em uma explosão visual estilizada de partículas e fumaça.**

## Regra consolidada

Após o lançamento e a queda fatal, **o inimigo desaparece em uma explosão visual estilizada de partículas e fumaça**. Esta regra não se aplica aos aliados derrotados, que permanecem visíveis no chão.

## Referências e limitações

- **Decisões relacionadas:** D-056, D-068, D-079.
- **Pendência:** Duração, escala, cores, intensidade e composição do efeito ainda não foram especificadas. Não inventar desaparecimento para aliados.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.

## Complemento posterior (2026-11-03)

**D-166:** para inimigos, o desaparecimento é o encolhimento no ar com brilho de faíscas, sem explosão de fumaça após a queda.
