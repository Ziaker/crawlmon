<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-081 — R43-Q10 (10A): Resultado exibido somente após sequência fatal completa

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Quando a batalha termina com um hit fatal, quando mostrar a tela de vitória ou derrota?
- **Escolha recomendada:** **10A — Somente depois que a sequência fatal do personagem derrotado terminar.**

## Regra consolidada

Quando a batalha terminar em consequência de um hit fatal, **mostrar a tela de vitória ou derrota somente depois da conclusão da sequência fatal do personagem derrotado**. Para inimigos inclui lançamento, queda e desaparecimento; para aliados inclui lançamento e queda, sem desaparecimento.

## Referências e limitações

- **Decisões relacionadas:** D-056, D-068, D-080.
- **Pendência:** O instante lógico do resultado da batalha não foi alterado: esta decisão trata de quando mostrar a tela. Casos de múltiplos derrotados/KO simultâneo permanecem sem regra específica.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
