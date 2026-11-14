<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-078 — R43-Q7 (7A): Velocidade de onda AoE configurável por Move

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Como definir a velocidade constante de propagação dos projéteis AoE?
- **Escolha recomendada:** **7A — Cada Move AoE possui sua própria velocidade configurável.**

## Regra consolidada

Cada Move de projétil AoE possui **sua própria velocidade de propagação configurável**, que se mantém **constante durante a onda** de sua execução, inclusive quando os alvos mudam de posição.

## Referências e limitações

- **Decisões relacionadas:** D-009, D-057, D-067, D-077.
- **Pendência:** Não há valores numéricos aprovados para as velocidades individuais; devem ser especificados por Move. A ausência de valor não autoriza usar velocidade global silenciosamente.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
