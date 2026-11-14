<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-077 — R43-Q6 (6D): Geometria da onda AoE definida por Move

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Qual geometria a onda de projéteis AoE deve utilizar?
- **Escolha recomendada:** **6D — A geometria depende do Move, preservando as regras gerais de AoE.**

## Regra consolidada

**Não impor uma única geometria universal** às ondas de projéteis AoE. **Cada Move determina sua geometria**, respeitando as regras comuns: onda única para o Move, sem alvo principal, participantes vivos na declaração, Evade compartilhado com resoluções individuais, velocidade espacial constante, e consideração das posições atuais dos alvos.

## Referências e limitações

- **Decisões relacionadas:** D-007, D-009, D-037, D-057, D-059, D-066, D-067.
- **Pendência:** A geometria concreta de cada Move ainda precisa ser especificada; esta decisão não autoriza escolher circular, linear ou múltiplos projéteis para Moves específicos sem outra aprovação.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
